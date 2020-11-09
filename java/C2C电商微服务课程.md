### 国内互联网公司的微服务架构演进路线:
大厂:使用自研组件支撑大型系统
小公司:使用阿里开源的dubbo加开源zookeeper来搭建基本的微服务架构雏形，其他组件各自找不同的开源项目来使用

### 海外互联网公司的微服务架构演进路线:
大公司自己研发，从netflix的微服务技术架构被整合到springCloud项目后，以eureka、feign+ribbon、zuul、hystrix，用zipkin和sleuth做链路监控，stream做消息中间件集成，contract做契约测试支持，当然gateway也可以做网关，consul也是一种注册中心，还有跟spring security配合的安全认证，跟k8s配合的容器支持。小公司使用这一套

### 当前国内公司的主流微服务技术栈:
* 两三年前:大公司以纯自研/dubbo+自研为主，中小公司以springCloud netflix技术栈为主
* 现在: 以nacos、dubbo、seata、sentinal、rocketMQ等为代表的阿里微服务技术栈融入SpringCloud形成SpringCloudAlibaba
注册中心：nacos -> eureka
RPC框架：dubbo -> feign+ribbon
分布式事务：seata -> 无
限流/熔断/降级：sentinel -> hystrix
API网关：无 -> zuul



















































































