#!/bin/bash
##
## You have to fill out the following variables with an S3 Bucket/Prefix that you have
## pre-staged with ISOs for the VCSA and customized ESXI isos.  The ADPASSWORD is whatever
## you specified as the admin password when you deployed AD  
## See https://github.com/seahow-uk/vmware-admin-scripts/esxi-on-kvm/ for more information

S3BUCKET=
S3PREFIX=
DNSIPADDRESS1=
DNSIPADDRESS2=
VCSAISO=
VSPHEREVERSION=
DNSDOMAIN=
ADPASSWORD=
ADUSER=

# Examples
# -------
# S3BUCKET=mybucket
# S3PREFIX=myprefix
# DNSIPADDRESS1=10.0.0.111
# DNSIPADDRESS2=10.0.0.74
# VCSAISO=VMware-VCSA-all-8.0.0-20920323.iso
# VSPHEREVERSION=8.0
# DNSDOMAIN=example.local
# ADPASSWORD=Aws2022@
# ADUSER=admin@EXAMPLE.LOCAL

## You can also modify the following variables if you want, but the defaults work fine and I haven't exhaustively tested changing these

HOSTPASSWORD="VMware1!"
SSOPASSWORD="Aws2022@"

## You'll need to hack the scripts to change this so I'd just leave it alone for now

ESXIROOT="/scripts/vmware-admin-scripts/esxi-on-kvm/"

## I hope you filled those out and prestaged the files or the rest of this won't work

# Enable the appropriate repos and level set with a clean and update
dnf config-manager --enable ha
dnf config-manager --enable powertools
dnf config-manager --enable nfv
dnf config-manager --enable extras
dnf clean all 
rm -rfv /var/cache/dnf
dnf distro-sync -y
dnf update -y

# install the packages we're going to need prior to running main.shn
dnf install python39 -y
dnf install wget git awscli krb5-workstation sssd realmd samba curl -y

# install the AWS SSM agent
dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Clone the git repo with all the scripts needed to build everything
mkdir -p /scripts
cd /scripts
git clone https://github.com/seahow-uk/vmware-admin-scripts.git
cd vmware-admin-scripts
chmod -R 770 *

# Install the AWS Cloudwatch agent and configure it using the file under ./JSON
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/centos/amd64/latest/amazon-cloudwatch-agent.rpm 
rpm -Uvh --quiet ./amazon-cloudwatch-agent.rpm 
cp esxi-on-kvm/JSON/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s


# Download the VMware bits from your S3 bucket
mkdir -p $ESXIROOT/ISO/esxi
mkdir -p $ESXIROOT/ISO/vcsa
aws s3 cp s3://$S3BUCKET/$S3PREFIX/$VCSAISO $ESXIROOT/ISO/vcsa/$VCSAISO
aws s3 cp s3://$S3BUCKET/$S3PREFIX/$VSPHEREVERSION.iso $ESXIROOT/ISO/esxi/$VSPHEREVERSION.iso

# Turn off source-dest-check
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
INSTANCEID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
aws ec2 modify-instance-attribute --instance-id=$INSTANCEID --no-source-dest-check --region=$EC2_REGION

# This is needed for SSM's Connection Manager feature to work
useradd ec2-user 
usermod -G 10 ec2-user
usermod -g 10 ec2-user
sed -i "s/%wheel/#wheel/g" /etc/sudoers
sed -i "s/# #wheel/%wheel/g" /etc/sudoers

# This sets the root password on L0 to match your ADPASSWORD variable so you can mount the CIFS shares Samba exposes from your jump host
$ESXIROOT/expect/installesxcli.sh

# This pushes all the variables above into main.sh
sed -i "0,/DNSIPADDRESS1=/ s/DNSIPADDRESS1=/DNSIPADDRESS1=$DNSIPADDRESS1/" $ESXIROOT/main.sh
sed -i "0,/DNSIPADDRESS2=/ s/DNSIPADDRESS2=/DNSIPADDRESS2=$DNSIPADDRESS2/" $ESXIROOT/main.sh
sed -i "0,/VCSAISO=/ s/VCSAISO=/VCSAISO=$VCSAISO/" $ESXIROOT/main.sh
sed -i "0,/VSPHEREVERSION=/ s/VSPHEREVERSION=/VSPHEREVERSION=$VSPHEREVERSION/" $ESXIROOT/main.sh
sed -i "0,/DNSDOMAIN=/ s/DNSDOMAIN=/DNSDOMAIN=$DNSDOMAIN/" $ESXIROOT/main.sh
sed -i "0,/ADPASSWORD=/ s/ADPASSWORD=/ADPASSWORD=$ADPASSWORD/" $ESXIROOT/main.sh
sed -i "0,/ADUSER=/ s/ADUSER=/ADUSER=$ADUSER/" $ESXIROOT/main.sh
sed -i "0,/HOSTPASSWORD=/ s/HOSTPASSWORD=/HOSTPASSWORD=$HOSTPASSWORD/" $ESXIROOT/main.sh
sed -i "0,/SSOPASSWORD=/ s/SSOPASSWORD=/SSOPASSWORD=$SSOPASSWORD/" $ESXIROOT/main.sh

# This joins your L0 to Active Directory
echo "$ADPASSWORD" | realm join -U admin --client-software=sssd $DNSDOMAIN  &>> /var/log/join_l0_to_ad.log

# Kick off main.sh which builds everything but stops short of actually deploying the nested VMware environment.

cd $ESXIROOT
./main.sh

# Once the host is done building and running everything under main.sh (easily 20 minutes), you need to SSH in and run
# $ESXIROOT/nested.sh to build the VMware environment.  Now you *could* add that here at the end right after main.sh
# but you will need to somehow make sure the route tables are pointing to this L0's ENI for 192.168.0.0/16 by the time
# that occurs.