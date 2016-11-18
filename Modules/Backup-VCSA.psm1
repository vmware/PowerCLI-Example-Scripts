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
        You must be connected to the CisService for this to work, if you are not connected, the function will prompt you for your credentials
		If a -LocationType is not chosen, the function will default to FTP.
        The destination location for a backup must be an empty folder (easiest to use the get-date cmdlet in the location)
        -ShowProgress will give you a progressbar as well as updates in the console
        -SeatBackup will only backup the config whereas -Fullbackup grabs the historical data as well
#>
    param (
        [Parameter(ParameterSetName=’FullBackup’)]
        [switch]$FullBackup,
        [Parameter(ParameterSetName=’SeatBackup’)]
        [switch]$SeatBackup,
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
            [System.Windows.Forms.MessageBox]::Show("It appears you have not created a connection to the CisServer. You will now be prompted to enter your vCenter credentials to continue" , "Connect to CisServer") | out-null
            $Connection = Connect-CisServer $global:DefaultVIServer 
        } else {
            $Connection = $global:DefaultCisServers
        }
        if ($FullBackup) {$parts = @("common","seat")}
        if ($SeatBackup) {$parts = @("seat")}
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
        }
        catch {
            Write-Error $Error[0].exception.Message
        }
            

        If ($ShowProgress){
            do {
                $BackupAPI.get("$($BackupJob.ID)") | select id, progress, state
                $progress = ($BackupAPI.get("$($BackupJob.ID)").progress)
                Write-Progress -Activity "Backing up VCSA"  -Status $BackupAPI.get("$($BackupJob.ID)").state -PercentComplete ($BackupAPI.get("$($BackupJob.ID)").progress) -CurrentOperation "$progress% Complete"
                start-sleep -seconds 5
            } until ($BackupAPI.get("$($BackupJob.ID)").progress -eq 100 -or $BackupAPI.get("$($BackupJob.ID)").state -ne "INPROGRESS")

            $BackupAPI.get("$($BackupJob.ID)") | select id, progress, state
        } 
        Else {
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
        }
        catch {
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
