



```sh
# 方便起见，使用root用户

# 添加namespace  red 和 blue
ip netns add red
ip netns add blue


# 添加veth pair   一端叫 veth-red  一端叫 veth-blue
ip link add veth-red type veth peer name veth-blue

# veth-red移动到netns red,  veth-blue移动到netns blue
ip link set veth-red netns red
ip link set veth-blue netns blue

# 给veth pair添加ip地址
ip -n  red  addr add 10.1.1.1/24 dev veth-red
ip -n  blue addr add 10.1.1.2/24 dev veth-blue

# 状态设置为up，创建出来默认是down
ip -n red  link set veth-red up
ip -n blue  link set veth-blue up

# 在一端ping另一端
ip netns exec red   ping 10.1.1.2
ip netns exec blue  ping 10.1.1.1

```







```sh
# 添加namespace  red 和 blue
ip netns add red
ip netns add blue

# 添加bridge   brd, 并设置为up状态
ip link add name brd type bridge
ip link set brd up

# 添加veth pair
ip link add veth-red type veth peer name veth-red-brd
ip link add veth-blue type veth peer name veth-blue-brd

# 一端连接到netns
ip link set veth-red netns red
ip link set veth-blue netns blue

# 一端连接到bridge
ip link set veth-red-brd master brd
ip link set veth-blue-brd master brd

# veth pair都设置为up
ip -n red  link set veth-red up
ip link set veth-red-brd up
ip -n blue  link set veth-blue up
ip link set veth-blue-brd up

# 全部添加ip地址
ip -n  red  addr add 10.1.1.1/24 dev veth-red
ip -n  blue addr add 10.1.1.2/24 dev veth-blue

```

