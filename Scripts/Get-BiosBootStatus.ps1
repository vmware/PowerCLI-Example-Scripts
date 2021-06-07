<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-BiosBootStatus {
<#
	.NOTES
	===========================================================================
	 Created by: Brian Graf
	 Organization: VMware
	 Official Blog: blogs.vmware.com/PowerCLI
     Personal Blog: www.vtagion.com
     Twitter: @vBrianGraf
	===========================================================================
	.DESCRIPTION
		This will return the boot status of Virtual Machines, whether they
    are booting to the Guest OS or being forced to boot into BIOS.
    .Example
    # Returns all VMs and where they are booting
    Get-BiosBootStatus -VMs (Get-VM)
    .Example
    # Only returns VMs that are booting to BIOS
    Get-BiosBootStatus (Get-VM) -IsSetup

#>
  [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$True,
                   Position=0)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]
        $VM,
        [switch]$IsSetup
    )
Process {
    if($IsSetup)
        {
        $Execute = $VM | where {$_.ExtensionData.Config.BootOptions.EnterBiosSetup -eq "true"} | Select Name,@{Name="EnterBiosSetup";Expression={$_.ExtensionData.config.BootOptions.EnterBiosSetup}}
        }
    else
        {
        $Execute = $VM | Select Name,@{Name="EnterBiosSetup";Expression={$_.ExtensionData.config.BootOptions.EnterBiosSetup}}
        }
}
End {$Execute}
}