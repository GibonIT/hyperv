#!usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Leos Marek (leos.marek@hotmail.com)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: gibonit.hyperv.hyperv_guest_customization
short_description: Customize Hyper-V virtual machines
description:
- Modify settings of existing Hyper-V virtual machines.
- Supports configuring memory, processors, checkpoints, and other VM properties.
options:
  name:
    description:
    - Name of the virtual machine to customize.
    - The action will fail if more than one VM with the same name exists. Use O(vmid) in such case.
    type: str
  vmid:
    description:
    - ID of the virtual machine to customize.
    type: str
  startup_memory_gb:
    description:
    - Startup memory for the virtual machine in GB.
    type: int
  processor_count:
    description:
    - Number of processors for the virtual machine.
    type: int
  dynamic_memory:
    description:
    - Enable or disable dynamic memory for the virtual machine.
    type: bool
  minimum_memory_gb:
    description:
    - Minimum memory for the virtual machine in GB when dynamic memory is enabled.
    type: int
  maximum_memory_gb:
    description:
    - Maximum memory for the virtual machine in GB when dynamic memory is enabled.
    type: int
  checkpoint_type:
    description:
    - Type of checkpoint for the virtual machine.
    choices: [ disabled, production, productiononly, standard ]
    type: str
  automatic_start_action:
    description:
    - Action to take when the host starts.
    choices: [ nothing, startifrunning, start ]
    type: str
  automatic_stop_action:
    description:
    - Action to take when the host shuts down.
    choices: [ save, turnoff, shutdown ]
    type: str
  automatic_start_delay:
    description:
    - Delay in seconds before starting the virtual machine automatically.
    type: int
  notes:
    description:
    - Notes or description for the virtual machine.
    type: str
  enable_automatic_checkpoints:
    description:
    - Enable or disable automatic checkpoints for the virtual machine.
    type: bool
  force:
    description:
    - Force the changes by stopping the virtual machine if necessary.
    default: false
    type: bool
  new_vm_name:
    description:
    - Rename the virtual machine.
    type: str
  smartpaging_file_path:
    description:
    - Path for the smart paging file.
    type: str
  snapshot_file_location:
    description:
    - Path for storing snapshot files.
    type: str
notes:
- Ensure the Hyper-V role is installed and enabled on the host system.
- Use this module to modify existing virtual machines. For creating new VMs, use the gibonit.hyperv.hyperv_guest module.
seealso:
- module: gibonit.hyperv.hyperv_guest_create
- module: gibonit.hyperv.hyperv_guest_powerstate
author:
- Leos Marek (@GibonIT)
'''

EXAMPLES = r'''
- name: Update VM memory and processors
  gibonit.hyperv.hyperv_guest_customization:
    name: TestVM
    startup_memory_gb: 8
    processor_count: 4

- name: Enable dynamic memory with limits
  gibonit.hyperv.hyperv_guest_customization:
    name: TestVM
    dynamic_memory: true
    minimum_memory_gb: 4
    maximum_memory_gb: 16

- name: Rename a virtual machine
  gibonit.hyperv.hyperv_guest_customization:
    name: TestVM
    new_vm_name: RenamedVM

- name: Configure automatic start and stop actions
  gibonit.hyperv.hyperv_guest_customization:
    name: TestVM
    automatic_start_action: start
    automatic_stop_action: save
'''

RETURN = r'''
vm_customization_info:
    description: Metadata about the customized virtual machine.
    returned: changed
    type: dict
    sample: {
        "Vmname": "TestVM",
        "ProcessorCount": 4,
        "MemoryStartup": 8589934592,
        "DynamicMemoryEnabled": true,
        "MemoryMinimum": 4294967296,
        "MemoryMaximum": 17179869184,
        "CheckpointType": "Production",
        "AutomaticStartAction": "Start",
        "AutomaticStopAction": "Save"
    }
'''
