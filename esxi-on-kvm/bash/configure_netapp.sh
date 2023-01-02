#!/bin/bash

# move nics 1 and 2 to their respective iscsi VLANs on the netapp, which is on vcsa 2 thus i=2

echo "configuring fas2040-01a on vcsa2.$DNSDOMAIN..."
python3 $ESXIROOT/python/configure_netapp.py -p $SSOPASSWORD -i 2 -d $DNSDOMAIN

# now force a rescan on the compute cluster hosts of lab 1

for ((i = 2; i <= 5; i++)); do
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli storage core adapter rescan --adapter=vmhba65"
done
