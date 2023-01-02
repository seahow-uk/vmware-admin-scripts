#!/bin/bash -x

## turn off selinux
	setenforce 0
	sed -i "s/enforcing/disabled/g" /etc/selinux/config

# this sets the NFS exports root to whatever directory this is
	function escapeSlashes {
		sed 's/\//\\\//g'
	}

	ESCAPEDPWD=$(echo "$PWD" | escapeSlashes)
	echo $ESCAPEDPWD
	sed -i 's/'"THISDIRPLACEHOLDER"'/'"$ESCAPEDPWD"'/' $ESXIROOT/config/exports
	sed -i 's/'"THISDIRPLACEHOLDER"'/'"$ESCAPEDPWD"'/' $ESXIROOT/config/smb.conf

## update grub
	rm -f /etc/default/grub && mv $ESXIROOT/boot/newgrub /etc/default/grub && grub2-mkconfig -o /boot/grub2/grub.cfg

## configure cron
	cat $ESXIROOT/config/crontabnew | crontab -

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
	dnf install libvirt-devel -y
	dnf install mlocate -y
	dnf install nfs-utils -y
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

## libvirt install via package groups 
	dnf groupinstall "Virtualization Host" --with-optional -y -q &>> /var/log/configure_l0_packages_2.log
	dnf install virt* libguestfs* swtpm* libibverbs -y -q &>> /var/log/configure_l0_packages_3.log

## Shuffle config files needed for Kickstart, etc
	mv -fv $ESXIROOT/config/exports /etc/exports
	mv -fv $ESXIROOT/config/smb.conf /etc/samba/smb.conf
	cp -f $ESXIROOT/bash/treesize.sh /bin/treesize
	cp -f $ESXIROOT/config/KS.CFG /var/www/html/KS.CFG
	cp -f $ESXIROOT/bash/epochtohuman.sh /bin/epochtohuman.sh

## Kickstart samba
	systemctl enable smb nmb
	systemctl start smb nmb

## set root password for Samba so jump host can easily mount shares
	echo -ne "$ADPASSWORD\n$ADPASSWORD\n" | smbpasswd -a -s root

## configure host profile
	tuned-adm profile virtual-host &>> /var/log/configure_l0_packages_5.log

## increase the open file limit for dbus
	sed -i 's/.*DefaultLimitNOFILE=.*/DefaultLimitNOFILE=16384/g' /etc/systemd/system.conf

  # extract all versions of the vcsa ISO (might want to tighten this up later to shorten build time)

  #### VCSA
    mount -o loop $VCSAISO /mnt/iso
    mkdir -p vcsa-extracted/$VSPHEREVERSION
    cp -rf /mnt/iso/* vcsa-extracted/$VSPHEREVERSION
    umount /mnt/iso
	ln -s $ESXIROOT/vcsa-extracted/$VSPHEREVERSION/vcsa/ovftool/lin64/ovftool /usr/bin/ovftool

  ## Permissions tweaks for the aforementioned config files
    chown -R root:nobody * 
    chmod -R 777 /bin/treesize
    chmod -R 744 *

  ## upgrade pip first
	pip3 install --upgrade pip

  ## install a few pip packages
	pip3 install pyvim --log /var/log/pip_install_pyvim.log
	pip3 install requests --log /var/log/pip_install_requests.log
	pip3 install vcrpy --log /var/log/pip_install_vrcpy.log
	pip3 install pyvmomi --log /var/log/pip_install_pyvmomi.log
	pip3 install suds-jurko --log /var/log/pip_install_suds-jurko.log
	pip3 install lxml --log /var/log/pip_install_lxml.log
	pip3 install ipaddress --log /var/log/pip_install_ipaddress.log
	pip3 install wheel --log /var/log/pip_install_wheel.log
	pip3 install flent --log /var/log/pip_install_flent.log

	# install vsphere-automation-sdk for python
	pip3 install git+https://github.com/vmware/vsphere-automation-sdk-python.git

	# community samples package for pyvmomi
	pip3 install git+https://github.com/vmware/pyvmomi-community-samples.git

	chmod 700 $ESXCLIFILE
	expect/installesxcli.sh

	# dcli must be forcibly installed dead last or dependency conflicts occur
	pip3 install dcli --force --log /var/log/pip_install_dcli.log
	dcli --version &>> /var/log/configure_l0_packages_6.log

  ## this section installs needed prereqs plus OVS
	dnf install net-tools -y
	dnf install openvswitch -y 
	dnf install os-net-config -y
	
exit 0