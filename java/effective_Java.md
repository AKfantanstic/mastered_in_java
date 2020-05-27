一个类只能有一个带有指定签名的构造器，编程人员通常知道如何避开这一限制:通过提供两个构造器，他们的参数列表只在参数类型的顺序上有所不同。
实际这并不是一个好主意。

方法签名包括：参数类型，参数顺序，不包括返回类型

Enum不允许继承，但是可以实现接口。

不写构造方法，编译器会自动提供一个共有的，无参的构造方法

对象锁与类锁

读源码，JDK常用工具包源码，juc,util,读guava源码，同样也是一些工具包,各大公司spring肯定都用到了。读spring源码。慢慢读，读不明白配合各种书籍和博客。
这个过程很艰辛和很复杂，一般要有三年左右的时间过渡。

《redis设计与实现》《TCP/ip详解》 《计算机网络自顶向下方法》
《现代操作系统》《深入理解计算机系统》
《深入理解Java虚拟机》 ---> 《Java并发编程实战》
《Spring技术内幕》第一遍读，什么都不懂，按图索骥，迷迷糊糊的读完了；
第二遍读，就轻车熟路一些咯，“卧槽！原来如此！”的感叹声也络绎不绝；
第三遍就能够在整体代码设计和细节实现两个不同的层次上去吸收spring框架的优点咯。 

工作：
Java基础 -> 暂时不看 Java核心技术(暂时去掉Java编程思想)
Java容器 -> 1 看Java集合源码：ArrayList，HashMap，HashSet,HashTable,LinkedList,TreeMap，ConcurrentHashMap，JDK常用工具包源码，juc,util
Java并发 -> 2 Java并发编程的艺术
Java虚拟机 -> 3 (纯理论相关，及调优思路和方法，见猪跑)
MySQL的哪部分：手写sql(基本sql与复杂sql)，索引及相关数据结构，查找mysql相关试题
，最后去做LeetCode上database试题
记笔记用github开个项目
redis都算作数据库部分
学习今日头条中收藏的文章

地铁：
1 进阶训练营视频 或者是 极客时间架构课程

回家：
1 数据结构和算法：剑指offer，玩转数据结构，Java并发编程的艺术

展望：
1 挖掘项目细节
2 spring源码视频，进阶后看《Spring技术内幕》，结合源码

复习阶段主要分为三部分： 
学习「自己知道自己不会」的知识 
全方位的学习，构建自己的「知识体系」 
学习「自己不知道自己不会」的知识 

Stream求和
```
BigDecimal:
BigDecimal bb =list.stream().map(Plan::getAmount).reduce(BigDecimal.ZERO,BigDecimal::add);
 

int、double、long:
double max = list.stream().mapToDouble(User::getHeight).sum();

```

@Autowired默认是根据byType注入的，如果根据type获取到的对象大于1，则根据byName注入

ThreadLocal:对threadLocal的理解可以分为3个方面:
1.应用场景: 首先只适用于多线程场景，   框架应用场景：Spring的事务管理，用ThreadLocal存储Connection，从而各个DAO可以获取同一Connection，可以进行事务回滚，提交等操作。
 2.内部细节 3. 最佳实践
是个啥，字面翻译过来，这是个线程本地变量。首先它是个类，可以被实例化为对象，这对象就3个方法，get，set，remove


已掌握的算法工具箱：冒泡排序，插入排序，归并排序，快速排序，放弃(堆排序，桶排序，拓扑排序，希尔排序)







建议多使用JDK并发包提供的并发容器和工具类解决并发问题，因为这些类都已经通过了充分的测试和优化  
Java中所使用的并发机制依赖于JVM的实现和CPU的指令  
synchronized实现同步的基础：Java中每一个对象都可以作为锁。具体表现为下面3种形式：  
1. 对于普通同步方法，锁是当前实例对象  
2. 对于静态同步方法，锁是当前类的Class对象  
3. 对于同步代码块，锁是synchronized 括号里配置的对象  

Java将操作系统中的运行和就绪两个状态合并称为运行状态，阻塞状态是线程阻塞在进入synchronized
关键字修饰的方法或代码块(获取锁)时的状态，但是阻塞在java.concurrent包中Lock接口的线程状态确实等待状态
，因为java.concurrent包中Lock接口对于阻塞的实现均使用了LockSupport类中的相关方法。  

java支持多个线程同时访问一个对象或者对象的成员变量，由于每个线程执行过程中可以拥有一份拷贝，
这样可以加速程序的执行，这是现代多核处理器的一个显著特性。所以程序在执行过程中，一个线程看到的变量
并不一定是最新的。  

mq是一个常见的解耦利器
什么时候不用mq？上游实时关注执行结果

HashMap在并发执行put操作时会引起死循环，是因为多线程会导致HashMap的Entry链表形成环形数据结构，
一旦形成环形数据结构，Entry的next节点永远为空，就会产生死循环获取Entry

## 
