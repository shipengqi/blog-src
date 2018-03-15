---
title: Linux查看端口占用
date: 2017-09-25 21:09:17
categories: ["Linux"]
---

Linux查看端口占用命令
<!-- more -->

## netstat
``` bash
netstat -tln
netstat -tln | grep <port>
```
netstat -tln 查看所有端口使用情况,grep <port> 查看某个端口使用情况.

## lsof
``` bash
lsof -i :<port>
```
查看端口被哪个进程占用

