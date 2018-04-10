---
title: Redis安装配置
date: 2018-04-05 17:34:24
categories: ["Linux"]
tags: ["Redis"]
---

Redis安装，配置认证密码，配置service服务。

<!-- more -->

## 安装

### linux
只介绍centos中的安装。
``` bash
#下载
wget http://download.redis.io/releases/redis-x.x.x.tar.gz
#解压
tar -xzvf redis-x.x.x.tar.gz
# 编译安装
cd redis-x.x.x
make
make install
```

`make install`会在`/usr/local/bin`目录下生成以下文件：

- redis-server：Redis服务器端启动程序
- redis-cli：Redis客户端操作工具。也可以用telnet根据其纯文本协议来操作
- redis-benchmark：Redis性能测试工具
- redis-check-aof：数据修复工具
- redis-check-dump：检查导出工具

如果出现以下错误：
```bash
make[1]: Entering directory `/root/redis/src'
You need tcl 8.5 or newer in order to run the Redis test
……
```
这是因为没有安装tcl导致，yum安装即可：
```bash
yum install tcl
```
**配置Redis**
复制配置文件到/etc/目录：
``` bash
cp redis.conf /etc/
vim /etc/redis.conf

#找到下面的内容
################################# GENERAL #####################################

# By default Redis does not run as a daemon. Use 'yes' if you need it.
# Note that Redis will write a pid file in /var/run/redis.pid when daemonized.
# NOT SUPPORTED ON WINDOWS daemonize no

#修改daemonize配置项为yes，使Redis进程在后台运行
daemonize yes
```

**启动Redis**
``` bash
cd /usr/local/bin
./redis-server /etc/redis.conf

#检查是否启动成功：
ps -ef | grep redis
```

**一些常用的Redis启动参数：**

- daemonize：是否以后台daemon方式运行
- pidfile：pid文件位置
- port：监听的端口号
- timeout：请求超时时间
- loglevel：log信息级别
- logfile：log文件位置
- databases：开启数据库的数量
- save * *：保存快照的频率，第一个*表示多长时间，第三个*表示执行多少次写操作。在一定时间内执行一定数量的写操作时，自动保存快照。可设置多个条件。
- rdbcompression：是否使用压缩
- dbfilename：数据快照文件名（只是文件名）
- dir：数据快照的保存目录（仅目录）
- appendonly：是否开启appendonlylog，开启的话每次写操作会记一条log，这会提高数据抗风险能力，但影响效率。
- appendfsync：appendonlylog如何同步到磁盘。三个选项，分别是每次写都强制调用fsync、每秒启用一次fsync、不调用fsync等待系统自己同步


### windows
下载地址：https://github.com/MSOpenTech/redis/releases。

根据实际情况载 Redis-x-xxx.zip压缩包并解压。

#### 运行redis server
切换到redis解压目录，打开一个 `cmd` 窗口，运行 `redis-server.exe redis.windows.conf` 。

#### 运行redis cli
在解压目录下打开另一个 `cmd` 窗口，运行 `redis-cli.exe -h 127.0.0.1 -p 6379` 。

### docker
``` bash
docker run --name some-redis -d redis
```

参考官方[redis镜像文档](https://hub.docker.com/_/redis/)。

## 配置认证密码登录

Redis默认配置是不需要密码认证，需要手动配置启用Redis的认证密码，增加Redis的安全性。

### 修改配置

linux下Redis的默认配置文件默认在`/etc/redis.conf`。windows下则是安装目录下的`redis.windows.conf`文件。
打开配置文件，找到下面的内容：
``` conf
################################## SECURITY ###################################

# Require clients to issue AUTH <PASSWORD> before processing any other
# commands.  This might be useful in environments in which you do not trust
# others with access to the host running redis-server.
#
# This should stay commented out for backward compatibility and because most
# people do not need auth (e.g. they run their own servers).
#
# Warning: since Redis is pretty fast an outside user can try up to
# 150k passwords per second against a good box. This means that you should
# use a very strong password otherwise it will be very easy to break.
#
#requirepass foobared
```
去掉前面的注释，并修改为你的认证密码：
``` conf
requirepass {your password}
```

### 重启Redis


``` bash
#如果已经配置为service服务
systemctl restart redis

#或者
/usr/local/bin/redis-cli shutdown
/usr/local/bin/redis-server /etc/redis.conf
```

### 登录验证
重启后登录时需要使用`-a`参数输入密码，否则登录后没有任何操作权限。如下：
``` bash
./redis-cli -h 127.0.0.1 -p 6379
127.0.0.1:6379> set testkey
(error) NOAUTH Authentication required.
```
使用密码认证登录：
``` bash
./redis-cli -h 127.0.0.1 -p 6379 -a myPassword
127.0.0.1:6379> set testkey hello
OK
```

或者不实用`-a`参数登录，在连接后进行验证：
``` bash
./redis-cli -h 127.0.0.1 -p 6379
127.0.0.1:6379> auth yourpassword
OK
127.0.0.1:6379> set testkey hello
OK
```
### 在命令行客户端配置密码
``` bash
127.0.0.1:6379> config set requirepass yourpassword
OK
127.0.0.1:6379> config get requirepass
1) "requirepass"
2) "yourpassword"
```

> 注意：使用命令行客户端配置密码，重启Redis后仍然会使用redis.conf配置文件中的密码。


### 在集群中配置认证密码

如果Redis使用了集群。除了在`master`中配置密码外，`slave`中也需要配置。在`slave`的配置文件中找到如下行，去掉注释并修改为与`master`相同的密码：
``` conf
# masterauth your-master-password
```


## Redis配置到系统服务(systemd)

### 创建redis.service文件

进入/usr/lib/systemd/system目录，创建redis.service文件：
```conf
[Unit]
#描述
Description=Redis
#启动时机,开机启动最好在网络服务启动后即启动
After=syslog.target network.target remote-fs.target nss-lookup.target

#表示服务信息
[Service]
Type=forking
#注意：需要和redis.conf配置文件中的信息一致
PIDFile=/var/run/redis.pid
#启动服务的命令
#redis-server安装的路径 和 redis.conf配置文件的路径
ExecStart=/usr/local/bin/redis-server /etc/redis.conf
#停止服务的命令
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always

#安装相关信息
[Install]
#启动方式
WantedBy=multi-user.target
#multi-user.target表明当系统以多用户方式（默认的运行级别）启动时，这个服务需要被自动运行。
```

`Type=forking`，forking 表示服务管理器是系统 init 的子进程，用于管理需要后台运行的服务。

修改 `/etc/redis.conf`：
``` conf
daemonize yes

supervised systemd
```

``` bash
#使配置生效
systemctl daemon-reload

#设置开机启动
systemctl enable redis.service

#启动
systemctl start redis.service

#查看状态
systemctl status redis.service

#重启
systemctl restart redis.service

#停止
systemctl stop redis.service

#关闭开机启动
systemctl disable redis.service
```