#!/bin/bash
# Script para Instalar GNS3 e dependencias em distribuçoes baseadas no debian

echo 'Adicionando suporte a PPA'
# Create add-apt-repository script in /usr/sbin
sudo cat <<EOT >> /usr/sbin/add-apt-repository
#!/bin/bash
# SCRIPT add-apt-repository
if [ $# -eq 1 ]
NM=`uname -a && date`
NAME=`echo $NM | md5sum | cut -f1 -d" "`
then
ppa_name=`echo "$1" | cut -d":" -f2 -s`
if [ -z "$ppa_name" ]
then
echo "PPA name not found"
echo "Utility to add PPA repositories in your debian machine"
echo "$0 ppa:user/ppa-name"
else
echo "$ppa_name"
echo "deb http://ppa.launchpad.net/$ppa_name/ubuntu bionic main" >> /etc/apt/sources.list
apt-get update >> /dev/null 2> /tmp/${NAME}_apt_add_key.txt
key=`cat /tmp/${NAME}_apt_add_key.txt | cut -d":" -f6 | cut -d" " -f3`
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $key
rm -rf /tmp/${NAME}_apt_add_key.txt
fi
else
echo "Utility to add PPA repositories in your debian machine"
echo "$0 ppa:user/ppa-name"
fi
EOT

echo 'Modificando permiçoes'
sudo chmod 755 /usr/sbin/add-apt-repository

echo 'Adicionando repositorios e PPA'
sudo dpkg --add-architecture i386 &&
sudo add-apt-repository ppa:gns3/ppa &&
wget -q -O - http://download.virtualbox.org/virtualbox/debian/oracle_vbox_2016.asc | sudo apt-key add - &&
sudo sh -c 'echo "deb http://download.virtualbox.org/virtualbox/debian bionic non-free contrib" >> /etc/apt/sources.list.d/virtualbox.org.list' &&

echo 'Atualizando listas de pacotes'
sudo apt-get -y update &&
sudo apt-get -y upgrade &&
sudo apt-get -y dist-upgrade &&
sudo apt-get -y autoremove &&
sudo apt-get -y autoclean &&
sudo apt-get -y clean &&

echo 'Instalando GNS3 e dependencias'
sudo apt-get -y install iptables-persistent dnsmasq gns3-gui gns3-iou vpcs iptraf-ng iperf3 ipcalc git vim uml-utilities bridge-utils wireshark wireshark-common wireshark-dev cpulimit qemu qemu-utils qemu-kvm qemu-user qemu-system-x86 virtualbox tigervnc-viewer &&

echo 'Agregando usuario nos grupos'
sudo usermod -a -G ubridge,libvirt,kvm $USER

echo 'Creando interface TAP'
sudo cat <<EOT >> /etc/network/interfaces
auto tap0
iface tap0 inet static
	address	172.31.1.254
	netmask	255.255.255.0
	pre-up	/sbin/ip tuntap add dev tap0 mode tap
	post-down /sbin/ip tuntap del dev tap0 mode tap
EOT

echo 'Iniciando o tunnel'
sudo ifup tap0

echo 'Ativando forwarding'
sudo echo 1 > /proc/sys/net/ipv4/ip_forward
sudo echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

echo 'Creando regras no Firewall'
sudo iptables -t nat -A POSTROUTING -s 172.31.1.0/24 ! -d 172.31.1.0/24 -j MASQUERADE
sudo netfilter-persistent save

echo 'Configurando servidor DHCP para GNS3'
sudo cat <<EOT >> /etc/dnsmasq.d/tap0.conf
# Configuration file for dnsmasq on tap0 interface
interface=tap0
dhcp-range=172.31.1.100,172.31.1.249,1h
EOT

echo 'Reiniciando dnsmasq'
sudo service dnsmasq restart

echo 'Processo completado, pode iniciar GNS3'
echo 'Script creado por Josectheone'
echo '21/01/2019'
