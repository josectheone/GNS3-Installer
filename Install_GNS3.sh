#!/bin/bash
# Script para Instalar GNS3 e dependencias em distribuçoes baseadas no debian

echo 'Adicionando suporte a PPA'
sudo apt-get -y install software-properties-common &&

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
sudo apt-get -y install gns3-gui gns3-iou vpcs iptraf-ng iperf3 ipcalc git vim uml-utilities bridge-utils wireshark wireshark-common wireshark-dev cpulimit qemu qemu-utils qemu-kvm qemu-user qemu-system-x86 virtualbox tigervnc-viewer &&

ECHO 'Agregando usuario nos grupos'
sudo usermod -a -G ubridge,libvirt,kvm $USER

echo 'Processo completado, pode iniciar GNS3'
echo 'Script creado por Josectheone'
echo '21/01/2019'
