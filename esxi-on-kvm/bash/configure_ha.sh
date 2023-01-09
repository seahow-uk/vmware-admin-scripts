#!/bin/bash -x

## this needs to run under a 3.6 venv
source $ESXIROOT/dcli_venv/bin/activate

# for each vcenter/lab environment, configure ha on the compute cluster

for ((i = 1; i <= 2; i++)); do

    echo "configuring ha on vcsa$i.$DNSDOMAIN..."
    python3 $ESXIROOT/python/configure_ha.py -p $SSOPASSWORD -r $HOSTPASSWORD -i $i -d $DNSDOMAIN

done


## leave the 3.6 venv
deactivate