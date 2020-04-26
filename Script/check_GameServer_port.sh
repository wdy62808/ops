#!/bin/bash
set -u
if [ $# -ne 1 ];then
    echo "Usage:$0"[deploy_tag]
	exit -1
fi
deploy_tag=$1
deploy_args_dir=/data/optools/deploy/file/$deploy_tag/$deploy_tag".args"
echo -e "\033[31m Game部署端口监测 \n 配置文件目录：\033[0m"
echo $deploy_args_dir
ports=(1 2 3 4)
count=0
used=0
unused=0
if [ -e $deploy_args_dir ];then
    for i in `cat $deploy_args_dir|grep -E '^DeployList@'`;
    do
        out_ip=`echo $i | cut -d '@' -f4`
        inner_ip=`echo $i | cut -d '@' -f3`
        if [[ $inner_ip == "" ]] || [[ $out_ip == "" ]]; then
          echo "Error : $i"
          exit 1
        fi
        ports[0]=`echo $i | cut -d '@' -f5`
        ports[1]=`echo $i | cut -d '@' -f6`
        ports[2]=`echo $i | cut -d '@' -f7`
        ports[3]=`echo $i | cut -d '@' -f8`
        for port in ${ports[*]};
        do
            nc -z -w 10 $inner_ip $port >/dev/null 2>&1
            if [ $? -ne 0 ];then
                #echo "$inner_ip 的 $port 端口未占用"
                let unused++
            else
                echo -e "\033[31m !!! 请注意 $inner_ip 的 $port 端口被占用 \033[0m"
                let used++
            fi
            let count++
        done
    done
    echo -e "\033[31m 总共检测端口:$count 端口占用:$used 端口未占用:$unused \033[0m"
else
    echo -e "\033[31m 请注意目录不存在 \033[0m"
fi
