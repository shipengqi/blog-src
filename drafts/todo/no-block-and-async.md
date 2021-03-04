---
title: 非阻塞 I/O 和 异步 I/O
tags:
---

## 阻塞 I/O

## 非阻塞 I/O

### I/O 多路复用

#### select

#### epoll

Linux 下效率最高的 IO 时间通知机制，在进入轮询的时候如果没有检查到 IO 事件，将会进行休眠，直到事件发生将它唤醒。
利用了事件通知，执行回调的方式，而不是遍历查询，不会浪费 CPU。

## 异步 I/O

- <https://segmentfault.com/a/1190000003063859>
- <https://www.cnblogs.com/lojunren/p/3856290.html>
- <https://www.zhihu.com/question/27734728>
- <https://zhuanlan.zhihu.com/p/63179839>
- <https://juejin.im/book/5afc2e5f6fb9a07a9b362527/section/5afc3625f265da0b9c10d2a7>
- <https://www.jianshu.com/p/2e56b528c169>
- Node.js 深入浅出 异步 I/O
- <https://draveness.me/redis-io-multiplexing/>
