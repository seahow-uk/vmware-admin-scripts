#!/bin/bash -x
#
# Troubleshooting script that only installs OVS, no virtualization

echo "export PATH=$PATH:/usr/local/share/openvswitch/scripts" >> bash/configure_l0_env.sh
. ./bash/configure_l0_env.sh &>> /var/log/configure_l0_env.sh.log

## make sure cloud-init doesnt run anymore at boot
touch /etc/cloud/cloud-init.disabled

## turn off selinux
	setenforce 0
	sed -i "s/enforcing/disabled/g" /etc/selinux/config

# this sets the NFS exports root to whatever directory this is
	function escapeSlashes {
		sed 's/\//\\\//g'
	}

	ESCAPEDPWD=$(echo "$PWD" | escapeSlashes)
	echo $ESCAPEDPWD
	sed -i 's/'"THISDIRPLACEHOLDER"'/'"$ESCAPEDPWD"'/' ./config/exports
	sed -i 's/'"THISDIRPLACEHOLDER"'/'"$ESCAPEDPWD"'/' ./config/smb.conf

## update grub
	rm -f /etc/default/grub && mv ./boot/newgrub /etc/default/grub && grub2-mkconfig -o /boot/grub2/grub.cfg

## configure cron
	cat ./config/crontabnew | crontab -

## create directory structures
	mkdir -p /mnt/iso /var/www/html OVA VM /etc/samba /var/log/pip

## level set
	## if this box has awscli already on it, it can cause problems
	dnf remove awscli -y
	
	dnf config-manager --enable ha
	dnf config-manager --enable powertools
	dnf config-manager --enable nfv
	dnf config-manager --enable extras

	dnf install python39 -y
	dnf install python2 -y
	dnf install centos-release-openstack-xena -y
	dnf install centos-release-nfv-openvswitch -y
	dnf clean all 
	rm -rfv /var/cache/dnf
	dnf distro-sync -y
	dnf update -y

## set python alternative references up.  something needs python2 later and i dont recall what
	update-alternatives --set python3 /usr/bin/python3.9
	update-alternatives --set python /usr/bin/python2

## install packages
	dnf install awscli -y
	dnf install dhcp-server -y
	dnf install expect -y
	dnf install httpd -y
	dnf install ipcalc -y
	dnf install libnsl -y
	dnf install mlocate -y
	dnf install nfs-utils -y
	dnf install parallel -y
	dnf install polkit -y
	dnf install samba -y
	dnf install sshpass -y
	dnf install unzip -y
	dnf install wget -y
	dnf install mod_ssl -y
	dnf install sysfsutils -y

## turn on cockpit, which you can access at https://<hostip>:9090
	systemctl enable --now cockpit.socket
	systemctl start --now cockpit.socket

## Shuffle config files needed for Kickstart, etc
	mv -fv ./config/exports /etc/exports
	mv -fv ./config/smb.conf /etc/samba/smb.conf
	cp -f ./bash/treesize.sh /bin/treesize
	cp -f ./bash/epochtohuman.sh /bin/epochtohuman.sh

## increase the open file limit for dbus
	sed -i 's/.*DefaultLimitNOFILE=.*/DefaultLimitNOFILE=16384/g' /etc/systemd/system.conf

## upgrade pip first
	pip3 install --upgrade pip

## install a few pip packages
	pip3 install requests --log /var/log/pip_install_requests.log
	pip3 install vcrpy --log /var/log/pip_install_vrcpy.log
	pip3 install suds-jurko --log /var/log/pip_install_suds-jurko.log
	pip3 install lxml --log /var/log/pip_install_lxml.log
	pip3 install ipaddress --log /var/log/pip_install_ipaddress.log
	pip3 install wheel --log /var/log/pip_install_wheel.log
	pip3 install flent --log /var/log/pip_install_flent.log

## this section installs needed prereqs plus OVS
	dnf install net-tools -y
	dnf install openvswitch -y 
	dnf install os-net-config -y

## configure openvswitch, routing, VLANs
  ./bash/configure_ovs.sh &>> /var/log/configure_ovs.sh.log

exit 0
