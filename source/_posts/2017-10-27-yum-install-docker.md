---
title: CentOs安装Docker
date: 2017-10-27 10:44:08
categories: ["Linux"]
tags: ["Docker"]
---
CentOS 7通过yum安装docker。

<!-- more -->

## 配置yum代理
因为安装docker的服务器在公司内网，所以要配置代理，如果不是请忽略。
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

## 卸载旧版本
旧版本的 Docker 称为 docker 或者 docker-engine，使用以下命令卸载旧版本：
``` bash
$ sudo yum remove docker \
                  docker-common \
                  docker-selinux \
                  docker-engine
```

## 安装依赖包
``` bash
$ sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
```

## 添加 yum 软件源
因为使用公司代理，所以我这里使用官方源：
``` bash
$ sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

如果使用国内网络，建议使用国内源：
``` bash
$ sudo yum-config-manager \
    --add-repo \
    https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

如果需要最新版本的 Docker CE 使用以下命令:
``` bash
$ sudo yum-config-manager --enable docker-ce-edge

$ sudo yum-config-manager --enable docker-ce-test
```

## 安装 Docker CE
``` bash
#更新 yum 软件源缓存
$ sudo yum makecache fast

#安装 docker-ce
$ sudo yum install docker-ce
```

## 启动 Docker CE
``` bash
$ sudo systemctl enable docker
$ sudo systemctl start docker
```

## 添加docker代理
为docker配置公司代理：
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

如果没有代理，由于国内网络的问题，拉取 Docker 镜像会十分缓慢，建议配置 国内镜像加速：

- [Docker 官方提供的中国registry mirror]()
- [阿里云加速器]()
- [DaoCloud 加速器]()

注册用户并且申请加速器后，会获得 `https://********.mirror.aliyuncs.com` 这样的地址。
在 `/etc/docker/daemon.json` 中写入如下内容（如果文件不存在请新建该文件）

```json
{
  "registry-mirrors": [
    "https://********.mirror.aliyuncs.com",
  ]
}
```

之后重新启动服务。

```bash
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```


[Docker 官方 CentOS 安装文档](https://docs.docker.com/engine/installation/linux/docker-ce/centos/)