#!powershell

# Copyright: (c) 2025, Leos Marek (@GibonIT)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

# Parameters section

$Erroractionpreference = "Stop"

$spec = @{
    options = @{
        state = @{ type = "str"; choices = @( "present", "absent" ); default = "present" }
        name = @{ type = "str" }
        vmid = @{ type = "str" }
        path = @{ type = "str" }
        controller_number = @{ type = "int" }
        controller_location = @{ type = "int" }
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
$path = $module.Params.path
$controllerNumber = $module.Params.controller_number
$controllerLocation = $module.Params.controller_location

$result = @{
    changed = $false
}

# Script section

if ($name) {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if ($vm.Count -gt 1) {
        $module.FailJson("Found more than 1 VM with name $name. Use id parameter to manage the correct one.")
    }
}
elseif ($vmid) {
    $vm = Get-VM -Id $vmid -ErrorAction SilentlyContinue
}

if ($vm) {
    $dvdDriveParams = @{
        VMName = $vm.Name
    }
    if ($controllerNumber -ne $null) {
        $dvdDriveParams.ControllerNumber = $controllerNumber
    }
    if ($controllerLocation -ne $null) {
        $dvdDriveParams.ControllerLocation = $controllerLocation
    }

    $dvdDrive = Get-VMDvdDrive @dvdDriveParams -ErrorAction SilentlyContinue

    switch ($state) {
        "present" {
            if ($dvdDrive) {
                if ($path -and $dvdDrive.Path -eq $path) {
                    $module.result.changed = $false
                }
                elseif (-not $path) {
                    $module.result.changed = $false
                }
                elseif ($module.CheckMode) {
                    $module.result.desired_action = "Update DVD drive path to $path for VM: $($vm.Name)"
                    $module.result.changed = $true
                }
                else {
                    try {
                        $setParams = @{}

                        if ($path) {
                            $setParams.Path = $path
                        }

                        Set-VMDvdDrive @dvdDriveParams @setParams
                        $module.result.changed = $true
                    }
                    Catch {
                        $module.FailJson($_)
                    }
                }
            }
            elseif ($module.CheckMode) {
                $module.result.desired_action = "Add DVD drive with path $path to VM: $($vm.Name)"
                $module.result.changed = $true
            }
            else {
                try {
                    $addParams = @{}
                    if ($path) {
                        $addParams.Path = $path
                    }
                    Add-VMDvdDrive @dvdDriveParams @addParams
                    $module.result.changed = $true
                }
                Catch {
                    $module.FailJson($_)
                }
            }
        }
        "absent" {
            if (-not $controllerNumber -or -not $controllerLocation) {
                $dvdDrive = Get-VMDvdDrive -VMName $vm.Name -ErrorAction SilentlyContinue
                if ($dvdDrive) {
                    $dvdDriveParams = @{
                    VMName = $vm.Name
                    ControllerNumber = $dvdDrive.ControllerNumber
                    ControllerLocation = $dvdDrive.ControllerLocation
                    }
                }
            }

            if ($dvdDrive) {
                if ($module.CheckMode) {
                    $module.result.desired_action = "Remove DVD drive from VM: $($vm.Name)"
                    $module.result.changed = $true
                }
                else {
                    try {
                        Remove-VMDvdDrive @dvdDriveParams
                        $module.result.changed = $true
                    }
                    Catch {
                        $module.FailJson($_)
                    }
                }
            }
            else {
                $module.result.changed = $false
            }
        }
    }
}
else {
    $module.FailJson("No VM found with the specified name or ID.")
}

$module.ExitJson()
