#！/bin/bash

echo -e "机器初始化 基本信息检查 请注意核对信息 :\n"

# 安装检测所需工具
function install_check_pkg(){
    echo -e "配置yum源:"
    yum install -y epel-release 1>/dev/null 
    if [ $? -ne 0 ];then
        echo "修改epel.repo"
        sed -i 's/^#baseurl/baseurl/g;s/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/epel.repo
        yum clean all
        yum install -y epel-release >/dev/null && echo "yum epel succ" || echo "Error installed epel" 
    fi
    yum install -y epel-release 1>/dev/null
    if [ $? -ne 0 ];then
        echo "修改epel.repo"
        sed -i 's/^#baseurl/baseurl/g;s/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/epel.repo
        yum clean all
        yum install -y epel-release >/dev/null && echo "yum epel succ" || echo "Error installed epel" 
    fi

    echo -e "安装 bc、wget、fio"
    yum install -y bc > /dev/null  && echo "yum bc succ"  || echo "Error installed bc"
    yum install -y wget > /dev/null && echo "yum wget succ" || echo "Error installed wget"
    yum install -y fio > /dev/null && echo "yum fio succ" || echo "Error installed fio"
    yum install -y ethtool > /dev/null && echo "yum ethtool succ" || echo "Error installed ethtool"
    yum install -y dmidecode > /dev/null && echo "yum dmidecode succ" || echo "Error installed dmidecode"
}

# 检测系统信息
function check_system_info(){
    echo -e "system 信息如下:"
    sys_info=`uname -a || echo 'Error code 1-1'`
    sys_issue=`cat /etc/issue | grep -iE "(Linux|centos|aliy)" || echo 'Error code 1-2'`
    sys_version=`cat /etc/redhat-release || echo 'Error code 1-3'`
    echo -e "${sys_info}\n${sys_issue}\n${sys_version}\n\n"
}

# 检测CPU 信息
function check_cpu_info(){
    echo -e "cpu 信息如下:"    
    cpu_c=`cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l || echo 'Error code 2-1'`
    pcpu_c=`cat /proc/cpuinfo| grep "cpu cores"| uniq | tr -d ' ' | cut -d ':' -f2 || echo 'Error code 2-2'`
    lcpu_c=`cat /proc/cpuinfo| grep "processor"| wc -l || echo 'Error code 2-3'`
    cpu_info=`cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c | sed 's/^\s*//g' || echo 'Error code 2-4'`
    cpu_Hz=`lscpu |grep Hz`
    echo -e "个数: ${cpu_c}\n物理核数: ${pcpu_c}\n逻辑核数: ${lcpu_c}\n信息: ${cpu_info} \nCPU主频信息：\n${cpu_Hz}\nπ计算能力:"
    if [ ${lcpu_c} -ge 8 ];then
        echo "!!!!CPU逻辑核数达标"
    else
        echo "！！！！！！！注意CPU逻辑核数不达标"
    fi
    #cpu_m=`time echo "scale=5000;4*a(1)" | bc -l -q || echo 'Error code 2-5'`
    #cpu_m=`time echo "scale=5000;4*a(1)" | bc -l -q || echo 'Error code 2-5'`
    #echo -e "\n\n"
}

# 检测磁盘信息、测速
function check_disk_info(){
    echo -e "memory&swap 信息如下:"
    free_info=`free -h  || free -g || echo 'Error code 4-1'`
    echo -e "${free_info}\nSwap在后续脚本中会再进行检查并处理!\n\n"

    echo -e "disk 信息如下:"
    disk_info=`df -h || echo 'Error code 3-1'`
    echo -e "${disk_info}\n磁盘在后续脚本中会再进行检查并处理!\n\n"
    disk_size=`df | sed '1d' | tr "\t" ' ' | tr -s ' ' |cut -d ' ' -f2,6|sort -rn | head -1|awk '{print $1}'`
    echo -e "disk size:${disk_size}\n"
    lsblk_info=`lsblk`
    echo -e "lsbk_info:\n"$lsblk_info
    if [[ $1 = 'SL' ]];then
        echo "磁盘测速:"
        disk_rate=`fio -direct=1 -iodepth=1 -rw=randrw -ioengine=psync -bs=4k -size=10G -numjobs=30 -runtime=100 -group_reporting -filename=iotest -name=Rand_Write_Testing | grep -i 'iops'`
        echo $disk_rate
        rm -f /root/iotest && echo "清理iotest succ" || echo "Error  /root/iotest 文件不存在"
    fi
}

# 检测网络信息
function check_network_info(){
    echo -e "dns 信息如下:"
    dns_resolv=`cat /etc/resolv.conf || echo 'Error code 6-1'`
    dns_hosts=`cat /etc/hosts || echo 'Error code 6-2'`
    echo -e "dns服务器:\n${dns_resolv}\n本地dns解析:\n${dns_hosts}\n\n"
    cat /etc/resolv.conf | grep '8.8.8.8'
    if [ "$?" != "0" ];then
        echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
    fi

    echo -e "ip 信息如下:"
    ip_info=`ip a | grep inet | grep -v inet6 | sed 's/^\s*//g' || echo 'Error code 5-1'`
    wip=`curl -s myip.ipip.net || echo 'Error code 5-2'`
    echo -e "${ip_info}\n外网信息:\n${wip}\n\n"
    
    if [[ $1 = 'NSL' ]];then
        echo -e "netstat 网卡上下行带宽测试:"
        rm -f /tmp/speedtest.*
        wget https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py  -P /tmp/ --no-check-certificate
        python /tmp/speedtest.py |  grep -E 'Download|Upload'
        python /tmp/speedtest.py |  grep -E 'Download|Upload'
        python /tmp/speedtest.py |  grep -E 'Download|Upload'
        
        echo -e "检查机器手否支持多队列"
        wip=`curl -s myip.ipip.net | tr '：' ' ' |tr -s ' '|cut -d ' ' -f3 || echo 'Error wip'  2>/dev/null`
        net=`ifconfig|grep -B 1 ${wip} |grep -v inet |awk '{print $1}'`
        Combined_value=`ethtool -l ${net}|grep Combined|awk '{print $2}'|head -n 1`
        ethtool -l ${net}|grep Combined 
        if [ $? == 1 -o "$Combined_value" == "0" ];then
                ethtool -l ${net}|grep Combined|sed -n 1p 2>/dev/null
                echo "网卡不支持多队列"  2>/dev/null
        else
                ethtool -l ${net}|grep Combined|sed -n 1p 2>/dev/null
                ethtool -l ${net}|grep Combined|sed -n 2p 2>/dev/null
        fi
        echo -e `ethtool -l ${net}`
    fi

    if [[ $1 = 'SL' ]];then
        echo "bond检测"
        cat /proc/net/bonding/bond0 |grep 'Slave Interface:' -A 3|grep Status && ethtool bond0 |grep 'Speed:';cat /proc/net/bonding/bond1 |grep 'Slave Interface:' -A 3|grep Status && ethtool bond1 |grep 'Speed:'
    fi
}

function check_producr_info(){
    echo "机器厂商检测:"
    product_info=`dmidecode | grep "Product Name"|sed -e 's/^\s*//g'|sed -n '1P'`
    echo -e "${product_info}\n"
}

function check_agent_or_server(){
    #检测有无第三方agent或者其他服务
    check_res=`ps x|grep -Ei 'agent|server'|grep -v grep`
    if [[ -z $check_res ]];then
       echo "没有第三方agent or server"
    else
       echo -e "！！！！！请注意有第三方agent or server\n"${check_res}
    fi
}

machine=$1

main(){
    echo $machine
    install_check_pkg
    check_system_info
    check_cpu_info
    check_disk_info $machine
    check_network_info $machine
    check_producr_info
    check_agent_or_server
}

main
