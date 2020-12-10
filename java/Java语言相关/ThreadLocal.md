#### 使用静态变量来共享对象带来的问题  --> 线程不安全

```java
import java.text.SimpleDateFormat;

/**
 * 多线程环境下使用 静态变量来共享对象 并不安全
 */
public class ThreadLocalDemo1 {
    public static void main(String[] args) {
        for (int i = 1; i <= 5; i++) {
            final int temp = i;
            new Thread(() ->
                    System.out.println(UnThreadSafeFormatter.sdf.format(temp * 1000))).start();
        }
    }
}

class UnThreadSafeFormatter {
    public static SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
}
```

```bash
# 运行结果-错误
1970-01-01 08:00:05
1970-01-01 08:00:05
1970-01-01 08:00:05
1970-01-01 08:00:03
1970-01-01 08:00:02
```

* 用锁也可以解决，但是有性能损耗，更好的办法是使用ThreadLocal

```java
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * 使用ThreadLocal给每个线程设置一个初始值，避免了共享变量，做到了线程安全
 */
public class ThreadLocalDemo2 {
    public static void main(String[] args) {
        for (int i = 1; i <= 5; i++) {
            final int temp = i;
            new Thread(() ->
                    System.out.println(ThreadSafeFormatter2.dateFormatThreadLocal.get().format(new Date(temp * 1000)))).start();
        }
    }
}

class ThreadSafeFormatter2 {
    public static ThreadLocal<SimpleDateFormat> dateFormatThreadLocal =
            ThreadLocal.withInitial(() -> new SimpleDateFormat("yyyy-MM-dd hh:mm:ss"));
}
```

```bash
# 运行结果-正确
1970-01-01 08:00:05
1970-01-01 08:00:04
1970-01-01 08:00:01
1970-01-01 08:00:02
1970-01-01 08:00:03
```

#### ThreadLocal的两大使用场景(用途)

* 典型场景1: 每个线程需要一个独享的对象(通常是工具类，典型需要使用的类有SimpleDataFormat 和 Random)，需要通过ThreadLocal.withInitial()来对每个线程初始化一个对象

  每个Thread内有自己的实例副本，不和其他线程共享。就像教材只有一本，一起做笔记有线程安全问题，复印后每人一本就没问题了

* 典型场景2: 每个线程内需要保存一个全局变量可以让不同方法直接使用(例如在拦截器中获取用户信息)，避免参数传递的麻烦,强调的是同一个请求内(同一个线程内)不同方法间的共享。不需要使用ThreadLocal.withInitial()赋初值，但是必须手动调用set()方法

```java
import lombok.Getter;

/**
 * 使用 ThreadLocal 来保存线程全局变量，避免层层方法传递参数
 */
public class ThreadLocalDemo4 {
    public static void main(String[] args) {
        ThreadLocalDemo4 demo4 = new ThreadLocalDemo4();
        // 将用户信息放入ThreadLocal
        demo4.serviceMethod1();
        // 然后直接从当前线程的ThreadLocal中取出用户信息
        demo4.serviceMethod2();
        demo4.serviceMethod3();
    }

    public void serviceMethod1() {
        User user = new User("张三");
        UserInfoHolder.holder.set(user);
    }

    public void serviceMethod2() {
        User user = UserInfoHolder.holder.get();
        System.out.println("serviceMethod2()  -----> 获取到用户信息: " + user.getName());

    }

    public void serviceMethod3() {
        User user = UserInfoHolder.holder.get();
        System.out.println("serviceMethod3()  -----> 获取到用户信息: " + user.getName());
    }
}

class UserInfoHolder {
    public static ThreadLocal<User> holder = new ThreadLocal<>();
}

@Getter
class User {
    private String name;

    public User(String name) {
        this.name = name;
    }
}
```

#### 使用ThreadLocal带来的好处

1. 如果单纯用静态变量共享对象则有线程安全问题，ThreadLocal能做到线程安全
2. 无需加锁能提高执行效率
3. 能节省内存

ThreadLocal的两个作用
1. 让某个需要用到的对象在线程间隔离(让每个线程都有自己独立的对象)
2. 在任何方法中都可以轻松获得该对象
根据共享对象的生成时机不同，选择initialValue或者set来保存对象

1. 在ThreadLocal第一次get时候把对象初始化出来，对象的初始化时机可以由我们控制
2. set:如果需要保存到ThreadLocal里的对象的生成时机不由我们随意控制，例如拦截器生成的用户信息，用ThreadLocal.set直接放到我们的ThreadLocal中去，以便于后续使用
3. initialValue():通常每个线程最多调用一次此方法，但如果已经调用了remove()后，再调用get()，则可以再次调用此方法
4. 如果不重写本方法，这个方法会返回null，一般使用匿名内部类或lambd表达式方式来重写initialValue()方法，以便在后续使用中可以初始化副本对象

#### ThreadLoca有哪些常用方法？

```bash
T initialValue(): 用于初始化
void set(T t): 为当前线程设置一个新值
T get(): 获取当前线程对应的value值。先取出当前线程的ThreadLocalMap，然后调用map.getEntry方法，根据当前的  
如果是首次调用get()，则会调用setInitialValue来得到这个值
void remove():删除当前线程对应的值
```





#### Thread、ThreadLocal、ThreadLocalMap之间有什么关系？

