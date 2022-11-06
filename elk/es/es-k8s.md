# k8s部署es



## 内核参数

参考 https://artifacthub.io/packages/helm/bitnami/elasticsearch

Default kernel settings

Currently, Elasticsearch requires some changes in the kernel of the host machine to work as expected. If those values are not set in the underlying operating system, the ES containers fail to boot with ERROR messages. More information about these requirements can be found in the links below:

- [File Descriptor requirements](https://www.elastic.co/guide/en/elasticsearch/reference/current/file-descriptors.html)
- [Virtual memory requirements](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html)

This chart uses a **privileged** initContainer to change those settings in the Kernel by running: `sysctl -w vm.max_map_count=262144 && sysctl -w fs.file-max=65536`. You can disable the initContainer using the `sysctlImage.enabled=false` parameter.





## 拓扑图



### 角色不分离

![image-20221106202919138](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062029199.png)



StatefulSet来部署





### 角色分离版



![image-20221106202937573](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062054125.png)





![image-20221106205449735](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062054782.png)



![image-20221106211639430](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202211062116478.png)







- 协调节点用 deployment 部署，而且可以用上HPA进行随意伸缩
- master节点也用deployment部署，也可用  StatefulSets，但是不能随意伸缩，副本数最好固定，要用headless service供外访问
- data节点用Stateful Set部署，用PVC申明存储