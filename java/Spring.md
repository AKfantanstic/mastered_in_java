什么是跨域：一句话：同一个ip，同一个网络协议，同一个端口，三者都满足就是同一个域，否则就是跨域.  

1. 自动装配注解的区别： 

1、@Autowired是Spring自带的，@Resource是JSR250规范实现的，@Inject是JSR330规范实现的  
2、@Autowired、@Inject用法基本一样，不同的是@Inject没有一个request属性  
3、@Autowired、@Inject是默认按照类型匹配的，@Resource是按照名称匹配的  
4、@Autowired如果需要按照名称匹配需要和@Qualifier一起使用，@Inject和@Name一起使用，@Resource则通过name进行指定  

2. filter中bean注入失败:  

![avatar](../static/filter1.png)

在spring中，web应用的启动顺序为：listener -> filter -> servlet,先初始花listener，
然后再初始化filter，接着才到dispatcherServlet的初始化，所以，当我们需要在filter里注入一个注解的bean时，就会注入失败。因为filter初始化时，注解的bean还没初始化，所以注入为null   

3. 用Spring Aop做切面编程时，如果切面处理类中出现异常，可能会影响切点方法(主业务逻辑)的执行。
解决方法:  
(1)不要用@Before 和@Around(5种通知类型还有一种@AfterThrowing)，而是采用@After 或者 @AfterReturning 等方式来处理，
让主业务逻辑走完后再执行切面方法,这样切面处理类的方法抛异常不影响主业务逻辑。  
(2)在切面处理类中try-catch住可能出异常的代码，不要向上抛
