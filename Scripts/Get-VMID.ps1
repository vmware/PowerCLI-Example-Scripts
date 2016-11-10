function Get-VMID {
<#	
	.NOTES
	===========================================================================
	 Created by: Markus Kraus
	 Organization: Private
     Personal Blog: mycloudrevolution.com
     Twitter: @vMarkus_K
	===========================================================================
	.DESCRIPTION
		This will quickly return all IDs of VMs
    .Example
    Get-VMID -myVMs (Get-VM) | ft
    .Example
    $SampleVMs = Get-VM "tst*"
    Get-VMID -myVMs $SampleVMs
#>
  [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$True,
                   Position=0)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]
        $myVMs
    )
Process { 

	$MyView = @()
	ForEach ($myVM in $myVMs){
		$UUIDReport = [PSCustomObject] @{
				Name = $myVM.name 
				UUID = $myVM.extensiondata.Config.UUID
				InstanceUUID = $myVM.extensiondata.config.InstanceUUID
				LocationID = $myVM.extensiondata.config.LocationId
				MoRef = $myVM.extensiondata.Moref.Value
				}
		$MyView += $UUIDReport
		}
	$MyView
	}
}