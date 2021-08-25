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

