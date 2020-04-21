---
title: CentOs 安装 ETCD
date: 2017-10-16 21:01:38
categories: ["Linux"]
---

CentOs 下安装 ETCD。

<!-- more -->

## 下载源码包：
下载地址：https://github.com/coreos/etcd/releases。
下载 etcd-v3.2.9-linux-amd64.tar.gz。
## 将下载的源码包解压。
``` bash
tar -xzf etcd-v3.2.9-linux-amd64.tar.gz

cd etcd-v3.2.9-linux-amd64

# 会看到etcd,etcdctl
cp etcd /usr/bin/
cp etcdctl /usr/bin/

```

## 运行 etcd，数据库服务端默认监听在 2379 和 4001 端口，etcd 实例监听在 2380 和 7001 端口。
``` bash
etcd
```

## 创建服务描述文件
``` bash
vim /usr/lib/systemd/system/etcd.service
# 添加
[Unit]
Description=Etcd Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=/etc/etcd/etcd.conf
ExecStart=/usr/bin/etcd

[Install]
WantedBy=multi-user.target
```
## etcd 配置
``` bash
mkdir /var/lib/etcd
mkdir /etc/etcd
vim /etc/etcd/etcd.conf
# 添加
ETCD_NAME=default
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://localhost:2379"
```
## 启动 etcd
``` bash
systemctl daemon-reload
systemctl start etcd
```

## 验证
通过 etcdctl 命令来验证，要在环境变量中设置 `ETCDCTL_API=3`.否则使用 etcdctl 时会报错。
``` bash
export ETCDCTL_API=3

etcdctl put testKey 'first'
# 输出
OK

etcdctl get testKey
# 输出
testKey
first
```