详细了解MySql索引相关(日常用的多，很重要)  

InnoDB引擎支持两种索引,一种是B+树索引，另一个是哈希索引。  

InnoDB存储引擎支持的哈希索引是自适应的，INNoDb存储引擎会根据表的使用情况自动为表生成哈希索引
，不能人为干预是否在一张表中生成哈希索引。  

#### mysql默认引擎为innodb，innodb默认使用行锁，而行锁是基于索引的，因此要想加上行锁，在加锁时必须命中索引，否则将使用表锁

### 1. Where子句过滤指定的是行而不是分组，事实上，Where没有分组的概念。那么不能用where用什么呢？
答案是Having子句。目前为止所学过的所有类型的where子句都可以用having来替代
having和where的区别：where在数据分组前对行进行过滤，having在数据分组后进行过滤

### 2. Union会从查询结果集中自动去除重复行，这是union的默认行为，如果需要可以用union all
来返回所有匹配的行而不进行去重。
union与where：union all为union的一种形式，如果确实需要每个条件的匹配行全部出现(包括重复行)
，则必须使用union all而不是where
在用union组合查询时，只能使用一条order by子句，它必须出现在最后一条select语句之后。
对于结果集，不存在用一种方式排序一部分，然后用另一部分排序另一部分的情况，
因此不允许使用多条order by子句。 因为union只是将所有结果集合成一个结果集，自然而然无论
有多少个union连接，都只能有一个order by子句来排序
利用union，可以把多条查询的结果作为一个结果集返回，这个结果集可以包含重复也可以不包含重复

### 3. Select查询结果按指定顺序排序:
```
SELECT
	*
FROM
	uc_user_identifier
WHERE
	uc_user_id = 4
ORDER BY
	FIELD(
		identifier_type,
		"EMAIL",
		"MOBILE"
	)
```
  	
### 4. Mysql 5.6 升级到 5.7 出现 groupBy 的问题
```
select @@GLOBAL.sql_mode;
select @@SESSION.sql_mode;
```
将结果中 ONLY_FULL_GROUP_BY去掉并保存即可解决。

### 5. 隔离级别: 在事务中为保证并发数据读写的正确性而提出的定义
隔离级别是针对事务来说的，mysql中只有innoDb引擎支持事务，而innoDB的隔离级别是基于 MVCC（Multi-Versioning Concurrency Control）和锁的复合实现
>1. Read uncommitted(读未提交)，就是一个事务能够看到其他事务尚未提交的修改，这是最低的隔离水平，允许脏读出现。

>2. Read committed(读已提交),
事务能够看到的数据都是其他事务已经提交的修改，也就是保证不会看到任何中间性状态，当然脏读也不会出现。读已提交仍然是比较低级别的隔离，并不保证再次读取时能够获取同样的数据，也就是允许其他事务并发修改数据，允许不可重复读和幻象读（Phantom Read）出现 

>3. Repeatable reads(可重复读),保证同一个事务中多次读取的数据是一致的，这是 MySQL InnoDB 引擎的默认隔离级别，但是和一些其他数据库实现不同的是，可以简单认为 MySQL 在可重复读级别不会出现幻象读  

>4. Serializable(串行化),并发事务之间是串行化的，通常意味着读取需要获取共享读锁，更新需要获取排他写锁，如果 SQL 使用 WHERE 语句，还会获取区间锁（MySQL 以 GAP 
锁形式实现，可重复读级别中默认也会使用），这是最高的隔离级别  

*注意*:
(1)脏读:
(2)幻读:

随着隔离级别从低到高，竞争性（Contention）逐渐增强，随之而来的代价是性能和扩展性的下降

至于悲观锁和乐观锁，也并不是 MySQL 或者数据库中独有的概念，而是并发编程的基本概念。主要区别在于，操作共享数据时，“悲观锁”即认为数据出现冲突的可能性更大，而“乐观锁”则是认为大部分情况不会出现冲突，进而决定是否采取排他性措施。

反映到 MySQL 数据库应用开发中，悲观锁一般就是利用类似 SELECT … FOR UPDATE 这样的语句，对数据加锁，避免其他事务意外修改数据。乐观锁则与 Java 并发包中的 AtomicFieldUpdater 类似，也是利用 CAS 机制，并不会对数据加锁，而是通过对比数据的时间戳或者版本号，来实现乐观锁需要的版本判断。我认为前面提到的 MVCC，其本质就可以看作是种乐观锁机制，而排他性的读写锁、双阶段锁等则是悲观锁的实现。

### 6. innodb_lock_wait_timeout 和 lock_wait_timeout 这两个参数的区别？
* 分别是 InnoDB等行锁，和 Server层等表锁

### 7. binlog有几种格式？分别是哪几种？
* binlog 有两种格式，一种是 statement，一种是 row。第三种格式，叫作 mixed，其实它就是前两种格式的混合。
* 当 binlog_format=statement 时，binlog 里面记录的就是 SQL 语句的原文
* 当 binlog_format=‘row’时，记录binlog是以event为单位的。row 格式的缺点是，很占空间。比如你用一个 delete 语句删掉 10 万行数据，
用 statement 的话就是一个 SQL 语句被记录到 binlog 中，占用几十个字节的空间。但如果用 row 格式的 binlog，
就要把这 10 万条记录都写到 binlog 中。这样做，不仅会占用更大的空间，同时写 binlog 也要耗费 IO 资源，
影响执行速度。
* 当 binlog_format=‘mixed’时，通常情况下是记录statement格式的binlog，但是如果有些sql语句mysql认为会发生歧义，则会补充记录row格式的binlog，

场景：
当执行如下sql时，三种格式的binlog会发生如下:
```
delete from t where a >= 4 and t_modified <= '2018-11-10' limit 1;
```
statement格式记录这个sql，会产生一个warning，原因是语句中包含limit子句，这个命令可能是unsafe的。  
什么情况下会发生unsafe事件呢？  
如果此sql走的是 a 的索引，那么会根据索引 a 找到第一个满足条件的行，所以删除的是a=4这条记录,
如果使用的是 t_modified 索引，那么删除的就是 t_modified='2018-11-09’也就是 a=5 这一行。
所以当主库和备库执行sql选择的索引不同就会发生unsafe  

### 8.为什么越来越多的场景要求把 MySQL 的 binlog 格式设置成 row？
因为设置为 row 格式对于恢复数据十分方便。分别从delete,insert，update语句说恢复方式:
* delete: 即使执行的是delete语句，row 格式的 binlog 也会把被删掉的行的整行信息保存起来。
所以，如果执行 delete 语句后，发现删错了数据，可以直接把 binlog 中记录的 delete 语句转成 insert，
把被删除的数据再insert回去就可以恢复了。
* insert: 如果误执行了insert语句时，binlog会记录所有字段信息，这些信息可以精确定位到刚刚插入的那行数据。这时可以直接把insert语句转为delete语句，
删掉就可以了
* update: 如果误执行了 update 语句，binlog 里面会记录修改前 整行的数据 和 修改后的整行数据，
只需要把这个 event 前后的两行信息对调一下，再去数据库里面执行第一条，就可以恢复到update之前的状态了  

### 9. MySQL是如何解决主主同步的循环复制问题的？
* 主主同步，指的是主A和主B是互为主备关系，是两条线相连的。
循环复制，指的是A把B当作从机，

