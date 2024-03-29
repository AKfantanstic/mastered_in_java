### 后台运行jar包:  
```bash
nohup java -jar xxx.jar > temp.txt &  
```
* nohup 意思是不挂断运行命令,当账户退出或终端关闭时,程序仍然运行     
* command >out.file是将command的输出重定向到out.file文件，即输出内容不打印到屏幕上，而是输出到out.file文件中。

### 运行jar包指定端口号
java -jar xxx.jar --server.port=8080

### 查看占用某端口的线程的pid  
```bash
netstat -nlp |grep 9181  
(9181为示例端口号)  

# 然后 

ps -ef|grep 25953  
(25953为示例进程pid)  
```
就找到此端口运行的进程名称了  

# 查找端口被哪个进程占用
```bash
#即可找出占用8080端口的进程 pid及相关信息
lsof -i:8080
```

### 查找文件位置:  
```bash
find / -name xxx.jar  
```
上面的意思是 在/根目录下查找名为 xxx.jar的文件  

### 将日志文件内容清除
cat /dev/null>/root/nohup.log

### vim操作命令:
```bash
跳转到 第一行: gg
跳转到 最后一行: shift + g

下一页: ctrl + f (f为forward)
上一页: ctrl + b (b为backward)

查找下一个 n
查找上一个 N
```
### 查看 CPU相关信息
```bash
cat /proc/cpuinfo
```
* 直接查看 CPU 核心数:
```bash
cat /proc/cpuinfo|grep "cpu cores"
```

### 重启
```bash
shutdown -r now
```

### 查看文件夹下所有文件大小
```bash
ll -h
```
ll是以字节计的大小，加 -h 参数后按常规大小显示
#### 查看目录下每个文件夹的空间占用大小

```bash
du -h --max-depth=1
# 结果:
[root@localhost home]# du -h --max-depth=1
261M    ./mysql
4.7G    ./shaogj
162M    ./dingjm
4.4G    ./datastorge
8.0K    ./keystorge
16K     ./www
12K     ./redis
9.5G    .
```



### 线上服务器的cpu使用率达到 100% 了，如何排查、定位和解决该问题？

* 主要考察是否有处理过高负载的线上问题场景。所以大公司考察基本功肯定会问这个。
* 核心思路:找到这台服务器上是哪个进程的哪个线程的哪段代码，导致cpu 100%了。
* 线上经验:由一个bug导致的，异常信息写入es里,但是线上es集群出了问题导致无法写入，最后定的现象是线程几十台机器全部因为下面的代码导致cpu 100%,卡死了
```
public void log(String message){
	try{
		//向es中写入日志
	}catch(Exception e){
		log(message);
	}
}
```
* 解决步骤:
(1)定位耗费cpu的进程  
```bash
top -c: 显示进程列表，然后输入p，按cpu使用率排序，找到占用cpu负载最高的进程。
```
(2)定位进程中耗费cpu的线程  
```bash
top -Hp 43987: 然后输入p，将进程中所有线程按照cpu使用率排序  
```
(3)定位哪段代码导致cpu过高  
```bash
print "%x\n" 16872: 将线程pid转为16进制，比如41e8
```
然后
```bash
jstack 43987|grep '0x41e8' -C5--color : 
这个就是用jstack打印进程的堆栈信息，然后通过grep那个线程的16进制pid，找到关于那个线程的东西，这时就可以在打印出的代码中看到是哪个类的哪个方法导致cpu 100% 问题
```
### 线上进程 kill 不掉怎么办？
* 线上经验:我们公司有一套自己研发的发布系统，系统根据git仓库地址拉取代码然后基于maven打包，并且可以指定要用的profile，打完jar包后用Java 
-jar命令启动。这个发布系统在每台机器上有自己的一个进程，当发布系统时，并不是用java -jar命令启动的，而是在发布系统的进程中启动一个子进程来运行系统。当kill 子进程时，会发现杀不死，并且该子进程成了僵尸进程，也就是zombie状态，因为这个进程释放了资源但是没有得到父进程的确认。
* 解决方法:
```bash
ps aux: 查看stat一栏，如果是z，就表示存在zombie状态的僵尸进程
```
然后
`ps -ef|grep 僵尸进程id: 可以找到父进程id，然后kill掉父进程即可`