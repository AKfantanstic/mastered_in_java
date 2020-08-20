## ThreadLocal 线程本地变量(每个线程一份)
如果一段代码中所需要的数据必须与其他代码共享，那就看看这些共享数据的代码是否能保证在同一个线程中执行。如果能保证，我们就可以把共享数据的可见范围限制在同一个线程之内，这样，无须同步也能保证线程之间不出现数据争用的问题。  
* 使用场景：符合这种特点的应用并不少见，大部分使用消费队列的架构模式（如“生产者-消费者”模式）都会将产品的消费过程尽量在一个线程中消费完。其中最重要的一个应用实例就是经典 Web 
交互模型中的“一个请求对应一个服务器线程”（Thread-per-Request）的处理方式，这种处理方式的广泛应用使得很多 Web 服务端应用都可以使用线程本地存储来解决线程安全问题。

ThreadLocal:是一个关于创建线程局部变量的类，用ThreadLocal创建的变量只能被当前线程访问，其他线程无法访问和修改。
要想在一个线程中存储一些东西，必须以ThreadLocal为key，但是value可以为任何对象。这个结构被存储在线程的ThreadLocalMap中。一个线程中允许存在多个以不同ThreadLocal对象为key的对象，也就是说，一个线程中能存多个变量，前提是需要以不同的ThreadLocal为key

应用场景：存储交易id等信息，每个线程私有
aop中记录日志在前置切面中记录请求id，然后在后置通知中获取请求id
jdbc连接池

THreadLocal和Thread之间的关系：
每个Thread对象中都持有一个ThreadLocalMap的成员变量。每个ThreadLocalMap内部又维护了N个Entry节点，也就是Entry数组，每个Entry代表一个完整的对象，key是ThreadLocal本身，value是ThreadLocal的泛型值。这里证明一个线程中允许存在多个以不同ThreadLocal对象为key的对象

### Thread、ThreadLocal、ThreadLocalMap、Entry之间的关系？
Thread内部维护了一个ThreadLocalMap，而ThreadLocalMap里维护了Entry，而Entry里存的是以ThreadLocal为key，传入的值为value的键值对。ThreadLocalMap内部是用Entry数组实现的

### ThreadLocal里的对象一定是线程安全的吗？
不是的，如果ThreadLocal放入的value是一个多线程共享的对象，比如static对象，那这样并发访问还是线程不安全的

### 下面代码运行后输出的是什么？
```
public class TestThreadLocalNpe {
    private static ThreadLocal<Long> threadLocal = new ThreadLocal();

    public static void set() {
        threadLocal.set(1L);
    }

    public static long get() {
        return threadLocal.get();
    }

    public static void main(String[] args) throws InterruptedException {
        new Thread(() -> {
            set();
            System.out.println(get());
        }).start();
        // 目的就是为了让子线程先运行完
        Thread.sleep(100);
        System.out.println(get());
    }
}
输出:
1
Exception in thread "main" java.lang.NullPointerException
	at com.example.demo.controller.TestThreadLocalNpe.get(TestThreadLocalNpe.java:11)
	at com.example.demo.controller.TestThreadLocalNpe.main(TestThreadLocalNpe.java:21)
```
原因是:get方法用的long而不是Long，long是基本类型，默认值是0，没有null这一说法。ThreadLocal里的泛型是Long，get却是基本类型，这需要拆箱操作的，也就是会执行null.longValue()
的操作，所以导致空指针


每个 Thread 都有一个 ThreadLocal.ThreadLocalMap 对象。

/* ThreadLocal values pertaining to this thread. This map is maintained
 * by the ThreadLocal class. */
ThreadLocal.ThreadLocalMap threadLocals = null;
当调用一个 ThreadLocal 的 set(T value) 方法时，先得到当前线程的 ThreadLocalMap 对象，然后将 ThreadLocal->value 键值对插入到该 Map 中。

public void set(T value) {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
}
get() 方法类似。

public T get() {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null) {
        ThreadLocalMap.Entry e = map.getEntry(this);
        if (e != null) {
            @SuppressWarnings("unchecked")
            T result = (T)e.value;
            return result;
        }
    }
    return setInitialValue();
}
ThreadLocal 从理论上讲并不是用来解决多线程并发问题的，因为根本不存在多线程竞争。

在一些场景 (尤其是使用线程池) 下，由于 ThreadLocal.ThreadLocalMap 的底层数据结构导致 ThreadLocal 有内存泄漏的情况，应该尽可能在每次使用 ThreadLocal 后手动调用 remove()，以避免出现 ThreadLocal 经典的内存泄漏甚至是造成自身业务混乱的风险。




### ThreadLocal能和线程同步机制(如：synchronized)提供一样的功能吗？(ThreadLocal和Synchronized的区别)
不能，synchronized是保证多线程对共享变量修改的正确性，ThreadLocal是以线程为单位去保存线程本地变量。
也就是说，对于i++这个统计需求，synchronized可以实现，ThreadLocal即使存储了i的值，也无法保证不被其他线程修改

### ThreadLocal是线程私有的，那么就是说ThreadLocal的实例和他的值时放在栈上的了？(ThreadLocal变量存储在JVM哪个区域？)
ThreadLocal实例还是在堆上产生，因为ThreadLocal对象也是对象，对象就在堆上产生。JVM通过一些技巧把ThreadLocal变量的可见性变成了线程可见

### ThreadLocal真的只是当前线程可见吗？
不是的，通过InheritableThreadLocal类可以实现多个线程访问ThreadLocal的值

### ThreadLocal会导致内存泄漏吗？




### 2. 并发与并行有什么区别？
个人理解，并发是一种竞争关系，并行是一种合作关系。一堆砖由两个人搬，把一堆砖如何分为两部分，然后让每个人各搬一部分，
这是并行。而并发考虑的是两个人一起搬这堆砖，需要解决的是保证两个人不能同时从这堆砖中拿出一块搬走。  

主语言本身以及它的高级特性，第二个阶段是讲述自己的项目，并在中间穿插着问题。
一个线程就是在进程中的一个单一的顺序控制流
如果希望任务完成后有一个返回值，那么需要实现callable接口，callable<String>,返回值类型为Future<String>，
必须使用ExecutorService.submit()方法调用它。因为异常不能跨线程传播，所以必须在本地(run方法中)处理所有在任务内部产生的异常
可以把单线程程序(单线程)看作问题域求解的单一实体，每次只能做一件事，也可以看作是一个盒子，
每次只能装一个东西，装了这个就不能装那个了，也可以看作一根线程，不准确，因为线程是一个容器，
一个盛放任务的容器。也可以是一个停车场，每次只能停一辆车
会被并发访问的资源，需要考虑要不要加锁，将这个资源保护起来。
防止由并发访问造成的错误的方法就是当资源被第一个访问的任务访问时，必须锁定这项资源，
使其他任务在这项资源被解锁之前，无法访问到这项资源。
基本上所有的并发模式在解决线程冲突问题的时候，都是采用序列化访问共享资源的方案。
这意味着在给定时刻只允许一个任务访问共享资源。通常这是通过在代码前面加上一条锁语句来实现的，
这就使得在一段时间内只有一个任务可以运行这段代码。因为锁语句产生了一种互相排斥的效果。
相当于多人洗浴占用浴室场景：多个人(即多个由线程驱动的任务)都希望能单独使用浴室(即使用共享资源)。
为了使用浴室，一个人先敲门，看看能否使用。如果没人的话，他就进入浴室并锁上门。这时其他人要使用浴室，
就会被“阻挡”，所以他们要在浴室门口等待，直到浴室可以使用。当浴室使用完毕，就该把浴室给其他人使用了(其他任务就可以访问资源了)。
在使用synchronized进行同步时，在使用并发时，将域设置为private是非常重要的，否则，synchronized关键字
就不能防止其他任务直接访问域，这样就会产生冲突。意思就是把所有的域都设置为private，然后提供getter，setter方法来修改，
如果用对象.filed来修改filed，这种方式的修改，synchronized是无法保证同步的。

什么时候需要用同步呢？brian同步原则：
如果你正在写一个变量，它可能接下来被另一个线程读取，或者正在读取一个上一次已经被另一个线程写过的变量，
那么你必须使用同步，并且，读写线程都必须用synchronized同步。

### 3.Java 并发类库提供的线程池有哪几种？ 分别有什么特点？
开发者都是利用 Executors 提供的通用线程池创建方法，去创建不同配置的线程池，
主要区别在于不同的 ExecutorService 类型或者不同的初始参数。
  
Executors 目前提供了 5 种不同的线程池创建配置：  
* newCachedThreadPool()，它是一种用来处理大量短时间工作任务的线程池，具有几个鲜明特点：它会试图缓存线程并重用，
当无缓存线程可用时，就会创建新的工作线程；如果线程闲置的时间超过 60 秒，则被终止并移出缓存；长时间闲置时，
这种线程池，不会消耗什么资源。其内部使用 SynchronousQueue 作为工作队列。

* newFixedThreadPool(int nThreads)，重用指定数目（nThreads）的线程，其背后使用的是无界的工作队列，
任何时候最多有 nThreads 个工作线程是活动的。这意味着，如果任务数量超过了活动队列数目，
将在工作队列中等待空闲线程出现；如果有工作线程退出，将会有新的工作线程被创建，以补足指定的数目 nThreads。

* newSingleThreadExecutor()，它的特点在于工作线程数目被限制为 1，操作一个无界的工作队列，
所以它保证了所有任务的都是被顺序执行，最多会有一个任务处于活动状态，并且不允许使用者改动线程池实例，
因此可以避免其改变线程数目。

* newSingleThreadScheduledExecutor() 和 newScheduledThreadPool(int corePoolSize)，
创建的是个 ScheduledExecutorService，可以进行定时或周期性的工作调度，区别在于单一工作线程还是多个工作线程。

* newWorkStealingPool(int parallelism)，这是一个经常被人忽略的线程池，Java 8 
才加入这个创建方法，其内部会构建ForkJoinPool，利用Work-Stealing算法，并行地处理任务，不保证处理顺序。



## 线程池的用处:并行执行任务，异步处理
使用线程池的好处：
当提交一个新任务到线程池时，线程池是怎样处理的？(ThreadPoolExecutor执行execute方法的内部处理流程)
(1)线程池判断核心线程池里的线程是否都在执行任务。如果不是，则创建一个新的工作线程来执行任务。
如果核心线程池里的线程都在执行任务，则进入下一个流程
(2)线程池判断工作队列(workQueue)是否已经满了。如果工作队列没有满，则将新提交的任务存储在这个工作队列里。
如果工作队列满了，则进入下个流程。
(3)线程池判断线程池的线程是否都处在工作状态。如果没有，则创建一个新的工作线程来执行任务。如果满了，则交给饱和策略来处理这个任务。
线程池的实现原理：线程池创建线程时，会将线程封装成工作线程worker，worker在执行完任务后，还会循环获取工作队列里的任务来执行。
jdk自带的几种饱和策略？
AbortPolicy 直接抛出异常，这是默认策略
DiscardPolicy，不处理直接丢弃掉
CallRunsPolicy，只用调用者所在线程来运行任务
DiscardOldestPolicy 丢掉队列里最近的一个任务，并执行当前任务
使用ThreadPoolExecutor创建线程池的几个参数？
corePoolSize(核心线程池的大小):
maximumPoolSize(线程池最大线程数量):线程池允许创建的最大线程数，注意：如果使用了无界的工作队列这个参数就没效果了
keepAliveTime:工作线程空闲后，允许存活的时间
ThreadFactory:用于设置创建线程的工厂，主要目的是通过工厂创建的线程可以设置更有意义的名字(可以用guava提供的ThreadFactoryBuilder为线程池里的线程快速设置有意义的名字)

调用线程池的prestartAllCoreThreads()方法，线程池会提前创建并启动所有基本线程。

### 如何向线程池提交任务？
execute()方法:用于提交不需要返回值的任务，所以无法判断任务是否被线程池执行成功
submit()方法:用于提交需要返回值的任务。线程池会返回一个future类型的对象，通过future对象可以判断任务是否执行成功。
调用future.get()方法可以获取返回值。get()方法会阻塞当前线程直到任务完成，
而get(long timeout,TimeUnit unit)会阻塞当前线程一段时间后，立即返回，这时任务有可能还没执行完，所以可能future对象携带的返回值可能是空对象

###如何关闭线程池？关闭线程池的原理是什么？
调用线程池的shutdown()或shutdownNow方法
原理：遍历线程池中的工作线程，逐个调用线程的interrupt方法来中断线程。所以无法响应中断的任务可能永远无法终止。
区别：shutdownNow先将线程池状态设置为STOP，然后尝试停止所有正在执行或暂停任务的线程。返回等待执行的任务列表(List<Runnable>)
shutdown将线程池状态设置为shutdown，然后中断所有空闲的线程
shutdown方法和shutdownNow如何选择？
一般通过调用shutdown方法来关闭线程池。如果任务不一定要执行完，则可以调用shutdownNow方法

### 说下线程池的生命周期？
running:能接受新提交的任务， 并且也能处理阻塞队列中的任务
shutdown:关闭状态，不再接受新提交的任务，但却可以继续处理阻塞队列中已保存的任务
stop:不能接受新任务，也不处理队列中的任务，会中断正在处理任务的线程。
tidying：所有的任务都已终止了，workerCount(有效线程数)为0
terminated：在terminated()方法执行完后进入该状态

描述下线程池的生命周期转换？

建议使用有界队列。

### 系统中大量使用线程池，需要对线程池进行监控，出现问题时，可以根据线程池的使用状况快速定位问题
可以使用线程池提供的参数进行监控:
taskCount:线程池需要执行的任务数量
completeTaskCount:已经完成的任务数量(小于等于taskCount)
largestPoolSize:线程池里曾经创建过的最大线程数量(可以通过该参数知道线程池是否满过，如果该数值等于线程池的最大大小，则表示线程池曾经满过)
getPoolSize:线程池中当前线程数量。(如果线程池不销毁的话，线程池里的线程不会自动销毁，所以这个大小只增不减)
getActiveCount:获取当前活动的线程数

## Java中的锁
* 锁是用来控制多个线程访问共享资源的方式的，一般来说，一个锁能够防止多个线程同时访问共享资源(但是有些锁可以允许多个线程并发的访问共享资源，比如读写锁)。
* 自旋锁思想：当其他线程抢到锁后，本线程无限循环，抢锁，除非时间片到了，被迫让出cpu，本线程不阻塞，仍然处于就绪状态
* 可重入锁：可以多次进入同一个函数
# Executor框架:

# **原子类**
一个变量被多个线程并发修改可能会发生错误，通常用synchronized来使修改串行化的方式来保证变量的正确性，JDK1.5的atomic包下的原子操作类可以不借助synchronized来保证变量的正确性
atomic包一共提供了4种类型，共13个类，atomic包中的类基本是使用unsafe实现的包装类

## 原子更新基本类:使用原子的方式更新基本类型(3个)
* AtomicBoolean: 原子更新布尔类
* AtomicInteger：原子更新整形类
* AtomicLong：原子更新长整型类
### AtomicInteger的常用方法:
```
// 以原子方式将给定值与当前值相加，并返回结果。
int addAndGet(int delta);

// 如果当前值 == 预期值，则以原子方式将该值设置为给定的更新值
boolean compareAndSet(int expect,int update);

// 以原子方式将当前值加1，注意这里返回的是自增前的值
int getAndIncrement();

// 以原子方式将当前值减1，注意这里返回的是自减前的值
int getAndDecrement();

// 以原子方式将当前值设置为newValue，并返回旧值
int getAndSet(int newValue);
```
### getAndIncrement是如何实现原子操作的呢？
```
public final int getAndIncrement() {
	// 调用unsafe方法的getAndAddInt来实现 
    return unsafe.getAndAddInt(this, valueOffset, 1);
}
```
```
public final int getAndAddInt(Object var1, long var2, int var4) {
    int var5;
    do {
		// 用do while循环来更新当前值，如果与预期值不符，重新计算，循环更新
        var5 = this.getIntVolatile(var1, var2);
    } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));
        return var5;
}
```
### 如何原子更新如char，float，double等其他基本类型呢？
* unsafe中只提供了3种cas方法，compareAndSwapObject、compareAndSwapInt和compareAndSwapLong,
那么AtomicBoolean源码中是怎么利用unsafe来原子更新的呢？AtomicBoolean源码中先把Boolean转为整型，然后再使用compareAndSwapInt进行cas，所以原子更新char，float和double变量也可以用类似思路来实现

### 原子更新数组:通过原子的方式更新数组里的某个元素(Atomic包提供了4个类)
* AtomicIntegerArray:原子更新整型数组里的元素
* AtomicLongArray：原子更新长整型数组里的元素
* AtomicReferenceArray:原子更新引用类型数组里的元素

以AtomicIntegerArray类为例介绍常用方法:
```
// 以原子方式将给定值与索引 i 的元素相加。返回更新的值
 int addAndGet(int i,int delta);

// 如果当前值 == 预期值，则以原子方式将位置 i的元素设置为给定的更新值。如果成功则返回true，返回false表示实际当前值与预期值不相等
boolean compareAndSet(int i,int expect,int update);
```
### 更改传入构造方法的数组value，会不会影响到AtomicIntegerArray中的值？
不会。当把数组value通过构造方法传递进去后，AtomicIntegerArray会将当前数组复制一份，所以分别修改这两个数组不会互相影响。
如下为测试代码:
```
public class AtomicIntegerArrayTest {
        static int[] value = new int[1,2];
        static AtomicIntegerArray ai = new AtomicIntegerArray(value);

        public static void main(String[] args) {
            ai.getAndSet(0, 3);
            System.out.println(ai.get(0));
            System.out.println(value[0]);
        }
}
输出结果：
3
1
```
### 原子更新引用类:(Atomic包提供了3个类)
* AtomicReference:原子更新引用类型
* AtomicReferenceFieldUpdater:原子更新引用类型里的字段
* AtomicMarkableReference:原子更新带有标记位的引用类型。可以原子更新一个布尔类型的标记位和引用类型。构造方法是AtomicMarkableReference(V initialRef,boolean initialMark)

代码示例如下:
```
public class AtomicReferenceTest {
    public static AtomicReference<User> atomicReference = new AtomicReference<>();
    public static void main(String[] args) {
        User user = new User("conan",15);
        atomicReference.set(user);
        User updaterUser = new User("shinichi",17);
        atomicReference.compareAndSet(user,updaterUser);
        System.out.println(atomicReference.get().getName());
        System.out.println(atomicReference.get().getOld());
    }
    static class User{
        private String name;
        private int old;
        public User(String name,int old){
            this.name = name;
            this.old = old;
        }
        public String getName(){
            return name;
        }
        public int getOld(){
            return old;
        }
    }
}
输出结果：
shinichi
17
```

### 原子更新字段类: 用于原子更新某个类里的某个字段(Atomic包提供了3个类)
* AtomicIntegerFieldUpdater:原子更新整型的字段
* AtomicLongFiledUpdater:原子更新长整型字段
* AtomicStampedReference：原子更新带有版本号的引用类型。能解决使用cas进行原子更新时可能出现的ABA问题

### 如何使用原子更新字段类？
>1. 因为原子更新字段类都是抽象类，所以每次使用时候必须用静态方法newUpdater()创建一个更新器，并且需要设置想要更新的类和属性
>2. 更新类的filed必须使用public volatile修饰符(如果不加 volatile修饰，会报java.lang.ExceptionInInitializerError
Caused by: java.lang.IllegalArgumentException: Must be volatile type)

以下为测试代码:
```
public class AtomicIntegerFieldUpdaterTest {
    private static AtomicIntegerFieldUpdater<User> a = AtomicIntegerFieldUpdater.newUpdater(User.class,"old");
    public static void main(String[] args) {
        User conan = new User("conan",10);
        System.out.println(a.getAndIncrement(conan));
        System.out.println(a.get(conan));
    }
    public static class User{
        private String name;
        public volatile int old;
        public User(String name,int old){
            this.name = name;
            this.old = old;
        }
        public String getName(){
            return name;
        }
        public int getOld(){
            return old;
        }
    }
}
输出结果:
10
11
```