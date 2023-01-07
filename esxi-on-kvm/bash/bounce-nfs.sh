#!/bin/bash -x

#stop all the individual components
systemctl stop nfs-server
systemctl stop nfsdcld
systemctl stop proc-fs-nfsd.mount
systemctl stop var-lib-nfs-rpc_pipefs.mount
systemctl stop nfs-client.target

#restart them in the opposite order
systemctl start nfs-client.target
systemctl start var-lib-nfs-rpc_pipefs.mount
systemctl start proc-fs-nfsd.mount
systemctl start nfsdcld
systemctl start nfs-server
