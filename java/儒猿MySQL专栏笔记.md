## "update user set name = 'XXX' where id = 10" 的更新过程？
先把要更新的这行记录从磁盘文件加载到缓冲池，然后对这行记录加锁后将这行数据的旧值记录到undo日志中。然后先更新内存缓冲池中的记录，然后将更新写入到redo log buffer中，redo log buffer是一块内存缓冲器，redo log buffer 有3种策略将数据写入磁盘中，
通过innodb_flush_log_at_trx_commit来配置。写完redo 
log后会将binlog按刷盘策略来写入磁盘写完binlog后，进入事务的最终提交阶段，会把本次更新对应的binlog文件名和本次更新内容记在binlog文件中的位置，都写入到redo log中，同时在redo 
log文件中写入一个commit标记，整个事务完成。commit标记用于保持redo log和binlog的一致性，假如刚刚将redolog写入磁盘文件，mysql宕机了，此时机器恢复后，由于redo log中没有commit标记，所以mysql判定此次事务不成功。假如将binlog写入磁盘了，然后mysql宕机了，此时同样会因为redo log中没有commit标记，认定此次事务不成功，必须是在redo log中写入commit标记后，才算此时事务提交成功，这时redolog 中有本次更新对应的日志，binlog中也有本次更新对应的日志，这时redo log和binlog是完全一致的。最后由后台IO线程将脏页刷回磁盘。
* 当参数为0时，提交事务时不会将redo log buffer里的数据写入磁盘，这种情况下当mysql宕机事务数据会丢失。
* 当参数为1时，提交事务时必须将redo log buffer中数据写入磁盘，也就是说只要事务提交成功，redo log一定会写入磁盘。此时mysql宕机事务数据也不会丢失，因为即使磁盘数据没有改变，但是redolog磁盘文件已经记录了，当mysql重启后会根据redo log去恢复内容。
* 当参数为2时，提交事务时将redo log写入磁盘文件对应的 os cache里，而不是直接写入磁盘文件，有可能1秒后才会把os cache里的数据写入磁盘。这种情况下，当提交事务后，redolog仅仅停留在os 
cache里没有实际写入磁盘文件，此时如果机器宕机，还是会丢失数据
* 对于redo log的刷盘策略，通常设置为1。也就是提交事务时，redo log必须刷入磁盘文件里，对于数据库这样的严格系统，这样可以保证事务提交后，数据绝不会丢失

## binlog的刷盘策略？
用sync_binlog参数来控制binlog的刷盘策略。
* 默认值是0。意思是把binlog写入磁盘时，不直接写入磁盘文件而是写入os cache内存中，此时宕机，os cache中binlog会丢失
* 参数为1。会强制在事务提交时，将binlog写入磁盘文件里。这样即使提交事务后机器宕机，binlog也不会丢。

生产经验:
Java应用系统部署在4核8G机器上，每秒可以抗500左右并发量。
一般8核16G的机器部署MySQL数据库，每秒种可以抗1、2K并发
对于16核32G的机器部署MySQL数据库，每秒可以抗2、3k并发
# 数据库压测需要关注的相关性能指标:
IO相关:
(1)IOPS:指的是机器随机IO并发处理能力，比如200IOPS意思就是说每秒可以执行200个随机IO读写请求。
当在内存bufferPool写入脏数据后，需要后台IO线程在机器空闲时刷回到磁盘，这是一个随机IO的过程。如果IOPS过低，会导致内存里脏数据刷回磁盘的效率太低
(2)吞吐量:指的是机器磁盘每秒可以读写多少字节
当执行sql提交事务时需要将大量redo log等日志写入磁盘，写入redolog一般是一行一行顺序写入，不会进行随机读写，一般SSD顺序写吞吐量可达到每秒200MB
，对于承载高并发来说，SSD磁盘吞吐量不是瓶颈
(3)latency:指的是向磁盘写入一条数据的延迟。当执行sql和提交事务时，需要将redo log顺序写到磁盘，如果写入延迟过高会影响数据库的sql执行性能。写入延迟越低，执行sql的事务的速度就越快，数据库性能就越高
(4)CPU负载:压测中如果CPU负载特别高，就说明已经到达瓶颈，不能继续压测了
(5)网络负载:关注每秒钟网卡会输入多少MB数据，会输出多少MB数据，当到达网络带宽最大值时说明已经出现瓶颈了，就不能再继续压测了
(6)内存负载:如果内存占用过高，也说明不能继续压测了

## 数据库压测工具 sysbench 使用方法:
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

# Buffer Pool:
是数据库中一块基于内存的组件，核心是通过使用内存而不是直接使用硬盘来提高访问速度。Java系统对数据库执行增删改查请求主要就是对这个内存组件中的缓存数据执行的

### 如何配置buffer pool大小？
默认大小下为128MB，有点偏小，对于16核32G机器，可以给BufferPool分配个2GB内存。通过修改配置参数:innodb_buffer_pool_size=2147483648

bufferPool内部结构:buffer_pool中包含多个缓存页，同时每个缓存页还有一个描述数据。当数据库启动时，会按照bufferPool的大小再稍微加大一点去向操作系统申请一块内存区域，作为bufferPool内存区域。然后按照默认缓存页的16KB大小以及800个字节左右的描述数据大小，将整个bufferPool划分成一个一个的缓存页和一个一个的缓存页对应的描述数据。每个描述数据块都是free链表的一个节点，free链表是一个双向链表

## 如何查询一个数据页是否在bufferPool中呢？
数据库中有一张hash表，使用表空间+数据页号作为key，缓存页的地址作为value。当要使用一个数据页时，通过“表空间号+数据页号”作为key去hash表中查询，如果value为空说明缓存页不存在，则需要从磁盘中读取数据页到缓存页中

## 如果bufferPool中的缓存页不够了怎么办？
bufferPool中维护了一个由缓存页的描述数据块作为结点的LRU链表，最近被访问过的数据块一定在LRU链表的头部。当缓存页满了时，就会找出最近最少被访问的缓存页，将这个缓存页刷入磁盘

MySQL使用磁盘存储数据是以页为单位的，BufferPool以页为单位从磁盘中加载数据，叫做缓存页，每个bufferPool中的页会和磁盘上的页一一对应起来，而每一页可能会记录好几行数据，默认情况下一页数据大小是16KB。每页的描述数据大概占页大小的5%用于存储缓存页信息
<bufferPool从磁盘加载页的图>

### 数据库启动时是如何初始化BufferPool的？
数据库启动时，按照配置中的bufferPool大小去找操作系统申请一块内存作为bufferPool缓存区域，申请完毕后按照设定的缓存页大小(默认16KB)以及800字节左右的描述数据大小，把bufferPool划分成一个一个的缓存页和对应的描述数据。划分完成后，缓存页都是空的，只有java系统发起增删改查请求时才会把数据以页为单位从磁盘中读取出来放入bufferPool的缓存页中。
《画图》

### 怎么能知道bufferPool中哪些缓存页是空闲的？
bufferPool中用一个双向链表来管理所有空闲的数据页，叫做free链表，链表中的每个节点都是一个空闲缓存页的描述数据(只要有一个缓存页是空闲的，它的描述数据就会被放到free链表中，数据库刚启动时所有的缓存页都是空闲的，此时所有缓存页的描述数据都在free链表中)，free链表中还有一个基础节点，里面存了free链表的头节点地址和尾节点地址还有free链表中当前还有多少个节点，但这个节点不属于bufferPool
《画图》

### 如何将磁盘上的页读取到bufferPool的缓存页中去？
先从free链表中取一个描述数据块，根据描述数据节点取到对应的空闲缓存页，然后把磁盘上的数据页读取到这个空闲缓存页里，然后把如数据页所属表空间等页相关描述数据写入描述数据块，然后从free链表中去除这个描述数据块就可以了

### 怎么知道数据页有没有被缓存呢？
当java系统向数据库发起增删改查请求时，一定是先判断数据页有没有被缓存，如果没有缓存就走上面的流程从磁盘中加载到bufferPool，如果数据页已被缓存则直接使用。
在数据库内部是使用一个哈希表，以表空间+数据页号为key，缓存数据页内存地址为value，来记录数据页是否被缓存。
当java系统要使用一个数据页时，先以"表空间号+数据页号"作为key去哈希表中查询页是否存在，如果不存在则从磁盘加载，然后在哈希表中写入一个key-value对，key就是表空间号+数据页号，value就是缓存页的内存地址，如果存在则说明数据页已缓存可以直接访问

### 什么原因会造成 bufferPool 中产生内存碎片？
由于bufferPool大小可以自定义，所以划分完缓存页和对应的描述数据后，还剩一点内存，这一点内存无法容纳一个缓存页，只能放着不能用，这点内存就是内存碎片。

### 数据库是如何减少bufferPool的内存碎片的？
如果数据库在给bufferPool划分缓存页时，是东一块西一块的，就会导致缓存页之间产生内存空洞，形成大量内存碎片。
实际上数据库在给bufferPool划分缓存页时是连续分配，会让所有的缓存页和描述数据块都紧密的挨在一起，这样就尽量减少了内存碎片

### 什么是脏页？
Java系统发送给数据库的增删改查请求，最终会在bufferPool中被执行，而磁盘上数据并没有变，这时bufferPool中被修改的缓存页就叫脏页

### 怎么知道哪些缓存页是脏页呢？
BufferPool中使用一个叫做flush链表的双向链表来记录bufferPool中的脏页，凡是被修改过的缓存页，都会把它的描述数据块加入到flush链表中，flush链表结构跟free链表结构几乎一样。flush就是刷脏页的意思，后续是要把脏页flush到磁盘上的

### 如果bufferPool满了，要在bufferPool中淘汰一些缓存页，该淘汰谁？
bufferPool内部使用了一个LRU链表(least recently used,最近最少使用)来记录哪些缓存页是最近最少被使用的。所有从磁盘加载的缓存页的描述数据块都会被这个LRU链表记录，当某个缓存页被访问(查询或修改),就会把这个缓存页的描述数据块挪到LRU链表的头部，也就是说最近被访问的缓存页一定在LRU链表的头部，而尾部保存的就是最近最少被访问的数据页。当bufferPool满了时，就会从LRU链表的尾部开始找到一个缓存页，把缓存页的数据flush到磁盘，然后将数据从缓存页中清空，最后把正在请求的数据从磁盘加载到这个缓存页从中。

### 缓存命中率
在100次请求中，有30次是在查询和修改缓存页中的数据，那么缓存命中率为30%

### 在 SQL 语句中用到的是表和行的概念，而数据库内部是使用表空间和数据页，两者的关系是什么呢？
表和行是逻辑概念，逻辑层面无需关心物理层面的实现。表空间、数据页就属于物理概念，在物理层面上，一个表里的数据都是放在一个表空间中，表空间由一堆磁盘上的数据文件组成，而数据文件是由一个一个的数据页组成的。




















































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































