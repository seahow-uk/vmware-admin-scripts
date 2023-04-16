#!/bin/bash -x

export ESXIROOT="$PWD"

  . $ESXIROOT/bash/configure_l0_env.sh

# build base vmware environment

#  NOTE: in addition to doing an unattended install of the ESXi hosts,
#  build.sh calls the following sub-scripts afterward:
    
# ./bash/configure_vcsas.sh 
# ./bash/configure_cluster.sh 
# ./bash/configure_dvs.sh 

    $ESXIROOT/bash/build.sh &>>/var/log/build.sh.log

## extended tweaks for the esxi hosts, vcsas, etc
    $ESXIROOT/bash/configure_esxi.sh &>>/var/log/configure_esxi.log

## download bitnami appliances
    $ESXIROOT/bash/get_ovas.sh &>>/var/log/get_ovas.sh.log

## install bitnami appliances to act as workload VMs
    $ESXIROOT/bash/configure_workload_vms.sh &>>/var/log/configure_workload_vms.sh.log

## deploy any custom ovfs like netapp, commvault, veeam, generic windows templates
    # $ESXIROOT/bash/configure_custom_ovfs.sh &>>/var/log/configure_custom_ovfs.sh.log
#
#  NOTE: this is disabled because you need to have those OVAs prestaged on your S3 bucket which requires more stuff I can't distribute.
#  If you really want to get this part automated contact me at darmok.and.jalad@tanagra.uk so I can walk you through it