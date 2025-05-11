# Copyright: (c) 2025, Leos Marek (@GibonIT)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$ErrorActionPreference = "Stop"

$spec = @{
  options = @{
    path = @{ type = "str"; required = $true }
    destination_path = @{ type = "str"; required = $true }
    type = @{ type = "str"; choices = @("fixed", "dynamic", "differencing"); default = "dynamic" }
    delete_source = @{ type = "bool"; default = $false }
  }
  supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$sourceVhdxPath = $module.Params.path
$destinationVhdxPath = $module.Params.destination_path
$deleteSource = $module.Params.delete_source
$type = $module.Params.type

$result = @{
  changed = $false
}

Function Clone-VHDX {
  if (-Not (Test-Path -Path $sourceVhdxPath)) {
    $module.FailJson("Source VHDX file does not exist: $sourceVhdxPath")
  }

  if (Test-Path -Path $destinationVhdxPath) {
    $module.FailJson("Destination VHDX file already exists: $destinationVhdxPath")
  }

  if ($module.CheckMode) {
    $module.result.desired_action = "Clone VHDX from $sourceVhdxPath to $destinationVhdxPath"
    $module.result.changed = $true
  } else {
    try {
      $results = Convert-VHD -Path $sourceVhdxPath -DestinationPath $destinationVhdxPath -VHDType $type -DeleteSource:$deleteSource -Passthru
      $module.result.vhdx_info = $results
      $module.result.changed = $true
    } Catch {
      $module.FailJson($_)
    }
  }
}

Try {
  Clone-VHDX
} Catch {
  $module.FailJson($_)
}

$module.ExitJson()
