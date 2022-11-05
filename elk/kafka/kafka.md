

## 基础架构



### 发布订阅模式

![image-20221105033554897](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211050335962.png)



不删除数据的好处，其它消费者也可以消费。

kafka就是这种模式，它是自己主动控制来什么时候删除数据。



最原始的形态，

![image-20221105150801212](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051508272.png)



### 分区

数据量这么大，单机很难处理，我们要分而治之，因而出现了partition。

Partition：为了实现扩展性，一个非常大的 topic 可以分布到多个 broker（即服 务器）上，一个 topic 可以分为多个 partition，每个 partition 是一个**有序**的队列。

![image-20221105150937031](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051509104.png)

### 消费者组

由消费者演变成消费者组， 现在的一个组，相当于原来的一个消费者

![image-20221105151126466](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051511552.png)

Consumer Group（CG）：消费者组，由多个 consumer 组成。消费者组内每个消费者负责消费不同分区的数据，一个分区只能由一个组内消费者消费；消费者组之间互不 影响。所有的消费者都属于某个消费者组，即消费者组是逻辑上的一个订阅者。



一个分区，只能是组内一个消费者去消费

这样弄的原因

> 消费者拉取消息需要提供offset, limit。
>
> 如果offset放在broker端，那么一定会产生额外的通信开销；
>
> 如果offset放在Consumer端，如果在一个组有多个消费者，就需要有一个协调者，集中式的管理，解决锁冲突，如果不解决冲突，那么势必会产生重复消费、无用的消费，从而导致资源浪费。
>
> kafka已经实现分布式消费，多个消费组同时消费同一个分区就可以，处于权衡目的，没有再细化到消费组内再分布消费。
>
> 
>
> 假设1个partition能够被同组的多个consumer消费，因为consumer是通过pull的模式从partition拉取消息的，pull的时候就要决定从哪里pull，也就是index的值，不做中心化维护index的值的话，consumer就很容易pull到重复的消息重复消费，对index做中心化处理的话，就会增加通信成本，consumer每次pull的时候还得通信获取最新的index的值，再加上consumer消费失败，不commit成功的话，index的值维护起来就会异常复杂。
>
> 整体上利大于弊呐，于是就1个partition只能被同组的一个consumer，如果需要多个consumer，就分多个partition

### 分区的副本

 Replica：副本。一个 topic 的每个分区都有若干个副本，一个 Leader 和若干个 Follower。

![image-20221105151536564](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051515665.png)



Leader：每个分区多个副本的“主”，**生产者发送数据的对象，以及消费者消费数 据的对象都是 Leader。** 

Follower：每个分区多个副本中的“从”，实时从 Leader 中同步数据，保持和 Leader 数据的同步。Leader 发生故障时，某个 Follower 会成为新的 Leader。

![image-20221105151805226](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051518318.png)



### zookeeper

zookeeper来维护分布式信息。

![image-20221105151922923](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051519044.png)

记录谁是leader，每个topic里面哪个partition是leader







## 安装

kafka 2.8之后不再需要zookeeper



## 配置



![image-20221104204957285](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211042049371.png)

![image-20221104205141764](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211042051844.png)

```properties

# 分区数，最好机器数量，除非CPU和内存特别好
num.partitions=  


num.network.threads=   # CPU线程数的80%，给操作系统留一点
num.io.threads=   # 略大于上面，差不多设1.5倍吧
```

