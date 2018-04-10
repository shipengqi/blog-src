---
title: Redis 键(Key)操作
date: 2018-04-05 23:42:45
categories: ["Linux"]
tags: ["Redis"]
---

Redis 中键Key操作也是常用的的操作。

<!-- more -->

## 查找
``` bash
KEYS pattern
```
`pattern`指定匹配模式：
``` bash
#查找数据库中所有的key
redis> KEYS *
1) "db"
2) "db2"
3) "class1"
4) "class2"
5) "testkey"

redis> KEYS *a*
1) "class1"
2) "class2"

redis> KEYS t??
1) "two"

redis> KEYS class[1]
1) "class2"

```
## EXISTS
该命令用来判断某个key是否存在。
``` bash
EXISTS key
```
检查指定的`key`是否存在。：
``` bash
redis> SET testkey hello
OK

redis> EXISTS testkey
(integer) 1

redis> DEL testkey
(integer) 1

redis> EXISTS testkey
(integer) 0
```

## RANDOMKEY
从当前数据库中随机返回一个`key`。数据库非空时，返回一个`key`；为空时，返回`nil`。
``` bash
# 设置多个 key
redis> MSET fruit "apple" drink "beer" food "cookies"
OK

redis> RANDOMKEY
"fruit"

redis> RANDOMKEY
"food"

# 返回 key 但不删除
redis> KEYS *
1) "food"
2) "drink"
3) "fruit"

# 删除当前数据库所有 key，数据库为空
redis> FLUSHDB
OK
redis> RANDOMKEY
(nil)
```

## TYPE
返回指定`key`的存储值的类型。
``` bash
redis> SET student xiaoming
OK
redis> TYPE student
string

# 列表
redis> LPUSH student_list "xiaoming xiaoqiang xiaogang"
(integer) 1
redis> TYPE student_list
list

# 集合
redis> SADD students "xiaoli"
(integer) 1
redis> TYPE students
set
```
## SORT
返回指定key中经过排序的元素，key可能是列表、集合、有序集合。排序默认以数字作为对象，值被解释为双精度浮点数，然后进行比较。
``` bash
SORT key [BY pattern] [LIMIT offset count] [GET pattern [GET pattern ...]] [ASC | DESC] [ALPHA] [STORE destination]
```
`SORT`的两种简单的用法：

- `SORT ke`y，将键值按从大到小顺序排序
- `SORT key DESC`，将键值按从小到大的顺序排序

```bash
使用ALPHA排序字符串

SORT默认的排序对象为数字，如果需要对字符串进行排序，就要增加ALPHA参数：

# 一些网址
redis> LPUSH website "www.reddit.com"
(integer) 1

redis> LPUSH website "www.slashdot.com"
(integer) 2

redis> LPUSH website "www.itbilu.com"
(integer) 3

# 默认（按数字）排序
redis> SORT website
1) "www.itbilu.com"
2) "www.slashdot.com"
3) "www.reddit.com"

# 按字符排序
redis> SORT website ALPHA
1) "www.itbilu.com"
2) "www.reddit.com"
3) "www.slashdot.com"


使用LIMIT限制返回结果

与SQL查询类似，Redis 同样可以使用LIMIT限制返回结果数量，该修饰符接收offset和count两个参数：

offset，指定偏移量
count，指定返回数量
如，返回前5个元素：

# 添加测试数据，列表值为 1 指 10
redis> RPUSH rank 1 3 5 7 9
(integer) 5

redis> RPUSH rank 2 4 6 8 10
(integer) 10

# 返回列表中最小的 5 个值
redis> SORT rank LIMIT 0 5
1) "1"
2) "2"
3) "3"
4) "4"
5) "5"
也可以对返回结果进行排序：

redis> SORT rank LIMIT 0 5 DESC
1) "10"
2) "9"
3) "8"
4) "7"
5) "6"


排序可以使用外部key的数据权重做为排序依据。

现在以下数据表：

uid	user_name_{uid}	user_level_{uid}
1	admin	9999
2	jack	10
3	peter	25
4	mary	70
将数据存入 Redis 中：

# admin
redis> LPUSH uid 1
(integer) 1
redis> SET user_name_1 admin
OK
redis> SET user_level_1 9999
OK

# jack
redis> LPUSH uid 2
(integer) 2
redis> SET user_name_2 jack
OK
redis> SET user_level_2 10
OK

# peter
redis> LPUSH uid 3
(integer) 3
redis> SET user_name_3 peter
OK
redis> SET user_level_3 25
OK

# mary
redis> LPUSH uid 4
(integer) 4
redis> SET user_name_4 mary
OK
redis> SET user_level_4 70
OK
BY 选项

默认情况下，SORT uid会按uid的值排序：

redis> SORT uid
1) "1"      # admin
2) "2"      # jack
3) "3"      # peter
4) "4"      # mary
可以通过BY选项为其指定其它元素来排序：

redis> SORT uid BY user_level_*
1) "2"      # jack , level = 10
2) "3"      # peter, level = 25
3) "4"      # mary, level = 70
4) "1"      # admin, level = 9999
GET 选项

GET 选项可以根据排序结果取出对应的键值：

redis> SORT uid GET user_name_*
1) "admin"
2) "jack"
3) "peter"
4) "mary"
BY和GET结合使用

如，先按user_level_{uid}来排序uid列表，再取出相应的user_name_{uid}的值：

 value="redis> SORT uid BY user_level_* GET user_name_*
1) "jack"       # level = 10
2) "peter"      # level = 25
3) "mary"       # level = 70
4) "admin"      # level = 9999" max=""
获取多个外部键

使用多个GET，可以获取多个外部键的值：

redis> SORT uid GET user_level_* GET user_name_*
1) "9999"       # level
2) "admin"      # name
3) "10"
4) "jack"
5) "25"
6) "peter"
7) "70"
8) "mary"
GET可以使用#获取被排序键的值：

redis> SORT uid GET # GET user_level_* GET user_name_*
1) "1"          # uid
2) "9999"       # level
3) "admin"      # name
4) "2"
5) "10"
6) "jack"
7) "3"
8) "25"
9) "peter"
10) "4"
11) "70"
12) "mary"


保存排序结果

默认情况下，SORT命令只是返回排序结果，而不做其它处理。我们可以为其指定一个key参数，将结果保存在指定键上。如果指定key已存在，会发生覆盖：

redis> RPUSH numbers 1 3 5 7 9
(integer) 5

redis> RPUSH numbers 2 4 6 8 10
(integer) 10

redis> LRANGE numbers 0 -1
1) "1"
2) "3"
3) "5"
4) "7"
5) "9"
6) "2"
7) "4"
8) "6"
9) "8"
10) "10"

redis> SORT numbers STORE sorted-numbers
(integer) 10

# 排序后的结果
redis> LRANGE sorted-numbers 0 -1
1) "1"
2) "2"
3) "3"
4) "4"
5) "5"
6) "6"
7) "7"
8) "8"
9) "9"
10) "10"


时间复杂度：O(N+M*log(M))，N为要排序的列表或集合内的元素数量，M 为要返回的元素数量。 如果只是使用SORT命令的GET选项获取数据而没有进行排序，时间复杂度O(N)。
返回值：没有使用STORE，返回列表形式的排序结果；使用STORE参数，返回排序结果的元素数量
```
## DEL 删除

## 重命名
### RENAME - 重命令
### RENAMENX - 仅当不存在时重命名
## DUMP 序列化
## RESTORE 反序列化

## EXPIRE
设置key的过期时间
## EXPIREAT
以时间戳格式设置过期时间
## PERSISTAT
设置过期时间
## PERSIST
移除生存时间
## TTL
返回剩余生存时间(秒)
## PTTL
返回剩余生存时间(毫秒)
## 键迁移
### MIGRATE
实例间键迁移
### MOVE
同实例不同库间的键移动

## 其它
### OBJECT - 内部调试
### SCAN - 增量迭代
