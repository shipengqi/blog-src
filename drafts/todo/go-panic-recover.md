---
title: go-panic-recover
tags:
---


当panic发生之后，程序从正常的执行流程跳转到执行panic发生之前通过defer语句注册的defered函数，直到某个defered函数通过recover函数
捕获了panic后再恢复正常的执行流程，如果没有recover则当所有的defered函数被执行完成之后结束程序

defer语句会被编译器翻译成对runtime包中deferproc()函数的调用，该函数会把defered函数打包成一个_defer结构体对象挂入goroutine对
应的g结构体对象的_defer链表中，_defer对象除了保存有defered函数的地址以及该函数需要的参数外，还会分别把call deferproc指令的下一
条指令的地址以及此时函数调用栈顶指针保存在_defer.pc和_defer.sp成员之中，用于recover时恢复程序的正常执行流程；

当某个defered函数通过recover()函数捕获到一个panic之后，程序将从该defered函数对应的_defer结构体对象的pc成员所保存的指令地址处开始执行；

panic可以嵌套，当发生panic之后在执行defer函数时又发生了panic即为嵌套。每个还未被recover的panic都会对应着一个_panic结构体对象，它
们会被依次挂入g结构体的_panic链表之中，最近一次发生的panic位于_panic链表表头，最早发生的panic位于链表尾。



Go程序在两种情况下会发生panic：

主动调用panic()函数，这包括go代码中直接调用以及由编译器插入的调用，比如编译器会插入代码检查访问数组/slice是否越界，同时还会插入调用panic()的代码，运行时如果越界就会去调用panic()函数；

非法操作，比如向只读内存写入数据，访问非法内存等也会发生panic。这种情况在Linux平台（其它平台不熟悉）下是通过信号(signal)机制来实现对panic()函数的调用。


panic()/recover()函数的调用会被编译器翻译成对runtime包中的gopanic()以及gorecover()函数的调用。

```go
// The implementation of the predeclared function panic.
func gopanic(e interface{}) {
    gp := getg()
    ......

    //panic可以嵌套，比如发生了panic之后运行defered函数又发生了panic，如上面的例3。
    //最新的panic会被挂入goroutine对应的g结构体对象的_panic链表的表头
    var p _panic  //创建_panic结构体对象
    p.arg = e  //panic的参数
    p.link = gp._panic
    gp._panic = (*_panic)(noescape(unsafe.Pointer(&p)))

    atomic.Xadd(&runningPanicDefers, 1)

    for {
        d := gp._defer  //取出_defer链表头的defered函数
        if d == nil {
            break  //没有defer函数将会跳出循环，然后打印栈信息然后结束程序
        }

        // If defer was started by earlier panic or Goexit (and, since we're back here, that triggered a new panic),
        // take defer off list. The earlier panic or Goexit will not continue running.
        if d.started {
            //到这里一定发生了panic嵌套，即在defered函数中又发生了panic
            //d.started = true是panic嵌套的充分条件，但并不是必要条件，也就是说
            //即使d.started为false也是可能发生嵌套的，
            //最近发生的一次panic并没有被recover所以取消上一次发生的panic
            if d._panic != nil {
                d._panic.aborted = true
            }
            d._panic = nil
            d.fn = nil
            gp._defer = d.link
            freedefer(d)
            continue
        }

        // Mark defer as started, but keep on list, so that traceback
        // can find and update the defer's argument frame if stack growth
        // or a garbage collection happens before reflectcall starts executing d.fn.
        d.started = true  //用于判断是否发生了嵌套panic

        // Record the panic that is running the defer.
        // If there is a new panic during the deferred call, that panic
        // will find d in the list and will mark d._panic (this panic) aborted.
        //把panic和defer函数关联起来
        d._panic = (*_panic)(noescape(unsafe.Pointer(&p)))

        //在panic中记录当前panic的栈顶位置，用于recover判断
        p.argp = unsafe.Pointer(getargp(0))
        //通过reflectcall函数调用defered函数
        //如果defered函数再次发生panic而且并未被该defered函数recover，则reflectcall永远不会返回，参考例2。
        //如果defered函数并没有发生过panic或者发生了panic但该defered函数成功recover了新发生的panic，
        //则此函数会返回继续执行后面的代码。
        reflectcall(nil, unsafe.Pointer(d.fn), deferArgs(d), uint32(d.siz), uint32(d.siz))
        p.argp = nil

        // reflectcall did not panic. Remove d.
        if gp._defer != d {
            throw("bad defer entry in panic")
        }
        //defer函数已经被执行，脱链
        d._panic = nil
        d.fn = nil
        gp._defer = d.link

        // trigger shrinkage to test stack copy. See stack_test.go:TestStackPanic
        //GC()

        pc := d.pc  //call deferproc的下一条指令的地址，下一条指令为 test rax, rax，在defer实现机制一文中有详细说明
        //call deferproc指令执行前的栈顶指针
        sp := unsafe.Pointer(d.sp) // must be pointer so it gets adjusted during stack copy
        freedefer(d)
        if p.recovered {
            //defered函数调用recover成功捕获了panic会设置p.recovered = true
            atomic.Xadd(&runningPanicDefers, -1)

            gp._panic = p.link
            // Aborted panics are marked but remain on the g.panic list.
            // Remove them from the list.
            for gp._panic != nil && gp._panic.aborted {
                gp._panic = gp._panic.link
            }
            if gp._panic == nil { // must be done with signal
                gp.sig = 0
            }
            // Pass information about recovering frame to recovery.
            gp.sigcode0 = uintptr(sp)
            gp.sigcode1 = pc
            //mcall函数永远不会返回，mcall函数的实现可以参考公众号内的其它文章，有详细分析
            //调用recovery函数跳转到pc位置继续执行
            mcall(recovery)  
            throw("recovery failed") // mcall should not return
        }
    }

    // ran out of deferred calls - old-school panic now
    // Because it is unsafe to call arbitrary user code after freezing
    // the world, we call preprintpanics to invoke all necessary Error
    // and String methods to prepare the panic strings before startpanic.
    preprintpanics(gp._panic)

    //打印函数调用链，然后挂死程序
    fatalpanic(gp._panic) // should not return
    *(*int)(nil) = 0      // not reached
}

// runtime/panic.go : 578

// The implementation of the predeclared function recover.
// Cannot split the stack because it needs to reliably
// find the stack segment of its caller.
//
// TODO(rsc): Once we commit to CopyStackAlways,
// this doesn't need to be nosplit.
//go:nosplit
func gorecover(argp uintptr) interface{} {
    // Must be in a function running as part of a deferred call during the panic.
    // Must be called from the topmost function of the call
    // (the function used in the defer statement).
    // p.argp is the argument pointer of that topmost deferred function call.
    // Compare against argp reported by caller.
    // If they match, the caller is the one who can recover.
    gp := getg()
    p := gp._panic
    //条件argp == uintptr(p.argp)在判断panic和recover是否匹配，内层recover不能捕获外层的panic
    //比如本文开头的例2中m函数中的defer catch("m")不能捕获g函数中的panic
    if p != nil && !p.recovered && argp == uintptr(p.argp) {
        p.recovered = true  //通过设置p.recovered = true告诉gopanic函数panic已经被recover了
        return p.arg
    }
    return nil
}

// runtime/panic.go : 634
// Unwind the stack after a deferred function calls recover
// after a panic. Then arrange to continue running as though
// the caller of the deferred function returned normally.
func recovery(gp *g) {
    // Info about defer passed in G struct.
    sp := gp.sigcode0   //call deferproc时的栈顶指针
    pc := gp.sigcode1   //call deferproc下一条指令的地址

    // d's arguments need to be in the stack.
    if sp != 0 && (sp < gp.stack.lo || gp.stack.hi < sp) {
        print("recover: ", hex(sp), " not in [", hex(gp.stack.lo), ", ", hex(gp.stack.hi), "]\n")
        throw("bad recovery")
    }

    // Make the deferproc for this d return again,
    // this time returning 1. The calling function will
    // jump to the standard return epilogue.
    gp.sched.sp = sp
    gp.sched.pc = pc
    gp.sched.lr = 0
    gp.sched.ret = 1     //该值（1）会被gogo函数放入eax寄存器
    gogo(&gp.sched)   //跳转到pc所指的指令处继续执行，gogo函数的实现请参考公众号内的其它文章，有详细分析
}
```

如果不考虑嵌套，主动 panic/recover 的流程比较清晰：遍历当前 goroutine 所注册的 defered 函数并通过 reflectcall 调用遍历到的
函数，如果某个 defered 函数调用了recover（对应到runtime的gorecover函数）则使用 mcall(recovery)  恢复程序的正常流程，否则执行完所
有的 defered 函数之后打印出 panic 的栈信息然后退出程序


为什么需要通过 reflectcall 来调用 defered 函数而不是直接调用 defered 函数

原因在于直接调用 defered 函数就得在当前栈帧中为它准备参数，而不同的 defered 函数的参数大小可能会有很大差异，比如有的defered函数没有
参数而有些defered函数可能又需要成千上万字节的参数，然而gopanic 函数的栈帧大小固定而且很小，所以很有可能没有足够的空间来存放 defered 
函数的参数，而reflectcall函数可以处理这种情况


panic的嵌套

对于panic的嵌套，也就是defered函数再次发生了panic，这会导致gopanic函数再次被调用，也就是说gopanic函数会存在递归调用，其调用
链为 gopanic()->reflectcall()->defered函数->gopanic() ，这时有两种情况：

defered函数通过defer再次注册了defered函数而且recover了最新的panic，则上面的调用链将原路从reflectcall()返回到gopanic函数继续执行；

defered函数没有recover它自己的panic，则reflectcall()不会返回。要么第二次gopanic执行完所有defered函数之后退出程序，要么新发生的panic代替了前一次panic然后由外层的defered函数recover。

```go
package main

import "fmt"
// m recover: m panic
// f recover: g panic

func main() {
    defer catch("f")

    g()
}

func catch(funcname string) {
    if r := recover(); r != nil {
        fmt.Println(funcname, "recover:", r)
    }
}

func g() {
    defer m()

    panic("g panic")
}

func m() {
    defer catch("m")

    panic("m panic")
}

// f recover: g panic
// func main() {
//     defer catch("f")
//
//     g()
// }
//
// func g() {
//     defer m()
//
//     panic("g panic")
// }
//
// func m() {
//     defer catch("m")
// }
//
// func catch(funcname string) {
//     if r := recover(); r != nil {
//         fmt.Println(funcname, "recover:", r)
//     }
// }
```

非法操作引起的panic
```go
package main

import (
   "fmt"
)

func f() {
    var p *int

    *p = 100  // crash

    fmt.Println("not reached")
}

func main() {
    f()
}
```

https://mp.weixin.qq.com/s/0JTBGHr-bV4ikLva-8ghEw