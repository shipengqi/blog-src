---
title: JDK安装
date: 2018-01-29 15:50:50
categories: ["Linux"]
tags: ["JDK"]
---

JDK 官网下载地址 ：<http://www.oracle.com/technetwork/java/javase/downloads/>

<!-- more -->



## CentOs下安装
JDK 在 CentOS 和 Ubuntu 下安装过程是一样的。
默认情况下， CentOS 安装有 openJDK，建议先卸载掉默认安装的openJDK，在进行安装。
### 卸载掉默认安装的openJDK
``` bash
#查询本地 JDK 安装程序情况
rpm -qa|grep java

#查询结果
java-1.6.0-openjdk-1.6.0.38-1.13.10.0.el6_7.x86_64
java-1.7.0-openjdk-1.7.0.95-2.6.4.0.el6_7.x86_64
tzdata-java-2015g-2.el6.noarch

#CentOS 6 卸载
sudo rpm -e --nodeps java-1.6.0-openjdk-1.6.0.38-1.13.10.0.el6_7.x86_64
sudo rpm -e --nodeps java-1.7.0-openjdk-1.7.0.95-2.6.4.0.el6_7.x86_64
sudo rpm -e --nodeps tzdata-java-2015g-2.el6.noarch

#CentOS 7 卸载
sudo rpm -e --nodeps javapackages-tools-3.4.1-11.el7.noarch \
java-1.8.0-openjdk-1.8.0.121-0.b13.el7_3.x86_64 \
java-1.7.0-openjdk-headless-1.7.0.131-2.6.9.0.el7_3.x86_64 \
python-javapackages-3.4.1-11.el7.noarch java-1.7.0-openjdk-1.7.0.131-2.6.9.0.el7_3.x86_64 \
java-1.8.0-openjdk-headless-1.8.0.121-0.b13.el7_3.x86_64 \
tzdata-java-2017a-1.el7.noarch
```

> `--nodeps` 的作用：忽略依赖的检查

### 安装
建议在`/opt/packages` 存放各种软件安装包；在 `/usr/local` 目录下存放解压后的软件包。
``` bash
#解压安装包
sudo tar -zxvf jdk-8u72-linux-x64.tar.gz

mv jdk1.8.0_72/ /usr/local/

#配置环境变量：
sudo vim /etc/profile

#在文件的末尾，添加内容：

# JDK
JAVA_HOME=/usr/local/jdk1.8.0_72
JRE_HOME=$JAVA_HOME/jre
PATH=$PATH:$JAVA_HOME/bin
CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export JAVA_HOME
export JRE_HOME
export PATH
export CLASSPATH

#使配置生效
source /etc/profile

#检查是否安装成功
java -version
```
