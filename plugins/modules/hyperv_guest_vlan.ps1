# filepath: /home/gibon/data/gibonit/hyperv/plugins/modules/hyperv_network_adapter_vlan.ps1
#!powershell

# Copyright: (c) 2025, Leos Marek (@GibonIT)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$Erroractionpreference = "Stop"

$spec = @{
  options = @{
    name = @{ type = "str" }
    vmid = @{ type = "str" }
    adapter_name = @{ type = "str" }
    vlan_id = @{ type = "int"; required = $true }
    access_mode = @{ type = "str"; choices = @("access", "trunk"); default = "access" }
    trunk_vlan_ids = @{ type = "array" }
  }
  mutually_exclusive = @(
    , @( 'name', 'vmid' )
  )
  required_one_of = @(
    , @( 'name', 'vmid' )
  )
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$vmid = $module.Params.vmid
$adapterName = $module.Params.adapter_name
$vlanId = $module.Params.vlan_id
$accessMode = $module.Params.access_mode
$trunkVlanIds = $module.Params.trunk_vlan_ids

$result = @{
  changed = $false
}

Function Configure-NetworkAdapterVLAN {
  if ($name) {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if ($vm.Count -gt 1) {
      $module.FailJson("Found more than 1 VM with name '$name'. Use the 'vmid' parameter to specify the correct VM.")
    }
  } elseif ($vmid) {
    $vm = Get-VM -Id $vmid -ErrorAction SilentlyContinue
  }

  if (!$vm) {
    $module.FailJson("No VM found with the specified name or ID.")
  }

  $adapters = Get-VMNetworkAdapter -VM $vm
  if ($adapters.Count -eq 0) {
    $module.FailJson("No network adapters found for the specified VM.")
  } elseif ($adapters.Count -eq 1 -and -not $adapterName) {
    $adapter = $adapters[0]
  } elseif ($adapterName) {
    $adapter = $adapters | Where-Object { $_.Name -eq $adapterName }
    if (!$adapter) {
      $module.FailJson("No network adapter found with the specified name '$adapterName'.")
    }
  } else {
    $module.FailJson("Multiple network adapters found. Specify the 'adapter_name' parameter to select one.")
  }

  $settingsChanged = $false

  if ($accessMode -eq "access") {
    if ($adapter.VlanSetting -ne "access" -or $adapter.accessVlanId -ne $vlanId) {
      $settingsChanged = $true
    }
  } elseif ($accessMode -eq "trunk") {
    if ($adapter.VlanSetting -ne "trunk" -or -not ($trunkVlanIds -eq $adapter.trunkVlanIdList)) {
      $settingsChanged = $true
    }
  }

  if (-not $settingsChanged) {
    $module.result.changed = $false
    $module.ExitJson()
  }

  if ($module.CheckMode) {
    $module.result.desired_action = "Configure VLAN for network adapter: $($adapter.Name)"
    $module.result.changed = $true
  } else {
    try {
      if ($accessMode -eq "access") {
        Set-VMNetworkAdapterVlan -VMNetworkAdapter $adapter -access -VlanId $vlanId -ErrorAction Stop
      } elseif ($accessMode -eq "trunk") {
        Set-VMNetworkAdapterVlan -VMNetworkAdapter $adapter -trunk -AllowedVlanIdList $trunkVlanIds -NativeVlanId $vlanId -ErrorAction Stop
      }

      $module.result.changed = $true
      # $module.result.vlan_configuration = @{
      #   adapter_name = $adapter.Name
      #   vlan_id = $vlanId
      #   access_mode = $accessMode
      #   trunk_vlan_ids = $trunkVlanIds
      }
    } Catch {
      $module.FailJson($_)
    }
  }
}

Try {
    Configure-NetworkAdapterVLAN
} Catch {
    $module.FailJson($_)
}

$module.ExitJson()
