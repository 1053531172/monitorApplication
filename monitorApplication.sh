#! /bin/bash

# tomcat启动脚本
startTomcat=$1

# 日志地址
tomcatMonitorLog=$2

# 邮件地址，多个逗号隔开
email_address=$3

# 请求接口
webUrl=$4

# 重试次数
retryCount=$5

# 最大重启次数
maxRestartCount=$6

# 计数器文件位置
restartCountTxt=$7

# tomcat停止脚本
stopTomcat=$8

# 判断容器是否存在的脚本
isExist=$9

# 用来计数重启tomcat的次数
restartCount=0

# 正确的请求返回值
statusCode=200

time=$(date "+%Y-%m-%d %H:%M:%S")
echo "=======================$time=======================">>$tomcatMonitorLog

# 日志输出
if [ -f $tomcatMonitorLog ]; then
	echo "日志文件已创建">>$tomcatMonitorLog
else 
	echo "日志文件未创建，马上创建">>$tomcatMonitorLog
	touch $tomcatMonitorLog
fi

# 初始化计数器
if [ -f $restartCountTxt ]; then 
	while read line
	do
		restartCount=$((line))
	done < $restartCountTxt
else
	touch $restartCountTxt
	echo "0" > $restartCountTxt
fi

# 判断是否已达到最大重启次数
if [[ "$restartCount" -eq "$maxRestartCount" ]]; then
	tomcatServiceCodeTry=$(curl -s -m 10 -o /dev/null --connect-timeout 10 $webUrl -w %{http_code})
	
	# 重置重启计数器（因手动重启应用而没有重置计数器）
	if [[ "$tomcatServiceCodeTry" -eq "$statusCode" ]]; then
		echo '【info】tomcat运行正常，访问系统接口正常，重置计数器'>>$tomcatMonitorLog
		true > $restartCountTxt
		echo "0" > $restartCountTxt
		exit 0
	else 
		echo "已超过最大重启次数，不再自动重启">>$tomcatMonitorLog
		echo '已超过最大重启次数，不再自动重启，请手动重启' | mail -v -s '系统告警' $email_address
		true > $restartCountTxt
		count=$[restartCount+1]
		echo $count > $restartCountTxt
		exit 0
	fi
fi
if [[ "$restartCount" -ge "$maxRestartCount" ]]; then
	tomcatServiceCodeTry=$(curl -s -m 10 -o /dev/null --connect-timeout 10 $webUrl -w %{http_code})
	# 重置重启计数器（因手动重启应用而没有重置机器）
	if [[ "$tomcatServiceCodeTry" -eq "$statusCode" ]]; then
		echo '【info】tomcat运行正常，访问系统接口正常，重置计数器'>>$tomcatMonitorLog
		true > $restartCountTxt
		echo "0" > $restartCountTxt
		exit 0
	else
		echo "已超过最大重启次数，不再自动重启">>$tomcatMonitorLog
		exit 0
	fi
fi

# 获取tomcat进程id
tomcatId=$($isExist)
# 重启
function restart() {
	if [ -n "$tomcatId" ]; then
		echo "tomcat开始关闭"
		$stopTomcat
	fi
	sleep 10
	# 循环100次，直到进程已经被关闭,否则认为关闭不成功，主动关闭进程
	for((i=1;i<100;i++));
	do
		tomcatId=$($isExist)
		if [ -n "$tomcatId" ]; then
			sleep 10
			echo "tomcat还没关闭，继续阻塞等待关闭完成"
		else 
			break
		fi
	done
	echo 'tomcat开始重启...'
	$startTomcat # 启动tomcat
}

# 监控服务是否正常
function monitor() {
	
	# 判断tomcat进程是否存在
	if [ -n "$tomcatId" ]; then
		tomcatServiceCodeTry=$(curl -s -m 10 -o /dev/null --connect-timeout 10 $webUrl -w %{http_code})
		if [[ "$tomcatServiceCodeTry" -eq "$statusCode" ]]; then
			echo '【info】tomcat运行正常,访问系统接口正常......'
			true > $restartCountTxt
			echo "0" > $restartCountTxt
			exit 0
		else 
			sleep 10
			for((i=0;i<$retryCount;i++))
			do
				tomcatServiceCodeTry=$(curl -s -m 10 -o /dev/null --connect-timeout 10 $webUrl -w %{http_code})
				if [[ "$tomcatServiceCodeTry" -eq "$statusCode" ]]; then
					echo '【info】tomcat运行正常,访问系统接口正常......'
					true > $restartCountTxt
					echo "0" > $restartCountTxt
					echo "执行完成"
					exit 0
				else
					echo '【error】重新访问系统接口失败'
					sleep 30
				fi
			done
			echo '【error】访问系统接口出错，请注意......开始重启tomcat'
			echo '【error】发送告警邮件'
			echo '【info】由于访问系统接口出错，tomcat开始自动重启'
			true > $restartCountTxt
			count=$[restartCount+1]
			echo $count > $restartCountTxt
			# 发送告警邮件
			echo "由于访问系统接口出错，tomcat开始自动重启，地址：$webUrl" | mail -v -s "系统告警" $email_address 
			restart # 重启
		fi
	else 
		echo '【error】tomcat进程不存在!tomcat开始自动重启...'
		echo '【error】$startTomcat,请稍候......'
		echo '【error】发送告警邮件'
		echo "由于tomcat没有启动，tomcat开始自动重启，地址：$webUrl" | mail -v -s "系统告警" $email_address 
		true > $restartCountTxt
		count=$[restartCount+1]
		echo $count > $restartCountTxt
		restart # 重启
	fi
}
monitor>>$tomcatMonitorLog