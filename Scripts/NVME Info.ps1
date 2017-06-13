<#
    .NOTES
    ===========================================================================
	 Created by:   	Alan Renouf
     Organization: 	VMware
     Blog:          http://virtu-al.net
     Twitter:       @alanrenouf
	===========================================================================
#>

Foreach ($vmhost in Get-VMHost) {
    $esxcli = get-esxcli -V2 -vmhost $vmhost
    Write-Host "Host: $($vmhost.name)" -ForegroundColor Green
    $devices = $esxcli.nvme.device.list.Invoke()
    Foreach ($device in $devices) {
        $nvmedevice = $esxcli.nvme.device.get.CreateArgs()
        $nvmedevice.adapter = $device.HBAName
        $esxcli.nvme.device.get.invoke($nvmedevice) | Select-Object ModelNumber, FirmwareRevision
        $features = $esxcli.nvme.device.feature.ChildElements | Select-object -ExpandProperty name
        ForEach ($feature in $features){
            Write-Host "Feature: $feature" -ForegroundColor Yellow
            $currentfeature = $esxcli.nvme.device.feature.$feature.get.CreateArgs()
            $currentfeature.adapter = $device.HBAName
            $esxcli.nvme.device.feature.$feature.get.Invoke($currentfeature)    
        }
    }
}