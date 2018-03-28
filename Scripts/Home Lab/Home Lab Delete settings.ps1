$ESXIP = "192.168.1.201"
$ESXUser = "root"
$ESXPWD = "VMware1!"

Connect-viserver $esxip -user $ESXUser -pass $ESXPWD

#Leaving confirm off just in case someone happens to be connected to more than one vCenter/Host!
Get-VM | Stop-VM
Get-VM | Remove-VM

$ESXCLI = Get-EsxCli -v2 -VMHost (get-VMHost)
$esxcli.vsan.cluster.leave.invoke()

$VSANDisks = $esxcli.storage.core.device.list.invoke() | Where {$_.isremovable -eq "false"} | Sort size
$Performance = $VSANDisks[0]
$Capacity = $VSANDisks[1]

$removal = $esxcli.vsan.storage.remove.CreateArgs()
$removal.ssd = $performance.Device
$esxcli.vsan.storage.remove.Invoke($removal)

$capacitytag = $esxcli.vsan.storage.tag.remove.CreateArgs()
$capacitytag.disk = $Capacity.Device
$capacitytag.tag = "capacityFlash"
$esxcli.vsan.storage.tag.remove.Invoke($capacitytag)

Set-VMHostSysLogServer $null
Remove-VMHostNtpServer (Get-VMHostNtpServer) -Confirm:$false