#!/bin/bash

for sip in `cat alllist`
do
    echo $sip
    ssh $sip "rm -f /data/app/zabbix_agent/etc/zabbix_agentd.confr"
    ssh $sip "sed -i -r '/^#+UserParameter=mysql/s/^#+//g' /data/app/zabbix_agent/etc/zabbix_agentd.conf"
    ssh $sip "/data/app/zabbix_agent/bin/zabbix_agentd restart"
    ssh $sip "sleep 5; if [[ `netstat -ntlp |grep 10050|wc -l` -eq 1 ]];then echo 'zabbix_agentd重启成功';else echo 'zabbix_agentd重启失败';fi"
    echo ""
done
