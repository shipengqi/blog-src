---
title: 笔记 从零开始学架构
date: 2018-10-19 10:06:07
categories: ["Others"]
---

## 架构和框架有什么区别？

架构关注的是结构，框架关注的是规范，如`MVC`。



## 架构设计的目的是什么？

**架构设计的主要目的是为了解决软件系统复杂度带来的问题。**

1. 通过熟悉和理解需求，识别系统复杂性所在的地方，然后针对这些复杂点进行架构设计。
2. 架构设计并不是要面面俱到，不需要每个架构都具备高性能、高可用、高扩展等特点，而是要识别出复杂点然后有针对性地解决问题。
3. 理解每个架构方案背后所需要解决的复杂点，然后才能对比自己的业务复杂点，参考复杂点相似的方案。

例如，一个学生管理系统。

其基本功能包括登录、注册、成绩管理、课程管理等。当我们对这样一个系统进行架构设计的时候，首先应识别其复杂度到底体现在哪里。
性能：一个学校的学生大约`1 ~ 2`万人，学生管理系统的访问频率并不高，平均每天单个学生的访问次数平均不到 1 次，因此性能这部分并不复杂，
存储用`MySQL`完全能够胜任，缓存都可以不用，Web 服务器用 Nginx 绰绰有余。

可扩展性：学生管理系统的功能比较稳定，可扩展的空间并不大，因此可扩展性也不复杂。

高可用：学生管理系统即使宕机 2 小时，对学生管理工作影响并不大，因此可以不做负载均衡，更不用考虑异地多活这类复杂的方案了。但是，如果学生的数据全部丢失，修复是非常麻烦的，只能靠人工逐条修复，这个很难接受，因此需要考虑存储高可靠，这里就有点复杂了。我们需要考虑多种异常情况：机器故障、机房故障，针对机器故障，我们需要设计`MySQL`同机房主备方案；针对机房故障，我们需要设计`MySQL`跨机房同步方案。

安全性：学生管理系统存储的信息有一定的隐私性，例如学生的家庭情况，但并不是和金融相关的，也不包含强隐私（例如玉照、情感）的信息，因此安全性方面只要做 3 个事情就基本满足要求了：
- Nginx 提供 ACL 控制
- 用户账号密码管理
- 数据库访问权限控制。

成本：由于系统很简单，基本上几台服务器就能够搞定，对于一所大学来说完全不是问题，可以
无需太多关注。

## 复杂度来源
架构设计的主要目的是为了解决软件系统复杂度带来的问题，复杂度有 6 个来源。

### 高性能
软件系统中高性能带来的复杂度主要体现在两方面，一方面是单台计算机内部为了高性能带来的复杂度；另一方面是多台计算机集群为了高性能带来的复杂度。

#### 单机复杂度
计算机内部复杂度最关键的地方就是操作系统。计算机性能的发展本质上是由硬件发展驱动的，尤其是CPU 的性能发展。

#### 集群复杂度
##### 任务分配
##### 任务分解

### 高可用
高可用：系统无中断地执行其功能的能力，代表系统的可用性程度，是进行系统设计时的准则之一。

#### 计算高可用
#### 存储高可用
对于需要存储数据的系统来说，整个系统的高可用设计关键点和难点就在于**存储高可用**。

存储高可用的难点不在于如何备份数据，而在于如何减少或者规避数据不一致对业务造成的影响。

#### 高可用状态决策
无论是计算高可用还是存储高可用，其基础都是**状态决策**，即系统需要能够判断当前的状态是正常还是异常，
如果出现了异常就要采取行动来保证高可用。

几种常见的决策方式：
1. 独裁式
2. 协商式
3. 民主式

### 可扩展性
可扩展性指系统为了应对将来需求变化而提供的一种扩展能力，当有新的需求出现时，系统不需要或者仅需要少量修改就可以支持，无须整个系统重构或者重建。
面向对象思想的提出，就是为了解决可扩展性带来的问题；后来的设计模式，更是将可扩展性做到了极致。

设计具备良好可扩展性的系统，有两个基本条件：正确预测变化、完美封装变化。

#### 预测变化
#### 应对变化
#### 封装变化
### 低成本、安全、规模

## 架构设计的三个原则
优秀程序员和架构师之间有一个明显的鸿沟需要跨越，这个鸿沟就是“不确定性”。

### 合适原则
合适优于业界领先。

1. 没那么多人，却想干那么多活，是失败的第一个主要原因。
2. 没有那么多积累，却想一步登天，是失败的第二个主要原因。
3. 没有那么卓越的业务场景，却幻想灵光一闪成为天才，是失败的第三个主要原因。

### 简单原则
简单优于复杂。

软件领域的复杂性体现在两个方面：
1. 结构的复杂性
2. 逻辑的复杂性

### 演化原则
演化优于一步到位。

## 架构设计流程
1. 识别复杂度
将主要的复杂度问题列出来，然后根据业务、技术、团队等综合情况进行排序，优先解决当前面临的最主要的复杂度问题。

2. 设计备选方案
备选阶段关注的是技术选型，而不是技术细节，技术选型的差异要比较明显。

3. 评估和选择备选方案
列出我们需要关注的质量属性点，然后分别从这些质量属性的维度去评估每个方案，再综合挑选适合当时情况的最优方案。

4. 详细方案设计

## 高性能数据库集群
### 读写分离
读写分离的基本原理是将数据库的读写操作分散到不同的节点。

基本实现：
- 数据库服务器搭建主从集群，一主一从或者一主多从。
- 主节点负责读写操作，从节点只负责读操作。
- 主节点复制数据同步到从节点，每个节点都存储所有业务数据。
- 业务服务器将写操作发给主节点，读操作发给从节点。

#### 复制延迟
数据在写入后立刻读，由于读操作在从机，因为复制延迟，导致从机还没有将数据复制过来，就会出现读取数据失败的问题。

解决方案：
- 写操作后的读操作发给主机。
对业务侵入，影响较大。 
- 从机读取失败后再读一次主机。
也叫二次读取，优点是改动不大，只需要对访问数据库的API进行封装，弊端是如果碰到大量的二次读取操作，会对主机造成很大的
读操作压力，导致崩溃。
- 关键业务的读操作发给主机，非关键业务采用读写分离。

#### 分配机制
##### 程序代码封装（中间层封装）
##### 中间件封装

### 分库分表
读写分离缓解了读操作的压力，但是没有分散写操作的压力。当数据量达到千万或者上亿，对于单台数据库服务器：
- 数据量太大，读写性能下降，索引会变得很庞大，性能同样下降。
- 数据文件很大，备份耗时长。
- 数据文件大，丢失数据的风险越高。

解决方案，将数据存储到多台数据库服务器上。

#### 业务分库
业务分库指的是按照业务模块将数据分散到不同的数据库服务器。

业务分库带来的问题：
1. `join`操作，原本在同一个数据库中的表，分散到不同的数据库中，无法使用`join`表查询。
2. 事务问题，原本在同一个数据库中的不同表可以在事务中修改，分库后无法通过事务同意修改。
3. 成本问题，未分库时只需一台服务器，分库后需要多台。

#### 分表
当单表数据达到数据库处理瓶颈时，比如将几亿的数据放到一台服务器的一张表中，性能肯定无法满足，这是就需要分表。

- 垂直拆分，按照表的列来拆分。
- 水平拆分，按照表的行来拆分。

<img src="/images/arch/split.jpg" width="80%" height="">

分表后，即使拆分的新表在同一个数据库服务器，性能也会显著提高，如果满足需求就不需要拆分到多个数据库服务器。

##### 垂直分表
垂直分表适合江不常用并且占用空间大的列分出去。

垂直分表引入的复杂性，就是原本只需要查一次的操作，需要多次操作才行。

##### 水平分表
适合非常庞大表，有些公司表的行数超过5000万，就要分表。这并不是标准，关键在表的性能，比较复杂的表，1000万可能就需要分表。
一些简单的表，可能超过1个亿才需要分表。但是当行数超过千万就应该考虑性能的问题。

水平分表的复杂性：
- 路由
水平分表后，某条数据具体数据哪个切分后的子表，需要路由算法计算，会引入复杂性。常见的路由算法：
  - 范围路由
  - hash 路由
  - 配置路由
- join 操作
- count 操作
- order by 操作

## NoSQL

关系型数据库的缺点：
- 关系型数据库无法存储数据结构。
- Schema 扩展不方便，表结构是强约束，操作不存在的列会报错，当业务变化时，扩展列很麻烦。
- 对大表进行统计之类的运算，I/O 会很高，因为即使只针对一列，数据库也会将整行数据读入内存。
- 全文搜索功能使用`like`全表扫描匹配，性能低下。

NoSQL 虽然为解决上述问题，带来了优势，但是牺牲了ACID中的某些特性。所以不要盲目使用 NoSQL，它可以作为 SQL 数据库的补充。**NoSQL = Not Only SQL**。

常见的四类NoSQL：
- K-V 存储（Redis），解决无法存储数据结构的问题。
- 文档数据库（Mongodb），解决表结构是强约束的问题。
- 列式数据库（HBase），解决大数据长街下的 I/O 问题。
- 文档搜索引擎（Elasticsearch），解决全文搜索性能问题。

## 高性能缓存架构
虽然可以通过各种手段来提升存储系统的性能，但在某些复杂的业务场景下，单纯依靠存储系统的性能提升不够的：
- 需要经过复杂运算后得出的数据，存储系统无能为力。
- 读多写少的数据，存储系统有心无力。以微博为例：一个明星发一条微博，可能几千万人来浏览。如果使用MySQL来存储微博，用户写微博只有一条insert语句，但每个用户浏览时都要select一次，即使有索引，几千万条select语句对MySQL数据库的压力也会非常大。

缓存就是为了弥补存储系统在这些复杂业务场景下的不足。但是缓存的也引入了更多复杂性。

### 缓存穿透
1. 存储数据不存在
2. 缓存数据生成耗费大量时间或者资源
### 缓存雪崩
### 缓存热点

## 单服务器高性能模式：PPC与TPC

高性能架构设计主要集中在两方面：
- 尽量提升单服务器的性能，将单服务器的性能发挥到极致。
- 如果单服务器无法支撑性能，设计服务器集群方案。

架构设计是高性能的基础，如果架构设计没有做到高性能，则后面的具体实现和编码能提升的空间是有限的。

单服务器高性能的关键之一就是**服务器采取的并发模型**，并发模型有如下两个关键设计点：
- 服务器如何管理连接。
- 服务器如何处理请求。

### PPC
PPC是Process Per Connection的缩写，其含义是指每次有新的连接就新建一个进程去专门处理这个连接的请求，这是传统的UNIX网络服务器所采用的模型。
### TPC
TPC是Thread Per Connection的缩写，其含义是指每次有新的连接就新建一个线程去专门处理这个连接的请求。

## 单服务器高性能模式：Reactor与Proactor
PPC和TPC模式，它们的优点是实现简单，缺点是都无法支撑高并发的场景，尤其是互联网发展到现在，各种海量用户业务的出现，PPC和TPC完全无能为力。

### Reactor
### Proactor

## 高性能负载均衡
当单服务器的性能无法满足业务需求时，就需要设计高性能集群来提升系统整体的处理性能。

由于计算本身存在一个特点：同样的输入数据和逻辑，无论在哪台服务器上执行，都应该得到相同的输出。因此高性能集群设计的复杂度主要体现在任务分配这部分，需要设计合理的任务分配策略，将计算任务分配到多台服务器上执行。

**高性能集群的复杂性主要体现在需要增加一个任务分配器，以及为任务选择一个合适的任务分配算法。**

不同的任务分配算法目标是不一样的，有的基于负载考虑，有的基于性能（吞吐量、响应时间）考虑，有的基于业务考虑。考虑到“负载均衡”已经成为了事实上的标准术语，这里我也用“负载均衡”来代替“任务分配”，但请你时刻记住，负载均衡不只是为了计算单元的负载达到均衡状态。

常见的负载均衡系统包括3种：DNS负载均衡、硬件负载均衡和软件负载均衡。

### DNS负载均衡

DNS是最简单也是最常见的负载均衡方式，一般用来实现地理级别的均衡。
例如，北方的用户访问北京的机房，南方的用户访问深圳的机房。DNS负载均衡的本质是DNS解析同一个域名可以返回不同的IP地址。例如，同样是www.baidu.com，北方用户解析后获取的地址是61.135.165.224（这是北京机房的IP），南方用户解析后获取的地址是14.215.177.38（这是深圳机房的IP）。

### 硬件负载均衡

硬件负载均衡是通过单独的硬件设备来实现负载均衡功能，这类设备和路由器、交换机类似，可以理解为一个用于负载均衡的基础网络设备。

### 软件负载均衡

软件负载均衡通过负载均衡软件来实现负载均衡功能，常见的有Nginx和LVS，其中Nginx是软件的7层负载均衡，LVS是Linux内核的4层负载均衡。4层和7层的区别就在于协议和灵活性，Nginx支持HTTP、E-mail协议；而LVS是4层负载均衡，和协议无关，几乎所有应用都可以做，例如，聊天、数据库等。

### 负载均衡典型架构

组合的基本原则为：DNS负载均衡用于实现地理级别的负载均衡；硬件负载均衡用于实现集群级别的负载均衡；软件负载均衡用于实现机器级别的负载均衡。

## 高性能负载均衡：算法
高性能负载均衡算法可以分为下面几类：
- 任务平分类：负载均衡系统将收到的任务平均分配给服务器进行处理，这里的“平均”可以是绝对数量的平均，也可以是比例或者权重上的平均。
- 负载均衡类：负载均衡系统根据服务器的负载来进行分配，这里的负载并不一定是通常意义上我们说的“CPU负载”，而是系统当前的压力，可以用CPU负载来衡量，也可以用连接数、I/O使用率、网卡吞吐量等来衡量系统的压力。
- 性能最优类：负载均衡系统根据服务器的响应时间来进行任务分配，优先将新任务分配给响应最快的服务器。
- Hash类：负载均衡系统根据任务中的某些关键信息进行Hash运算，将相同Hash值的请求分配到同一台服务器上。常见的有源地址Hash、目标地址Hash、session id hash、用户ID Hash等。

### 轮询
### 加权轮询
### 负载最低优先
### 性能最优类
### Hash类

## CAP理论










