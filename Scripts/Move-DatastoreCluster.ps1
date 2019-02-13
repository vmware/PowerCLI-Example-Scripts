function Move-DatastoreCluster {
<#  
.SYNOPSIS  
    Moves a datastore cluster to a new location
.DESCRIPTION 
    Will move a datastore cluster to a new location
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER DatastoreCluster
    Specifies the datastore cluster you want to move.	
.PARAMETER Destination
    Specifies a destination where you want to place the datastore cluster
.EXAMPLE
    Move-DatastoreCluster -DatastoreCluster $DSCluster -Destination $DSClusterFolder
    Moves the $DSCluster datastore cluster to the specified $DSClusterFolder folder.
#>
[CmdletBinding(SupportsShouldProcess = $True)] 
	param(
	[Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
    [VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.DatastoreCluster]$DatastoreCluster,
    [Parameter(Mandatory=$false,Position=1,ValueFromPipelineByPropertyName=$true)]
    [VMware.VimAutomation.ViCore.Types.V1.Inventory.Folder]$Destination
  	)

    if ($Global:DefaultVIServer.IsConnected -eq $false) {
        Write-Warning -Message "No vCenter Server connection found."
        break
    }

    If ($Pscmdlet.ShouldProcess($DatastoreCluster,"Move Datastore Cluster")) {
        $Destination.ExtensionData.MoveIntoFolder($DatastoreCluster.ExtensionData.MoRef)
    }

}