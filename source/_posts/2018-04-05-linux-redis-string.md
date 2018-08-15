---
title: Redis 数据类型 String
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
如果`key`不存在，则设置其值。设置成功，返回`1`。失败，返回`0`。
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

### APPEND
向`key`值字符串的末尾追加指定的`value`；如果`key`不存在，则执行`SET`操作，设置`key`值
```bash
redis> APPEND notexistkey hello
(integer) 5

redis> APPEND notexistkey " - redis"
(integer) 13

redis> GET myphone
"hello - redis"
```

### STRLEN
返回key的值的长度。如果`key`不存在，则返回`0`。果key的值不是字符串，则返回一个错误。

```bash
redis> SET existkey "hello redis"
OK
redis> STRLEN existkey
(integer) 11

redis> STRLEN notexistkey
(integer) 0
```

### SETRANGE
使用`value`覆盖`key`以偏移量`offset`开始的字符串。
```bash
SETRANGE key offset value
```
如果key原来储存的字符串长度比偏移量小，那么原字符和偏移量之间的空白将用零字节("\x00")来填充。
```bash
# 对非空字符串进行 SETRANGE
redis> SET greeting "hello redis"
OK
redis> SETRANGE greeting 6 "Redis"
(integer) 11
redis> GET greeting
"hello Redis"

# 对空字符串/不存在的 key 进行 SETRANGE
redis> EXISTS notexistkey
(integer) 0
redis> SETRANGE notexistkey 5 "Redis"
(integer) 10
redis> GET notexistkey
"\x00\x00\x00\x00\x00Redis"
```
### GETRANGE
`GETRANGE`类似`javascript`中的`substring`。提取字符串中两个指定的索引号之间的字符。
```bash
GETRANGE key start end
```
`start`提取字符串的起始位置，`end`为结束位置。
如果是负数，那么该参数声明从字符串的尾部开始算起的位置。也就是说，-1 指字符串中最后一个字符，-2 指倒数第二个字符，以此类推。

```bash
redis> SET greeting "hello, redis"
OK

redis> GETRANGE greeting 0 4
"hello"

# 不支持回绕操作
redis> GETRANGE greeting -1 -5
""

redis> GETRANGE greeting -3 -1
"dis"

# 从第一个到最后一个
redis> GETRANGE greeting 0 -1
"hello, redis"

# 取值范围超过实际字符串长度范围，会被自动忽略
redis> GETRANGE greeting 0 1008611
"hello, redis"
```

### 位图
位图不是特殊的数据结构，它的内容其实就是普通的字符串，也就是 byte 数组。
在日常开发中，可能会有一些`bool`型数据需要存取，如果使用普通的`key/value`方式存储，会浪费很多存储空间,比如签到记录，签了是`1`，没签是`0`，记录`365`天。
如果每个用户存储`365`条记录，当用户量很庞大的时候，需要的存储空间是惊人的。

对于这种操作，Redis 提供了位操作，这样每天的签到记录只占据一个位，`365`天就是`365`个位，`46`个字节就可以完全容纳下，大大节约了存储空间。

#### SETBIT
Redis 的位数组是自动扩展，如果设置了某个偏移位置超出了现有的内容范围，就会自动将位数组进行零扩充。
```bash
SETBIT key offset value
```
设置指定偏移量上的位`bit`的值。`value`的值是`0`或`1`。当`key`不存在时，自动生成一个新的字符串值。
`offset`参数的取值范围为大于等于`0`，小于`2^32`(bit 映射限制在 512 MB 以内)。
```bash
redis> SETBIT testbit 100 1
(integer) 0
redis> GETBIT testbit 100
(integer) 1
redis> GETBIT testbit 101
(integer) 0 # bit 默认被初始化为 0
```
#### GETBIT
获取指定偏移量上的位`bit`的值。
```bash
GETBIT key offset
```
如果`offset`比字符串值的长度大，或者`key`不存在时，返回`0`。
```bash
redis> EXISTS testbit2
(integer) 0
redis> GETBIT testbit2 100
(integer) 0

redis> SETBIT testbit2 100 1
(integer) 0
redis> GETBIT bit 100
(integer) 1
```

#### BITPOS

获取字符串里面第一个被设置为`1`或者`0`的`bit`位。
`BITPOS`可以用来做查找，例如，查找用户从哪一天开始第一次签到。如果指定了范围参数`start`, `end`，就可以统计在某个时间范围内用户签到了多少天，用户自某天以后的哪天开始签到。
```bash
BITPOS key value start end
```
`value`是`0`或者`1`。如果我们在空字符串或者`0`字节的字符串里面查找`bit`为`1`的内容，那么结果将返回`-1`。
`start`和`end`也可以包含负值，负值将从字符串的末尾开始计算，`-1`是字符串的最后一个字节，`-2`是倒数第二个，等等。
`start`和`end`参数是字节索引，也就是说指定的位范围必须是 8 的倍数，而不能任意指定。
不存在的`key`将会被当做空字符串来处理。
```bash
redis> SET testbit3 hello
OK
redis> BITPOS testbit3 1 # 第一个 1 位
(integer) 1
redis> BITPOS testbit3 0 # 第一个 0 位
(integer) 0
redis> SET mykey "\xff\xf0\x00"
OK
redis> BITPOS mykey 0 # 查找字符串里面bit值为0的位置
(integer) 12
redis> SET mykey "\x00\xff\xf0"
OK
redis> BITPOS mykey 1 0 # 查找字符串里面bit值为1从第0个字节开始的位置
(integer) 8
redis> BITPOS mykey 1 2 # 查找字符串里面bit值为1从第2个字节(12)开始的位置
(integer) 16
redis> set mykey "\x00\x00\x00"
OK
redis> BITPOS mykey 1 # 查找字符串里面bit值为1的位置
(integer) -1
```

#### BITOP

对一个或多个保存二进制位的字符串`key`进行位元操作，并将结果保存到`destkey`上。处理不同长度的字符串时，较短的那个字符串所缺少的部分会被看作`0`，空的`key`也被看作是包含`0`的字符串序列。
```bash
BITOP operation destkey key [key ...]
```
`operation`有四种操作可选：
- `AND`，对一个或多个`key`值求逻辑并。
- `OR`，对一个或多个`key`值求逻辑或。
- `XOR`，对一个或多个`key`值求逻辑异或。
- `NOT`，对给定`key`值求逻辑非，**注意`NOT`操作，只可以接收一个`key`作为输入，其他三个操作一个或多个。**

`BITOP`的复杂度为`O(N)`，当处理大型矩阵(matrix)或者进行大数据量的统计时，最好将任务指派到`slave`进行，避免阻塞主节点。

```bash
redis> SETBIT testbit1 0 1        # testbit1 = 1001
(integer) 0
redis> SETBIT testbit1 3 1
(integer) 0
redis> SETBIT testbit2 0 1        # testbit2 = 1101
(integer) 0
redis> SETBIT testbit2 1 1
(integer) 0
redis> SETBIT testbit2 3 1
(integer) 0
redis> BITOP AND andresult testbit1 testbit2
(integer) 1
redis> GETBIT andresult 0      # andresult = 1001
(integer) 1
redis> GETBIT andresult 1
(integer) 0
redis> GETBIT andresult 2
(integer) 0
redis> GETBIT andresult 3
(integer) 1
```

#### BITCOUNT
可以用来做高位统计，例如，统计用户一共签到了多少天。
计算指定字符串中，比特位被设置为`1`的数量。指定可选参数`start`和`end`时只统计指定位上的字符，否则统计全部。
```bash
BITPOS key value start end
```
```bash
redis> BITCOUNT testbit4
(integer) 0

redis> SETBIT testbit4 0 1          # 0001
(integer) 0

redis> BITCOUNT testbit4
(integer) 1

redis> SETBIT testbit4 3 1          # 1001
(integer) 0

redis> BITCOUNT testbit4
(integer) 2
```
#### BITFIELD
`SETBIT`和`GETBIT`都只能操作一个`bit`，如果要操作多个`bit`就使用`BITFIELD`。

`BITFIELD` 有四个子指令：
- `GET type offset`，返回指定的位域
- `SET type offset value`，设置指定位域的值并返回它的原值
- `INCRBY type offset increment`，自增或自减（如果increment为负数）指定位域的值并返回它的新值
- `OVERFLOW [WRAP|SAT|FAIL]`，溢出策略子指令，通过设置溢出行为来改变调用INCRBY指令的后序操作

`GET`，`SET`，`INCRBY`最多只能处理`64`个连续的位，超过`64`位，就得使用多个子指令，`BITFIELD`可以一次执行多个子指令。

##### `GET` 子指令

```bash
redis> set w hello
OK
redis> BITFIELD w get u4 0  # 从第一个位开始取 4 个位，结果是无符号数 (u)
(integer) 6
redis> BITFIELD w get u3 2  # 从第三个位开始取 3 个位，结果是无符号数 (u)
(integer) 5
redis> BITFIELD w get i4 0  # 从第一个位开始取 4 个位，结果是有符号数 (i)
1) (integer) 6
redis> BITFIELD w get i3 2  # 从第三个位开始取 3 个位，结果是有符号数 (i)
1) (integer) -3

# 执行多个子命令
redis> BITFIELD w get u4 0 get u3 2 get i4 0 get i3 2
1) (integer) 6
2) (integer) 5
3) (integer) 6
4) (integer) -3
```
有符号数最多可以获取`64`位，无符号数只能获取`63`位 (`Redis`中的`integer`是有符号数，最大`64`位，不能传递`64`位无符号值)。如果超出位数限制，`Redis`就会告诉你参数错误。

##### `SET` 子指令
 `SET`子指令将第二个字符`e`改成`a`，`a`的`ASCII`码是`97`：
```bash
redis> BITFIELD w set u8 8 97  # 从第 8 个位开始，将接下来的 8 个位用无符号数 97 替换
1) (integer) 101
redis> get w
"hallo"
```

##### `INCRBY` 子指令
它用来对指定范围的位进行自增操作。既然提到自增，就有可能出现溢出。如果增加了正数，会出现上溢，如果增加的是负数，就会出现下溢出。
`Redis`默认的处理是折返。如果出现了溢出，就将溢出的符号位丢掉。如果是`8`位无符号数`255`，加`1`后就会溢出，会全部变零。如果是`8`位有符号数`127`，加`1`后就会溢出变成 `-128`。
```bash
redis> set w hello
OK
redis> bitfield w incrby u4 2 1  # 从第三个位开始，对接下来的 4 位无符号数 +1
1) (integer) 11
redis> bitfield w incrby u4 2 1
1) (integer) 12
redis> bitfield w incrby u4 2 1
1) (integer) 13
redis> bitfield w incrby u4 2 1
1) (integer) 14
redis> bitfield w incrby u4 2 1
1) (integer) 15
redis> bitfield w incrby u4 2 1  # 溢出折返
1) (integer) 0
```
##### `OVERFLOW` 子指令
用户可以使用`OVERFLOW`来选择溢出行为，默认是折返 (wrap)。
- `WRAP` 回环/折返 算法，默认是`WRAP`，适用于有符号和无符号整型两种类型。对于无符号整型，回环计数将对整型最大值进行取模操作（C语言的标准行为）。
对于有符号整型，上溢从最负的负数开始取数，下溢则从最大的正数开始取数，例如，如果i8整型的值设为127，自加1后的值变为-128。
- `SAT` 饱和截断算法，下溢之后设为最小的整型值，上溢之后设为最大的整数值。例如，i8整型的值从120开始加10后，结果是127，继续增加，结果还是保持为127。
下溢也是同理，但量结果值将会保持在最负的负数值。
- `FAIL` 失败算法，这种模式下，在检测到上溢或下溢时，不做任何操作。相应的返回值会设为NULL，并返回给调用者。

```bash
redis> set w hello
OK
redis> bitfield w overflow sat incrby u4 2 1
1) (integer) 11
redis> bitfield w overflow sat incrby u4 2 1
1) (integer) 12
redis> bitfield w overflow sat incrby u4 2 1
1) (integer) 13
redis> bitfield w overflow sat incrby u4 2 1
1) (integer) 14
redis> bitfield w overflow sat incrby u4 2 1
1) (integer) 15
redis> bitfield w overflow sat incrby u4 2 1  # 保持最大值
1) (integer) 15

redis> set w hello
OK
redis> bitfield w overflow fail incrby u4 2 1
1) (integer) 11
redis> bitfield w overflow fail incrby u4 2 1
1) (integer) 12
redis> bitfield w overflow fail incrby u4 2 1
1) (integer) 13
redis> bitfield w overflow fail incrby u4 2 1
1) (integer) 14
redis> bitfield w overflow fail incrby u4 2 1
1) (integer) 15
redis> bitfield w overflow fail incrby u4 2 1  # 不执行
1) (nil)
```



