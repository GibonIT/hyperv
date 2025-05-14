#!usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Leos Marek (leos.marek@hotmail.com)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: gibonit.hyperv.hyperv_guest
short_description: Manage Hyper-V virtual machines
description:
- Create, configure, or remove Hyper-V virtual machines.
- Supports creating VMs with new or existing VHDX files, configuring memory, CPU, and attaching to virtual switches.
- Provides options for VM generation, boot device, and storage configuration.
options:
  state:
    description:
    - Desired state of the virtual machine.
    choices: [ present, absent ]
    default: present
    type: str
  name:
    description:
    - Name of the virtual machine.
    required: yes
    type: str
  generation:
    description:
    - Generation of the virtual machine (1 or 2).
    default: 2
    type: int
  startup_memory_gb:
    description:
    - Startup memory for the virtual machine in GB.
    default: 4
    type: int
  cpu_count:
    description:
    - Number of processors for the virtual machine.
    - Note: This can only be set after VM creation using the Set-VMProcessor command.
    type: int
  path:
    description:
    - Path to store the virtual machine configuration files.
    type: str
  switch:
    description:
    - Name of the virtual switch to connect the virtual machine to.
    type: str
  new_vhdx:
    description:
    - Whether to create a new VHDX file for the virtual machine.
    type: bool
  new_vhdx_size_gb:
    description:
    - Size of the new VHDX file in GB.
    default: 20
    type: int
  new_vhdx_path:
    description:
    - Path to store the new VHDX file.
    type: str
  boot_device:
    description:
    - Boot device for the virtual machine.
    choices: [ cd, ide, networkadapter, vhd ]
    default: networkadapter
    type: str
  existing_vhdx_path:
    description:
    - Path to an existing VHDX file to attach to the virtual machine.
    type: str
  vmid:
    description:
    - ID of the virtual machine.
    type: str
  remove_vhdx:
    description:
    - Whether to remove the associated VHDX file when deleting the virtual machine.
    default: false
    type: bool
notes:
- Ensure the Hyper-V role is installed and enabled on the host system.
- Some settings, such as the number of CPUs, must be configured after VM creation due to limitations of the New-VM PowerShell cmdlet.
- Use the gibonit.hyperv.hyperv_guest_customization module for advanced VM customization.
seealso:
- module: gibonit.hyperv.hyperv_guest_powerstate
- module: gibonit.hyperv.hyperv_guest_customization
author:
- Leos Marek (@GibonIT)
'''

EXAMPLES = r'''
- name: Create a new VM
  gibonit.hyperv.hyperv_guest:
    name: TestVM
    state: present

- name: Create a new VM with 4 cores
  gibonit.hyperv.hyperv_guest:
    name: TestVM
    state: present
    cpu_count: 4

- name: Create VM with new VHDX and attach to a virtual switch
  gibonit.hyperv.hyperv_guest:
    name: TestVM
    state: present
    new_vhdx: true
    new_vhdx_size_gb: 50
    switch: DefaultSwitch

- name: Remove VM and VHDX
  gibonit.hyperv.hyperv_guest:
    name: TestVM
    state: absent
    remove_vhdx: true
'''

RETURN = r'''
vm_deploy_info:
  description: Metadata about the new virtual machine.
  returned: changed
  type: dict
  sample:
    vmname: TestVM
    vmid: "12345678-1234-1234-1234-123456789abc"
    ConfigurationLocation: "C:\\Hyper-V\\TestVM"
    SmartPagingFilePath: "C:\\Hyper-V\\TestVM"
    ProcessorCount: 4
    SnapshotFileLocation: "C:\\Hyper-V\\TestVM\\Snapshots"
    MemoryStartup: 4294967296
    Generation: 2
    Path: "C:\\Hyper-V\\TestVM"
    Harddrives:
      - "C:\\Hyper-V\\TestVM\\Virtual Hard Disks\\TestVM.vhdx"
'''
