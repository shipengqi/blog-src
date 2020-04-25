---
title: Node.js 为什么不擅长 CPU 密集型业务？
tags:
---

Node.js 是单线程的（这里的单线程仅仅只是 javascript 执行在单线程中），单线程最大的好处就是，不需要关心多个线程间的状态同步，也避
免了线程上下文切换带来的开销。

但是 Node 的单线程也有自身的弱点：
1. 无法利用多核 CPU。
2. 一旦出现异常，可能导致整个进程退出。
3. 碰到大量计算的场景，CPU 会被长时间占用，导致事件循环阻塞。

## IO 密集型 和 CPU 密集型
Node 擅长 IO 密集型的应用场景，是因为它的事件循环的机制。  
## 异步 IO 和 非阻塞 IO
## Node Event Loop
首先，

https://blog.csdn.net/shmnh/article/details/31972071
https://www.ibm.com/developerworks/cn/opensource/os-cn-nodejscpu/

经常看到nodejs不适用于CPU密集型计算的场景，那我们在nodejs中也经常使用异步编程async来执行耗时的查询操作，查询完，再返回就可以了。是
不是异步编程来解决CPU密集型计算的问题？

结论：
异步编程是用来解决IO的。
js是单线程，cpu密集型计算还是会耗时。
