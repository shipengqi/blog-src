---
title: Redis 数据类型 Sorted Set
date: 2018-04-05 22:11:54
categories: ["数据库"]
tags: ["Redis"]
---

`Redis`的有序集合和`Set`一样也是`String`类型元素的集合,且不允许重复的成员。`Redis`提供的最为特色的数据结构。
不同的是每个元素都会关联一个double类型的分数。redis正是通过分数来为集合中的成员进行从小到大的排序。zset的成员是唯一的,但分数(score)却可以重复。

<!-- more -->

`Redis`的`ZSET`类似`Java`的`SortedSet`和`HashMap`的结合体，既保证了内部`value`的唯一性，还可以给每个`value`赋予一个`score`，代表这个`value`的排序权重。
当集合移除了最后一个元素之后，该`key`会被自动被删除，内存被回收。

`ZSET`可以用来存粉丝列表，`value`值是粉丝的`用户ID`，`score`是关注时间。我们可以对粉丝列表按关注时间进行排序。
`ZSET`还可以用来存储学生的成绩，`value`值是学生的`ID`，`score`是考试成绩。可以按分数对名次进行排序就。

## 存取
### ZADD
将一个或多个`member`元素及其`score`值添加到有序集合`key`中。
```bash
ZADD key score member [[score member] [score member] ...]
```
`score`可以是整数或双精度浮点数。
如果`key`不存在，创建`key`并执行`ZADD`。如果`key`不是有序集合类型，返回一个错误。
如果`member`已经存在，则更新其`score`值，并重新插入，排序。

```bash
# 添加单个元素

redis> ZADD page_rank 10 google.com
(integer) 1


# 添加多个元素

redis> ZADD page_rank 9 baidu.com 8 bing.com
(integer) 2

redis> ZRANGE page_rank 0 -1 WITHSCORES
1) "bing.com"
2) "8"
3) "baidu.com"
4) "9"
5) "google.com"
6) "10"


# 添加已存在元素，且 score 值不变

redis> ZADD page_rank 10 google.com
(integer) 0

redis> ZRANGE page_rank 0 -1 WITHSCORES  # 没有改变
1) "bing.com"
2) "8"
3) "baidu.com"
4) "9"
5) "google.com"
6) "10"


# 添加已存在元素，但是改变 score 值

redis> ZADD page_rank 6 bing.com
(integer) 0

redis> ZRANGE page_rank 0 -1 WITHSCORES  # bing.com 元素的 score 值被改变
1) "bing.com"
2) "6"
3) "baidu.com"
4) "9"
5) "google.com"
6) "10"
```
### ZCARD
返回有序集合`key`的基数。
```bash
ZCARD key
```

如果`key`不存在，返回`0`。

```bash
# 添加一个元素
redis > ZADD salary 2000 tom
(integer) 1

redis > ZCARD salary
(integer) 1

 # 再添加一个元素
redis > ZADD salary 5000 jack
(integer) 1

redis > ZCARD salary
(integer) 2

# 对不存在的有序集合进行 ZCARD 操作
redis > EXISTS non_exists_key
(integer) 0

redis > ZCARD non_exists_key
(integer) 0
```
### ZRANK
返回有序集合`key`中的指定`member`元素的排名。
```bash
ZRANK key member
```

元素成员按`score`值递增，相同`score`值的成员按字典排序。注意**元素排名从`0`开始计数，也就是说第一名返回的是`0`，以此类推**。
如果`key`不是有序集合类型，返回`nil`。

```bash
# 显示所有成员及其 score 值
redis> ZRANGE salary 0 -1 WITHSCORES
1) "peter"
2) "3500"
3) "tom"
4) "4000"
5) "jack"
6) "5000"

# tom 排名第二
redis> ZRANK salary tom
(integer) 1
```
### ZSCORE
返回有序集合`key`中的指定`member`元素的`score`值。
```bash
ZRANK key member
```

如果`key`或`member`不存在，返回`nil`。

```bash
redis> ZRANGE salary 0 -1 WITHSCORES
1) "tom"
2) "2000"
3) "peter"
4) "3500"
5) "jack"
6) "5000"

# 返回值是字符串形式
redis> ZSCORE salary peter
"3500"
```
### ZCOUNT
返回有序集合`key`中`score`值在`min`和`max`之间的元素个数，**注意包含值为`min`和`max`的元素**。

```bash
ZCOUNT key min max
```

如果`key`不存在，返回`0`。

```bash
# 测试数据
redis> ZRANGE salary 0 -1 WITHSCORES
1) "jack"
2) "2000"
3) "peter"
4) "3500"
5) "tom"
6) "5000"

# 计算薪水在 2000-5000 之间的人数
redis> ZCOUNT salary 2000 5000
(integer) 3

# 计算薪水在 3000-5000 之间的人数
redis> ZCOUNT salary 3000 5000
(integer) 2
```

### ZLEXCOUNT

返回有序集合`key`中指定元素`min`和`max`之间的元素个数，**注意包含值为`min`和`max`的元素**。

```bash
ZLEXCOUNT key min max
```
**这里的`max`和`min`分别指的是：有序集合中分数排名较大的成员，有序集合中分数排名较小的成员。`ZLEXCOUNT key min max`相当于`ZLEXCOUNT key [min-member [max-member`**
成员名称前需要加`[`符号作为开头,`[`符号与成员之间不能有空格。
可以使用`-`和`+`表示`score`的最小值和最大值。
`max`放前面，`min`放后面会导致返回结果为`0`。
如果`key`不存在，返回`0`。

```bash
redis> ZADD myzset 0 a 0 b 0 c 0 d 0 e
(integer) 5
redis> ZADD myzset 0 f 0 g
(integer) 2
redis> ZLEXCOUNT myzset - +
(integer) 7
redis> ZLEXCOUNT myzset [b [f
(integer) 5
```

### ZRANGE

返回有序集合`key`指定区间内的元素。`WITHSCORES`用于指定是否同时返回元素的`score`。

```bash
ZRANGE key start stop [WITHSCORES]
```
`start`和`stop`都是从`0`开始。可以是负数，如，`-1`表示列表的最后一个元素， `-2`表示列表的倒数第二个元素，以此类推。。
元素成员按`score`值递增，相同`score`值的成员按字典排序。

```bash
# 显示有序集合所有成员
redis > ZRANGE salary 0 -1 WITHSCORES
1) "jack"
2) "3500"
3) "tom"
4) "5000"
5) "boss"
6) "10086"

# 返回有序集下标区间 1 至 2 的成员
redis > ZRANGE salary 1 2 WITHSCORES
1) "tom"
2) "5000"
3) "boss"
4) "10086"

# end 超出最大下标时
redis > ZRANGE salary 0 200000 WITHSCORES
1) "jack"
2) "3500"
3) "tom"
4) "5000"
5) "boss"
6) "10086"

# 当指定区间超出有序集合范围时
redis > ZRANGE salary 200000 3000000 WITHSCORES
(empty list or set)
```

### ZREVRANGE
`ZREVRANGE`和`ZRANGE`类似，区别在于排序，`ZREVRANGE`的`score`值按倒序(从大到小)顺序排序。`WITHSCORES`用于指定是否同时返回元素的`score`。

```bash
ZREVRANGE key start stop [WITHSCORES]
```

```bash
# 递增排列
redis> ZRANGE salary 0 -1 WITHSCORES
1) "peter"
2) "3500"
3) "tom"
4) "4000"
5) "jack"
6) "5000"

# 递减排列
redis> ZREVRANGE salary 0 -1 WITHSCORES
1) "jack"
2) "5000"
3) "tom"
4) "4000"
5) "peter"
6) "3500"
```

### ZRANGEBYLEX

返回有序集合`key`指定区间内的元素。`WITHSCORES`用于指定是否同时返回元素的`score`。

```bash
ZRANGEBYLEX key min max [LIMIT offset count]
```
**这里的`max`和`min`分别指的是：有序集合中分数排名较大的成员，有序集合中分数排名较小的成员。`ZRANGEBYLEX key min max`相当于`ZRANGEBYLEX key [min-member [max-member`**
成员名称前需要加`[`符号作为开头,`[`符号与成员之间不能有空格。
可以使用`-`和`+`表示`score`的最小值和最大值。
`max`放前面，`min`放后面会导致返回结果为`0`。
**不要在分数不一致的有序集合中去使用`ZRANGEBYLEX`,因为获取的结果并不准确。**

```bash
redis> zadd zset 0 a 0 aa 0 abc 0 apple 0 b 0 c 0 d 0 d1 0 dd 0 dobble 0 z 0 z1
(integer) 12
redis> ZRANGEBYLEX zset - +
 1) "a"
 2) "aa"
 3) "abc"
 4) "apple"
 5) "b"
 6) "c"
 7) "d"
 8) "d1"
 9) "dd"
10) "dobble"
11) "z"
12) "z1"
```

### ZRANGEBYSCORE

返回有序集合`key`中`score`值位于`max`和`min`(默认包含`max`和`min`)区间内的成员的元素。

```bash
ZRANGEBYSCORE key min max [WITHSCORES] [LIMIT offset count]
```

可选参数：
- `WITHSCORES`：用于指定是否同时返回元素的`score`。
- `LIMIT`：用于指定返回元素数量，
- `offset`：用于指定偏移量(类似`SQL`中的`SELECT LIMIT offset, count`)。

`-inf`和`+inf`可以表示最小值和最大值。

```bash
# 测试数据
redis> ZADD salary 2500 jack
(integer) 0
redis> ZADD salary 5000 tom
(integer) 0
redis> ZADD salary 12000 peter
(integer) 0

# 显示整个有序集合
redis> ZRANGEBYSCORE salary -inf +inf
1) "jack"
2) "tom"
3) "peter"

# 显示整个有序集合及成员的 score 值
redis> ZRANGEBYSCORE salary -inf +inf WITHSCORES
1) "jack"
2) "2500"
3) "tom"
4) "5000"
5) "peter"
6) "12000"

# 工资 <=5000 的成员
redis> ZRANGEBYSCORE salary -inf 5000 WITHSCORES
1) "jack"
2) "2500"
3) "tom"
4) "5000"

# 工资大于 5000 小于等于 400000 的成员
redis> ZRANGEBYSCORE salary 5000 400000
1) "peter"
```

### ZREVRANGEBYLEX

`ZREVRANGEBYLEX`和`ZRANGEBYLEX`类似，区别在于排序，`ZREVRANGEBYLEX`的`score`值按倒序(从大到小)顺序排序。

```bash
ZREVRANGEBYLEX key max min [WITHSCORES] [LIMIT offset count]
```

```bash
redis> zadd zset 0 a 0 aa 0 abc 0 apple 0 b 0 c 0 d 0 d1 0 dd 0 dobble 0 z 0 z1
(integer) 12
redis> ZREVRANGEBYLEX zset + -
 1) "z1"
 2) "z"
 3) "dobble"
 4) "dd"
 5) "d1"
 6) "d"
 7) "c"
 8) "b"
 9) "apple"
10) "abc"
11) "aa"
12) "a"
```

### ZREVRANGEBYSCORE

`ZREVRANGEBYSCORE`和`ZRANGEBYSCORE`类似，区别在于排序，`ZREVRANGEBYSCORE`的`score`值按倒序(从大到小)顺序排序。

```bash
ZREVRANGEBYSCORE key max min [WITHSCORES] [LIMIT offset count]
```

```bash
redis > ZADD salary 10086 jack
(integer) 1
redis > ZADD salary 5000 tom
(integer) 1
redis > ZADD salary 7500 peter
(integer) 1
redis > ZADD salary 3500 joe
(integer) 1

# 倒序返回所有成员
redis > ZREVRANGEBYSCORE salary +inf -inf
1) "jack"
2) "peter"
3) "tom"
4) "joe"

# 倒序返回salary于 10000 和 2000 之间的成员
redis > ZREVRANGEBYSCORE salary 10000 2000
1) "peter"
2) "tom"
3) "joe"
```

## 自增
### ZINCRBY
为有序集合`key`中的`member`元素的`score`值增加增量`increment`。
```bash
ZINCRBY key increment member
```
`score`可以是整数或双精度浮点数。
如果`key`不存在或者`member`不存在，执行`ZINCRBY key increment member`相当于执行`ZADD key increment member`。
如果`key`不是有序集合类型，返回一个错误。

```bash
redis> ZSCORE salary tom
"2000"

redis> ZINCRBY salary 2000 tom
"4000"
```
## 删除
### ZREM
移除有序集合`key`中的一个或多个元素`member`。
```bash
ZREM key member [member ...]
```
如果`key`不是有序集类型，返回一个错误。
```bash
# 测试数据
redis> ZRANGE page_rank 0 -1 WITHSCORES
1) "bing.com"
2) "8"
3) "baidu.com"
4) "9"
5) "google.com"
6) "10"


# 移除单个元素
redis> ZREM page_rank google.com
(integer) 1

redis> ZRANGE page_rank 0 -1 WITHSCORES
1) "bing.com"
2) "8"
3) "baidu.com"
4) "9"


# 移除多个元素
redis> ZREM page_rank baidu.com bing.com
(integer) 2

redis> ZRANGE page_rank 0 -1 WITHSCORES
(empty list or set)

# 移除不存在元素
redis> ZREM page_rank non-exists-element
(integer) 0
```
### ZREMRANGEBYLEX

移除有序集合`key`中指定区间内的元素。
```bash
ZREMRANGEBYLEX key min max
```

**这里的`max`和`min`分别指的是：有序集合中分数排名较大的成员，有序集合中分数排名较小的成员。`ZREMRANGEBYLEX key min max`相当于`ZREMRANGEBYLEX key [min-member [max-member`**
成员名称前需要加`[`符号作为开头,`[`符号与成员之间不能有空格。
可以使用`-`和`+`表示`score`的最小值和最大值。
`max`放前面，`min`放后面会导致返回结果为`0`。
**不要在分数不一致的有序集合中去使用`ZREMRANGEBYLEX`,因为获取的结果并不准确。**

```bash
redis> zadd zset 0 a 0 aa 0 abc 0 apple 0 b 0 c 0 d 0 d1 0 dd 0 dobble 0 z 0 z1
(integer) 12
redis> ZRANGEBYLEX zset + -
 1) "a"
 2) "aa"
 3) "abc"
 4) "apple"
 5) "b"
 6) "c"
 7) "d"
 8) "d1"
 9) "dd"
10) "dobble"
11) "z"
12) "z1"
redis> ZREMRANGEBYLEX zset - +
(integer) 7
redis> ZRANGEBYLEX zset - +
(empty list or set)
```

### ZREMRANGEBYRANK

移除有序集合`key`中指定排名(rank)区间内的元素。
```bash
ZREMRANGEBYRANK key start stop
```
`start`和`stop`包含在区间内，可以使用负数，如`-1`表示最后一个元素，依次类推。
```bash
# 测试数据
redis> ZADD salary 2000 jack
(integer) 1
redis> ZADD salary 5000 tom
(integer) 1
redis> ZADD salary 3500 peter
(integer) 1

# 移除 0 至 1 区间内的成员
redis> ZREMRANGEBYRANK salary 0 1
(integer) 2

# 有序集只剩下一个成员
redis> ZRANGE salary 0 -1 WITHSCORES
1) "tom"
2) "5000"
```

### ZREMRANGEBYSCORE

移除有序集合`key`中指定`score`区间内的元素。
```bash
ZREMRANGEBYRANK key min max
```

```bash
# 有序集合内的所有成员及其 score 值
redis> ZRANGE salary 0 -1 WITHSCORES
1) "tom"
2) "2000"
3) "peter"
4) "3500"
5) "jack"
6) "5000"

# 移除所有salary 在 1500 到 3500 内的员工
redis> ZREMRANGEBYSCORE salary 1500 3500
(integer) 2

# 剩余的成员
redis> ZRANGE salary 0 -1 WITHSCORES
1) "jack"
2) "5000"
```

## 合并
### ZUNIONSTORE

计算一或多个有序集合的并集，并将结果存储到`destination`中。
```bash
ZUNIONSTORE destination numkeys key [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM|MIN|MAX]
```

可选参数：
- `WEIGHTS`，乘法因子，所有有序集合值在传递聚合函数前，都要乘以该因子。默认值为`1`
- `AGGREGATE`，指定结果集的聚合方式。
  - `SUM`，求合，默认值
  - `MAX`，计算最大值
  - `MIN`，计算最小值

```bash
redis> ZRANGE programmer 0 -1 WITHSCORES
1) "peter"
2) "2000"
3) "jack"
4) "3500"
5) "tom"
6) "5000"

redis> ZRANGE manager 0 -1 WITHSCORES
1) "herry"
2) "2000"
3) "mary"
4) "3500"
5) "bob"
6) "4000"

# 除 programmer 外，其它成员增加 salary
redis> ZUNIONSTORE salary 2 programmer manager WEIGHTS 1 3
(integer) 6

redis> ZRANGE salary 0 -1 WITHSCORES
1) "peter"
2) "2000"
3) "jack"
4) "3500"
5) "tom"
6) "5000"
7) "herry"
8) "6000"
9) "mary"
10) "10500"
11) "bob"
12) "12000"
```
### ZINTERSTORE

计算一或多个有序集合的交集，并将结果存储到`destination`中。
```bash
ZINTERSTORE destination numkeys key [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM|MIN|MAX]
```

可选参数：
- `WEIGHTS`，乘法因子，所有有序集合值在传递聚合函数前，都要乘以该因子。默认值为`1`
- `AGGREGATE`，指定结果集的聚合方式。
  - `SUM`，求合，默认值
  - `MAX`，计算最大值
  - `MIN`，计算最小值

```bash
redis > ZADD mid_test 70 "Li Lei"
(integer) 1
redis > ZADD mid_test 70 "Han Meimei"
(integer) 1
redis > ZADD mid_test 99.5 "Tom"
(integer) 1

redis > ZADD fin_test 88 "Li Lei"
(integer) 1
redis > ZADD fin_test 75 "Han Meimei"
(integer) 1
redis > ZADD fin_test 99.5 "Tom"
(integer) 1

# 保存交集
redis > ZINTERSTORE sum_point 2 mid_test fin_test
(integer) 3

redis > ZRANGE sum_point 0 -1 WITHSCORES
1) "Han Meimei"
2) "145"
3) "Li Lei"
4) "158"
5) "Tom"
6) "199"
```

## 其他
### ZSCAN
参考**[SCAN](/2018/08/08/redis-key/#more)**。
```bash
ZSCAN key cursor [MATCH pattern] [COUNT count]
```