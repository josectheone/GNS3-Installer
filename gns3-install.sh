#! /bin/bash

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

if [[ $UID != 0 ]]; then
        echo "Please, execute this script as root:"
        echo "sudo $0 $*"
        exit 1
fi

clear

function Install {
        if ls /etc/apt/sources.list.d/gns3-ubuntu-ppa* &> /dev/null 
        then
                apt update && apt -y install gns3-gui tigervnc-viewer
                usermod -a -G ubridge,libvirt,kvm,wireshark $USER
                whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "Done, remember to logout before using GNS3." 10 60
        else
                add-apt-repository -y ppa:gns3/ppa && apt update && apt -y install gns3-gui tigervnc-viewer
                usermod -a -G ubridge,libvirt,kvm,wireshark $USER
                whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "Done, remember to logout before using GNS3." 10 60
        fi 
}

function TAP {
        if ($( cat /etc/network/interfaces | grep -q "tap0" ))
        then
                whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "TAP interface already configured." 10 60
        else
                apt -y install iptables-persistent dnsmasq
                cat >/etc/network/interfaces << EOF
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
        iptables -t nat -A POSTROUTING -s $netvar/24 ! -d $netvar/24 -j MASQUERADE
        netfilter-persistent save
        cat >/etc/dnsmasq.d/tap0.conf << EOF
interface=tap0
dhcp-range=$netvarc.100,$netvarc.150,1h
EOF
        sudo service dnsmasq restart
        sudo update-rc.d dnsmasq defaults
        whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "Done, run ifconfig to test the tap interface." 10 60
        fi
}

function PPA {
        if [ -f /usr/sbin/add-apt-repository ]
        then
                whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "PPA already configured in this system." 10 60
        else
                cat >/usr/sbin/add-apt-repository << "EOF"
#!/bin/bash
# SCRIPT add-apt-repository
if [ $# -eq 1 ] 
NM=$(uname -a && date) NAME=$(echo $NM | md5sum | cut -f1 -d" ")
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
                chmod 755 /usr/sbin/add-apt-repository
                whiptail --title "Information" --backtitle "GNS3 Installer" --msgbox "Done, now you can install GNS3." 10 60
        fi
}

while [ 1 ]
do
CHOICE=$(
whiptail --title "Main menu" --backtitle "GNS3 Installer" --menu "Make your choice" 15 50 4\
        "1)" "Install GNS3 network simulator." \
        "2)" "Setup NAT - DHCP-SERVER - TAP interface." \
        "3)" "Setup PPA in Debian and Deepin distros." \
        "4)" "End script."  3>&2 2>&1 1>&3
        )

case $CHOICE in
        "1)")   
                Install
        ;;

        "2)")   
                whiptail --title "TAP interface configuration" --backtitle "GNS3 Installer" \
                        --inputbox "\n Input network address for the interface:\n Example 192.168.0.0\n The interface adddress will be 192.168.0.1\n The dhcp pool will be 192.168.0.100-150\n" 12 50 2> /tmp/inputvar
                netvar=$(</tmp/inputvar)
                netvarc=${netvar%??};
                TAP
        ;;

        "3)")   
                PPA
        ;;

        "4)") exit
        ;;
esac
done
exit