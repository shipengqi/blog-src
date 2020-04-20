---
title: CentOS 安装 Node.js
date: 2017-10-12 20:03:27
categories: ["Linux"]
---

在 CentOS 上用源码安装 Node.js。

<!-- more -->

1. 官网下载 [node](https://nodejs.org/en/download/) 。
``` bash
wget https://nodejs.org/dist/v6.11.4/node-v6.11.4-linux-x64.tar.xz

# /usr/local/node/
mkdir /usr/local/node/
mv ./node-v6.11.4-linux-x64 /usr/local/node/
```

2. 解压源码
``` bash
tar -xvf node-v6.11.4-linux-x64.tar.xz
```

3. Node 环境配置
``` bash
vim /etc/profile

# 在 export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE HISTCONTROL 一行的上面添加

# nodejs
export NODE_HOME=/usr/local/node/6.11.4
export PATH=$NODE_HOME/bin:$PATH

# 编译/etc/profile 使配置生效
source /etc/profile
```

4. 验证
``` bash
node -v
npm -v
```