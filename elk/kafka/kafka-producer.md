# kafka生产者



## 原理



![image-20221105154432006](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051544086.png)



### 缓冲队列

生产者的设计，本身是一个通过缓冲队列，实现的生产消费模型。

数据不断生产，放到内存的队列里面。

sender线程作为缓冲队列的消费者，不断从队列里读取数据，发送到kafka。



这个缓冲队列在内存里，默认大小是32M。

当sender线程，等到有16k的数据之后，就会把他们作为一批，读取过来而发送。

这样的批处理方式，产生了几个参数

> buffer.memory： 队列 缓冲区总大小，默认 32m。
>
> batch.size：只有数据积累到batch.size之后，sender才会发送数据。默认16k 
>
> linger.ms：如果数据迟迟未达到batch.size，sender等待linger.ms设置的时间 到了之后就会发送数据。单位ms，默认值是0ms，表示没有延迟。



### 发送可靠性

可靠性通过ack和重试来保证

#### ACK



• 0：生产者发送过来的数据，不需要等数据落盘应答。即没有ACK，无脑发

 • 1：生产者发送过来的数据，Leader收到数据后应答。

 • -1（all）：生产者发送过来的数据，Leader和ISR队列 里面的所有节点收齐数据后应答。-1和all等价。简化理解就是leader和所有follower都落盘了才应答



在生产环境中，

acks=0很少使用；

acks=1，一般用于传输普通日志，允许丢个别数据；

acks=-1，一般用于传输和钱相关的数据， 对可靠性要求比较高的场景。



##### 无应答

![image-20221105162742448](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051627480.png)

万一leader挂了，直接丢数据



##### ack=1

![image-20221105162818268](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051628299.png)

此时如果应答完成后，但是数据还没有同步到follower，leader挂了，那么也会丢数据



##### all 

![image-20221105162944666](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051629715.png)

**ISR(In-Sync Replicas)**：所有与leader副本保持一定程度同步的副本（包括 leader 副本在内），这个落后多少是可配置的。只有ISR中的副本才有可能成为leader。

分区副本数大于等于2，即至少有一个副本。

ISR里应答的最小副本数量大于等于2，即至少有一个leader和一个follower是同步的，就是你那个副本不但有，且要可用，否则就和只有一个leader没区别，就退化成ack=1了



这个可靠性也会有副作用，可能产生重复数据的情况。



### 数据重复性

当ack设置为all，最高级别时，可能造成数据重复。

![image-20221105164026582](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051640622.png)





![image-20221105164120766](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211051641817.png)

ack为1的时候，大部分情况下还是能保证1次的



通过kafka的幂等性和事务，加上 ack= -1 

可以保证精确一次。



### 数据有序

单分区内，有序，不过也是有条件的；

多分区，分区与分区间无序；



我们用于日志，不需要管它有没有序。







## 分区策略

默认分区策略

```
1. 指明partition的情况下

直接将指明的值作为partition值；例如partition=0，所有数据写入分区0
```



```
2. 使用分区键

没有指明partition值但有key的情况下，将key的hash值与topic的partition数进行取余得到partition值；例如：key1的hash值=5， key2的hash值=6 ，topic的partition数=2，那么key1 对应的value1写入1号分区，key2对应的value2写入0号分区。

```



```
3. 既没有partition值又没有key值的情况下，Kafka采用Sticky Partition（黏性分区器），会随机选择一个分区，并尽可能一直使用该分区，待该分区的batch已满或者已完成，Kafka再随机一个分区进行使用（和上一次的分区不同）。

例如：第一次随机选择0号分区，等0号分区当前批次满了（默认16k）或者linger.ms设置的时间到， Kafka再随机一个分区进
行使用（如果还是0会继续随机）。

```



一般我们自定义分区器，实现数据分区的均衡



## 小结



### 吞吐量、批处理发送相关参数

```
buffer.memory： 队列 缓冲区总大小，默认 32m。

batch.size：只有数据积累到batch.size之后，sender才会发送数据。默认16k ，增大能提高吞吐量，但是会增加传输延迟

linger.ms：如果数据迟迟未达到batch.size，sender等待linger.ms设置的时间 到了之后就会发送数据。单位ms，默认值是0ms，表示没有延迟。 增大能提高吞吐量，但是会增加传输延迟

compression.type：压缩，显然，如果压缩，会减小传输数据的大小，能够提高吞吐量，但是会增加CPU占用，感觉一般不开
```



吞吐量是日志系统最关心的



