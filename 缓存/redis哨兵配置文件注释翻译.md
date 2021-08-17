### sentinel.conf 官方注释:

重要: 哨兵在默认情况下不会被除 localhost 外的端口访问到。要想被访问到，要么使用"bind"去绑定一个网络接口列表，要么在配置文件中添加"protected-mode no"来关闭保护模式。配置前确保该实例被外部通过防火墙保护或者其他办法

例如你可以用下面任意一种:

```bash
bind 127.0.0.1 192.168.1.1
```

```bash
protected-mode no
```

哨兵实例将运行在:

```bash
port 26379
```

默认情况下哨兵不会以守护形式运行，如果需要使用守护模式运行要使用“yes”
注意当守护模式运行时，redis会在/var/run/redis-sentinel.pid下写入一个pid文件

```bash
daemonize no
```

运行守护进程时，redis哨兵默认会在/var/run/redis-sentinel.pid写入一个pid文件，你可以在这里指定一个自定义pid文件路径:

```bash
pidfile /var/run/redis-sentinel.pid
```

指定日志文件名称，空字符串名会被用于强制哨兵使用标准输出记录日志。注意如果你使用标准输出去记录日志除了守护进程模式，日志将会发送到/dev/null下

```bash
logfile ""
```

每一个长时间运行的进程都应该有一个定义良好的工作目录。对于redis哨兵来说，启动时指定目录/tmp是保证进程不干扰诸如卸载文件系统之类的管理任务的最简单的事。

```bash
dir /tmp
```

告诉哨兵去监控这个master，并且在除非至少 quorum 个哨兵同意情况下才考虑它是否处在客观宕机状态。
请注意无论 odown 的 quorum 是多少，一个哨兵将需要由大多数已知哨兵选出才能启动故障转移，所以不能在少数情况下执行故障转移

副本是自动发现的，所以你无需使用任何形式指定副本。哨兵自身将会使用添加到配置文件的参数去覆写这个配置文件。也请注意当一个副本被提升为master时配置文件会被覆写

注意:master名字不应该包含特殊字符或空格，有效字符是 A-Z 0-9 和三个字符".-_"

```bash
sentinel monitor mymaster 127.0.0.1 6379 2 
```

设置密码以用于对master和副本进行身份认证。如果在redis实例中设置了密码进行监控，则很有用。

请注意master的密码也会应用于副本，所以如果你想用哨兵去监控他们，那么在master和副本之间设置不同密码是不可能的

但是，你可以将未启用身份验证的redis实例与需要身份验证的redis实例混合使用(只要所有需要密码的实例的密码设置相同)，因为AUTH 命令在身份验证关闭的redis实例中无效
例如：

```bash
sentinel auto-pass mymaster MySUPER--secret-0123passw0rd
```

```bash
sentinel down-after-milliseconds <master-name> <milliseconds>
```

master(或者任何附属的副本或哨兵)被认为不可达(例如在指定的时间段内接收不到ping的回复)的毫秒数，以便将其视为S_DOWN状态(主观宕机)，默认是30s

```bash
sentinel down-after-milliseconds mymaster 30000
```



```bash
sentinel parallel-syncs <master-name> <numreplicas>
```

在故障转移期间我们可以重新配置多少个副本以同时指向新副本。如果你使用副本来提供查询服务，请使用较小的数字以避免在与master同步时几乎无法同时访问所有副本

```bash
sentinel parallel-syncs mymaster 1
```



```bash
sentinel failover-timeout <master-name> <milliseconds>
```

用毫秒指定故障超时时间。用于很多方式：
1.在上一次故障转移之后重新启动故障转移所需的时间，已经由给定的sentinel尝试针对同一个master，是故障转移超时时间的两倍

由给定的sentinel尝试针对同一个master发起一次故障转移被拒绝后，需要重新发起故障转移的时间，也就是两次故障转移的超时时间。

2. 
根据哨兵当前配置将副本复制到错误master到强制复制到正确的master所需的时间，就是故障转移超时时间(从哨兵检测到错误配置的那一刻开始计算)

3. 取消一次已经在进程中但是还没有产生任何配置改变(SLAVEOF NO ONE 还没有被提升的副本确认)所需的时间

4. 正在进行的故障转移等待所有副本重新配置为新master的副本的最长时间。然而，即使在这段时间之后，副本也会被哨兵重新配置，但不会按照指定的精确并行同步进程进行配置。

默认是3分钟

```bash
sentinel failover-timeout mymaster 180000
```

### redis 命令重命名

有时 Redis 服务器有某些命令重命名为不可猜测的字符串，这些命令是哨兵正常工作所必需的。在提供 Redis 作为服务的提供商的上下文中，CONFIG 和 SLAVEOF 的情况通常如此，并且不希望客户在管理控制台之外重新配置实例。 在这种情况下，可以告诉哨兵使用不同的命令名称而不是正常的。例如，如果master “mymaster” 和关联的副本将 “CONFIG” 都重命名为“GUESSME”，我可以使用:

```bash
SENTINEL rename-command mymaster CONFIG GUESSME
```

设置此类配置后，每次 Sentinel 使用 CONFIG 时，它都会使用GUESSME。请注意，实际上没有必要尊重命令的大小写，因此在上面的示例中编写“config guessme”是相同的。SENTINEL SET 也可用于在运行时执行此配置。为了将命令设置回其原始名称（撤消重命名），可以将命令重命名为 itef:

```bash
SENTINEL rename-command mymaster CONFIG CONFIG
```

