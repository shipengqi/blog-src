---
title: CentOs 安装配置 MySQL
date: 2017-04-27 13:20:10
categories: ["Database"]
---

安装参考官网 [Yum 安装 MySQL 文档](https://dev.mysql.com/doc/refman/8.0/en/linux-installation-yum-repo.html)。

<!-- more -->

## 安装步骤

### 添加 MySQL Yum Repository

1. 在 [这里](https://dev.mysql.com/downloads/repo/yum/) 下载。
2. 选择你要下载的版本下载。我的系统是 CentOs7：

```sh
wget https://repo.mysql.com//mysql80-community-release-el7-2.noarch.rpm
```

3. 下载好之后，使用下面的命令安装 RPM 包

```sh
yum localinstall mysql80-community-release-el7-2.noarch.rpm
```

这个安装命令会把 MySQL 的 Yum 源添加到系统的源列表中，并且下载 GnuPG key 校验软件包的完整性。使用下面的命令验证 MySQL 的 Yum 源是否添加成功：

```sh
yum repolist enabled | grep "mysql.*-community.*"
```

### 选择一个版本系列

使用 MySQL Yum Repository，默认会选择最新的 GA（Generally Available）系列（当前是MySQL 8.0）安装。如果这是你想要安装的版本，可以跳过这
一步。MySQL 的不同版本系列托管在不同的子仓库中。默认情况下启用了最新 GA 系列(当前 MySQL 8.0)的子仓库，并且其他版本的子仓库默认是禁用的。
使用下面的命令查看所有仓库的状态：

```sh
yum repolist all | grep mysql
```

安装指定的版本要先禁用最新的 GA 子仓库，并启用指定版本的子仓库。如果系统支持 `yum-config-manager`，可以使用 `yum-config-manager`，比如，
禁用 `5.7` 的子仓库并启用 `8.0`:

```sh
yum-config-manager --disable mysql57-community
yum-config-manager --enable mysql80-community
```

对于启用了 `dnf` 的系统，使用：

```sh
dnf config-manager --disable mysql57-community
dnf config-manager --enable mysql80-community
```

除了上面的方式，还可以手动修改 `/etc/yum.repos.d/mysql-community.repo` 文件：

```
[mysql57-community]
name=MySQL 5.7 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.7-community/el/6/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

# Enable to use MySQL 8.0
[mysql80-community]
name=MySQL 8.0 Community Server
baseurl=http://repo.mysql.com/yum/mysql-8.0-community/el/6/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
```

通过修改 `enabled` 的值来禁用和启用对应的版本仓库。`enabled=0` 表示禁用。使用 `yum repolist enabled | grep mysql` 检查状态。

> 注意，只能启用一个版本。

### 安装 MySQL

执行下面的命令安装 MySQL：

```sh
yum install mysql-community-server
```

这个命令安装 MySQL server(mysql-community-server)和运行 MySQL server 必要的组件，包括MySQL 客户端(mysql-community-client)等。

### 启动 MySQL

启动 MySQL：

```sh
systemctl start mysqld

# 检查
systemctl status mysqld
```

初次启动 MySQL server，要注意：

- SSL 证书和密钥文件在数据目录中生成。
- [validate_password](https://dev.mysql.com/doc/refman/8.0/en/validate-password.html) 被安装并启用。
- 会创建一个名为 `root` 的超级用户。密码可以使用 `grep 'temporary password' /var/log/mysqld.log` 来查看。使用生成的临时密码登录，
尽快更改 `root` 密码，并为超级用户帐户设置自定义密码:

```sh
mysql -uroot -p

# 修改密码
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Admin@111';
```

#### 报错：Your password does not satisfy the current policy requirements

说明密码太简单了。

## 配置

安装后，配置文件为 `/etc/my.cnf`。具体配置参数参考 [官网](https://dev.mysql.com/doc/refman/8.0/en/server-option-variable-reference.html)。

### MySQL 主从复制

环境说明和注意点：

- 假设有两台服务器，一台做主，一台做从
  - MySQL 主信息：
    - IP：10.5.4.247
    - 端口：3306
  - MySQL 从信息：
    - IP：10.5.4.248
    - 端口：3306
- 注意点
  - 主 DB server 和从 DB server 数据库的版本一致
  - 主 DB server 和从 DB server 数据库数据一致
  - 主 DB server 开启二进制日志，主 DB server 和从 DB server 的 server-id 都必须唯一
- 优先操作：
  - **把主库的数据库复制到从库并导入**

### 主库机子操作

- 主库操作步骤
  - 创建一个目录：`mkdir -p /usr/local/mysql/data/mysql-bin`
  - 主 DB 开启二进制日志功能：`vim /etc/my.cnf`，
    - 添加一行：`log-bin = /usr/local/mysql/data/mysql-bin`
    - 指定同步的数据库，如果不指定则同步全部数据库，其中 ssm 是我的数据库名：`binlog-do-db=ssm`
  - 主库关掉慢查询记录，用 SQL 语句查看当前是否开启：`SHOW VARIABLES LIKE '%slow_query_log%';`，如果显示 OFF 则表示关闭，ON 表示开启
  - 重启主库 MySQL 服务
  - 进入 MySQL 命令行状态，执行 SQL 语句查询状态：`SHOW MASTER STATUS;`
    - 在显示的结果中，我们需要记录下 **File** 和 **Position** 值，等下从库配置有用。
  - 设置授权用户 slave01 使用 123456 密码登录主库，这里 @ 后的 IP 为从库机子的 IP 地址，如果从库的机子有多个，我们需要多个这个 SQL 语句。

    ``` SQL
    grant replication slave on *.* to 'slave01'@'192.168.1.135' identified by '123456';
    flush privileges;
    ```

### 从库机子操作

- 从库操作步骤
  - 从库开启慢查询记录，用 SQL 语句查看当前是否开启：`SHOW VARIABLES LIKE '%slow_query_log%';`，如果显示 OFF 则表示关闭，ON 表示开启。
  - 测试从库机子是否能连上主库机子：`mysql -h 192.168.1.105 -u slave01 -p`，必须要连上下面的操作才有意义。
    - 由于不能排除是不是系统防火墙的问题，所以建议连不上临时关掉防火墙：`service iptables stop`
    - 或是添加防火墙规则：
      - 添加规则：`iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT`
      - 保存规则：`service iptables save`
      - 重启 iptables：`service iptables restart`
  - 修改配置文件：`vim /etc/my.cnf`，把 server-id 改为跟主库不一样
  - 在进入 MySQL 的命令行状态下，输入下面 SQL：

 ``` SQL
 CHANGE MASTER TO
 master_host='192.168.1.113',
 master_user='slave01',
 master_password='123456',
 master_port=3306,
 master_log_file='mysql3306-bin.000006',>>>这个值复制刚刚让你记录的值
 master_log_pos=1120;>>>这个值复制刚刚让你记录的值
 ```

- 执行该 SQL 语句，启动 slave 同步：`START SLAVE;`
- 执行该 SQL 语句，查看从库机子同步状态：`SHOW SLAVE STATUS;`
- 在查看结果中必须下面两个值都是 Yes 才表示配置成功：
  - `Slave_IO_Running:Yes`
    - 如果不是 Yes 也不是 No，而是 Connecting，那就表示从机连不上主库，需要你进一步排查连接问题。
  - `Slave_SQL_Running:Yes`
- 如果你的 Slave_IO_Running 是 No，一般如果你是在虚拟机上测试的话，从库的虚拟机是从主库的虚拟机上复制过来的，那一般都会这样的，因为两台
的 MySQL 的 UUID 值一样。你可以检
