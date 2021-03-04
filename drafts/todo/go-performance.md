---
title: Go 如何做性能优化
tags:
---


cpu占用99% -> 发现GC线程占用率持续异常 -> 怀疑是内存问题 -> 排查对象数量 -> 定位产生对象异常多的接口 -> 定位到某接口 -> 在日志中找到此接口的异常请求 -> 根据异常参数排查代码中的问题 -> 定位到问题

在做内存问题相关的 profiling 时：

若 gc 相关函数占用异常，可重点排查对象数量

解决速度问题（CPU占用）时，关注对象数量（ --inuse/alloc_objects ）指标

解决内存占用问题时，关注分配空间（ --inuse/alloc_space ）指标

inuse 代表当前时刻的内存情况，alloc 代表从从程序启动到当前时刻累计的内存情况，一般情况下看 inuse 指标更重要一些，但某些时候两张图对比着看也能有些意外发现。

在日常 golang 编码时：

参数类型要检查，尤其是 sql 参数要检查（低级错误）
传递struct尽量使用指针，减少复制和内存占用消耗（尤其对于赋值给interface，会分配到堆上，额外增加gc消耗）
尽量不使用循环引用，除非逻辑真的需要
能在初始化中做的事就不要放到每次调用的时候做、

首先得分析问题，是CPU问题还是内存问题，又或者是网络问题。当三者都没问题的时候，请你压一压是不是自己程序性能有问题

标准库中的json序列化效率不高，咱们换个高效率的不就行了吗？例如：<https://github.com/json-iterator/go>

第一、首先排查是不是网络问题，查一段时间的 redis slowlog（slowlog 最直接简单）；

第二、 本地抓包，看日志中 redis 的 get key 网络耗时跟日志的时间是否对的上；

第三、查机器负载，是否对的上毛刺时间（弹性云机器，宿主机情况比较复杂）；

第四、查 redis sdk，这库我们维护的，看源码，看实时栈，看是否有阻塞（sdk 用了pool，pool 逻辑是否可能造成阻塞）；

第五、查看 runtime 监控，看是否有协程暴增，看 gc stw 时间是否影响 redis（go 版本有点低，同时内存占用大）；

第六、抓 trace ，看调度时间和调度时机是否有问题（并发协程数，GOMAXPROCS cpu负载都会影响调度）；

为什么获取到错误的 cpu 数，会导致业务耗时增长这么严重？主要还是对延迟要求太敏感了，然后又是高频服务，runtime 的影响被放大了。

关于怎么解决获取正确核数的问题，目前 golang 服务的解决方式主要是两个，第一是设置环境变量 GOMAXPROCS 启动，第二是显式调用 uber/automaxprocs。
 <https://github.com/uber-go/automaxprocs>

 delve 使用
<https://github.com/go-delve/delve/blob/master/Documentation/installation/windows/install.md>
<https://juejin.im/entry/5aa1f98d6fb9a028c522c84b>
<https://chai2010.cn/advanced-go-programming-book/ch3-asm/ch3-09-debug.html>

<https://mp.weixin.qq.com/s?__biz=MzAxMTA4Njc0OQ==&mid=2651439572&idx=1&sn=8e550f66eae78e2838e441b07a0330dc&chksm=80bb1f26b7cc9630f1144c135a4a448f8688d42e47ec1b64d90f9a76d427f69ae70c455b008f&mpshare=1&scene=24&srcid=&sharer_sharetime=1591665240002&sharer_shareid=29c7df185dfebeb5476e82189ac60d4d#rd>

常见性能瓶颈
业务逻辑
出现无效甚至降低性能的逻辑。常见的有

逻辑重复：相同的操作在不同的位置做了多次或循环跳出的条件设置不当。
资源未复用：内存频繁申请和释放，数据库链接频繁建立和销毁等。
无效代码。
存储
未选择恰当的存储方式，常见的有：

临时数据存放到数据库中，导致频繁读写数据库。
将复杂的树状结构的数据用 SQL 数据库存储，出现大量冗余列，并且在读写时要进行拆解和拼接。
数据库表设计不当，无法有效利用索引查询，导致查询操作耗时高甚至出现大量慢查询。
热点数据未使用缓存，导致数据库负载过高，响应速度下降。
并发处理
并发操作的问题主要出现在资源竞争上，常见的有：

死锁/活锁导致大量阻塞，性能严重下降。
资源竞争激烈：大量的线程或协程抢夺一个锁。
临界区过大：将不必要的操作也放入临界区，导致锁的释放速度过慢，引起其他线程或协程阻塞。

GC 处理
GC 的工作就是确定哪些内存可以释放，它是通过扫描内存查找内存分配的指针来完成这个工作的。GC 触发时机：

到达堆阈值：默认情况下，它将在堆大小加倍时运行，可通过 GOGC 来设定更高阈值（不建议变更此配置）
到达时间阈值：每两分钟会强制启动一次 GC 循环
为啥要注意 GC，是因为 GC 时出现 2 次 Stop the world，即停止所有协程，进行扫描操作。若是 GC 耗时高，则会严重影响服务器性能。

变量逃逸
注意，golang 中的栈是跟函数绑定的，函数结束时栈被回收。
变量内存回收：
如果分配在栈中，则函数执行结束可自动将内存回收；

如果分配在堆中，则函数执行结束可交给 GC（垃圾回收）处理；

而变量逃逸就意味着增加了堆中的对象个数，影响 GC 耗时。一般要尽量避免逃逸。

逃逸分析不变性：
指向栈对象的指针不能存在于堆中；
指向栈对象的指针不能在栈对象回收后存活；
在逃逸分析过程中，凡是发现出现违反上述约定的变量，就将其移到堆中。

逃逸常见的情况：
指针逃逸：返回局部变量的地址（不变性 2）
栈空间不足
动态类型逃逸：如 fmt.Sprintf,json.Marshel 等接受变量为...interface{}函数的调用，会导致传入的变量逃逸。
闭包引用

类型转换优化

```go
func String(b []byte) string {
 return *(*string)(unsafe.Pointer(&b))
}
func Str2Bytes(s string) []byte {
 x := (*[2]uintptr)(unsafe.Pointer(&s))
 h := [3]uintptr{x[0], x[1], x[1]}
 return *(*[]byte)(unsafe.Pointer(&h))
}
```

本地测试
将服务处理的核心逻辑，使用 go test 的 benchmark 加 pprof 来测试。建议上线前，就对整个业务逻辑的性能进行测试，提前优化瓶颈。

线上测试
一般 http 服务可以通过常见的测试工具进行压测，如 wrk，locust 等。taf 服务则需要我们自己编写一些测试脚本。同时，要注意的是，压测的目的是定位出服务的最佳性能，而不是盲目的高并发请求测试。因此，一般需要逐步提升并发请求数量，来定位出服务的最佳性能点。

优化方法
golang 自带的 json 解析性能较低，这里我们可以替换为github.com/json-iterator来提升性能

在 golang 中，遇到不需要解析的 json 数据，可以将其类型声明为json.RawMessage. 即，可以将上述 2 个方法优化为

逃逸分析及处理
go build -gcflags "-m -m" gateway/*.go

性能查看工具 pprof,trace 及压测工具 wrk 或其他压测工具的使用要比较了解。
代码逻辑层面的走读非常重要，要尽量避免无效逻辑。
对于 golang 自身库存在缺陷的，可以寻找第三方库或自己改造。
golang 版本尽量更新，这次的测试是在 golang1.12 下进行的。而 go1.13 甚至 go1.14 在很多地方进行了改进。比如 fmt.Sprintf，sync.Pool 等。替换成新版本应该能进一步提升性能。
本地 benchmark 结果不等于线上运行结果。尤其是在使用缓存来提高处理速度时，要考虑 GC 的影响。
传参数或返回值时，尽量按 golang 的设计哲学，少用指针，多用值对象，避免引起过多的变量逃逸，导致 GC 耗时暴涨。struct 的大小一般在 2K 以下的拷贝传值，比使用指针要快（可针对不同的机器压测，判断各自的阈值)。
值类型在满足需要的情况下，越小越好。能用 int8，就不要用 int64。
资源尽量复用,在 golang1.13 以上，可以考虑使用 sync.Pool 缓存会重复申请的内存或对象。或者自己使用并管理大块内存，用来存储小对象，避免 GC 影响（如本地缓存的场景)。

<https://mp.weixin.qq.com/s?__biz=MzAxMTA4Njc0OQ==&mid=2651438895&idx=1&sn=dbc9b3e775ae301c3ea6a9c9cf4ce912&chksm=80bb61ddb7cce8cb6230794cd656185961e29747f6fecce5d5c9f8770a7652a1dcb00edd3acb&mpshare=1&scene=24&srcid=&sharer_sharetime=1584837943386&sharer_shareid=29c7df185dfebeb5476e82189ac60d4d#rd>

<https://github.com/panjf2000/ants/blob/master/README_ZH.md>
<https://eddycjy.gitbook.io/golang/di-1-ke-za-tan/control-goroutine>
