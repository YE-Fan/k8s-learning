# ES介绍



## 对比其他数据库

ES PB级

Hadoop  EB级

Redis  GB级  顶天了TB 级

MySQL  TB级没什么问题



![image-20221103225721258](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032257919.png)





## 版本发展历史



![image-20221103225832631](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032258734.png)



![image-20221103225913843](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032259976.png)



## 核心概念

![image-20221103230320092](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032303170.png)





- 索引 index  相当于一个数据库



- 类型 type   用来规定文档的各个字段内容的数据类型和其他约束，相当于是一张表

es7淘汰了type



- 文档 document     es中最小的、整体的数据单位，相当于数据库里的一条记录



![image-20221103230549799](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032305921.png)





## 操作系统准备



### 用户

es不支持root用户

![image-20221103231358953](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032313999.png)



### 修改资源限制参数





![image-20221103231430548](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032314620.png)



- nproc 操作系统针对每个用户创建进程数量的限制
- nofile 一个进程能够同时打开的文件描述符的数量
- stack
- memlock  不限制， 这个我们由jvm来控制

soft的就是到了这个数就警告，hard就是最多这么多了



### 修改内核参数

![image-20221103232023549](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032320631.png)



- fs.aio-max-nr  同时拥有的异步io请求数量
- fs.file-max 系统允许的文件描述符的最打数量



- net.ipv4.ip_local_port_range  系统允许程序使用的ipv4的端口范围
- net.ipv4.tcp_mem tcp内存大小，单位是页，防止高并发时系统拒绝socket分配啥的
- net.ipv4.tcp_rmem tcp读取缓冲区，单位是字节
- net.ipv4.tcp_rmem tcp发送缓冲区，单位是字节
- net.ipv4.tcp_tw_reuse  挥手中time_wait
- net.ipv4.tcp_tw_recycle  挥手中time_wait，此2个参数是为了高并发时，防止大量socket处于time_wait状态占用了资源



- vm.swappiness  官方建议禁止虚拟内存swap，此处我设置剩下1%才能用内存swap，为了让操作系统里面跑的其它东西用
- vm.min_free_kbytes 操作系统保留内存，防止应用把内存全部吃完，根据机器内存设置
- vm.max_map_count   跟着设就行
- kernel.pid_max 最大进程数
- vm.zone_reclaim_mode 
- vm.nr_hugepages 一定要关了，注释掉

### 修改时区

![image-20221103234307491](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032343531.png)



### 重启系统

需要重启吗？

shutdown -r now

## 单机安装



### jdk安装

es7.2+ 需要jdk 11+



### es安装

#### 切换到es用户

`su esadmin`

#### 创建文件夹

![image-20221103234957991](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032349046.png)



#### 修改配置使得es使用jdk

![image-20221103235121745](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032351789.png)

#### 修改配置文件

![image-20221103235307657](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032353711.png)



#### 修改jvm参数

jvm.options



设为物理内存一半

![image-20221103235455929](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032355314.png)



#### 启动

![image-20221103235319953](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211032353989.png)



```
curl 192.168.1.81:9200

输出节点信息
```





## elasticsearch.yml

```yml
#cluster
cluster.name: # 集群名  一个集群要一样

```



```yml
# node
node.name: # 在集群中唯一，建议用ip地址
node.attr.rack： # 集群联邦用的，一般不用
```



```yml
# Memory
bootstrap.memory_lock # 防止交换内存

```



```yml
# network
network.host: # 集群监听的地址
http.port: 9200
transport.tcp.port: 9300 # 集群内部通信端口
```



```yml
# Discovery 集群发现
discovery.seed_hosts: # 候选主节点，一般生产环境是3个
cluster.initial_master_nodes: # 初始化集群时，谁被选为主节点，一般和上面配成一样就行
```





## jvm.options

es在生产环境，jvm最多不超过32G, 即单台机器最大64G物理内存

一般建议jvm内存6G, 云平台机器买16G物理内存

```
-Xms6G
-Xmx6G
-Xmn2G  约为6G的3/8
-Xss228k 一个线程的内存开销
-XX:+DisableExplicitGC 禁止系统级的GC
```





## 一般规模分布式集群配置

以3台为例

### 架构图

每台都承担着下面的角色

![image-20221104000932466](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211040009536.png)



### 操作系统设置

略

### es安装

略



### 参数配置

#### elasticsearch.yml

![image-20221104001441655](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211040014769.png)

其它机器，只需要修改ndoe.name和network.host



#### jvm.options

待学



### 启动



### 水平扩容

新增的节点，角色就只是数据节点

和主节点不同的，就是  node.master改为false

然后重新分片一下

![image-20221104002143495](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211040021557.png)
