Function Backup-VCSAToFile {
<#
	.NOTES
	===========================================================================
	 Created by:   	Brian Graf
	 Date:          October 30, 2016
	 Organization: 	VMware
	 Blog:          www.vtagion.com
	 Twitter:       @vBrianGraf
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
		If a -LocationType is not chosen, the function will default to FTP.
		The destination location for a backup must be an empty folder (easiest to use the get-date cmdlet in the location)
		-ShowProgress will give you a progressbar as well as updates in the console
		-CommonBackup will only backup the config whereas -Fullbackup grabs the historical data as well
#>
	param (
		[Parameter(ParameterSetName=’FullBackup’)]
		[switch]$FullBackup,
		[Parameter(ParameterSetName=’CommonBackup’)]
		[switch]$CommonBackup,
		[ValidateSet('FTPS', 'HTTP', 'SCP', 'HTTPS', 'FTP')]
		$LocationType = "FTP",
		$Location,
		$LocationUser,
		[VMware.VimAutomation.Cis.Core.Types.V1.Secret]$LocationPassword,
		[VMware.VimAutomation.Cis.Core.Types.V1.Secret]$BackupPassword,
		$Comment = "Backup job",
		[switch]$ShowProgress
	)
	Begin {
		if (!($global:DefaultCisServers)){ 
			Add-Type -Assembly System.Windows.Forms
			[System.Windows.Forms.MessageBox]::Show("It appears you have not created a connection to the CisServer. You will now be prompted to enter your vCenter credentials to continue" , "Connect to CisServer") | out-null
			$Connection = Connect-CisServer $global:DefaultVIServer 
		} else {
			$Connection = $global:DefaultCisServers
		}
		if ($FullBackup) {$parts = @("common","seat")}
		if ($CommonBackup) {$parts = @("common")}
	}
	Process{
		$BackupAPI = Get-CisService com.vmware.appliance.recovery.backup.job
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
				$BackupAPI.get("$($BackupJob.ID)") | select id, progress, state
				$progress = ($BackupAPI.get("$($BackupJob.ID)").progress)
				Write-Progress -Activity "Backing up VCSA"  -Status $BackupAPI.get("$($BackupJob.ID)").state -PercentComplete ($BackupAPI.get("$($BackupJob.ID)").progress) -CurrentOperation "$progress% Complete"
				start-sleep -seconds 5
			} until ($BackupAPI.get("$($BackupJob.ID)").progress -eq 100 -or $BackupAPI.get("$($BackupJob.ID)").state -ne "INPROGRESS")
			Write-Progress -Activity "Backing up VCSA" -Completed
			$BackupAPI.get("$($BackupJob.ID)") | select id, progress, state
		} Else {
			$BackupJob | select id, progress, state
		}
	}
	End {}
}

Function Get-VCSABackupJobs {
<#
	.NOTES
	===========================================================================
	 Created by:   	Brian Graf
	 Date:          October 30, 2016
	 Organization: 	VMware
	 Blog:          www.vtagion.com
	 Twitter:       @vBrianGraf
	===========================================================================

	.SYNOPSIS
		Get-VCSABackupJobs returns a list of all backup jobs VCSA has ever performed (vSphere 6.5 and higher)
	.DESCRIPTION
		Get-VCSABackupJobs returns a list of all backup jobs VCSA has ever performed
	.EXAMPLE
		PS C:\> Get-VCSABackupJobs
	.NOTES
		The values returned are read as follows:
		YYYYMMDD-hhmmss-vcsabuildnumber
		You can pipe the results of this function into the Get-VCSABackupStatus function
		Get-VCSABackupJobs | select -First 1 | Get-VCSABackupStatus <- Most recent backup
#>
	param (
		[switch]$ShowNewest
	)
	Begin {
		if (!($global:DefaultCisServers)){ 
			[System.Windows.Forms.MessageBox]::Show("It appears you have not created a connection to the CisServer. You will now be prompted to enter your vCenter credentials to continue" , "Connect to CisServer") | out-null
			$Connection = Connect-CisServer $global:DefaultVIServer 
		} else {
			$Connection = $global:DefaultCisServers
		}
	}
	Process{
		$BackupAPI = Get-CisService com.vmware.appliance.recovery.backup.job
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
	 Created by:   	Brian Graf
	 Date:          October 30, 2016
	 Organization: 	VMware
	 Blog:          www.vtagion.com
	 Twitter:       @vBrianGraf
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
		[parameter(ValueFromPipeline=$True)]
		[string[]]$BackupID
	)
	Begin {
		if (!($global:DefaultCisServers)){ 
			[System.Windows.Forms.MessageBox]::Show("It appears you have not created a connection to the CisServer. You will now be prompted to enter your vCenter credentials to continue" , "Connect to CisServer") | out-null
			$Connection = Connect-CisServer $global:DefaultVIServer 
		} else {
			$Connection = $global:DefaultCisServers
		}
		$BackupAPI = Get-CisService com.vmware.appliance.recovery.backup.job
	}
	Process{
		foreach ($id in $BackupID) {
			$BackupAPI.get("$id") | select id, progress, state
		}
	}
	End {}
}

Function Create-VCSASchedule {
<#
	.NOTES
	===========================================================================
	 Original Created by:  Brian Graf
	 Blog:                 www.vtagion.com
	 Twitter:              @vBrianGraf
	 Organization:         VMware
	 Created / Modifed by: Michael Dunsdon
	 Twitter:              @MJDunsdon
	 Date:                 September 16, 2020
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
		
		PS C:\> Set-VCSASchedule -Location $location -LocationUser $LocationUser -LocationPassword $locationPassword -BackupHour $BHour -BackupMinute $BMin -backupDays $BDays -MaxCount $MaxCount -BackupPassword $BackupPassword
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
		
		PS C:\> Set-VCSASchedule -IncludeSeat -force -Location $location -LocationUser $LocationUser -LocationPassword $locationPassword -BackupHour $BHour -BackupMinute $BMin -backupDays $BDays -MaxCount $MaxCount -BackupPassword $BackupPassword
	.NOTES
		Credit goes to @AlanRenouf & @vBrianGraf for sharing the base of this function.
		You must be connected to the CisService for this to work, if you are not connected, the function will prompt you for your credentials
#>
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
	param (
		[Parameter(Mandatory=$true)]$Location,
		[Parameter(Mandatory=$true)]$LocationUser,
		[Parameter(Mandatory=$true)][VMware.VimAutomation.Cis.Core.Types.V1.Secret]$LocationPassword,
		[Parameter(Mandatory=$true)][VMware.VimAutomation.Cis.Core.Types.V1.Secret]$BackupPassword,
		[Parameter(Mandatory=$true)][ValidateRange(0,23)]$BackupHour,
		[Parameter(Mandatory=$true)][ValidateRange(0,59)]$BackupMinute,
		[Parameter(Mandatory=$true)][ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')][Array]$backupDays = $null,
		[Parameter(Mandatory=$true)][Integer]$MaxCount,
		[Parameter(Mandatory=$false)]$BackupID = "default",
		[Parameter(Mandatory=$false)][switch]$IncludeSeat,
		[Parameter(Mandatory=$false)][switch]$force
	)
	Begin {
		if (!($global:DefaultCisServers)){ 
			Add-Type -Assembly System.Windows.Forms
			[System.Windows.Forms.MessageBox]::Show("It appears you have not created a connection to the CisServer. You will now be prompted to enter your vCenter credentials to continue" , "Connect to CisServer") | out-null
			$Connection = Connect-CisServer $global:DefaultVIServer 
		} else {
			$Connection = $global:DefaultCisServers
		}
 	}
	Process{
		if ((get-cisservice).name -notcontains "com.vmware.appliance.recovery.backup.schedules" ) {
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
			$CreateSpec.parts = @("seat")
		} else {
			$CreateSpec.parts = @()
		}
		$currentschedule = $BackupAPI.list()
		
		
		if ($currentschedule.keys.value) {
			if($Force -or $PSCmdlet.ShouldContinue($currentschedule.keys.value,'Delete Old Schedule')){
				$BackupAPI.delete($currentschedule.keys.value)
			} else {
				Write-Error "There is an exisiting Schedule. Please delete before Creating a new one."
				return
			}
		}
		if ($PSCmdlet.ShouldProcess($backupID, 'Create New Schedule.')) {
			try {
				$BackupJob = $BackupAPI.create($backupID, $CreateSpec)
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
	 Date:                 September 16, 2020
	===========================================================================

	.SYNOPSIS
		This function will allow you to Get the scheduled backup of your
		VCSA appliance. (vSphere 6.7 and higher)
	.DESCRIPTION
		Use this function to Get the backup schedule for your VCSA appliance.
	.EXAMPLE
		PS C:\> Get-VCSASchedule
	.EXAMPLE
		PS C:\> Get-VCSASchedule -ScheduleID 1
	.NOTES
		Credit goes to @AlanRenouf & @vBrianGraf for sharing the base of this function.
		Returns a simplified object with the schedule details. 
		You must be connected to the CisService for this to work, if you are not connected, the function will prompt you for your credentials
#>
	param (
		[Parameter(Mandatory=$False,HelpMessage="Will Filter List By ScheduleID")]
		$ScheduleID
	)
	Begin {
		if (!($global:DefaultCisServers)){ 
			Add-Type -Assembly System.Windows.Forms
			[System.Windows.Forms.MessageBox]::Show("It appears you have not created a connection to the CisServer. You will now be prompted to enter your vCenter credentials to continue" , "Connect to CisServer") | out-null
			$Connection = Connect-CisServer $global:DefaultVIServer 
		} else {
			$Connection = $global:DefaultCisServers
		}
	}
	Process{
		if ((get-cisservice).name -notcontains "com.vmware.appliance.recovery.backup.schedules" ) {
			Write-Error "This VCSA does not support Backup Schedules."
			return
		}
		$BackupAPI = Get-CisService -name 'com.vmware.appliance.recovery.backup.schedules'
		$Schedules = $BackupAPI.list()
		if ($Schedules.count -ge 1) {
			$objschedule = @()
			foreach ($schedule in $Schedules) {
				$objschedule += $Schedule.values | select *,@{N = "ID"; e = {"$($schedule.keys.value)"}} -ExpandProperty recurrence_info -ExcludeProperty Help | select * -ExcludeProperty recurrence_info,Help | select * -ExpandProperty retention_info | select * -ExcludeProperty retention_info,Help
			}
			if ($ScheduleID) {
				$objschedule = $objschedule | Where-Object {$_.ID -eq $ScheduleID}
			}
			return $objschedule
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
	 Date:                 September 16, 2020
	============================================================================
 	.SYNOPSIS
		This function will remove any scheduled backups of your
		VCSA appliance. (vSphere 6.7 and higher)
	.DESCRIPTION
		Use this function to remove the backup schedule for your VCSA appliance.
	.EXAMPLE
		PS C:\> Remove-VCSASchedule
	.EXAMPLE
		PS C:\> Remove-VCSASchedule -ScheduleID 1
	.NOTES
		Credit goes to @AlanRenouf & @vBrianGraf for sharing the base of this function.
		You must be connected to the CisService for this to work, if you are not connected, the function will prompt you for your credentials
#>
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
	param (
		$ScheduleID = "default"
	)
	Begin {
		if (!($global:DefaultCisServers)){ 
			Add-Type -Assembly System.Windows.Forms
			[System.Windows.Forms.MessageBox]::Show("It appears you have not created a connection to the CisServer. You will now be prompted to enter your vCenter credentials to continue" , "Connect to CisServer") | out-null
			$Connection = Connect-CisServer $global:DefaultVIServer 
		} else {
			$Connection = $global:DefaultCisServers
		}
	}
	Process{
		if ((get-cisservice).name -notcontains "com.vmware.appliance.recovery.backup.schedules" ) {
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
	 Date:                 September 16, 2020
	===========================================================================
	.SYNOPSIS
		This function will check to see if your VCSA supports Scheduled Backups.
		(vSphere 6.7 and higher)
	.DESCRIPTION
		Use this function to check if your VCSA supports Scheduled Backups.
	.EXAMPLE
		PS C:\> Test-VCSAScheduleSupport
	.NOTES
		Credit goes to @AlanRenouf & @vBrianGraf for sharing the base of this function.
		You must be connected to the CisService for this to work, if you are not connected, the function will prompt you for your credentia
#>
	param ()
	Begin {
		if (!($global:DefaultCisServers)){ 
			Add-Type -Assembly System.Windows.Forms
			[System.Windows.Forms.MessageBox]::Show("It appears you have not created a connection to the CisServer. You will now be prompted to enter your vCenter credentials to continue" , "Connect to CisServer") | out-null
			$Connection = Connect-CisServer $global:DefaultVIServer 
		} else {
			$Connection = $global:DefaultCisServers
		}
	}
	Process{
		if ((get-cisservice).name -contains "com.vmware.appliance.recovery.backup.schedules" ) {
			Write-Verbose "This VCSA does supports Backup Schedules."
			return $true
		} else {
			Write-Verbose "This VCSA does not support Backup Schedules."
			return $false
		}
	}
	End {}
}

