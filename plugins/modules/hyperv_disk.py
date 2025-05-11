#!usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Leos Marek (leos.marek@hotmail.com)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: gibonit.hyperv.hyperv_disk
short_description: Clone VHDX files on Windows systems
description:
- Clone a VHDX file to a new location with options for type and source deletion.
- Supports fixed, dynamic, and differencing VHDX types.
options:
  path:
    description:
    - Path to the source VHDX file.
    required: yes
    type: str
  destination_path:
    description:
    - Path to the destination VHDX file.
    required: yes
    type: str
  type:
    description:
    - Type of the cloned VHDX file.
    choices: [ fixed, dynamic, differencing ]
    default: dynamic
    type: str
  delete_source:
    description:
    - Whether to delete the source VHDX file after cloning.
    default: false
    type: bool
notes:
- Ensure the Hyper-V role is installed and enabled on the host system.
- The Convert-VHD PowerShell cmdlet is used for cloning operations.
seealso:
- module: gibonit.hyperv.hyperv_guest
- module: gibonit.hyperv.hyperv_guest_powerstate
author:
- Leos Marek (@GibonIT)
'''

EXAMPLES = r'''
- name: Clone a VHDX file to a new location
  gibonit.hyperv.hyperv_disk:
    path: C:\VMs\source.vhdx
    destination_path: C:\VMs\destination.vhdx

- name: Clone a VHDX file and delete the source
  gibonit.hyperv.hyperv_disk:
    path: C:\VMs\source.vhdx
    destination_path: C:\VMs\destination.vhdx
    delete_source: true

- name: Clone a VHDX file as a fixed type
  gibonit.hyperv.hyperv_disk:
    path: C:\VMs\source.vhdx
    destination_path: C:\VMs\destination_fixed.vhdx
    type: fixed
'''

RETURN = r'''
vhdx_info:
    description: Metadata about the cloned VHDX file.
    returned: changed
    type: dict
    sample:
      Path: C:\VMs\destination.vhdx
      Size: 10737418240
      Type: Dynamic
'''
