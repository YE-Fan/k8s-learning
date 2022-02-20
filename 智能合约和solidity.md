## 以太坊核心概念

![image-20220220031609011](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202200316074.png)



智能合约 *Smart contract*

Solidity 运行在EVM上。类似于JAVA和JVM

### 账户

账户由地址和它的状态组成

![image-20220220132824373](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201328422.png)

账户分两类：

- 外部账户：EOA   由私钥（人）控制，对应的公钥（地址）就是外部账户
- 合约账户   把合约的字节码发布到区块链上，并由一个特别的地址标识这个合约，这个地址就是合约账户

对于智能合约来说，他们是一样的。

账户之间能够交互（交易），但是只能由外部账户能够发起交互。所以合约无法自己定时执行，因为它不能主动发起交互。



### 交易

![image-20220220133903577](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201339634.png)



用钱包发起一个交易。

![image-20220220134224972](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201342004.png)

点击next之后，就发起了交易。



成功后就能查看到这笔交易

![image-20220220134435306](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201344429.png)





向合约地址发起交易时，在payload传入对合约的函数的调用。这个二进制串是要调用的合约的函数的签名

![image-20220220134841966](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201348997.png)

其代表的内容是如下，下图是解析后的，方便人看的格式

![image-20220220135027861](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201350908.png)









为什么说事务性（原子性），交易的扣钱和加钱是在一次交易里的，打包在一个区块里，不会出现一个成功一个失败





### 部署智能合约

其实就是payload传了代表智能合约的二进制内容。这样我就部署了一个helloworld的合约上去

![image-20220220135132004](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201351030.png)



### 消息调用

![image-20220220135342154](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201353211.png)

下图展示了3种不同方式的消息调用

![image-20220220135605004](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201356079.png)



消息调用不管发生了几层，它用的gas都是最初外部账户触发交易时的gas



### 钱包

![image-20220220143848165](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201438222.png)

![image-20220220144155128](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201441175.png)

### gas

使用区块链的费用

![image-20220220144347941](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201443989.png)

![image-20220220144606520](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201446574.png)

如图，一次加号（ADD）要消耗3个gas

![image-20220220144857729](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201448776.png)

gas limit

![image-20220220144635759](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201446812.png)

如下图，我用钱包发起交易后，还要填GAS来确认交易。其中GWEI是以太币的一个单位, 10E-9次方

![image-20220220144739461](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201447495.png)

![image-20220220144959496](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201449515.png)

超过gas limit了就会抛异常并回滚



### 以太坊网络

![image-20220220145310446](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201453503.png)

![image-20220220145409678](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201454749.png)



## Solidity

![image-20220220032220758](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202200322813.png)



### Remix

https://remix.ethereum.org

 ![image-20220220150459936](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201505030.png)



![image-20220220150855625](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201508679.png)



客户端版

![image-20220220151133199](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201511286.png)



## MetaMask

![image-20220220151329767](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201513809.png)

钱包都是要连接到节点上的，在MetaMask上连接的不管主网络还是测试网络，都是连接到MetaMask给我们提供的节点



我们可以连接自己的本地节点

![image-20220220151731000](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201517045.png)

我们启动Geth后，会在本地提供一个RPC server（http地址），可以用MetaMask连接这个地址，这样就连接到本地节点了

