# volatile:是JVM提供的轻量级的同步机制
##### 3个特性:
1.保证可见性
2.不保证原子性
3.禁止指令重排序

#### 保证可见性:
```java
public class VolatileDemo {

    /**
     * 不加volatile的现象:main线程将num改为1后，由于线程t1不知道主内存已经发生了变化，还在用自己工作内存的值去判断导致死循环
     * <p>
     * 加上volatile后保证了num变量的可见性，main线程修改num后，t1立刻感知到，然后停止了循环
     */
    public static int num = 0;

    public static void main(String[] args) throws InterruptedException {
        new Thread(() -> {
            while (num == 0) {
            }
        }, "t1").start();

        TimeUnit.SECONDS.sleep(1);
        num = 1;
        System.out.println(num);
    }
}
```

#### 不保证原子性:
```java
public class VolatileNotAtomicDemo {

    // 加volatile并不能每次都能得到正确结果，所以volatile不保证原子性
    public static volatile int num = 0;
    
    /**
     * 用原子类可以解决，用lock和synchronized也可以解决
     * 
     * AtomicInteger底层已经使用volatile的方式获取值了，所以这里不加volatile可以
     */
    public static AtomicInteger num = new AtomicInteger(0);

    public static void main(String[] args) {
        for (int i = 1; i <= 20; i++) {
            new Thread(() -> {
                for (int j = 1; j <= 1000; j++) {
                    increment();
                }
            }).start();
        }
        // 最少有两个线程 main线程和gc线程，大于2，说明计算线程还在跑
        while (Thread.activeCount() > 2) {
            Thread.yield();
        }
        System.out.println(num);
    }

    public static void increment() {
        // num++是一个复合操作，分成3步，先获取值，然后加1，再写回
        num++;
        num.getAndAdd(1);
    }
}
```
volatile无法保证原子性，那变量的原子性如何解决呢？
用JDK提供的原子类来解决


什么是指令重排?


### 禁止指令重排:
内存屏障是一个CPU指令，有两个作用:
1. 保证特定操作的执行顺序
2. 保证某些变量的内存可见性

volatile的保证变量可见性和禁止指令重排序这两个特性都是依靠底层用内存屏障指令来实现的