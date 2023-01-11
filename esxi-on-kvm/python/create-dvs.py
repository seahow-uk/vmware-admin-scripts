#!/usr/bin/python3

"""
Prerequisites
---------
pip3 install argparse
pip3 install setuptools-git
pip3 install normalizer
pip3 install wheel
pip3 install pyVim
pip3 install pyVmomi
pip3 install git+https://github.com/vmware/pyvmomi-community-samples.git
pip3 install git+https://github.com/vmware/vsphere-automation-sdk-python.git

Arguments
---------
-s [vcenter FQDN or IP]
-u [vcenter administrator username - usually $SSOACCOUNT@$SSODOMAINBASE[n].local]
-p [vcenter administrator password]
-S [tells it to ignore SSL errors, you probably want this]
-d [datacenter you want to use.  optional - it will just use the first one if you don't specify]

example:  python3 create-dvs.py -s vcsa1.$DNSDOMAIN -u $SSOACCOUNT@${SSODOMAINBASE}1.local -p VMware1!VMware1!

"""

import atexit
import argparse
import time

from pyVim.connect import SmartConnectNoSSL, Disconnect
from pyVmomi import vim
from re import search

def setup_args():
    parser = argparse.ArgumentParser(
        description='Arguments needed to configure vCenter')

    # because -h is reserved for 'help' we use -s for service
    parser.add_argument('-s', '--host',
                        required=True,
                        action='store',
                        help='vSphere service to connect to')

    # because we want -p for password, we use -o for port
    parser.add_argument('-o', '--port',
                        type=int,
                        default=443,
                        action='store',
                        help='Port to connect on')

    parser.add_argument('-u', '--user',
                        required=True,
                        action='store',
                        help='User name to use when connecting to host')

    parser.add_argument('-p', '--password',
                        required=True,
                        action='store',
                        help='Password to use when connecting to host')

    parser.add_argument('-S', '--disable_ssl_verification',
                        required=False,
                        action='store_true',
                        help='Disable ssl host certificate verification')

    parser.add_argument('-d', '--datacenter',
                        help='Name of datacenter to use. '
                             'Defaults to first.')

    return (parser.parse_args())

def main():
    args = setup_args()
    try:
        si = SmartConnectNoSSL(host=args.host,
                               user=args.user,
                               pwd=args.password,
                               port=args.port)
        atexit.register(Disconnect, si)
    except:
        print("Unable to connect to %s" % args.host)
        return 1

    ''' Obtain DVS, cluster, and DC information and set up variables '''

    if args.datacenter:
        dc = get_dc(si, args.datacenter)
    else:
        dc = si.content.rootFolder.childEntity[0]
    
    network_folder = dc.networkFolder
    content = si.RetrieveContent()

    for cluster in _get_vim_objects(content, vim.ClusterComputeResource):
      clustername = cluster.name
      clustermorefraw = cluster

      if search("management", clustername):
          print("management cluster moref:"+str(clustermorefraw))
          management_cluster_moref=clustermorefraw
          management_dvswitch_object = create_dvSwitch(si, network_folder, clustermorefraw, "management-dvs")
          add_dvPort_group(si, management_dvswitch_object, "Management (VLAN 20) [management-dvs]", 20)
          add_dvPort_group(si, management_dvswitch_object, "vMotion (VLAN 50) [management-dvs]", 50)

      if search("compute", clustername):
          print("compute cluster moref:"+str(clustermorefraw))
          compute_cluster_moref=clustermorefraw
          compute_dvswitch_object = create_dvSwitch(si, network_folder, clustermorefraw, "compute-dvs")
          add_dvPort_group(si, compute_dvswitch_object, "Management (VLAN 20) [compute-dvs]", 20)
          add_dvPort_group(si, compute_dvswitch_object, "Applications (VLAN 30) [compute-dvs]", 30)
          add_dvPort_group(si, compute_dvswitch_object, "Databases (VLAN 40) [compute-dvs]", 40)
          add_dvPort_group(si, compute_dvswitch_object, "vMotion (VLAN 50) [compute-dvs]", 50)
          add_dvPort_group(si, compute_dvswitch_object, "VSAN (VLAN 60) [compute-dvs]", 60)
          add_dvPort_group(si, compute_dvswitch_object, "ISCSI 1 (VLAN 70) [compute-dvs]", 70)
          add_dvPort_group(si, compute_dvswitch_object, "ISCSI 2 (VLAN 80) [compute-dvs]", 80)

    rename_uplink_portgroups(si)

    for entity in dc.hostFolder.childEntity:

        if entity == compute_cluster_moref:
            for host in entity.host:
                print("Attaching vmnic1, vmnic2, vmnic3, vmnic4, vmnic5, and vmnic6 on:", host.name)
                assign_pnic_list = ["vmnic1", "vmnic2", "vmnic3", "vmnic4", "vmnic5", "vmnic6"]
                assign_pnic(compute_dvswitch_object, host, assign_pnic_list)
                time.sleep(1)

        if entity == management_cluster_moref:
            for host in entity.host:
                print("Attaching vmnic1, vmnic2, vmnic3, vmnic4, vmnic5, and vmnic6 on:", host.name)
                assign_pnic_list = ["vmnic1", "vmnic2", "vmnic3", "vmnic4", "vmnic5", "vmnic6"]
                assign_pnic(management_dvswitch_object, host, assign_pnic_list)
                time.sleep(1)    

    print("done attaching hosts.  now migrating from vss")

    ''' relocate the c&c vms '''
    list_of_vms_to_relocate = [args.host]

    for vmname in list_of_vms_to_relocate:
        vm = get_obj(content, [vim.VirtualMachine], vmname)
        vmtype = str(type(vm))

        if vmtype == "<class 'pyVmomi.VmomiSupport.vim.VirtualMachine'>" and vmname == args.host:
            network = get_obj(content, [vim.DistributedVirtualPortgroup], "Management (VLAN 20) [management-dvs]")
            move_vm(vm, network)
            print("Successfully moved", vmname, "to new Management DVS")

        time.sleep(10)

    for entity in dc.hostFolder.childEntity:

        if entity == compute_cluster_moref:
            for host in entity.host:

                tries = 3
                succeeded = 0
                for i in range(tries):
                    print("try #" + str(i))
                    if succeeded == 0:
                        try:
                            target_portgroup = get_obj(content, [vim.DistributedVirtualPortgroup], "Management (VLAN 20) [compute-dvs]")
                            print("moving vmk0 on:", host.name)
                            migrate_vmk(host, target_portgroup, compute_dvswitch_object, "vmk0")
                            time.sleep(5)
                            succeeded = 1
                        except Exception as e:
                            print(e)
                            time.sleep(60)

                tries = 3
                succeeded = 0
                for i in range(tries):
                    print("try #" + str(i))
                    if succeeded == 0:
                        try:
                            target_portgroup = get_obj(content, [vim.DistributedVirtualPortgroup], "VSAN (VLAN 60) [compute-dvs]")
                            print("creating vmk1 on:", host.name)
                            create_vmk(host, target_portgroup, compute_dvswitch_object, "vsan")
                            time.sleep(5)
                            succeeded = 1
                        except Exception as e:
                            print(e)
                            time.sleep(60)

                tries = 3
                succeeded = 0
                for i in range(tries):
                    print("try #" + str(i))
                    if succeeded == 0:
                        try:
                            target_portgroup = get_obj(content, [vim.DistributedVirtualPortgroup], "ISCSI 1 (VLAN 70) [compute-dvs]")
                            print("creating vmk2 on:", host.name)
                            create_vmk(host, target_portgroup, compute_dvswitch_object, "iscsi")
                            time.sleep(5)
                            succeeded = 1
                        except Exception as e:
                            print(e)
                            time.sleep(60)

                tries = 3
                succeeded = 0
                for i in range(tries):
                    print("try #" + str(i))
                    if succeeded == 0:
                        try:
                            target_portgroup = get_obj(content, [vim.DistributedVirtualPortgroup], "ISCSI 2 (VLAN 80) [compute-dvs]")
                            print("creating vmk3 on:", host.name)
                            create_vmk(host, target_portgroup, compute_dvswitch_object, "iscsi")
                            time.sleep(5)
                            succeeded = 1
                        except Exception as e:
                            print(e)
                            time.sleep(60)


                tries = 3
                succeeded = 0
                for i in range(tries):
                    print("try #" + str(i))
                    if succeeded == 0:
                        try:
                            target_portgroup = get_obj(content, [vim.DistributedVirtualPortgroup], "vMotion (VLAN 50) [compute-dvs]")
                            print("creating vmk4 on:", host.name)
                            create_vmk(host, target_portgroup, compute_dvswitch_object, "vmotion")
                            time.sleep(5)
                            succeeded = 1
                        except Exception as e:
                            print(e)
                            time.sleep(60)

        if entity == management_cluster_moref:
            for host in entity.host:
                tries = 3
                for i in range(tries):
                    print("try #" + str(i))
                    if succeeded == 0:
                        try:
                            target_portgroup = get_obj(content, [vim.DistributedVirtualPortgroup], "Management (VLAN 20) [management-dvs]")
                            print("moving vmk0 on:", host.name)
                            migrate_vmk(host, target_portgroup, management_dvswitch_object, "vmk0")
                            time.sleep(5)  
                            succeeded = 1
                        except Exception as e:
                            print(e)
                            time.sleep(60)

    print ("done and done!")

def create_host_vnic_config(target_portgroup, target_dvswitch, vmk):
    host_vnic_config = vim.host.VirtualNic.Config()
    host_vnic_config.spec = vim.host.VirtualNic.Specification()

    host_vnic_config.changeOperation = "edit"
    host_vnic_config.device = vmk
    host_vnic_config.portgroup = ""
    host_vnic_config.spec.distributedVirtualPort = vim.dvs.PortConnection()
    host_vnic_config.spec.distributedVirtualPort.switchUuid = target_dvswitch.uuid
    host_vnic_config.spec.distributedVirtualPort.portgroupKey = target_portgroup.key

    return host_vnic_config

def _get_vim_objects(content, vim_type):
    """Get vim objects of a given type."""
    return [item for item in content.viewManager.CreateContainerView(
        content.rootFolder, [vim_type], recursive=True
    ).view]

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

def create_dvSwitch(si, network_folder, cluster, dvswitchname):
    content = si.RetrieveContent()
    dvs_host_configs = []
    uplink_port_names = []
    dvs_create_spec = vim.DistributedVirtualSwitch.CreateSpec()
    dvs_config_spec = vim.VmwareDistributedVirtualSwitch.ConfigSpec()
    dvs_config_spec.name = dvswitchname
    dvs_config_spec.maxMtu = 9000
    ##dvs_config_spec.networkResourceManagementEnabled = True
    dvs_config_spec.uplinkPortPolicy = vim.DistributedVirtualSwitch.NameArrayUplinkPortPolicy()

    hosts = cluster.host
    vmnic1=str(dvswitchname)+"-vmnic1"
    vmnic2=str(dvswitchname)+"-vmnic2"
    vmnic3=str(dvswitchname)+"-vmnic3"
    vmnic4=str(dvswitchname)+"-vmnic4"
    vmnic5=str(dvswitchname)+"-vmnic5"
    vmnic6=str(dvswitchname)+"-vmnic6"

    uplink_port_names.append(vmnic1)
    uplink_port_names.append(vmnic2)
    uplink_port_names.append(vmnic3)
    uplink_port_names.append(vmnic4)
    uplink_port_names.append(vmnic5)
    uplink_port_names.append(vmnic6)

    for host in hosts:
        dvs_config_spec.uplinkPortPolicy.uplinkPortName = uplink_port_names
        dvs_config_spec.maxPorts = 60000
        dvs_host_config = vim.dvs.HostMember.ConfigSpec()
        dvs_host_config.operation = vim.ConfigSpecOperation.add
        dvs_host_config.host = host
        dvs_host_configs.append(dvs_host_config)
        dvs_config_spec.host = dvs_host_configs

    dvs_create_spec.configSpec = dvs_config_spec
    dvs_create_spec.productInfo = vim.dvs.ProductSpec(version='6.6.0')

    task = network_folder.CreateDVS_Task(dvs_create_spec)
    print("Creating new DVS", dvswitchname)
    time.sleep(5)

    newdvs = get_obj(content, [vim.DistributedVirtualSwitch], dvswitchname)
    return newdvs

def assign_pnic(dvs, host, pnic_device_list):
    dvs_config_spec = vim.DistributedVirtualSwitch.ConfigSpec()
    dvs_config_spec.configVersion = dvs.config.configVersion
    dvs_host_configs = []
    dvs_host_config = vim.dvs.HostMember.ConfigSpec()
    dvs_host_config.operation = vim.ConfigSpecOperation.edit
    dvs_host_config.backing = vim.dvs.HostMember.PnicBacking()

    for pnic in pnic_device_list:
        dvs_host_config.backing.pnicSpec.append(vim.dvs.HostMember.PnicSpec(pnicDevice=pnic))

    dvs_host_config.host = host
    dvs_host_configs.append(dvs_host_config)
    dvs_config_spec.host = dvs_host_configs
    task = dvs.ReconfigureDvs_Task(dvs_config_spec)

def add_dvPort_group(si, dv_switch, portgroupname, vlanid):
    dv_pg_spec = vim.dvs.DistributedVirtualPortgroup.ConfigSpec()
    dv_pg_spec.name = portgroupname
    dv_pg_spec.numPorts = 64
    dv_pg_spec.type = vim.dvs.DistributedVirtualPortgroup.PortgroupType.earlyBinding

    dv_pg_spec.defaultPortConfig = vim.dvs.VmwareDistributedVirtualSwitch.VmwarePortConfigPolicy()
    dv_pg_spec.defaultPortConfig.securityPolicy = vim.dvs.VmwareDistributedVirtualSwitch.SecurityPolicy()

    dv_pg_spec.defaultPortConfig.vlan = vim.dvs.VmwareDistributedVirtualSwitch.VlanIdSpec()
    dv_pg_spec.defaultPortConfig.vlan.vlanId = vlanid
    dv_pg_spec.defaultPortConfig.securityPolicy.allowPromiscuous = vim.BoolPolicy(value=False)
    dv_pg_spec.defaultPortConfig.securityPolicy.forgedTransmits = vim.BoolPolicy(value=True)

    dv_pg_spec.defaultPortConfig.vlan.inherited = False
    dv_pg_spec.defaultPortConfig.securityPolicy.macChanges = vim.BoolPolicy(value=True)
    dv_pg_spec.defaultPortConfig.securityPolicy.inherited = False
    
    dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy = vim.dvs.VmwareDistributedVirtualSwitch.UplinkPortTeamingPolicy()
    # dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.notifySwitches.inherited = False
    dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.notifySwitches = vim.BoolPolicy(value=True)

    # dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.policy.inherited = False
    dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder = vim.dvs.VmwareDistributedVirtualSwitch.UplinkPortOrderPolicy()
    dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.inherited = False

    if portgroupname == "Management (VLAN 20) [management-dvs]":
        vmnic1="management-dvs-vmnic1"
        vmnic2="management-dvs-vmnic2"
        vmnic3="management-dvs-vmnic3"
        vmnic4="management-dvs-vmnic4"
        vmnic5="management-dvs-vmnic5"
        vmnic6="management-dvs-vmnic6"
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.policy = vim.StringPolicy(value="loadbalance_loadbased")
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort = []
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic1)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic2)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic3)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic4)

    if portgroupname == "vMotion (VLAN 50) [management-dvs]":
        vmnic1="management-dvs-vmnic1"
        vmnic2="management-dvs-vmnic2"
        vmnic3="management-dvs-vmnic3"
        vmnic4="management-dvs-vmnic4"
        vmnic5="management-dvs-vmnic5"
        vmnic6="management-dvs-vmnic6"
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.policy = vim.StringPolicy(value="loadbalance_loadbased")
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort = []
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic1)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic2)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic3)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic4)

    if portgroupname == "Management (VLAN 20) [compute-dvs]":
        vmnic1="compute-dvs-vmnic1"
        vmnic2="compute-dvs-vmnic2"
        vmnic3="compute-dvs-vmnic3"
        vmnic4="compute-dvs-vmnic4"
        vmnic5="compute-dvs-vmnic5"
        vmnic6="compute-dvs-vmnic6"
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.policy = vim.StringPolicy(value="loadbalance_loadbased")
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort = []
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic1)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic2)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic3)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic4)

    if portgroupname == "vMotion (VLAN 50) [compute-dvs]":
        vmnic1="compute-dvs-vmnic1"
        vmnic2="compute-dvs-vmnic2"
        vmnic3="compute-dvs-vmnic3"
        vmnic4="compute-dvs-vmnic4"
        vmnic5="compute-dvs-vmnic5"
        vmnic6="compute-dvs-vmnic6"
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.policy = vim.StringPolicy(value="loadbalance_loadbased")
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort = []
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic1)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic2)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic3)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic4)

    if portgroupname == "VSAN (VLAN 60) [compute-dvs]":
        vmnic1="compute-dvs-vmnic1"
        vmnic2="compute-dvs-vmnic2"
        vmnic3="compute-dvs-vmnic3"
        vmnic4="compute-dvs-vmnic4"
        vmnic5="compute-dvs-vmnic5"
        vmnic6="compute-dvs-vmnic6"
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.policy = vim.StringPolicy(value="loadbalance_loadbased")
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort = []
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic1)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic2)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic3)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic4)

    if portgroupname == "ISCSI 1 (VLAN 70) [compute-dvs]":
        vmnic1="compute-dvs-vmnic1"
        vmnic2="compute-dvs-vmnic2"
        vmnic3="compute-dvs-vmnic3"
        vmnic4="compute-dvs-vmnic4"
        vmnic5="compute-dvs-vmnic5"
        vmnic6="compute-dvs-vmnic6"
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.policy = vim.StringPolicy(value="failover_explicit")
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort = []
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic5)

    if portgroupname == "ISCSI 2 (VLAN 80) [compute-dvs]":
        vmnic1="compute-dvs-vmnic1"
        vmnic2="compute-dvs-vmnic2"
        vmnic3="compute-dvs-vmnic3"
        vmnic4="compute-dvs-vmnic4"
        vmnic5="compute-dvs-vmnic5"
        vmnic6="compute-dvs-vmnic6"
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.policy = vim.StringPolicy(value="failover_explicit")
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort = []
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic6)

    if portgroupname == "Applications (VLAN 30) [compute-dvs]":
        vmnic1="compute-dvs-vmnic1"
        vmnic2="compute-dvs-vmnic2"
        vmnic3="compute-dvs-vmnic3"
        vmnic4="compute-dvs-vmnic4"
        vmnic5="compute-dvs-vmnic5"
        vmnic6="compute-dvs-vmnic6"
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.policy = vim.StringPolicy(value="loadbalance_loadbased")
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort = []
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic1)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic2)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic3)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic4)

    if portgroupname == "Databases (VLAN 40) [compute-dvs]":
        vmnic1="compute-dvs-vmnic1"
        vmnic2="compute-dvs-vmnic2"
        vmnic3="compute-dvs-vmnic3"
        vmnic4="compute-dvs-vmnic4"
        vmnic5="compute-dvs-vmnic5"
        vmnic6="compute-dvs-vmnic6"
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.policy = vim.StringPolicy(value="loadbalance_loadbased")
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort = []
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic1)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic2)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic3)
        dv_pg_spec.defaultPortConfig.uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort.append(vmnic4)

    task = dv_switch.AddDVPortgroup_Task([dv_pg_spec])
    time.sleep(5)

    print("Successfully created DV Port Group", portgroupname)

def rename_uplink_portgroups(si):
    content = si.RetrieveContent()

    for portgroup in _get_vim_objects(content, vim.dvs.DistributedVirtualPortgroup):
        if portgroup.name[:5] == "manag":
            task = portgroup.Rename("management-uplinks")
            print("Changing Uplink Port Group Name to 'management-uplinks'")

        if portgroup.name[:5] == "compu":
            task = portgroup.Rename("compute-uplinks")
            print("Changing Uplink Port Group Name to 'compute-dvs'")

def move_vm(vm, network):
    device_change = []

    for device in vm.config.hardware.device:
        if isinstance(device, vim.vm.device.VirtualEthernetCard):
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

def migrate_vmk(host, target_portgroup, target_dvswitch, vmk):
    host_network_system = host.configManager.networkSystem
    config = vim.host.NetworkConfig()
    config.vnic = [create_host_vnic_config(target_portgroup, target_dvswitch, vmk)]
    host_network_system.UpdateNetworkConfig(config, "modify")

def create_vmk(host, target_portgroup, target_dvswitch, vmktype):
    
    host_config_manager = host.configManager
    host_network_system = host_config_manager.networkSystem
    host_virtual_vic_manager = host_config_manager.virtualNicManager

    config = vim.host.NetworkConfig()
    config.vnic = [create_host_vnic_config_for_add_new(target_portgroup, target_dvswitch)]
    host_network_config_result = host_network_system.UpdateNetworkConfig(config, "modify")

    for vnic_device in host_network_config_result.vnicDevice:
        if vmktype == "vsan":
            vsan_system = host_config_manager.vsanSystem
            vsan_config = vim.vsan.host.ConfigInfo()
            vsan_config.networkInfo = vim.vsan.host.ConfigInfo.NetworkInfo()
 
            vsan_config.networkInfo.port = [vim.vsan.host.ConfigInfo.NetworkInfo.PortConfig()]
 
            vsan_config.networkInfo.port[0].device = vnic_device
            host_vsan_config_result = vsan_system.UpdateVsan_Task(vsan_config)
 
        if vmktype == "vmotion":
            host_virtual_vic_manager.SelectVnicForNicType("vmotion", vnic_device)
 
    return True

def create_host_vnic_config_for_add_new(target_portgroup, target_dvswitch):
    host_vnic_config = vim.host.VirtualNic.Config()
    host_vnic_config.spec = vim.host.VirtualNic.Specification()

    host_vnic_config.changeOperation = "add"
    host_vnic_config.spec.ip = vim.host.IpConfig()
    host_vnic_config.spec.ip.dhcp = True
    host_vnic_config.spec.distributedVirtualPort = vim.dvs.PortConnection()
    host_vnic_config.spec.distributedVirtualPort.switchUuid = target_dvswitch.uuid
    host_vnic_config.spec.distributedVirtualPort.portgroupKey = target_portgroup.key

    return host_vnic_config
    
if __name__ == "__main__":
    exit(main())    