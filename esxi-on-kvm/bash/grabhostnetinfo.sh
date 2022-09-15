#!/bin/bash



# build our global variables
    STARTHOST=1
    ENDHOST=$ESXHOSTCOUNT

# grab the entire net config of each host and post to log

  for ((i=$STARTHOST; i<=$ENDHOST; i++)) 
  do
    sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "vim-cmd hostsvc/net/info" &>> /var/log/esxi-host-net-info.log
  done

exit 0