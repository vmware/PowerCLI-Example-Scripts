function Get-VMEvcMode {
<#  
.SYNOPSIS  
    Gathers information on the EVC status of a VM
.DESCRIPTION 
    Will provide the EVC status for the specified VM
.NOTES  
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com
.PARAMETER Name
    VM name which the function should be ran against
.EXAMPLE
	Get-VMEvcMode -Name vmName
	Retreives the EVC status of the provided VM 
#>
[CmdletBinding()] 
	param(
	[Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
        $Name
  	)

    Process {
        $evVM = @()

        if ($name -is [string]) {$evVM += Get-VM -Name $Name -ErrorAction SilentlyContinue}
        elseif ($name -is [array]) {

            if ($name[0] -is [string]) {
                $name | foreach {
                    $evVM += Get-VM -Name $_ -ErrorAction SilentlyContinue
                }
            }
            elseif ($name[0] -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl]) {$evVM = $name}

        }
        elseif ($name -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl]) {$evVM += $name}
        
        if ($evVM -eq $null) {Write-Warning "No VMs found."}
        else {
            $output = @()
            foreach ($v in $evVM) {

                $report = "" | select Name,EVCMode
                $report.Name = $v.Name
                $report.EVCMode = $v.ExtensionData.Runtime.MinRequiredEVCModeKey
                $output += $report

            }

        return $output

        }

    }

}

function Remove-VMEvcMode {
<#  
.SYNOPSIS  
    Removes the EVC status of a VM
.DESCRIPTION 
    Will remove the EVC status for the specified VM
.NOTES  
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com
.PARAMETER Name
    VM name which the function should be ran against
.EXAMPLE
	Remove-VMEvcMode -Name vmName
	Removes the EVC status of the provided VM 
#>
[CmdletBinding()] 
	param(
	[Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
        $Name
  	)

    Process {
        $evVM = @()
        $updateVM = @()

        if ($name -is [string]) {$evVM += Get-VM -Name $Name -ErrorAction SilentlyContinue}
        elseif ($name -is [array]) {

            if ($name[0] -is [string]) {
                $name | foreach {
                    $evVM += Get-VM -Name $_ -ErrorAction SilentlyContinue
                }
            }
            elseif ($name[0] -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl]) {$evVM = $name}

        }
        elseif ($name -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl]) {$evVM += $name}
        
        if ($evVM -eq $null) {Write-Warning "No VMs found."}
        else {
            foreach ($v in $evVM) {

                if (($v.HardwareVersion -ge 'vmx-14' -and $v.PowerState -eq 'PoweredOff') -or ($v.Version -ge 'v14' -and $v.PowerState -eq 'PoweredOff')) {

                    $v.ExtensionData.ApplyEvcModeVM_Task($null, $true) | Out-Null
                    $updateVM += $v.Name
                                        
                }
                else {Write-Warning $v.Name + " does not have the minimum requirements of being Hardware Version 14 and powered off."}

            }

            if ($updateVM) {
            
            Start-Sleep -Seconds 2
            Get-VMEvcMode -Name $updateVM
            
            }

        }

    }

}

function Set-VMEvcMode {
<#  
.SYNOPSIS  
    Configures the EVC status of a VM
.DESCRIPTION 
    Will configure the EVC status for the specified VM
.NOTES  
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com
.PARAMETER Name
    VM name which the function should be ran against
.PARAMETER EvcMode
    The EVC Mode key which should be set
.EXAMPLE
	Set-VMEvcMode -Name vmName -EvcMode intel-sandybridge
	Configures the EVC status of the provided VM to be 'intel-sandybridge'
#>
[CmdletBinding()] 
	param(
	[Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
        $Name,
    [Parameter(Mandatory=$true,Position=1)]
    [ValidateSet("intel-merom","intel-penryn","intel-nehalem","intel-westmere","intel-sandybridge","intel-ivybridge","intel-haswell","intel-broadwell","intel-skylake","amd-rev-e","amd-rev-f","amd-greyhound-no3dnow","amd-greyhound","amd-bulldozer","amd-piledriver","amd-steamroller","amd-zen")]
        $EvcMode
  	)

    Process {
        $evVM = @()
        $updateVM = @()

        if ($name -is [string]) {$evVM += Get-VM -Name $Name -ErrorAction SilentlyContinue}
        elseif ($name -is [array]) {

            if ($name[0] -is [string]) {
                $name | foreach {
                    $evVM += Get-VM -Name $_ -ErrorAction SilentlyContinue
                }
            }
            elseif ($name[0] -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl]) {$evVM = $name}

        }
        elseif ($name -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl]) {$evVM += $name}
        
        if ($evVM -eq $null) {Write-Warning "No VMs found."}
        else {

            $si = Get-View ServiceInstance
            $evcMask = $si.Capability.SupportedEvcMode | where-object {$_.key -eq $EvcMode} | select -ExpandProperty FeatureMask

            foreach ($v in $evVM) {

                if (($v.HardwareVersion -ge 'vmx-14' -and $v.PowerState -eq 'PoweredOff') -or ($v.Version -ge 'v14' -and $v.PowerState -eq 'PoweredOff')) {

                    $v.ExtensionData.ApplyEvcModeVM_Task($evcMask, $true) | Out-Null
                    $updateVM += $v.Name
                                        
                }
                else {Write-Warning $v.Name + " does not have the minimum requirements of being Hardware Version 14 and powered off."}

            }

            if ($updateVM) {
            
            Start-Sleep -Seconds 2
            Get-VMEvcMode -Name $updateVM
            
            }

        }

    }

}
