一个数字货币支付软件。swagger2，springboot，redis，mysql，lombok，mybatisPlus，rabbitmq,
对象存储用阿里云oss，(spring websocket) httpclient做http访问
服务部署在aws，接口访问时间长,做dns解析，静态页面做cdn加速

### 1 主服务
主服务整个工程模块划分：拦截器模块:用@RestControllerAdvice对controller层全局异常处理，确保不返回异常及堆栈信息，
请求签名用过滤器实现校验  继承OncePerRequestFilter
请求签名：前后端约定好密钥串。需要前端将key按字母升序排列，然后以key=value和逗号形式组成字符串，用sha256来签名，url后面的签名和body中生成的签名来比较

登录token过滤器，继承OncePerRequestFilter，token有效期为7天，当token存在redis中，每次访问验证通过更新redis过期时间，需要校验token中存的userId和传参userId是否一致
遇到的问题：在签名filter中，读取一次body后，body中的流就不存在了，所以需要写一个类来复制流。继承HttpServletRequestWrapper

幂等检查用拦截器实现，主要是每个请求有个幂等token，幂等token有2个状态:待定-已消费，过期时间5分钟，幂等token状态为完成时，将此response
请求过来时候检查幂等接口的幂等token状态

totp相关时间序列的东西

业务点：账务相关计算手续费，

mq部分的作用：解耦，异步
redis的作用:

做了一个自定义注解，做了一个返回通知AOP,来记录用户的操作 自动记录日志 注解处理切面

用BeanValidate来对请求参数做校验

和go对接区块链

短信模块，用户模块，拦截器模块，账务处理模块，钱包交易模块，otc支付模块，
otc模块(查询商家订单状态，创建预生成支付订单，发起付款)，go对接模块，理财模块(抵押挖矿)

定时任务工程：用@Async开启异步线程池，用线程池执行。而不是单纯用一个线程来执行。

### 0 api工程
接入api工程：商户对接时，先交换公钥，然后私钥签名，公钥验签。过滤请求ip白名单
跨域通过corsFilter来解决。其他没啥好说的


### 1 websocket工程
推送websocket工程：心跳检测任务，放入线程池中调度。
问题：在第一条socket因为网络原因断开时，服务端还没有检测到时，第二条socket已经建立好了，并且开始接单
，这时第一条socket服务端检测到断开，暂停了接单，这时心跳任务检测到当前任务的状态不对，开始做补偿，开始接单。

安卓端监控软件做自动放币监控。偶尔会无网络和进程被杀，所以需要后端搭建websocket工程
来解决这个问题。当websocket连接时，开启接单，当websocket断开时，暂停接单
安卓端需要在接收服务端消息超时时开始重连，所以后端需要定时发送消息给每个客户端。

服务启动时，新建一个ScheduledThreadPoolExecutor，核心线程数为Runtime.getRuntime().availableProcessors();
因为任务都是计算密集型。在socket连接事件上，将任务放进线程池调度，2秒一次。
ScheduledThreadPoolExecutor.scheduleWithFixedDelay(task,0,2,TimeUnit.SECONDS);
任务具体是：实现了Runnable接口。给所有连接的socket用户发送消息，如果socketClient不存在了，则将挂单暂停
，抛异常中止任务。

遇到的问题：因为安卓端偶尔会掉网后和断掉socket之间有延迟，重新连接socket，这时挂单状态会是正在接单，
但超时时间过后，会将挂单暂停。造成socket在连接，单已经停掉的问题。解决方案：
每次修改挂单状态维护一个map，记录每个用户的挂单状态，当socket心跳任务进行中时，检查map中当前用户的挂单状态
，如果挂单是停止的，将挂单开启。


核心账务部分用jMeter进行并发测试

项目中实际遇到的问题：
mybatis二级缓存导致实体类属性不同

用金额作为订单的偏移量，然后可复用。用户下订单时，在订单号加一个小数，用来区分订单号，给商家便于分辨。


jenkins在gitlab测试环境自动构建,正式环境打jar包上:
```
#当jenkins进程结束后新开的tomcat进程不被杀死
#BUILD_ID=DONTKILLME
#加载变量
#. /etc/profile
#配置运行参数
 
#PROJ_PATH为设置的jenkins目录的执行任务目录
#export PROJ_PATH=/usr/local/apps/jenkens/workspace


#配置job 名称 所在目录
#echo $PROJ_PATH/$JOB_NAME
# maven 打包 拉去git
#sh /usr/local/apps/jenkens/pulls.sh  $PROJ_PATH/$JOB_NAME

#sh /usr/local/apps/jenkens/cp.sh $PROJ_PATH/$JOB_NAME/target/$JOB_NAME.jar
#执行写好的自动化部署脚本
#sh /usr/local/apps/jenkens/s.sh  $JOB_NAME.jar
export MAVEN_HOME=/usr/share/maven
export PATH=$PATH:$MAVEN_HOME/bin

cd $WORKSPACE/
pwd
#cp  /root/deploy/clean.sh ./
#./clean.sh

mvn clean install
rm -rf /root/deploy/$JOB_NAME.jar

cp -rf $WORKSPACE/target/$JOB_NAME.jar /root/deploy
cd /root/deploy

./jenkinsjb.sh restart $JOB_NAME.jar 8087 dev

#java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5006 -jar apay-service.jar
```


```
由用户 赵宁 启动
在远程节点 113 上构建 在工作空间 /usr/local/apps/jenkens/workspace/apay-service 中
using credential 43efbf81-37b3-4ce7-89e0-4d5d902bf590
 > git rev-parse --is-inside-work-tree # timeout=10
Fetching changes from the remote Git repository
 > git config remote.origin.url ssh://git@192.168.11.111:10022/apay/apay-service.git # timeout=10
Fetching upstream changes from ssh://git@192.168.11.111:10022/apay/apay-service.git
 > git --version # timeout=10
using GIT_ASKPASS to set credentials 局域网113 shell 登陆凭证
 > git fetch --tags --progress ssh://git@192.168.11.111:10022/apay/apay-service.git +refs/heads/*:refs/remotes/origin/*
 > git rev-parse refs/remotes/origin/dev^{commit} # timeout=10
 > git rev-parse refs/remotes/origin/origin/dev^{commit} # timeout=10
Checking out Revision 7d4d1b6d51bc40a88650458fdb28edb9be47feeb (refs/remotes/origin/dev)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f 7d4d1b6d51bc40a88650458fdb28edb9be47feeb
Commit message: "修改排序"
 > git rev-list --no-walk 1c7e58c9ba890007e07add922ffc54c39c44c2ef # timeout=10
[apay-service] $ /bin/sh -xe /tmp/jenkins3308274921650389728.sh
+ export MAVEN_HOME=/usr/share/maven
+ MAVEN_HOME=/usr/share/maven
+ export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/share/maven/bin
+ PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/share/maven/bin
+ cd /usr/local/apps/jenkens/workspace/apay-service/
+ pwd
/usr/local/apps/jenkens/workspace/apay-service
+ mvn clean install
[INFO] Scanning for projects...
[WARNING] 
[WARNING] Some problems were encountered while building the effective model for com.apay:apay-service:jar:0.0.1-SNAPSHOT
[WARNING] 'dependencies.dependency.(groupId:artifactId:type:classifier)' must be unique: com.aliyun.oss:aliyun-sdk-oss:jar -> duplicate declaration of version 3.5.0 @ line 264, column 21
[WARNING] The expression ${name} is deprecated. Please use ${project.name} instead.
[WARNING] 
[WARNING] It is highly recommended to fix these problems because they threaten the stability of your build.
[WARNING] 
[WARNING] For this reason, future Maven versions might no longer support building such malformed projects.
[WARNING] 
[INFO] 
[INFO] -----------------------< com.apay:apay-service >------------------------
[INFO] Building apay-service 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-clean-plugin:3.1.0:clean (default-clean) @ apay-service ---
[INFO] Deleting /usr/local/apps/jenkens/workspace/apay-service/target
[INFO] 
[INFO] --- maven-resources-plugin:3.1.0:resources (default-resources) @ apay-service ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] Copying 5 resources
[INFO] Copying 154 resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.8.1:compile (default-compile) @ apay-service ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 969 source files to /usr/local/apps/jenkens/workspace/apay-service/target/classes
[INFO] /usr/local/apps/jenkens/workspace/apay-service/src/main/java/com/apay/apaypayment/otc/service/impl/OcMakeServiceImpl.java: Some input files use or override a deprecated API.
[INFO] /usr/local/apps/jenkens/workspace/apay-service/src/main/java/com/apay/apaypayment/otc/service/impl/OcMakeServiceImpl.java: Recompile with -Xlint:deprecation for details.
[INFO] /usr/local/apps/jenkens/workspace/apay-service/src/main/java/com/apay/apaypayment/utils/RedisUtil.java: Some input files use unchecked or unsafe operations.
[INFO] /usr/local/apps/jenkens/workspace/apay-service/src/main/java/com/apay/apaypayment/utils/RedisUtil.java: Recompile with -Xlint:unchecked for details.
[INFO] 
[INFO] --- maven-resources-plugin:3.1.0:testResources (default-testResources) @ apay-service ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /usr/local/apps/jenkens/workspace/apay-service/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.8.1:testCompile (default-testCompile) @ apay-service ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 2 source files to /usr/local/apps/jenkens/workspace/apay-service/target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:2.22.2:test (default-test) @ apay-service ---
[INFO] Tests are skipped.
[INFO] 
[INFO] --- maven-jar-plugin:3.1.2:jar (default-jar) @ apay-service ---
[INFO] Building jar: /usr/local/apps/jenkens/workspace/apay-service/target/apay-service.jar
[INFO] 
[INFO] --- spring-boot-maven-plugin:2.1.6.RELEASE:repackage (repackage) @ apay-service ---
[INFO] Replacing main artifact with repackaged archive
[INFO] 
[INFO] --- maven-install-plugin:2.5.2:install (default-install) @ apay-service ---
[INFO] Installing /usr/local/apps/jenkens/workspace/apay-service/target/apay-service.jar to /root/.m2/repository/com/apay/apay-service/0.0.1-SNAPSHOT/apay-service-0.0.1-SNAPSHOT.jar
[INFO] Installing /usr/local/apps/jenkens/workspace/apay-service/pom.xml to /root/.m2/repository/com/apay/apay-service/0.0.1-SNAPSHOT/apay-service-0.0.1-SNAPSHOT.pom
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  19.494 s
[INFO] Finished at: 2020-04-13T09:30:58Z
[INFO] ------------------------------------------------------------------------
+ rm -rf /root/deploy/apay-service.jar
+ cp -rf /usr/local/apps/jenkens/workspace/apay-service/target/apay-service.jar /root/deploy
+ cd /root/deploy
+ ./jenkinsjb.sh restart apay-service.jar 8087 dev
/root/deploy/logs/apay-service
apay-service stop...
指定启动环境配置 当前启动环境为： 8087
apay-service is starting you can check the /root/deploy/logs/apay-service/2020-04-13-stdout.out
Finished: SUCCESS
```