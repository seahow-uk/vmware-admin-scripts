#!/bin/bash

## usage:
##
## ./bash/main.sh <dns server ip 1> <dns server ip 2>
##
## NOTE: you MUST run this as root
##
## 
## example:
##
## ./bash/main.sh 192.168.10.10 192.168.20.50

if [[ $1 == "" ]]; then
  echo "You didnt supply DNS server 1, try again"
  exit 1
fi

if [[ $2 == "" ]]; then
  echo "You didnt supply DNS server 2, try again"
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
