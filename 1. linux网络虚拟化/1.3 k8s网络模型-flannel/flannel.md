# flannel





## 安装前

### master 和 node 上的网卡

```sh
yefan@kube-node1-fl:~$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:9a:64:22 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
    link/ether 02:42:09:90:29:3a brd ff:ff:ff:ff:ff:ff
```



```sh
yefan@kube-master-fl:~$ ip link 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:3c:6e:18 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
    link/ether 02:42:8e:85:ab:c4 brd ff:ff:ff:ff:ff:ff
```



### k8s集群

```sh
yefan@kube-master-fl:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                     READY   STATUS    RESTARTS        AGE
kube-system   coredns-6d8c4cb4d-8pbx2                  0/1     Pending   0               5d16h
kube-system   coredns-6d8c4cb4d-vjzkv                  0/1     Pending   0               5d16h
kube-system   etcd-kube-master-fl                      1/1     Running   1 (2m47s ago)   5d16h
kube-system   kube-apiserver-kube-master-fl            1/1     Running   1 (5d16h ago)   5d16h
kube-system   kube-controller-manager-kube-master-fl   1/1     Running   1 (2m47s ago)   5d16h
kube-system   kube-proxy-hxvfp                         1/1     Running   1 (2m45s ago)   5d16h
kube-system   kube-proxy-nmr98                         1/1     Running   1 (5d16h ago)   5d16h
kube-system   kube-scheduler-kube-master-fl            1/1     Running   1 (2m47s ago)   5d16h


yefan@kube-master-fl:~$ kubectl get nodes
NAME             STATUS     ROLES                  AGE     VERSION
kube-master-fl   NotReady   control-plane,master   5d16h   v1.23.1
kube-node1-fl    NotReady   <none>                 5d16h   v1.23.1


yefan@kube-master-fl:~$ kubectl get cs
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE                         ERROR
scheduler            Healthy   ok                              
controller-manager   Healthy   ok                              
etcd-0               Healthy   {"health":"true","reason":""} 
```



coredns是pending的

节点是unready的



## 安装后





### k8s 集群

```sh
yefan@kube-master-fl:~$ kubectl get pods -n kube-system
NAME                                     READY   STATUS    RESTARTS        AGE
coredns-6d8c4cb4d-8pbx2                  1/1     Running   0               5d16h
coredns-6d8c4cb4d-vjzkv                  1/1     Running   0               5d16h
etcd-kube-master-fl                      1/1     Running   1 (14m ago)     5d16h
kube-apiserver-kube-master-fl            1/1     Running   1 (5d16h ago)   5d16h
kube-controller-manager-kube-master-fl   1/1     Running   1 (14m ago)     5d16h
kube-flannel-ds-6txx5                    1/1     Running   0               71s
kube-flannel-ds-c8z95                    1/1     Running   0               71s
kube-proxy-hxvfp                         1/1     Running   1 (14m ago)     5d16h
kube-proxy-nmr98                         1/1     Running   1 (5d16h ago)   5d16h
kube-scheduler-kube-master-fl            1/1     Running   1 (14m ago)     5d16h

yefan@kube-master-fl:~$ kubectl get nodes
NAME             STATUS   ROLES                  AGE     VERSION
kube-master-fl   Ready    control-plane,master   5d16h   v1.23.1
kube-node1-fl    Ready    <none>                 5d16h   v1.23.1

yefan@kube-master-fl:~$ kubectl get cs
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE                         ERROR
controller-manager   Healthy   ok                              
scheduler            Healthy   ok                              
etcd-0               Healthy   {"health":"true","reason":""}  
```

coreDns 变成Running了

多了flannel的pod

节点也变成ready了



### master和node上的网卡

```sh
yefan@kube-master-fl:~$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:3c:6e:18 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
    link/ether 02:42:8e:85:ab:c4 brd ff:ff:ff:ff:ff:ff
4: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default 
    link/ether aa:77:16:6c:8a:d7 brd ff:ff:ff:ff:ff:ff
5: cni0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether e6:8b:8f:da:c3:de brd ff:ff:ff:ff:ff:ff
6: veth366e17d8@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default 
    link/ether 3e:33:88:9d:95:0b brd ff:ff:ff:ff:ff:ff link-netnsid 0
7: veth37be2869@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default 
    link/ether 76:99:0a:06:0d:68 brd ff:ff:ff:ff:ff:ff link-netnsid 1
```



```sh
yefan@kube-node1-fl:~$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:9a:64:22 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
    link/ether 02:42:09:90:29:3a brd ff:ff:ff:ff:ff:ff
4: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default 
    link/ether c6:4d:5e:fd:9a:43 brd ff:ff:ff:ff:ff:ff
```



显然, 二者都多出了叫做flannel.1的网卡。

而master上还有cni0和两张veth网卡，是因为master上有pod。验证如下

```sh
yefan@kube-master-fl:~$ kubectl get pods -o wide --all-namespaces
NAMESPACE     NAME                                     READY   STATUS    RESTARTS        AGE     IP               NODE             NOMINATED NODE   READINESS GATES
kube-system   coredns-6d8c4cb4d-8pbx2                  1/1     Running   0               5d17h   10.244.0.3       kube-master-fl   <none>           <none>
kube-system   coredns-6d8c4cb4d-vjzkv                  1/1     Running   0               5d17h   10.244.0.2       kube-master-fl   <none>           <none>
kube-system   etcd-kube-master-fl                      1/1     Running   1 (42m ago)     5d17h   192.168.56.133   kube-master-fl   <none>           <none>
kube-system   kube-apiserver-kube-master-fl            1/1     Running   1 (5d17h ago)   5d17h   192.168.56.133   kube-master-fl   <none>           <none>
kube-system   kube-controller-manager-kube-master-fl   1/1     Running   1 (42m ago)     5d17h   192.168.56.133   kube-master-fl   <none>           <none>
kube-system   kube-flannel-ds-6txx5                    1/1     Running   0               29m     192.168.56.134   kube-node1-fl    <none>           <none>
kube-system   kube-flannel-ds-c8z95                    1/1     Running   0               29m     192.168.56.133   kube-master-fl   <none>           <none>
kube-system   kube-proxy-hxvfp                         1/1     Running   1 (42m ago)     5d17h   192.168.56.134   kube-node1-fl    <none>           <none>
kube-system   kube-proxy-nmr98                         1/1     Running   1 (5d17h ago)   5d17h   192.168.56.133   kube-master-fl   <none>           <none>
kube-system   kube-scheduler-kube-master-fl            1/1     Running   1 (42m ago)     5d17h   192.168.56.133   kube-master-fl   <none>           <none>
```

显然这两张veth就是2个codedns pod用的。

如果我们再创建其它pod，调度到node1上，那么Node1也会出现veth和cni0的网卡。验证如下：

```sh
kubectl create deployment hello-node --image=k8s.gcr.io/echoserver:1.4
```



```sh
yefan@kube-node1-fl:~$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:9a:64:22 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
    link/ether 02:42:09:90:29:3a brd ff:ff:ff:ff:ff:ff
4: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default 
    link/ether c6:4d:5e:fd:9a:43 brd ff:ff:ff:ff:ff:ff
5: cni0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether c2:38:b7:a7:e7:26 brd ff:ff:ff:ff:ff:ff
6: veth8703809b@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default 
    link/ether 7a:87:67:4f:92:0d brd ff:ff:ff:ff:ff:ff link-netnsid 0
```





如拓扑图

![image-20220103145607122](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202201031456295.png)



其中cni0和veth之间是绑定的

```sh
yefan@kube-master-fl:~$ ip link show type bridge
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
    link/ether 02:42:8e:85:ab:c4 brd ff:ff:ff:ff:ff:ff
5: cni0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether e6:8b:8f:da:c3:de brd ff:ff:ff:ff:ff:ff
    
    
yefan@kube-master-fl:~$ ip link show type veth
6: veth366e17d8@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default 
    link/ether 3e:33:88:9d:95:0b brd ff:ff:ff:ff:ff:ff link-netnsid 0
7: veth37be2869@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default 
    link/ether 76:99:0a:06:0d:68 brd ff:ff:ff:ff:ff:ff link-netnsid 1
    

yefan@kube-master-fl:~$ bridge link show | grep cni0
6: veth366e17d8@docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 master cni0 state forwarding priority 32 cost 2 
7: veth37be2869@docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 master cni0 state forwarding priority 32 cost 2 
```



### 路由表

```sh
yefan@kube-master-fl:~$ ip route
# 这条是vmware的vswitch，虚拟机的默认流量都从这走，让本虚拟机可以访问外面的网络
default via 192.168.56.2 dev ens33 proto dhcp src 192.168.56.133 metric 100 
# 这条是对本机器上pod的访问，访问本机器的pod，都从网桥cni0走流量
10.244.0.0/24 dev cni0 proto kernel scope link src 10.244.0.1 
# 这条是对其它机器(kube-node1-fl)上pod的访问，访问那台机器的pod，流量都从隧道flannel.1走
10.244.1.0/24 via 10.244.1.0 dev flannel.1 onlink 
# 这条是docker的暂时不管他
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
# 和这个vmware创建的其它虚拟机沟通，都走ens33
192.168.56.0/24 dev ens33 proto kernel scope link src 192.168.56.133 
# 这条也是虚拟机相关的，不管他
192.168.56.2 dev ens33 proto dhcp scope link src 192.168.56.133 metric 100 
```



## 访问pod

首先创建nginx deploy和nodeport service



查看pod和service

```sh
yefan@kube-master-fl:~$ kubectl get pods -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP           NODE            NOMINATED NODE   READINESS GATES
nginx-deployment-9fbb7d78-wwtwv   1/1     Running   0          14s   10.244.1.6   kube-node1-fl   <none>           <none>
nginx-deployment-9fbb7d78-z8g66   1/1     Running   0          28s   10.244.1.5   kube-node1-fl   <none>           <none>
```

```sh
yefan@kube-master-fl:~$ kubectl get service
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
kubernetes      ClusterIP   10.96.0.1       <none>        443/TCP           5d17h
nginx-service   NodePort    10.107.16.132   <none>        30080:30011/TCP   5m27s
```



### 通过nodeport service访问



能访问通

```sh
yefan@kube-master-fl:~$ curl http://192.168.56.133:30011
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```





### 直接访问pod

在master上访问了node1上的pod.   能访问通

```sh
yefan@kube-master-fl:~$ curl http://10.244.1.6:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```



### 在pod内部，访问其它机器上的pod

如下拓扑

![image-20220103211256382](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202201032112469.png)

调整pod的容忍，重新部署pod，让它分别在master和node上都有一个

```sh
yefan@kube-master-fl:~$ kubectl get pods -o wide
NAME                               READY   STATUS    RESTARTS   AGE   IP           NODE             NOMINATED NODE   READINESS GATES
nginx-deployment-d9b954f65-2scxn   1/1     Running   0          28s   10.244.1.7   kube-node1-fl    <none>           <none>
nginx-deployment-d9b954f65-djxrj   1/1     Running   0          27s   10.244.0.4   kube-master-fl   <none>           <none>
```





在master的ens33网卡上抓包

```sh
sudo tshark -V --color -i ens33 -d udp.port=8472,vxlan -f "port 8472"

-V 表示详细信息
```



进入master上的pod

```sh
yefan@kube-master-fl:~$ kubectl exec -it nginx-deployment-d9b954f65-djxrj -- sh
```



#### 直接访问其它机器的pod

master上访问node上的pod

```sh
yefan@kube-master-fl:~$ kubectl exec -it nginx-deployment-d9b954f65-djxrj -- sh
/ # curl http://10.244.1.7:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
/ # 
```



node上抓到的包

第一帧

```
Frame 1: 124 bytes on wire (992 bits), 124 bytes captured (992 bits) on interface ens33, id 0
    Interface id: 0 (ens33)
        Interface name: ens33
    Encapsulation type: Ethernet (1)
    Arrival Time: Jan  3, 2022 07:42:40.688877390 UTC
    [Time shift for this packet: 0.000000000 seconds]
    Epoch Time: 1641195760.688877390 seconds
    [Time delta from previous captured frame: 0.000000000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 0.000000000 seconds]
    Frame Number: 1
    Frame Length: 124 bytes (992 bits)
    Capture Length: 124 bytes (992 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:udp:vxlan:eth:ethertype:ip:tcp]
    [Coloring Rule Name: HTTP]
    [Coloring Rule String: http || tcp.port == 80 || http2]
Ethernet II, Src: VMware_3c:6e:18 (00:0c:29:3c:6e:18), Dst: VMware_9a:64:22 (00:0c:29:9a:64:22)
    Destination: VMware_9a:64:22 (00:0c:29:9a:64:22)
        Address: VMware_9a:64:22 (00:0c:29:9a:64:22)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: VMware_3c:6e:18 (00:0c:29:3c:6e:18)
        Address: VMware_3c:6e:18 (00:0c:29:3c:6e:18)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
Internet Protocol Version 4, Src: 192.168.56.133, Dst: 192.168.56.134
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x00 (DSCP: CS0, ECN: Not-ECT)
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..00 = Explicit Congestion Notification: Not ECN-Capable Transport (0)
    Total Length: 110
    Identification: 0x8936 (35126)
    Flags: 0x0000
        0... .... .... .... = Reserved bit: Not set
        .0.. .... .... .... = Don't fragment: Not set
        ..0. .... .... .... = More fragments: Not set
    Fragment offset: 0
    Time to live: 64
    Protocol: UDP (17)
    Header checksum: 0xfeec [validation disabled]
    [Header checksum status: Unverified]
    Source: 192.168.56.133
    Destination: 192.168.56.134
User Datagram Protocol, Src Port: 45069, Dst Port: 8472
    Source Port: 45069
    Destination Port: 8472
    Length: 90
    Checksum: 0x368f [unverified]
    [Checksum Status: Unverified]
    [Stream index: 0]
    [Timestamps]
        [Time since first frame: 0.000000000 seconds]
        [Time since previous frame: 0.000000000 seconds]
Virtual eXtensible Local Area Network
    Flags: 0x0800, VXLAN Network ID (VNI)
        0... .... .... .... = GBP Extension: Not defined
        .... .... .0.. .... = Don't Learn: False
        .... 1... .... .... = VXLAN Network ID (VNI): True
        .... .... .... 0... = Policy Applied: False
        .000 .000 0.00 .000 = Reserved(R): 0x0000
    Group Policy ID: 0
    VXLAN Network Identifier (VNI): 1
    Reserved: 0
Ethernet II, Src: aa:77:16:6c:8a:d7 (aa:77:16:6c:8a:d7), Dst: c6:4d:5e:fd:9a:43 (c6:4d:5e:fd:9a:43)
    Destination: c6:4d:5e:fd:9a:43 (c6:4d:5e:fd:9a:43)
        Address: c6:4d:5e:fd:9a:43 (c6:4d:5e:fd:9a:43)
        .... ..1. .... .... .... .... = LG bit: Locally administered address (this is NOT the factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: aa:77:16:6c:8a:d7 (aa:77:16:6c:8a:d7)
        Address: aa:77:16:6c:8a:d7 (aa:77:16:6c:8a:d7)
        .... ..1. .... .... .... .... = LG bit: Locally administered address (this is NOT the factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
Internet Protocol Version 4, Src: 10.244.0.4, Dst: 10.244.1.7
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x00 (DSCP: CS0, ECN: Not-ECT)
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..00 = Explicit Congestion Notification: Not ECN-Capable Transport (0)
    Total Length: 60
    Identification: 0x5696 (22166)
    Flags: 0x4000, Don't fragment
        0... .... .... .... = Reserved bit: Not set
        .1.. .... .... .... = Don't fragment: Set
        ..0. .... .... .... = More fragments: Not set
    Fragment offset: 0
    Time to live: 63
    Protocol: TCP (6)
    Header checksum: 0xce33 [validation disabled]
    [Header checksum status: Unverified]
    Source: 10.244.0.4
    Destination: 10.244.1.7
Transmission Control Protocol, Src Port: 57240, Dst Port: 80, Seq: 0, Len: 0
    Source Port: 57240
    Destination Port: 80
    [Stream index: 0]
    [TCP Segment Len: 0]
    Sequence number: 0    (relative sequence number)
    Sequence number (raw): 1684892138
    [Next sequence number: 1    (relative sequence number)]
    Acknowledgment number: 0
    Acknowledgment number (raw): 0
    1010 .... = Header Length: 40 bytes (10)
    Flags: 0x002 (SYN)
        000. .... .... = Reserved: Not set
        ...0 .... .... = Nonce: Not set
        .... 0... .... = Congestion Window Reduced (CWR): Not set
        .... .0.. .... = ECN-Echo: Not set
        .... ..0. .... = Urgent: Not set
        .... ...0 .... = Acknowledgment: Not set
        .... .... 0... = Push: Not set
        .... .... .0.. = Reset: Not set
        .... .... ..1. = Syn: Set
            [Expert Info (Chat/Sequence): Connection establish request (SYN): server port 80]
                [Connection establish request (SYN): server port 80]
                [Severity level: Chat]
                [Group: Sequence]
        .... .... ...0 = Fin: Not set
        [TCP Flags: ··········S·]
    Window size value: 64860
    [Calculated window size: 64860]
    Checksum: 0xa3e8 [unverified]
    [Checksum Status: Unverified]
    Urgent pointer: 0
    Options: (20 bytes), Maximum segment size, SACK permitted, Timestamps, No-Operation (NOP), Window scale
        TCP Option - Maximum segment size: 1410 bytes
            Kind: Maximum Segment Size (2)
            Length: 4
            MSS Value: 1410
        TCP Option - SACK permitted
            Kind: SACK Permitted (4)
            Length: 2
        TCP Option - Timestamps: TSval 2342082080, TSecr 0
            Kind: Time Stamp Option (8)
            Length: 10
            Timestamp value: 2342082080
            Timestamp echo reply: 0
        TCP Option - No-Operation (NOP)
            Kind: No-Operation (1)
        TCP Option - Window scale: 7 (multiply by 128)
            Kind: Window Scale (3)
            Length: 3
            Shift count: 7
            [Multiplier: 128]
    [Timestamps]
        [Time since first frame in this TCP stream: 0.000000000 seconds]
        [Time since previous frame in this TCP stream: 0.000000000 seconds]

```



分析

```
master
ens33      00:0c:29:3c:6e:18     192.168.56.133
flannel.1  aa:77:16:6c:8a:d7     10.244.0.0/32
pod                              10.244.0.4
```

```
node1
ens33      00:0c:29:9a:64:22     192.168.56.134
flannel.1  c6:4d:5e:fd:9a:43     10.244.1.0/32
pod                              10.244.1.7
```





**原始的包**

```sh
# 二层  master ens33 MAC 00:0c:29:3c:6e:18   ->    node1 ens33 MAC  00:0c:29:9a:64:22
Ethernet II, Src: VMware_3c:6e:18 (00:0c:29:3c:6e:18), Dst: VMware_9a:64:22 (00:0c:29:9a:64:22)
# 三层  master ens33 IP  192.168.56.133 -> node ens33 IP 192.168.56.134
Internet Protocol Version 4, Src: 192.168.56.133, Dst: 192.168.56.134
# udp  因为是udp隧道，目标端口是8472是udp隧道的固定端口
User Datagram Protocol, Src Port: 45069, Dst Port: 8472
```

封装的内部vxlan的包

```sh
# 二层  master flannel.1 MAC aa:77:16:6c:8a:d7   ->    node1 flannel.1 MAC  c6:4d:5e:fd:9a:43
Ethernet II, Src: aa:77:16:6c:8a:d7 (aa:77:16:6c:8a:d7), Dst: c6:4d:5e:fd:9a:43 (c6:4d:5e:fd:9a:43)
# 三层  master pod IP  10.244.0.4  -> node1  pod IP 10.244.1.7
Internet Protocol Version 4, Src: 10.244.0.4, Dst: 10.244.1.7
# tcp 因为我们的curl是http本质是tcp， 目标的端口是80是pod监听的端口
Transmission Control Protocol, Src Port: 57240, Dst Port: 80, Seq: 0, Len: 0
```





**如果是在master的flannel.1上抓包，抓到的包是**

```sh
# 二层  master flannel.1 MAC aa:77:16:6c:8a:d7   ->    node1 flannel.1 MAC  c6:4d:5e:fd:9a:43
Ethernet II, Src: aa:77:16:6c:8a:d7 (aa:77:16:6c:8a:d7), Dst: c6:4d:5e:fd:9a:43 (c6:4d:5e:fd:9a:43)
# 三层  master pod IP  10.244.0.4  -> node1  pod IP 10.244.1.7
Internet Protocol Version 4, Src: 10.244.0.4, Dst: 10.244.1.7
Transmission Control Protocol, Src Port: 57240, Dst Port: 80, Seq: 0, Len: 0
```

就是将要被后面封装的包



**如果是在CNI0上抓包，抓到的包是如下，（由于机器重启了，所以mac和ip与之前不同，直接用代称）**

```
二层  Ethernet II, Src: pod的eth0的MAC, Dst: 主机bridge cni0的MAC
三层  Internet Protocol Version 4, Src: master pod IP, Dst: node1  pod IP 10.244.1.7
Transmission Control Protocol, Src Port: 42046, Dst Port: 80, Seq: 76, Ack: 855, Len: 0
```



**如过是在veth上抓包，得到的结果同上，和在cni0上抓包的结果一样，MAC和IP之类的都一样**



**在网卡docker0上抓不到包**



数据包是  pod eth0 -> host veth -> host cni0 -> host flannel.1 -> host ens33 -> other host ens33 -> other host flannel.1 -> xxxxxxxxxx



![image-20220103232002969](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202201032320140.png)