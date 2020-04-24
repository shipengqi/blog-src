---
title: Node.js 为什么不擅长 CPU 密集型业务？
tags:
---

Node.js 是单线程的，

## IO 密集型 和 CPU 密集型
## 异步和非阻塞 IO
## Node.js Event Loop
首先，

https://blog.csdn.net/shmnh/article/details/31972071
https://www.ibm.com/developerworks/cn/opensource/os-cn-nodejscpu/

经常看到nodejs不适用于CPU密集型计算的场景，那我们在nodejs中也经常使用异步编程async来执行耗时的查询操作，查询完，再返回就可以了。是
不是异步编程来解决CPU密集型计算的问题？

结论：
异步编程是用来解决IO的。
js是单线程，cpu密集型计算还是会耗时。
