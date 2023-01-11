#!/usr/bin/python3


"""
seahow@amazon.com
Jan 2022

Mandatory Arguments
---------
-p [vcenter administrator password]
-r [root password for esxi hosts]
-i [vcsa index - 1 through 8]
-d [domain name - usually example.local]

"""

import atexit
import argparse
import time
from pyVim.connect import SmartConnectNoSSL, Disconnect
from pyVmomi import vim

def setup_args():
    parser = argparse.ArgumentParser(
        description='Arguments needed to configure the virtual datacenter')

    # because -h is reserved for 'help' we use -s for service
    parser.add_argument('-p', '--password',
                        required=True,
                        action='store',
                        help='vcenter admin password')

    parser.add_argument('-i', '--index',
                        required=True,
                        action='store',
                        help='vcenter appliance index - usually 2')

    parser.add_argument('-d', '--domain',
                        required=True,
                        action='store',
                        help='ad domain name')

    return (parser.parse_args())


def main():
    args = setup_args()

    vcsaaddr = "vcsa" + str(args.index) + "." + args.domain
    vcsauser = "administrator@lab" + str(args.index) + ".local"
    datacentername = "datacenter-" + str(args.index)
    computeclustername = "compute-cluster-" + str(args.index)
    managementclustername = "management-cluster-" + str(args.index)

    print("vcsa: " + vcsaaddr)
    print("username: " + vcsauser)
    print("datacenter: " + datacentername)
    print("compute: " + computeclustername)
    print("management: " + managementclustername)

    try:
        si = SmartConnectNoSSL(host=vcsaaddr,
                               user=vcsauser,
                               pwd=args.password,
                               port="443")
        atexit.register(Disconnect, si)
    except:
        print("Unable to connect to %s" % vcsaaddr)
        return 1

    content = si.RetrieveContent()

    ''' relocate the 2nd and 3rd nic to iscsi on the netapp '''
    vmname = "fas2040-01a"
    vm = get_obj(content, [vim.VirtualMachine], vmname)
    vmtype = str(type(vm))

    network = get_obj(content, [vim.DistributedVirtualPortgroup], "ISCSI 1 (VLAN 70) [compute-dvs]")
    nic = 2
    move_vmnic(vm, nic, network)
    print("Successfully moved", vmname, "nic 2 to ISCSI 1 VLAN 70")
    time.sleep(10)

    network = get_obj(content, [vim.DistributedVirtualPortgroup], "ISCSI 2 (VLAN 80) [compute-dvs]")
    nic = 3
    move_vmnic(vm, nic, network)
    print("Successfully moved", vmname, "nic 3 to ISCSI 2 VLAN 80")
    time.sleep(10)

def move_vmnic(vm, nic, network):
    device_change = []
    dynLabel = 'Network adapter ' + str(nic)

    for device in vm.config.hardware.device:
        if isinstance(device, vim.vm.device.VirtualEthernetCard):
            if device.deviceInfo.label == dynLabel:
                print("device: ", device, " ")
                nicspec = vim.vm.device.VirtualDeviceSpec()
                nicspec.operation = vim.vm.device.VirtualDeviceSpec.Operation.edit
                nicspec.device = device
                nicspec.device.wakeOnLanEnabled = True

                dvs_port_connection = vim.dvs.PortConnection()
                dvs_port_connection.portgroupKey = network.key
                dvs_port_connection.switchUuid = network.config.distributedVirtualSwitch.uuid
                nicspec.device.backing = vim.vm.device.VirtualEthernetCard.DistributedVirtualPortBackingInfo()
                nicspec.device.backing.port = dvs_port_connection

                nicspec.device.connectable = vim.vm.device.VirtualDevice.ConnectInfo()
                nicspec.device.connectable.connected = True
                nicspec.device.connectable.startConnected = True
                nicspec.device.connectable.allowGuestControl = True
                device_change.append(nicspec)

                config_spec = vim.vm.ConfigSpec(deviceChange=device_change)
                task = vm.ReconfigVM_Task(config_spec)
                time.sleep(10)

def get_dc(si, name):
    """
    Get a datacenter by its name.
    """
    for dc in si.content.rootFolder.childEntity:
        if dc.name == name:
            return dc

def get_obj(content, vimtype, name):
    ''' Get the vsphere object associated with a given text name '''
    obj = None
    container = content.viewManager.CreateContainerView(content.rootFolder, vimtype, True)
    for c in container.view:
        if c.name == name:
            obj = c
            break
    return obj

if __name__ == "__main__":
    exit(main())