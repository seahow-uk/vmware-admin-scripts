#!/bin/bash -x

. $ESXIROOT/bash/configure_l0_env.sh

## this needs to run under the special dcli 3.6 venv
## because the python script needs the vsphere automation sdk
source $ESXIROOT/dcli_venv/bin/activate

for ((i = 1; i <= 2; i++)); do

    echo "creating dvswitch on vcsa$i.$DNSDOMAIN..."
    python3 $ESXIROOT/python/create-dvs.py -s vcsa$i.$DNSDOMAIN -u $SSOACCOUNT@lab$i.local -p $SSOPASSWORD

done

# kill the old vswitch0 on the workload hosts

for ((i = 2; i <= 5; i++)); do
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli network vswitch standard remove -v vSwitch0"
done

for ((i = 7; i <= 10; i++)); do
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli network vswitch standard remove -v vSwitch0"
done

## leave the 3.6 venv
deactivate