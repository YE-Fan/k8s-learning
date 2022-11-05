# Kraft模式



kafka3.3开始，Kraft生产可用了。

Kafka 社区计划在下一个版本（3.4）中弃用 ZooKeeper，然后在 4.0 版本中完全删除它



![image-20221105172501299](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051725373.png)



这样做的好处有以下几个：

 ⚫ Kafka 不再依赖外部框架，而是能够独立运行；

 ⚫ controller 管理集群时，不再需要从 zookeeper 中先读取数据，集群性能上升；

 ⚫ 由于不依赖 zookeeper，集群扩展时不再受到 zookeeper 读写能力限制； 

⚫ controller 不再动态选举，而是由配置文件规定。这样我们可以有针对性的加强 controller 节点的配置，而不是像以前一样对随机 controller 节点的高负载束手无策。



## 下载安装



## 配置

/config/kraft/server.properties

```properties

#kafka 的角色（controller 相当于主机、broker 节点相当于从机，主机类似 zk 功能）
# 此处我们就是既是主机，也是从机
process.roles=broker, controller
#节点 ID
node.id=2
#controller 服务协议别名
controller.listener.names=CONTROLLER
#全 Controller 列表， 一般我们就3台主机
controller.quorum.voters=2@hadoop102:9093,3@hadoop103:9093,4@hadoop104:9093
#协议别名到安全协议的映射
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL

#不同服务器绑定的端口
listeners=PLAINTEXT://:9092,CONTROLLER://:9093
#broker 服务协议别名
inter.broker.listener.name=PLAINTEXT
#broker 对外暴露的地址
advertised.Listeners=PLAINTEXT://hadoop102:9092

#kafka 数据存储目录
log.dirs=/opt/module/kafka2/data
```



不同的机器，node.id和ip地址要改一下





## 初始化集群

![image-20221105173414569](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051734623.png)



## 启动集群



每个节点执行启动命令

```
[atguigu@hadoop102 kafka2]$ bin/kafka-server-start.sh -daemon 
config/kraft/server.properties

[atguigu@hadoop103 kafka2]$ bin/kafka-server-start.sh -daemon 
config/kraft/server.properties

[atguigu@hadoop104 kafka2]$ bin/kafka-server-start.sh -daemon 
config/kraft/server.properties

```



## 结束集群



```
[atguigu@hadoop102 kafka2]$ bin/kafka-server-stop.sh

[atguigu@hadoop103 kafka2]$ bin/kafka-server-stop.sh

[atguigu@hadoop104 kafka2]$ bin/kafka-server-stop.sh
```

