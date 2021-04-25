#!/bin/bash
# zabbix server 运行
ser_conf=/data/app/zabbix_server/etc/zabbix_server.conf
dir_ser=(/data/app/zabbix_server/share/zabbix/externalscripts/ /data/app/zabbix_server/share/zabbix/trapper/ /data/app/zabbix_server/share/zabbix/alertscripts/)
dir_ser_bak=(/data/app/zabbix_server/share/zabbix/externalscripts.tar.gz /data/app/zabbix_server/share/zabbix/trapper.tar.gz /data/app/zabbix_server/share/zabbix/alertscripts.tar.gz)
dir_proxy=(/data/app/zabbix_proxy/share/zabbix/externalscripts/ /data/app/zabbix_proxy/share/zabbix/trapper/ /data/app/zabbix_proxy/share/zabbix/alertscripts/)
DB_Host=`cat ${ser_conf}|grep -E '^DBHost'|cut -d '=' -f2`
DB_Name=`cat ${ser_conf}|grep -E '^DBName'|cut -d '=' -f2`
DB_User=`cat ${ser_conf}|grep -E '^DBUser'|cut -d '=' -f2`
DB_PWD=`cat ${ser_conf}|grep -E '^DBPassword'|cut -d '=' -f2`
DB_Port=`cat ${ser_conf}|grep -E '^DBPort'|cut -d '=' -f2`
MYSQL=/usr/bin/mysql
for((i=0;i<${#dir_ser[@]};i++))
do
    echo "sync ${dir_ser[i]}"
    [[  -f ${dir_ser_bak[i]} ]] && rm -f ${dir_ser_bak[i]}
    tar -czPf ${dir_ser_bak[i]} ${dir_ser[i]}
    proxy_list=`${MYSQL} -h${DB_Host} -u${DB_User} -p${DB_PWD} -P${DB_Port} -D${DB_Name} -N -e "select proxy_address from hosts where proxy_address<>'';" 2>/dev/null`
    for proxy in ${proxy_list}
    do
       echo ${proxy}
       sshpass -p mulong2016 rsync -avzu --delete --progress -e "ssh -o PubkeyAuthentication=yes -o stricthostkeychecking=no" ${dir_ser[i]} ${proxy}:${dir_proxy[i]}
       echo ""
    done
done
