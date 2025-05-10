#!powershell

# Copyright: (c) 2025, Leos Marek (@Gibonnn)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$Erroractionpreference = "Stop"

$spec = @{
  options = @{
    name = @{ type = "str"}
    vmid = @{ type = "str" }
    startup_memory_gb = @{ type = "int" }
    processor_count = @{ type = "int" }
    dynamic_memory = @{ type = "bool" }
    minimum_memory_gb = @{ type = "int" }
    maximum_memory_gb = @{ type = "int" }
    checkpoint_type = @{ type = "str"; choices = @("disabled", "production", "productiononly", "standard") }
    automatic_start_action = @{ type = "str"; choices = @("nothing", "startifrunning", "start") }
    automatic_stop_action = @{ type = "str"; choices = @("save", "turnoff", "shutdown") }
    automatic_start_delay = @{ type = "int" }
    notes = @{ type = "str" }
    enable_automatic_checkpoints = @{ type = "bool" }
    force = @{ type = "bool"; default = $false }
    new_vm_name = @{ type = "str" }
    smartpaging_file_path = @{ type = "str" }
    snapshot_file_location = @{ type = "str" }
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
$startupMemoryGb = $module.Params.startup_memory_gb
$processorCount = $module.Params.processor_count
$dynamicMemory = $module.Params.dynamic_memory
$minimumMemoryGb = $module.Params.minimum_memory_gb
$maximumMemoryGb = $module.Params.maximum_memory_gb
$checkpointType = $module.Params.checkpoint_type
$automaticStartAction = $module.Params.automatic_start_action
$automaticStopAction = $module.Params.automatic_stop_action
$automaticStartDelay = $module.Params.automatic_start_delay
$notes = $module.Params.notes
$enableAutomaticCheckpoints = $module.Params.enable_automatic_checkpoints
$force = $module.Params.force
$newVMName = $module.Params.new_vm_name
$smartpagingFilePath = $module.Params.smartpaging_file_path
$snapshotFileLocation = $module.Params.snapshot_file_location

$result = @{
  changed = $false
}

Function Configure-VM {
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

  $cmd = "Set-VM -VMName '$($vm.Name)' -Passthru"
  $settingsChanged = $false

  if ($startupMemoryGb -and $vm.MemoryStartup -ne ($startupMemoryGb * 1GB)) {
    $cmd += " -MemoryStartupBytes $($startupMemoryGb * 1GB)"
    $settingsChanged = $true
  }

  if ($processorCount -and $vm.ProcessorCount -ne $processorCount) {
    $cmd += " -ProcessorCount $processorCount"
    $settingsChanged = $true
  }

  if ($dynamicMemory -ne $null -and $vm.DynamicMemoryEnabled -ne $dynamicMemory) {
    $cmd += " -DynamicMemory"
    $settingsChanged = $true
  }

  if ($minimumMemoryGb -and $vm.MemoryMinimum -ne ($minimumMemoryGb * 1GB)) {
    $cmd += " -MemoryMinimumBytes $($minimumMemoryGb * 1GB)"
    $settingsChanged = $true
  }

  if ($maximumMemoryGb -and $vm.MemoryMaximum -ne ($maximumMemoryGb * 1GB)) {
    $cmd += " -MemoryMaximumBytes $($maximumMemoryGb * 1GB)"
    $settingsChanged = $true
  }

  if ($checkpointType -and $vm.CheckpointType -ne $checkpointType) {
    $cmd += " -CheckpointType $checkpointType"
    $settingsChanged = $true
  }

  if ($automaticStartAction -and $vm.AutomaticStartAction -ne $automaticStartAction) {
    $cmd += " -AutomaticStartAction $automaticStartAction"
    $settingsChanged = $true
  }

  if ($automaticStopAction -and $vm.AutomaticStopAction -ne $automaticStopAction) {
    $cmd += " -AutomaticStopAction $automaticStopAction"
    $settingsChanged = $true
  }

  if ($automaticStartDelay -and $vm.AutomaticStartDelay -ne $automaticStartDelay) {
    $cmd += " -AutomaticStartDelay $automaticStartDelay"
    $settingsChanged = $true
  }

  if ($notes -and $vm.Notes -ne $notes) {
    $cmd += " -Notes '$notes'"
    $settingsChanged = $true
  }

  if ($enableAutomaticCheckpoints -ne $null -and $vm.AutomaticCheckpointsEnabled -ne $enableAutomaticCheckpoints) {
    $cmd += " -AutomaticCheckpointsEnabled $enableAutomaticCheckpoints"
    $settingsChanged = $true
  }

  if ($newVMName -and $vm.Name -ne $newVMName) {
    $cmd += " -NewVMName '$newVMName'"
    $settingsChanged = $true
  }

  if ($smartpagingFilePath -and $vm.SmartPagingFilePath -ne $smartpagingFilePath) {
    $cmd += " -SmartPagingFilePath '$smartpagingFilePath'"
    $settingsChanged = $true
  }

  if ($snapshotFileLocation -and $vm.SnapshotFileLocation -ne $snapshotFileLocation) {
    $cmd += " -SnapshotFileLocation '$snapshotFileLocation'"
    $settingsChanged = $true
  }

  if (-not $settingsChanged) {
    $module.result.changed = $false
    $module.ExitJson()
  }

  if ($force -and $vm.State -eq "Running") {
    Stop-VM -VM $vm -Force -ErrorAction Stop
  }

  if ($module.CheckMode) {
    $module.result.desired_action = "Configure VM: $($vm.Name)"
    $module.result.changed = $true
  } else {
    try {
      $results = Invoke-Expression $cmd

      $hashTable = @{}
      $results | Get-Member -MemberType Properties | Where-Object {
        $_.Name -in @('Vmname', 'vmid', 'ConfigurationLocation', 'SmartPagingFilePath', 'SnapshotFileLocation', 'MemoryStartup', 'Generation', 'Path', 'harddrives', 'ProcessorCount', 'DynamicMemoryEnabled', 'MemoryMaximum', 'MemoryMinimum', 'CheckpointType', 'AutomaticStartAction', 'AutomaticStopAction', 'AutomaticStartDelay', 'Notes','AutomaticCheckpointsEnabled','EnhancedSessionTransportType')
      } | ForEach-Object {
        $value = $results.$($_.Name)
        if ($null -ne $value -and $value -ne '') {
          $hashTable.Add($_.Name, $value)
        }
      }

      $module.result.vm_customization_info = $hashTable
      $module.result.changed = $true
    } Catch {
      $module.FailJson($_)
    }
  }

  if ($force -and $settingsChanged -and $vm.State -ne "Running") {
    Start-VM -VM $vm -ErrorAction Stop
  }
}

Try {
    Configure-VM
} Catch {
    $module.FailJson($_)
}

$module.ExitJson()
