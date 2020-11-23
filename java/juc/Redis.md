为什么要使用Nosql?

数据量变大，mysql无法承受压力，所以使用nosql来缓解mysql的压力。而且80%请求是读请求，缓存可以提高性能

### NoSQL的四大分类

1. K-V键值对: redis、memcached
2. 文档型数据库: mongoDB
3. 列存储数据库: HBase、Cassandra
4. 图关系数据库:Neo4J

## Redis =>  ==Re== mote ==Di==ctionary ==S==erver，即远程字典服务

### 1. Linux下安装Redis:

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

### 2.官方推荐压力测试工具: redis-benchmark

