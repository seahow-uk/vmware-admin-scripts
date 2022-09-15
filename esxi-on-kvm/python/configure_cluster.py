#!/usr/bin/python3

"""
Prerequisites
---------
pip install argparse
pip install normalizer
pip install wheel
pip install pyVim
pip install pyVmomi
pip install git+https://github.com/vmware/pyvmomi-community-samples.git
pip install git+https://github.com/vmware/vsphere-automation-sdk-python.git

or just run ./install_vmware_prereqs.sh

Mandatory Arguments
---------
-p [vcenter administrator password]
-r [root password for esxi hosts]
-i [vcsa index - 1 through 8]
-d [domain name - usually $DNSDOMAIN]
"""


import atexit
import argparse
import subprocess
from pyVim.connect import SmartConnectNoSSL, Disconnect
from pyVmomi import vim
from samples.tools import cluster, tasks, datacenter


def setup_args():
    parser = argparse.ArgumentParser(
        description='Arguments needed to configure the virtual datacenter')

    # because -h is reserved for 'help' we use -s for service
    parser.add_argument('-p', '--password',
                        required=True,
                        action='store',
                        help='vcenter admin password')

    parser.add_argument('-r', '--rootpassword',
                        required=True,
                        action='store',
                        help='root password for esxi hosts')

    parser.add_argument('-i', '--index',
                        required=True,
                        action='store',
                        help='vcsa index 1-2')

    parser.add_argument('-d', '--domain',
                        required=True,
                        action='store',
                        help='ad domain name')

    return (parser.parse_args())


def main():
    args = setup_args()

    vcsaaddr = "vcsa" + str(args.index) + "." + args.domain
    vcsauser = "$SSOACCOUNT@lab" + str(args.index) + ".local"
    datacentername = "datacenter-" + str(args.index)
    computeclustername = "compute-cluster-" + str(args.index)
    managementclustername = "management-cluster-" + str(args.index)

    print("vcsa: " + vcsaaddr)
    print("username: " + vcsauser)
    print("datacenter: " + datacentername)
    print("compute: " + computeclustername)
    print("management: " + managementclustername)

    vcsa_to_management_host_mapping = {
        "1": "esxi1." + str(args.domain),
        "2": "esxi6." + str(args.domain)
    }

    vcsa_to_compute_host_1_mapping = {
        "1": "esxi2." + str(args.domain),
        "2": "esxi7." + str(args.domain)
    }

    vcsa_to_compute_host_2_mapping = {
        "1": "esxi3." + str(args.domain),
        "2": "esxi8." + str(args.domain)
    }

    vcsa_to_compute_host_3_mapping = {
        "1": "esxi4." + str(args.domain),
        "2": "esxi9." + str(args.domain)
    }

    vcsa_to_compute_host_4_mapping = {
        "1": "esxi5." + str(args.domain),
        "2": "esxi10." + str(args.domain)
    }

    print("management host: " + vcsa_to_management_host_mapping[args.index])
    print("compute host 1: " + vcsa_to_compute_host_1_mapping[args.index])
    print("compute host 2: " + vcsa_to_compute_host_2_mapping[args.index])
    print("compute host 3: " + vcsa_to_compute_host_3_mapping[args.index])
    print("compute host 4: " + vcsa_to_compute_host_4_mapping[args.index])

    try:
        si = SmartConnectNoSSL(host=vcsaaddr,
                               user=vcsauser,
                               pwd=args.password,
                               port="443")
        atexit.register(Disconnect, si)
    except:
        print("Unable to connect to %s" % vcsaaddr)
        return 1

    host_connect_spec = vim.host.ConnectSpec()
    host_connect_spec.userName = "root"
    host_connect_spec.password = args.rootpassword
    host_connect_spec.force = True
    domainname = args.domain

    ''' Create the cluster objects '''
    dc = datacenter.create_datacenter(
        dc_name=datacentername, service_instance=si)
    managementcluster = cluster.create_cluster(
        datacenter=dc, name=managementclustername)
    computecluster = cluster.create_cluster(
        datacenter=dc, name=computeclustername)

    ''' Add the management host '''
    host_connect_spec.hostName = vcsa_to_management_host_mapping[args.index]
    host_connect_spec.sslThumbprint = get_ssl_thumbprint(
        vcsa_to_management_host_mapping[args.index], args.rootpassword)
    print(host_connect_spec.sslThumbprint)
    add_host_task = managementcluster.AddHost(
        spec=host_connect_spec, asConnected=True)
    tasks.wait_for_tasks(si, [add_host_task])

    ''' Add compute host 1 '''
    host_connect_spec.hostName = vcsa_to_compute_host_1_mapping[args.index]
    host_connect_spec.sslThumbprint = get_ssl_thumbprint(
        vcsa_to_compute_host_1_mapping[args.index], args.rootpassword)
    print(host_connect_spec.sslThumbprint)
    add_host_task = computecluster.AddHost(
        spec=host_connect_spec, asConnected=True)
    tasks.wait_for_tasks(si, [add_host_task])

    ''' Add compute host 2 '''
    host_connect_spec.hostName = vcsa_to_compute_host_2_mapping[args.index]
    host_connect_spec.sslThumbprint = get_ssl_thumbprint(
        vcsa_to_compute_host_2_mapping[args.index], args.rootpassword)
    print(host_connect_spec.sslThumbprint)
    add_host_task = computecluster.AddHost(
        spec=host_connect_spec, asConnected=True)
    tasks.wait_for_tasks(si, [add_host_task])

    ''' Add compute host 3 '''
    host_connect_spec.hostName = vcsa_to_compute_host_3_mapping[args.index]
    host_connect_spec.sslThumbprint = get_ssl_thumbprint(
        vcsa_to_compute_host_3_mapping[args.index], args.rootpassword)
    print(host_connect_spec.sslThumbprint)
    add_host_task = computecluster.AddHost(
        spec=host_connect_spec, asConnected=True)
    tasks.wait_for_tasks(si, [add_host_task])

    ''' Add compute host 4 '''
    host_connect_spec.hostName = vcsa_to_compute_host_4_mapping[args.index]
    host_connect_spec.sslThumbprint = get_ssl_thumbprint(
        vcsa_to_compute_host_4_mapping[args.index], args.rootpassword)
    print(host_connect_spec.sslThumbprint)
    add_host_task = computecluster.AddHost(
        spec=host_connect_spec, asConnected=True)
    tasks.wait_for_tasks(si, [add_host_task])


def get_ssl_thumbprint(hostname, password):
    bashCommand = "esxcli -s " + hostname + \
        " -u root -p " + password + " storage nfs list"
    normal = subprocess.run(bashCommand,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            shell=True,
                            check=False,
                            executable='/bin/bash')
    return normal.stdout.decode('utf-8').split(" ")[5]


if __name__ == "__main__":
    exit(main())
