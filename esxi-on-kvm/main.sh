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
#
# here is an example:
#
#% DNSIPADDRESS1=10.0.0.111
#% DNSIPADDRESS2=10.0.0.74
#% VCSAISO=/scripts/vmware-admin-scripts/esxi-on-kvm/ISO/vcsa/VMware-VCSA-all-7.0.3-20395099.iso
#% VSPHEREVERSION=7.0
#% DNSDOMAIN=example.local
#% ADPASSWORD=Aws2022@
#% ADUSER=admin@example.local

export DNSIPADDRESS1=
export DNSIPADDRESS2=
export VCSAISO=
export VSPHEREVERSION=
export DNSDOMAIN=
export ADPASSWORD=
export ADUSER=

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

## ********** START CALL OUTS TO OTHER BASH SCRIPTS ********** 

    ## set environment variables
      ./bash/configure_l0_env.sh &>> /var/log/configure_l0_env.sh.log

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
