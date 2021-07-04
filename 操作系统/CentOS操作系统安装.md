1. 下载virtual box虚拟机软件，并安装
2. 下载centos7系统镜像
3. 在virtual Box中创建虚拟机，选择操作系统为linux，选择版本为redHat，分配1024MB内存，在最后一步虚拟机磁盘文件存储路径时要自己指定一个盘符下的文件夹，最后创建完成。
4. **选择创建好的虚拟机，点击"设置"按钮，在网络一栏选择桥接网络。**

配置网络:

编辑网络配置文件，开启网卡访问:

```bash
 vi /etc/sysconfig/network-scripts/ifcfg-enp0s3
 # 把onboot从no改为yes
 ONBOOT=yes
```

启动网络服务，并通过dhcp获取一个ip

```bash
service network start
```

配置yum,安装wget

```bash
yum clean all
yum makecache
yum install -y wget
```

安装net-tools，便于使用ifconfig命令查看网络配置

```bash
yum install -y net-tools
```

使用ifconfig查看分配的ip

```bash
ifconfig
```

编辑网络配置文件

```bash
 vi /etc/sysconfig/network-scripts/ifcfg-enp0s3
```

```shell
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
NAME=enp0s3
DEVICE=enp0s3
ONBOOT=yes
IPADDR=192.168.10.7
NETMASK=255.255.255.0
GATEWAY=192.168.10.1
DNS1=8.8.8.8
```

```bash
service network restart
```

配置hosts，配置本机的hostname到ip地址的映射

```bash
vi /etc/hosts
```

```shell
# 增加一行
192.168.10.7 eshop-cache-01
```

然后使用SecureCRT通过SSH连接到虚拟机

```bash
# centos查看防火墙状态：      
firewall-cmd --state
 
# 停止防火墙：
systemctl stop firewalld.service

# 禁止防火墙开机启动：
systemctl disable firewalld.service 
```

关闭selinux:

```bash
vi /etc/selinux/config
#修改selinux=disabled
```

安装perl

```bash
yum install -y perl
```

把需要配置互相免密码通信的机器ip添加到每台机器的hosts文件中

```shell
192.168.3.33   eshop-cache-01
192.168.3.34   eshop-cache-02
192.168.3.35   eshop-cache-03
192.168.3.38   eshop-cache-04
```

配置ssh免密码登录

```bash
ssh-keygen -t rsa
# 一路不断敲回车即可，ssh-keygen命令默认会将公钥存放在/root/.ssh目录下、
cd /root/.ssh
# 将公钥复制为authorized_keys文件后，使用ssh连接本机就不需要输入密码了
cp id_rsa.pub authorized_keys
# 将本机公钥拷贝到指定hostname的机器的authorized_keys文件中
ssh-copy-id -i hostname
```

安装文件上传下载工具

```bash
 yum install -y lrzsz
```

安装java：先下载 jdk-8u211-linux-x64.tar.gz 文件到本机

```bash
tar -zxvf jdk-8u211-linux-x64.tar.gz
# 打开环境变量配置文件
vim /etc/profile
```

在文件末尾添加:

```shell
export JAVA_HOME=/root/jdk1.8.0_211
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
```

```bash
# 使环境变量生效
source /etc/profile
# 添加软连接
ln -s /root/jdk1.8.0_211/bin/java /usr/bin/java
# 检查java版本
java -version
```















