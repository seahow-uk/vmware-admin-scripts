#!/bin/bash -x

. $ESXIROOT/bash/configure_l0_env.sh

  ## variables
  STARTHOST=1
  ENDHOST=$ESXHOSTCOUNT

  function escapeSlashes {
    sed 's/\//\\\//g'
  }

  ESCAPEDESXIROOT=$(echo "$ESXIROOT" | escapeSlashes)

  ## permissions need to be 770 for root:kvm on esxi and ISO directories
  chown -R root:kvm $ESXIROOT/ISO
  chmod -R 770 $ESXIROOT/ISO

  ## kick the apache server in the pants to make sure the hosts can download
  ## http://192.168.20.1/KS.CFG at build time
  chmod -R 777 $ESXIROOT/webserver
  systemctl restart httpd

  ## prepare the screenshot locations


  ## prep for network

    virsh net-destroy default
    virsh net-undefine default

    virsh net-define XML/ovs-net.xml
    virsh net-autostart ovs-net
    virsh net-start ovs-net

  # Loop through and create specified number of generic esxi hosts using custom kickstart script added to the iso

  for ((i = $STARTHOST; i <= $ENDHOST; i++)); do
    MAC1=$(printf 'DA:AD:BE:EF:%02X:%02X\n' $((RANDOM % 256)) $((RANDOM % 256)))
    MAC2=$(printf 'DA:AD:BE:EF:%02X:%02X\n' $((RANDOM % 256)) $((RANDOM % 256)))
    MAC3=$(printf 'DA:AD:BE:EF:%02X:%02X\n' $((RANDOM % 256)) $((RANDOM % 256)))
    MAC4=$(printf 'DA:AD:BE:EF:%02X:%02X\n' $((RANDOM % 256)) $((RANDOM % 256)))
    MAC5=$(printf 'DA:AD:BE:EF:%02X:%02X\n' $((RANDOM % 256)) $((RANDOM % 256)))
    MAC6=$(printf 'DA:AD:BE:EF:%02X:%02X\n' $((RANDOM % 256)) $((RANDOM % 256)))
    MAC7=$(printf 'DA:AD:BE:EF:%02X:%02X\n' $((RANDOM % 256)) $((RANDOM % 256)))

    MGMTHOSTLIST="1 6"
    let OCTET=200+$i
    let VNCPORT=5910+$i

    ISMGMTHOST=$(echo $MGMTHOSTLIST | grep -wc $i)
    MYDISK="300G"

    if [ "$ISMGMTHOST" == "1" ]; then
      let MYMEM=$MGMTMEM
      let MYCORE=$MGMTCORE
    else
      let MYMEM=$MEM
      let MYCORE=$CORE
    fi

    if [ "$VSPHEREVERSION" == "6.7" ]; then
      VSSVNICMODEL="e1000"
      DVSVNICMODEL="e1000"
    else
      VSSVNICMODEL="e1000e"
      DVSVNICMODEL="e1000e"
    fi

    mkdir -p $ESXIROOT/esxi$i
    chmod -R 770 $ESXIROOT/esxi$i
    chown -R root:kvm $ESXIROOT/esxi$i
    cp -f $ESXIROOT/XML/esxi.xml $ESXIROOT/esxi$i/esxi$i.xml

    qemu-img create -f raw $ESXIROOT/esxi$i/esxi$i-root $MYDISK
    qemu-img convert -O raw $ESXIROOT/esxi$i/esxi$i-root esxi$i/esxi$i-root.raw
    rm $ESXIROOT/esxi$i/esxi$i-root -f

    qemu-img create -f raw $ESXIROOT/esxi$i/esxi$i-disk1 900G
    qemu-img create -f raw $ESXIROOT/esxi$i/esxi$i-disk2 900G
    qemu-img create -f raw $ESXIROOT/esxi$i/esxi$i-disk3 900G
    qemu-img create -f raw $ESXIROOT/esxi$i/esxi$i-disk4 900G

    qemu-img convert -O raw $ESXIROOT/esxi$i/esxi$i-disk1 esxi$i/esxi$i-disk1.raw
    qemu-img convert -O raw $ESXIROOT/esxi$i/esxi$i-disk2 esxi$i/esxi$i-disk2.raw
    qemu-img convert -O raw $ESXIROOT/esxi$i/esxi$i-disk3 esxi$i/esxi$i-disk3.raw
    qemu-img convert -O raw $ESXIROOT/esxi$i/esxi$i-disk4 esxi$i/esxi$i-disk4.raw

    rm $ESXIROOT/esxi$i/esxi$i-disk1 -f
    rm $ESXIROOT/esxi$i/esxi$i-disk2 -f
    rm $ESXIROOT/esxi$i/esxi$i-disk3 -f
    rm $ESXIROOT/esxi$i/esxi$i-disk4 -f

    sed -i "s/ESXIROOTPLACEHOLDER/$ESCAPEDESXIROOT/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/MEMPLACEHOLDER/$MYMEM/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/CPUPLACEHOLDER/$MYCORE/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/NAMEPLACEHOLDER/esxi$i/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/MACPLACEHOLDER1/$MAC1/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/MACPLACEHOLDER2/$MAC2/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/MACPLACEHOLDER3/$MAC3/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/MACPLACEHOLDER4/$MAC4/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/MACPLACEHOLDER5/$MAC5/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/MACPLACEHOLDER6/$MAC6/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/MACPLACEHOLDER7/$MAC7/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/QUEUEPLACEHOLDER/$MYCORE/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/DVSMODELPLACEHOLDER/$DVSVNICMODEL/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/VSSMODELPLACEHOLDER/$VSSVNICMODEL/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/VNCPORTPLACEHOLDER/$VNCPORT/g" $ESXIROOT/esxi$i/esxi$i.xml
    sed -i "s/VSPHEREVERSIONPLACEHOLDER/$VSPHEREVERSION/g" $ESXIROOT/esxi$i/esxi$i.xml

    sed -i "$ a host esxi$i-vmnic0 {" /etc/dhcp/dhcpd.conf
    sed -i "$ a   option host-name \"esxi$i.$DNSDOMAIN\";" /etc/dhcp/dhcpd.conf
    sed -i "$ a   hardware ethernet $MAC1;" /etc/dhcp/dhcpd.conf
    sed -i "$ a   fixed-address 192.168.20.$OCTET;" /etc/dhcp/dhcpd.conf
    sed -i "$ a }" /etc/dhcp/dhcpd.conf

    chmod -R 770 $ESXIROOT/esxi$i
    chown -R root:kvm $ESXIROOT/esxi$i
    virsh define $ESXIROOT/esxi$i/esxi$i.xml

    virsh attach-disk esxi$i $ESXIROOT/esxi$i/esxi$i-disk1.raw sdb --persistent --targetbus sata
    virsh attach-disk esxi$i $ESXIROOT/esxi$i/esxi$i-disk2.raw sdc --persistent --targetbus sata
    virsh attach-disk esxi$i $ESXIROOT/esxi$i/esxi$i-disk3.raw sdd --persistent --targetbus sata
    virsh attach-disk esxi$i $ESXIROOT/esxi$i/esxi$i-disk4.raw sde --persistent --targetbus sata

    chmod -R 770 $ESXIROOT/esxi$i
    chown -R root:kvm $ESXIROOT/esxi$i

    virsh autostart esxi$i
    virsh start esxi$i
  done

  systemctl restart dhcpd
  systemctl restart httpd

  ESXIPID=$(ps -aux | grep -F "guest=esxi$ENDHOST" | grep -Fv "grep" | awk '{ print $2 }')
  ESXISECUP=$(ps -p $ESXIPID -o etimes -h | xargs)
  echo "esxi$ENDHOST's PID: $ESXIPID"
  echo "esxi$ENDHOST's uptime initial: $ESXISECUP"


  ## this is the first boot up where the kickstart install happens.  The process takes just under 300 seconds on an m5zn.metal
  ## to do an unattended install of vsphere 8.0.  I'm setting it to 450 seconds just to be safe.

  while [ $ESXISECUP -le 450 ]; do
    echo "last esxi has only been up $ESXISECUP sec... sleeping 15 seconds"
    sleep 15
    ESXISECUP=$(ps -p $ESXIPID -o etimes -h | xargs)

    ## this script gathers additional information and injects it into the screencaps under $ESXIROOT/data/esxi-screenshots/postbuild
    $ESXIROOT/bash/screencapper.sh &>>/var/log/screencapper.log

    ## this just grabs raw screenshots and puts them under $ESXIROOT/data/esxi-screenshots/kvm-config
    ## I have both happening because the more complicated screencapper.sh script could break and you'd still
    ## at least have basic screenshots here

    for ((j = $STARTHOST; j <= $ENDHOST; j++)); do
      virsh screenshot esxi$j $ESXIROOT/data/esxi-screenshots/kvm-config/esxi$j-$ESXISECUP-seconds.ppm
    done

  done

  ## this is where we reboot them all, and also use ethtool to turn off all fancy offloading features for their nics

  echo "ok we appear to be done defining all the domains in kvm."
  for ((i = $STARTHOST; i <= $ENDHOST; i++)); do
    virsh destroy esxi$i
    virsh start esxi$i
    ethtool -K esxi$i-vmnic0 gso off gro off tx off sg off txvlan off
    ethtool -K esxi$i-vmnic1 gso off gro off tx off sg off txvlan off
    ethtool -K esxi$i-vmnic2 gso off gro off tx off sg off txvlan off
    ethtool -K esxi$i-vmnic3 gso off gro off tx off sg off txvlan off
    ethtool -K esxi$i-vmnic4 gso off gro off tx off sg off txvlan off
    ethtool -K esxi$i-vmnic5 gso off gro off tx off sg off txvlan off
    ethtool -K esxi$i-vmnic6 gso off gro off tx off sg off txvlan off
  done

  ESXI1PID=$(ps -aux | grep -F "guest=esxi1" -m1 | grep -Fv "grep" | awk '{ print $2 }')
  ESXI1MINUP=$(ps -p $ESXI1PID -o etimes -h | xargs)

  echo "esx1's PID: $ESXI1PID"
  echo "esx1's uptime initial: $ESXI1MINUP"

  ## this is the second boot sequence where the postinstall stuff defined in KS.CFG happens
   
 
  while [ $ESXI1MINUP -le 360 ]; do
    echo "esxi1 was only up $ESXI1MINUP sec... sleeping 15 seconds"
    sleep 15
    ESXI1MINUP=$(ps -p $ESXI1PID -o etimes -h | xargs)

    $ESXIROOT/bash/screencapper.sh &>>/var/log/screencapper.log

    for ((j = 1; j <= $ESXHOSTCOUNT; j++)); do
      virsh screenshot esxi$j $ESXIROOT/data/esxi-screenshots/postboot/esxi$j-$ESXI1MINUP-seconds.ppm
    done
  done

  echo "esx1's uptime after stalling: $ESXI1MINUP"

  echo "ok we appear to be ready"

  echo "deploying vcsa appliances..."
  $ESXIROOT/bash/configure_vcsas.sh &>/var/log/configure_vcsas.sh.log

  echo "post-deployment vcsa config..."
  $ESXIROOT/bash/configure_cluster.sh &>/var/log/configure_cluster.sh.log

  echo "create dvses..."
  $ESXIROOT/bash/configure_dvs.sh &>/var/log/configure_dvs.sh.log

  echo "configure vmks and such..."
  $ESXIROOT/bash/configure_esxi.sh &>/var/log/configure_esxi.sh.log

  sed -i '105,$ d' /etc/dhcp/dhcpd.conf

exit 0
