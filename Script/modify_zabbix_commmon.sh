#!/bin/bash

Usage() {
    echo "Usage:"
    echo "$0 [-a zabbix_proxy_ip or zabbix_agent_ip] [ -s 指定zabbix_server_ip] [-n name1 -n name2] [-e \"key1=value1\"-e \"key2=value2\"] [-m modify/insert/delete] [-r start/stop/restart/list] [-h help]"
    echo "Description: 修改zabbix server or proxy 配置"
    echo "    -a zabbix_server_ip  or zabbix_proxy_ip 和 zabbix_agent_ip 需要单独修改时指定,-n 指定一个"
    echo "    -s zabbix server ip 默认:1.1.1.1"
    echo "    -n name,zabbix_proxy or server name. -n zabbix_agent 表示修改name1下面所有zabbix_agent配置,且是-n 的最后一个添加."
    echo "    -e key, 配置文件中的一条记录. 必须传入对应 -m 参数"
    echo "    -m 修改方式 modify/insert/delete."
    echo "    -r 启动方式 start/stop/restart/list. list打印下面zabbix_agent IP"
    echo "    -h 帮助."
    echo "    配置文件."
    echo "   zabbix_proxy 默认配置文件: /data/app/zabbix_proxy/etc/zabbix_proxy.conf"
    echo "   zabbix_server 默认配置文件: /data/app/zabbix_server/etc/zabbix_server.conf"
    echo "   zabbix_agent 默认配置文件: /data/app/zabbix_agent/etc/zabbix_agentd.conf 如需修改请修改脚本"
    exit 1
}

if [ $# -eq 0 ];then
   Usage
fi

function check_args(){
    case "$1" in
    "ip")
        echo "$2"|grep -E "^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})$" >/dev/null 2>&1
        if [ $? -ne 0 ];then
            echo "无效参数,请按照IP规则正确填写."
            exit 1
        fi
    ;;
   "method")
        echo "$2"|grep -E "^modify$|^insert$|^delete$" >/dev/null 2>&1
        if [ $? -ne 0 ];then
            echo "无效名称：请按照modify/insert/delete 填写"
            exit 1
        fi
   ;;
   "run")
        echo "$2"|grep -E "^start$|^stop$|^restart$|^list$" >/dev/null 2>&1
        if [ $? -ne 0 ];then
            echo "无效名称：请按照start/stop/restart 填写"
            exit 1
        fi
   
   ;;
   *)
       echo "无效参数"
       Usage
       exit 1
   ;;
   esac    
}

ADDR_FLAG=0
SERVER_ADDR=1.1.1.1
DIR_CONIFG=/data/app/zabbix_proxy/etc/zabbix_proxy.conf

# 获取脚本执行时的选项
while getopts a:n:e:m:r:s: option
do
   case "${option}"  in  
       a)
           ADDR=${OPTARG}
           ADDR_FLAG=1
           check_args 'ip' $SERVER_ADDR
       ;;
       s)
           SERVER_ADDR=${OPTARG}
           check_args 'ip' $SERVER_ADDR
       ;;
       n) 
           NAME=(${NAME[@]} ${OPTARG})
       ;;
       e) 
           SET_ENV=(${SET_ENV[@]} ${OPTARG})
       ;;
       m) 
           METHOD=${OPTARG}
           check_args 'method' $METHOD
       ;;
       r) 
           RUN=${OPTARG}
           check_args 'run' $RUN
       ;;
       h) 
           Usage
       ;;
       ?)
           Usage
       ;;
       *)
           Usage
       ;;
   esac
done

function get_env_config(){
    if [[ "$1" =~ "zabbix_proxy" ]];then
        DIR_CONIFG=/data/app/zabbix_proxy/etc/zabbix_proxy.conf
        START_CMD="/data/app/zabbix_proxy/sbin/zabbix_proxy -c /data/app/zabbix_proxy/etc/zabbix_proxy.conf"
        STOP_CMD="killall -9 zabbix_proxy"
    elif [[ "$1" =~ "zabbix_agent" ]];then
        DIR_CONIFG=/data/app/zabbix_agent/etc/zabbix_agentd.conf
        START_CMD="/data/app/zabbix_agent/bin/zabbix_agentd start"
        STOP_CMD="/data/app/zabbix_agent/bin/zabbix_agentd stop"
    elif [[ "$1" =~ "zabbix_server" ]];then
        DIR_CONIFG=/data/app/zabbix_server/etc/zabbix_server.conf
        START_CMD="/data/app/zabbix_server/sbin/zabbix_server -c /data/app/zabbix_server/etc/zabbix_server.conf"
        STOP_CMD="killall -9 zabbix_server"
    else
        echo "无效 name:$1"
        exit 1
    fi
    BACKEND="cp ${DIR_CONIFG} /tmp"
}

function method_env_config(){
   col="$1"
   if [[ "$col" =~ "UserParameter=" ]];then
       col_head=`echo "$1"|cut -d ',' -f1`
   else
	   col_head=`echo "$1"|cut -d '=' -f1`'='
   fi
   if [[ "$METHOD" == "modify" ]];then
       echo "sed -i \"s/^${col_head}.\+/${col}/g\" ${DIR_CONIFG}"
   elif [[ "$METHOD" == "insert" ]];then
       echo "echo \"${col}\" >> ${DIR_CONIFG}" 
   elif [[ "$METHOD" == "delete" ]];then
       echo "sed -i \"/^${col_head}/d\" ${DIR_CONIFG}"
   else
       echo "错误参数"
       exit 1
   fi

}

echo "SERVER_ADDR:$ADDR"
echo "NAME:${NAME[@]}"
echo "SET_ENV:${SET_ENV[@]}"
echo "METHOD:$METHOD"
echo "RUN:$RUN"
echo "DIR_CONIFG:$DIR_CONIFG"
sleep 3 

get_env_config 'zabbix_server'
MYSQL="/usr/bin/mysql"
dir_name="$(dirname $(readlink -f "$0"))"
scp mulong@${SERVER_ADDR}:${DIR_CONIFG} ${dir_name}
source ${dir_name}/zabbix_server.conf

if [ ${#NAME[@]} -gt 1 ];then
    last=$((${#NAME[@]}-1))
    if [[ "${NAME[$last]}" != "zabbix_agent" ]];then
        echo "请将 -n zabbix_agent 排在最后."
        Usage
    fi
    echo "开始修改 ${NAME[$i]} 所有zabbix_agent 配置"
    for i in `seq 0 $(($last -1))`
    do   
         get_env_config ${NAME[$last]} 
         if [[ "${NAME[$i]}" =~ "zabbix_server" ]];then
             sql="select host from hosts where proxy_hostid is NULL and host REGEXP '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$';"
         elif [[ "${NAME[$i]}" =~ "zabbix_proxy" ]];then
             sql="SELECT h2.host FROM hosts h1 LEFT JOIN hosts h2 ON h1.hostid = h2.proxy_hostid WHERE h1.status IN (5, 6) and h1.host='${NAME[$i]}';"
         else
             echo "请检查输入的名称是否正确"
             exit 1
         fi
         res=`${MYSQL} -h${DBHost} -u${DBUser} -p${DBPassword} -P${DBPort} -D${DBName} -e "${sql}" 2>/dev/null|grep -v 'host'`
         if [[ ! -n "$res" ]];then
             echo "${NAME[$last]} zabbix_agent节点为空,请注意。"
         fi
         for ip in ${res}
         do
                [ ${#SET_ENV[@]} -gt 0 ] && echo "修改 $ip zabbix_agent 配置"
                ssh mulong@${ip} "${BACKEND}"
                for key in ${SET_ENV[@]}
                do
                    CMD=`method_env_config "${key}"`
                    echo "cmd=$CMD"
                    ssh mulong@${ip} "${CMD}"
                done
                if [[ "$RUN" == "start" ]];then
                    echo $ip
                    ssh mulong@${ip} "$START_CMD"
                elif [[ "$RUN" == "stop" ]];then
                    echo $ip
                    ssh mulong@${ip} "$STOP_CMD"
                elif [[ "$RUN" == "restart" ]];then
                    echo $ip
                    ssh mulong@${ip} "$STOP_CMD"
                    ssh mulong@${ip} "$START_CMD"
                else
                     echo "$ip"
                fi 
         done
    done 
else
    if [ $ADDR_FLAG -ne 1 ];then
        echo "修改$NAME 单独配置 必须指定IP地址"
        exit 1
    fi
    get_env_config $NAME
    ssh mulong@${ADDR} "${BACKEND}"
    echo "修改 $ADDR $NAME 配置"
    for key in ${SET_ENV[@]}
    do
        CMD=`method_env_config "${key}"`
        echo "cmd=$CMD"
        ssh mulong@${ADDR} "${CMD}"
    done
    if [[ "$RUN" == "start" ]];then
        echo $ADDR
        ssh mulong@${ADDR} "$START_CMD"
    elif [[ "$RUN" == "stop" ]];then
        echo $ADDR
        ssh mulong@${ADDR} "$STOP_CMD"
    elif [[ "$RUN" == "restart" ]];then
        echo $ADDR
        ssh mulong@${ADDR} "$STOP_CMD"
        ssh mulong@${ADDR} "$START_CMD"
    else
        echo "只修改配置文件"
    fi
fi
