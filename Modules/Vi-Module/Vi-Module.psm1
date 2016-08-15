Function Get-RDM {

<#
.SYNOPSIS
	Get all RDMs.
.DESCRIPTION
	This function reports all VMs with their RDM disks.
.PARAMETER VM
	VM's collection, returned by Get-VM cmdlet.
.EXAMPLE
	C:\PS> Get-VM -Server VC1 |Get-RDM
.EXAMPLE
	C:\PS> Get-VM |? {$_.Name -like 'linux*'} |Get-RDM |sort VM,Datastore,HDLabel |ft -au
.EXAMPLE
	C:\PS> Get-Datacenter 'North' |Get-VM |Get-RDM |? {$_.HDSizeGB -gt 1} |Export-Csv -NoTypeInformation 'C:\reports\North_RDMs.csv'
.EXAMPLE
	C:\PS> $res = Get-Cluster prod |Get-VM |Get-ViMRDM
	C:\PS> $res |Export-Csv -NoTypeInformation 'C:\reports\ProdCluster_RDMs.csv'
	Save the results in variable and than export them to a file.
.INPUTS
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] Get-VM collection.
.OUTPUTS
	[System.Management.Automation.PSCustomObject] PSObject collection.
.NOTES
	Author: Roman Gelman.
	Version 1.0 :: 16-Oct-2015 :: Release
	Version 1.1 :: 03-Dec-2015 :: Bugfix :: Error message appear while VML mismatch,
	when the VML identifier does not match for an RDM on two or more ESXi hosts.
	VMware [KB2097287].
	Version 1.2 :: 03-Aug-2016 :: Improvement :: GetType() method replaced by -is for type determine.
.LINK
	http://www.ps1code.com/single-post/2015/10/16/How-to-get-RDM-Raw-Device-Mappings-disks-using-PowerCLi
#>

[CmdletBinding()]

Param (

	[Parameter(Mandatory=$false,Position=1,ValueFromPipeline=$true,HelpMessage="VM's collection, returned by Get-VM cmdlet")]
		[ValidateNotNullorEmpty()]
		[Alias("VM")]
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]]$VMs = (Get-VM)

)

Begin {

	$Object    = @()
	$regxVMDK  = '^\[(?<Datastore>.+)\]\s(?<Filename>.+)$'
	$regxLUNID = ':L(?<LUNID>\d+)$'
}

Process {
	
	Foreach ($vm in ($VMs |Get-View)) {
		Foreach ($dev in $vm.Config.Hardware.Device) {
		    If ($dev -is [VMware.Vim.VirtualDisk]) {
				If ("physicalMode","virtualMode" -contains $dev.Backing.CompatibilityMode) {
		         	
					Write-Progress -Activity "Gathering RDM ..." -CurrentOperation "Hard disk - [$($dev.DeviceInfo.Label)]" -Status "VM - $($vm.Name)"
					
					$esx        = Get-View $vm.Runtime.Host
					$esxScsiLun = $esx.Config.StorageDevice.ScsiLun |? {$_.Uuid -eq $dev.Backing.LunUuid}
					
					### Expand 'LUNID' from device runtime name (vmhba2:C0:T0:L12) ###
					$lunCN = $esxScsiLun.CanonicalName
					$Matches = $null
					If ($lunCN) {
						$null  = (Get-ScsiLun -VmHost $esx.Name -CanonicalName $lunCN -ErrorAction SilentlyContinue).RuntimeName -match $regxLUNID
						$lunID = $Matches.LUNID
					} Else {$lunID = ''}
					
					### Expand 'Datastore' and 'VMDK' from file path ###
					$null = $dev.Backing.FileName -match $regxVMDK
					
					$Properties = [ordered]@{
						VM            = $vm.Name
						VMHost        = $esx.Name
						Datastore     = $Matches.Datastore
						VMDK          = $Matches.Filename
						HDLabel       = $dev.DeviceInfo.Label
						HDSizeGB      = [math]::Round(($dev.CapacityInKB / 1MB), 3)
						HDMode        = $dev.Backing.CompatibilityMode
						DeviceName    = $dev.Backing.DeviceName
						Vendor        = $esxScsiLun.Vendor
						CanonicalName = $lunCN
						LUNID         = $lunID
					}
					$Object = New-Object PSObject -Property $Properties
					$Object
				}
			}
		}
	}
}

End {
	Write-Progress -Completed $true -Status "Please wait"
}

} #EndFunction Get-RDM
New-Alias -Name Get-ViMRDM -Value Get-RDM -Force:$true

Function Convert-VmdkThin2EZThick {

<#
.SYNOPSIS
	Inflate thin virtual disks.
.DESCRIPTION
	This function converts all Thin Provisioned VM' disks to type 'Thick Provision Eager Zeroed'.
.PARAMETER VM
	Virtual Machine(s).
.EXAMPLE
	C:\PS> Get-VM VM1 |Convert-VmdkThin2EZThick
.EXAMPLE
	C:\PS> Get-VM VM1,VM2 |Convert-VmdkThin2EZThick -Confirm:$false |sort VM,Datastore,VMDK |ft -au
.INPUTS
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] Objects, returned by Get-VM cmdlet.
.OUTPUTS
	[System.Management.Automation.PSCustomObject] PSObject collection.
.NOTES
	Author: Roman Gelman.
	Version 1.0 :: 05-Nov-2015 :: Release.
	Version 1.1 :: 03-Aug-2016 :: Improvements ::
	[1] GetType() method replaced by -is for type determine.
	[2] Parameter 'VMs' renamed to 'VM', parameter alias renamed from 'VM' to 'VMs'.
.LINK
	http://www.ps1code.com/single-post/2015/11/05/How-to-convert-Thin-Provision-VMDK-disks-to-Eager-Zeroed-Thick-using-PowerCLi
#>

[CmdletBinding(ConfirmImpact='High',SupportsShouldProcess=$true)]

Param (

	[Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true,HelpMessage="VM's collection, returned by Get-VM cmdlet")]
		[ValidateNotNullorEmpty()]
		[Alias("VMs")]
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]]$VM

)

Begin {

	$Object   = @()
	$regxVMDK = '^\[(?<Datastore>.+)\]\s(?<Filename>.+)$'

}

Process {
	
	Foreach ($vmv in ($VM |Get-View)) {
	
		### Ask confirmation to proceed if VM is PoweredOff ###
		If ($vmv.Runtime.PowerState -eq 'poweredOff' -and $PSCmdlet.ShouldProcess("VM [$($vmv.Name)]","Convert all Thin Provisioned VMDK to Type: 'Thick Provision Eager Zeroed'")) {
		
			### Get ESXi object where $vmv is registered ###
			$esx = Get-View $vmv.Runtime.Host
			
			### Get Datacenter object where $vmv is registered ###
			$parentObj = Get-View $vmv.Parent
		    While ($parentObj -isnot [VMware.Vim.Datacenter]) {$parentObj = Get-View $parentObj.Parent}
		    $datacenter       = New-Object VMware.Vim.ManagedObjectReference
			$datacenter.Type  = 'Datacenter'
			$datacenter.Value = $parentObj.MoRef.Value
		   
			Foreach ($dev in $vmv.Config.Hardware.Device) {
			    If ($dev -is [VMware.Vim.VirtualDisk]) {
					If ($dev.Backing.ThinProvisioned -and $dev.Backing.Parent -eq $null) {
					
			        	$sizeGB = [math]::Round(($dev.CapacityInKB / 1MB), 1)
						
						### Invoke 'Inflate virtual disk' task ###
						$ViDM      = Get-View -Id 'VirtualDiskManager-virtualDiskManager'
						$taskMoRef = $ViDM.InflateVirtualDisk_Task($dev.Backing.FileName, $datacenter)
						$task      = Get-View $taskMoRef
						
						### Show task progress ###
						For ($i=1; $i -lt [int32]::MaxValue; $i++) {
							If ("running","queued" -contains $task.Info.State) {
								$task.UpdateViewData("Info")
								If ($task.Info.Progress -ne $null) {
									Write-Progress -Activity "Inflate virtual disk task is in progress ..." -Status "VM - $($vmv.Name)" `
									-CurrentOperation "$($dev.DeviceInfo.Label) - $($dev.Backing.FileName) - $sizeGB GB" `
									-PercentComplete $task.Info.Progress -ErrorAction SilentlyContinue
									Start-Sleep -Seconds 3
								}
							}
 							Else {Break}
						}
						
						### Get task completion results ###
						$tResult       = $task.Info.State
						$tStart        = $task.Info.StartTime
						$tEnd          = $task.Info.CompleteTime
						$tCompleteTime = [math]::Round((New-TimeSpan -Start $tStart -End $tEnd).TotalMinutes, 1)
						
						### Expand 'Datastore' and 'VMDK' from file path ###
						$null = $dev.Backing.FileName -match $regxVMDK
						
						$Properties = [ordered]@{
							VM           = $vmv.Name
							VMHost       = $esx.Name
							Datastore    = $Matches.Datastore
							VMDK         = $Matches.Filename
							HDLabel      = $dev.DeviceInfo.Label
							HDSizeGB     = $sizeGB
							Result       = $tResult
							StartTime    = $tStart
							CompleteTime = $tEnd
							TimeMin      = $tCompleteTime
						}
						$Object = New-Object PSObject -Property $Properties
						$Object
					}
				}
			}
			$vmv.Reload()
		}
	}
}

End {
	Write-Progress -Completed $true -Status "Please wait"
}

} #EndFunction Convert-VmdkThin2EZThick
New-Alias -Name Convert-ViMVmdkThin2EZThick -Value Convert-VmdkThin2EZThick -Force:$true

Function Find-VcVm {

<#
.SYNOPSIS
	Search VC's VM throw direct connection to group of ESXi Hosts.
.DESCRIPTION
	This script generates a list of ESXi Hosts with common suffix in a name,
	e.g. (esxprod1,esxprod2, ...) or (esxdev01,esxdev02, ...) etc. and
	searches VCenter's VM throw direct connection to this group of ESXi Hosts.
.PARAMETER VC
	VC's VM Name.
.PARAMETER HostSuffix
	ESXi Hosts' common suffix.
.PARAMETER PostfixStart
	ESXi Hosts' postfix number start.
.PARAMETER PostfixEnd
	ESXi Hosts' postfix number end.
.PARAMETER AddZero
	Add ESXi Hosts' postfix leading zero to one-digit postfix (from 01 to 09).
.EXAMPLE
	PS C:\> Find-VcVm vc1 esxprod 1 20 -AddZero
.EXAMPLE
	PS C:\> Find-VcVm -VC vc1 -HostSuffix esxdev -PostfixEnd 6
.EXAMPLE
	PS C:\> Find-VcVm vc1 esxprod |fl
.NOTES
	Author      :: Roman Gelman.
	Limitation  :: [1] The function uses common credentials for all ESXi hosts.
	               [2] The hosts' Lockdown mode should be disabled.
	Version 1.0 :: 03-Sep-2015 :: Release.
	Version 1.1 :: 03-Aug-2016 :: Improvement :: Returned object properties changed.
.OUTPUTS
	[System.Management.Automation.PSCustomObject] PSObject collection.
.LINK
	http://ps1code.com
#>

Param (

	[Parameter(Mandatory=$true,Position=1,HelpMessage="vCenter's VM Name")]
		[Alias("vCenter","VcVm")]
	[string]$VC
	,
	[Parameter(Mandatory=$true,Position=2,HelpMessage="ESXi Hosts' common suffix")]
		[Alias("VMHostSuffix","ESXiSuffix")]
	[string]$HostSuffix
	,
	[Parameter(Mandatory=$false,Position=3,HelpMessage="ESXi Hosts' postfix number start")]
		[ValidateRange(1,98)]
		[Alias("PostfixFirst","Start")]
	[int]$PostfixStart = 1
	,
	[Parameter(Mandatory=$false,Position=4,HelpMessage="ESXi Hosts' postfix number end")]
		[ValidateRange(2,99)]
		[Alias("PostfixLast","End")]
	[int]$PostfixEnd = 9
	,
	[Parameter(Mandatory=$false,Position=5,HelpMessage="Add ESXi Hosts' postfix leading zero")]
	[switch]$AddZero = $false
)

Begin {

	Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -Confirm:$false |Out-Null
	If ($PostfixEnd -le $PostfixStart) {Throw "PostfixEnd must be greater than PostfixStart"}
}

Process {

	$cred = Get-Credential -UserName root -Message "Common VMHost Credentials"
	If ($cred) {
		$hosts = @()
		
		For ($i=$PostfixStart; $i -le $PostfixEnd; $i++) {
			If ($AddZero -and $i -match '^\d{1}$') {
				$hosts += $HostSuffix + '0' + $i
			} Else {
				$hosts += $HostSuffix + $i
			}
		}
		
		Connect-VIServer $hosts -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -Credential $cred `
		|select @{N='VMHost';E={$_.Name}},IsConnected |ft -AutoSize
		
		If ($global:DefaultVIServers.Length -ne 0) {
			$TargetVM = Get-VM -ErrorAction SilentlyContinue |? {$_.Name -eq $VC}
			$VCHostname     = $TargetVM.Guest.HostName
			$PowerState     = $TargetVM.PowerState
			$VMHostHostname = $TargetVM.VMHost.Name
			Disconnect-VIServer -Server '*' -Force -Confirm:$false
		}
	}
}

End {

	If ($TargetVM)	{
		$Properties = [ordered]@{
			VC         = $VC
			Hostname   = $VCHostname
			PowerState = $PowerState
			VMHost     = $VMHostHostname
		}
		$Object = New-Object PSObject -Property $Properties
		$Object
	}
}

} #EndFunction Find-VcVm
New-Alias -Name Find-ViMVcVm -Value Find-VcVm -Force:$true

Function Set-PowerCLiTitle {

<#
.SYNOPSIS
	Write connected VI servers info to PowerCLi window title bar.
.DESCRIPTION
	This function write connected VI servers info to PowerCLi window/console title bar [Name :: Product (VCenter/ESXi) ProductVersion].
.EXAMPLE
	C:\PS> Set-PowerCLiTitle
.NOTES
	Author: Roman Gelman.
.LINK
	http://www.ps1code.com/single-post/2015/11/17/ConnectVIServer-deep-dive-or-%C2%ABWhere-am-I-connected-%C2%BB
#>

$VIS = $global:DefaultVIServers |sort -Descending ProductLine,Name

If ($VIS) {
	Foreach ($VIObj in $VIS) {
		If ($VIObj.IsConnected) {
			Switch -exact ($VIObj.ProductLine) {
				vpx			{$VIProduct = 'VCenter'; Break}
				embeddedEsx {$VIProduct = 'ESXi'; Break}
				Default		{$VIProduct = $VIObj.ProductLine; Break}
			}
			$Header += "[$($VIObj.Name) :: $VIProduct$($VIObj.Version)] "
		}
	}
} Else {
	$Header = ':: Not connected to Virtual Infra Services ::'
}

$Host.UI.RawUI.WindowTitle = $Header

} #EndFunction Set-PowerCLiTitle
New-Alias -Name Set-ViMPowerCLiTitle -Value Set-PowerCLiTitle -Force:$true

Filter Get-VMHostFirmwareVersion {

<#
.SYNOPSIS
	Get ESXi host BIOS version.
.DESCRIPTION
	This filter returns ESXi host BIOS/UEFI Version and Release Date as a single string.
.EXAMPLE
	PS C:\> Get-VMHost 'esxprd1.*' |Get-VMHostFirmwareVersion
	Get single ESXi host's Firmware version.
.EXAMPLE
	PS C:\> Get-Cluster PROD |Get-VMHost |select Name,@{N='BIOS';E={$_ |Get-VMHostFirmwareVersion}}
	Get ESXi Name and Firmware version for single cluster.
.EXAMPLE
	PS C:\> Get-VMHost |sort Name |select Name,Version,Manufacturer,Model,@{N='BIOS';E={$_ |Get-VMHostFirmwareVersion}} |ft -au
	Add calculated property, that will contain Firmware version for all registered ESXi hosts.
.EXAMPLE
	PS C:\> Get-View -ViewType 'HostSystem' |select Name,@{N='BIOS';E={$_ |Get-VMHostFirmwareVersion}}
.EXAMPLE
	PS C:\> 'esxprd1.domain.com','esxdev2' |Get-VMHostFirmwareVersion
.INPUTS
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost[]] Objects, returned by Get-VMHost cmdlet.
	[VMware.Vim.HostSystem[]] Objects, returned by Get-View cmdlet.
	[System.String[]] ESXi hostname or FQDN.
.OUTPUTS
	[System.String[]] BIOS/UEFI version and release date.
.NOTES
	Author: Roman Gelman.
	Version 1.0 :: 09-Jan-2016 :: Release.
	Version 1.1 :: 03-Aug-2016 :: Improvement :: GetType() method replaced by -is for type determine.
.LINK
	http://www.ps1code.com/single-post/2016/1/9/How-to-know-ESXi-servers%E2%80%99-BIOSFirmware-version-using-PowerCLi
#>

Try
	{
		If     ($_ -is [VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost]) {$BiosInfo = ($_ |Get-View).Hardware.BiosInfo}
		ElseIf ($_ -is [VMware.Vim.HostSystem])                                 {$BiosInfo = $_.Hardware.BiosInfo}
		ElseIf ($_ -is [string])                                                {$BiosInfo = (Get-View -ViewType HostSystem -Filter @{"Name" = $_}).Hardware.BiosInfo}
		Else   {Throw "Not supported data type as pipeline"}

		$fVersion = $BiosInfo.BiosVersion -replace ('^-\[|\]-$', $null)
		$fDate    = [Regex]::Match($BiosInfo.ReleaseDate, '(\d{1,2}/){2}\d+').Value
		If ($fVersion) {return "$fVersion [$fDate]"} Else {return $null}
	}
Catch
	{}
} #EndFilter Get-VMHostFirmwareVersion
New-Alias -Name Get-ViMVMHostFirmwareVersion -Value Get-VMHostFirmwareVersion -Force:$true

Function Compare-VMHostSoftwareVib {

<#
.SYNOPSIS
	Compares the installed VIB packages between VMware ESXi Hosts.
.DESCRIPTION
	This function compares the installed VIB packages between reference ESXi Host and
	group of difference/target ESXi Hosts or single ESXi Host.
.PARAMETER ReferenceVMHost
	Reference VMHost.
.PARAMETER DifferenceVMHosts
	Target VMHosts to compare them with the reference VMHost.
.EXAMPLE
	PS C:\> Compare-VMHostSoftwareVib -ReferenceVMHost (Get-VMHost 'esxprd1.*') -DifferenceVMHosts  (Get-VMHost 'esxprd2.*')
	Compare two ESXi hosts.
.EXAMPLE
	PS C:\> Get-VMHost 'esxdev2.*','esxdev3.*' |Compare-VMHostSoftwareVib -ReferenceVMHost (Get-VMHost 'esxdev1.*')
	Compare two target ESXi Hosts with the reference Host.
.EXAMPLE
	PS C:\> Get-Cluster DEV |Get-VMHost |Compare-VMHostSoftwareVib -ReferenceVMHost (Get-VMHost 'esxdev1.*')
	Compare all HA/DRS cluster members with the reference ESXi Host.
.EXAMPLE
	PS C:\> Get-Cluster PRD |Get-VMHost |Compare-VMHostSoftwareVib -ReferenceVMHost (Get-VMHost 'esxhai1.*') |Export-Csv -NoTypeInformation -Path '.\VibCompare.csv'
	Export the comparison report to the file.
.INPUTS
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost[]] Objects, returned by Get-VMHost cmdlet.
.OUTPUTS
	[System.Management.Automation.PSCustomObject] PSObject collection.
.NOTES
	Author       ::	Roman Gelman.
	Dependencies ::	ESXCLI V2 works on vCenter 5.0/ESXi 5.0 and later.
	Version 1.0  ::	10-Jan-2016  :: Release.
	Version 1.1  ::	01-May-2016  :: Improvement :: Added support for PowerCLi 6.3R1 and ESXCLI V2 interface.
	Version 1.2  :: 15-Aug-2016  :: Bugfix      :: In the 'Foreach ($esx in $DifferenceVMHosts)' loop the '$DifferenceVMHosts' var replaced with '$DifferenceVMHost'.
.LINK
	http://www.ps1code.com/single-post/2016/1/10/How-to-compare-installed-VIB-packages-between-two-or-more-ESXi-hosts
#>

Param (

	[Parameter(Mandatory,Position=1,HelpMessage="Reference VMHost")]
		[Alias("ReferenceESXi")]
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost]$ReferenceVMHost
	,
	[Parameter(Mandatory,Position=2,ValueFromPipeline,HelpMessage="Difference VMHosts collection")]
		[Alias("DifferenceESXi","DifferenceVMHosts")]
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost[]]$DifferenceVMHost
)

Begin {
	$PcliVer = Get-PowerCLIVersion -ErrorAction SilentlyContinue
	$PcliMM  = ($PcliVer.Major.ToString() + $PcliVer.Minor.ToString()) -as [int]
}

Process {

	 Try 
		{
			If ($PcliMM -ge 63) {
				$esxcliRef = Get-EsxCli -V2 -VMHost $ReferenceVMHost -ErrorAction Stop
				$refVibId  = ($esxcliRef.software.vib.list.Invoke()).ID
			}
			Else {
				$esxcliRef = Get-EsxCli -VMHost $ReferenceVMHost -ErrorAction Stop
				$refVibId  = ($esxcliRef.software.vib.list()).ID
			}
		}
	Catch
		{
			"{0}" -f $Error.Exception.Message
		}

	Foreach ($esx in $DifferenceVMHost) {
	
		 Try
			{
				If ($PcliMM -ge 63) {
					$esxcliDif = Get-EsxCli -V2 -VMHost $esx -ErrorAction Stop
					$difVibId = ($esxcliDif.software.vib.list.Invoke()).ID
				}
				Else {
					$esxcliDif = Get-EsxCli -VMHost $esx -ErrorAction Stop
					$difVibId = ($esxcliDif.software.vib.list()).ID
				}
				$diffObj = Compare-Object -ReferenceObject $refVibId -DifferenceObject $difVibId -IncludeEqual:$false
				Foreach ($diff in $diffObj) {
					If ($diff.SideIndicator -eq '=>') {$diffOwner = $esx} Else {$diffOwner = $ReferenceVMHost}
					$Properties = [ordered]@{
						VIB    = $diff.InputObject
						VMHost = $diffOwner 
					}
					$Object = New-Object PSObject -Property $Properties
					$Object
				}
			}
		Catch
			{
				"{0}" -f $Error.Exception.Message
			}
	}
}

} #EndFunction Compare-VMHostSoftwareVib
New-Alias -Name Compare-ViMVMHostSoftwareVib -Value Compare-VMHostSoftwareVib -Force:$true

Filter Get-VMHostBirthday {

<#
.SYNOPSIS
	Get ESXi host installation date (Birthday).
.DESCRIPTION
	This filter returns ESXi host installation date.
.EXAMPLE
	PS C:\> Get-VMHost 'esxprd1.*' |Get-VMHostBirthday
	Get single ESXi host's Birthday.
.EXAMPLE
	PS C:\> Get-Cluster DEV |Get-VMHost |select Name,Version,@{N='Birthday';E={$_ |Get-VMHostBirthday}} |sort Name
	Get ESXi Name and Birthday for single cluster.
.EXAMPLE
	PS C:\> 'esxprd1.domain.com','esxprd2' |select @{N='ESXi';E={$_}},@{N='Birthday';E={$_ |Get-VMHostBirthday}}
	Pipe hostnames (strings) to the function.
.EXAMPLE
	PS C:\> Get-VMHost |select Name,@{N='Birthday';E={($_ |Get-VMHostBirthday).ToString('yyyy-MM-dd HH:mm:ss')}} |sort Name |ft -au
	Format output using ToString() method.
	http://blogs.technet.com/b/heyscriptingguy/archive/2015/01/22/formatting-date-strings-with-powershell.aspx
.INPUTS
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost[]] Objects, returned by Get-VMHost cmdlet.
	[System.String[]] ESXi hostname or FQDN.
.OUTPUTS
	[System.DateTime[]] ESXi installation date/time.
.NOTES
	Original idea: Magnus Andersson
	Author:        Roman Gelman
	Requirements:  vSphere 5.x or above
.LINK
	http://vcdx56.com/2016/01/05/find-esxi-installation-date/
#>

Try
	{
		$EsxCli = Get-EsxCli -VMHost $_ -ErrorAction Stop
		$Uuid   = $EsxCli.system.uuid.get()
		$bdHexa = [Regex]::Match($Uuid, '^(\w{8,})-').Groups[1].Value
		$bdDeci = [Convert]::ToInt64($bdHexa, 16)
		$bdDate = [TimeZone]::CurrentTimeZone.ToLocalTime(([DateTime]'1/1/1970').AddSeconds($bdDeci))
		If ($bdDate) {return $bdDate} Else {return $null}
	}
Catch
	{ }
} #EndFilter Get-VMHostBirthday
New-Alias -Name Get-ViMVMHostBirthday -Value Get-VMHostBirthday -Force:$true

Function Enable-VMHostSSH {

<#
.SYNOPSIS
	Enable SSH on all ESXi hosts in a cluster.
.DESCRIPTION
	This function enables SSH on all ESXi hosts in a cluster.
	It starts the SSH daemon and opens incoming TCP connections on port 22.
.EXAMPLE
	PS C:\> Get-Cluster PROD |Enable-VMHostSSH
.EXAMPLE
	PS C:\> Get-Cluster DEV,TEST |Enable-VMHostSSH |sort Cluster,VMHost |Format-Table -AutoSize
.INPUTS
	[VMware.VimAutomation.ViCore.Impl.V1.Inventory.ClusterImpl[]] Clusters collection, returtned by Get-Cluster cmdlet.
.OUTPUTS
	[System.Management.Automation.PSCustomObject] PSObject collection.
.NOTES
	Author      ::	Roman Gelman.
	Version 1.0 :: 07-Feb-2016 :: Release.
	Version 1.1 :: 02-Aug-2016 :: -Cluster parameter data type changed to the portable type.
.LINK
	http://www.ps1code.com/single-post/2016/02/07/How-to-enabledisable-SSH-on-all-ESXi-hosts-in-a-cluster-using-PowerCLi
#>

Param (

	[Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)]
		[ValidateNotNullorEmpty()]
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster[]]$Cluster = (Get-Cluster)
)

Process {

	Foreach ($container in $Cluster) {
		Foreach ($esx in Get-VMHost -Location $container) {
			
			If ('Connected','Maintenance' -contains $esx.ConnectionState -and $esx.PowerState -eq 'PoweredOn') {
			
				$sshSvc = Get-VMHostService -VMHost $esx |? {$_.Key -eq 'TSM-SSH'} |Start-VMHostService -Confirm:$false -ErrorAction Stop
				If ($sshSvc.Running) {$sshStatus = 'Running'} Else {$sshStatus = 'NotRunning'}
				$fwRule = Get-VMHostFirewallException -VMHost $esx -Name 'SSH Server' |Set-VMHostFirewallException -Enabled $true -ErrorAction Stop
				
				$Properties = [ordered]@{
					Cluster    = $container.Name
					VMHost     = $esx.Name
					State      = $esx.ConnectionState
					PowerState = $esx.PowerState
					SSHDaemon  = $sshStatus
					SSHEnabled = $fwRule.Enabled
				}
			}
			Else {
			
				$Properties = [ordered]@{
					Cluster    = $container.Name
					VMHost     = $esx.Name
					State      = $esx.ConnectionState
					PowerState = $esx.PowerState
					SSHDaemon  = 'Unknown'
					SSHEnabled = 'Unknown'
				}
			}
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
	}

}

} #EndFunction Enable-VMHostSSH
New-Alias -Name Enable-ViMVMHostSSH -Value Enable-VMHostSSH -Force:$true

Function Disable-VMHostSSH {

<#
.SYNOPSIS
	Disable SSH on all ESXi hosts in a cluster.
.DESCRIPTION
	This function disables SSH on all ESXi hosts in a cluster.
	It stops the SSH daemon and (optionally) blocks incoming TCP connections on port 22.
.PARAMETER BlockFirewall
	Try to disable "SSH Server" firewall exception rule.
	It might fail if this rule categorized as "Required Services" (VMware KB2037544).
.EXAMPLE
	PS C:\> Get-Cluster PROD |Disable-VMHostSSH -BlockFirewall
.EXAMPLE
	PS C:\> Get-Cluster DEV,TEST |Disable-VMHostSSH |sort Cluster,VMHost |Format-Table -AutoSize
.INPUTS
	[VMware.VimAutomation.ViCore.Impl.V1.Inventory.ClusterImpl[]] Clusters collection, returtned by Get-Cluster cmdlet.
.OUTPUTS
	[System.Management.Automation.PSCustomObject] PSObject collection.
.NOTES
	Author      ::	Roman Gelman.
	Version 1.0 :: 07-Feb-2016 :: Release.
	Version 1.1 :: 02-Aug-2016 :: -Cluster parameter data type changed to the portable type.
.LINK
	http://www.ps1code.com/single-post/2016/02/07/How-to-enabledisable-SSH-on-all-ESXi-hosts-in-a-cluster-using-PowerCLi
#>

Param (

	[Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)]
		[ValidateNotNullorEmpty()]
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster[]]$Cluster = (Get-Cluster)
	,
	[Parameter(Mandatory=$false,Position=1)]
	[Switch]$BlockFirewall
)

Process {

	Foreach ($container in $Cluster) {
		Foreach ($esx in Get-VMHost -Location $container) {
			
			If ('Connected','Maintenance' -contains $esx.ConnectionState -and $esx.PowerState -eq 'PoweredOn') {
			
				$sshSvc = Get-VMHostService -VMHost $esx |? {$_.Key -eq 'TSM-SSH'} |Stop-VMHostService -Confirm:$false -ErrorAction Stop
				If ($sshSvc.Running) {$sshStatus = 'Running'} Else {$sshStatus = 'NotRunning'}
				$fwRule = Get-VMHostFirewallException -VMHost $esx -Name 'SSH Server'
				If ($BlockFirewall) {
					Try   {$fwRule = Set-VMHostFirewallException -Exception $fwRule -Enabled:$false -Confirm:$false -ErrorAction Stop}
					Catch {}
				}
				
				$Properties = [ordered]@{
					Cluster    = $container.Name
					VMHost     = $esx.Name
					State      = $esx.ConnectionState
					PowerState = $esx.PowerState
					SSHDaemon  = $sshStatus
					SSHEnabled = $fwRule.Enabled
				}
			}
			Else {
			
				$Properties = [ordered]@{
					Cluster    = $container.Name
					VMHost     = $esx.Name
					State      = $esx.ConnectionState
					PowerState = $esx.PowerState
					SSHDaemon  = 'Unknown'
					SSHEnabled = 'Unknown'
				}
			}
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
	}

}

} #EndFunction Disable-VMHostSSH
New-Alias -Name Disable-ViMVMHostSSH -Value Disable-VMHostSSH -Force:$true

Function Set-VMHostNtpServer {

<#
.SYNOPSIS
	Set NTP server settings on a group of ESXi hosts.
.DESCRIPTION
	This cmdlet sets NTP server settings on a group of ESXi hosts
	and restarts the NTP daemon to apply these settings.
.PARAMETER VMHost
	ESXi hosts.
.PARAMETER NewNtp
	NTP servers (IP/Hostname).
.EXAMPLE
	PS C:\> Set-VMHostNtpServer -NewNtp 'ntp1','ntp2'
	Set two NTP servers to all hosts in inventory.
.EXAMPLE
	PS C:\> Get-VMHost 'esx1.*','esx2.*' |Set-VMHostNtpServer -NewNtp 'ntp1','ntp2'
.EXAMPLE
	PS C:\> Get-Cluster DEV,TEST |Get-VMHost |sort Parent,Name |Set-VMHostNtpServer -NewNtp 'ntp1','10.1.2.200' |ft -au
.EXAMPLE
	PS C:\> Get-VMHost -Location Datacenter1 |sort Name |Set-VMHostNtpServer -NewNtp 'ntp1','ntp2' |epcsv -notype -Path '.\Ntp_report.csv'
	Export the results to Excel.
.INPUTS
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost[]] VMHost collection returned by Get-VMHost cmdlet.
.OUTPUTS
	[System.Management.Automation.PSCustomObject] PSObject collection.
.NOTES
	Author      ::	Roman Gelman.
	Version 1.0 ::	10-Mar-2016  :: Release.
.LINK
	http://www.ps1code.com/single-post/2016/03/10/How-to-configure-NTP-servers-setting-on-ESXi-hosts-using-PowerCLi
#>

[CmdletBinding()]

Param (

	[Parameter(Mandatory=$false,Position=1,ValueFromPipeline=$true)]
		[ValidateNotNullorEmpty()]
	[VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost[]]$VMHost = (Get-VMHost)
	,
	[Parameter(Mandatory,Position=2)]
	[System.String[]]$NewNtp
)

Begin {
	$ErrorActionPreference = 'Stop'
}

Process {

	Foreach ($esx in $VMHost) {
	
		If ('Connected','Maintenance' -contains $esx.ConnectionState -and $esx.PowerState -eq 'PoweredOn') {

			### Get current Ntp ###
			$Ntps = Get-VMHostNtpServer -VMHost $esx
			
			### Remove previously configured Ntp ###
			$removed = $false
			Try
			{
				Remove-VMHostNtpServer -NtpServer $Ntps -VMHost $esx -Confirm:$false
				$removed = $true
			}
			Catch { }

			### Add new Ntp ###
			$added = $null
			Try
			{
				$added = Add-VMHostNtpServer -NtpServer $NewNtp -VMHost $esx -Confirm:$false
			}
			Catch { }
			
			### Restart NTP Daemon ###
			$restarted = $false
			Try
			{
				If ($added) {Get-VMHostService -VMHost $esx |? {$_.Key -eq 'ntpd'} |Restart-VMHostService -Confirm:$false |Out-Null}
				$restarted = $true
			}
			Catch {}
			
			### Return results ###
			$Properties = [ordered]@{
				VMHost            = $esx
				OldNtp            = $Ntps
				IsOldRemoved      = $removed
				NewNtp            = $added
				IsDaemonRestarted = $restarted
			}
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
		Else {Write-Warning "VMHost '$($esx.Name)' is in unsupported state"}
	}

}

} #EndFunction Set-VMHostNtpServer
New-Alias -Name Set-ViMVMHostNtpServer -Value Set-VMHostNtpServer -Force:$true

Function Get-Version {

<#
.SYNOPSIS
	Get VMware Virtual Infrastructure objects' version info.
.DESCRIPTION
	This cmdlet gets VMware Virtual Infrastructure objects' version info.
.PARAMETER VIObject
	Vitual Infrastructure objects (VM, VMHosts, DVSwitches, Datastores).
.PARAMETER VCenter
	Get versions for all connected VCenter servers/ESXi hosts and PowerCLi version on the localhost.
.PARAMETER LicenseKey
	Get versions of license keys.
.EXAMPLE
	PS C:\> Get-VMHost |Get-Version |? {$_.Version -ge 5.5 -and $_.Version.Revision -lt 2456374}
	Get all ESXi v5.5 hosts that have Revision less than 2456374.
.EXAMPLE
	PS C:\> Get-View -ViewType HostSystem |Get-Version |select ProductName,Version |sort Version |group Version |sort Count |select Count,@{N='Version';E={$_.Name}},@{N='VMHost';E={($_.Group |select -expand ProductName) -join ','}} |epcsv -notype 'C:\reports\ESXi_Version.csv'
	Group all ESXi hosts by Version and export the list to CSV.
.EXAMPLE
	PS C:\> Get-VM |Get-Version |? {$_.FullVersion -match 'v10' -and $_.Version -gt 9.1}
	Get all VM with Virtual Hardware v10 and VMTools version above v9.1.0.
.EXAMPLE
	PS C:\> Get-Version -VCenter |Format-Table -AutoSize
	Get all connected VCenter servers/ESXi hosts versions and PowerCLi version.
.EXAMPLE
	PS C:\> Get-VDSwitch |Get-Version |sort Version |? {$_.Version -lt 5.5}
	Get all DVSwitches that have version below 5.5.
.EXAMPLE
	PS C:\> Get-Datastore |Get-Version |? {$_.Version.Major -eq 3}
	Get all VMFS3 datastores.
.EXAMPLE
	PS C:\> Get-Version -LicenseKey
	Get license keys version info.
.INPUTS
	Output objects from the following cmdlets:
	Get-VMHost, Get-VM, Get-DistributedSwitch, Get-Datastore and Get-View -ViewType HostSystem.
.OUTPUTS
	[System.Management.Automation.PSCustomObject] PSObject collection.
.NOTES
	Author       ::	Roman Gelman.
	Version 1.0  ::	23-May-2016  :: Release.
	Version 1.1  ::	03-Aug-2016  :: Bugfix ::
	[1] VDSwitch data type changed from [VMware.Vim.VmwareDistributedVirtualSwitch] to [VMware.VimAutomation.Vds.Types.V1.VmwareVDSwitch].
	[2] Function Get-VersionVDSwitch edited to support data type change.
.LINK
	http://www.ps1code.com/single-post/2016/05/25/How-to-know-any-VMware-object%E2%80%99s-version-Use-GetVersion
#>

[CmdletBinding(DefaultParameterSetName='VIO')]

Param (

	[Parameter(Mandatory,Position=1,ValueFromPipeline=$true,ParameterSetName='VIO')]
	$VIObject
	,
	[Parameter(Mandatory,Position=1,ParameterSetName='VC')]
	[switch]$VCenter
	,
	[Parameter(Mandatory,Position=1,ParameterSetName='LIC')]
	[switch]$LicenseKey
)

Begin {

	$ErrorActionPreference = 'SilentlyContinue'
	
	Function Get-VersionVMHostImpl {
	Param ([Parameter(Mandatory,Position=1)]$InputObject)
	$ErrorActionPreference = 'Stop'
	Try
		{
			If ('Connected','Maintenance' -contains $InputObject.ConnectionState -and $InputObject.PowerState -eq 'PoweredOn') {
				$ProductInfo = $InputObject.ExtensionData.Config.Product
				$ProductVersion = [version]($ProductInfo.Version + '.' + $ProductInfo.Build)
				
				$Properties = [ordered]@{
					ProductName = $InputObject.Name
					ProductType = $ProductInfo.Name
					FullVersion = $ProductInfo.FullName
					Version     = $ProductVersion
				}
			}
			Else {
				$Properties = [ordered]@{
					ProductName = $InputObject.Name
					ProductType = 'VMware ESXi'
					FullVersion = 'Unknown'
					Version     = [version]'0.0.0.0'
				}
			}
		}
	Catch
		{
			$Properties = [ordered]@{
				ProductName = $InputObject.Name
				ProductType = 'VMware ESXi'
				FullVersion = 'Unknown'
				Version     = [version]'0.0.0.0'
			}
		}
	Finally
		{
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
		
	} #EndFunction Get-VersionVMHostImpl
	
	Function Get-VersionVMHostView {
	Param ([Parameter(Mandatory,Position=1)]$InputObject)
	$ErrorActionPreference = 'Stop'
	Try
		{
			$ProductRuntime = $InputObject.Runtime
			If ('connected','maintenance' -contains $ProductRuntime.ConnectionState -and $ProductRuntime.PowerState -eq 'poweredOn') {
				$ProductInfo = $InputObject.Config.Product
				$ProductVersion = [version]($ProductInfo.Version + '.' + $ProductInfo.Build)
				
				$Properties = [ordered]@{
					ProductName = $InputObject.Name
					ProductType = $ProductInfo.Name
					FullVersion = $ProductInfo.FullName
					Version     = $ProductVersion
				}
			}
			Else {
				$Properties = [ordered]@{
					ProductName = $InputObject.Name
					ProductType = 'VMware ESXi'
					FullVersion = 'Unknown'
					Version     = [version]'0.0.0.0'
				}
			}
		}
	Catch
		{
			$Properties = [ordered]@{
				ProductName = $InputObject.Name
				ProductType = 'VMware ESXi'
				FullVersion = 'Unknown'
				Version     = [version]'0.0.0.0'
			}
		}
	Finally
		{
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
		
	} #EndFunction Get-VersionVMHostView
	
	Function Get-VersionVM {
	Param ([Parameter(Mandatory,Position=1)]$InputObject)
	$ErrorActionPreference = 'Stop'
	Try
		{
			$ProductInfo = $InputObject.Guest
			
			If ($InputObject.ExtensionData.Guest.ToolsStatus -ne 'toolsNotInstalled' -and $ProductInfo) {	
				$ProductVersion = [version]$ProductInfo.ToolsVersion
				
				$Properties = [ordered]@{
					ProductName = $InputObject.Name
					ProductType = $InputObject.ExtensionData.Config.GuestFullName  #$ProductInfo.OSFullName
					FullVersion = "VMware VM " + $InputObject.Version
					Version     = $ProductVersion
				}
			}
			Else {
			
				$Properties = [ordered]@{
					ProductName = $InputObject.Name
					ProductType = $InputObject.ExtensionData.Config.GuestFullName
					FullVersion = "VMware VM " + $InputObject.Version
					Version     = [version]'0.0.0'
				}
			}
		}
	Catch
		{
			$Properties = [ordered]@{
				ProductName = $InputObject.Name
				ProductType = 'Unknown'
				FullVersion = 'VMware VM'
				Version     = [version]'0.0.0'
			}
		}
	Finally
		{
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
		
	} #EndFunction Get-VersionVM
	
	Function Get-VersionPowerCLi {
	$ErrorActionPreference = 'Stop'
		Try
			{
				$PCLi = Get-PowerCLIVersion
				$PCLiVer = [string]$PCLi.Major + '.' + [string]$PCLi.Minor + '.' + [string]$PCLi.Revision + '.' + [string]$PCLi.Build
				
				$Properties = [ordered]@{
					ProductName = $env:COMPUTERNAME
					ProductType = 'VMware vSphere PowerCLi'
					FullVersion = $PCLi.UserFriendlyVersion
					Version     = [version]$PCLiVer
				}
				$Object = New-Object PSObject -Property $Properties
				$Object
			}
		Catch {}	
	} #EndFunction Get-VersionPowerCLi
	
	Function Get-VersionVCenter {
	Param ([Parameter(Mandatory,Position=1)]$InputObject)
	$ErrorActionPreference = 'Stop'
	Try
		{
			If ($obj.IsConnected) {
				$ProductInfo = $InputObject.ExtensionData.Content.About
				$ProductVersion = [version]($ProductInfo.Version + '.' + $ProductInfo.Build)
				Switch -regex ($ProductInfo.OsType) {
					'^win'   {$ProductFullName = $ProductInfo.Name + ' Windows'   ;Break}
					'^linux' {$ProductFullName = $ProductInfo.Name + ' Appliance' ;Break}
					Default  {$ProductFullName = $ProductInfo.Name                ;Break}
				}
				
				$Properties = [ordered]@{
					ProductName = $InputObject.Name
					ProductType = $ProductFullName
					FullVersion = $ProductInfo.FullName
					Version     = $ProductVersion
				}
			}
			Else {
				$Properties = [ordered]@{
					ProductName = $InputObject.Name
					ProductType = 'VMware vCenter Server'
					FullVersion = 'Unknown'
					Version     = [version]'0.0.0.0'
				}
			}
		}
	Catch
		{
			$Properties = [ordered]@{
				ProductName = $InputObject.Name
				ProductType = 'VMware vCenter Server'
				FullVersion = 'Unknown'
				Version     = [version]'0.0.0.0'
			}
		}
	Finally
		{
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
		
	} #EndFunction Get-VersionVCenter
	
	Function Get-VersionVDSwitch {
	Param ([Parameter(Mandatory,Position=1)]$InputObject)
	$ErrorActionPreference = 'Stop'
	$ProductTypeName = 'VMware DVSwitch'
	Try
		{
			$ProductInfo = $InputObject.ExtensionData.Summary.ProductInfo
			$ProductFullVersion = 'VMware Distributed Virtual Switch ' + $ProductInfo.Version + ' build-' + $ProductInfo.Build
			$ProductVersion = [version]($ProductInfo.Version + '.' + $ProductInfo.Build)
			
			$Properties = [ordered]@{
				ProductName = $InputObject.Name
				ProductType = $ProductTypeName
				FullVersion = $ProductFullVersion
				Version     = $ProductVersion
			}
		}
	Catch
		{
			$Properties = [ordered]@{
				ProductName = $InputObject.Name
				ProductType = $ProductTypeName
				FullVersion = 'Unknown'
				Version     = [version]'0.0.0.0'
			}
		}
	Finally
		{
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
		
	} #EndFunction Get-VersionVDSwitch
	
	Function Get-VersionDatastore {
	Param ([Parameter(Mandatory,Position=1)]$InputObject)
	$ErrorActionPreference = 'Stop'
	$ProductTypeName = 'VMware VMFS Datastore'
	Try
		{
			$ProductVersionNumber = $InputObject.FileSystemVersion
			$ProductFullVersion = 'VMware Datastore VMFS v' + $ProductVersionNumber
			$ProductVersion = [version]$ProductVersionNumber
			
			$Properties = [ordered]@{
				ProductName = $InputObject.Name
				ProductType = $ProductTypeName
				FullVersion = $ProductFullVersion
				Version     = $ProductVersion
			}
		}
	Catch
		{
			$Properties = [ordered]@{
				ProductName = $InputObject.Name
				ProductType = $ProductTypeName
				FullVersion = 'Unknown'
				Version     = [version]'0.0'
			}
		}
	Finally
		{
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
		
	} #EndFunction Get-VersionDatastore
	
	Function Get-VersionLicenseKey {
	Param ([Parameter(Mandatory,Position=1)]$InputObject)
	$ErrorActionPreference = 'Stop'
	$ProductTypeName = 'License Key'
	Try
		{
			$InputObjectProp = $InputObject |select -ExpandProperty Properties
			Foreach ($prop in $InputObjectProp) {
				If ($prop.Key -eq 'ProductName')        {$ProductType    = $prop.Value + ' ' + $ProductTypeName}
				ElseIf ($prop.Key -eq 'ProductVersion') {$ProductVersion = [version]$prop.Value}
			}
			
			Switch -regex ($InputObject.CostUnit) {
				'^cpu'     {$LicCostUnit = 'CPU'; Break}
				'^vm'      {$LicCostUnit = 'VM'; Break}
				'server'   {$LicCostUnit = 'SRV'; Break}
				Default    {$LicCostUnit = $InputObject.CostUnit}
			
			}
			
			$ProductFullVersion = $InputObject.Name + ' [' + $InputObject.Used + '/' + $InputObject.Total + $LicCostUnit + ']'
			
			$Properties = [ordered]@{
				ProductName = $InputObject.LicenseKey
				ProductType = $ProductType
				FullVersion = $ProductFullVersion
				Version     = $ProductVersion
			}
		}
	Catch
		{
			$Properties = [ordered]@{
				ProductName = $InputObject.LicenseKey
				ProductType = $ProductTypeName
				FullVersion = 'Unknown'
				Version     = [version]'0.0'
			}
		}
	Finally
		{
			$Object = New-Object PSObject -Property $Properties
			If ($InputObject.EditionKey -ne 'eval') {$Object}
		}
		
	} #EndFunction Get-VersionLicenseKey
	
}

Process {

	If ($PSCmdlet.ParameterSetName -eq 'VIO') {
		Foreach ($obj in $VIObject) {
			If     ($obj -is [VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost])                  {Get-VersionVMHostImpl -InputObject $obj}
			ElseIf ($obj -is [VMware.Vim.HostSystem])                                                  {Get-VersionVMHostView -InputObject $obj}
			ElseIf ($obj -is [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine])          {Get-VersionVM -InputObject $obj}
			ElseIf ($obj -is [VMware.VimAutomation.Vds.Types.V1.VmwareVDSwitch])                       {Get-VersionVDSwitch -InputObject $obj}
			ElseIf ($obj -is [VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.VmfsDatastore]) {Get-VersionDatastore -InputObject $obj}
			Else   {Write-Warning "Not supported object type"}
		}
	}
	ElseIf ($PSCmdlet.ParameterSetName -eq 'VC') {
		If ($global:DefaultVIServers.Length) {Foreach ($obj in $global:DefaultVIServers) {Get-VersionVCenter -InputObject $obj}}
		Else {Write-Warning "Please use 'Connect-VIServer' cmdlet to connect to VCenter servers or ESXi hosts."}
		Get-VersionPowerCLi
	}
	ElseIf ($PSCmdlet.ParameterSetName -eq 'LIC') {
		If ($global:DefaultVIServers.Length) {Foreach ($obj in ((Get-View (Get-View ServiceInstance).Content.LicenseManager).Licenses)) {Get-VersionLicenseKey -InputObject $obj}}
		Else {Write-Warning "Please use 'Connect-VIServer' cmdlet to connect to VCenter servers or ESXi hosts."}
	}
}

End {}

} #EndFunction Get-Version
New-Alias -Name Get-ViMVersion -Value Get-Version -Force:$true

Export-ModuleMember -Alias '*' -Function '*'
