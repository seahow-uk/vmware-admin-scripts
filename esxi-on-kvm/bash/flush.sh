#!/bin/bash

## variables
STARTHOST=1
ENDHOST=$ESXHOSTCOUNT

## delete the screenshots
rm -rv $ESXIROOT/data/esxi-screenshots/kvm-config
rm -rv $ESXIROOT/data/esxi-screenshots/postboot

# kill existing vms

for ((i = $STARTHOST; i <= $ENDHOST; i++)); do
  virsh destroy esxi$i
  virsh undefine esxi$i
  rm -rv $ESXIROOT/esxi$i
done

# remove the dhcpd static entries for all esxi hosts
sed -i '55,$ d' /etc/dhcp/dhcpd.conf

# destroy the ovs network definitions in libvirtd
virsh net-destroy ovs-net
virsh net-undefine ovs-net

echo "done"

exit 0
