<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
Function Backup-VCSAToFile {
<#
	.NOTES
	===========================================================================
	 Created by:   	Brian Graf
	 Date:          October 30, 2016
	 Organization: 	VMware
	 Blog:          www.vtagion.com
	 Twitter:       @vBrianGraf
	 Modifed by:    Michael Dunsdon
	 Twitter:       @MJDunsdon
	 Date:          September 21, 2020
	===========================================================================

	.SYNOPSIS
		This function will allow you to create a full or partial backup of your
		VCSA appliance. (vSphere 6.5 and higher)
	.DESCRIPTION
		Use this function to backup your VCSA to a remote location
	.EXAMPLE
		[VMware.VimAutomation.Cis.Core.Types.V1.Secret]$BackupPassword = "VMw@re123"
		$Comment = "First API Backup"
		$LocationType = "FTP"
		$location = "10.144.99.5/vcsabackup-$((Get-Date).ToString('yyyy-MM-dd-hh-mm'))"
		$LocationUser = "admin"
		[VMware.VimAutomation.Cis.Core.Types.V1.Secret]$locationPassword = "VMw@re123"
		PS C:\> Backup-VCSAToFile -BackupPassword $BackupPassword  -LocationType $LocationType -Location $location -LocationUser $LocationUser -LocationPassword $locationPassword -Comment "This is a demo" -ShowProgress -FullBackup
	.NOTES
		Credit goes to @AlanRenouf for sharing the base of this function with me which I was able to take and make more robust as well as add in progress indicators
		You must be connected to the CisService for this to work, if you are not connected, the function will prompt you for your credentials
		A CisService can also be supplied as a parameter.
		If a -LocationType is not chosen, the function will default to FTP.
		The destination location for a backup must be an empty folder (easiest to use the get-date cmdlet in the location)
		-ShowProgress will give you a progressbar as well as updates in the console
		-CommonBackup will only backup the config whereas -Fullbackup grabs the historical data as well
#>
	param (
		[Parameter(ParameterSetName='FullBackup')]
		[switch]$FullBackup,
		[Parameter(ParameterSetName='CommonBackup')]
		[switch]$CommonBackup,
		[ValidateSet('FTPS', 'HTTP', 'SCP', 'HTTPS', 'FTP', 'SMB', 'SFTP')]
		$LocationType = "FTP",
		$Location,
		$LocationUser,
		[VMware.VimAutomation.Cis.Core.Types.V1.Secret]$LocationPassword,
		[VMware.VimAutomation.Cis.Core.Types.V1.Secret]$BackupPassword,
		$Comment = "Backup job",
		[Parameter(Mandatory=$false)]$CisServer = $global:DefaultCisServers,
		[switch]$ShowProgress
	)
	Begin {
		if ($CisServer.IsConnected) {
			Write-Verbose "Connected to $($CisServer.Name)"
			$connection = $CisServer
		} elseif ($CisServer.gettype().name -eq "String") {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($CisServer)."
			$Connection = Connect-CisServer $CisServer
		} elseif ($global:DefaultCisServers) {
			$connection = $global:DefaultCisServers
		} elseif ($global:DefaultVIServer) {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($global:DefaultVIServer.name)."
			$Connection = Connect-CisServer $global:DefaultVIServer
		}
		if (!$Connection) {
			Write-Error "It appears you have not created a connection to the CisServer. Please Connect First and try command again. (Connect-CisServer)"
		}
		if ($FullBackup) {$parts = @("common","seat")}
		if ($CommonBackup) {$parts = @("common")}

		# Per github issue 468 (https://github.com/vmware/PowerCLI-Example-Scripts/issues/468) adding some logic to account for SFTP/SCP handling in versions after VC 7.0.
		$vCenterVersionNumber = (Get-CisService -Name 'com.vmware.appliance.system.version').get().version
		if ( ($vCenterVersionNumber -ge 6.5 -AND $vCenterVersionNumber -lt 7.0 ) -AND $LocationType -eq 'SFTP' )  {
			write-warning 'VCSA Backup for versions 6.5 and 6.7 use SCP, not SFTP.  Adjusting the LocationType accordingly.'
			$LocationType = 'SCP'
		} 
		if ( $vCenterVersionNumber -ge 7.0 -AND $LocationType -eq 'SCP' ) {
			write-warning 'VCSA Backup starting with version 7.0 use SFTP and not SCP.  Adjusting the LocationType accordingly.'
			$LocationType = 'SFTP'
		}
	}
	Process{
		$BackupAPI = Get-CisService 'com.vmware.appliance.recovery.backup.job'
		$CreateSpec = $BackupAPI.Help.create.piece.CreateExample()
		$CreateSpec.parts = $parts
		$CreateSpec.backup_password = $BackupPassword
		$CreateSpec.location_type = $LocationType
		$CreateSpec.location = $Location
		$CreateSpec.location_user = $LocationUser
		$CreateSpec.location_password = $LocationPassword
		$CreateSpec.comment = $Comment
		try {
			$BackupJob = $BackupAPI.create($CreateSpec)
		} catch {
			throw $_.Exception.Message
		}
		If ($ShowProgress){
			do {
				$BackupAPI.get("$($BackupJob.ID)") | Select-Object id, progress, state
				$progress = ($BackupAPI.get("$($BackupJob.ID)").progress)
				Write-Progress -Activity "Backing up VCSA"  -Status $BackupAPI.get("$($BackupJob.ID)").state -PercentComplete ($BackupAPI.get("$($BackupJob.ID)").progress) -CurrentOperation "$progress% Complete"
				Start-Sleep -seconds 5
			} until ($BackupAPI.get("$($BackupJob.ID)").progress -eq 100 -or $BackupAPI.get("$($BackupJob.ID)").state -ne "INPROGRESS")
			Write-Progress -Activity "Backing up VCSA" -Completed
			$BackupAPI.get("$($BackupJob.ID)") | Select-Object id, progress, state
		} Else {
			$BackupJob | Select-Object id, progress, state
		}
	}
	End {}
}

Function Get-VCSABackupJobs {
<#
	.NOTES
	===========================================================================
	 Created by:    Brian Graf
	 Date:          October 30, 2016
	 Organization:  VMware
	 Blog:          www.vtagion.com
	 Twitter:       @vBrianGraf
	 Modifed by:    Michael Dunsdon
	 Twitter:       @MJDunsdon
	 Date:          September 21, 2020
	===========================================================================

	.SYNOPSIS
		Get-VCSABackupJobs returns a list of all backup jobs VCSA has ever performed (vSphere 6.5 and higher)
	.DESCRIPTION
		Get-VCSABackupJobs returns a list of all backup jobs VCSA has ever performed
	.EXAMPLE
		PS C:\> Get-VCSABackupJobs
	.EXAMPLE
		PS C:\> Get-VCSABackupJobs -ShowNewest -CisServer "vcserver.sphere.local"
	.NOTES
		The values returned are read as follows:
		YYYYMMDD-hhmmss-vcsabuildnumber
		You can pipe the results of this function into the Get-VCSABackupStatus function
		Get-VCSABackupJobs | select -First 1 | Get-VCSABackupStatus <- Most recent backup
#>
	param (
		[Parameter(Mandatory=$false)][switch]$ShowNewest,
		[Parameter(Mandatory=$false)]$CisServer = $global:DefaultCisServers
	)
	Begin {
		if ($CisServer.IsConnected) {
			Write-Verbose "Connected to $($CisServer.Name)"
			$connection = $CisServer
		} elseif ($CisServer.gettype().name -eq "String") {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($CisServer)."
			$Connection = Connect-CisServer $CisServer
		} elseif ($global:DefaultCisServers) {
			$connection = $global:DefaultCisServers
		} elseif ($global:DefaultVIServer) {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($global:DefaultVIServer.name)."
			$Connection = Connect-CisServer $global:DefaultVIServer
		}
		if (!$Connection) {
			Write-Error "It appears you have not created a connection to the CisServer. Please Connect First and try command again. (Connect-CisServer)"
		}
	}
	Process{
		$BackupAPI = Get-CisService 'com.vmware.appliance.recovery.backup.job'
		try {
			if ($ShowNewest) {
				$results = $BackupAPI.list()
				$results[0]
			} else {
				$BackupAPI.list()
			}
		} catch {
			Write-Error $Error[0].exception.Message
		}
	}
	End {}
}

Function Get-VCSABackupStatus {
<#
	.NOTES
	===========================================================================
	 Created by:    Brian Graf
	 Date:          October 30, 2016
	 Organization:  VMware
	 Blog:          www.vtagion.com
	 Twitter:       @vBrianGraf
	 Modifed by:    Michael Dunsdon
	 Twitter:       @MJDunsdon
	 Date:          September 21, 2020
	===========================================================================

	.SYNOPSIS
		Returns the ID, Progress, and State of a VCSA backup (vSphere 6.5 and higher)
	.DESCRIPTION
		Returns the ID, Progress, and State of a VCSA backup
 	.EXAMPLE
		PS C:\> $backups = Get-VCSABackupJobs
				$backups[0] | Get-VCSABackupStatus
	.NOTES
		The BackupID can be piped in from the Get-VCSABackupJobs function and can return multiple job statuses
#>
	Param (
		[parameter(Mandatory=$false,ValueFromPipeline=$True)][string[]]$BackupID,
		[Parameter(Mandatory=$false)]$CisServer = $global:DefaultCisServers
	)
	Begin {
		if ($CisServer.IsConnected) {
			Write-Verbose "Connected to $($CisServer.Name)"
			$connection = $CisServer
		} elseif ($CisServer.gettype().name -eq "String") {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($CisServer)."
			$Connection = Connect-CisServer $CisServer
		} elseif ($global:DefaultCisServers) {
			$connection = $global:DefaultCisServers
		} elseif ($global:DefaultVIServer) {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($global:DefaultVIServer.name)."
			$Connection = Connect-CisServer $global:DefaultVIServer
		}
		if (!$Connection) {
			Write-Error "It appears you have not created a connection to the CisServer. Please Connect First and try command again. (Connect-CisServer)"
		}
	}
	Process{
		$BackupAPI = Get-CisService 'com.vmware.appliance.recovery.backup.job'
		Foreach ($id in $BackupID) {
			$BackupAPI.get("$id") | Select-Object id, progress, state
		}
	}
	End {}
}

Function New-VCSASchedule {
<#
	.NOTES
	===========================================================================
	 Original Created by:  Brian Graf
	 Blog:                 www.vtagion.com
	 Twitter:              @vBrianGraf
	 Organization:         VMware
	 Created / Modifed by: Michael Dunsdon
	 Twitter:              @MJDunsdon
	 Date:                 September 21, 2020
	===========================================================================

	.SYNOPSIS
		This function will allow you to create a scheduled to backup your
		VCSA appliance. (vSphere 6.7 and higher)
	.DESCRIPTION
		Use this function to create a schedule to backup your VCSA to a remote location
	.EXAMPLE
		The Below Create a schedule on Monday @11:30pm to FTP location 10.1.1.10:/vcsabackup/vcenter01
		and keep 4 backups with a Encryption Passowrd of "VMw@re123"

		$location = "ftp://10.1.1.10/vcsabackup/vcenter01"
		$LocationUser = "admin"
		[VMware.VimAutomation.Cis.Core.Types.V1.Secret]$locationPassword = "VMw@re123"
		$BHour = 23
		$BMin = 30
		$BDays = @("Monday")
		$MaxCount = 4
		[VMware.VimAutomation.Cis.Core.Types.V1.Secret]$BackupPassword = "VMw@re123"

		PS C:\> New-VCSASchedule -Location $location -LocationUser $LocationUser -LocationPassword $locationPassword -BackupHour $BHour -BackupMinute $BMin -backupDays $BDays -MaxCount $MaxCount -BackupPassword $BackupPassword
	.EXAMPLE
		The Below Create a schedule on Sunday & Wednesday @5:15am
		to NFS location 10.1.1.10:/vcsabackup/vcenter01
		keep 10 backups with a Encryption Passowrd of "VMw@re123"
		with Event Data included (Seat) and will delete any existing schedule.

		$location = "nfs://10.1.1.10/vcsabackup/vcenter01"
		$LocationUser = "admin"
		[VMware.VimAutomation.Cis.Core.Types.V1.Secret]$locationPassword = "VMw@re123"
		$BHour = 5
		$BMin = 15
		$BDays = @("Sunday", "Monday")
		$MaxCount = 10
		[VMware.VimAutomation.Cis.Core.Types.V1.Secret]$BackupPassword = "VMw@re123"

		PS C:\> New-VCSASchedule -IncludeSeat -force -Location $location -LocationUser $LocationUser -LocationPassword $locationPassword -BackupHour $BHour -BackupMinute $BMin -backupDays $BDays -MaxCount $MaxCount -BackupPassword $BackupPassword -CisServer "vcserver.sphere.local"
	.NOTES
		Credit goes to @AlanRenouf & @vBrianGraf for sharing the base of this function.
		You must be connected to the CisService for this to work, if you are not connected, the function will prompt you for your credentials
#>
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
	param (
		[Parameter(Mandatory=$true)]$Location,
		[Parameter(Mandatory=$true)]$LocationUser,
		[Parameter(Mandatory=$true)][VMware.VimAutomation.Cis.Core.Types.V1.Secret]$LocationPassword,
		[Parameter(Mandatory=$false)][VMware.VimAutomation.Cis.Core.Types.V1.Secret]$BackupPassword,
		[Parameter(Mandatory=$true)][ValidateRange(0,23)]$BackupHour,
		[Parameter(Mandatory=$true)][ValidateRange(0,59)]$BackupMinute,
		[Parameter(Mandatory=$true)][ValidateSet('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY', IgnoreCase = $False)][Array]$BackupDays = $null,
		[Parameter(Mandatory=$true)][Int]$MaxCount,
		[Parameter(Mandatory=$false)]$BackupID = "default",
		[Parameter(Mandatory=$false)]$CisServer = $global:DefaultCisServers,
		[Parameter(Mandatory=$false)][switch]$IncludeSeat,
		[Parameter(Mandatory=$false)][switch]$Force
	)
	Begin {
		if ($CisServer.IsConnected) {
			Write-Verbose "Connected to $($CisServer.Name)"
			$connection = $CisServer
		} elseif ($CisServer.gettype().name -eq "String") {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($CisServer)."
			$Connection = Connect-CisServer $CisServer
		} elseif ($global:DefaultCisServers) {
			$connection = $global:DefaultCisServers
		} elseif ($global:DefaultVIServer) {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($global:DefaultVIServer.name)."
			$Connection = Connect-CisServer $global:DefaultVIServer
		}
		if (!$Connection) {
			Write-Error "It appears you have not created a connection to the CisServer. Please Connect First and try command again. (Connect-CisServer)"
		}
	}
	Process{
		if (!(Test-VCSAScheduleSupport)) {
			Write-Error "This VCSA does not support Backup Schedules."
			return
		}
		$BackupAPI = Get-CisService -name 'com.vmware.appliance.recovery.backup.schedules'
		$CreateSpec = $BackupAPI.Help.create.spec.Create()
		$CreateSpec.backup_password = $BackupPassword
		$CreateSpec.location = $Location
		$CreateSpec.location_user = $LocationUser
		$CreateSpec.location_password = $LocationPassword
		$CreateSpec.Enable = $true
		$CreateSpec.recurrence_info.Hour = $BackupHour
		$CreateSpec.recurrence_info.Minute = $BackupMinute
		$CreateSpec.recurrence_info.Days = $BackupDays
		$CreateSpec.retention_info.max_count = $MaxCount
		if ($IncludeSeat) {
			$CreateSpec.parts = @("seat","common")
		} else {
			$CreateSpec.parts = @("common")
		}
		$CurrentSchedule = $BackupAPI.list()


		if ($CurrentSchedule.keys.value) {
			if($Force -or $PSCmdlet.ShouldContinue($CurrentSchedule.keys.value,'Delete Old Schedule')){
				$BackupAPI.delete($CurrentSchedule.keys.value)
			} else {
				Write-Error "There is an exisiting Schedule. Please delete before Creating a new one."
				return
			}
		}
		if ($PSCmdlet.ShouldProcess($BackupID, 'Create New Schedule.')) {
			try {
				$BackupJob = $BackupAPI.create($BackupID, $CreateSpec)
			}
			catch {
				throw $_.Exception.Message
			}
		}
		if ($BackupJob) {
			Write-Host "Backup up Job Created."
			return $BackupJob
		}
	}
	End {}
}

Function Get-VCSASchedule {
<#
	.NOTES
	===========================================================================
	 Original Created by:  Brian Graf
	 Blog:                 www.vtagion.com
	 Twitter:              @vBrianGraf
	 Organization:         VMware
	 Created / Modifed by: Michael Dunsdon
	 Twitter:              @MJDunsdon
	 Date:                 September 21, 2020
	===========================================================================

	.SYNOPSIS
		This function will allow you to Get the scheduled backup of your
		VCSA appliance. (vSphere 6.7 and higher)
	.DESCRIPTION
		Use this function to Get the backup schedule for your VCSA appliance.
	.EXAMPLE
		PS C:\> Get-VCSASchedule
	.EXAMPLE
		PS C:\> Get-VCSASchedule -ScheduleID 1 -CisServer "vcserver.sphere.local"
	.NOTES
		Credit goes to @AlanRenouf & @vBrianGraf for sharing the base of this function.
		Returns a simplified object with the schedule details.
		You must be connected to the CisService for this to work, if you are not connected, the function will prompt you for your credentials
#>
	param (
		[Parameter(Mandatory=$False,HelpMessage="Will Filter List By ScheduleID")]$ScheduleID,
		[Parameter(Mandatory=$false)]$CisServer = $global:DefaultCisServers
	)
	Begin {
		if ($CisServer.IsConnected) {
			Write-Verbose "Connected to $($CisServer.Name)"
			$connection = $CisServer
		} elseif ($CisServer.gettype().name -eq "String") {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($CisServer)."
			$Connection = Connect-CisServer $CisServer
		} elseif ($global:DefaultCisServers) {
			$connection = $global:DefaultCisServers
		} elseif ($global:DefaultVIServer) {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($global:DefaultVIServer.name)."
			$Connection = Connect-CisServer $global:DefaultVIServer
		}
		if (!$Connection) {
			Write-Error "It appears you have not created a connection to the CisServer. Please Connect First and try command again. (Connect-CisServer)"
		}
	}
	Process{
		if (!(Test-VCSAScheduleSupport)) {
			Write-Error "This VCSA does not support Backup Schedules."
			return
		}
		$BackupAPI = Get-CisService -name 'com.vmware.appliance.recovery.backup.schedules'
		$Schedules = $BackupAPI.list()
		if ($Schedules.count -ge 1) {
			$ObjSchedule = @()
			foreach ($Schedule in $Schedules) {
				$ObjSchedule += $Schedule.values | Select-Object *,@{N = "ID"; e = {"$($schedule.keys.value)"}} -ExpandProperty recurrence_info -ExcludeProperty Help | Select-Object * -ExcludeProperty recurrence_info,Help | Select-Object * -ExpandProperty retention_info | Select-Object * -ExcludeProperty retention_info,Help
			}
			if ($ScheduleID) {
				$ObjSchedule = $ObjSchedule | Where-Object {$_.ID -eq $ScheduleID}
			}
			return $ObjSchedule
		} else {
			Write-Information "No Schedule Defined."
		}
	}
	End {}
}

Function Remove-VCSASchedule {
<#
	.NOTES
	===========================================================================
	 Original Created by:  Brian Graf
	 Blog:                 www.vtagion.com
	 Twitter:              @vBrianGraf
	 Organization:         VMware
	 Created / Modifed by: Michael Dunsdon
	 Twitter:              @MJDunsdon
	 Date:                 September 21, 2020
	============================================================================
 	.SYNOPSIS
		This function will remove any scheduled backups of your
		VCSA appliance. (vSphere 6.7 and higher)
	.DESCRIPTION
		Use this function to remove the backup schedule for your VCSA appliance.
	.EXAMPLE
		PS C:\> Remove-VCSASchedule
	.EXAMPLE
		PS C:\> Remove-VCSASchedule -ScheduleID 1 -CisServer "vcserver.sphere.local"
	.NOTES
		Credit goes to @AlanRenouf & @vBrianGraf for sharing the base of this function.
		You must be connected to the CisService for this to work, if you are not connected, the function will prompt you for your credentials
#>
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
	param (
		[Parameter(Mandatory=$false)]$ScheduleID = "default",
		[Parameter(Mandatory=$false)]$CisServer = $global:DefaultCisServers
	)
	Begin {
		if ($CisServer.IsConnected) {
			Write-Verbose "Connected to $($CisServer.Name)"
			$connection = $CisServer
		} elseif ($CisServer.gettype().name -eq "String") {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($CisServer)."
			$Connection = Connect-CisServer $CisServer
		} elseif ($global:DefaultCisServers) {
			$connection = $global:DefaultCisServers
		} elseif ($global:DefaultVIServer) {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($global:DefaultVIServer.name)."
			$Connection = Connect-CisServer $global:DefaultVIServer
		}
		if (!$Connection) {
			Write-Error "It appears you have not created a connection to the CisServer. Please Connect First and try command again. (Connect-CisServer)"
		}
	}
	Process{
		if (!(Test-VCSAScheduleSupport)) {
			Write-Error "This VCSA does not support Backup Schedules."
			return
		}
		if ($PSCmdlet.ShouldProcess($ScheduleID, "Removes Current Backup Schedule")) {
			$BackupAPI = Get-CisService -name 'com.vmware.appliance.recovery.backup.schedules'
			$BackupAPI.delete($ScheduleID)
		}
	}
	End {}
}

Function Test-VCSAScheduleSupport {
<#
	.NOTES
	===========================================================================
	 Original Created by:  Brian Graf
	 Blog:                 www.vtagion.com
	 Twitter:              @vBrianGraf
	 Organization:         VMware
	 Created / Modifed by: Michael Dunsdon
	 Twitter:              @MJDunsdon
	 Date:                 September 21, 2020
	===========================================================================
	.SYNOPSIS
		This function will check to see if your VCSA supports Scheduled Backups.
		(vSphere 6.7 and higher)
	.DESCRIPTION
		Use this function to check if your VCSA supports Scheduled Backups.
	.EXAMPLE
		PS C:\> Test-VCSAScheduleSupport
	.EXAMPLE
		PS C:\> Test-VCSAScheduleSupport -CisServer "vcserver.sphere.local"
	.NOTES
		Credit goes to @AlanRenouf & @vBrianGraf for sharing the base of this function.
		You must be connected to the CisService for this to work, if you are not connected, the function will prompt you for your credentia
#>
	param (
		[Parameter(Mandatory=$false)]$CisServer = $global:DefaultCisServers
	)
	Begin {
		if ($CisServer.IsConnected) {
			Write-Verbose "Connected to $($CisServer.Name)"
			$connection = $CisServer
		} elseif ($CisServer.gettype().name -eq "String") {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($CisServer)."
			$Connection = Connect-CisServer $CisServer
		} elseif ($global:DefaultCisServers) {
			$connection = $global:DefaultCisServers
		} elseif ($global:DefaultVIServer) {
			Write-Host "Prompting for CIS Server credentials. Connecting to $($global:DefaultVIServer.name)."
			$Connection = Connect-CisServer $global:DefaultVIServer
		}
		if (!$Connection) {
			Write-Error "It appears you have not created a connection to the CisServer. Please Connect First and try command again. (Connect-CisServer)"
		}
	}
	Process{
		if ((Get-CisService).name -contains "com.vmware.appliance.recovery.backup.schedules" ) {
			Write-Verbose "This VCSA does supports Backup Schedules."
			return $true
		} else {
			Write-Verbose "This VCSA does not support Backup Schedules."
			return $false
		}
	}
	End {}
}
