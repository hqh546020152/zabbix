#!/bin/bash
#

#数据库连接地址
#DBHost=10.40.2.212
#数据库密码
#DBPassword=rvSs6WZGGKyW8Ywz8d3v

#安装wget
wget --version &> /dev/null
[ $? -ne 0 ] && yum install -y wget && echo "wget已安装完毕"

#更换yum源
yum_check(){
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
	cd -
fi
}

#安装release
rpm -ivh http://www.rpmfind.net/linux/centos/7.4.1708/extras/x86_64/Packages/epel-release-7-9.noarch.rpm
#关闭firewalld
firewall-cmd --state |grep running &> /dev/null
[ $? -eq 0 ] && systemctl stop firewalld.service && systemctl disable firewalld.service
#关闭SELinux
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" '/etc/selinux/config' && setenforce 0


zabbix_mysql(){
	mysql --version &> /dev/null
	[ $? -eq 0 ] && echo "MySQL已安装完毕" && return 0
	wget http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
	rpm -ivh mysql-community-release-el7-5.noarch.rpm
	yum install mysql-community-server mysql -y
	[ $? -ne 0 ] && return 0
	systemctl start mysqld && systemctl enable mysqld && echo "请初始化MySQL，并创建zabbix数据库"
	netstat -lntp| grep 3306 | grep mysqld &> /dev/null
	[ $? -ne 0 ] && echo "MySQL启动失败,请检查日志"
}

zabbix_php(){
	php -v &> /dev/null
	[ $? -eq 0 ] && echo "php已安装完毕" && return 0
	yum install php php-mysql php-fpm -y
	[ $? -ne 0 ] && return 0
	#sed -i '38,57s/^/#/' /etc/nginx/nginx.conf     ##把38行到57的注释掉
	sed -i 's/^;date.timezone =/date.timezone = Asia\/Shanghai/' /etc/php.ini
	sed -i 's/^post_max_size =.*/post_max_size = 16M/' /etc/php.ini
	sed -i 's/^max_execution_time =.*/max_execution_time = 300/' /etc/php.ini
	sed -i 's/^max_input_time =.*/max_input_time = 300/' /etc/php.ini
	sed -i 's/^user = .*/user = nginx/' /etc/php-fpm.d/www.conf
	sed -i 's/^group = .*/group = nginx/' /etc/php-fpm.d/www.conf
	chown nginx: /var/log/php-fpm

	systemctl start php-fpm && systemctl enable php-fpm
	netstat -lntp| grep 9000 |grep php-fpm &> /dev/null
	[ $? -ne 0 ] && echo "PHP启动失败,请检查日志"
}

zabbix_nginx(){
	nginx -v &> /dev/null
	[ $? -eq 0 ] && echo "nginx已安装完毕" && return 0
	yum install -y nginx
	#如yum上没nginx包则继续安装包添加，并重新下载安装
	[ $? -ne 0 ] && rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm && yum install -y nginx
	
	nginx -v &> /dev/null
	[ $? -ne 0 ] && echo "nginx安装失败，请检查原因" && return 0
	systemctl start nginx
	systemctl enable nginx

	cat ./conf/zabbix.conf > /etc/nginx/conf.d/zabbix.conf
	mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
	cat ./conf/nginx.conf > /etc/nginx/nginx.conf  
	nginx -t &> /dev/null
	B=$?  
	[ $B -eq 0 ] && systemctl start nginx && systemctl enable nginx
	[ $B -ne 0 ] && echo "nginx配置有误，请检查后再启动"
}


zabbix_server_install(){

	zabbix_server --version &> /dev/null
	[ $? -eq 0 ] && echo "zabbix_server已安装完毕" && return 0

	rpm -ivh http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm
	rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
	yum install -y zabbix-server-mysql zabbix-web-mysql zabbix-get
	[ $? -ne 0 ] && return 0
	A=`ls /usr/share/doc/zabbix-server-mysql*/cre*`
	chown nginx:nginx -R /etc/zabbix/web/
	cp -r /usr/share/zabbix /var/www
	chown nginx:nginx -R /var/www/zabbix
	chown root:nginx /var/lib/php/session

	#DBName=zabbix
	#echo "ListenPort=10051" >> /etc/zabbix/zabbix_server.conf
	#echo "DBHost=$DBHost" >> /etc/zabbix/zabbix_server.conf
	#echo "DBPassword=$DBPassword" >> /etc/zabbix/zabbix_server.conf
	#echo "DBSocket=/tmp/mysql.sock" >> /etc/zabbix/zabbix_server.conf
	#echo "DBPort=3306" >> /etc/zabbix/zabbix_server.conf
	#echo "Timeout=30" >> /etc/zabbix/zabbix_server.conf

	mv /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.initbak
	cat ./conf/zabbix_server.conf > /etc/zabbix/zabbix_server.conf

	systemctl start zabbix-server && systemctl enable zabbix-server

	echo "请按以下命令执行，完成zabbix安装" > install.txt
	echo "mysql" >> install.txt
	echo "set password=password('$DBPassword');" >> install.txt
	echo "create database zabbix;" >> install.txt
	echo "grant all privileges on zabbix.* to 'zabbix'@'$DBHost' identified by '$DBPassword';" >> install.txt
	echo "grant all privileges on zabbix.* to 'zabbix'@'localhost' identified by '$DBPassword';" >> install.txt
	echo "flush privileges;" >> install.txt
	echo "\q" >> install.txt
	echo "zcat $A |mysql -uzabbix -p zabbix" >> install.txt
	echo "数据库密码：$DBPassword" >> install.txt
	echo "访问host" >> install.txt
	echo "初始账号密码：admin/zabbix" >> install.txt

	nginx -t &> /dev/null
	[ $? -eq 0 ] && nginx -s reload
	php-fpm -t &> /dev/null
	[ $? -eq 0 ] && systemctl restart php-fpm
}

zabbix_server_zhongwen(){

	file_data=`ls -l /usr/share/fonts/dejavu/DejaVuSans.ttf|awk '{print $5}'`
	[ $file_data -eq 11785184 ] && echo "已存在中文包" && return 0 
	#dirname=`pwd`
	mv /usr/share/fonts/dejavu/DejaVuSans.ttf /usr/share/fonts/dejavu/DejaVuSans.ttf.bak
	cp conf/simkai.ttf /usr/share/fonts/dejavu/DejaVuSans.ttf

}


#检测yum源
yum_check
#安装nginx
zabbix_nginx
#安装mysql
zabbix_mysql
#安装php
zabbix_php
#安装zabbix-server端
zabbix_server_install
#加载中文包
zabbix_server_zhongwen
