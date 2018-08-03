---
title: Redis 数据类型 string
date: 2018-04-05 22:11:25
categories: ["Linux"]
tags: ["Redis"]
---

String类型是最常用，也是最简单的的一种类型，string类型是二进制安全的。也就是说string可以包含任何数据。比如`jpg图片`或者`序列化的对象` 。
一个键**最大能存储512MB**。Redis 所有的数据结构都是以唯一的 `key` 字符串作为名称，然后通过这个唯一 `key` 值来获取相应的 `value` 数据。
不同类型的数据结构的差异就在于 `value` 的结构不一样。

<!-- more -->

字符串结构使用非常广泛，不仅限于字符串，通常会使用 JSON 序列化成字符串，然后将序列化后的字符串塞进 Redis 来缓存。


### 键值对存取

```bash
redis> set testkey hello
OK
redis> get testkey
"hello"

//EX
redis> set testkey hello2 EX 60
OK
redis> get testkey
"hello2"
redis> TTL testkey
(integer) 55

//PX
redis> SET testkey hello3 PX 60000
OK
redis> GET testkey
"hello3"
redis> PTTL testkey
(integer) 55000

//NX
redis> SET testkey hello4 NX
OK # 键不存在，设置成功
redis> GET testkey
"hello4"
redis> SET testkey hello4 NX
(nil) # 键已经存在，设置失败
redis> GET testkey
"hello4"

//XX
redis> SET testkey hello5 XX
OK # 键已经存在，设置成功
redis> GET testkey
"hello5"
redis> SET testkey2 hello XX
(nil) # 键不存在，设置失败

//EX 和 PX 同时使用，后面的选项会覆盖前面设置的选项
redis> set testkey hello2 EX 10 PX 50000
OK
redis> TTL testkey
(integer) 45000 # PX 参数覆盖了 EX
redis> set testkey hello2 PX 50000 EX 10
OK
redis> TTL testkey
(integer) 8 # EX 参数覆盖了 PX
```

#### SET
```bash
SET [key] [value] [EX seconds] [PX milliseconds] [NX|XX]
```

- EX seconds - 设置过期时间，单位为秒。
- PX millisecond - 设置过期时间，单位毫秒。
- NX - 只在`key`不存在时才进行设置。
- XX - 只在`key`存在时才进行设置。

#### SETEX
设置`key`值并指定过期时间，单位秒。
`SET key value EX second`等同于`SETEX key second value`
```bash
redis> SETEX name 60 xiaoming
OK
redis> GET name
"10086"
redis> TTL name
(integer) 49
```
#### PSETEX
设置`key`值并指定过期时间，单位毫秒。
`SET key value PX millisecond`等同于`PSETEX key millisecond value`
```bash
redis> SETEX age 60000 18
OK
redis> GET age
"18"
redis> TTL age
(integer) 49000
```
#### SETNX
如果 `key` 不存在，则设置其值。
`SET key value NX`等同于`SETNX key value`

#### GET
获取 `key` 对应的 `value`。如果`key`不存在，则返回nil；如果`key`不是字符串类型，则返回错误。

#### GETSET
设置`key`的值，并返回其旧值。也就是执行了`set`操作和`get`操作。如果`key`不是字符串类型，则返回错误。
```bash
redis> GETSET testkey3 hello3
(nil)    # 没有旧值，返回 nil

redis> GETSET testkey3 hello4
"hello3"    # 返回旧值
```


### 批量操作键值对
同时设置或获取多个字符串，可以节省网络耗时开销。
```bash
> SET name xiaoming
OK
> SET age 18
OK
> MGET name age phone
1) "xiaoming"
2) "18"
3) (nil)
> MSET name xiaoming age 18 phone 17235617235
> MGET name age phone
1) "xiaoming"
2) "18"
3) "17235617235"
```

#### MSET
`MSET`操作具有原子性，所有`key`设置要么全成功，要么全部失败。

#### MSETNX
`MSETNX`和`SETNX`类似，当`key`不存在时，才会设置其值。`MSETNX`一样具有原子性。
```bash
# 对不存在的 key 进行 MSETNX
redis> MSETNX rmdbs "MySQL" nosql "MongoDB" key-value-store "redis"
(integer) 1
redis> MGET rmdbs nosql key-value-store
1) "MySQL"
2) "MongoDB"
3) "redis"

# MSET 的给定 key 当中有已存在的 key
redis> MSETNX rmdbs "Sqlite" language "python"
(integer) 0
# 因为 MSET 是原子性操作，language 没有被设置
redis> EXISTS language
(integer) 0
# rmdbs 也没有被修改
redis> GET rmdbs
"MySQL"
```

#### MGET
返回一个或多个`key`值。

### 自增/自减
在Redis中，**数值也会也字符串形式存储。**
**注意，执行自增或自减时，如果`key`不存在，会被初始化为`0`再执行自增或自减操作。如果`key`值为非数字，那么会返回一个错误。数字值的有效范围为 64 位(bit)有符号数字。**

```bash
redis> SET age 18
OK
redis> INCR age
(integer) 19
redis> GET age
"19"
redis> DECR age
(integer) 18
redis> INCRBY age 20
(integer) 38
```

#### INCR
将`key`的值加`1`。
#### INCRBY
将`key`的值增加指定的值。
#### INCRBYFLOAT
将`key`的值增加指定的浮点值。
```bash
redis> SET floatkey 9.5
OK
redis> INCRBYFLOAT floatkey 0.1
"9.6"
```
#### DECR
将`key`的值减`1`。如果`key`不存在，
```bash
redis> DECR count #count 不存在，初始化为 0，再减一
(integer) -1
```
#### DECRBY
将`key`的值减去指定的值。
```bash
redis> SET count 100
OK
redis> DECRBY count 20
(integer) 80
```

### 位图
