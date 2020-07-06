# jenkinsMultibranchPipeline
一、背景情况
整个项目组有32个java应用，10个javascript应用以及若干其他应用，并且还有增加的趋势；
3套测试环境，测试发布非常频繁，并且有同一个应用不同分支并行测试的情况；
版本管理器gitlab在公司内网局域网，测试环境在公网的青云主机上；
Java应用在测试环境，可能有单节点或多节点部署；
Java应用非常多，内存吃紧，需要合理部署应用在主机上，并且增加限制内存使用的启动参数；
Java应用有多种部署及启动方式，有tomcat部署的，有一个整的jar包方式部署的，有jar包与配置文件分离并且主要配置都在配置管理中心的部署方式；
代码管理分支策略方式为，从master分支切出功能开发分支，并且其他分支提交到master分支的变更及时合并到此开发分支用以消除代码冲突，此分支发布生产环境之后，合并到master分支；
配置文件繁多，不同的环境配置文件不同；

二、multibranch pipeline介绍及实现构想
1、简单介绍：
A、先介绍下什么是Jenkins 2.0，Jenkins 2.0的精髓是 Pipeline as Code，是帮助Jenkins实现CI到CD转变的重要角色。什么是Pipeline，简单来说，就是一套运行于Jenkins上的工作流框架，将原本独立运行于单个或者多个节点的任务连接起来，实现单个任务难以完成的复杂发布流程。Pipeline的实现方式是一套Groovy DSL，任何发布流程都可以表述为一段Groovy脚本，并且Jenkins支持从代码库直接读取脚本，从而实现了Pipeline as Code的理念。
B、multiBranch Pipeline的使用首先需要在每个分支代码的根目录下存放Jenkinsfile（Pipeline的定义文件），我们可以理解下maven的pom.xml文件，Jenkinsfile作为pipeline的管理文件也需要在源代码中进行直接的配置管理。这就要求devops工程师（QA、运维等）首先要有代码库的权限，或者至少赋能给dev工程师jenkinsfile的设计能力。
2、Groovy DSL定义了测试环境发布的所有步骤，包括：合并master分支，选择配置文件与替换，编译构建，上传构建后的应用包文件，部署应用；
3、上传包文件有唯一的shell脚本，不同测试环境的不同应用的包对应上传到包文件中转主机上不同的路径;
4、部署应用，都使用ansible的playbook剧本控制，java应用包括结束进程，替换应用包，重启应用。静态页面只需要替换。由于各个应用的部署方式差别较大，所有暂时每个应用都有单独ansible剧本，部署到不同环境参数有不同变量；
5、Groovy DSL流程固定，将其中变量作为参数列出来，再增加新的应用需要发布的时候，直接用模板，只需要修改变量参数即可使用；
6、Jenkinsfile保存在gitlab中项目代码的master分支根目录，不会丢失，不会被篡改，对Jenkins服务器依赖小不需要额外备份；
7、每个应用只需要配置一个Jenkins的项目即可部署到多个环境，其中实现选择功能，使用"Extended Choice Parameter"插件；
8、发布不同的分支直接选择即可；
9、每套环境有多台主机，ansible的剧本根据各个主机上是否有次应用的目录来确定是否将应用部署到主机上，不需要配置的时候指定主机；
10、使用cksum进行CRC校验；
11、打印出部署的java应用的进程ID。 

三、整体拓扑结构
![Alt text](https://github.com/aragron/jenkinsMultibranchPipeline/blob/master/pic/structure.png)

Jenkins、nexus和gitlab都在公司内网局域网，测试环境都是青云云主机；
测试环境由一台专门的中转主机（transfer station），打包之后的包文件先上传到这个中转主机上，然后再分发到对应的测试环境的主机；
测试环境的主机，启动java应用进程，结束java应用进程，删除旧的包，传输新的包，全部是Jenkins的主机通过ansible控制；
Multibranch pipeline方式，gitlab上项目的master分支，增加Jenkinsfile文件。
通过Jenkins的pipeline流水线作业，完成了从编译构建到部署的全部过程，即持续部署（continue deploy）。
为了简化过程，gitlab用户名密码保存在Jenkins主机的linux系统上，Jenkins主机ansible也是给测试环境主机分组并且用ssh密钥登录。
总结：Jenkinsfile文件放在gitlab项目master分支的根目录；Jenkins系统上配置multibranch pipeline项目；上传文件的shell脚本和部署应用的ansible playbook脚本都存放在Jenkins的主机上，Jenkinsfile中定义了调用这两个脚本。

四、发布过程涉及到的步骤
1、合并master分支代码；
2、替换不同环境的配置文件；
3、编译构建;
4、上传编译的包文件到linux主机；
5、结束应用的旧进程，替换包文件，重启应用。

五、Groovy DSL实现

1、Jenkins pipeline的代码实现，先将所有的变量都单独抽取出来，使用脚本编程方式。因为有合并master分支到测试分支的需要，所以得获取到Jenkins项目的环境变量：gitlab URL和分支名字；选择环境的变量使用"Extended Choice Parameter"插件；

 

2、合并master分支并且提交



3、替换配置文件，这里需要判断提供的路径指向的是目录还是文件



4、maven构建



5、上传构建完成后生产的包，调用shell脚本，其中包的相对路径、Jenkins的job名字和部署到的环境为三个参数变量



6、部署，需要三个参数，分布是Jenkins的job名字，部署到的环境，以及部署此java应用的ansible playbook剧本的绝对路径，因为剧本保存在Jenkins的主机上。



六、上传脚本


Shell脚本做了三件事：

根据Jenkinsfile调用脚本的时候给的包路径的参数，判断是否需要归档打包，如果需要打包则tar归档打包；
Cksum在Jenkins主机上进行CRC校验；
上传包到中转主机的指定的路径，此处用scp通过公网上传。


七、ansible部署剧本

1、判读是否存在此应用的路径，记录结果，忽略报错



2、kill此应用的进程，如果步骤1的判断结果result是succeeded的时候



3、删掉旧的包文件，由于此处部署测试环境，无需备份保留，可以直接删除，条件也是步骤1的判断结果result是succeeded



4、从包中转机器下载包文件，条件也是步骤1的判断结果result是succeeded



5、cksum进行CRC校验



6、重新启动应用，捕获报错信息



7、返回进程ID

 
注意：
上传包的shell脚本和部署应用的ansible剧本中，很多命名都是统一了方式。

八、Jenkins配置job

1、新建multibranch pipeline项目



2、配置gitlab地址



3、构建配置



4、配置完毕之后保存，然后扫描分支



5、扫描出来分支，点进去，构建，这里会显示所有的变量



6、在控制台的输出中，能看到CRC校验值以及进程ID


#/etc/ansible/hosts 
beta1-1 ansible_ssh_port=2203 ansible_ssh_user=apps host_key_checking=Flase ansible_ssh_host=12.x.x.x
