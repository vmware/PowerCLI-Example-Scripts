<#
    .NOTES
    ===========================================================================
	 Created by:   	Alan Renouf
     Date:          March 27, 2018
	 Organization: 	VMware
     Blog:          virtu-al.net
     Twitter:       @alanrenouf
    ===========================================================================
    
	.DESCRIPTION
    This will allow you to create multiple workloads in the correct locations on VMware Cloud on AWS.

    .Example
    $vCenter = "vcenter.sddc-52-53-75-20.vmc.vmware.com"
    $vCenterUser = "cloudadmin@vmc.local"
    $vCenterPassword = 'VMware1!'
    $ResourcePool = "Compute-ResourcePool"
    $Datastore = "WorkloadDatastore"
    $DestinationFolder = "Workloads"
    $Template = "Gold_Linux_Template"
    $VMNamePrefix = "NEWVM"
    $NumofVMs = 100
    $RunASync = $true #Set this to $True to create the VMs and not wait for the result before starting the next one
#>

# ------------- VARIABLES SECTION - EDIT THE VARIABLES BELOW ------------- 
$vCenter = "vcenter.sddc-123456789.vmc.vmware.com"
$vCenterUser = "cloudadmin@vmc.local"
$vCenterPassword = '123456789'
$ResourcePool = "Compute-ResourcePool"
$Datastore = "WorkloadDatastore"
$DestinationFolder = "Workloads"
$Template = "Gold_Linux_Template"
$VMNamePrefix = "NEWVM"
$NumofVMs = 100
$RunASync = $true
# ------------- END VARIABLES - DO NOT EDIT BELOW THIS LINE ------------- 

# Connect to VMC vCenter Server
$VCConn = Connect-VIServer -Server $vCenter -User $vCenterUser -Password $vCenterPassword

1..$NumofVMs | Foreach-Object {
    Write-Host "Creating $VMNamePrefix$($_)"
    if ($RunASync){
        New-VM -Name "$VMNamePrefix$($_)" -Template $Template -ResourcePool $ResourcePool -Datastore $datastore -Location $DestinationFolder -RunAsync
    } Else {
        New-VM -Name "$VMNamePrefix$($_)" -Template $Template -ResourcePool $ResourcePool -Datastore $datastore -Location $DestinationFolder
    }
}
