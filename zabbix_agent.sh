#!/bin/bash
#


rpm -ivh http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm

zabbix_agentd_install(){
zabbix_agentd --version &> /dev/null
[ $? -eq 0 ] && echo "zabbix_agentd已安装完毕" && return 0
yum install zabbix-agent -y


mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.initbak
cat ./conf/zabbix_agentd.conf > /etc/zabbix/zabbix_agentd.conf

systemctl start zabbix-agent			
systemctl enable zabbix-agent
}

#安装zabbix客户端
zabbix_agentd_install
