#!/bin/bash
# gns3-installer.sh - Script para facilitar a instalação e configuração do gns3.
# Developed by: Jose Carlos Mendez Pena. 
# version 0.1.1
#
# Request root access
if [[ $UID != 0 ]]; then
	echo "Por favor, execute este script como root:"
	echo "sudo $0 $*"
	exit 1
fi
apt -y install dialog

# Store menu options selected by the user
INPUT=/tmp/menu.sh.$$
INPUT1=/tmp/input.sh.$$

# Storage file for displaying cal and date command output
OUTPUT=/tmp/output.sh.$$

# trap and delete temp files
trap "rm $OUTPUT; rm $INPUT; rm $INPUT1; exit" SIGHUP SIGINT SIGTERM

# Purpose - display output using msgbox 
#  $1 -> set msgbox height
#  $2 -> set msgbox width
#  $3 -> set msgbox title
function display_output(){
	local h=${1-10}			# box height default 10
	local w=${2-41} 		# box width default 41
	local t=${3-Output} 	# box title 
	dialog --backtitle "Instalador do gns3 by JC" --title "${t}" --clear --msgbox "$(<$OUTPUT)" ${h} ${w}
}
#
# Purpose - Enable PPA
#
function PPA()
{
    if [ -f /usr/sbin/add-apt-repository ]; then
		break
    else
		cat >/usr/sbin/add-apt-repository << "EOF"
#!/bin/bash
# SCRIPT add-apt-repository.sh
if [ $# -eq 1 ]	NM=$(uname -a && date) NAME=$(echo $NM | md5sum | cut -f1 -d" ")
then
	ppa_name=$(echo "$1" | cut -d":" -f2 -s)
if [ -z "$ppa_name" ]
then
	echo "PPA name not found"
	echo "Utility to add PPA repositories in your debian machine"
	echo "$0 ppa:user/ppa-name"
else
	echo "$ppa_name"
	echo "deb http://ppa.launchpad.net/$ppa_name/ubuntu bionic main" >> /etc/apt/sources.list
	apt-get update >> /dev/null 2> /tmp/${NAME}_apt_add_key.txt
	key=$(cat /tmp/${NAME}_apt_add_key.txt | cut -d":" -f6 | cut -d" " -f3)
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $key
	rm -rf /tmp/${NAME}_apt_add_key.txt
fi
else
    echo "Utility to add PPA repositories in your debian machine"
	echo "$0 ppa:user/ppa-name"
fi
EOF
		chmod 755 /usr/sbin/add-apt-repository.sh
	fi
}
#
# Purpose - Install gns3
#
function Install()
{
    if ls /etc/apt/sources.list.d/gns3-ubuntu-ppa* &> /dev/null; 
    then
		apt update && apt -y install gns3-gui tigervnc-viewer
    	usermod -a -G ubridge,libvirt,kvm,wireshark $USER
    else
		add-apt-repository ppa:gns3/ppa && apt update && apt -y install gns3-gui tigervnc-viewer
    	usermod -a -G ubridge,libvirt,kvm,wireshark
    fi
}
#
# purpose - configure TAP iface for direct access to the gns3 devices
#
function TAP()
{
    apt -y install iptables-persistent dnsmasq
	if ($( cat /etc/network/interfaces | grep -q "tap0" ));
    then
		break
	else
		cat >/etc/network/interfaces << EOF
auto tap0
iface tap0 inet static
address	$INPUT2.1
netmask	255.255.255.0
pre-up	/sbin/ip tuntap add dev tap0 mode tap
post-down /sbin/ip tuntap del dev tap0 mode tap
EOF
	    ifup tap0
	    echo 1 >/proc/sys/net/ipv4/ip_forward
	    echo 'net.ipv4.ip_forward=1' >>/etc/sysctl.conf
	    iptables -t nat -A POSTROUTING -s $INPUTC/24 ! -d $INPUTC/24 -j MASQUERADE
	    netfilter-persistent save
	    
	    cat >/etc/dnsmasq.d/tap0.conf << EOF
interface=tap0
dhcp-range=$INPUT2.100,$INPUT2.150,1h
EOF
	    sudo service dnsmasq restart
	    sudo update-rc.d dnsmasq defaults
	fi
}
#
# set infinite loop
#
while true
do
### display main menu ###
dialog --clear --backtitle "Instalador do gns3 by JC" \
--title "[ B R I S A N E T ]" \
--menu "Você pode navegar usando as teclas UP/DOWN" 15 70 4 \
PPA "Necesario em Debian e Deepin" \
GNS3 "Instala o sistema gns3" \
TAP "Cria uma interface TAP com NAT ativado e servidor DHCP" \
Sair "Saida de volta ao terminal" 2>"${INPUT}"

menuitem=$(<"${INPUT}")

# make decsion 
case $menuitem in
	PPA) PPA;;
	GNS3) Install;;
	TAP) dialog --title "TAP setup" --clear \
        --inputbox "Configuração da interface TAP:\n
        Insira o endereço de Network da interface TAP\n
        exemplo 192.168.0.0 a interface tap0 vai ficar\n
        com IP X.X.X.1 a pool dhcp vai ficar\n
        X.X.X.100 - X.X.X.150" 16 60 2> ${INPUT1}
        INPUTC=$(<"${INPUT1}")
        INPUT2=${INPUTC%??};
    TAP;;
	Sair) clear && echo "É precisso enserrar sessão antes de usar o gns3 pela primeira vez!"; break;;
esac

done

# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT