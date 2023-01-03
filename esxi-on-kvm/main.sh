#!/bin/bash

## usage:
##
## ./bash/main.sh <dns server ip 1> <dns server ip 2>
##
## NOTE: you MUST run this as root
## errata: there are a couple places where it assumes the primary network interface is called eth0
##

# VARIABLES YOU MUST SET -- this whole thing will break if you dont set these
# You will need to download the ISOs for the VCSA appliance you want to use and point VCSAISO to it
# You will need to set the vsphere version.  It can only be 7.0 or 6.7.  Other values will break things.
# You must set the DNS parameters
# The AD user and password is needed to insert appropriate DNS records into your environment.  
# oddly enough, the way kinit works you have to capitalize the domain name in the ADUSER variable
#
DNSIPADDRESS1=
DNSIPADDRESS2=
VCSAISO=
VSPHEREVERSION=
DNSDOMAIN=
ADPASSWORD=
ADUSER=

# here is an example:
#
#% DNSIPADDRESS1=10.0.0.111
#% DNSIPADDRESS2=10.0.0.74
#% VCSAISO=/scripts/vmware-admin-scripts/esxi-on-kvm/ISO/vcsa/VMware-VCSA-all-8.0.0-20920323
#% VSPHEREVERSION=8.0
#% DNSDOMAIN=example.local
#% ADPASSWORD=Aws2022@
#% ADUSER=admin@EXAMPLE.LOCAL

## These variables tune the size of the ESXi hosts that get deployed
## The default represents the practical minimum.  In aggregate, there are 10 ESXi hosts, 2 of which
## are management hosts.  so the default will require the following physical resources on the server
## Memory: 168GB
## Cores: 40
## This means the default settings below will run on a c5n.metal host in AWS, which has 72 vcpu and 192GB RAM
## Personally, I recommend an m5zn.metal.  It drops to 48CPU but they run at 4.5GHz vs 3GHz for c5n
## These defaults fit perfectly in an m5zn.metal.

MEM=16
CORE=4
MGMTMEM=20
MGMTCORE=4

# NOTE: There are more variables you can alter inside configure_l0_env.sh

if [[ $DNSIPADDRESS1 == "" ]]; then
  echo "You didnt supply DNS server 1"
  exit 1
fi

if [[ $DNSIPADDRESS2 == "" ]]; then
  echo "You didnt supply DNS server 2"
  exit 1
fi

if [[ $VCSAISO == "" ]]; then
  echo "You didnt supply a path to the VCSA ISO"
  exit 1
fi

if [[ $VSPHEREVERSION == "" ]]; then
  echo "You didnt specify the vsphere version"
  exit 1
fi

if [[ $DNSDOMAIN == "" ]]; then
  echo "You didnt specify the DNS domain"
  exit 1
fi

if [[ "$(whoami)" != root ]]; then
  echo "Only user root can run this script."
  exit 1
fi

## this inserts the exports into configure_l0_env.sh which is sourced elsewhere
## long story short, it makes them permanent in case you need to just re-run subcomponents
## yes its a hack that was added later

export ESXIROOT="$PWD"

echo "export MEM=$MEM" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export CORE=$CORE" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export MGMTMEM=$MGMTMEM" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export MGMTCORE=$MGMTCORE" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export DNSIPADDRESS1=$DNSIPADDRESS1" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export DNSIPADDRESS2=$DNSIPADDRESS2" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export VCSAISO=$VCSAISO" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export VSPHEREVERSION=$VSPHEREVERSION" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export DNSDOMAIN=$DNSDOMAIN" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export ADPASSWORD=$ADPASSWORD" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export ADUSER=$ADUSER" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export OVFTOOLPATH=vcsa-extracted/$VSPHEREVERSION/vcsa/ovftool/lin64" >> $ESXIROOT/bash/configure_l0_env.sh 
echo "export PATH=$PATH:/usr/local/share/openvswitch/scripts:$PWD/bash:$PWD/python:$PWD/expect" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export ESXIROOT=$PWD" >> $ESXIROOT/bash/configure_l0_env.sh

## make sure cloud-init doesnt run anymore at boot
touch /etc/cloud/cloud-init.disabled

## ok we've now made configure_l0_env.sh a central store for all env vars
## we need to source it once so it is available to subcomponents of this script run

. $ESXIROOT/bash/configure_l0_env.sh &>> /var/log/configure_l0_env.sh.log

## now lets copy it to /etc/profile.d so future interactive root sessions can
## just run the individual pieces below for troubleshooting

cp $ESXIROOT/bash/configure_l0_env.sh /etc/profile.d/configure_l0_env.sh
chmod 644 /etc/profile.d/configure_l0_env.sh

## ********** START CALL OUTS TO OTHER BASH SCRIPTS ********** 

    ## install dnf packages, do some other l0 system config needed for nested vmware
      $ESXIROOT/bash/configure_l0_packages.sh &>> /var/log/configure_l0_packages.sh.log

    ## configure libvirt, QEMU, KVM
      $ESXIROOT/bash/configure_libvirt.sh &>> /var/log/configure_libvirt.sh.log

    ## configure openvswitch, routing, VLANs
      $ESXIROOT/bash/configure_ovs.sh &>> /var/log/configure_ovs.sh.log

    ## insert DNS records into your AD-based DNS
      $ESXIROOT/bash/insertdnsrecords.sh &>> /var/log/insertdnsrecords.sh.log

exit 0
