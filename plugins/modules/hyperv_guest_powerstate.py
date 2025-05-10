#!usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Leos Marek (leos.marek@hotmail.com)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: gibonnn.windows.hyperv_guest_powerstate
short_description: Manage the power state of Hyper-V virtual machines
description:
- Start, stop, save, or power off Hyper-V virtual machines.
- Supports managing VMs by name or ID.
options:
  state:
    description:
    - Desired power state of the virtual machine.
    choices: [ started, stopped, saved, poweroff ]
    default: started
    type: str
  name:
    description:
    - Name of the virtual machine to manage.
    - The action will fail if more than one VM with the same name exists. Use O(vmid) in such case.
    type: str
  vmid:
    description:
    - ID of the virtual machine to manage.
    type: str
  force:
    description:
    - Whether to force the operation (e.g., force stop or power off).
    type: bool
notes:
- Ensure the Hyper-V role is installed and enabled on the host system.
seealso:
- module: ansible.windows.win_hyperv
- module: ansible.windows.win_hyperv_network
author:
- Leos Marek (@Gibonnn)
'''

EXAMPLES = r'''
- name: Start a VM by name
  gibonnn.windows.hyperv_guest_powerstate:
    name: TestVM
    state: started

- name: Stop a VM gracefully
  gibonnn.windows.hyperv_guest_powerstate:
    name: TestVM
    state: stopped

- name: Save the state of a VM
  gibonnn.windows.hyperv_guest_powerstate:
    name: TestVM
    state: saved

- name: Force power off a VM
  gibonnn.windows.hyperv_guest_powerstate:
    name: TestVM
    state: poweroff
    force: true
'''

RETURN = r'''
'''
