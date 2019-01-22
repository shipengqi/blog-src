---
title: CentOs安装Go
date: 2017-10-16 21:01:29
categories: ["Linux"]
tags: ["Go"]
---

CentOs下安装Go。

<!-- more -->

## 下载源码包：
官网[下载地址](https://golang.org/dl/)。
下载`go1.9.1.linux-amd64.tar.gz`。
## go的默认路径是`/usr/local`下，所以将下载的源码包解压至 `/usr/local`目录。、
``` bash
tar -C /usr/local -xzf go1.9.1.linux-amd64.tar.gz
```
## 添加PATH环境变量：
``` bash
vim /etc/profile

#添加
export GOPATH=$HOME/gocode   #默认安装包的路径
export PATH=$PATH:/usr/local/go/bin

#使配置生效
source /etc/profile
```
`go`命令依赖一个重要的环境变量：`$GOPATH`，这个不是Go安装目录，相当于我们的工作目录。
GOPATH允许多个目录，当有多个目录时，请注意分隔符，多个目录的时候Windows是分号`;`，Linux系统是冒号`:`，当有多个GOPATH时默认将`go get`获取的包存放在第一个目录下。
$GOPATH 目录约定有三个子目录：
- `src`存放源代码(比如：.go .c .h .s等)
- `pkg`编译时生成的中间文件（比如：.a）
- `bin`编译后生成的可执行文件（为了方便，可以把此目录加入到 `$PATH` 变量中，如果有多个gopath，那么使用${GOPATH//://bin:}/bin添加所有的bin目录）

## 验证
``` bash
vim hello.go

#添加保存
package main

import "fmt"

func main() {
   fmt.Println("Hello, World!")
}

#执行
go run hello.go

#输出
Hello, World!
```