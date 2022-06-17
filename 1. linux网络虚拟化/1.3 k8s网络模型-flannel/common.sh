# ubuntu 20.04 lts

# DOCKER_VERSION=""
# K8S_VERSION=""

# ================== 安装k8s的前提条件 ==================
# 每台机器都需要有各自的host，云环境的话就不用了，会自动有的？这块忘记了
# 需要有sudo权限

# ================== Step 0: Install Docker ==================
# SEE https://docs.docker.com/engine/install/ubuntu/

# = Before you start installing Docker, you need to set up its repository. After that, you can install Docker from the repository.

# First, you need to update the apt package index and install a few packages. These packages will allow apt to use a repository over HTTPS
sudo apt-get update

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Then, you need to add GPG key of the official Docker repository to your system:
curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

# Next, you go ahead and add the official repository using this command:
sudo add-apt-repository \
   "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/ \
  $(lsb_release -cs) \
  stable"

# = Install Docker Engine

# Update the apt package index, and install the latest version of Docker Engine and containerd, or go to the next step to install a specific version:
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
#sudo apt-get install docker-ce=$DOCKER_VERSION docker-ce-cli=$DOCKER_VERSION containerd.io


# ================== Step 1: Install Kubernetes ==================

# 使得 apt 支持 ssl 传输
sudo apt install apt-transport-https curl

# 下载 gpg 密钥   这个需要root用户否则会报错
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add - 

# 添加 k8s 镜像源
#echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list
echo "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" >> ~/kubernetes.list
sudo mv ~/kubernetes.list /etc/apt/sources.list.d
sudo apt-get update

# 安装 kubelet kubeadm kubectl kubernetes-cni
sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

# ================== Step 2: Disabling Swap Memory ==================
# 临时关闭
sudo swapoff -a && sudo sysctl -w vm.swappiness=0
# 永久关闭
sudo sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab

# ================== Step 3: Setting Unique Hostnames ==================
# 跳过
# sudo hostnamectl set-hostname kubernetes-master


# ================== Step 4: Letting Iptables See Bridged Traffic ==================
# For the master and worker nodes to correctly see bridged traffic, you should ensure net.bridge.bridge-nf-call-iptables is set to 1 in your config. First, ensure the br_netfilter module is loaded. You can confirm this by issuing the command:
lsmod | grep br_netfilter

# Optionally, you can explicitly load it with the command:
sudo modprobe br_netfilter

# Now, you can run this command to set the value to 1:
sudo sysctl net.bridge.bridge-nf-call-iptables=1

# ================== Step 5: Changing Docker Cgroup Driver ==================

# By default, Docker installs with “cgroupfs” as the cgroup driver. Kubernetes recommends that Docker should run with “systemd” as the driver. If you skip this step and try to initialize the kubeadm in the next step, you will get the following warning in your terminal:

# [preflight] Running pre-flight checks
#    [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/


# On both master and worker nodes, update the cgroupdriver with the following commands:

# sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{ "exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts":
{ "max-size": "100m" },
"storage-driver": "overlay2"
}
EOF

# Then, execute the following commands to restart and enable Docker on system boot-up:

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Once that is set, we can proceed to the fun stuff, deploying the Kubernetes cluster!

