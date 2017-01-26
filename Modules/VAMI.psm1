Function Get-VAMISummary {
<#
    .NOTES
    ===========================================================================
     Created by:   	William Lam
     Date:          Jan 20, 2016
     Organization: 	VMware
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

    $summaryResult = "" | Select Product, Type, Version, Build, InstallTime, Uptime
    $summaryResult.Product = $results.product
    $summaryResult.Type = $results.type
    $summaryResult.Version = $results.version
    $summaryResult.Build = $results.build
    $summaryResult.InstallTime = $results.install_time
    $summaryResult.Uptime = $uptime

    $summaryResult
}

Function Get-VAMIHealth {
<#
    .NOTES
    ===========================================================================
     Created by:   	William Lam
     Date:          Jan 20, 2016
     Organization: 	VMware
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

    $healthResult = "" | Select HealthOverall, HealthLastCheck, HealthCPU, HealthMem, HealthSwap, HealthStorage, HealthVCDB, HealthSoftware
    $healthResult.HealthOverall = $healthOverall
    $healthResult.HealthLastCheck = $healthLastCheck
    $healthResult.HealthCPU = $healthCPU
    $healthResult.HealthMem = $healthMem
    $healthResult.HealthSwap = $healthSwap
    $healthResult.HealthStorage = $healthStorage
    $healthResult.HealthVCDB = $healthVCDB
    $healthResult.HealthSoftware = $healthSoftwareUpdates

    $healthResult
}

Function Get-VAMIAccess {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
     Date:          Jan 25, 2016
	 Organization: 	VMware
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

    $accessResult = "" | Select Console, DCUI, BashShell, SSH
    $accessResult.Console = $consoleAccess
    $accessResult.DCUI = $dcuiAccess
    $accessResult.BashShell = $shellAccess.enabled
    $accessResult.SSH = $sshAccess

    $accessResult
}