### Global Variables# If the parameter -auto $true is used then it will attempt to connect without credential promptsparam($auto)
### Datastore Array$vmList = @()
### vCenter Connect$vcArray = "vcenter1","vcenter2"
if ($auto){ Add-PSSnapin VMware.VimAutomation.Core -ErrorAction:SilentlyContinue Write-Host Connecting to $vcArray $vcs = Connect-VIServer -Server $vcArray -WarningAction:SilentlyContinue}else{ Write-Host Write-Host "Using the -auto switch will attempt to connect to all vCenters under the current credentials." -ForegroundColor White Write-Host "vCenters" -ForegroundColor White "_" * 40
 $i = 0 foreach($vcElement in $vcArray){  $i++  Write-Host "$i`: $vcElement" }
 Write-Host $vcNum = Read-Host "Enter the vCenter to connect to"
 $cred = Get-Credential $vcs = Connect-VIServer -Credential $cred -Server $vcArray[$vcNum -1] -WarningAction:SilentlyContinue Write-Host
}
$totalVCs = $vcs | Measure-Object$i = 0
foreach($vc in $vcs){ $i++ Write-Progress -activity "Searching $vc for Connected CD-ROMs..." -status "Percent Completed: " -PercentComplete (($i / $totalVCs.Count)  * 100)  Write-Host Retrieving VMs... $vms = Get-VM -Server $vc | where {($_.Name -notlike "vm-*") -and ($_.Name -notlike "sc-*")} | Sort-Object Name Write-Host  foreach($vm in $vms){  $vmCD = Get-CDDrive $vm    if($vmCD.IsoPath -ne $null){   if($vmCD.IsoPath.Contains("vmware")){    $results = Dismount-Tools $vm   }   $results = Set-CDDrive $vmCD -NoMedia -Confirm:$false  }     if($vmCD.RemoteDevice -ne $null){   if($vmCD.RemoteDevice.Contains("vmware")){    $results = Dismount-Tools $vm   }   $results = Set-CDDrive $vmCD -NoMedia -Confirm:$false  }    if(($vmCD.ConnectionState.Connected -eq $true) -or ($vmCD.HostDevice -ne $null)){   $results = Set-CDDrive $vmCD -NoMedia -Confirm:$false  }    $vmRow = New-Object psobject|select "vCenter","VM","Connected","Start_Connected","ISO","Host_Device","Remote_Device"  $vmRow.vCenter = $vc.Name  $vmRow.VM = $vm.Name  $vmRow.Connected = $vmCD.ConnectionState.Connected  $vmRow.Start_Connected = $vmCD.ConnectionState.StartConnected  $vmRow.ISO = $vmCD.IsoPath  $vmRow.Host_Device = $vmCD.HostDevice  $vmRow.Remote_Device = $vmCD.RemoteDevice  $vmList += $vmRow  # $vmList | Export-Csv $vmListFile -noTypeInformation  $vmRow
 }}
Write-Host Disconnecting from vCenter`(s`)Disconnect-VIServer * -Confirm:$false
