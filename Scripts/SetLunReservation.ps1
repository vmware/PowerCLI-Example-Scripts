<#
	.SYNOPSIS
		Set a given LUN ID to Perennially Reserved.
	
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER vCenter
		Set vCenter server to connect to
	
	.PARAMETER Username
		Set username to use
	
	.PARAMETER Password
		Set password to be used
	
	.PARAMETER VirtualMachine
		Name of the virtual machine which has the RDM
	
	.NOTES
		===========================================================================
		Created on:   	20/03/2017 15:05
		Created by:   	Alessio Rocchi <arocchi@vmware.com>
		Organization: 	VMware
		Filename:     	SetLunReservation.ps1
		===========================================================================
#>
param
(
	[Parameter(Mandatory = $true,
			   ValueFromPipeline = $true,
			   Position = 0)]
	[ValidateNotNullOrEmpty()]
	[String]$vCenter,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   HelpMessage = 'Set vCenter Username')]
	[AllowNull()]
	[String]$Username,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   HelpMessage = 'Set vCenterPassword')]
	[AllowNull()]
	[String]$Password,
	[Parameter(Mandatory = $true,
			   ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[String]$VirtualMachine
)

Import-Module -Name VMware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null

try
{
	if ([String]::IsNullOrEmpty($Username) -or [String]::IsNullOrEmpty($Password))
	{
		$vcCredential = Get-Credential
		Connect-VIServer -Server $vCenter -Credential $vcCredential -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
	}
	else
	{
		Connect-VIServer -Server $vCenter -User $Username -Password $Password -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
	}
}
catch
{
	Write-Error("Error connecting to vCenter: {0}" -f $vCenter)
	exit
}


$rDms = Get-HardDisk -DiskType rawPhysical -Vm (Get-VM -Name $VirtualMachine)
$clusterHosts = Get-Cluster -VM $VirtualMachine | Get-VMHost

$menu = @{ }

for ($i = 1; $i -le $rDms.count; $i++)
{
	Write-Host("{0}) {1}[{2}]: {3}" -f ($i, $rDms[$i - 1].Name, $rDms[$i - 1].CapacityGB, $rDms[$i - 1].ScsiCanonicalName))
	$menu.Add($i, ($rDms[$i - 1].ScsiCanonicalName))
}

[int]$ans = Read-Host 'Which Disk you want to configure?'
$selection = $menu.Item($ans)
write-host("Choosed Disk: {0}" -f $selection)

$current = 0
foreach ($vmHost in $clusterHosts)
{
	Write-Progress -Activity "Processing Cluster." -CurrentOperation $vmHost.Name -PercentComplete (($counter / $clusterHosts.count) * 100)
	$esxcli = Get-EsxCli -V2 -VMHost $vmHost
	$deviceListArgs = $esxcli.storage.core.device.list.CreateArgs()
	$deviceListArgs.device = $selection
	$esxcli.storage.core.device.list.Invoke($deviceListArgs) | Select-Object Device, IsPerenniallyReserved
	$deviceSetArgs = $esxcli.storage.core.device.setconfig.CreateArgs()
	$deviceSetArgs.device = $selection
	$deviceSetArgs.perenniallyreserved = $true
	$esxcli.storage.core.device.setconfig.Invoke($deviceSetArgs)
	$counter++
}

Disconnect-VIServer -WarningAction SilentlyContinue -Server $vCenter -Force -Confirm:$false

