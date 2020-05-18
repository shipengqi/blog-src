---
title: Go 
tags:
---

## Goroutine 是什么
goroutine 其实就是协程，也叫用户态线程，二级线程，为了解决系统线程太“重”的问题：
- 创建和切换太重，操作系统线程的创建和切换都需要进入内核，进入内核消耗的性能较高，开销大。
- 内存使用太重 1. 内核创建线程时，会默认分配一块较大的栈内存，避免极端情况下，系统线程栈的溢出。但是大部分情况下，系统线程
用不了那么多内存，导致浪费。2. 栈内存空间一旦创建和初始化完成后，大小就不能再改变，在某些场景下，线程栈还是有溢出的
风险


goroutine 是用户态线程，它的创建和切换，都是在用户代码中完成的，不需要进入系统内核，开销远远小于系统线程的创建和切换

goroutine 启动时 默认栈大小是 2 k。栈不够用就自动扩展，如果太大了就自动收缩。避免了内存的浪费，和栈溢出的风险。

## GPM 模型

## 一些重要的结构体

## Goroutine 调度策略

## Goroutine 被动调度
## Goroutine 主动调度
## 抢占调度

## 调度器初始化
## main goroutine
## 非 main goroutine
https://www.cnblogs.com/my_captain/p/12663865.html
https://www.jianshu.com/p/4393a4537eca
https://www.jianshu.com/p/f8b2e2869372
https://www.jianshu.com/p/c38a22d8f913
https://www.jianshu.com/p/0ab4d1b1db45
https://www.jianshu.com/p/44be951fc19f
并发编程实战
极客时间 go
go 学习笔记
https://github.com/qcrao/Go-Questions 电子书 公众号
https://changkun.de/golang/
http://mp.weixin.qq.com/mp/homepage?__biz=MjM5MDUwNTQwMQ==&hid=1&sn=e47afe02b972f5296e1e3073982cf1b6&scene=18#wechat_redirect
http://mp.weixin.qq.com/mp/homepage?__biz=MzU1OTg5NDkzOA==&hid=1&sn=8fc2b63f53559bc0cee292ce629c4788&scene=18#wechat_redirect

go gc，memory manage

go context
https://blog.csdn.net/u011957758/article/details/82948750
https://studygolang.com/articles/13866?fr=sidebar
https://leileiluoluo.com/posts/golang-context.html
https://www.cnblogs.com/zhangboyu/p/7456606.html
https://www.cnblogs.com/sunlong88/p/11272559.html
https://studygolang.com/articles/23247?fr=sidebar

系统线程对 goroutine 的调度与内核对系统线程的调度原理是一样的，本质上都是通过保存和修改 CPU 寄存器的值来达到切换线程/ goroutine 的目的。

内核调度线程时，寄存器和程序计数器的值保存在内核的内存中，那么线程对 goroutine 的调度时，寄存器和程序计数器的值，保存在哪里？

goroutine 的调度器，引入了一个数据结构来保存 CPU 寄存器的值以及 goroutine 的其它一些状态信息。

`runtime/runtime2.go`
```go
type g struct {
	// Stack parameters.
	// stack describes the actual stack memory: [stack.lo, stack.hi).
	// stackguard0 is the stack pointer compared in the Go stack growth prologue.
	// It is stack.lo+StackGuard normally, but can be StackPreempt to trigger a preemption.
	// stackguard1 is the stack pointer compared in the C stack growth prologue.
	// It is stack.lo+StackGuard on g0 and gsignal stacks.
	// It is ~0 on other goroutine stacks, to trigger a call to morestackc (and crash).
	stack       stack   // offset known to runtime/cgo
	stackguard0 uintptr // offset known to liblink
	stackguard1 uintptr // offset known to liblink

	_panic         *_panic // innermost panic - offset known to liblink
	_defer         *_defer // innermost defer
	m              *m      // current m; offset known to arm liblink
	sched          gobuf
	syscallsp      uintptr        // if status==Gsyscall, syscallsp = sched.sp to use during gc
	syscallpc      uintptr        // if status==Gsyscall, syscallpc = sched.pc to use during gc
	stktopsp       uintptr        // expected sp at top of stack, to check in traceback
	param          unsafe.Pointer // passed parameter on wakeup
	atomicstatus   uint32
	stackLock      uint32 // sigprof/scang lock; TODO: fold in to atomicstatus
	goid           int64
	schedlink      guintptr
	waitsince      int64      // approx time when the g become blocked
	waitreason     waitReason // if status==Gwaiting
	preempt        bool       // preemption signal, duplicates stackguard0 = stackpreempt
	paniconfault   bool       // panic (instead of crash) on unexpected fault address
	preemptscan    bool       // preempted g does scan for gc
	gcscandone     bool       // g has scanned stack; protected by _Gscan bit in status
	gcscanvalid    bool       // false at start of gc cycle, true if G has not run since last scan; TODO: remove?
	throwsplit     bool       // must not split stack
	raceignore     int8       // ignore race detection events
	sysblocktraced bool       // StartTrace has emitted EvGoInSyscall about this goroutine
	sysexitticks   int64      // cputicks when syscall has returned (for tracing)
	traceseq       uint64     // trace event sequencer
	tracelastp     puintptr   // last P emitted an event for this goroutine
	lockedm        muintptr
	sig            uint32
	writebuf       []byte
	sigcode0       uintptr
	sigcode1       uintptr
	sigpc          uintptr
	gopc           uintptr         // pc of go statement that created this goroutine
	ancestors      *[]ancestorInfo // ancestor information goroutine(s) that created this goroutine (only used if debug.tracebackancestors)
	startpc        uintptr         // pc of goroutine function
	racectx        uintptr
	waiting        *sudog         // sudog structures this g is waiting on (that have a valid elem ptr); in lock order
	cgoCtxt        []uintptr      // cgo traceback context
	labels         unsafe.Pointer // profiler labels
	timer          *timer         // cached timer for time.Sleep
	selectDone     uint32         // are we participating in a select and did someone win the race?

	// Per-G GC state

	// gcAssistBytes is this G's GC assist credit in terms of
	// bytes allocated. If this is positive, then the G has credit
	// to allocate gcAssistBytes bytes without assisting. If this
	// is negative, then the G must correct this by performing
	// scan work. We track this in bytes to make it fast to update
	// and check for debt in the malloc hot path. The assist ratio
	// determines how this corresponds to scan work debt.
	gcAssistBytes int64
}
```

当 goroutine 被调离 CPU 时，把寄存器和程序计数器的值保存到 g 对象中，当被调度器调起时，再从 g 对象中取出，
恢复到 CPU 的寄存器中

`shcedt` 