@Autowired默认是根据byType注入的，如果根据type获取到的对象大于1，则根据byName注入

### 1. 自动装配注解的区别： 

1、@Autowired是Spring自带的，@Resource是JSR250规范实现的，@Inject是JSR330规范实现的  
2、@Autowired、@Inject用法基本一样，不同的是@Inject没有一个request属性  
3、@Autowired、@Inject是默认按照类型匹配的，@Resource是按照名称匹配的  
4、@Autowired如果需要按照名称匹配需要和@Qualifier一起使用，@Inject和@Name一起使用，@Resource则通过name进行指定  

### 2. filter中bean注入失败:  

![avatar](../static/filter1.png)

在spring中，web应用的启动顺序为：listener -> filter -> servlet,先初始花listener，
然后再初始化filter，接着才到dispatcherServlet的初始化，所以，当我们需要在filter里注入一个注解的bean时，就会注入失败。因为filter初始化时，注解的bean还没初始化，所以注入为null   


### IOC 的作用？
解除了类之间的耦合。底层用反射来实现

### cglib和jdk动态代理的区别？
jdk的动态代理是基于接口的，原理是jdk通过实现和你的类一样接口，来实现代理的
cglib动态代理是基于子类的，他会生成你的类的一个子类，然后动态生成字节码，覆盖你的一些方法，然后在方法中包含增强的代码

### 3. 用Spring Aop做切面编程时，如果切面处理类中出现异常，可能会影响切点方法(主业务逻辑)的执行。
解决方法:  
(1)不要用@Before 和@Around(5种通知类型还有一种@AfterThrowing)，而是采用@After 或者 @AfterReturning 等方式来处理，
让主业务逻辑走完后再执行切面方法,这样切面处理类的方法抛异常不影响主业务逻辑。  
(2)在切面处理类中try-catch住可能出异常的代码，不要向上抛


## spring的事务实现原理？
事务的实现原理，事务的传播机制:主要是为了解决两个都加了声明式事务的方法相互调用的机制与规则。
主要讲3个级别的传播机制就可以，
required
required_new:自己独立一个事务，里面抛异常不会影响外围调用的事务。外面方法抛异常不会影响里面的new事务。场景:比如说，我们现在有一段业务逻辑，方法A调用方法B，我希望的是如果说方法A出错了，此时仅仅回滚方法A，不能回滚方法B，必须得用REQUIRES_NEW，传播机制，让他们俩的事务是不同的
nested:外层的事务如果回滚，会导致内层的事务也回滚，但是内层的事务如果回滚，仅仅回滚自己的代码，不会影响到外层的事务。场景:方法A调用方法B，如果出错，方法B只能回滚他自己，方法A可以带着方法B一起回滚，NESTED嵌套事务

### 4. 从源码解析Spring事务传播:
spring事务传播与事务隔离：事务传播和事务隔离是两回事。
在spring中，是否存在事务指的是在当前线程，在当前数据源(DataSource)中是否存在处于活动状态的事务
，猜测更具体是当前的connection是否存在事务。

声明式事务其实说白了是一种特殊的aop应用，它其实包括两种advice，一种是around，另外一种是after-throwing。
利用around advice在方法执行前，先关闭数据库的自动提交功能，然后设定一个标志符。根据业务代码实际的情况，对标志符赋不同的值，如果数据更新成功赋true，否则false。在业务方法执行完之后的部分对标志符进行处理。如为true，则提交数据库操作，否则就进行回滚。
另外还会使用after-throwing，对出错的信息进行记录。然后再将错误抛出至上层。

如果在spring执行的方法中，检测到了已存在的事务，那么就要考虑事务的传播行为了  

(1) PROPAGATION_NEVER  
即当前方法需要在非事务的环境下执行，如果有事务存在，那么抛出异常。相关源码:  
```
if (definition.getPropagationBehavior() == TransactionDefinition.PROPAGATION_NEVER) {
    throw new IllegalTransactionStateException(
        "Existing transaction found for transaction marked with propagation 'never'");
}
```
(2) PROPAGATION_NOT_SUPPORTED
与前者的区别在于，如果有事务存在，那么将事务挂起，而不是抛出异常。事务挂起其实是移除当前线程数据源活动事务对象的过程，
挂起是将ConnectionHolder设为null，因为一个ConnectionHolder对象就代表了一个数据库连接，将ConnectionHolder设为null就
意味着我们下次要使用连接时，将重新从数据库连接池中获取，而新的Connection得自动提交是为true的  
```
if (definition.getPropagationBehavior() == TransactionDefinition.PROPAGATION_NOT_SUPPORTED) {
    Object suspendedResources = suspend(transaction);
    boolean newSynchronization = (getTransactionSynchronization() == SYNCHRONIZATION_ALWAYS);
    return prepareTransactionStatus(
        definition, null, false, newSynchronization, debugEnabled, suspendedResources);
}
```
(3) PROPAGATION_REQUIRES_NEW  
挂起当前活动事务并创建新事务的过程，doBegin方法是事务开启的核心
```
if (definition.getPropagationBehavior() == TransactionDefinition.PROPAGATION_REQUIRES_NEW) {
    SuspendedResourcesHolder suspendedResources = suspend(transaction);
    boolean newSynchronization = (getTransactionSynchronization() != SYNCHRONIZATION_NEVER);
    DefaultTransactionStatus status = newTransactionStatus(
            definition, transaction, true, newSynchronization, debugEnabled, suspendedResources);
    doBegin(transaction, definition);
    prepareSynchronization(status, definition);
    return status;
}
```
(4) PROPAGATION_NESTED
PROPAGATION_NESTED 开始一个 "嵌套的" 事务,  它是已经存在事务的一个真正的子事务. 嵌套事务开始执行时,  它将取得一个 savepoint. 如果这个嵌套事务失败, 我们将回滚到此 savepoint. 
嵌套事务是外部事务的一部分, 只有外部事务结束后它才会被提交.   
```
if (definition.getPropagationBehavior() == TransactionDefinition.PROPAGATION_NESTED) {
    if (useSavepointForNestedTransaction()) {
        // Create savepoint within existing Spring-managed transaction,
        // through the SavepointManager API implemented by TransactionStatus.
        // Usually uses JDBC 3.0 savepoints. Never activates Spring synchronization.
        DefaultTransactionStatus status =
            prepareTransactionStatus(definition, transaction, false, false, debugEnabled, null);
        status.createAndHoldSavepoint();
        return status;
    }
}
```

### 5. Spring Bean的生命周期和作用域:Spring Bean 生命周期比较复杂，可以分为创建和销毁两个过程。
* 1.初始化:
实例化 Bean 对象。
设置 Bean 属性。
如果我们通过各种 Aware 接口声明了依赖关系，则会注入 Bean 对容器基础设施层面的依赖。具体包括 BeanNameAware、BeanFactoryAware 和 ApplicationContextAware，分别会注入 Bean ID、Bean Factory 或者 ApplicationContext。
调用 BeanPostProcessor 的前置初始化方法 postProcessBeforeInitialization。
如果实现了 InitializingBean 接口，则会调用 afterPropertiesSet 方法。
调用 Bean 自身定义的 init 方法。
调用 BeanPostProcessor 的后置初始化方法 postProcessAfterInitialization。
创建过程完毕。
![avatar](../static/spring_bean_1.png)
* 2.销毁:
依次调用 DisposableBean 的 destroy 方法和 Bean 自身定制的 destroy 方法

spring bean生命周期，从创建 -› 使用 -› 销毁、在整个生命周期定义了很多个扩展点，可以插手这个生命周期过程
 
你在系统里用xml或者注解，定义一大堆的bean
 
* （1）实例化Bean：如果要使用一个bean的话
* （2）设置对象属性（依赖注入）：他需要去看看，你的这个bean依赖了谁，把你依赖的bean也创建出来，给你进行一个注入，比如说通过构造函数setter
* （3）处理Aware接口：如果这个Bean已经实现了ApplicationContextAware接口，spring容器就会调用我们的bean的setApplicationContext(ApplicationContext)
方法，传入Spring上下文，把spring容器给传递给这个bean
* （4）BeanPostProcessor：如果我们想在bean实例构建好了之后，此时在这个时间带你，我们想要对Bean进行一些自定义的处理，那么可以让Bean实现了BeanPostProcessor
接口，那将会调用postProcessBeforeInitialization(Object obj, String s)方法。
* （5）InitializingBean 与 init-method：如果Bean在Spring配置文件中配置了 init-method 属性，则会自动调用其配置的初始化方法。
* （6）如果这个Bean实现了BeanPostProcessor接口，将会调用postProcessAfterInitialization(Object obj, String s)方法
* （7）DisposableBean：当Bean不再需要时，会经过清理阶段，如果Bean实现了DisposableBean这个接口，会调用其实现的destroy()方法；
* （8）destroy-method：最后，如果这个Bean的Spring配置中配置了destroy-method属性，会自动调用其配置的销毁方法。

创建+初始化一个bean -› spring容器管理的bean长期存活 -› 销毁bean（两个回调函数）

### spring中的bean是线程安全的吗？
不是的，而且spring中的bean，spring并没有对此保证线程安全性。原因先讲5个作用域:
>1 Singleton: Spring的默认作用域，为每个ioc容器创建唯一的Bean  ，多个线程会进入同一段代码来执行
>2 ProtoType: 针对每个 getBean 请求，容器都会单独创建一个 Bean 实例  
>3 Request: 为每个 HTTP 请求创建单独的 Bean 实例  
>4 Session: 每个Session单独一个Bean实例
>5 GlobalSession: 用于 Portlet 容器

### Spring中使用到哪些设计模式?
* 工厂模式:把创建对象的过程封装起来，封装在工厂中，用静态方法封装。(spring ioc核心 
的设计模式思想体现，自己就是一个大工厂，把所有的bean实例都给放在了spring容器里（大工厂），如果你要使用bean，就找spring容器就可以了，你自己不用创建对象了)
* 单例模式:spring默认来说，对每个bean走的都是一个单例模式，确保说你的一个类在系统运行期间只有一个实例对象，只有一个bean，用到了一个单例模式的思想，保证了每个bean都是单例的
* 代理模式:如果说你要对一些类的方法切入一些增强的代码，会创建一些动态代理的对象，让你对那些目标对象的访问，先经过动态代理对象，动态代理对象先做一些增强的代码，调用你的目标对象

* BeanFactory和ApplicationContext应用了工厂模式。
* 在 Bean 的创建中，Spring 也为不同 scope 定义的对象，提供了单例和原型等模式实现。
* AOP 使用了代理模式、装饰器模式、适配器模式等。
* 各种事件监听器，是观察者模式的典型应用。
* 类似 JdbcTemplate 等则是应用了模板模式。

### 6. SpringBoot创建定时任务的三种方法
(1) 基于注解@Scheduled
(2) 基于实现接口SchedulingConfigurer，主要用于需要从数据库读取cron表达式执行的场景
(3) 基于注解@Scheduled和@Async("线程池bean名称"),将定时任务标记为异步任务，然后用指定的线程池来执行

### SpringMVC的核心架构？
（1）tomcat的工作线程将请求转交给spring mvc框架的DispatcherServlet
（2）DispatcherServlet查找@Controller注解的controller，我们一般会给controller加上你@RequestMapping的注解，标注说哪些controller用来处理哪些请求，此时根据请求的uri，去定位到哪个controller来进行处理
（3）根据@RequestMapping去查找，使用这个controller内的哪个方法来进行请求的处理，对每个方法一般也会加@RequestMapping的注解
（4）他会直接调用我们的controller里面的某个方法来进行请求的处理
（5）我们的controller的方法会有一个返回值，以前的时候，一般来说还是走jsp、模板技术，我们会把前端页面放在后端的工程里面，返回一个页面模板的名字，spring mvc的框架使用模板技术，对html页面做一个渲染；返回一个json串，前后端分离，可能前端发送一个请求过来，我们只要返回json数据
（6）再把渲染以后的html页面返回给浏览器去进行显示；前端负责把html页面渲染给浏览器就可以了
