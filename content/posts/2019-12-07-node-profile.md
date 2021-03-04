---
title: Node 如何做性能分析
date: 2019-12-07 12:57:31
categories: ["Node.js"]
---

Node.js 的性能分析工具 [v8-profiler](https://github.com/node-inspector/v8-profiler) 可以采集性能分析样本。

<!--more-->

## 性能分析工具

### v8-profiler

```javascript
const v8Profiler = require('v8-profiler');
const title = 'test';
v8Profiler.startProfiling(title, true);
setTimeout(() => {
    const profiler = v8Profiler.stopProfiling(title);
    profiler.delete();
    console.log(profiler);
}, 5000);
```

上面的示例，会采集运行 5s 内的分析样本。

v8-profiler 貌似已经不再维护了，可以尝试 [v8-profiler-next](https://github.com/hyj1991/v8-profiler-next)。

v8-profiler 生成的 profile 文件如何分析可以看 [这里](https://github.com/aliyun-node/Node.js-Troubleshooting-Guide/blob/master/0x03_%E5%B7%A5%E5%85%B7%E7%AF%87_%E6%AD%A3%E7%A1%AE%E6%89%93%E5%BC%80%20Chrome%20devtools.md)。

### webstrom v8 profiling

也可以使用 webstrom 的 v8 profiling：

选择 **Edit Configuration**，切换到 **V8 Profiling**，选中 **Record CPU profiling info** ，然后运行代码，就可以了。

![](/images/node-profile/webstrom-v8-profile.png)

**Log folder** 可以指定生成分析样本文件的目录，样本文件的命名格式是 `isolate-<session number>`。

我使用的就是 webstrom 的 v8 profiling。

## 准备工作

示例：

```javascript
const App = require('..');
const fs = require('fs');

function run() {
  let app = new App();
  app.bindAny('age', 18);
  app.use(($age, $ctx, $next) => {
    console.log('app middleware1');
    console.log('age' + $age);
    $next();
  });
  app.use(($ctx, $age, $next, $address) => {
    console.log('app middleware2');
    console.log('age' + $age);
    console.log('address', $address);
    $next();
  });
  app.get('/users/:name', ($age, $ctx, $next, $address) => {
    console.log('users/name middleware1');
    console.log($ctx.params.name);
    console.log('age' + $age);
    console.log('address', $address);
    $ctx.params.id = 'user1';
    $next();
  }, async ($age, $ctx, $next, $address) => {
    console.log('users/name middleware2');
    console.log($ctx.params.name, $ctx.params.id);
    console.log('age' + $age);
    console.log('address', $address);
    await read();
    $ctx.body = 'hello, ' + $ctx.path;
  });
  app.get('/users/', ($age, $ctx, $next, $address) => {
    console.log('users middleware1');
    console.log('age' + $age);
    console.log('address', $address);
    $ctx.params.id = 'user1';
    $next();
  }, ($age, $ctx, $next, $address) => {
    console.log('users middleware2');
    console.log($ctx.params.id);
    console.log('age' + $age);
    $ctx.body = 'hello, ' + $ctx.path;
  });
  app.use(($address, $ctx, $next, $age, $getAddress) => {
    console.log('app middleware3');
    console.log('age' + $age);
    console.log('address', $address);
    console.log('getAddress', $getAddress);
    $next();
  });
  app.bindAny('address', 'shanghai');
  app.bindFunction('getAddress', $address => {
    return $address;
  });
  app.listen(8080);
}

function read() {
  return new Promise((resolve, reject) => {
    fs.writeFile('test.log', `test`, {flag:'a',encoding:'utf-8',mode:'0666'},() => {
      resolve();
    })
  })
}
run();
````

使用 AB 进行压力测试：

```bash
[root@SGDLITVM0905 ~]# ab -n 10000 -c 100 http://10.5.41.247:8080/users/pooky
This is ApacheBench, Version 2.3 <$Revision: 1430300 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 10.5.41.247 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        10.5.41.247
Server Port:            8080

Document Path:          /users/pooky
Document Length:        9 bytes

Concurrency Level:      100
Time taken for tests:   16.801 seconds
Complete requests:      10000
Failed requests:        0
Write errors:           0
Non-2xx responses:      10000
Total transferred:      1510000 bytes
HTML transferred:       90000 bytes
Requests per second:    595.19 [#/sec] (mean)
Time per request:       168.014 [ms] (mean)
Time per request:       1.680 [ms] (mean, across all concurrent requests)
Transfer rate:          87.77 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    4   2.4      3      21
Processing:    38  163  54.3    151     465
Waiting:       10  135  45.4    125     373
Total:         39  167  55.0    154     474

Percentage of the requests served within a certain time (ms)
  50%    154
  66%    163
  75%    175
  80%    189
  90%    230
  95%    299
  98%    338
  99%    370
 100%    474 (longest request)
```

### 查看分析报告

程序停止运行之后，可以得到如下结果：

![](/images/node-profile/v8-profile-top-calls.png)

**Top Calls** 按 Self 指标（函数本身代码段调用次数和执行时间）降序列出所有函数，可以看出 `routergroup` 的 `dispatch` 方法消耗调用次数最多，占用 CPU 时间最长。

Total 指标表示**函数本身和其调用地其它函数总共的执行时间**

`Bottom-UP` 会从外到里的列出函数的整个调用栈：

![](/images/node-profile/v8-profile-bottom-up.png)

`Flame Chart` 可以帮助查看程序执行时暂停的位置，是什么引起的暂停。

![](/images/node-profile/v8-profile-flame-chart.png)

最上方的是 timeline，可以随意选择时间段，来查看该时间段程序的执行片段。

火焰图区域展示了 GC ，引擎，外部调用和程序本身的调用。这些调用对应的颜色在火焰图的上方有标注。

右侧展示了函数的调用栈（从下到上），和执行时间。

选中某个片段，点击左上角的 `+` 可以放大图表。

## 内存分析工具

### heapdump

内存分析工具可以使用 [heapdump](https://github.com/bnoordhuis/node-heapdump):

```javascipt
const heapdump = require('heapdump');
heapdump.writeSnapshot('./test' + '.heapsnapshot');
```

当前目录会生成内存快照 `test.heapsnapshot` 文件，后缀必须为 `.heapsnapshot` ，否则 Chrome devtools 不识别。

Chrome devtools 如何分析可以看 [这里](https://github.com/aliyun-node/Node.js-Troubleshooting-Guide/blob/master/0x03_%E5%B7%A5%E5%85%B7%E7%AF%87_%E6%AD%A3%E7%A1%AE%E6%89%93%E5%BC%80%20Chrome%20devtools.md)。

### webstrom heap snapshot

和 CPU profiling 一样，进入 **Edit Configuration**，选中 **Allow Taking heap snapshot**。

运行程序，点击 **Take heap snapshot**：

![](/images/node-profile/v8-profile-take-heap-snapshots.png)

webstrom 就会收集内存的 profile 信息，并保存到指定文件。

如果已经有 `.heapsnapshot` 文件，也可以通过 `Tools | V8 Profiling - Analyze V8 Heap Snapshot` 来查看。

### 内存分析

![](/images/node-profile/v8-heap-profile.png)

**Summary** 视图显示应用程序中按类型分组的对象。每种类型的对象数量、它们的大小以及它们占用的内存百分比。

- Constructor，表示所有通过该构造函数生成的对象
- Distance， 对象到达 GC 根的最短距离
- Shallow Size，对象本身占用的内存，也就是对象自身被创建时，在 V8 堆上分配的大小
- Retained Size，占用总内存，包括引用的对象所占用的内存，GC 后 V8 堆能够释放出的空间大小

**支配树**

![](/images/node-profile/object-tree.png)

1 为根节点（GC 根），如果要回收对象 5 ，也就是使对象 5 从 GC 根不可达，仅仅去掉对象 4 或者对象 3 对于对象 5 的引用是不够的，只有去掉对象 2 才能将对象 5 回收，所以在上面这个图中，对象 5 的直接支配者是对象 2。

上面图中对象 3、对象 7 和对象 8 没有任何直接支配对象，因此其 Retained Size 等于其 Shallow Size。

**GC 根的 Retained Size 等于堆上所有从此根出发可达对象的 Shallow Size 之和**。

按照上面的介绍，**Retained Size 非常大的对象，就可能是泄露的对象**。

**Biggest Objects** 视图显示按对象大小排序，消耗内存最多的对象。
**Containment view** 视图可以用来探测堆内容，可以查看 function 内部，观察 VM 内部对象，可以看到底层的内存使用情况。

实际项目中，我们应该对多个内存快照进行比对分析，如果某个对象占用的内存一直持续增加，那么就又可能是泄露了。

### 其他工具

- [node-memwatch](https://github.com/airbnb/node-memwatch)
- [node-clinic](https://github.com/nearform/node-clinic)

## 线上性能分析

上面的方式适合在本地做性能分析和优化，线上项目如果要分析性能问题，就要提前引入 v8-profiler 和 heapdump，使用不太方便。而且除了 CPU/Memory 的问题
，可能还会遇到其他问题。线上项目推荐使用 [阿里的 Node.js 性能平台](https://cn.aliyun.com/product/nodejs)。如何使用可以看[这里](https://github.com/aliyun-node/Node.js-Troubleshooting-Guide/blob/master/0x04_%E5%B7%A5%E5%85%B7%E7%AF%87_Node.js%20%E6%80%A7%E8%83%BD%E5%B9%B3%E5%8F%B0%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97.md)。

## 参看链接

- <https://developers.google.com/web/tools/chrome-devtools/evaluate-performance/reference>
- <https://developers.google.com/web/tools/chrome-devtools/memory-problems?utm_campaign=2016q3&utm_medium=redirect&utm_source=dcc#retained-size>
- <https://github.com/aliyun-node/Node.js-Troubleshooting-Guide/blob/master/0x03_%E5%B7%A5%E5%85%B7%E7%AF%87_%E6%AD%A3%E7%A1%AE%E6%89%93%E5%BC%80%20Chrome%20devtools.md>
- <https://github.com/aliyun-node/Node.js-Troubleshooting-Guide/blob/master/0x04_%E5%B7%A5%E5%85%B7%E7%AF%87_Node.js%20%E6%80%A7%E8%83%BD%E5%B9%B3%E5%8F%B0%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97.md>
- <https://juejin.im/post/5c6844b3e51d4520f0175839>
