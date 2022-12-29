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

## repo stuff
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
	dnf install byacc cmake dhcp-server expect gcc gdisk httpd iftop iotop ipcalc kernel-devel libnfsidmap libnsl libvirt-devel lvm2 maven mlocate netpbm nfs4-acl-tools nfs-utils nload numactl nvme-cli parallel polkit python39* samba sshpass sysfsutils unbound unzip wget sshpass -y -q &>> /var/log/configure_l0_packages_1.log

## update-alternatives for python
	update-alternatives --set python3 /usr/bin/python3.9
	update-alternatives --set python /usr/bin/python2

## libvirt install via package groups 
	dnf module disable virt -y &>> /var/log/userdata.log
	dnf groupinstall "Virtualization Host" --with-optional -y -q &>> /var/log/configure_l0_packages_2.log
	dnf install virt* libguestfs* swtpm* -y -q &>> /var/log/configure_l0_packages_3.log

## OVS install
	dnf install openvswitch libibverbs os-net-config vnstat -y -q &>> /var/log/configure_l0_packages_4.log
	systemctl enable vnstat
	systemctl start vnstat

## install various tool packages for troubleshooting
	# dnf group install "Networking Tools" --with-optional -y
	# dnf group install "Hardware Monitoring Utilities" --with-optional -y
	# dnf group install "Large Systems Performance" --with-optional -y
	# dnf group install "Performance Tools" --with-optional -y
	# dnf group install "System Tools" --with-optional -y

## Shuffle config files needed for Kickstart, etc
	mv -fv ./config/exports /etc/exports
	mv -fv ./config/smb.conf /etc/samba/smb.conf
	cp -f ./bash/treesize.sh /bin/treesize
	cp -f ./config/KS.CFG /var/www/html/KS.CFG
	cp -f ./bash/epochtohuman.sh ./bash/epochtohuman.sh

## Kickstart samba
	systemctl enable smb nmb
	systemctl start smb nmb

## configure host profile
	tuned-adm profile virtual-host &>> /var/log/configure_l0_packages_5

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
    mkdir -p vcsa-extracted/$VSPHEREVERSION
    cp -rf /mnt/iso/* vcsa-extracted/$VSPHEREVERSION
    umount /mnt/iso
	ln -s ./vcsa-extracted/$VSPHEREVERSION/vcsa/ovftool/lin64/ovftool /usr/bin/ovftool

  ## Permissions tweaks for the aforementioned config files
    chown -R root:nobody * 
    chmod -R 777 /bin/treesize
    chmod -R 744 *

	pip install pyvim --log /var/log/pip_install_pyvim.log
	pip install requests --log /var/log/pip_install_requests.log
	pip install vcrpy --log /var/log/pip_install_vrcpy.log
	pip install pyvmomi --log /var/log/pip_install_pyvmomi.log
	pip install suds-jurko --log /var/log/pip_install_suds-jurko.log
	pip install lxml --log /var/log/pip_install_lxml.log
	pip install ipaddress --log /var/log/pip_install_ipaddress.log
	pip install setuptools --log /var/log/pip_install_setuptools.log
	pip install wheel --log /var/log/pip_install_wheel.log
	pip install dcli --log /var/log/pip_install_dcli.log
	pip install flent --log /var/log/pip_install_flent.log

	# install vsphere-automation-sdk for python
	pip install git+https://github.com/vmware/vsphere-automation-sdk-python.git

	# community samples package for pyvmomi
	pip install git+https://github.com/vmware/pyvmomi-community-samples.git

	chmod 700 data/$ESXCLIFILE
	expect/installesxcli.sh

	# this is just here for troubleshooting
	dcli --version &>> /var/log/configure_l0_packages_6

exit 0

