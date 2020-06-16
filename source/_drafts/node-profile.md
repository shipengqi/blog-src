---
title: Node 如何做性能分析
tags:
---

Node.js 的性能分析工具 [v8-profiler](https://github.com/node-inspector/v8-profiler) 可以采集性能分析样本。

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

## 查看分析报告

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

右侧展示了函数的调用栈，和执行时间。

上图就展示了程序运行到 21s 打 21.1s 秒时，函数调用栈中，每个调用的执行时间。

选中某个片段，点击左上角的 `+` 可以放大图表。


GC 带来的问题
虽然上面介绍中现代语言的 GC 机制解放了程序员间接提升了开发效率，但是万事万物都存在利弊，底层的引擎引入 GC 后程序员无需再关注对象何时释放的问题，那么相对来说程序员也就没办法实现对自己编写的程序的精准控制，它带来两大问题：

代码编写问题引发的内存泄漏
程序执行的性能降低

**Allow taking heap snapshots** （分析内存泄露等问题）
