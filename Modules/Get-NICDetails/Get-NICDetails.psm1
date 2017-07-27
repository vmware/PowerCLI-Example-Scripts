function Get-NICDetails {
<#	
    .NOTES
    ===========================================================================
    Created by: Markus Kraus
    Twitter: @VMarkus_K
    Private Blog: mycloudrevolution.com
    ===========================================================================
    Changelog:  
    2017.02 ver 1.0 Base Release  
    ===========================================================================
    External Code Sources: 
    -
    ===========================================================================
    Tested Against Environment:
    vSphere Version: ESXi 6.0 U2, ESXi 6.5
    PowerCLI Version: PowerCLI 6.3 R1, PowerCLI 6.5 R1
    PowerShell Version: 4.0, 5.0
    OS Version: Windows 8.1, Server 2008 R2, Server 2012 R2
    Keyword: ESXi, NIC, vmnic, Driver, Firmware
    ===========================================================================

    .DESCRIPTION
    Reports Firmware and Driver Details for your ESXi vmnics.

    .Example
    Get-NICDetails -Clustername *

    .PARAMETER Clustername
    Name or Wildcard of your vSphere Cluster Name to process.


#Requires PS -Version 4.0
#Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="6.3.0.0"}
#>

[CmdletBinding()]
param( 
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, Position=0)]
    [ValidateNotNullorEmpty()]
        [String] $Clustername
        
)

Begin {
    $Validate = $True

    if (($myCluster = Get-Cluster -Name $Clustername).count -lt 1) {
       $Validate = $False
       thow "No Cluster '$myCluster' found!"
    }
  
}

Process {

    $MyView = @()
    if ($Validate -eq $True) {
  
        foreach ($myVMhost in ($myCluster | Get-VMHost)) {

            $esxcli2 = Get-ESXCLI -VMHost $myVMhost -V2
            $niclist = $esxcli2.network.nic.list.invoke()

            $nicdetails = @()
            foreach ($nic in $niclist) {

                $args = $esxcli2.network.nic.get.createargs()
                $args.nicname = $nic.name
                $nicdetail = $esxcli2.network.nic.get.Invoke($args)
                $nicdetails += $nicdetail

                }
            ForEach ($nicdetail in $nicdetails){
		        $NICReport = [PSCustomObject] @{
				        Host = $myVMhost.Name
				        vmnic = $nicdetail.Name
				        LinkStatus = $nicdetail.LinkStatus
				        BusInfo = $nicdetail.driverinfo.BusInfo
				        Driver = $nicdetail.driverinfo.Driver
				        FirmwareVersion = $nicdetail.driverinfo.FirmwareVersion
				        DriverVersion = $nicdetail.driverinfo.Version
				        }
		        $MyView += $NICReport
		        }

		}
        
       $MyView

    }
}
}