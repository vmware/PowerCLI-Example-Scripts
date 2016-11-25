function Recommend-Sizing {
<#	
    .NOTES
    ===========================================================================
    Created by: Markus Kraus
    Twitter: @VMarkus_K
    Private Blog: mycloudrevolution.com
    ===========================================================================
    Changelog:  
    2016.11 ver 1.0 Base Release 
    ===========================================================================
    External Code Sources:  
    http://www.lucd.info/2011/04/22/get-the-maximum-iops/
    https://communities.vmware.com/thread/485386
    ===========================================================================
    Tested Against Environment:
    vSphere Version: 5.5 U2
    PowerCLI Version: PowerCLI 6.3 R1, PowerCLI 6.5 R1
    PowerShell Version: 4.0, 5.0
    OS Version: Windows 8.1, Server 2012 R2
    ===========================================================================
    Keywords vSphere, ESXi, VM, Storage, Sizing
    ===========================================================================

    .DESCRIPTION
    This Function collects Basic vSphere Informations for a Hardware Sizing Recomamndation. Focus is in Compute Ressources.        

    .Example
    Recommend-Sizing -ClusterNames Cluster01, Cluster02 -StatsRange 480 -Verbose    

    .Example
    Recommend-Sizing -ClusterNames Cluster01, Cluster02 

    .Example
    Recommend-Sizing -ClusterNames Cluster01 

    .PARAMETER ClusterNames
    List of your vSphere Cluser Names to process.

    .PARAMETER StatsRange
    Time Range in Minutes for the Stats Collection.
    Default is 24h.

#Requires PS -Version 4.0
#Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="6.3.0.0"}
#>

[CmdletBinding()]
param( 
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, Position=0)]
        [Array] $ClusterNames,
     [Parameter(Mandatory=$False, ValueFromPipeline=$False, Position=1)]
        [int] $StatsRange = 1440      
        
)
Begin {
    [int]$TimeRange = "-" + $StatsRange
    $Validate = $True
    #region: Check Clusters
    Write-Verbose "$(Get-Date -Format G) Starting Cluster Validation..." 
    foreach ($ClusterName in $ClusterNames) {
        $TestCluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue -Verbose:$False
        if(!($TestCluster)){
            Write-Warning "No Custer found wth Name $ClusterName!"
            $Validate = $False
        }
        elseif ($TestCluster.count -gt 1) {
            Write-Warning "Multiple Custers found wth Name $ClusterName!`nUse a List of explicit Cluster Names: Recommend-Sizing -ClusterNames Cluster01, Cluster02 "
            $Validate = $False
        }
    }
    Write-Verbose "$(Get-Date -Format G) Cluster Validation completed" 
    #endregion
}

Process {
    $MyView = @()
    if ($Validate -eq $True) {
        foreach ($ClusterName in $ClusterNames) {
            #region: Get Cluster Objects
            Write-Verbose "$(Get-Date -Format G) Collect $ClusterName Cluster Objects..." 
            $Cluster =  Get-Cluster -Name $ClusterName -Verbose:$False
            $ClusterVMs = $Cluster | Get-VM -Verbose:$False
            $ClusterVMsPoweredOn = $ClusterVMs | where {$_.PowerState -eq "PoweredOn"}
            $ClusterDatastores = $Cluster | Get-Datastore -Verbose:$False
            $ClusterHosts = $Cluster | Get-VMHost -Verbose:$False
            $HostsAverageMemoryUsageGB = [math]::round( ($ClusterHosts | Measure-Object -Average -Property MemoryUsageGB).Average,1 )
            $HostsAverageMemoryUsage = $([math]::round( (($ClusterHosts | Measure-Object -Average -Property MemoryUsageGB).Average / ($ClusterHosts | Measure-Object -Average -Property MemoryTotalGB).Average) * 100,1 ))
            $HostsAverageCpuUsageMhz = [math]::round( ($ClusterHosts | Measure-Object -Average -Property CpuUsageMhz).Average,1 )
            $HostsAverageCpuUsage = $([math]::round( (($ClusterHosts | Measure-Object -Average -Property CpuUsageMhz).Average / ($ClusterHosts | Measure-Object -Average -Property CpuTotalMhz).Average) * 100,1 ))
            Write-Verbose "$(Get-Date -Format G) Collect $($Cluster.name) Cluster Objects completed" 
            #endregion

            #region: CPU Calculation
            Write-Verbose "$(Get-Date -Format G) Collect $($Cluster.name) CPU Details..." 
            $VMvCPUs = ($ClusterVMs | Measure-Object -Sum -Property NumCpu).sum
            $LogicalThreads = $Cluster.ExtensionData.Summary.NumCpuThreads
            $CpuCores = $Cluster.ExtensionData.Summary.NumCpuCores
            $vCPUpCPUratio = [math]::round( $VMvCPUs / $LogicalThreads,1 )
            Write-Verbose "$(Get-Date -Format G) Collect $($Cluster.name) CPU Details completed." 
            #endregion

            #region: Memory Calculation
            Write-Verbose "$(Get-Date -Format G) Collect $($Cluster.name) Memory Details..." 
            $AllocatedVMMemoryGB = [math]::round( ($ClusterVMs | Measure-Object -Sum -Property MemoryGB).sum )
            $PhysicalMemory = [math]::round( $Cluster.ExtensionData.Summary.TotalMemory / 1073741824,1 )
            $MemoryUsage = [math]::round( ($AllocatedVMMemoryGB / $PhysicalMemory) * 100 ,1 )
            Write-Verbose "$(Get-Date -Format G) Collect $($Cluster.name) Memory Details completed" 
            #endregion

            #region: Creating Disk Metrics
            Write-Verbose "$(Get-Date -Format G) Create $($Cluster.name) IOPS Metrics..."
            $DiskMetrics = "virtualDisk.numberReadAveraged.average","virtualDisk.numberWriteAveraged.average"
            $start = (Get-Date).AddMinutes($TimeRange)
            $DiskStats = Get-Stat -Stat $DiskMetrics -Entity $ClusterVMsPoweredOn -Start $start -Verbose:$False
            Write-Verbose "$(Get-Date -Format G) Create $($Cluster.name) IOPS Metrics completed"
            #endregion
            
            #region: Creating IOPS Reports
            Write-Verbose "$(Get-Date -Format G) Process $($Cluster.name) IOPS Report..."
            $reportDiskPerf = @() 
            $reportDiskPerf = $DiskStats | Group-Object -Property {$_.Entity.Name},Instance | %{
                New-Object PSObject -Property @{
                    IOPSMax = ($_.Group | `
                        Group-Object -Property Timestamp | `
                        %{$_.Group[0].Value + $_.Group[1].Value} | `
                        Measure-Object -Maximum).Maximum
                }
            }
            Write-Verbose "$(Get-Date -Format G) Process $($Cluster.name) IOPS Report completed"
            #endregion

            #region: Create VM Disk Space Report
            Write-Verbose "$(Get-Date -Format G) Process $($Cluster.name) VM Disk Space Report..."
            $reportDiskSpace = @()
            foreach ($ClusterVM in $ClusterVMs){
                $VMDKs = $ClusterVM | get-HardDisk -Verbose:$False
                foreach ($VMDK in $VMDKs) {
                    if ($VMDK -ne $null){
                        [int]$CapacityGB = $VMDK.CapacityKB/1024/1024
                        $Report = [PSCustomObject] @{
                                CapacityGB = $CapacityGB
                            }
                            $reportDiskSpace += $Report
                        }   
                    }
                }
            Write-Verbose "$(Get-Date -Format G) Process $($Cluster.name) VM Disk Space Report completed"
            #endregion

            #region: Create Datastore Space Report
            Write-Verbose "$(Get-Date -Format G) Process $($Cluster.name) Datastore Space Report..."
            $DatastoreReport = @($ClusterDatastores | Select-Object @{N="CapacityGB";E={[math]::Round($_.CapacityGB,2)}}, @{N="FreeSpaceGB";E={[math]::Round($_.FreeSpaceGB,2)}}, @{N="UsedSpaceGB";E={[math]::Round($_.CapacityGB - $_.FreeSpaceGB,2)}})
            Write-Verbose "$(Get-Date -Format G) Process $($Cluster.name) Datastore Space Report completed"
            #endregion

            #region: Create Global Report
            Write-Verbose "$(Get-Date -Format G) Process Global Report..."
            $SizingReport = [PSCustomObject] @{
				Cluster = $Cluster.name
                HAEnabled = $Cluster.HAEnabled
                DrsEnabled = $Cluster.DrsEnabled
                Hosts = $Cluster.ExtensionData.Summary.NumHosts
                HostsAverageMemoryUsageGB = $HostsAverageMemoryUsageGB
                HostsAverageMemoryUsage = "$HostsAverageMemoryUsage %" 
                HostsAverageCpuUsageMhz = $HostsAverageCpuUsageMhz
                HostsAverageCpuUsage = "$HostsAverageCpuUsage %" 
                PhysicalCPUCores = $CpuCores
                LogicalCPUThreads = $LogicalThreads
                VMs =  $ClusterVMs.count
                ActiveVMs =  $ClusterVMsPoweredOn.count
                VMvCPUs = $VMvCPUs
				vCPUpCPUratio = "$vCPUpCPUratio : 1"
                PhysicalMemoryGB = $PhysicalMemory
                AllocatedVMMemoryGB = $AllocatedVMMemoryGB        
				ClusterMemoryUsage = "$MemoryUsage %"
                SumMaxVMIOPS = [math]::round( ($reportDiskPerf | Measure-Object -Sum -Property IOPSMax).sum, 1 )
                AverageMaxVMIOPs = [math]::round( ($reportDiskPerf | Measure-Object -Average -Property IOPSMax).Average,1 )
                SumVMDiskSpaceGB = [math]::round( ($reportDiskSpace | Measure-Object -Sum -Property CapacityGB).sum, 1 )
                SumDatastoreSpaceGB = [math]::round( ($DatastoreReport | Measure-Object -Sum -Property CapacityGB).sum, 1 )
                SumDatastoreUsedSpaceGB = [math]::round( ($DatastoreReport | Measure-Object -Sum -Property UsedSpaceGB).sum, 1 )
			}
		    $MyView += $SizingReport
            Write-Verbose "$(Get-Date -Format G) Process Global Report completed"
            #endregion
		}

        }
        Else {
            Write-Error "Validation Failed! Processing Skipped"
        }
        
    }

    End {
        $MyView
    }

}