function Enable-OMMaintenance {
      <#	
	    .NOTES
	        Script name: vRealize Operations Maintenance Mode.ps1
            Created on: 07/26/2016
            Author: Alan Renouf, @alanrenouf
            Dependencies: PowerCLI 6.0 R2 or later
	    .DESCRIPTION
		    Places a vSphere Inventory object into maintenance mode in vRealize Operations
        .Example
        Set All VMs with a name as backup as being in maintenance mode for 20 minutes:

        Since Get-Inventory does not return Datastore Objects, we need to specify we're passing Datastore objects using switch "IsDatastore"
	
	Get-Datastore DS1 | Enable-OMMaintenance -MaintenanceTime 20 -IsDatastore True
	
	Get-VM backup* | Enable-OMMaintenance -MaintenanceTime 20

        Name                         Health  ResourceKind    Description                                           
        ----                         ------  ------------    -----------                                           
        backup-089e13fd-7d7a-0       Grey    VirtualMachine                                                        
        backup-d90e0b39-2618-0       Grey    VirtualMachine                                                        
        backup-e48ca842-316a-0       Grey    VirtualMachine                                                        
        backup-77da3713-919a-0       Grey    VirtualMachine                                                        
        backup-c32f4da8-86c4-0       Grey    VirtualMachine                                                        
        backup-c3fcb95c-cfe2-0       Grey    VirtualMachine                                                        
        backup-4318bb1e-614a-0       Grey    VirtualMachine                                                        

    #>
    [CmdletBinding()]
      param(
            [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
            [ValidateNotNullOrEmpty()]
            [System.String]
            $Resource,

            [Parameter(Position=1, Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [Int]
            $MaintenanceTime,
	    
	    [Parameter(Position=2, Mandatory=$false)]
	    [ValidateSet(“True”, “False”)]
	    [System.String]
            $IsDatastore= $false

      )
      process {
            Foreach ($Entry in $resource) {
	       if ($IsDatastore -eq $true)
                {
                  $Item = Get-Datastore -Name $Entry | Get-OMResource
                  if (-not $Item) {
                        throw "$Entry not found"
                  } Else {
                        $Item.ExtensionData.MarkResourceAsBeingMaintained($MaintenanceTime)
                        Get-Datastore -Name $Entry | Get-OMResource
                  }
                }
                Else
                {
                  $Item = Get-Inventory -Name $Entry | Get-OMResource
                  if (-not $Item) {
                        throw "$Entry not found"
                  } Else {
                        $Item.ExtensionData.MarkResourceAsBeingMaintained($MaintenanceTime)
                        Get-Inventory -Name $Entry | Get-OMResource
                  }
		}
            }
      }
}

function Disable-OMMaintenance {
      <#	
	    .NOTES
	        Script name: vRealize Operations Maintenance Mode.ps1
            Created on: 07/26/2016
            Author: Alan Renouf, @alanrenouf
            Dependencies: PowerCLI 6.0 R2 or later
	    .DESCRIPTION
		    Removes a vSphere Inventory object from maintenance mode in vRealize Operations
        .Example
        Disable maintenance mode for all VMs with a name of backup

        Since Get-Inventory does not return Datastore Objects, we need to specify we're passing Datastore objects using switch "IsDatastore"
	
	Get-Datastore DS1 | Disable-OMMaintenance -IsDatastore True
	
	Get-VM backup* | Disable-OMMaintenance

        Name                         Health  ResourceKind    Description                                           
        ----                         ------  ------------    -----------                                           
        backup-089e13fd-7d7a-0       Grey    VirtualMachine                                                        
        backup-d90e0b39-2618-0       Grey    VirtualMachine                                                        
        backup-e48ca842-316a-0       Grey    VirtualMachine                                                        
        backup-77da3713-919a-0       Grey    VirtualMachine                                                        
        backup-c32f4da8-86c4-0       Yellow  VirtualMachine                                                        
        backup-c3fcb95c-cfe2-0       Yellow  VirtualMachine                                                        
        backup-4318bb1e-614a-0       Yellow  VirtualMachine                                                        

    #>
    [CmdletBinding()]
      param(
            [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
            [ValidateNotNullOrEmpty()]
            [System.String]
            $Resource,
	    
	    [Parameter(Position=1, Mandatory=$false)]
	    [ValidateSet(“True”, “False”)]
	    [System.String]
            $IsDatastore= $false
      )
      process {
            Foreach ($Entry in $resource) {
	      If ($IsDatastore -eq $true)
                {
                  $Item = Get-Datastore -Name $Entry | Get-OMResource
                  if (-not $Item) {
                        throw "$Entry not found"
                  } Else {
                        $Item.ExtensionData.UnmarkResourceAsBeingMaintained()
                        Get-Datastore -Name $Entry | Get-OMResource
                  }
                }
                Else
                {
                  $Item = Get-Inventory -Name $Entry | Get-OMResource
                  if (-not $Item) {
                        throw "$Entry not found"
                  } Else {
                        $Item.ExtensionData.UnmarkResourceAsBeingMaintained()
                        Get-Inventory -Name $Entry | Get-OMResource
                  }
		}
            }
      }
}

#Write-Host "Enable a single host as being in maintenance mode for 1 minute"
#Enable-OMMaintenance -Resource ESX-01a* -MaintenanceTime 1

#Write-Host "List All Host Resources and their state"
#Get-OMResource ESX-* | Select Name, State | FT

#Write-Host "Set All VMs with a name as backup as being in maintenance mode for 20 minutes"
#Get-VM backup* | Enable-OMMaintenance -MaintenanceTime 20

#Write-Host "List All Backup VM Resources and their state"
#Get-VM backup* | Get-OMResource | Select Name, State | FT

#Write-Host "Disable maintenance mode for all VMs with a name as backup as we have completed our scheduled work"
#Get-VM backup* | Disable-OMMaintenance

#Write-Host "List All VM Resources and their state"
#Get-VM backup* | Get-OMResource | Select Name, State | FT

