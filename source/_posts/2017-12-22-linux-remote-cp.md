---
title: Linux 下远程拷贝传输文件
date: 2017-12-22 12:32:04
categories: ["Linux"]
tags: ["Shell"]
---
Linux下进行远程拷贝传输文件的命令: `scp`，`scp`是 `secure copy`的缩写，基于`ssh`登陆进行安全的远程文件拷贝命令。

<!-- more -->

`scp`命令特点：

- `scp`传输是加密的。
- 占用资源少。`rsync`命令比`scp`会快一点，但当小文件多的情况下，`rsync`会导致硬盘I/O非常高，而`scp`基本不影响系统正常使用。


## 语法
```
scp [可选参数] file_source file_target 
```
**参数说明：**

- -1： 使用协议ssh1
- -2： 使用协议ssh2
- -4： 使用IPv4寻址
- -6： 使用IPv6寻址
- -B： 使用批处理模式（传输过程中不询问传输口令或短语）
- -C： 允许压缩。（将-C标志传递给ssh，从而打开压缩功能）
- -p： 保留原文件的修改时间，访问时间和访问权限。
- -q： 不显示传输进度条。
- -r： 递归复制整个目录。
- -v： 详细方式显示输出。scp和ssh(1)会显示出整个过程的调试信息。这些信息用于调试连接，验证和配置问题。
- -c cipher： 以cipher将数据传输进行加密，这个选项将直接传递给ssh。
- -F ssh_config： 指定一个替代的ssh配置文件，此参数直接传递给ssh。
- -i identity_file： 从指定文件中读取传输时使用的密钥文件，此参数直接传递给ssh。
- -l limit： 限定用户所能使用的带宽，以Kbit/s为单位。
- -o ssh_option： 如果习惯于使用ssh_config(5)中的参数传递方式，
- -P port：注意是大写的P, port是指定数据传输用到的端口号
- -S program： 指定加密传输时所使用的程序。此程序必须能够理解ssh(1)的选项。

## 命令格式

``` bash
scp local_file remote_username@remote_ip:remote_folder 
或者 
scp local_file remote_username@remote_ip:remote_file 
或者 
scp local_file remote_ip:remote_folder 
或者 
scp local_file remote_ip:remote_file 
```
第1,2个指定了用户名，命令执行后需要再输入密码，第1个仅指定了远程的目录，文件名字不变，第2个指定了文件名；
第3,4个没有指定用户名，命令执行后需要输入用户名和密码，第3个仅指定了远程的目录，文件名字不变，第4个指定了文件名；

## 实例

``` bash
#从远程复制到本地
scp -r root@16.187.189.203:/root/mattermost-docker /root/mattermost

#如果远程服务器防火墙有为scp命令设置了指定的端口，我们需要使用 -P 参数来设置命令的端口号
scp -P 4588 -r root@16.187.189.203:/root/mattermost-docker /root/mattermost

#从本地复制到远程
scp -r /root/mattermost root@16.187.189.203:/root/mattermost-docker
```