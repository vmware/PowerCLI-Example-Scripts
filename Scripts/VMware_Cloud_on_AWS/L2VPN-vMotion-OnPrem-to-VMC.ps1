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

    .Example
    # ------------- VARIABLES SECTION - EDIT THE VARIABLES BELOW ------------- 
    $destinationvCenter = "vcenter.sddc-52-53-75-20.vmc.vmware.com"
    $destinationvCenterUser = "clouduser@cloud.local"
    $destinationvCenterPassword = 'VMware1!'
    $DestinationResourcePool = "Compute-ResourcePool"
    $DestinationPortGroup = "L2-Stretch-Network"
    $DestinationDatastore = "WorkloadDatastore"
    $DestinationFolder = "Workloads"

    $SourcevCenter = "vcsa-tmm-02.utah.lab" # This is your on-prem vCenter
    $SourcevCenterUser = "administrator@vsphere.local"
    $SourcevCenterPassword = "VMware1!"

    # This is an easy way to select which VMs will vMotion up to VMC. The Asterisk
    # acts as a wildcard
    $VMs = "BG_Ubuntu_*"
#>

# ------------- VARIABLES SECTION - EDIT THE VARIABLES BELOW ------------- 
$destinationvCenter = "" # This is your VMware Cloud on AWS SDDC
$destinationvCenterUser = ""
$destinationvCenterPassword = ''
$DestinationResourcePool = "" # Name of the resource pool where the VM will be migrated to
$DestinationPortGroup = "" # Portgroup name that the VM will be connected to
$DestinationDatastore = "" # Name of the vSAN datastore
$DestinationFolder = "" # VM folder where the VM will reside

$SourcevCenter = "" # This is your on-prem vCenter
$SourcevCenterUser = ""
$SourcevCenterPassword = ""

# This is an easy way to select which VMs will vMotion up to VMC.
$VMs = "" 
# ------------- END VARIABLES - DO NOT EDIT BELOW THIS LINE ------------- 

# Connect to VMC Server
$destVCConn = Connect-VIServer -Server $destinationvCenter -User $destinationvCenterUser -Password $destinationvCenterPassword

# Connect to On-Prem Server
$sourceVCConn = connect-viserver $SourcevCenter -User $SourcevCenterUser -Password $SourcevCenterPassword

# Start numbering for status updates
$i = 1

# Count total VMs selected to move
$CountVMstoMove = (Get-VM $VMs -Server $sourceVCConn).Count

# For each VM Get the necessary information for the migration
foreach ($VM in (get-VM $VMs -Server $sourceVCConn)) {

# Get the network adapter information
$networkAdapter = Get-NetworkAdapter -VM $vm -Server $sourceVCConn

# Get the destination resource pool
$destination = Get-Resourcepool $DestinationResourcePool -Server $destVCConn

# Get the destination portgroup
$destinationPortGroup = Get-VDPortgroup -Name $DestinationPortGroup -Server $destVCConn

# Get the destination datastore
$destinationDatastore = Get-Datastore $DestinationDatastore -Server $destVCConn

# Get the destination folder
$folder = get-folder $DestinationFolder -server $destVCConn

# Write updates as each VM is being migrated
Write-host "($i of $CountVMsToMove) Moving " -NoNewline
Write-host "$($VM.name) " -NoNewline -ForegroundColor Yellow
Write-host "from " -NoNewline
Write-host "($SourcevCenter) " -NoNewline -ForegroundColor Yellow
Write-host "to " -NoNewline
Write-host "($DestinationvCenter) " -ForegroundColor Yellow

# The actual vMotion command along with a measurement to time the duration of the vMotion
$Duration = Measure-Command {Move-VM -VM $vm -Destination $destination -NetworkAdapter $networkAdapter -PortGroup $destinationPortGroup -Datastore $destinationDatastore -InventoryLocation $folder | Out-Null}

# Write the completion string
Write-host "    ($i of $CountVMsToMove) Move of $($VM.name) Completed in ($Duration) Minutes!" -ForegroundColor Green

# Increase our integer by one and move on
$i++
}
