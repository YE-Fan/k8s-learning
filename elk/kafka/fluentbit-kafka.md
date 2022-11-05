



| Key                | Description                                                  | default    | 说明                                                         |
| :----------------- | :----------------------------------------------------------- | :--------- | ------------------------------------------------------------ |
| format             | Specify data format, options available: json, msgpack.       | json       | 不变                                                         |
| message_key        | Optional key to store the message                            |            | 没看懂                                                       |
| message_key_field  | If set, the value of Message_Key_Field in the record will indicate the message key. If not set nor found in the record, Message_Key will be used (if set). |            | 没看懂                                                       |
| timestamp_key      | Set the key to store the record timestamp                    | @timestamp | fluentbit的record的时间戳，变成kafka里的消息比如json格式消息后，它的时间戳会变成消息里的一个字段，此处就是那个字段名 |
| timestamp_format   | 'iso8601' or 'double'                                        | double     |                                                              |
| brokers            | Single of multiple list of Kafka Brokers, e.g: 192.168.1.3:9092, 192.168.1.4:9092. |            |                                                              |
| topics             | Single entry or list of topics separated by comma (,) that Fluent Bit will use to send messages to Kafka. If only one topic is set, that one will be used for all records. Instead if multiple topics exists, the one set in the record by Topic_Key will be used. | fluent-bit |                                                              |
| topic_key          | If multiple Topics exists, the value of Topic_Key in the record will indicate the topic to use. E.g: if Topic_Key is *router* and the record is {"key1": 123, "router": "route_2"}, Fluent Bit will use topic *route_2*. Note that if the value of Topic_Key is not present in Topics, then by default the first topic in the Topics list will indicate the topic to be used. |            | record里的哪个key作为topic.一般用这个而不是固定的topic。注意！如果topic不在上面的topics中，那么会默认用topics中的第一个，所以我们必须要开启dynamic_topic来避免 |
| dynamic_topic      | adds unknown topics (found in Topic_Key) to Topics. So in Topics only a default topic needs to be configured | Off        |                                                              |
| queue_full_retries | Fluent Bit queues data into rdkafka library, if for some reason the underlying library cannot flush the records the queue might fills up blocking new addition of records. The `queue_full_retries` option set the number of local retries to enqueue the data. The default value is 10 times, the interval between each retry is 1 second. Setting the `queue_full_retries` value to `0` set's an unlimited number of retries. | 10         | fluentbit和底层的发送库之间，有一个缓冲队列，如果队列满了，会阻塞发新的records, 阻塞后，fluentbit会去重试。默认每秒重试一次，共重试10次。这个参数就是设置重试次数 |
| rdkafka.{property} | `{property}` can be any [librdkafka properties](https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md) |            | 底层的发送库的参数                                           |



|      |      |      |      |
| :--- | :--- | :--- | ---- |
|      |      |      |      |
|      |      |      |      |
|      |      |      |      |
|      |      |      |      |
|      |      |      |      |
|      |      |      |      |
|      |      |      |      |
|      |      |      |      |
|      |      |      |      |
|      |      |      |      |
|      |      |      |      |



| Property                                              | C/P  | Range           | Default    | Importance | Description                                                  |                                           |
| ----------------------------------------------------- | ---- | --------------- | ---------- | ---------- | ------------------------------------------------------------ | ----------------------------------------- |
| client.id                                             | *    |                 | rdkafka    | low        | Client identifier. *Type: string*                            | 客户端id，我们可以写fluentbit-kafka       |
| acks                                                  | P    | -1 .. 1000      | -1         | high       | Alias for `request.required.acks`: This field indicates the number of acknowledgements the leader broker must receive from ISR brokers before responding to the request: *0*=Broker does not send any response/ack to client, *-1* or *all*=Broker will block until message is committed by all in sync replicas (ISRs). If there are less than `min.insync.replicas` (broker configuration) in the ISR set the produce request will fail. *Type: integer* | 需要设置成1。我们不需要-1那么高的可靠性   |
|                                                       |      |                 |            |            |                                                              |                                           |
| log.connection.close                                  | *    | true, false     | true       | low        | Log broker disconnects. It might be useful to turn this off when interacting with 0.9 brokers with an aggressive `connections.max.idle.ms` value. *Type: boolean* | 是否打印连接断开的日志。我们要调整为false |
|                                                       |      |                 |            |            |                                                              |                                           |
|                                                       |      |                 |            |            |                                                              |                                           |
| 下面4个参数就是配置发送缓冲队列，影响吞吐量和传输延时 |      |                 |            |            |                                                              |                                           |
| queue.buffering.max.messages                          | P    | 0 .. 2147483647 | 100000     | high       | Maximum number of messages allowed on the producer queue. This queue is shared by all topics and partitions. A value of 0 disables this limit. *Type: integer* |                                           |
| queue.buffering.max.kbytes                            | P    | 1 .. 2147483647 | 1048576    | high       | Maximum total message size sum allowed on the producer queue. This queue is shared by all topics and partitions. This property has higher priority than queue.buffering.max.messages. *Type: integer* |                                           |
| queue.buffering.max.ms                                | P    | 0 .. 900000     | 5          | high       | Delay in milliseconds to wait for messages in the producer queue to accumulate before constructing message batches (MessageSets) to transmit to brokers. A higher value allows larger and more effective (less overhead, improved compression) batches of messages to accumulate at the expense of increased message delivery latency. *Type: float* | 等同于linger.ms                           |
| linger.ms                                             | P    | 0 .. 900000     | 5          | high       | Alias for `queue.buffering.max.ms`: Delay in milliseconds to wait for messages in the producer queue to accumulate before constructing message batches (MessageSets) to transmit to brokers. A higher value allows larger and more effective (less overhead, improved compression) batches of messages to accumulate at the expense of increased message delivery latency. *Type: float* |                                           |
|                                                       |      |                 |            |            |                                                              |                                           |
| 下面4个参数，影响重试和背压，看上去不需要调整         |      |                 |            |            |                                                              |                                           |
| message.send.max.retries                              | P    | 0 .. 2147483647 | 2147483647 | high       | How many times to retry sending a failing Message. **Note:** retrying may cause reordering unless `enable.idempotence` is set to true. *Type: integer* |                                           |
| retries                                               | P    | 0 .. 2147483647 | 2147483647 | high       | Alias for `message.send.max.retries`: How many times to retry sending a failing Message. **Note:** retrying may cause reordering unless `enable.idempotence` is set to true. *Type: integer* |                                           |
| retry.backoff.ms                                      | P    | 1 .. 300000     | 100        | medium     | The backoff time in milliseconds before retrying a protocol request. *Type: integer* |                                           |
| queue.buffering.backpressure.threshold                | P    | 1 .. 1000000    | 1          | low        | The threshold of outstanding not yet transmitted broker requests needed to backpressure the producer's message accumulator. If the number of not yet transmitted requests equals or exceeds this number, produce request creation that would have otherwise been triggered (for example, in accordance with linger.ms) will be delayed. A lower number yields larger and more effective batches. A higher value can improve latency when using compression on slow machines. *Type: integer* |                                           |
|                                                       |      |                 |            |            |                                                              |                                           |
| request.timeout.ms                                    | P    | 1 .. 900000     | 30000      | medium     | The ack timeout of the producer request in milliseconds. This value is only enforced by the broker and relies on `request.required.acks` being != 0. *Type: integer* | 等待ack的超时时间。没必要改               |
| message.timeout.ms                                    | P    | 0 .. 2147483647 | 300000     | high       | Local message timeout. This value is only enforced locally and limits the time a produced message waits for successful delivery. A time of 0 is infinite. This is the maximum time librdkafka may use to deliver a message (including retries). Delivery error occurs when either the retry count or the message timeout are exceeded. The message timeout is automatically adjusted to `transaction.timeout.ms` if `transactional.id` is configured. *Type: integer* | 发送消息的超时时间。没必要改。            |





```
format json
timestamp_key @timestamp
timestamp_format # 待定


brokers  # 待定

# topics # 用于配置固定的topic, 我们不用
topic_key
dynamic_topic On

queue_full_retries 0  # 无限尝试往底层的kafka库发record

rdkafka.client.id fluentbit-kafka
rdkafka.acks 1
rdkafka.log.connection.close false # 关闭打印和kafka连接关闭的信息，不然idle的连接断开了，会打印出来污染错误日志，fluentbit官方推荐关闭
# rdkafka的其它参数，如果遇到问题了再需要配置
```

