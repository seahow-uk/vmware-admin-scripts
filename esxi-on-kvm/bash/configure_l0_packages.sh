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
	sed -i 's/'"THISDIRPLACEHOLDER"'/'"$ESCAPEDPWD"'/' ./config/exports
	sed -i 's/'"THISDIRPLACEHOLDER"'/'"$ESCAPEDPWD"'/' ./config/smb.conf

## update grub
	rm -f /etc/default/grub && mv ./boot/newgrub /etc/default/grub && grub2-mkconfig -o /boot/grub2/grub.cfg

## configure cron
	cat ./config/crontabnew | crontab -

## create directory structures
	mkdir -p /mnt/iso /var/www/html OVA VM /etc/samba /var/log/pip

## level set
	dnf install epel-release -y
	dnf install centos-release-nfv-openvswitch -y
	# openstack Xena is the newest openstack release they have a package for on Centos 8 stream as of Dec 2022
	dnf install centos-release-openstack-xena -y
	dnf install python39 -y
	dnf install python2 -y
	dnf clean all 
	rm -rfv /var/cache/dnf
	dnf distro-sync -y
	dnf update -y

## set python alternative references up.  something needs python2 later and i dont recall what
	update-alternatives --set python3 /usr/bin/python3.9
	update-alternatives --set python /usr/bin/python2

## install packages
	dnf install net-tools dhcp-server expect httpd ipcalc libnsl libvirt-devel mlocate nfs-utils parallel polkit samba sshpass unzip wget sshpass -y -q &>> /var/log/configure_l0_packages_1.log

## libvirt install via package groups 
	dnf groupinstall "Virtualization Host" --with-optional -y -q &>> /var/log/configure_l0_packages_2.log
	dnf install virt* libguestfs* swtpm* -y -q &>> /var/log/configure_l0_packages_3.log

## OVS install
	dnf install openvswitch libibverbs os-net-config -y -q &>> /var/log/configure_l0_packages_4.log

## Shuffle config files needed for Kickstart, etc
	mv -fv ./config/exports /etc/exports
	mv -fv ./config/smb.conf /etc/samba/smb.conf
	cp -f ./bash/treesize.sh /bin/treesize
	cp -f ./config/KS.CFG /var/www/html/KS.CFG
	cp -f ./bash/epochtohuman.sh /bin/epochtohuman.sh

## Kickstart samba
	systemctl enable smb nmb
	systemctl start smb nmb

## set root password for Samba so jump host can easily mount shares
	echo -ne "$ADPASSWORD\n$ADPASSWORD\n" | smbpasswd -a -s root

## configure host profile
	tuned-adm profile virtual-host &>> /var/log/configure_l0_packages_5.log

## vnet rules
	mv -f ./config/60-vnet.rules /etc/udev/rules.d/60-vnet.rules

## increase the open file limit for dbus
	sed -i 's/.*DefaultLimitNOFILE=.*/DefaultLimitNOFILE=16384/g' /etc/systemd/system.conf

  # extract all versions of the vcsa ISO (might want to tighten this up later to shorten build time)

  #### VCSA
    mount -o loop $VCSAISO /mnt/iso
    mkdir -p vcsa-extracted/$VSPHEREVERSION
    cp -rf /mnt/iso/* vcsa-extracted/$VSPHEREVERSION
    umount /mnt/iso
	ln -s ./vcsa-extracted/$VSPHEREVERSION/vcsa/ovftool/lin64/ovftool /usr/bin/ovftool

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
	pip3 install setuptools --log /var/log/pip_install_setuptools.log
	pip3 install wheel --log /var/log/pip_install_wheel.log
	pip3 install dcli --log /var/log/pip_install_dcli.log
	pip3 install flent --log /var/log/pip_install_flent.log

	# install vsphere-automation-sdk for python
	pip3 install git+https://github.com/vmware/vsphere-automation-sdk-python.git

	# community samples package for pyvmomi
	pip3 install git+https://github.com/vmware/pyvmomi-community-samples.git

	chmod 700 $ESXCLIFILE
	expect/installesxcli.sh

	# this is just here for troubleshooting
	dcli --version &>> /var/log/configure_l0_packages_6.log

exit 0

