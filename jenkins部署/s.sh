#!/bin/bash
#jdk环境变量
export JAVA_HOME=/usr/local/java
export JAVA_BIN=$JAVA_HOME/bin
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH
date=`date +%Y%m%d%H%M%S`
APP_NAME=$1
echo "我擦"
#检查程序是否在运行
is_exist(){
pid=`ps -ef|grep $APP_NAME|grep -v grep|awk '{print $2}|sed -n 2' `
#如果不存在返回1,存在返回0
if [ -z "${pid}" ]; then
return 1
else
return 0
fi
}

is_exist
ps -ef | grep $APP_NAME
if [ $? -eq "0" ]; then
kill -9 $pid
else
echo "${APP_NAME} is not running"
fi
cd /lxm/wapps
mv ${APP_NAME} backup/${APP_NAME%%.*}${date}.jar
echo "备份成功"
cd /lxm/deploy
cp -r ${APP_NAME} /lxm/wapps
rm -rf ${APP_NAME}
cd /lxm/wapps
is_exist
if [ $? -eq "0" ]; then
echo "${APP_NAME} is already running. pid=${pid} ."
else
nohup java -jar /lxm/wapps/$APP_NAME  >/lxm/wapps/$APP_NAME.log 2>&1 &
echo "程序已启动..."
fi
is_exist
if [ $? -eq "0" ]; then
echo "${APP_NAME} is running. pid is ${pid} "
else
echo "${APP_NAME} is not running."
fi
exit