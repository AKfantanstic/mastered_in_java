#!/usr/bin/env bash
#编译+部署项目站点

#需要配置如下参数
# 项目路径, 在Execute Shell中配置项目路径, pwd 就可以获得该项目路径
 export PROJ_PATH=$1
echo "当前路径：$PROJ_PATH"
pwd
 ### base 函数
cd $PROJ_PATH
echo "进入项目目录"
pwd
echo "拉取git 最新代码"
git pull
echo " maven 打包开始"
mvn clean install
echo "maven 打包结束"