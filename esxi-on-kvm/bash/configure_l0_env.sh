#!/bin/bash -x
	export ESXCLIFILE=esxcli/esxcli-7.0.0-15866526-lin64.sh
	export OVFTOOLPATH=vcsa-extracted/$VSPHEREVERSION/vcsa/ovftool/lin64
# VARIABLES YOU CAN LEAVE AT THE DEFAULT
	export TIMEZONE=EDT
# these variables set the octet for the relevant VLANs/subnets
# you probably don't want to change these as they match up to the VLAN IDs
# aka management VLAN is 20 and the octet/range is 192.168.20
	export HOSTOCTET=192.168.10
	export MANAGEMENTOCTET=192.168.20
	export APPOCTET=192.168.30
	export DBOCTET=192.168.40
	export VMOTIONOCTET=192.168.50
	export VSANOCTET=192.168.60
	export ISCSI1OCTET=192.168.70
	export ISCSI2OCTET=192.168.80
# password for root on the ESXi hosts
	export HOSTPASSWORD=VMware1!VMware1!
# password for the SSO administrator account
	export SSOPASSWORD=VMware1!VMware1!
# username for the SSO administrator account
	export SSOACCOUNT=administrator
# SSO domain structure, so by default SSO admin for lab 1 will be $SSOACCOUNT@lab1.local
	export SSODOMAINBASE=lab
	export SSODOMAINSUFFIX=local
# should probably leave this alone
	export PYTHONIOENCODING=UTF-8
# total number of ESXi hosts. Keep in mind this will be split into two clusters so hosts per lab needs to be divide evenly
	export ESXHOSTCOUNT=10
	export HOSTSPERLAB=5
# this is how many IPs in each range are set aside per lab, so like 192.168.20.10-19 for lab 1, 192.168.20-29 for lab 2
	export IPSPERLAB=10
# memory for the "normal" ESXi hosts, aka Compute Hosts in the main cluster of each lab
	export MEM=48
# cores for the "normal" ESXi hosts
	export CORE=8
# memory for the single "management" ESXi host that lives in the management cluster.  It is meant to host VCSA alone by default.
	export MGMTMEM=64
# cores for the management host
	export MGMTCORE=8

# only enable this if your HOME variable is messed up somehow, the scripts assume they are running as root
# 	export HOME=</home/you>

# this sets the NFS exports root to whatever directory this is
	function escapeSlashes {
		sed 's/\//\\\//g'
	}

	ESCAPEDPWD=$(echo "$PWD" | escapeSlashes)
	echo $ESCAPEDPWD
	sed -i 's/'"THISDIRPLACEHOLDER"'/'"$ESCAPEDPWD"'/' ./config/exports


exit 0