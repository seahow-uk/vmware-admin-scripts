#!/bin/bash

## this needs to run under a 3.6 venv
source $ESXIROOT/dcli_venv/bin/activate

# for each vcenter/lab environment, configure DRS on the compute cluster

for ((i = 1; i <= 2; i++)); do

    echo "configuring drs on vcsa$i.$DNSDOMAIN..."
    python3 $ESXIROOT/python/configure_drs.py -p $SSOPASSWORD -r $HOSTPASSWORD -i $i -d $DNSDOMAIN

done

## leave the 3.6 venv
deactivate