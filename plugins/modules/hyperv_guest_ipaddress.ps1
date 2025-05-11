# Copyright: (c) 2025, Leos Marek (@GibonIT)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$ErrorActionPreference = "Stop"

$spec = @{
  options = @{
    name = @{ type = "str"; required = $true }
    mask = @{ type = "str"; required = $true }
    gateway = @{ type = "str"; required = $true }
    ipaddress = @{ type = "str"; required = $true }
    dnsservers = @{ type = "list"; required = $false }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vmName = $module.Params.name
$mask = $module.Params.mask
$gateway = $module.Params.gateway
$ipAddress = $module.Params.ipaddress
$dnsServers = $module.Params.dnsservers

$result = @{
  changed = $false
}

Function Set-VMIp {
  param (
    [string]$VMname,
    [string]$Mask,
    [string]$GateW,
    [string]$IPaddress,
    [string[]]$DNSServers
  )

    $VMManServ = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_VirtualSystemManagementService

    $vm = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' | Where-Object { $_.ElementName -eq $VMname }

    $vmSettings = $vm.GetRelated('Msvm_VirtualSystemSettingData') | Where-Object { $_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized' }

    $nwAdapters = $vmSettings.GetRelated('Msvm_SyntheticEthernetPortSettingData')

    $ipstuff = $nwAdapters.GetRelated('Msvm_GuestNetworkAdapterConfiguration')

    $ipstuff.DHCPEnabled = $false
    $ipstuff.DNSServers = $DNSServers
    $ipstuff.IPAddresses = $IPaddress
    $ipstuff.Subnets = $Mask
    $ipstuff.DefaultGateways = $GateW

    $setIP = $VMManServ.SetGuestNetworkAdapterConfiguration($vm, $ipstuff.GetText(1))
}


Try {
  if ($module.CheckMode) {
    $module.result.desired_action = "Set IP configuration for VM $vmName on host $vmHost"
    $module.result.changed = $true
  } else {
    Set-VMIp -VMname $vmName -Mask $mask -GateW $gateway -IPaddress $ipAddress -DNSServers $dnsServers
    $module.result.changed = $true
  }
} Catch {
  $module.FailJson($_)
}

$module.ExitJson()
