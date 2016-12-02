function Get-VMmaxIOPS {
<#	
    .NOTES
    ===========================================================================
    Created by: Markus Kraus
    Twitter: @VMarkus_K
    Private Blog: mycloudrevolution.com
    ===========================================================================
    Changelog:  
    2016.10 ver 1.0 Base Release 
    2016.11 ver 1.1 Added vSphere 6.5 Support, New Counters, More Error Handling
    ===========================================================================
    External Code Sources:  
    http://www.lucd.info/2011/04/22/get-the-maximum-iops/
    https://communities.vmware.com/thread/485386
    ===========================================================================
    Tested Against Environment:
    vSphere Version: 5.5 U2, 6.5
    PowerCLI Version: PowerCLI 6.3 R1, 6.5 R1
    PowerShell Version: 4.0, 5.0
    OS Version: Windows 8.1, Windows Server 2012 R2
    ===========================================================================
    Keywords vSphere, ESXi, VM, Storage
    ===========================================================================

    .DESCRIPTION
    This Function will Create a VM Disk IOPS Report  

    .Example
    Get-VM TST* | Get-VMmaxIOPS -Minutes 60 | FT -Autosize

    .Example
    $SampleVMs = Get-VM "TST*"
    Get-VMmaxIOPS -VMs $SampleVMs -Minutes 60

    .PARAMETER VMs
    Specify the VMs 

	.PARAMETER Minutes
    Specify the Minutes to report (10080 is one Week) 

#Requires PS -Version 4.0
#Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="6.3.0.0"}
#>

[CmdletBinding()]
param( 
    [Parameter(Mandatory=$true, ValueFromPipeline=$True, Position=0)]
    [ValidateNotNullorEmpty()]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]] $VMs,
    [Parameter(Mandatory=$false, Position=1, HelpMessage = "Specify the Minutes to report (10080 is one Week)")]
    [ValidateNotNullorEmpty()]
        [int] $Minutes = 30
)
Begin {
    # none
    }
Process { 
       if ($_.PowerState -eq "PoweredOn") {
            #region: Global Definitions
            [int]$TimeRange = "-" + $Minutes
            #endregion

            #region: Creating VM Stats
            Write-Verbose "$(Get-Date -Format G) Create VM Stats..."
            $VMMetrics = "virtualdisk.numberwriteaveraged.average","virtualdisk.numberreadaveraged.average"
            $Start = (Get-Date).AddMinutes($TimeRange)
            $stats = Get-Stat -Realtime -Stat $VMMetrics -Entity $VMs -Start $Start -Verbose:$False
            Write-Verbose "$(Get-Date -Format G) Create VM Stats completed"
            #endregion

            #region: Creating HD-Tab
            Write-Verbose "$(Get-Date -Format G) Create HD Tab..."
            $hdTab = @{}
            foreach($hd in (Get-Harddisk -VM $VMs)){
                $controllerKey = $hd.Extensiondata.ControllerKey
                $controller = $hd.Parent.Extensiondata.Config.Hardware.Device | where{$_.Key -eq $controllerKey}
                $hdTab[$hd.Parent.Name + "/scsi" + $controller.BusNumber + ":" + $hd.Extensiondata.UnitNumber] = $hd.FileName.Split(']')[0].TrimStart('[')
            }
            Write-Verbose "$(Get-Date -Format G) Create HD Tab completed"
            #endregion

            #region: Creating Reports
            Write-Verbose "$(Get-Date -Format G) Create Report..."
            $reportPerf = @() 
            $reportPerf = $stats | Group-Object -Property {$_.Entity.Name},Instance | %{
                New-Object PSObject -Property @{
                    VM = $_.Values[0]
                    Disk = $_.Values[1]
                    IOPSWriteAvg = [math]::round( ($_.Group | `
                        where{$_.MetricId -eq "virtualdisk.numberwriteaveraged.average"} | `
                        Measure-Object -Property Value -Average).Average,2)
                    IOPSReadAvg = [math]::round( ($_.Group | `
                        where{$_.MetricId -eq "virtualdisk.numberreadaveraged.average"} | `
                        Measure-Object -Property Value -Average).Average,2)
                    Datastore = $hdTab[$_.Values[0] + "/"+ $_.Values[1]]
                }
            }
            Write-Verbose "$(Get-Date -Format G) Create Report completed"
            #endregion
            

        }
        Else {
            Write-Error "VM $($_.Name) is Powered Off! Processing Skipped"
       }
       $reportPerf | Select-Object VM, Disk, Datastore, IOPSWriteAvg, IOPSReadAvg
    }

End {
     # none   
    }

}