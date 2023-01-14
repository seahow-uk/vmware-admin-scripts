#!/bin/bash

# pip3 install -U pysphere
# cd ./bash
# git clone https://github.com/pdellaert/vSphere-Python.git

# NOTICE THIS AT THE END:  > /dev/null 2>&1 &
# That means run these 4 commands in parallel
# The wait statement at the bottom is where it
# stops and wont proceed until all 5 are done.

URIENCODEDSSOPASSWORD=$(echo $SSOPASSWORD|jq -Rr @uri)

# deploy cifs-01a to lab 1
${OVFTOOLPATH}/ovftool --acceptAllEulas --X:injectOvfEnv --powerOn --noSSLVerify --name=cifs-01a --datastore=vm-datastore --diskMode=thin --net:'Management (VLAN 20) [compute-dvs]'='Applications (VLAN 30) [compute-dvs]' --prop:guestinfo.hostname="cifs-01a" --prop:guestinfo.ipaddress="$APPOCTET.236" --prop:guestinfo.netmask="24" --prop:guestinfo.gateway="$APPOCTET.1" --prop:guestinfo.dns="$DNSIPADDRESS1" --prop:guestinfo.domain="$DNSDOMAIN" --prop:guestinfo.ad_domain="$DNSDOMAIN" --prop:guestinfo.ad_username="admin" --prop:guestinfo.ad_password="VMware1!VMware1!" ./OVA/win2019/win-2019.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}1.$SSODOMAINSUFFIX:${URIENCODEDSSOPASSWORD}@vcsa1.$DNSDOMAIN/datacenter-1/host/compute-cluster-1/esxi4.$DNSDOMAIN" >/dev/null 2>&1 &

# deploy veeam-01a to lab 2
${OVFTOOLPATH}/ovftool --acceptAllEulas --X:injectOvfEnv --powerOn --noSSLVerify --name=veeam-01a --datastore=vm-datastore --diskMode=thin --net:'Management (VLAN 20) [compute-dvs]'='Management (VLAN 20) [compute-dvs]' --prop:guestinfo.hostname="veeam-01a" --prop:guestinfo.ipaddress="$MANAGEMENTOCTET.236" --prop:guestinfo.netmask="24" --prop:guestinfo.gateway="$MANAGEMENTOCTET.1" --prop:guestinfo.dns="$DNSIPADDRESS1" --prop:guestinfo.domain="$DNSDOMAIN" --prop:guestinfo.ad_domain="$DNSDOMAIN" --prop:guestinfo.ad_username="admin" --prop:guestinfo.ad_password="VMware1!VMware1!" ./OVA/win2019/win-2019.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}2.$SSODOMAINSUFFIX:${URIENCODEDSSOPASSWORD}@vcsa2.$DNSDOMAIN/datacenter-2/host/compute-cluster-2/esxi7.$DNSDOMAIN" >/dev/null 2>&1 &

# deploy mssql-01a to lab 1
${OVFTOOLPATH}/ovftool --acceptAllEulas --X:injectOvfEnv --powerOn --noSSLVerify --name=mssql-01a --datastore=vm-datastore --diskMode=thin --net:'Management (VLAN 20) [compute-dvs]'='Databases (VLAN 40) [compute-dvs]' --prop:guestinfo.hostname="mssql-01a" --prop:guestinfo.ipaddress="$DBOCTET.236" --prop:guestinfo.netmask="24" --prop:guestinfo.gateway="$DBOCTET.1" --prop:guestinfo.dns="$DNSIPADDRESS1" --prop:guestinfo.domain="$DNSDOMAIN" --prop:guestinfo.ad_domain="$DNSDOMAIN" --prop:guestinfo.ad_username="admin" --prop:guestinfo.ad_password="VMware1!VMware1!" ./OVA/win2019/win-2019.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}1.$SSODOMAINSUFFIX:${URIENCODEDSSOPASSWORD}@vcsa1.$DNSDOMAIN/datacenter-1/host/compute-cluster-1/esxi5.$DNSDOMAIN" >/dev/null 2>&1 &

# deploy commvault-01a to lab 2
${OVFTOOLPATH}/ovftool --acceptAllEulas --X:injectOvfEnv --powerOn --noSSLVerify --name=commvault-01a --datastore=vm-datastore --diskMode=thin --net:'VM Network'='Management (VLAN 20) [compute-dvs]' --prop:001_HostName.Host_Name="commvault-01a" --prop:001_HostName.Password="VMware1!VMware1!" ./OVA/commvault/CV_CS_VMWare_SP22.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}2.$SSODOMAINSUFFIX:${URIENCODEDSSOPASSWORD}@vcsa2.$DNSDOMAIN/datacenter-2/host/compute-cluster-2/esxi7.$DNSDOMAIN" >/dev/null 2>&1 &

# deploy vnx-01a to lab 2
# ${OVFTOOLPATH}/ovftool --powerOn --noSSLVerify --name='vnx-01a' --datastore='vm-datastore' --diskMode='thin' --net:'ISCSI 1 (VLAN 70) [compute-dvs]'='ISCSI 1 (VLAN 70) [compute-dvs]' --net:'ISCSI 1 (VLAN 70) [compute-dvs]'='ISCSI 1 (VLAN 70) [compute-dvs]' --net:'ISCSI 2 (VLAN 80) [compute-dvs]'='ISCSI 2 (VLAN 80) [compute-dvs]' --net:'ISCSI 2 (VLAN 80) [compute-dvs]'='ISCSI 2 (VLAN 80) [compute-dvs]' --net:'Management (VLAN 20) [compute-dvs]'='Management (VLAN 20) [compute-dvs]' ./OVA/emc/vnx-01a.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}2.$SSODOMAINSUFFIX:${URIENCODEDSSOPASSWORD}@vcsa2.$DNSDOMAIN/datacenter-2/host/compute-cluster-2/esxi8.$DNSDOMAIN" > /dev/null 2>&1 &

# ${OVFTOOLPATH}/ovftool --powerOn --noSSLVerify --name='vnx-01a' --datastore='vm-datastore' --diskMode='thin' --net:bridged='ISCSI 1 (VLAN 70) [compute-dvs]' --net:bridged='ISCSI 1 (VLAN 70) [compute-dvs]' --net:bridged='ISCSI 2 (VLAN 80) [compute-dvs]' --net:bridged='ISCSI 2 (VLAN 80) [compute-dvs]' --net:bridged='Management (VLAN 20) [compute-dvs]' ./OVA/emc/vnx-01a.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}2.$SSODOMAINSUFFIX:${URIENCODEDSSOPASSWORD}@vcsa2.$DNSDOMAIN/datacenter-2/host/compute-cluster-2/esxi8.$DNSDOMAIN"

# deploy netapp to lab 2
${OVFTOOLPATH}/ovftool --powerOn --noSSLVerify --name=fas2040-01a --datastore=vm-datastore --diskMode=thin --net:'bridged'='Management (VLAN 20) [compute-dvs]' ./OVA/netapp/fas2040-01a.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}2.$SSODOMAINSUFFIX:${URIENCODEDSSOPASSWORD}@vcsa2.$DNSDOMAIN/datacenter-2/host/compute-cluster-2/esxi9.$DNSDOMAIN" >/dev/null 2>&1 &

# create a basic template
${OVFTOOLPATH}/ovftool --noSSLVerify --name=win-2019-template --datastore=vm-datastore --diskMode=thin --net:'Management (VLAN 20) [compute-dvs]'='Management (VLAN 20) [compute-dvs]' ./OVA/win2019/win-2019.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}1.$SSODOMAINSUFFIX:${URIENCODEDSSOPASSWORD}@vcsa1.$DNSDOMAIN/datacenter-1/host/compute-cluster-1/esxi3.$DNSDOMAIN" >/dev/null 2>&1 &

# deploy SGW VTL appliance to cluster 2
${OVFTOOLPATH}/ovftool --noSSLVerify --powerOn --name=vtl-01a --datastore=vm-datastore --diskMode=thin --net:'Management (VLAN 20) [compute-dvs]'='Management (VLAN 20) [compute-dvs]' ./OVA/storagegatewayvtl/vtl-01a.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}2.$SSODOMAINSUFFIX:${URIENCODEDSSOPASSWORD}@vcsa2.$DNSDOMAIN/datacenter-2/host/compute-cluster-2/esxi10.$DNSDOMAIN" >/dev/null 2>&1 &

wait

## fix the thing where the netapp's nics 2 and 3 are on the management net instead of iscsi 1 and 2

./bash/configure_netapp.sh &>>/var/log/configure_netapp.sh.log

exit 0
