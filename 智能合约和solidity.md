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



## MetaMask

![image-20220220151329767](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201513809.png)

钱包都是要连接到节点上的，在MetaMask上连接的不管主网络还是测试网络，都是连接到MetaMask给我们提供的节点



我们可以连接自己的本地节点

![image-20220220151731000](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201517045.png)

我们启动Geth后，会在本地提供一个RPC server（http地址），可以用MetaMask连接这个地址，这样就连接到本地节点了





## Solidity

![image-20220220032220758](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202200322813.png)



### Remix

https://remix.ethereum.org

 ![image-20220220150459936](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201505030.png)

要用新命令 npm i @remix-project/remixd



```
remixd -s ./
```





![image-20220220150855625](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201508679.png)





客户端版

![image-20220220151133199](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202201511286.png)







https://github.com/xilibi2003/leanSolidity



### QuickStart

1. ### 编写代码

```solidity
pragma solidity ^0.4.24;  // 编译器版本，不同版本好像语法是有点不同的

// 相当于类申明
contract SimpleStorage {
	// 状态变量
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public constant returns (uint) {
        return storedData;
    }

}
```

2. ### 钱包设置

MetaMask选择以太网测试网络Ropsten

![image-20220222001703483](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220017524.png)

一开始没有eth，先免费买一点，点购买

![image-20220222001754606](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220017640.png)

Ropsten ETH简称 rETH



Faucet就是水龙头，就是免费发币的地方

网上由很多Ropsten Faucet都提供这种服务，可以随便google搜一下，不过有的发币快有的慢。



由于太慢了，就改用rinkeby测试一下

搜了好几个，发现这个发币最快https://www.rinkebyfaucet.com/





3. ### 部署

remix连接网页钱包metamask



![image-20220222005114794](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220052153.png)

点击部署后会弹出

![image-20220222005650792](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220056821.png)



确认后得到报错

![image-20220222013809935](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220138967.png)

点进去看报错

![image-20220222013833482](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220138539.png)

它说只支持 byzantium 块，可能和选了rinkeby测试链有关

修改remix的编译为byzantium格式的虚拟机

![image-20220222013949502](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220139533.png)

记得重新手动点一下编译，有时候不灵，多点几遍



这下能部署成功了

![image-20220222014013224](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220140246.png)

4. ### 执行

部署的页面最下面出现了刚部署的合约

![image-20220222014449609](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220144641.png)





![image-20220222014504649](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220145672.png)

黄色是修改状态，修改状态是要让矿工修改链的，所以要花费eth

蓝色get不会修改状态，不用花费。

测试：

点击get

![image-20220222014622787](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220146821.png)

一开始返回了初始值0.



set会弹出要付钱的对话框

![image-20220222014714331](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220147380.png)

过了一会儿，日志里面打印出

![image-20220222014845089](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220148109.png)

说明区块链操作成功了。



再一次发起get，发现得到了新状态 2

![image-20220222014813488](https://raw.githubusercontent.com/YE-Fan/k8s-learning/main/imgs/202202220148527.png)





### 基本结构

```solidity
pragma solidity 0.4.24;  表示我用的是0.4.24版本的编译器

或者
pragma solidity ^0.4.24; 表示[0.4.24, 0.5) 的版本都行，小版本号都兼容


pragma 翻译过来就是 编译指示
```





