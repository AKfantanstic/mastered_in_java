---
typora-copy-images-to: ..\static
---

所谓jvm优化，就是尽可能让对象都在新生代里被分配回收，尽量别让太多对象频繁进入老年代，避免频繁触发fullGc对老年代进行垃圾回收。同时给系统充足的内存大小，避免新生代频繁进行minorGc。

fullgc优化的前提是minorgc的优化，minorgc的优化前提是合理分配内存空间，合理分配内存空间的前提是对系统运行期间的内存使用模型进行预估。

对于很多普通的java系统，只要对系统运行期间的内存使用模型做好预估，分配好合理的内存空间，尽量让minorgc后的存活对象留在survivor区不要去老年代，其余gc参数不做太多优化也不怎么会影响系统性能。

## 什么时候触发新生代 + 老年代的Mixed GC？
G1有一个参数是"-XX:InitiatingHeapOccupancyPercent",默认值是45%，就是说当老年代占用堆内存45%的Region时，尝试触发新生代+老年代一起回收的Mixed Gc。比如堆内存有2048个region,如果老年代占用了其中45%的region,也就是将近1000个Region时就会触发Mixed GC。

## G1的Mixed GC垃圾回收过程？
>1. 首先进入stop the world，触发初始标记阶段，这个阶段仅仅是标记一下gc roots的直接引用对象，速度很快。
>2. 然后恢复工作线程的运行，进入并发标记阶段，从GC roots开始追踪所有存活对象
(追踪GC Roots 间接引用的对象，也就是将GC Roots所引用的对象标记为存活状态)，由于要追踪全部的存活对象所以这个阶段很耗时，但是这个阶段可以和工作线程并行运行，所以不影响系统程序的运行。JVM会记录此阶段对象状态的变化，比如哪些对象被新创建，哪些对象失去了引用。
>3. 进入"Stop The World"状态，进入最终标记阶段，将上一阶段(并发标记阶段)JVm记录的对象做最终标记，标记一下哪些是存活对象，哪些是垃圾对象。
>4. 进入Mixed GC阶段(混合回收阶段)，然后计算新生代、老年代、大对象中每个Region的存活对象数量、存活对象比例、垃圾回收的预期性能、回收效率。先"Stop The World"停止工作线程，然后根据预期设定的停顿时间来选择部分Region进行回收。比如本次垃圾回收预期停顿时间为200ms，就会从新生代、老年代、大对象里都挑选出一些Region，以此来达到在指定的停顿时间内回收尽可能多的垃圾，这就叫做混合回收。这个阶段回收会被拆分为多次，也就是进行一次预期停顿时间的回收，然后恢复系统运行，然后再进次进行回收，通过参数"-XX:G1MixedGcCountTarget"来控制回收次数，默认值是 8，也就是先停止系统运行，混合回收一些Region，然后再恢复系统运行，重复8次。
Mixed Gc是基于复制算法对Region回收的，这样不会出现内存碎片，并且不需要CMS那样标记-清除后还需要进行内存碎片整理。还有一个参数"-XX:G1HeapWastePercent"，默认值是5%，意思是Mixed Gc过程中会不断空出新的Region，一旦空闲出来的Region数量达到了堆内存的5%，就立即停止MixedGC。
还有一个参数"-XX:G1MixedGcLiveThresholdPercent",默认值是85%，意思是在对Region回收时，只有存活对象低于85%的Region才能被回收(对存活对象比例高于85%的Region拷贝到其他Region，成本很高)

由于Mixed GC基于复制算法进行回收，所以一旦在拷贝过程中找不到空闲的Region来存放拷贝的对象，就会触发失败，而一旦失败，立即会"Stop The World"，然后采用单线程进行标记、清除、内存碎片整理，这个过程是很慢很慢的

## G1的回收过程？
* youngGC触发时机:新生代占用达到堆大小的60%,无法继续在新生代找到空间继续给分配对象。采用G1回收，最开始到eden区满了也不会立即开始gc，还会继续给新生代分配region，直到新生代占据region总数的60%（或者自定义的数值），才会对新生代回收
* youngGc过程：因为新生代占60%，老年代可用空间肯定小于新生代空间。所以接下来判断是否开启了空间担保，如果开启了则比较老年代可用空间和历次gc进入老年代对象的平均大小，如果大于则可以youngGc
，如果没有开启或者小于则直接进入oldGc。如果youngGc后的存活对象老年代放不下则进行一次oldGc。
* mixedGc触发时机:老年代占用堆空间的45%,无法继续在老年代找到空间分配给对象
* mixedGc过程：第一阶段，停止用户线程进入stop the world状态，以gc 
roots为起点开始标记哪些不是垃圾对象直到标记完成。第二阶段，恢复用户线程的运行，进入并发标记阶段，这时用户线程和垃圾回收标记线程并行执行，然后到第三阶段，再次进入stop the world状态，开始标记出在第一次stop the world和第二次stop the world之间产生的新垃圾对象，然后第四阶段混合回收，通过复制算法将region中存活对象拷贝到空的region中然后将整个region清空，所以此过程不产生内存碎片。将垃圾对象确定后，G1开始按照设定的预期停顿时间和停顿次数(默认8次)进入stop the world开始混合回收性价比最高的对象(还是region？)，也就是先停止系统运行再混合回收一些region，然后再恢复系统运行重复8次，如果回收次数少于8次则再次进行mixedGC(这里是什么意思？答疑篇其他同学总结的)，如果在回收的过程中空闲region大小达到堆内存的5%，就会提前结束本次gc。一旦在拷贝过程中找不到空闲的Region来存放拷贝的对象，就会触发失败，则转而使用serialOld用单线程重新开始一次gc过程，标记清除整理

## 名词定义:
* 年轻代GC:Minor GC/Young GC
* 老年代GC:Old GC。对于major GC到底指的是 Old GC还是 full GC，这个概念比较容易混淆，以后不用这个概念
* 针对新生代、老年代、永久代在内的全体内存空间的GC:fullGC
* Mixed GC:是G1中特有的概念，mixedGC同时对年轻代和老年代进行垃圾回收

## 每日百亿数据量的实时分析系统频繁发生FullGC情况的分析
* 案例介绍:一个实时分析系统不停从MySQL数据库提起大量数据到JVM内存里进行计算，负载大概是每分钟500次数据提取后计算，
分为5台机器，每台机器每分钟负责100次数据提取后计算，每次提取1万条数据，每次计算耗时10秒钟。每台机器是4核8G，JVM内存
给4G，其中新生代和老年代分别是1.5G内存空间，目前问题是会频繁发生FullGC
* 分析:这个系统多久会塞满新生代?
每台机器每分钟执行100次计算任务，每次是1万条数据需要计算10秒钟，这个系统的每条数据比较大，大概20个字段，可以
认为每条数据1KB大小，所以每次计算任务需要10MB大小，新生代按照8:1:1的比例分配，Eden区分到1.2GB，每个Survivor区
100MB，这样大概1分钟左右新生代塞满，然后在继续执行计算过程中，一定是需要先通过MinorGC回收一部分内存才能继续进行计算的
开始第一次MinorGC，先检查老年代可用空间是否大于新生代全部对象，此时老年代是空的(1.5G空闲)，新生代eden区有1.2G，这样即使MinorGC后
对象全部存活，老年代也是能放下的，所以进行minorGC。此时eden区有多少对象是存活的呢？eden区对象是被100个计算任务占满的
，当1分钟多过去时，假设80个计算任务完成，eden区还剩20个计算任务共计200MB还在计算中不能被回收，然后survivor区只有100MB
，所以survivor区放不下，只能通过空间担保机制放入老年代，然后eden区清空。接下来每分钟就是一个轮回，每分钟触发一次minorGC，
然后大概200MB左右数据进入老年代。当2分钟过去后，此时老年代400MB空间被占用，只有1.1GB可用，然后进入第3分钟，此时eden区是满的1.2GB，
先进行检查，检查老年代可用空间是否能放下全部eden区对象，此时放不下，然后检查"-XX:-HandlePromotionFailure"参数是否打开，默认是打开的，
所以就检查当前老年代可用空间是否大于历次minorGC后进入老年代对象的平均大小，之前算过了每次是200MB对象进入老年代，此时老年代可用空间还有
1.1GB，所以预计minorGC后大概率还是200MB对象进入老年代，所以可以放心触发一次MinorGC，然后当7分钟过去后，大概1.4GB对象已经进入了老年代，
老年代只剩100MB对象了，当进入第8分钟时，新生代eden区满了，此时检查老年代可用空间比每次minorGC平均进入老年代对象的大小要小，所以此时
直接触发一次fullGC，此时假设老年代被占据的1.4GB空间全部是可回收的，所以老年代控件被全部回收。然后进行minorGC，200MB对象再次从eden'区进入老年代。
所以平均下来是7、8分钟一次fullGC，这个频率已经很高了，因为每次fullGC速度都很慢，性能很差
* 优化方法:GC频繁的原因就是Survivor区太小，所以更改新生代内存比例，2GB分给新生代，1GB留给老年代，这样survivor区是200MB，每次刚好能放下minorGC后存活的对象，
这样每次MinorGC后200MB存活对象放入survivor区，然后下次minorGC时，整个survivor的对象对应的计算任务早就结束了，可以全部回收，而此时eden区的总1.6GB空间被占满，其中1,4GB
可以被回收掉，这样minorGC后，eden区和survivor区被清空，eden区仍在存活的200MB对象进入Survivor2区，这样基本很少对象会进入老年代，从而将
fullGC频率从几分钟一次降低到几个小时一次，大幅提升了系统的性能
* 负载扩大10倍后发生的状况:负载扩大10倍后，每秒钟要加载100MB数据，现在eden区空间是1.6GB，那么最多16秒就会塞满触发minorGC，
每次计算需要处理10秒钟才能处理完成，所以10多秒触发一次minorGC可能只能回收几百MB内存空间，还剩1GB对象内存无法被回收，只能放到老年代，
所以就导致每隔10秒钟就有1GB数据进入老年代，老年代总空间也就是1GB，这样第二个10秒过来时，就需要提前触发fullGC去回收老年代的1GB空间，然后
再把MinorGC后存活的1GB对象放入老年代。就会造成一台4核8G的机器每分钟要触发2、3次fullGC
* 优化方法: 将机器升级为16核32GB内存的高配置机器，eden区扩大10倍，有16GB，如果每秒加载100MB，要2分钟
左右才会触发一次MinorGC，这样每次MinorGC后存活对象大概有几百mB，不超过1GB。而目前每个survivor区域有2GB内存，
所以每次minorGC后的存活对象可以轻松放入survivor区，不会进入老年代。这样通过升级机器配置就解决了频繁GC问题。而由于这是一个
后台自动计算的系统，并不直接面向用户，所以即使2分钟1次MinorGC，每次停顿1秒钟也是没什么影响的，所以没必要使用G1来管理大内存来减少每次MinorGC
的停顿时间

## 作业: 打开脑洞，假设当你负责的系统负载增加10倍，100倍，在每台机器负载都很高的情况下，分析出minorGC频率？fullGC频率？如何负载扩大10倍后如何优化？
分析当前系统的机器配置、minorGC频率、fullGC频率、负载扩大10倍后如何升级机器、负载扩大100倍如何调整JVM参数

## oldGC的触发时机:
核心原因就是老年代可用空间不足
(1)youngGC之前检查，新生代历次youngGC后升入老年代对象的平均大小 大于当前老年代可用空间
(2)youngGC后的存活对象大于老年代当前可用空间
(3)老年代内存占用率达到92%

## G1的核心卖点:
低延时和管理大堆，由于使用划分Region的方式可以降低延时，从而可以管理大堆。
* G1和parNew的调优原则都是尽可能YoungGC，不进行或少进行oldGC。为什么G1适合大堆情况呢？因为如果大堆情况下使用parNew+CMS，必须等内存占满后才会触发GC，由于内存过大会一次需要回收几十G的垃圾，有可能会导致一次停顿多达几十秒，而使用G1，将大内存分成Region，然后G1按照预期设定的MaxPause来每次回收一小部分region,而不是对整个新生代回收。也就是把parNew的一次长停顿分成多个短停顿，从而降低延时

### 如何根据xss计算JVm中可以容纳多少个线程？
整个jvm内存大小减掉堆和方法区，除以xss(单个线程栈大小)大小。一般JVM内部也就最多几百个线程





























### youngGC场景复现:
```java
public class Demo1 {
    public static void main(String[] args) {
        byte[] array1 = new byte[1024*1024];
        array1 = new byte[1024*1024];
        array1 = new byte[1024*1024];
        array1 = null;
        byte[] array2 = new byte[2*1024*1024];
    }
}
```
```
JVM参数:
堆内存分配10MB，新生代分配5MB，其中Eden区占4MB，每个Survivor区占0.5MB，大对象阈值为10MB，年轻代使用parNew垃圾回收器，老年代使用CMS回收器
-XX:+PrintGCDetails  --->  打印详细的 gc 日志
-XX:+PrintGCTimeStamps ---> 打印每次 gc 发生时间
-Xloggc:gc.log  ---> 将 gc 日志写入磁盘文件
-XX:NewSize=5242880 -XX:MaxNewSize=5242880 -XX:InitialHeapSize=10485760 -XX:MaxHeapSize=10485760 -XX:SurvivorRatio=8 -XX:PretenureSizeThreshold=10485760 -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:gc.log
```
解析GC日志:
```
Java HotSpot(TM) 64-Bit Server VM (25.231-b11) for windows-amd64 JRE (1.8.0_231-b11), built on Oct  5 2019 03:11:30 by "java_re" with MS VC++ 10.0 (VS2010)
Memory: 4k page, physical 8246884k(1825456k free), swap 17684068k(7620872k free)
// 运行的 JVM 参数
CommandLine flags: -XX:InitialHeapSize=10485760 -XX:MaxHeapSize=10485760 -XX:MaxNewSize=5242880 -XX:NewSize=5242880 -XX:OldPLABSize=16 -XX:PretenureSizeThreshold=10485760 -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:SurvivorRatio=8 -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:+UseConcMarkSweepGC -XX:-UseLargePagesIndividualAllocation -XX:+UseParNewGC 
// JVM运行开始0.510s对象分配失败，触发gc，使年轻代占用空间从3463KB降低到512KB，耗时0.0030857秒。使整个堆空间占用从3463KB降低到1870KB，耗时0.0033517秒
0.510: [GC (Allocation Failure) 0.510: [ParNew: 3463K->512K(4608K), 0.0030857 secs] 3463K->1870K(9728K), 0.0033517 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
0.513: [GC (Allocation Failure) 0.513: [ParNew: 2679K->96K(4608K), 0.0014751 secs] 4038K->1965K(9728K), 0.0015300 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
// JVM 退出时打印出来的当前堆内存的使用情况 
Heap
  // parNew回收器负责的年轻代总共有4608KB(4.6MB)内存，已使用2214KB(2.5MB)
  par new generation   total 4608K, used 2214K [0x00000000ff600000, 0x00000000ffb00000, 0x00000000ffb00000)
  // eden区使用情况
  eden space 4096K,  51% used [0x00000000ff600000, 0x00000000ff811910, 0x00000000ffa00000)
  // from 区使用情况
  from space 512K,  18% used [0x00000000ffa00000, 0x00000000ffa180c8, 0x00000000ffa80000)
  // to 区使用情况
  to   space 512K,   0% used [0x00000000ffa80000, 0x00000000ffa80000, 0x00000000ffb00000)
  // CMS回收器管理老年代空间总计5MB，已使用1869KB
 concurrent mark-sweep generation total 5120K, used 1869K [0x00000000ffb00000, 0x0000000100000000, 0x0000000100000000)
  // 元空间使用情况
 Metaspace       used 3285K, capacity 4496K, committed 4864K, reserved 1056768K
  // 类空间使用情况
  class space    used 355K, capacity 388K, committed 512K, reserved 1048576K

```

youngGC后存活对象在survivor区放不下，并不是将全部存活对象都转移到老年代，而是将一部分对象放入Survivor区，剩余的部分放入老年代

当需要在新生代分配对象时，新生代内存不足就会触发youngGc，youngGc后Survivor区放不下，所以直接放入老年代，当老年代空间不足时触发一次fullGc(指的是由老年代垃圾回收器对老年代回收一次，再对metaspace回收一次)

虽然设置了大对象阈值为10mb，但是当分配一个8.2mb的对象大于8mb的Eden区时，连youngGc都不会触发，也不会判断是否符合大对象标准（8.2mb小于10mb），会将对象直接在老年代分配

一次youngGc后survivor区占用达到百分之百不会立即触发动态年龄判断机制从而将对象升入老年代，而是在下次youngGc完成时检查survivor区占用是否还超过50%，如果超过则动态年龄判断机制生效，将对象升入老年代

实际生产中对于survivor区，最好是让每次youngGc后的存活对象小于survivor区大小的50%，这样以免触发动态年龄判断机制让对象提前升入老年代。第一次youngGC后触发了动态年龄判断机制不会直接入老年代，要第二次触发youngGC后才会触发动态年龄判断机制让对象进入老年代

基于动态年龄判断机制来判断时，如果年龄1-5的对象占survivor区的50%，此时年龄大于等于5的对象都会进入老年代，这里是有等号的。

## 使用 jstat 工具查看 JVM 的内存使用情况及 gc 情况
```bash
jstat -gc Pid  // 查看java进程的内存及gc情况

S0C: From Survivor区大小
S1C: To Survivor区大小
S0U: From Survivor区当前使用的内存大小
S1U: To Survivor区当前使用的内存大小
EC: Eden区大小
EU: Eden区当前使用的内存大小
OC: 老年代大小
OU: 老年代当前使用的内存大小
MC: 方法区(永久代、元数据区)大小
MU: 方法区当前使用的内存大小
YGC: 系统运行至今的YoungGC次数
YGCT: YoungGC总耗时
FGC: 系统运行至今的FullGc次数
FGCT: FullGC总耗时
GCT: 所有GC的总耗时

还有一些其他命令:
jstat -gccapacity pid: 堆内存分析
jstat -gcnew pid: youngGC分析，TT和MTT可以看到对象在年轻代存活的年龄和存活的最大年龄
jstat -gcnewcapacity pid: 新生代内存分析
jstat -gcold pid: 老年代gc分析
jstat -gcoldcapacity pid: 老年代内存分析
jstat -gcmetacapacity pid: 元数据区内存分析
```

### 如何查看JVM中的对象分布？

使用顺序:先用 jmap -histo查看对象大致分布情况，然后使用jmap生成堆转储快照，最后用jhat去分析堆转储快照

```bash
jmap -heap pid  --> 查看当前堆内存各个区域的情况
jmap -histo pid --> 查看各种对象占用内存的大小按降序排列，占用内存最多的对象排在第一位 
也可以使用 jmap -dump:live,format=b,file=dump.hprof pid --> 在当前目录下生成一个dump.hprof的二进制文件，存的是这一时刻堆内存里所有对象的快照
还可以用 jhat dump.hprof -port 7000 --> 就可以在浏览器上访问这台机器的7000端口以图像化的方式去查看堆内存的对象分布情况
```

### 案例分析:大数据商家bi系统用于给商家实时生成经营数据报表，没什么大影响的频繁youngGC场景复现

* 背景介绍:最开始bi系统使用的商家不是很多，使用了几台普通4核8g机器，给堆内存中的新生代分配了1.5G内存，这样eden区大概是1G内存。由于每个商家的前端页面有一个js脚本定时请求接口来刷新数据，所以在商家用户暴涨时，每秒并发量就会达到几百，按每秒500个请求算，每个请求大概是100kb数据，所以每秒钟需要加载50mb数据到内存中进行计算。

* GC计算:每秒加载50MB数据到eden区，eden区大小为1G，所以20s就会填满eden区，然后触发一次youngGc，回收一次只需要几十ms，而且每次youngGC后存活对象可能就是几十MB，这种场景对用户和系统都是几乎没有影响的

* 场景复现:目标是用一段程序来模拟出bi系统的频繁youngGC的场景,堆内存设置为200MB，新生代分配100MB，eden区为80MB，每个Survivor区是10MB，老年代也是100MB

  JVM参数为:-XX:NewSize=104857600 -XX:MaxNewSize=104857600 -XX:InitialHeapSize=209715200 -XX:MaxHeapSize=209715200 -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=15 -XX:PretenureSizeThreshold=3145728 -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:gc.log

  示例程序:

  ```java
  public class Demo1 {
      public static void main(String[] args) throws Exception {
          Thread.sleep(30000);
          while (true) {
              loadData();
          }
      }
  
      private static void loadData() throws Exception {
          byte[] data = null;
          for (int i = 0; i < 50; i++) {
              data = new byte[100 * 1024];
          }
          data = null;
          Thread.sleep(1000);
      }
  }
  ```

  * gc分析:通过jstat -gc pid 1000 1000，每隔1秒钟输出gc状态发现，新生代eden区的对象增速为每秒5MB左右，当eden区使用量达到78MB时，再分配5MB就不够用了所以分配失败触发了youngGC，youngGC后Eden区只剩下3MB左右。所以是大概10几秒就触发一次youngGC，耗时1ms回收了70MB内存，youngGC后回收了大部分对象。整个过程没有触发fullGC，已经几乎不需要什么优化了。

  * 总结:通过一个示例程序的运行，可以通过jstat分析出如下信息:

    1. 新生代eden区对象的增长速率

    2. YoungGC的触发频率
    3. YoungGC的耗时
    4. 每次youngGC后有多少对象存活下来
    5. 每次youngGC后有多少对象进入老年代
    6. 老年代对象的增长速率
    7. FullGC的触发频率
    8. FullGC的耗时

###   案例分析:上亿数据量的实时计算系统频繁 fullGC 场景分析与复现:

* 背景介绍:实时计算系统不停从mysql拉取数据到jvm中计算，整个系统大概每分钟500次数据拉取和计算，部署了5台机器，所以也就是每台机器每分钟要执行100次数据提取与计算，每次拉取1万条数据，机器配置为4核8g，JVM内存分配了4G，新生代和老年代分别1.5G内存，按8:1:1的比例，eden区大小为1.2GB,每个survivor区100MB

* JVM计算:单台机器每分钟100次数据拉取并计算，每次是1万条数据需要计算10秒钟的时间。每条数据包含了20个字段，可以认为平均每条数据为1KB大小。所以每次计算任务的1万条数据就是10MB大小。这样计算大概1分钟左右会占满eden区。假设1分钟后80个计算任务执行完成，还剩20个计算任务没有完成，此时eden区存活对象共200MB，此时MinorGc无法将存活对象放入survivor区，因为survivor区只有100MB，所以会通过空间担保机制进入老年代，然后eden区被清空了。因为老年代空间为1.5GB，所以转折点发生在第7分钟，这时minorGC回收后的存活对象无法放入老年代了，这时触发fullGc。也就是7,8分钟发生一次fullGC

* 优化方案:这个系统最大的问题就是survivor区放不下存活对象，所以调整堆内存的分配，3GB的堆内存其中2GB分给新生代，1GB分给老年代，这样survivor区大概是200MB，基本每次都能放下存活对象。这样几乎不会有对象进入老年代，也就大大降低了fullGC的频率。通过这种优化成功将老年代fullGC频率从几分钟一次降低到了几小时一次

* 场景复现:大对象阈值改为20MB

  JVM参数为:-XX:NewSize=104857600 -XX:MaxNewSize=104857600 -XX:InitialHeapSize=209715200 -XX:MaxHeapSize=209715200 -XX:SurvivorRatio=8  -XX:MaxTenuringThreshold=15 -XX:PretenureSizeThreshold=20971520 -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:gc.log
  
  示例代码:
  
  

#### JDK1.6后去掉了"-XX:+HandlePromotionFailure"参数，他默认是比较历次youngGc后升入老年代的平均对象大小和老年代的剩余可用空间就可以了。所以JDK1.8不需要配置这个参数

### 案例实战:每秒 10 万 QPS 的社交 APP 优化 JVM 后性能提升 3 倍

问题现象:10W QPS的高并发查询下导致频繁fullGC

分析: 由于并发很高，在每次youngGC时会有很多请求没有处理完,导致存活对象过多，然后survivor区放不下，使对象提前进入了老年代。而JVM参数设置的是"-XX:+UseCmsCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=5"。由于CMS垃圾回收器默认采用标记-清除算法，所以会造成大量内存碎片，而参数表示在5次FullGC后会触发一次Compact操作，也就是压缩操作，会把所有存活对象向一个方向移动，也就是一个整理内存碎片的过程。

如何优化: 

1. 使用jstat分析各个机器上的jvm运行情况，判断每次youngGc后存活对象有多少，然后根据存活对象的大小调整survivor区大小，避免存活对象大小超过survivor区的50%，避免动态年龄判断使对象快速进入老年代。
2. 由于负载很高，这样调优过后还是会每小时有1次fullGC。所以第二个需要解决的是CMS回收器的内存碎片问题，需要设置参数"-XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0"。让CMS在每次fullGC后都要整理一下内存碎片，否则会产生正反馈，会使下一次FullGC更快到来

#### 案例实战:垂直电商APP后端系统的fullGC优化

问题现象: 后端系统使用默认jVM参数运行，导致有一定用户量后频繁FullGC

分析: 默认jVM参数的堆内存只有几百MB，当业务高峰期时由于堆内存不够导致频繁GC。

解决方案: 不使用默认JVM参数，自己定制JVM参数模版

```bash
# JVM 参数模板
-Xms4096M -Xms4096M -Xmn3072M -Xss1M -XX:PermSize=256M -XX:MaxPermSize=256M -XX:+UseParNewGC -XX:+UseConcMarkSweepGc -XX:CMSInitiatingOccupancyFraction=92 -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0 -XX:+CMSParallelInitialMarkEnabled -XX:+CMSScavengeBeforeRemark
# 8G内存机器，因为有其他进程会使用内存，所以给堆内存分配4G差不多
# 新生代给3G，让新生代尽量大一些，从而让每个Survivor区大一些，达到300MB左右。由于YoungGc时可能有部分请求没有处理完，存活对象大概有几十MB，survivor区能放的下，并且不会触发动态年龄判断规则
# 每次FullGC后压缩内存，整理一下内存碎片

# 用于优化 FullGC 性能的参数:
-XX:+CMSParallelInitialMarkEnabled : 这个参数会在CMS回收器的"初始标记阶段"开启多线程并行执行
-XX:+CMSScavengeBeforeRemark: 这个参数表示CMS重新标记阶段之前尽量先执行一次YoungGc。由于CMS的重新标记也会StopTheWorld，如果在重新标记之前先执行一次YoungGc回收掉新生代里失去引用的对象，在重新标记阶段就可以少扫描一些对象，可以提升CMS重新标记阶段的性能。如果这次YOungGC把大部分新生代对象回收了，那作为根的部分减少了，从而提高了remark的效率。老年代扫描的时候要确认老年代里哪些对象是存活的，这个时候必然会扫描到年轻代，因为有些年轻代的对象可能引用了老年代的对象，所以提前做youngGC可以把年轻代里一些对象回收掉，减少了扫描时间，可以提升性能
```

#### 案例实战:新手工程师增加不合理的JVM参数导致频繁FullGC

问题现象:线上频繁收到JVM fulGC报警，登录线上机器后，在GC日志里看到 "【Full GC(Metadata Threshold) xxxx,xxxxx】"，从这里知道这次的频繁fullGC是由metaspace元数据区导致的。元数据区一般都是存放一些加载到JVM中的类，为什么会因为metaspace频繁被塞满而导致fullGC呢，而fullGC会带动CMS回收老年代，也会对metaData区域进行回收

排查过程: 登录监控系统查看metaspace的内存占用情况，发现metaspace的空间使用情况呈现一个波动状态，先不断增加然后到达一个顶点后，触发了fullGc对metaSpace的垃圾回收，然后占用率就下降了。推测是由于有某些类不停被加载到metaSpace中，所以在JVm启动参数加上"-XX:TraceClassLoading -XX:TraceClassUnLoading"用于追踪类的加载和卸载情况，会在tomcat的catalina.out日志中打印出来，发现日志内容"Loaded sun.reflect.GeneratedSerializationConstructorAccessor from _JVM_Defined_Class",明显看到JVM在运行期间不停加载了大量的"GeneratedSerializationConstructorAccessor"到metaspace里。到这里知道了是由于代码中使用了反射，而在执行反射代码时，JVM会在代码被反复调用一定次数后就动态生成一些类放入metaspace，然后下次再执行反射时就直接调用这些类的方法，这是一个JVM底层优化机制。而JVM为反射创建的类都是软引用的(softReference)。正常情况下是不会回收软引用对象的，只有在内存紧张时才会回收软引用对象。

而软引用的对象到底在gc时要不要被回收怎么判断呢？

| 参数名                  | 含义                                  |
| ----------------------- | ------------------------------------- |
| clock                   | 当前时间戳                            |
| timestamp               | 上次被访问时间                        |
| freespace               | jvm中空闲内存空间的大小               |
| SoftRefLRUPolicyMSPerMB | 每1MB空闲空间允许软引用对象存活的时间 |

| 软引用实际存活时间 | 最大允许软引用存活时间              |
| ------------------ | ----------------------------------- |
| clock - timestamp  | freespace * SoftRefLRUPolicyMSPerMB |

"clock-timestamp <=freespace * SoftRefLRUPolicyMSPerMB"。当实际存活时间比允许存活时间小，则软引用可存活。否则被回收。例如当前JVM空闲内存为3000MB，SoftRefLRUPolicyMSPerMB默认值是1000ms，则JVM为反射创建的软引用的Class对象能存活的时间为3000*1s为3000秒，大概50分钟。而新手工程师把SoftRefLRUPolicyMSPerMB参数设置为0，导致允许软引用存活的时间为0，也就是JVM为反射刚创建出来的类会立刻被回收，然后继续创建这种类

解决办法:SoftRefLRUPolicyMSPerMB用默认值，或者是设置为1000ms、2000ms、5000ms都可以，提高这个数值后JVM自动创建的类对象就不会随便被回收了。修改后系统开始稳定运行

#### 案例实战:线上系统每天数十次FullGC导致频繁卡死的优化

问题现象:一般正常系统的fullGC频率大概几天发生一次或者最多一天发生几次。而新系统上线后发现每天的FullGC次数达到几十次甚至上百次，经过jVM监控平台+jstat工具分析得出每分钟3次youngGC，每小时2次fullGC。

线上JVM参数及内存分配情况:

```bash
-Xms1536M -Xmx1536 -Xmn512M -Xss256K -XX:SurvivorRatio=5 -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=68 -XX:+CMSParallelRemarkEnabled -XX:+UseCMSInitiatingOccupancyOnly -XX:+printGCDetaild -XX:+PrintGCTimeStamps -XX:+PrintHeapAtGC
```

双核4G机器，JVM堆内存分配1.5G，新生代分配512M，老年代1G，eden:survivor:survivor = 5:1:1,所以eden区大致为365M，每个Survivor区大致为70MB。比较关键的参数就是 CMSInitiatingOccupancyFraction 参数设置为68，也就是一旦老年代内存占用达到68%大概680MB左右就会触发FullGC

根据线上系统GC情况倒推运行内存模型:

* 新生代分析: 根据每分钟触发3次YoungGC，说明20秒就会占满Eden区的300MB空间，平均每秒钟产生15-20MB的对象

* 老年代分析: 根据每小时触发2次FullGC推断出30分钟触发一次FullGC，根据"-XX:CMSInitiatingOccupancyFraction=68"参数计算出老年代有600MB左右对象时就会触发一次FullGC，因为1GB的老年代有68%的空间占满就会触发FullGC了，所以系统运行30分钟会导致老年代里有600MB左右的对象，从而触发FullGC

  

  通过jstat分析发现，并不是每次YoungGC后都有几十MB对象进入老年代的，而是偶尔一次YoungGC才会有几十MB对象进入老年代，所以并不是新生代的存活对象太多导致Survivor区放不下触发动态年龄判定从而使存活对象进入老年代的。所以继续通过jstat观察发现，系统运行过程中，会突然有大概五六百MB对象一直进入老年代，所以这里已经出现答案了，一定是系统运行过程中每隔一段时间就会突然产生几百MB的大对象直接进入老年代，而不经过Eden区，然后再加上偶尔YoungGc后有几十MB对象进入老年代，所以导致了30分钟触发一次FullGC

  如何定位系统的大对象:通过jstat工具观察系统，什么时候发现老年代里突然进入了几百MB大对象，立即使用jmap工具导出一份dump内存快照，然后使用jhat或者是Visual VM之类的可视化工具来分析dump内存快照，分析过后发现是几个map，是从数据库查出来的，最后发现是由于某些特殊场景下会执行没有where 条件的查询语句，导致一次查询几十万条数据

  优化方法: 第一步，修改代码bug，避免代码中执行不加where条件的查询语句

  第二步，修改堆内存分配。由于偶尔还是会有存活对象进入老年代，所以很明显survivor区空间不够，所以改为新生代分配700MB，这样每个survivor区是150mb左右，老年代分配500MB就够了，因为一般不会有对象进入老年代，而且调整了参数"-XX:CMSInitiatingOccupancyFraction=92"，避免老年代仅仅占用68%就触发GC，然后主动设置永久代大小为256MB，如果不主动设置会导致默认永久代就只有几十MB，很容易导致万一系统运行时利用了反射，这样一旦动态加载类过多就会频繁触发GC

  #### 案例实战:电商大促活动下，严重FullGC导致系统直接卡死的优化

  问题背景: 新系统上线平时都是正常的，结果在大促活动下，系统直接卡死不动，所有请求到系统内直接卡住无法处理，无论怎么重启都没有任何效果

  排查过程: 使用jstat查看JVM各个内存区域的使用量，发现一切正常，年轻代对象增长并不快，老年代占用了不到10%空间，永久代使用了20%左右空间，怀疑是代码中存在"System.gc()"，结果发现确实存在这行代码。System.gc()每次被调用都会让jVM去尝试执行一次FullGC，连同新生代、老年代、永久代都会回收。平时系统访问量低时基本没问题，大促活动访问量高立马由"System.gc()"代码频繁触发了FullGC，导致整个系统被卡死

  优化方案:针对这个问题，为了防止代码中主动触发FullGC，可以在启动JVM参数中加入"-XX:+DisableExplicitGC"来禁止显式触发GC

  #### 案例实战:线上大促活动导致的内存泄漏和FullGC优化

  场景:大促活动刚开始就导致CPU使用率过高从而使系统直接卡死，无法处理任何请求，重启系统后会好一段时间，但是CPU马上又会使用率太高，继续卡死

  排查过程:

  一般线上机器cpu负载过高有两个常见场景:

  一是业务系统确实在扛高并发导致cpu负载过高，

  二是业务系统在频繁发生FullGC，fullGC是非常耗费cpu资源的。

  对于确定是哪种原因导致的cpu负载过高可以使用排除法，先看看fullGc的频率，如果fullGC频率不高则就是由于系统在扛高并发。通过监控平台发现业务系统fullGC频率十分频繁，几乎一分钟一次fullGC。

  频繁fullGC可能的4个原因:

  1. 内存分配不合理导致对象频繁进入老年代，进而引发频繁fullGC
  2. 存在内存泄漏，导致大量对象进入老年代，导致稍微有一些对象进入老年代就会引发fullGC
  3. metaspace加载类太多触发了fullGC
  4. 代码中错误执行了"System.gc()"

  通过使用jstat排查发现，老年代中驻留了大量对象，所以年轻代稍微有一些存活对象进入老年代，就很容易触发fullGC，而且fullGC无法回收掉之前老年代中驻留的大量对象，导致了频繁触发fullGC。

  通过jmap命令导出线上系统的内存快照:

  ```bash
  jmap -dump:live,format=b,file=dump.hprof pid
  ```

  然后使用MAT打开这个内存快照。分析后发现是在系统内做了一个本地缓存，但是没有限制本地缓存大小，并且也没有用LRU算法定期淘汰缓存中的数据所以导致缓存在内存中的对象越来越多，进而造成了内存泄漏 

  解决办法:使用EHcache缓存框架设置最多缓存多少个对象，然后使用LRU算法淘汰对象

  #### 什么是内存溢出？哪些区域会发生内存溢出？

  * 系统运行过程中申请内存时内存空间不足
  * metaspace、虚拟机栈、堆
  
  MetaSpace:通过参数"-XX:MetaspaceSize=512M"和"-XX:MaxMetaspaceSize=512M"来设置metaspace占用的内存大小，也就是说metaspace大小是固定的。一旦频繁加载类就会导致metaspace满，然后触发fullGC。fullGC会对old区和metaspace同时回收，也会带着回收新生代的youngGC。
  
  ##### 哪些情况下会导致metaspace内存溢出？
  
* 第一种原因:系统上线时直接用默认参数导致metaspace只有几十MB，导致稍微加载一些jar包中的类空间就不够了
* 第二种原因:使用cglib或反射动态生成一些类，代码中出现bug导致频繁加载类进而造成内存溢出
* 实际生产中只要合理分配metaspace大小，给512MB，同时代码中避免动态生成太多类，这样metaspace一般不会触发oom

虚拟机栈:栈中存储一个一个的栈帧，每个栈帧代表一个方法，并且栈帧里面有方法的局部变量，也就是说栈帧也是需要占用内存的，如果进行了无限制的方法递归，最终就会导致虚拟机栈内存溢出，也就是stackOverFlow

#### 一般只要代码上注意，不太容易会引发metaspace和虚拟机栈内存溢出。最容易引发内存溢出的，就是系统在堆上创建出来的对象太多了，最终导致系统堆内存溢出

#### 堆内存溢出的原因:

有限的内存中放了过多的对象，而且都是存活的无法被回收，所以无法继续放入更多对象，只能引发内存溢出
堆内存溢出的两种主要场景:

1. 系统承载高并发，由于请求量过大导致大量对象存活，gc回收又回收不掉，如果继续放入新对象就会引发OOM
2. 系统存在内存泄漏，导致大量对象存活，gc回收回收不掉，由于放不下更多对象了只能引发OOM

#### 使用cglib动态生成大量类来模拟metaspace内存溢出

有一个car类，只能启动后行驶，但现在想在启动前做些安全检查再行驶，使用cglib的Enhancer来动态生成car的子类来实现

```xml
<!-- 先导入cglib依赖 -->   
<dependency>
        <groupId>cglib</groupId>
        <artifactId>cglib</artifactId>
        <version>3.3.0</version>
</dependency>
```

```java
import net.sf.cglib.proxy.Enhancer;
import net.sf.cglib.proxy.MethodInterceptor;
import net.sf.cglib.proxy.MethodProxy;

import java.lang.reflect.Method;

public class CglibDemo {
    public static void main(String[] args) {
        long count = 0;
        while (true) {
            System.out.println("目前创建了" + count + "个car的子类");
            Enhancer enhancer = new Enhancer();
            enhancer.setSuperclass(Car.class);
           // 设置为不缓存，让类不停在 metaSpace 里创建
            enhancer.setUseCache(false);
            enhancer.setCallback(new MethodInterceptor() {
                @Override
                public Object intercept(Object o, Method method, Object[] objects, MethodProxy methodProxy) throws Throwable {
                    if (method.getName().equals("run")) {
                        System.out.println("启动汽车之前，先进行安全检查");
                        return methodProxy.invokeSuper(o, objects);
                    } else {
                        return methodProxy.invokeSuper(o, objects);
                    }
                }
            });
            Car car = (Car) enhancer.create();
            car.run();
            count++;
        }
    }
    static class Car {
        public void run() {
            System.out.println("启动成功，开始行驶");
        }
    }
}

```

```bash
# 设置运行的 JVM 参数，metaSpace设置为 10 MB
-XX:MetaspaceSize=10m -XX:MaxMetaspaceSize=10m
```

```bash
# 运行结果: --->  OOM
启动汽车之前，先进行安全检查
启动成功，开始行驶
目前创建了262个car的子类
Caused by: java.lang.OutOfMemoryError: Metaspace
	at java.lang.ClassLoader.defineClass1(Native Method)
	at java.lang.ClassLoader.defineClass(ClassLoader.java:763)
	... 11 more
```

#### 模拟线程虚拟机栈溢出

```bash
# 设置JVM参数,将栈内存设置为 1M
-XX:ThreadStackSize=1m
```

```java
public class ThreadStackDemo {
    static long count = 0;

    public static void work() {
        System.out.println("当前是第" + (++count) + "次调用方法");
        work();
    }

    public static void main(String[] args) {
        work();
    }
}
```

```bash
# 运行结果:调用6206次方法后栈溢出
当前是第6206次调用方法
Exception in thread "main" java.lang.StackOverflowError
	at sun.nio.cs.UTF_8$Encoder.encodeLoop(UTF_8.java:691)
	at java.nio.charset.CharsetEncoder.encode(CharsetEncoder.java:579)
	at sun.nio.cs.StreamEncoder.implWrite(StreamEncoder.java:271)
	at sun.nio.cs.StreamEncoder.write(StreamEncoder.java:125)
	at java.io.OutputStreamWriter.write(OutputStreamWriter.java:207)
	at java.io.BufferedWriter.flushBuffer(BufferedWriter.java:129)
	at java.io.PrintStream.write(PrintStream.java:526)
	at java.io.PrintStream.print(PrintStream.java:669)
	at java.io.PrintStream.println(PrintStream.java:806)
```

#### 模拟堆内存溢出

```bash
# 设置 JVM 参数,将堆内存设置为 10 MB
-Xms10M -Xmx10M
```

```java
import java.util.ArrayList;
import java.util.List;

public class OOMDemo {
    public static void main(String[] args) {
        long count = 0;
        List<Object> list = new ArrayList<>();
        while (true) {
            list.add(new byte[1024*1024]);
            System.out.println("当前创建了第 " + (++count) + " 个对象");
        }
    }
}
```

```bash
# 运行结果:
当前创建了第 7 个对象
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at java.util.Arrays.copyOf(Arrays.java:3210)
	at java.util.Arrays.copyOf(Arrays.java:3181)
	at java.util.ArrayList.grow(ArrayList.java:265)
	at java.util.ArrayList.ensureExplicitCapacity(ArrayList.java:239)
	at java.util.ArrayList.ensureCapacityInternal(ArrayList.java:231)
	at java.util.ArrayList.add(ArrayList.java:462)
	at com.example.juc.OOMDemo.main(OOMDemo.java:11)
```

#### 案例实战:导致大数据处理系统OOM的优化

系统背景:拉取数据--计算数据--推送数据

这个大数据系统会不停从mysql中加载大量数据到内存里进行复杂的计算，计算好后将结果通过 kafka 推送给另一个系统。当遇到kafka故障时，解决方案是将一次计算的结果全部驻留在内存中然后不停重试，直到kafka恢复。

故障背景:当kafka发生了短暂故障时，所有计算结果全部驻留在内存里无法推送到kafka，造成大量存活对象无法回收最终OOM

解决方案:取消大数据处理系统在kafka故障下的重试机制。一旦kafka故障了直接丢弃掉本地计算结果，把计算结果占用的大量内存释放，后续迭代的话，当kafka故障时，把计算结果写入本地磁盘然后将内存释放

#### 案例实战:es写日志bug导致死循环问题

背景:系统中需要将核心链路节点一些重要日志写入 ES 集群中，然后再基于 ELK 对日志进行分析。当某个节点发生异常时也需要将节点异常写入es集群中，需要知道系统异常发生的地方。当es集群故障时，log方法会死循环递归调用自己，导致StackOverFlow，直接导致了JVM进程崩溃

产生bug的代码:

```java
try{
    // 业务逻辑代码
    log();
}catch(Exception e){
    log();
}

public void log(){
    try{
        // 将日志写入es集群
    }catch(Exception e){
        log();
    }
}
```

解决方案:通过严格的持续集成+严格的codeReview标准来避免。提交代码后直接集成到整体代码中，自动运行全部单元测试+集成测试

#### 案例实战:动态代理类没有缓存起来复用导致的OOM问题

背景:在使用cglib进行动态代理时，生成的代理类没有被缓存起来复用而是每次处理请求都会生成一个代理类，在系统并发很高时瞬间产生了很多类塞满了metaspace且无法被回收，由metaspace引发OOM，导致系统崩溃

解决方案:将动态代理类全局缓存起来。然后在每次上线前进行严格的自动化压力测试，通过高并发压力下系统是否能正常运行24小时来判断是否可以上线

#### 如何对线上系统的OOM异常监控并报警？

对于OOM监控，最好使用如zabbix、Open-Falcon之类的监控平台，当系统出现oom异常时会自动报警通过邮件、短信、钉钉等发送给对应的开发人员

* 监控cpu使用率:cpu负载过高长时间占用90%使用率，就需要报警了
* 监控内存:主要是监控JVM各个区域的内存使用情况，内存长期使用率超过90%则报警
* 监控jvm的fullGC频率:
* 监控某些业务指标:比如每次创建订单上报监控系统，由监控系统统计创建订单频率，过高则报警
* 监控系统中trycatch中的异常报错:所有异常直接上报到监控平台

#### 如何在OOM时自动dump内存快照？

* 为什么要dump内存快照:  系统发生OOM时一定是由于对象太多了最终导致OOM的，所以系统发生OOM时必须有一份发生OOM时的内存快照，然后用MAT等工具对内存快照进行分析就能知道是由于什么对象太多了导致的。
* 设置在OOM时自动dump内存快照: 首先OOM是由JVM主动触发的，所以他在触发OOM'之前是可以将内存快照dump到本地磁盘文件中的。在JVM的启动参数中增加: -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/usr/local/oom,第一个参数是设置在OOM时自动dump内存快照到磁盘，第二个参数是设置内存快照的存储路径

#### 一份JVM参数模板

```bash
-Xms4098M -Xmx4094M -Xmn3072M -Xss1M -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+UseParNewGC -XX:UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFaction=92 -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGcsBeforeCompaction=0 -XX:+CMSParallelInitialMarkEnabled -XX:+CMSScavengeBeforeRemark -XX:+DisableExplicitGC -XX:+PrintGCDetails -Xloggc:gc.log -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/usr/local/app/oom
```

```bash
# 先进行内存分配
# 然后指定垃圾回收器及一些和gc相关的参数
# 设置平时gc时打印日志，然后可以结合jstat工具分析gc频率和性能
# 设置当oom时dump内存快照到磁盘文件
```

#### Metaspace内存溢出时如何解决？

先通过gc.log查看jvm的gc情况，在gc.log中发现如下:metaspace满了触发fullGC

```bash
1.651: [Full GC (Metadata GC Threshold) 1.651: [CMS: 1312K->2892K(87424K), 0.0271283 secs] 10259K->2892K(126720K), [Metaspace: 9799K->9799K(1058816K)], 0.0272228 secs] [Times: user=0.00 sys=0.03, real=0.03 secs] 

```

然后对metaspace回收后还是没有足够空间分配，进行了最后一次拯救"last ditch collection"

```bash
1.678: [Full GC (Last ditch collection) 1.678: [CMS: 2892K->1920K(87424K), 0.0108122 secs] 2892K->1920K(126848K), [Metaspace: 9799K->9799K(1058816K)], 0.0108976 secs] [Times: user=0.03 sys=0.00, real=0.01 secs] 
```

最后一次拯救后的结果是"[Metaspace: 9799K->9799K(1058816K)]"，没有回收掉任何类，几乎占满了设定的10M的metaspace，然后控制台产生了oom异常，

```bash
Caused by: java.lang.OutOfMemoryError: Metaspace
	at java.lang.ClassLoader.defineClass1(Native Method)
	at java.lang.ClassLoader.defineClass(ClassLoader.java:763)
	... 20 more
```

Jvm进程退出，退出时打印出了当前jvm内存的情况:

```bash
Heap
 par new generation   total 39424K, used 1039K [0x0000000081600000, 0x00000000840c0000, 0x00000000962c0000)
  eden space 35072K,   2% used [0x0000000081600000, 0x0000000081703f50, 0x0000000083840000)
  from space 4352K,   0% used [0x0000000083840000, 0x0000000083840000, 0x0000000083c80000)
  to   space 4352K,   0% used [0x0000000083c80000, 0x0000000083c80000, 0x00000000840c0000)
 concurrent mark-sweep generation total 87424K, used 1920K [0x00000000962c0000, 0x000000009b820000, 0x0000000100000000)
 Metaspace       used 9827K, capacity 10122K, committed 10240K, reserved 1058816K
  class space    used 874K, capacity 881K, committed 896K, reserved 1048576K
```

这里得知是由于metaspace内存溢出导致系统oom。oom时系统自动dump内存快照到磁盘文件，从线上拷贝到本地笔记本电脑，然后打开MAT工具分析内存快照，首先看到占用内存最多的对象是AppClassLoader

![image-20210105112925723](../static/image-20210105112925723.png)

分析得出是由于使用cglib动态生成类时候搞出来的。然后看到有一堆自己写的CglibDemo中的Car$EnhancerByCGLIB

![image-20210105113013873](../static/image-20210105113013873.png)

从这里知道了是由于自己写的代码中创建了太多动态生成类填满metaspace导致OOM。解决办法就是缓存Enhancer对象，不要无限制去生成。

oom异常问题排查解决的总结:

* 从gc日志可以知道系统是如何在多次gc后导致oom的
* 从内存快照可以分析出到底是哪些对象占据太多内存导致OOM的
* 最后在代码中找出原因并解决

#### 线程栈内存溢出如何解决？

栈内存溢出本质是由于线程栈中压入了过多栈帧导致栈内存不足最终stackoverflow的，跟gc与内存分配无关，所以之前的gc日志、内存快照对栈内存溢出没有任何帮助。只要把异常信息写入本地日志文件，系统崩溃时直接看日志就能直接定位到出问题的代码处。

```bash
Exception in thread "main" java.lang.StackOverflowError
	at com.example.juc.jvm.StackDemo.lock(StackDemo.java:13)
	at com.example.juc.jvm.StackDemo.lock(StackDemo.java:13)
	at com.example.juc.jvm.StackDemo.lock(StackDemo.java:13)
```

#### JVM堆内存溢出如何解决？

```java
public class MemDemo {
    public static void main(String[] args) {
        List<Data> datas = new ArrayList<>();
        while (true) {
            datas.add(new Data() {
            });
        }
    }
}
```

jvm参数如下:

```bash
-Xms10M
-Xmx10M
-XX:+PrintGCDetails
-Xloggc:gc.log
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=./
-XX:+UseParNewGC
-XX:+UseConcMarkSweepGC
```

运行后的现象:控制台输出堆内存溢出

```bash
java.lang.OutOfMemoryError: Java heap space
Dumping heap to ./\java_pid32980.hprof ...
Heap dump file created [13573490 bytes in 0.051 secs]
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at java.util.Arrays.copyOf(Arrays.java:3210)
	at java.util.Arrays.copyOf(Arrays.java:3181)
	at java.util.ArrayList.grow(ArrayList.java:261)
	at java.util.ArrayList.ensureExplicitCapacity(ArrayList.java:235)
	at java.util.ArrayList.ensureCapacityInternal(ArrayList.java:227)
	at java.util.ArrayList.add(ArrayList.java:458)
	at com.example.juc.jvm.MemDemo.main(MemDemo.java:16)
```

此时不用分析gc日志了，因为堆内存溢出会对应大量的gc日志，所以直接将内存快照拷贝到本地笔记本电脑中用MAT分析即可。MAT打开后如下图:

![image-20210105203458529](../static/image-20210105203458529.png)

MAT告诉我们内存溢出的原因只有一个，是因为main线程持有局部变量占用了7203512个字节，大概是7MB，而堆内存总共只有10MB。"The memory is accumulated in one instance of "java.lang.Object[]"告诉我们内存都被一个实例对象占用了，就是java.lang.Object[],然后点击stacktrace

![image-20210105204349841](../static/image-20210105204349841.png)

得到原因，是因为MemDemo的main方法一直调用add方法导致的，到代码处修改即可

#### 案例实战:每秒仅100个请求的系统因OOM而崩溃

* 故障背景:线上系统收到OOM报警，登录线上机器查看日志发现"Exception in thread"http-nio-8080-exec-1089"java.lang.OutOfMemoryError:Java heap space",说明堆内存溢出，而且是tomcat的工作线程在处理请求时需要在堆内存分配对象时发现空间不足了且无法继续回收空间

* 排查过程:

  1. 第一步先看日志，确定一下溢出类型，是堆内存溢出、栈内存溢出、metaspace内存溢出
  2. 第二步，看日志中是哪个线程运行代码时内存溢出的
  3. 第三步，系统上线前需要设置参数"-XX:+HeapDumpOnOutOfMemoryError"，在OOM时会自动导出内存快照，然后这时开始用MAT分析内存快照。发现占内存最大的是大量的"byte[]"数组，占8G左右内存，系统JVM堆内存分配为8G。也就是说tomcat工作线程在处理请求时创建了大量的byte[]数组，大概有8G，导致JVM堆内存占满了，无法继续在堆上分配对象了。然后在MAT中看到byte[]数组中大部分是10MB,大概有800个，都被TaskThread类引用着，发现是tomcat自己的线程类。此时发现Tomcat的工作线程大概有400个，每个线程创建了2个byte[]数组，每个byte[]数组是10MB，最终是400个tomcat工作线程同时在处理请求，总共创建了8GB内存的byte[] 数组，最终导致了OOM

  ```bash
  "byte[10008192]@0x7aa800000 GET /order/v2 http/1.0-forward"
  ```

  4. 排查为何系统QPS只有100，但是tomcat400个线程都在工作？
  5. 由于系统qps为100，每秒请求数只有100，但是400个线程都在工作，所以也就只有一种可能，每个请求处理需要4秒。并且由于tomcat配置文件中配置了"max-http-header-size:10000000"导致每个请求创建2个数组，每个数组是配置的10MB
  6. 继续查找日志发现有大量服务调用超时，"Timeout Exception..."，查找发现工程师将RPC调用超时时间设置为4秒，然后远程服务故障，导致4秒内请求处理工作线程直接卡死在无效的网络访问上

  解决方案:把超时时间改为1s。这样每秒100个请求，tomcat一共创建200个byte[]数组，占据2G内存，不会有压力，并且可以适当调小tomcat的"max-http-header-size"参数

  #### 案例实战:Jetty的NIO机制导致堆外内存溢出

  故障背景:一个使用jetty的线上系统报警服务不可用，去线上机器查看日志发现是由于Direct buffer memory内存溢出，也就是堆外内存溢出，直接内存是直接被操作系统管理的内存，也就是jetty利用nio机制直接向操作系统申请的内存

  ```bash
  nio handle failed java.lang.OutOfMemoryError:Direct buffer memory
  	at org.eclipse.jetty.io.nio.xxxx
  ```

  jetty使用的nio通过java中的DirectByteBuffer对象来引用堆外内存，一个DirectByteBuffer对象关联一块直接被操作系统分配的内存，当DirectByteBuffer对象被回收时，它所关联的那块内存才会被释放。

  故障原因:如果系统承载高并发，瞬时大量请求过来创建过多DirectByteBuffer占据过多堆内存导致OOm，但是系统并没有高并发。最终原因是由于堆内存分配不合理，导致survivor区放不下存活的DirectByteBuffer，进入老年代后一直没有触发老年代的gc，导致大量DirectByteBuffer无法被回收。java 的NIO已经考虑到这点了(可能很多DirectByteBuffer对象已经没人使用了，但是由于一直无法触发gc导致一直占据堆内存)，ajva的NIO源码中每次分配新的堆外内存时，都会调用System.gc去主动触发JVM的gc去回收一些失去引用的DirectByteBuffer对象来释放堆内存空间，但是上线的JVM参数中禁掉了主动gc"-XX:+DisableExplicitGC",导致NIO源码中的"System.gc()"不生效，最终引发OOM

  解决方案:
  
  * 堆内存分配不合理:合理分配堆内存，给年轻代更多内存
  * 放开"-XX:DisableExplicitGC"，让System.gc()生效，这样java nio就可以回收失去引用的DirectByteBuffer了
  
  #### 案例实战:微服务自研RPC框架下引发的OOM故障
  
  故障背景:服务A通过RPC框架调用服务A，当服务A上线新代码后，导致服务B宕机了。登录服务B所在机器查看日志，发现了"java.lang.OutOfMemoryError:java heap space",说明堆内存溢出导致了OOM，尝试重启服务B后还是很快由于OOM宕机。
  
  排查过程:
  
  * 一般内存溢出问题必须首先找到故障点，一般看日志就可以了，因为日志中有详细的异常栈信息 ------> 查看日志发现引发OOM异常的是自研RPC框架
  * 通过日志已经找到了引发OOM的组件，接下来使用MAT来分析一下OOM时占内存最大的对象。MAT分析发现占内存最大的是一个byte[]数组，有4G大小，而堆内存只不过才4G。
  * RPC框架的类定义:RPC框架对要传输的Request对象要通过特殊语法定义后反向生成java类，然后导入到服务A和服务B中，当服务A传输对象Request给服务B时，服务A先把对象序列化为字节流，然后服务B收到后把字节流反序列化成一个Request对象，自研RPC框架有一个bug，一旦对方发送过来的字节流反序列化失败(一般是由于两方定义的Request类不一致，可能是有一方做了修改)，就会开辟一个byte[]数组，把对方发过来的字节流完整复制进这个byte[]数组，默认大小给的是4GB。而服务A改了很多Request类并且没有同步给服务B，导致服务B反序列化失败，开辟了一个巨大的byte[]数组，直接导致OOM了
  
* 解决方案:

  1. 把自定义RPC框架中数组默认值从4GB改为4MB即可，一般请求都不会超过4MB
  2. 让服务A和服务B的Request类定义保持一致，一方有修改及时同步另一方

#### 排查OOM故障步骤:

1. 首先定位故障的引发者，是tomcat、jetty、rpc框架，业务代码？
2. 使用MAT来分析OOM时dump出的内存快照
3. 结合mat分析得出的信息对tomcat、jetty、rpc框架等进行代码分析
4. 最好能在本地复现问题

#### 案例实战:每天10亿数据的日志分析系统OOM问题

故障背景:一个日志分析系统不断从kafka中消费各种日志数据然后对用户敏感信息脱敏处理，然后把清洗后数据交付给其他系统使用。线上突然收到报警发生了OOm异常，查看日志后发现是"java.lang.OutOfMemoryError:java heap space"。

排查过程: 从日志中查看堆栈信息发现有一个方法反复出现了很多次:xxxClass.process(),最终导致了堆内存溢出。初步推测可能是某块代码出现了大量递归最终导致堆内存溢出，必须进一步使用MAT分析dump内存快照。分析发现有大量的xxxClass.process()方法递归调用，并且每个process方法中都创建了大量的char[]数组，最终导致OOM。但是process方法只调用了10几次最多几十次，所有递归调用创建出来的char[]对象总和加起来最多1G。然后分析gc日志，看到jvm启动参数，4核8g的机器给堆内存分配了1g，并且从日志中看到由于youngGC后存活对象过多无法放入survivor区，只能进入老年代，然后每秒钟执行一次fullGC，最终导致oom

解决方案:

1. 修改jvm启动参数，给堆内存分配5g
2. 修改代码。去掉递归调用，直接在一个方法中对不同用户的日志切分后处理

#### 案例实战:服务类加载过多导致OOM的问题

故障背景:一个部署在tomcat中的web系统，突然收到反馈说服务不稳定，调用此系统接口出现服务假死。但是上游系统反馈说一段时间无法访问接口，但是过了一会又可以访问了。

排查过程:由于是服务假死，并不是说不可用，一般猜测有两种可能:

1. 可能是服务使用了大量内存，并且内存始终无法释放，导致频繁gc。可能每秒都执行一个fullGC，结果每次都回收不了多少内存，最终表现出来就是接口调用出现频繁假死
2. 可能是由于机器上的其他进程占用cpu负载过高，导致服务中的web工作线程始终无法得到cpu资源来执行，也就会造成接口假死

所以先用top命令查看下服务进程的cpu和内存使用情况，发现cpu使用率只有1%，内存使用率为50%，这台机器是4核8g，分给堆内存的为4-5G，

jvm占用的总内存主要有三类，栈内存，堆内存，metaspace，4核8g机器，一般给metaspace 512MB，堆内存给4G，栈内存，每个线程给1MB，如果jvm进程中创建了几百上千个线程，就是大约占用1g的内存。此时jvm进程真实耗费的总内存为6g，剩余2g是留给操作系统内核及其他进程使用的。所以进程的内存使用率为50%意味着几乎要把整个堆内存都占用了，并且长期保持50%说明gc时并没有回收掉很多内存

一个进程的内存占用率过高会发生什么？

* 第一个可能:内存使用率居高不下，导致频繁进行fullGC，频繁fullGC带来的频繁stop the world会导致接口假死
* 第二个可能:内存使用率过多，导致jvm发生oom
* 第三个可能:内存使用率过高，导致进程因为申请内存不足然后直接被操作系统杀掉

继续排查，用jstat分析gc情况，频繁gc时上游服务并没有反馈服务假死问题，日志中也并不存在oom异常，排除前两种可能。当进程被杀时，就会出现上游服务无法访问，然后使用的脚本来监控进程，一旦被杀脚本会自动把进程重新拉起，这时上游服务就又可以访问了，所以找到了问题，就是因为进程向操作系统申请内存被操作系统杀掉，继续排查被操作系统杀掉的原因，用top命令和jstat观察发现jvm耗费超过50%内存时直接从线上导出一份内存快照，使用mat进行分析，发现占内存的是一大堆的classLoader，有几千个，加载了大量的byte[]数组，由于系统代码工程师做了自定义类加载器，并且在代码里无限制的创建了大量的自定义类加载器去重复加载大量数据，经常把内存耗尽导致进程被杀

解决方案:修改代码，避免重复创建几千个自定义类加载器，避免重复加载大量数据到内存中

#### 专栏总结

有三个问题是在面试时回答的不好的:

1. 你们生产环境的系统jvm参数是怎么设置的？为什么要这么设置？

2. 可以聊聊生产环境中的jvm优化经验吗？

3. 说说在生产环境解决过哪些jvm的oom问题？
