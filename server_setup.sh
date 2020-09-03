#!/bin/bash
# Author: Adam Sneed
# Date:  12 Aug 2020
# Purpose: Setup server for at home practice. meant to be used on centos
# Usage: ./server_setup.sh

if [ $UID != '0' ];then
    printf "$0 must be ran as root!\n"
    exit 1
fi

function restart_service {
    systemctl stop $1
    systemctl start $1
}

#VARS
account='student.lcl.adm'
share='/mnt/server-share'


# Update System
if ping -c 2 8.8.8.8;then
    yum update && yum upgrade -y
else
    echo "No network connection, can not update"
    exit 3
fi


# Setup student account
if ! grep $account /etc/passwd ;then
    useradd -G wheel -p '$6$eNzUajbJpHs5RNd0$7RcTgCAhOZNEaJn8YxGIW9fo02LJHzmtqW9HEgcUW.ZvApZQA/IGrUA6SeMtlw4ajKVnfXPDMepyS/Qm9NZg50' $account
    echo "Created the $account account and added to wheel group"
fi

# Setup NFS
yum install nfs-server nfs-utils
if [[ -f /etc/exports ]];then
    printf "Setting up NFS\n"
    if [[ ! -d $share ]];then
        mkdir -p $share
    fi
    if grep $share /etc/exports; then
        echo '/etc/exports already configured'
    else
        yum install nfs-server
        printf "$share *(rw,sync) #Server share\n" >> /etc/exports
        exportfs -ra
        sysemtctl disable --now firewalld
        iptables -I INPUT -p tcp -m multiport --dport 111,2049,20048 -m comment --comment "NFS/mountd Ports TCP" -j ACCEPT
        iptables -I INPUT -p udp -m multiport --dport 111,2049,20048 -m comment --comment 'NFS/mountd Ports UDP' -j ACCEPT
        systemctl enable --now nfs-server
        sysemtctl restart nfs-server
    if ping -c 2 8.8.8.8 ;then
        yum install wget -y 
        wget -O ${share}/linux-cheatsheet00.pdf http://images.linoxide.com/linux-cheat-sheet.pdf
        wget -O ${share}/linux-cheatsheet01.pdf https://www.loggly.com/wp-content/uploads/2015/05/Linux-Cheat-Sheet-Sponsored-By-Loggly.pdf
        wget -O ${share}/linux-cheatsheet02.pdf https://learncodethehardway.org/unix/bash_cheat_sheet.pdf
        wget -O ${share}/bash.md https://raw.githubusercontent.com/rstacruz/cheatsheets/master/bash.md
    fi
    fi
fi

# Change hostname
hostnamectl set-hostname 'srvr01'


