#!/bin/bash

if [ $# -lt 1 ]; then
        echo "Usage $0 master_host"
        exit -1
fi

master_host=$1

mysqldump -umoba -pmoba2016 -h$master_host --single-transaction -q --all-databases > slave.sql
echo "stop slave; reset slave; reset master; source slave.sql; change master to master_host='$master_host', master_user='replicate', master_password='moba2016';start slave;" | mysql -uroot --socket=/tmp/percona.3307.sock
rm -f slave.sql
mysql -u root -S /tmp/percona.3307.sock -e "show slave status\G;"