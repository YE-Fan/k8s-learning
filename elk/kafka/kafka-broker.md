# kafka-broker





## 工作流程



### 启动、注册

![image-20221106160716261](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061607330.png)



### 选择controller

![image-20221106160758582](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061607646.png)

在kraft模式下，由配置文件决定，而不是选举



### 选举leader

topic的副本 分leader和follower

这个就是由controller决定的

![image-20221106160922636](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061609730.png)



### 同步leader信息

选出leader后，上传到zookeeper，共其它节点同步

![image-20221106161041555](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061610663.png)



### 假设leader挂了



controller会选其它的follwer作为新的leader

![image-20221106161256921](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211061612967.png)





## 水平扩缩容



### 扩容

1. 直接启动新的kafka加入集群
2. 手动进行负载均衡，让新节点









