---
typora-copy-images-to: ..\..\static
---

### 为什么要使用Nosql?

数据量变大，mysql无法承受压力，而且80%请求是读请求，缓存可以提高性能所以使用nosql来缓解mysql的压力。

### NoSQL的四大分类

1. K-V键值对: Redis、Memcached
2. 文档型数据库: MongoDB
3. 列存储数据库: HBase、Cassandra
4. 图关系数据库:Neo4J

### Redis   ==Re== mote ==Di==ctionary ==S==erver，即远程字典服务

官网介绍:Redis 是一个开源（BSD许可）的，内存中的数据结构存储系统，它可以用作数据库、缓存和消息中间件。 它支持多种类型的数据结构，如 字符串（strings）， 散列（hashes）， 列表（lists）， 集合（sets）， 有序集合（sorted sets） 与范围查询， bitmaps， hyperloglogs 和 地理空间（geospatial） 索引半径查询。 Redis 内置了 复制（replication），LUA脚本（Lua scripting）， LRU驱动事件（LRU eviction），事务（transactions） 和不同级别的 磁盘持久化（persistence）， 并通过 Redis哨兵（Sentinel）和自动分区（Cluster）提供高可用性（high availability）。

redis基于内存操作，cpu不是redis的瓶颈。redis的瓶颈是机器的内存和网络带宽

###  Linux下安装Redis

```bash
# 使用wget命令下载redis源码
wget http://download.redis.io/releases/redis-5.0.8.tar.gz
# 解压源码
tar -zxvf redis-5.0.8.tar.gz
# 进入解压目录进行编译
cd redis-5.0.8
# 安装gcc环境
yum install -y gcc-c++
# 编译
make
# 安装
make install
# 修改 redis.conf 配置文件，把daemonize 改为 yes
# 启动redis
redis-server /user/local/redis-5.0.8/redis.conf
# 启动后用redis客户端连接到server
redis-cli -p 6379
# 测试是否连接成功,当收到 ‘Pong’说明连接成功
ping
# 从客户端关闭server
127.0.0.1:6379> shutdown
not connected> exit
```

### 压力测试工具:

#### 官方工具  -->  redis-benchmark

| 序号 | 选项      | 描述                                       | 默认值    |
| ---- | --------- | ------------------------------------------ | --------- |
| 1    | **-h**    | 指定服务器主机名                           | 127.0.0.1 |
| 2    | **-p**    | 指定服务器端口                             | 6379      |
| 3    | **-s**    | 指定服务器 socket                          |           |
| 4    | **-c**    | 指定并发连接数                             | 50        |
| 5    | **-n**    | 指定请求数                                 | 10000     |
| 6    | **-d**    | 以字节的形式指定 SET/GET 值的数据大小      | 2         |
| 7    | **-k**    | 1=keep alive 0=reconnect                   | 1         |
| 8    | **-r**    | SET/GET/INCR 使用随机 key, SADD 使用随机值 |           |
| 9    | **-P**    | 通过管道传输 请求                          | 1         |
| 10   | **-q**    | 强制退出 redis。仅显示 query/sec 值        |           |
| 11   | **--csv** | 以 CSV 格式输出                            |           |
| 12   | **-l**    | 生成循环，永久执行测试                     |           |
| 13   | **-t**    | 仅运行以逗号分隔的测试命令列表。           |           |
| 14   | **-I**    | Idle 模式。仅打开 N 个 idle 连接并等待。   |           |

#### 简单性能测试:

```bash
# 100个并发连接进行100000次请求
redis-benchmark -h localhost -p 6379 -c 100 -n 100000
```

### 常用命令

#### 通用命令

```bash
# 默认是16个数据库，切换数据库(0-15)
127.0.0.1:6379[3]> select 3  # 切换数据库
OK
127.0.0.1:6379[3]> dbsize # 统计数据库中key个数 
(integer) 2
127.0.0.1:6379[3]> keys * # 查看数据库中的所有key
1) "out"
2) "money"
127.0.0.1:6379[3]> flushdb # 清空当前数据库
OK
127.0.0.1:6379[3]> flushall # 清空所有数据库
OK
127.0.0.1:6379[3]> exists money # 查看key是否存在(返回0为不存在，1为存在)
(integer) 1
127.0.0.1:6379[3]> move money 0 # 把key迁移到其他数据库
(integer) 1
127.0.0.1:6379[3]> keys *  # 迁移成功
1) "out"
127.0.0.1:6379[3]>  expire out 10000 # 对key设置过期时间10000s
(integer) 1
127.0.0.1:6379[3]> ttl out # 查看key的剩余存活时间
(integer) 9997
127.0.0.1:6379[3]> type out # 查看key所存value的类型
string
```

#### 五大基本数据类型

###### String字符串类型

```bash
127.0.0.1:6379[3]> set k1 v1 # 设置值
OK
127.0.0.1:6379[3]> get k1 # 获取值
"v1"
127.0.0.1:6379[3]> append k1 hello # 给指定key的value追加字符串
(integer) 7
127.0.0.1:6379[3]> get k1 # 追加成功
"v1hello"
127.0.0.1:6379[3]> append k2 v2 #追加时如果key不存在则相当于set k-v
(integer) 2
127.0.0.1:6379[3]> get k2 # 设置成功
"v2"
```

```bash
127.0.0.1:6379[3]> set money 0 #设置余额初始值为数字
OK
127.0.0.1:6379[3]> incr money # 增加1
(integer) 1
127.0.0.1:6379[3]> decr money # 减少1
(integer) 0
127.0.0.1:6379[3]> get money # 查看修改结果
"0"
127.0.0.1:6379[3]> incrby money 100 # 增加指定步长
(integer) 100
127.0.0.1:6379[3]> decrby money 50 # 减少指定步长
(integer) 50
127.0.0.1:6379[3]> get money # 查看修改结果
"50"
```

```bash
127.0.0.1:6379[3]> get k1 #查看k1
"v1hello"
127.0.0.1:6379[3]> getrange k1 1 3 # 截取字符串
"1he"
127.0.0.1:6379[3]> getrange k1 0 -1 #截取全部字符串(-1)
"v1hello"
127.0.0.1:6379[3]> set k2 abcd 
OK
127.0.0.1:6379[3]> setrange k2 1 xx # 替换字符串
(integer) 4
127.0.0.1:6379[3]> get k2 # 替换成功
"axxd
```

```bash
127.0.0.1:6379[3]> setex k3 100 hello #设置值带过期时间
OK
127.0.0.1:6379[3]> ttl k3 # 设置过期时间成功
(integer) 96
127.0.0.1:6379[3]> setnx db redis # 如果不存在则创建，创建成功返回1
(integer) 1
127.0.0.1:6379[3]> get db #key不存在，创建成功
"redis"
127.0.0.1:6379[3]> setnx db redis #key已存在，创建失败返回0
(integer) 0
127.0.0.1:6379> mset k1 v1 k2 v2 k3 v3 #同时设置多个值
OK
127.0.0.1:6379> mget k1 k2 k3 # 同时获取多个值
1) "v1"
2) "v2"
3) "v3"
127.0.0.1:6379> msetnx k1 v1 k4 v4 # msetnx是一个原子命令，要么一起成功，要么一起失败
(integer) 0
127.0.0.1:6379> keys * # 查看所有key发现由于k1已存在，所以k4没有被设置
1) "k3"
2) "k1"
3) "k2"
```

```bash
127.0.0.1:6379> getset db redis #先获取value再设置value，如果原值不存在则返回null
(nil)
127.0.0.1:6379> get db #设置成功
"redis"
127.0.0.1:6379> getset db mongodb #如果原值存在则返回原值并设置新值
"redis"
127.0.0.1:6379> get db #设置成功
"mongodb"
```

###### List列表类型

```bash
127.0.0.1:6379[3]> lpush mylist one # 左插
(integer) 1
127.0.0.1:6379[3]> lpush mylist two
(integer) 2
127.0.0.1:6379[3]> lpush mylist three
(integer) 3
127.0.0.1:6379[3]> lrange mylist 0 -1 # 获取list中的值
1) "three"
2) "two"
3) "one"
127.0.0.1:6379[3]> lrange mylist 0 1  # 获取list中指定区间的值
1) "three"
2) "two"
127.0.0.1:6379[3]> rpush mylist hello # 右插
(integer) 4
127.0.0.1:6379[3]> get mylist # 尝试发现list类型不能使用get命令来获取整个list中的值
(error) WRONGTYPE Operation against a key holding the wrong kind of value
127.0.0.1:6379[3]> lrange mylist 0 -1 #list类型必须使用lrange来获取list中的值
1) "three"
2) "two"
3) "one"
4) "hello"
```

```bash
127.0.0.1:6379[3]> lpop mylist #从左边弹出一个元素
"three"
127.0.0.1:6379[3]> rpop mylist # 从右边弹出一个元素
"hello"
127.0.0.1:6379[3]> lrange mylist 0 -1 # 查看弹出两个元素后的list中值
1) "two"
2) "one"
127.0.0.1:6379[3]> lindex mylist 0 #根据下标获取list中值
"two"
127.0.0.1:6379[3]> lindex mylist 1 
"one"
```

```bash
127.0.0.1:6379[3]> lpush mylist one #左插一个重复的值
(integer) 3
127.0.0.1:6379[3]> lrange mylist 0 -1 #查看当前list中的值
1) "one"
2) "two"
3) "one"
127.0.0.1:6379[3]> llen mylist # 查看列表的长度
(integer) 3
127.0.0.1:6379[3]> lrem mylist 1 one # 移除列表中的一个one
(integer) 1
127.0.0.1:6379[3]> lrange mylist 0 -1 #查看移除后的结果
1) "two"
2) "one"
```

```bash
127.0.0.1:6379[3]> rpush mylist v1
(integer) 1
127.0.0.1:6379[3]> rpush mylist v2
(integer) 2
127.0.0.1:6379[3]> rpush mylist v3 #右插3个元素
(integer) 3
127.0.0.1:6379[3]> ltrim mylist 1 2 #截取list
OK
127.0.0.1:6379[3]> lrange mylist 0 -1 #查看截取后的结果
1) "v2"
2) "v3"
```

```bash
127.0.0.1:6379[3]> rpush mylist v1 v2 v3 v4 # 右插4个元素
(integer) 4
127.0.0.1:6379[3]> lrange mylist 0 -1
1) "v1"
2) "v2"
3) "v3"
4) "v4"
127.0.0.1:6379[3]> rpoplpush mylist list #从右边弹出一个元素左插入另一个list中
"v4"
127.0.0.1:6379[3]> rpoplpush mylist list #再次执行
"v3"
127.0.0.1:6379[3]> lrange mylist 0 -1 #查看源list结果
1) "v1"
2) "v2"
127.0.0.1:6379[3]> lrange list 0 -1 #查看目标list结果
1) "v3"
2) "v4"
```

```bash
127.0.0.1:6379[3]> exists list #确保list不存在
(integer) 0
127.0.0.1:6379[3]> rpush list v1 #右插一个元素
(integer) 1
127.0.0.1:6379[3]> lset list 0 tttt # 把list下标0的位置替换为tttt
OK
127.0.0.1:6379[3]> lrange list 0 -1 # 查看替换后结果
1) "tttt"
127.0.0.1:6379[3]> lset list 1 v2 # 不存在的下标替换会报错
(error) ERR index out of range
```

```bash
127.0.0.1:6379[3]> rpush mylist v1 v2 v3 v4 #右插4个元素
(integer) 4
127.0.0.1:6379[3]> lrange mylist 0 -1
1) "v1"
2) "v2"
3) "v3"
4) "v4"
127.0.0.1:6379[3]> linsert mylist before v2 0-0 #在list中指定的值前面插入
(integer) 5
127.0.0.1:6379[3]> lrange mylist 0 -1 #查看插入后结果
1) "v1"
2) "0-0"
3) "v2"
4) "v3"
5) "v4"
127.0.0.1:6379[3]> linsert mylist after v4 aa # 往list中指定的值后面插入
(integer) 6
127.0.0.1:6379[3]> lrange mylist 0 -1 # 查看插入结果
1) "v1"
2) "0-0"
3) "v2"
4) "v3"
5) "v4"
6) "aa"
```

总结:

* list由链表实现。列表中的值是有序的，可以通过索引下标来获取某个元素，列表中的值可以重复

###### Set集合数据类型

set中的值是不能重复的

```bash
127.0.0.1:6379[6]> sadd myset hello   #向集合中添加元素
(integer) 1
127.0.0.1:6379[6]> sadd myset world
(integer) 1
127.0.0.1:6379[6]> smembers myset  #查看集合中所有元素
1) "world"
2) "hello"
127.0.0.1:6379[6]> sismember myset hello #判断是否为集合中元素(是返回1)
(integer) 1
127.0.0.1:6379[6]> sismember myset 110 #不是返回0
(integer) 0
```

```bash
127.0.0.1:6379[6]> scard myset   # 获取set集合中的元素个数
(integer) 2
```

```bash
127.0.0.1:6379[6]> srem myset hello #移除set中指定元素
(integer) 1
127.0.0.1:6379[6]> smembers myset   #可以看到移除成功
1) "world"
```

```bash
127.0.0.1:6379[6]> smembers myset #查看当前set中所有元素
1) "002"
2) "001"
3) "world"
4) "003"
5) "004"
127.0.0.1:6379[6]> srandmember myset #随机抽出一个元素
"003"
127.0.0.1:6379[6]> srandmember myset 2 #随机抽出指定个数的元素
1) "001"
2) "003"
```

```bash
127.0.0.1:6379[6]> smove myset myset2 world #将一个set中指定值移动到另一个set中
(integer) 1
127.0.0.1:6379[6]> smembers myset  #查看源set
1) "003"
2) "004"
3) "002"
4) "001"
127.0.0.1:6379[6]> smembers myset2 #查看目标set
1) "world"
```

```bash
########################### 集合运算 ######################
127.0.0.1:6379[6]> sadd myset 001 002 003 #向myset中添加3个元素
(integer) 3
127.0.0.1:6379[6]> sadd myset2 003 004 005 #向myset2中添加3个元素
(integer) 3
127.0.0.1:6379[6]> sdiff myset myset2 # 计算myset2相对于myset的差集
1) "002"
2) "001"
127.0.0.1:6379[6]> sinter myset myset2 # 计算myset和myset2的交集
1) "003"
127.0.0.1:6379[6]> sunion myset myset2 # 计算myset和myset2的并集
1) "004"
2) "001"
3) "003"
4) "002"
5) "005"
# 交集可以用于计算共同关注，差集可以用于计算还没有关注的人
```

###### Hash(哈希，用于存储对象)

hash结构存储的是一个key-map结构

```bash
127.0.0.1:6379[6]> hset myhash name ak  #往hash结构中set值
(integer) 1
127.0.0.1:6379[6]> hget myhash name #获取一个字段的值
"ak"
127.0.0.1:6379[6]> hmset myhash age 27 address 0001 #set多个kye-value
OK
127.0.0.1:6379[6]> hmget myhash age address #获取多个字段值
1) "27"
2) "0001"
127.0.0.1:6379[6]> hgetall myhash #获取全部key-value
1) "name"
2) "ak"
3) "age"
4) "27"
5) "address"
6) "0001"
127.0.0.1:6379[6]> hdel myhash address #删除指定的key。此时对应的value也就消失了
(integer) 1
127.0.0.1:6379[6]> hgetall myhash  #删除成功
1) "name"
2) "ak"
3) "age"
4) "27"
```

```bash
127.0.0.1:6379[6]> hgetall myhash 
1) "name"
2) "ak"
3) "age"
4) "27"
127.0.0.1:6379[6]> hlen myhash # 查看hash中字段数量
(integer) 2
127.0.0.1:6379[6]> hexists myhash name # 判断hash中指定字段是否存在(1为已存在)
(integer) 1
127.0.0.1:6379[6]> hexists myhash address # 0为不存在
(integer) 0
127.0.0.1:6379[6]> hkeys myhash # 只获取hash中所有key
1) "name"
2) "age"
127.0.0.1:6379[6]> hvals myhash # 只获取hash中所有value
1) "ak"
2) "27"
```

```bash
# incr
127.0.0.1:6379[6]> hset myhash age 23
(integer) 1
127.0.0.1:6379[6]> hincrby myhash age 1 #给指定字段增加指定的值
(integer) 24
127.0.0.1:6379[6]> hincrby myhash age -1 #给指定字段减少指定的值(hash中没有decrby命令)
(integer) 23
127.0.0.1:6379[6]> hsetnx myhash name ak #不存在则设置
(integer) 1
127.0.0.1:6379[6]> hsetnx myhash name ak #存在则设置失败
(integer) 0
```

###### Zset(有序集合)

应用场景:排行榜、成绩排序

```bash
127.0.0.1:6379[6]> zadd myzset 1 one 2 two 3 three #向zset中添加元素
(integer) 3
127.0.0.1:6379[6]> zrange myzset 0 -1 #查看zset中的所有元素
1) "one"
2) "two"
3) "three"
127.0.0.1:6379[6]> zadd salary 2500 xiaohong 5000 zhangsan 500 kuang 
(integer) 3
127.0.0.1:6379[6]> zrangebyscore salary -inf +inf #在负无穷到正无穷范围内对员工薪资排序
1) "kuang"
2) "xiaohong"
3) "zhangsan"
127.0.0.1:6379[6]> zrangebyscore salary -inf +inf  withscores  #显示全部员工并附带薪资
1) "kuang"
2) "500"
3) "xiaohong"
4) "2500"
5) "zhangsan"
6) "5000"
127.0.0.1:6379[6]> zrangebyscore salary -inf 2500 withscores    # 显示工资小于2500的员工，按薪资升序排序
1) "kuang"
2) "500"
3) "xiaohong"
4) "2500"
```

```bash
127.0.0.1:6379[6]> zadd myset 1 hello 2 world 3 ak #添加3个元素
(integer) 3
127.0.0.1:6379[6]> zcount myset 1 3 #统计zset指定区间的元素数量
(integer) 3
127.0.0.1:6379[6]> zcount myset 1 2 #统计zset指定区间的元素数量
(integer) 2
```

#### 三种特殊数据类型

##### geospatial

共6个命令:

* geoadd: 添加地理坐标
* geopos: 获取地理坐标
* geodist: 获取距离
* georadius: 获取附近的坐标
* georadiusbymember: 获取元素附近坐标
* geohash: 获取元素的geohash值

```bash
# 添加地理坐标(经度，纬度)
127.0.0.1:6379[6]> geoadd china:city 116.40 39.90 beijing 121.47 31.23 shanghai 106.50 29.53 chongqing 114.05 22.52 shenzhen 120.16 60.24 hangzhou 108.96 34.26 xian
(integer) 6
# 获取地理坐标(经度，纬度)
127.0.0.1:6379[6]> geopos china:city beijing shanghai 
1) 1) "116.39999896287918091"
   2) "39.90000009167092543"
2) 1) "121.47000163793563843"
   2) "31.22999903975783553"
```

单位:

* m 表示单位为米
* km 表示单位为千米
* mi 表示单位为英里
* ft 表示单位为英尺

```bash
# 查看两个坐标之间的距离
127.0.0.1:6379[6]> geodist china:city beijing shanghai km 
"1067.3788"
```

```bash
# 找出指定key集合中与给定坐标距离不超过给定距离的元素
127.0.0.1:6379[6]> georadius china:city 110 30 500 km
1) "chongqing"
2) "xian"
# 可追加参数:
# withdist: 返回位置与给定坐标的距离
# withcoord: 返回位置元素的经纬值
# withhash: 返回元素经过geohash后的值，官方文档标注用处不大
127.0.0.1:6379[6]> georadius china:city 110 30 500 km withcoord 
1) 1) "chongqing"
   2) 1) "106.49999767541885376"
      2) "29.52999957900659211"
2) 1) "xian"
   2) 1) "108.96000176668167114"
      2) "34.25999964418929977"
127.0.0.1:6379[6]> georadius china:city 110 30 500 km withdist
1) 1) "chongqing"
   2) "341.9374"
2) 1) "xian"
   2) "483.8340"
127.0.0.1:6379[6]> georadius china:city 110 30 500 km withdist withcoord count 1 # 筛选出指定的结果
1) 1) "chongqing"
   2) "341.9374"
   3) 1) "106.49999767541885376"
      2) "29.52999957900659211"
```

```bash
# 找出指定key集合中与给定元素距离不超过给定距离的元素
127.0.0.1:6379[6]> georadiusbymember china:city beijing 1000 km
1) "beijing"
2) "xian"
```

```bash
# 获取指定元素的geohash值
127.0.0.1:6379[6]> geohash china:city beijing shanghai
1) "wx4fbxxfke0"
2) "wtw3sj5zbj0"
```

```bash
# geo底层是用zset实现的，所以可以用zset命令来操作geo
127.0.0.1:6379[6]> zrange china:city 0 -1 # 查看地图中全部元素
1) "chongqing"
2) "xian"
3) "shenzhen"
4) "shanghai"
5) "beijing"
6) "hangzhou"
127.0.0.1:6379[6]> zrem china:city beijing  # 移除指定元素
(integer) 1
127.0.0.1:6379[6]> zrange china:city 0 -1
1) "chongqing"
2) "xian"
3) "shenzhen"
4) "shanghai"
5) "hangzhou"
```

##### hyperloglog

redis 2.8.9版本新增了Hyperloglog数据结构，用于基数统计。基数统计指的是统计一个集合中所有不重复的数字。

* 使用场景:统计网页UV（一个人访问网站多次，但还是算作一个人）。传统的网页UV统计方式是使用一个set来保存用户id，然后统计set中元素个数的方式，但是UV统计是为了计数，而不是为了保存用户id，会造成空间浪费

* 优点:所占用的内存是固定的，并且最多能满足2^64个不同元素的计数，而仅需要12KB内存
* 缺点:有0.81%的错误率。如果允许容错则使用hyperloglog，如果需要精确统计则使用set集合

```bash
# 创建一组元素mykey
127.0.0.1:6379[6]> pfadd mykey 0001 0002 0003 0004 0005 0006 0007
(integer) 1
# 对mykey进行基数统计
127.0.0.1:6379[6]> pfcount mykey
(integer) 7
# 创建第二组元素mykey2
127.0.0.1:6379[6]> pfadd mykey2 0001 0007 0008 0009 0010
(integer) 1
127.0.0.1:6379[6]> pfcount mykey2
(integer) 5
# 合并两组元素: mykey3 = mykey + mykey2 
127.0.0.1:6379[6]> pfmerge mykey3 mykey mykey2
OK
# 查看合并后集合的并集数量
127.0.0.1:6379[6]> pfcount mykey3
(integer) 10
```

##### bitmaps(位图)

按位存储信息，每位只有0和1两个状态。可以用于统计有两个状态的信息，比如活跃或不活跃、登录或未登录。

如果使用bitmaps统计一年的打卡情况，则365天只需要365bit，1字节=8bit，则只需要46个字节左右

```bash
#依次设置一周中每一天的打卡情况
127.0.0.1:6379[6]> setbit sign 0 1
(integer) 0
127.0.0.1:6379[6]> setbit sign 1 0
(integer) 0
127.0.0.1:6379[6]> setbit sign 2 1
(integer) 0
127.0.0.1:6379[6]> setbit sign 3 0
(integer) 0
127.0.0.1:6379[6]> setbit sign 4 0
(integer) 0
127.0.0.1:6379[6]> setbit sign 5 1
(integer) 0
127.0.0.1:6379[6]> setbit sign 6 1
(integer) 0
# 统计一周的打卡情况
127.0.0.1:6379[6]> bitcount sign
(integer) 4
# 查看星期日的打卡情况:已打卡
127.0.0.1:6379[6]> getbit sign 6
(integer) 1
# 查看星期五的打卡情况:未打卡
127.0.0.1:6379[6]> getbit sign 4
(integer) 0
```

### 事务

redis事务的本质就是一组命令的集合。redis单条命令能保证原子性但是事务不保证原子性。redis事务通过multi命令开启，开启事务后所有命令都放入队列中缓存，通过exec命令提交事务，事务中的任何一条命令执行失败，其余的命令仍然会被执行，在事务收集命令的过程中，其他客户端提交的命令不会被插入到当前事务的命令队列中

#### 一个事务从开启到执行的三个阶段:

* 开启事务:MULTI
* 命令入队
* 提交事务:EXEC 或放弃事务:DISCARD

```bash
127.0.0.1:6379[3]> multi   #开启事务
OK
127.0.0.1:6379[3]> set k1 v1
QUEUED
127.0.0.1:6379[3]> set k2 v2
QUEUED
127.0.0.1:6379[3]> get k1
QUEUED
127.0.0.1:6379[3]> exec  #执行事务
1) OK
2) OK
3) "v1"
```

```bash
127.0.0.1:6379[3]> multi     #开启事务
OK
127.0.0.1:6379[3]> set k1 v1
QUEUED
127.0.0.1:6379[3]> set k2 v2
QUEUED
127.0.0.1:6379[3]> discard   #放弃事务
OK
127.0.0.1:6379[3]> get k1  #事务并没有执行，值是空的
(nil)
```

#### 事务中的编译型异常与运行时异常:

* 编译型异常:事务队列里的某条命令有语法错误，则整个事务都不会执行

```bash
127.0.0.1:6379[3]> multi  #开启事务
OK
127.0.0.1:6379[3]> set k1 v1
QUEUED
127.0.0.1:6379[3]> set k2 v2
QUEUED
127.0.0.1:6379[3]> setget k1 #事务队列中输入了语法错误的命令
(error) ERR unknown command 'setget'
127.0.0.1:6379[3]> exec  #执行事务报错，事务被放弃了
(error) EXECABORT Transaction discarded because of previous errors.
127.0.0.1:6379[3]> get k1   #事务并没有被执行，值是空的
(nil)
```

* 运行时异常:事务队列中的命令语法全部正确，而是执行时出的错，则错误命令抛出异常，剩余的其他命令都可以被正常执行

```bash
127.0.0.1:6379[3]> multi  #开启事务
OK
127.0.0.1:6379[3]> set k1 v1
QUEUED
127.0.0.1:6379[3]> incr k1 #写一条执行时会失败的命令
QUEUED
127.0.0.1:6379[3]> set k2 v2
QUEUED
127.0.0.1:6379[3]> exec #提交事务
1) OK
2) (error) ERR value is not an integer or out of range   #只有这条出错，其余命令全部被执行
3) OK
```

### 使用 watch 命令作为redis的乐观锁

* watch命令用于事务开启前对指定key进行监视，如果在事务中被监视的值被其他线程所修改，则整个事务会失败返回一个null。watch命令底层使用了cas方式去更新值。

* 当执行exec命令时，无论事务是否成功，对所有key的监视都会取消。也可以使用命令unwatch手动取消对key的监视

```bash
127.0.0.1:6379[3]> set money 100 #钱包初始余额为100
OK
127.0.0.1:6379[3]> set out 0
OK
127.0.0.1:6379[3]> watch money #开启监视余额
OK
127.0.0.1:6379[3]> multi
OK
127.0.0.1:6379[3]> decrby money 20 #减少钱包余额
QUEUED
127.0.0.1:6379[3]> incrby out 20
QUEUED
127.0.0.1:6379[3]> exec
(nil)  #事务执行期间，余额已经被其他线程修改过了，cas失败所以事务执行失败
127.0.0.1:6379[3]> get money
"200"  #余额已经被其他线程修改为200了
```

使用watch命令执行事务正常更新的情况:

```bash
127.0.0.1:6379[3]> set money 100 #钱包余额为100
OK
127.0.0.1:6379[3]> set out 0
OK
127.0.0.1:6379[3]> watch money #开启监视余额
OK
127.0.0.1:6379[3]> multi
OK
127.0.0.1:6379[3]> decrby money 20 #减少钱包余额
QUEUED
127.0.0.1:6379[3]> incrby out 20
QUEUED
127.0.0.1:6379[3]> exec 
1) (integer) 80   #对比监视的值，cas成功所以事务执行成功
2) (integer) 20
```

### Jedis

#### redis官方推荐的java连接开发工具

#### jedis的使用步骤

1. 导入依赖

```xml
<!--jedis-->
<dependency>
    <groupId>redis.clients</groupId>
    <artifactId>jedis</artifactId>
    <version>3.2.0</version>
</dependency>
<!--fastjson-->
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.62</version>
</dependency>
```

2. 在 maven 项目中编码测试:

```java
public class TestJedis {
    public static void main(String[] args) {
        Jedis jedis = new Jedis("192.168.200.40", 6379);
        System.out.println(jedis.ping());
    }
}
// 输出:  PONG
```

#### Jedis常用api

jedis的命令和redis原生命令基本相同

#### jedis中执行事务

```java
public class JedisDemo {
    public static void main(String[] args) {
        JedisPoolConfig poolConfig = new JedisPoolConfig();
        JedisPool jedisPool = new JedisPool(poolConfig, "192.168.11.112", 6379, 0, "123456", false);
        Jedis jedis = jedisPool.getResource();

        JsonObject jsonObject = new JsonObject();
        jsonObject.addProperty("hello", "world");
        //开启事务
        Transaction multi = jedis.multi();
        try {
            multi.set("json".getBytes(), jsonObject.getAsString().getBytes());
            //除0异常
            int i = 100 / 0;
            multi.exec();
        } catch (Exception e) {
            e.printStackTrace();
            //如果出现异常则放弃事务
            multi.discard();
        } finally {
            //关闭客户端
            jedis.close();
        }
    }
}
```

### SpringBoot整合Redis

#### 说明:

SpringBoot 2.x后把jedis替换成了lettuce。

jedis:采用直连方式，线程模型，多个线程操作是不安全的，如果想要避免不安全，使用jedis pool连接池，更像bio模式

lettuce:采用netty，实例可以在多个线程中进行共享，不存在线程不安全的情况，可以减少线程数量，更像NIO模型，比较高效

#### 设置RedisTemplate的序列化方式

```java
import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

@Configuration
public class RedisSerializeConfig {
    /**
     * 修改redisTemplate序列化方式
     *
     * @return
     */
    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, Object> redisTemplate = new RedisTemplate<>();
        redisTemplate.setConnectionFactory(factory);

        // jackson序列化对象
        Jackson2JsonRedisSerializer jackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer(Object.class);
        ObjectMapper om = new ObjectMapper();
        om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        om.enableDefaultTyping(ObjectMapper.DefaultTyping.NON_FINAL);
        jackson2JsonRedisSerializer.setObjectMapper(om);

        // string序列化对象
        StringRedisSerializer stringRedisSerializer = new StringRedisSerializer();

        // key使用string的序列化方式
        redisTemplate.setKeySerializer(stringRedisSerializer);
        // value使用string的序列化方式
        redisTemplate.setValueSerializer(stringRedisSerializer);
        // hash的key使用string的序列化方式
        redisTemplate.setHashKeySerializer(stringRedisSerializer);
        // hash的value使用fastJson的序列化方式
//        redisTemplate.setHashValueSerializer(new FastJsonRedisSerializer<>(Object.class));
        redisTemplate.setHashValueSerializer(jackson2JsonRedisSerializer);
        redisTemplate.afterPropertiesSet();

        return redisTemplate;
    }
}
```



#### 对 SpringData 中的 RedisTemplate 封装形成工具类

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.util.CollectionUtils;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;

@Component
public final class RedisUtil {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    // =============================common============================

    /**
     * 指定缓存失效时间
     *
     * @param key  键
     * @param time 时间(秒)
     */
    public boolean expire(String key, long time) {
        try {
            if (time > 0) {
                redisTemplate.expire(key, time, TimeUnit.SECONDS);
            }
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 根据key 获取过期时间
     *
     * @param key 键 不能为null
     * @return 时间(秒) 返回0代表为永久有效
     */
    public long getExpire(String key) {
        return redisTemplate.getExpire(key, TimeUnit.SECONDS);
    }

    /**
     * 判断key是否存在
     *
     * @param key 键
     * @return true 存在 false不存在
     */
    public boolean hasKey(String key) {
        try {
            return redisTemplate.hasKey(key);
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 删除缓存
     *
     * @param key 可以传一个值 或多个
     */
    @SuppressWarnings("unchecked")
    public void del(String... key) {
        if (key != null && key.length > 0) {
            if (key.length == 1) {
                redisTemplate.delete(key[0]);
            } else {
                redisTemplate.delete(CollectionUtils.arrayToList(key));
            }
        }
    }

    // ============================String=============================

    /**
     * 普通缓存获取
     *
     * @param key 键
     * @return 值
     */
    public Object get(String key) {
        return key == null ? null : redisTemplate.opsForValue().get(key);
    }

    /**
     * 普通缓存放入
     *
     * @param key   键
     * @param value 值
     * @return true成功 false失败
     */

    public boolean set(String key, Object value) {
        try {
            redisTemplate.opsForValue().set(key, value);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 普通缓存放入并设置时间
     *
     * @param key   键
     * @param value 值
     * @param time  时间(秒) time要大于0 如果time小于等于0 将设置无限期
     * @return true成功 false 失败
     */

    public boolean set(String key, Object value, long time) {
        try {
            if (time > 0) {
                redisTemplate.opsForValue().set(key, value, time, TimeUnit.SECONDS);
            } else {
                set(key, value);
            }
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 递增
     *
     * @param key   键
     * @param delta 要增加几(大于0)
     */
    public long incr(String key, long delta) {
        if (delta < 0) {
            throw new RuntimeException("递增因子必须大于0");
        }
        return redisTemplate.opsForValue().increment(key, delta);
    }

    /**
     * 递减
     *
     * @param key   键
     * @param delta 要减少几(小于0)
     */
    public long decr(String key, long delta) {
        if (delta < 0) {
            throw new RuntimeException("递减因子必须大于0");
        }
        return redisTemplate.opsForValue().increment(key, -delta);
    }

    // ================================Map=================================

    /**
     * HashGet
     *
     * @param key  键 不能为null
     * @param item 项 不能为null
     */
    public Object hget(String key, String item) {
        return redisTemplate.opsForHash().get(key, item);
    }

    /**
     * 获取hashKey对应的所有键值
     *
     * @param key 键
     * @return 对应的多个键值
     */
    public Map<Object, Object> hmget(String key) {
        return redisTemplate.opsForHash().entries(key);
    }

    /**
     * HashSet
     *
     * @param key 键
     * @param map 对应多个键值
     */
    public boolean hmset(String key, Map<String, Object> map) {
        try {
            redisTemplate.opsForHash().putAll(key, map);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * HashSet 并设置时间
     *
     * @param key  键
     * @param map  对应多个键值
     * @param time 时间(秒)
     * @return true成功 false失败
     */
    public boolean hmset(String key, Map<String, Object> map, long time) {
        try {
            redisTemplate.opsForHash().putAll(key, map);
            if (time > 0) {
                expire(key, time);
            }
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 向一张hash表中放入数据,如果不存在将创建
     *
     * @param key   键
     * @param item  项
     * @param value 值
     * @return true 成功 false失败
     */
    public boolean hset(String key, String item, Object value) {
        try {
            redisTemplate.opsForHash().put(key, item, value);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 向一张hash表中放入数据,如果不存在将创建
     *
     * @param key   键
     * @param item  项
     * @param value 值
     * @param time  时间(秒) 注意:如果已存在的hash表有时间,这里将会替换原有的时间
     * @return true 成功 false失败
     */
    public boolean hset(String key, String item, Object value, long time) {
        try {
            redisTemplate.opsForHash().put(key, item, value);
            if (time > 0) {
                expire(key, time);
            }
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 删除hash表中的值
     *
     * @param key  键 不能为null
     * @param item 项 可以使多个 不能为null
     */
    public void hdel(String key, Object... item) {
        redisTemplate.opsForHash().delete(key, item);
    }

    /**
     * 判断hash表中是否有该项的值
     *
     * @param key  键 不能为null
     * @param item 项 不能为null
     * @return true 存在 false不存在
     */
    public boolean hHasKey(String key, String item) {
        return redisTemplate.opsForHash().hasKey(key, item);
    }

    /**
     * hash递增 如果不存在,就会创建一个 并把新增后的值返回
     *
     * @param key  键
     * @param item 项
     * @param by   要增加几(大于0)
     */
    public double hincr(String key, String item, double by) {
        return redisTemplate.opsForHash().increment(key, item, by);
    }

    /**
     * hash递减
     *
     * @param key  键
     * @param item 项
     * @param by   要减少记(小于0)
     */
    public double hdecr(String key, String item, double by) {
        return redisTemplate.opsForHash().increment(key, item, -by);
    }

    // ============================set=============================

    /**
     * 根据key获取Set中的所有值
     *
     * @param key 键
     */
    public Set<Object> sGet(String key) {
        try {
            return redisTemplate.opsForSet().members(key);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /**
     * 根据value从一个set中查询,是否存在
     *
     * @param key   键
     * @param value 值
     * @return true 存在 false不存在
     */
    public boolean sHasKey(String key, Object value) {
        try {
            return redisTemplate.opsForSet().isMember(key, value);
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 将数据放入set缓存
     *
     * @param key    键
     * @param values 值 可以是多个
     * @return 成功个数
     */
    public long sSet(String key, Object... values) {
        try {
            return redisTemplate.opsForSet().add(key, values);
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }

    /**
     * 将set数据放入缓存
     *
     * @param key    键
     * @param time   时间(秒)
     * @param values 值 可以是多个
     * @return 成功个数
     */
    public long sSetAndTime(String key, long time, Object... values) {
        try {
            Long count = redisTemplate.opsForSet().add(key, values);
            if (time > 0)
                expire(key, time);
            return count;
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }

    /**
     * 获取set缓存的长度
     *
     * @param key 键
     */
    public long sGetSetSize(String key) {
        try {
            return redisTemplate.opsForSet().size(key);
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }

    /**
     * 移除值为value的
     *
     * @param key    键
     * @param values 值 可以是多个
     * @return 移除的个数
     */

    public long setRemove(String key, Object... values) {
        try {
            Long count = redisTemplate.opsForSet().remove(key, values);
            return count;
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }

    // ===============================list=================================

    /**
     * 获取list缓存的内容
     *
     * @param key   键
     * @param start 开始
     * @param end   结束 0 到 -1代表所有值
     */
    public List<Object> lGet(String key, long start, long end) {
        try {
            return redisTemplate.opsForList().range(key, start, end);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /**
     * 获取list缓存的长度
     *
     * @param key 键
     */
    public long lGetListSize(String key) {
        try {
            return redisTemplate.opsForList().size(key);
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }

    /**
     * 通过索引 获取list中的值
     *
     * @param key   键
     * @param index 索引 index>=0时， 0 表头，1 第二个元素，依次类推；index<0时，-1，表尾，-2倒数第二个元素，依次类推
     */
    public Object lGetIndex(String key, long index) {
        try {
            return redisTemplate.opsForList().index(key, index);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /**
     * 将list放入缓存
     *
     * @param key   键
     * @param value 值
     */
    public boolean lSet(String key, Object value) {
        try {
            redisTemplate.opsForList().rightPush(key, value);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 将list放入缓存
     *
     * @param key   键
     * @param value 值
     * @param time  时间(秒)
     */
    public boolean lSet(String key, Object value, long time) {
        try {
            redisTemplate.opsForList().rightPush(key, value);
            if (time > 0)
                expire(key, time);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }

    }

    /**
     * 将list放入缓存
     *
     * @param key   键
     * @param value 值
     * @return
     */
    public boolean lSet(String key, List<Object> value) {
        try {
            redisTemplate.opsForList().rightPushAll(key, value);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }

    }

    /**
     * 将list放入缓存
     *
     * @param key   键
     * @param value 值
     * @param time  时间(秒)
     * @return
     */
    public boolean lSet(String key, List<Object> value, long time) {
        try {
            redisTemplate.opsForList().rightPushAll(key, value);
            if (time > 0)
                expire(key, time);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 根据索引修改list中的某条数据
     *
     * @param key   键
     * @param index 索引
     * @param value 值
     * @return
     */

    public boolean lUpdateIndex(String key, long index, Object value) {
        try {
            redisTemplate.opsForList().set(key, index, value);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 移除N个值为value
     *
     * @param key   键
     * @param count 移除多少个
     * @param value 值
     * @return 移除的个数
     */

    public long lRemove(String key, long count, Object value) {
        try {
            Long remove = redisTemplate.opsForList().remove(key, count, value);
            return remove;
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }
}
```

### redis配置文件详解

#### 单位

![image-20201127111436122](../../static/image-20201127111436122.png)

#### 引入其他配置文件

![image-20201127112105803](../../static/image-20201127112105803.png)

#### 网络设置

![image-20201127140007903](../../static/image-20201127140007903.png)

```bash
bind 127.0.0.1		#绑定ip，远程访问可以设置本机ip

protected-mode yes		#开启保护模式，只允许绑定的ip访问

port 6379		#端口
```

#### 通用

![image-20201127140506568](../../static/image-20201127140506568.png)

![image-20201127140627594](../../static/image-20201127140627594.png)

#### 快照

redis是内存数据库，如果没有持久化则断电即失

![image-20201127140839737](../../static/image-20201127140839737.png)

![image-20201127141734508](../../static/image-20201127141734508.png)

持久化设置:在规定时间内执行多少次操作，则会持久化到文件dump.rdb、apendonly.aof文件

```bash
save 900 1  #900s内， 如果至少有1个key进行了修改，就进行持久化操作
save 300 10   #300s内， 如果至少有10个key进行了修改， 就进行持久化操作
save 60 10000  #60s内， 如果至少有10000个key进行了修改， 就进行持久化操作
```

#### 安全

![image-20201127142117184](../../static/image-20201127142117184.png)

```bash
192.168.200.40:6379> ping
PONG
192.168.200.40:6379> CONFIG GET requirepass		#获取redis的密码
1) "requirepass"
2) ""
192.168.200.40:6379> CONFIG SET requirepass 123456		#设置redis的密码
OK
192.168.200.40:6379> CONFIG GET requirepass		#所有命令都没有权限了
(error) NOAUTH Authentication required.
192.168.200.40:6379> ping
(error) NOAUTH Authentication required.
192.168.200.40:6379> AUTH 123456		#使用密码登录
OK
192.168.200.40:6379> CONFIG GET requirepass
1) "requirepass"
2) "123456"
```

#### 客户端

![image-20201127142159175](../../static/image-20201127142159175.png)

#### 内存管理

![image-20201127143435643](../../static/image-20201127143435643.png)

```bash
maxmemory-policy noeviction			#内存到达上限之后的处理策略

# maxmemory-policy 六种方式
volatile-lru：只对设置了过期时间的key进行LRU（默认值）
allkeys-lru ： 删除lru算法的key
volatile-random：随机删除即将过期key
allkeys-random：随机删除
volatile-ttl ： 删除即将过期的
noeviction ： 永不过期，返回错误
```

#### aof设置

![image-20201127144015769](../../static/image-20201127144015769.png)

### redis持久化

redis是内存数据库，如果不将内存中的数据保存到磁盘，一旦服务器进程退出数据库中数据就会消失，所以redis提供了两种持久化方案:一种是快照的方式，一种是类似日志追加的方式。

#### RDB持久化

RDB(Redis DataBase)持久化是一种快照存储的持久化方式，也就是将某一时刻的内存数据保存到磁盘上，在redis服务器启动时会重新加载dump.rdb文件的数据到内存中以恢复数据库

##### RDB快照触发机制:

* 满足save规则时，会自动触发rdb快照
* 执行flushall命令也会触发rdb快照
* 退出redis，也会触发rdb快照

##### RDB文件的恢复

```bash
192.168.200.40:6379> config get dir  # 先查看rdb文件的存放目录
1) "dir"
2) "/usr/local/bin"

# 把rdb文件放在上面的存放目录中，redis启动时则会自动检查dump.rdb文件并恢复其中的数据
```

##### RDB持久化的缺点

* fork子进程进行持久化需要占用一定的内存空间
* fork过程中如果意外宕机则修改的数据会丢失

#### AOF持久化

aof(Append Only File)持久化方式就是把server端收到的每一条写命令，以redis协议追加保存到appendonly.aof文件中，当redis重启时会加载aof文件并重放命令来恢复数据

##### 开启aof持久化的方式

```bash
appendonly yes    # 开启aof持久化机制
appendfilename "appendonly.aof" # 配置aof文件名
appendsync everysec # 写入策略:每秒写入一次
no-appendfsync-on-rewrite no # 默认不重写aof文件
dir ~/redis/  # aof文件保存目录
```

##### aof文件损坏的处理

在写入aof日志文件时redis服务器宕机则aof日志文件会出现格式错误，当重启redis服务器时，redis服务器会拒绝载入这个aof文件。需要使用redis-check-aof对aof文件修复后再重新启动redis，修复时可能删除部分aof日志内容，也就是修复时可能丢失一部分数据

```bash
redis-check-aof --fix appendonly.aof
```

##### 优点和缺点

* 优点:aof只是追加日志文件，对服务器性能影响较小，速度比rdb快
* 缺点:aof生成的日志文件体积较大，恢复数据速度比rdb慢

### RDB与AOF如何选择？

当RDB与AOF两种持久化方式都开启时，redis优先使用aof日志来恢复数据，因为aof文件保存的数据比rdb文件更完整

| 持久化方式 | RDB      | AOF        |
| ---------- | -------- | ---------- |
| 启动优先级 | 低       | 高         |
| 体积       | 小       | 大         |
| 恢复速度   | 快       | 慢         |
| 数据完整性 | 会丢数据 | 由策略决定 |
| 轻重       | 重       | 轻         |

### 发布与订阅(pub/sub)

redis使用publish、subscribe等命令实现了发布订阅模式。subscribe命令可以让客户端订阅任意数量的channel，每当有新消息发送到被订阅的频道时，消息就会发送给所有订阅指定频道的客户端

```bash
subscribe channel    #订阅指定的一个或多个频道
unsubscribe channel #退订指定的一个或多个频繁
publish channel message  #将信息发送到指定频道
psubscribe pattern #订阅给定的模式
punsbuscribe pattern # 退订给定的模式
pubsub  #查询发布订阅系统相关信息
```

#### 订阅

```bash
127.0.0.1:6379[3]> SUBSCRIBE zhaoning  # 订阅channel
Reading messages... (press Ctrl-C to quit)
1) "subscribe"
2) "zhaoning"
3) (integer) 1

1) "message"                              #收到消息
2) "zhaoning"
3) "hello"
```

#### 发布

```bash
127.0.0.1:6379[3]> publish zhaoning hello #将消息hello发送到执行channel
(integer) 1
```

### 主从复制

* 80%情况下都是在进行读操作，所以用主从复制架构来做读写分离，减轻单台服务器压力是架构中经常用的办法。

* 主从复制指的是将一台redis服务器的数据复制到其他redis服务器，前者称为主节点(master)，后者称为从节点(slave)。
* 数据的复制是单向的，只能由主节点数据同步到从节点

* 默认情况下每台redis服务器都是主节点。一个 主节点可以有多个从节点，而一个从节点只能有一个主节点

#### 为什么要使用主从复制？

因为单机有宕机风险，无法支撑高可用

#### 主从复制的配置

只需要配置从库，主库无需配置

```bash
127.0.0.1:6379> info replication # 查看当前库的信息
# Replication
role:master        #角色:master
connected_slaves:0 #当前没有从机
master_replid:ae7a58dd1a19dfbf53c48f06fbea01c11ef97a01
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:0
second_repl_offset:-1
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
```

复制3个配置文件，然后修改对应的信息:

1. port

2. pid名字
3. log文件名字
4. dump.rdb名字

修改完成后用这3个配置文件分别启动3个redis服务器，然后通过进程信息查看是否启动成功

![image-20201130231619775](..\..\static\image-20201130231619775.png)

##### 配置一主二从(是一个认老大的过程，一主(79)二从(80、81))

因为默认情况下每台redis服务器都是主节点，所以我们只需要配置从机就好了，先配置6380端口的从机

```bash
127.0.0.1:6380> SLAVEOF 127.0.0.1 6379  # 找谁当自己的老大
OK
127.0.0.1:6380> info replication
# Replication
role:slave             # 当前角色是从机
master_host:127.0.0.1  # 可以看到主机的信息
master_port:6379
master_link_status:up
master_last_io_seconds_ago:5
master_sync_in_progress:0
slave_repl_offset:0
slave_priority:100
slave_read_only:1
connected_slaves:0
master_replid:20a0c0758e3515e1dc02b52295eb9baad94ab31f
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:0
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:0
```

在主机6379上查看当前集群情况:

```bash
127.0.0.1:6379> info replication
# Replication
role:master
connected_slaves:1   #多了从机的配置信息
slave0:ip=127.0.0.1,port=6380,state=online,offset=378,lag=0 #从机的信息
master_replid:20a0c0758e3515e1dc02b52295eb9baad94ab31f
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:378
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:378
```

然后配置6381端口的从机

```bash
127.0.0.1:6381> SLAVEOF 127.0.0.1 6379
OK
```

再次查看主机6379端口的信息，如果两台从机都配置完后，这里会出现两个从节点。真实的主从配置应该在配置文件中配置，这样才是永久的。使用命令配置的是暂时的

```bash
127.0.0.1:6379> info replication     
# Replication
role:master
connected_slaves:2   #两台从机配置成功
slave0:ip=127.0.0.1,port=6380,state=online,offset=742,lag=0
slave1:ip=127.0.0.1,port=6381,state=online,offset=742,lag=0
master_replid:20a0c0758e3515e1dc02b52295eb9baad94ab31f
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:742
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:742
```

==主机可以写(wirte)，从机只能读(readlOnly)==

```bash
127.0.0.1:6379> set k1 v1 #6379为主机，只有主机才可以写
OK

127.0.0.1:6380> get k1   # 6380为从机，从机只能读
"v1"
127.0.0.1:6380> set k2 v2 # 从机写会报错
(error) READONLY You can't write against a read only replica.
```

测试:主机断开连接，从机依然是连接到主机的，但是没有写操作，这时如果主机回来了，从机依然可以直接获取到主机写的信息

如果是使用命令行来配置的主从，然后从机重启，这时从机就会变回主机。需要手动再次配置为从机，这时立马可以从主机中获取值

##### 复制原理:

slave成功连接到master后会发送一个sync同步命令，master接到命令后会启动后台的存盘进程，同时收集所有接收到的用于修改数据的命令。在后台进程执行完毕后，master将传送整个数据文件到slave，并完成一次完全同步

全量复制:slave服务在接收到数据库文件数据后，将其存盘并加载到内存中

增量复制:master继续将新的所有收集到的修改命令依次传给slave，完成同步

只要重新连接master，一次完全同步(全量复制)将被自动执行我们的数据一定可以在从机中看到

##### 也可以使用层层链路的方式配置主从关系

M <----- S   <--- S,这样也可以完成主从复制

如果主节点宕机了，是否可以选出一个节点继续当主节点呢？可以，使用手动配置的方式。在从节点上执行: slave of no one使自己变成主机，然后再手动配置其他机器以这台新主机为老大。

### 哨兵模式(自动选举老大的模式，从2.8开始支持)

主从切换技术的方法是:当主服务器宕机后，需要手动把一台从服务器切换为主服务器，这就需要人工干预，费时费力，还会造成一段时间内服务不可用，不推荐。更多时候我们优先考虑啥哨兵模式，redis从2.8开始正式提供了sentinel(哨兵)架构来解决这个问题

某朝篡位的自动版，能够后台监控主机是否故障，如果故障了根据投票数自动将从库切换为主库

哨兵模式是一种特殊的模式，首先redis提供了哨兵的命令，哨兵是一个独立的进程，作为进程他会独立运行，原理是哨兵通过发送命令等待服务器响应，从而监控运行的多个redis实例

这里的哨兵有两个作用：

1. 通过发送命令让redis服务器返回监控其运行状态，包括主服务器和从服务器
2. 当哨兵检测到master宕机时，会自动将slave切换为master，然后通过发布订阅模式通知其他从服务器修改配置文件，让他们切换主机

然而一个哨兵进程对redis服务器监测可能会发生单点故障， 所以可以使用多个哨兵进行监控，各个哨兵之间还会互相监测，这样就形成了多哨兵模式

假设主服务器宕机，哨兵1先检测到这个结果，系统并不会马上进行failover过程，当前仅仅是哨兵1主观认为主服务器不可用，这个现象称为主观下线，当后面的哨兵也监测到主服务器不可用，并且数量达到一定值时，那么哨兵之间就会进行一次投票，投票的结果由一个哨兵发起，进行failover故障转移操作，切换成功后，就会通过发布订阅模式，让每个哨兵把自己监控的从服务器实现切换主机，这个过程称为客观下线

##### 测试

我们目前的状态是一主二从。

1. 配置哨兵配置文件sentinel.conf

   ```bash
                    #被监控的名称  host  port 1
   sentinel monitor myredis 127.0.0.1 6379 1 
   ```

   后面的数字1，表示主机挂了，从机变成主机所需要得到的票数

2. 启动sentinel：

![image-20201201112808738](../../static/image-20201201112808738.png)

3. 将主机下线，模拟宕机，查看哨兵日志，6381从机已被选为主机

   ![image-20201201113208057](../../static/image-20201201113208057.png)

4. 这时重新开启6379服务，6379会变为6381的一个从机，这就是哨兵模式的规则

   ![image-20201201113615386](../../static/image-20201201113615386.png)

#### 优点和缺点:

优点:

1. 哨兵集群，基于主从复制模式，所有主从配置的优点他都有
2. 主从可以切换，故障可以转移，高可用
3. 哨兵模式就是主从模式的升级，从手动到自动，更加健壮

缺点:

1. redis不好在线扩容，集群容量一旦达到上限，在线扩容非常麻烦
2. 实现哨兵模式的配置其实是很麻烦的，里面有很多选择

##### 哨兵模式的全部配置:

```bash
# 哨兵sentinel实例运行的端口，默认26379  
port 26379
# 哨兵sentinel的工作目录
dir ./

# 哨兵sentinel监控的redis主节点的 
## ip：主机ip地址
## port：哨兵端口号
## master-name：可以自己命名的主节点名字（只能由字母A-z、数字0-9 、这三个字符".-_"组成。）
## quorum：当这些quorum个数sentinel哨兵认为master主节点失联 那么这时 客观上认为主节点失联了  
# sentinel monitor <master-name> <ip> <redis-port> <quorum>  
sentinel monitor mymaster 127.0.0.1 6379 2

# 当在Redis实例中开启了requirepass <foobared>，所有连接Redis实例的客户端都要提供密码。
# sentinel auth-pass <master-name> <password>  
sentinel auth-pass mymaster 123456  

# 指定主节点应答哨兵sentinel的最大时间间隔，超过这个时间，哨兵主观上认为主节点下线，默认30秒  
# sentinel down-after-milliseconds <master-name> <milliseconds>
sentinel down-after-milliseconds mymaster 30000  

# 指定了在发生failover主备切换时，最多可以有多少个slave同时对新的master进行同步。这个数字越小，完成failover所需的时间就越长；反之，但是如果这个数字越大，就意味着越多的slave因为replication而不可用。可以通过将这个值设为1，来保证每次只有一个slave，处于不能处理命令请求的状态。
# sentinel parallel-syncs <master-name> <numslaves>
sentinel parallel-syncs mymaster 1  

# 故障转移的超时时间failover-timeout，默认三分钟，可以用在以下这些方面：
## 1. 同一个sentinel对同一个master两次failover之间的间隔时间。  
## 2. 当一个slave从一个错误的master那里同步数据时开始，直到slave被纠正为从正确的master那里同步数据时结束。  
## 3. 当想要取消一个正在进行的failover时所需要的时间。
## 4.当进行failover时，配置所有slaves指向新的master所需的最大时间。不过，即使过了这个超时，slaves依然会被正确配置为指向master，但是就不按parallel-syncs所配置的规则来同步数据了
# sentinel failover-timeout <master-name> <milliseconds>  
sentinel failover-timeout mymaster 180000

# 当sentinel有任何警告级别的事件发生时（比如说redis实例的主观失效和客观失效等等），将会去调用这个脚本。一个脚本的最大执行时间为60s，如果超过这个时间，脚本将会被一个SIGKILL信号终止，之后重新执行。
# 对于脚本的运行结果有以下规则：  
## 1. 若脚本执行后返回1，那么该脚本稍后将会被再次执行，重复次数目前默认为10。
## 2. 若脚本执行后返回2，或者比2更高的一个返回值，脚本将不会重复执行。  
## 3. 如果脚本在执行过程中由于收到系统中断信号被终止了，则同返回值为1时的行为相同。
# sentinel notification-script <master-name> <script-path>  
sentinel notification-script mymaster /var/redis/notify.sh

# 这个脚本应该是通用的，能被多次调用，不是针对性的。
# sentinel client-reconfig-script <master-name> <script-path>
sentinel client-reconfig-script mymaster /var/redis/reconfig.sh
```

### 缓存穿透、缓存击穿、缓存雪崩

##### 缓存穿透

用户查询一个数据，发现缓存中没有，然后向数据库发起查询，发现也没有，于是本次查询无结果，所以并没有被缓存，下次还会继续请求数据库

当这样的请求量很大时，就会给数据库造成很大的压力，也就是缓存穿透

解决方案:

布隆过滤器：一种数据结构，对所有可能查询的参数以hash形式存储，先进行校验如果不符合则丢弃请求，从而避免对数据库查询造成压力

缓存空数据:但是会带来两个问题，第一是如果缓存空值则意味着需要占用很多缓存空间来存储更多的key。第二是对空值设置了过期时间还是会存在缓存和数据库的数据有一段时间窗口的不一致，对需要保持一致性的业务会有影响

##### 缓存击穿(量太大，缓存过期！)

缓存击穿指的是一个key非常热点，在不停的扛着大并发，大并发集中对这一个点进行访问，当这个key在失效的瞬间，持续的大并发就会穿破缓存直接请求数据库，就像在一个屏障上凿开了一个洞。

当某个key在过期的瞬间，有大量的请求并发访问，这类数据一般是热点数据，由于缓存过期，会同时访问数据库来查询最新数据，并且回写缓存，会导致数据库瞬间压力过大

解决方案:

1. 设置热点数据永不过期:
2. 分布式锁:

#### 缓存雪崩

缓存雪崩，是指在某一个时间段内，缓存集中过期失效。redis宕机

产生雪崩的原因之一，比如双十一秒杀，把商品放入缓存，缓存过期时间为1小时，当缓存过期时，大量商品访问请求都落到了数据库，导致数据库挂掉。

集中过期并不是非常致命，比较致命的缓存雪崩， 是缓存服务器某个节点宕机或断网，因为自然形成的缓存雪崩，一定是在某个时间段集中创建缓存，这个时候，数据库也是可以顶住压力的，无非就是对数据库产生周期性压力而已，而缓存服务节点的宕机，对数据库服务器造成的压力是不可预知的，很可能瞬间把数据库压垮

解决方案:双十一停掉一些服务(保证主要服务高可用)

redis高可用:搭建集群，异地多活

限流降级:缓存失效后通过加锁或者队列来控制读数据库写缓存的线程数量，比如某个key只允许一个线程查询数据和写缓存



























































































