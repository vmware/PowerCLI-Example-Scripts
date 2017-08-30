<#
	.SYNOPSIS
	Gathers details from vCenter and outputs the resulting data to an XML file

	.DESCRIPTION
	Gathers details from vCenter and outputs the resulting data to an XML file. Metrics are gathered from 
    every cluster including:
        Cluster CPU Cores
        Cluster CPU Sockets
        Cluster Name
        Cluster VM Cores
        CPU Consumed (%)
        CPU Total (MHz)
        CPU Used (MHz)
        Memory Consumed (%)
        Memory Total (GB)
        Memory Used (GB)
        Storage Capacity (GB)
        Storage Consumed (%)
        Storage Used (GB)
        vCenter

	.PARAMETER vCenters
    Array of vCenters

    .PARAMETER outXML
    Path to output XML
	
	.NOTES
	Author: Brian Marsh
	Version: 1.0
#>

[CmdletBinding()]
param(
        [Parameter(Mandatory=$True)]
        [String[]] $vCenters = @("vcenter1","vcenter2"),
        $outXML = "c:\temp\ClusterReport.xml"
     )
BEGIN{}
PROCESS
{
    
    $ClusterReport = @{}

    foreach ($vCenter in $vCenters)
    {
     #   $cred = get-credential -Message "vCenter $vCenter"
        Connect-VIServer -Server $vCenter -Credential $cred

        # For ISE only, null things!
        $clusters = $cluster = $count = $stats = $numCores = $numSockets = $numVmCpus = $null

        # Set initial cluster statistic array to null
        $clusterStats = @()

        # Get the clusters in this vCenter
        $clusters = Get-Cluster

        # Get the full list of Storage Pods
        $storagePodList = get-view -ViewType storagepod -property ChildEntity,summary

        # Write some progress counter stuff
        $count = 0
        Write-Progress -Activity "Gathering information from clusters in $vCenter" -Status "Cluster: $($clusters[0].name)" -PercentComplete $(($count/$clusters.Count)*100)

        # Parse each of the clusters in this vCenter
        foreach ($cluster in $clusters )
        {
            # Pull CPU/Memory stats for this cluster for the past 30 days, interval of once per day
            $stats = Get-Stat -Start (Get-Date).AddDays(-30) -Finish (Get-Date) -Cpu -Memory -Entity $cluster -ErrorAction SilentlyContinue -IntervalMins 86400
            
            # Null out the various counts for this go through
            $numCores = $numSockets = $numVmCpus = $thisStoragePod = $null

            # Find all the hosts in this cluster
            $hostViews = Get-View -ViewType HostSystem -Filter @{"Parent"="$($cluster.ExtensionData.MoRef.value)"} -Property Hardware.CpuInfo,datastore
            foreach ($hostView in $hostViews) {
            
                # Add the number of cores and sockets of this host to the total count
                $numCores += $hostView.Hardware.CpuInfo.NumCpuCores
                $numSockets += $hostView.Hardware.CpuInfo.NumCpuPackages

            }
        
            # Get the Unique Datastores for this group of hosts
            $uniqDatastores = $hostView.datastore | sort -Unique
        
            # Set the Storage Pod(s)
            $thisStoragePod = $uniqDatastores | %{
            
                # Grab this uniq Datastore's MoRef
                $thisMoref = $_.value

                # Find the Storage Pod whose child entity contains this MoRef
                $storagePodList | ?{$_.ChildEntity.Value -contains $thisMoref} | Select -ExpandProperty Summary
            } | select -Unique


            # Create a cluster filter to find VMs in said cluster
            $clusterFilter = $cluster.ExtensionData.MoRef
        
            try
            {
                # Grab all the VMs in this cluster and sum their CPU allocations (Num CPU)
                $clusterVms = Get-View -ViewType VirtualMachine -SearchRoot $clusterFilter -property Config
        
                $clusterVms | %{ $numVmCpus += $_.Config.Hardware.NumCPU }
            }
            catch
            {
                Write-Verbose "Error finding Cluster VM CPUs in cluster $($Cluster.Name)"
                Write-Debug   "Error finding Cluster VM CPUs in cluster $($Cluster.Name)"
            }


            # Create a custom object with the relevant information
            $clusterStat = [PsCustomObject]@{
                                'Cluster Name'          = $cluster.Name
                                vCenter                 = $vCenter
                                'Cluster CPU Sockets'   = $numSockets
                                'Cluster CPU Cores'     = $numCores
                                'Cluster VM Cores'      = $numVmCpus
                                'CPU Used (MHz)'        = [Math]::Round(($stats | ?{$_.MetricId -match "cpu.usagemhz.average"} | measure -Property Value -Average).Average,2)
                                'CPU Total (MHz)'       = $cluster.ExtensionData.Summary.EffectiveCpu
                                'CPU Consumed (%)'          = $null
                                'Memory Used (GB)'      = [Math]::Round((($stats | ?{$_.MetricId -match 'mem.usage.average'} | `
                                                          measure -property Value -Average).Average /100) * ($cluster.ExtensionData.Summary.TotalMemory /1GB), 2)
                                'Memory Total (GB)'     = [Math]::Round($cluster.ExtensionData.Summary.TotalMemory /1GB,2)
                                'Memory Consumed (%)'       = [Math]::Round(($stats | ?{$_.MetricId -match "mem.usage.average"} | measure -Property Value -Average).Average,2)
                                'Storage Used (GB)'     = [Math]::Round(($thisStoragePod.Capacity - $thisStoragePod.FreeSpace) /1GB,2)
                                'Storage Capacity (GB)' = [Math]::Round($thisStoragePod.Capacity /1GB,2)
                                'Storage Consumed (%)'      = $null
                           }
        
            try
            {
                # We can sometimes get a divide by zero error if there's zero Mhz in this cluster
                $clusterStat.'CPU Consumed (%)' = [Math]::Round(($clusterStat.'CPU Used (MHz)' / $clusterStat.'CPU Total (MHz)') * 100, 2)
            }
            catch
            {
                Write-Verbose "Error calculating CPU Percentage consumed"
                Write-Debug   "Error calculating CPU Percentage consumed"
            }

            try
            {
                # We can sometimes get a divide by zero error if there's zero Mhz in this cluster
                $clusterStat.'Storage Consumed (%)' = [Math]::Round(($clusterStat.'Storage Used (GB)' / $clusterStat.'Storage Capacity (GB)') * 100, 2)
            }
            catch
            {
                Write-Verbose "Error calculating CPU Percentage consumed"
                Write-Debug   "Error calculating CPU Percentage consumed"
            }

            # Add this cluster's stats to the array
            $clusterStats += $clusterStat

            # Update progress
            $count++
            Write-Progress -Activity "Gathering information from clusters in $vCenter" -Status "Cluster: $($cluster.name)" -PercentComplete $(($count/$clusters.Count)*100)
        }
        
        $ClusterReport[$vCenter] = $clusterStats

        Disconnect-VIServer * -Confirm:$false
    }
}
END
{
    write-debug "anything else?"
    $ClusterReport | Export-Clixml $outXML
}