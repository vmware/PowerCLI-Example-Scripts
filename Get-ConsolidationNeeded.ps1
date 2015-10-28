function Get-ConsolidationNeeded {
<#
    .SYNOPSIS
    Find vSphere VMs that need disk consolidation.

    .DESCRIPTION
    Checks vCenter for Virtual Machines that require disk consolidation. You
	must specify the VirtualMachine object objects (e.g. with Get-VM) you want
    to check.

    You must already have the PowerCLI Snap-In/Module loaded and be connected
    to a vCenter server.

    .EXAMPLE
    Get-VM | Get-ConsolidationNeeded

    Checks all Virtual Machines managed by the currently connected vCenter 
    Server.

    .EXAMPLE
    Get-VM -Location 'TestDev' | Get-ConsolidationNeeded

    Check all Virtual Machines in vSphere location "TestDev" for needed disk 
    consolidation.

    .EXAMPLE
    Get-VM -Name 'isolated-*' -Location 'Development' | Get-ConsolidationNeeded

    Checks all VMs in Vsphere location "Development" whose name begins with
    isolated- for needed disk consolidation.

    .EXAMPLE
    Get-VM | Get-ConsolidationNeeded | Start-Consolidation

    Check all VMs registered to the currently connected vCenter server for
	needed disk consolidation and begins the proccess of consolidating disks if
	needed.

    .PARAMETER VM
    Specifies the virtual machine(s) you want to check.

    .LINK
    Start-Consolidation

    .LINK
    https://github.com/vmware/PowerCLI-Example-Scripts
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   Position = 0)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl[]]
        [alias('VirtualMachine')]
        $VM
    )

    process {
        foreach ($vMachine in $VM) {
            Write-Verbose -Message "Checking for disk consolidated needed on $vMachine"
            if ($vMachine.Extensiondata.Runtime.ConsolidationNeeded) {
                Write-Verbose -Message "$vMachine requires disk consolidation"
                $vMachine | Select-Object -Property 'Name', @{
                    Name = 'ConsolidationNeeded';
                    Expression = {$_.Extensiondata.Runtime.ConsolidationNeeded
                }}
            }
        }
    }
}
