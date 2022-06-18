

## metris简介

参考 CNCF的视频 Deep Dive: Kubernetes Metric APIs using Prometheus   https://www.youtube.com/watch?v=cIoOAbzhR7k

> 这个视频里，kubectl 读作cube 卡特儿.....



![image-20220618062127362](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180621537.png)



![image-20220618062143331](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180621365.png)





3种metricApi

![image-20220618062256153](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180622190.png)

- resource Api
  - 最基本的容器信息
- custom  metric
  - 对k8s内部对象的指标，  比如我某个deployment app的 qps
- external
  - 在k8s内部，来访问外部metric





通常大家都用的metric server， 提供最基本的容器资源使用信息，但是它不包括custom和external的metric

![image-20220618062706521](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180627554.png)





## Resource Metric



![image-20220618064641201](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180646242.png)

图中的AVAILABLE 为 True，表明它已经注册到 aggregation api server了



硬编码在k8s内部。

最著名的就是Node Metrics， Pod Metrics的CPU和内存



kubectl top背后本质就是调用的resource metric api

![image-20220618064910767](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180649802.png)



![image-20220618064943854](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180649887.png)





## Cunstom Metrics

![image-20220618070149630](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180704161.png)





![image-20220618070324727](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180703760.png)





下面是如何获取已经注册的 custom metric。

比如下面pod就多了qps的 metric

![image-20220618070351938](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180704202.png)