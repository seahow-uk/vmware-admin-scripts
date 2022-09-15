#!/bin/bash


## enable libvirtd
systemctl enable libvirtd
systemctl start libvirtd

modprobe -r kvm_intel

# activate the nesting feature, along with several others
modprobe kvm_intel nested=Y enable_apicv=Y ept=Y enable_shadow_vmcs=Y

# see what the deal is with kvm_intel's option config set overall
systool -m kvm_intel -v &>>/var/log/kvm_intel_option_set.log

# make it all stick on subsequent reboots
echo "options kvm_intel nested=Y" >>/etc/modprobe.d/kvm_intel.conf
echo "options kvm_intel enable_apicv=Y" >>/etc/modprobe.d/kvm_intel.conf
echo "options kvm_intel ept=Y" >>/etc/modprobe.d/kvm_intel.conf
echo "options kvm_intel enable_shadow_vmcs=Y" >>/etc/modprobe.d/kvm_intel.conf

# routing and other ip tweaks
echo 'net.ipv4.ip_forward=1' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_timestamps=1' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_sack=1' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_window_scaling=1' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_rmem=4096 12582912 16777216' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_wmem=4096 12582912 16777216' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog=8192' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_tw_reuse=1' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_slow_start_after_idle=0' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_abort_on_overflow=0' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog=8192' >>/etc/sysctl.conf
echo 'net.core.rmem_max=16777216' >>/etc/sysctl.conf
echo 'net.core.wmem_max=16777216' >>/etc/sysctl.conf
echo 'net.core.somaxconn=2048' >>/etc/sysctl.conf
echo 'net.core.netdev_max_backlog=16384' >>/etc/sysctl.conf

## The following settings came from:
## http://techblog.cloudperf.net/2016/05/2-million-packets-per-second-on-public.html

# vm tunables
echo 'vm.dirty_ratio=80' >>/etc/sysctl.conf
echo 'vm.dirty_background_ratio=5' >>/etc/sysctl.conf
echo 'vm.dirty_expire_centisecs=12000' >>/etc/sysctl.conf
echo 'vm.swappiness=0' >>/etc/sysctl.conf

# numa tunables: Disable numa balancing feature
echo 'kernel.numa_balancing=0' >>/etc/sysctl.conf


exit 0
