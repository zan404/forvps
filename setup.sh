#!/bin/bash

#Requirement
if [ ! -e /usr/bin/curl ]; then
    apt-get -y update --fix-missing
	apt-get -y install curl git nano ufw stunnel4
fi

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(curl -4 icanhazip.com)
if [ $MYIP = "" ]; then
   MYIP=`ifconfig | grep 'inet addr:' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d: -f2 | awk '{ print $1}' | head -1`;
fi
MYIP2="s/xxxxxxxxx/$MYIP/g";

# go to root
cd

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

#Add DNS Server ipv4
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
sed -i '$ i\echo "nameserver 8.8.8.8" > /etc/resolv.conf' /etc/rc.local
sed -i '$ i\echo "nameserver 8.8.4.4" >> /etc/resolv.conf' /etc/rc.local

# install wget and curl
apt-get update;apt-get -y install wget curl;

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# remove unused
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;
apt-get -y purge sendmail*
apt-get -y remove sendmail*

# update
apt-get update

# install essential package
apt-get -y install bmon iftop htop nmap axel nano traceroute sysv-rc-conf dnsutils bc nethogs openvpn less screen psmisc apt-file whois ptunnel ngrep mtr git unzip unrar rsyslog debsums rkhunter
apt-get -y install build-essential

# update apt-file
apt-file update

# install screenfetch
cd
wget -O /usr/bin/screenfetch "https://github.com/malikshi/elora/raw/master/screenfetch"
chmod +x /usr/bin/screenfetch
echo "clear" >> .profile
echo "screenfetch" >> .profile

# set ipv4 forward
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
sed -i 's|net.ipv4.ip_forward=0|net.ipv4.ip_forward=1|' /etc/sysctl.conf

#tcpfastopen
echo "3" > /proc/sys/net/ipv4/tcp_fastopen
echo "net.ipv4.tcp_fastopen=3" > /etc/sysctl.d/30-tcp_fastopen.conf
echo '* soft nofile 51200' >> /etc/security/limits.conf
echo '* hard nofile 51200' >> /etc/security/limits.conf
wget -O /etc/sysctl.d/local.conf "https://github.com/malikshi/elora/raw/master/local.conf"
wget -O /etc/issue.net "https://github.com/malikshi/elora/raw/master/issue.net"
ulimit -n 51200
sysctl --system
sysctl -p /etc/sysctl.d/local.conf

#swap ram
echo 'vm.swappiness= 40' >>/etc/sysctl.conf
echo 'vm.vfs_cache_pressure = 50' >>/etc/sysctl.conf
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >>/etc/fstab
sudo sysctl vm.swappiness=40
sudo sysctl vm.vfs_cache_pressure=50
sudo swapon -s
clear

# install badvpn
cd
#wget -O /usr/bin/badvpn-udpgw "https://github.com/malikshi/elora/raw/master/badvpn-udpgw"
#if [ "$OS" == "x86_64" ]; then
#  wget -O /usr/bin/badvpn-udpgw "https://github.com/malikshi/elora/raw/master/badvpn-udpgw64"
#fi
#sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
#chmod +x /usr/bin/badvpn-udpgw
#screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300
apt-get -y install cmake make gcc libc6-dev
wget https://github.com/ambrop72/badvpn/archive/1.999.130.tar.gz
tar xf 1.999.130.tar.gz
mkdir badvpn-build
cd badvpn-build
cmake ~/badvpn-1.999.130 -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 -DBUILD_TUN2SOCKS=1
make install
sed -i '$ i\/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local


#install ssh
cd
echo 'MaxAuthTries 2' >>/etc/ssh/sshd_config
echo 'Banner /etc/issue.net' >>/etc/ssh/sshd_config

# install dropbear
cd
apt-get -y install dropbear
wget -O /etc/default/dropbear "https://github.com/malikshi/elora/raw/master/dropbear"
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
sed -i 's/obscure/minlen=5/g' /etc/pam.d/common-password
service ssh restart
service dropbear restart

#Upgrade to Dropbear 2017
cd
apt-get install zlib1g-dev
wget https://matt.ucc.asn.au/dropbear/dropbear-2018.76.tar.bz2
bzip2 -cd dropbear-2018.76.tar.bz2 | tar xvf -
cd dropbear-2018.76
./configure
make && make install
mv /usr/sbin/dropbear /usr/sbin/dropbear.old
ln /usr/local/sbin/dropbear /usr/sbin/dropbear
cd && rm -rf dropbear-2018.76 && rm -rf dropbear-2018.76.tar.bz2
service dropbear restart

#install stunnel4
cd
apt-get -y install stunnel4
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
wget -O /etc/stunnel/stunnel.conf "https://github.com/malikshi/elora/raw/master/stunnel.conf"
sed -i $MYIP2 /etc/stunnel/stunnel.conf

#setting cert
country=ID
state=JAWABARAT
locality=Bussiness
organization=IPTUNNELS
organizationalunit=ISPSSH
commonname=server
email=support@iptunnels.com

openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem
/etc/init.d/stunnel4 restart

# install fail2ban
cd
apt-get -y install fail2ban;service fail2ban restart
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
service fail2ban restart
cd

# install squid3
apt-get -y install squid3
wget -O /etc/squid3/squid.conf "https://github.com/malikshi/elora/raw/master/squid.conf"
sed -i $MYIP2 /etc/squid3/squid.conf
service squid3 restart

# install webmin
cd
echo 'deb http://download.webmin.com/download/repository sarge contrib' >>/etc/apt/sources.list
echo 'deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib' >>/etc/apt/sources.list
wget http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc
apt-get -y update && apt-get -y install webmin

# install tinyproxy & monir
#cd
#apt-get -y install tinyproxy monit
#wget -O /etc/monit/monitrc "https://github.com/malikshi/elora/raw/master/monitrc"
#/etc/init.d/monit reload
#/etc/init.d/monit start
#service tinyproxy restart
#autoban & filtering
cd
sed -i '$ i\screen -AmdS limit /root/limit.sh' /etc/rc.local
sed -i '$ i\screen -AmdS ban /root/ban.sh' /etc/rc.local
sed -i '$ i\screen -AmdS limit /root/limit.sh' /etc/rc.d/rc.local
sed -i '$ i\screen -AmdS ban /root/ban.sh' /etc/rc.d/rc.local
sed -i '$ i\service fail2ban restart' /etc/rc.local
sed -i '$ i\service dropbear restart' /etc/rc.local
sed -i '$ i\sudo service squid3 restart' /etc/rc.local
sed -i '$ i\/etc/init.d/stunnel4 restart' /etc/rc.local
#sed -i '$ i\/etc/init.d/monit reload' /etc/rc.local
#sed -i '$ i\/etc/init.d/monit start' /etc/rc.local
sed -i '$ i\/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 > /dev/nul &' /etc/rc.local
echo "0 0 * * * root /usr/local/bin/user-expire" > /etc/cron.d/user-expire
cd

cat > /root/ban.sh <<END1
#!/bin/bash
#/usr/local/bin/user-ban
END1

cat > /root/limit.sh <<END2
#!/bin/bash
#/usr/local/bin/user-limit
END2

cd /usr/local/bin
wget -O premium-script.tar.gz "https://github.com/malikshi/elora/raw/master/premium-script.tar.gz"
tar -xvf premium-script.tar.gz
rm -f premium-script.tar.gz

cp /usr/local/bin/premium-script /usr/local/bin/menu

chmod +x /usr/local/bin/trial
chmod +x /usr/local/bin/user-add
chmod +x /usr/local/bin/user-aktif
chmod +x /usr/local/bin/user-ban
chmod +x /usr/local/bin/user-delete
chmod +x /usr/local/bin/user-detail
chmod +x /usr/local/bin/user-expire
chmod +x /usr/local/bin/user-limit
chmod +x /usr/local/bin/user-lock
chmod +x /usr/local/bin/user-login
chmod +x /usr/local/bin/user-unban
chmod +x /usr/local/bin/user-unlock
chmod +x /usr/local/bin/user-password
chmod +x /usr/local/bin/user-log
chmod +x /usr/local/bin/user-add-pptp
chmod +x /usr/local/bin/user-delete-pptp
chmod +x /usr/local/bin/alluser-pptp
chmod +x /usr/local/bin/user-login-pptp
chmod +x /usr/local/bin/user-expire-pptp
chmod +x /usr/local/bin/user-detail-pptp
chmod +x /usr/local/bin/bench-network
chmod +x /usr/local/bin/speedtest
chmod +x /usr/local/bin/ram
chmod +x /usr/local/bin/log-limit
chmod +x /usr/local/bin/log-ban
chmod +x /usr/local/bin/listpassword
chmod +x /usr/local/bin/pengumuman
chmod +x /usr/local/bin/user-generate
chmod +x /usr/local/bin/user-list
chmod +x /usr/local/bin/diagnosa
chmod +x /usr/local/bin/premium-script
chmod +x /usr/local/bin/user-delete-expired
chmod +x /usr/local/bin/auto-reboot
chmod +x /usr/local/bin/log-install
chmod +x /usr/local/bin/menu
chmod +x /usr/local/bin/user-auto-limit
chmod +x /usr/local/bin/user-auto-limit-script
chmod +x /usr/local/bin/edit-port
chmod +x /usr/local/bin/edit-port-squid
chmod +x /usr/local/bin/edit-port-openvpn
chmod +x /usr/local/bin/edit-port-openssh
chmod +x /usr/local/bin/edit-port-dropbear
chmod +x /usr/local/bin/autokill
chmod +x /root/limit.sh
chmod +x /root/ban.sh
screen -AmdS limit /root/limit.sh
screen -AmdS ban /root/ban.sh
cd

# finalisasi
service ssh restart
service dropbear restart
service fail2ban restart
service squid3 restart
service webmin restart
/etc/init.d/stunnel4 restart
service openvpn restart


# info
clear
echo " "
echo "Instalasi telah selesai! Mohon baca dan simpan penjelasan setup server!"
echo " "
echo "--------------------------- Penjelasan Setup Server ----------------------------"
echo "            Modified by https://www.facebook.com/ibnumalik.al                   "
echo "--------------------------------------------------------------------------------"
echo ""  | tee -a log-install.txt
echo "Informasi Server"  | tee -a log-install.txt
echo "   - Timezone    : Asia/Jakarta (GMT +7)"  | tee -a log-install.txt
echo "   - Fail2Ban    : [on]"  | tee -a log-install.txt
echo "   - IPtables    : [off]"  | tee -a log-install.txt
echo "   - Auto-Reboot : [on]"  | tee -a log-install.txt
echo "   - IPv6        : [off]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Aplikasi & Port"  | tee -a log-install.txt
echo "   - OpenVPN     : TCP 1194 UDP 25 110 UDP SSL 53"  | tee -a log-install.txt
echo "   - OpenSSH     : 22"  | tee -a log-install.txt
echo "   - OpenSSH-SSL : 444"  | tee -a log-install.txt
echo "   - Dropbear    : 143, 54793"  | tee -a log-install.txt
echo "   - Dropbear-SSL: 443, 80"  | tee -a log-install.txt
echo "   - Squid Proxy : 8000 (limit to IP Server)"  | tee -a log-install.txt
echo "   - Squid-SSL   : 8080,3128 (limit to IP Server)"  | tee -a log-install.txt
echo "   - Badvpn      : 7300"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Tools Dalam Server"  | tee -a log-install.txt
echo "   - htop"  | tee -a log-install.txt
echo "   - iftop"  | tee -a log-install.txt
echo "   - mtr"  | tee -a log-install.txt
echo "   - nethogs"  | tee -a log-install.txt
echo "   - screenfetch"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Premium Script"  | tee -a log-install.txt
echo "   Perintah untuk menampilkan daftar perintah: menu"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "   Penjelasan script dan setup VPS"| tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Penting"  | tee -a log-install.txt
echo "   - Webmin                  : http://$MYIP:10000/"  | tee -a log-install.txt
echo "   - Log Instalasi           : cat /root/log-install.txt"  | tee -a log-install.txt
echo "     NB: User & Password Webmin adalah sama dengan user & password root"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "            Modified by https://www.facebook.com/ibnumalik.al                   "
