#! /bin/bash
#
# Author: Jose Carlos Mendez Pena
# Contact email: josectheone@ g m a i l .com 
#
if [[ $UID != 0 ]]; then
	exec sudo -- "$0" "$@"
fi

clear

################################
#---- Functions start here ----# 
################################

Install() {
	ls /etc/apt/sources.list.d/gns3-ubuntu-ppa* &> /dev/null
	if [[ $? == 0 ]]; then
		apt -y install gns3-gui tigervnc-viewer
		usermod -a -G ubridge,libvirt,kvm,wireshark "$USER"
		whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "Done, remember to logout before using GNS3." 10 60
	else
		add-apt-repository -y ppa:gns3/ppa && apt -y install gns3-gui tigervnc-viewer
		usermod -a -G ubridge,libvirt,kvm,wireshark "$USER"
		whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "Done, remember to logout before using GNS3." 10 60
	fi 
}

TAP() {
	apt -y install iptables-persistent dnsmasq
	cat >/etc/network/interfaces <<-EOF
		auto tap0
		iface tap0 inet static
		address $netvarc.1
		netmask 255.255.255.0
		pre-up  /sbin/ip tuntap add dev tap0 mode tap
		post-down /sbin/ip tuntap del dev tap0 mode tap
	EOF
		ifup tap0
		echo 1 >/proc/sys/net/ipv4/ip_forward
		echo 'net.ipv4.ip_forward=1' >>/etc/sysctl.conf
		iptables -t nat -A POSTROUTING -s "$netvar"/24 ! -d "$netvar"/24 -j MASQUERADE
		netfilter-persistent save
		cat >/etc/dnsmasq.d/tap0.conf <<-EOF
		interface=tap0
		dhcp-range=$netvarc.100,$netvarc.150,1h
	EOF
		sudo service dnsmasq restart
		sudo update-rc.d dnsmasq defaults
		whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "Done, run ifconfig to test the tap interface." 10 60
}

PPA() {
	cat >/usr/sbin/add-apt-repository <<-"EOF"
	#!/bin/bash
	# SCRIPT add-apt-repository
	if [ $# -eq 1 ]
	NM=$(uname -a && date) NAME=$(echo "$NM" | md5sum | cut -f1 -d" ")
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
			apt-get update >> /dev/null 2> /tmp/"${NAME}"_apt_add_key.txt
			key=$(cat /tmp/"${NAME}"_apt_add_key.txt | cut -d":" -f6 | cut -d" " -f3)
			apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key"
			rm -rf /tmp/${NAME}_apt_add_key.txt
		fi
	else
		echo "Utility to add PPA repositories in your debian machine"
		echo "$0 ppa:user/ppa-name"
	fi
	EOF
	chmod 755 /usr/sbin/add-apt-repository
	whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "Done, now you can install GNS3." 10 60
}

################################
#---- Main code start here ----# 
################################

while true; do
	CHOICE=$(whiptail --title "Main menu" --backtitle "GNS3 Installer" --menu "Make your choice" 15 50 4\
						"1)" "Install GNS3 network simulator."\
						"2)" "Setup TAP interface with NAT and DHCP-SERVER."\
						"3)" "Setup PPA in Debian and Deepin distros."\
						"4)" "End script." 3>&2 2>&1 1>&3)
	case $CHOICE in
		"1)" )
			apt list gns3-gui | grep installed &>/dev/null
			if [[ $? != 1 ]]; then
				whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "GNS3 already installed in this system." 10 60
			else
				Install
			fi
			;;
		"2)")   
			grep -q "tap0" /etc/network/interfaces
			if [[ $? == 0 ]]; then
				whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "TAP interface already configured." 10 100
			else
				netvar=$(whiptail --title "TAP interface configuration" --backtitle "GNS3 Installer" --inputbox "Input network address for the interface:\\n \\n Example 192.168.0.0" 12 50 3>&1 1>&2 2>&3)
				netvarc=${netvar%??};
				whiptail --msgbox "Awesome your setup will be:\\n \\n #tap interface\\n ip address = $netvarc.1\\n netmask    = 255.255.255.0\\n network    = $netvar\\n broadcast  = $netvarc.255\\n	dhcp-range = $netvarc.100 - $netvarc.150" 15 100
				TAP
			fi
			;;
		"3)")   
			if [[ -e /usr/bin/add-apt-repository ]]; then
				whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "PPA already configured in this system." 10 60
			else
				PPA
			fi
			;;
		"4)")   
			exit
			;;
	esac
done
exit
