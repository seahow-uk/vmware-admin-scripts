Notes from deploying this on an r5b.metal in EC2
---
    I used the centos 8 appstream image AWS makes from the marketplace. 
    I gave the host 2 ENIs both on the same private subnet.
    I deployed a managed AD instance that also has its domain controllers on the same private subnets.  Note: not Simple AD, normal managed AD.

Steps
---
    sudo su -
        * note: the scripts expect you to be root
  
    systemctl enable --now cockpit.socket
    yum install wget python38* epel-release git -y
    yum update -y
    yum install awscli s3cmd -y

        [this next part is just so cloudwatch agent log stuff works and is optional]
	
        wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/centos/amd64/latest/amazon-cloudwatch-agent.rpm 
        rpm -Uvh --quiet ./amazon-cloudwatch-agent.rpm 
        vi /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json 
            (manually insert json base file)
            (manually create new log group called nest-test-centos-8-appstream)
        sed -i "s/INSTANCELOGSPLACEHOLDER/nest-test-centos-8-appstream/g" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
        /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

    mkdir -p /scripts
    cd /scripts
    git clone https://github.com/seahow-uk/vmware-admin-scripts.git
    cd vmware-admin-scripts
    chmod -R 700 *
    cd esxi-on-kvm/ISO
    mkdir vcsa
    cd vcsa

        [you will need to pre stage these in an s3 bucket for this next 2 commands to work, or you could manually get them from VMware]

        aws s3 cp s3://$S3PATH/VMware-VCSA-all-7.0.3-20395099.iso .
        aws s3 cp s3://$S3PATH/VMware-VCSA-all-6.7.0-15132721.iso .

    cd /scripts/vmware-admin-scripts/esxi-on-kvm

    vi main.sh

        [Here you will have to manually set the parameters it wants at the top of the file]
    
    ./main.sh



configure_l0_env.sh
---
<!-- ## NOTES for future reference
# 	export ESXCLIFILE=esxcli/esxcli-7.0.0-15866526-lin64.sh
# # VARIABLES YOU CAN LEAVE AT THE DEFAULT
# 	export TIMEZONE=EDT
# # these variables set the octet for the relevant VLANs/subnets
# # you probably don't want to change these as they match up to the VLAN IDs
# # aka management VLAN is 20 and the octet/range is 192.168.20
# 	export HOSTOCTET=192.168.10
# 	export MANAGEMENTOCTET=192.168.20
# 	export APPOCTET=192.168.30
# 	export DBOCTET=192.168.40
# 	export VMOTIONOCTET=192.168.50
# 	export VSANOCTET=192.168.60
# 	export ISCSI1OCTET=192.168.70
# 	export ISCSI2OCTET=192.168.80
# # password for root on the ESXi hosts
# 	export HOSTPASSWORD=VMware1!VMware1!
# # password for the SSO administrator account
# 	export SSOPASSWORD=VMware1!VMware1!
# # username for the SSO administrator account
# 	export SSOACCOUNT=administrator
# # SSO domain structure, so by default SSO admin for lab 1 will be $SSOACCOUNT@lab1.local
# 	export SSODOMAINBASE=lab
# 	export SSODOMAINSUFFIX=local
# # should probably leave this alone
# 	export PYTHONIOENCODING=UTF-8
# # total number of ESXi hosts. Keep in mind this will be split into two clusters so hosts per lab needs to be divide evenly
# 	export ESXHOSTCOUNT=10
# 	export HOSTSPERLAB=5
# # this is how many IPs in each range are set aside per lab, so like 192.168.20.10-19 for lab 1, 192.168.20-29 for lab 2
# 	export IPSPERLAB=10
# # memory for the "normal" ESXi hosts, aka Compute Hosts in the main cluster of each lab
# 	export MEM=48
# # cores for the "normal" ESXi hosts
# 	export CORE=8
# # memory for the single "management" ESXi host that lives in the management cluster.  It is meant to host VCSA alone by default.
# 	export MGMTMEM=64
# # cores for the management host
# 	export MGMTCORE=8 -->
