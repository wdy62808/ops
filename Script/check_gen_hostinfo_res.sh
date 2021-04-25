#！/bin/bash
if [ $# -ne 1 ];then
   echo "Usage $0 ip,password,isp,country,region,price,disk_type,bandwidth,cpu,mem,disk,system,type"
   exit 1
fi
date_info=`date '+%Y%m%d-%H%M%S'`
succ="/tmp/check/succ_${date_info}.log"
fail="/tmp/check/fail_${date_info}.log"
res="/tmp/check/res_${date_info}.log"
mkdir -p /tmp/check/
echo -e "机器初始化 基本信息检查 请注意核对信息 :" >> ${succ}
echo -e "检测项\t检测结果\t备注" >>$res

# 安装检测所需工具
function install_check_pkg(){
    echo -e "配置yum源:">>${succ}
    yum install -y epel-release 1>/dev/null 2>&1 
    if [ $? -ne 0 ];then
        echo "修改epel.repo">> ${succ}
        sed -i 's/^#baseurl/baseurl/g;s/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/epel.repo
        yum clean all
        yum install -y epel-release >/dev/null && echo "yum epel succ" >> ${succ} || echo "Error installed epel" >>${fail}
    fi
    yum install -y epel-release 1>/dev/null
    if [ $? -ne 0 ];then
        echo "修改epel.repo"
        sed -i 's/^#baseurl/baseurl/g;s/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/epel.repo
        yum clean all
        yum install -y epel-release >/dev/null && echo "yum epel succ" || echo "Error installed epel" 
    fi

    echo -e "安装 bc、wget、fio" >> ${succ}
    yum install -y bc > /dev/null  && echo "yum bc succ" |tee -a ${succ} || echo "Error installed bc" >>${fail}
    yum install -y wget > /dev/null && echo "yum wget succ"|tee -a ${succ} || echo "Error installed wget" >>${fail}
    yum install -y fio > /dev/null && echo "yum fio succ"|tee -a ${succ}|| echo "Error installed fio" >>${fail}
    yum install -y ethtool > /dev/null && echo "yum ethtool succ"|tee -a ${succ} || echo "Error installed ethtool" >>${fail}
    yum install -y dmidecode > /dev/null && echo "yum dmidecode succ"|tee -a ${succ}|| echo "Error installed dmidecode" >>${fail}
}

# 检测系统信息
function check_system_info(){
    # $1 6. 7.
    echo -e "system 信息如下:" >> ${succ}
    echo -e "内核版本\t达标\t"`uname -r`"\n" >>${res}
    system_version=`cat /etc/redhat-release || echo 'Error code 1-3'>>${fail}`
    if [[ "$system_version" =~ "$1" ]];then
        echo -e "系统版本\t达标\t`cat /etc/redhat-release`" >>$res
    else
        echo -e "系统版本\t不达标\t`cat /etc/redhat-release`" >>$res
    fi
}

# 检测CPU 信息
function check_cpu_info(){
    # $1 cpu核数
    echo -e "cpu 信息如下:" >> ${succ}   
    cpu_c=`cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l|| echo 'Error code 2-1' >>${fail}` 
    pcpu_c=`cat /proc/cpuinfo| grep "cpu cores"| uniq | tr -d ' ' | cut -d ':' -f2|| echo 'Error code 2-2' >>${fail}`
    lcpu_c=`cat /proc/cpuinfo| grep "processor"| wc -l|| echo 'Error code 2-3' >>${fail}`
    cpu_info=`cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c | sed 's/^\s*//g'|| echo 'Error code 2-4' >>${fail}`
    cpu_Hz=`lscpu |grep MHz`
    echo -e "个数: ${cpu_c}\n物理核数: ${pcpu_c}\n逻辑核数: ${lcpu_c}\n信息: ${cpu_info} \nCPU主频信息：\n${cpu_Hz}\nπ计算能力:" >> ${succ}
    if [ ${lcpu_c} -ge 8 ];then
        echo "!!!!CPU逻辑核数达标" >> ${succ}
    else
        echo "！！！！！！！注意CPU逻辑核数不达标" >>${fail}
    fi
    if [ ${lcpu_c} -ge $1 ];then
       echo -e "CPU核数\t达标\t${lcpu_c}">>$res
    else
       echo -e "CPU核数\t不达标\t${lcpu_c}" >>$res
    fi
    cpu_mhz=`lscpu |grep 'Model name'|tr -d ' '|cut -d '@' -f2|grep '^1'`
    #cpu 主频与2GHZ的认为不达标
    if [ $? -ne 0 ];then
       echo -e "CPU主频\t达标\t${cpu_Hz}" >>$res
    else
       echo -e "CPU主频\t不达标\t${cpu_Hz}" >>$res
    fi
    #cpu_m=`time echo "scale=5000;4*a(1)" | bc -l -q >>${succ}|| echo 'Error code 2-5'>>${fail}`
    #cpu_m=`time echo "scale=5000;4*a(1)" | bc -l -q >>${succ}|| echo 'Error code 2-5'>>${fail}`
}

# 检测磁盘信息、测速
function check_disk_info(){
    # $1 type $2 men $3 disk
    echo -e "memory&swap 信息如下:" >> ${succ}
    free_info=`free -h  2>/dev/null|| free -g 2>/dev/null || echo 'Error code 4-1'>>${fail}`
    echo -e "${free_info}\nSwap在后续脚本中会再进行检查并处理!" >>${succ}
    mem=`free -h  2>/dev/null|sed 1d|tr -s ' '|cut -d ' ' -f2|sed 's/G/ /g'|head -n 1|| free -g 2>/dev/null |sed 1d|tr -s ' '|cut -d ' ' -f2|sed 's/G/ /g'|head -n 1`    
    check_mem=$2
    abs_mem=`awk "BEGIN{ print int(${check_mem} - ${mem})}"`
    if [ $abs_mem -lt 5 -o ${mem} -ge ${check_mem} ];then
        echo -e "内存\t达标\t"$mem"G" >>$res
    else    
        echo -e "内存\t不达标\t"$mem"G" >>$res
    fi    

    echo -e "disk 信息如下:" >> ${succ}
    disk_info=`df -h || echo 'Error code 3-1' >>${fail}`
    echo -e "${disk_info}\n磁盘在后续脚本中会再进行检查并处理!" >> ${succ}
    disk_size=`fdisk -l|grep '^Disk /dev'|cut -d ' ' -f3|sort -rn|head -n 1`
    disk_ask=$3
    disk_abs=`awk 'BEGIN{print int('$disk_ask' - '$disk_size')}'`
    if [[ $disk_abs -lt 100 ]];then #允许磁盘波动范围在100内
        echo -e "磁盘大小\t达标\t"$disk_size"G" >>$res
    else    
        echo -e "磁盘大小\t不达标\t"$disk_size"G" >>$res
    fi
    lsblk_info=`lsblk` 
    echo -e "lsbk_info:\n$lsblk_info" >>$res
    if [[ $1 == 'SL' ]];then
        echo "磁盘测速:"
        disk_rate=`fio -direct=1 -iodepth=1 -rw=randrw -ioengine=psync -bs=4k -size=10G -numjobs=30 -runtime=100 -group_reporting -filename=iotest -name=Rand_Write_Testing | grep -i 'iops'`
        echo $disk_rate >>${succ}
        iops=`echo $disk_rate|grep -P "iops=(\d+)" -o|head -n 1|sed 's/iops=//g'`
        if [ `expr $iops \> 380` -eq 1 ];then
            echo -e "磁盘测速\t达标\t$disk_rate">>$res
        else
            echo -e "磁盘测速\t不达标\t$disk_rate">>$res
        fi
        rm -f /root/iotest && echo "清理iotest succ" >>${succ}|| echo "Error  /root/iotest 文件不存在" >>${fail}
    fi
}

# 检测网络信息
function check_network_info(){
    # $1 type $2带宽
    echo -e "dns 信息如下:">>${succ}
    dns_resolv=`cat /etc/resolv.conf || echo 'Error code 6-1'>>${fail}`
    dns_hosts=`cat /etc/hosts || echo 'Error code 6-2'>>${fail}`
    echo -e "dns服务器:\n${dns_resolv}\n本地dns解析:\n${dns_hosts}" >>${succ}
    if [[ -n "${dns_resolv}" && -n "${dns_hosts}" ]];then
        echo -e "dns服务器\t达标\t${dns_resolv}\n本地dns解析\t达标\t${dns_hosts}">>${res}
    else
       echo -e "dns服务器\t不达标\t${dns_resolv}\n本地dns解析\t不达标\t${dns_hosts}">>${res}
    fi
    cat /etc/resolv.conf | grep '8.8.8.8'>>${succ}
    if [ "$?" != "0" ];then
        echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
    fi

    echo -e "ip 信息如下:" >> ${succ}
    ip_info=`ip a | grep inet | grep -v inet6 | sed 's/^\s*//g' || echo 'Error code 5-1'`
    wip=`curl -s myip.ipip.net || echo 'Error code 5-2' 2>>/dev/null`
    if [ $? -ne 0 ];then
        echo -e "外网信息\t不达标\t${wip}" >>${res}
    else
       echo -e "外网信息\t达标\t${wip}" >>${res}
    fi
    echo -e "${ip_info}\n外网信息:\n${wip}" >>${succ}
    if [[ $1 == 'NSL' ]];then
        echo -e "网卡上下行带宽测试:">>${succ}
        rm -f /tmp/speedtest.*
        wget https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py  -P /tmp/ --no-check-certificate >>/dev/null 2>&1
        test1=`python /tmp/speedtest.py |grep -E 'Download|Upload'` 
        test2=`python /tmp/speedtest.py |grep -E 'Download|Upload'`
        test3=`python /tmp/speedtest.py |grep -E 'Download|Upload'`
        down1=`echo $test1|cut -d ' ' -f2`
        load1=`echo $test1|cut -d ' ' -f5`
        check_band=`echo $2|sed 's/Mbps//g'`
        res1=`awk 'BEGIN{ print int('$down1' - '$check_band')}'`
        res2=`awk 'BEGIN{ print int('$load1' - '$check_band')}'`
        if [ $res1 -gt 0 ] && [ $res2 -gt 0 ];then
            echo -e "带宽检测\t达标\n$test1">>${res}
        else
           echo -e "带宽检测\t不达标\n$test1\n$test2\n$test3\n">>${res}
        fi
        echo -e "检查机器手否支持多队列" >> ${succ}
        wip=`curl -s myip.ipip.net | tr '：' ' ' |tr -s ' '|cut -d ' ' -f3 || echo 'Error wip'  2>/dev/null`
        net=`ifconfig|grep -B 1 ${wip} |grep -v inet |awk '{print $1}'`
        queues=`ls /sys/class/net/${net}/queues/|wc -l||echo 0`
        proc=`cat /proc/interrupts |grep ${net}|wc -l||echo 0`
        Combined_value=`ethtool -l ${net}|grep Combined|awk '{print $2}'|head -n 1`
        eth_res=`ethtool -l ${net}|grep Combined||echo 1` 
        if [ "$eth_res" == "1" -o "$Combined_value" == "0" ] && [ "${queues}" == "0" -a "${proc}" == "0" ];then
                ethtool -l ${net}|grep Combined|sed -n 1p 2>/dev/null >>${succ}
                echo -e "多队列\t不达标\t`ethtool -l ${net}|grep Combined`\t`cat /proc/interrupts |grep ${net}`\t`ls /sys/class/net/${net}/queues/`" >>${res}
        else
                echo -e "多队列\t达标\n${eth_res}">>${res}
        fi
    fi

    if [[ $1 == 'SL' ]];then
        echo "bond检测">>${succ}
        status0=`cat /proc/net/bonding/bond0 |grep 'Slave Interface:' -A 3|grep Status`
        speed0=`ethtool bond0 |grep 'Speed:'`
        status1=`cat /proc/net/bonding/bond1 |grep 'Slave Interface:' -A 3|grep Status`
        speed1=`ethtool bond1 |grep 'Speed:'`
        if [[ "$status0" =~ "up" ]] && [[ "$status1" =~ "up" ]];then
            echo "bond0 staus\t达标\t${status0}" >>${res}
            echo "bond1 staus\t达标\t${status1}" >>${res}
        else
            echo "bond0 staus\t不达标\t${status0}" >>${res}
            echo "bond1 staus\t不达标\t${status1}" >>${res}
        fi
        if [[ "$speed0" =~ "2000Mb" ]] && [[ "$speed1" =~ "2000Mb" ]];then
            echo "bond0 speed\t达标\t${speed0}" >>${res}
            echo "bond1 speed\t达标\t${speed1}" >>${res}
        else
            echo "bond0 speed\t不达标\t${speed0}" >>${res}
            echo "bond1 speed\t不达标\t${speed1}" >>${res}
        fi
    fi
}

function check_producr_info(){
    echo "机器厂商检测:">>${succ}
    product_info=`dmidecode | grep "Product Name"|sed -e 's/^\s*//g'|sed -n '1P'`
    echo $product_info>>${succ}
    pro_res=`echo $product_info|grep -i 'LENOVO'||echo 2`
    if [ $pro_res -eq 2 ];then
       echo -e "厂商检测\t达标\t${product_info}">>${res}
    else
        echo -e "厂商检测\t不达标 联想机器\t${product_info}">>${res}
    fi
}

function check_agent_or_server(){
    #检测有无第三方agent或者其他服务
    check_res=`ps x|grep -Ei 'agent|server'|grep -v grep`
    if [ -z $check_res ];then
       echo -e "第三方服务检测\t达标\n" >>${res}
    else
       echo -e "第三方服务检测\t不达标\t${check_res}" >>${res}
    fi
}

function output(){
    echo "检测结果"
    cat ${res}
#    echo "执行过程的输出信息"
#    cat ${succ}
    if [ -e ${fail} ];then
        cat ${fail}
    else
        echo "检测过程没有出现执行错误"
    fi
}
args=$1
machine=`echo $args|cut -d ',' -f13`
bandwidth=`echo $args|cut -d ',' -f8`
cpus=`echo $args|cut -d ',' -f9`
mens=`echo $args|cut -d ',' -f10`
disk=`echo $args|cut -d ',' -f11`
sys=`echo $args|cut -d ',' -f12`
#ip,password,isp,country,region,price,disk_type,bandwidth,cpu,mem,disk,system,type
#193.118.56.138,jp102694.doo,Zenlayer,阿联酋,迪拜,329.0,HDD,280,24,32,500,CentOS 6,NSL
main(){
    echo $args
    install_check_pkg
    check_system_info $sys
    check_cpu_info $cpus
    check_disk_info $machine $mens $disk
    check_network_info $machine $bandwidth
    check_producr_info
    check_agent_or_server
    output
}
main
