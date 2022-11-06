# Kafka-Consumer



## 常见的消费模式

![image-20221105173820381](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051738463.png)



## 消费流程



首先生产者往leader里面发送数据

![image-20221105174201190](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051742274.png)

同时，follower不断的向leader同步数据

![image-20221105174251519](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051742615.png)





消费者可以消费一个或多个分区的数据。

每个消费者之间完全独立，一份数据你消费了，我也可以消费。



一个消费者组可以看成一个消费者，一个分区的数据，只能被同个组内的一个消费者消费，即同组的消费之间，不是独立的。

所以一个组内的消费者，应该 小于等于分区数

![image-20221105174336082](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051743179.png)





消费到哪了，由offset来记录

![image-20221105174825235](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051748340.png)



每个消费者消费到哪了，记录在系统主题里。很老版本的存在zookeeper里。

![image-20221105174852860](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051748974.png)





## 消费者组

![image-20221105212033345](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211052120392.png)



![image-20221105212110599](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211052121644.png)



### 初始化流程

如何将多个消费者组成一个消费者组



1. 选择一个broker作为协调节点

![image-20221105212650563](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211052126659.png)

回顾一下消费者的原理， 一个消费者，消费到哪里了，是由offset记录的， offset则是由消费者提交到broker的 _consumer_offsets 这个topic下面。

_consumer_offsets 这个topic默认有50个partition。

一个消费者组，逻辑上是一个消费者，所以要先确定它（整个组）的offset提交到哪台broker的__consumer_offsets -partition上。那台broker就被叫做coordinator节点，协调节点。



2. 制定组内的消费计划

选定 协调节点后， group 会和它沟通，制定消费计划

![image-20221105213429641](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211052134690.png)

图中的 7）就是表明消费者掉线或者卡住了怎么处理





### 消费方案指定

确定好协调节点后，就是要制定消费方案。

也就是哪个消费者消费哪个分区。



感觉elk用round robin策略比较好



#### 分区分配策略和再平衡

![image-20221106141704200](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061417307.png)



分区分配相关参数



| 参数                            | 描述                                                         |      |
| ------------------------------- | ------------------------------------------------------------ | ---- |
| 此3参数决定消费者多久被移除出组 |                                                              |      |
| heartbeat.interval.ms           | Kafka 消费者和 coordinator 之间的心跳时间，默认 3s。 该条目的值必须小于 session.timeout.ms，也不应该高于 session.timeout.ms 的 1/3。 |      |
| session.timeout.ms              | Kafka 消费者和 coordinator 之间连接超时时间，默认 45s。超 过该值，该消费者被移除，消费者组执行再平衡。 |      |
| max.poll.interval.ms            | 消费者处理消息的最大时长，默认是 5 分钟。超过该值，该 消费者被移除，消费者组执行再平衡。 |      |
|                                 |                                                              |      |
| 此参数决定分区分配策略          |                                                              |      |
| partition.assignment.strategy   | 消 费 者 分 区 分 配 策 略 ， 默 认 策 略 是 Range + CooperativeSticky。Kafka 可以同时使用多个分区分配策略。 可 以 选 择 的 策 略 包 括 ： Range 、 RoundRobin 、 Sticky 、 CooperativeSticky |      |

##### Range策略

注意！ Range策略是针对每个topic的

![image-20221106142242332](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061422390.png)

弊端是容易产生数据倾斜，前几个消费者压力大一点，尤其是topic多了的时候。

所以最好分区数量是消费者数量的整数倍



![image-20221106142514380](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061425435.png)



##### Round Robin

注意，轮询是针对所有topic的。

也就是总的topic的分区数， 轮询分配给组内的所有消费者

![image-20221106142747010](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061427067.png)



##### Sticky

粘性分区定义：可以理解为分配的结果带有“粘性的”。即在执行一次新的分配之前， 考虑上一次分配的结果，尽量少的调整分配的变动，可以节省大量的开销。

![image-20221106142951847](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061429882.png)



这个主要影响的是有消费者被移除后，再平衡的时候。

![image-20221106143213909](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061432973.png)





### 消费的批处理流程

消费也类似于生产，有缓冲队列和批处理



![image-20221105213845573](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211052138654.png)

先抓一批数据到缓冲队列。



消费者再从自己的缓冲队列里面，poll处理数据

![image-20221105214138585](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211052142947.png)





如何提高吞吐量来应对数据堆积

![image-20221106145113466](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061451521.png)







## Offset

![image-20221106143648833](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061436890.png)

不再放到zookeeper，是为了防止和zookeeper带来大量网络交互

__consumer_offsets 主题里面采用 key 和 value 的方式存储数据。

key 是 group.id+topic+ 分区号，value 就是当前 offset 的值。

每隔一段时间，kafka 内部会对这个 topic 进行 compact （压缩），也就是每个 group.id+topic+分区号就保留最新数据。



### 自动offset

![image-20221106143924790](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061439855.png)



### 手动offset

![image-20221106143954945](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061439999.png)



### 指定offset  初始offset

![image-20221106144320698](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061443733.png)

（1）earliest：自动将偏移量重置为最早的偏移量，--from-beginning。

（2）latest（默认值）：自动将偏移量重置为最新偏移量

（3）none：如果未找到消费者组的先前偏移量，则向消费者抛出异常。

（4）任意指定 offset 位移开始消费

  (5)  指定时间消费   （在生产环境中，会遇到最近消费的几个小时数据异常，想重新按照时间消费。 例如要求按照时间消费前一天的数据）



对于我们elk来说，

用 earliest 可能造成重复日志

用latest 可能造成丢日志，这是个取舍



![image-20221106144610955](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061446993.png)



### 漏消费和重复消费

重复消费：已经消费了数据，但是 offset 没提交。 

漏消费：先提交 offset 后消费，有可能会造成数据的漏消费。



需要配合消费者事务



暂时不管了，日志系统没这么复杂要求





## 重要的参数



| 参数名                        | 描述                                                         | fluentd kafka插件对应参数 |                                                              |
| ----------------------------- | ------------------------------------------------------------ | ------------------------- | ------------------------------------------------------------ |
| bootstrap.servers             | 向 Kafka 集群建立初始连接用到的 host/port 列表。             | brokers                   |                                                              |
| group.id                      | 标记消费者所属的消费者组。                                   | consumer_group  ？？？    |                                                              |
|                               |                                                              |                           |                                                              |
| offset相关                    |                                                              |                           |                                                              |
| enable.auto.commit            | 默认值为 true，消费者会自动周期性地向服务器提交offset。      |                           |                                                              |
| auto.commit.interval.ms       | 如果设置了 enable.auto.commit 的值为 true， 则该值定义了 消费者偏移量向 Kafka 提交的频率，默认 5s。 |                           |                                                              |
| auto.offset.reset             | 当 Kafka 中没有初始偏移量或当前偏移量在服务器中不存在 （如，数据被删除了），该如何处理？ earliest：自动重置偏 移量到最早的偏移量。 latest：默认，自动重置偏移量为最 新的偏移量。 none：如果消费组原来的（previous）偏移量 不存在，则向消费者抛异常。 anything：向消费者抛异常。 |                           |                                                              |
|                               |                                                              |                           |                                                              |
| 消费者组相关                  |                                                              |                           |                                                              |
| offsets.topic.num.partitions  | __consumer_offsets 的分区数，默认是 50 个分区。              |                           |                                                              |
|                               |                                                              |                           |                                                              |
| 消费者组掉线相关              |                                                              |                           |                                                              |
| heartbeat.interval.ms         | Kafka 消费者和 coordinator 之间的心跳时间，默认 3s。 该条目的值必须小于 session.timeout.ms ，也不应该高于 session.timeout.ms 的 1/3。 |                           |                                                              |
| session.timeout.ms            | Kafka 消费者和 coordinator 之间连接超时时间，默认 45s。 超过该值，该消费者被移除，消费者组执行再平衡。 |                           |                                                              |
| max.poll.interval.ms          | 消费者处理消息的最大时长，默认是 5 分钟。超过该值，该 消费者被移除，消费者组执行再平衡。 |                           |                                                              |
|                               |                                                              |                           |                                                              |
| 此参数决定分区分配策略        |                                                              |                           |                                                              |
| partition.assignment.strategy | 消 费 者 分 区 分 配 策 略 ， 默 认 策 略 是 Range + CooperativeSticky。Kafka 可以同时使用多个分区分配策略。 可 以 选 择 的 策 略 包 括 ： Range 、 RoundRobin 、 Sticky 、 CooperativeSticky |                           |                                                              |
| 消费者批处理相关              |                                                              |                           |                                                              |
| fetch.min.bytes               | 默认 1 个字节。消费者获取服务器端一批消息最小的字节 数。     | min_bytes                 |                                                              |
| fetch.max.wait.ms             | 默认 500ms。如果没有从服务器端获取到一批数据的最小字 节数。该时间到，仍然会返回数据。 | max_wait_time             | 必须是max_wait_time` * num brokers + `heartbeat_interval` is less than `session_timeout |
| fetch.max.bytes               | 默认 Default: 52428800（50 m）。消费者获取服务器端一批 消息最大的字节数。如果服务器端一批次的数据大于该值 （50m）仍然可以拉取回来这批数据，因此，这不是一个绝 对最大值。一批次的大小受 message.max.bytes （broker  config）or max.message.bytes （topic config）影响。 |                           |                                                              |
| max.poll.records              | 一次 poll 拉取数据返回消息的最大条数，默认是 500 条。调整它也要配合最大bytes之类的参数一起调整 |                           |                                                              |

