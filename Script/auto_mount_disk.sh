#!/bin/bash

function SCAN {
	echo -e "\033[44;37mScaning...\033[0m"
	sleep 1
	> /tmp/mount.log
	ALL_DISK=`fdisk -l 2>/dev/null| grep -Ev "mapper|root|swap|docker" |grep ^"Disk /"|cut -d ' ' -f2 |cut -d: -f1`
	for i in ${ALL_DISK}
	do
		df -Th | grep ${i} &> /dev/null
		if [ $? -eq 0 ];then
			echo -e "Found Disk: ${i}  - \033[31mUsed\033[0m" | tee -a /tmp/mount.log
		else
			echo -e "Found Disk: ${i}  - \033[32mUseless\033[0m" | tee -a /tmp/mount.log
		fi
	done
	Used_Disk=`cat /tmp/mount.log | grep Used | cut -d ' ' -f3`
	Useless_Disk=`cat /tmp/mount.log | grep Useless | cut -d ' ' -f3`
}
function PART {
	for dev in ${Useless_Disk}
	do
		echo -e "\033[36mFormating ${i}....\033]0m"
	sleep 1
	parted ${dev} mklabel gpt <<EOF
Yes
EOF
  parted ${dev} mkpart primary ext4 0 100% <<EOF
Ignore
EOF
	echo -e "\033[32mDone\033[0m"
	done
}
function MKFS {
	for i in ${Useless_Disk}
	do
		echo -e "\033[36mMkfs ${i}....\033]0m"
		mkfs.ext4 ${i}1 &> /dev/null
		echo -e "\033[32mDone\033[0m"
		sleep 1
	done
}
function MOUNT {
  i=1
	for dev in ${Useless_Disk}
	do
	    res=`du --max-depth=0 -h /data | awk '{print $1}'|sed 's/G//g'||echo 0`
		m_res=`lsblk |grep /data`
		if [ ! -d /data -o $res -lt 5 ] && [[ ! "${m_res}" ]];then
		    rm -rf /data && echo "删除data目录"||echo "没有data目录"
			mkdir /data
			UUID_NUM=`blkid | grep "${dev}1" | cut -d ' ' -f2`
			echo "${UUID_NUM} /data	ext4	defaults 0 0" >> /etc/fstab
			mount -a
			[ $? -eq 0 ] && echo "${dev} Mount Finished."
		else
			NEW_POINT="/data"${i}
			if [ -d ${NEW_POINT} ];then
			  let i=$i+1
			  NEW_POINT="/data"${i}
				mkdir ${NEW_POINT}
				UUID_NUM=`blkid | grep "${dev}1" | cut -d ' ' -f2`
				echo "${UUID_NUM} ${NEW_POINT}	ext4	defaults 0 0" >> /etc/fstab
				mount -a
				[ $? -eq 0 ] && echo "${dev} Mount Finished."
			else
				mkdir ${NEW_POINT}
				let i=$i+1
				UUID_NUM=`blkid | grep "${dev}1" | cut -d ' ' -f2`
				echo "${UUID_NUM} ${NEW_POINT}	ext4	defaults 0 0" >> /etc/fstab
				mount -a
				[ $? -eq 0 ] && echo "${dev} Mount Finished."
			fi
		fi
	done
}
function MAIN {
	SCAN
	if [ -z "${Useless_Disk}" ];then
		echo -e "\033[31mNot Fount Useless Disk.Exited...\033[0m" && exit 2
	fi
	PART
	MKFS
	MOUNT
	rm -fr /tmp/mount.log
}
MAIN