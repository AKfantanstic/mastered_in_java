## 电商系统使用Spring Cloud架构图:
![avatar](../static/电商系统使用SpringCloud架构.png)

##SpringCloud四大核心组件:
* Eureka:服务注册中心
* Feign:服务调用
* Ribbon:负载均衡
* Zuul/Spring Cloud Gateway:网关

Hystrix、链路追踪、Stream等很多组件，并不是说一个普通系统刚开始就必须得用的，如果用了没有用好反而会出问题。Hystrix线路熔断的框架必须得设计对应的一整套限流方案、熔断方案、资源隔离方案、降级方案等机制，来配合降级机制来做。