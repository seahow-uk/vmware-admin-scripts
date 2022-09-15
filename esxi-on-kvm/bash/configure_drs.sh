#!/bin/bash



# for each vcenter/lab environment, configure DRS on the compute cluster

for ((i = 1; i <= 2; i++)); do

    echo "configuring drs on vcsa$i.$DNSDOMAIN..."
    python3 ./python/configure_drs.py -p $SSOPASSWORD -r $HOSTPASSWORD -i $i -d $DNSDOMAIN

done
