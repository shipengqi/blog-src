---
title: Nodejs中的全局对象和全局变量
date: 2017-10-09 19:42:20
categories: ["Node.js"]
---

Node.js中的全局对象有哪些？
全局对象是指在所有模块中都是可以使用的对象，Node.js中，有一个全局命名空间对象global，process、console、Buffer等都是global的子对象，不需要require引用而直接使用。

<!-- more -->

1. 全局变量：__filename、__dirname
2. 计时器：setTimeout(cb, ms)、clearTimeout(t)、setInterval(cb, ms)、clearInterval(t)
3. 控制台对象：console
4. 进程对象：process
5. 二进制数据处理类: Buffer
6. 模块对象： module，模块导出对象：exports，模块加载对象：require

## 全局变量

### __filename
__filename 表示当前正在执行的脚本的文件名。
``` javascript
//test.js
console.log( __filename ); // C:\code\hubot-enterprise-bot\test.js
```

### __dirname
__dirname 表示当前执行脚本所在的目录。
``` javascript
//test.js
console.log( __dirname ); // C:\code\hubot-enterprise-bot
```

## 计时器

### setTimeout

setTimeout(fn, ms) 全局函数在指定的毫秒(ms)数后执行指定函数(fn)。
返回一个代表定时器的句柄值。
``` javascript
//test.js
function test(){
   console.log( "Hello");
}

// 两秒后执行test()
setTimeout(test, 2000); //Hello

```

### clearTimeout
clearTimeout( t ) 全局函数用于停止一个之前通过 setTimeout() 创建的定时器。 参数 t 是通过 setTimeout() 函数创建的定时器。
``` javascript
//test.js
function test(){
   console.log( "Hello");
}

// 两秒后执行test()
let t = setTimeout(test, 2000); //Hello
clearTimeout(t)
```

### setInterval clearInterval
setInterval(cb, ms) 全局函数在指定的毫秒(ms)数后执行指定函数(cb)。
返回一个代表定时器的句柄值。setInterval() 方法会不停地调用函数，直到 clearInterval() 被调用。

``` javascript
//test.js
function test(){
   console.log( "Hello");
}

// 两秒后执行test()
let t = setInterval(test, 2000);
//Hello
//Hello
//Hello
clearInterval(t)
```

## 全局对象

### console
console 用于向标准输出流（stdout）或标准错误流（stderr）输出字符。

|序号|描述|
|-|-|
|1|**console.log([data][, ...])、console.info([data][, ...])**：console.log()方法用于向stdout中打印一行，console.info()是其别名方法。log方法可接收多个参数，其格式化输出与util.format方法类似。|
|2|**console.error([data][, ...])、console.warn([data][, ...])** ：console.error()方法与console.log()方法类似，但会打印到stderr中。console.warn()是其别名方法。|
|3|**console.dir(obj[, options])**：console.dir()方法会调用util. inspect方法，将对象格式化后打印到stdout中，但此方法会忽略object上自定义的inspect()方法。|
|4|**console.time(label)、console.timeEnd(label)**：console.time()方法用于标记一个时间点，console.timeEnd()方法用于结束记时，并输出所用时间。这两个方法在调试程序，统计程序执行时长时很有用。|
|5|**	console.trace(message[, ...])**：console.trace()方法用于格式化错误信息及当前位置的栈跟踪信息，并向stderr中打印Trace。|
|6|**console.assert(value[, message][, ...])**：console.assert()方法与assert.ok()方法类似，用于断言表达式，但console.assert()方法会调util.format方法方法对提示信息进行格式化。|

``` javascript
console.log('a string: ', 'sss'); 	// a string:  sss
console.log('12%d45%d', 3, 6);		//123456
console.log('a string: ', 'sss'); 	// a string:  sss
console.log('12%d45%d', 3, 6);		//123456
console.dir(global, {showHidden:true, depth:3});
console.time('100-elements');
for (var i = 0; i < 100; i++) {
    console.log(i);
}
console.timeEnd('100-elements');
//100-elements: 9ms

console.trace('出错了');

//输出如下：
Trace: 出错了
    at Object.……

console.assert(1<0, '%d不小于%d', 1, 0);
//以上代码输出为
AssertionError: 1不小于0
  at Console.assert (console.js:102:23)
  ……
```

### process
它用于描述当前Node.js 进程状态的对象，提供了一个与操作系统的简单接口。

#### 事件
|序号|描述|
|-|-|
|1|**'exit'**事件会在进程退出时触发。'exit'事件的监听器可以用来检查进程退出的状态，在其回调函数中会有一个进程退出的状态码。有一点要注意，'exit'事件触发后事件循环将会停止，记时器等也会失效。|
|2|**'uncaughtException'**当进程异常退出时，会触发'uncaughtException'事件，当此引发此事件的异常一般并不明确，因此不建议使用，推荐使用domains模块进行异常处理。|
|3|**'beforeExit'**当 node 清空事件循环，并且没有其他安排时触发这个事件。通常来说，当没有进程安排时 node 退出，但是 'beforeExit' 的监听器可以异步调用，这样 node 就会继续执行。|
|4|**Signal 事件**信号相关事件会在进程接收到POSIX标准信号时触发。监听的事件名为POSIX信号名，如：SIGINT、SIGUSR1 等。|

``` javascript
process.on('exit', function(code) {
  // 进程退出后，其后的事件循环将会结束，计时器也不会被执行
  setTimeout(function() {
    console.log('This code will not run');
  }, 0);
  console.log('退出码是:', code);
});

//进程退出
process.exit();
//进程正常退出，其退出码为：0


//异常捕获
process.on('uncaughtException', function(exception) {
  console.log('捕获到的异常是:', exception);
});


//使用Control+C键，可以触发SIGINT信号
process.on('SIGINT', function() {
  console.log('收到SIGINT信号，按Control+D键可以退出进程');
});
```

#### 属性

##### process.stdout
process.stdout是一个指向标准输出流的可写流Writable Stream。console.log就是通过process.stdout实现的：
``` javascript
console.log = function(str) {
  process.stdout.write(str + '\n');
};
```
##### process.stderr
process.stderr是一个指向标准错误流的可写流Writable Stream。console.error就是通过process.stderr实现的。

##### process.stdin

process.stdin是一个指向标准输入流的可读流 Readable Stream，
process.stdin.pause()： 暂停标准输入流
process.stdin.resume()： 恢复标准输入流
``` javascript

//一个读取输入流的方法
function getFromStdin(cb){
  process.stdin.resume(); //标准输入流默认是暂停的，所以要先调用 process.stdin.resume() 来恢复接收
  process.stdin.setEncoding('utf8');

  process.stdin.on('data', function(chunk) {
     process.stdin.pause();
     cb(chunk);
  });
}

getFromStdin(function(reuslt){
  console.log("["+reuslt+"]");
});
```
##### process.argv

`process.argv` 属性返回一个数组，由命令行执行脚本时的各个参数组成。第一个参数是node，第二个参数是当前执行的.js文件名，之后是脚本文件的参数。
``` javascript
  // test.js
  console.log(process.argv);
```
执行`node test.js`，输出:
```
[ 'node',
  '/home/hubot-enterprise-bot/test.js' ]
```

##### process.execPath

`process.execPath`返回执行当前脚本的程序的绝对路径。例如：node test.js会返回，/usr/local/bin/node，：
``` javascript
  // test.js
  console.log(process.execPath);
```

##### process.execArgv

`process.execArgv`属性会返回Node的命令行参数数组。代码如下：
``` bash
$ node --harmony test.js --version
```
`process.execArgv`返回
```
['--harmony']
```
`process.argv`返回
```
['/usr/local/bin/node', 'script.js', '--version']
```

##### process.env

`env`返回一个对象，成员为当前 shell 的环境变量。

##### process.exitCode

`exitCode`进程退出时的代码，或process.exit(code)方法指定的退出码。

##### process.version

`version`会返回Node 的版本。

##### process.versions
`versions`会返回node 的版本和依赖。

##### process.config
`process.config`属性会返回Node编译时的配置信息，返回内容与运行./configure脚本生成的 "config.gypi"文件相同。

##### process.pid
process.pid返回当前进程的PID。

##### process.title
`title`返回'ps'中显示的进程名,默认值为"node"。

##### process.arch
`arch`返回当前CPU架构信息：'arm'、'ia32' 或者 'x64'。

##### process.platform
`platform`返回当前进程的运行平台系统：'linux','win32'


##### process.mainModule

类似`require.main`,返回指向启动脚本的模块：
``` javascript
console.log(process.mainModule);

//输出如下
Module {
  id: '.',
  exports: {},
  parent: null,
  filename: 'C:\\code\\hubot-enterprise-bot\\test.js',
  loaded: false,
  children: [],
  paths:
   [ 'C:\\code\\hubot-enterprise-bot\\node_modules',
     'C:\\code\\node_modules',
     'C:\\node_modules' ] }
```

#### 方法

##### abort()
`process.abort()`会导致Node解发一个abort事件并使node进程退出。

##### process.chdir(directory)、process.cwd()

process.chdir()用于改变当前工作进程的目录,切换目录失败会抛出异常。
process.cwd()返回进程当前的工作目录。示例如下：
``` javascript
console.log('当前目录：' + process.cwd());
process.chdir('./lib');
console.log('新目录：' + process.cwd());

//输出如下
当前目录：C:\code\hubot-enterprise-bot
新目录：C:\code\hubot-enterprise-bot\lib
```

##### process.exit([code])
process.exit()退出当前进程，接收一个退出状态的参数code,可选，默认为0。

#####　process.getgid()、process.setgid(id)
这两个方法只可以在POSIX平台使用。
`getgid()`获取进程的GID，`setgid(pid)`设置进程的GID，参数可以是一个数字ID或者群组名。

##### process.getuid()、process.setuid(id)
这两个方法只可以在POSIX平台使用。
`getuid()`获取进程的UID，setuid(id)设置进程的UID，参数可以是一个数字ID或者用户名。

##### process.getgroups()、process.setgroups(groups)
这两个方法只可以在POSIX平台使用。
`getgroups()`获取对当前进程有操作权限GID数组，`setgroups(groups)`设置对当前进程有操作权限GID数组，数组值可以是一个数字ID或者用户组名。

##### process.initgroups(user, extra_group)
这两个方法只可以在POSIX平台使用。
这个方法仅适用于POSIX标准的系统。process.initgroups()初始化group分组访问列表，参数可以是一个数字ID或者组名。

##### process.kill(pid[, signal])

`process.kill()`向指进程发送一个信号，需要注意的是kill方法不仅是用来杀死指定进程的，可以是任何POSIX标准信息,比如 'SIGINT' 或 'SIGHUP',默认是'SIGTERM'：
``` javascript
process.stdin.resume();
process.on('SIGTERM', function() {
  console.log('收到了 SIGTERM 信号');
});

process.kill(process.pid, 'SIGTERM');
```

##### process.memoryUsage()

process.memoryUsage()返回node内存使用情况。

##### process.nextTick(callback)
`nextTick`会将callback中的回调函数延迟到下一次的事件循环中。
``` javascript
console.log('开始');
process.nextTick(function() {
  console.log('nextTick 回调');
});
console.log('已设定');

//输出如下
开始
已设定
nextTick 回调
```

##### process.umask([mask])
`umask()`设置或读取进程文件的权限掩码，子进程从父进程中继承这个掩码。如果设定了参数 mask 那么返回旧的掩码，否则返回当前的掩码。示例如下：
``` javascript
var oldmask, newmask = 0022;

oldmask = process.umask(newmask);
console.log('原掩码: ' + oldmask.toString(8) +
'\n新掩码: ' + newmask.toString(8));
```

##### process.hrtime()

`hrtime()`返回当前进程的高精度时间：
``` javascript
setTimeout(function(){
	console.log(process.uptime());   //1.367
}, 1000)
```
##### process.uptime()

`uptime()`返回Node进程已运行的秒数，返回形式为[秒，毫秒]数组。它是相对于在过去的任意时间，与日期无关，因此不受时钟漂移的影响。
主要用途是可以通过精确的时间间隔，来衡量程序的性能。你可以将前一个 process.uptime() 的结果传递给当前的 process.uptime()函数，
结果会返回时间差，用来比较时间间隔：
``` javascript
let uptime1 = process.uptime();

setTimeout(function() {
  let uptime2 = process.uptime();

  console.log(`uptime1: ${uptime1}`);
  console.log(`uptime2: ${uptime2}`)

}, 1000);
```
### Buffer
JavaScript没有二进制数据类型，但在处理像TCP流或文件流时，必须使用到二进制数据，Node.js提供了Buffer类，可以让 Node.js 处理二进制数据。

#### 创建buffer
``` javascript
var buf = new Buffer(1024); //创建长度为1024字节的缓冲区
var buf = new Buffer([10, 20, 30, 40, 50, 60]);  //通过给定的数组创建
var buf = new Buffer("www.shipengqi.top", "utf-8"); //默认使用UTF-8格式编码，编码格式包括：ascii、utf8、utf16le(ucs2)、base64、binary、hex
```

#### 读写buffer

``` javascript
buf.write(string[, offset[, length]][, encoding])
```
- string: 写入缓冲区的字符串。
- offset: 缓冲区开始写入的索引值，默认为 0 。
- length: 写入的字节数，默认为 buffer.length
- encoding: 使用的编码。默认为 'utf8' 。
返回实际写入的大小。如果 buffer 空间不足， 则只会写入部分字符串。

``` javascript
buf.toString([encoding[, start[, end]]])
```
- encoding: 使用的编码。默认为 'utf8' 。
- start: 指定开始读取的索引位置，默认为 0。
- end: 结束位置，默认为缓冲区的末尾。
返回指定编码字符串。

``` javascript
var buf = new Buffer(1024);
var length = buf.write("www.shipengqi.top");

console.log("Write length: "+  length);
buf[3]=109;      //设置第4位的数据


console.log(buf[3]); //获取第4位的数据
console.log(buf.toString()); //读取缓冲区数据
```

#### 解码、转码

``` javascript
//buffer转换为base64格式字符串
var buffer = new Buffer('Hello World');
console.log(buffer.toString('base64'));  //SGVsbG8gV29ybGQ=

//base64编码的字符串，转换为UTF-8编码
var base64String = 'SGVsbG8gV29ybGQ=';
var buffer = new Buffer(base64String, 'base64');
var utf8String = buffer.toString('utf8');
console.log(utf8String); //Hello World
```

#### 合并、复制、裁剪

``` javascript
Buffer.concat(list[, totalLength])
```
- list: 用于合并的 Buffer 对象数组列表。
- totalLength: 指定合并后Buffer对象的总长度0。

返回多个成员合并的新 Buffer 对象。


``` javascript
buf.copy(targetBuffer[, targetStart[, sourceStart[, sourceEnd]]])
```
- targetBuffer: 要拷贝的 Buffer 对象。
- targetStart: 数字, 可选, 默认: 0
- sourceStart: 数字, 可选, 默认: 0
- sourceEnd: 数字, 可选, 默认: buffer.length

无返回值。

``` javascript
buf.slice([start[, end]])
```
- start: 起始位置, 可选, 默认: 0
- end: 结束位置, 可选, 默认: buffer.length

缓冲区切分并没有分配新的内存，它和旧缓冲区指向同一块内存，只是引用了父缓冲区不同的起始/结束位置。修改父缓冲区重合部分的数据，修改也会影响子缓冲区。
父缓冲区操作结束后，子缓冲区还存在，所以内存仍然没有释放，使用不当会造成内存泄漏。所以使用`copy`方法代替`slice`可以避免内存泄漏。
``` javascript
//合并
var buf1 = new Buffer('hello');
var buf2 = new Buffer(' world');
var buf3 = Buffer.concat([buf1,buf2]);
console.log(buf3.toString()); //hello world
//裁剪
var longBuffer = new Buffer('hello world');
var smallBuffer = longBuffer.slice(6, 11);
console.log(smallBuffer.toString()); //world

//拷贝
var buf = new Buffer('hello world');
var newBuf = new Buffer(3);
buf.copy(newBuf);
console.log(newBuf.toString());
```

### 模块对象
module，模块导出对象：exports，模块加载对象：require
#### module
``` javascript
console.log('module.id: ', module.id);
console.log('module.exports: ', module.exports);
console.log('module.parent: ', module.parent);
console.log('module.filename: ', module.filename);
console.log('module.loaded: ', module.loaded);
console.log('module.children: ', module.children);
console.log('module.paths: ', module.paths);
//输出
module.id:  .
module.exports:  {}
module.parent:  null
module.filename:  C:\code\hubot-enterprise-bot\test.js
module.loaded:  false
module.children:  []
module.paths:  [ 'C:\\code\\hubot-enterprise-bot\\node_modules',
  'C:\\code\\node_modules',
  'C:\\node_modules' ]
```
如果没有父模块，直接调用当前模块，`parent` 属性就是 `null`，`id` 属性就是一个`.`。`filename` 属性是模块的绝对路径，`path` 属性是一个数组，包含了模块可能的位置。另外，输出这些内容时，模块还没有全部加载，所以 loaded 属性为 false 。

module.require(id)方法提供类似全局对象require(id)方式的模块加载,只是简单的模块加载。
`module.children`指向这个模块引入的所有模块对象数组。
`module.exports`导出模块文件中方法或对象。
#### exports
`exports`对象其实就是`module.exports`对象的引用:
``` javascript
global.exports = self.exports;
```

#### require
1. require()
用于加载模块:
``` javascript
var express = require('express');
```
2. require.resolve()
返回解析过的模块文件路径：
``` javascript
console.log(require.resolve('./test.js')); //C:\code\hubot-enterprise-bot\test.js
console.log(require.resolve('http'));    //http
```
3. require.cache
模块的加载机制，在首次加载模块时将会被缓存到require.cache中。删除该对象的键值，下次调用require时会重新加载相应模块:
``` javascript
delete require.cache[require.resolve('./test.js')];
```

### 自定义全局对象

Node.js中的`global`对象是可读写的，可以自定义对象到`global`，通过全局访问。
``` javascript
//test.js
global.hostName = 'www.shipengqi.top';

//demo.js
console.log(hostName) //'www.shipengqi.top'
```

应用场景：配置文件、国际化/本地化资源等，将其添加到全局对象，使用会非常方便。