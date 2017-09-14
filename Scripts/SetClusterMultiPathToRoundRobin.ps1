<#
 Script name: SetClusterMultiPathToRoundRobin.ps1
 Created on: 09/14/2017
 Author: Alan Comstock, @Mr_Uptime
 Description: Set the MultiPath policy for FC devices to RoundRobin for all hosts in a cluster.
 Dependencies: None known
 PowerCLI Version: VMware PowerCLI 6.5 Release 1 build 4624819
 PowerShell Version: 5.1.14393.1532
 OS Version: Windows 10
#>

#Check for any Fibre Channel devices that are not set to Round Robin in a cluster.
#Get-Cluster -Name CLUSTERNAME | Get-VMhost | Get-VMHostHba -Type "FibreChannel" | Get-ScsiLun -LunType disk | Where { $_.MultipathPolicy -notlike "RoundRobin" } | Select CanonicalName,MultipathPolicy

#Set the Multipathing Policy to Round Robin for any Fibre Channel devices that are not Round Robin in a cluster
$cluster = Get-Cluster CLUSTERNAME
$hostlist = Get-VMHost -Location $cluster | Sort Name
$TotalHostCount = $hostlist.count
$hostincrement = 0
while ($hostincrement -lt $TotalHostCount){		#Host Loop
	$currenthost = $hostlist[$hostincrement].Name
	Write-Host "Working on" $currenthost
	$scsilun = Get-VMhost $currenthost | Get-VMHostHba -Type "FibreChannel" | Get-ScsiLun -LunType disk | Where { $_.MultipathPolicy -notlike "RoundRobin" }
	if ($scsilun -ne $null){
		Set-ScsiLun -ScsiLun $scsilun -MultipathPolicy RoundRobin	
	}
	$hostincrement++	#bump the host increment
}
#The End
