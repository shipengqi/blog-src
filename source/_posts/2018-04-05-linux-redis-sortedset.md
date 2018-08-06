---
title: Redis 数据类型 Sorted Set
date: 2018-04-05 22:11:54
categories: ["Linux"]
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
### ZCARD
### ZRANK
### ZSCORE
### ZCOUNT
### ZLEXCOUNT
### ZRANGE
### ZREVRANGE
### ZRANGEBYLEX
### ZRANGEBYSCORE
### ZREVRANGEBYLEX
### ZREVRANGEBYSCORE

## 自增
### ZINCRBY
## 删除
### ZREM
### ZREMRANGEBYLEX
### ZREMRANGEBYRANK
### ZREMRANGEBYSCORE

## 合并
### ZUNIONSTORE
### ZINTERSTORE

## 其他
### ZSCAN
参考**SCAN**。
```bash
ZSCAN key cursor [MATCH pattern] [COUNT count]
```