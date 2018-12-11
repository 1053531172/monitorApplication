#! /bin/bash

# 发送邮箱
$from=$1
# 协议
$smtp=$2
# 发送用户，一般与发送邮箱一致
$user=$3
# 授权码（非邮箱密码）
$password=$4

# 安装sendmail
yum install -y sendmail
yum install -y sendmail-cf

# 安装salauthd
# 使用smtp认证，需要安装saslauthd
yum install -y saslauthd

# 启动saslauthd服务
service saslauthd start

# 设置saslauthd开机自动启动
chkconfig saslauthd on

# 安装perl，不然无法使用下面的命令查找文件内容并替换
yum install -y perl perl-devel

# 安装mailx
yum install -y mailx

# 配置sendmail
# 设置外网可访问
# 实际是将DAEMON_OPTIONS(`Port=smtp,Addr=127.0.0.1, Name=MTA')dnl 替换成 DAEMON_OPTIONS(`Port=smtp,Addr=0.0.0.0, Name=MTA')dnl
find /etc/mail -name 'sendmail.mc' | xargs perl -pi -e 's|Addr=127.0.0.1|Addr=0.0.0.0|g'

# 设置发送邮箱相关信息
echo "set ssl-verify=ignore">>/etc/mail.rc
echo "set nss-config-dir=/etc/pki/nssdb">>/etc/mail.rc
# 发送邮箱
echo "set from=$from">>/etc/mail.rc
# 协议
echo "set smtp=$smtp">>/etc/mail.rc
# 发送邮箱用户，一般与发送邮箱一致
echo "set smtp-auth-user=$user">>/etc/mail.rc
# 授权码（非邮箱密码）
echo "set smtp-auth-password=$password">>/etc/mail.rc
echo "set smtp-auth=login">>/etc/mail.rc

# sendmail开机启动
chkconfig sendmail on

# 启动sendmail
service sendmail start