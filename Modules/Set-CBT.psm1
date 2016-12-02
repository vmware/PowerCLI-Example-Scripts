function Set-CBT {
<#	
    .NOTES
    ===========================================================================
    Created by: Markus Kraus
    Twitter: @VMarkus_K
    Private Blog: mycloudrevolution.com
    ===========================================================================
    Changelog:  
    2016.11 ver 1.0 Base Release 
    ===========================================================================
    External Code Sources:  
    http://wahlnetwork.com/2015/12/01/change-block-tracking-cbt-powercli/
    ===========================================================================
    Tested Against Environment:
    vSphere Version: 5.5 U2
    PowerCLI Version: PowerCLI 6.3 R1
    PowerShell Version: 4.0
    OS Version: Windows Server 2012 R2
    ===========================================================================
    Keywords vSphere, ESXi, VM, Storage, CBT, Backup
    ===========================================================================

    .DESCRIPTION
    This Function enables or disables CBT.       

    .Example
    Get-VN TST* | Set-CBT -DisableCBT  

    .Example
    Get-VN TST* | Set-CBT -EnableCBT  

    .PARAMETER DisableCBT
    Disables CBT for any VMs found with it enabled

    .PARAMETER EnableCBT
    Enables CBT for any VMs found with it disabled

#Requires PS -Version 4.0
#Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="6.3.0.0"}
#>

  [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage = "VMs to process")]
        [ValidateNotNullorEmpty()]
        	[VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]] $myVMs,
        [Parameter(Mandatory = $False,ValueFromPipeline=$False, Position = 1, HelpMessage = "Enables CBT for any VMs found with it disabled", ParameterSetName = "EnableCBT")]
        [ValidateNotNullorEmpty()]
            [Switch]$EnableCBT,
        [Parameter(Mandatory = $False,ValueFromPipeline=$False, Position = 1, HelpMessage = "Disables CBT for any VMs found with it enabled", ParameterSetName = "DisableCBT")]
        [ValidateNotNullorEmpty()]
            [Switch]$DisableCBT
    )
Process { 

	    $vmconfigspec = New-Object -TypeName VMware.Vim.VirtualMachineConfigSpec
        Write-Verbose -Message "Walking through given VMs"
        foreach($myVM in $myVMs)
        {
            if ($DisableCBT -and $myVM.ExtensionData.Config.ChangeTrackingEnabled -eq $true -and $myVM.ExtensionData.Snapshot -eq $null)
            {
                try 
                {
                    Write-Verbose -Message "Reconfiguring $($myVM.name) to disable CBT" -Verbose
                    $vmconfigspec.ChangeTrackingEnabled = $false
                    $myVM.ExtensionData.ReconfigVM($vmconfigspec)

                    if ($myVM.PowerState -eq "PoweredOn" ) {
                        Write-Verbose -Message "Creating a snapshot on $($myVM.name) to clear CBT file" -Verbose
                        $SnapShot = New-Snapshot -VM $myVM -Name "CBT Cleanup"

                        Write-Verbose -Message "Removing snapshot on $($myVM.name)" -Verbose
                        $SnapShot|  Remove-Snapshot -Confirm:$false
                    }

                }
                catch 
                {
                    throw $myVM
                }
            }
            elseif ($EnableCBT -and $myVM.ExtensionData.Config.ChangeTrackingEnabled -eq $false -and $myVM.ExtensionData.Snapshot -eq $null)
            {
                Write-Verbose -Message "Reconfiguring $($myVM.name) to enable CBT" -Verbose
                $vmconfigspec.ChangeTrackingEnabled = $true
                $myVM.ExtensionData.ReconfigVM($vmconfigspec)

                if ($myVM.PowerState -eq "PoweredOn" ) {
                    Write-Verbose -Message "Creating a snapshot on $($myVM.name) to Create CBT file" -Verbose
                    $SnapShot = New-Snapshot -VM $myVM -Name "CBT Cleanup"

                    Write-Verbose -Message "Removing snapshot on $($myVM.name)" -Verbose
                    $SnapShot |  Remove-Snapshot -Confirm:$false
                }
            }
            else 
            {
                if ($myVM.ExtensionData.Snapshot -ne $null -and $EnableCBT) 
                {
                    Write-Warning -Message "Skipping $($myVM.name) - Snapshots found"
                }
                elseif ($myVM.ExtensionData.Snapshot -ne $null -and $DisableCBT) 
                {
                    Write-Warning -Message "Skipping $($myVM.name) - Snapshots found"
                }
            }
        }

	}
}
