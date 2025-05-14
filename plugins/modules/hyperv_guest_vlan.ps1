#!powershell

# Copyright: (c) 2025, Leos Marek (@GibonIT)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

# Parameters section

$Erroractionpreference = "Stop"

$spec = @{
    options = @{
        name = @{ type = "str" }
        vmid = @{ type = "str" }
        adapter_name = @{ type = "str" }
        vlan_id = @{ type = "int"; required = $true }
        access_mode = @{ type = "str"; choices = @("access", "trunk"); default = "access" }
        trunk_vlan_ids = @{ type = "str" }
    }
    mutually_exclusive = @(
        , @( 'name', 'vmid' )
    )
    required_one_of = @(
        , @( 'name', 'vmid' )
    )
    required_if = @(
        , @( 'access_mode','trunk', @( 'trunk_vlan_ids'), $true)
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

# Script section
if ($name) {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if ($vm.Count -gt 1) {
        $module.FailJson("Found more than 1 VM with name '$name'. Use the 'vmid' parameter to specify the correct VM.")
    }
}
elseif ($vmid) {
    $vm = Get-VM -Id $vmid -ErrorAction SilentlyContinue
}

if (!$vm) {
    $module.FailJson("No VM found with the specified name or ID.")
}

$adapters = Get-VMNetworkAdapter -VM $vm

if ($adapters.Count -eq 0) {
    $module.FailJson("No network adapters found for the specified VM.")
}
elseif ($adapters.Count -eq 1 -and -not $adapterName) {
    $adapter = $adapters[0]
}
elseif ($adapterName) {
    $adapter = $adapters | Where-Object { $_.Name -eq $adapterName }
    if (!$adapter) {
        $module.FailJson("No network adapter found with the specified name '$adapterName'.")
    }
}
else {
    $module.FailJson("Multiple network adapters found. Specify the 'adapter_name' parameter to select one.")
}

$settingsChanged = $false

if ($accessMode -eq "access") {
    if ($adapter.VlanSetting.OperationMode -ne "access" -or $adapter.VlanSetting.accessVlanId -ne $vlanId) {
        $settingsChanged = $true
    }
}
elseif ($accessMode -eq "trunk") {
    if ($adapter.VlanSetting.OperationMode -ne "trunk" -or -not ($trunkVlanIds -eq $adapter.VlanSetting.trunkVlanIdList)) {
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
}
else {
    try {
        if ($accessMode -eq "access") {
            if ($adapter.VlanSetting.OperationMode -eq "trunk") {
            # Change the adapter to untagged mode before setting to access otherwise it fails
            Set-VMNetworkAdapterVlan -VMNetworkAdapter $adapter -Untagged -ErrorAction Stop
            }
            $results = Set-VMNetworkAdapterVlan -VMNetworkAdapter $adapter -access -VlanId $vlanId -ErrorAction Stop -Passthru
        }
        elseif ($accessMode -eq "trunk") {
            $results = Set-VMNetworkAdapterVlan -VMNetworkAdapter $adapter -trunk -AllowedVlanIdList $trunkVlanIds -NativeVlanId $vlanId -ErrorAction Stop -Passthru
        }

        $hashTable = @{}
        $results | Get-Member -MemberType Properties | Where-Object {
            $_.Name -in @('OperationMode', 'AccessVlanId', 'NativeVlanId', 'AllowedVlanIdList')
        } | ForEach-Object {
            $value = $results.$($_.Name)
            if ($null -ne $value -and $value -ne '') {
                $hashTable.Add($_.Name, $value)
            }
        }

        $module.result.changed = $true
        $module.result.vlan_configuration = $hashTable
    }
    Catch {
        $module.FailJson($_)
    }
}

$module.ExitJson()

