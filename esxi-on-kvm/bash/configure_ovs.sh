#!/bin/bash

    ## destroy the virbr0 libvirt creates by default
	virsh net-undefine default
	virsh net-destroy default

    ## delete the ens files
    rm -rfv /etc/sysconfig/network-scripts/ifcfg-ens*

    ## disable networkmanager AND enact workaround from https://github.com/systemd/systemd/issues/3374
    systemctl disable NetworkManager
    systemctl stop NetworkManager
    mkdir -p /etc/systemd/network
    cp /usr/lib/systemd/network/99-default.link /etc/systemd/network/99-default.link
    dnf install network-scripts -y
    systemctl enable network
    systemctl restart network
    
    ETH0MAC=$(ifconfig -a | grep -m1 eth0 -A3 | grep ether | awk '/ether / {print $2}')
    ETH0IP=$(ifconfig eth0 | awk '/inet / {print $2}')
    ETH0NETMASK=$(ifconfig -a | grep -m1 eth0 -A2 | grep netmask | awk '{print $4}')
    ETH0GATEWAY=$(ip route | grep -m1 default | awk '{print $3}')
    ETH0PREFIX=$(ipcalc $ETH0IP $ETH0NETMASK -p | awk -F = '{print $2}')
    ETH0NETWORK=$(ipcalc $ETH0IP $ETH0NETMASK -n | awk -F = '{print $2}')

    echo "ETH0MAC=$ETH0MAC"
    echo "ETH0IP=$ETH0IP"
    echo "ETH0NETMASK=$ETH0NETMASK"
    echo "ETH0GATEWAY=$ETH0GATEWAY"
    echo "ETH0PREFIX=$ETH0PREFIX"
    echo "ETH0NETWORK=$ETH0NETWORK"

    sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/g' /etc/libvirt/libvirtd.conf
    sed -i 's/#unix_sock_ro_perms = "0777"/unix_sock_ro_perms = "0777"/g' /etc/libvirt/libvirtd.conf
    sed -i 's/#unix_sock_rw_perms = "0777"/unix_sock_rw_perms = "0777"/g' /etc/libvirt/libvirtd.conf
    sed -i 's/#unix_sock_admin_perms = "0700"/unix_sock_admin_perms = "0777"/g' /etc/libvirt/libvirtd.conf

    ## Add in ifcfg files

    cp -f $ESXIROOT/config/ifcfg-ovs-br0 /etc/sysconfig/network-scripts/
    cp -f $ESXIROOT/config/ifcfg-ovs-vlan20 /etc/sysconfig/network-scripts/
    cp -f $ESXIROOT/config/ifcfg-ovs-vlan30 /etc/sysconfig/network-scripts/
    cp -f $ESXIROOT/config/ifcfg-ovs-vlan40 /etc/sysconfig/network-scripts/
    cp -f $ESXIROOT/config/ifcfg-ovs-vlan50 /etc/sysconfig/network-scripts/
    cp -f $ESXIROOT/config/ifcfg-ovs-vlan60 /etc/sysconfig/network-scripts/
    cp -f $ESXIROOT/config/ifcfg-ovs-vlan70 /etc/sysconfig/network-scripts/
    cp -f $ESXIROOT/config/ifcfg-ovs-vlan80 /etc/sysconfig/network-scripts/

    # add in routing placeholder so connection to metadata isnt lost

    cp -f $ESXIROOT/config/route-ovs-uplink /etc/sysconfig/network-scripts/
    sed -i "s/ETH0GATEWAYPLACEHOLDER/$ETH0GATEWAY/g" /etc/sysconfig/network-scripts/route-ovs-uplink
    echo 'GATEWAYDEV=ovs-uplink' >>/etc/sysconfig/network

    ## ifcfg-ovs-uplink.

    sed -i "s/ETH0MACPLACEHOLDER/$ETH0MAC/g" $ESXIROOT/config/ifcfg-ovs-uplink
    sed -i "s/ETH0IPPLACEHOLDER/$ETH0IP/g" $ESXIROOT/config/ifcfg-ovs-uplink
    sed -i "s/ETH0NETMASKPLACEHOLDER/$ETH0NETMASK/g" $ESXIROOT/config/ifcfg-ovs-uplink
    sed -i "s/ETH0GATEWAYPLACEHOLDER/$ETH0GATEWAY/g" $ESXIROOT/config/ifcfg-ovs-uplink
    cp $ESXIROOT/config/ifcfg-ovs-uplink /etc/sysconfig/network-scripts/ifcfg-ovs-uplink

    # ## Network files need to be tuned up before moving them to /etc/sysconfig/network-scripts

    mv /etc/sysconfig/network-scripts/ifcfg-eth0 $ESXIROOT/config/ifcfg-eth0.original
    cp $ESXIROOT/config/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0

    # ## General OVS / network config files

    cp $ESXIROOT/config/ifcfg-ovs-br0 /etc/sysconfig/network-scripts/
    systemctl stop firewalld
    systemctl disable firewalld

    systemctl stop dhcpd

    sed -i "s/DNSDOMAINPLACEHOLDER/$DNSDOMAIN/g" $ESXIROOT/config/dhcpd.conf
    sed -i "s/DNS1PLACEHOLDER/$DNSIPADDRESS1/g" $ESXIROOT/config/dhcpd.conf
    sed -i "s/DNS2PLACEHOLDER/$DNSIPADDRESS2/g" $ESXIROOT/config/dhcpd.conf

    mv /etc/dhcp/dhcpd.conf $ESXIROOT/data/dhcpd.conf.old
    cp $ESXIROOT/config/dhcpd.conf /etc/dhcp/dhcpd.conf
    chmod 664 /etc/dhcp/dhcpd.conf

    ## initialize ovs db and service

    systemctl enable openvswitch
    systemctl start openvswitch
    ovs-vsctl add-br ovs-br0
    /etc/sysconfig/network-scripts/ifdown ifcfg-eth0
    systemctl restart network

    ## turn on network services

    systemctl enable nfs-server
    systemctl enable nfsdcld
    systemctl enable rpcbind
    systemctl enable httpd
    systemctl enable dhcpd
    systemctl enable chronyd
    systemctl enable smb
    systemctl enable nmb
    systemctl start httpd
    systemctl start chronyd
    systemctl start nfs-server
    systemctl start rpcbind
    systemctl start dhcpd
    systemctl start smb
    systemctl start nmb
    systemctl start nfsdcld

    ## diagnostic info in case dhcpd startup fails (it is strangely fragile)
    #systemctl status dhcpd.service
    #cat /etc/dhcp/dhcpd.conf
    #echo "-----"
    #echo "running command: journalctl -xe"
    #journalctl -xe

    systemctl restart httpd
    systemctl restart libvirtd

exit 0
