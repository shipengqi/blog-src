---
title: go-select
tags:
---


Go 语言的 select 与 C 语言中的 select 有着比较相似的功能。
Go 语言中的 select 关键字能够让 Goroutine 同时等待多个 Channel 的可读或者可写，在多个文件或者 Channel 发生状态改变之前，select 会一
直阻塞当前线程或者 Goroutine。

select 中有多个 case，这些 case 中的表达式必须都是 Channel 的收发操作

1. select 能在 Channel 上进行非阻塞的收发操作；
2. select 在遇到多个 Channel 同时响应时会随机挑选 case 执行；

## 非阻塞的收发

通常情况下，select 语句会阻塞当前 Goroutine 并等待多个 Channel 中的一个达到可以收发的状态。但是如果 select 控制结构中包含 default 语句，
那么这个 select 语句在执行时会遇到以下两种情况：

1. 当存在可以收发的 Channel 时，直接处理该 Channel 对应的 case；
2. 当不存在可以收发的 Channel 时，执行 default 中的语句；

## 随机执行

使用 select 遇到的情况是同时有多个 case 就绪时，select 会选择那个 case 执行？

```go
func main() {
 ch := make(chan int)
 go func() {
  for range time.Tick(1 * time.Second) {
   ch <- 0
  }
 }()

 for {
  select {
  case <-ch:
   println("case1")
  case <-ch:
   println("case2")
  }
 }
}

// 输出
// case1
// case2
// case1
```

select 在遇到多个 <-ch 同时满足可读或者可写条件时会随机选择一个 case 执行其中的代码。

## 数据结构

select 在 Go 语言的源代码中不存在对应的结构体
select 控制结构中的 case 使用 `runtime.scase` 结构体来表示：

```go
type scase struct {
 c           *hchan // 存储 case 中使用的 Channel, 非默认的 case 中都与 Channel 的发送和接收有关
 elem        unsafe.Pointer // 接收或者发送数据的变量地址
 kind        uint16 // 表示 runtime.scase 的种类
 pc          uintptr
 releasetime int64
}
```

runtime.scase 的种类

```go
const (
 caseNil = iota
 caseRecv
 caseSend
 caseDefault
)
```

## 实现原理

select 语句在编译期间会被转换成 `OSELECT` 节点

**每一个 OSELECT 节点都会持有一组 OCASE 节点，如果 OCASE 的执行条件是空，那就意味着这是一个 default 节点**:

每一个 OCASE 既包含执行条件也包含满足条件后执行的代码。

编译器在中间代码生成期间会根据 select 中 case 的不同对控制语句进行优化，这一过程都发生在 `cmd/compile/internal/gc.walkselectcases` 函数中

分四种情况

1. select 不存在任何的 case；
2. select 只存在一个 case；
3. select 存在两个 case，其中一个 case 是 default；
4. select 存在多个 case；

### 直接阻塞

当 select 结构中不包含任何 case 时编译器是如何进行处理的，`cmd/compile/internal/gc.walkselectcases`：

```go
func walkselectcases(cases *Nodes) []*Node {
 n := cases.Len()

 if n == 0 {
  return []*Node{mkcall("block", nil, nil)}
 }
 ...
}
```

直接将类似 `select {}` 的空语句转换成调用 `runtime.block` 函数：

```go
func block() {
 gopark(nil, nil, waitReasonSelectNoCases, traceEvGoStop, 1)
}
```

调用 runtime.gopark 让出当前 Goroutine 对处理器的使用权，传入的等待原因是 `waitReasonSelectNoCases`。

空的 select 语句会直接阻塞当前的 Goroutine，导致 Goroutine 进入无法被唤醒的永久休眠状态。

## 只包含一个 case

如果当前的 select 条件只包含一个 case，那么就会将 select 改写成 if 条件语句。

```go
// 改写前
select {
case v, ok <-ch: // case ch <- v
    ...
}

// 改写后
if ch == nil {
    block()
}
v, ok := <-ch // case ch <- v
...
```

处理单操作 select 语句时，会根据 Channel 的收发情况生成不同的语句。当 case 中的 Channel 是空指针时，就会直接挂起当前 Goroutine 并永久休眠。

### 非阻塞操作

当 select 中仅包含两个 case，并且其中一个是 default 时，Go 语言的编译器就会认为这是一次非阻塞的收发
操作。`walkselectcases` 函数会对这种情况单独处理，不过在正式优化之前，该函数会将 case 中的所有 Channel 都转换成指向 Channel 的地址。

#### 发送

Channel 的发送过程，当 case 中表达式的类型是 OSEND 时，编译器会使用 if/else 语句和 runtime.selectnbsend 函数改写代码：

```go
select {
case ch <- i:
    ...
default:
    ...
}

if selectnbsend(ch, i) {
    ...
} else {
    ...
}
```

runtime.selectnbsend 函数，它为我们提供了向 Channel 非阻塞地发送数据的能力。

```go
func selectnbsend(c *hchan, elem unsafe.Pointer) (selected bool) {
 return chansend(c, elem, false, getcallerpc())
}
```

runtime.chansend 函数包含一个 block 参数，该参数会决定这一次的发送是不是阻塞的

这里传入了 `false` ，所以哪怕是不存在接收方或者缓冲区空间不足都不会阻塞当前 Goroutine 而是会直接返回。

#### 接受

从 Channel 中接收数据可能会返回一个或者两个值，所以接受数据的情况会比发送稍显复杂，不过改写的套路是差不多的：

```go
// 改写前
select {
case v <- ch: // case v, ok <- ch:
    ......
default:
    ......
}

// 改写后
if selectnbrecv(&v, ch) { // if selectnbrecv2(&v, &ok, ch) {
    ...
} else {
    ...
}
```

返回值数量不同会导致使用函数的不同，两个用于非阻塞接收消息的函数 runtime.selectnbrecv 和 runtime.selectnbrecv2 只是
对 runtime.chanrecv 返回值的处理稍有不同：

```go
func selectnbrecv(elem unsafe.Pointer, c *hchan) (selected bool) {
 selected, _ = chanrecv(c, elem, false)
 return
}

func selectnbrecv2(elem unsafe.Pointer, received *bool, c *hchan) (selected bool) {
 selected, *received = chanrecv(c, elem, false)
 return
}
```

因为接收方不需要，所以 runtime.selectnbrecv 会直接忽略返回的布尔值，而 runtime.selectnbrecv2 会将布尔值回传给调用方。

与 runtime.chansend 一样，runtime.chanrecv 也提供了一个 block 参数用于控制这一次接收是否阻塞。

### 常见流程

在默认的情况下，编译器会使用如下的流程处理 select 语句：

1. 将所有的 case 转换成包含 Channel 以及类型等信息的 runtime.scase 结构体；
2. 调用运行时函数 runtime.selectgo 从多个准备就绪的 Channel 中选择一个可执行的 runtime.scase 结构体；
3. 通过 for 循环生成一组 if 语句，在语句中判断自己是不是被选中的 case

```go
selv := [3]scase{}
order := [6]uint16
for i, cas := range cases {
    c := scase{}
    c.kind = ...
    c.elem = ...
    c.c = ...
}
chosen, revcOK := selectgo(selv, order, 3)
if chosen == 0 {
    ...
    break
}
if chosen == 1 {
    ...
    break
}
if chosen == 2 {
    ...
    break
}
```

最重要的就是用于选择待执行 case 的运行时函数 runtime.selectgo

runtime.selectgo 函数首先会进行执行必要的初始化操作并决定处理 case 的两个顺序 — 轮询顺序 pollOrder 和加锁顺序 lockOrder：

```go
func selectgo(cas0 *scase, order0 *uint16, ncases int) (int, bool) {
 cas1 := (*[1 << 16]scase)(unsafe.Pointer(cas0))
 order1 := (*[1 << 17]uint16)(unsafe.Pointer(order0))
 
 scases := cas1[:ncases:ncases]
 pollorder := order1[:ncases:ncases]
 lockorder := order1[ncases:][:ncases:ncases]
 for i := range scases {
  cas := &scases[i]
 }

 for i := 1; i < ncases; i++ {
  j := fastrandn(uint32(i + 1))
  pollorder[i] = pollorder[j]
  pollorder[j] = uint16(i)
 }

 // 根据 Channel 的地址排序确定加锁顺序
 ...
 sellock(scases, lockorder)
 ...
}
```

轮询顺序 pollOrder 和加锁顺序 lockOrder 分别是通过以下的方式确认的：

轮询顺序：通过 runtime.fastrandn 函数引入随机性；
加锁顺序：按照 Channel 的地址排序后确定加锁顺序；

随机的轮询顺序可以避免 Channel 的饥饿问题，保证公平性；而根据 Channel 的地址顺序确定加锁顺序能够避免死锁的发生。

runtime.sellock 函数会按照之前生成的加锁顺序锁定 select 语句中包含所有的 Channel。

#### 循环

select 语句锁定了所有 Channel 之后就会进入 runtime.selectgo 函数的主循环，它会分三个阶段查找或者等待某个 Channel 准备就绪：

1. 查找是否已经存在准备就绪的 Channel，即可以执行收发操作；
2. 将当前 Goroutine 加入 Channel 对应的收发队列上并等待其他 Goroutine 的唤醒；
3. 当前 Goroutine 被唤醒之后找到满足条件的 Channel 并进行处理；

## 小结

在编译期间，Go 语言会对 select 语句进行优化，它会根据 select 中 case 的不同选择不同的优化路径：

空的 select 语句会被转换成 runtime.block 函数的调用，直接挂起当前 Goroutine；
如果 select 语句中只包含一个 case，就会被转换成 if ch == nil { block }; n; 表达式；
首先判断操作的 Channel 是不是空的；
然后执行 case 结构中的内容；
如果 select 语句中只包含两个 case 并且其中一个是 default，那么会使用 runtime.selectnbrecv 和 runtime.selectnbsend 非阻塞地执行收发操作；
在默认情况下会通过 runtime.selectgo 函数获取执行 case 的索引，并通过多个 if 语句执行对应 case 中的代码；
在编译器已经对 select 语句进行优化之后，Go 语言会在运行时执行编译期间展开的 runtime.selectgo 函数，该函数会按照以下的流程执行：

随机生成一个遍历的轮询顺序 pollOrder 并根据 Channel 地址生成锁定顺序 lockOrder；
根据 pollOrder 遍历所有的 case 查看是否有可以立刻处理的 Channel；
如果存在就直接获取 case 对应的索引并返回；
如果不存在就会创建 runtime.sudog 结构体，将当前 Goroutine 加入到所有相关 Channel 的收发队列，并调用 runtime.gopark 挂起当前 Goroutine 等待调度器的唤醒；
当调度器唤醒当前 Goroutine 时就会再次按照 lockOrder 遍历所有的 case，从中查找需要被处理的 runtime.sudog 结构对应的索引；

https://draveness.me/golang/docs/part2-foundation/ch05-keyword/golang-select/
