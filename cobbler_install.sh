#安装cobbler脚本
#脚本基于centos7系统
1系统初始化
#关闭防火墙
systemctl disable firewalld.service
systemctl stop firewalld.service
#关闭selinux
setenforce 0
sed -i “s#SELINUX=enabled#SELINUX=disabled#g” /etc/selinux/config

#yum源安装
yum install epel-release
#安装cobbler所需要的软件
yum -y install cobbler cobbler-web dhcp tftp-server pykickstart httpd
#cobbler启动前先启动http和cobbler
#启动http 此处需要完善脚本去判断http服务是否启动,如果未启动，则退出脚本并提示（服务未启动请使用systemctl status httpd检查问题）。 （待续…）
systemctl start httpd.service

#cobbler启动会出一些问题 修改成自己想要的值（如果做更改只需要改一下ip地址）
sed -i ‘s/server: 127.0.0.1/server: 192.168.122.2/’ /etc/cobbler/settings
sed -i ‘s/next_server: 127.0.0.1/next_server: 192.168.122.2/’ /etc/cobbler/settings
sed -i ‘s/manage_dhcp: 0/manage_dhcp: 1/’ /etc/cobbler/settings
sed -i ‘s/pxe_just_once: 0/pxe_just_once: 1/’ /etc/cobbler/settings
#密码是“123456”
sed -ri “/default_password_crypted/s#(.: ).#\1"openssl passwd -1 -salt 'oldboy' '123456'”#" /etc/cobbler/settings
sed -i ‘s#yes#no#’ /etc/xinetd.d/tftp
#更改完成
#启动
systemctl start rsyncd
systemctl enable rsyncd
systemctl enable httpd
systemctl enable tftpd.socket
systemctl start tftpd.socket
systemctl restart cobblerd.service
##修改dhcp文件
sed -i.ori ‘s#192.168.1#192.168.122#g;22d;23d’ /etc/cobbler/dhcp.template
#然后做同步
cobbler sync
cobbler get-loaders

cp /etc/cobbler/settings{,.ori}
sed -i ‘s/server: 127.0.0.1/server: 192.168.122.2/’ /etc/cobbler/settings
sed -i ‘s/next_server: 127.0.0.1/next_server: 192.168.122.2/’ /etc/cobbler/settings
sed ‘s#yes#no#g’ /etc/xinetd.d/tftp -i
#替换的密码为使用了openssl加密的（123456）
openssl passwd -1 -salt ‘CLSN’ ‘123456’ >> password.txt
sed -i “101c default_password_crypted: $1$CLSN$LpJk4x1cplibx3q/O4O/K/” /etc/cobbler/settings
sed -i ‘s/manage_dhcp: 0/manage_dhcp: 1/’ /etc/cobbler/settings
sed -i.ori ‘s#192.168.1#192.168.122#g;22d;23d’ /etc/cobbler/dhcp.template
#重启服务并设置开机自启动
systemctl restart httpd.service
systemctl enable httpd.service
systemctl restart cobblerd.service
systemctl enable cobblerd.service
systemctl restart dhcpd.service
systemctl enable dhcpd.server
systemctl restart rsyncd.service
systemctl enable rsyncd.service
systemctl restart tftp.socket
systemctl enable tftp.socket
#访问https//192.169.122.2/cobbler_web 网站
#Cobbler 登录web界面提示报错“Internal Server Error”
#https://blog.51cto.com/12643266/2339793
#可能会遇到django的版本问题 可能需要用到vpn
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install Django==1.8.9
python -c “import django; print(django.get_version())”
systemctl restart httpd
#cobbler账号密码默认为cobbler

#centos 7 ks模板

#Cobbler for Kickstart Configurator for CentOS 7 by clsn
install
url --url=$tree
text
lang en_US.UTF-8
keyboard us
zerombr
bootloader --location=mbr --driveorder=sda --append=“crashkernel=auto rhgb quiet”
#Network information
$SNIPPET(‘network_config’)
#network --bootproto=dhcp --device=eth0 --onboot=yes --noipv6 --hostname=CentOS7
timezone --utc Asia/Shanghai
authconfig --enableshadow --passalgo=sha512
rootpw --iscrypted $default_password_crypted
clearpart --all --initlabel
part /boot --fstype xfs --size 1024
part swap --size 1024
part / --fstype xfs --size 1 --grow
firstboot --disable
selinux --disabled
firewall --disabled
logging --level=info
reboot

%pre
$SNIPPET(‘log_ks_pre’)
$SNIPPET(‘kickstart_start’)
$SNIPPET(‘pre_install_network_config’)

Enable installation monitoring
$SNIPPET(‘pre_anamon’)
%end

%packages
@^minimal
@compat-libraries
@core
@debugging
@development
bash-completion
chrony
dos2unix
kexec-tools
lrzsz
nmap
sysstat
telnet
tree
vim
wget
%end

%post
systemctl disable postfix.service
%end

#cnetos 6 ks 模板

Cobbler for Kickstart Configurator for CentOS 6 by clsn
install
url --url=$tree
text
lang en_US.UTF-8
keyboard us
zerombr
bootloader --location=mbr --driveorder=sda --append=“crashkernel=auto rhgb quiet”
$SNIPPET(‘network_config’)
timezone --utc Asia/Shanghai
authconfig --enableshadow --passalgo=sha512
rootpw --iscrypted $default_password_crypted
clearpart --all --initlabel
part /boot --fstype=ext4 --asprimary --size=200
part swap --size=1024
part / --fstype=ext4 --grow --asprimary --size=200
firstboot --disable
selinux --disabled
firewall --disabled
logging --level=info
reboot

%pre
$SNIPPET(‘log_ks_pre’)
$SNIPPET(‘kickstart_start’)
$SNIPPET(‘pre_install_network_config’)

Enable installation monitoring
$SNIPPET(‘pre_anamon’)
%end

%packages
@base
@compat-libraries
@debugging
@development
tree
nmap
sysstat
lrzsz
dos2unix
telnet
%end

%post --nochroot
$SNIPPET(‘log_ks_post_nochroot’)
%end

%post
$SNIPPET(‘log_ks_post’)

Start yum configuration
$yum_config_stanza

End yum configuration
$SNIPPET(‘post_install_kernel_options’)
$SNIPPET(‘post_install_network_config’)
$SNIPPET(‘func_register_if_enabled’)
$SNIPPET(‘download_config_files’)
$SNIPPET(‘koan_environment’)
$SNIPPET(‘redhat_register’)
$SNIPPET(‘cobbler_register’)

Enable post-install boot notification
$SNIPPET(‘post_anamon’)

Start final steps
$SNIPPET(‘kickstart_done’)

End final steps
%end
--------------------- 
作者：懒羊羊真懒 
来源：CSDN 
原文：https://blog.csdn.net/JAIWUI/article/details/95504507 
版权声明：本文为博主原创文章，转载请附上博文链接！
