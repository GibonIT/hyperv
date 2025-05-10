#!powershell

# Copyright: (c) 2025, Leos Marek (@Gibonnn)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$Erroractionpreference = "Stop"

$spec = @{
  options = @{
    # Global params
    state = @{ type = "str"; choices = @( "started", "stopped", "saved", "poweroff" ); default = "started" }
    name = @{ type = "str"}
    vmid = @{ type = "str" }
    force = @{ type = "bool"}
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

$state = $module.Params.state
$name = $module.Params.name
$vmid = $module.Params.vmid
$force = $module.Params.force

$result = @{
  changed = $false
}

Function Manage-VMState {
  if ($name) {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if ($vm.Count -gt 1) {
      $module.FailJson("Found more than 1 VM with name $name. Use id parameter to manage the correct one.")
    }
  } elseif ($id) {
    $vm = Get-VM -Id $id -ErrorAction SilentlyContinue
  }

  if ($vm) {
    switch ($state) {
      "started" {
        if ($vm.State -eq "Running") {
          $module.result.changed = $false
        } elseif ($module.CheckMode) {
          $module.result.desired_action = "Start VM: $($vm.Name)"
          $module.result.changed = $true
        } else {
          try {
            Start-VM -VM $vm
            $module.result.changed = $true
          } Catch {
            $module.FailJson($_)
          }
        }
      }
      "stopped" {
        if ($vm.State -eq "Off") {
          $module.result.changed = $false
        } elseif ($module.CheckMode) {
          $module.result.desired_action = "Stop VM gracefully: $($vm.Name)"
          $module.result.changed = $true
        } else {
          try {
            Stop-VM -VM $vm -Force:$force
            $module.result.changed = $true
          } Catch {
            $module.FailJson($_)
          }
        }
      }
      "poweroff" {
        if ($vm.State -eq "Off") {
          $module.result.changed = $false
        } elseif ($module.CheckMode) {
          $module.result.desired_action = "Power off VM: $($vm.Name)"
          $module.result.changed = $true
        } else {
          try {
            Stop-VM -VM $vm -TurnOff -Force:$force
            $module.result.changed = $true
          } Catch {
            $module.FailJson($_)
          }
        }
      }
      "saved" {
        if ($vm.State -eq "Saved") {
          $module.result.changed = $false
        } elseif ($module.CheckMode) {
          $module.result.desired_action = "Save VM state: $($vm.Name)"
          $module.result.changed = $true
        } else {
          try {
            Save-VM -VM $vm
            $module.result.changed = $true
          } Catch {
            $module.FailJson($_)
          }
        }
      }
    }
  } else {
    $module.FailJson("No VM found with the specified name or ID.")
  }
}

Try {
    switch ($state) {
        "started" { Manage-VMState }
        "stopped" { Manage-VMState }
        "saved" { Manage-VMState }
        "poweroff" { Manage-VMState }
    }
} Catch {
    $module.FailJson($_)
}

$module.ExitJson()
