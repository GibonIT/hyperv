#!powershell

# Copyright: (c) 2025, Leos Marek (@GibonIT)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$Erroractionpreference = "Stop"

$spec = @{
  options = @{
    # Global params
    state = @{ type = "str"; choices = @("present", "absent"); default = "present" }
    name = @{ type = "str"; required = $true }

    # state=present params
    generation = @{ type = "int"; default = 2 }
    startup_memory_gb = @{ type = "int"; default = 4 }
    path = @{ type = "str" }
    switch = @{ type = "str" }
    new_vhdx = @{ type = "bool"}
    new_vhdx_size_gb = @{ type = "int"; default = 20 }
    new_vhdx_path = @{ type = "str" }
    boot_device = @{ type = "str"; choices = @("cd", "ide", "networkadapter", "vhd"); default = "networkadapter" }
    existing_vhdx_path = @{ type = "str" }
    cpu_count = @{ type = "int" }

    # state=absent params
    vmid = @{ type = "str" }
    remove_vhdx = @{ type = "bool"; default = $false}
  }
  mutually_exclusive = @(
    , @( 'new_vhdx', 'existing_vhdx_path' )
  )
  required_if = @(
    , @( 'boot_device','vhd', @( 'new_vhdx', 'existing_vhdx_path'), $true)
  )
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$state = $module.Params.state
$name = $module.Params.name
$generation = $module.Params.generation
$memory = $module.Params.startup_memory_gb
$path = $module.Params.path
$networkSwitch = $module.Params.switch
$newVhdx = $module.Params.new_vhdx
$newVhdxSizeGb = $module.Params.new_vhdx_size_gb
$newVhdxPath = $module.Params.new_vhdx_path
$bootDevice = $module.Params.boot_device
$existingVhdxPath = $module.Params.existing_vhdx_path
$cpuCount = $module.Params.cpu_count
$vmid = $module.Params.vmid
$removeVhdx = $module.Params.remove_vhdx

$result = @{
  changed = $false
}

Function Create-VM {
  # Fail fast block
  if ($bootDevice -eq "ide" -and $generation -eq 2) {
    $module.FailJson('Generation 2 VM does not support ide bootdevice. Use vhd instead.')
  }

  if ($bootDevice -eq "cd" -and ($newVhdx -or $existingVhdxPath)) {
    $error_msg = "Can't set CD as the boot device when adding disks to a VM." +
    " First, create the VM without disks and attach them later using the hyperv_guest_customization module, " +
    "or create the VM with disks and then add the CD-ROM as the boot device using the same module."
    $module.FailJson($error_msg)
  }

  $CheckVM = Get-VM -Name $name -ErrorAction SilentlyContinue

  if (!$CheckVM) {
    $newVmParams = @{
      Name = $name
    }

    if ($memory) {
      $newVmParams.MemoryStartupBytes = $memory * 1GB
    }

    if ($generation) {
      $newVmParams.Generation = $generation
    }

    if ($networkSwitch) {
      $newVmParams.SwitchName = $networkSwitch
    }

    if (!$path) {
      $defaultVmPath = (Get-VMhost).VirtualMachinePath
      $newVmParams.Path = $defaultVmPath
    } else {
      $newVmParams.Path = $path
    }

    if ($newVhdx -and $newVhdxPath) {
      $newVmParams.NewVHDPath = $newVhdxPath
      $newVmParams.NewVHDSizeBytes = $newVhdxSizeGb * 1GB
    } elseif ($newVhdx -and $path) {
      $vhdxPath = Join-Path -Path $path -ChildPath "$name\Virtual Hard Disks\$name.vhdx"
      $newVmParams.NewVHDPath = $vhdxPath
      $newVmParams.NewVHDSizeBytes = $newVhdxSizeGb * 1GB
    } elseif ($newVhdx) {
      $defaultVhdxPath = (Get-VMhost).VirtualHardDiskPath
      $vhdxPath = Join-Path -Path $defaultVhdxPath -ChildPath "$name.vhdx"
      $newVmParams.NewVHDPath = $vhdxPath
      $newVmParams.NewVHDSizeBytes = $newVhdxSizeGb * 1GB
    }

    if ($existingVhdxPath) {
      $newVmParams.VHDPath = $existingVhdxPath
    }

    if ($module.CheckMode) {
      $module.result.desired_action = "Create VM: $name"
      $module.result.changed = $true
    } else {
      try {
        $results = New-VM @newVmParams

        if ($cpuCount) {
          Set-VMProcessor -VMName $name -Count $cpuCount
        }

        $hashTable = @{}
        $results | Get-Member -MemberType Properties | Where-Object {
          $_.Name -in @('Vmname', 'vmid', 'ConfigurationLocation', 'SmartPagingFilePath', 'ProcessorCount','SnapshotFileLocation', 'MemoryStartup', 'Generation', 'Path', 'harddrives')
        } | ForEach-Object {
          $value = $results.$($_.Name)
          if ($null -ne $value -and $value -ne '') {
          $hashTable.Add($_.Name, $value)
          }
        }

        $module.result.vm_deploy_info = $hashTable
        $module.result.changed = $true
      } Catch {
        $module.FailJson($_)
      }
    }
  } else {
    $module.result.changed = $false
  }
}

Function Delete-VM {
  if ($name) {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if ($vm.Count -gt 1) {
      $module.FailJson('Found more than 1 VM with name $name. Use id parameter to remove the correct one.')
    }
  } elseif ($id) {
    $vm = Get-VM -Id $id -ErrorAction SilentlyContinue
  }

  if ($vm) {
    if ($module.CheckMode) {
      $module.result.desired_action = "Remove VM: $($vm.Name)"
      $module.result.changed = $true
    } else {
      try {
        if ($removeVhdx) {
          $vmHardDrives = Get-VMHardDiskDrive -VMName $vm.Name -ErrorAction SilentlyContinue
          foreach ($disk in $vmHardDrives) {
            Remove-Item -Path $disk.Path -Force -ErrorAction SilentlyContinue
          }
        }
        Remove-VM -VM $vm -Force
        $module.result.changed = $true
      } Catch {
        $module.FailJson($_)
      }
    }
  } else {
    $module.result.changed = $false
  }
}

Try {
    switch ($state) {
        "present" { Create-VM }
        "absent" { Delete-VM }
    }
} Catch {
    $module.FailJson($_)
}

$module.ExitJson()
