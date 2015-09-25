function Invoke-BiosBoot {
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
		This function allows you to set a VM to boot into BIOS or Guest OS
    .Example
    # Set a VM to boot to BIOS
    Invoke-BiosBoot -VMs (Get-VM) -Bios
    .Example
    Invoke-BiosBoot -VMs (Get-VM) -OS
#>
  [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$True,
                   Position=0)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]
        $VM,
        [switch]$Bios,
        [switch]$OS
    )
Process {
    if($Bios) 
    {        
        Foreach ($VirtualMachine in $VM) {
            $object = New-Object VMware.Vim.VirtualMachineConfigSpec
            $object.bootOptions = New-Object VMware.Vim.VirtualMachineBootOptions
            $object.bootOptions.enterBIOSSetup = $true

            $Reconfigure = $VirtualMachine | Get-View
            $Reconfigure.ReconfigVM_Task($object)
            $Return 
        }
    }
    if($OS)
    {
        Foreach ($VirtualMachine in $VM) {
            $object = New-Object VMware.Vim.VirtualMachineConfigSpec
            $object.bootOptions = New-Object VMware.Vim.VirtualMachineBootOptions
            $object.bootOptions.enterBIOSSetup = $false

            $Reconfigure = $VirtualMachine | Get-View
            $Reconfigure.ReconfigVM_Task($object)
            $Return
        }
    }
}
}