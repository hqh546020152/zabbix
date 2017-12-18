#!/bin/bash
#

#1、完成微信企业号的注册获取AgentId、Secret、CorpID和用户账号等信息
#2、配置Zabbix

#查看zabbix-web界面上获取脚本的路径
grep alertscripts /etc/zabbix/zabbix_server.conf
#lertScriptsPath=/usr/lib/zabbix/alertscripts

cd /usr/lib/zabbix/alertscripts
#下载脚本
wget http://download.zhsir.org/Zabbix/weixin_linux_amd64
mv weixin_linux_amd64 wechat
chmod   755 wechat
chown  zabbix:zabbix wechat

#脚本测试
#./wechat --corpid=wwcxxxxxxxxxxxxxxxx  --corpsecret=Q-HMnIo9HKX8kZwbT4m1SUcS-kmYhmiuRgr4DCLreQA   --msg="您好,告警测试" --user=CongYuHong  --agentid=1000002
#提示：
#--corpid= 我们企业里面的id
#--corpsecret= 这里就是我们Secret里面的id
#-msg= 内容
#-user=我们邀请用户的账号


#web界面配置
#1、添加“报警某介类型”
#	名称		wechat
#	类型		脚本
#	脚本名称	wechat	
#	脚本参数	--corpid=XXXXXXXXXXXXX
#			--corpsecret=XXXXXXXXXXXXXXXXXXXXXXXXXX
#			--agentid=1000002
#			--user={ALERT.SENDTO}
#			--msg={ALERT.MESSAGE}
#2、添加报警“用户”
#	用户
#		别名		wechat
#		用户名第一部分	wechat
#		姓氏		wechat
#		群组		Zabiix Admin
#		
#	报警某介
#		类型		wechat
#		收件人		XXX（微信企业号中对应用户账号）
#3、配置-新增“动作”
#	动作
#		名称		wechat
#		条件		A	维护状态 非在 维护
#				B	触发器示警度 <= 一般严重
#	操作
#		程序收件	120
#		默认收件人	{TRIGGER.SEVERITY}:{HOSTNAME1}:{TRIGGER.NAME}
#		默认信息	Warning
#				Host:{HOSTNAME1}
#				IP:{HOST.IP}
#				Time:{EVENT.DATE} {EVENT.TIME}
#				Level:{TRIGGER.SEVERITY}
#				Message: {TRIGGER.NAME}
#				Project:{TRIGGER.KEY1}
#				Details:{ITEM.NAME}:{ITEM.VALUE}
#				Status:{TRIGGER.STATUS}:{ITEM.VALUE1}
#				Event_ID:{EVENT.ID}
#		操作
#			操作类型	发送信息
#			发送到用户	wechat
#			仅送到		wechat
#			默认信息	√
#	恢复操作
#		默认收件人      {TRIGGER.SEVERITY}:{HOSTNAME1}:{TRIGGER.NAME}
#                默认信息	Restore
#                                Host:{HOSTNAME1}
#                                Time:{EVENT.DATE} {EVENT.TIME}
#                                Level:{TRIGGER.SEVERITY}
#                                Message: {TRIGGER.NAME}
#                                Project:{TRIGGER.KEY1}
#                                Status:{TRIGGER.STATUS}:{ITEM.VALUE1}
#		操作
#                        操作类型        发送信息
#                        发送到用户      wechat
#                        仅送到          wechat
#                        默认信息 

#验证
#用监控集群中的某台机器的Zabbix停止
