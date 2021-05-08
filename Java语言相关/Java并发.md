# ThreadLocal
ThreadLocal 的作用是提供线程内的局部变量，这种变量在线程的生命周期内起作用，减少同一个线程内多个函数或者组件之间传递公共变量的复杂度。
如果一段代码中所需要的数据必须与其他代码共享，那就看看这些共享数据的代码是否能保证在同一个线程中执行。如果能保证，我们就可以把共享数据的可见范围限制在同一个线程之内，这样，无须同步也能保证线程之间不出现数据争用的问题。  
* 使用场景：符合这种特点的应用并不少见，大部分使用消费队列的架构模式（如“生产者-消费者”模式）都会将产品的消费过程尽量在一个线程中消费完。其中最重要的一个应用实例就是经典 Web 
交互模型中的“一个请求对应一个服务器线程”（Thread-per-Request）的处理方式，这种处理方式的广泛应用使得很多 Web 服务端应用都可以使用线程本地存储来解决线程安全问题。

ThreadLocal:是一个关于创建线程局部变量的类，用ThreadLocal创建的变量只能被当前线程访问，其他线程无法访问和修改。
要想在一个线程中存储一些东西，必须以ThreadLocal为key，但是value可以为任何对象。这个结构被存储在线程的ThreadLocalMap中。一个线程中允许存在多个以不同ThreadLocal对象为key的对象，也就是说，一个线程中能存多个变量，前提是需要以不同的ThreadLocal为key

应用场景：存储交易id等信息，每个线程私有
aop中记录日志在前置切面中记录请求id，然后在后置通知中获取请求id
jdbc连接池

ThreadLocal和Thread之间的关系：
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
```
/* ThreadLocal values pertaining to this thread. This map is maintained
 * by the ThreadLocal class. */
 
ThreadLocal.ThreadLocalMap threadLocals = null;
```
当调用一个 ThreadLocal 的 set(T value) 方法时，先得到当前线程的 ThreadLocalMap 对象，然后将 ThreadLocal->value 键值对插入到该 Map 中。
```
public void set(T value) {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
}
```
get() 方法类似: 
```
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
```
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
* 主要是在线程池场景中发生内存泄漏。由于ThreadLocalMap的生命周期和Thread一样长，而threadLocalMap的key是弱引用的，当将key-value存入ThreadLocalMap后，发生gc时会将key
删除，这时ThreadLocalMap存入的数据变为null-value，如果当前线程迟迟不结束的话，这些key为null的Entry的value就会一直存在一条强引用链：Thread -> ThreaLocalMap -> Entry -> value永远无法回收，造成内存泄漏。

* JDK的解决方案：惰性删除，在每次get、set、remove时都会清除ThreadLocalMap里所有key为null的value。但是如果存入key-value后，不再调用get、set\remove，且弱引用key已被gc
回收了，这时还是会发生内存泄漏。
* 最佳实践:只要保证每次使用完ThreadLocal，都调用它的remove方法清除数据就可以保证不发生内存泄漏。在线程池场景下如果没有及时清理ThreadLocal
不仅会发生内存泄漏也可能导致业务逻辑错误，所以使用ThreadLocal要像加锁和解锁一样，用完就清理

### key使用弱引用是导致ThreadLocal内存泄漏的原因吗？
从表面上看内存泄漏的根源在于使用了弱引用。网上的文章大多着重分析ThreadLocal使用了弱引用会导致内存泄漏，但是另一个问题也同样值得思考：为什么使用弱引用而不是强引用？

我们先来看看官方文档的说法：
```
To help deal with very large and long-lived usages, the hash table entries use WeakReferences for keys.
为了应对非常大和长时间的用途，哈希表使用弱引用的 key。
```

下面我们分两种情况讨论：

key 使用强引用：引用的ThreadLocal的对象被回收了，但是ThreadLocalMap还持有ThreadLocal的强引用，如果没有手动删除，ThreadLocal不会被回收，导致Entry内存泄漏。  

key 使用弱引用：引用的ThreadLocal的对象被回收了，由于ThreadLocalMap持有ThreadLocal的弱引用，即使没有手动删除，ThreadLocal也会被回收。value在下一次ThreadLocalMap调用set,get，remove的时候会被清除。

比较两种情况，我们可以发现：由于ThreadLocalMap的生命周期跟Thread一样长，如果都没有手动删除对应key，都会导致内存泄漏，但是使用弱引用可以多一层保障：弱引用ThreadLocal不会内存泄漏，对应的value在下一次ThreadLocalMap调用set,get,remove的时候会被清除。

因此，ThreadLocal内存泄漏的根源是：由于ThreadLocalMap的生命周期跟Thread一样长，如果没有手动删除对应key就会导致内存泄漏，而不是因为弱引用。


---

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

-----------------------
## Java中的锁
* 锁是用来控制多个线程访问共享资源的方式的，一般来说，一个锁能够防止多个线程同时访问共享资源(但是有些锁可以允许多个线程并发的访问共享资源，比如读写锁)。
* 自旋锁思想：当其他线程抢到锁后，本线程无限循环，抢锁，除非时间片到了，被迫让出cpu，本线程不阻塞，仍然处于就绪状态
* 可重入锁：可以多次进入同一个函数

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
```bash
// 以原子方式将给定值与索引 i 的元素相加。返回更新的值
 int addAndGet(int i,int delta);

// 如果当前值 == 预期值，则以原子方式将位置 i的元素设置为给定的更新值。如果成功则返回true，返回false表示实际当前值与预期值不相等
boolean compareAndSet(int i,int expect,int update);
```
### 更改传入构造方法的数组value，会不会影响到AtomicIntegerArray中的值？
不会。当把数组value通过构造方法传递进去后，AtomicIntegerArray会将当前数组复制一份，所以分别修改这两个数组不会互相影响。
如下为测试代码:
```java
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
```java
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
```java
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