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
HOSTPASSWORD=
SSOPASSWORD=

# here is an example:
#
#% DNSIPADDRESS1=10.0.0.111
#% DNSIPADDRESS2=10.0.0.74
#% VCSAISO=/scripts/vmware-admin-scripts/esxi-on-kvm/ISO/vcsa/VMware-VCSA-all-8.0.0-20920323.iso
#% VSPHEREVERSION=8.0
#% DNSDOMAIN=example.local
#% ADPASSWORD=Aws2022@
#% ADUSER=admin@EXAMPLE.LOCAL
#% HOSTPASSWORD="VMware1!"
#% SSOPASSWORD="Aws2022@"

## These variables tune the size of the ESXi hosts that get deployed
## The default represents the practical minimum.  
## In aggregate, there are 10 ESXi hosts, 2 of which
## are management hosts.  Both management hosts house a VCSA of size "small", which is 24GB RAM in 8.0
##
## You want a little bit of overhead on those hosts, hence 28GB is a good minimum for those two.
## 16GB for each of the 8x Compute hosts is a good amount considering all of the sample and storage VMs
## that get deployed by the later parts of these scripts
##
## In total, the default will require the following physical resources on the server for the KVM domains
##
## Memory: 152GB
## Cores: 24
## 
## [Due to the way I've got various services running on L0 you should leave a decent amount of cpu cores and ram free]
##
## This means the default settings below will run on a c5n.metal host in AWS, which has 72 vcpu and 192GB RAM
## c5n.metal is the cheapest x86_64 baremetal instance type at $3.88/hour or $2838.24/month (on demand) 
##
## Personally, I recommend an m5zn.metal.  Only 24 real / 48 HT VCPU but they are 4.5GHz Xeon 8252's vs 3GHz 8124M's
## m5zn.metal is almost as cheap as c5n.metal at $3.96/hour or $2893.79/month (on demand)
##

MEM=12
CORE=2
MGMTMEM=28
MGMTCORE=4

## All that said, if you don't care as much about cost and need bigger/faster ESXi hosts, I would recommend
## an r6i.metal with 128 VCPU and 1024 GB memory.  They have even newer 3.5 GHz Intel Xeon 8375C (Ice Lake) cpus
## Cost goes up significantly, though.  r6i.metal costs $8.06/hour or $5886.72/month (on demand)
##
## With an r6i.metal, you could raise these parameters to something like the following:
##
## MEM=64
## CORE=8
## MGMTMEM=96
## MGMTCORE=12
##
## It might make more sense at that point to just raise the number of total nested hosts from 10 to 20 or something
## Unfortunately, as of Jan 2023, you will have to hack the scripts especially the python ones that configure the 
## vsphere clusters.  There are hard coded spots in there.  Maybe I will change this in time.
##
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

if [[ $HOSTPASSWORD == "" ]]; then
  echo "You didnt specify the host password"
  exit 1
fi

if [[ $SSOPASSWORD == "" ]]; then
  echo "You didnt specify the sso password"
  exit 1
fi

if [[ $ADPASSWORD == "" ]]; then
  echo "You didnt specify the ad password"
  exit 1
fi

if [[ $ADUSER == "" ]]; then
  echo "You didnt specify the ad user"
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
echo "export SSOPASSWORD=$SSOPASSWORD" >> $ESXIROOT/bash/configure_l0_env.sh
echo "export HOSTPASSWORD=$HOSTPASSWORD" >> $ESXIROOT/bash/configure_l0_env.sh
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

rm -rfv /etc/profile.d/configure_l0_env.sh
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

    ## install an xfce desktop and tigervnc-server environment
      $ESXIROOT/bash/configure_l0_desktop.sh --r root --p $ADPASSWORD &>> /var/log/configure_l0_desktop.sh.log
exit 0
