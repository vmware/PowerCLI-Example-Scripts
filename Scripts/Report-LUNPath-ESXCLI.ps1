<#	
	.NOTES
	===========================================================================
	 Created by: Markus Kraus
	 Organization: Private
     Personal Blog: mycloudrevolution.com
     Twitter: @vMarkus_K
	===========================================================================
	.DESCRIPTION
	This script will create a Report of LUNs with Paths that have more than one unique LUN ID or have more than the defined Paths.
	Information’s will be gathered via ESXCLI. This is necessary to report also hidden Paths!

    .Example
    ./Report-LUNPath-ESXCLI.ps1

#>

#region 1: Global Definitions
$MaxLUNPaths  = 2
#endregion

#region 2: Get all Connected Hosts
$myHosts = Get-VMHost | where {$_.ConnectionState  -eq "Connected" -and $_.PowerState -eq "PoweredOn"}
#endregion

#region 3: Create Report
$Report = @()
foreach ($myHost in $myHosts) {
	$esxcli2 = Get-ESXCLI -VMHost $myHost -V2
	$devices = $esxcli2.storage.core.path.list.invoke() | select Device -Unique

	foreach ($device in $devices) {
		$arguments = $esxcli2.storage.core.path.list.CreateArgs()
		$arguments.device = $device.Device
		$LUNs = $esxcli2.storage.core.path.list.Invoke($arguments)
	
		$LUNReport = [PSCustomObject] @{
			HostName = $myHost.Name
			Device = $device.Device
			LUNPaths = $LUNs.Length
			LUNIDs = $LUNs.LUN | Select-Object -Unique
		}
		$Report += $LUNReport
		}
	}
#endregion

#region 4: Output Report
$Report | where {$_.LUNPaths -gt $MaxLUNPaths -or ($_.LUNIDs | measure).count -gt 1 }  | ft -AutoSize
#endregion