# ubuntu 20.04 lts
MASTER_IP="192.168.56.133"
NODE_IP="192.168.56.133"
HOST_IP="192.168.56.133"

# default
POD_CIDR="10.244.0.0/16"
# default
SERVICE_CIDR="10.96.0.0/12"

# ================== Step 1: Initializing the Kubernetes Master Node ==================
# 先拉取coredns的镜像否则下一步会失败, 这里是国内镜像源造成的鬼畜 因为Tag多了一个v
sudo docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.8.4
sudo docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.8.4 registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:v1.8.4

# 初始化集群
sudo kubeadm init \
--ignore-preflight-errors=NumCPU,Mem \
--apiserver-advertise-address=$MASTER_IP \
--image-repository registry.aliyuncs.com/google_containers \
--pod-network-cidr=$POD_CIDR

# 配置kubectl 
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# ================== Step 2: Deploying a Pod Network ==================
# flannel https://github.com/flannel-io/flannel#deploying-flannel-manually
# 默认pod网段就直接执行
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

