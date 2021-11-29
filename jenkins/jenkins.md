[toc]



## CICD

持续集成     开发提交代码后，自动合并代码，触发镜像构建

持续交付    将通过集成测试的代码合并到可部署到生产的代码库、

持续部署    代码自动发布到环境中

##  Jenkins安装课堂笔记及常见问题分析定位

- 前置条件

  JDK、tomcat

- 安装tomcat

  下载地址： https://tomcat.apache.org/download-90.cgi

   useradd tomcat --新增一个名为tomcat的用户

   passwd tomcat --给tomcat用户设置密码 

  tar -zxvf apache-tomcat-9.0.8.tar.gz -C /usr/local/ --将tomcat解压到相应目录

   chown -R tomcat:tomcat /usr/local/apache-tomcat-9.0.8 --将整个目录的所属权转移给tomcat用户、tomcat组

- 安装Jenkins

  下载地址： https://jenkins.io/download/ 

  将Jenkins上传到tomcat的webapp目录

   chown tomcat:tomcat Jenkins.war 

  修改Jenkinswar包为tomcat用户所有 

  启动tomcat --通过浏览器无法访问tomcat

   1.看tomcat是否存活 ps aux | grep tomcat 

  2.看端口 netstat -tlun 看到8080端口已经使用了 

  3.检查防火墙 vim /etc/sysconfig/iptables 加入8080 

  4.查看tomcat日志 --》出现异常，地址已经被使用

   5.关闭tomcat --》 查看端口（步骤2）--》发现8080依旧存在 

  6.断定8080被其他程序占用 --》netstat -tlunp | grep 8080 -->看到被gitlab相关的程序使用了 

  7.修改tomcat端口 vim conf/server.xml ,找到8080 --》将8080改成不被占用的9999端口 

  8.防火墙开启9999端口

   9.可以正常访问tomcat

  浏览器打开http://192.168.56.101:9999/jenkins 

  more /home/tomcat/.jenkins/secrets/initialAdminPassword 

  将里面的内容复制粘贴 

  此时发现提示Jenkins离线

   访问 http://192.168.56.101:9999/jenkins/pluginManager/advanced 拉到最底下，将https--》改成http，之后提交 

  重启tomcat 浏览器打开http://192.168.56.101:9999/jenkins more /home/tomcat/.jenkins/secrets/initialAdminPassword 选择默认安装



## Jenkins插件安装及配置课堂笔记

- 插件安装

  系统管理--》插件管理 

  1.安装Maven Integration plugin 

  2.安装SonarQube Scanner for Jenkins 

  3.Publish Over SSH --发布到远程服务器

- 系统配置

  系统管理--》全局工具配置 

  1.配置jdk 

  2.配置maven 

  3.配置sonar 

  4.邮件配置 系统管理--》系统设置--》邮件通知--》 smtp服务器 smtp.qq.com 用户默认邮件后缀 @qq.com 勾选ssl Reply-To Address发件者邮箱 之后测试一下配置，无误即可

- 配置gitlab授权

  Credentials--》system--》Global credentials

- 配置免密登陆

  yum -y install openssh-clients 

  ssh-keygen -t rsa -- 产生私钥

   配置git登陆

   将Jenkins所在机子的公钥 more ~/.ssh/id_rsa.pub 的内容拷贝到gitlab项目上

##  Jenkins仪表盘简介

- 用户 --显示Jenkins里的用户

- 构建历史 --以时间轴的形式，显示项目的构建历史

- 系统管理 --跟Jenkins相关的配置都在里面

  3.1 系统设置 全局设置相关的都在里面(maven、邮件、ssh服务器等都在里面配置) 

  3.2 全局安全配置 用户权限、是否允许用户登录等配置

   3.3 configure credentials 配置证书相关的 

  3.4 全局工具配置 JDK Git Maven 等都在里面配置

   3.5 读取配置 放弃当前配置，而读取配置文件 

  3.6 管理插件 所有的插件都是在此处管理的，安装，升级

   3.7 系统信息 系统相关的信息 

  3.8 系统日志 系统日志，帮助定位问题

  3.9 负载统计

   3.10 Jenkins cli

   3.11 脚本命令行

   3.12 管理节点 

  3.13 关于Jenkins

   3.14 manage old data

   3.15 管理用户  Jenkins用户的管理

- 我的视图 --我们配置的要构建的项目

- Credentials --证书相关，授权相关



## Jenkins本地持续集成

所谓本地持续集成，就是我jenkins和要部署的jar包在同一台机器上。Jenkins构建好了之后，直接把jar包复制到某个目录下面，然后java -jar启动。

![image-20211130011508441](F:/documents/jenkins/asserts/image-20211130011508441.png)



- nohup 的用途就是让提交的命令忽略 hangup 信号，那什么叫做hangup信号？这里给出了答案

  0：标准输入 1：标准输出，2：标准错误

- --本地手动构建

  - 新建item时选择maven构建

  - 新建job并配置

    General --可不配 

    源码管理 --按项目所使用的源码管理选择，课程使用git 填写项目地址，Credentials选择配置好的认证 选择分支 可以是项目中的任意分支 

    构建触发器

    ​	 触发远程构建 (例如,使用脚本)

    ​	 其他工程构建后触发 -- 在Jenkins中其他项目构建之后，触发本项目构建，一般用于项目间有依赖关系，一方修改，另一方需实时感知

    ​	 定时构建 --定时进行构建，无论是否有变更 （类似cron表达式） 

    ​	GitHub hook trigger for GITScm polling --github的hook触发构建,一般不使用 

    ​	轮询 SCM --设置定时检查源码变更，有更新就构建（类似cron表达式）

    ```
        定时表达式含义
    ```

    ```
            * * * * * --五个字段
    ```

    ```
            分 时 天 月 周
    ```

    ```
    构建环境
    ```

    ```
        Delete workspace before build starts：在构建之前清空工作空间
    ```

    ```
        Abort the build if it's stuck：如果构建出现问题则终止构建
    ```

    ```
        Add timestamps to the Console Output：给控制台输出增加时间戳
    ```

    ```
        Use secret text(s) or file(s)：使用加密文件或者文本
    ```

    ```
    执行shell
    ```

    ```
    #!/bin/bash
    ```

    ```
    mv target/*.jar /root/demo/
    ```

    ```
    cd /root/demo
    ```

    ```
    BUILD_ID= 
    ```

    ```
    java -jar springboot-demo.jar >log 2>&1 &
    ```

 

- 本地gitlab触发构建

  - 先安装Jenkins的gitlab插件
  - 然后在构建触发器里配置触发方式

- 配置gitlab webhook

  系统管理员登陆 http://192.168.56.101:8888/admin/application_settings settings Outbound requests 勾选Allow requests to the local network from hooks and services

- sonarqube整合

  required metadata

  ```
      #projectKey项目的唯一标识，不能重复
  ```

  ```
      sonar.projectKey=xdclass
  ```

  ```
      sonar.projectName=xdclass
  ```

  ```
  
  ```

  ```
      sonar.projectVersion=1.0 
  ```

  ```
      sonar.sourceEncoding=UTF-8
  ```

  ```
      sonar.modules=java-module
  ```

  ```
  
  ```

  ```
      # Java module
  ```

  ```
      java-module.sonar.projectName=test
  ```

  ```
      java-module.sonar.language=java
  ```

  ```
      # .表示projectBaseDir指定的目录
  ```

  ```
      java-module.sonar.sources=src
  ```

  ```
      java-module.sonar.projectBaseDir=.
  ```

  ```
      java-module.sonar.java.binaries=target/
  ```

 

## 构建后发送到远程

在poststep里

![image-20211130011440890](F:/documents/jenkins/asserts/image-20211130011440890.png)

## 流水线



以工厂为例

**stage**

组装

**step**

组装里要有打螺丝等步骤

**node**

用于分布式构建

比如有master 、 agent



### **blue ocean**

Jenkins流水线的编辑器。

流水线可视化。

#### 安装

先安装blue ocean和blue ocean pipeline插件

安装后

![image-20211130012252228](F:/documents/jenkins/asserts/image-20211130012252228.png)

#### 建立流水线

![image-20211130012344888](F:/documents/jenkins/asserts/image-20211130012344888.png)

![image-20211130012355624](F:/documents/jenkins/asserts/image-20211130012355624.png)

![image-20211130012430457](F:/documents/jenkins/asserts/image-20211130012430457.png)

#### 配置流水线

![image-20211130012518069](F:/documents/jenkins/asserts/image-20211130012518069.png)



![image-20211130012547545](F:/documents/jenkins/asserts/image-20211130012547545.png)



![image-20211130012609713](F:/documents/jenkins/asserts/image-20211130012609713.png)

![image-20211130012627223](F:/documents/jenkins/asserts/image-20211130012627223.png)



弄好后，想办法回到编辑状态，继续添加步骤

![image-20211130012751441](F:/documents/jenkins/asserts/image-20211130012751441.png)



step1 复制jar包和部署脚本

step2 传输到远程服务器上，执行命令启动jar包。

当然这里是举个例子，也可以是step并行执行

![image-20211130013014270](F:/documents/jenkins/asserts/image-20211130013014270.png)

保存流水线

![image-20211130013139028](F:/documents/jenkins/asserts/image-20211130013139028.png)



## 分布式构建

比如我一台jenkins只能跑2个任务

![image-20211130013454623](F:/documents/jenkins/asserts/image-20211130013454623.png)

他们忙的时候就要等待。

可以在系统管理-》管理节点里面添加节点来帮助构建

![image-20211130013536264](F:/documents/jenkins/asserts/image-20211130013536264.png)

新建节点

![image-20211130013647481](F:/documents/jenkins/asserts/image-20211130013647481.png)



![image-20211130013726495](F:/documents/jenkins/asserts/image-20211130013726495.png)

添加成功后

![image-20211130013758605](F:/documents/jenkins/asserts/image-20211130013758605.png)

## 容器化



dockerfile可以放在Jenkins里面

![image-20211130015433041](F:/documents/jenkins/asserts/image-20211130015433041.png)