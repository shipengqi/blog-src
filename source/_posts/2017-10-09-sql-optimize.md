---
title: SQL语句优化
date: 2017-10-09 19:41:55
categories: ["Linux"]
tags: ["SQL"]
---

SQL语句优化整理。

<!-- more -->

1. 尽量避免全表扫描，首先应考虑在`where`及`order by`涉及的列上建立索引。

2. 尽量避免在`where`子句中对判断字段值是否为`null`，否则会导致引擎放弃使用索引而进行全表扫描，如：
```
select id from t where num is null
```

3. 尽量不要给数据库留`NULL`，使用`NOT NULL`填充数据库。备注、描述、评论之类的可以设置为`NULL`，其他的，最好不要使用`NULL`。
不要以为`NULL`不需要空间，比如：char(100) 型，在字段建立时，空间就固定了，不管是否插入值（`NULL`也包含在内），都是占用100个字符的空间的，如果是`varchar`这样的变长字段，`null`不占用空间。

4. 可以在num上设置默认值0，确保表中num列没有null值，然后这样查询：
```
select id from t where num = 0
```

5. 尽量避免在`where`子句中使用`!=`或`<>`操作符，否则会导致引擎放弃使用索引而进行全表扫描。
6. 尽量避免在`where`子句中使用`or`来连接条件，如果一个字段有索引，一个字段没有索引，也会导致引擎放弃使用索引而进行全表扫描，如：
```
select id from t where num=10 or Name = 'admin'
```
    可以这样查询：
    ```
    select id from t where num = 10 union all select id from t where Name = 'admin'
    ```
7. `in` 和 `not in` 谨慎用，否则会导致全表扫描，如：
```
select id from t where num in(1,2,3)
```

8. 对于连续的数值，使用 `between` 代替 `in`：
```
select id from t where num between 1 and 3
```
9. 使用 `exists` 代替 `in`：
```
select num from a where num in(select num from b)
```

    用下面的语句替换：
    ```
    select num from a where exists(select 1 from b where num=a.num)
    ```



10. 避免使用`like`，会导致全表扫描：
```
select id from t where name like ‘%abc%’
```
    若要提高效率，可以考虑全文检索。

11. 在 `where` 子句中使用参数，也会导致全表扫描。因为SQL只有在运行时才会解析局部变量，但优化程序不能将访问计划的选择推迟到运行时；它必须在编译时进行选择。然 而，如果在编译时建立访问计划，变量的值还是未知的，因而无法作为索引选择的输入项。下面语句将进行全表扫描：
```
select id from t where num = @num
```
    可以改为强制查询使用索引：
    ```
    select id from t with(index(索引名)) where num = @num
    ```

12. 避免在 `where`子句中对`字段`进行表达式操作，这同样会导致引擎放弃使用索引而进行全表扫描。如：
```
select id from t where num/2 = 100
```
    应改为:
    ```
    select id from t where num = 100*2
    ```
13. 避免在`where`子句中对字段进行函数操作，这将导致引擎放弃使用索引而进行全表扫描。如：
```
select id from t where substring(name,1,3) = ’abc’       -–name以abc开头的id
select id from t where datediff(day,createdate,’2005-11-30′) = 0    -–‘2005-11-30’    --生成的id
```

    应改为:
    ```
    select id from t where name like 'abc%'select id from t where createdate >= '2005-11-30' and createdate < '2005-12-1'
    ```

14. 不要在 `where` 子句中的`=`左边进行函数、算术运算或其他表达式运算，否则系统将可能无法正确使用索引。

15. 在使用索引字段作为条件时，如果该索引是复合索引，那么必须使用到该索引中的`第一个字段作为条件`时才能保证系统使用该索引，否则该索引将不会被使用，并且应尽可能的让字段顺序与索引顺序相一致。

16. 关于`Update` 语句，如果只需要更改部分字段，不要Update全部字段，否则频繁调用会引起明显的性能消耗，同时带来大量日志。

17. 对于多张表的`JOIN`，要先分页再`JOIN`，否则逻辑读会很高，性能很差。

18. 避免不带任何条件的`count`， 否则会引起全表扫描。如下面的查询会导致全表扫描：
```
select count(*) from table；
```

19. 索引可以提高`select`的效率，但同时也降低了 `insert` 及 `update` 的效率，因为 `insert` 和 `update`有可能会重建索引，所以怎样建索引需要慎重考虑，视具体情况而定。一个表的索引并不是越多越好，数最好不要超过6个，应考虑一些不常使用到的列上建的索引是否有必要。

20. 避免更新 `clustered` 索引数据列，因为 `clustered` 索引数据列的顺序就是表记录的物理存储顺序，一旦该列值改变将导致整个表记录的顺序的调整，会耗费相当大的资源。若应用系统需要频繁更新 `clustered`索引数据列，考虑是否应将该索引建为 `clustered` 索引。

21. 使用数字型字段，若只含数值信息的字段尽量不要设计为字符型，这会降低查询和连接的性能，并会增加存储开销。这是因为引擎在处理查询和连接时会逐个比较字符串中每一个字符，而对于数字型而言只需要比较一次就够了。

22. 使用 `varchar/nvarchar` 代替 `char/nchar` ，因为变长字段存储空间小，可以节省存储空间，其次对于查询来说，在一个相对较小的字段内搜索效率显然要高些。

23. 不要使用 `select * from t` ，用具体的字段列表代替`*`。

24. 使用表变量来代替临时表。如果表变量包含大量数据，请注意索引非常有限（只有主键索引）。

25. 避免频繁创建和删除临时表，以减少系统表资源的消耗。临时表并不是不可使用，适当地使用它们可以使某些例程更有效，例如，当需要重复引用大型表或常用表中的某个数据集时。但是，对于一次性事件， 最好使用导出表。

26. 在新建临时表时，如果一次性插入数据量很大，那么可以使用 `select into` 代替 `create table`，避免造成大量 log ，以提高速度；如果数据量不大，为了缓和系统表的资源，应先`create table`，然后`insert`。
如需要生成一个空表不要用下面的语句：
```
select col1,col2 into #t from t where 1=0
```
    应改成这样：
    ```
    create table #t(…)
    ```

27. 如果使用到了临时表，在存储过程的最后务必将所有的临时表显式删除，先 `truncate table` ，然后 `drop table` ，这样可以避免系统表的较长时间锁定。

28. 避免使用游标，因为游标的效率较差，如果游标操作的数据超过1万行，就应该考虑改写。

29. 使用基于游标的方法或临时表方法之前，应先寻找基于集的解决方案来解决问题，基于集的方法通常更有效。

30. 与临时表一样，游标并不是不可使用。对小型数据集使用 `FAST_FORWARD` 游标通常要优于其他逐行处理方法，尤其是在必须引用几个表才能获得所需的数据时。在结果集中包括“合计”的例程通常要比使用游标执行的速度快。如果开发时 间允许，基于游标的方法和基于集的方法都可以尝试一下，看哪一种方法的效果更好。

31. 在所有的存储过程和触发器的开始处设置 `SET NOCOUNT ON` ，在结束时设置 `SET NOCOUNT OFF` 。无需在执行存储过程和触发器的每个语句后向客户端发送 `DONE_IN_PROC` 消息。

32. 避免大事务操作，提高系统并发能力。
尽管事务是维护数据库完整性的一个非常好的方法,但却因为它的独占性,有时会影响数据库的性能,尤其是在很多的应用系统中.由于事务执行的过程中,数据库将会被锁定,因此其他的用户请求只能暂时等待直到该事务结算.如果一个数据库系统只有少数几个用户来使用,事务造成的影响不会成为一个太大问题;但假设有成千上万的用户同时访问一个数据库系统,就会产生比较严重的响应延迟.有些情况下我们可以通过锁定表的方法来获得更好的性能.如:
```
LOCK TABLE inventory write
Select quanity from inventory whereitem=’book’;
…
Update inventory set quantity=11 whereitem=’book’;
UNLOCK TABLES;
```
    这里，我们用一个`select`语句取出初始数据，通过一些计算，用`update`语句将新值更新到列表中。包含有`write`关键字的`LOCK TABLE`语句可以保证在`UNLOCK TABLES`命令被执行之前，不会有其他的访问来对`inventory`进行插入，更新或者删除的操作。

33. 避免向客户端返回大数据量，若数据量过大，应该考虑相应需求是否合理。
实际案例分析：拆分大的 `DELETE` 或`INSERT `语句，批量提交SQL语句。因为这两个操作是会锁表的，表一锁住了，别的操作都进不来了。
Apache 会有很多的子进程或线程。所以，其工作起来相当有效率，而我们的服务器也不希望有太多的子进程，线程和数据库链接，这是极大的占服务器资源的事情，尤其是内存。
如果你把你的表锁上一段时间，比如30秒钟，那么对于一个有很高访问量的站点来说，这30秒所积累的访问进程/线程，数据库链接，打开的文件数，可能不仅仅会让你的WEB服务崩溃，还可能会让你的整台服务器马上挂了。
所以，如果你有一个大的处理，你一定把其拆分，使用 `LIMIT oracle(rownum),sqlserver(top)`条件是一个好的方法。下面是一个mysql示例：
```
while(1){

 //每次只做1000条

 mysql_query(“delete from logs where log_date <= ’2012-11-01’ limit 1000”);

 if(mysql_affected_rows() == 0){
 //删除完成，退出！
 break；
}

//每次暂停一段时间，释放表让其他进程/线程访问。usleep(50000)

}
```

34. 利用`limit 1`取得唯一行，查询一张表时，查询一条独特的记录。你可以使用limit 1.来终止数据库引擎继续扫描整个表或者索引,如：
```
select * from A  where name like ‘%xxx’ limit 1;
```
    这样只要查询符合`like ‘%xxx’`的记录，那么引擎就不会继续扫描表或者索引了。

35. 尽量不要使用BY RAND()命令，如果需要随机显示你的结果，有很多更好的途径实现。而这个函数可能会为表中每一个独立的行执行BY RAND()命令—这个会消耗处理器的处理能力，如：
```
SELECT id FROM table ORDER BY RAND() LIMIT n;
//优化rand()
SELECT id FROM table t1 JOIN (SELECT RAND() * (SELECT MAX(id) FROM table) AS nid) t2 ON t1.id > t2.nid LIMIT n;
//完全随机
SELECT id FROM table t1 JOIN (SELECT round(RAND() * (SELECT MAX(id) FROM table)) AS nid FROM table LIMIT n) t2 ON t1.id = t2.nid;
```

36. 尽量少排序，排序操作会消耗较多的CPU资源，所以减少排序可以在缓存命中率高等

37. limit千万级分页的时候优化。在我们平时用limit,倘若到达千万级，如：
```
Select * from A order by id limit 10000000,10;
```
    可以这样写：
    ```
    Select * from A where id between 10000000 and 10000010;
    ```

38. 带有`DISTINCT`,`UNION`,`MINUS`,`INTERSECT`,`ORDER BY`的SQL语句会启动SQL引擎执行耗费资源的排序(SORT)功能. `DISTINCT`需要一次排序操作, 而其他的至少需要执行两次排序. 通常, 带有`UNION`, `MINUS` , `INTERSECT`的SQL语句都可以用其他方式重写. 如果你的数据库的SORT_AREA_SIZE调配得好, 使用`UNION` , `MINUS`, `INTERSECT`也是可以考虑的, 毕竟它们的可读性很强。

39. 用union all 代替union，`union`和`union all`的差异主要是`union`会将结果集合并后再进行唯一性过滤操作，就涉及到排序，增大的cpu运算和资源消耗及延迟。所以当我们可以确认不可能出现重复结果集或者不在乎重复结果集的时候，尽量使用`union all`。

40. 对多表的关联可能会有性能上的问题，我们可以对多表建立视图，这样操作简单话，增加数据安全性，通过视图，用户只能查询和修改指定的数据。且提高表的逻辑独立性，视图可以屏蔽原有表结构变化带来的影响。

41. Inner join和`left join`，`right join`，`full join`，子查询
`inner join`内连接也叫等值连接，`left/right join`是外连接。
`inner join`性能比较快，因为`inner join`是等值连接，或许返回的行数比较少。但是我们要记得有些语句隐形的用到了等值连接，子查询的性能又比外连接性能慢，尽量用外连接来替换子查询。

42. 使用`DECODE`函数来减少处理时间，`DECODE`函数可以避免重复扫描相同记录或重复连接相同的表。

43. 避免在`SELECT`子句中使用`DISTINCT`。一般可以考虑用EXIST替换， `EXISTS` 使查询更为迅速，因为RDBMS核心模块将在子查询的条件一旦满足后，立刻返回结果。

44. 用`>=`替代`>`:
```
SELECT * FROM EMP WHERE DEPTNO >=4
SELECT * FROM EMP WHERE DEPTNO >3
```
    前者DBMS将直接跳到第一个DEPT等于4的记录而后者将首先定位到DEPTNO=3的记录并且向前扫描到第一个DEPT大于3的记 录。

45. 优化GROUP BY:可以通过将不需要的记录在`GROUP BY` 之前过滤掉.下面两个查询返回相同结果但第二个明显就快了许多.
```
低效:
SELECT JOB , AVG(SAL)
FROM EMP
GROUP by JOB
HAVING JOB = ‘PRESIDENT'
OR JOB = ‘MANAGER'
高效:
SELECT JOB , AVG(SAL)
FROM EMP
WHERE JOB = ‘PRESIDENT'
OR JOB = ‘MANAGER'
GROUP by JOB
```
46．在使用ON 和 WHERE 的时候，记得它们的顺序，如：
```
SELECT A.id,A.name,B.id,B.name FROM A LEFT JOIN B ON A.id =B.id WHERE B.NAME=’XXX’
```
先on条件筛选表，然后两表再做`join`，`where`在`join`结果后再次筛选。
`ON`后面的条件只能过滤出B表的条数。
- ON后面的筛选条件主要是针对的是关联表，而对于主表刷选条件不适用。
- 对于主表的筛选条件应放在`where`后面。
- 对于关联表我们要区分对待。如果是要条件查询后才连接应该把查询件放置于`ON`后，如果是想再连接完毕后才筛选就应把条件放置于where后面。
- 对于关联表我们其实可以先做子查询再做join。

47．使用JOIN时候，应该用小的结果驱动大的结果（`left join` 左边表结果尽量小，如果有条件应该放到左边先处理，`right join`相反），尽量把牵涉到多表联合的查询拆分多个query(多个表查询效率低，容易锁表和阻塞)。如：
```
Select * from A left join B on a.id=B.ref_id where B.ref_id>10
```
改为：
```
select * from (select * from A wehre id >10) T1 left join B onT1.id=B.ref_id
```

