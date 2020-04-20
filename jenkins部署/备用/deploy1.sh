#!/usr/bin/env bash
#编译+部署项目站点
 
#需要配置如下参数
# 项目路径, 在Execute Shell中配置项目路径, pwd 就可以获得该项目路径
 export PROJ_PATH=/usr/local/apps/jenkens/workspace/apay-service
 
# 输入你的环境上tomcat的全路径
 export TOMCAT_APP_PATH=/usr/local/tomcat8088/
 
### base 函数
killTomcat()
{
    pid=`ps -ef|grep tomcat9|grep java|awk '{print $2}'`
    echo "tomcat Id list :$pid"
    if [ "$pid" = "" ]
    then
      echo "no tomcat pid alive"
    else
      kill -9 $pid
    fi
    #上面注释的或者下面的
  #  cd $TOMCAT_APP_PATH/bin
#echo " 进入tomcat bin目录下"

 #   sh shutdown.sh
echo “关闭tomcat“
}
cd $PROJ_PATH
echo "进入项目目录"
pwd
echo "拉取git 最新代码"
git pull
echo " maven 打包开始"
mvn clean install
echo "maven 打包结束"
# 停tomcat
killTomcat
 
# 删除原有工程
#rm -rf $TOMCAT_APP_PATH/webapps/ROOT
#rm -f $TOMCAT_APP_PATH/webapps/ROOT.war
rm -f $TOMCAT_APP_PATH/webapps/apay-service.war
 
# 复制新的工程到tomcat上

cp $PROJ_PATH/target/apay-service.war $TOMCAT_APP_PATH/webapps/
 
cd $TOMCAT_APP_PATH/webapps/
#mv qpsmanage.war ROOT.war
 
# 启动Tomcat
cd $TOMCAT_APP_PATH/
sh bin/startup.sh
