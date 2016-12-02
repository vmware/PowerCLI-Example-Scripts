function Get-VMmaxIOPS {
<#	

    .SYNOPSIS
	Report VM Disk IOPS of VMs

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

    .Notes
    NAME:  Get-VMmaxIOPS.ps1
    LASTEDIT: 08/23/2016
    VERSION: 1.1
    KEYWORDS: VMware, vSphere, ESXi, IOPS

	.Link
	http://mycloudrevolution.com/

#Requires PS -Version 4.0
#Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="6.3.0.0"}
#>

[CmdletBinding()]
param( 
    [Parameter(Mandatory=$true, ValueFromPipeline=$True, Position=0)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]
        $VMs,
    [Parameter(Mandatory=$false, Position=1)]
        [int] $Minutes = 30
)

Process { 

    #region: Global Definitions
    [int]$TimeRange = "-" + $Minutes
    #endregion

    #region: Creating Metrics
    Write-Debug "Starting to Create Metrics..."
    $metrics = "virtualDisk.numberReadAveraged.average","virtualDisk.numberWriteAveraged.average"
    $start = (Get-Date).AddMinutes($TimeRange)
    $stats = Get-Stat -Stat $metrics -Entity $VMs -Start $start
    #endregion

    #region: Creating HD-Tab
    Write-Debug "Starting to Create HD-Tab..."
    $hdTab = @{}
    foreach($hd in (Get-Harddisk -VM $VMs)){
        $controllerKey = $hd.Extensiondata.ControllerKey
        $controller = $hd.Parent.Extensiondata.Config.Hardware.Device | where{$_.Key -eq $controllerKey}
        $hdTab[$hd.Parent.Name + "/scsi" + $controller.BusNumber + ":" + $hd.Extensiondata.UnitNumber] = $hd.FileName.Split(']')[0].TrimStart('[')
    }
    #endregion

    #region: Creating Reports
    Write-Debug "Starting to Process IOPS Report..."
    $reportPerf = @() 
    $reportPerf = $stats | Group-Object -Property {$_.Entity.Name},Instance | %{
        New-Object PSObject -Property @{
            VM = $_.Values[0]
            Disk = $_.Values[1]
            IOPSMax = ($_.Group | `
                Group-Object -Property Timestamp | `
                %{$_.Group[0].Value + $_.Group[1].Value} | `
                Measure-Object -Maximum).Maximum
            Datastore = $hdTab[$_.Values[0] + "/"+ $_.Values[1]]
        }
    }
    $reportPerf | Select-Object VM, Disk, Datastore, IOPSMax
    #endregion
    }
}