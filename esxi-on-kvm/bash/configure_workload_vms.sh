#!/bin/bash 

${OVFTOOLPATH}/ovftool --acceptAllEulas --powerOn --noSSLVerify --name=wordpress-01a --datastore=vm-datastore --net:bridged='Applications (VLAN 30) [compute-dvs]' ./OVA/wordpress/bitnami-wordpress-5.5.1-1-linux-debian-10-x86_64.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}1.${SSODOMAINSUFFIX}:VMware1%21VMware1%21@vcsa1.$DNSDOMAIN/datacenter-1/host/compute-cluster-1/esxi2.$DNSDOMAIN"
                
${OVFTOOLPATH}/ovftool --acceptAllEulas --powerOn --noSSLVerify --name=odoo-01a --datastore=vm-datastore --net:bridged='Applications (VLAN 30) [compute-dvs]' ./OVA/odoo/bitnami-odoo-13.0.20200915-0-linux-debian-10-x86_64.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}1.${SSODOMAINSUFFIX}:VMware1%21VMware1%21@vcsa1.$DNSDOMAIN/datacenter-1/host/compute-cluster-1/esxi4.$DNSDOMAIN"

${OVFTOOLPATH}/ovftool --acceptAllEulas --powerOn --noSSLVerify --name=mysql-01a --datastore=vm-datastore --net:bridged='Databases (VLAN 40) [compute-dvs]' ./OVA/bitnami/bitnami-mysql-8.0.21-4-r08-linux-debian-10-x86_64-nami.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}1.${SSODOMAINSUFFIX}:VMware1%21VMware1%21@vcsa1.$DNSDOMAIN/datacenter-1/host/compute-cluster-1/esxi5.$DNSDOMAIN"

${OVFTOOLPATH}/ovftool --acceptAllEulas --powerOn --noSSLVerify --name=suitecrm-01a --datastore=vm-datastore --net:bridged='Databases (VLAN 40) [compute-dvs]' ./OVA/suitecrm/bitnami-suitecrm-7.11.15-2-linux-debian-10-x86_64.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}1.${SSODOMAINSUFFIX}:VMware1%21VMware1%21@vcsa1.$DNSDOMAIN/datacenter-1/host/compute-cluster-1/esxi2.$DNSDOMAIN"

${OVFTOOLPATH}/ovftool --acceptAllEulas --powerOn --noSSLVerify --name=mysql-01b --datastore=vm-datastore --net:bridged='Databases (VLAN 40) [compute-dvs]' ./OVA/bitnami/bitnami-mysql-8.0.21-4-r08-linux-debian-10-x86_64-nami.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}1.${SSODOMAINSUFFIX}:VMware1%21VMware1%21@vcsa1.$DNSDOMAIN/datacenter-1/host/compute-cluster-1/esxi4.$DNSDOMAIN"

${OVFTOOLPATH}/ovftool --acceptAllEulas --powerOn --noSSLVerify --name=tomcat-01a --datastore=vm-datastore --net:bridged='Applications (VLAN 30) [compute-dvs]' ./OVA/bitnami/bitnami-tomcat-9.0.38-0-linux-debian-10-x86_64-nami.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}1.${SSODOMAINSUFFIX}:VMware1%21VMware1%21@vcsa1.$DNSDOMAIN/datacenter-1/host/compute-cluster-1/esxi2.$DNSDOMAIN"

${OVFTOOLPATH}/ovftool --acceptAllEulas --powerOn --noSSLVerify --name=tomcat-01b --datastore=vm-datastore --net:bridged='Applications (VLAN 30) [compute-dvs]' ./OVA/bitnami/bitnami-tomcat-9.0.38-0-linux-debian-10-x86_64-nami.ova "vi://$SSOACCOUNT@${SSODOMAINBASE}1.${SSODOMAINSUFFIX}:VMware1%21VMware1%21@vcsa1.$DNSDOMAIN/datacenter-1/host/compute-cluster-1/esxi3.$DNSDOMAIN"          

exit 0
