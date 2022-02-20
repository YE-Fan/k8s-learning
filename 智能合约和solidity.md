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



### 消息调用

外部账户



## Solidity

![image-20220220032220758](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202200322813.png)



 