### 集群部署时的分布式Session如何实现？
* 思路1:不使用session，使用jwt token储存用户身份，然后根据jwt中的信息从数据库或者缓存中获取其他信息。这样无论请求分配到哪个服务器都无所谓
* 思路2: tomcat + redis
使用session的代码保持和以前一样，原理还是基于tomcat原生的session支持，只不过是用 tomcat RedisSessionManager来将所有session数据存储到redis
在tomcat的配置文件中配置
```
<Value className="com.orangefunction.tomcat.redissessions.RedisSessionHandlerValue" />

<Manager className="com.orangefunction.tomcat.redissessions.RedisSessionManager"
         host="{redis.host}"
         port="{redis.port}"
         database="{redis.dbnum}"
         maxInactiveInterval="60"/>
```
也可以使用下面这种方式配置基于 redis 哨兵支持的 redis 高可用集群来保存 session 数据
```
<Value className="com.orangefunction.tomcat.redissessions.RedisSessionHandlerValue" />
<Manager className="com.orangefunction.tomcat.redissessions.RedisSessionManager"
	 sentinelMaster="mymaster"
	 sentinels="<sentinel1-ip>:26379,<sentinel2-ip>:26379,<sentinel3-ip>:26379"
	 maxInactiveInterval="60"/>
```
方案问题: 与web容器严重耦合，不便于更换web容器
* 思路3: Spring Session + Redis
在 pom.xml 中配置：
```
<dependency>
  <groupId>org.springframework.session</groupId>
  <artifactId>spring-session-data-redis</artifactId>
  <version>1.2.1.RELEASE</version>
</dependency>
<dependency>
  <groupId>redis.clients</groupId>
  <artifactId>jedis</artifactId>
  <version>2.8.1</version>
</dependency>
```
在 spring 配置文件中配置：
```
<bean id="redisHttpSessionConfiguration"
     class="org.springframework.session.data.redis.config.annotation.web.http.RedisHttpSessionConfiguration">
    <property name="maxInactiveIntervalInSeconds" value="600"/>
</bean>

<bean id="jedisPoolConfig" class="redis.clients.jedis.JedisPoolConfig">
    <property name="maxTotal" value="100" />
    <property name="maxIdle" value="10" />
</bean>

<bean id="jedisConnectionFactory"
      class="org.springframework.data.redis.connection.jedis.JedisConnectionFactory" destroy-method="destroy">
    <property name="hostName" value="${redis_hostname}"/>
    <property name="port" value="${redis_port}"/>
    <property name="password" value="${redis_pwd}" />
    <property name="timeout" value="3000"/>
    <property name="usePool" value="true"/>
    <property name="poolConfig" ref="jedisPoolConfig"/>
</bean>
```
在 web.xml 中配置：
```
<filter>
    <filter-name>springSessionRepositoryFilter</filter-name>
    <filter-class>org.springframework.web.filter.DelegatingFilterProxy</filter-class>
</filter>
<filter-mapping>
    <filter-name>springSessionRepositoryFilter</filter-name>
    <url-pattern>/*</url-pattern>
</filter-mapping>
```
示例代码：
```
@RestController
@RequestMapping("/test")
public class TestController {

    @RequestMapping("/putIntoSession")
    public String putIntoSession(HttpServletRequest request, String username) {
        request.getSession().setAttribute("name",  "leo");
        return "ok";
    }

    @RequestMapping("/getFromSession")
    public String getFromSession(HttpServletRequest request, Model model){
        String name = request.getSession().getAttribute("name");
        return name;
    }
}
```
使用 Spring Session 基于 redis 来存储 Session 数据，然后配置一个 Spring Session 的过滤器，这样的话，Session 相关操作都会交给 spring session 
来管了。接着在代码中，就用原生的 Session 操作，就是直接基于 Spring Session 从 redis 中获取数据了。