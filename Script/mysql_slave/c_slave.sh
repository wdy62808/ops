#!/bin/bash

cp /data/tools/script/agent_slave.sh ./
for i in `cat list`
do
    echo "############################################ $i"
    mip=`echo "$i" | cut -d '@' -f1`
    sip=`echo "$i" | cut -d '@' -f2`
    echo "make $sip master to $mip"
    scp ./agent_slave.sh $sip:~/
    ssh $sip "test -d /usr/local/mysql || ln -sv /usr/local/percona /usr/local/mysql"
    ssh $sip "sh ~/agent_slave.sh $mip"
    if [ "$?" == "0" ];then
        echo "succ"
    else
        echo "fail"
    fi
    
    mip=`echo "$i" | cut -d '@' -f2`
    sip=`echo "$i" | cut -d '@' -f1`
    echo "make $sip master to $mip"
    scp ./agent_slave.sh $sip:~/
    ssh $sip "test -d /usr/local/mysql || ln -sv /usr/local/percona /usr/local/mysql"
    ssh $sip "sh ~/agent_slave.sh $mip"
    if [ "$?" == "0" ];then
        echo "succ"
    else
        echo "fail"
    fi
    echo ""
    echo ""
done
