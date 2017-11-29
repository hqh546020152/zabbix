#!/bin/bash
#


wget --version &> /dev/null
[ $? -eq 0 ] && echo "wget已安装完毕" && return 0
yum install -y wget

if [ -d /etc/yum.repos.d/backup ];then
	echo "aliyun"	
else
	cd /etc/yum.repos.d/
	mkdir backup
	mv *.repo ./backup
	wget -O ./CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
	yum clean all
  	yum makecache
  	yum -y update
fi

rpm -ivh http://www.rpmfind.net/linux/centos/7.4.1708/extras/x86_64/Packages/epel-release-7-9.noarch.rpm




