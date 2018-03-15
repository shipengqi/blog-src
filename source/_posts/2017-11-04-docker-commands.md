---
title: Docker命令
date: 2017-11-04 15:35:35
categories: ["Linux"]
tags: ["Docker"]
---

记录docker命令。

<!-- more -->

## 容器生命周期管理
```
docker [run|start|stop|restart|kill|rm|pause|unpause|create|exec]
```

### dcoker run
创建一个新的容器并运行一个命令
```
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
```

- -a :指定标准输入输出内容类型，可选 STDIN/STDOUT/STDERR 三项，也就是进入容器（必须是以docker run -d启动的容器）
- -d :后台运行容器，并返回容器ID，默认为false
- -i :以交互模式运行容器，通常与 -t 同时使用
- -t :为容器重新分配一个伪输入终端，通常与 -i 同时使用
- -h :"mars": 指定容器的hostname
- -e :设置环境变量，容器中可以使用该环境变量 e.g. username="ritchie"
- -m :设置容器的内存上限
- -u :指定容器的用户
- -w :指定容器的工作目录
- -c :设置容器CPU权重，在CPU共享场景使用
- -P :Docker 会随机映射一个 49000~49900 的端口到内部容器开放的网络端口。
- -p :指定容器暴露的端口
- -h :指定容器的主机名
- -v :给容器挂载存储卷，挂载到容器的某个目录
- --name: 为容器指定一个名称
- --env-file=[]: 从指定文件读入环境变量
- --rm :指定容器停止后自动删除容器(不支持以docker run -d启动的容器)
- --expose=[]: 指定容器暴露的端口，即修改镜像的暴露端口
- --restart="no" :指定容器停止后的重启策略:  no(容器退出时不重启)/on-failur(容器故障退出（返回值非零）时重启)/always(容器退出时总是重启)
- --volumes-from :给容器挂载其他容器上的卷，挂载到容器的某个目录
- --dns 8.8.8.8: 指定容器使用的DNS服务器，默认和宿主一致
- --dns-search example.com: 指定容器DNS搜索域名，默认和宿主一致，写入到容器的/etc/resolv.conf文件
- --cpuset="0-2" or --cpuset="0,1,2": 绑定容器到指定CPU运行，此参数可以用来容器独占CPU
- --cap-add :添加权限，权限清单详见：http://linux.die.net/man/7/capabilities
- --cap-drop :删除权限，权限清单详见：http://linux.die.net/man/7/capabilities
- --cidfile="" :运行容器后，在指定文件中写入容器PID值，一种典型的监控系统用法
- --device :添加主机设备给容器，相当于设备直通
- --entrypoint :覆盖image的入口点
- --lxc-conf=[] :指定容器的配置文件，只有在指定--exec-driver=lxc时使用
- --privileged=false :指定容器是否为特权容器，特权容器拥有所有的capabilities
- --sig-proxy=true :设置由代理接受并处理信号，但是SIGCHLD、SIGSTOP和SIGKILL不能被代理
- --net="bridge": 指定容器的网络连接类型，支持 bridge(使用docker daemon指定的网桥)/host(容器使用主机的网络)/none(容器使用自己的网络（类似--net=bridge），但是不进行配置)/container(使用其他容器的网路，共享IP和PORT等网络资源): 四种类型
- --link=[]: 添加链接到另一个容器，使用其他容器的IP、env等信息

- -b BRIDGE or --bridge=BRIDGE --指定容器挂载的网桥
- --bip=CIDR --定制 docker0 的掩码
- -H SOCKET... or --host=SOCKET... --Docker 服务端接收命令的通道
- --icc=true|false --是否支持容器之间进行通信
- --ip-forward=true|false --请看下文容器之间的通信
- --iptables=true|false --是否允许 Docker 添加 iptables 规则
- --mtu=BYTES --容器网络中的 MTU

`--rm` 和 `-d` 参数不能同时使用。

``` bash
#本地主机的随机映射一个 49000~49900 的端口到容器的 5000 端口
docker run -d -P training/webapp python app.py

#本地的 5000 端口映射到容器的 5000 端口
docker run -d -p 5000:5000 training/webapp python app.py

#加载一个数据卷到容器的 /webapp 目录
docker run -d -P --name web -v /webapp training/webapp python app.py

#加载主机的 /src/webapp 目录到容器的 /opt/webapp 目录
docker run -d -P --name web -v /src/webapp:/opt/webapp training/webapp python app.py

#--link 参数的格式为 --link name:alias，其中 name 是要链接的容器的名称，alias 是这个连接的别名。
docker run -d -P --name web --link db:db training/webapp python app.py
```

### dcoker start
直接将一个已经终止的容器启动运行。

```
docker start [OPTIONS] CONTAINER [CONTAINER...]
```

例:
``` bash
docker start myContainer
```

### dcoker stop
终止一个运行中的容器。用法与`dcoker start`相同。

### docker restart
将一个运行态的容器终止，然后再重新启动它。用法与`dcoker start`相同。

### docker kill
杀掉一个运行中的容器。
```
docker kill [OPTIONS] CONTAINER [CONTAINER...]
```

- -s :向容器发送一个信号

例如：
``` bash
docker kill -s KILL myContainer
```

### docker rm
删除一个或多个容器。
```
docker rm [OPTIONS] CONTAINER [CONTAINER...]
``` 
- -f :强制删除一个运行中的容器
- -l :移除容器间的网络连接，而非容器本身
- -v :-v 删除容器，并删除容器挂载的数据卷

``` bash
docker rm -f myContainer
```

### docker pause
暂停容器中所有的进程。
```
docker pause [OPTIONS] CONTAINER [CONTAINER...]
```

``` bash
docker pause myContainer
```

### docker unpause
恢复容器中所有的进程。用法与`dcoker pause`相同。


### docker create
创建一个新的容器但不启动它。用法与`docker run`相同。

### docker exec
在运行的容器中执行命令。
```
docker exec [OPTIONS] CONTAINER COMMAND [ARG...]
```

- -d: 后台运行容器，并返回容器ID
- -i: 以交互模式运行容器，通常与 -t 同时使用
- -t: 为容器重新分配一个伪输入终端，通常与 -i 同时使用

``` bash
#在容器mynginx中开启一个交互模式的终端
docker exec -i -t  mynginx /bin/bash
```

## 容器操作
``` bash
docker [ps|inspect|top|attach|events|logs|wait|export|port]
```

### docker ps
查看容器信息。
```
docker ps [OPTIONS]
```

- -a :显示所有的容器，包括未运行的
- -f :根据条件过滤显示的内容
- --format :指定返回值的模板文件
- -l :显示最近创建的容器
- -n :列出最近创建的n个容器
- --no-trunc :不截断输出
- -q :静默模式，只显示容器编号
- -s :显示总的文件大小

### docker inspect
 获取容器/镜像的元数据。

 ```
 docker inspect [OPTIONS] NAME|ID [NAME|ID...]
 ```

- -f :指定返回值的模板文件
- -s :显示总的文件大小
- --type :为指定类型返回JSON

``` bash
#获取正在运行的容器mymysql的 IP。
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mymysql

#输出
172.17.0.3
```

### docker top
查看容器中运行的进程信息，支持 ps 命令参数。
```
docker top [OPTIONS] CONTAINER [ps OPTIONS]
```

``` bash
docker top mymysql
```
### docker attach
连接到正在运行中的容器。
```
docker attach [OPTIONS] CONTAINER
```
但是使用 `attach` 命令有时候并不方便。当多个窗口同时 attach 到同一个容器的时候，所有窗口都会同步显示。当某个窗口因命令阻塞时,其他窗口也无法执行操作了。

> attach是可以带上--sig-proxy=false来确保CTRL-D或CTRL-C不会关闭容器。

``` bash
docker attach --sig-proxy=false myContainer
```

### docker events
```
docker events [OPTIONS]
```

- -f ：根据条件过滤事件
- --since ：从指定的时间戳后显示所有事件
- --until ：流水时间显示到指定的时间为止

``` bash
#显示docker 镜像为mysql:5.6 2016年7月1日后的相关事件。
docker events -f "image"="mysql:5.6" --since="1467302400" 

#输出

2016-07-11T00:38:53.975174837+08:00 container start 96f7f14e99ab9d2f60943a50be23035eda1623782cc5f930411bbea407a2bb10 (image=mysql:5.6, name=mymysql)
2016-07-11T00:51:17.022572452+08:00 container kill 96f7f14e99ab9d2f60943a50be23035eda1623782cc5f930411bbea407a2bb10 (image=mysql:5.6, name=mymysql, signal=9)
2016-07-11T00:51:17.132532080+08:00 container die 96f7f14e99ab9d2f60943a50be23035eda1623782cc5f930411bbea407a2bb10 (exitCode=137, image=mysql:5.6, name=mymysql)
2016-07-11T00:51:17.514661357+08:00 container destroy 96f7f14e99ab9d2f60943a50be23035eda1623782cc5f930411bbea407a2bb10 (image=mysql:5.6, name=mymysql)
...
```
### docker logs
获取容器的输出信息。
```
docker logs [OPTIONS] CONTAINER
```

- -f : 跟踪日志输出
- --since :显示某个开始时间的所有日志
- -t : 显示时间戳
- --tail :仅列出最新N条容器日志

``` bash
#跟踪查看容器mynginx的日志输出。
docker logs -f mynginx

#查看容器mynginx从2017年11月5日后的最新10条日志。
docker logs --since="2017-11-05" --tail=10 mynginx
```

### docker wait
阻塞运行直到容器停止，然后打印出它的退出代码。
```
docker wait [OPTIONS] CONTAINER [CONTAINER...]
```

``` bash
docker wait myContainer
```


### docker export
导出容器快照到本地文件。

```
docker export [OPTIONS] CONTAINER
```
- -o :将输入内容写到文件

``` bash
docker export -o ubuntu.tar 7691a814370e

#或者
docker export 7691a814370e > ubuntu.tar
```

### docker port
列出指定的容器的端口映射。
```
docker port [OPTIONS] CONTAINER [PRIVATE_PORT[/PROTO]]
```

``` bash
#查看容器myContainer的端口映射情况。
docker port myContainer
```

## 容器rootfs命令
``` bash
docker [commit|cp|diff]
```

### docker commit
从容器创建一个新的镜像。
``` 
docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
```

- -a :提交的镜像作者
- -c :使用Dockerfile指令来创建镜像
- -m :提交时的说明文字
- -p :在commit时，将容器暂停

``` bash
#将容器a404c6c174a2 保存为新的镜像,并添加提交人信息和说明信息。
docker commit -a "share.com" -m "my apache" a404c6c174a2  mymysql:v1 
```
### docker cp
用于容器与主机之间的数据拷贝。
``` bash
#将主机/www/share目录拷贝到容器96f7f14e99ab的/www目录下。
docker cp /www/share 96f7f14e99ab:/www/

#将主机/www/share目录拷贝到容器96f7f14e99ab中，目录重命名为www。
docker cp /www/share 96f7f14e99ab:/www

#将容器96f7f14e99ab的/www目录拷贝到主机的/tmp目录中。
docker cp  96f7f14e99ab:/www /tmp/
```
### docker diff
检查容器里文件结构的更改。
```
检查容器里文件结构的更改。
```

``` bash
#查看容器mymysql的文件结构更改。
docker diff mymysql
```

## 镜像仓库
``` bash
docker [login|pull|push|search]
```

### docker login/logot
登陆/登出 一个Docker镜像仓库，如果未指定镜像仓库地址，默认为官方仓库 Docker Hub
```
docker login/logout [OPTIONS] [SERVER]
```
- -u :登陆的用户名
- -p :登陆的密码

### docker pull
从镜像仓库中拉取或者更新指定镜像。
```
docker pull [OPTIONS] NAME[:TAG|@DIGEST]
```

- -a :拉取所有 tagged 镜像
- --disable-content-trust :忽略镜像的校验,默认开启

``` bash
#下载java最新版镜像
docker pull java
```
### docker push
将本地的镜像上传到镜像仓库，注意要先登陆到镜像仓库。
```
docker push [OPTIONS] NAME[:TAG]
```

- -disable-content-trust :忽略镜像的校验,默认开启

``` bash
#上传本地镜像myComtainer:v1到镜像仓库中

docker push myComtainer:v1
```

### docker search
从Docker 仓库查找镜像。
```
docker search [OPTIONS] TERM
```

- --automated :只列出 automated build类型的镜像；
- --no-trunc :显示完整的镜像描述；
- -s :列出收藏数不小于指定值的镜像。

``` bash
#从Docker Hub查找所有镜像名包含java，并且收藏数大于10的镜像
docker search -s 10 java
```
## 本地镜像管理
``` bash
docker [images|rmi|tag|build|history|save|import]
```

### docker images
列出本地镜像。
```
docker images [OPTIONS] [REPOSITORY[:TAG]]
```

- -a :列出本地所有的镜像（含中间映像层，默认情况下，过滤掉中间映像层）；
- --digests :显示镜像的摘要信息；
- -f :显示满足条件的镜像；
- --format :指定返回值的模板文件；
- --no-trunc :显示完整的镜像信息；
- -q :只显示镜像ID

### docker rmi
删除本地一个或多个镜像。
```
docker rmi [OPTIONS] IMAGE [IMAGE...]
```
- -f :强制删除
- --no-prune :不移除该镜像的过程镜像，默认移除

### docker tag
标记本地镜像，将其归入某一仓库。
```
docker tag [OPTIONS] IMAGE[:TAG] [REGISTRYHOST/][USERNAME/]NAME[:TAG]
```

``` bash
#将镜像ubuntu:15.10标记为 share/ubuntu:v3 镜像。
docker tag ubuntu:15.10 share/ubuntu:v3
```
### docker build
使用Dockerfile创建镜像。
```
docker build [OPTIONS] PATH | URL | -
```
- -t :指定要创建的目标镜像名
- --build-arg=[] :设置镜像创建时的变量；
- --cpu-shares :设置 cpu 使用权重；
- --cpu-period :限制 CPU CFS周期；
- --cpu-quota :限制 CPU CFS配额；
- --cpuset-cpus :指定使用的CPU id；
- --cpuset-mems :指定使用的内存 id；
- --disable-content-trust :忽略校验，默认开启；
- -f :指定要使用的Dockerfile路径；
- --force-rm :设置镜像过程中删除中间容器；
- --isolation :使用容器隔离技术；
- --label=[] :设置镜像使用的元数据；
- -m :设置内存最大值；
- --memory-swap :设置Swap的最大值为内存+swap，"-1"表示不限swap；
- --no-cache :创建镜像的过程不使用缓存；
- --pull :尝试去更新镜像的新版本；
- -q :安静模式，成功后只输出镜像ID；
- --rm :设置镜像成功后删除中间容器；
- --shm-size :设置/dev/shm的大小，默认值是64M；
- --ulimit :Ulimit配置。

``` bash
docker build -t nginx:v3 .
```

docker build 命令最后有一个 `.`。`.` 表示当前目录，而 Dockerfile 就在当前目录，因此不少初学者以为这个路径是在指定 Dockerfile 所在路径，这么理解其实是不准确的。如果对应上面的命令格式，你可能会发现，这是在指定上下文路径。

### docker history
查看指定镜像的创建历史。
```
docker history [OPTIONS] IMAGE
```

- -H :以可读的格式打印镜像大小和日期，默认为true；
- --no-trunc :显示完整的提交记录；
- -q :仅列出提交记录ID。


### docker save
将指定镜像保存成 tar 归档文件。
```
docker save [OPTIONS] IMAGE [IMAGE...]
```

- -o :输出到的文件

``` bash
#将镜像share/ubuntu:v3 生成my_ubuntu_v3.tar文档
docker save -o my_ubuntu_v3.tar share/ubuntu:v3
```
### docker import
从归档文件中创建镜像。

```
docker import [OPTIONS] file|URL|- [REPOSITORY[:TAG]]
```
- -c :应用docker 指令创建镜像
- -m :提交时的说明文字

``` bash
#容器快照导出到ubuntu.tar
docker export 7691a814370e > ubuntu.tar


#从镜像归档文件ubuntu.tar创建镜像，命名为share/ubuntu:v4
docker import  ubuntu.tar share/ubuntu:v4 
```
## info|version
``` bash
docker [info|version]
```

### docker info
显示 Docker 系统信息，包括镜像和容器数。

### docker version
显示 Docker 版本信息。

```
docker version [OPTIONS]
```

- -f :指定返回值的模板文件。

## docker 磁盘管理

### docker system df
``` bash
docker system df

#输出
TYPE                TOTAL               ACTIVE              SIZE                RECLAIMABLE
Images              9                   3                   1.534GB             1.254GB (81%)
Containers          3                   3                   2.133MB             0B (0%)
Local Volumes       6                   0                   514.3MB             514.3MB (100%)
Build Cache                                                 0B                  0B
```
`docker system df`类似`Linux`的`df`命令。

### docker system prune
`docker system prune`用于清理磁盘，删除状态`Exit`的容器，无用的数据卷和网络，以及dangling镜像，也就是**没有tag的镜像**。
`docker system prune -a`，清理更彻底，把**没有容器使用的镜像**全部删除。
建议谨慎使用。

### 其他常用命令

``` bash
#删除`Exit`的容器
docker rm -f `docker ps -a -q`

#删除没有tag的镜像
docker rmi $(docker images | grep "none" | awk '{print $3}')

#删除无用的数据卷
docker volume rm $(docker volumels -qf dangling=true)
```

## 参考文章

- [Docker — 从入门到实践](https://www.gitbook.com/book/yeasy/docker_practice/details)
- [Docker 命令大全](http://www.runoob.com/docker/docker-command-manual.html)