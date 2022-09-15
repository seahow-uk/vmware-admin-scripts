#!/bin/bash

# build our global variables
STARTHOST=1
ENDHOST=$ESXHOSTCOUNT

# loop through and soft shutdown all VMs
for ((i = $STARTHOST; i <= $ENDHOST; i++)); do
    PROCESSLIST=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli vm process list" | grep "World ID" | awk '{print $3}')

    for val in $PROCESSLIST; do

        echo "attempting soft shutdown of $val"

        if [[ "$val" != "" ]]; then
            sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli vm process kill -t soft -w $val"
        fi

        ## Now put the host in maintenance mode and shut it down as well
        sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli system maintenanceMode set --enable true"
        sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli system shutdown poweroff -d 10 -r none"
    done

done

# give the cluster a few seconds to chill
sleep 10

# now shutdown L0
shutdown -P now
