---
title: Linux 环境变量设置
date: 2017-06-22 20:05:53
categories: ["Linux"]
---

Linux 下环境变量设置，可以在通过 `export` 命令在控制台中设置，也可修改 `profile` 文件或者 `bashrc` 文件。

<!-- more -->

## export命令

控制台中用户利用 `export` 命令，在当前终端下声明环境变量，只对当前的 Shell 终端起作用，关闭 Shell 终端失效。如:
``` bash
export  NODE_ENV="production"
```
## 修改 profile 文件

用户登录时，文件会被执行。修改 `profile` 文件，环境变量对该系统中所有用户都永久有效。因为所有用户的 Shell 终端都有权使用这个环境变量，可能会
给系统带来安全性问题。添加环境变量时，可以在行尾使用 `;` 号，也可以不使用。一个变量名可以对应多个变量值，多个变量值使用 `:` 分隔。

```bash
PATH=$PATH:<PATH 1>:<PATH 2>:<PATH 3>:....:<PATH N>
```

**Example:**
``` bash
vim /etc/profile

# 添加
export  NODE_ENV="production"

# node
export NODE_HOME=/usr/local/node/v8.11.4
export PATH=$NODE_HOME/bin:$PATH

# yarn
YARN_INSTALL_DIR=/usr/local/yarn/v1.9.4
PATH=$PATH:$YARN_INSTALL_DIR/bin

# proxy
export http_proxy=http://web-proxy.net:8080
export https_proxy=$http_proxy
export HTTP_PROXY=$http_proxy
export HTTPS_PROXY=$http_proxys
export no_proxy=127.0.0.1,localhost
export NO_PROXY=$no_proxy

# 使配置生效
source /etc/profile

# 查看是否生效
$ echo $NODE_ENV
```
## 修改 bashrc 文件

bashrc 文件有两种:`/etc/bashrc` 和 `~/.bashrc`。bashrc 只会被 bash shell 调用。
`/etc/bashrc` 对该系统中所有用户都永久有效，当用户打开 Shell 终端时，该文件被读取，修改后无需重启，重新开一个 Shell 终端即可生效，也可以使
用 source 命令强制立即生效。

`~/.bashrc` 只对某个用户永久有效，当登录或打开新的 Shell 终端时，文件被读取，修改后无需重启，重新开一个 Shell 终端即可生效，也可以使用 source 
命令强制立即生效。修改用户主目录下的 `~/.bashrc` 文件，对某个用户永久有效。这种方法相对安全。
``` bash
vim ~/.bashrc

# 添加
export  NODE_ENV="production"

# 使配置生效
source ~/.bashrc
```

## 修改 bash_profile 文件

用户登录时，文件会被执行。`~/.bash_profile` 文件只对某个用户永久有效，和 `profile` 文件作用类似。
``` bash
vim ~/.bash_profile

# 添加
export  NODE_ENV="production"

# 使配置生效
source ~/.bash_profile
```

## 常见环境变量
* `$PATH`：决定了shell将到哪些目录中寻找命令或程序
* `$HOME`：当前用户主目录。
* `$SHELL`：指当前用户用的是哪种 Shell。
* `$LOGNAME`：指当前用户的登录名。
* `$HOSTNAME`：指主机的名称。
* `$HISTSIZE`：指保存历史命令记录的条数。
* `$LANG/LANGUGE`：和语言相关的环境变量，使用多种语言的用户可以修改此环境变量。
* `$MAIL`：指当前用户的邮件存放目录。
* `$PS1`：是基本提示符，对于 root 用户是 `#`，对于普通用户是 `$`，也可以使用一些更复杂的值。
* `$PS2`：是附属提示符，默认是 `>`。可以通过修改此环境变量来修改当前的命令符。
* `$IFS`：输入域分隔符。当 Shell 读取输入时，用来分隔单词的一组字符，它们通常是空格、制表符和换行符。
* `$0`：shell 脚本的名字。
* `$#`：传递给脚本的参数个数。

``` bash
# 在 shell 中
echo $0
# 输出
/usr/bin/bash

echo $#
# 输出
0
```

## 环境变量相关的命令
* `export` 设置一个新的环境变量 `export  NODE_ENV="production"` (可以无引号)
* `echo` 显示某个环境变量值 `echo $NODE_ENV`
* `env` 显示所有环境变量
* `set` 显示本地定义的 shell 变量
* `unset` 清除环境变量 `unset NODE_ENV`
* `readonly` 设置只读环境变量 `readonly HELLO`

``` bash
set
# 输出
BASH=/bin/bash
...

export  NODE_ENV="production"
readonly NODE_ENV  # 将环境变量 NODE_ENV 设为只读
unset NODE_ENV
# 输出 发现此变量不能被删除
-bash: unset: NODE_ENV: cannot unset: readonly variable
```




