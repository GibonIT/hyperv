#!usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Leos Marek (leos.marek@hotmail.com)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: gibonit.hyperv.hyperv_network
short_description: Configure network settings for Hyper-V guest VMs
description:
- Configure the IP address, subnet mask, gateway, and DNS servers for a Hyper-V guest virtual machine.
- Uses the Hyper-V WMI provider to apply network settings.
options:
    name:
        description:
        - Name of the virtual machine to configure.
        required: yes
        type: str
    ipaddress:
        description:
        - Static IP address to assign to the virtual machine.
        required: yes
        type: str
    mask:
        description:
        - Subnet mask to assign to the virtual machine.
        required: yes
        type: str
    gateway:
        description:
        - Default gateway to assign to the virtual machine.
        required: yes
        type: str
    dnsservers:
        description:
        - List of DNS servers to assign to the virtual machine.
        required: no
        type: list
        elements: str
notes:
- Ensure the Hyper-V role is installed and enabled on the host system.
- This module uses the Hyper-V WMI provider for network configuration.
seealso:
- module: gibonit.hyperv.hyperv_disk
- module: gibonit.hyperv.hyperv_guest
author:
- Leos Marek (@GibonIT)
'''

EXAMPLES = r'''
- name: Configure network settings for a VM
    gibonit.hyperv.hyperv_network:
        name: TestVM
        ipaddress: 192.168.1.100
        mask: 255.255.255.0
        gateway: 192.168.1.1
        dnsservers:
            - 8.8.8.8
            - 8.8.4.4

- name: Configure network settings without DNS servers
    gibonit.hyperv.hyperv_network:
        name: TestVM
        ipaddress: 192.168.1.101
        mask: 255.255.255.0
        gateway: 192.168.1.1
'''

RETURN = r'''
'''
