function Apply-Hardening {
<#	
    .NOTES
    ===========================================================================
    Created by: Markus Kraus
    Twitter: @VMarkus_K
    Private Blog: mycloudrevolution.com
    ===========================================================================
    Changelog:  
    2016.11 ver 2.0 Base Release 
    ===========================================================================
    External Code Sources:  
    
    ===========================================================================
    Tested Against Environment:
    vSphere Version: 5.5 U2
    PowerCLI Version: PowerCLI 6.3 R1, PowerCLI 6.5 R1
    PowerShell Version: 4.0, 5.0
    OS Version: Windows 8.1, Server 2012 R2
    Keyword: VM, Hardening, Security
    ===========================================================================

    .DESCRIPTION
    Applys a set of Hardening options to your VMs

    .Example
    Get-VM TST* | Apply-Hardening 

    .Example
    $SampleVMs = Get-VM "TST*"
    Apply-Hardening -VMs $SampleVMs

    .PARAMETER VMs
    Specify the VMs 


#Requires PS -Version 4.0
#Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="6.3.0.0"}
#>

[CmdletBinding()]
param( 
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$True,
                Position=0)]
    [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]
    $VMs
)

Process { 
#region: Create Options
	$ExtraOptions = @{
		"isolation.tools.diskShrink.disable"="true";
		"isolation.tools.diskWiper.disable"="true";
		"isolation.tools.copy.disable"="true";
		"isolation.tools.paste.disable"="true";
		"isolation.tools.dnd.disable"="true";
		"isolation.tools.setGUIOptions.enable"="false"; 
		"log.keepOld"="10";
		"log.rotateSize"="100000"
		"RemoteDisplay.maxConnections"="2";
		"RemoteDisplay.vnc.enabled"="false";  
	
	}
    if ($DebugPreference -eq "Inquire") {
        Write-Output "VM Hardening Options:"
        $ExtraOptions | Format-Table -AutoSize
    }
	
	$VMConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
	
	Foreach ($Option in $ExtraOptions.GetEnumerator()) {
		$OptionValue = New-Object VMware.Vim.optionvalue
		$OptionValue.Key = $Option.Key
		$OptionValue.Value = $Option.Value
		$VMConfigSpec.extraconfig += $OptionValue
	}
#endregion

#region: Apply Options
	ForEach ($VM in $VMs){
			$VMv = Get-VM $VM | Get-View
		$state = $VMv.Summary.Runtime.PowerState
		Write-Output "...Starting Reconfiguring VM: $VM "
		$TaskConf = ($VMv).ReconfigVM_Task($VMConfigSpec)
			if ($state -eq "poweredOn") {
				Write-Output "...Migrating VM: $VM "
				$TaskMig = $VMv.MigrateVM_Task($null, $_.Runtime.Host, 'highPriority', $null)
				}
		}
	}
#endregion
}