#!/bin/bash 

# build our global variables
    STARTHOST=1
    ENDHOST=$ESXHOSTCOUNT
    ETH0IP=`ifconfig eth0 | awk '/inet / {print $2}'`

    mkdir -p $ESXIROOT/data/esxi-screenshots/kvm-config
	mkdir -p $ESXIROOT/data/esxi-screenshots/postboot
	mkdir -p $ESXIROOT/data/esxi-screenshots/postbuild

# define our functions
    timestamp() {
        date +"%H-%M-%S" # current time
    }

# build the directories if they aint there and create the initial screenshots
    for ((i=$STARTHOST; i<=$ENDHOST; i++)) 
    do
        mkdir -p $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working
        virsh screenshot esxi$i $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/esxi$i.ppm
    done

# now loop over all x number of screenshots and tack on the external data points we want
    for ((i=$STARTHOST; i<=$ENDHOST; i++)) 
    do
        PINGRESULTFROMVLAN20=$(ping -c 1 -s 1470 -S 192.168.20.1 esxi$i > /dev/null && echo "ALIVE" || echo "DEAD")
        ARPGREPPED=$(arp -a | grep esxi$i -m 1 | awk '{print $4}' | tr [:lower:] [:upper:])
        DHCPCONTENTRAW=$(cat /etc/dhcp/dhcpd.conf | grep esxi$i-vmnic0 -A4 | grep hardware | awk '{print $3}' )
        DHCPCONTENT=$(echo $DHCPCONTENTRAW | sed s/\;//g)
        ESXCFGNICSLIST=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-nics -l" | grep vmnic0 | awk '{print $7}' | tr [:lower:] [:upper:])
        VMKNIC0MAC=$(virsh domiflist esxi$i | grep vmnic0  | awk '{print $5}' | tr [:lower:] [:upper:])
        NOW=$(timestamp)
        ESXHOSTIPLISTRAW=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcli network ip interface ipv4 address list | grep vmk0")
        ESXHOSTIPLIST=$(echo "$ESXHOSTIPLISTRAW" | tr [:lower:] [:upper:])
        MY_THUMBPRINT=`echo -n | openssl s_client -connect esxi$i.$DNSDOMAIN:443 2>/dev/null | openssl x509 -noout -fingerprint -sha1 | awk -F= '{ print $2 }'`

        # Grab MAC addresses of all VMKs
        VMK0MAC=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk0 | awk '{print $7}' | tr [:lower:] [:upper:])
        VMK1MAC=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk1 | awk '{print $7}' | tr [:lower:] [:upper:])
        VMK2MAC=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk2 | awk '{print $7}' | tr [:lower:] [:upper:])
        VMK3MAC=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk3 | awk '{print $7}' | tr [:lower:] [:upper:])
        VMK4MAC=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk4 | awk '{print $7}' | tr [:lower:] [:upper:])

        # Grab IPs of all VMKs
        VMK0IP=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk0 | awk '{print $4}' | tr [:lower:] [:upper:])
        VMK1IP=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk1 | awk '{print $4}' | tr [:lower:] [:upper:])
        VMK2IP=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk2 | awk '{print $4}' | tr [:lower:] [:upper:])
        VMK3IP=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk3 | awk '{print $4}' | tr [:lower:] [:upper:])  
        VMK4IP=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk4 | awk '{print $4}' | tr [:lower:] [:upper:])

        # Grab the DVS Port ID of all VMKs
        VMK0PORT=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk0 | awk '{print $2}' | tr [:lower:] [:upper:])
        VMK1PORT=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk1 | awk '{print $2}' | tr [:lower:] [:upper:])
        VMK2PORT=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk2 | awk '{print $2}' | tr [:lower:] [:upper:])
        VMK3PORT=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk3 | awk '{print $2}' | tr [:lower:] [:upper:])
        VMK4PORT=$(sshpass -p "$HOSTPASSWORD" ssh "esxi$i" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "esxcfg-vmknic -l" | grep vmk4 | awk '{print $2}' | tr [:lower:] [:upper:])

        printf '%s\n' "VMKernel info (esxcli):" \
        "VMK0 - MAC: $VMK0MAC  IP: $VMK0IP  PORT: $VMK0PORT" \
        "VMK1 - MAC: $VMK1MAC  IP: $VMK1IP  PORT: $VMK1PORT" \
        "VMK2 - MAC: $VMK2MAC  IP: $VMK2IP  PORT: $VMK2PORT" \
        "VMK3 - MAC: $VMK3MAC  IP: $VMK3IP  PORT: $VMK3PORT" \        
        "VMK4 - MAC: $VMK4MAC  IP: $VMK4IP  PORT: $VMK4PORT" >$ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/outputfilevmks

        printf '%s\n' "L0's Perspective:" \
        "ping result source 20.1: $PINGRESULTFROMVLAN20" \
        "MAC from arp   : $ARPGREPPED" \
        "MAC from dhcpd : $DHCPCONTENT" \
        "MAC from virsh  : $VMKNIC0MAC"  >$ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/outputfilehost

        printf '%s\n' "ESXI$i's perspective:" \
        "VMK0 MAC (esxcfg): $ESXCFGNICSLIST" >$ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/outputfileesx

        ppmlabel -size 12 -x 290 -y 50 -color green -background black -file $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/outputfilehost $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/esxi$i.ppm > $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/esxi$i-a.ppm
        ppmlabel -size 12 -x 290 -y 180 -color red -background black -file $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/outputfileesx $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/esxi$i-a.ppm > $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/esxi$i-b.ppm
        ppmlabel -size 12 -x 290 -y 230 -color yellow -background black -file $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/outputfilevmks $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/esxi$i-b.ppm > $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/esxi$i-c.ppm
        cp $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/esxi$i-c.ppm $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/$NOW.ppm

        # rm -f $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/outputfilehost $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/outputfileesx
        # rm -f $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/esxi$i.ppm $ESXIROOT/data/esxi-screenshots/postbuild/esxi$i/working/esxi$i-a.ppm
    done    