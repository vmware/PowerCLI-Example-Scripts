<#
Script name: Get-VMotion.ps1
Created on: 2016/08/09
Author: Brian Bunke, @brianbunke
Description: View details of recent vMotion and Storage vMotion events
Note to future contributors: Test changes with Pester file Get-VMotion.Tests.ps1

===Tested Against Environment====
vSphere Version: 6.0 U1/U2
PowerCLI Version: PowerCLI 6.3 R1
PowerShell Version: 5.0
OS Version: Windows 7/10
#>

#Requires -Version 3 -Modules VMware.VimAutomation.Core

function Get-VMotion {
<#
.SYNOPSIS
View details of recent vMotion and Storage vMotion events.

.DESCRIPTION
Use to check DRS history, or to help with troubleshooting.
Can filter to just results from recent days, hours, or minutes (default is 1 day).
Supplying one parent object (Get-Cluster) and filtering later will perform much faster than supplying many VMs.

.EXAMPLE
Get-VMotion
For all datacenters found by Get-Datacenter, view all s/vMotion events from the last day.

.EXAMPLE
Get-Cluster '*arcade' | Get-VMotion -Hours 8 -Verbose | Where-Object {$_.Type -eq 'vmotion'}
For the cluster Flynn's Arcade, view all vMotions in the last eight hours.
Verbose output tracks each VM as it is processed.
NOTE: Piping "Get-Datacenter" or "Get-Cluster" will be much faster than an unfiltered "Get-VM".

.EXAMPLE
>
PS C:\>$Grid = $global:DefaultVIServers | Where-Object {$_.Name -eq 'Grid'}
PS C:\>Get-VM -Name 'Tron','Rinzler' | Get-VMotion -Days 7 -Server $Grid

View all s/vMotion events for only VMs "Tron" and "Rinzler" in the last week.
If connected to multiple servers, will only search for events on server Grid.

.INPUTS
[VMware.VimAutomation.ViCore.Types.V1.Inventory.InventoryItem[]]
PowerCLI cmdlets Get-Datacenter / Get-Cluster / Get-VM

.OUTPUTS
[System.Collections.ArrayList]

.NOTES
Thanks to lucdekens/alanrenouf/sneddo for doing the hard work long ago.
http://www.lucd.info/2013/03/31/get-the-vmotionsvmotion-history/
https://github.com/alanrenouf/vCheck-vSphere

.LINK
https://github.com/vmware/PowerCLI-Example-Scripts

.LINK
https://github.com/brianbunke
#>
    [CmdletBinding(DefaultParameterSetName='Days')]
    [OutputType([System.Collections.ArrayList])]
    param (
        # Filter results to only the specified object(s)
        # Tested with datacenter, cluster, and VM entities
        [Parameter(ValueFromPipeline = $true)]
        [ValidateScript({$_.GetType().Name -match 'VirtualMachine|Cluster|Datacenter'})]
        [Alias('Name','VM','Cluster','Datacenter')]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.InventoryItem[]]$Entity = (Get-Datacenter),

        # Number of days to return results from. Defaults to 7
        # Mutually exclusive from Hours, Minutes
        [Parameter(ParameterSetName='Days')]
        [ValidateRange(0,[int]::MaxValue)]
        [int]$Days = 1,
        # Number of hours to return results from
        # Mutually exclusive from Days, Minutes
        [Parameter(ParameterSetName='Hours')]
        [ValidateRange(0,[int]::MaxValue)]
        [int]$Hours,
        # Number of minutes to return results from
        # Mutually exclusive from Days, Hours
        [Parameter(ParameterSetName='Minutes')]
        [ValidateRange(0,[int]::MaxValue)]
        [int]$Minutes,

        # Specifies the vCenter Server systems on which you want to run the cmdlet.
        # If no value is passed to this parameter, the command runs on the default servers.
        # For more information about default servers, see the description of Connect-VIServer.
        [VMware.VimAutomation.Types.VIServer[]]$Server
    )

    BEGIN {
        # Based on parameter supplied, set $Time for $EventFilter below
        switch ($PSCmdlet.ParameterSetName) {
            'Days'    {$Time = (Get-Date).AddDays(-$Days)}
            'Hours'   {$Time = (Get-Date).AddHours(-$Hours)}
            'Minutes' {$Time = (Get-Date).AddMinutes(-$Minutes)}
        }

        # Construct an empty array for events returned
        # Performs faster than @() when appending; matters if running against many VMs
        $Events = New-Object System.Collections.ArrayList

        # Build a vMotion-specific event filter query
        # http://pubs.vmware.com/vsphere-60/index.jsp#com.vmware.wssdk.apiref.doc/vim.event.EventManager.html
        $EventFilter        = New-Object VMware.Vim.EventFilterSpec
        $EventFilter.Entity = New-Object VMware.Vim.EventFilterSpecByEntity
        $EventFilter.Time   = New-Object VMware.Vim.EventFilterSpecByTime
        $EventFilter.Time.BeginTime = $Time
        $EventFilter.Category = 'Info'
        $EventFilter.DisableFullMessage = $true
        $EventFilter.EventTypeID = 'VmMigratedEvent', 'DrsVmMigratedEvent', 'VmBeingHotMigratedEvent', 'VmBeingMigratedEvent'
    } #Begin

    PROCESS {
        $Entity | ForEach-Object {
            Write-Verbose "Processing $($_.Name)"

            # Add the entity details for the current loop of the Process block
            $EventFilter.Entity.Entity = $_.ExtensionData.MoRef
            $EventFilter.Entity.Recursion = &{
                If ($_.ExtensionData.MoRef.Type -eq 'VirtualMachine') {'self'} Else {'all'}}
            # Create the event collector, and collect 100 events at a time
            $Collector = Get-View (Get-View EventManager).CreateCollectorForEvents($EventFilter)
            $Buffer = $Collector.ReadNextEvents(100)
            While ($Buffer) {
                # Append the 100 results into the $Events array
                If (($Buffer | Measure-Object).Count -gt 1) {
                    # .AddRange if more than one event
                    $Events.AddRange($Buffer) | Out-Null
                } Else {
                    # .Add if only one event; should never happen since gathering begin & end events
                    $Events.Add($Buffer) | Out-Null
                }
                $Buffer = $Collector.ReadNextEvents(100)
            }
            # Destroy the collector after each entity to avoid running out of memory :)
            $Collector.DestroyCollector()
        } #ForEach
    } #Process

    END {
        # Construct an empty array for results within the ForEach
        $Results = New-Object System.Collections.ArrayList

        # Group together by ChainID; each vMotion has begin/end events
        ForEach ($vMotion in ($Events | Sort-Object CreatedTime | Group-Object ChainID)) {
            If ($vMotion.Group.Count -eq 2) {
                # Mark the current vMotion as vMotion / Storage vMotion / Both
                If ($vMotion.Group[0].Ds.Name -eq $vMotion.Group[0].DestDatastore.Name) {
                    $Type = 'vMotion'
                } ElseIf ($vMotion.Group[0].Host.Name -eq $vMotion.Group[0].DestHost.Name) {
                    $Type = 's-vMotion'
                } Else {
                    $Type = 'Both'
                }

                # Add the current vMotion into the $Results array
                $Results.Add([PSCustomObject][Ordered]@{
                    Name      = $vMotion.Group[0].Vm.Name
                    Type      = $Type
                    # Src/Dst are hosts if a vMotion, but datastores if svMotion
                    SrcHost   = $vMotion.Group[0].Host.Name
                    DstHost   = $vMotion.Group[0].DestHost.Name
                    SrcDS     = $vMotion.Group[0].Ds.Name
                    DstDS     = $vMotion.Group[0].DestDatastore.Name
                    # Hopefully people aren't performing vMotions that take >24 hours, because I'm ignoring days in the string
                    Duration  = (New-TimeSpan -Start $vMotion.Group[0].CreatedTime -End $vMotion.Group[1].CreatedTime).ToString('hh\:mm\:ss')
                    StartTime = $vMotion.Group[0].CreatedTime
                    EndTime   = $vMotion.Group[1].CreatedTime
                    # Making an assumption that all events with an empty username are DRS-initiated
                    Username  = &{If ($vMotion.Group[0].UserName) {$vMotion.Group[0].UserName} Else {'DRS'}}
                }) | Out-Null
            } #IfGroup
        } #ForEach ChainID
        $Results
    } #End
}
