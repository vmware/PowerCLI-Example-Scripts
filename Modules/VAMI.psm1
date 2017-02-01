Function Get-VAMISummary {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Jan 20, 2016
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
    $results = $systemVersionAPI.get() | select product, type, version, build, install_time

    $systemUptimeAPI = Get-CisService -Name 'com.vmware.appliance.system.uptime'
    $ts = [timespan]::fromseconds($systemUptimeAPI.get().toString())
    $uptime = $ts.ToString("hh\:mm\:ss\,fff")

    $summaryResult = New-Object PSObject -Property @{
        Product = $results.product;
        Type = $results.type;
        Version = $results.version;
        Build = $results.build;
        InstallTime = $results.install_time;
        Uptime = $uptime
    }
    $summaryResult
}

Function Get-VAMIHealth {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Jan 25, 2016
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

    $healthResult = New-Object PSObject -Property @{
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
     Date:          Jan 26, 2016
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
        SSH = $sshAccess
    }
    $accessResult
}

Function Get-VAMITime {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Jan 27, 2016
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
		This function retrieves the time and NTP info from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
		Function to return current Time and NTP information
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMITime
#>
    $systemTimeAPI = Get-CisService -Name 'com.vmware.appliance.system.time'
    $timeResults = $systemTimeAPI.get()

    $timeSync = (Get-CisService -Name 'com.vmware.appliance.techpreview.timesync').get()
    $timeSyncMode = $timeSync.mode

    $timeResult  = New-Object PSObject -Property @{
        Timezone = $timeResults.timezone;
        Date = $timeResults.date;
        CurrentTime = $timeResults.time;
        Mode = $timeSyncMode;
        NTPServers = "N/A";
        NTPStatus = "N/A";
    }

    if($timeSyncMode -eq "NTP") {
        $ntpServers = (Get-CisService -Name 'com.vmware.appliance.techpreview.ntp').get()
        $timeResult.NTPServers = $ntpServers.servers
        $timeResult.NTPStatus = $ntpServers.status
    }
    $timeResult
}

Function Get-VAMINetwork {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Jan 31, 2016
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
		This function retrieves network information from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
		Function to return networking information including details for each interface
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMINetwork
#>
    $netResults = @()

    $Hostname = (Get-CisService -Name 'com.vmware.appliance.networking.dns.hostname').get()
    $dns = (Get-CisService -Name 'com.vmware.appliance.networking.dns.servers').get()

    Write-Host "Hostname: " $hostname
    Write-Host "DNS Servers: " $dns.servers

    $interfaces = (Get-CisService -Name 'com.vmware.appliance.networking.interfaces').list()
    foreach ($interface in $interfaces) {
        $ipv4API = (Get-CisService -Name 'com.vmware.appliance.techpreview.networking.ipv4')
        $spec = $ipv4API.Help.get.interfaces.CreateExample()
        $spec+= $interface.name
        $ipv4result = $ipv4API.get($spec)

        $interfaceResult = New-Object PSObject -Property @{
            Inteface =  $interface.name;
            MAC = $interface.mac;
            Status = $interface.status;
            Mode = $ipv4result.mode;
            IP = $ipv4result.address;
            Prefix = $ipv4result.prefix;
            Gateway = $ipv4result.default_gateway;
            Updateable = $ipv4result.updateable
        }
        $netResults += $interfaceResult
    }
    $netResults
}