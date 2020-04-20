---
title: Shell eval 命令
date: 2018-01-08 15:47:22
categories: ["Linux"]
tags: ["Shell"]
---

`Shell`中的`eval`命令用于重新运算求出参数的内容，可读取一连串的参数，然后再依参数本身的特性来执行。

<!-- more -->

## eval使用
`eval`命令会先扫描命令行进行所有的替换，然后再执行命令。该命令使用于那些一次扫描无法实现其功能的变量。该命令对变量进行两次扫描。这些需要进行两次扫描的变量有时候被称为复杂变量。
### 回显变量
`eval`命令可以用于回显简单变量，不一定是复杂变量。
``` bash
$ NAME=Pooky
$ eval echo $NAME
Pooky
$ echo $NAME
Pooky
```
### 执行含有字符串的命令
test.txt文件:
``` bash
Hello World!!!
```
``` bash
$ testfile="cat test"
$ echo $testfile
#输出
cat test

$ #eval $testfile
#输出
Hello World!!!
```
`eval`命令第一次扫描进行了变量置换，第二次扫描执行了该字符串中所包含的命令`cat test`。
### 获得最后一个参数
``` bash
$ cat test
#!/bin/bash
echo "Last argument is $(eval echo \$$#)"

$ ./test test last
Last argument os last
```

`eval`命令首先把`$`，`$#`解析为当前`Shell`的参数个数，然后在第二次扫描时
得出最后一个参数。