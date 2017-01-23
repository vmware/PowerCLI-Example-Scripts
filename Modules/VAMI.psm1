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