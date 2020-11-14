一个类只能有一个带有指定签名的构造器，编程人员通常知道如何避开这一限制:通过提供两个构造器，他们的参数列表只在参数类型的顺序上有所不同。
实际这并不是一个好主意。

方法签名包括：参数类型，参数顺序，不包括返回类型

Enum不允许继承，但是可以实现接口。

不写构造方法，编译器会自动提供一个共有的，无参的构造方法 

数组相关的工具类为Arrays，集合类的工具类为Collections

### 1. Stream求和
```
BigDecimal:
BigDecimal bb =list.stream().map(Plan::getAmount).reduce(BigDecimal.ZERO,BigDecimal::add);
 

int、double、long:
double max = list.stream().mapToDouble(User::getHeight).sum();

``` 

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

Final关键字修饰的变量
String的intern()是什么作用
方法的名字和参数列表称为方法的签名，返回类型不是签名的一部分。
如果将一个类声明为final，只有其中的方法自动的成为final，而不包括域

所有的数组类型，不管是对象数组还是基本类型的数组都扩展了object类

Arrays.deepToString

synchronized关键字是怎么实现可重入的？
当一个线程进入synchronized修饰的代码块中且该代码块未被其他线程访问时，JVM会记下锁的持有者，并且
将获取计数器值置为1.如果同一个线程再次获取这个锁时，计数器值将递增，而当线程退出同步代码块时，计数器会相应地递减。
当计数器值为0时，这个锁将被释放。

### 2. filter和interceptor有什么区别？
1. Filter是基于函数回调（doFilter()方法）的，而Interceptor则是基于Java反射的（AOP思想）。
2. Filter依赖于Servlet容器，而Interceptor不依赖于Servlet容器。
3. Filter对几乎所有的请求起作用，而Interceptor只能对action请求起作用。
4. Interceptor可以访问Action的上下文，值栈里的对象，而Filter不能。
5. 在action的生命周期里，Interceptor可以被多次调用，而Filter只能在容器初始化时调用一次。  
6. Filter在过滤是只能对request和response进行操作，而interceptor可以对request、response、handler、modelAndView、exception进行操作。

filter 继承OncePerRequestFilter,重写doFilterInternal方法
interceptor实现HandlerInterceptor接口，重写preHandle方法，其中postHandle方法是在业务处理器处理请求执行完成后，生成视图之前执行。
afterCompletion方法在DispatcherServlet完全处理完请求后被调用

Interceptor和AOP可以看作是类似的,因为其内部实现原理都是利用JAVA的反射机制(AOP是使用动态代理,动态代理的实现就是java反射机制).
但是Filter和Interceptor有本质上的区别.其实现是通过回调函数.两者的控制粒度也不同,AOP和Interceptor的控制粒度都是方法级别,
但是Filter的控制粒度就是servlet容器,它只能在servlet容器执行前后进行处理.

### 3.JDK 和 JRE 有什么区别？
* JRE 为 Java 提供了必要的运行时环境，JDK 为 Java 提供了必要的开发环境
* JDK 是 JRE 的超集，JRE 是 JDK 的子集

### 4. Java运行程序的步骤：
我理解的java程序执行步骤:
* 首先javac编译器将源代码编译成字节码。
* 然后jvm类加载器加载字节码文件，然后通过解释器逐行解释执行，这种方式的执行速度相对会比较慢。
* 有些方法是高频率调用的(JIT即时编译是以方法和代码块为单位的)，也就是所谓的热点代码，所以引进JIT技术，运行时将热点代码直接编译为机器码，
* 这样类似于缓存技术，运行时再遇到这类热点代码直接可以执行，而不是先解释后执行。

# IO
##你能聊聊BIO、NIO、AIO分别都是啥？有什么区别？
如果聊io这块，必问这个问题，因为io那些过于基础的知识比如流的使用主要是考察应届生和培训班刚出来的同学。正常问一个有经验的开发人员，io这块就是聊几种io模式，以及同步、异步、阻塞和非阻塞这几种io概念
* BIO():同步阻塞式IO，最传统的网络通信模型。

通信过程: 服务端创建一个SocketServer，然后客户端用一个socket去连接socketServer，当socketServer接收到一个socket连接请求时，会在服务端创建一个socket和一个线程去和客户端那个socket进行通信。这个进行通信的过程就属于同步阻塞式通信，当客户端socket发送一个请求时，服务端socket进行处理后才能给客户端socket返回，客户端socket在这期间什么事都不能干，只能在这里阻塞等待服务端的响应返回，这就是同步阻塞

缺点:每一个客户端接入都要在服务端创建一个线程来服务这个客户端，在大量客户端的场景，服务端的线程数量可能达到几千甚至几万，几十万，会导致服务端机器负载过高最后崩溃宕机。可以用一个线程池来改进前面这种状况，用固定的线程数量来处理请求，但是高并发请求时，还是可能会导致各种排队和延时，因为线程不够用。
* NIO():JDK1.4中引入了NIO，这是一种同步非阻塞式IO，基于Reactor模型
* 基本概念:
Buffer:缓冲区，一般都是将数据写入Buffer中，然后从Buffer中读取数据。有IntBuffer、LongBuffer、CharBuffer等很多种针对基础数据类型的Buffer。
Channel:NIO中都是通过Channel来进行数据读写的
Selector:多路复用器，selector会不断轮询已注册的Channel，如果某个channel上发生了读写事件，selector就会将这个Channel读取出来，然后通过SelectionKey获取有读写事件的channel，再进行io操作。
一个Selector通过一个线程，就可以轮询成千上万的channel，意味着服务端可以接入成千上万的客户端。这里相当于一个线程处理大量客户端请求，通过一个线程轮询大量的channel，每次获取一批有读写事件的channel，然后对每个请求启动一个线程处理。这里的核心就是非阻塞，selector一个线程可以不停轮询channel，所有客户端请求都不会阻塞，请求直接可以进来，大不了就是等待一下排个队而已
* 同步指的是工作线程从channel中读写数据，这个过程是同步的。工作线程的作用就是从channel中读写数据。当工作线程从channel中读数据时，数据没读完会卡住直到数据读完。当向channel
中写数据时，数据没写完也会卡住直到数据写完。
* 非阻塞指的是无论多少客户端都可以接入服务端，服务端只会创建一个channel然后注册到selector上，由一个selector线程不断轮询所有socket连接，有读写事件时通知channel，然后启动一个线程对channel进行处理

AIO():基于proactor模型，也就是异步非阻塞模型。
IO过程:每个连接发送过来的请求，都会绑定一个buffer。工作线程读取数据时，是提供给操作系统一个空的buffer，然后就可以去干其他事了。操作系统内核会将读取的数据写入buffer然后回调你的接口。写数据时是工作线程把带有数据的buffer交给操作系统内核，然后就可以去干别的事了。当操作系统完成了数据的写入后会回调接口
### 同步阻塞、同步非阻塞、异步非阻塞区别
* BIO同步阻塞，这个不是针对网络编程模型说的，而是针对磁盘文件的io读写来说的，FileInputStream，因为BIO是基于流读写文件，也就是说当客户端发起io请求时在请求未处理完成的这段时间会直接hang死，必须等io
处理完成后才能返回。
* NIO同步非阻塞，当通过NIO的FileChannel发起文件io操作后，请求发起后立即返回，这时候可以干别的事，这就是非阻塞，但是需要不断轮询操作系统，查看io操作是否完成
* AIO异步非阻塞，当通过AIO发起文件io操作后，立即可以返回去做别的事，当操作系统完成io操作后，会回调接口通知。
* 同步就是工作线程自己主动轮询操作系统，异步就是操作系统来回调工作线程的接口

### 7. 一个线程两次调用 start() 方法会出现什么情况？谈谈线程的生命周期和状态转移。
* Java 的线程是不允许启动两次的，第二次调用必然会抛出 IllegalThreadStateException，这是一种运行时异常，多次调用 start 被认为是编程错误。
在第二次调用 start() 方法的时候，线程可能处于终止或者其他（非 NEW）状态，但是不论如何，都是不可以再次启动的。

![avatar](../static/thread-1.png)

### 8.线程有哪几个状态？

在任意一个时间点中，一个线程只能有且只有其中的一种状态，并 且可以通过特定的方法在不同状态之间转换

Java 5 以后，线程状态被明确定义在其公共内部枚举类型 java.lang.Thread.State 中，6种分别是：
* 新建（NEW），表示线程被创建出来还没真正启动的状态，可以认为它是个 Java 内部状态。
* 就绪（RUNNABLE），表示该线程已经在 JVM 中执行，当然由于执行需要计算资源，它可能是正在运行，
也可能还在等待系统分配给它 CPU 片段，在就绪队列里面排队。在其他一些分析中，会额外区分一种状态 RUNNING，但是从 
Java API 的角度，并不能表示出来。
* 阻塞（BLOCKED），这个状态和我们前面两讲介绍的同步非常相关，阻塞表示线程在等待 Monitor lock。比如，线程试图通过 synchronized 
去获取某个锁，但是其他线程已经独占了，那么当前线程就会处于阻塞状态。
* 等待（WAITING），表示正在等待其他线程采取某些操作。一个常见的场景是类似生产者消费者模式，发现任务条件尚未满足，就让当前消费者线程等待（wait），另外的生产者线程去准备任务数据，然后通过类似 notify 
等动作，通知消费线程可以继续工作了。Thread.join() 也会令线程进入等待状态。
* 计时等待（TIMED_WAIT），其进入条件和等待状态类似，但是调用的是存在超时条件的方法，比如 wait 或 join 等方法的指定超时版本，如下面示例：public final native void wait(long 
timeout) throws InterruptedException;
* 终止（TERMINATED），不管是意外退出还是正常执行结束，线程已经完成使命，终止运行，也有人把这个状态叫作死亡。

### 8.为什么volatile只能保证可见性不保证原子性？
* volatile保证的可见性是指当一条线程修改了这个变量的值，新值对于其他线程来说是可以立即得知的，(每一条线程获取volatile变量值时，
拿到的确实是那个时刻的最新值，但是由于volatile变量是没有限制并发修改的，所以无法保证原子性)，
而普通变量不能做到这一点。普通变量的值在线程间传递时均需要通过主内内存来完成。例如，线程A修改
 一个普通变量的值，然后向主内存进行回写，另外一条线程B在线程A回写完成后再对主内存进行读取操作，
 新变量值才会对线程B可见。
 
* 可见性就是指当一个线程修改了共享变量的值时，其他线程能够立即得知这个修改。Java内存模型是通过在变量修改后将新值同步回主内存，
在变量读取前从主内存刷新变量值这种依赖主内存作为传递媒介的方式来实现可见性的，无论是普通变量还是volatile变量都是如此。普通变量与volatile变量的区别是，
volatile的特殊规则保证了新值 能立即同步到主内存，以及每次使用前立即从主内存刷新。因此我们可以说volatile保证了多线程操作时变量的可见性，而普通变量则不能保证这一点。
 
* 每条线程内的工作内存与主内存同步存在延迟，这也是普通变量无法保证可见性的原因
 
 对i++操作来说，读取，+1，写回。当一条线程读取到volatile变量值后，其他线程可能会在读取后
 把i值已经修改了，这时第一条线程读取到的值就变成过期数据了，这时将值+1后写回时，就可能会把错误值
 写回到主内存中。

* 一个变量i被volatile修饰，两个线程想对这个变量修改，都对其进行自增操作也就是i++，i++的过程可以分为三步，
首先获取i的值，其次对i的值进行加1，最后将得到的新值写回到缓存中。线程A首先得到了i的初始值100，
但是还没来得及修改，就阻塞了，这时线程B开始了，它也得到了i的值，由于i的值未被修改，即使是被volatile修饰，
主存的变量还没变化，那么线程B得到的值也是100，之后对其进行加1操作，得到101后，将新值写入到缓存中，再刷入主存中。
根据可见性的原则，这个主存的值可以被其他线程可见。问题来了，线程A已经读取到了i的值为100，
也就是说读取的这个原子操作已经结束了，所以这个可见性来的有点晚，线程A阻塞结束后，继续将100这个值加1，得到101，
再将值写到缓存，最后刷入主存，所以即便是volatile具有可见性，也不能保证对它修饰的变量具有原子性。

### 什么情况下变量适合用volatile修饰？如果volatile无法解决原子性该选取什么？
* 运算结果并不依赖变量的当前值，或者能够确保只有单一的线程修改变量的值
* 变量不需要与其他的状态变量共同参与不变约束。

* 不符合上面两条的，只能通过加锁（使用synchronized、java.util.concurrent中的锁或原子类）来保证原子性

### 9.Java内存模型的先行发生原则是做什么用的？
* Java内存模型操作简化为read，write，lock，unlock四种。
* 先行发生原则主要用来确定一个操作在并发环境下是否安全

### 10. ReentrantLock 与 synchronized 有什么区别？
* ReentrantLock 与 synchronized 相比增加了一些高级功能，主要有以下三项：等待可中断、可实现公平锁及锁可以绑定多个条件。
* 等待可中断：指的是当持有锁的线程长期不释放锁的时候，正在等待的线程可以选择放弃等待，改为处理其他事情。
可中断特性对处理执行时间非常长的同步块很有帮助。 
* 公平锁：指的是多个线程在等待同一个锁时，必须按照申请锁的时间顺序来依次获得锁；而非公平锁则不保证这一点，
在锁被释放时，任何一个等待锁的线程都有机会获得锁。synchronized中的锁是非公平的，
ReentrantLock在默认情况下也是非公平的，但可以通过带布尔值的构造函数要求使用公平锁。不过一旦使用了公平锁，
将会导致ReentrantLock的性能急剧下降，会明显影响吞吐量。 
* 锁绑定多个条件：是指一个ReentrantLock对象可以同时绑定多个Condition对象。在synchronized 中，
锁对象的wait()跟它的notify()或者notifyAll()方法配合可以实现一个隐含的条件，如果要和多于一个的条件关联的时候，
就不得不额外添加一个锁；而ReentrantLock则无须这样做，多次调用 newCondition()方法即可。


### 从JVM源码看synchronized:
https://blog.csdn.net/pange1991/article/details/84970574

### 11.如何用linkedHashMap实现一个lru？
```
/**
 * 利用现有的JDK数据结构来实现java版的LRU
 *
 * @param <K>
 * @param <V>
 */
class LRUCache<K, V> extends LinkedHashMap<K, V> {

    private final int CACHE_SIZE;

    // 这里就是传递进来最多能缓存多少个数据
    public LRUCache(int cacheSize) {
        /**
         * 这块就是设置一个hashmap的初始大小，同时最后一个true指的是让linkedHashMap按照访问顺序来进行排序，
         * 最近访问的放在头，最老访问的放在尾
         */
        super((int) Math.ceil(cacheSize / 0.75) + 1, 0.75f, true);
        CACHE_SIZE = cacheSize;
    }

    @Override
    protected boolean removeEldestEntry(Map.Entry eldest) {
        // 这个意思就是说当map中的数据量大于指定的缓存个数时，就自动删除最老的数据
        return size() > CACHE_SIZE;
    }
}
```
### 11.synchronized 和 Object 中的方法 wait，notify，notifyAll 的用法？
使用wait(),notify(),notifyAll()进行线程间通信必须和synchronized配合使用，
也就是说，synchronized支持的3种同步方法：同步代码块，同步方法，静态同步方法都是
可以搭配这3个方法使用的。如果没有搭配synchronized，直接调用这3个方法，会报java.lang.IllegalMonitorStateException，

* 执行完wait后会释放对象锁
* 执行notify后不会立即让出对象锁，而是必须把同步块中的程序执行完才会释放锁，这时才轮到wait线程执行
* notify会随机通知一个正在wait的线程

等待通知的经典范式：
等待方遵循的原则：
(1)获取锁
(2)如果条件不满足，调用锁对象的wait()方法，需要用while，这样在被通知后仍然会检查条件
(3)条件满足则执行对应的逻辑
伪代码:
```
synchronized (对象) {
     while (条件不满足) {
           对象.wait();
      }
     对应的处理逻辑
}
```
```
while(condition is not true) {
	 lock.wait() 
}
```
解释：两个消费者线程c1和c2，逻辑都是，判断资源是否为空，是就wait，否就消费一个；某个时
刻，两个线程都进入等待队列，然后生产者生产了一个资源，并执行notifyAll，唤醒c1和c2都进入锁
池，c1先获取锁，执行完消费掉资源，然后释放锁，此时，如果c2获得锁，如果是if逻辑，那么就会
进入消费代码，但是资源已经被c1消费掉了，可能抛出异常。如果是while逻辑，则不会进入消费代
码，而是继续等待。

在一般情况下，总应该调用notifyAll唤醒所有需要被唤醒的线程。可能会唤醒其他一些线程，但这不
影响程序的正确性，这些线程醒来之后，会检查他们正在等待的条件（循环检测），如果发现条件
不满足，就会继续等待

* 通知方遵循的原则:
(1)获得锁
(2)改变条件
(3)通知等待在对象上的所有线程
伪代码:
```
synchronized (对象){
     改变条件
     对象.notifyAll();
}
```

### 用3个线程轮流打印ABC:
```
public class PrintABC {
    final Object monitor = new Object();
    int count = 1;//轮次计数，从1开始，为了保证可见性，这里需要用volatile修饰
    String id = "A";//共享的
    int printCount;

    public PrintABC(int printCount) {
        this.printCount = printCount;
    }

    public void printA() throws InterruptedException {
        while (count < printCount) {
            synchronized (monitor) {
                while (!id.equals("A")) {
                    monitor.wait();
                }
                System.out.println(Thread.currentThread().getName() + "打印： " + id);
                id = "B";
                monitor.notifyAll();
            }

        }
    }

    public void printB() throws InterruptedException {
        while (count < printCount) {
            synchronized (monitor) {
                while (!id.equals("B")) {
                    monitor.wait();
                }
                System.out.println(Thread.currentThread().getName() + "打印： " + id);
                id = "C";
                monitor.notifyAll();
            }

        }
    }

    public void printC() throws InterruptedException {
        while (count < printCount + 1) {//最后一次终结线程，需要多加一次
            synchronized (monitor) {
                while (!id.equals("C")) {
                    monitor.wait();
                }
                System.out.println(Thread.currentThread().getName() + "打印： " + id + "\n");
                id = "A";
                count = count + 1;
                monitor.notifyAll();
            }
        }
    }

    public static void main(String[] args) {
        PrintABC printABC = new PrintABC(1000);

        Thread t1 = new Thread(() -> {
            try {
                printABC.printA();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

        });
        t1.setName("A线程");

        Thread t2 = new Thread(() -> {
            try {
                printABC.printB();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });
        t2.setName("B线程");

        Thread t3 = new Thread(() -> {
            try {
                printABC.printC();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });
        t3.setName("C线程");

        t2.start();
        t3.start();
        t1.start();
    }
}
```
synchronized方法加锁不是通过monitor指令，而是通过acc_synchronized关键字，判断方法是否同步

每个对象都有一个关联的monitor，比如一个对象实例就有一个monitor，一个类的Class对象也有一个monitor，如果要对这个对象加锁，那么必须获取这个对象关联的monitor的lock锁。monitor里面有一个计数器，从0开始的。其他的线程在第一次synchronized那里，会发现说myObject对象的monitor锁的计数器是大于0的，意味着被别人加锁了，然后此时线程就会进入block阻塞状态，什么都干不了，就是等着获取锁。

## volatile关键字:
如何讲清volatile关键字？
应该从内存模型开始讲起，然后讲原子性、可见性、有序性的理解。
然后讲volatile关键字本身的一些原理。volatile关键字是用来解决可见性和有序性，在有些罕见条件下，可以有效的保证原子性。在很多开源中间件系统的源码中，大量的使用了volatile
，每一个开源中间件系统或者是大数据系统，都是多线程并发。

### 适合用volatile 关键字的一个场景：
* 很多个线程都在运行，只要有一个线程更改了变量，其他线程必须要第一时间去知道这个变化。

### volatile底层原理，如何实现保证可见性的呢？如何实现保证有序性的呢？

（1）lock指令：volatile保证可见性
* 对volatile修饰的变量，执行写操作的话，JVM会发送一条lock前缀指令给CPU，CPU在计算完之后会立即将这个值写回主内存，同时因为有MESI缓存一致性协议，所以各个CPU都会对总线进行嗅探，自己本地缓存中的数据是否被别人修改
。如果发现别人修改了某个缓存的数据，那么CPU就会将自己本地缓存的数据过期掉，然后这个CPU上执行的线程在读取那个变量的时候，就会从主内存重新加载最新的数据了

lock前缀指令 + MESI缓存一致性协议

（2）内存屏障：volatile禁止指令重排序
* volatile是如何保证有序性的？加了volatile的变量，可以保证前后的一些代码不会被指令重排，这个是如何做到的呢？指令重排是怎么回事，volatile就不会指令重排，简单介绍一下，内存屏障机制是非常非常复杂的，如果要讲解的很深入

Load1：
int localVar = this.variable
Load2：
int localVar = this.variable2
LoadLoad屏障：Load1；LoadLoad；Load2，确保Load1数据的装载先于Load2后所有装载指令，他的意思，Load1对应的代码和Load2对应的代码，是不能指令重排的

Store1：
this.variable = 1
StoreStore屏障
Store2：
this.variable2 = 2

* StoreStore屏障：Store1；StoreStore；Store2，确保Store1的数据一定刷回主存，对其他cpu可见，先于Store2以及后续指令
* LoadStore屏障：Load1；LoadStore；Store2，确保Load1指令的数据装载，先于Store2以及后续指令
* StoreLoad屏障：Store1；StoreLoad；Load2，确保Store1指令的数据一定刷回主存，对其他cpu可见，先于Load2以及后续指令的数据装载

### volatile的作用是什么呢？
volatile variable = 1
this.variable = 2 => store操作

int localVariable = this.variable => load操作
对于volatile修改变量的读写操作，都会加入内存屏障

每个volatile写操作前面，加StoreStore屏障，禁止上面的普通写和他重排；每个volatile写操作后面，加StoreLoad屏障，禁止跟下面的volatile读/写重排

每个volatile读操作后面，加LoadLoad屏障，禁止下面的普通读和volatile读重排；每个volatile读操作后面，加LoadStore屏障，禁止下面的普通写和volatile读重排

### volatile变量的可见性在硬件底层是如何实现的？
```
volatile boolean isRunning = true;
isRunning = false;  -->  写volatile变量，这时会通过插入一个内存屏障在底层会触发flush处理器缓存的操作
while(isRunning){}  -->  读volatile变量，也会通过插入一个内存屏障，在底层触发refresh操作
```

* flush缓存:强制刷新数据到高速缓存(主内存)
* refresh:从总线嗅探发现某个变量被修改，必须强制从其他处理器的高速缓存(或者主内存)加载变量的最新值到自己的高速缓存里去 
* 从java层面来说，写volatile变量时，一是强制刷主内存，一个是过期掉其他处理器的高速缓存中的数据；读volatile变量时会发现高速缓存中的值过期，然后强制从主内存加载最新值
* 从硬件层面来说，对volatile变量的写操作，会执行flush处理器缓存，把数据刷到高速缓存(或者主内存)中；对volatile变量的读操作，会执行refresh处理器缓存，从其他处理器的高速缓存(或者是主内存)中读取最新值
### volatile在哪种场景下可以保证原子性？
* 当在32位虚拟机里面，对long/double类型变量的赋值写不是原子的，此时如果对变量加上了volatile，就可以保证在32位虚拟机里面对long/double类型变量的赋值写不是原子的，此时如果对变量加上了volatile
，就可以保证在32位虚拟机里面对long/double类型变量的赋值写是原子的了。
























