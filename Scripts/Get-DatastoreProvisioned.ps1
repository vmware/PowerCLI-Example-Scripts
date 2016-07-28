<#
Script name: Get-DatastoreProvisioned.ps1
Created on: 2016/07/27
Author: Brian Bunke, @brianbunke
Description: Augments Get-Datastore with thin provisioned info
Note to future contributors: Test changes with Pester file Get-DatastoreProvisioned.Tests.ps1

===Tested Against Environment====
vSphere Version: 6.0 U1/U2
PowerCLI Version: PowerCLI 6.3 R1
PowerShell Version: 5.0
OS Version: Windows 7/10
#>

function Get-DatastoreProvisioned {
<#
.SYNOPSIS
Retrieve the total thin provisioned space on each datastore.

.DESCRIPTION
Intended to reveal provisioned space alongside total/free space, to assist with svMotion decisions.
-Name should be supplied from the pipeline via Get-Datastore.

.EXAMPLE
Get-Datastore | Get-DatastoreProvisioned | Format-Table -AutoSize
View all datastores and view their capacity statistics in the current console.

.EXAMPLE
Get-Datastore -Name '*ssd' | Get-DatastoreProvisioned | Where-Object -Property ProvisionedPct -ge 100
For all datastores ending in 'ssd', return the capacity stats of those at least 100% provisioned.

.INPUTS
[VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.VmfsDatastoreImpl]
Object type supplied by PowerCLI function Get-Datastore

.LINK
https://github.com/vmware/PowerCLI-Example-Scripts

.LINK
https://twitter.com/brianbunke
#>
    [CmdletBinding()]
    param (
        # Specifies the datastore names to check. Tested only with pipeline input (see examples).
        [Parameter(ValueFromPipeline = $true)]
        $Name
    )

    PROCESS {
        ForEach ($DS in $Name) {
            # Calculate total provisioned space from the exposed properties
            $Provisioned = ($DS.ExtensionData.Summary.Capacity -
                $DS.ExtensionData.Summary.FreeSpace +
                $DS.ExtensionData.Summary.Uncommitted) / 1GB

            # Return info, wrapping it in the Math.Round method to trim to two decimal places
            [PSCustomObject]@{
                Name           = $DS.Name
                FreeSpaceGB    = [math]::Round($DS.FreeSpaceGB, 2)
                CapacityGB     = [math]::Round($DS.CapacityGB, 2)
                ProvisionedGB  = [math]::Round($Provisioned, 2)
                UsedPct        = [math]::Round((($DS.CapacityGB - $DS.FreeSpaceGB) / $DS.CapacityGB) * 100, 2)
                ProvisionedPct = [math]::Round(($Provisioned / $DS.CapacityGB) * 100, 2)
            } #pscustomobject
        } #foreach
    } #process
} #function
