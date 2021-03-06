使用MySQL基本要求: 存储引擎（了解），索引（能建索引，写的SQL都用上索引），事务（了解事务的隔离级别，基于spring的事务支持在代码里加事务）。
存储引擎 -> innodb，索引，基本按照你的SQL的需求都建了索引（可能漏了部分索引忘了建），事务（@Transactional注解，对service层统一加了事务）

# 存储引擎
myisam，不支持事务，不支持外键约束，索引文件和数据文件分开，这样在内存里可以缓存更多的索引，对查询的性能会更好，适用于那种少量的插入，大量查询的场景。
 
* 最经典的场景就是报表系统，比如大数据的报表系统，常见的就是走hadoop生态来搞，hdfs来存储数据，然后基于hive来进行数仓建模，每次hive跑出来的数据都用sqoop从hive中导出到mysql中去。然后基于mysql的在线查询，就接上j2ee写个简单的web系统，每个报表开发一套代码，写sql查数据，组织数据，按照前端要求的格式返回数据，展现出来一个报表。这种报表系统，是最适合mysql的myisam存储引擎的，不需要事务，就是一次性批量导入，接下来一天之内就是纯查询了。但是在很多大数据场景里这种方式是不适用的，因为真正的大数据系统，很多时候hadoop跑出来的结果还是很大，一天就几千万结果数据，几十亿明细数据，那mysql是抗不住这么大量的数据的。所以现在大数据一般用kylin做离线数据的分析引擎，直接hive数据导入kylin里面去了，或者也可以走elasticsearch。
 
尝试做过一个事情，用mysql分库分表来抗，抗不住了，单表一般建议是控制在几百万的数据量级，500w以内的数据量，多少表？多少库？多少台数据库服务器？sql多达几百行，各种子查询、join、函数、行转列、列传行，非常不适合用mysql -› 数据量很大 -› sql很复杂 -› 导致mysql数据库服务器cpu负载过高
 
比较高端一点了，我们会基于自己研发的可配置化BI系统 + kylin + elasticsearch，支持大规模数据的复杂报表的支持，效果远远超出基于mysql的那套方案，效果非常好
 
后来还有那种实时数据报表，就是storm或者是spark streaming，跑数据出来，来一条算一条，然后结果立马写入mysql中，这个的话，一般就保留当天数据，其实压力不会太大，但是问题在于说，可能写并发会超高，每秒并发轻易就可以几千甚至上万。所以大数据实时报表不会写mysql了，现在一般都是写es。
 
你可以按照我上面的这套说辞去说说，如果是java方向的同学，就说你们之前配合你们公司的数据团队开发过这种报表系统的j2ee部分，所以当时用myisam比较多，但是后来人家几乎都不用了，借此体现出你是有实际经验的，这回答的档次都不一样了。
 
**innodb**
说真的，现在一般用mysql都是innodb，很少用其他的存储引擎，而且国内用其他存储引擎的场景和公司也不多，所以用innodb就可以了，而且这个也是mysql 5.5之后的默认存储引擎。
 
主要特点就是支持事务，走聚簇索引，强制要求有主键，支持外键约束，高并发、大数据量、高可用等相关成熟的数据库架构，分库分表、读写分离、主备切换，全部都可以基于innodb存储引擎来做，如果真聊到这儿，其实大家就可以带一带，说你们用innodb存储引擎怎么玩儿分库分表支撑大数据量、高并发的，怎么用读写分离支撑高可用和高并发读的，用上第1季的内容就可以了。 
 
## 数据库锁有哪些类型？
表锁、行锁，页锁。

一般myisam会加表锁，在myisam引擎下执行查询时，会默认加表共享锁，也就是读表锁，这时其他对这张表的查询可以进行，但是无法向表中写数据。当myisam表中写数据时，会加表独占锁，别人不能读也不能写。如果myisam表建好索引，只查询性能还是不错的，单表支撑千万级别数据没问题
页级锁一般几乎很少用，提一句就ok了  

innodb:innodb的行锁有共享锁(S锁)和排他锁(X锁)，共享锁就是多个事务都可以加共享锁读同一行数据，但是别的事务不能写这行数据；
排他锁，就是只有一个事务可以写这行数据，别的事务只能读，不能写。当执行insert、update、delete时，innodb会自动给那一行加行级排他锁  

innodb的表锁，分为意向共享锁和意向排他锁。这个表锁是innodb引擎自动加的，不用你自己去加。
意向共享锁:加共享行锁时，必须先加共享表锁。
意向排他锁:给某行加排他锁的时候，必须先给表加排他锁。

innodb不会主动加共享锁，只能手动开启
手动加共享锁: select * from table where id = 1 lock in share mode。对id为1的这行加了共享锁，其他事务无法修改这行数据
手动加排他锁: select * from table where id = 1 for update。对id为1的这行加了排他锁，意思是你准备修改，其他事务不能在这期间对这行数据进行修改，
其他事务会阻塞在这。(要慎用，一般线上系统不用这个，容易出问题)

锁是如何实现的？
mysql行级锁有哪两种？
一定会锁定指定的行么？为什么?

## 24.MySQL中锁分为哪三类？
根据加锁的范围，MySQL 里面的锁大致可以分成全局锁、表级锁和行锁三类。  
* 全局锁：全局锁就是对整个数据库实例加锁，命令是 Flush tables with read lock (FTWRL)，
命令执行后其他线程的以下语句会被阻塞：数据更新语句（数据的增删改）、数据定义语句（包括建表、修改表结构等）和更新类事务的提交语句。
使用场景：全库逻辑备份。也就是把整库每个表都 select 出来存成文本。

全局备份的方法：官方自带的逻辑备份工具是 mysqldump。当 mysqldump 使用参数–single-transaction 的时候，
导数据之前就会启动一个事务，来确保拿到一致性视图。而由于 MVCC 的支持，这个过程中数据是可以正常更新的。

一致性读是好，但前提是引擎要支持这个隔离级别。比如，对于 MyISAM 这种不支持事务的引擎，如果备份过程中有更新，
总是只能取到最新的数据，那么就破坏了备份的一致性。这时，我们就需要使用 FTWRL 命令了。

所以，single-transaction 方法只适用于所有的表使用事务引擎的库。如果有的表使用了不支持事务的引擎，那么备份就只能通过 FTWRL 方法。

* 表级锁MySQL 里面表级别的锁有两种：一种是表锁，一种是元数据锁（meta data lock，MDL)。

表锁的语法是 lock tables … read/write。与 FTWRL 类似，可以用 unlock tables 主动释放锁，
也可以在客户端断开的时候自动释放。需要注意，lock tables 语法除了会限制别的线程的读写外，
也限定了本线程接下来的操作对象。举个例子, 如果在某个线程 A 中执行 lock tables t1 read, t2 write; 
这个语句，则其他线程写 t1、读写 t2 的语句都会被阻塞。同时，线程 A 在执行 unlock tables 之前，
也只能执行读 t1、读写 t2 的操作。连写 t1 都不允许，自然也不能访问其他表。

另一类表级的锁是 MDL（metadata lock)。MDL 不需要显式使用，在访问一个表的时候会被自动加上。MDL 的作用是，
保证读写的正确性。你可以想象一下，如果一个查询正在遍历一个表中的数据，而执行期间另一个线程对这个表结构做变更，
删了一列，那么查询线程拿到的结果跟表结构对不上，肯定是不行的。因此，在 MySQL 5.5 版本中引入了 MDL，
当对一个表做增删改查操作的时候，加 MDL 读锁；当要对表做结构变更操作的时候，加 MDL 写锁。读锁之间不互斥，
因此你可以有多个线程同时对一张表增删改查。读写锁之间、写锁之间是互斥的，用来保证变更表结构操作的安全性。
因此，如果有两个线程要同时给一个表加字段，其中一个要等另一个执行完才能开始执行。

读锁是共享的，也就是相互不阻塞，写锁是排他的，也就是一个写锁会阻塞其他写锁和读锁

## 悲观锁和乐观锁是什么？使用场景是什么？
* 悲观锁: 在mysql中的表现形式为select * from table where id =1 for update,
锁语义为悲观的担心自己无法拿到锁，必须先锁死然后独占，其他人无法访问，不能加共享锁也不能加排他锁
* 使用场景: 当查询出一条数据，要在内存中修改后再更新到数据库中去，但是这个过程中数据可能被别人更新，所以用悲观锁，在查询后不让其他人读写，你更新后才会重新允许别人读写

* 乐观锁:锁语义为觉得自己大概率可以获取到锁，实现方式为先select id，name，version from table where id = 1,接着执行业务逻辑，然后update table set name="新名字",
version = version + 1 where id =1 and version = 1。也就是在每次修改时比较一下本次update的版本号和前面select时查出来的version是不是相同的，如果相同则进行update并将version + 1，否则不会更新这条数据，需呀重新查询后再次执行业务逻辑后更新。
## mysql死锁原理及如何定位和解决？
两个事务分别持有一个锁，互相持有对方事务需要的资源会导致死锁，
解决办法；找dba看一下死锁日志，然后根据对应的sql，找到对应的 代码，分析死锁原因。

## 死锁处理策略(当发生死锁时，mysql是怎么处理的？)
* 一种策略是，直接进入等待，直到超时。这个超时时间可以通过参数 innodb_lock_wait_timeout 来设置。在 InnoDB 中，innodb_lock_wait_timeout 的默认值是 50s，
* 另一种策略是，发起死锁检测，发现死锁后，主动回滚死锁链条中的某一个事务，让其他事务得以继续执行。将参数 innodb_deadlock_detect 设置为 on，表示开启这个逻辑。  
当innodb发现死锁时，将持有最少行级排它锁的事务回滚，通过这种方式打破死锁
 
# 索引篇:
innodb表是基于聚簇索引建立的。聚簇索引对主键查询有很高的性能，不过它的二级索引(secondary index，非主键索引)中必须包含主键列，所以如果主键列很大的话，其他的所有索引都会很大。因此若表上的索引较多的话，逐渐应当尽可能的小。

官方手册中“innodb事务模型与锁”一节

索引：索引可以包含一个或多个列的值。如果索引包含多个列，那么列的顺序也十分重要，因为mysql只能高效地使用索引的最左前缀列。创建一个包含两个列的索引，和创建两个只包含一列的索引是大不相同的。

innodb支持两种索引：btree hash
实际上很多存储引擎使用的是B+Tree,即每一个叶子节点都包含指向下一个叶子节点的指针，从而方便叶子节点的范围遍历。

BTree索引：innodb底层使用B+tree来实现的btree索引方式。
btree通常意味着所有的值都是按顺序存储的，并且每一个叶子节点到根的距离相同。这种数据结构很适合查找范围数据。每次查询时都从根节点开始出发
BTree支持“只访问索引的查询”，即查询只需要访问索引，而无需访问数据行。称为覆盖索引

InnoDB引擎支持两种索引,一种是B+树索引，另一个是哈希索引。 InnoDB存储引擎支持的哈希索引是自适应的，INNoDb存储引擎会根据表的使用情况自动为表生成哈希索引
，不能人为干预是否在一张表中生成哈希索引。

从普通索引查询到主键索引，然后回到主键索引树搜索的过程，我们称为回表

### 聚簇索引并不是一种单独的索引类型，而是一种数据存储方式。innoDb存储引擎的聚簇索引实际上是在同一个结构中保存了B-Tree索引和数据行记录。

当表有聚簇索引时，它的数据行记录实际上存放在索引的叶子页中。术语"聚簇"表示数据行记录和相邻的键值紧凑地存储在一起。因为无法同时把数据行记录存放在两个不同的地方，所以一个表只能有一个聚簇索引。
聚簇索引的key是索引值，value是行记录

如果没有定义主键，innodb会选择一个唯一的非空索引代替。如果没有这样的索引，innodb会隐式定义一个主键来作为聚簇索引。

### 19.什么是覆盖索引？
如果执行的语句是 select ID from T where k between 3 and 5，这时只需要查 ID 的值，而 ID 的值已经在 k 索引树上了，因此可以直接提供查询结果，
不需要回表。也就是说，在这个查询里面，索引 k 已经“覆盖了”我们的查询需求，我们称为覆盖索引。
由于覆盖索引可以减少树的搜索次数，显著提升查询性能，所以使用覆盖索引是一个常用的性能优化手段。

也就是说。索引中如何有你要查询的数据，就称为覆盖索引

覆盖索引不能只覆盖要查询的列，同时必须将WHERE后面的查询条件的列都覆盖，因为覆盖索引的目的就是”不回表“，
所以只有索引包含了where条件部分和select返回部分的所有字段，才能实现这个目的

#### mysql默认引擎为innodb，innodb默认使用行锁，而行锁是基于索引的，因此要想加上行锁，在加锁时必须命中索引，否则将使用表锁

### 11.按不同类型对索引分类？
* 根据叶子节点的内容，索引类型分为主键索引和非主键索引。主键索引的叶子节点存的是整行数据。在 InnoDB 里，主键索引也被称为聚簇索引，每张表只能建一个聚簇索引
非主键索引的叶子节点内容是主键的值。在 InnoDB 里，非主键索引也被称为二级索引

### 12.基于主键索引和普通索引的查询有什么区别？
* 主键索引查询: 如果语句是 select * from T where ID=500，即主键查询方式，则只需要搜索 ID 这棵 B+ 树；
* 普通索引查询: 如果语句是 select * from T where k=5，即普通索引查询方式，则需要先搜索 k 索引树，
得到 ID 的值为 500，再到 ID 索引树搜索一次。这个过程称为回表。也就是说，基于非主键索引的查询需要多扫描一棵索引树。
因此，我们在应用中应该尽量使用主键查询。   

innodb中对主键索引的存储方式为聚簇索引，即主键索引key值为主键值，value为整行数据
普通索引key值为普通索引值，value为对应的主键值 

### 21.什么是索引下推？
在 MySQL 5.6 之前，只能从 ID3 开始一个个回表。到主键索引上找出数据行，再对比字段值。

而 MySQL 5.6 引入的索引下推优化（index condition pushdown)， 可以在索引遍历过程中，
对索引中包含的字段先做判断，直接过滤掉不满足条件的记录，减少回表次数。

### MySQL索引的原理和数据结构能介绍一下吗？
考点:说出mysql索引底层的数据结构实现，并且现场画出索引的数据结构，说出mysql索引的常见使用原则，拿出具体sql考察索引建立方法。
mysql的索引实现方式不是二叉树，而是一棵b+树。查找时从根节点开始二分查找。b+树时b-树的变种，同样的一份数据在b-树和b+树中排列是不一样的。
b+树和b-树的区别:
(1)每个节点的指针上限为2d而不是2d+1
(2)内节点不存储data，只存储key；叶子节点存储data，并且叶子节点不存储指针

### MySQL聚簇索引和非聚簇索引的区别是什么？他们分别是如何存储的？
* 聚簇索引指的是表数据按照索引的顺序来存储的，也就是说索引顺序和表中记录顺序一致，在一张表上最多只能创建一个聚簇索引，因为表数据的物理顺序只能有一种。
* 非聚簇索引指的是表数据的存储顺序和索引顺序无关
* myisam对索引的实现:索引和数据单独存储，索引文件的b+树叶子节点存的是数据行的物理地址，数据文件存储的是物理地址和数据。查询时先从索引文件中搜索，然后根据物理地址到数据文件中定位一个行记录
* innodb对索引的实现:根据主键来建立聚簇索引的方式存储数据，所以innodb要求必须有主键，而myisam表主键不是必须的，innodb的数据文件本身同时也是个索引文件。innodb中建立非主键索引，此索引key
是索引值，value是主键值。为什么不建议innodb下用uuid这种超长随机字符串作为主键呢？因为所有其他索引都会存储主键索引值，会导致索引占磁盘空间过大，浪费磁盘空间。建议使用auto_increment自增值作为主键值，因为这样可以保持聚簇索引直接加记录即可，如果不使用单调递增，可能会导致b+树分裂后重新组织浪费性能

### 使用MySQL索引都有哪些原则？
因为索引需要占用磁盘空间，并且在高并发场景下频繁插入和修改索引会导致性能损耗。基于这两个问题的最佳实践就是，尽量少的创建索引，一个表一两个索引，10来个，20个索引，高并发场景下还是可以接受的。并且在创建索引时区分度要高，使用select count(discount(col))/count(*)来计算区分度。如果字段的唯一值在总行数占比过低，说明区分度不高，那么当查询时搜一个值会定位到多行记录，还是需要逐行对多行记录扫描，就失去建立索引的作用了，就是要每个字段的值几乎都不太一样这样使用索引的效果才是最好的。
如果对某个很长的字符串类型字段建立前缀索引时，最好对字符串的前缀来创建，用前面的sql来计算取不同长度的前缀索引的区分度，区分度越高越好。

### MySQL联合索引如何使用？
单个索引是等值匹配，联合索引有最左前缀匹配原则，很多时候不是对很多字段分别建索引的，而是针对几个字段建立一个联合索引。
最左前缀匹配原则:例如对shop_id,product_id,gmt_create三个字段建立了联合索引
* (1)全列匹配: 一个sql的where子句里用了这3个字段，那么一定可以走这个联合索引
* (2)最左前缀匹配: 一个sql的where子句只使用到了联合索引最左边的一个或几个字段，这种情况也可以走联合索引，在联合索引里查最左边的几个列即可。
* (3)最左前缀匹配了，但是中间某个值没有匹配: 在sql中查询时where中国包含了联合索引的第一个列和第三个列，这种情况会按照第一个列值在联合索引中找，找完后对结果集根据第三个列来过滤。例如:
```
select * from product where shop_id =1 and gmt_create = '2018-01-01 10:00:00'
就是先根据shop_id=1在联合索引里找，找到100行记录，然后对这100行记录再次扫描一遍，过滤出来gmt_create = '2018-01-01 10:00:00'的行
```
线上经验:线上系统经常遇到这种情况，就是根据联合索引的前一两个列按索引查，然后后面跟一堆复杂条件，还有函数，但是只要对索引查找结果过滤就好了，根据线上实践，单表数据几百万数据量，性能还不错，简单sql几ms，复杂sql也就几百ms，可以接受的
(4)没有匹配最左前缀
where子句没有用最左前缀的第一个列查询，一定不走联合索引
* (5)前缀匹配:
如果不是等值匹配(=,>=,<=)的操作，而是like操作，那么必须是like 'XX%'这种方式才可以用上索引。比如:
```
select * from product where shop_id = 1 and product_id = 1 and gmt_create like '2018%';
```
* (6)范围匹配:
比如>=,<=,between等范围查询操作，只有符合最左前缀规则的列可以使用联合索引查询范围，但是范围后面的列就不走索引了。
```
select * from product where shop_id >= 1 and product_id = 1;
这里就使用联合索引根据shop_id来查询，然后对product_id 来过滤
```
* (7)使用函数:
如果对某个列使用了函数(比如substring)，那么这一列不走联合索引。
```
select * from product where shop_id = 1 and 函数(product_id) = 2;
这条sql只能根据shop_id这一列在联合索引中查询，不走product_id这列
```

### 10.说一下索引常见的3种模型？
* 索引的使命就是为了提高数据查询效率，就像书的目录一样。索引就是数据库表的目录  
一本 500 页的书，如果想快速找到其中的某一个知识点，
在不借助目录的情况下，估计要找一会。同样，对于数据库的表而言，索引其实就是它的“目录”。

* 哈希表:用拉链法解决哈希冲突，哈希表不是有序的，所以做区间查询速度很慢。哈希表这种结构适用于只有等值查询的场景，比如 Memcached 及其他一些 NoSQL 引擎。

* 有序数组:有序数组在等值查询和范围查询场景中的性能就都非常优秀。查询单条数据用二分法，查询区间用二分法先确定左边界，
然后向右遍历循环查找。缺点是更新数据比如插入数据时，需要挪动后面所有记录，成本太高。有序数组索引只适用于静态存储引擎，
比如你要保存的是 2017 年某个城市的所有人口信息，这类不会再修改的数据。

* 搜索树:在二叉树中查询时间复杂度为O(log(N)) ，为了保证二叉树的平衡性，更新时时间复杂度也是O(log(N))

### 16.通过两个 alter 语句重建索引 k，以及通过两个 alter 语句重建主键索引是否合理？
重建普通索引:  
```
alter table T drop index k;
alter table T add index(k);
```
重建主键索引:
```
alter table T drop primary key;
alter table T add primary key(id);
```
如果删除并新建主键索引，会同时去修改普通索引对应的主键索引，性能消耗比较大。
删除重建普通索引貌似影响不大，不过要注意在业务低谷期操作，避免影响业务。

如果有同时删除普通索引和主键索引的需求，需要注意顺序：
顺序应是先删除k列索引，主键索引。然后再创建主键索引和k列索引。

1. 直接删掉主键索引是不好的，它会使得所有的二级索引都失效，并且会用ROWID来作主键索引；
2. 看到mysql官方文档写了三种措施，第一个是整个数据库迁移，先dump出来再重建表（这个一般只适合离线的业务来做）；
第二个是用空的alter操作，比如ALTER TABLE t1 ENGINE = InnoDB;这样子就会原地重建表结构（真的吗？）；
第三个是用repaire table，不过这个是由存储引擎决定支不支持的（innodb就不行）。

为什么要重建索引？索引可能因为删除，或者页分裂等原因，导致数据页有空洞，
重建索引的过程会创建一个新的索引，把数据按顺序插入，这样页面的利用率最高，也就是索引更紧凑、更省空间。

删除数据的同时索引也删除了，但是引起了页里面的空洞，alter table T engine=InnoDB是重建索引去掉空洞的操作

重建索引 k 的做法是合理的，可以达到省空间的目的。但是，重建主键的过程不合理。不论是删除主键还是创建主键，
都会将整个表重建。所以连着执行这两个语句的话，第一个语句就白做了。这两个语句，你可以用这个语句代替 ： 
```
alter table T engine=InnoDB。
```

实例：今天这个 alter table T engine=InnoDB 让我想到了我们线上的一个表, 记录日志用的, 会定期删除过早之前的数据.
最后这个表实际内容的大小才10G, 而他的索引却有30G. 在阿里云控制面板上看,就是占了40G空间. 这可花的是真金白银啊.
后来了解到是 InnoDB 这种引擎导致的,虽然删除了表的部分记录,但是它的索引还在, 并未释放.只能是重新建表才能重建索引.

### 17.没有主键的表，有一个普通索引。怎么回表？
没有主键的表，innodb会给默认创建一个Rowid做主键

### 23.数据量很大的时候，二级索引比主键索引更快”，这个结论什么情况下成立？
* 只有在使用覆盖索引时才成立，非覆盖索引还是要回表查询。

### 20.什么是最左前缀原则？
B+ 树这种索引结构，可以利用索引的“最左前缀”，来定位记录。也就是说，如何用两个字段建立了联合索引，
这个最左前缀可以是联合索引的最左 N 个字段，也可以是字符串索引的最左 M 个字符。 

---
# 事务
简单说就是保证一组数据库操作，要么全部成功，要么全部失败。事务id是mysql内部自己维护的，全局唯一递增的，例如事务id=1，事务id=2，事务id=3
### ACID特性:
* A:原子性(Atomic):事务中的一堆sql的执行，要么都成功，要么都失败，没有中间状态
* C:一致性(consistency):事务中的一堆sql确保一定会被执行，事务会保证数据库会从一个一致性状态到另一个一致性状态
* I:隔离性(Isolation):多个事务在同时跑的时候不能互相干扰
* D:持久性(Durability):事务执行成功后的结果会被永久保存，即使数据库宕机也不会丢失
### 隔离级别: 在事务中为保证并发数据读写的正确性而提出的定义，多个事务同时执行的时候

隔离级别是针对事务来说的，mysql中只有innoDb引擎支持事务，而innoDB的隔离级别是基于 MVCC（Multi-Versioning Concurrency Control）和锁的复合实现
>1. 读未提交(Read uncommitted): 一个事务能够看到其他事务尚未提交的修改，这是最低的隔离水平，会出现脏读。
>2. 读已提交(Read committed): 
一个事务能够看到的数据都是其他事务已经提交的修改，也就是保证不会看到任何中间性状态，当然脏读也不会出现。读已提交仍然是比较低级别的隔离，并不保证再次读取时能够获取同样的数据，也就是允许其他事务并发修改数据，会出现不可重复读和幻象读
(Phantom Read)
>3. 可重复读(Repeatable reads): 一个事务执行过程中看到的数据，总是跟这个事务在启动时看到的数据是一致的，能保证同一个事务中多次读取的数据是一致的，这是 MySQL InnoDB 
引擎的默认隔离级别。innodb存储引擎通过多版本并发控制(mvcc)解决了幻读问题(用间隙锁策略防止幻读的出现)间隙锁使得innodb不仅仅锁定查询涉及的行，还会对索引中的间隙进行锁定，以防止幻影行的插入
>4. 串行化(Serializable): 并发事务之间是串行化的，通常意味着读取需要获取共享读锁，更新需要获取排他写锁，如果 SQL 使用 WHERE 语句，还会获取区间锁（MySQL 以 GAP 锁形式实现，可重复读级别中默认也会使用），这是最高的隔离级别  
随着隔离级别从低到高，竞争性（Contention）逐渐增强，随之而来的代价是性能和扩展性的下降  

*名词解释*:
(1)脏读:
(2)不可重复读:
(3)幻读:幻读，或者幻行指的是当一个事务在读取某个范围内的记录时，另一个事务又在该范围内插入了新的记录，当前事务再次读取该范围的记录时，就会产生幻行。
* 幻读：指的是在一个事务中前后两次查询同一范围时，后一次查询看到了前一次查询没有看到的行记录。  
* 说明:在可重复读隔离级别下，普通查询是快照读，是不会看到别的事务插入的数据的。  
* 事务中的查询为当前读。幻读只会在事务中的查询才会出现。幻读仅专指读到了“新插入的行”  因此，幻读在“当前读”下才会出现。  
* 上面 session B 的修改结果，被 session A 之后的 select 语句用“当前读”看到，不能称为幻读。幻读仅专指“新插入的行” 

记住，聊到事务隔离级别，必须把这套东西(事务隔离级别各级别会出现什么问题，mysql内部对隔离级别的实现方式)给喷出来，尤其是mvcc，说实话，市面上相当大比重的java程序员，对mvcc是不了解的

mvcc:只在读已提交和 可重复读级别下工作，因为读未提交总是读取最新数据行，而不是符合当前事务版本的数据行，而串行化会对所有读取的行都加锁。 innodb的mvcc，是通过在每行记录后面保存两个隐藏的列来实现的。这两个列，一个保存了行的创建时间，一个保存行的过期时间(或删除时间)。
当然存储的并不是实际的时间值，而是系统版本号(system version number)。每开始一个新的事务，系统版本号都会自动递增。事务开始时刻的系统版本号会作为事务的版本号，用来和查询到的每行记录的版本号进行比较。

### 隔离级别在mysql内部的实现区别？
在实现上，数据库里面会创建一个视图，访问的时候以视图的逻辑结果为准。
在“可重复读”隔离级别下，这个视图是在事务启动时创建的，整个事务存在期间都用这个视图。
在“读提交”隔离级别下，这个视图是在每个 SQL语句开始执行的时候创建的。这里需要注意的是，
“读未提交”隔离级别下直接返回记录上的最新值，没有视图概念；
而“串行化”隔离级别下直接用加锁的方式来避免并行访问。

### 25.在 InnoDB 事务中，什么是行锁的两阶段锁协议？以及知道了两阶段锁协议我们如何优化事务中使用的行锁？
* 行锁是在需要的时候才加上的，但并不是不需要了就立刻释放，而是要等到事务结束时才释放。这个就是两阶段锁协议。
启示：如果事务中需要锁多个行，要把最可能造成锁冲突、最可能影响并发度的锁尽量往后放

---
# 日志: redo log 和 binlog 
## innoDB的redo log：
在执行更新操作时，如果每一次更新都需要写进磁盘，那么磁盘就需要先找到那条记录，然后更新，整个过程查找成本，io成本都很高，

所以用redo log来提升效率
而酒馆粉板和账本配合的过程，在mysql中叫做wal技术(WAL-->Write-head logging),关键点是 先实时写日志，然后等系统不忙的时候再写磁盘(刷脏页)

当有一条记录需要更新时，InnoDB引擎会先将记录写到redo log(粉板)中，并更新内存，这时候更新就算完成了。在系统空闲时，会将这个记录更新到磁盘中。如果redo log(粉板)写满了， 那就会将redo log中的一部分记录更新到磁盘中，然后把这些记录从redo log中清掉。

innodb中的redo log是固定大小的，比如可以配置一组4个文件，每个文件的大小是1gb，那么这个redo log文件就总共可以记录4gb的操作。是一个环状文件，从头开始写，写到末尾就又回到开头循环写。
![avatar](../static/redoLog.png)
write pos是当前记录的位置，一边写一遍后移，写到第3号文件末尾后就回到0号文件开头。checkpoint是当前已经写入到磁盘的一个标记位置，也就是说，之前从redo log更新到磁盘时，已经更新到checkPoint位置了，如果下次再开始将redo log更新到磁盘时，要先从checkpoint位置更新到磁盘，然后擦除记录。

write pos和checkPoint之间是redo log上空着的部分，可以用来记录新的操作。如果write pos追上checkPoint，表示redo log写满了，这时候就不能再执行新的更新了，需要停下来刷脏页，把checkPoint推进一下

有了redo log。innoDB就可以保证即使数据库发生异常重启，之前提交的记录都不会丢失，这个能力称为crash-safe。是如何做到crash-safe的呢？通过磁盘数据和redo log，也就是通过账本和粉板上的数据，就可以确保赊账账目正确

## binlog：
redo log是innodb存储引擎特有的日志，而server层的日志叫做binlog(归档日志)

为什么会有两份日志呢？
最开始mysql自带的引擎是myisam，
但是myisam引擎是没有crash-safe能力的，binlog只能用于归档。
而innodb是innodb公司以插件形式引入mysql的，
因为innodb只依靠binlog是没有crash-safe能力的，所以innodb自己实现了一套日志系统redo log来实现crash-safe能力

### redo log和binlog有什么区别？
* redo log不是记录数据页“更新之后的状态”，而是记录这个页 “做了什么改动”。
* binlog有两种模式，statement 格式的话是记sql语句， row格式会记录行的内容，记两条，更新前和更新后都有。
>1. redo log 是 InnoDB 引擎特有的；binlog 是 MySQL 的 Server 层实现的，所有引擎都可以使用。
>2. redo log 是物理日志，记录的是“在某个数据页上做了什么修改”；binlog 是逻辑日志，记录的是这个语句的原始逻辑，比如“给 ID=2 这一行的 c 字段加 1 ”。
>3. redo log 是循环写的，空间固定会用完；binlog 是可以追加写入的。“追加写”是指 binlog 文件写到一定大小后会切换到下一个，并不会覆盖以前的日志

* redo log 用于保证 crash-safe 能力。innodb_flush_log_at_trx_commit 这个参数设置成 1 的时候，表示每次事务的 redo log 都直接持久化到磁盘。这个参数我建议你设置成 
1，这样可以保证 MySQL 异常重启之后数据不丢失。
* sync_binlog 这个参数设置成 1 的时候，表示每次事务的 binlog 都持久化到磁盘。这个参数我也建议你设置成 1，这样可以保证 MySQL 异常重启之后 binlog 不丢失。

### 讲一下mysql中用的两阶段提交？
两阶段提交是跨系统维持数据逻辑一致性时常用的一个方案。当更新一条数据时，首先获取到行记录，然后修改，修改后将修改后的行记录更新到内存中，然后写入redo log，这时redo log处于prepare阶段，然后写入binlog，最后提交事务，redo log处于commit状态。
为什么这样能保证数据完整呢？



---

### MySQL的SQL调优一般都有哪些手段？你们一般怎么做？
保持sql简单，一般90%的sql都建议单表查询，join等逻辑放在java代码里实现。如果sql跑得慢，十有八九因为没走索引，所以第一步用explain分析sql执行计划，看sql是否有用到索引，没用到索引就改写sql走索引；如果索引没建就建立索引
分析sql执行计划: explain select * from table,结果有如下参数:  

table | type| possible_keys|key|key_len|ref|rows|extra

|参数|描述|
|:---:|:---:|
|table|哪个表|
|select_type|simple,简单查询还是联表查询|
|type|(很重要),all(全表扫描),const(读常量，最多一条记录匹配),eq_ref(走主键，一般就最多一条记录匹配),index(扫描全部索引),range(扫描部分索引)|
|possible_keys|显示可能使用的索引|
|key|primary,实际使用的索引|
|key_len|使用索引的长度|
|ref|联合索引的哪一列被使用了|
|rows|一共扫描并返回了多少行|
|extra|using filesort(需要额外进行排序),using temporary(mysql构建了临时表，比如排序的时候),using where(就是对索引扫出来的数据再次根据where条件进行了过滤)|

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

### 13.用自增主键为什么比用业务主键效率高？

一个数据页满了，按照B+Tree算法，新增加一个数据页，叫做页分裂，会导致性能下降。空间利用率降低大概50%。当相邻的两个数据页利用率很低的时候会做数据页合并，合并的过程是分裂过程的逆过程。

B+ 树为了维护索引有序性，在插入新值的时候需要做必要的维护。以上面这个图为例，如果插入新的行 ID 值为 700，则只需要在 R5 的记录后面插入一个新记录。
如果新插入的 ID 值为 400，就相对麻烦了，需要逻辑上挪动后面的数据，空出位置。而更糟的情况是，
如果 R5 所在的数据页已经满了，根据 B+ 树的算法，这时候需要申请一个新的数据页，然后挪动部分数据过去。
这个过程称为页分裂。在这种情况下，性能自然会受影响。除了性能外，页分裂操作还影响数据页的利用率。
原本放在一个页的数据，现在分到两个页中，整体空间利用率降低大约 50%。当然有分裂就有合并。
当相邻两个页由于删除了数据，利用率很低之后，会将数据页做合并。合并的过程，可以认为是分裂过程的逆过程。

B+ 树能够很好地配合磁盘的读写特性，减少单次查询的磁盘访问次数。  

索引的实现由存储引擎来决定，InnoDB使用B+树（N叉树，比如1200叉树），把整颗树的高度维持在很小的范围内，
同时在内存里缓存前面若干层的节点，可以极大地降低访问磁盘的次数，提高读的效率。

也就是说，自增主键的插入数据模式，正符合了我们前面提到的递增插入的场景。每次插入一条新记录，都是追加操作，都不涉及到挪动其他记录，也不会触发叶子节点的分裂。

从存储空间的角度来看。假设你的表中确实有一个唯一字段，比如字符串类型的身份证号，那应该用身份证号做主键，还是用自增字段做主键呢？
由于每个非主键索引的叶子节点上都是主键的值。如果用身份证号做主键，那么每个二级索引的叶子节点占用约 20 个字节，
而如果用整型做主键，则只要 4 个字节，如果是长整型（bigint）则是 8 个字节。显然，主键长度越小，
普通索引的叶子节点就越小，普通索引占用的空间也就越小。所以，从性能和存储空间方面考量，自增主键往往是更合理的选择。

### 14.什么场景适合用业务字段直接做主键？
* 有些业务的场景需求是这样的：只有一个索引；该索引必须是唯一索引。这就是典型的 KV 场景。由于没有其他索引，
所以也就不用考虑其他索引的叶子节点大小的问题。这时候我们就要优先考虑上一段提到的“尽量使用主键查询”原则，
直接将这个索引设置为主键，可以避免每次查询需要搜索两棵树。

### 15.select * 和select具体字段有什么区别？
select *要读和拷贝更多列到server,还要发送更多列给客户端，所以还是select id更快的。

### 18.N叉树”的N值在MySQL中是可以被人工调整的么？
5.6以后可以通过page大小来间接控制  
数据页调整后，如果数据页太小层数会太深，数据页太大，加载到内存的时间和单个数据页查询时间会提高，需要达到平衡才行  
默认情况下，表空间中的页大小都为 16KB，当然也可以通过改变 innodb_page_size 选项对默认大小进行修改，需要注意的是不同的页大小最终也会导致区大小的不同  

1， 通过改变key值来调整
N叉树中非叶子节点存放的是索引信息，索引包含Key和Point指针。Point指针固定为6个字节，假如Key为10个字节，那么单个索引就是16个字节。如果B+树中页大小为16K，那么一个页就可以存储1024个索引，此时N就等于1024。我们通过改变Key的大小，就可以改变N的值
2， 改变页的大小
页越大，一页存放的索引就越多，N就越大。

### 22.下面两条语句有什么区别，为什么都提倡使用2:
```
1.select * from T where k in(1,2,3,4,5)
2.select * from T where k between 1 and 5
```
* 第一个要搜索5次,算是等值匹配
* 第二个只需搜索一次(因为B+树叶子节点是顺序存储的,其叶子节点增加了范围查询)。因为mysql会认为这是一个连续的范围，
通过一次查找找到开始位置之后，继续往后遍历即可。而between 1 and 5 是范围查询，每个叶子节点都有一个额外指针，
指向下一个叶子结点，且他们的值都是有序的，直接遍历叶子结点的链表就可以了。
两个sql都是回表5次

### 26.说下主备同步的过程？
* 首先备库 B 跟主库 A 之间维持了一个长连接。主库 A 内部有一个线程，专门用于服务备库 B 的这个长连接。

* 一个事务日志同步的完整过程是这样的：
在备库 B 上通过 change master 命令，设置主库 A 的 IP、端口、用户名、密码，以及要从哪个位置开始请求 binlog，
这个位置包含文件名和日志偏移量。

* 在备库 B 上执行 start slave 命令，这时候备库会启动两个线程，就是 io_thread 和 sql_thread。
其中 io_thread 负责与主库建立连接。主库 A 校验完用户名、密码后，开始按照备库 B 传过来的位置，
从本地读取 binlog，发给 B。备库 B 拿到 binlog 后，写到本地文件，称为中转日志（relay log）。
sql_thread 读取中转日志，解析出日志里的命令，并执行。后来由于多线程复制方案的引入，sql_thread 演化成为了多个线程。

* 在一个主备关系中，由主库主动将binlog发送给备库，备库接收binlog然后执行。正常情况下，
只要主库执行更新生成的所有binlog都传到了备库且被备库正确执行了，备库就能达到跟主库一致的状态，
这就是最终一致性。但是mysql要提供高可用能力，只有最终一致性是不够的。

### 27 主备从的定义是怎样的？各有什么作用？
* 在mysql部署架构中，正在使用中的主机只能有一个，而备机，指的是可以替换主机的一个存在，一般主和备是主主同步，
也就是互为主备的关系。而从机只从当前的主机同步binlog，从机可以有多个，一般用从机来提高读性能。、
* 一主多从的设置，一般用于读写分离，主库负责所有的写入和一部分读，其他的读请求则由从库分担。

### 9. MySQL是如何解决主主同步的循环复制问题的？
* 主主同步，指的是主A和主B是互为主备关系，是两条线相连的。
循环复制，指的是A把B当作从机，

### 互联网公司使用mysql最佳实践？
互联网系统中，一般会尽量降低sql的复杂度，让sql保持简单，然后搭配主键索引(聚簇索引)+少数几个联合索引，就可以覆盖一个表的所有查询需求了，如果有更加复杂的业务逻辑，放在java代码里去实现。当sql达到95%都是单表增删改查，然后如果有join等逻辑就放在java代码里来做，sql越简单，后续迁移分库分表、读写分离时成本越低，几乎不怎么用改造sql。互联网公司都是用mysql当最牛的在线即时存储，存数据然后简单取出来，合理利用mysql的事务支持，并且不要使用mysql来计算，不要写join、子查询、函数在mysql里计算，计算放在java代码中做，这样来撑高并发场景

