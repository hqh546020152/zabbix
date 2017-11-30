#!/bin/bash
#

postconf -d| grep mail_version &> /dev/null
[ $? -eq 0 ] && echo "Emailx已安装完毕" && return 0
yum install -y postfix
inet_interfaces = localhost  	inet_interfaces = all
systemctl start postfix
systemctl enable postfix



mailx -V &> /dev/null
[ $? -eq 0 ] && echo "邮件服务已安装" && return 0
yum install -y mailx


