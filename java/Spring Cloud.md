## 电商系统使用Spring Cloud架构图:
![avatar](../static/电商系统使用SpringCloud架构.png)

## SpringCloud四大核心组件:
* Eureka:服务注册中心
* Feign:服务调用
* Ribbon:负载均衡
* Zuul/Spring Cloud Gateway:网关

Hystrix、链路追踪、Stream等很多组件，并不是说一个普通系统刚开始就必须得用的，如果用了没有用好反而会出问题。Hystrix线路熔断的框架必须得设计对应的一整套限流方案、熔断方案、资源隔离方案、降级方案等机制，来配合降级机制来做。

## 

## SpringCloud接口请求处理流程:
基于SpringCloud对外发布一个接口，实际上就是对外发布一个最普通的SpringMVC的http接口。请求首先到达网关，
网关里配置了不同请求路径和服务的对应关系，由网关查找请求所要访问的服务，然后将请求转发给服务的某台机器，
然后这台机器要调用其他服务时，先访问的是打了feign注解的接口，然后feign对这个接口生成动态代理，
当针对feign的动态代理去调用方法时，会在底层生成http协议格式的请求，/order/create?productId=1,
然后先通过Ribbon从本地的Eureka注册表缓存中获取出目标服务的机器列表，然后按照负载均衡算法选出一台机器，
然后使用Httpclient对这台机器发起Http请求。


## SpringCloud和Dubbo的优劣比较？
对于Dubbo，经过深度优化的RPC服务框架性能和并发是比HTTP更好的，Dubbo请求一次10ms，SpringCloud耗费20ms，但是对于中型公司而言，性能、并发并不是主要因素。
SpringCloud这套框架走Http请求就足够满足性能和并发的需要了，没必要使用高度优化的RPC服务框架。





























































