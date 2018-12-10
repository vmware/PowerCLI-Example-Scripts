function Start-UNMAP {
<#
	.SYNOPSIS
    Process SCSI UNMAP on VMware Datastores
    
	.DESCRIPTION
    This Function will process SCSI UNMAP on VMware Datastores via ESXCLI -V2

	.Example
    Start-UNMAP -ClusterName myCluster -DSWildcard *RAID5* 

	.Example
    Start-UNMAP -ClusterName myCluster -DSWildcard *RAID5* -Verbose -WhatIf

	.Notes
	NAME: Start-UNMAP.psm1
    AUTHOR: Markus Kraus  
	LASTEDIT: 23.09.2016
	VERSION: 1.0
	KEYWORDS: VMware, vSphere, ESXi, SCSI, VAAI, UNMAP
   
	.Link
	http://mycloudrevolution.com/
 
 #Requires PS -Version 4.0
 #Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="6.3.0.0"}
 #>

    [CmdletBinding(SupportsShouldProcess = $true,ConfirmImpact='High')]
    param( 
        [Parameter(Mandatory=$true, Position=0)]
            [String]$ClusterName,
        [Parameter(Mandatory=$true, Position=1)]
            [String]$DSWildcard
    )
    Process {
        $Validate = $true 
        #region: PowerCLI Session Timeout
        Write-Verbose "Set Session Timeout ..."
        $initialTimeout = (Get-PowerCLIConfiguration -Scope Session).WebOperationTimeoutSeconds
        Set-PowerCLIConfiguration -Scope Session -WebOperationTimeoutSeconds -1 -Confirm:$False | Out-Null
        #endregion

        #region: Get Cluster
        $Cluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue
        Write-Verbose "vSphere Cluster: $Cluster"
        if (!$Cluster){Write-Error "No Cluster found!"; $Validate = $false}
        #endregion

        #region: Get Hosts
        $ClusterHosts = $Cluster | Get-VMHost -ErrorAction SilentlyContinue | where {$_.ConnectionState -eq "Connected" -and $_.PowerState -eq "PoweredOn"}
        Write-Verbose "vSphere Cluster Hosts: $ClusterHosts"
        if (!$ClusterHosts){Write-Error "No Hosts found!"; $Validate = $false}
        #endregion

        #region: Get Datastores
        $ClusterDataStores = $Cluster | Get-Datastore -ErrorAction SilentlyContinue | where {$_.Name -like $DSWildcard -and $_.State -eq "Available" -and $_.Accessible -eq "True"}
        Write-Verbose "vSphere Cluster Datastores: $ClusterDataStores"
        if (!$ClusterDataStores){Write-Error "No Datastores found!"; $Validate = $false}
        #endregion

        #region: Process Datastores
        if ($Validate -eq $true) {
            Write-Verbose "Starting Loop..."
            foreach ($ClusterDataStore in $ClusterDataStores) {
                Write-Verbose "vSphere Datastore to Process: $ClusterDataStore"
                $myHost = $ClusterHosts[(Get-Random -Maximum ($ClusterHosts).count)]
                Write-Verbose "vSphere Host to Process: $myHost"
                $esxcli2 = $myHost | Get-ESXCLI -V2
                $arguments = $esxcli2.storage.vmfs.unmap.CreateArgs()
		        $arguments.volumelabel = $ClusterDataStore
                $arguments.reclaimunit = "256"
                if ($PSCmdlet.ShouldProcess( $ClusterDataStore,"Starting UNMAP on $myHost")) {
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    try {
                        Write-Output "Starting UNMAP for $ClusterDataStore on $myHost..."
                        $esxcli2.storage.vmfs.unmap.Invoke($arguments)
                        }
                    catch {
                        Write-Output "A Error occured: " "" $error[0] ""
                        }
                    $stopwatch.Stop()
                    Write-Output "UNMAP duration: $($stopwatch.Elapsed.Minutes)"
                }

            }
        }
        else {
            Write-Error "Validation Failed. Processing Loop Skipped!"
        }
        #endregion

    #region: Revert PowerCLI Session Timeout    
    Write-Verbose "Revert Session Timeout ..."
    Set-PowerCLIConfiguration -Scope Session -WebOperationTimeoutSeconds $initialTimeout -Confirm:$False | Out-Null
    #endregion
    }
    
}
