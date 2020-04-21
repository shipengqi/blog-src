---
title: Linux 实现无密码登录
date: 2017-05-21 19:38:54
categories: ["Linux"]
---
Linux 实现无密码登录
<!-- more -->

## 本地机配置
如果本机已经有 ssh key, 请忽略这一步, 如果还没有需要同过下面的命令生成：
``` bash
ssh-keygen
\\ 或者
ssh-keygen -t rsa
```
这里一路回车。生成 ssh 密钥后，可以到 `~/.ssh` 目录下查看, 该目录下有两个文件 `id_rsa` (私钥)和 `id_rsa.pub` (公钥),
`-t rsa` 是设置生成密钥的算法, 如果使用 `-t dsa`,生成的文件名分别是：`id_dsa`, `id_rsa.pub`。还可以通过 `-C` 参数添加密钥的注释例如：
``` bash
ssh-keygen -t rsa -C "<注释>"
```

## 远端服务器
1. 查看是否存在 `~/.ssh` 目录，查看是否已经有 ssh key。如果没有执行上一步操作的命令。
2. 创建好SSH 密钥后，创建 `authorized_keys`，该文件是授权文件。编辑该文件：
``` bash
vim authorized_keys
```
将本地机器的 `id_rsa.pub` 文件内容粘贴到 `authorized_keys` 文件。

## 配置无密码登录
切换到 root 账户。编辑以下配置文件：
``` bash
vim /etc/ssh/sshd_config 
```
去掉如下三行注释#：
``` bash
#RSAAuthentication yes
#PubkeyAuthentication yes
#AuthorizedKeysFile     .ssh/authorized_keys
```

## 重启 sshd 服务：
``` bash
service sshd restart

\\CentOS
systemctl restart sshd.service
```

## 登录
``` bash
ssh -l bot 192.168.0.1
```

这个时候应该可以直接登录了。


