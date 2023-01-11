#!/bin/bash
##
## You have to fill out the following variables with an S3 Bucket/Prefix that you have
## pre-staged with ISOs for the VCSA and customized ESXI isos.  The ADPASSWORD is whatever
## you specified as the admin password when you deployed AD  See https://github.com/seahow-uk 
## for more information

S3BUCKET=
S3PREFIX=
DNSIPADDRESS1=
DNSIPADDRESS2=
VCSAISO=
VSPHEREVERSION=
DNSDOMAIN=
ADPASSWORD=
ADUSER=

# Example
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

## You can modify these variables if you want, but the defaults work fine

HOSTPASSWORD="VMware1!"
SSOPASSWORD="Aws2022@"

## You'll need to hack this script up a bit to change this

ESXIROOT="/scripts/vmware-admin-scripts/esxi-on-kvm/"

## I hope you filled those out and prestaged the files or the rest of this won't work

dnf config-manager --enable ha
dnf config-manager --enable powertools
dnf config-manager --enable nfv
dnf config-manager --enable extras
dnf clean all 
rm -rfv /var/cache/dnf
dnf distro-sync -y
dnf update -y
dnf install python39 -y
dnf install wget git awscli krb5-workstation sssd realmd samba curl -y
dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

mkdir -p /scripts
cd /scripts
git clone https://github.com/seahow-uk/vmware-admin-scripts.git
cd vmware-admin-scripts
chmod -R 770 *

wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/centos/amd64/latest/amazon-cloudwatch-agent.rpm 
rpm -Uvh --quiet ./amazon-cloudwatch-agent.rpm 
cp esxi-on-kvm/JSON/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

mkdir -p $ESXIROOT/ISO/esxi
mkdir -p $ESXIROOT/ISO/vcsa

aws s3 cp s3://$S3BUCKET/$S3PREFIX/$VCSAISO $ESXIROOT/ISO/vcsa/$VCSAISO
aws s3 cp s3://$S3BUCKET/$S3PREFIX/$VSPHEREVERSION.iso $ESXIROOT/ISO/esxi/$VSPHEREVERSION.iso

# Turn off source-dest-check
aws s3 cp s3://ec2metadata/ec2-metadata /usr/bin
chmod 777 /usr/bin/ec2-metadata
INSTANCEID=$(ec2-metadata -i | awk '{print $2}')
aws ec2 modify-instance-attribute --instance-id=$INSTANCEID --no-source-dest-check

useradd ec2-user 
usermod -G 10 ec2-user
usermod -g 10 ec2-user
sed -i "s/%wheel/#wheel/g" /etc/sudoers
sed -i "s/# #wheel/%wheel/g" /etc/sudoers

sed -i "0,/DNSIPADDRESS1=/ s/DNSIPADDRESS1=/DNSIPADDRESS1=$DNSIPADDRESS1/" $ESXIROOT/main.sh
sed -i "0,/DNSIPADDRESS2=/ s/DNSIPADDRESS2=/DNSIPADDRESS2=$DNSIPADDRESS2/" $ESXIROOT/main.sh
sed -i "0,/VCSAISO=/ s/VCSAISO=/VCSAISO=$VCSAISO/" $ESXIROOT/main.sh
sed -i "0,/VSPHEREVERSION=/ s/VSPHEREVERSION=/VSPHEREVERSION=$VSPHEREVERSION/" $ESXIROOT/main.sh
sed -i "0,/DNSDOMAIN=/ s/DNSDOMAIN=/DNSDOMAIN=$DNSDOMAIN/" $ESXIROOT/main.sh
sed -i "0,/ADPASSWORD=/ s/ADPASSWORD=/ADPASSWORD=$ADPASSWORD/" $ESXIROOT/main.sh
sed -i "0,/ADUSER=/ s/ADUSER=/ADUSER=$ADUSER/" $ESXIROOT/main.sh
sed -i "0,/HOSTPASSWORD=/ s/HOSTPASSWORD=/HOSTPASSWORD=$HOSTPASSWORD/" $ESXIROOT/main.sh
sed -i "0,/SSOPASSWORD=/ s/SSOPASSWORD=/SSOPASSWORD=$SSOPASSWORD/" $ESXIROOT/main.sh

echo "$ADPASSWORD" | realm join -U admin --client-software=sssd example.local  &>> /var/log/join_l0_to_ad.log

cd $ESXIROOT
./main.sh
