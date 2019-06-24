---
title: NPM package.json 详解
date: 2017-10-19 21:03:08
categories: ["Node.js"]
---

使用 `npm init` 命令初始化一个 `package.json` 文件，描述这个 NPM 包的所有相关信息，包括作者、简介、包依赖、构建等信息，格式是严格的 JSON 格式。

<!-- more -->

## 属性

### name

name:模块名称，name和version是最重要的两个属性，也是发布到NPM平台上的唯一标识，如果没有正确设置这两个字段，包就不能发布和被下载。模块更新，版本也应该一起更新。
命名规则:
- name必须小于等于214个字节，包括前缀名称在内（如 xxx/xxxmodule）。
- name不能以"_"或"."开头
- 不能含有大写字母
- name会成为url的一部分，不能含有url非法字符
- name中不要含有"js"和"node"。 It's assumed that it's js, since you're writing a package.json file, and you can specify the engine using the "engines" field. (See below.)
- name属性可以有一些前缀如 e.g. @myorg/mypackage.

### version

模块的版本号。如"1.0.0"。

### description

模块的描述信息。

### keywords

模块的关键词信息，是一个字符串数组。

### homepage

模块的主页url。

### bugs

模块的bug提交地址或者一个邮箱。例如：
``` javascript
{
    "url" : "https://github.com/owner/project/issues",
    "email" : "project@hostname.com"
}
```

### license

模块的开源协议名称。

### author，contributors, maintainers

author：模块的作者。
contributors、maintainers：模块的贡献者、维护者，是一个数组。
``` javascript
{
    "name" : "Xiao Ming",
    "email" : "xiaoming@163.com",
    "url" : "http://www.xiaoming.com/"
}
```
email和url属性是可以省略的。


### files
一个数组，模块所包含的所有文件，可以取值为文件夹。通常是用.npmignore来去除不想包含到包里的文件，与".gitignore"类似。

### main

模块的入口文件。

### bin

如果你的模块里包含可执行文件，通过设置这个字段可以将它们包含到系统的PATH中，这样直接就可以运行，很方便。

### man

为系统的man命令提供帮助文档。帮助文件的文件名必须以数字结尾，如果是压缩的，需要以.gz结尾。
``` javascript
"man": ["./man/foo.1", "./man/bar.1", "./man/foo.2" ]
```

### directories

CommonJS模块所要求的目录结构信息，展示项目的目录结构信息。字段可以是：lib, bin, man, doc, example。值都是字符串。

### repository

模块的仓库地址。
``` javascript
"repository": {
    "type": "git",
    "url": "git+https://github.com/rainnaZR/es6-react.git"
}
```

### config
添加设置，供scripts读取用，同时这里的值也会被添加到系统的环境变量中。通常用来设置一些项目不怎么变化的配置，例如port：
``` javascript
"config": {
  "port": "8080"
}
//用户调用
http.createServer(...).listen(process.env.npm_package_config_port)
```
可以通过`npm config set foo:port 8080`来修改`config`:
``` javascript
{ "name" : "foo", "config" : { "port" : "8080" } }
```
`npm start`的时候会读取到`npm_package_config_port`环境变量。

### dependencies

指定依赖的其它包，这些依赖是指包发布后正常执行时所需要的，也就是线上需要的包。使用下面的命令来安装：
``` bash
npm install --save <package_name>
```
用法：
- version 精确匹配版本
- >version 必须大于某个版本
- >=version 大于等于
- <version 小于
- <=versionversion 小于
- ~version "约等于"，具体规则详见semver文档
- ^version "兼容版本"具体规则详见semver文档
- 1.2.x 仅一点二点几的版本
- http://... url作为denpendencies
- "" 空字符，和*相同，任何版本
- version1 - version2 相当于 >=version1 <=version2.
- range1 || range2 范围1和范围2满足任意一个都行
- git... git url作为denpendencies
- user/repo See 见下面GitHub仓库的说明
- tag 发布的一个特殊的标签，见[npm-tag](https://docs.npmjs.com/getting-started/using-tags)的文档
- path/path/path 本地模块

``` javascript
{ "dependencies" :
  {
    "foo" : "1.0.0 - 2.9999.9999",
    "bar" : ">=1.0.2 <2.1.2",
    "baz" : ">1.0.2 <=2.3.4",
    "boo" : "2.0.1",
    "qux" : "<1.0.0 || >=2.3.1 <2.4.5 || >=2.5.2 <3.0.0",
    "asd" : "http://asdf.com/asdf.tar.gz",
    "til" : "~1.2",
    "elf" : "~1.2.3",
    "two" : "2.x",
    "thr" : "3.3.x",
    "lat" : "latest",
    "dyl" : "file:../dyl"
  }
}
```
#### URLs as Dependencies
在版本范围的地方可以写一个url指向一个压缩包，模块安装的时候会把这个压缩包下载下来安装到模块本地。

#### Git URLs as Dependencies
Git url可以像下面一样:
``` javascript
git://github.com/user/project.git#commit-ish
git+ssh://user@hostname:project.git#commit-ish
git+ssh://user@hostname/project.git#commit-ish
git+http://user@hostname/project/blah.git#commit-ish
git+https://user@hostname/project/blah.git#commit-ish
```
commit-ish 可以是任意标签，哈希值，或者可以检出的分支，默认是master分支。
#### GitHub URLs
支持github的 username/modulename 的写法，#后边可以加后缀写明分支hash或标签：
``` javascript
{
  "name": "foo",
  "version": "0.0.0",
  "dependencies": {
    "express": "visionmedia/express",
    "mocha": "visionmedia/mocha#4727d357ea"
  }
}
```

### devDependencies

这些依赖只有在开发时候才需要。使用下面的命令来安装：
``` bash
npm install --save-dev <package_name>
```
### peerDependencies

相关的依赖，如果你的包是插件，而用户在使用你的包时候，通常也会需要这些依赖（插件），那么可以将依赖列到这里。

如karma, 它的package.json中有设置，依赖下面这些插件：
``` javascript
"peerDependencies": {
  "karma-jasmine": "~0.1.0",
  "karma-requirejs": "~0.2.0",
  "karma-coffee-preprocessor": "~0.1.0",
  "karma-html2js-preprocessor": "~0.1.0",
  "karma-chrome-launcher": "~0.1.0",
  "karma-firefox-launcher": "~0.1.0",
  "karma-phantomjs-launcher": "~0.1.0",
  "karma-script-launcher": "~0.1.0"
}
```

### bundledDependencies

绑定的依赖包，发布的时候这些绑定包也会被一同发布。

### engines

指定模块运行的环境。
``` javascript
"engines": {
  "node": ">=0.10.3 < 0.12",
  "npm": "~1.0.20"
}
```
### os

一个数组，指定模块支持的系统平台。

### cpu

指定模块运行的cpu架构。

### private

设为true这个模块将不会发布到NPM平台下。


### scripts

使用scripts字段定义脚本命令。
``` javascript
"scripts": {
    "build": "node build.js"
}
```

使用npm run命令，就可以执行这段脚本:
``` bash
npm run build
```


更多参考[官方文档](https://docs.npmjs.com/)