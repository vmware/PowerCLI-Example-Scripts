<#
	.NOTES
	Script name: vCenterSnapshot.ps1
	Created on: 20/09/2017
	Author: Lukas Winn, @lukaswinn
	Dependencies: Password is set to VMware123 in my test environment but this can be changed.

	.DESCRIPTION
	Script to retrieve snapshot information for all VM's in a given vCenter

#>
Write-Host "`nGet VM Snapshot Information!"
Write-Host "Copyright 2017 Lukas Winn / @lukaswinn"
Write-Host "Version 1.0" "`n"

$vCenter = Read-Host -prompt 'Enter FQDN / IP address of vCenter'

if ($vCenter) {
    	$vcUser = Read-Host -prompt 'Username'

Write-Host 'vCenter:' $vCenter ''

# Connect to vCenter with $vCenter variable value
Connect-VIServer -Server $vCenter -User $vcUser -Password VMware123

	Write-Host "`nConnected to vCenter: " $vCenter
	Write-Host 'Retrieving snapshot information...'
	Write-Progress -Activity 'Working...'
	  	
		# Get VM snapshot information and output in table format  
		$getSnap = Get-VM | Get-Snapshot | sort SizeGB -descending | Select VM, Name, Created, @{Label="Size";Expression={"{0:N2} GB" -f ($_.SizeGB)}}, Id
	  	$getSnap | Format-Table | Out-Default

# Close connection to active vCenter
Disconnect-VIServer $vCenter -Confirm:$false
	Write-Host 'Connection closed to' $vCenter
}
else {
    Write-Warning "Error: No data entered for vCenter!"
} 
