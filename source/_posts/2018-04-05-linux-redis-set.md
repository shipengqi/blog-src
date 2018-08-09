---
title: Redis 数据类型 Set
date: 2018-04-05 22:11:45
categories: ["Linux"]
tags: ["Redis"]
---

`Redis`的`Set`是`string`类型的无序集合，类似于`List`类型。但是集合中不允许重复成员的存在。一个`Redis`集合中最多可包含`232-1`(40亿)个元素。
`Set`类型有一个非常重要的特性，就是支持集合之间的聚合计算操作，这些操作均在服务端完成，效率极高，而且也节省了的网络`I/O`开销。
<!-- more -->

`Redis`的集合和`Java`的`HashSet`类似，它内部的键值对是无序的唯一的。它的内部实现相当于一个特殊的字典，字典中所有的`value`都是一个值`NULL`。
当集合移除了最后一个元素之后，该`key`会被自动被删除，内存被回收。

`Set`结构可以用来存储活动中奖的`用户ID`，可以保证同一个用户不会中奖两次。

## 存取
### SADD
添加一个或多个`member`元素到集合`key`中。
```bash
SADD key member [member ...]
```
返回被添加到集合中的新元素的数量。如果集合`key`不存在，创建集合`key`，并执行`SADD`。如果`key`不是集合类型，将返回一个错误。

```bash
# 添加单个元素
redis> SADD blog "segmentfault.com"
(integer) 1

# 添加重复元素
redis> SADD blog "segmentfault.com"
(integer) 0

# 添加多个元素
redis> SADD blog "csdn.net" "itbilu.com"
(integer) 2

redis> SMEMBERS blog
1) "segmentfault.com"
2) "csdn.net"
3) "itbilu.com"
```

### SCARD
返回集合`key`中元素的数量。
```bash
SCARD key
```
如果`key`不存在，返回`0`。
```bash
redis> SADD tool pc printer phone
(integer) 3

redis> SCARD tool   # 非空集合
(integer) 3

redis> DEL tool
(integer) 1

redis> SCARD tool   # 空集合
(integer) 0
```

### SMEMBERS
返回集合`key`的所有成员。
**注意当`SMEMBERS`处理一个很大的集合键时，由于`Redis`是单线程，它可能会阻塞服务器。**
```bash
SMEMBERS key
```
如果`key`不存在，返回空集合。
```bash
# key 不存在或集合为空

redis> EXISTS not_exists_key
(integer) 0

redis> SMEMBERS not_exists_key
(empty list or set)


# 非空集合

redis> SADD language Ruby Python Clojure
(integer) 3

redis> SMEMBERS language
1) "Python"
2) "Ruby"
3) "Clojure"
```
### SISMEMBER
判断集合`key`中是否包含`member`元素。

```bash
SISMEMBER key member
```
如果包含，返回`1`。如果不包含或`key`不存在，返回`0`。

```bash
redis> SMEMBERS joe's_movies
1) "hi, lady"
2) "Fast Five"
3) "2012"

redis> SISMEMBER joe's_movies "bet man"
(integer) 0

redis> SISMEMBER joe's_movies "Fast Five"
(integer) 1
```

### SRANDMEMBER
返回集合`key`中的一个或指定数量`count`的随机元素。与`SPOP`类似，但是`SPOP`会删除返回的随机元素，`SRANDMEMBER`不会删除元素。

```bash
SRANDMEMBER key [count]
```
`count`的值可以有下面两种：
- `count`为正数，且小于集合基数，返回一个包含`count`个元素的数组，数组中的元素各不相同。如果`count`大于等于集合基数，那么返回整个集合。
- `count`为负数，返回一个数组，数组中的元素可能会重复出现多次，而数组的长度为`count`的绝对值。

```bash
# 添加元素

redis> SADD fruit apple banana cherry
(integer) 3

# 只给定 key 参数，返回一个随机元素

redis> SRANDMEMBER fruit
"cherry"

redis> SRANDMEMBER fruit
"apple"

# 给定 3 为 count 参数，返回 3 个随机元素
# 每个随机元素都不相同

redis> SRANDMEMBER fruit 3
1) "apple"
2) "banana"
3) "cherry"

# 给定 -3 为 count 参数，返回 3 个随机元素
# 元素可能会重复出现多次

redis> SRANDMEMBER fruit -3
1) "banana"
2) "cherry"
3) "apple"

redis> SRANDMEMBER fruit -3
1) "apple"
2) "apple"
3) "cherry"

# 如果 count 是整数，且大于等于集合基数，那么返回整个集合

redis> SRANDMEMBER fruit 10
1) "apple"
2) "banana"
3) "cherry"

# 如果 count 是负数，且 count 的绝对值大于集合的基数
# 那么返回的数组的长度为 count 的绝对值

redis> SRANDMEMBER fruit -10
1) "banana"
2) "apple"
3) "banana"
4) "cherry"
5) "apple"
6) "apple"
7) "cherry"
8) "apple"
9) "apple"
10) "banana"

# SRANDMEMBER 并不会修改集合内容

redis> SMEMBERS fruit
1) "apple"
2) "cherry"
3) "banana"

# 集合为空时返回 nil 或者空数组

redis> SRANDMEMBER not-exists
(nil)

redis> SRANDMEMBER not-eixsts 10
(empty list or set)
```

## 移除
### SPOP
删除并返回集合`key`中的一个**随机元素**。注意返回的是**随机元素**，不是头部也不是尾部元素。
```bash
SPOP key
```
如果`key`不存在或`key`是空集，返回`nil`。
```bash
redis> SMEMBERS db
1) "MySQL"
2) "MongoDB"
3) "Redis"

redis> SPOP db
"Redis"

redis> SMEMBERS db
1) "MySQL"
2) "MongoDB"

redis> SPOP db
"MySQL"

redis> SMEMBERS db
1) "MongoDB"
```

### SREM
删除集合`key`中的一个或多个元素。
```bash
SREM key member [member ...]
```
如果`member`不存在，会被忽略。

```bash
# 测试数据

redis> SMEMBERS languages
1) "c"
2) "lisp"
3) "python"
4) "ruby"


# 移除单个元素

redis> SREM languages ruby
(integer) 1


# 移除不存在元素

redis> SREM languages non-exists-language
(integer) 0


# 移除多个元素

redis> SREM languages lisp python c
(integer) 3

redis> SMEMBERS languages
(empty list or set)
```

## 合并
### SDIFF
返回指定的一个或多个集合的差集。
```bash
SDIFF key [key ...]
```

```bash
redis> SMEMBERS peter's_movies
1) "bet man"
2) "start war"
3) "2012"

redis> SMEMBERS joe's_movies
1) "hi, lady"
2) "Fast Five"
3) "2012"

redis> SDIFF peter's_movies joe's_movies
1) "bet man"
2) "start war"
```
### SDIFFSTORE
和`SDIFF`类似，但是`SDIFFSTORE`是将指定的一个或多个集合的差集存储到集合`destination`中。
```bash
SDIFFSTORE destination key [key ...]
```
如果`destination`已存在，则覆盖。返回**交集**（注意这里不是差集）成员数量。
```bash
redis> SMEMBERS joe's_movies
1) "hi, lady"
2) "Fast Five"
3) "2012"

redis> SMEMBERS peter's_movies
1) "bet man"
2) "start war"
3) "2012"

redis> SDIFFSTORE joe_diff_peter joe's_movies peter's_movies
(integer) 2

redis> SMEMBERS joe_diff_peter
1) "hi, lady"
```
### SINTER
返回一个或多个指定集合的交集。
```bash
SINTER key [key ...]
```
如果`key`不存在，返回的结果集为空。
```bash
redis> SMEMBERS group_1
1) "LI LEI"
2) "TOM"
3) "JACK"

redis> SMEMBERS group_2
1) "HAN MEIMEI"
2) "JACK"

redis> SINTER group_1 group_2
1) "JACK"
```
### SINTERSTORE
和`SINTER`类似，但是`SINTERSTORE`是将指定的一个或多个集合的交集存储到集合`destination`中。
```bash
SDIFFSTORE destination key [key ...]
```
如果`destination`已存在，则覆盖。返回交集成员数量。
```bash
redis> SMEMBERS songs
1) "good bye joe"
2) "hello,peter"

redis> SMEMBERS my_songs
1) "good bye joe"
2) "falling"

redis> SINTERSTORE song_interset songs my_songs
(integer) 1

redis> SMEMBERS song_interset
1) "good bye joe"
```
### SUNION
返回一个或多个指定集合的并集。
```bash
SUNION key [key ...]
```
如果`key`不存在，返回的结果集为空。
```bash
redis> SMEMBERS songs
1) "Billie Jean"

redis> SMEMBERS my_songs
1) "Believe Me"

redis> SUNION songs my_songs
1) "Billie Jean"
2) "Believe Me"
```
### SUNIONSTORE
和`SUNION`类似，但是`SUNIONSTORE`是将指定的一个或多个集合的并集存储到集合`destination`中。
```bash
SDIFFSTORE destination key [key ...]
```
如果`destination`已存在，则覆盖。返回并集成员数量。
```bash
redis> SMEMBERS NoSQL
1) "MongoDB"
2) "Redis"

redis> SMEMBERS SQL
1) "sqlite"
2) "MySQL"

redis> SUNIONSTORE db NoSQL SQL
(integer) 4

redis> SMEMBERS db
1) "MySQL"
2) "sqlite"
3) "MongoDB"
4) "Redis"
```
### SMOVE
将指定的`member`元素从`source`集合删除并移动到`destination`集合。该命令原子操作。

```bash
SMOVE source destination member
```

如果`source`不存在或者没有指定的`member`元素，则不执行任何操作，并返回`0`。
如果`source`和`destination`是同一个集合，就会把尾元素移动至开头，这叫做列表的旋转(rotation)操作。
如果`destination`已经存在该`member`元素，只删除`source`集合中的`member`元素。
如果`source`或`destination`不是集合类型，返回错误。

```bash
redis> SMEMBERS songs
1) "Billie Jean"
2) "Believe Me"

redis> SMEMBERS my_songs
(empty list or set)

redis> SMOVE songs my_songs "Believe Me"
(integer) 1

redis> SMEMBERS songs
1) "Billie Jean"

redis> SMEMBERS my_songs
1) "Believe Me"
```

## 其他
### SSCAN
参考**[SCAN](/2018/08/08/redis-key/#more)**命令。
```bash
SSCAN key cursor [MATCH pattern] [COUNT count]
```
