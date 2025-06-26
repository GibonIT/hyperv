#!usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Leos Marek (leos.marek@hotmail.com)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: gibonit.hyperv.hyperv_guest_vlan
short_description: Manage VLAN configuration for Hyper-V virtual machine network adapters
description:
- Configure VLAN settings for network adapters of Hyper-V virtual machines.
- Supports both access and trunk VLAN modes.
- Allows specifying VLAN IDs and trunk VLAN ID lists.
options:
  name:
    description:
    - Name of the virtual machine.
    - Mutually exclusive with C(vmid).
    type: str
  vmid:
    description:
    - ID of the virtual machine.
    - Mutually exclusive with C(name).
    type: str
  adapter_name:
    description:
    - Name of the network adapter to configure.
    - Required if the VM has multiple network adapters.
    type: str
  vlan_id:
    description:
    - VLAN ID to configure for the network adapter.
    required: yes
    type: int
  access_mode:
    description:
    - VLAN mode for the network adapter.
    choices: [ access, trunk ]
    default: access
    type: str
  trunk_vlan_ids:
    description:
    - Comma-separated list of VLAN IDs to allow in trunk mode.
    - Required if C(access_mode) is set to C(trunk).
    type: str
notes:
- Ensure the Hyper-V role is installed and enabled on the host system.
- Use the adapter_name parameter if the VM has multiple network adapters.
seealso:
- module: gibonit.hyperv.hyperv_guest_create
- module: gibonit.hyperv.hyperv_guest_powerstate
author:
- Leos Marek (@GibonIT)
'''

EXAMPLES = r'''
- name: Configure VLAN in access mode
  gibonit.hyperv.hyperv_guest_vlan:
    name: TestVM
    vlan_id: 100
    access_mode: access

- name: Configure VLAN in trunk mode
  gibonit.hyperv.hyperv_guest_vlan:
    name: TestVM
    vlan_id: 1
    access_mode: trunk
    trunk_vlan_ids: "100,200,300"

- name: Configure VLAN for a specific adapter
  gibonit.hyperv.hyperv_guest_vlan:
    name: TestVM
    adapter_name: Ethernet0
    vlan_id: 200
    access_mode: access

- name: Configure VLAN using VM ID
  gibonit.hyperv.hyperv_guest_vlan:
    vmid: 12345
    vlan_id: 300
    access_mode: access
'''

RETURN = r'''
vlan_configuration:
    description: Metadata about the VLAN configuration applied to the network adapter.
    returned: changed
    type: dict
    sample:
      OperationMode: 1
      AccessVlanId: 100
      AllowedVlanIdList: null
'''
