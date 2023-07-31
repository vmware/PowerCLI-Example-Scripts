param (
    [Parameter(Mandatory=$true)]    
    [VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster[]] $cluster, 
    [Parameter(Mandatory=$true)]
    [string] $smtp,
    [Parameter(Mandatory=$true)]
    [string] $email)

$vms = Get-VM -Location $cluster
$snapshots = @()
foreach ($vm in $vms) {
    $snapshots += Get-Snapshot -VM $vm    
}

$header = @"
<style>
   table {
		font-size: 12px;
		border: 0px; 
		font-family: Arial, Helvetica, sans-serif;
	} 
	
    td {
		padding: 4px;
		margin: 0px;
		border: 0;
	}
    th {
        background: #395870;
        background: linear-gradient(#49708f, #293f50);
        color: #fff;
        font-size: 11px;
        text-transform: uppercase;
        padding: 10px 15px;
        vertical-align: middle;
	}
    tbody tr:nth-child(even) {
        background: #f0f0f2;
    }
</style>
"@

$snapshots | select Name,VM,Created,@{Name="Size";Expression={[math]::Round($_.SizeMB,3)}},IsCurrent | `
    ConvertTo-Html -head $header | Out-File "SnapshotReport.html"

Send-MailMessage -from "Snapshot Reports <noreply@vmware.com>" `
                -to $email `
                -subject "Snapshot Report" `
                -body "Cluster snapshot report" `
                -Attachment "SnapshotReport.html" `
                -smtpServer $smtp