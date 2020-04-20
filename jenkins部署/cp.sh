#!/usr/bin/env bash
#编译+部署项目站点

#需要配置如下参数
# 项目路径, 在Execute Shell中配置项目路径, pwd 就可以获得该项目路径
 export JAR_PATH=$1
echo "当前路径：$PROJ_PATH"
pwd
cp -r $JAR_PATH  /lxm/deploy/
echo "复制完成"