#!/bin/bash

## this needs to run under a 3.6 venv
source $ESXIROOT/dcli_venv/bin/activate

let m1=1
let c1=2
let c2=3
let c3=4
let c4=5

for ((i = 1; i <= 2; i++)); do
    VCSAHOST="vcsa$i.$DNSDOMAIN"
    MGMTHOST="esxi$m1.$DNSDOMAIN"
    COMPHOST1="esxi$c1.$DNSDOMAIN"
    COMPHOST2="esxi$c2.$DNSDOMAIN"
    COMPHOST3="esxi$c3.$DNSDOMAIN"
    COMPHOST4="esxi$c4.$DNSDOMAIN"
    MGMTHOSTSHORT="esxi$m1"
    COMPHOST1SHORT="esxi$c1"
    COMPHOST2SHORT="esxi$c2"
    COMPHOST3SHORT="esxi$c3"
    COMPHOST4SHORT="esxi$c4"
    SSODOMAIN="lab$i.local"

    echo "applying tweaks to $VCSAHOST..."

    dcli +credstore-add +server $VCSAHOST +skip +username administrator@$SSODOMAIN +password $SSOPASSWORD com vmware vcenter vm list
    dcli +server $VCSAHOST +skip +username administrator@$SSODOMAIN +password $SSOPASSWORD com vmware appliance access ssh set --enabled true
    dcli +server $VCSAHOST +skip +username administrator@$SSODOMAIN +password $SSOPASSWORD com vmware appliance networking dns domains add --domain $DNSDOMAIN
    dcli +server $VCSAHOST +skip +username administrator@$SSODOMAIN +password $SSOPASSWORD com vmware appliance access consolecli set --enabled true
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "timesync.set --mode host"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "timesync.get"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell ethtool -K eth0 lro off"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell ethtool -K eth0 tso off"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell ethtool -K eth0 gso off"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell ethtool -K eth0 gro off"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell ethtool -K eth0 tx off"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell ethtool -K eth0 rx off"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell echo 'ethtool -K eth0 lro off' >> /sbin/ifup-local"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell echo 'ethtool -K eth0 tso off' >> /sbin/ifup-local"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell echo 'ethtool -K eth0 gso off' >> /sbin/ifup-local"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell echo 'ethtool -K eth0 gro off' >> /sbin/ifup-local"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell echo 'ethtool -K eth0 tx off' >> /sbin/ifup-local"
    sleep 1
    sshpass -p "$HOSTPASSWORD" ssh "$VCSAHOST" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "shell echo 'ethtool -K eth0 rx off' >> /sbin/ifup-local"

    echo "creating clusters within vcsa$i.$DNSDOMAIN..."
    python3 ./python/configure_cluster.py -i $i -d $DNSDOMAIN -r $HOSTPASSWORD -p $SSOPASSWORD

    ## take the compute hosts out of maintenance mode

    echo "taking $COMPHOST1 out of maintenance mode..."
    sshpass -p "$HOSTPASSWORD" ssh "$COMPHOST1" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli system maintenanceMode set --enable false"

    echo "taking $COMPHOST2 out of maintenance mode..."
    sshpass -p "$HOSTPASSWORD" ssh "$COMPHOST2" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli system maintenanceMode set --enable false"

    echo "taking $COMPHOST3 out of maintenance mode..."
    sshpass -p "$HOSTPASSWORD" ssh "$COMPHOST3" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli system maintenanceMode set --enable false"

    echo "taking $COMPHOST4 out of maintenance mode..."
    sshpass -p "$HOSTPASSWORD" ssh "$COMPHOST4" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli system maintenanceMode set --enable false"

    for ((j = 0; j <= 7; j++)); do
        ethtool -K $MGMTHOSTSHORT-vmnic$j gso off gro off tx off sg off txvlan off
        ethtool -K $COMPHOST1SHORT-vmnic$j gso off gro off tx off sg off txvlan off
        ethtool -K $COMPHOST2SHORT-vmnic$j gso off gro off tx off sg off txvlan off
        ethtool -K $COMPHOST3SHORT-vmnic$j gso off gro off tx off sg off txvlan off
        ethtool -K $COMPHOST4SHORT-vmnic$j gso off gro off tx off sg off txvlan off
    done

    echo "^^-------"
    echo $SSODOMAIN
    echo $VCSAHOST
    echo $MGMTHOST
    echo $COMPHOST1
    echo $COMPHOST2
    echo $COMPHOST3
    echo $COMPHOST4

    let m1=m1+5
    let c1=c1+5
    let c2=c2+5
    let c3=c3+5
    let c4=c4+5
done

## leave the 3.6 venv
deactivate