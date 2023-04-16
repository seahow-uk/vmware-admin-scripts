#!/bin/bash -x

## this needs to run under the special dcli 3.6 venv
## because dcli is directly run here
source $ESXIROOT/dcli_venv/bin/activate

# variables
  STARTHOST=1
  ENDHOST=$ESXHOSTCOUNT

# make a log of the network situation of the esxi hosts
  $ESXIROOT/bash/grabhostnetinfo.sh 

# detach cdroms
  for ((i = $STARTHOST; i <= $ENDHOST; i++)); do
    virsh attach-disk esxi$i "" hdc --type cdrom --mode readonly
  done

# fix the vmkernels and do some other post-hoc tweaks we've identified

  dcli +server vcsa1.$DNSDOMAIN +skip-server-verification com vmware appliance ntp set --servers $DNSIPADDRESS1

  for ((i = 2; i <= 5; i++)); do
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli vsan network ip add -i vmk1"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vswitch -m 9000 compute-dvs"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli network ip interface set -i vmk1 -m 9000"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli network ip interface set -i vmk2 -m 9000"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli network ip interface set -i vmk3 -m 9000"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli network ip interface set -i vmk4 -m 9000"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi software set --enabled=true"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi adapter set --adapter=vmhba65 --name='iqn.1998-01.com.vmware:esxi$i'"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi adapter set --adapter=vmhba65 --alias='esxi$i.$DNSDOMAIN'"

    # bind to vmk2 and vmk3
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi networkportal add --adapter vmhba65 --nic vmk2 --force=true"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi networkportal add --adapter vmhba65 --nic vmk3 --force=true"
    # sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi networkportal ipconfig set --adapter vmhba65 --nic vmk2 --enable-dhcpv4 true"
    # sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi networkportal ipconfig set --adapter vmhba65 --nic vmk3 --enable-dhcpv4 true"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi adapter discovery sendtarget add -A vmhba65 -a 192.168.70.70:3260"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi adapter discovery sendtarget add -A vmhba65 -a 192.168.80.70:3260"
  done

  dcli +server vcsa2.$DNSDOMAIN +skip-server-verification com vmware appliance ntp set --servers $DNSIPADDRESS1

  for ((i = 7; i <= 10; i++)); do
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli vsan network ip add -i vmk1"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vswitch -m 9000 compute-dvs"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli network ip interface set -i vmk1 -m 9000"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli network ip interface set -i vmk2 -m 9000"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli network ip interface set -i vmk3 -m 9000"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli network ip interface set -i vmk4 -m 9000"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi software set --enabled=true"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi adapter set --adapter=vmhba65 --name='iqn.1998-01.com.vmware:esxi$i'"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi adapter set --adapter=vmhba65 --alias='esxi$i.$DNSDOMAIN'"

    # bind to vmk2 and vmk3
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi networkportal add --adapter vmhba65 --nic vmk2 --force=true"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi networkportal add --adapter vmhba65 --nic vmk3 --force=true"
    # sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi networkportal ipconfig set --adapter vmhba65 --nic vmk2 --enable-dhcpv4 true"
    # sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi networkportal ipconfig set --adapter vmhba65 --nic vmk3 --enable-dhcpv4 true"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi adapter discovery sendtarget add -A vmhba65 -a 192.168.70.70:3260"
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli iscsi adapter discovery sendtarget add -A vmhba65 -a 192.168.80.70:3260"
  done



## leave the 3.6 venv
deactivate

exit 0
