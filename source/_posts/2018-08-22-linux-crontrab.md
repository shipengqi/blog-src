---
title: Linux 定时任务
date: 2018-08-22 14:54:21
categories: ["Linux"]
---

在 `Linux` 下如何实现定时执行脚本。可以使用 `crontab`。

<!-- more -->

`Linux` 默认安装 `crontab`，一般被用来执行周期性任务。`crond` 进程会定期检查是否有要执行的任务，如果有，则自动执行。

## crontab 命令

```bash
crontab [OPTIONS] [ARGS]
```

**OPTIONS**

- `-e`：设置指定用户计时器；
- `-l`：列出指定用户的所有计时器设置；
- `-r`：删除指定用户的计时器设置；
- `-u`：指定用户名，如果不指定，默认是当前用户。

**ARGS**
指定要执行脚本文件。

## 系统任务和用户任务

### 系统任务

`/etc/crontab` 文件是系统任务的配置文件：

```bash
SHELL=/bin/bash  # 指定系统要使用的shell 这里是bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin # 指定系统执行命令的路径
MAILTO="" # 指定 crond 的任务执行信息将通过电子邮件发送给 root 用户，为空则不发送
HOME=/ # 指定在执行命令或者脚本时使用的主目录。

0 1 * * * root /user/local/run.sh
```

**注意系统任务要指定用户，如上面例子中的 `root`，否则会报错 `ERROR (getpwnam() failed)`**。

### 用户任务

用户定义的 `crontab` 文件保存在 `/var/spool/cron`，**文件名与用户名一致**。
还有两个文件比较重要：

- `/etc/cron.deny`: 包含了所有不允许使用 `crontab` 命令的用户
- `/etc/cron.deny`: 包含了所有允许使用 `crontab` 命令的用户

在用户的 `crontab` 文件中，每一行就是一个任务，怎么定义用户任务，我们以上面的 `crontab` 文件中的任务 `0 1 * * * root /user/local/run.sh`
为例，一行任务分为六段：

```bash
minute   hour   day   month   week   command
```

- `minute`： 分钟，从 `0` 到`59` 之间的任何整数。
- `hour`：小时，从 `0` 到 `23` 之间的任何整数。
- `day`：日期，从 `1` 到 `31` 之间的任何整数。
- `month`：月份，从 `1` 到 `12` 之间的任何整数。
- `week`: 星期几，从 `0` 到 `7` 之间的任何整数，`0` 或 `7` 代表星期日。
- `command`: 行的命令，可以是系统命令，也可以是脚本文件。

各段中还可以使用下面的字符：

- `*`：代表所有可能的值，例如 `month` 字段如果是星号，则表示在满足其它字段的制约条件后每月都执行该命令操作。
- `,`：可以用逗号隔开的值指定一个列表范围，例如，`1,2,5,7,8`
- `-`：可以用整数之间的中杠表示一个整数范围，如 `1-5` 表示 `1,2,3,4,5`
- `/`：可以用正斜线指定时间的间隔频率，例如 `0-23/2` 表示每两小时执行一次。同时正斜线可以和星号一起使用，如 `*/10`，如果用在 `minute` 字段，
表示每十分钟执行一次。

**Example**

```bash
* * * * * command
```

每分钟执行一次 `command`。

```bash
10,20 * * * * command
```

每小时的第 `10` 和第 `20` 分钟执行一次。

```bash
10,20 8-11 */2 * * command
```

每隔两天的上午 `8` 点到 `11` 点的第 `10` 和第 `20` 分钟执行。

```bash
10 1 * * 6,0 /etc/init.d/smb restart
```

每周六、周日的一点十分重启 smb

## crontab 中的环境变量

`crontab` 执行定时任务时自动执行失败，但是手动执行可以，报类似的错：`xx command not found`，这说明配置的环境变量未找到。这是应为 `crontab`
执行脚本时用的是系统的环境变量，用户定义的环境变量找不到。

解决方案：

1. 脚本中涉及到的的文件路径使用绝对路径。
2. 脚本中的命令式用户自定义的环境变量可以在脚本头部执行 `source` 命令引入环境变量，如 `source /etc/profile`。
3. 如果上述方法都无效，可以在 `crontab` 文件中引入环境变量，如 `* * * * * . /etc/profile;/bin/bash command`

## 其他问题

可以在任务后面加上 `* * * * * /root/install.sh >/dev/null 2>&1` 将日志重定向处理，避免 `crontab` 运行中有内容输出。

也可以追加到日志文件，如 `* * * * * /root/install.sh >> /root/install.log 2>&1`。
