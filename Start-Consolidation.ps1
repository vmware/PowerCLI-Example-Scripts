function Start-Consolidation {
<#
    .SYNOPSIS
    Consolidates VM disks

	.DESCRIPTION
    Calls a VM object's "ConsolidateVMDisks" method. Takes VirtualMachine
	objects as input (Get-VM or similar command), best used in conjunction with
    Get-ConsolidationNeeded which will only return objects that require disk
    consolidation.

    You must already have the PowerCLI Snap-In/Module loaded and be connected
    to a vCenter server.

	.EXAMPLE
    Get-VM | Start-Consolidation

    Attempts to consolidate every VM registered to the currently connected
    vCenter server regardless of whether they need consolidation or not.

	.EXAMPLE
    Get-VM | Get-ConsolidationNeeded | Start-Consolidation

    Check all VMs registered to the currently connected vCenter server for
	needed disk consolidation and begins the proccess of consolidating disks if
	needed.

	.PARAMETER VM
    Specifies the Virtual Machine you would like to start disk consolidation on.

	.LINK
	Get-ConsolidationNeeded

	.LINK
    https://github.com/vmware/PowerCLI-Example-Scripts
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   Position = 0)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl[]]
        $VM
    )

    process {
        foreach ($vMachine in $VM) {
            Write-Verbose -Message "Starting disk consolidation on $($vMachine.Name)"
            try {
                $vMachine.ExtensionData.ConsolidateVMDisks()
                Write-Verbose -Message "Finished disk consolidation on $($vMachine.Name)"
            } 
            catch {
                Write-Warning -Message "Disk consolidation failed on $($vMachine.Name), it is possible that this Virtual Machine did not require consolidation."
            }
        }
    }
}
