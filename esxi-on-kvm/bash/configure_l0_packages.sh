#!/bin/bash -x

## turn off selinux
	setenforce 0
	sed -i "s/enforcing/disabled/g" /etc/selinux/config

## update grub
	rm -f /etc/default/grub && mv ./boot/newgrub /etc/default/grub && grub2-mkconfig -o /boot/grub2/grub.cfg

## configure cron
	cat ./config/crontabnew | crontab -

## create directory structure
	mkdir -p /mnt/iso /var/www/html ./OVA ./VM 

## repo stuff
	#sed -i -e "s|mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/CentOS-*
	#sed -i -e "s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g" /etc/yum.repos.d/CentOS-*
	rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Virtualization
	rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8
	rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Cloud
	wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Virtualization -O /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization
	wget https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8 -O /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
	wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Cloud -O /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud

## Prep dnf environment
	dnf clean all 
	rm -rfv /var/cache/dnf
	cp -f ./repos/* /etc/yum.repos.d
	dnf distro-sync -y

## install packages
	yum install gdisk -y
	yum install wget -y
	yum install expect -y
	yum install lvm2 -y
	yum install kernel-devel -y
	yum install nfs-utils -y
	yum install nfs4-acl-tools -y
	yum install libnfsidmap -y
	yum install python2 -y
	yum install python2-pip -y
	yum install python39 -y
	yum install python39-pip -y
	yum install python39-wheel -y
	yum install python39-devel -y
	yum install gcc -y
	yum install expect -y
	yum install numactl -y
	yum install cmake -y
	yum install maven -y 
	yum install byacc -y 
	yum install unbound -y 
	yum install parallel -y 
	yum install nvme-cli -y 
	yum install mlocate -y 
	yum install ipcalc -y 
	yum install polkit -y 
	yum install wget -y  
	yum install httpd -y
	yum install dhcp-server -y 
	yum install libnsl -y 
	yum install sshpass -y 
	yum install unzip -y 
	yum install libvirt-devel -y 
	yum install nload -y 
	yum install sysfsutils -y
	yum install iotop -y
	yum install iftop -y
	yum install netpbm -y
	yum install samba -y

## update-alternatives for python
	update-alternatives --set python3 /usr/bin/python3.9
	update-alternatives --set python /usr/bin/python2

## libvirt install via package groups 
	dnf module disable virt -y &>> /var/log/userdata.log
	dnf groupinstall "Virtualization Host" --with-optional -y -q &>> /var/log/userdata.log
	dnf install virt* -y -q &>> /var/log/userdata.log
	dnf install libguestfs* -y -q &>> /var/log/userdata.log
	dnf install swtpm* -y -q &>> /var/log/userdata.log   

## OVS install
	dnf install openvswitch -y -q &>> /var/log/userdata.log
	dnf install libibverbs -y -q &>> /var/log/userdata.log
	dnf install os-net-config -y -q &>> /var/log/userdata.log
	dnf install vnstat -y -q &>> /var/log/userdata.log
	systemctl enable vnstat
	systemctl start vnstat

## install various tool packages for troubleshooting
	dnf group install "Networking Tools" --with-optional -y
	dnf group install "Hardware Monitoring Utilities" --with-optional -y
	dnf group install "Large Systems Performance" --with-optional -y
	dnf group install "Performance Tools" --with-optional -y
	dnf group install "System Tools" --with-optional -y

## Install Web Services
	dnf install cockpit-* -y -q &>> /var/log/userdata.log
	dnf install mod_ssl -y -q &>> /var/log/userdata.log
	systemctl enable --now cockpit.socket &>> /var/log/userdata.log
	systemctl start --now cockpit.socket &>> /var/log/userdata.log  

## Shuffle config files needed for Kickstart, etc
	mv -fv ./config/exports /etc/exports
	mv -fv ./config/smb.conf /etc/samba/smb.conf
	cp -f ./bash/treesize.sh /bin/treesize
	cp -f ./config/KS.CFG /var/www/html/KS.CFG
	cp -f ./bash/epochtohuman.sh ./bash/epochtohuman.sh

## Permissions tweaks for the aforementioned config files
	chown -R root:nobody ./ 
	chmod -R 777 /bin/treesize
	chmod 777 ./bash/epochtohuman.sh 
	chmod -R 777 ./

## Kickstart samba
	systemctl enable smb nmb
	systemctl start smb nmb

## configure host profile
	tuned-adm profile virtual-host &>> /var/log/userdata.log

## python links
	update-alternatives --set python3 /usr/bin/python3.9
	update-alternatives --set python /usr/bin/python2

## vnet rules
	mv -f ./config/60-vnet.rules /etc/udev/rules.d/60-vnet.rules

## increase the open file limit for dbus
	sed -i 's/.*DefaultLimitNOFILE=.*/DefaultLimitNOFILE=16384/g' /etc/systemd/system.conf

  # extract all versions of the vcsa ISO (might want to tighten this up later to shorten build time)

  #### VCSA
    mount -o loop $VCSAISO /mnt/iso
    mkdir -p ./vcsa-extracted/$VSPHEREVERSION
    cp -rf /mnt/iso/* ./vcsa-extracted/$VSPHEREVERSION
    umount /mnt/iso
	ln -s ./vcsa-extracted/$VSPHEREVERSION/vcsa/ovftool/lin64/ovftool /usr/bin/ovftool

  ## Create directory structures needed
    mkdir -p /etc/samba 
    mkdir -p /var/www/html/

  ## Shuffle config files needed for Kickstart, etc
    mv -fv ./config/exports /etc/exports
    mv -fv ./config/smb.conf /etc/samba/smb.conf
    cp -f ./bash/treesize /bin/treesize
    cp -f ./config/KS.CFG /var/www/html/KS.CFG

  ## Kickstart samba
    systemctl enable smb nmb
    systemctl start smb nmb

  ## Permissions tweaks for the aforementioned config files
    chown -R root:nobody ./ 
    chown -R root:wheel /gopath/src/github.com/advantageous/systemd-cloud-watch/installer.sh
    chmod -R 777 /bin/treesize
    chmod 777 ./data/epochtohuman.sh /gopath/src/github.com/advantageous/systemd-cloud-watch/installer.sh
    chmod -R 777 ./
    chmod -R 444 /etc/systemd/system/journald-cloudwatch.service

	mkdir -p /var/log/pip

	update-alternatives --set python3 /usr/bin/python3.9
	update-alternatives --set python /usr/bin/python2

	pip install pyvim --log /var/log/pip/install_pyvim.log
	pip install requests --log /var/log/pip/install_requests.log
	pip install vcrpy --log /var/log/pip/install_vrcpy.log
	pip install pyvmomi --log /var/log/pip/install_pyvmomi.log
	pip install suds-jurko --log /var/log/pip/install_suds-jurko.log
	pip install lxml --log /var/log/pip/install_lxml.log
	pip install ipaddress --log /var/log/pip/install_ipaddress.log
	pip install setuptools --log /var/log/pip/install_setuptools.log
	pip install wheel --log /var/log/pip/install_wheel.log
	pip install dcli --log /var/log/pip/install_dcli.log
	pip install flent --log /var/log/pip/install_flent.log

	# install vsphere-automation-sdk for python
	pip install git+https://github.com/vmware/vsphere-automation-sdk-python.git

	# community samples package for pyvmomi
	pip install git+https://github.com/vmware/pyvmomi-community-samples.git

	chmod 700 ./data/$ESXCLIFILE
	./expect/installesxcli.sh

	dcli --version

	dnf install sshpass -y

exit 0

