一个数字货币支付平台
swagger2，springboot，redis，mysql，lombok，mybatisPlus，rabbitmq,
对象存储用阿里云oss，(spring websocket) httpclient做http访问,用maven打jar包，swagger2来维护接口

服务部署在 AWS ，接口访问时间长,做dns解析，静态页面做cdn加速,用堡垒机来访问服务器

使用idea编辑器，搭建工程，用secureCRT上传jar包并部署，使用gitlab进行代码管理

测试环境验证码用钉钉机器人，减少测试成本

抓包使用tcpdump命令导出文件，然后用wireShark分析文件

## 主服务工程遇到的问题：需要总结

## OTC挂单监控工程遇到的问题：需要总结

### 1 主服务
主服务整个工程模块划分：拦截器模块:用@RestControllerAdvice对controller层全局异常处理，确保不返回异常及堆栈信息，
请求签名用过滤器实现校验  继承OncePerRequestFilter
请求签名：前后端约定好密钥串。需要前端将key按字母升序排列，然后以key=value和逗号形式组成字符串，用sha256来签名，url后面的签名和body中生成的签名来比较

登录token过滤器，继承OncePerRequestFilter，token有效期为7天，当token存在redis中，每次访问验证通过更新redis过期时间，需要校验token中存的userId和传参userId是否一致
遇到的问题：在签名filter中，读取一次body后，body中的流就不存在了，所以需要写一个类来复制流。继承HttpServletRequestWrapper

幂等检查用拦截器实现，主要是每个请求有个幂等token，幂等token有2个状态:待定-已消费，过期时间5分钟，幂等token状态为完成时，将此response
请求过来时候检查幂等接口的幂等token状态

* 分模块介绍：
1. 账户模块，初始化不同类型账户，资金划转，限额，计算手续费(跨币种支付手续费)
2. otc支付模块：给对接商户用，主要包括买和卖两块，
买币：检查时间戳和签名及ip白名单,匹配订单，提交订单
卖币：查询匹配总价后，发起卖币。回调商户失败后支持商户端申请，管理后台回调
3.app内收款码收款，付款码付款
4.承兑商入驻抵押模块：，分为A级承兑商，和B级承兑商。入驻抵押，抵押退回，承兑商升级，获取承兑商统计信息，
5.返佣与手续费模块：第一部分，承兑商被邀请入驻后交易返佣，
收取商户手续费，商户手续费分润给承兑商，挂单手续费的分润，
项目介绍人定时分润(按时间或者手动分润)

maven编译为jar包，部署到aws

数据库规约基本按照阿里规约来

账户相关记账方式，用订单套账单，每个账单每个操作为一个操作码，一加一减
钱包账户到 冻结账户，

密码的存储方式：密码明文加salt(32位uuid)，sha256生成字符串base64。记录这个字符串，记录salt，每次传来明文


aop解决验证支付密码，减少重复代码

发送验证码为实时调用短信服务商接口，比较耗时，改为用mq异步，原来项目中是用线程池来消费的。

totp相关时间序列的东西

业务点：账务相关计算手续费，

还包括商户对接后，匿名支付部分，怎么给商户回调的，怎么异步回调的，怎么记录支付订单的，商户发送请求时用私钥签名，平台用商户公钥来验签，
平台返回时用平台私钥签名，商户用平台公钥来验签后方可信任数据，这部分是参考了支付宝的。

还有账户部分对事务传播（常用的就是3个，required必须在事务中，如果不在事务中则开启一个事务，如果在事务中则加入这个事务，
require_new，nested）的选择
核心账务部分用jMeter进行并发测试，用数据库的悲观锁解决并发问题，时刻考虑并发问题。

mq部分的作用：解耦，异步
redis的作用:

做了一个自定义注解，做了一个返回通知AOP,来记录用户的操作 自动记录日志 注解处理切面

用BeanValidate来对请求参数做校验

和go对接区块链

短信模块，用户模块，拦截器模块，账务处理模块，钱包交易模块，otc支付模块
otc模块(查询商家订单状态，创建预生成支付订单，发起付款)，go对接模块，理财模块(抵押挖矿)

最近做的功能模块: 承兑商抵押入驻和邀请机制。包括承兑商抵押入驻(填写邀请码入驻)，注销承兑商抵押退回，查询承兑商状态，查询承兑商邀请详情(返佣列表详情，用户邀请的
承兑商成交金额的万二返给当前用户，在当前用户成单时，判断当前用户是否由其他人邀请来，为邀请人生成返佣订单，并返佣。和返佣金额总的统计)
承兑商审核成功和承兑商拉黑都是调用此模块接口。User表中两个字段来控制承兑商状态，是否为承兑商 和 承兑商的审核状态

修改数据时用数据库行锁解决并发修改问题。
邀请码10进制转32进制，32进制转10进制

遇到的问题：
1. 排查验证码无效问题，
2. 我向redis中写入的数据，他获取到为null，因为我写入用的StringRedisTemplate，他用redisTemplate来获取的，
这两个序列化类型不同

### API工程
接入api工程：商户对接时，先交换公钥，然后私钥签名，公钥验签。过滤请求ip白名单
跨域通过corsFilter来解决。其他没啥好说的


### WebSocket工程
项目描述(项目背景)：安卓监控软件做OTC收款自动放币监控，偶尔会无网络和进程被杀导致无法自动放币，，因此后端搭建websocket工程通过连接状态来监控挂单状态
责任描述：负责基于netty-socketIo搭建websocket工程，完成编码任务
项目总结：
1. 系统基于netty-socketIo搭建的websocket服务
2. 

安卓端需要在接收服务端消息超时时开始重连，所以后端需要定时发送消息给每个客户端。
用ScheduledThreadPoolExecutor，核心线程数为Runtime.getRuntime().availableProcessors();
因为任务都是计算密集型。在socket连接事件上，将任务放进线程池调度，2秒一次。
ScheduledThreadPoolExecutor.scheduleWithFixedDelay(task,0,2,TimeUnit.SECONDS);
任务具体是：实现了Runnable接口。给所有连接的socket用户发送消息，如果socketClient不存在了，则将挂单暂停
，抛异常中止任务。

遇到的问题：因为安卓端偶尔会掉网后无网络和进程被杀和断掉socket之间有延迟，重新连接socket，这时挂单状态会是正在接单，
但超时时间过后，会将挂单暂停。造成socket在连接，单已经停掉的问题。
推送websocket工程：心跳检测任务，放入线程池中调度。
问题：在第一条socket因为网络原因断开时，服务端还没有检测到时，第二条socket已经建立好了，并且开始接单
，这时第一条socket服务端检测到断开，暂停了接单，这时心跳任务检测到当前任务的状态不对，开始做补偿，开始接单。
解决方案：每次修改挂单状态维护一个HashMap，记录每个用户当前的挂单状态，当socket心跳任务进行中时，检查map中当前用户的挂单状态
，如果挂单是停止的，将挂单开启。

### 定时任务工程:
定时任务工程：用@Async开启异步线程池，用线程池执行。而不是单纯用一个线程来执行。
```
@Configuration
// 所有的定时任务都放在一个线程池中，定时任务启动时使用不同都线程。
public class ScheduleConfig implements SchedulingConfigurer {
	@Override
	public void configureTasks(ScheduledTaskRegistrar taskRegistrar) {
		// 设定一个长度10的定时任务线程池
		taskRegistrar.setScheduler(Executors.newScheduledThreadPool(10));
	}
}
```