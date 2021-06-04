<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Validate-ESXiPackages {
    <#
    .DESCRIPTION
        Compares all ESXi Host VIBs within a vSphere with a reference Hosts.

    .NOTES
        File Name  : Validate-ESXiPackages.ps1
        Author     : Markus Kraus
        Version    : 1.0
        State      : Ready

        Tested Against Environment:

        vSphere Version: 6.0 U2, 6.5 U1
        PowerCLI Version: PowerCLI 10.0.0 build 7895300
        PowerShell Version: 4.0
        OS Version: Windows Server 2012 R2

    .LINK
        https://mycloudrevolution.com/

    .EXAMPLE
        Validate-ESXiPackages -Cluster (Get-Cluster) -RefernceHost (Get-VMHost | Select-Object -First 1)

    .PARAMETER Cluster
        vSphere Cluster to verify

    .PARAMETER RefernceHost
        The VIB Reference ESXi Host
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, HelpMessage="vSphere Cluster to verify")]
        [ValidateNotNullorEmpty()]
            [VMware.VimAutomation.ViCore.Impl.V1.Inventory.ComputeResourceImpl] $Cluster,
        [Parameter(Mandatory=$True, ValueFromPipeline=$false, HelpMessage="The VIB Reference ESXi Host")]
        [ValidateNotNullorEmpty()]
            [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl] $RefernceHost
    )

    Process {

        #region: Get reference VIBs
        $EsxCli2 = Get-ESXCLI -VMHost $RefernceHost -V2
        $RefernceVibList = $esxcli2.software.vib.list.invoke()
        #endregion

        #region: Compare reference VIBs
        $MyView = @()
        foreach ($VmHost in ($Cluster | Get-VMHost)) {

            $EsxCli2 = Get-ESXCLI -VMHost $VmHost -V2
            $VibList = $esxcli2.software.vib.list.invoke()
            [Array]$VibDiff = Compare-Object -ReferenceObject $RefernceVibList.ID -DifferenceObject $VibList.ID

            if($VibDiff.Count -gt 0) {
                $VibDiffSideIndicator = @()
                foreach ($Item in $VibDiff) {
                    $VibDiffSideIndicator += $($Item.SideIndicator + " " + $Item.InputObject)
                }
            }
            else {
                $VibDiffSideIndicator = $null
            }

            $Report = [PSCustomObject] @{
                    Host = $VmHost.Name
                    Version = $VmHost.Version
                    Build = $VmHost.Build
                    VibDiffCount = $VibDiff.Count
                    VibDiff = $VibDiff.InputObject
                    VibDiffSideIndicator = $VibDiffSideIndicator
                    }
            $MyView += $Report

        }
        #region: Compare reference VIBs

        $MyView
    }
}