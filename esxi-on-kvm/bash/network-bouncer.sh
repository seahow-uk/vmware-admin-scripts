#!/bin/bash

FILE=./config/firstrebootcomplete
NEWMAC=$(ec2-metadata --mac)
OLDMAC=$(cat /etc/sysconfig/network-scripts/ifcfg-ovs-uplink | grep HWADDR | awk -F= '{ print $2 }')

NEWMACCAPS=$(echo $NEWMAC | tr [:lower:] [:upper:])
NEWMACCLEAN1=$(echo $NEWMACCAPS | sed 's/://g')
NEWMACCLEANED=$(echo $NEWMACCLEAN1 | sed 's/://g')

OLDMACCAPS=$(echo $OLDMAC | tr [:lower:] [:upper:])
OLDMACCLEAN1=$(echo $OLDMACCAPS | sed 's/://g')
OLDMACCLEANED=$(echo $OLDMACCLEAN1 | sed 's/://g')

if [ ! -f "$FILE" ]; then

    echo "this must be the first boot because $FILE does not exist"
    echo "therefore we do nothing"

else

    if [[ "$NEWMACCLEANED" == "$OLDMACCLEANED" ]]; then

        echo "ok this is not the first boot, BUT the MAC has not changed on us, so we do nothing"

    else

        echo "woop woop 2nd or later boot AND MAC has changed, presumably from a deployment of some kind"

        ETH0MAC=$(ifconfig -a | grep -m1 eth0 -A3 | grep ether | awk '/ether / {print $2}')
        ETH0IP=$(ifconfig eth0 | awk '/inet / {print $2}')
        ETH0NETMASK=$(ifconfig -a | grep -m1 eth0 -A2 | grep netmask | awk '{print $4}')
        ETH0GATEWAY=$(ip route | grep -m1 default | awk '{print $3}')
        ETH0PREFIX=$(ipcalc $ETH0IP $ETH0NETMASK -p | awk -F = '{print $2}')
        ETH0NETWORK=$(ipcalc $ETH0IP $ETH0NETMASK -n | awk -F = '{print $2}')

        rm -f /etc/sysconfig/network-scripts/route-ovs-uplink
        cp -f ./config/route-ovs-uplink /etc/sysconfig/network-scripts/route-ovs-uplink
        sed -i "s/ETH0GATEWAYPLACEHOLDER/$ETH0GATEWAY/g" /etc/sysconfig/network-scripts/route-ovs-uplink

        rm -f /etc/sysconfig/network-scripts/ifcfg-ovs-uplink
        cp ./config/ifcfg-ovs-uplink /etc/sysconfig/network-scripts/ifcfg-ovs-uplink
        sed -i "s/ETH0MACPLACEHOLDER/$ETH0MAC/g" /etc/sysconfig/network-scripts/ifcfg-ovs-uplink
        sed -i "s/ETH0IPPLACEHOLDER/$ETH0IP/g" /etc/sysconfig/network-scripts/ifcfg-ovs-uplink
        sed -i "s/ETH0NETMASKPLACEHOLDER/$ETH0NETMASK/g" /etc/sysconfig/network-scripts/ifcfg-ovs-uplink
        sed -i "s/ETH0GATEWAYPLACEHOLDER/$ETH0GATEWAY/g" /etc/sysconfig/network-scripts/ifcfg-ovs-uplink
    fi
fi
