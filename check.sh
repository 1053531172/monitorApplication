#! /bin/bash

# tomcat启动脚本
startTomcat=/usr/local/apache-tomcat-7.0.92/bin/startup.sh

# 日志地址
tomcatMonitorLog=/usr/local/monitorApplication.log

# 邮件地址，多个逗号隔开
email_address=a664760042@163.com

# 请求接口
webUrl=http://localhost:8080/

# 重试次数，每次间隔30秒
retryCount=5

# 最大重启次数
maxRestartCount=3

# 计数器文件位置
restartCountTxt=/usr/local/restartCountTxt.txt

# tomcat停止脚本
stopTomcat=/usr/local/kill.sh

# 判断容器是否存在的脚本
isExist=/usr/local/isExistTomcat.sh

# 执行监控脚本
monitorApplicationProcessId=$(ps -ef |grep monitorApplication |grep -w /usr/local |grep -v 'grep'|awk '{print $2}')
if [[ $monitorApplicationProcessId ]]; then
	time=$(date "+%Y-%m-%d %H:%M:%S")
	echo "=======================$time=======================">>$tomcatMonitorLog
	echo "monitorApplication.sh脚本正在试行，此次定时任务不执行该脚本，直接退出，等待下一次定时任务">>$tomcatMonitorLog
	exit 0
else
	sh /usr/local/monitorApplication.sh $startTomcat $tomcatMonitorLog $email_address $webUrl $retryCount $maxRestartCount $restartCountTxt "$stopTomcat" "$isExist"
fi