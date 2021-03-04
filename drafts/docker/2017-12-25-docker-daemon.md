---
title: Docker daemon 配置
date: 2017-12-25 09:34:53
categories: ["Linux"]
tags: ["Docker"]
---


Docker 命令有两大类，客户端命令和服务端命令。前者是主要的操作接口，后者用来启动 Docker Daemon。

* 客户端命令：基本命令格式为 `docker [OPTIONS] COMMAND [arg...]`；

* 服务端命令：基本命令格式为 `dockerd [OPTIONS]`。

可以通过 `man docker` 或 `docker help` 来查看这些命令。




## 客户端命令选项

* --config=""：指定客户端配置文件，默认为 `/.docker`；
* -D=true|false：是否使用 debug 模式。默认不开启；
* -H, --host=[]：指定命令对应 Docker 守护进程的监听接口，可以为 unix 套接字（unix:///path/to/socket），
文件句柄（fd://socketfd）或 tcp 套接字（tcp://[host[:port]]），默认为 unix:///var/run/docker.sock；
* -l, --log-level="debug|info|warn|error|fatal"：指定日志输出级别；
* --tls=true|false：是否对 Docker 守护进程启用 TLS 安全机制，默认为否；
* --tlscacert= /.docker/ca.pem：TLS CA 签名的可信证书文件路径；
* --tlscert= /.docker/cert.pem：TLS 可信证书文件路径；
* --tlscert= /.docker/key.pem：TLS 密钥文件路径；
* --tlsverify=true|false：启用 TLS 校验，默认为否。

## dockerd 命令选项

[官方配置文档](https://docs.docker.com/engine/reference/commandline/dockerd/)

`Linux`上的配置文件的默认位置是`/etc/docker/daemon.json`，`--config-file`标志可以指定非默认的位置。

官方`daemon.json`例子：

``` json
{
	"authorization-plugins": [],
	"data-root": "",
	"dns": [],
	"dns-opts": [],
	"dns-search": [],
	"exec-opts": [],
	"exec-root": "",
	"experimental": false,
	"storage-driver": "",
	"storage-opts": [],
	"labels": [],
	"live-restore": true,
	"log-driver": "",
	"log-opts": {},
	"mtu": 0,
	"pidfile": "",
	"cluster-store": "",
	"cluster-store-opts": {},
	"cluster-advertise": "",
	"max-concurrent-downloads": 3,
	"max-concurrent-uploads": 5,
	"default-shm-size": "64M",
	"shutdown-timeout": 15,
	"debug": true,
	"hosts": [],
	"log-level": "",
	"tls": true,
	"tlsverify": true,
	"tlscacert": "",
	"tlscert": "",
	"tlskey": "",
	"swarm-default-advertise-addr": "",
	"api-cors-header": "",
	"selinux-enabled": false,
	"userns-remap": "",
	"group": "",
	"cgroup-parent": "",
	"default-ulimits": {},
	"init": false,
	"init-path": "/usr/libexec/docker-init",
	"ipv6": false,
	"iptables": false,
	"ip-forward": false,
	"ip-masq": false,
	"userland-proxy": false,
	"userland-proxy-path": "/usr/libexec/docker-proxy",
	"ip": "0.0.0.0",
	"bridge": "",
	"bip": "",
	"fixed-cidr": "",
	"fixed-cidr-v6": "",
	"default-gateway": "",
	"default-gateway-v6": "",
	"icc": false,
	"raw-logs": false,
	"allow-nondistributable-artifacts": [],
	"registry-mirrors": [],
	"seccomp-profile": "",
	"insecure-registries": [],
	"disable-legacy-registry": false,
	"no-new-privileges": false,
	"default-runtime": "runc",
	"oom-score-adjust": -500,
	"runtimes": {
		"runc": {
			"path": "runc"
		},
		"custom": {
			"path": "/usr/local/bin/my-runc-replacement",
			"runtimeArgs": [
				"--debug"
			]
		}
	}
}
```

* --api-cors-header=""：CORS 头部域，默认不允许 CORS，要允许任意的跨域访问，可以指定为 “*”；
* --authorization-plugin=""：载入认证的插件；
* -b=""：将容器挂载到一个已存在的网桥上。指定为 'none' 时则禁用容器的网络，与 --bip 选项互斥；
* --bip=""：让动态创建的 docker0 网桥采用给定的 CIDR 地址; 与 -b 选项互斥；
* --cgroup-parent=""：指定 cgroup 的父组，默认 fs cgroup 驱动为 `/docker`，systemd cgroup 驱动为 `system.slice`；
* --cluster-store=""：构成集群（如 Swarm）时，集群键值数据库服务地址；
* --cluster-advertise=""：构成集群时，自身的被访问地址，可以为 `host:port` 或 `interface:port`；
* --cluster-store-opt=""：构成集群时，键值数据库的配置选项；
* --config-file="/etc/docker/daemon.json"：daemon 配置文件路径；
* --containerd=""：containerd 文件的路径；
* -D, --debug=true|false：是否使用 Debug 模式。缺省为 false；
* --default-gateway=""：容器的 IPv4 网关地址，必须在网桥的子网段内；
* --default-gateway-v6=""：容器的 IPv6 网关地址；
* --default-ulimit=[]：默认的 ulimit 值；
* --disable-legacy-registry=true|false：是否允许访问旧版本的镜像仓库服务器；
* --dns=""：指定容器使用的 DNS 服务器地址；
* --dns-opt=""：DNS 选项；
* --dns-search=[]：DNS 搜索域；
* --exec-opt=[]：运行时的执行选项；
* --exec-root=""：容器执行状态文件的根路径，默认为 `/var/run/docker`；
* --fixed-cidr=""：限定分配 IPv4 地址范围；
* --fixed-cidr-v6=""：限定分配 IPv6 地址范围；
* -G, --group=""：分配给 unix 套接字的组，默认为 `docker`；
* -g, --graph=""：Docker 运行时的根路径，默认为 `/var/lib/docker`；
* -H, --host=[]：指定命令对应 Docker daemon 的监听接口，可以为 unix 套接字（unix:///path/to/socket），
文件句柄（fd://socketfd）或 tcp 套接字（tcp://[host[:port]]），默认为 unix:///var/run/docker.sock；
* --icc=true|false：是否启用容器间以及跟 daemon 所在主机的通信。默认为 true。
* --insecure-registry=[]：允许访问给定的非安全仓库服务；
* --ip=""：绑定容器端口时候的默认 IP 地址。缺省为 0.0.0.0；
* --ip-forward=true|false：是否检查启动在 Docker 主机上的启用 IP 转发服务，默认开启。注意关闭该选项将不对系统转发能力进行任何检查修改；
* --ip-masq=true|false：是否进行地址伪装，用于容器访问外部网络，默认开启；
* --iptables=true|false：是否允许 Docker 添加 iptables 规则。缺省为 true；
* --ipv6=true|false：是否启用 IPv6 支持，默认关闭；
* -l, --log-level="debug|info|warn|error|fatal"：指定日志输出级别；
* --label="[]"：添加指定的键值对标注；
* --log-driver="json-file|syslog|journald|gelf|fluentd|awslogs|splunk|etwlogs|gcplogs|none"：指定日志后端驱动，默认为 json-file；
* --log-opt=[]：日志后端的选项；
* --mtu=VALUE：指定容器网络的 mtu；
* -p=""：指定 daemon 的 PID 文件路径。缺省为 `/var/run/docker.pid`；
* --raw-logs：输出原始，未加色彩的日志信息；
* --registry-mirror=<scheme>://<host>：指定 `docker pull` 时使用的注册服务器镜像地址；
* -s, --storage-driver=""：指定使用给定的存储后端；
* --selinux-enabled=true|false：是否启用 SELinux 支持。缺省值为 false。SELinux 目前尚不支持 overlay 存储驱动；
* --storage-opt=[]：驱动后端选项；
* --tls=true|false：是否对 Docker daemon 启用 TLS 安全机制，默认为否；
* --tlscacert= /.docker/ca.pem：TLS CA 签名的可信证书文件路径；
* --tlscert= /.docker/cert.pem：TLS 可信证书文件路径；
* --tlscert= /.docker/key.pem：TLS 密钥文件路径；
* --tlsverify=true|false：启用 TLS 校验，默认为否；
* --userland-proxy=true|false：是否使用用户态代理来实现容器间和出容器的回环通信，默认为 true；
* --userns-remap=default|uid:gid|user:group|user|uid：指定容器的用户命名空间，默认是创建新的 UID 和 GID 映射到容器内进程。


`daemon.json`几乎可以配置所有的服务端进程配置选项。但是`daemon.json`不能 [配置HTTP代理](/2017/10/27/yum-install-docker/)。

官方配置文档：
- [Configure and troubleshoot the Docker daemon](https://docs.docker.com/config/daemon/)
- [Control Docker with systemd](https://docs.docker.com/config/daemon/systemd/)


## 常用 daemon.json 配置

`daemon.json` 配置方式
+ `Linux`: `/etc/docker/daemon.json`
+ `Windows Server`: `C:\ProgramData\docker\config\daemon.json`
+ `Docker for Mac` / `Docker for Windows`: Click the Docker icon in the toolbar, select `Preferences`,
then select `Daemon`. Click `Advanced`.


### 镜像加速器

```json
// 配置一个
{
  "registry-mirrors": ["https://registry.docker-cn.com"]
}

// 配置多个
{
  "registry-mirrors": ["https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn"]
}
```

> 镜像加速器常用值：
>> `docker-cn 官方` : `https://registry.docker-cn.com`
>>
>> `中科大` : `https://docker.mirrors.ustc.edu.cn`

### 日志

```json
{
  "debug": true,
  "log-level": "info"
}
```

> `log-level` 的有效值包括: `debug`, `info`, `warn`, `error`, `fatal`


### 监控 Prometheus

> https://docs.docker.com/engine/admin/prometheus/#configure-docker

```json
{
  "metrics-addr" : "127.0.0.1:9323",
  "experimental" : true
}
```


### 保持容器在线

> https://docs.docker.com/engine/admin/live-restore/#enable-the-live-restore-option

当 `dockerd` 进程死掉后， 依旧保持容器存活。

```json
{
  "live-restore": true
}
```

Linux 重载 docker daemon

```bash
$ sudo kill -SIGHUP $(pidof dockerd)
```


### 设置 `镜像、容器、卷` 存放目录和驱动

> https://docs.docker.com/engine/admin/systemd/#runtime-directory-and-storage-driver

下述两个参数可以单独使用

```json
{
    "graph": "/mnt/docker-data",
    "storage-driver": "overlay"
}
```

`graph`: 设置存放目录
+ `Docker Root Dir: /mnt/docker-data`

`storage-driver`: 设置存储驱动
+ `Storage Driver: overlay`


### user namespace remap

> https://docs.docker.com/engine/security/userns-remap/#enable-userns-remap-on-the-daemon

安全设置： 用户空间重映射

`userns-remap` 的值可以是
如果值字段 `只有` 一个值， 那么该字段表示 `组`。
如果需要同时指定 `用户` 和 `组`, 需要使用 `冒号` 分隔，格式为  `用户:组`

+ `组`
+ `用户:组`
+ `组` 或 `用户` 的值可以是组或用户的 `名称` 或 `ID`。
  + `testuser`
  + `testuser:testuser`
  + `1001`
  + `1001:1001`
  + `testuser:1001`
  + `1001:testuser`

```json
{
  "userns-remap": "testuser"
}

// 或同时指定 用户和组，且使用 名称和ID
{
  "userns-remap": "testuser:1001"
}
```

```bash
$ dockerd --userns-remap="testuser:testuser"
```

> `userns-remap` 使用不多，但并不是不重要。目前不是默认启用的原因是因为一些应用会**假定** uid 0 的用户拥有特殊能力，从而导
致假定失败，然后报错退出。所以**如果要启用 user id remap，你要充分测试一下**。但是启用 uid remap 的安全性提高是明显的。


## 一张图总结 Docker 的命令
![Docker 命令总结](/images/docker-daemon/cmd_logic.png)


**本文摘自**
- [Docker — 从入门到实践](https://www.gitbook.com/book/yeasy/docker_practice/details)
- [Docker 17.09 官方文档中文笔记](https://docs-cn.docker.octowhale.com/000.get_docker/001.docker-configure-daemon-json.html)