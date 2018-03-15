---
title: RedHat安装Docker
date: 2017-10-11 19:16:46
categories: ["Linux"]
tags: ["Docker"]
---

关于Docker的通俗解释：
Docker的思想来自于集装箱，集装箱解决了什么问题？在一艘大船上，可以把货物规整的摆放起来。并且各种各样的货物被集装箱标准化了，集装箱和集装箱之间不会互相影响。
那么我就不需要专门运送水果的船和专门运送化学品的船了。只要这些货物在集装箱里封装的好好的，那我就可以用一艘大船把他们都运走。 docker就是类似的理念。现在都流行云计算了，云计算就好比大货轮，docker就是集装箱。

<!-- more -->

- 不同的应用程序可能会有不同的应用环境，比如.net开发的网站和php开发的网站依赖的软件就不一样，如果把他们依赖的软件都安装在一个服务器上就要调试很久，而且很麻烦，还会造成一些冲突。
比如IIS和Apache访问端口冲突。这个时候你就要隔离.net开发的网站和php开发的网站。常规来讲，我们可以在服务器上创建不同的虚拟机在不同的虚拟机上放置不同的应用，但是虚拟机开销比较高。
docker可以实现虚拟机隔离应用环境的功能，并且开销比虚拟机小，小就意味着省钱了。
- 你开发软件的时候用的是Ubuntu，但是运维管理的都是centos，运维在把你的软件从开发环境转移到生产环境的时候就会遇到一些Ubuntu转centos的问题，比如：有个特殊版本的数据库，只有Ubuntu支持，centos不支持，
在转移的过程当中运维就得想办法解决这样的问题。这时候要是有docker你就可以把开发环境直接封装转移给运维，运维直接部署你给他的docker就可以了。而且部署速度快。
- 在服务器负载方面，如果你单独开一个虚拟机，那么虚拟机会占用空闲内存的，docker部署的话，这些内存就会利用起来。 总之docker就是集装箱原理。

> 一个容器最好专注去做一个事情。虽然它可以既装 MySQL，又装 Redis，Nginx 等等，但是让一个容器只做好一件事是最合适的。


1. Docker要求Linux内核至少3.10，64-bit。
``` bash
#查看内核
uname -a
```

2. 因为安装docker的服务器在公司内网，所以要配置代理，如果不是请忽略。
``` bash
export http_proxy=<http proxy endpoint>
export https_proxy=$http_proxy
export HTTP_PROXY=$http_proxy
export HTTPS_PROXY=$http_proxy
export no_proxy=127.0.0.1,localhost
export NO_PROXY=$no_proxy

vim /etc/yum.conf
#添加行
proxy=http://web-proxy.isr.hp.com:8080
```

3. 更新yum源
``` bash
yum update -y
```

4. 添加docker.repo
``` bash
tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
```

5. 安装docker
``` bash
yum install docker-engine -y
```

6. 启用docker服务，系统启动时自动启动
``` bash
systemctl enable docker.service
```

7. 如果需要配置代理，添加docker代理
``` bash
mkdir /etc/systemd/system/docker.service.d
vim /etc/systemd/system/docker.service.d/http-proxy.conf

#添加下面的内容
[Service]
Environment="HTTP_PROXY={http proxy endpoint}" "NO_PROXY=localhost,127.0.0.1,docker-registry.somecorporation.com"

#重新载入 systemd，扫描新的或有变动的单元
systemctl daemon-reload

#查看环境变量属性
systemctl show --property=Environment docker

#重启docker服务
systemctl restart docker
```

8. 验证
``` bash
docker -v
#运行官方镜像hello world,检验是否安装成功。
docker run hello-world

#输出
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
5b0f327be733: Pull complete
Digest: sha256:b2ba691d8aac9e5ac3644c0788e3d3823f9e97f757f01d2ddc6eb5458df9d801
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://cloud.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/engine/userguide/
```

官网的安装手册：https://docs.docker.com/engine/installation/#docker-editions
官网的镜像仓库地址：https://store.docker.com/