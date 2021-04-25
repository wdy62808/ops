#!/bin/bash

for i in `cat alllist`
do
    echo $i
    ssh $i "mysql -uroot --socket=/tmp/percona.3306.sock  -e 'show engines;' | grep -i ROCKSDB"
    ssh $i "mysql -uroot --socket=/tmp/percona.3307.sock -e 'show engines;' | grep -i ROCKSDB"
    ssh $i "mysql -u root --socket=/tmp/percona.3307.sock -e 'show slave status\G;'"
    ssh $i "cat /data/app/zabbix_agent/etc/zabbix_agentd.conf | grep 'mysql'"
    echo ""
done
