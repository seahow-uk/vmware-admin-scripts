#!/bin/bash
##
## You have to fill out the following variables with an S3 Bucket/Prefix that you have
## pre-staged with ISOs for the VCSA and customized ESXI isos.  See https://github.com/seahow-uk 
## for more information

S3BUCKET=
S3PREFIX=

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

mkdir -p /scripts/vmware-admin-scripts/esxi-on-kvm/ISO/esxi
mkdir -p /scripts/vmware-admin-scripts/esxi-on-kvm/ISO/vcsa

aws s3 cp s3://$S3BUCKET/$S3PREFIX/VMware-VCSA-all-8.0.0-20920323.iso /scripts/vmware-admin-scripts/esxi-on-kvm/ISO/vcsa/VMware-VCSA-all-8.0.0-20920323.iso
aws s3 cp s3://$S3BUCKET/$S3PREFIX/VMware-VCSA-all-7.0.3-20395099.iso /scripts/vmware-admin-scripts/esxi-on-kvm/ISO/vcsa/VMware-VCSA-all-7.0.3-20395099.iso
aws s3 cp s3://$S3BUCKET/$S3PREFIX/VMware-VCSA-all-6.7.0-15132721.iso /scripts/vmware-admin-scripts/esxi-on-kvm/ISO/vcsa/VMware-VCSA-all-6.7.0-15132721.iso

aws s3 cp s3://$S3BUCKET/$S3PREFIX/8.0.iso /scripts/vmware-admin-scripts/esxi-on-kvm/ISO/esxi/8.0.iso
aws s3 cp s3://$S3BUCKET/$S3PREFIX/7.0.iso /scripts/vmware-admin-scripts/esxi-on-kvm/ISO/esxi/7.0.iso
aws s3 cp s3://$S3BUCKET/$S3PREFIX/6.7.iso /scripts/vmware-admin-scripts/esxi-on-kvm/ISO/esxi/6.7.iso

useradd ec2-user 
usermod -G 10 ec2-user
usermod -g 10 ec2-user
sed -i "s/%wheel/#wheel/g" /etc/sudoers
sed -i "s/# #wheel/%wheel/g" /etc/sudoers

sed -i 's/'"#% "'/'" "'/' /scripts/vmware-admin-scripts/esxi-on-kvm/main.sh

echo "Aws2022@" | realm join -U admin --client-software=sssd example.local  &>> /var/log/join_l0_to_ad.log

cd /scripts/vmware-admin-scripts/esxi-on-kvm/
./main.sh