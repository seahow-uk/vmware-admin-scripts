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
#% VCSAISO=/scripts/vmware-admin-scripts/esxi-on-kvm/ISO/vcsa/VMware-VCSA-all-7.0.3-20395099.iso
#% VSPHEREVERSION=7.0
#% DNSDOMAIN=example.local
#% ADPASSWORD=Aws2022@
#% ADUSER=admin@EXAMPLE.LOCAL

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

echo "export DNSIPADDRESS1=$DNSIPADDRESS1" >> bash/configure_l0_env.sh
echo "export DNSIPADDRESS2=$DNSIPADDRESS2" >> bash/configure_l0_env.sh
echo "export VCSAISO=$VCSAISO" >> bash/configure_l0_env.sh
echo "export VSPHEREVERSION=$VSPHEREVERSION" >> bash/configure_l0_env.sh
echo "export DNSDOMAIN=$DNSDOMAIN" >> bash/configure_l0_env.sh
echo "export ADPASSWORD=$ADPASSWORD" >> bash/configure_l0_env.sh
echo "export ADUSER=$ADUSER" >> bash/configure_l0_env.sh
echo "export OVFTOOLPATH=vcsa-extracted/$VSPHEREVERSION/vcsa/ovftool/lin64" >> bash/configure_l0_env.sh 

## ok we've now made configure_l0_env.sh a central store for all env vars
## we need to source it once so it is available to subcomponents of this script run

. ./bash/configure_l0_env.sh &>> /var/log/configure_l0_env.sh.log

## now lets copy it to /etc/profile.d so future interactive root sessions can
## just run the individual pieces below for troubleshooting

cp ./bash/configure_l0_env.sh /etc/profile.d/configure_l0_env.sh

## ********** START CALL OUTS TO OTHER BASH SCRIPTS ********** 

    ## install dnf packages, do some other l0 system config needed for nested vmware
      ./bash/configure_l0_packages.sh &>> /var/log/configure_l0_packages.sh.log

    ## insert DNS records into your AD-based DNS
      ./bash/insertdnsrecords.sh &>> /var/log/insertdnsrecords.sh.log

    ## configure libvirt, QEMU, KVM
      ./bash/configure_libvirt.sh &>> /var/log/configure_libvirt.sh.log

    ## configure openvswitch, routing, VLANs
      ./bash/configure_ovs.sh &>> /var/log/configure_ovs.sh.log

    ## build base vmware environment
    #
    #  NOTE: in addition to doing an unattended install of the ESXi hosts,
    #  build.sh calls the following sub-scripts afterward:
    #  
    # ./bash/configure_vcsas.sh 
    # ./bash/configure_cluster.sh 
    # ./bash/configure_dvs.sh 
    # ./bash/configure_drs.sh 
    # ./bash/configure_ha.sh 
      ./bash/build.sh &>>/var/log/build.sh.log

    ## extended tweaks for the esxi hosts, vcsas, etc
      ./bash/configure_esxi.sh &>>/var/log/configure_esxi.log

    ## download bitnami appliances
      ./bash/get_ovas.sh &>>/var/log/get_ovas.sh.log

    ## install bitnami appliances to act as workload VMs
      ./bash/configure_workload_vms.sh &>>/var/log/configure_workload_vms.sh.log

    ## deploy any custom ovfs like netapp, commvault, veeam, generic windows templates
      ./bash/configure_custom_ovfs.sh &>>/var/log/configure_custom_ovfs.sh.log

exit 0
