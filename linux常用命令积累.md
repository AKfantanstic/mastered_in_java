### 后台运行jar包:  
```
nohup java -jar xxx.jar > temp.txt &  
```
* nohup 意思是不挂断运行命令,当账户退出或终端关闭时,程序仍然运行     
* command >out.file是将command的输出重定向到out.file文件，即输出内容不打印到屏幕上，而是输出到out.file文件中。  
### 查看占用某端口的线程的pid  
```
netstat -nlp |grep 9181  
(9181为示例端口号)  

然后 

ps -ef|grep 25953  
(25953为示例进程pid)  
```
就找到此端口运行的进程名称了  
### 查找文件位置:  
```
find / -name xxx.jar  
```
上面的意思是 在/根目录下查找名为 xxx.jar的文件  
### vim操作命令:
```
跳转到 第一行: gg
跳转到 最后一行: shift + g

下一页: ctrl + f (f为forward)
上一页: ctrl + b (b为backward)

查找下一个 n
查找上一个 N
```
### 查看 CPU相关信息
```
cat /proc/cpuinfo
```
* 直接查看 CPU 核心数:
```
cat /proc/cpuinfo|grep "cpu cores"
```