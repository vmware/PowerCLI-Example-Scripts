function Remove-HostClient {
<#	
	.NOTES
	===========================================================================
	 Created on:   	8/13/2015 9:12 AM
	 Created by:   	Brian Graf
	 Github:        http://www.github.com/vtagion
     Twitter:       @vBrianGraf
     Website:     	http://www.vtagion.com
	===========================================================================
	.DESCRIPTION
		This advanced function will allow you to remove the ESXi Host Client
    on all the hosts in a specified cluster.
    .Example
    Remove-HostClient -Cluster (Get-Cluster Management-CL) 

    .Example
    $Cluster = Main-CL
    Remove-HostClient -Cluster $cluster
#>
[CmdletBinding()]
param(
    [ValidateScript({Get-Cluster $_})]
    [VMware.VimAutomation.ViCore.Impl.V1.Inventory.ComputeResourceImpl]$Cluster
)
Process {

# Get all ESX hosts in cluster that meet criteria
Get-VMhost -Location $Cluster | where { $_.PowerState -eq "PoweredOn" -and $_.ConnectionState -eq "Connected" } | foreach {

    Write-host "Preparing to remove Host Client from $($_.Name)" -ForegroundColor Yellow

    # Prepare ESXCLI variable
    $ESXCLI = Get-EsxCli -VMHost $_

    # Check to see if VIB is installed on the host
    if (($ESXCLI.software.vib.list() | Where {$_.Name -match "esx-ui"})) {

        Write-host "Removing ESXi Embedded Host Client on $($_.Name)" -ForegroundColor Yellow

        # Command saved to variable for future verification
        $action = $esxcli.software.vib.remove($null,$null,$null,$null,"esx-ui")

        # Verify VIB removed successfully
        if ($action.Message -eq "Operation finished successfully."){Write-host "Action Completed successfully on $($_.Name)" -ForegroundColor Green} else {Write-host $action.Message -ForegroundColor Red}

    } else { Write-host "It appears Host Client is not installed on this host. Skipping..." -ForegroundColor Yellow }
}
}
End {Write-host "Function complete" -ForegroundColor Green}
}
