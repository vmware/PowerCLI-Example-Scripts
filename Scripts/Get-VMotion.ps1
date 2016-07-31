<#
Script name: Get-VMotion.ps1
Created on: 2016/07/30
Author: Brian Bunke, @brianbunke
Description: View details of recent vMotion and Storage vMotion events
Note to future contributors: Test changes with Pester file Get-VMotion.Tests.ps1

===Tested Against Environment====
vSphere Version: 6.0 U1/U2
PowerCLI Version: PowerCLI 6.3 R1
PowerShell Version: 5.0
OS Version: Windows 7/10
#>

function Get-VMotion {
<#
.SYNOPSIS
View details of recent vMotion and Storage vMotion events.

.DESCRIPTION
Use to check DRS history, or to help with troubleshooting performance issues.
If filtering by VM, objects should be supplied from the pipeline via Get-VM.

.EXAMPLE
Get-VMotion
View all s/vMotion events from the last 7 days.

.EXAMPLE
Get-VM -Name 'vm1' | Get-VMotion -ExcludeSVMotion
View all vMotion events for VM "vm1" in the last week.

.EXAMPLE
Get-VM | Get-VMotion -Days 1 -ExcludeVMotion | Select-Object Name, Source, Destination, Duration
View all Storage vMotion events for all VMs in the last 24 hours.
Select less properties for easier reading in a table format.

.INPUTS
[VMware.VimAutomation.ViCore.Impl.V1.VM.UniversalVirtualMachineImpl]
Object type supplied by PowerCLI cmdlet Get-VM

.OUTPUTS
[System.Collections.ArrayList]

.NOTES
Thanks to alanrenouf/sneddo for doing the hard work as part of vCheck.
https://github.com/alanrenouf/vCheck-vSphere

.LINK
https://github.com/vmware/PowerCLI-Example-Scripts

.LINK
https://github.com/brianbunke
#>
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param (
        # Number of days to search for events. Defaults to 7.
        [int]$Days = 7,
        
        # Filter results to only the specified VMs. Pipeline input recommended.
        [Parameter(ValueFromPipeline = $true)]
        [Alias('Name')]
        $VM,

        # Exclude all vMotion events, and review only Storage vMotion history.
        [switch]$ExcludeVMotion,

        # Exclude all Storage vMotion events, and review only vMotion history.
        [switch]$ExcludeSVMotion
    )

    BEGIN {
        # If both switches are supplied, advise the user and stop the script
        If ($ExcludeVMotion -and $ExcludeSVMotion) {
            Write-Warning 'Using both "exclude" switches filters out all results. Use one or neither.'
            break
        }

        # Build a vMotion-specific event filter query. Shamelessly stolen from vCheck
        $EventFilterSpec = New-Object VMware.Vim.EventFilterSpec
        $EventFilterSpec.Category = 'Info'
        $EventFilterSpec.Time = New-Object VMware.Vim.EventFilterSpecByTime
        $EventFilterSpec.Time.BeginTime = (Get-Date).AddDays(-$Days)
        $EventFilterSpec.Type = 'VmMigratedEvent', 'DrsVmMigratedEvent', 'VmBeingHotMigratedEvent', 'VmBeingMigratedEvent'
        # Perform the query and condition the data for further use
        $vMotionList = (Get-View (Get-View ServiceInstance -Property Content.EventManager).Content.EventManager).QueryEvents($EventFilterSpec) |
            Select-Object ChainID,
                          CreatedTime,
                          UserName,
                          @{n='Cluster';   e={$_.ComputeResource.Name}},
                          @{n='Datacenter';e={$_.Datacenter.Name}},
                          @{n='DestDS';    e={$_.DestDatastore.Name}},
                          @{n='DestHost';  e={$_.DestHost.Name}},
                          @{n='SourceDS';  e={$_.Ds.Name}},
                          @{n='SourceHost';e={$_.Host.Name}},
                          @{n='VM';        e={$_.Vm.Name}}

        # Construct an empty array for results within the ForEach
        $Results = New-Object System.Collections.ArrayList

        # Group together by ChainID; each vMotion has a begin event and end event
        ForEach ($vMotion in ($vMotionList | Sort-Object CreatedTime | Group-Object ChainID)) {
            If ($vMotion.Group.Count -eq 2) {
                # Mark the current vMotion as vMotion / Storage vMotion / Both
                If ($vMotion.Group[0].SourceDS -eq $vMotion.Group[0].DestDS) {
                    $Type = 'vMotion'
                } ElseIf ($vMotion.Group[0].SourceHost -eq $vMotion.Group[0].DestHost) {
                    $Type = 's-vMotion'
                } Else {
                    $Type = 'Both'
                }

                # Add the current vMotion into the $Results array
                $Results.Add([PSCustomObject][Ordered]@{
                    Name        = $vMotion.Group[0].VM
                    Type        = $Type
                    # Src/Dst are hosts if a vMotion, but datastores if svMotion
                    Source      = &{If ($Type -eq 's-vMotion') {$vMotion.Group[0].SourceDS} Else {$vMotion.Group[0].SourceHost}}
                    Destination = &{If ($Type -eq 's-vMotion') {$vMotion.Group[0].DestDS} Else {$vMotion.Group[0].DestHost}}
                    # Hopefully people aren't performing vMotions that take >24 hours, because I'm ignoring days in the string
                    Duration    = (New-TimeSpan -Start $vMotion.Group[0].CreatedTime -End $vMotion.Group[1].CreatedTime).ToString('hh\:mm\:ss')
                    StartTime   = $vMotion.Group[0].CreatedTime
                    EndTime     = $vMotion.Group[1].CreatedTime
                    # Making an assumption that all events with an empty username are DRS-initiated
                    Username    = &{If ($vMotion.Group[0].UserName) {$vMotion.Group[0].UserName} Else {'DRS'}}
                }) | Out-Null
            }
        }

        # Construct an empty array to grab any $VM objects from the pipeline
        $VMList = New-Object System.Collections.ArrayList
    } #begin

    PROCESS {
        # All VM names are added to the array here
        $VMList.Add($VM.Name) | Out-Null
    }

    END {
        # This block if the -VM parameter was used
        If (($VMList | Measure-Object).Count -gt 0) {
            If ($ExcludeVMotion) {
                return $Results | Where-Object {$_.Type -ne 'vMotion' -and $_.Name -in $VMList}
            } ElseIf ($ExcludeSVMotion) {
                return $Results | Where-Object {$_.Type -ne 's-vMotion' -and $_.Name -in $VMList}
            } Else {
                return $Results | Where-Object Name -in $VMList
            }
        # This block if -VM was not used
        } Else {
            If ($ExcludeVMotion) {
                return $Results | Where-Object Type -ne 'vMotion'
            } ElseIf ($ExcludeSVMotion) {
                return $Results | Where-Object Type -ne 's-vMotion'
            } Else {
                return $Results
            }
        } #if/else -VM
    } #end
} #function
