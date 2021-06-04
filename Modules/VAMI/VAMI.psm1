<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

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
    $systemTimeAPI = ( Get-VAMIServiceAPI -NameFilter "system.time")
    $timeResults = $systemTimeAPI.get()

    $timeSyncMode = ( Get-VAMIServiceAPI -NameFilter "timesync").get()
    if ($timeSyncMode.mode) {
        $timeSyncMode = $timeSync.mode
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
        $ntpServers = ( Get-VAMIServiceAPI -NameFilter "ntp").get()
        if ($ntpServers.servers) {
            $timeResult.NTPServers = $ntpServers.servers
            $timeResult.NTPStatus = $ntpServers.status
        } else {
            $timeResult.NTPServers = $ntpServers
            $timeResult.NTPStatus = ( Get-VAMIServiceAPI -NameFilter "ntp").test(( Get-VAMIServiceAPI -NameFilter "ntp").get()).status
        }
    }
    $timeResult
}

Function Set-VAMITimeSync {
<#
    .NOTES
    ===========================================================================
     Inspired by:   William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
     Created by:    Michael Dunsdon
     Twitter:       @MJDunsdon
     Date:          September 21, 2020
    ===========================================================================
    .SYNOPSIS
        This function sets the time and NTP info from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return current Time and NTP information
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Set-VAMITimeSync -SyncMode "NTP" -TimeZone "US/Pacific" -NTPServers "10.0.0.10,10.0.0.11,10.0.0.12"
    .NOTES
        Create script to Set NTP for Newer VCSA. Script supports 6.7 VCSAs
#>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Disabled', 'NTP', 'Host')]
        [String]$SyncMode,
        [Parameter(Mandatory=$False,HelpMessage="TimeZone Name needs to be in Posix Naming / Unix format")]
        [String]$TimeZone,
        [Parameter(Mandatory=$false,HelpMessage="NTP Servers need to be either a string separated by ',' or an array of servers")]
        $NTPServers
    )

    $timeSyncMode = ( Get-VAMIServiceAPI -NameFilter "timesync").get()
    if ($timeSyncMode.gettype().name -eq "PSCustomObject") {
        if ($SyncMode.ToUpper() -ne $timeSyncMode.mode.toupper()) {
          $timesyncapi = (Get-VAMIServiceAPI -NameFilter "timesync")
          $timesyncconfig = $timesyncapi.help.set.config.createexample()
          $timesyncconfig = $Sync
          $timesyncapi.set($timesyncconfig)
        }
    } else {
        if ($SyncMode.ToUpper() -ne $timeSyncMode.toupper()) {
            $timesyncapi = (Get-VAMIServiceAPI -NameFilter "timesync")
            $timesyncapi.set($Sync)
        }
        if ($NTPServers) {
            $ntpapi = (Get-VAMIServiceAPI -NameFilter "ntp")
            if ($NTPServers.gettype().Name -eq "String") {
                $NTPServersArray = ($NTPServers -split ",").trim()
            } else {
                 $NTPServersArray = $NTPServers
            }
            if ($NTPServersArray -ne $ntpapi.get()) {
                $ntpapi.set($NTPServersArray)
            }
        }
        if ($TimeZone) {
            $timezoneapi = (Get-VAMIServiceAPI -NameFilter "timezone")
            if ($TimeZone -ne ($timezoneapi.get())) {
                $timezoneapi.set($TimeZone)
            }
        }
    }
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
     Date:         September 21, 2020
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

    $Hostname = ( Get-VAMIServiceAPI -NameFilter "dns.hostname").get()
    $dns = (Get-VAMIServiceAPI -NameFilter "dns.servers").get()

    Write-Host "Hostname: " $hostname
    Write-Host "DNS Servers: " $dns.servers

    $interfaces = (Get-VAMIServiceAPI -NameFilter "interfaces").list()
    foreach ($interface in $interfaces) {
        $ipv4API = (Get-VAMIServiceAPI -NameFilter "ipv4")
        if ($ipv4API.help.get.psobject.properties.name -like "*_*") {
            $ipv4result = $ipv4API.get($interface.Name)
            $Updateable = $ipv4result.configurable
        } else {
            $ipv4result = $ipv4API.get(@($interface.Name))
            $Updateable = $ipv4result.updateable
        }
        $interfaceResult = [pscustomobject] @{
            Inteface =  $interface.name;
            MAC = $interface.mac;
            Status = $interface.status;
            Mode = $ipv4result.mode;
            IP = $ipv4result.address;
            Prefix = $ipv4result.prefix;
            Gateway = $ipv4result.default_gateway;
            Updateable = $Updateable
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
    $querySpec.Names = ($monitoringAPI.list() | Where-Object {($_.name -like "*storage.used.filesystem*") -or ($_.name -like "*storage.totalsize.filesystem*") } | Select-Object id | Sort-Object -Property id).id.value

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
    $querySpec.start_time = ((Get-Date).AddDays(-1))
    $querySpec.end_time = (Get-Date)
    $queryResults = $monitoringAPI.query($querySpec) | Select-Object * -ExcludeProperty Help

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
        Write-Host "Starting $Name service ..."
        $vMonAPI.start($Name)
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
        Write-Host "Stopping $Name service ..."
        $vMonAPI.stop($Name)
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

    $userAPI = Get-VAMIServiceAPI -NameFilter "accounts"
    $UserResults = @()

    if (($Name -ne "") -and ($null -ne $Name)) {
        try {
            $Users = $UserAPI.get($name)
        } catch {
            Write-Error $Error[0].exception.Message
        }
    } else {
        $Users = $UserAPI.list()
    }
    if ($Users.status) {
        foreach ($User in $Users) {
            $UserString = [pscustomobject] @{
                User = $User.username
                Name = $User.fullname
                Email = $User.email
                Status = $User.status
                PasswordStatus = $User.passwordstatus
                Roles = @($User.role)
            }
            $UserResults += $UserString
        }
    } else {
        foreach ($User in $Users) {
            $UserInfo = $userAPI.get($user)
            $UserString = [pscustomobject] @{
                User = $User.value
                Name = $UserInfo.fullname
                Email = $UserInfo.email
                Status = $UserInfo.enabled
                LastPasswordChange = $UserInfo.last_password_change
                PasswordExpiresAt = $UserInfo.password_expires_at
                PasswordStatus = if ($UserInfo.has_password) { if ((!!$UserInfo.password_expires_at) -and ([datetime]$UserInfo.password_expires_at -lt (get-date))) {"good"} else {"expired"}} else { "notset"}
                Roles = $UserInfo.roles
            }
            $UserResults += $UserString
        }
    }
    $UserResults
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
     Twitter:       @MJDunsdon
     Date:          September 16, 2020
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
        [String]$Name,
        [Parameter(Mandatory=$true)]
        [String]$FullName,
        [Parameter(Mandatory=$true)]
        [ValidateSet("admin","operator","superAdmin")]
        [String]$Role,
        [Parameter(Mandatory=$false)]
        [String]$Email="",
        [Parameter(Mandatory=$true)]
        [String]$Password,
        [Parameter(Mandatory=$false)]
        [switch]$PasswordExpires,
        [Parameter(Mandatory=$false)]
        [String]$PasswordExpiresAt = $null,
        [Parameter(Mandatory=$false)]
        [String]$MaxPasswordAge = 90
    )

    $userAPI = Get-VAMIServiceAPI -NameFilter "accounts"
    if ($userAPI.name -eq 'com.vmware.appliance.techpreview.localaccounts.user') {
        $CreateSpec = $UserAPI.Help.add.config.CreateExample()
    } else {
        $CreateSpec = $UserAPI.Help.create.config.CreateExample()
    }

    $CreateSpec.fullname = $FullName
    $CreateSpec.role = $Role
    $CreateSpec.email = $Email
    $CreateSpec.password = [VMware.VimAutomation.Cis.Core.Types.V1.Secret]$Password

    if ($CreateSpec.psobject.properties.name -contains "username") {
        $CreateSpec.username = $Name
        try {
            Write-Host "Creating new user $Name ..."
            $UserAPI.add($CreateSpec)
        } catch {
            Write-Error $Error[0].exception.Message
        }
    } else {
        $CreateSpec.password_expires = $PasswordExpires
        $CreateSpec.password_expires_at = $PasswordExpiresAt
        $CreateSpec.max_days_between_password_change = $MaxPasswordAge
        try {
            Write-Host "Creating new user $Name ..."
            $UserAPI.create($Name, $CreateSpec)
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
     Date:         September 21, 2020
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
        [String]$Name,
        [Parameter(Mandatory=$false)]
        [String]$FullName,
        [Parameter(Mandatory=$false)]
        [ValidateSet("admin","operator","superAdmin")]
        [String]$Role,
        [Parameter(Mandatory=$false)]
        [String]$Email="",
        [Parameter(Mandatory=$false)]
        [String]$Password = $null,
        [Parameter(Mandatory=$false)]
        [switch]$PasswordExpires,
        [Parameter(Mandatory=$false)]
        [String]$PasswordExpiresAt = $null,
        [Parameter(Mandatory=$false)]
        [String]$MaxPasswordAge = 90
    )

    $userAPI = Get-VAMIServiceAPI -NameFilter "accounts"
    $UpdateSpec = $UserAPI.Help.set.config.CreateExample()

    $UpdateSpec.fullname = $FullName
    $UpdateSpec.role = $Role
    $UpdateSpec.email = $Email

    if ($UpdateSpec.psobject.properties.name -contains "username") {
        $UpdateSpec.username = $Name
        try {
            Write-Host "Updating Settings for user $Name ..."
            $UserAPI.set($UpdateSpec)
        } catch {
            Write-Error $Error[0].exception.Message
        }
    } else {
        $UpdateSpec.password = [VMware.VimAutomation.Cis.Core.Types.V1.Secret]$Password
        $UpdateSpec.password_expires = $PasswordExpires
        $UpdateSpec.password_expires_at = $PasswordExpiresAt
        $UpdateSpec.max_days_between_password_change = $MaxPasswordAge
        try {
            Write-Host "Updating Settings for user $Name ..."
            $UserAPI.update($Name, $UpdateSpec)
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
     Date:         September 21, 2020
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
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory=$true)]
        [String]$Name
    )
    Begin {}
    Process{
        if($PSCmdlet.ShouldProcess($Name,'Delete')) {
            $userAPI =  Get-VAMIServiceAPI -NameFilter "accounts"
            try {
                Write-Host "Deleting user $name ..."
                $userAPI.delete($name)
            } catch {
                Write-Error $Error[0].exception.Message
            }
        }
    }
    End{}
}

Function Get-VAMIServiceAPI {
<#
    .NOTES
    ===========================================================================
     Inspired by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
     Created by:    Michael Dunsdon
     Twitter:      @MJDunsdon
     Date:         September 21, 2020
    ===========================================================================
    .SYNOPSIS
        This function returns the Service Api Based on a String of Service Name.
    .DESCRIPTION
        Function to find and get service api based on service name string
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIUser -NameFilter "accounts"
    .NOTES
        Script supports 6.5 and 6.7 VCSAs.
        Function Gets all Service Api Names and filters the list based on NameFilter
        If Multiple Serivces are returned it takes the Top one.
#>
    param(
        [Parameter(Mandatory=$true)]
        [String]$NameFilter
    )

    $ServiceAPI = Get-CisService | Where-Object {$_.name -like "*$($NameFilter)*"}
    if (($ServiceAPI.count -gt 1) -and $NameFilter) {
        $ServiceAPI = ($ServiceAPI | Sort-Object -Property Name)[0]
    }
    return $ServiceAPI
}
