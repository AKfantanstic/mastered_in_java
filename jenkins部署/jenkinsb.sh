#!/usr/bin/env bash

INPUT=$2
INPUT2=$3
INPUT3=$4
FILE_PATH=`readlink -f ${INPUT}`
SERVICE=${INPUT##*/}
SERVICE_NAME=${SERVICE%.*}
DEPLOY_DIR=`pwd`
JVM_OPTS="-server -Xms64m -Xmx128m"

if [[ "$1" = "" ]];
then
    echo -e "\033[0;31m 未输入操作名 \033[0m  \033[0;34m {start|stop|restart|status} \033[0m"
    exit 1
fi

if [[ "$SERVICE" = "" ]];
then
    echo -e "\033[0;31m 未输入应用名 \033[0m"
    exit 1
fi

LOGS_DIR="$DEPLOY_DIR/logs/$SERVICE_NAME"
echo "$LOGS_DIR"
if [[ ! -d "$LOGS_DIR" ]]; then
        mkdir -p ${LOGS_DIR}
fi

LOG_PATH="$LOGS_DIR/$(date +%Y-%m-%d)-stdout.out"
pid=0

start()
{
        checkPid
        if [[ ! -n "$pid" ]]; then
                if [[ "${INPUT3}" = "" ]]; then
        echo  "未指定环境配置 默认调用pom文件下默认环境"
        echo $3
        echo ${JVM_OPTS}
        echo "上面是jvm opts"
        echo ${FILE_PATH}
    BUILD_ID=dontKillMe  nohup java ${JVM_OPTS} '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${INPUT2}' -jar  ${FILE_PATH} >> ${LOG_PATH} 2>&1 &

                else

        echo  "指定启动环境配置 当前启动环境为：" $INPUT2
    BUILD_ID=dontKillMe  nohup java ${JVM_OPTS} "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${INPUT2}" -jar "-Dspring.profiles.active=${INPUT3}" ${FILE_PATH} >> ${LOG_PATH} 2>&1 &

                fi
    echo "$SERVICE_NAME is starting you can check the $LOG_PATH"
  else
      echo "$SERVICE_NAME is runing PID: $pid"
  fi
}

checkPid()
{
    pid=`ps -ef |grep ${FILE_PATH} |grep -v grep |awk '{print $2}'`
}

stop()
{
        checkPid
    if [[ ! -n "$pid" ]]; then
     echo "$SERVICE_NAME not runing"
    else
      echo "$SERVICE_NAME stop..."
      kill -9 ${pid}
    fi
}

restart()
{
        stop
        sleep 5
        start
}

status()
{
   checkPid
   if [[ ! -n "$pid" ]]; then
     echo "$SERVICE_NAME not runing"
   else
     echo "$SERVICE_NAME runing PID: $pid"
   fi
}

case $1 in
          start) start;;
          stop)  stop;;
          restart)  restart;;
          status)  status;;
              *)  echo "require start|stop|restart|status"  ;;
esac