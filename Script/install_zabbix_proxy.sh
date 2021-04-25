#!/bin/bash

Usage(){
    echo "$0 new_ip new_proxy_name"
	echo "请提前安装好mysql"
    echo "数据库引擎为innodb"
    exit 1
}

if [ $# -ne 2 ];then
    Usage
fi

# 1、安装依赖
# 2、导入mysql表结构
# 3、在目标启动zabbix_proxy
# 4、将迁移的zabbix agent 指向改到新proxy

new_ip=$1
new_proxy_host_name=$2

MYSQL="/usr/bin/mysql"

echo "zabbix_server 添加zabbix_proxy"
user='Admin'
passwd='zabbix'
url='https://company.com/api_jsonrpc.php'
data="{\"jsonrpc\": \"2.0\",\"method\": \"user.login\",\"params\": {\"user\":\"${user}\",\"password\":\"${passwd}\"},\"id\": 1,\"auth\": null}"
token=`curl -s -X POST -H 'Content-Type:application/json' -d "${data}" ${url}|jq .result|tr -d '"'`
echo "zabbix token:${token}"
create="{\"jsonrpc\": \"2.0\",\"method\": \"proxy.create\",\"params\": {\"host\":\"${new_proxy_host_name}\",\"status\":5,\"proxy_address\":\"${new_ip}\"},\"id\": 1,\"auth\":\"${token}\"}"
curl -s -X POST -H 'Content-Type:application/json' -d "${create}" ${url}|jq .

echo "安装依赖"
sudo su root -c "ssh -o StrictHostKeyChecking=no root@${new_ip} 'yum install -y unixODBC net-snmp-libs lm_sensors-libs libevent OpenIPMI-libs php-mysqli'"
sudo su root -c "ssh -o StrictHostKeyChecking=no root@${new_ip} 'rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/6/x86_64/zabbix-proxy-mysql-4.0.15-1.el6.x86_64.rpm'"

echo "导入数据库"
MYSQL="mysql -umoba -pmoba2016 -h${new_ip} -P3306"
ssh mulong@${new_ip} "${MYSQL} -e \"create database if Not exists zabbix_proxy character set utf8 collate utf8_bin;\""
sudo su root -c "ssh -o StrictHostKeyChecking=no root@${new_ip} \"zcat /usr/share/doc/zabbix-proxy-mysql-4.0.15/schema.sql.gz|sed 's/CHARSET=utf8/CHARSET=utf8 COLLATE=utf8_bin/'|${MYSQL} -Dzabbix_proxy\""

echo "添加 hosts文件"
sudo su root -c "ssh -o StrictHostKeyChecking=no root@${new_ip} 'cat << EOF >> /etc/hosts
10.117.16.251 zabbix.server.master
EOF'"

echo "同步zabbix proxy"
#修改zabbix_proxy 配置
scp /data/config_backup/tools/bk_package/install_zabbix_proxy/zabbix_proxy.tar.gz mulong@${new_ip}:/data/app/
ssh mulong@${new_ip} "tar xzf /data/app/zabbix_proxy.tar.gz -C /data/app/"

echo "修改zabbix proxy 配置"
ssh mulong@${new_ip} "sed -i -e 's/zabbix_proxy12/${new_proxy_host_name}/g;s/10.116.207.149/${new_ip}/' /data/app/zabbix_proxy/etc/zabbix_proxy.conf"
start_proxy="/data/app/zabbix_proxy/sbin/zabbix_proxy -c /data/app/zabbix_proxy/etc/zabbix_proxy.conf"
stop_proxy="killall -9 zabbix_proxy"
ssh mulong@${new_ip} "${start_proxy}"
if [ $? -eq 0 ];then
    echo "${new_proxy_name} 启动成功"
else
   echo "${new_proxy_name} 启动失败"
fi

echo "清理安装文件 zabbix_proxy.tar.gz"
ssh mulong@${new_ip} "rm -f /data/app/zabbix_proxy.tar.gz"

echo "${new_proxy_name} 部署完成"
