

## 简介

![image-20220618063414333](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180634375.png)



无论是 resource metric还是custom metric还是external metric， 

k8s-prometheus-adapter通过向prometheus查询这3类指标，然后注册到k8s的aggregation server。



k8s-prometheus-adapter做的，就是把对k8s metric api的查询，在内部转换成对 prometheus 时间序列的查询





## Resource Metrics



实际上，我们能用k8s-prometheus-adapter, 把原本的metric api提供的信息，给它替换成从k8s-prometheus-adapter得到的信息。

让k8s的 resource metric，不是直接从Kubelet的cAdvisor拿，而是通过k8s-prometheus-adapter从Prometheus拿。



下面这是对k8s-prometheus-adapter的配置，只是一个示例。

![image-20220618065911059](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180659100.png)



![image-20220618065920788](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180659824.png)





## Custom Metrics

具体做的事情，就是让k8s的custom metric api 能获取到我们自定义的指标。

如下对k8s api的访问：

就是通过 /apis/custom.metric.k8s.io/v1beta1 这个api

获取 default namspace下， podinfo-67xxxxxx这个pod的qps指标。

![image-20220618091627247](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180916282.png)



要完成上述目标，

把自定义的指标暴露给k8s的 custom metric api， 有以下四个步骤



![image-20220618090654193](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180906228.png)







1. Discovery 在k8s-prometheus-adapter中配置查询哪个指标

下图，就是表明 我要把外部的

![image-20220618090915986](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180909016.png)

下面是这个指标在prometheus中的保存形式

![image-20220618090942220](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180909257.png)





2. 把这个指标绑定给某个资源，比如说我要绑定给pod



![image-20220618091012963](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180910995.png)

绑定的意思，就是要把 Prometheus 的指标里面的label，和k8s的资源对应起来。

比如说

| prometheus指标的label | k8s资源   |      |
| --------------------- | --------- | ---- |
| node                  | node      |      |
| pod                   | pod       |      |
| namespace             | namespace |      |

假如说label和k8s资源的名字恰好符合规范，那么可以用k8s-prometheus-adapter的模板变量 `<<.Resource>>`来完成自动对应，如上面那张图就是使用了这个模板变量。

下图展示了使用模板变量 `<<.Resource>>` 之后我们这个qps的指标的label和k8s资源的绑定关系

![image-20220618092357805](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180923844.png)



当然我们也可以使用下图这样的例子，来手动绑定，

下面这张图，就是手动指明， 指标里面label的node 绑定到资源node， pod_name绑定到pod

![image-20220618092531738](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180933041.png)



3. Naming  指标重命名

我们在Prometheus里的原始指标叫做 http_requests_total

但是我们通过k8s Api查询pod的指标叫做 http_requests_per_second

所以要重命名。

下面是使用正则表达式重命名指标的例子

![image-20220618092824892](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180933893.png)





4. Querying  如何查询这个指标

前面3步，指明了我们要查什么指标，怎么和k8s的资源绑定。

第四步，我们就是要指明，让prometheus执行什么语句，来真正获取这个指标

图中的  <<某某某>>，是k8s-prometheus-adapter的模板变量

![image-20220618093007956](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180933427.png)

图中这样的配置，实际在Prometheus里面，就是以下的查询

![image-20220618093316276](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180933307.png)

下面是模板变量的一些例子

![image-20220618093415189](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180934237.png)





通过前面的配置，就完成了把我们自定义的指标，绑定到k8s custom metric api的步骤。

就可以通过k8s的api去查询指标了，如下 获取 default namspace下， podinfo-67xxxxxx这个pod的qps指标。

![image-20220618091627247](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180916282.png)



## External Metrics

步骤和Custom Metric几乎一样

不同点是，custom metric 绑定到K8s的内部资源，但是external metric却不是， 不过可以绑定到k8s  namespace



![image-20220618095205015](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206180952052.png)





## autoscaler



通过Prometheus adaptor，我们把metric暴露到k8s metric api了，因此，我们在使用HPA的时候，就能够使用这些metric作为指标参考。



![image-20220618100325421](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206181003458.png)

## 注意点



可能会和Metric Server 冲突

因为k8s的metric api 不能只能被一方代理





![image-20220618100707301](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202206181007344.png)



## 其他参考资料

https://www.freesion.com/article/1890405282/

https://copyfuture.com/blogs-details/20210103173205885C

https://kingjcy.github.io/post/cloud/paas/base/kubernetes/k8s-autoscaler/

http://blog.itpub.net/28916011/viewspace-2216340/

https://help.aliyun.com/document_detail/181491.html

https://github.com/kubernetes-sigs/prometheus-adapter

https://github.com/prometheus-operator/kube-prometheus/issues/312

https://cloud.tencent.com/document/product/457/50125

**http://www.xuyasong.com/?page_id=1827**