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







