---
title: NodeJs 命令行实现
date: 2017-09-18 20:27:28
categories: ["NodeJs"]
---

介绍三个实现nodejs命令行的模块
<!-- more -->
### yargs
#### 简单模式
只需要引入yargs，就能读取命令行参数，不需要写任何的配置
``` javascript
#!/usr/bin/env node
var argv = require('yargs').argv;

console.log('hello ', argv.name);
```
``` bash
$ hello --name=tom
hello tom

$ hello --name tom
hello tom
```
简单模式还能读取短变量如-x 4相当于argv.x = 4

简单模式还能读取布尔类型-s相当于argv.s = true

简单模式还能读取非-开始的变量，这种类型的变量保存在argv._数组里面

#### count 统计变量出现的次数
``` javascript
var argv = require('yargs')
    .count('num')
    .alias('n', 'num')
    .argv;
```
统计num参数出现的次数，缩写-n也会统计进去
``` bash
$ node count.js -n
$ node count.js -nn
$ node count.js -n --num

```

#### demand default describe

``` javascript
var argv = require('yargs')
  .demand(['n']) //是否必选
  .default({n: 'tom'}) //默认值
  .describe({n: 'your name'}) //提示
  .argv;
```
n 参数不可省略，默认值为 tom，并给出一行提示

#### options 将所有配置写进一个对象
``` javascript
var argv = require('yargs')
  .option('n', {
    alias : 'name',
    demand: true,
    default: 'tom',
    describe: 'your name',
    type: 'string'
  })
  .argv;
```
#### boolean 方法指定参数返回布尔值
``` javascript
var argv = require('yargs')
  .boolean(['l'])
  .argv;
```
#### 帮助信息
* usage：用法格式
* example：提供例子
* help：显示帮助信息
* epilog：出现在帮助信息的结尾

``` javascript
var argv = require('yargs')
  .option('f', {
    alias : 'name',
    demand: true,
    default: 'tom',
    describe: 'your name',
    type: 'string'
  })
  .usage('Usage: hello [options]')
  .example('hello -n tom', 'say hello to Tom')
  .help('h')
  .alias('h', 'help')
  .epilog('epilog 2017')
  .argv;
```
结果
``` bash
$ hello -h

Usage: hello [options]

Options:
  -f, --name  your name [string] [required] [default: "tom"]
  -h, --help  Show help [boolean]

Examples:
  hello -n tom  say hello to Tom

epilog 2017
```
#### 设置子命令 command()
``` javascript
.command(cmd, desc, [builder], [handler])
.command(module)
.command(cmd, desc, [module])

//.command(cmd, desc, [builder], [handler])
yargs
  .command(
    'get',
    'get incident',
    function (yargs) {
      return yargs.option('u', {
        alias: 'url',
        describe: 'the url get incident'
      })
    },
    function (argv) {
      console.log(argv.url)
    }
  )
  .help()
  .argv

//.command(module) test.js
exports.command = 'get'

exports.describe = 'get incident'

exports.builder = {
  name: {
    default: 'tom'
  }
}

exports.handler = function (argv) {
  //console.log(argv)
}


yargs.command(require('test'))
  .help()
  .argv
```
#### commandDir
如果有大量的命令都使用上面的command(module)来开发的话，这些模块都有相同的结构，yargs提供了.commandDir接口,简化这些命令的引入过程，把这个过程自动化.
``` javascript
require('yargs')
  .commandDir('commands')
  .demand(1)
  .help()
  .locale('en')
  .showHelpOnFail(true, 'Specify --help for available options')
  .argv
```
> commandDir默认加载目录下第一级的文件，递归加载: commandDir('pit', {recurse: true})

作者：蓝猫163
链接：http://www.jianshu.com/p/fef668d61085
來源：简书
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

### commander
commander是从Ruby下同名项目移植过来的
#### commander特性
* 自记录代码
* 自动生成 help
* 合并短参数（“ABC”==“-A-B-C”）
* 默认选项
* 强制选项​​
* 命令解析
* 提示符

#### example
``` javascript
\\example test.js file:
var commander = require('commander');

commander
    .version('1.0.0')
    .usage('[options] [value ...]')
    .option('-l, --langu', 'langueage')
    .parse(process.argv);

if (commander.langu == 'zh-cn') {
    console.log('Chinese website!');
}else if(commander.langu == 'en') {
    console.log('English website!');
}

```
启动test.js 时,接受一个 -l 的参数
``` bash
$node test.js -l en
```

#### commander API
* Option(): 初始化自定义参数对象，设置“关键字”和“描述”
* Command(): 初始化命令行参数对象，直接获得命令行输入
* Command#command(): 定义一个命令名字
* Command#action(): 注册一个callback函数
* Command#option(): 定义参数，需要设置“关键字”和“描述”，关键字包括“简写”和“全写”两部分，以”,”,”|”,”空格”做分隔。
* Command#parse(): 解析命令行参数argv
* Command#description(): 设置description值
* Command#usage(): 设置usage值
* Command#version(): 指定当前应用程序的一个版本号

#### commander 自定义帮助信息
``` javascript
commander.on('help', function() {
    console.log('       # website langueage ')
    console.log('       $ ./app.js -l \"a string zh-cn or en \" ')
    console.log('')
});
```
### argparse
``` javascript
\\example test.js file:

import {ArgumentParser} from 'argparse';

const parser = new ArgumentParser({
    version: require("../package.json").version,
    addHelp: true,
    description: "Storage Server"
});

parser.addArgument(["-rpc","--rpcPort"], {
    required: false,
    help: "rpc port",
    dest: "rpcPort"
});

parser.addArgument("--isLocal", {
    dest: "isLocal",
    help: "is publish from office network",
    defaultValue: false,
    action: "storeTrue"
});

const argument = parser.parseArgs();

console.log(argument.rpcPort)
console.dir(args);
```
``` bash
$ ./test.js -h
usage: example.js [-h] [-rpc] [--isLocal]

Storage Server

Optional arguments:
  -h, --help        Show this help message and exit.
  -v, --version     Show program's version number and exit.
  -rpc, --rpcPort   rpc port
 --isLocal          is publish from office network
```


