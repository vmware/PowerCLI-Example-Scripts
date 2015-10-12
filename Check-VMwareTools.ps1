﻿function Check-Tools {
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
        This will quickly return all VMs that have VMware Tools out of date, along
        with the version that it is running

        .Example
        Check-Tools -VMs (Get-VM)

        .Example
        $SampleVMs = Get-VM "Mgmt*"
        Check-Tools -VMs $SampleVMs
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   Position = 0)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]
        $VMs
    )
    Process {
        #foreach ($VM in $VMs) {
        $OutofDate = $VMs | Where-Object -FilterScript {$_.ExtensionData.Guest.ToolsStatus -ne 'toolsOk'}
        $Result = @($OutofDate | Select-Object -Property Name, @{
            Expression = {$_.ExtensionData.Guest.Toolsversion}
            Name       = 'ToolsVersion'
        })

        $Result
    }
}
