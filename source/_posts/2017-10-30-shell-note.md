---
title: Shell笔记
date: 2017-10-30 10:07:53
categories: ["Linux"]
tags: ["Shell"]
---

Shell 是用 C 语言编写的，它是用户使用 Linux 的桥梁。

<!-- more -->

## 简单使用

``` bash
#!/bin/bash
echo "Hello World !"
```
`#!`是一个约定的标记，它告诉系统这个脚本需要哪一种 `Shell`来执行。

## 变量

### 定义变量
``` bash
name="Pooky"
```

注意：
- 变量名和等号之间不能有空格
- 变量名首字符必须为字母
- 变量名中间不能有空格或者其他标点符号，可以使用`_`
- 变量名不能使用bash里的关键字
- `shell`脚本中定义的变量是`global`的，其作用域从被定义的地方开始，到`shell`结束或
被显示删除的地方为止。
- `shell`函数中定义的变量默认是`global`的，其作用域从“函数被调用时执行变量定义的地方”开始，到`shell`结束或被显示删除处为止。函数定义的变量可以被显示定义成local的，其作用域局限于函数内。

### 定义local变量
``` bash
set_node_env() {
  local NODE_ENV="dev"
}

get_node_env() {
  echo ${NODE_ENV}
}

set_node_env
get_node_env
```
这里的`get_node_env`中的`echo ${NODE_ENV}`是不会打印`dev`的。

### 变量默认值
``` bash
#当变量a为null时则var=b  
var=${a-b} 

#当变量a为null或为空字符串时则var=b  
var=${a:-b} 
```

### 使用变量
使用变量只要在变量名前面加`$`。
``` bash
name="Pooky"
echo "hello ${name}"

#或者
#echo "hello $name"
```
推荐给变量加上花括号，帮助解释器识别变量的边界。

### 只读
只读变量只要在变量名前面加`readonly `。
``` bash
name="Pooky"
echo "hello ${name}"
readonly name
name = "Pooky2"
```
运行脚本:
``` bash
NAME: This variable is read only.
```

### 删除变量
``` bash
name="Pooky"
unset name
```

### 字符串
shell编程中字符串可以用单引号，也可以用双引号，也可以不用引号。
单双引号的区别：
- 双引号里可以有变量
- 双引号里可以出现转义字符
- 单引号字串中不能出现单引号

#### 操作字符串
``` bash

#字符串拼接
name="Pooky"
hello_1="hello, "$your_name" !"
hello_2="hello, ${your_name} !"
echo $hello_1 $hello_2

#字符串长度
name="Pooky"
echo ${#name} #输出 5


#查找字符串
string="hello pooky"
echo `expr index "$string" ky`  # 输出 10

#字符串截取
#假设有变量 var=http://www.aaa.com/123.htm
#1. `#`号截取，删除左边字符，保留右边字符。

echo ${var#*//}

#`var` 是变量名，`#`号是运算符，`*//` 表示从左边开始删除第一个 `//` 号及左边的所有字符
#即删除 `http://`
#结果是 ：`www.aaa.com/123.htm`

#2. `##` 号截取，删除左边字符，保留右边字符。

echo ${var##*/}

#`##*/`表示从左边开始删除最后（最右边）一个 `/` 号及左边的所有字符
#即删除 `http://www.aaa.com/`
#结果是 `123.htm`

#3. `%`号截取，删除右边字符，保留左边字符

echo ${var%/*}

#`%/*` 表示从右边开始，删除第一个 `/` 号及右边的字符
#结果是：`http://www.aaa.com`

#4. `%%` 号截取，删除右边字符，保留左边字符

echo ${var%%/*}


#`%%/*` 表示从右边开始，删除最后（最左边）一个 `/` 号及右边的字符
#结果是：`http:`

#5. 从左边第几个字符开始，及字符的个数

echo ${var:0:5}

#其中的 `0` 表示左边第一个字符开始，`5` 表示字符的总个数。
#结果是：`http:`

#6. 从左边第几个字符开始，一直到结束。

echo ${var:7}

#其中的 `7` 表示左边第8个字符开始，一直到结束。
#结果是 ：`www.aaa.com/123.htm`

#7. 从右边第几个字符开始，及字符的个数

echo ${var:0-7:3}

#其中的 `0-7` 表示右边算起第七个字符开始，`3` 表示字符的个数。
#结果是：`123`

#8. 从右边第几个字符开始，一直到结束。
echo ${var:0-7}

#表示从右边第七个字符开始，一直到结束。
#结果是：`123.htm`
#注：（左边的第一个字符是用 `0` 表示，右边的第一个字符用 `0-1` 表示）
```



### 数组

``` bash
#定义数组
names=(pooky pooky1 pooky2 pooky3)

#获取元素
echo ${names[0]}

#获取所有元素
echo ${names[@]}

# 取得数组元素的个数
length=${#array_name[@]}
# 或者
length=${#array_name[*]}
```


## 脚本参数
在执行 Shell 脚本时，向脚本传递参数，脚本内获取参数的格式为：$n。n 代表一个数字，1 为执行脚本的第一个参数，2 为执行脚本的第二个参数，以此类推……

``` bash
#!/bin/bash
# this is demo.sh

echo "文件名：$0";
echo "第一个参数：$1";
echo "第二个参数：$2";
echo "第三个参数：$3";
```

一些参数字符：
- `$#`: 传递到脚本的参数个数
- `$*`: 显示所有向脚本传递的参数
- `$$`: 当前进程ID
- `$!`: 后台运行的最后一个进程的ID
- `$@`: 与$*相同，但是使用时加引号，并在引号中返回每个参数。
- `$-`: 显示Shell使用的当前选项，与set命令功能相同。
- `$?`: 显示最后命令的退出状态。0表示没有错误，其他任何值表明有错误。

``` bash
./demo.sh 1 2 3
文件名：./demo.sh
第一个参数：1
第二个参数：2
第三个参数：3
```
$* 与 $@ 区别:
假设在脚本运行时写了三个参数 1、2、3，，则 " * " 等价于 "1 2 3"（传递了一个参数），而 "@" 等价于 "1" "2" "3"（传递了三个参数）。

## 运算符

### 算术运算符
``` bash
#!/bin/bash

a=1
b=2

val=`expr $a + $b`
echo "a + b : $val"

val=`expr $a - $b`
echo "a - b : $val"

#乘号(*)前必须加反斜杠(\)
val=`expr $a \* $b`
echo "a * b : $val"

val=`expr $b / $a`
echo "b / a : $val"

val=`expr $b % $a`
echo "b % a : $val"

if [ $a == $b ]
then
   echo "a 等于 b"
fi
if [ $a != $b ]
then
   echo "a 不等于 b"
fi
```

输出：
``` bash
a + b : 3
a - b : -1
a * b : 20
b / a : 2
b % a : 0
a 不等于 b
```

### 关系运算符
- `-eq` ：两个数是否相等
- `-ne` ：两个数是否不相等
- `-gt` ：左边的数是否大于右边的
- `-lt` ：左边的数是否小于右边的
- `-ge` ：左边的数是否大于等于右边的
- `-le` ：左边的数是否小于等于右边的

``` bash

if [ $a -eq $b ]
then
   echo "$a -eq $b : a 等于 b"
fi
if [ $a -ne $b ]
then
   echo "$a -ne $b: a 不等于 b"
fi
if [ $a -gt $b ]
then
   echo "$a -gt $b: a 大于 b"
fi
if [ $a -lt $b ]
then
   echo "$a -lt $b: a 小于 b"
fi
if [ $a -ge $b ]
then
   echo "$a -ge $b: a 大于或等于 b"
fi
if [ $a -le $b ]
then
   echo "$a -le $b: a 小于或等于 b"
fi
```

### 其他运算符
#### 字符串运算符

- `=`: 两个字符串是否相等  (相等返回 true)
- `!=`: 两个字符串是否相等  (不相等返回 true)
- `-z`: 字符串长度是否为0 (为0返回 true)
- `-n`: 字符串长度是否为0 (不为0返回 true)
- `str`: 字符串是否为空   (不为空返回 true)

#### 布尔运算符
`!`非运算，`-o`或运算，`-a`与运算。

#### 逻辑运算符
`&&`逻辑与，`||`逻辑或

#### 文件测试运算符

- `-b file`: 文件是否是块设备文件
- `-c file`: 文件是否是字符设备文件
- `-d file`: 文件是否是目录
- `-f file`: 文件是否是普通文件（既不是目录，也不是设备文件）
- `-g file`: 文件是否设置了 SGID 位
- `-k file`: 文件是否设置了粘着位(Sticky Bit)
- `-p file`: 文件是否是有名管道
- `-u file`: 文件是否设置了 SUID 位
- `-r file`: 文件是否可读
- `-w file`: 文件是否可写
- `-x file`: 文件是否可执行
- `-s file`: 文件是否为空（文件大小是否大于0）
- `-e file`: 文件（包括目录）

``` bash
a=10
b=20

if [ $a -lt 100 -a $b -gt 15 ]
then
   echo "$a 小于 100 且 $b 大于 15 : 返回 true"
fi

if [ $a -lt 100 -o $b -gt 100 ]
then
   echo "$a 小于 100 或 $b 大于 100 : 返回 true"
fi




if [[ $a -lt 100 && $b -gt 100 ]]
then
   echo "返回 true"
fi


file="./demo.sh"
if [ -r $file ]
then
   echo "文件可读"
fi
```

## 流程控制
if else 语法要注意：else分支没有语句执行，就不要写else。
``` bash
if [ -e $file ]
then
   echo "文件存在"
fi

a=10
b=20

if [ $a == $b ]
then
   echo "a 等于 b"
elif [ $a -gt $b ]
then
   echo "a 小于 b"
else
   echo "没有符合的条件"
fi

#for循环
for loop in 1 2 3 4 5
do
    echo "The value is: $loop"
done

#while循环
int=1
while(( $int<=5 ))
do
    echo $int
    let "int++"
done
```

case语句: 取值后面必须为单词in，每一模式必须以`)`结束。取值可以为变量或常数。匹配发现取值符合某一模式后，其间所有命令开始执行直至 `;;`。
一旦模式匹配，则执行完匹配模式相应命令后不再继续其他模式。如果无一匹配模式，使用星号 `*` 捕获该值，再执行后面的命令。


``` bash
echo '你输入的数字为:'
read aNum
case $aNum in
    1)  echo '你选择了 1'
    ;;
    2)  echo '你选择了 2'
    ;;
    *)  echo "你输入的数字 ${aNum}"
    ;;
esac

while :
do
    echo -n "输入 1 到 5 之间的数字:"
    read aNum
    case $aNum in
        1|2|3|4|5) echo "你输入的数字为 $aNum!"
        ;;
        *) echo "你输入的数字不是 1 到 5 之间的! 游戏结束"
         
        ;;
    esac
done

```
## 函数
### 函数定义
``` bash
sayHello(){
    echo "hello pooky!"
}

#调用
sayHello

#输出
hello pooky!
```

不加`return`，将以最后一条命令运行结果，作为返回值。

### 函数参数
``` bash
sayHello(){
    echo "hello $1 !"
    echo "hello $2 !"
    echo "hello $10 !"
    echo "hello ${10} !"
    echo "hello ${11} !"
    echo "参数总数有 $# 个!"
    echo "所有参数 $* !"
}
sayHello 1 2 3 4 5 6 7 8 9 34 73

#输出
hello 1 !
hello 2 !
hello 10 !
hello 34 !
hello 73 !
参数总数有 11 个!
所有参数 1 2 3 4 5 6 7 8 9 34 73 !
```
注意，`$10` 不能获取第十个参数，获取第十个参数需要`${10}`。当`n>=10`时，需要使用`${n}`来获取参数。

## 输入输出重定向
- `command > file`	将输出重定向到 file。
- `command < file`	将输入重定向到 file。
- `command >> file`	将输出以追加的方式重定向到 file。
- `n > file`	将文件描述符为 n 的文件重定向到 file。
- `n >> file`	将文件描述符为 n 的文件以追加的方式重定向到 file。
- `n >& m`	将输出文件 m 和 n 合并。
- `n <& m`	将输入文件 m 和 n 合并。
- `<< tag`	将开始标记 tag 和结束标记 tag 之间的内容作为输入。
``` bash
cat << EOF
hello
pooky
EOF

#输出
hello
pooky
```

一般情况下，Linux 命令运行时会打开三个文件：
标准输入文件(stdin)：stdin的文件描述符为0，Unix程序默认从stdin读取数据。
标准输出文件(stdout)：stdout 的文件描述符为1，Unix程序默认向stdout输出数据。
标准错误文件(stderr)：stderr的文件描述符为2，Unix程序会向stderr流中写入错误信息。
默认情况下，command > file 将 stdout 重定向到 file，command < file 将stdin 重定向到 file。
stderr 重定向到 file：
``` bash
command 2 > file
```
stderr 追加到 file 文件末尾：
``` bash
command 2 >> file
```
`2` 表示标准错误文件(stderr)。
stdout 和 stderr 合并后重定向到 file：
``` bash
command > file 2>&1

#或者
command >> file 2>&1
```

stdin 和 stdout 都重定向：
``` bash
command < file1 >file2

#执行某个命令，屏幕上不显示输出结果，那么可以将输出重定向到 /dev/null：
command > /dev/null

```
command 命令将 stdin 重定向到 file1，将 stdout 重定向到 file2。
`/dev/null` 是一个特殊的文件，写入到它的内容都会被丢弃；从该文件读取内容，也什么都读不到。将命令的输出重定向到它，会起到"禁止输出"的效果。

## 引用外部脚本

创建两个脚本文件demo1.sh，demo2.sh。

``` bash
#!/bin/bash
#this is demo1

name="Pooky"
```

``` bash
#!/bin/bash
#this is demo2

#引用文件
. ./demo1.sh

#或者
#source ./demo1.sh

echo "hello $name"
```

## 常见问题

### No such file or directory
``` bash
./start.sh

#输出

-bash: ./start.sh: /bin/bash^M: bad interpreter: No such file or directory
```
解决：

``` bash
vim start.sh

#step 1
set ff=unix

#setp 2
wq
```

