# CountDownLatch:减法计数器

```java
import java.util.concurrent.CountDownLatch;

/**
 * 场景:一共有6个学生，放学后只有6个学生全部离开后，门卫才可以锁教室门
 * <p>
 * 原理:减法计数器
 * countDownLatch.countDown():数量减1
 * countDownLatch.await():等待计数器归零，然后再向下执行
 * 每次由线程执行完业务后调用countDown()使数量减1，当计数器变为0时，countDownLatch.await()就会被唤醒，继续往下执行
 */
public class CountDownLatchDemo {
    public static void main(String[] args) throws InterruptedException {
        // 总数是6
        CountDownLatch countDownLatch = new CountDownLatch(6);
        for (int i = 1; i <= 6; i++) {
            new Thread(() -> {
                System.out.println(Thread.currentThread().getName() + " go out");
                countDownLatch.countDown();
            }, String.valueOf(i)).start();
        }

        //等待计数器归0，然后再向下执行，在计数器没有归零前是阻塞在这里的
        countDownLatch.await();
        System.out.println("close door");
    }
}
```

# CyclicBarrier: 可循环使用的栅栏

```java
/**
 * 集齐7颗龙珠召唤神龙
 *
 * 原理:加法计数器
 */
public class CyclicBarrierDemo {
    public static void main(String[] args) {
        // 使用线程来召唤龙珠
        CyclicBarrier cyclicBarrier = new CyclicBarrier(7, () -> {
            System.out.println("召唤神龙成功!");
        });

        for (int i = 1; i <= 7; i++) {
            // lambda能操作到i吗？
            //Variable used in lambda expression should be final or effectively final
            // 所以用final定义一个临时变量供lambda使用
            final int temp = i;
            new Thread(() -> {
                System.out.println(Thread.currentThread().getName() + "收集" + temp + "个龙珠");
                // 等待
                try {
                    cyclicBarrier.await();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (BrokenBarrierException e) {
                    e.printStackTrace();
                }
            }).start();
        }
    }
}
```

# Semaphore:信号量
```java
public class SemaphoreDemo {
    /**
     * 原理:
     * semaphore.acquire()获得，如果已经满了，就等待直到位置被释放为止
     * semaphore.release()释放，会将当前信号量释放+1，然后唤醒等待的线程
     * 作用:多个共享资源互斥的使用，并发限流，控制最大线程数
     *
     * @param args
     */
    public static void main(String[] args) {
        // 允许的线程数量  停车位，限流用
        Semaphore semaphore = new Semaphore(3);
        for (int i = 1; i <= 6; i++) {
            new Thread(() -> {
                // acquire()得到
                // release()释放
                try {
                    // 获得，如果已经满了，就等待直到位置被释放为止
                    semaphore.acquire();
                    System.out.println(Thread.currentThread().getName() + "抢到车位");
                    TimeUnit.SECONDS.sleep(2);
                    System.out.println(Thread.currentThread().getName() + "离开车位");
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } finally {
                    // 释放，会将当前信号量释放+1，然后唤醒等待的线程
                    semaphore.release();
                }
            }, String.valueOf(i)).start();
        }
    }
}
```
运行结果:
```
1抢到车位
2抢到车位
3抢到车位
2离开车位
1离开车位
4抢到车位
5抢到车位
3离开车位
6抢到车位
4离开车位
5离开车位
6离开车位
```