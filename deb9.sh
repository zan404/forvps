#!/bin/bash

if [[ $USER != "root" ]]; then
	echo "Maaf, Anda harus menjalankan ini sebagai root"
	exit
fi

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
#MYIP=$(wget -qO- ipv4.icanhazip.com);

# get the VPS IP
#ip=`ifconfig venet0:0 | grep 'inet addr' | awk {'print $2'} | sed s/.*://`

#MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | head -n1`;
MYIP=$(ifconfig | grep 'inet addr:' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d: -f2 | awk '{ print $1}' | head -1)
if [ "$MYIP" = "" ]; then
	MYIP=$(wget -qO- ipv4.icanhazip.com)
fi
MYIP2="s/xxxxxxxxx/$MYIP/g";
ether=`ifconfig | cut -c 1-8 | sort | uniq -u | grep venet0 | grep -v venet0:`
if [[ $ether = "" ]]; then
        ether=eth0
fi

#vps="zvur";
vps="aneka";

#if [[ $vps = "zvur" ]]; then
	#source="http://"
#else
	source="https://raw.githubusercontent.com/tunnelproooo/mbkde/master"
#fi

# MULAI SETUP
myip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | head -n1`;
myint=`ifconfig | grep -B1 "inet addr:$myip" | head -n1 | awk '{print $1}'`;
if [ $USER != 'root' ]; then
echo "Sorry, for run the script please using root user"
exit 1
fi
if [[ "$EUID" -ne 0 ]]; then
echo "Sorry, you need to run this as root"
exit 2
fi
if [[ ! -e /dev/net/tun ]]; then
echo "TUN is not available"
exit 3
fi

# SET TIMEZONE JAKARTA GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime;

#detail perusahaan
country=ID
state=Java
locality=Blora
organization=tunnelssh.pro
organizationalunit=coowner
commonname=mfauzan
email=tunnelssh.pro@gmail.com

# ENABLE IPV4 AND IPV6
echo ipv4 >> /etc/modules
echo ipv6 >> /etc/modules
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
sysctl -p

# login setting
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells

# MEMBUANG SPAM PACKAGE
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove postfix*;
apt-get -y --purge remove bind*;
clear

sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -
apt-get update;
apt-get -y autoremove;
apt-get -y install wget curl;

# setting vnstat
vnstat -u -i $ether
service vnstat restart

# script
wget -O /etc/pam.d/common-password $source/common-password
chmod +x /etc/pam.d/common-password

# install webserver
apt-get -y install nginx

# fail2ban & exim & protection
apt-get -y install fail2ban sysv-rc-conf dnsutils dsniff zip unzip;
wget https://github.com/jgmdev/ddos-deflate/archive/master.zip;unzip master.zip;
cd ddos-deflate-master && ./install.sh
service exim4 stop;sysv-rc-conf exim4 off;

# setting vnstat
vnstat -u -i venet0
service vnstat restart

# install webmin
cd
wget "http://prdownloads.sourceforge.net/webadmin/webmin_1.890_all.deb"
dpkg --install webmin_1.890_all.deb;
apt-get -y -f install;
rm /root/webmin_1.890_all.deb
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart
service vnstat restart

# ssh
sed -i '$ i\Banner bannerssh' /etc/ssh/sshd_config
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

# dropbear
apt-get -y install dropbear
wget -O /etc/default/dropbear "$source/dropbear"
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells

# openvpn
apt-get -y install openvpn
cd /etc/openvpn/
wget -O openvpn.tar "$source/openvpn.tar"
tar xf openvpn.tar;rm openvpn.tar
wget -O /etc/rc.local "$source/rc.local"
chmod +x /etc/rc.local
# install webserver
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "$source/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Setup by M Fauzan Romandhoni | whtasapp : +62895703796928 | telegram :  UNKNOW | Pin BBM : UNKNOW</pre>" > /home/vps/public_html/index.html
wget -O /etc/nginx/conf.d/vps.conf "$source/vps.conf"
service nginx restart
# etc
wget -O /home/vps/public_html/client.ovpn "$source/client.ovpn"
wget -O /home/vps/public_html/client1.ovpn "$source/client1.ovpn"
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
sed -i "s/ipserver/$myip/g" /home/vps/public_html/client.ovpn
sed -i "s/ipserver/$myip/g" /home/vps/public_html/client1.ovpn
useradd -m -g users -s /bin/bash mfauzan
echo "mfauzan:121998" | chpasswd
rm *.sh;rm *.txt;rm *.tar;rm *.deb;rm *.asc;rm *.zip;rm ddos*;
clear

# install vnstat gui
cd /home/vps/public_html/
wget http://www.sqweek.com/sqweek/files/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
if [[ `ifconfig -a | grep "venet0"` ]]
then
cekvirt='OpenVZ'
elif [[ `ifconfig -a | grep "venet0:0"` ]]
then
cekvirt='OpenVZ'
elif [[ `ifconfig -a | grep "venet0:0-00"` ]]
then
cekvirt='OpenVZ'
elif [[ `ifconfig -a | grep "venet0-00"` ]]
then
cekvirt='OpenVZ'
elif [[ `ifconfig -a | grep "eth0"` ]]
then
cekvirt='KVM'
elif [[ `ifconfig -a | grep "eth0:0"` ]]
then
cekvirt='KVM'
elif [[ `ifconfig -a | grep "eth0:0-00"` ]]
then
cekvirt='KVM'
elif [[ `ifconfig -a | grep "eth0-00"` ]]
then
cekvirt='KVM'
fi
if [ $cekvirt = 'KVM' ]; then
	sed -i 's/eth0/eth0/g' config.php
	sed -i "s/\$iface_list = array('eth0', 'sixxs');/\$iface_list = array('eth0');/g" config.php
	sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
	sed -i 's/Internal/Internet/g' config.php
	sed -i '/SixXS IPv6/d' config.php
	cd
elif [ $cekvirt = 'OpenVZ' ]; then
	sed -i 's/eth0/venet0/g' config.php
	sed -i "s/\$iface_list = array('venet0', 'sixxs');/\$iface_list = array('venet0');/g" config.php
	sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
	sed -i 's/Internal/Internet/g' config.php
	sed -i '/SixXS IPv6/d' config.php
	cd
else
	cd
fi

# install stunnel
apt-get install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 443
connect = 127.0.0.1:442
connect = 127.0.0.1:80
connect = 127.0.0.1:777

[dropbear]
accept = 444
connect = 127.0.0.1:442
connect = 127.0.0.1:80
connect = 127.0.0.1:777

END

#membuat sertifikat
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

#konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart

# squid3
apt-get -y install squid3
wget -O /etc/squid/squid.conf "$source/squid.conf"
sed -i "s/ipserver/$myip/g" /etc/squid/squid.conf

# install badvpn
cd
wget -O /usr/bin/badvpn-udpgw "$source/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "$source/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# install mrtg
apt-get update;apt-get -y install snmpd;
wget -O /etc/snmp/snmpd.conf $source/snmpd.conf
wget -O /root/mrtg-mem.sh $source/mrtg-mem.sh
chmod +x /root/mrtg-mem.sh
cd /etc/snmp/
sed -i 's/TRAPDRUN=no/TRAPDRUN=yes/g' /etc/default/snmpd
service snmpd restart
snmpwalk -v 1 -c public localhost 1.3.6.1.4.1.2021.10.1.3.1
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg.cfg public@localhost
curl $source/mrtg.conf >> /etc/mrtg.cfg
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg.cfg
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
cd

# bannerssh
wget $source/bannerssh
mv ./bannerssh /bannerssh
chmod 0644 /bannerssh
service dropbear restart
service ssh restart

# text gambar
apt-get install boxes

# color text
cd
rm -rf /root/.bashrc
wget -O /root/.bashrc "$source/.bashrc"

# text pelangi
sudo apt-get install ruby -y
sudo gem install lolcat

#install PPTP
apt-get -y install pptpd
cat > /etc/ppp/pptpd-options <<END
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
nodefaultroute
lock
nobsdcomp
END

cat > /etc/pptpd.conf <<END
option /etc/ppp/pptpd-options
logwtmp
localip 10.1.0.1
remoteip 10.1.0.5-100
END

cat >> /etc/ppp/ip-up <<END
ifconfig ppp0 mtu 1400
END
mkdir /var/lib/premium-script
/etc/init.d/pptpd restart

# download script
cd
wget -O /usr/bin/benchmark $source/benchmark.sh
wget -O /usr/bin/speedtest $source/speedtest_cli.py
wget -O /usr/bin/ps-mem $source/ps_mem.py
wget -O /usr/bin/dropmon $source/dropmon.sh
wget -O /usr/bin/menu $source/menu.sh
wget -O /usr/bin/user-active-list $source/user-active-list.sh
wget -O /usr/bin/user-add $source/user-add.sh
wget -O /usr/bin/user-add-pptp $source/user-add-pptp.sh
wget -O /usr/bin/user-del $source/user-del.sh
wget -O /usr/bin/disable-user-expire $source/disable-user-expire.sh
wget -O /usr/bin/delete-user-expire $source/delete-user-expire.sh
wget -O /usr/bin/banned-user $source/banned-user.sh
wget -O /usr/bin/unbanned-user $source/unbanned-user.sh
wget -O /usr/bin/user-expire-list $source/user-expire-list.sh
wget -O /usr/bin/user-gen $source/user-gen.sh
wget -O /usr/bin/userlimit.sh $source/userlimit.sh
wget -O /usr/bin/userlimitssh.sh $source/userlimitssh.sh
wget -O /usr/bin/user-list $source/user-list.sh
wget -O /usr/bin/user-login $source/user-login.sh
wget -O /usr/bin/user-pass $source/user-pass.sh
wget -O /usr/bin/user-renew $source/user-renew.sh
wget -O /usr/bin/clearcache.sh $source/clearcache.sh
cd

#rm -rf /etc/cron.weekly/
#rm -rf /etc/cron.hourly/
#rm -rf /etc/cron.monthly/
rm -rf /etc/cron.daily/

echo "*/30 * * * * root service dropbear restart" > /etc/cron.d/dropbear
echo "00 23 * * * root /usr/bin/disable-user-expire" > /etc/cron.d/disable-user-expire
echo "00 23 * * * root /usr/bin/delete-user-expire" > /etc/cron.d/disable-user-expire
echo "0 */12 * * * root /sbin/reboot" > /etc/cron.d/rebootdelete
##echo "00 01 * * * root echo 3 > /proc/sys/vm/drop_caches && swapoff -a && swapon -a" > /etc/cron.d/clearcacheram3swap
echo "0 */1 * * * root /usr/bin/clearcache.sh" > /etc/cron.d/clearcache1

cd
chmod +x /usr/bin/benchmark
chmod +x /usr/bin/speedtest
chmod +x /usr/bin/ps-mem
#chmod +x /usr/bin/autokill
chmod +x /usr/bin/dropmon
chmod +x /usr/bin/menu
chmod +x /usr/bin/user-active-list
chmod +x /usr/bin/user-add
chmod +x /usr/bin/user-add-pptp
chmod +x /usr/bin/user-del
chmod +x /usr/bin/disable-user-expire
chmod +x /usr/bin/delete-user-expire
chmod +x /usr/bin/banned-user
chmod +x /usr/bin/unbanned-user
chmod +x /usr/bin/user-expire-list
chmod +x /usr/bin/user-gen
chmod +x /usr/bin/userlimit.sh
chmod +x /usr/bin/userlimitssh.sh
chmod +x /usr/bin/user-list
chmod +x /usr/bin/user-login
chmod +x /usr/bin/user-pass
chmod +x /usr/bin/user-renew
chmod +x /usr/bin/clearcache.sh
cd

# Finishing
wget -O /etc/vpnfix.sh $source/vpnfix.sh
chmod 777 /etc/vpnfix.sh
sed -i 's/exit 0//g' /etc/rc.local
echo "" >> /etc/rc.local
echo "bash /etc/vpnfix.sh" >> /etc/rc.local
echo "$ screen badvpn-udpgw --listen-addr 127.0.0.1:7300 > /dev/null &" >> /etc/rc.local
echo "nohup ./cron.sh &" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local

# restart service
service ssh restart
service openvpn restart
service dropbear restart
service nginx restart
service webmin restart
service squid restart
service fail2ban restart
service stunnel4 restart
clear

rm -rf ~/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

# history
clear
echo ""  | tee -a log-install.txt
echo "=============================================="  | tee -a log-install.txt | lolcat
echo "  Autoscript Created By M Fauzan Romandhoni "  | tee -a log-install.txt | lolcat
echo "----------------------------------------------"  | tee -a log-install.txt | lolcat
echo "Facebook    : https://www.facebook.com/cyb32.n0b"  | tee -a log-install.txt | lolcat
echo "Contact Me  : +62 8957-0379-6928"  | tee -a log-install.txt | lolcat
echo "----------------------------------------------"  | tee -a log-install.txt | lolcat
echo "Service     :" | tee -a log-install.txt | lolcat
echo "-------------" | tee -a log-install.txt | lolcat
echo "Nginx       : 81"  | tee -a log-install.txt | lolcat
echo "OpenVPN     : " | tee -a log-install.txt | lolcat
echo " • UDP      : http://$myip:81/client.ovpn"  | tee -a log-install.txt | lolcat
echo " • TCP      : http://$myip:81/client1.ovpn"  | tee -a log-install.txt | lolcat
echo "VNSTAT      : http://$myip:81/vnstat"  | tee -a log-install.txt | lolcat
echo "MRTG        : http://$myip:81/mrtg"  | tee -a log-install.txt | lolcat
echo "Webmin      : http://$myip:10000/" | tee -a log-install.txt | lolcat
echo "badvpn      : badvpn-udpgw port 7300" | tee -a log-install.txt | lolcat
echo "Squid3      : 8000, 8080, 3128"  | tee -a log-install.txt | lolcat
echo "OpenSSH     : 22"  | tee -a log-install.txt | lolcat
echo "Dropbear    : 80, 442, 777"  | tee -a log-install.txt | lolcat
echo "SSL/TLS     : 443"  | tee -a log-install.txt | lolcat
echo "PPTP VPN    : TCP 1723" | tee -a log-install.txt | lolcat
echo "Timezone    : Asia/Jakarta"  | tee -a log-install.txt | lolcat
echo "Fail2Ban    : [ON]"   | tee -a log-install.txt | lolcat | lolcat
echo "Anti [D]dos : [ON]"   | tee -a log-install.txt | lolcat
echo "IPv6        : [ON]" | tee -a log-install.txt | lolcat
echo "Tools       :" | tee -a log-install.txt | lolcat
echo "   axel, bmon, htop, iftop, mtr, rkhunter, nethogs: nethogs $ether" | tee -a log-install.txt | lolcat
echo "Auto Lock User Expire tiap jam 00:00" | tee -a log-install.txt | lolcat
echo "VPS Restart : 00.00/24.00 WIB"   | tee -a log-install.txt | lolcat
echo ""  | tee -a log-install.txt
echo "----------------------------------------------"  | tee -a log-install.txt | lolcat
echo "    -------THANK YOU FOR CHOIS US--------"  | tee -a log-install.txt | lolcat
echo "=============================================="  | tee -a log-install.txt | lolcat
echo "-   PLEASE REBOOT TAKE EFFECT TERIMA KASIH   -" | lolcat
echo "ALL MODD DEVELOPED SCRIPT BY FAUZAN ROMANDHONI" | lolcat
echo "==============================================" | lolcat
cat /dev/null > ~/.bash_history && history -c
rm -f /root/deb9.sh
rm -f deb9.sh
rm -f master.zip
rm -f mrtg-mem.sh
rm -f cert.pem
rm -f key.pem
rm -f cert.pem
rm -f log-install.txt
