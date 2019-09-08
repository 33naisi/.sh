#!/bin/sh
# Testing script for install cacti 0.8.7i and spine 0.8.7i on Centos Linux Release 6.x
# Version : 1.0.4
# Make by Patrick.Ru @ China
# E-Mail : patrick.ru@hotmail.com
# Date : 28-Dec-2011


chkconfig iptables off
service iptables stop
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
/usr/sbin/setenforce 0

yum update -y
yum install -y wget
mkdir -p /usr/src/cacti
cd /usr/src/cacti
yum install -y httpd
chkconfig httpd on
service httpd start
yum install -y mysql-server
chkconfig mysqld on
service mysqld start
mysqladmin -u root password dbadmin
yum install -y php php-gd php-mysql php-cli php-ldap php-snmp php-mbstring php-mcrypt
service httpd restart
yum install -y rrdtool 
yum install -y net-snmp-utils 
yum install -y tftp-server
chkconfig xinetd on
service xinetd start
wget http://www.cacti.net/downloads/cacti-0.8.7i-PIA-3.1.tar.gz
tar zxvf cacti-0.8.7i-PIA-3.1.tar.gz
wget http://www.cacti.net/downloads/patches/0.8.7i/settings_checkbox.patch
cd cacti-0.8.7i-PIA-3.1
patch -p1 -N < ../settings_checkbox.patch
cd ..
mv -f cacti-0.8.7i-PIA-3.1/* /var/www/html/
rm -rf cacti-0.8.7i-PIA-3.1
chown -R apache:apache /var/www/html/
service httpd restart
mysql -u root -pdbadmin -e 'CREATE DATABASE `cacti` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;'
mysql -u root -pdbadmin -e "CREATE USER 'cactiuser'@'localhost' IDENTIFIED BY 'cactiuser';"
mysql -u root -pdbadmin -e 'GRANT ALL PRIVILEGES ON `cacti` . * TO 'cactiuser'@'localhost';'
mysql -u cactiuser -pcactiuser cacti < /var/www/html/cacti.sql
echo "*/5 * * * * apache /usr/bin/php /var/www/html/poller.php > /dev/null 2>&1" > /etc/cron.d/cacti
yum install -y gcc gcc-c++ make automake patch libtool net-snmp-devel openssl-devel mysql mysql-devel
wget http://www.cacti.net/downloads/spine/cacti-spine-0.8.7i.tar.gz
tar zxvf cacti-spine-0.8.7i.tar.gz
cd cacti-spine-0.8.7i
./configure 
make && make install
cp /usr/local/spine/etc/spine.conf.dist  /usr/local/spine/etc/spine.conf
cd /usr/src/cacti
wget http://docs.cacti.net/_media/plugin:settings-v0.71-1.tgz -O settings.tgz
tar zxvf settings*.tgz -C /var/www/html/plugins
chown -R apache:apache /var/www/html/plugins/settings
wget http://docs.cacti.net/_media/plugin:clog-v1.7-1.tgz -O clog.tgz 
tar zxvf clog*.tgz -C /var/www/html/plugins 
chown -R apache:apache /var/www/html/plugins/clog
wget http://docs.cacti.net/_media/plugin:thold-v0.4.9-3.tgz -O thold.tgz 
tar zxvf thold*.tgz -C /var/www/html/plugins 
chown -R apache:apache /var/www/html/plugins/thold
wget http://docs.cacti.net/_media/plugin:monitor-v1.3-1.tgz -O monitor.tgz
tar zxvf monitor*.tgz -C /var/www/html/plugins 
chown -R apache:apache /var/www/html/plugins/monitor
wget http://docs.cacti.net/_media/plugin:realtime-v0.5-1.tgz -O realtime.tgz
tar zxvf realtime*.tgz -C /var/www/html/plugins
mkdir -p /var/www/html/plugins/realtime/cache
chown -R apache:apache /var/www/html/plugins/realtime
