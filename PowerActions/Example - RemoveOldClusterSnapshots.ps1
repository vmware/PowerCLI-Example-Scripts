param (
    [Parameter(Mandatory=$true)]    
    [VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster] $cluster, 
    [DateTime] $date)

if ($null -eq $date) {
    $date = (Get-Date).AddDays(-7)
}

$vms = Get-VM -Location $cluster
foreach ($vm in $vms) {
    $snaphostsToBeRemoved = Get-Snapshot -VM $vm | where {$_.Created -lt $date}
    if ($null -ne $snaphostsToBeRemoved) {
        Write-Host "Removing snapshots: '$snaphostsToBeRemoved' of VM: '$vm'"
        Remove-Snapshot $snaphostsToBeRemoved -Confirm:$false
    }
}