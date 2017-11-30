#!/bin/bash
#


rpm -ivh http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm

zabbix_agentd_install(){
zabbix_agentd --version &> /dev/null
[ $? -eq 0 ] && echo "zabbix_agentd已安装完毕" && return 0
yum install zabbix-agent -y


vi /etc/zabbix/zabbix_agentd.conf

Server=127.0.0.1   	  Server=172.18.53.159

ServerActive=127.0.0.1    #ServerActive=127.0.0.1

Hostname=Zabbix server    Hostname=zabbixserver


systemctl start zabbix-agent			
systemctl enable zabbix-agent
}

#安装zabbix客户端
zabbix_agentd_install
