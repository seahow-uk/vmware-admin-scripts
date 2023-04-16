#!/bin/bash -x

. $ESXIROOT/bash/configure_l0_env.sh

# NOTE: Jan 7, 2023:
# I've just finished porting all of this to Centos 8 Stream and decoupling from an old build environment
# I have tested with libvirt configured exactly like this for 6.7 and 7.0 - nested VMs definitely boot
#
# Remaining to be seen: will 8.0 nested work with this libvirt config?

## make sure permissions are right
chmod -R 770 $ESXIROOT/*
chown -R root:kvm $ESXIROOT/*

## enable libvirtd
systemctl enable libvirtd

## now stop it so kvm and kvm_intel can be unloaded
systemctl stop libvirtd

## unload
modprobe -r kvm_intel
modprobe -r kvm

## note:  AMD uses 0 and 1 for these options while Intel uses Y and N

## load now
modprobe kvm_intel nested=Y
modprobe kvm_intel ept=Y 
modprobe kvm_intel enable_apicv=Y
modprobe kvm_intel enable_shadow_vcms=Y

modprobe kvm ignore_msrs=1
modprobe kvm tdp_mmu=0

# add for future boots

# NOTE: I've gone back and forth on which of these options should and should not be set.
# After extensive testing in 2022, I've concluded the following:
# 
# These two are ALWAYS required for nesting to work, regardless of ESXi version (6.7, 7.0, 80)
# If you turn either of these off, the nested VMs inside ESXi will refuse to boot flat out

echo "options kvm_intel nested=Y" > /etc/modprobe.d/kvm_intel.conf
echo "options kvm_intel ept=Y" >>/etc/modprobe.d/kvm_intel.conf

# These seem to help in some situations, but I haven't tested every permuation

echo "options kvm_intel enable_apicv=Y" >>/etc/modprobe.d/kvm_intel.conf
echo "options kvm_intel enable_shadow_vcms=Y" >>/etc/modprobe.d/kvm_intel.conf

# I'm not sure on MSRS, I can't tell either way that it matters, but I recommend setting it to
# ignore as it doesn't provide any detectable benefit and there is documentation out there from
# VMware and others recommending these settings.  Reasons unclear.

echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf

# This one is for two dimensional pages and can cause Win 10 or Server 2022 to crash randomly
echo "options modprobe kvm tdp_mmu=0" >>/etc/modprobe.d/kvm.conf

## now start libvirtd with nesting enabled
systemctl start libvirtd

## get the status of these values for the logs
systool -m kvm_intel -v
systool -m kvm -v

# routing and other ip tweaks
echo 'net.ipv4.ip_forward=1' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_timestamps=1' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_window_scaling=1' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_rmem=4096 12582912 16777216' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_wmem=4096 12582912 16777216' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog=8192' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_tw_reuse=1' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_abort_on_overflow=0' >>/etc/sysctl.conf
echo 'net.core.rmem_max=16777216' >>/etc/sysctl.conf
echo 'net.core.wmem_max=16777216' >>/etc/sysctl.conf
echo 'net.core.somaxconn=2048' >>/etc/sysctl.conf
echo 'net.core.netdev_max_backlog=16384' >>/etc/sysctl.conf

# things which are useful across the internet but not needed for fast local networks

# Disable TCP gradual speed increase 
echo 'net.ipv4.tcp_slow_start_after_idle=0' >>/etc/sysctl.conf

# Enable/disable TCP selective acknowledgement and its permutations 
echo 'net.ipv4.tcp_sack = 1' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_dsack = 1' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_fack = 1' >>/etc/sysctl.conf

## The following settings came from:
## http://techblog.cloudperf.net/2016/05/2-million-packets-per-second-on-public.html

# vm tunables
echo 'vm.dirty_ratio=80' >>/etc/sysctl.conf
echo 'vm.dirty_background_ratio=5' >>/etc/sysctl.conf
echo 'vm.dirty_expire_centisecs=12000' >>/etc/sysctl.conf
echo 'vm.swappiness=0' >>/etc/sysctl.conf

# numa tunables: Enable or disable numa balancing feature
# I've been disabling it, in theory this should help performance by keeping nested vm
# processes from moving around, but I haven't proven it.

echo 'kernel.numa_balancing=0' >>/etc/sysctl.conf

# AWS recommended sysctl tweaks
# From: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/enhanced-networking-os.html
echo 'vm.min_free_kbytes=1048576' >>/etc/sysctl.conf

## this forces everything in /etc/sysctl.conf to take effect without needing a reboot
sysctl --system

# make sure the options take immediate effect just in case the L0 doesn't get rebooted as part of the build
systemctl restart libvirtd

exit 0
