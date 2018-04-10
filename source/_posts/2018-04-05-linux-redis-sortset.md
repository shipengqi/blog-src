---
title: Redis 数据类型 sort set
date: 2018-04-05 22:11:54
categories: ["Linux"]
tags: ["Redis"]
---

Redis zset 和 set 一样也是string类型元素的集合,且不允许重复的成员。
不同的是每个元素都会关联一个double类型的分数。redis正是通过分数来为集合中的成员进行从小到大的排序。zset的成员是唯一的,但分数(score)却可以重复。

<!-- more -->