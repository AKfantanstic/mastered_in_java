1.\#{}和${}的区别是什么？
答：${}是 Properties 文件中的变量占位符，它可以用于标签属性值和 sql 内部，属于静态文本替换,有xss注入风险，一般不用这种方式  
\#{}是 sql 的参数占位符，Mybatis 会将 sql 中的#{}替换为?号，在 sql 执行前会使用 PreparedStatement 的参数设置方法，按序给 sql 的?号占位符设置参数值，比如 ps.setInt(0,
 parameterValue)，#{item.name} 的取值方式为使用反射从参数对象中获取 item 对象的 name 属性值，相当于 param.getItem().getName()。

2、Xml 映射文件中，除了常见的 select|insert|updae|delete 标签之外，还有哪些标签？(京东面试题)
答：还有很多其他的标签，<resultMap>、<parameterMap>、<sql>、<include>、<selectKey>，加上动态 sql 的 9 个标签，trim|where|set|foreach|if|choose|when|otherwise|bind等，其中为 sql 片段标签，通过<include>标签引入 sql 片段，<selectKey>为不支持自增的主键生成策略标签。

3、最佳实践中，通常一个 Xml 映射文件，都会写一个 Dao 接口与之对应，请问，这个 Dao 接口的工作原理是什么？Dao 接口里的方法，参数不同时，方法能重载吗？(京东面试题)  
答：Dao 接口，就是人们常说的 Mapper接口，接口的全限名，就是映射文件中的 namespace 的值，接口的方法名，就是映射文件中MappedStatement的 id 值，接口方法内的参数，就是传递给 sql 的参数。Mapper接口是没有实现类的，当调用接口方法时，接口全限名+方法名拼接字符串作为 key 值，可唯一定位一个MappedStatement，举例：com.mybatis3.mappers.StudentDao.findStudentById，可以唯一找到 namespace 为com.mybatis3.mappers.StudentDao下面id = findStudentById的MappedStatement。在 Mybatis 中，每一个<select>、<insert>、<update>、<delete>标签，都会被解析为一个MappedStatement对象。
Dao 接口里的方法，是不能重载的，因为是全限名+方法名的保存和寻找策略。
Dao 接口的工作原理是 JDK 动态代理，Mybatis 运行时会使用 JDK 动态代理为 Dao 接口生成代理 proxy 对象，代理对象 proxy 会拦截接口方法，转而执行MappedStatement所代表的 sql，然后将 sql 执行结果返回。

4、Mybatis 是如何进行分页的？分页插件的原理是什么？
答：Mybatis 使用 RowBounds 对象进行分页，它是针对 ResultSet 结果集执行的内存分页，而非物理分页，可以在 sql 内直接书写带有物理分页的参数来完成物理分页功能，也可以使用分页插件来完成物理分页。
分页插件的基本原理是使用 Mybatis 提供的插件接口，实现自定义插件，在插件的拦截方法内拦截待执行的 sql，然后重写 sql，根据 dialect 方言，添加对应的物理分页语句和物理分页参数。
举例：select _ from student，拦截 sql 后重写为：select t._ from （select \* from student）t limit 0，10

5、简述 Mybatis 的插件运行原理，以及如何编写一个插件。
答：Mybatis 仅可以编写针对 ParameterHandler、ResultSetHandler、StatementHandler、Executor 这 4 种接口的插件，Mybatis 使用 JDK 的动态代理，为需要拦截的接口生成代理对象以实现接口方法拦截功能，每当执行这 4 种接口对象的方法时，就会进入拦截方法，具体就是 InvocationHandler 的 invoke()方法，当然，只会拦截那些你指定需要拦截的方法。
实现 Mybatis 的 Interceptor 接口并复写 intercept()方法，然后在给插件编写注解，指定要拦截哪一个接口的哪些方法即可，记住，别忘了在配置文件中配置你编写的插件。

6、Mybatis 执行批量插入，能返回数据库主键列表吗？
答：能，JDBC 都能，Mybatis 当然也能。

7、Mybatis 动态 sql 是做什么的？都有哪些动态 sql？能简述一下动态 sql 的执行原理不？
答：Mybatis 动态 sql 可以让我们在 Xml 映射文件内，以标签的形式编写动态 sql，完成逻辑判断和动态拼接 sql 的功能，Mybatis 提供了 9 种动态 sql 标签 trim|where|set|foreach|if|choose|when|otherwise|bind。
其执行原理为，使用 OGNL 从 sql 参数对象中计算表达式的值，根据表达式的值动态拼接 sql，以此来完成动态 sql 的功能。

8、Mybatis 是如何将 sql 执行结果封装为目标对象并返回的？都有哪些映射形式？
答：第一种是使用<resultMap>标签，逐一定义列名和对象属性名之间的映射关系。第二种是使用 sql 列的别名功能，将列别名书写为对象属性名，比如 T_NAME AS NAME，对象属性名一般是 name，小写，但是列名不区分大小写，Mybatis 会忽略列名大小写，智能找到与之对应对象属性名，你甚至可以写成 T_NAME AS NaMe，Mybatis 一样可以正常工作。
有了列名与属性名的映射关系后，Mybatis 通过反射创建对象，同时使用反射给对象的属性逐一赋值并返回，那些找不到映射关系的属性，是无法完成赋值的。

9、Mybatis 能执行一对一、一对多的关联查询吗？都有哪些实现方式，以及它们之间的区别。
答：能，Mybatis 不仅可以执行一对一、一对多的关联查询，还可以执行多对一，多对多的关联查询，多对一查询，其实就是一对一查询，只需要把 selectOne()修改为 selectList()即可；多对多查询，其实就是一对多查询，只需要把 selectOne()修改为 selectList()即可。
关联对象查询，有两种实现方式，一种是单独发送一个 sql 去查询关联对象，赋给主对象，然后返回主对象。另一种是使用嵌套查询，嵌套查询的含义为使用 join 查询，一部分列是 A 对象的属性值，另外一部分列是关联对象 B 的属性值，好处是只发一个 sql 查询，就可以把主对象和其关联对象查出来。
那么问题来了，join 查询出来 100 条记录，如何确定主对象是 5 个，而不是 100 个？其去重复的原理是<resultMap>标签内的<id>子标签，指定了唯一确定一条记录的 id 列，Mybatis 根据列值来完成 100 条记录的去重复功能，<id>可以有多个，代表了联合主键的语意。
同样主对象的关联对象，也是根据这个原理去重复的，尽管一般情况下，只有主对象会有重复记录，关联对象一般不会重复。

举例：下面 join 查询出来 6 条记录，一、二列是 Teacher 对象列，第三列为 Student 对象列，Mybatis 去重复处理后，结果为 1 个老师 6 个学生，而不是 6 个老师 6 个学生。

t_id t_name s_id

| 1 | teacher | 38 | | 1 | teacher | 39 | | 1 | teacher | 40 | | 1 | teacher | 41 | | 1 | teacher | 42 | | 1 | teacher | 43 |

10、Mybatis 是否支持延迟加载？如果支持，它的实现原理是什么？
答：Mybatis 仅支持 association 关联对象和 collection 关联集合对象的延迟加载，association 指的就是一对一，collection 指的就是一对多查询。在 Mybatis 配置文件中，可以配置是否启用延迟加载 lazyLoadingEnabled=true|false。
它的原理是，使用 CGLIB 创建目标对象的代理对象，当调用目标方法时，进入拦截器方法，比如调用 a.getB().getName()，拦截器 invoke()方法发现 a.getB()是 null 值，那么就会单独发送事先保存好的查询关联 B 对象的 sql，把 B 查询上来，然后调用 a.setB(b)，于是 a 的对象 b 属性就有值了，接着完成 a.getB().getName()方法的调用。这就是延迟加载的基本原理。
当然了，不光是 Mybatis，几乎所有的包括 Hibernate，支持延迟加载的原理都是一样的。

11、Mybatis 的 Xml 映射文件中，不同的 Xml 映射文件，id 是否可以重复？
答：不同的 Xml 映射文件，如果配置了 namespace，那么 id 可以重复；如果没有配置 namespace，那么 id 不能重复；毕竟 namespace 不是必须的，只是最佳实践而已。
原因就是 namespace+id 是作为 Map<String, MappedStatement>的 key 使用的，如果没有 namespace，就剩下 id，那么，id 重复会导致数据互相覆盖。有了 namespace，自然 id 就可以重复，namespace 不同，namespace+id 自然也就不同。

12、Mybatis 中如何执行批处理？
答：使用 BatchExecutor 完成批处理。

13、Mybatis 都有哪些 Executor 执行器？它们之间的区别是什么？
答：Mybatis 有三种基本的 Executor 执行器，SimpleExecutor、ReuseExecutor、BatchExecutor。

**SimpleExecutor：**每执行一次 update 或 select，就开启一个 Statement 对象，用完立刻关闭 Statement 对象。
**``ReuseExecutor`：**执行 update 或 select，以 sql 作为 key 查找 Statement 对象，存在就使用，不存在就创建，用完后，不关闭 Statement 对象，而是放置于 Map<String, Statement>内，供下一次使用。简言之，就是重复使用 Statement 对象。

**BatchExecutor：**执行 update（没有 select，JDBC 批处理不支持 select），将所有 sql 都添加到批处理中（addBatch()），等待统一执行（executeBatch()），它缓存了多个 Statement 对象，每个 Statement 对象都是 addBatch()完毕后，等待逐一执行 executeBatch()批处理。与 JDBC 批处理相同。

作用范围：Executor 的这些特点，都严格限制在 SqlSession 生命周期范围内。

14、Mybatis 中如何指定使用哪一种 Executor 执行器？
答：在 Mybatis 配置文件中，可以指定默认的 ExecutorType 执行器类型，也可以手动给 DefaultSqlSessionFactory 的创建 SqlSession 的方法传递 ExecutorType 类型参数。

15、Mybatis 是否可以映射 Enum 枚举类？
答：Mybatis 可以映射枚举类，不单可以映射枚举类，Mybatis 可以映射任何对象到表的一列上。映射方式为自定义一个 TypeHandler，实现 TypeHandler 的 setParameter()和 getResult()接口方法。TypeHandler 有两个作用，一是完成从 javaType 至 jdbcType 的转换，二是完成 jdbcType 至 javaType 的转换，体现为 setParameter()和 getResult()两个方法，分别代表设置 sql 问号占位符参数和获取列查询结果。

16、Mybatis 映射文件中，如果 A 标签通过 include 引用了 B 标签的内容，请问，B 标签能否定义在 A 标签的后面，还是说必须定义在 A 标签的前面？
答：虽然 Mybatis 解析 Xml 映射文件是按照顺序解析的，但是，被引用的 B 标签依然可以定义在任何地方，Mybatis 都可以正确识别。
原理是，Mybatis 解析 A 标签，发现 A 标签引用了 B 标签，但是 B 标签尚未解析到，尚不存在，此时，Mybatis 会将 A 标签标记为未解析状态，然后继续解析余下的标签，包含 B 标签，待所有标签解析完毕，Mybatis 会重新解析那些被标记为未解析的标签，此时再解析 A 标签时，B 标签已经存在，A 标签也就可以正常解析完成了。

17、简述 Mybatis 的 Xml 映射文件和 Mybatis 内部数据结构之间的映射关系？
答：Mybatis 将所有 Xml 配置信息都封装到 All-In-One 重量级对象 Configuration 内部。在 Xml 映射文件中，<parameterMap>标签会被解析为 ParameterMap 对象，其每个子元素会被解析为 ParameterMapping 对象。<resultMap>标签会被解析为 ResultMap 对象，其每个子元素会被解析为 ResultMapping 对象。每一个<select>、<insert>、<update>、<delete>标签均会被解析为 MappedStatement 对象，标签内的 sql 会被解析为 BoundSql 对象。

18、为什么说 Mybatis 是半自动 ORM 映射工具？它与全自动的区别在哪里？
答：Hibernate 属于全自动 ORM 映射工具，使用 Hibernate 查询关联对象或者关联集合对象时，可以根据对象关系模型直接获取，所以它是全自动的。而 Mybatis 在查询关联对象或关联集合对象时，需要手动编写 sql 来完成，所以，称之为半自动 ORM 映射工具。



### Java中的statement,preparedStatement和callableStatement
| 接口名称 | 使用场景 | 
| :---: | :---: | 
| Statement| 用于数据库进行通用访问，在运行时使用静态sql语句时很有用，Statement接口不能接受参数 |
| PreparedStatement | 当计划要多次使用sql语句时使用。PreparedStatement接口在运行时接受输入参数 |
| CallableStatement | 当想要访问数据库存储过程时使用。CallableStatement接口也可以接受运行时输入参数 |

## 一级缓存与二级缓存(针对查询语句)

### 一级缓存：SqlSession 级别
SqlSession是mybatis对jdbc连接的封装。
针对的场景：在一次数据库会话中两次查询同样的sql，第二次会直接查询缓存，提高性能。
原理：每个SqlSession中持有了Executor，每个Executor中有一个LocalCache。当用户发起查询时，MyBatis根据当前执行的语句生成MappedStatement，在Local Cache进行查询，如果缓存命中的话，直接返回结果给用户，如果缓存没有命中的话，查询数据库，结果写入Local Cache，最后返回结果给用户
### 如何配置开启一级缓存？
首先一级缓存是默认开启的，并且无法关闭。一级缓存中又分为两个级别，session级别和Statement级别，session级别就是在一次数据库会话中共享，
这个级别在分布式环境会有问题，假设目前有两个节点，两个节点都执行了一样的查询，也都产生了自己的一级缓存，后续两个节点再执行相同的查询不会走数据库
直接从缓存中获取，如果节点1进行了update，节点1的一级缓存被更新了，但是节点2的一级缓存没有被更新，如果用节点2的缓存去做业务，就会产生错误，解决方式是将一级缓存级别修改为statement级别，这样每次查询结束后(也就是每个query执行完后)，都会清掉一级缓存。即使两次执行了一样的sql，也会查询两次数据库，不走缓存了。下面源码为证
```
if(configuration.getLocalCacheScope() == LocalCacheScope.statement){
	clearLocalCache();
}
```
* 
在mybatis配置文件中配置localCache
```
<setting name="localCacheScope" value="SESSION"/>
```
### 一级缓存级别为Session级别时，什么场景会使一级缓存失效？
在同一个sqlsession中，两次查询中间如果调用了insert、delete、update方法，方法执行过程中会清空一级缓存

### 一级缓存总结:
MyBatis的一级缓存生命周期和SqlSession一致。在有多个SqlSession或者分布式环境下， 数据库写会引起读脏数据，最佳实践为设定一级缓存级别为Statement。

### 二级缓存: Mapper 级别
* 二级缓存开启后，同一个namespace下的所有操作语句，都影响着同一个cache。即二级缓存被多个SqlSession共享，是一个全局变量
* 当开启二级缓存后，查询的执行流程为: 二级缓存 -> 一级缓存 -> 数据库
### 如何开启二级缓存？
* 第一步:在mybatis的配置文件中开启二级缓存
```
<setting name="cacheEnabled" value="true"/>
```
* 第二步:在mybatis的mapper.xml文件中配置cache

```
<cache/>
```
或者配置cache-ref , cache-ref表示引用其他命名空间的cache配置，意思就是两个namespace用的是同一个cache（这里真的是引用的同一个cache，）
```
<cache-ref namespace="mapper.StudentMapper"/>
```
cache中其他配置参数说明如下:
```
<cache type="" eviction="" flushInterval="" size="" readOnly="" blocking=""/>

type：cache使用的类型，默认是PerpetualCache，这在一级缓存中提到过。
eviction： 定义回收的策略，常见的有FIFO，LRU。
flushInterval： 配置一定时间自动刷新缓存，单位是毫秒。
size： 最多缓存对象的个数。
readOnly： 是否只读，若配置可读写，则需要对应的实体类能够序列化。
blocking： 若缓存中找不到对应的key，是否会一直blocking，直到有对应的数据进入缓存。
```

### 二级缓存什么情况下会出现读取到脏数据？
增删改操作，无论是否进行提交sqlSession.commit()，均会请控股一级、二级缓存，下次查询会直接走DB


### 二级缓存总结:
在多表查询场景中，极大可能回出现脏数据，有设计上的缺陷，安全使用二级缓存的条件比较苛刻，
在分布式环境下，由于默认的mybatis缓存特性都是基于本地缓存的实现，分布式环境下必然会出现读取到脏数据，
想要解决需要使用集中式缓存来实现mybatis的cache接口，相比之下，直接使用redis，memcached等分布式缓存成本更低，安全性也更高


### 一级缓存与二级缓存总结:
由于MyBatis的一级缓存和二级缓存都可能产生脏读，因此建议在生产环境中关闭，单纯将Mybatis作为一个ORM框架使用可能更合适。