NS1="NS1"
NS2="NS2"

NODE_IP="192.168.56.131"
BRIDGE_SUBNET="172.16.0.0/24"
BRIDGE_IP="172.16.0.1"
IP1="172.16.0.2"
IP2="172.16.0.3"
TUNNEL_IP="172.16.0.100"

TO_NODE_IP="192.168.56.132"
TO_BRIDGE_SUBNET="172.16.1.0/24"
TO_BRIDGE_IP="172.16.1.1"
TO_IP1="172.16.1.2"
TO_IP2="172.16.1.3"
TO_TUNNEL_IP="172.16.1.100"

echo "Createting the namespaces"
sudo ip netns add $NS1
sudo ip netns add $NS2
ip netns show

echo "Creating the veth pairs"
sudo ip link add veth10 type veth peer name veth11
sudo ip link add veth20 type veth peer name veth21
ip link show veth

echo "Adding the veth pairs to the namespaces"
sudo ip link set veth11 netns $NS1
sudo ip link set veth21 netns $NS2

echo "Configuring the interfaces in the network namespaces with IP address"
sudo ip netns exec $NS1 ip addr add $IP1/24 dev veth11
sudo ip netns exec $NS2 ip addr add $IP2/24 dev veth21

echo "Enabling the interfaces inside the network namespaces"
sudo ip netns exec $NS1 ip link set dev veth11 up
sudo ip netns exec $NS2 ip link set dev veth21 up

echo "Creating the bridge"
sudo ip link add br0 type bridge
ip link show type bridge
ip link show br0

echo "Adding the network namespaces interfaces to the bridge"
sudo ip link set dev veth10 master br0
sudo ip link set dev veth20 master br0

echo "Assigning the IP address to the bridge"
sudo ip addr add $BRIDGE_IP/24 dev br0

echo "Enabling the bridge"
sudo ip link set dev br0 up

echo "Enabling the interfaces connected to the bridge"
sudo ip link set dev veth10 up
sudo ip link set dev veth20 up

echo "Setting the loopback interfaces in the network namespaces"
sudp ip netns exec $NS1 ip link set lo up
sudp ip netns exec $NS2 ip link set lo up
sudo ip netns exec $NS1 ip a
sudo ip netns exec $NS2 ip a

echo "Setting the default route in the network namespaces"
sudo ip netns exec $NS1 ip route add default via $BRIDGE_IP dev veth11
sudo ip netns exec $NS2 ip route add default via $BRIDGE_IP dev veth21

# ---------------------- Step 3 Specific Setup ----------------------

echo "Setting the route on the node to reach the network namespaces on "
sudo ip route add $TO_BRIDGE_SUBNET via $TO_NODE_IP dev eth0

echo "Enables IP forwarding on the node"
sudo sysctl -w net.ipv4.ip_forward=1

# ---------------------- Step 4 Specific Setup  tunnel ----------------------
echo "Starts the UDP tunnel in the background"
sudo socat UDP:$TO_NODE_IP:9000,bind=$NODE_IP:9000 TUN:$TUNNEL_IP/16,tun-name=tundudp,iff-no-pi,tun-type=tun &
# 此时要去另一台机器也启动

echo "Setting the MTU on the tun interface"
sudo ip link set dev tundudp mtu 1492

echo "Setting the tundudp up"
sudo ip link set dev tundudp up

echo "Disables reverse path filtering"
sudo bash -c 'echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter'
sudo bash -c 'echo 0 > /proc/sys/net/ipv4/conf/eth0/rp_filter'
sudo bash -c 'echo 0 > /proc/sys/net/ipv4/conf/br0/rp_filter'
sudo bash -c 'echo 0 > /proc/sys/net/ipv4/conf/tundudp/rp_filter'

# ---------------------- Tests ----------------------

# Check routes in container1
sudo ip netns exec $NS1 ip route
# result NS1里的流量默认都从veth11走bridge了
# default via 172.16.0.1 dev veth11 
# 172.16.0.0/24 dev veth11 proto kernel scope link src 172.16.0.2 

# Examine what route the route to reach one of the container on Ubuntu2
ip route get $TO_IP1
# 没开启udp tunnel的时候，结果如下，去另一台机器，是走的虚拟机的vswitch (192.168.56.2)
# yefan@ubuntu1:~$ ip route get $TO_IP1
# 172.16.1.2 via 192.168.56.2 dev ens33 src 192.168.56.131 uid 1000 
#     cache 
# 开启udp tunnel之后，结果如下，去另一台机器，是走的udp tunnel($TUNNEL_IP)
# yefan@ubuntu1:~$ ip route get $TO_IP1
# 172.16.1.2 dev tundudp src 172.16.0.100 uid 1000 
#     cache 

# Ping a container hosted on Ubuntu2 from a ccontainer hosted on this server(Ubuntu1)
sudo ip netns exec $NS1 ping -c 1 $TO_IP1