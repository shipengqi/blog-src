---
title: Node.js 命令行实现
date: 2017-09-18 20:27:28
categories: ["Node.js"]
---

使用 Node.js 实现命令行。
<!-- more -->
## 命令行参数处理
### yargs
#### 简单模式
只需要引入 yargs，就能读取命令行参数，不需要写任何的配置
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
简单模式还能读取短变量如 `-x 4` 相当于 `argv.x = 4`

简单模式还能读取布尔类型 `-s` 相当于 `argv.s = true`

简单模式还能读取非 `-` 开始的变量，这种类型的变量保存在 `argv._` 数组里面

#### count 统计变量出现的次数
``` javascript
var argv = require('yargs')
    .count('num')
    .alias('n', 'num')
    .argv;
```
统计 `num` 参数出现的次数，缩写 `-n` 也会统计进去
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
`n` 参数不可省略，默认值为 `tom`，并给出一行提示

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
#### 设置子命令 `command()`
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
如果有大量的命令都使用上面的 `command(module)` 来开发的话，这些模块都有相同的结构，yargs 提供了 `commandDir` 接口,简化这些命令的引入过程，把这个过程自动化.
``` javascript
require('yargs')
  .commandDir('commands')
  .demand(1)
  .help()
  .locale('en')
  .showHelpOnFail(true, 'Specify --help for available options')
  .argv
```
> `commandDir` 默认加载目录下第一级的文件，递归加载: `commandDir('pit', {recurse: true})`

### commander
`commander` 是从 Ruby 下同名项目移植过来的，[官方文档](http://tj.github.io/commander.js/)。
#### commander 特性
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
启动 test.js 时,接受一个 `-l` 的参数
``` bash
$node test.js -l en
```

#### commander API
* `Option()`: 初始化自定义参数对象，设置“关键字”和“描述”
* `Command()`: 初始化命令行参数对象，直接获得命令行输入
* `Command#command()`: 定义一个命令名字
* `Command#action()`: 注册一个 `callback` 函数
* `Command#option()`: 定义参数，需要设置“关键字”和“描述”，关键字包括“简写”和“全写”两部分，以`,`，`|`，`空格` 做分隔。
* `Command#parse()`: 解析命令行参数 `argv`
* `Command#description()`: 设置 `description` 值
* `Command#usage()`: 设置 `usage` 值
* `Command#version()`: 指定当前应用程序的一个版本号

#### 参数解析
1.使用 `option()` 方法自定义参数；
2.使用 `parse()` 方法解析用户从命令行输入的参数。

上面的例子中： `parse()` 方法对 `option()` 方法定义的参数进行赋值，然后将剩下的参数（未定义的参数）赋值给 commander 对象的 `args` 属性
(`program.args`)，`program.args`是一个数组。

#### `command()`、`description()` 和 `action()`
`command()`方法有点复杂，最常用的方法是和 `action()` 联合起来用：

```js
var program = require('commander');

program
    .version('0.0.1')
    .option('-C, --chdir <path>', 'change the working directory')
    .option('-c, --config <path>', 'set config path. defaults to ./deploy.conf')
    .option('-T, --no-tests', 'ignore test hook')


program
    .command('setup') // 定义命令
    .description('run remote setup commands') // 对命令参数的描述信息
    .action(function() { // setup命令触发时调用
        console.log('setup');
    });

program
    .command('exec <cmd>') // 定义命令，参数可以用 <> 或 [] 修饰
    .description('run the given remote command')
    // exec 触发时调用，参数和定义的参数顺序一致
    .action(function(cmd) {
        console.log('exec "%s"', cmd);
    });

program
    .command('init') // 定义命令，参数可以用 <> 或 [] 修饰
    .description('run the given remote command')
    .option('-y, --yes', 'without prompt')
    // options 是 init 命令的参数对象、是 action 回调方法的最后一个参数
    .action(function(options) {
        console.log('init param "%s"',options.yes );
    });

program.parse(process.argv);
```

##### 可变参数
一个命令的最后一个参数可以是可变参数, 并且只能是最后一个参数。可变参数需要在参数名后面追加 `...`：
```js
var program = require('commander');

program
    .version('0.0.1')
    .command('rmdir <dir> [otherDirs...]')
    .action(function(dir, otherDirs) {
        console.log('rmdir %s', dir);
        if (otherDirs) {
           //otherDirs是一个数组
            otherDirs.forEach(function(oDir) {
                console.log('rmdir %s', oDir);
            });
        }
    });

program.parse(process.argv);
```

#### commander 帮助信息
默认情况下，commander 会根据 `option()` 方法的参数为你帮你实现 `--help` 参数，当用户在命令行使用 `-h` 或 `--help` 参数时，将自动打印出帮助信息。
也支持自定义帮助信息：

``` javascript
commander.on('help', function() { // 自定义帮助信息
    console.log('       # website langueage ')
    console.log('       $ ./app.js -l \"a string zh-cn or en \" ')
    console.log('')
});

# or
commander.on('--help', function(){ // 自定义帮助信息
  console.log('  Examples:');
  console.log('');
  console.log('    $ custom-help --help');
  console.log('    $ custom-help -h');
  console.log('');
});
```

##### 主动打印帮助信息
两种情况：
1. 打印帮助信息，然后等待用户继续输入信息，不结束当前进程—— `program.outputHelp()`
2. 打印帮助信息，并立即结束当前进程—— `program.help()`

`.outputHelp()` 方法和 `.help()` 方法都可以带一个参数——一个回调方法，打印信息在显示到命令行之前会先传入这个方法，你可以在方法里面做必要的信息处理，比如改变文本颜色。
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

## shell.js
`shelljs` 模块重新包装了 `child_process`,调用系统命令更加简单。[官方文档](http://documentup.com/shelljs/shelljs)

### 安装
```sh
npm install shelljs --save
```

### 使用
`shelljs` 绝大部分命令都是对文件和文件夹的操作。看个例子：
```js
var shell = require('shelljs');

// 判定 git 命令是否可用
if (!shell.which('git')) {
	// 向命令行打印git命令不可用的提示信息
    shell.echo('Sorry, this script requires git');
    // 退出当前进程
    shell.exit(1);
}

// 先删除 'out/Release' 目录
shell.rm('-rf', 'out/Release');
// 拷贝文件到 'out/Release' 目录
shell.cp('-R', 'stuff/', 'out/Release');

// 切换当前工作目录到 'lib'
shell.cd('lib');
// shell.ls('*.js') 返回值是一个包含所有 js 文件路径的数组
shell.ls('*.js').forEach(function(file) {//遍历数组
	// sed 命令用于文件内容的替换，这里是对每个文件都执行如下 3 步操作，更改版本信息
    shell.sed('-i', 'BUILD_VERSION', 'v0.1.2', file);
    shell.sed('-i', /^.*REMOVE_THIS_LINE.*$/, '', file);
    shell.sed('-i', /.*REPLACE_LINE_WITH_MACRO.*\n/, shell.cat('macro.js'), file);
});
// 切换当前工作目录到上一层
shell.cd('..');

// 同步执行 git 命令提交代码
if (shell.exec('git commit -am "Auto-commit"').code !== 0) {
    shell.echo('Error: Git commit failed');
    shell.exit(1);
}
```
上面的例子展示了一个可发布版本提交到 `git` 仓库的过程。

### exec
- exec(command [, options] [, callback])
  - `command <String>`: 要在命令行执行的完整命令
  - `options <Object>`: 可选参数，`JSON` 对象
    - `async`: 异步执行.如果你提供了回调方法，这个值就一定为 `true`，无论你怎么设置
    - `silent`: 打印信息不输出到命令控制台
    - Node.js 的 `child_process.exec()` 方法的其他参数都可以用
  - `callback:<Function>`: 当进程终止时调用，并带上输出。
    - `error <Error>`
    - `stdout <String> | <Buffer>`
    - `stderr <String> | <Buffer>`
  返回值：同步模式下，将返回一个 `ShellString`（shelljs v0.6.xf 返回一个形如 `{ code:..., stdout:... , stderr:... }` 的对象；
  异步模式下，将返回一个 `child_process` 的对象

> `exec()`同步方法的实现会占用大量 `CPU`，所以**建议使用异步模式**。

例：
```js
var version = exec('node --version', {silent:true}).stdout;

var child = exec('some_long_running_process', {async:true});
child.stdout.on('data', function(data) {
  /* ... do something with data ... */
});

exec('some_long_running_process', function(code, stdout, stderr) {
  console.log('Exit code:', code);
  console.log('Program output:', stdout);
  console.log('Program stderr:', stderr);
});
```

## 命令行交互
命令行交互可以使用 [prompt](https://github.com/flatiron/prompt) 实现。

```js
const prompt = require('prompt');

var schema = {
properties: {
  name: {
    pattern: /^[a-zA-Z\s\-]+$/,
    message: 'Name must be only letters, spaces, or dashes',
    required: true
  },
  password: {
    hidden: true
  }
}
};

//
// Start the prompt
//
prompt.start();

//
// Get two properties from the user: email, password
//
prompt.get(schema, function (err, result) {
//
// Log the results.
//
console.log('Command-line input received:');
console.log('  name: ' + result.name);
console.log('  password: ' + result.password);
});
```

## 隐式调用 node 程序
在执行 node 程序的时候都是使用 `node filePath`(比如，`node run.js`)的形式。如何像 `npm`，`git` 一样直接调用？

1. 在你要运行的脚本文件头添加 `#!/usr/bin/env node`，例如：
```js
#!/usr/bin/env node

console.log('Hello,world!');
```

它的作用是指定脚本文件的执行程序 node。做完上面的修改，可以直接 `./<file>` 了。

2. 如果想要一个全局的命令，在 `package.json` 中加入一个字段 `bin`，注意：
```js
  "bin":{
    "myCmd":"<file path>"
  },
```
myCmd 就是你命令的名字，如果是准备发布的模块，一般是会使用模块名称。

3. 在当前工作目录下执行 `npm link`，把模块链接的本地 `npm` 仓库，然后就可以全局调用 myCmd 了。
