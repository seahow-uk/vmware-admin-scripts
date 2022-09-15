#!/bin/bash



# for each vcenter/lab environment, configure ha on the compute cluster

for ((i = 1; i <= 2; i++)); do

    echo "configuring ha on vcsa$i.$DNSDOMAIN..."
    python3 ./python/configure_ha.py -p $SSOPASSWORD -r $HOSTPASSWORD -i $i -d $DNSDOMAIN

done
