

# 节点角色

![image-20221106202721409](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062027568.png)





![image-20221106202743845](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062027901.png)





## 几种架构

![image-20221106202919138](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062029199.png)





![image-20221106202937573](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062029662.png)







## Master  节点

注意，master是只有1个，这里3台是表示这3台有资格成为master

![image-20221106203021956](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062030049.png)



```
node.master: true
```



如果要纯主节点

```
node.master: true
node.data: false
```







## Data  节点



![image-20221106203039972](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062030092.png)



```
node.data: true
```



如果要纯数据节点

```
node.master: false
node.data: true
```





## Coordinating 节点

![image-20221106203149001](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062031079.png)

协调节点用于接收客户端请求，***\*将请求转发给保存数据的数据节点。每个数据节点在本地执行请求，并将结果返回给协调节点。协调节点收集完数据合，将每个数据节点的结果合并为单个全局结果。\****对结果收集和排序的过程可能需要很多CPU和内存资源。



**默认每个节点都是协调节点**



如果要纯协调节点，那么

```
node.master: false
node.data: false
```







## Ingest 节点



![image-20221106203242124](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062032225.png)



默认每个节点都开启了这个功能。

如果要纯Ingest节点

```
node.master: false
node.data: false
node.ingest: true
```







## 