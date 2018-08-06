---
title: Redis 数据类型 hash
date: 2018-04-05 22:11:34
categories: ["Linux"]
tags: ["Redis"]
---

`Redis`对`JSON`数据的支持不是很友好。通常把`JSON`转成`String`存储到`Redis`中，但现在的`JSON`数据都是连环嵌套的，每次更新时都要先获取整个`JSON`，然后更改其中一个字段再放上去。
这种使用方式，如果在海量的请求下，`JSON`字符串比较复杂，会导致在频繁更新数据使网络`I/O`跑满，甚至导致系统超时、崩溃。
所以`Redis`官方推荐采用`Hash`(字典)保存对象。但是`Hash`结构的存储消耗要高于单个字符串。

<!-- more -->

`Redis`的字典和`Java`的`HashMap`类似，它是无序字典。包括内部结构的实现也和`HashMap`也是一致的，同样的**数组 + 链表**二维结构。

### 存取

#### HSET
设置字典`key`值的`field`字段值为`value`。

```bash
HSET key field value
```
如果`key`不存在，创建`key`并进行`HSET`操作。
如果`field`不存在，则增加新字段，设置成功，返回`1`。如果`field`已存在，覆盖旧值，返回`0`。
```bash
redis> hset student name xiaoming
(integer) 1
redis> hget student name
"xiaoming"
redis> hset student age 18
(integer) 0
redis> hget student age
"18"
```
#### HSETNX
和`HSET`一样，但是只在字段`field`不存时才会设置。设置成功，返回`1`。
```bash
HSETNX key field value
```

如果`field`字段已经存在，该操作无效，返回`0`。
```bash
redis> HSETNX student phone 16790624749
(integer) 1

redis> HSETNX nosql phone 16790624778
(integer) 0
```

#### HGET
获取指定字段`field`的值。
```bash
HSETNX key field value
```

`key`存在且`field`存在则返回其值，否则返回`nil`。
```bash
redis> HGET student address
(nil)

redis> HGET student phone
"16790624749"
```
#### HGETALL

获取`key`所有字段的值。
```bash
HSETNX key field value
```

以列表形式返回哈希表中的字段和值。若哈希表不存在，否则返回一个空列表。
```bash
redis> HSET people jack "Jack Sparrow"
(integer) 1

redis> HSET people gump "Forrest Gump"
(integer) 1

redis> HGETALL people
1) "jack"          # 域
2) "Jack Sparrow"  # 值
3) "gump"
4) "Forrest Gump"
```

### 批量操作
`Hash`和`String`一样，支持操作多个字段。
#### HMSET
将一个或多个`field/value`对设置到哈希表`key`。
```bash
HMSET key field value [field value ...]
```
如果`key`不存在，创建`key`并进行`HMSET`操作。
如果`field`不存在，则增加新字段，设置成功，返回`1`。如果`field`已存在，覆盖旧值，返回`0`。

```bash
redis> HMSET website google www.google.com yahoo www.yahoo.com
OK
redis> HGET website google
"www.google.com"
redis> HGET website yahoo
"www.yahoo.com"
```
#### HMGET
返回`key`中一个或多个指定字段的值。
```bash
HMGET key field [field ...]
```

返回一个列表，如果指定的字段在不存在，则返回一个`nil`。如果`key`不存在将返回一个只带有`nil`值的表。如果`key`为非`Hash`结构，则返回一个错误。
```bash
redis> HMSET pet dog "doudou" cat "nounou"
OK

redis> HMGET pet dog cat fake_pet
1) "doudou"
2) "nounou"
3) (nil)        # 不存在,返回nil值

# 非Hash结构
redis> set istring "Hello"
OK
redis> hmget istring notexsitfield
(error) WRONGTYPE Operation against a key holding the wrong kind of value
```

### 自增
#### HINCRBY
为`key`中的指定字段`field`增加一个增量`increment`。
```bash
HINCRBY key field increment
```
`increment`可以为负数，相当于对进行减法操作。
如果`key`不存在，创建`key`，并执行`HINCRBY`操作。如果指定`field`不存在，先初始化为`0`，再执行`HINCRBY`。如果为非数字值执行`HINCRBY`操作，则返回一个错误。
**本操作的值被限制在`64`位(bit)有符号数字表示之内。**
```bash
# increment 为正数

redis> HEXISTS counter page_view    # 对空域进行设置
(integer) 0

redis> HINCRBY counter page_view 200
(integer) 200

redis> HGET counter page_view
"200"


# increment 为负数

redis> HGET counter page_view
"200"

redis> HINCRBY counter page_view -50
(integer) 150

redis> HGET counter page_view
"150"


# 尝试对字符串值的域执行HINCRBY命令

redis> HSET myhash string hello,world       # 设定一个字符串值
(integer) 1

redis> HGET myhash string
"hello,world"

redis> HINCRBY myhash string 1              # 命令执行失败，错误。
(error) ERR hash value is not an integer

redis> HGET myhash string                   # 原值不变
"hello,world"
```
#### HINCRBYFLOAT
与`HINCRBY`一样，不同的是`HINCRBYFLOAT`是为指定字段`field`增加一个浮点数增量`increment`。
```bash
# 值和增量都是普通小数
redis> HSET mykey field 10.50
(integer) 1
redis> HINCRBYFLOAT mykey field 0.1
"10.6"

# 值和增量都是指数符号
redis> HSET mykey field 5.0e3
(integer) 0
redis> HINCRBYFLOAT mykey field 2.0e2
"5200"

# 对不存在的键执行 HINCRBYFLOAT
redis> EXISTS price
(integer) 0
redis> HINCRBYFLOAT price milk 3.5
"3.5"
redis> HGETALL price
1) "milk"
2) "3.5"

# 对不存在的字段进行 HINCRBYFLOAT
redis> HGETALL price
1) "milk"
2) "3.5"
redis> HINCRBYFLOAT price coffee 4.5
"4.5"
redis> HGETALL price
1) "milk"
2) "3.5"
3) "coffee"
4) "4.5"
```
### 其他
#### HDEL
删除`key`中的一个或多个字段。
```bash
HDEL key field [field ...]
```
不存在的字段将被忽略。返回被成功删除的字段数量。
```bash
redis> HGETALL abbr
1) "a"
2) "apple"
3) "b"
4) "banana"
5) "c"
6) "cat"
7) "d"
8) "dog"


# 删除单个域

redis> HDEL abbr a
(integer) 1


# 删除不存在的域

redis> HDEL abbr not-exists-field
(integer) 0


# 删除多个域

redis> HDEL abbr b c
(integer) 2

redis> HGETALL abbr
1) "d"
2) "dog"
```
#### HEXISTS
判断`key`中指定的`field`是否存在。
```bash
HEXISTS key field
```
指定字段存在，返回`1`。不存在，返回`0`。
```bash
redis> HEXISTS phone myphone
(integer) 0
redis> HSET phone myphone nokia-1110
(integer) 1
redis> HEXISTS phone myphone
(integer) 1
```

#### HLEN
返回`key`哈希表的长度，也就是所有字段的数量。
```bash
HLEN key
```
哈希表存在，返回字段数。哈希表不存在，返回`0`。
```bash
redis> HSET db redis redis.com
(integer) 1
redis> HSET db mysql mysql.com
(integer) 1
redis> HLEN db
(integer) 2

redis> HSET db mongodb mongodb.org
(integer) 1
redis> HLEN db
(integer) 3
```

#### HKEYS
返回`key`中的所有字段。
```bash
HKEYS key
```
哈希表存在，返回字段列表。哈希表不存在，返回空列表。
```bash
# 哈希表非空
redis> HMSET website google www.google.com yahoo www.yahoo.com
OK
redis> HKEYS website
1) "google"
2) "yahoo"

# 空哈希表不存在
redis> EXISTS fake_key
(integer) 0
redis> HKEYS fake_key
(empty list or set)
```


#### HVALS
与`HKEYS`对应，`HVALS`返回`key`中的所有字段的值。
```bash
HVALS key
```
哈希表存在，返回字段数。哈希表不存在，返回`0`。
```bash
# 非空哈希表
redis> HMSET website google www.google.com yahoo www.yahoo.com
OK
redis> HVALS website
1) "www.google.com"
2) "www.yahoo.com"


# 空哈希表/不存在的key
redis> EXISTS not_exists
(integer) 0
redis> HVALS not_exists
(empty list or set)
```

#### HSTLEN

返回`key`中指定`field`的`value`的字符串长度。
```bash
HSTLEN key field
```
如果`key`或者`field`不存在，返回`0`。
```bash
redis> HMSET myhash f1 HelloWorld f2 99 f3 -256
OK
redis> HSTRLEN myhash f1
(integer) 10
redis> HSTRLEN myhash f2
(integer) 2
redis> HSTRLEN myhash f3
(integer) 4
```
#### HSCAN
参考**SCAN**命令。
```bash
HSCAN key cursor [MATCH pattern] [COUNT count]
```