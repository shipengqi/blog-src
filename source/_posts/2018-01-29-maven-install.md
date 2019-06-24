---
title: Maven安装
date: 2018-01-29 16:15:29
categories: ["Linux"]
---

Maven官网下载地址：<http://maven.apache.org/download.cgi>

<!-- more -->

## 安装
Maven 3.3 的 JDK 最低要求是 JDK 7
``` bash
#下载压缩包
wget http://mirrors.cnnic.cn/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz

#解压
tar zxvf apache-maven-3.3.9-bin.tar.gz

mv apache-maven-3.3.9/ maven3.3.9/

mv maven3.3.9/ /usr/local

#配置环境变量：
sudo vim /etc/profile

#在文件的末尾，添加内容：

# Maven
MAVEN_HOME=/usr/local/maven3.3.9
PATH=$PATH:$MAVEN_HOME/bin
MAVEN_OPTS="-Xms256m -Xmx356m"
export MAVEN_HOME
export PATH
export MAVEN_OPTS

#使配置生效
source /etc/profile

#检查是否安装成功
mvn -version
```