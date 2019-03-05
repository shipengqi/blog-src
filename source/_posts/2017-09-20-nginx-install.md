---
title: Nginx安装
date: 2017-09-20 19:38:47
categories: ["Linux"]
tags: ["Nginx"]
---

## 引用Nginx介绍

- 来源：<https://help.aliyun.com/knowledge_detail/6703521.html?spm=5176.788314854.2.2.CdMGlB>

<!-- more -->

> - 传统上基于进程或线程模型架构的 Web 服务通过每进程或每线程处理并发连接请求，这势必会在网络和 I/O 操作时产生阻塞，其另一个必然结果则是对内存或 CPU 的利用率低下。生成一个新的进程/线程需要事先备好其运行时环境，这包括为其分配堆内存和栈内存，以及为其创建新的执行上下文等。这些操作都需要占用 CPU，而且过多的进程/线程还会带来线程抖动或频繁的上下文切换，系统性能也会由此进一步下降。
> - 在设计的最初阶段，Nginx 的主要着眼点就是其高性能以及对物理计算资源的高密度利用，因此其采用了不同的架构模型。受启发于多种操作系统设计中基于“事件”的高级处理机制，nginx采用了模块化、事件驱动、异步、单线程及非阻塞的架构，并大量采用了多路复用及事件通知机制。在 Nginx 中，连接请求由为数不多的几个仅包含一个线程的进程 Worker 以高效的回环(run-loop)机制进行处理，而每个 Worker 可以并行处理数千个的并发连接及请求。
> - 如果负载以 CPU 密集型应用为主，如 SSL 或压缩应用，则 Worker 数应与 CPU 数相同；如果负载以 IO 密集型为主，如响应大量内容给客户端，则 Worker 数应该为 CPU 个数的 1.5 或 2 倍。
> - Nginx会按需同时运行多个进程：一个主进程(Master)和几个工作进程(Worker)，配置了缓存时还会有缓存加载器进程(Cache Loader)和缓存管理器进程(Cache Manager)等。所有进程均是仅含有一个线程，并主要通过“共享内存”的机制实现进程间通信。主进程以root用户身份运行，而 Worker、Cache Loader 和 Cache manager 均应以非特权用户身份运行。
> - 主进程主要完成如下工作：
    - 1.读取并验正配置信息；
    - 2.创建、绑定及关闭套接字；
    - 3.启动、终止及维护worker进程的个数；
    - 4.无须中止服务而重新配置工作特性；
    - 5.控制非中断式程序升级，启用新的二进制程序并在需要时回滚至老版本；
    - 6.重新打开日志文件，实现日志滚动；
    - 7.编译嵌入式perl脚本；
> - Worker 进程主要完成的任务包括：
    - 1.接收、传入并处理来自客户端的连接；
    - 2.提供反向代理及过滤功能；
    - 3.nginx任何能完成的其它任务；
> - Cache Loader 进程主要完成的任务包括：
    - 1.检查缓存存储中的缓存对象；
    - 2.使用缓存元数据建立内存数据库；
> - Cache Manager 进程的主要任务：
    - 1.缓存的失效及过期检验；

## 创建nginx.repo,编辑
``` bash
sudo touch /etc/yum.repos.d/nginx.repo
sudo vim /etc/yum.repos.d/nginx.repo
```
**填入以下内容`{version}`是 OS 版本 6 for RHEL 6.6 , 7 for RHEL 7.1，注意版本是 6 或 7**
``` bash
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/rhel/{version}/$basearch/
gpgcheck=0
enabled=1
```
## install nginx
``` bash
#更新yum源
sudo yum update

sudo yum install nginx.x86_64
```
### 错误解决
1. 如下错误：This system is not registered to Red Hat Subscription Management. You can use subscription-manager to register.
是因为Red Hat Enterprise Linux Server(RHEL) 的yum服务是付费的，因为没有付费，所以无法使用yum安装软件。
解决方法:
``` bash

rpm -qa |grep yum \\查看RHEL是否安装了yum

rpm -qa|grep yum|xargs rpm -e --nodeps \\不检查依赖，直接删除rpm包

rpm -qa |grep yum \\无信息显示表示已经卸载完成

\\下载新的yum包
wget http://mirrors.163.com/centos/7.3.1611/os/x86_64/Packages/yum-3.4.3-150.el7.centos.noarch.rpm
wget http://mirrors.163.com/centos/7.3.1611/os/x86_64/Packages/yum-metadata-parser-1.1.4-10.el7.x86_64.rpm
wget http://mirrors.163.com/centos/7.3.1611/os/x86_64/Packages/yum-plugin-fastestmirror-1.1.31-40.el7.noarch.rpm

\\更换yum源 http://mirrors.163.com/.help/centos.html
cd /etc/yum.repos.d/
wget  http://mirrors.163.com/.help/CentOS7-Base-163.repo
vim CentOS7-Base-163.repo \\把文件里面的$releasever全部替换为版本号，即7.3.1611 最后保存

\\清除原有缓存
yum clean all

\\重建缓存，以提高搜索安装软件的速度
yum makecache

\\更新系统
yum update
```

2. No such file or directory
``` bash
error: open of <!DOCTYPE failed: No such file or directory
error: open of HTML failed: No such file or directory
error: open of PUBLIC failed: No such file or directory
```
是因为没有尝试安装rpm文件，而是试图安装一个web页面。使用cat查看rpm文件。获取正确的rpm包安装，可以直接下载下来，不实用wget

3. Error importing
如下错误
Error importing  repomd.xml for extras: Damaged repomd.xml file
检查网络配置

## start nginx
On RHEL 6.6:
``` bash
sudo service nginx start
```
On RHEL 7.1:
``` bash
sudo systemctl start nginx
```
## Verify that nginx is running
``` bash
curl http://<your ip>
```

## Nginx 源码编译安装

- 开始安装：
    - 下载源码包：`wget http://nginx.org/download/nginx-1.8.1.tar.gz`
    - 解压：`tar zxvf nginx-1.8.1.tar.gz`
    - 进入解压后目录：`cd nginx-1.8.1/`
    - 编译配置：

    ``` ini
    ./configure \
    --prefix=/usr/local/nginx \
    --pid-path=/var/local/nginx/nginx.pid \
    --lock-path=/var/lock/nginx/nginx.lock \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --with-http_gzip_static_module \
    --http-client-body-temp-path=/var/temp/nginx/client \
    --http-proxy-temp-path=/var/temp/nginx/proxy \
    --http-fastcgi-temp-path=/var/temp/nginx/fastcgi \
    --http-uwsgi-temp-path=/var/temp/nginx/uwsgi \
    --with-http_ssl_module \
    --http-scgi-temp-path=/var/temp/nginx/scgi
    ```

    - 编译：`make`
    - 安装：`make install`
- 启动 Nginx
    - 先检查是否在 /usr/local 目录下生成了 Nginx 等相关文件：`cd /usr/local/nginx;ll`，正常的效果应该是显示这样的：

    ``` nginx
    drwxr-xr-x. 2 root root 4096 3月  22 16:21 conf
    drwxr-xr-x. 2 root root 4096 3月  22 16:21 html
    drwxr-xr-x. 2 root root 4096 3月  22 16:21 sbin
    ```

    - 停止防火墙：`service iptables stop`
        - 或是把 80 端口加入到的排除列表：
        - `sudo iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT`
        - `sudo service iptables save`
        - `sudo service iptables restart`
    - 启动：`/usr/local/nginx/sbin/nginx`，启动完成 shell 是不会有输出的
    - 检查 时候有 Nginx 进程：`ps aux | grep nginx`，正常是显示 3 个结果出来
    - 检查 Nginx 是否启动并监听了 80 端口：`netstat -ntulp | grep 80`
    - 访问：`192.168.1.114`，如果能看到：`Welcome to nginx!`，即可表示安装成功
    - 检查 Nginx 启用的配置文件是哪个：`/usr/local/nginx/sbin/nginx -t`
    - 刷新 Nginx 配置后重启：`/usr/local/nginx/sbin/nginx -s reload`
    - 停止 Nginx：`/usr/local/nginx/sbin/nginx -s stop`
    - 如果访问不了，或是出现其他信息看下错误立即：`vim /var/log/nginx/error.log`


## 把 Nginx 添加到系统服务中

- 新建文件：`vim /etc/init.d/nginx`
- 添加如下内容：

``` nginx
#!/bin/bash


#nginx执行程序路径需要修改
nginxd=/usr/local/nginx/sbin/nginx

# nginx配置文件路径需要修改
nginx_config=/usr/local/nginx/conf/nginx.conf

# pid 地址需要修改
nginx_pid=/var/local/nginx/nginx.pid


RETVAL=0
prog="nginx"

# Source function library.
. /etc/rc.d/init.d/functions
# Source networking configuration.
. /etc/sysconfig/network
# Check that networking is up.
[ ${NETWORKING} = "no" ] && exit 0
[ -x $nginxd ] || exit 0

# Start nginx daemons functions.
start() {
if [ -e $nginx_pid ];then
   echo "nginx already running...."
   exit 1
fi

echo -n $"Starting $prog: "
daemon $nginxd -c ${nginx_config}
RETVAL=$?
echo
[ $RETVAL = 0 ] && touch /var/lock/subsys/nginx
return $RETVAL
}

# Stop nginx daemons functions.
# pid 地址需要修改
stop() {
	echo -n $"Stopping $prog: "
	killproc $nginxd
	RETVAL=$?
	echo
	[ $RETVAL = 0 ] && rm -f /var/lock/subsys/nginx /var/local/nginx/nginx.pid
}

# reload nginx service functions.
reload() {
	echo -n $"Reloading $prog: "
	#kill -HUP `cat ${nginx_pid}`
	killproc $nginxd -HUP
	RETVAL=$?
	echo
}

# See how we were called.
case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	reload)
		reload
		;;
	restart)
		stop
		start
		;;
	status)
		status $prog
		RETVAL=$?
		;;
	*)

	echo $"Usage: $prog {start|stop|restart|reload|status|help}"
	exit 1

esac
exit $RETVAL
```

- 修改权限：`chmod 755 /etc/init.d/nginx`
- 启动服务：`service nginx start`
- 停止服务：`service nginx stop`
- 重启服务：`service nginx restart`


## 错误解决

### nginx: [emerg] bind() to 0.0.0.0:80 failed (13: Permission denied)

启动时碰到上面的错误，原因：
``` bash
the socket API bind() to a port less than 1024, such as 80 as your title mentioned, need root access.
```
没有权限使用小于1024的端口，使用`root`或者更改端口（我用的8000）

### nginx: [emerg] bind() to 0.0.0.0:8000 failed (13: Permission denied)

更改了端口还是启动失败：
``` bash
SELinux is preventing /usr/sbin/openvpn from name_bind access on the tcp_socket .

***** Plugin bind_ports (92.2 confidence) suggerisce  ************************

Se you want to allow /usr/sbin/openvpn to bind to network port 8000
Quindi you need to modify the port type.
Fai
# semanage port -a -t TIPO_PORTA -p tcp 8000
dove TIPO_PORTA è una delle seguenti: openvpn_port_t, http_port_t.
```

原因：
`SElinux` 导致的。
查看`SElinux`状态：
``` bash
getenforce

#permissive:关闭 enforcing：开启
#输出 
Enforcing

#或者
sestatus
#输出
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      28
```
`SElinux`是开启的，可以暂时关闭：
``` bash
setenforce 0  ##设置SELinux 成为permissive模式

#setenforce 1 ##设置SELinux 成为enforcing模式
```

重新启动`Nginx`。
