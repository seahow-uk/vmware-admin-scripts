#!/bin/bash

## variables
STARTHOST=1
ENDHOST=$ESXHOSTCOUNT

# kill existing vms

for ((i = $STARTHOST; i <= $ENDHOST; i++)); do
  virsh destroy esxi$i
  virsh undefine esxi$i
  rm -rv ./esxi$i
done

# remove the dhcpd static entries for all esxi hosts
sed -i '55,$ d' /etc/dhcp/dhcpd.conf

# destroy the ovs network definitions in libvirtd
virsh net-destroy ovs-net
virsh net-undefine ovs-net

# kill network stuff in the right order
systemctl stop libvirtd
systemctl stop httpd
systemctl stop dhcpd
systemctl start ovs-vswitchd
systemctl start ovsdb-server
systemctl start network

# start network stuff in the right order
systemctl start network
systemctl start ovsdb-server
systemctl start ovs-vswitchd
systemctl start dhcpd
systemctl start httpd
systemctl start libvirtd

echo "done"

exit 0
