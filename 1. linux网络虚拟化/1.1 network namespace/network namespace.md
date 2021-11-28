# network namespace



## 目录

[toc]



## namespace

linux namespace是隔离内核资源



文件系统挂载点、主机名、ip地址等全局系统资源被namespace分割

隔离这些资源的分别是Mount namespace、UTS namespace 、network namespace



对进程来说，要想使用namespace里的资源，必须先进入。

namespace里的进程有2个错觉

1. 它是系统里唯一的进程
2. 它独享linux所有资源



默认情况下，Linux进程处在和宿主机相同的初始的根namespace，默认享有全局系统资源



### network namespace

每个network namespace里都有自己的网络设备（ip、路由表、端口范围、/proc/net 目录等)

因为每个容器都有自己的（虚拟）网络设备，因此容器里的进程可以绑定同一个端口而不冲突。


![image-20211127204147296](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/image-20211127204147296.png)



### 创建、删除

namespace可以通过系统调用创建，不过network namespace，在linux里面集成了工具。

**ip工具的netns子命令。**



```bash
# 创建一个名为 netns1 的 network namespace
ip netns add netns1

# 进入命令  ip netns exec
# 进入netns1 查询网卡信息            
ip netns exec netns1 ip link list
# 应该只能看到默认的本地回环设备lo

# 查看ns
ip netns list

# 删除ns
ip netns delete netns1
# 注意，此命令只是删除了ns的挂载点，如果里面有进程，那么ns还是会存在。
```



附带的ip 命令解释

```bash
# ip  [OPTIONS]  OBJECT  [COMMAND [ARGUMENTS]]
# OBJECT:  是你要管理或者获取信息的对象
ip  link  list # link是网络对象

```



注意，创建了一个network ns时，系统会在`/var/run/netns`下生成挂载点，挂载点的作用是方便管理ns，且使得ns在没有进程运行时也能村子啊。

删除ns时



### 配置

创建network ns 时，默认会创建一个本地回环设备lo

且lo的状态是down, 无法ping通

需要将其修改为UP

```bash
sudo ip netns exec netns1 ip link set dev lo up
# sudo ip netns exec netns1  进入netns1
# ip link set dev lo up  设置 设备lo状态为up
```



### 注意

1. 不同的network namespace之间，路由和防火墙规则也是隔离的
2. 用户可以随意将虚拟网络设备分配到自定义的ns里，但是连接真实设备的，只能在根network namespace]
3. 非root只能访问和配置自己在的ns
4. root可以把本ns的网络设备，移到别的ns，反之亦可，因此存在了风险，如果用户需要屏蔽这种方式，需要结合PID namespace和Mount namespace的隔离性
5. 有两种方式能索引netns，名字或者属于该namespace的进程pid





### 实验

一个跑在虚拟机里的ubuntu 20.04。

一开始是有2个网络设备，一个本地回环lo，一个是连接宿主机的网络的设备ens33

```bash
yefan@ubuntu:~$ ip link list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:a3:f9:48 brd ff:ff:ff:ff:ff:ff

```

安装了docker以后，出现了第三个设备docker0

```
yefan@ubuntu:~$ ip link list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:a3:f9:48 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default
    link/ether 02:42:f3:d1:c6:47 brd ff:ff:ff:ff:ff:ff
```



一开始也没有network namespace

```sh
yefan@ubuntu:~$ ip netns list
# 什么也没输出
```



**创建ns**



创建一个netns1， 注意，需要特权才能执行

```sh
yefan@ubuntu:~$ sudo ip netns add netns1
yefan@ubuntu:~$ ip netns list
netns1
# 可以看到有一个netns1被创建出来了
```

可以看到`/var/run/netns`下创建了一个挂载点

```sh
yefan@ubuntu:~$ ls /var/run/netns
netns1
```



**配置ns**

进入netns1查看网络设备，非root只能访问自己的namespace，因此需要用sudo

```sh
yefan@ubuntu:~$ sudo ip netns exec netns1 ip link list
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```

可以看到已经有了一个本地回环设备，

但它的状态是DOWN，是访问不通的

```bash
yefan@ubuntu:~$ sudo ip netns exec netns1 ping localhost
ping: connect: Network is unreachable
yefan@ubuntu:~$ sudo ip netns exec netns1 ping 127.0.0.1
ping: connect: Network is unreachable

```

把它修改为UP再ping

```bash
yefan@ubuntu:~$ sudo ip netns exec netns1 ip link set dev lo up
yefan@ubuntu:~$ sudo ip netns exec netns1 ping localhost
PING localhost (127.0.0.1) 56(84) bytes of data.
64 bytes from localhost (127.0.0.1): icmp_seq=1 ttl=64 time=0.010 ms
```

可以看到已经ping通了



**删除ns**

```bash
yefan@ubuntu:~$ sudo ip netns delete netns1
yefan@ubuntu:~$ ip netns list
yefan@ubuntu:~$ ls /var/run/netns
```

删除后再查看ns，啥也没输出，说明已经删除了





## Veth Pair

veth是虚拟以太网卡 Virtual Ethernet 的缩写 

veth总是成对，因此叫veth pair

一端发送的数据总是在另一端接收

常用于跨namespace通信


![image-20211127212747108](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/image-20211127212747108.png)




通信原理


![image-20211127222715733](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/image-20211127222715733.png)



### **数据传输实验**

在根netns和netns1之间，使用veth pair进行通信



1. **创建netns1**

```bash
yefan@ubuntu:~$ sudo ip netns add netns1
```

2. **创建veth pair**

```bash
yefan@ubuntu:~$ sudo ip link add veth0 type veth peer name veth1
```

```
ip link add veth0  添加veth0设备
type veth          类型是veth
peer name veth1    另一端是 veth1
```

此时可以看到，当前netns里面已经有了这2个设备，而netns1里没有

```bash
yefan@ubuntu:~$ ip link list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:a3:f9:48 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default
    link/ether 02:42:f3:d1:c6:47 brd ff:ff:ff:ff:ff:ff
4: veth1@veth0: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether c6:a2:1e:c8:bd:35 brd ff:ff:ff:ff:ff:ff
5: veth0@veth1: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 7e:5a:98:79:7b:88 brd ff:ff:ff:ff:ff:ff


yefan@ubuntu:~$ sudo ip netns exec netns1 ip link list
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```



3. **把veth1 移动到netns1**

```sh
yefan@ubuntu:~$ sudo ip link set veth1 netns netns1

yefan@ubuntu:~$ ip link list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:a3:f9:48 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default
    link/ether 02:42:f3:d1:c6:47 brd ff:ff:ff:ff:ff:ff
5: veth0@if4: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 7e:5a:98:79:7b:88 brd ff:ff:ff:ff:ff:ff link-netns netns1
    
yefan@ubuntu:~$ sudo ip netns exec netns1 ip link list
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
4: veth1@if5: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether c6:a2:1e:c8:bd:35 brd ff:ff:ff:ff:ff:ff link-netnsid 0
```

可以看到，veth1已经被移动到netns1了，当前netns已经只剩下veth0



4. **为veth绑定ip**

从上一步可以看到，创建出来的veth是状态为DOWN，故而此时他们并不能通信。

我们要为其绑定ip，且将其状态设置为UP。

```bash
yefan@ubuntu:~$ sudo ifconfig veth0 10.1.1.1/24 up
yefan@ubuntu:~$ sudo ip netns exec netns1 ifconfig veth1 10.1.1.2/24 up
```

此时就能通信了.

在主机ping veth1

```sh
yefan@ubuntu:~$ ping 10.1.1.2
PING 10.1.1.2 (10.1.1.2) 56(84) bytes of data.
64 bytes from 10.1.1.2: icmp_seq=1 ttl=64 time=0.021 ms
```

在netns1 ping veth0

```sh
yefan@ubuntu:~$ sudo ip netns exec netns1 ping 10.1.1.1
PING 10.1.1.1 (10.1.1.1) 56(84) bytes of data.
64 bytes from 10.1.1.1: icmp_seq=1 ttl=64 time=0.024 ms
```



5. 使用特权用户，把veth1重新移动到根namespace

```bash
yefan@ubuntu:~$ sudo ip netns exec netns1 ip link set dev veth1 netns 1

yefan@ubuntu:~$ ip link list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:a3:f9:48 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default
    link/ether 02:42:f3:d1:c6:47 brd ff:ff:ff:ff:ff:ff
4: veth1@veth0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether c6:a2:1e:c8:bd:35 brd ff:ff:ff:ff:ff:ff
5: veth0@veth1: <NO-CARRIER,BROADCAST,MULTICAST,UP,M-DOWN> mtu 1500 qdisc noqueue state LOWERLAYERDOWN mode DEFAULT group default qlen 1000
    link/ether 7e:5a:98:79:7b:88 brd ff:ff:ff:ff:ff:ff
    
yefan@ubuntu:~$ sudo ip netns exec netns1 ip link list
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00

```

有两种方式能索引netns，名字或者属于该namespace的进程pid

此处是通过进程号来索引

```
ip netns exec netns1 ip link set dev veth1 netns 1
ip netns exec netns1 是进入netns1执行命令
ip link set dev veth1 netns 1 是把veth1移动到进程号1所在的netns

pid为1的进程是init进程，通常都在根netns下

```



注意，此时netns1是无法访问外部网络的，因为从netns1发出的数据包，其实是直接进了veth pair设备的协议栈，如果容器需要访问网络，则需要网桥技术将veth接收的数据包，通过某种方式转发出去

```bash
yefan@ubuntu:~$ sudo ip netns exec netns1 ping 220.181.38.148
ping: connect: Network is unreachable

# 220.181.38.148是baidu.com的地址
```





而且，不同的network namespace之间，路由和防火墙规则也是隔离的，

可以看到netns1里面啥也没有

```sh
yefan@ubuntu:~$ sudo ip netns exec netns1 route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface

yefan@ubuntu:~$ sudo ip netns exec netns1 iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

```



## bridge

veth pair能连接2个netns，但是更多就比较困难了，需要bridge。

### 前置知识：中继器、集线器、网桥、交换机、路由器

参考资料   https://www.youtube.com/watch?v=H7-NR3Q3BeI

**中继器 Repeater**

主要功能是对接收到的信号进行再生整形放大，以扩大网络的传输距离，它工作于OSI参考模型第一层，即“物理层”。

![image-20211128122142133](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281221163.png)



**集线器 Hub**

当网络变得复杂时，我们直接连接设备是无法扩展的，如下图

![image-20211128122243315](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281222362.png)

因此需要集线器的帮助

集线器是一个  multiport-repeater， 也工作在1层，也只是简单的发送数据。

采用**广播**的形式发送，当它要向某节点发送数据时，不是直接把数据发送到目的节点，而**是把数据包发送到与集线器相连的所有节点**

![hub](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281232265.gif)



缺陷：

1. 所有设施共享带宽的一个设施，所以它是半-双工的，所以他会**存在冲突**，同时发给hub的入站和出站包会存在冲突，需要算法处理冲突，因而hub的性能相对会差
2. 一台主机发给另外一台主机的内容会被其余无关的主机监听到。**有安全问题**





**网桥 Bridge**

定义上是一个双端口设备，工作在二层，数据包会根据MAC地址来发给指定的端口

能知道主机在哪边

如下图，绿色主机和绿色主机通信，hub会广播包，但是Bridge知道绿色主机在左侧，故而不会把包转发到右侧

![bridge-side](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281309593.gif)

如下图，蓝色主机和蓝色主机通信，bridge知道主机在另一侧，故而会把包转发过去

![bridge-cross-side](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281312561.gif)

- 桥会跟踪插到他的接口上的网络的所有主机的地址，当桥的一端的这个网络的数据包发到桥，桥会过滤机制，保证属于这一端的网络的数据包留在本地，而不会被无辜的转发到对面网络（由于本地包，不是发给桥对面的）
- 当桥接受到网络发出来的包的地址不属于桥的这一端，那么他会发到对面去。但是，实际上它并不知道对面能否存在这个地址，只是猜测既然不在这边，那么可能在对面，而后假如对面网络还有其余桥，那么它会发现这个包不在自己这里，又会把包发到其余桥的对面去，**所以一个包要到达目的地址所在的主机，需要经过多个桥**
- 由于上面这一点，广播和多播（比方arp这种找所有人要地址的包）的这类流量必需经过网络上的所有桥，那么所有的主机都是有机会读到这个广播包的，而网络那么大（特别是桥越多的网络），其实很多包是和自己无关的，那么就会有可能引起**广播风暴**，从而阻止了单播的流量（就是目的明确的包）



**交换机 Switch**

交换机就像一个多端口的网桥，工作在二层，数据包会根据MAC地址来发给指定的端口

它知道主机在哪个端口上

![switch](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281317004.gif)





交换机促成了一个网络（Network），像上图这样结构的一系列所有设备，组成了一个网络。

![image-20211128132258728](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281322778.png)



**路由器 Router**

路由器知道连接到它的网络（Network），以路由表（Routing Table）的形式存储。

路由就是把数据从一个网络发送到另一个网络



![image-20211128132924779](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281329830.png)



路由器在每个连接到它的网络中都有个ip地址，如下图，这个ip地址通常被我们称为**网关Gateway**

![image-20211128133103371](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281331427.png)



路由器使得网络能有很多层级

![image-20211128133216300](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281332364.png)

![image-20211128133255268](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281332343.png)



**总结**

![image-20211128133532734](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281335801.png)

![image-20211128133548691](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111281335757.png)



### Linux Bridge 

Linux里的Bridge更像是一个虚拟的交换机，任意真实设备如eth0或虚拟设备如（veth) 都能连接上去，但它不能跨机器连接网络设备。

它是多端口的，根据mac地址转发设备，类似于物理交换机。





### 实验

#### 创建单个bridge



使用iproute2工具包创建

```bash
# 创建一个bridge名字是br0
yefan@ubuntu:~$ sudo ip link add name br0 type bridge
# 刚创建出来状态是down，将其设为UP
yefan@ubuntu:~$ sudo ip link set br0 up

yefan@ubuntu:~$ ip link list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:a3:f9:48 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default
    link/ether 02:42:41:f7:1e:9b brd ff:ff:ff:ff:ff:ff
4: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether ee:a4:1a:1a:41:da brd ff:ff:ff:ff:ff:ff


```

如下图

![image-20211128214722913](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111282147955.png)

此时bridge是一个独立的网络设备，它一端连着协议栈，另一端什么也没连，因此，此时它没有任何功能。





或者使用bridge-utils工具包创建

```bash
sudo brctl addbr br0
```



#### 连接到veth pair

1. 首先创建veth pair并且给他加上ip地址

![image-20211128215422800](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111282154851.png)

```bash
yefan@ubuntu:~$ sudo ip link add veth0 type veth peer name veth1
yefan@ubuntu:~$ sudo ip addr add 1.2.3.101/24 dev veth0
yefan@ubuntu:~$ sudo ip addr add 1.2.3.102/24 dev veth1
yefan@ubuntu:~$ sudo ip link set veth0 up
yefan@ubuntu:~$ sudo ip link set veth1 up

yefan@ubuntu:~$ ip link list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:a3:f9:48 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default
    link/ether 02:42:41:f7:1e:9b brd ff:ff:ff:ff:ff:ff
4: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether ee:a4:1a:1a:41:da brd ff:ff:ff:ff:ff:ff
5: veth1@veth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 0a:32:b0:18:a9:75 brd ff:ff:ff:ff:ff:ff
6: veth0@veth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 66:72:a9:ae:06:1d brd ff:ff:ff:ff:ff:ff

yefan@ubuntu:~$ ip addr
......
5: veth1@veth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 0a:32:b0:18:a9:75 brd ff:ff:ff:ff:ff:ff
    inet 1.2.3.102/24 scope global veth1
       valid_lft forever preferred_lft forever
    inet6 fe80::832:b0ff:fe18:a975/64 scope link
       valid_lft forever preferred_lft forever
6: veth0@veth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 66:72:a9:ae:06:1d brd ff:ff:ff:ff:ff:ff
    inet 1.2.3.101/24 scope global veth0
       valid_lft forever preferred_lft forever
    inet6 fe80::6472:a9ff:feae:61d/64 scope link
       valid_lft forever preferred_lft forever
```

2. 把veth0连接到br0



```bash

yefan@ubuntu:~$ sudo ip link set dev veth0 master br0

# 可以通过bridge link 查看连接
yefan@ubuntu:~$ bridge link
6: veth0@veth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2

# 也可以用下面命令查看连接
yefan@ubuntu:~$ brctl show
bridge name     bridge id               STP enabled     interfaces
br0             8000.6672a9ae061d       no              veth0
docker0         8000.024241f71e9b       no

#
yefan@ubuntu:~$ ip addr
......
4: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 66:72:a9:ae:06:1d brd ff:ff:ff:ff:ff:ff
    inet6 fe80::eca4:1aff:fe1a:41da/64 scope link
       valid_lft forever preferred_lft forever
5: veth1@veth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 0a:32:b0:18:a9:75 brd ff:ff:ff:ff:ff:ff
    inet 1.2.3.102/24 scope global veth1
       valid_lft forever preferred_lft forever
    inet6 fe80::832:b0ff:fe18:a975/64 scope link
       valid_lft forever preferred_lft forever
6: veth0@veth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br0 state UP group default qlen 1000
    link/ether 66:72:a9:ae:06:1d brd ff:ff:ff:ff:ff:ff
    inet 1.2.3.101/24 scope global veth0
       valid_lft forever preferred_lft forever
    inet6 fe80::6472:a9ff:feae:61d/64 scope link
       valid_lft forever preferred_lft forever


```









此时，发生了下面的变化

- br0和veth0连接了，且是双向通道

- 协议栈和veth0连接变成了单通道，只能协议栈发数据给veth0，veth0从**外部**接收的数据不能发给协议栈

- br0的mac地址变成了veth0的mac地址

  - br0   ee:a4:1a:1a:41:da
    veth0 66:72:a9:ae:06:1d

    br0   66:72:a9:ae:06:1d
    veth0 66:72:a9:ae:06:1d

这就相当于是bridge在veth0和协议栈直接做了拦截，在veth0上，把veth0要转发给协议栈的数据拦截，全部转发给bridge。同时bridge可以像veth0发送数据。

![image-20211128220513438](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111282205493.png)



验证数据发送

1. veth0 ping veth1

```
# 使用veth0接口向1.2.3.102 ping 1次
yefan@ubuntu:~$ ping -c 1 -I veth0 1.2.3.102
PING 1.2.3.102 (1.2.3.102) from 1.2.3.101 veth0: 56(84) bytes of data.
^C
--- 1.2.3.102 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms
```

如上，是失败了

抓包分析

因为我们是使用非debian系统，用的ubuntu20.04，这里的实验可能会有点问题，需要先设置一下

```bash
yefan@ubuntu:~$ su root
Password:
root@ubuntu:/home/yefan# echo 1 > /proc/sys/net/ipv4/conf/veth1/accept_local
root@ubuntu:/home/yefan# echo 1 > /proc/sys/net/ipv4/conf/veth0/accept_local
root@ubuntu:/home/yefan# echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
root@ubuntu:/home/yefan# echo 0 > /proc/sys/net/ipv4/conf/veth0/rp_filter
root@ubuntu:/home/yefan# echo 0 > /proc/sys/net/ipv4/conf/veth1/rp_filter

```



首先开另一个终端进行tcpdump，分别监听veth1和veth0和br0

```bash
yefan@ubuntu:~$ sudo tcpdump -n -i veth1
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on veth1, link-type EN10MB (Ethernet), capture size 262144 bytes

yefan@ubuntu:~$ sudo tcpdump -n -i veth0
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on veth0, link-type EN10MB (Ethernet), capture size 262144 bytes

yefan@ubuntu:~$ sudo tcpdump -n -i br0
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on br0, link-type EN10MB (Ethernet), capture size 262144 bytes
```

重新ping一次

```
yefan@ubuntu:~$ ping -c 1 -I veth0 1.2.3.102
PING 1.2.3.102 (1.2.3.102) from 1.2.3.101 veth0: 56(84) bytes of data.

--- 1.2.3.102 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms
```



监听到的报文如下

其中veth1这边

```
14:25:23.104996 ARP, Request who-has 1.2.3.102 tell 1.2.3.101, length 28
14:25:23.105002 ARP, Reply 1.2.3.102 is-at 0a:32:b0:18:a9:75, length 28
```

其中veth0这边

```
14:25:23.104991 ARP, Request who-has 1.2.3.102 tell 1.2.3.101, length 28
14:25:23.105002 ARP, Reply 1.2.3.102 is-at 0a:32:b0:18:a9:75, length 28
```

其中br0这边

```
14:25:23.105002 ARP, Reply 1.2.3.102 is-at 0a:32:b0:18:a9:75, length 28
```



veth1和veth0上抓到的报文，都包含arp请求和响应

而br0这边只有响应包

说明了veth0收到响应包之后，没有给协议栈，而是给了br0，于是协议栈拿不到veth1的mac地址，就无法通信。







#### 把IP让给bridge

从前面实验看出，给veth0配ip是没意义的，因为数据包无法给协议栈，协议栈传数据给veth0，回程报文回不去。

于是把veth0的IP让给br0



```bash
yefan@ubuntu:~$ sudo ip addr del 1.2.3.101/24 dev veth0
yefan@ubuntu:~$ sudo ip addr add 1.2.3.101/24 dev br0

4: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 66:72:a9:ae:06:1d brd ff:ff:ff:ff:ff:ff
    inet 1.2.3.101/24 scope global br0
       valid_lft forever preferred_lft forever
    inet6 fe80::eca4:1aff:fe1a:41da/64 scope link
       valid_lft forever preferred_lft forever
5: veth1@veth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 0a:32:b0:18:a9:75 brd ff:ff:ff:ff:ff:ff
    inet 1.2.3.102/24 scope global veth1
       valid_lft forever preferred_lft forever
    inet6 fe80::832:b0ff:fe18:a975/64 scope link
       valid_lft forever preferred_lft forever
6: veth0@veth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br0 state UP group default qlen 1000
    link/ether 66:72:a9:ae:06:1d brd ff:ff:ff:ff:ff:ff
    inet6 fe80::6472:a9ff:feae:61d/64 scope link
       valid_lft forever preferred_lft forever

```

就相当于是

![image-20211128223933763](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111282239820.png)

> 上图删去了协议栈和veth0的联系，其实他们还是有联系的，但由于veth0没有IP，因此协议栈路由的时候不会把包发给veth0。就算强制让包从veth0发出去，由于veth0接收到的数据只会给br0，协议栈还是无法接收到arp应答包，同样导致通信失败。此时veth0相当于一根网线

此时通过br0 ping veth1

```
yefan@ubuntu:~$ ping -c 1 -I br0 1.2.3.102

# 应该要ping通的，但是使用的ubuntu20可能因为内核设置而ping不通，换成debian可能能行
```





这块由于系统问题，进行不下去了，有机会换debian进行继续。



### 容器网络中的bridge

![image-20211128235304626](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202111282353685.png)

在容器中配置网关为br0

从容器发出的数据包，先通过br0-> 主机协议栈 , 由于目的地址是外网ip， 且host开启了IP forward，数据包会通过ens33发出去



## tun/tap设备



