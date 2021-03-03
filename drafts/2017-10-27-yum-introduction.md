---
title: Yum使用笔记
date: 2017-10-27 10:44:46
categories: ["Linux"]
---

`yum`（全称: Yellow dog Updater, Modified）是一个在基于`RPM`，为了提高`RPM`软件包安装性而开发的一种软件包管理器。
`yum`的关键之处 是要有可靠的软件仓库`repository`，yum在得到正确的参数后，会首先从`/etc/yum.repo`（repository）路径下的众repo文件中取得软件仓库的地址并下载、安装等，它可以是http或ftp站点，也可以是本地软件池，但必须包含rpm的header， header包括了rpm包的各种信息，
包括描述，功能，提供的文件，依赖性等.正是收集了这些 header并加以分析，才能自动化地完成余下的任务。



特点：

- 更方便的添加、删除、更新RPM包。
- 自动处理包的依赖性关系，方便系统更新及软件管理。
- 资源仓库(Repository)也可以配置多个。
- 简洁的配置文件(/etc/yum.conf)。

## yum命令

命令格式：

```
yum [options] COMMAND
```

命令(COMMAND)列表：

```
check          检测 rpmdb 是否有问题
check-update   检查可更新的包
clean          清除缓存的数据
deplist        显示包的依赖关系
distribution-synchronization 将已安装的包同步到最新的可用版本
downgrade      降级一个包
erase          删除包
groupinfo      显示包组的详细信息
groupinstall   安装指定的包组
grouplist      显示可用包组信息
groupremove    从系统删除已安装的包组
help           删除帮助信息
history        显示或使用交互历史
info           显示包或包组的详细信息
install        安装包
list           显示可安装或可更新的包
makecache      生成元数据缓存
provides       搜索特定包文件名
reinstall      重新安装包
repolist       显示已配置的资源库
resolvedep     指事实上依赖
search         搜索包
shell          进入yum的shell提示符
update         更新系统中的包，更新下载源里面的metadata，包括这个源有什么包、每个包什么版本之类的
upgrade        升级系统中的包，会根据update后的元信息对软件包进行升级
version        显示机器可用源的版本
```

常用选项(options)列表：

```
-h, --help          显示帮助信息
-t, --tolerant        容错
-C, --cacheonly       完全从系统缓存中运行，不更新缓存
-c [config file], --config=[config file]
                      本地配置文件
-R [minutes], --randomwait=[minutes]
                      命令最大等待时间
-d [debug level], --debuglevel=[debug level]
                      设置调试级别
-e [error level], --errorlevel=[error level]
                      设置错误等级
-q, --quiet           退出运行
-v, --verbose         详细模式
-y, --assumeyes       对所有交互提问都回答“yes”
```

## yum配置

yum全局配置文件只有一个`/etc/yum.conf`。
主要配置：

``` bash
[main]
cachedir=/var/cache/yum/$basearch/$releasever
            # yum 的缓存目录，用于存储下载的RPM包和数据库
keepcache=0
            # 安装完成后是否保留软件包，0为不保留（默认为0），1为保留
debuglevel=2
            # Debug 信息输出等级，范围为0-10，缺省为2
logfile=/var/log/yum.log
            # yum 日志文件位置，用户通过该文件查询做过的更新
exactarch=1
            # 是否只安装和系统架构匹配的软件包。可选项为：1､0，默认 1。设置为1时不会将i686的软件包安装在适合i386的系统中。
obsoletes=1
            # update 设置，是否允许更新陈旧的RPM包，相当于upgrade
gpgcheck=1
            # 是否进行 GPG(GNU Private Guard) 校验，以确定rpm 包的来源是有效和安全。当在这个选项设置在[main]部分，则对每个repository 都有效
plugins=1
            # 是否启用插件，默认1为允许，0表示不允许
exclude=*.i?86 kernel kernel-xen kernel-debug
            # 排除某些软件在升级名单之外，可以用通配符，各个项目用空格隔开
installonly_limit=5
            # 可同时安装多少程序包
bugtracker_url=http://bugs.centos.org/set_project.php?project_id=16&ref=http://bugs.centos.org/bug_report_page.php?category=yum
            # Bug 追踪路径
distroverpkg=centos-release
            # 当前发行版版本号

# PUT YOUR REPOS HERE OR IN separate files named file.repo
# in /etc/yum.repos.d
```

## yum源配置

yum源配置文件通常在`/etc/yum.repo.d`目录下。
目录下一般包含这些文件：

```
CentOS-Base.repo   用于配置yum网络源
CentOS-Media.repo    用于配置yum本地源
CentOS-Debuginfo.repo
CentOS-Vault.repo
```

### repo文件

repo文件是yum源（软件仓库）的配置文件，通常一个repo文件定义了一个或者多个软件仓库的细节内容，例如我们将从哪里下载需要安装或者升级的软件包，repo文件中的设置内容将被yum读取和应用。

常用属性：

- [serverid]：源标识，必须唯一，用于区别各个不同的repository。
- name：源名称，支持$releasever $basearch等变量名。
- mirrorlist：是一个包含有众多源镜像地址的列表的网站，yum安装或升级软件时，yum会试图依次从列表中所示的镜像源中进行下载，如果从一个镜像源下载失败，则会自动尝试列表中的下一个。若列表遍历完成依然没有成功下载到目标软件包，则向用户抛错。
- baseurl：是一个包库，支持的协议有 http:// ftp:// file://。
- gpgcheck：1 或 0，分别代表是否是否进行gpg校验，默认是检查。
- gpgkey：gpgkey则用来指明KEY文件的地址，同样支持“http、ftp和file”三种协议。
- exclude：exclude指明将哪些软件排除在升级名单之外，可以用通配符，列表中各个项目需用空格隔开。
- failovermethod：failovermethode在yum有多个源可供选择时，决定其选择的顺序。该属性有两个选项：roundrobin和priority。roundrobin是随机选择，如果连接失败，则使用下一个，依次循环。priority则根据url的次序从第一个开始，如果不指明，默认是roundrobin。
- enabled：1 或 0，分别代表启用或禁用软件仓库。

常用变量：

- $releasever：发行版的版本，从[main]部分的distroverpkg获取，如果没有，则根据redhat-release包进行判断。
- $arch，cpu体系，如i386、x86_64等。
- $basearch，cpu的基本体系组，如i686和athlon同属i386，alpha和alphaev6同属alpha。

### 配置yum本地源

``` bash
vim CentOS-Media.repo


# CentOS-Media.repo
#
# This repo is used to mount the default locations for a CDROM / DVD on
#  CentOS-6.  You can use this repo and yum to install items directly off the
#  DVD ISO that we release.
#
# To use this repo, put in your DVD and use it with the other repos too:
#  yum --enablerepo=c6-media [command]
#
# or for ONLY the media repo, do this:
#
#  yum --disablerepo=\* --enablerepo=c6-media [command]

[c6-media]
name=CentOS-$releasever - Media
# 本地源路径
baseurl=file:///media/CentOS/
        file:///media/cdrom/
        file:///media/cdrecorder/
gpgcheck=1
# 启用本地源
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
```

`baseurl` 中第2个路径修改为/mnt/cdrom（即光盘挂载点）。
将`enabled=0`改为1，启用本地源。
讲`CentOS-Base.repo` 中的`enabled`配置项改为`enabled=0`，或将`CentOS-Base.repo`文件删除或重命名，否则会先在网络源中寻找适合的包，改名之后直接从本地源读取。

### yum网络源

#### 配置国内 yum 源

网易（163）yum源是国内比较好的yum源之一 ，无论是速度还是软件版本，都非常的不错。
配置国内 yum 源，可以提升软件包安装和更新的速度，避免一些常见软件版本无法找到的问题。

``` bash
#备份/etc/yum.repos.d/CentOS-Base.repo
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup

#下载对应版本repo文件, 放入/etc/yum.repos.d/
wget http://mirrors.163.com/.help/CentOS6-Base-163.repo

#生成缓存
yum clean all
yum makecache
```

中科大的yum源：<https://lug.ustc.edu.cn/wiki/mirrors/help/centos>
sohu的yum源: <http://mirrors.sohu.com/help/centos.html>
阿里云镜像源地址：<http://mirrors.aliyun.com/>

#### 添加yum源、

网络源`CentOS-Base.repo`文件配置，配置一个源包括以下几个部分：

- [serverid] - 源标识，必须唯一
- name - 源名称，支付$releasever等变量名
- mirrorlist或baseurl - 其中，
  - mirrorlist是一个保存了镜像列表列表的网站
  - baseurl是一个包库
  
如，以下是CentOS 6.3中的一个配置镜像：

``` [contrib]
name=CentOS-$releasever - Contrib
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=contrib
#baseurl=http://mirror.centos.org/centos/$releasever/contrib/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
```

### 常见问题

#### repodata/repomd.xml: [Errno 14] HTTP Error 404 - Not Found

在浏览器中访问该文件，发现该文件不存在。修改`yum`源文件，例如`Centos`中的 `/etc/yum.repos.d/CentOS-Base.repo`，
修改文件中的源地址。可能是某个变量没有替换，例如 `http://mirrors.aliyun.com/centos/%24releasever/os/x86_64/repodata/repomd.xml: [Errno 14] HTTP Error 404 - Not Found`，中的 `$releasever` 没有替换为正确的版本号，导致 404 错误，如果是 CentOS 7 或者 RedHat 7，可以直接讲 `$releasever` 替换为 7。
