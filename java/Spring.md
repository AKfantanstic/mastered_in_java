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