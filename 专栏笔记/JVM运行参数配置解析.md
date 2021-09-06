## JVM启动相关参数设置

与内存相关的jvm参数:

```bash
#限制堆内存大小的参数
-Xms: Java堆内存的大小
-Xmx: Java堆内存的最大大小，允许扩张的最大大小，一般这两个参数都设置一样大小，用于限定Java堆内存的总大小
-Xmn: 堆内存新生代大小，扣除新生代剩下的就是老年代内存大小

#限制永久代大小的参数
-XX:PermSize: 永久代大小
-XX:MaxPermSize: 永久代最大大小

#JDK 1.8后修改了限制永久代大小的参数
-XX:MetaspaceSize
-XX:MaxMetaspaceSize
-Xss: 每个线程的虚拟机栈内存大小
```

与垃圾收集器相关的jvm参数：

```bash
-XX:+UseParNewGC :对新生代指定使用parNew垃圾收集器
-XX:ParallelGCThreads=4 :指定parNew垃圾收集器的gc线程数

-XX:+UseCMSCompactAtFullCollection :fullGC后再次进入stop the world，整理内存碎片，把存活对象往一个方向移动。默认打开
-XX:CMSFullGCsBeforeCompaction=5  :执行多少次fullGC后才执行一次内存碎片整理工作，默认是0

-XX:CMSInitiatingOccupancyFaction=92,老年代内存使用率为百分之多少呢，触发cms垃圾回收，jdk1.6默认值为92。也就是说当老年代被使用92%内存就会进行cms垃圾回收，留8%空间给并发清理期间minorGC把新对象放入老年代

```



