---
title: Redis入门
date: 2018-04-05 11:00:24
categories: ["Linux"]
tags: ["Redis"]
---

[Redis中文官网的介绍](http://www.redis.cn/)：

Redis（Remote Dictionary Service）是目前互联网技术领域使用最为广泛的存储中间件，它是一个开源（BSD许可）的，内存中的数据结构存储系统，它可以用作数据库、缓存和消息中间件。
它支持多种类型的数据结构，如 字符串（strings）， 散列（hashes）， 列表（lists）， 集合（sets）， 有序集合（sorted sets） 与范围查询，
bitmaps， hyperloglogs 和 地理空间（geospatial） 索引半径查询。 Redis 内置了 复制（replication），LUA脚本（Lua scripting），
LRU驱动事件（LRU eviction），事务（transactions） 和不同级别的 磁盘持久化（persistence），
并通过 Redis哨兵（Sentinel）和自动 分区（Cluster）提供高可用性（high availability）。


<!-- more -->

## Redis与其他key-value存储

最常用的缓存数据库有Redis和Memcached。

### 数据类型：

Redis一共支持5种数据类型：

- [字符串(Strings)](/2018/04/05/linux-redis-strings/)
- [哈希(Hashs)](/2018/04/05/linux-redis-hash/)
- [列表(Lists)](/2018/04/05/linux-redis-list/)
- [集合(Sets)](/2018/04/05/linux-redis-set/)
- [有序集合(SortedSets)](/2018/04/05/linux-redis-sortset/)

Memcache只支持对键值对的存储。

### 线程模型

- Redis：使用单线程实现。
由于Redis使用单线程，所以不要在Redis中存储太大的内容，否则会阻塞其它请求。
Redis实现非阻塞网络I/O模型，适合快速地操作逻辑，有复杂的长逻辑时会影响性能。
如果遇到长逻辑可以配置多个实例来提高多核CPU的利用率，在单个机器上多个端口配置多个实例。（官方的推荐是一台机器使用8个实例）

- Memcache：使用多线程实现。
Memcache也使用了非阻塞I/O模型，可以应用于多种场景，遇到长逻辑不会阻塞其它请求的响应。



### 持久机制
- Redis提供了两种持久机制：
  - `RDB`：定时持久机制，但是出现宕机时可能会丢失数据。
  - `AOF`：基于操作日志的持久机制。
- Memcahe不支持持久机制：
Memache的设计理念就是设计一个单纯的缓存，缓存的数据都是临时的，不应该是持久的，但是可以通过`MemcacheDB`来实现Memache的持久机制。

### 高可用

- Redis提供多种高可用集群方案：
  - 主从节点复制：从节点可使用RDB和缓存的AOF命令进行同步和恢复。Redis还支持
  - 哨兵 Sentinel（version 3.0+）
  - Cluster（version 3.0+）

- Memecache不提供高可用方案：
但是可以通过`Megagent`代理，实现当一个实例宕机时，连接另外一个实例。


### 队列

- Redis支持消息队列发布订阅模式。
- Memcache不支持队列，可通过`MemcachQ`实现。

### 事务

- Redis的所有操作都是原子性的，意思就是要么成功执行要么失败完全不执行。单个操作是原子性的。多个操作也支持事务，即原子性，通过`MULTI`和`EXEC`指令包起来。
- Memcached的单个命令也是线程安全的，单个连接的多个命令序列不是线程安全的，它也提供了inc等线程安全的自加命令，并提供了gets/cas保证线程安全。

## 数据类型
我们已经知道 Redis 的 5 种基础数据结构，分别为：string (字符串)、list (列表)、set (集合)、hash (哈希) 和 zset (有序集合)。
### String（字符串）
String类型是最常用，也是最简单的的一种类型，string类型是二进制安全的。也就是说string可以包含任何数据。比如`jpg图片`或者`序列化的对象` 。
一个键**最大能存储512MB**。
``` bash
redis> set testkey hello
OK
redis> get testkey
"hello"
```
### Hash（哈希）
Redis对JSON数据的支持不是很友好。通常把JSON转成String存储到Redis中，但现在的JSON数据都是连环嵌套的，每次更新时都要先获取整个JSON，然后更改其中一个字段再放上去。
这种使用方式，如果在海量的请求下，JSON字符串比较复杂，会导致在频繁更新数据使网络I/O跑满，甚至导致系统超时、崩溃。
所以Redis官方推荐采用哈希保存对象。
设置哈希类型的值使用`HSET`，取值使用`HGET`获取单个哈希属性值，或使用`HGETALL`获取哈希属性和值。
比如一个学生对象：
``` bash
redis> HSET  xiaoming age 18
(integer) 1
redis> HSET xiaoming phone 15676666666
(integer) 1
redis> HMSET xiaoqiang age 18 phone 13816666666
OK
redis> HGET xiaoming age
"18"
redis> HGETALL xiaoming
1)"age"
2)"18"
3)"phone"
4)"15676666666"
redis> HGETALL xiaoqiang
1)"age"
2)"18"
3)"phone"
4)"13816666666"
```
### List（列表）
Redis 列表(Lists)是简单的字符串列表，并根据插入顺序进行排序。一个Redis 列表中最多可存储`232-1`(40亿)个元素。
使用`LPUSH`方法向列表的开头插入新元素，使用`RPUSH`方法向列表的结尾插入新元素。通过`LSET`对列表中指定索引位的元素进行操作。`LSET`不允许对不存在的列表进行操作。
列表元素取值用`LINDEX`获取指定索引位的元素，也可以使用`LPOP`返回并移除列表头部的元素，或使用`RPOP`返回并移除列表尾部的元素。
``` bash
redis> LPUSH testlist one
(integer) 1
redis> RPUSH testlist two
(integer) 2
redis> LSET testlist 0 1
OK
redis> LINDEX testlist 0
"1"
redis> LPOP testlist
"1"
redis> RPOP testlist
"two"
redis> lindex testlist 0
(nil)
```

### Set（集合）

Redis的Set是string类型的无序集合。集合中不允许重复成员的存在。一个Redis 集合中最多可包含`232-1`(40亿)个元素。
向集合中插入值使用`SADD`命令。获取集合中的元素使用`SMEMBERS`命令，也可以使用`SPOP`获取并删除一个随机值。
``` bash
redis> sadd class xiaoming xiaoqiang xiaogang
(integer) 3
redis> smembers class
1) "xiaoming"
2) "xiaoqiang"
3) "xiaogang"
redis> spop class
"xiaoqiang"
redis> smembers class
1) "xiaoming"
2) "xiaogang"
```
集合间的操作:
通过`SINTER`查询集合间的交集、通过`SUNION`获取集间的并集，通过`SDIFF`获取集合间的差集。集合中的元素可以通过`SMOVE`命令从一个集合移到另一个集中。
``` bash
redis> sadd class1 xiaoming xiaoqiang xiaogang
(integer) 1
redis> sadd class2 xiaoming xiaoli
(integer) 1
redis> sinter class1 class2
1) "xiaoming"
redis> sunion class1 class2
1) "xiaoming"
2) "xiaoqiang"
3) "xiaogang"
4) "xiaoming"
5) "xiaoli"
redis> sdiff class1 class2
1) "xiaoqiang"
2) "xiaogang"
redis> smove class1 class2 xiaoqiang
(integer) 0
redis> smembers class2
1) "xiaoming"
2) "xiaoqiang"
3) "xiaoli"
```
### zset(sorted set：有序集合)
Redis zset 和 set 一样也是string类型元素的集合,且不允许重复的成员。
不同的是每个元素都会关联一个double类型的分数。redis正是通过分数来为集合中的成员进行从小到大的排序。zset的成员是唯一的,但分数(score)却可以重复。
使用`ZADD`添加元素到集合，元素在集合中存在则更新对应score。
通过`ZRANGE`集合指定范围内的元素，也可以通过`ZRANK`获取指定成员的排名，通过`ZSCORE`返回元素的权重(score)值。
``` bash
ZADD key score member
```

``` bash
redis> ZADD class 1 xiaoming
(integer) 1
redis> ZADD class 2 xiaoqiang 3 xiaogang
(integer) 2
redis> ZRANGE class 1 2
1) "xiaoming"
2) "xiaoqiang"
redis> ZRANK class xiaogang
(integer) 2
redis> ZSCORE class xiaogang
"3"
```

### 容器型数据结构

`list/set/hash/zset`这四种都属于容器型数据结构，他们有两条通用规则：
- 如果容器不存在，那就创建一个，再进行操作。比如`RPUSH`，如果列表不存在，`Redis`就会自动创建一个，然后再执行`RPUSH`。
- 如果容器里元素没有了，那么立即删除元素，释放内存。比如`LPOP`操作到最后一个元素，列表`key`就会自动删除。
