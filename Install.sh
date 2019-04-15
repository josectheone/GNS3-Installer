#!/bin/bash

# Solicita acesso root
if [[ $UID != 0 ]]; then
	echo "Por favor, execute este script como root:"
	echo "sudo $0 $*"
	exit 1
fi
# Suporte PPA
while true; do
	read -r -p "Deseja configurar suporte a PPA? [Y/n] " input
	case $input in
	[yY][eE][sS] | [yY])
		if [ -f /usr/sbin/add-apt-repository ]; then
			break
		else
			cat >/usr/sbin/add-apt-repository <<'EOF'
#!/bin/bash
# SCRIPT add-apt-repository.sh
if [ $# -eq 1 ]
	NM=$(uname -a && date)
	NAME=$(echo $NM | md5sum | cut -f1 -d" ")
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
		break
		;;
	[nN][oO] | [nN])
		break
		;;
	*)
		echo "Entrada errada..."
		;;

	esac

done

if ls /etc/apt/sources.list.d/gns3-ubuntu-ppa* &> /dev/null; then
	apt-get update && sudo apt-get install gns3-gui iptables-persistent dnsmasq tigervnc-viewer
else
	add-apt-repository ppa:gns3/ppa && apt-get update && apt-get install gns3-gui iptables-persistent dnsmasq tigervnc-viewer
fi

# Interface TAP
while true; do
	read -r -p "Deseja configurar uma interface TAP com forwarding e NAT? [Y/n] " input1
	case $input1 in
	[yY][eE][sS] | [yY])
		apt-get install iptables-persistent dnsmasq
		if ($( cat /etc/network/interfaces | grep -q "tap0" )); then
			break
		else
			cat >/etc/network/interfaces <<'EOF'
auto tap0
iface tap0 inet static
address	172.16.1.254
netmask	255.255.255.0
pre-up	/sbin/ip tuntap add dev tap0 mode tap
post-down /sbin/ip tuntap del dev tap0 mode tap
EOF
			ifup tap0
			echo 1 >/proc/sys/net/ipv4/ip_forward
			echo 'net.ipv4.ip_forward=1' >>/etc/sysctl.conf
			iptables -t nat -A POSTROUTING -s 172.16.1.0/24 ! -d 172.16.1.0/24 -j MASQUERADE
			netfilter-persistent save
			
			cat >/etc/dnsmasq.d/tap0.conf <<'EOF'
interface=tap0
dhcp-range=172.16.1.100,172.16.1.150,1h
EOF

			sudo service dnsmasq restart
			sudo update-rc.d dnsmasq defaults
		fi
		break
		;;
	[nN][oO] | [nN])
		break
		;;
	*)
		echo "Entrada errada..."
		;;
	esac
done

sudo usermod -a -G ubridge,libvirt,kvm $USER

echo "Proceso completado com sucesso"
echo "Reinicie o computador antes de usar GNS3"
