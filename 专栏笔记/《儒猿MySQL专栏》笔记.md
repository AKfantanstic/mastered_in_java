生产经验:

* Java应用系统部署在4核8G机器上，每秒可以抗500左右并发量。
* 一般8核16G的机器部署MySQL数据库，每秒可以抗1、2K并发
* 对于16核32G的机器部署MySQL数据库，每秒可以抗2、3k并发，3-4k并发



undo log、redo log是innodb存储引擎层的日志，binlog是mysql的server层日志

redo log是一种物理性质的重做日志，记录的是基于磁盘上存储的数据页所做的修改，例如对磁盘中存储的某个数据页中的什么记录，做了什么修改

binlog叫做归档日志，记录的是逻辑日志，都是sql

## "update user set name = 'XXX' where id = 10" 的更新过程？

进入事务的最终提交阶段，会把本次更新对应的binlog文件名和本次更新内容记在binlog文件中的位置，都写入到redo log中，同时在redo log文件中写入一个commit标记，整个事务完成。commit标记用于保持redo log和binlog的一致性，假如刚刚将redolog写入磁盘文件，mysql宕机了，此时机器恢复后，由于redo log中没有commit标记，所以mysql判定此次事务不成功。假如将binlog写入磁盘了，然后mysql宕机了，此时同样会因为redo log中没有commit标记，认定此次事务不成功，必须是在redo log中写入commit标记后，才算此时事务提交成功，这时redolog 中有本次更新对应的日志，binlog中也有本次更新对应的日志，这时redo log和binlog是完全一致的。最后由后台IO线程将脏页刷回磁盘。

## redo log buffer对应的redo log的3种刷盘策略

通过mysql配置中的innodb_flush_log_at_trx_commit参数来配置刷盘策略:

1. 参数为0: 提交事务时不会将redo log buffer里的数据写入磁盘。**此时宕机数据丢失**
2. 参数为1：提交事务之前必须保证将redo log buffer里的数据写入磁盘。
3. 参数为2:  提交事务之前仅将redo log buffer中数据写入磁盘文件对应的osCache中，后续由操作系统决定什么时候写入磁盘文件。**宕机后数据可能丢失**

通常必须设置为1，也就是说要提交事务时redo log必须刷入磁盘文件里，因为对于数据库这样的严格系统，必须要保证事务提交后，数据绝不会丢失。

## binlog的刷盘策略？
用sync_binlog参数来控制binlog的刷盘策略。
* 默认值是0：把binlog写入osCache而不是直接写入磁盘文件中。此时宕机则os cache中binlog会丢失，可能会造成事务提交成功但binlog丢失
* 参数为1: 强制在事务提交时将binlog写入磁盘文件里。这样即使提交事务后机器宕机，binlog也不会丢。

## 为什么要在redolog中写入commit标记?

用来保证redolog和binlog的强一致性。写入redo log，写入binlog，把binlog文件名和本次事务记录在binlog的位置写入redolog，最后在redo log中写入commit标记，其中任何一个中间步骤出错，事务都是提交失败的，只有写入commit标记了，才算事务提交成功，这就是mysql的innoDb存储引擎定的规则

# 数据库压测

## 需要关注的相关性能指标:

IO相关:
(1)IOPS:指的是机器随机IO并发处理能力，比如200 IOPS 意思就是说每秒可以执行200个随机IO读写请求。当在内存bufferPool中写入脏数据后，需要后台IO线程在机器空闲时刷回到磁盘，这是一个随机IO的过程。如果IOPS过低，会导致内存里脏数据刷回磁盘的效率太低
(2)吞吐量:指的是机器磁盘每秒可以读写多少字节
当执行sql提交事务时需要将大量redo log等日志写入磁盘。写入redolog一般是一行一行顺序写入，不会进行随机读写，一般普通磁盘顺序写吞吐量可达到每秒200MB
，对于承载高并发来说，磁盘吞吐量通常不是瓶颈
(3)latency:指的是向磁盘写入一条数据的延迟。当执行sql和提交事务时，需要将redo log顺序写到磁盘，如果写入延迟过高会影响数据库的sql执行性能。写入延迟越低，执行sql的事务的速度就越快，数据库性能就越高
(4)CPU负载:压测中如果CPU负载特别高，就说明已经到达瓶颈，不能继续压测了
(5)网络负载:关注每秒钟网卡会输入多少MB数据，会输出多少MB数据，当到达网络带宽最大值时说明已经出现瓶颈了，就不能再继续压测了
(6)内存负载:如果内存占用过高，也说明不能继续压测了

## 数据库压测工具 sysbench 使用方法
```
使用如下命令设置yum repo仓库，然后使用yum来安装sysbench
curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh|sudo bash
sudo yum -y install sysbench
sysbench --version  
看到sysbench版本号说明安装成功

然后在数据库建好测试库名字叫test_db,然后创建测试账号，然后基于sysbench构建20个测试表，每个表100万条数据，使用10个并发线程对数据库发起访问，连续访问300秒，也就是压测5分钟。
先基于sysbench构造测试表和测试数据:
sysbench --db-driver=mysql --time=300 --threads=10 --report-interval=1 --mysql-host=192.168.11.113 --mysql-port=3306 --mysql-user=root --mysql-password=123456 --mysql-db=test_db --tables=20 --table_size=1000000 oltp_read_write --db-ps-mode=disable prepare

(1)--db-driver=mysql: 基于mysql驱动去连接mysql数据库，如果是oracle、sqlServer可以更换
(2)--time: 连续压测时间，单位秒
(3)--threads=10: 10个线程并发访问
(4)--report-interval=1: 每隔1秒输出压测情况
(5)--mysql-host=127.0.0.1 --mysql-port=3306 --mysql-user=test_user --mysql-password=test_user:指定mysql连接相关信息
(6)--mysql-db=test_db --tables=20 --table_size=1000000: 指定压测数据库，构造20个测试表，每个表100万条测试数据
(7)oltp_read_write: 执行oltp数据库的读写测试
(8)--db-ps-mode=disable: 禁用ps模式
(9)prepare: 按照上面的命令去构造测试数据
   run:运行压测
   cleanup:清理测试数据
   
测试数据库综合读写TPS，使用oltp_read_write模式:
sysbench --db-driver=mysql --time=300 --threads=20 --report-interval=1 --mysql-host=192.168.11.113 --mysql-port=3306 --mysql-user=root --mysql-password=123456 --mysql-db=test_db --tables=20 --table_size=1000000 oltp_read_write --db-ps-mode=disable run

测试数据库的只读性能，使用oltp_read_only模式(将oltp_read_write改为oltp_read_only)

测试数据库的删除性能，使用oltp_delete模式

测试数据库的更新索引字段性能，使用oltp_update_index模式

测试数据库的更新非索引字段的性能，使用oltp_update_non_index模式

测试数据库的写入性能，使用oltp_write_only模式

[ 116s ] thds: 20 tps: 340.03 qps: 6809.60 (r/w/o: 4760.42/1369.12/680.06) lat (ms,95%): 125.52 err/s: 0.00 reconn/s: 0.00
每秒压测报告解读:
(1)thds:20,压测线程数
(2)tps:340.03，每秒执行340.03个事务
(3)qps:6809.60，每秒执行6809.60个请求
(4)r/w/o:760.42/1369.12/680.06 : 每秒6809.60个请求中，有760.42个读请求，1369.12个写请求，680.06个其他请求。也就是对QPS的拆解
(5)lat(ms,95%):125.52 :95%请求的延迟在125.52毫秒以下
(6)err/s:0.00 reconn/s:0.00 :每秒有0个请求失败，发生了0次网络重连

总压测报告:
SQL statistics:
    queries performed:
        read(压测期间执行的总读请求数): 1275694
        write(总写请求数):            364484
        other(总其他请求数):          182242
        total(总请求数):              1822420
    transactions:                        91121  (303.60 per sec.)
    queries:                             1822420 (6072.00 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          300.1328s
    total number of events(总执行事务数):  91121

Latency (ms):
         min(请求最小延迟):  12.34
         avg(请求平均延迟):  65.85
         max(请求最大延迟):  1494.97
         95th percentile(95%请求延迟时间): 123.28
         sum:  6000298.15

Threads fairness:
    events (avg/stddev):           4556.0500/20.80
    execution time (avg/stddev):   300.0149/0.03
```

### SQL标准中对事务的4个隔离级别是如何规定的？

针对数据库的多事务并发带来的问题，sql标准规定了事务的4种隔离级别来解决这些问题。如果事务全部串行化，毫无并发可言，影响效率，所以sql标准针对事务的隔离级别本质上是为了去按不同粒度划分多事务并发带来的影响。

* 第一个读未提交隔离级别。不允许发生脏写，也就是说不允许两个事务在没提交的情况下去更新同一行数据。允许发生脏读、不可重复读、幻读
* 第二个是读已提交级别。不允许发生脏写和脏读，由于其他事务未提交的记录是无法被另一个事务读到的，所以就避免了脏读。同时允许发生不可重复读和幻读
* 第三个是可重复读级别。不允许发生脏写、脏读、不可重复读。由于一个事务的多次查询即使数据被其他事务修改了，他也是读不到的，所以查询结果始终没有变化，因此避免了脏写、脏读、不可重复读
* 第四个是串行化级别。不允许事务并发执行，只能一个一个排队执行，所以能避免一切并发带来的问题

### MySQL是如何支持SQL标准中的4种隔离级别的？

mysql支持sql标准中的4种隔离级别，除此之外，mysql默认事务隔离级别为可重复读，sql标准下这个隔离级别是可以发生幻读的，而mysql对可重复读隔离级别的实现能做到避免幻读

```bash
# 修改mysql事务隔离级别：level值可以是REPEATEABLE READ，READ COMMITTED，READ UNCOMMITTED，SERIALIZABLE
SET [GLOBALSESSION] TRANSACTION ISOLATION LEVEL level
```

### 理解MVCC机制的前奏，undo log版本链是什么？

mysql的默认隔离级别可重复读能做到多个事务并发执行之间互不影响，依靠的就是经典的MVCC多版本并发控制机制来做到的。而mvcc机制是由undo log版本链和readView来实现的。

undo log版本链:表中的每条数据都有两个隐藏字段，一个是trx_id，表示最近一次更新这条数据的事务id；一个是roll_pointer，记录的是这条数据在被trx_id这个事务更新之前的undo log指针。

因为mysql数据库已经根据sql标准去在任何级别下避免了脏写，所以多个事务是串行修改一行数据的，并且修改时会更新隐藏字段trx_id和roll_pointer

#### 基于undo log版本链是如何实现readView机制的？

开启事务时会生成一个readView读视图数据结构，一个读视图由4个关键参数构成:

* m_ids: 此时有哪些事务正在执行还没有提交
* min_trx_id: m_ids里的最小值
* max_trx_id: mysql下一个要生成的事务id，也就是最大事务id
* creator_trx_id: 当前事务的id

通过记录undo log多版本链条，再加上事务开启时生成的一个readView，然后事务中的查询就根据readView进行判断，去选择读取哪个版本的数据。这套机制能保证当前事务只能读到事务开启前已经提交的事务更新的值，还有本事务更新的值。 当本事务开启后，其他事务更新了值无论是否已提交，本事务都不会读到修改的值。 通过这套机制实现了多个事务并发执行时的数据隔离

#### 读已提交级别是如何基于readView机制实现的？

读已提交隔离级别的意思就是，在本事务运行期间，只要其他事务修改后提交了，那本事务就可以读取其他事务所提交的数据。所以这样会发生不可重复读、幻读问题。

所以对于读已提交级别，是每次发起新查询都会重新生成一个readView

#### 可重复读级别是如何基于readView机制实现的？

事务开启后，生成一个readView，然后在整个事务查询过程中都使用这一个readView去处理数据可见性

## 锁

#### 多个事务并发更新同一行数据，数据库是怎么避免脏写的？

简单说，脏写是依靠锁机制把并发更新做串行化处理，避免并发更新。当事务A要对一行数据更新时，先检查下是否有其他事务对这行数据加了锁，如果没有则会创建一个锁，锁里面包含本事务的trx_id和等待状态false(已经获取锁)，然后把这把锁和这行数据做关联(在内存中)。这是事务B要修改这行记录检查是否有锁，发现这行数据已被加锁，事务B也生成一个锁数据结构，等待状态为true。当A更新完成后，会把锁释放然后去找是否有其他事务对这行数据加锁，发现了事务B加的锁，然后把事务B的锁的等待状态改为false，然后唤醒B继续执行。

#### MySQL中的共享锁和独占锁

多个事务并发更新同一行数据时加的是行级别独占锁。

mysql也支持共享锁，语法为:select * from table lock in share mode

mysql也支持独占锁，语法为:select * from table for update

* 共享锁和共享锁不互斥，可以同时加。
* 共享锁和独占锁互斥，不能同时加。
* 独占锁和独占锁互斥，不能同时加

一般开发业务系统时， 很少在数据库去加共享锁、行锁，而是用基于zookeeper/redis的分布式锁来控制业务的锁逻辑

#### 数据库中哪些操作会导致在表级别加锁？









#### 查询一条数据的过程？

* 根据主键查询: 每个数据页里都有一个页目录，存放这个页里每个主键和所在槽位的映射关系。
  每张表都有一个主键索引，也叫主键目录，是由数据页号和最小主键值组成的。如果是根据主键查询一条数据，则只需要在主键目录里通过二分查找来找到对应的数据页，就可以在数据页中找到要的数据了
* 根据非主键且没有索引的字段查询: 由于无法利用页目录来进行二分查找，所以无论怎么查找数据都是一个全表扫描的过程，只能。最坏情况下需要把所有数据页里的每条数据都得遍历一遍才能要找到想要的那条数据，这就是全表扫描

#### 什么情况下会发生页分裂？

在不停往表中插入数据时，会增加一个一个的数据页，如果主键不是自增的，就会有一个数据行的挪动过程，核心目的是为了保证下一个数据页里的主键值都比上一个数据页的主键值大，这个调整叫做页分裂



















#### 多表关联查询是如何执行的？

多表关联的执行原理:

from后面直接跟两个表名，就是针对两个表进行联表查询了，如果没有其他任何限制，就会得到一个笛卡尔积。比如t1表有10条数据，t2表有5条数据，当select * from t1，t2时，t1表里的每一条数据都会跟t2 表里的数据连接起来再返回，所以是10 * 5=50，会查出50条数据，这就是笛卡尔积。

```mysql
SELECT
	*
FROM
	t1,
	t2
WHERE
	t1.x1 = "A"
AND t1.x2 = t2.x2
AND t2.x3 = "B"
```

以上sql中 t1.x1="A",是针对t1表的数据筛选条件，本质是从t1表里筛选出一些符合条件的数据出来再跟t2表做关联，而不是多表关联条件。t2.x3="B"也不是关联条件，也是针对表t2的筛选条件。真正的关联条件是t1.x2=t2.x2，意思是说在表t1里的每条数据跟表t2做关联时，要求t1表中每条数据的x2值和表t2的x2字段值相等。比如t1表中有1条数据的x2值为"A",t2表里有两条数据的x2字段值为"A",此时就会把t1表里的1条数据跟t2表中的两条数据分别关联起来，最终会返回两条关联后的数据。

多表关联查询时，可能是先从一个表里查出一波数据，这个表叫做"驱动表"，再根据这波数据去另外一个表里再查询一波数据然后进行关联，另一个表叫做"被驱动表"

#### 多表关联的分类

多表关联，主要就是内连接和外连接。

内连接:inner join,只有两个表的数据能完全关联上，才能作为返回结果，并且内连接的连接条件是可以放在where语句里的

外连接:outer join,分为左外连接和右外连接。外连接的连接条件必须放在on子句中，不能放在where子句中

* 左外连接的意思是，在左侧表的里某条数据如果在右侧表中关联不到任何数据，也要把左侧表这条数据返回。
* 右外连接的意思是，在右侧表里的某条数据如果在左侧表中关联不到任何数据，也要把右侧表的数据返回

假设有一个员工表employee，一个产品销售业绩表product_sale，如下:

| 员工表 employee  |           |                 |
| ---------------- | --------- | --------------- |
| employee_id 主键 | name 姓名 | department 部门 |

| 销售业绩表product_sale |                    |                      |                      |
| ---------------------- | ------------------ | -------------------- | -------------------- |
| product_sale_id 主键   | employee_id 员工id | product_name产品名称 | saled_amount销售业绩 |

1.如果想看每个员工对每个产品的销售业绩:

```mysql
SELECT
	em.name,
	em.department,
	ps.product_name,
	ps.sale_amount
FROM
	employee em,
	product_sale ps
WHERE
	em.id = ps.employee_id
```

查询过程: 从员工表全表扫描，然后根据每个员工id去销售业绩表中找employee_id和员工id相等的数据进行关联。一个员工id可能在销售业绩表中找到多条数据，需要让每个员工和在销售业绩表中找到的数据都关联起来，查询结果如下:

| name | department | product_name | sale_amount |
| ---- | ---------- | ------------ | ----------- |
| 张三 | 大客户部   | 产品A        | 30万        |
| 张三 | 大客户部   | 产品B        | 50万        |
| 张三 | 大客户部   | 产品C        | 80万        |
| 李四 | 零售部     | 产品A        | 10万        |
| 李四 | 零售部     | 产品B        | 20万        |

新问题:如果员工表中有一个人是新员工，入职到现在还没有开单，此时需要把这个员工的数据也一起跟着查询出来，只不过在销售业绩里用null值来表示没有任何业绩。这样的需求用内连接是无法实现的，因为内连接必须要两个表能关联上才能查询出结果，所以此时必须用外连接实现，而且是用左外连接:

```mysql
SELECT
	em. NAME,
	em.department,
	ps.product_name,
	ps.sale_amount
FROM
	employee em
LEFT OUTER JOIN product_sale ps 
ON 
	em.id = ps.employee_id
```

返回结果:

| name | department | product_name | sale_amount |
| ---- | ---------- | ------------ | ----------- |
| 张三 | 大客户部   | 产品A        | 30万        |
| 张三 | 大客户部   | 产品B        | 50万        |
| 张三 | 大客户部   | 产品C        | 80万        |
| 李四 | 零售部     | 产品A        | 10万        |
| 李四 | 零售部     | 产品B        | 20万        |
| 王五 | 零售部     | NULL         | NULL        |

#### 多表关联的实现原理？

本质就是先查一个驱动表，然后根据连接条件去被驱动表里循环查询，然后关联起来！

两表关联的执行原理:嵌套循环关联。也就是说，如果有两个表要一起关联查询，会先在一个驱动表里根据它的where条件筛选出一波数据，假设10条，然后对这10条数据走一个for循环，用每条数据都到被驱动表里根据on连接条件和被驱动表的where条件筛选出数据，找出来的数据就进行关联。这样需要循环去被驱动表里查询10次。

三表关联查询的原理:先从表1查出10条数据，然后去表2里查10次，如果每次在表2种都查出来3条数据，然后关联起来，就会得到一个30条数据的结果集。然后再用这批数据去表3里继续查询30次

#### 多表关联查询速度慢的原因？

从多表关联查询的过程来分析：多表关联查询时，首先从驱动表中用where筛选出一部分数据，然后再对查询结果中每条数据都循环一次去被驱动表里查询数据。这个过程中:

* 第一个影响性能点是如果驱动表索引没建好，那么驱动表根据where条件进行筛选时就会走全表扫描，会影响性能。
* 第二个影响性能点是如果被驱动表索引没建好，在对查询结果进行循环查询并关联时就会走全表扫描，会影响性能

总之，多表关联查询速度慢的答案就是驱动表和被驱动表的索引没有建好。如果驱动表和被驱动表索引建好，多表查询的性能就会很高

#### explain命令得到sql执行计划

用explain + sql，就可以拿到这个sql的执行计划，也就是mysql是如何访问这个表的

| id   | select_type | table | partitions | type | possible_key | key  | key_len | ref  | rows | filtered | extra |
| ---- | ----------- | ----- | ---------- | ---- | ------------ | ---- | ------- | ---- | ---- | -------- | ----- |
|      |             |       |            |      |              |      |         |      |      |          |       |

id:一个复杂sql里可能会有很多个select，也可能会包含多条执行计划，每个执行计划都有一个唯一id

select_type：查询类型

type：const，ref，range，index，all，

possible_keys：type确定了访问方式后，可供选择的索引

ref:

rows:大概会读取多少条数据

extra:额外信息，不太重要

#### 使用MySQL为什么要搭建主从复制架构？(也就是说，主从复制架构有什么用处？)

主从复制的两个作用:

* 实现高可用: 单机部署后如果出现单点故障会导致数据库不可用，进而导致整个 Java 业务系统不可用。所以真正的生产架构需要实现高可用，实现高可用主要靠主从复制架构+高可用工具。

* 做读写分离架构: 主节点负责全部数据的写入，从节点负责全部数据的查询。

  读写分离架构是怎么提高性能的？假设一台 8 核 16 GB 的 MySQL单机服务器每秒最多能抗 4000 读写请求。而现在java业务系统负载为每秒2500写请求+2500读请求，显然一台机器扛不住。而使用了主从复制来做读写分离后，使用两台机器一主一从，让2500个写请求落到主库，2500个读请求落到从库，这样就解决了性能问题。并且一般 Java 系统业务场景都是读多写少，mysql的主从复制支持一主多从，当读请求压力继续增加时，可继续横向加机器做从节点。读写分离一般使用mycat或者sharding-sphere之类的中间件来实现。

一般生产环境中 MySQL 高可用架构是必做的。但是读写分离架构并不是必做的，等业务并发量到达一定程度再去做

#### 主从复制还有哪些其他应用场景？

* 可以单独挂载一个从库专门用来执行报表类的查询sql，因为这种报表类的sql一般都上百行，运行要好几秒。所以单独用一个从库，从而不影响主库的运行。

#### MySQL主从复制的原理？

MySQL 在执行增删改时会记录 binlog。当我们在从库上配置好主库信息后，从库的一个io线程会主动跟主库建立一个tcp连接并请求主库将binlog发送过来，这时主库上有一个io dump线程负责通过这个tcp连接把binlog发给从库的io线程，io线程把收到的binlog写入自己本地的relay中继日志文件中，这时从库上的sql线程会读取relay日志并进行日志重做来把所有在主库执行过的增删改操作在从库上做一遍来还原数据。

#### 那如何为MySQL搭建一套主从架构呢？

首先在两台机器上安装好 MySQL，并检查确保主库和从库的server-id是不同的，然后打开主库的binlog功能。并在主库上执行如下配置:

```bash
# 在主库上创建一个用于主从复制的账号
create user `backup_user`@`192.168.3.%` identified by `backup_123`;
grant replication slave on *.* to `backup_user`@`192.168.31.%`;
flush privileges;
```

如果主库已经存在许多数据，则需要先将系统停机保证不再写入数据，然后使用mysqldump工具做一个全量备份:

```bash
# --master-data=2意思就是在备份sql中记录一下此时主库的binlog文件和postion号，为主从复制做准备
/usr/local/mysql/bin/mysqldump --single-transaction -uroot -proot --master-data=2 -A > backup.sql
```

然后把backup.sql拷贝到从库上去执行完。然后打开backup.sql，找到

```bash
master_log_file=`mysql-bin.000015`,master_log_pos=1689
```

然后根据backup.sql中找到的内容在从库mysql命令行中执行命令来指定主库进行复制:

```bash
change master to master_host=`192.168.31.229`,
master_user = `backup_user`,master_password=`backup_123`,
master_log_file=`mysql-bin.000015`,master_log_pos=1689;
```

然后执行start slave命令开始主从复制。最后用show slave status查看一下主从复制状态，如果看到Slave_IO_Running和Slave_SQL_Running都是yes表示本次配置成功，主从复制已经开始了。这是一个异步复制，所以会出现短暂的主从不一致。

异步复制时，主库把日志写入binlog后直接提交事务返回了，并没有去保证从库一定接收到了这条日志，如果此时主库宕机，即使进行主从切换，也会造成数据丢失，因为从库并没有这条记录。所以MySQL用半同步复制机制来解决这种场景带来的问题: 就是说当主库写入数据并记录binlog后，要确保binlog复制到从库了，才能告诉请求客户端本次事务写入成功。这样即使主库宕机，把从库切换为主库，数据也不会丢失。

#### 半同步复制有哪两种实现方式？

第一种: after_commit 方式，非默认方式。当主库写入binlog时，等binlog复制到从库时，主库就提交自己的本地事务，然后等待从库给主库返回成功的响应，主库再返回提交事务成功的响应给客户端

第二种:MySQL 5.7 的默认方式。主库写入 binlog，然后复制给从库，等待从库给主库返回成功，主库再提交事务，然后再返回提交事务成功的响应给客户端

#### 如何搭建半同步复制？

在搭建好异步复制的基础上，先在主库安装半同步复制插件，并开启半同步复制功能:

```bash
# 以下命令在MySQL命令中执行
# 插件名称在linux环境是".so"，如果是windows环境，则改为".dll"
install plugin rpl_semi_sync_master soname `semisync_master.so`;
set global rpl_semi_sync_master_enbale=on;
show plugins;
# 如果能看到安装了这个插件，存在则主库半同步插件安装成功
```

然后在从库安装插件并开启半同步复制功能:

```bash
install plugin rpl_semi_sync_slave soname `semisync_slave.so`;
set global rpl_semi_sync_slave_enable=on;
show plugins;
# 检查插件列表是否存在当前安装的插件，存在则从库半同步插件安装成功
```

然后重启从库的IO线程:

```bash
stop slave io_thread;
start slave io_thead;
```

最后在主库上检查半同步复制是否在正常运行:

```bash
show global status like `%semi%`;
# 如果看到 Rpl_semi_sync_master_status的状态为on则完成
```

#### 如何基于GTID搭建主从复制？

MYSQL主从复制，除了搭建半同步复制模式，还有一种是GTID搭建模式:

在主库上mysql配置文件上配置:

```bash
gtid_mode=on;
enforce_gtid_consistency=on
log_bin=on
# 单独设置一个
server_id=2
binlog_format=row
```

然后在从库mysql配置文件上进行配置:

```bash
gtid_mode=on
enforce_gtid_consistency=on
log_slave_updates=1
# 单独设置一个和主库不同的id
server_id=3
```

然后创建用于主从复制的账号，然后从主库停止写入，dump出备份sql，在从库执行一遍，然后然后把backup.sql拷贝到从库上去执行完。然后打开backup.sql，找到

```bash
@@GLOBAL.GTID_PURGED=XX
```

然后根据backup.sql中找到的内容在从库mysql命令行中执行命令来指定主库进行复制:

```bash
change master to master_host=`192.168.31.229`,
master_user = `backup_user`,master_password=`backup_123`,
@@GLOBAL.GTID_PURGED=XX;
```

然后在从库执行查询:

```bash
# 找到executed_gtid_set,里面记录的事执行过的 gtid
show master status;
# 接着执行下面的命令与上面的结果做对比
select * gtid_executed;
# 对应上说明已经开始gtid复制了
```

#### 如何解决主从复制带来的数据延迟？

主从复制为什么会产生延迟？

很简单，由于主库是多线程并发写入，但是从库是单个线程过来拉取数据的，所以导致了从库复制速度较慢。主从之间延迟时间可以使用percona-tookit工具集中的pt-heartbeat工具，工具会在主库创建一个heartbeat表，然后有一个线程定时更新表中时间戳字段，然后从库上有一个monitor线程负责检查主库同步过来的heartbeat表里的时间戳。

主从复制延迟会导致什么问题？

如果基于主从复制做了读写分离架构，主从复制延迟就会导致系统刚写入一条数据到主库，但是立即在从库中读取会发现读取不到。

如何解决复制延迟？

也就是说让从库也用多线程并行复制数据就可以了，这样从库复制的足够快就能大大降低延迟。具体做法是:mysql5.7开始就支持并行复制了，可以在从库mysql配置文件中配置:

```bash
slave_parallel_workers>0
slave_parallel_type=LOGICAL_CLOCK
```

如果在读写分离架构下还是有刚刚写入的数据需要立即被读到，可以在mycat或者sharding_sphere等中间件中设置读写强制都从主库走，这样刚写入的数据就能立即被读到。

在搭建读写分离架构时，如果对数据丢失不敏感，可以使用异步复制再搭配从库并行复制机制。

如果对mysql要做高可用来保证数据绝对不丢失的话，还是要使用半同步复制，然后搭配从库并行复制机制

#### 如何让MySQL基于主从复制实现故障转移保证高可用？也就是说如何实现故障转移？

一般生产环境里使用MHA工具，也就是Master High Availability and Tools for MySQL,日本人使用perl脚本写的一个工具。MHA需要单独部署，分为Manager节点和Node节点。Manager节点一般是单独部署一台机器，Node节点需要部署在MySQL机器上，因为Node节点需要去解析MySql日志进行一些操作。而manager节点会通过探测集群里的node节点来判断
