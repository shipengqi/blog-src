---
title: Redis 数据类型 List
date: 2018-04-05 22:11:39
categories: ["数据库"]
tags: ["Redis"]
---

`Redis`列表(Lists)是简单的字符串列表，并根据插入顺序进行排序。一个`Redis`列表中最多可存储`232-1`(40亿)个元素。

<!-- more -->

`Redis`的列表和`Java`的`LinkedList`类似，注意它是链表而不是数组。这意味着`List`的插入和删除操作非常快，但是索引定位很慢。
当列表移除了最后一个元素之后，该`key`会被自动被删除，内存被回收。


`Redis`的列表结构常用来做异步队列使用。将需要延后处理的任务结构体序列化成字符串塞进列表，另一个线程从这个列表中读取数据进行处理。

## 存取
### LPUSH
将一个或多个值`value`插入到列表`key`的头部。

```bash
LPUSH key value [value ...]
```
如果有多个`value`，那么从左到右依次插入列表。如果`key`不存在，首先会创建一个空列表再执行`LPUSH`操作。
命令执行成功，返回列表的长度。如果`key`存在，但不是`List`类型，会返回一个错误。

```bash
# 加入单个元素
redis> LPUSH languages python
(integer) 1

# 加入重复元素
redis> LPUSH languages python
(integer) 2
redis> LRANGE languages 0 -1     # 列表允许重复元素
1) "python"
2) "python"

# 加入多个元素
redis> LPUSH mylist a b c
(integer) 3
redis> LRANGE mylist 0 -1
1) "c"
2) "b"
3) "a"
```
### LPUSHX
`LPUSHX`和`LPUSH`相同，不同的是，`LPUSHX`一次只能插入一个`value`，而且只有当`key`存在且是`List`类型时，才会将值`value`插入到列表`key`的头部。
如果`key`不存在，则不执行操作。

```bash
LPUSHX key value
```

命令执行成功，返回列表的长度。如果`key`存在，但不是`List`类型，会返回一个错误。

```bash
# 对空列表执行 LPUSHX
redis> LLEN greet
(integer) 0
redis> LPUSHX greet "hello"    # LPUSHX 失败，因为列表为空
(integer) 0

# 对非空列表执行 LPUSHX
redis> LPUSH greet "hello" # 这次 LPUSHX 执行成功
(integer) 1
redis> LPUSHX greet "good morning"
(integer) 2
redis> LRANGE greet 0 -1
1) "good morning"
2) "hello"

# 非列表类型，返回错误
redis> set key value
OK
redis> lpush key xxx
(error) WRONGTYPE Operation against a key holding the wrong kind of value
```
### RPUSH
`RPUSH`是将一个或多个值`value`插入到列表`key`的尾部。

```bash
RPUSH key value [value ...]
```
如果`key`不存在，会首先创建一个空列表，再执行`RPUSH`。
返回执行`RPUSH`后列表的长度。

```bash
# 添加单个元素
redis> RPUSH languages c
(integer) 1

# 添加重复元素
redis> RPUSH languages c
(integer) 2
redis> LRANGE languages 0 -1 # 列表允许重复元素
1) "c"
2) "c"

# 添加多个元素
redis> RPUSH mylist a b c
(integer) 3
redis> LRANGE mylist 0 -1
1) "a"
2) "b"
3) "c"
```

### RPUSHX
`RPUSHX`和`RPUSH`相同，不同的是，`RPUSHX`一次只能插入一个`value`，而且只有当`key`存在且是`List`类型时，才会将值`value`插入到列表`key`的尾部。
如果`key`不存在，则不执行操作。

```bash
RPUSHX key value
```

返回执行`RPUSH`后列表的长度。

```bash
# key不存在
redis> LLEN greet
(integer) 0
# 对不存在的 key 进行 RPUSHX，PUSH 失败。
redis> RPUSHX greet "hello"
(integer) 0

# key 存在且是一个非空列表
# 先用 RPUSH 插入一个元素
redis> RPUSH greet "hi"
(integer) 1
 # greet 是一个列表类型，RPUSHX 操作成功
redis> RPUSHX greet "hello"
(integer) 2
redis> LRANGE greet 0 -1
1) "hi"
2) "hello"
```

### LINSERT
将`value`插入`key`中指定`pivot`元素的前面或后面。
如果`pivot`或`key不`存在则不执行任何操作。
```bash
LINSERT key BEFORE|AFTER pivot value
```

操作成功，返回插入之后，列表的长度。`pivot`不存在，返回`-1`。如果`key`不存在或为空，则返回`0`，如果`key`不是一个列表类型，则返回一个错误。
```bash
redis> RPUSH mylist "Hello"
(integer) 1
redis> RPUSH mylist "World"
(integer) 2
redis> LINSERT mylist BEFORE "World" "There"
(integer) 3
redis> LRANGE mylist 0 -1
1) "Hello"
2) "There"
3) "World"

# 对一个非空列表插入，查找一个不存在的 pivot
redis> LINSERT mylist BEFORE "go" "let's"
(integer) -1                  # 失败

# 对一个空列表执行 LINSERT 命令
redis> EXISTS fake_list
(integer) 0
redis> LINSERT fake_list BEFORE "nono" "gogogog"
(integer) 0                                      # 失败
```

### LPOP

返回`key`列表中的头元素。

```bash
LINSERT key BEFORE|AFTER pivot value
```

如果`key`不存在，则返回`nil`。

```bash
redis> LLEN course
(integer) 0
redis> RPUSH course algorithm001
(integer) 1
redis> RPUSH course c++101
(integer) 2
redis> LPOP course  # 移除头元素
"algorithm001"
```

### BLPOP

`BLPOP`是`LPOP`类似，但是`BLPOP`在列表为空时，当前连接会被`BLPOP`阻塞，直到超时或有另一个客户端PUSH了可弹出的元素为止。
当指定多个`key`参数时，会按`key`的先后顺序依次检查各个列表，并弹出第一个非空列表的头元素。
`timeout`参数表示阻塞的时长，单位为秒，**注意如果`timeout`为`0`，表示可以无限期延长阻塞。**

```bash
BLPOP key [key ...] timeout
```

如果列表为空，返回一个`nil`。 否则，返回一个含有两个元素的列表，第一个元素是被弹出元素所属的`key`，第二个元素是被弹出元素的值。

#### `BLPOP`命令的非阻塞行为
例如，现在有`job`、`command`和`request`三个列表，`job`不存在，而`command`和`request`都是非空列表：
```bash
 # 确保key都被删除
redis> DEL job command request
(integer) 0

# 为command列表增加一个值
redis> LPUSH command "update system..."
(integer) 1
# 为request列表增加一个值
redis> LPUSH request "visit page"
(integer) 1

# job 列表为空，被跳过，紧接着 command 列表的第一个元素被弹出。
redis> BLPOP job command request 0
1) "command"                     # 弹出元素所属列表的key
2) "update system..."            # 弹出元素的值
```

#### `BLPOP`命令的阻塞行为
当指定的所有`key`都不存在或包含空列表，`BLPOP`命令将阻塞连接，直到等待超时，或有可弹出元素为止。


### RPOP
移除并返回`key`列表的尾元素。
```bash
RPOP key
```

当`key`不存在时，返回`nil`。

```bash
edis> RPUSH mylist "one"
(integer) 1

redis> RPUSH mylist "two"
(integer) 2

redis> RPUSH mylist "three"
(integer) 3

redis> RPOP mylist           # 返回被弹出的元素
"three"

redis> LRANGE mylist 0 -1    # 列表剩下的元素
1) "one"
2) "two"
```
### BRPOP
`BRPOP`和`BLPOP`基本相同，不同点在于一个弹出头部元素，一个是尾部元素，而且会阻塞操作。

```bash
BRPOP key [key ...] timeout
```

注意`BRPOP`弹出的元素，一样会被移除。
```bash
redis> LLEN course
(integer) 0

redis> RPUSH course algorithm001
(integer) 1

redis> RPUSH course c++101
(integer) 2

redis> BRPOP course 30
1) "course"             # 弹出元素的 key
2) "c++101"             # 弹出元素的值
```

### LINDEX
返回列表`key`中下标为`index`的元素。
```bash
LINDEX key index
```
`index`可以是负数，比如：`-1`表时倒数第一个元素，`-2`表时倒数第二个元素，以次类推。
如果`index`不在列表有效范围内，返回一个`nil`。如果`key`不是列表类型，返回一个错误。

```bash
redis> LPUSH mylist "World"
(integer) 1
redis> LPUSH mylist "Hello"
(integer) 2
redis> LINDEX mylist 0
"Hello"
redis> LINDEX mylist -1
"World"
# index不在 mylist 的区间范围内
redis> LINDEX mylist 3
(nil)
```
### LRANGE
返回列表`key`中指定区间内的元素。以偏移量`start`和`stop`指定的区间内的元素。
```bash
LRANGE key start stop
```
`start`和`stop`索引位的元素都包含在取值范围内，比如执行`LRANGE list 0 10`，结果是一个包含`11`个元素的列表。
`start`和`stop`超出范围的下标值不会引起错误。
如果`start`大于最大下标值`end`则会返回一个空列表。如果`stop`大于最大下标值`end`，会自动设置`stop`的值设置为`end`。

```bash
redis> RPUSH fp-language lisp
(integer) 1

redis> LRANGE fp-language 0 0
1) "lisp"

redis> RPUSH fp-language scheme
(integer) 2

redis> LRANGE fp-language 0 1
1) "lisp"
2) "scheme"
```

## 修改列表元素
### LSET
设置列表`key`中下标为`index`的元素值为`value`。

```bash
LSET key index value
```

如果`index`超出范围，或对一个空列表进行设置时，会返回错误。
```bash
# 对空列表进行 LSET
redis> EXISTS list
(integer) 0
redis> LSET list 0 item
(error) ERR no such key

# 对非空列表进行 LSET
redis> LPUSH job "cook food"
(integer) 1
redis> LRANGE job 0 0
1) "cook food"
redis> LSET job 0 "play game"
OK
redis> LRANGE job  0 0
1) "play game"

# index 超出范围
redis> LLEN list
(integer) 1
redis> LSET list 3 'out of range'
(error) ERR index out of range
```

### RPOPLPUSH

`RPOPLPUSH`是`RPOP`和`LPUSH`两个操作的合并，会执行两个原子操作：
- 将列表`source`的尾元素弹出，并返回给客户端。
- 将`source`弹出的元素，作为`destination`列表的头元素插入。

```bash
RPOPLPUSH source destination
```

如果`source`不存在，返回`nil`。如果`source`和`destination`是同一个列表，就会把尾元素移动至开头，这叫做列表的旋转(rotation)操作。

```bash
# source 和 destination 不同
redis> LRANGE alpha 0 -1
1) "a"
2) "b"
3) "c"
4) "d"
redis> RPOPLPUSH alpha reciver
"d"
redis> LRANGE alpha 0 -1
1) "a"
2) "b"
3) "c"
redis> LRANGE reciver 0 -1
1) "d"
# 再执行一次，表明 RPOP 和 LPUSH 的位置正确
redis> RPOPLPUSH alpha reciver
"c"
redis> LRANGE alpha 0 -1
1) "a"
2) "b"
redis> LRANGE reciver 0 -1
1) "c"
2) "d"


# source 和 destination 相同
redis> LRANGE number 0 -1
1) "1"
2) "2"
3) "3"
4) "4"
redis> RPOPLPUSH number number
"4"
# 4 被旋转到了表头
redis> LRANGE number 0 -1
1) "4"
2) "1"
3) "2"
4) "3"
redis> RPOPLPUSH number number
"3"
redis> LRANGE number 0 -1
1) "3"
2) "4"
3) "1"
4) "2"
```

### BRPOPLPUSH

`BRPOPLPUSH`和`RPOPLPUSH`基本相同，`BRPOPLPUSH`是阻塞版本，当指定的源列表`source`不为空时，其表现和`RPOPLPUSH`一样。
当`source`为空时，连接将被`BRPOP`命令阻塞，直到等待超时或有可弹出元素为止。

```bash
BRPOPLPUSH source destination timeout
```

如果指定时间内没有任何元素弹出，返回一个`nil`。 否则，返回一个含有两个元素的列表，其中：第一个元素是被弹出元素所属的`key`，第二个元素是被弹出元素的值。
```bash
# 非空列表
redis> BRPOPLPUSH msg reciver 500
"hello moto"                        # 弹出元素的值
(4.31s)                             # 等待时长
redis> LLEN reciver
(integer) 1
redis> LRANGE reciver 0 0
1) "hello moto"


# 空列表
redis> BRPOPLPUSH msg reciver 1
(nil)
(2.24s)
```

## 其他
### LLEN
返回列表`key`的长度。
```bash
LLEN key
```
如果`key`不存在，返回`0`。如果`key`不是列表类型，返回一个错误。

```bash
# 空列表
redis> LLEN job
(integer) 0

# 非空列表
redis> LPUSH job "cook food"
(integer) 1

redis> LPUSH job "have lunch"
(integer) 2

redis> LLEN job
(integer) 2
```

### LREM
移除元素，指定移除数量`count`，移除列表`key`中与`value`相等的元素。
```bash
LREM key count value
```
`count`的值可以有下面三种情况：
- `count > 0`，从表头开始向表尾搜索，移除与`value`相等的元素，数量为`count`。
- `count < 0`，从表尾开始向表头搜索，移除与`value`相等的元素，数量为`count`的绝对值。
- `count = 0`，移除表中所有与`value`相等的值。

如果`key`不存在，返回`0`。

```bash
# 先创建一个表，内容排列是
# morning hello morning helllo morning

redis> LPUSH greet "morning"
(integer) 1
redis> LPUSH greet "hello"
(integer) 2
redis> LPUSH greet "morning"
(integer) 3
redis> LPUSH greet "hello"
(integer) 4
redis> LPUSH greet "morning"
(integer) 5

redis> LRANGE greet 0 4         # 查看所有元素
1) "morning"
2) "hello"
3) "morning"
4) "hello"
5) "morning"

redis> LREM greet 2 morning     # 移除从表头到表尾，最先发现的两个 morning
(integer) 2                     # 两个元素被移除

redis> LLEN greet               # 还剩 3 个元素
(integer) 3

redis> LRANGE greet 0 2
1) "hello"
2) "hello"
3) "morning"

redis> LREM greet -1 morning    # 移除从表尾到表头，第一个 morning
(integer) 1

redis> LLEN greet               # 剩下两个元素
(integer) 2

redis> LRANGE greet 0 1
1) "hello"
2) "hello"

redis> LREM greet 0 hello      # 移除表中所有 hello
(integer) 2                    # 两个 hello 被移除

redis> LLEN greet
(integer) 0
```
### LTRIM
对列表`key`进行修剪，通过`start`和`stop`指定区间，保留指定区间内的元素，其余的元素删除。
比如，执行`LTRIM list 0 10`，表示保留列表`list`的前`11`个元素，其余元素删除。
`start`和`stop`可以是负数，如，`-1`表示列表的最后一个元素， `-2`表示列表的倒数第二个元素，以此类推。
```bash
LTRIM key start stop
```

操作成功返回`OK`，失败会返回错误信息。
```bash
# 1. start 和 stop 都在列表的索引范围之内

# alpha 是一个包含 5 个字符串的列表
redis> LRANGE alpha 0 -1
1) "h"
2) "e"
3) "l"
4) "l"
5) "o"

# 删除 alpha 列表索引为 0 的元素
redis> LTRIM alpha 1 -1
OK
# "h" 已被删除
redis> LRANGE alpha 0 -1
1) "e"
2) "l"
3) "l"
4) "o"

# 2. stop 大于最大下标值
# 保留 alpha 列表索引 1 至索引 10086 上的元素
redis> LTRIM alpha 1 10086
OK
# 只有索引 0 上的元素 "e" 被删除了，其他元素还在
redis> LRANGE alpha 0 -1
1) "l"
2) "l"
3) "o"

# 3. start 和 stop 都大于列表的最大下标，并且 start < stop
redis> LTRIM alpha 10086 123321
OK

redis> LRANGE alpha 0 -1        # 列表被清空
(empty list or set)


# 4. start 和 stop 都大于列表的最大下标，并且 start > stop
# 重新建立一个新列表
redis> RPUSH new-alpha "h" "e" "l" "l" "o"
(integer) 5

redis> LRANGE new-alpha 0 -1
1) "h"
2) "e"
3) "l"
4) "l"
5) "o"
# 执行 LTRIM
redis> LTRIM new-alpha 123321 10086
OK
# 同样被清空
redis> LRANGE new-alpha 0 -1
(empty list or set)
```

