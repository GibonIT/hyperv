#!usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Leos Marek (leos.marek@hotmail.com)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: gibonit.hyperv.hyperv_guest_dvddrive
short_description: Manage DVD drives for Hyper-V virtual machines
description:
- Add, update, or remove DVD drives for Hyper-V virtual machines.
- Supports specifying the controller number, location, and ISO path for the DVD drive.
options:
  state:
    description:
    - Desired state of the DVD drive.
    choices: [ present, absent ]
    default: present
    type: str
  name:
    description:
    - Name of the virtual machine.
    required: false
    type: str
  vmid:
    description:
    - ID of the virtual machine.
    required: false
    type: str
  path:
    description:
    - Path to the ISO file to attach to the DVD drive.
    required: false
    type: str
  controller_number:
    description:
    - Controller number for the DVD drive.
    required: false
    type: int
  controller_location:
    description:
    - Controller location for the DVD drive.
    required: false
    type: int
notes:
- Either C(name) or C(vmid) must be provided to identify the virtual machine.
- Ensure the Hyper-V role is installed and enabled on the host system.
seealso:
- module: gibonit.hyperv.hyperv_guest_create
- module: gibonit.hyperv.hyperv_guest_powerstate
author:
- Leos Marek (@GibonIT)
'''

EXAMPLES = r'''
- name: Add a DVD drive with an ISO to a VM
  gibonit.hyperv.hyperv_guest_dvddrive:
    name: TestVM
    state: present
    path: C:\ISOs\example.iso

- name: Remove a DVD drive from a VM
  gibonit.hyperv.hyperv_guest_dvddrive:
    name: TestVM
    state: absent

- name: Update the ISO path for an existing DVD drive
  gibonit.hyperv.hyperv_guest_dvddrive:
    name: TestVM
    state: present
    path: C:\ISOs\new_example.iso
'''

RETURN = r'''
'''
