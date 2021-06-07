<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Get-DatastoreSIOCStatCollection {
<#
.SYNOPSIS
    Gathers information on the status of SIOC statistics collection for a datastore
.DESCRIPTION
    Will provide the status on a datastore's SIOC statistics collection
.NOTES
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com
.PARAMETER Datastore
    Datastore to be ran against
.EXAMPLE
	Get-DatastoreSIOCStatCollection -Datastore ExampleDatastore
	Retreives the status of SIOC statistics collection for the provided datastore
#>
[CmdletBinding()]
	param(
	[Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
        $Datastore
  	)

    Process {

        #Collect information about the desired datastore/s and verify existance
        $ds = Get-Datastore $datastore -warningaction silentlycontinue -erroraction silentlycontinue
        if (!$ds) {Write-Warning -Message "No Datastore found"}
        else {

            $report = @()

            #Loops through each datastore provided and feeds back information about the SIOC Statistics Collection status
            foreach ($item in $ds) {

                $tempitem = "" | select Name,SIOCStatCollection
                $tempitem.Name = $item.Name
                $tempitem.SIOCStatCollection = $item.ExtensionData.IormConfiguration.statsCollectionEnabled
                $report += $tempitem

            }

        #Returns the output to the user
        return $report

        }

    }

}


function Set-DatastoreSIOCStatCollection {
<#
.SYNOPSIS
    Configures the status of SIOC statistics collection for a datastore
.DESCRIPTION
    Will modify the status on a datastore's SIOC statistics collection
.NOTES
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com
.PARAMETER Datastore
    Datastore to be ran against
.EXAMPLE
	Set-DatastoreSIOCStatCollection -Datastore ExampleDatastore -Enable
	Enables SIOC statistics collection for the provided datastore
#>
[CmdletBinding(SupportsShouldProcess)]
	param(
	    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
        $Datastore,
        [Switch]$Enable,
        [Switch]$Disable
  	)

    Process {

        #Collect information about the desired datastore/s and verify existance
        $ds = Get-Datastore $datastore -warningaction silentlycontinue -erroraction silentlycontinue
        if (!$ds) {Write-Warning -Message "No Datastore found"}
        else {

            $report = @()

            #Loops through each datastore provided and modifies the SIOC Statistics Collection status
            foreach ($dsobj in $ds) {

                $_this = Get-View -id 'StorageResourceManager-StorageResourceManager'
                $spec = New-Object vmware.vim.storageiormconfigspec

                if ($Enable) {

                    $spec.statsCollectionEnabled = $true

                } elseif ($Disable) {

                    $spec.statsCollectionEnabled = $false

                }

                $_this.ConfigureDatastoreIORM_Task($dsobj.ExtensionData.MoRef,$spec) | out-null
                start-sleep -s 1
                $report += Get-View -Id $dsobj.ExtensionData.MoRef -Property Name,Iormconfiguration.statsCollectionEnabled | select Name,@{N='SIOCStatCollection';E={$_.Iormconfiguration.statsCollectionEnabled}}

            }

            #Returns the output to the user
            return $report
        }
    }

}
