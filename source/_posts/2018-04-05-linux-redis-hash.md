---
title: Redis 数据类型 hash
date: 2018-04-05 22:11:34
categories: ["Linux"]
tags: ["Redis"]
---

Redis对JSON数据的支持不是很友好。通常把JSON转成String存储到Redis中，但现在的JSON数据都是连环嵌套的，每次更新时都要先获取整个JSON，然后更改其中一个字段再放上去。
这种使用方式，如果在海量的请求下，JSON字符串比较复杂，会导致在频繁更新数据使网络I/O跑满，甚至导致系统超时、崩溃。
所以Redis官方推荐采用哈希保存对象。

<!-- more -->