Function Get-VAMISummary {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves some basic information from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return basic VAMI summary info
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMISummary
#>
    $systemVersionAPI = Get-CisService -Name 'com.vmware.appliance.system.version'
    $results = $systemVersionAPI.get() | select product, type, version, build, install_time, releasedate

    $systemUptimeAPI = Get-CisService -Name 'com.vmware.appliance.system.uptime'
    $ts = [timespan]::fromseconds($systemUptimeAPI.get().toString())
    $uptime = $ts.ToString("hh\:mm\:ss\,fff")

    $summaryResult = [pscustomobject] @{
        Product = $results.product;
        Type = $results.type;
        Version = $results.version;
        Build = $results.build;
        InstallTime = $results.install_time;
        ReleaseDate = $results.releasedate;
        Uptime = $uptime
    }
    $summaryResult
}

Function Get-VAMIHealth {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves health information from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return VAMI health
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIHealth
#>
    $healthOverall = (Get-CisService -Name 'com.vmware.appliance.health.system').get()
    $healthLastCheck = (Get-CisService -Name 'com.vmware.appliance.health.system').lastcheck()
    $healthCPU = (Get-CisService -Name 'com.vmware.appliance.health.load').get()
    $healthMem = (Get-CisService -Name 'com.vmware.appliance.health.mem').get()
    $healthSwap = (Get-CisService -Name 'com.vmware.appliance.health.swap').get()
    $healthStorage = (Get-CisService -Name 'com.vmware.appliance.health.storage').get()

    # DB health only applicable for Embedded/External VCSA Node
    $vami = (Get-CisService -Name 'com.vmware.appliance.system.version').get()

    if($vami.type -eq "vCenter Server with an embedded Platform Services Controller" -or $vami.type -eq "vCenter Server with an external Platform Services Controller") {
        $healthVCDB = (Get-CisService -Name 'com.vmware.appliance.health.databasestorage').get()
    } else {
        $healthVCDB = "N/A"
    }
    $healthSoftwareUpdates = (Get-CisService -Name 'com.vmware.appliance.health.softwarepackages').get()

    $healthResult = [pscustomobject] @{
        HealthOverall = $healthOverall;
        HealthLastCheck = $healthLastCheck;
        HealthCPU = $healthCPU;
        HealthMem = $healthMem;
        HealthSwap = $healthSwap;
        HealthStorage = $healthStorage;
        HealthVCDB = $healthVCDB;
        HealthSoftware = $healthSoftwareUpdates
    }
    $healthResult
}

Function Get-VAMIAccess {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves access information from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return VAMI access interfaces (Console,DCUI,Bash Shell & SSH)
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIAccess
#>
    $consoleAccess = (Get-CisService -Name 'com.vmware.appliance.access.consolecli').get()
    $dcuiAccess = (Get-CisService -Name 'com.vmware.appliance.access.dcui').get()
    $shellAccess = (Get-CisService -Name 'com.vmware.appliance.access.shell').get()
    $sshAccess = (Get-CisService -Name 'com.vmware.appliance.access.ssh').get()

    $accessResult = New-Object PSObject -Property @{
        Console = $consoleAccess;
        DCUI = $dcuiAccess;
        BashShell = $shellAccess.enabled;
        BashTimeout = $shellAccess.timeout;
        SSH = $sshAccess
    }
    $accessResult
}

Function Get-VAMITime {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
     Modifed by:    Michael Dunsdon
     Twitter:      @MJDunsdon
     Date:         September 16, 2020
    ===========================================================================
    .SYNOPSIS
        This function retrieves the time and NTP info from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return current Time and NTP information
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMITime
    .NOTES
        Modified script to account for Newer VCSA. Script supports 6.5 and 6.7 VCSAs
#>
    $systemTimeAPI = Get-CisService -Name 'com.vmware.appliance.system.time'
    $timeResults = $systemTimeAPI.get()

    if ((Get-CisService | Where-Object {$_.name -like "*timesync*"}).name -like "*techpreview*") {
        $timeSync = (Get-CisService -Name 'com.vmware.appliance.techpreview.timesync').get()
        $timeSyncMode = $timeSync.mode
    } else {
        $timeSyncMode = (Get-CisService -Name 'com.vmware.appliance.timesync').get()
    }

    $timeResult  = [pscustomobject] @{
        Timezone = $timeResults.timezone;
        Date = $timeResults.date;
        CurrentTime = $timeResults.time;
        Mode = $timeSyncMode;
        NTPServers = "N/A";
        NTPStatus = "N/A";
    }

    if($timeSyncMode -eq "NTP") {
        if ((Get-CisService | Where-Object {$_.name -like "*timesync*"}).name -like "*techpreview*") {
            $ntpServers = (Get-CisService -Name 'com.vmware.appliance.techpreview.ntp').get()
            $timeResult.NTPServers = $ntpServers.servers
            $timeResult.NTPStatus = $ntpServers.status
        } else {
            $timeResult.NTPServers = (Get-CisService -Name 'com.vmware.appliance.ntp').get()
        }
    }
    $timeResult
}

Function Get-VAMINetwork {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
     Modifed by:    Michael Dunsdon
     Twitter:      @MJDunsdon
     Date:         September 16, 2020
	===========================================================================
    .SYNOPSIS
        This function retrieves network information from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return networking information including details for each interface
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMINetwork
    .NOTES
        Modified script to account for Newer VCSA. Script supports 6.5 and 6.7 VCSAs
#>
    $netResults = @()

    $Hostname = (Get-CisService -Name 'com.vmware.appliance.networking.dns.hostname').get()
    $dns = (Get-CisService -Name 'com.vmware.appliance.networking.dns.servers').get()

    Write-Host "Hostname: " $hostname
    Write-Host "DNS Servers: " $dns.servers

    $interfaces = (Get-CisService -Name 'com.vmware.appliance.networking.interfaces').list()
    foreach ($interface in $interfaces) {
        if ((Get-CisService | Where-Object {$_.name -like "*ipv4*"}).name -like "*techpreview*") {
            $ipv4API = (Get-CisService -Name 'com.vmware.appliance.techpreview.networking.ipv4')
            $spec = $ipv4API.Help.get.interfaces.CreateExample()
            $spec+= $interface.name
            $ipv4result = $ipv4API.get($spec)

            $interfaceResult = [pscustomobject] @{
                Inteface =  $interface.name;
                MAC = $interface.mac;
                Status = $interface.status;
                Mode = $ipv4result.mode;
                IP = $ipv4result.address;
                Prefix = $ipv4result.prefix;
                Gateway = $ipv4result.default_gateway;
                Updateable = $ipv4result.updateable
            }
        } else {
            $interfaceResult = [pscustomobject] @{
                Inteface =  $interface.name;
                MAC = $interface.mac;
                Status = $interface.status;
                Mode = $interface.ipv4.mode;
                IP = $interface.ipv4.address;
                Prefix = $interface.ipv4.prefix;
                Gateway = $interface.ipv4.default_gateway;
                Updateable = $interface.ipv4.configurable
            }
        }
        $netResults += $interfaceResult
    }
    $netResults
}

Function Get-VAMIDisks {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves VMDK disk number to partition mapping VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return VMDK disk number to OS partition mapping
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIDisks
#>
    $storageAPI = Get-CisService -Name 'com.vmware.appliance.system.storage'
    $disks = $storageAPI.list()

    foreach ($disk in $disks | sort {[int]$_.disk.toString()}) {
        $disk | Select Disk, Partition
    }
}

Function Start-VAMIDiskResize {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function triggers an OS partition resize after adding additional disk capacity
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function triggers OS partition resize operation
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Start-VAMIDiskResize
#>
    $storageAPI = Get-CisService -Name 'com.vmware.appliance.system.storage'
    Write-Host "Initiated OS partition resize operation ..."
    $storageAPI.resize()
}

Function Get-VAMIStatsList {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves list avialable monitoring metrics in VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return list of available monitoring metrics that can be queried
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIStatsList
#>
    $monitoringAPI = Get-CisService -Name 'com.vmware.appliance.monitoring'
    $ids = $monitoringAPI.list() | Select id | Sort-Object -Property id

    foreach ($id in $ids) {
        $id
    }
}

Function Get-VAMIStorageUsed {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
     Modifed by:    Michael Dunsdon
     Twitter:      @MJDunsdon
     Date:         September 16, 2020
	===========================================================================
    .SYNOPSIS
        This function retrieves the individaul OS partition storage utilization
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return individual OS partition storage utilization
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIStorageUsed
    .NOTES
        Modified script to account for Newer VCSA. Script supports 6.5 and 6.7 VCSAs.
        Also modifed the static list of filesystems to be more dynamic in nature to account for the differences in VCSA versions.
#>


    $monitoringAPI = Get-CisService 'com.vmware.appliance.monitoring'
    $querySpec = $monitoringAPI.help.query.item.CreateExample()

    # List of IDs from Get-VAMIStatsList to query
    $querySpec.Names = ($monitoringAPI.list() | Where-Object {($_.name -like "*storage.used.filesystem*") -or ($_.name -like "*storage.totalsize.filesystem*") } | Select id | Sort-Object -Property id).id.value

    # Tuple (Filesystem Name, Used, Total) to store results
    $storageStats = @{
    "archive"=@{"name"="/storage/archive";"used"=0;"total"=0};
    "autodeploy"=@{"name"="/storage/autodeploy";"used"=0;"total"=0};
    "boot"=@{"name"="/boot";"used"=0;"total"=0};
    "core"=@{"name"="/storage/core";"used"=0;"total"=0};
    "imagebuilder"=@{"name"="/storage/imagebuilder";"used"=0;"total"=0};
    "invsvc"=@{"name"="/storage/invsvc";"used"=0;"total"=0};
    "log"=@{"name"="/storage/log";"used"=0;"total"=0};
    "netdump"=@{"name"="/storage/netdump";"used"=0;"total"=0};
    "root"=@{"name"="/";"used"=0;"total"=0};
    "updatemgr"=@{"name"="/storage/updatemgr";"used"=0;"total"=0};
    "db"=@{"name"="/storage/db";"used"=0;"total"=0};
    "seat"=@{"name"="/storage/seat";"used"=0;"total"=0};
    "dblog"=@{"name"="/storage/dblog";"used"=0;"total"=0};
    "swap"=@{"name"="swap";"used"=0;"total"=0}
    }

    $querySpec.interval = "DAY1"
    $querySpec.function = "MAX"
    $querySpec.start_time = ((get-date).AddDays(-1))
    $querySpec.end_time = (Get-Date)
    $queryResults = $monitoringAPI.query($querySpec) | Select * -ExcludeProperty Help

    foreach ($queryResult in $queryResults) {
        # Update hash if its used storage results
        $key = ((($queryResult.name).toString()).split(".")[-1]) -replace "coredump","core" -replace "vcdb_","" -replace "core_inventory","db" -replace "transaction_log","dblog"
        $value = [Math]::Round([int]($queryResult.data[1]).toString()/1MB,2)
        if($queryResult.name -match "used") {
            $storageStats[$key]["used"] = $value
        # Update hash if its total storage results
        } else {
            $storageStats[$key]["total"] = $value
        }
    }

    $storageResults = @()
    foreach ($key in $storageStats.keys | Sort-Object -Property name) {
        $statResult = [pscustomobject] @{
            Filesystem = $storageStats[$key].name;
            Used = $storageStats[$key].used;
            Total = $storageStats[$key].total
        }
        $storageResults += $statResult
    }
    $storageResults
}

Function Get-VAMIService {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves list of services in VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return list of services and their description
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIService
    .EXAMPLE
        Get-VAMIService -Name rbd
#>
    param(
        [Parameter(
            Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String]$Name
    )

    if($Name -ne "") {
        $vMonAPI = Get-CisService 'com.vmware.appliance.vmon.service'

        try {
            $serviceStatus = $vMonAPI.get($name,0)
            $serviceString = [pscustomobject] @{
                Name = $name;
                State = $serviceStatus.state;
                Health = "";
                Startup = $serviceStatus.startup_type
            }
            if($serviceStatus.health -eq $null) { $serviceString.Health = "N/A"} else { $serviceString.Health = $serviceStatus.health }
            $serviceString
        } catch {
            Write-Error $Error[0].exception.Message
        }
    } else {
        $vMonAPI = Get-CisService 'com.vmware.appliance.vmon.service'
        $services = $vMonAPI.list_details()

        $serviceResult = @()
        foreach ($key in $services.keys | Sort-Object -Property Value) {
            $serviceString = [pscustomobject] @{
                Name = $key;
                State =  $services[$key].state;
                Health = "N/A";
                Startup = $services[$key].Startup_type
            }
            if($services[$key].health -eq $null) { $serviceString.Health = "N/A"} else { $serviceString.Health = $services[$key].health }

            $serviceResult += $serviceString
        }
        $serviceResult
    }
}

Function Start-VAMIService {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves list of services in VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return list of services and their description
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Start-VAMIService -Name rbd
#>
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String]$Name
    )

    $vMonAPI = Get-CisService 'com.vmware.appliance.vmon.service'

    try {
        Write-Host "Starting $name service ..."
        $vMonAPI.start($name)
    } catch {
        Write-Error $Error[0].exception.Message
    }
}

Function Stop-VAMIService {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves list of services in VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return list of services and their description
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Stop-VAMIService -Name rbd
#>
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String]$Name
    )

    $vMonAPI = Get-CisService 'com.vmware.appliance.vmon.service'

    try {
        Write-Host "Stopping $name service ..."
        $vMonAPI.stop($name)
    } catch {
        Write-Error $Error[0].exception.Message
    }
}

Function Get-VAMIBackupSize {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.SYNOPSIS
		This function retrieves the backup size of the VCSA from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
	.DESCRIPTION
		Function to return the current backup size of the VCSA (common and core data)
	.EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIBackupSize
#>
    $recoveryAPI = Get-CisService 'com.vmware.appliance.recovery.backup.parts'
    $backupParts = $recoveryAPI.list() | select id

    $estimateBackupSize = 0
    $backupPartSizes = ""
    foreach ($backupPart in $backupParts) {
        $partId = $backupPart.id.value
        $partSize = $recoveryAPI.get($partId)
        $estimateBackupSize += $partSize
        $backupPartSizes += $partId + " data is " + $partSize + " MB`n"
    }

    Write-Host "Estimated Backup Size: $estimateBackupSize MB"
    Write-Host $backupPartSizes
}

Function Get-VAMIUser {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
     Modifed by:    Michael Dunsdon
     Twitter:      @MJDunsdon
     Date:         September 16, 2020
    ===========================================================================
    .SYNOPSIS
        This function retrieves VAMI local users using VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to retrieve VAMI local users
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIUser
    .NOTES
        Modified script to account for Newer VCSA. Script supports 6.5 and 6.7 VCSAs.
#>
    param(
        [Parameter(
            Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String]$Name
    )

    if ((Get-CisService | Where-Object {$_.name -like "*accounts*"}).name -like "*techpreview*") {
        $userAPI = Get-CisService 'com.vmware.appliance.techpreview.localaccounts.user'
    } else {
        $userAPI = Get-CisService 'com.vmware.appliance.local_accounts'
    }

    $userResults = @()

    if (($Name -ne "") -and ($null -ne $Name)) {
        try {
            $users = $userAPI.get($name)
        } catch {
            Write-Error $Error[0].exception.Message
        }
    } else {
        $users = $userAPI.list()
    }
    if ($users.status) {
        foreach ($user in $users) {
            $userString = [pscustomobject] @{
                User = $user.username
                Name = $user.fullname
                Email = $user.email
                Status = $user.status
                PasswordStatus = $user.passwordstatus
                Roles = @($user.role)
            }
            $userResults += $userString
        }
    } else {
        foreach ($user in $users) {
            $userinfo = $userAPI.get($user)
            $userString = [pscustomobject] @{
                User = $user.value
                Name = $userinfo.fullname
                Email = $userinfo.email
                Status = $userinfo.enabled
                LastPasswordChange = $userinfo.last_password_change
                PasswordExpiresAt = $userinfo.password_expires_at
                PasswordStatus = if ($userinfo.has_password) { if ((!!$userinfo.password_expires_at) -and ([datetime]$userinfo.password_expires_at -lt (get-date))) {"good"} else {"expired"}} else { "notset"}
                Roles = $userinfo.roles
            }
            $userResults += $userString
        }
    }
    $userResults
}

Function New-VAMIUser {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
     Modifed by:    Michael Dunsdon
     Twitter:      @MJDunsdon
     Date:         September 16, 2020
    ===========================================================================
    .SYNOPSIS
        This function to create new VAMI local user using VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to create a new VAMI local user
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        New-VAMIUser -name lamw -fullname "William Lam" -role "operator" -email "lamw@virtuallyghetto.com" -password "VMware1!" -passwordexpires  -passwordexpiresat "1/1/1970" -maxpasswordage 90
    .NOTES
        Modified script to account for Newer VCSA. Script supports 6.5 and 6.7 VCSAs.
        Also added new Parameters to script.
#>
    param(
        [Parameter(Mandatory=$true)]
        [String]$name,
        [Parameter(Mandatory=$true)]
        [String]$fullname,
        [Parameter(Mandatory=$true)]
        [ValidateSet("admin","operator","superAdmin")]
        [String]$role,
        [Parameter(Mandatory=$false)]
        [String]$email="",
        [Parameter(Mandatory=$true)]
        [String]$password,
        [Parameter(Mandatory=$false)]
        [switch]$passwordexpires,
        [Parameter(Mandatory=$false)]
        [String]$passwordexpiresat = $null,
        [Parameter(Mandatory=$false)]
        [String]$maxpasswordage = 90
    )

    if ((Get-CisService | Where-Object {$_.name -like "*accounts*"}).name -like "*techpreview*") {
        $userAPI = Get-CisService 'com.vmware.appliance.techpreview.localaccounts.user'
        $createSpec = $userAPI.Help.add.config.CreateExample()
    } else {
        $userAPI = Get-CisService 'com.vmware.appliance.local_accounts'
        $createSpec = $userAPI.Help.create.config.CreateExample()
    }

    $createSpec.fullname = $fullname
    $createSpec.role = $role
    $createSpec.email = $email
    $createSpec.password = [VMware.VimAutomation.Cis.Core.Types.V1.Secret]$password
    
    if ((Get-CisService | Where-Object {$_.name -like "*accounts*"}).name -like "*techpreview*") {
        $createSpec.username = $name
        try {
            Write-Host "Creating new user $name ..."
            $userAPI.add($createSpec)
        } catch {
            Write-Error $Error[0].exception.Message
        }
    } else {
        $createSpec.password_expires = $passwordexpires
        $createSpec.password_expires_at = $passwordexpiresat
        $createSpec.max_days_between_password_change = $maxpasswordage
        try {
            Write-Host "Creating new user $name ..."
            $userAPI.create($name, $createSpec)
        } catch {
            Write-Error $Error[0].exception.Message
        }
    }
}

Function Update-VAMIUser {
<#
    .NOTES
    ===========================================================================
     Inspired by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
     Created by:    Michael Dunsdon
     Twitter:      @MJDunsdon
     Date:         September 16, 2020
    ===========================================================================
    .SYNOPSIS
        This function to update fields of a VAMI local user using VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to update fields of a VAMI local user
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Update-VAMIUser -name lamw -fullname "William Lam" -role "operator" -email "lamw@virtuallyghetto.com" -password "VMware1!" -passwordexpires  -passwordexpiresat "1/1/1970" -maxpasswordage 90
    .NOTES
        Created script to allow updating of an exisiting user account. Script supports 6.5 and 6.7 VCSAs.
#>
    param(
        [Parameter(Mandatory=$true)]
        [String]$name,
        [Parameter(Mandatory=$false)]
        [String]$fullname,
        [Parameter(Mandatory=$false)]
        [ValidateSet("admin","operator","superAdmin")]
        [String]$role,
        [Parameter(Mandatory=$false)]
        [String]$email="",
        [Parameter(Mandatory=$false)]
        [String]$password = $null,
        [Parameter(Mandatory=$false)]
        [switch]$passwordexpires,
        [Parameter(Mandatory=$false)]
        [String]$passwordexpiresat = $null,
        [Parameter(Mandatory=$false)]
        [String]$maxpasswordage = 90
    )

    if ((Get-CisService | Where-Object {$_.name -like "*accounts*"}).name -like "*techpreview*") {
        $userAPI = Get-CisService 'com.vmware.appliance.techpreview.localaccounts.user'
        $updateSpec = $userAPI.Help.set.config.CreateExample()
    } else {
        $userAPI = Get-CisService 'com.vmware.appliance.local_accounts'
        $updateSpec = $userAPI.Help.update.config.CreateExample()
    }

    $updateSpec.fullname = $fullname
    $updateSpec.role = $role
    $updateSpec.email = $email
    $updateSpec.password = [VMware.VimAutomation.Cis.Core.Types.V1.Secret]$password

    if ((Get-CisService | Where-Object {$_.name -like "*accounts*"}).name -like "*techpreview*") {
        $updateSpec.username = $name
        try {
            Write-Host "Creating new user $name ..."
            $userAPI.set($updateSpec)
        } catch {
            Write-Error $Error[0].exception.Message
        }
    } else {
        $updateSpec.password_expires = $passwordexpires
        $updateSpec.password_expires_at = $passwordexpiresat
        $updateSpec.max_days_between_password_change = $maxpasswordage
        try {
            Write-Host "Creating new user $name ..."
            $userAPI.update($name, $updateSpec)
        } catch {
            Write-Error $Error[0].exception.Message
        }
    }
}

Function Remove-VAMIUser {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
     Modifed by:    Michael Dunsdon
     Twitter:      @MJDunsdon
     Date:         September 16, 2020
    ===========================================================================
    .SYNOPSIS
        This function to remove VAMI local user using VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to remove VAMI local user
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIAccess
    .NOTES
        Modified script to account for Newer VCSA. Script supports 6.5 and 6.7 VCSAs.
#>
    param(
        [Parameter(Mandatory=$true)]
        [String]$name,
        [Parameter(Mandatory=$false)]
        [boolean]$confirm=$false
    )

    if(!$confirm) {
        $answer = Read-Host -Prompt "Do you want to delete user $name (Y or N)"
        if($answer -eq "Y" -or $answer -eq "y") {
            if ((Get-CisService | Where-Object {$_.name -like "*accounts*"}).name -like "*techpreview*") {
                $userAPI = Get-CisService 'com.vmware.appliance.techpreview.localaccounts.user'
            } else {
                $userAPI = Get-CisService 'com.vmware.appliance.local_accounts'
            }
            try {
                Write-Host "Deleting user $name ..."
                $userAPI.delete($name)
            } catch {
                Write-Error $Error[0].exception.Message
            }
        }
    }
}
