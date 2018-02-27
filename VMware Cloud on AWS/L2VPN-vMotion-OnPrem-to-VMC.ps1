<#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          January 8, 2018
	 Organization: 	VMware
     Blog:          brianjgraf.com
     Twitter:       @vBrianGraf
    ===========================================================================
    
	.DESCRIPTION
    This will allow you to vMotion workloads from your on-premises environment to VMware Cloud on AWS.

	.NOTES
    PLEASE NOTE THAT THIS REQUIRES L2 Stretch Network between your on-prem environment and VMC. Without the Layer2 VPN, vMotion will not work.
#>
# ------------- VARIABLES SECTION - EDIT THE VARIABLES BELOW ------------- 
$destinationvCenter = "vcenter.sddc-52-35-57-20.vmc.vmware.com"
$destinationvCenterUser = "brian"
$destinationvCenterPassword = ''
$DestinationResourcePool = "Compute-ResourcePool"
$DestinationPortGroup = "L2-Stretch-Network"
$DestinationDatastore = "WorkloadDatastore"
$DestinationFolder = "Workloads"

$SourcevCenter = "vcsa-tmm-02.cpbu.lab" # This is your on-prem vCenter
$SourcevCenterUser = "brian"
$SourcevCenterPassword = ""

# This is an easy way to select which VMs will vMotion up to VMC.
$VMs = "BG_Ubuntu*"
# ------------- END VARIABLES - DO NOT EDIT BELOW THIS LINE ------------- 

$destVCConn = Connect-VIServer -Server $destinationvCenter -User $destinationvCenterUser -Password $destinationvCenterPassword
$sourceVCConn = connect-viserver $SourcevCenter -User $SourcevCenterUser -Password $SourcevCenterPassword
$i = 1
$CountVMstoMove = (Get-VM $VMs -Server $sourceVCConn).Count
foreach ($VM in (get-VM $VMs -Server $sourceVCConn)) {
$networkAdapter = Get-NetworkAdapter -VM $vm -Server $sourceVCConn

$destination = Get-Resourcepool $DestinationResourcePool -Server $destVCConn
$destinationPortGroup = Get-VDPortgroup -Name $DestinationPortGroup -Server $destVCConn
$destinationDatastore = Get-Datastore $DestinationDatastore -Server $destVCConn
$folder = get-folder $DestinationFolder -server $destVCConn

Write-host "($i of $CountVMsToMove) Moving " -NoNewline
Write-host "$($VM.name) " -NoNewline -ForegroundColor Yellow
Write-host "from " -NoNewline
Write-host "($SourcevCenter) " -NoNewline -ForegroundColor Yellow
Write-host "to " -NoNewline
Write-host "($DestinationvCenter) " -ForegroundColor Yellow
$Duration = Measure-Command {Move-VM -VM $vm -Destination $destination -NetworkAdapter $networkAdapter -PortGroup $destinationPortGroup -Datastore $destinationDatastore -InventoryLocation $folder | Out-Null}
Write-host "    ($i of $CountVMsToMove) Move of $($VM.name) Completed in ($Duration) Minutes!" -ForegroundColor Green
$i++
}
##############################################