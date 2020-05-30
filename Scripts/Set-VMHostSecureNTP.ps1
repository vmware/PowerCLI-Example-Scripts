function Set-VMHostSecureNTP {
<#	
    .NOTES
    ===========================================================================
    Created by: Markus Kraus
    ===========================================================================
    Changelog:  
    2020.05 ver 1.0 Base Release  
    ===========================================================================
    External Code Sources: 
    -
    ===========================================================================
    Tested Against Environment:
    vSphere Version: vSphere 6.7 U3
    PowerCLI Version: PowerCLI 11.5
    PowerShell Version: 5.1
    OS Version: Windows 10
    Keyword: ESXi, NTP, Hardening, Security, Firewall 
    ===========================================================================

    .DESCRIPTION
    This function sets new NTP Servers on given ESXi Hosts and configures the host firewall to only accept NTP connections from these servers.

    .Example
    Get-VMHost | Set-VMHostSecureNTP -Secure

    .Example
    Get-VMHost | Set-VMHostSecureNTP -Type SetSecure -NTP 10.100.1.1, 192.168.2.1

    .PARAMETER VMHost
    Specifies the hosts to configure

    .PARAMETER SetSecure
    Execute Set and Secure operation for new NTP Servers

    .PARAMETER NTP
    Specifies a Array of NTP Servers

    .PARAMETER Secure
    Execute Secure operation for exitsting NTP Servers

#Requires PS -Version 5.1
#Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="11.5.0.0"}
#>

    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage = "Specifies the hosts to configure.")]
            [ValidateNotNullorEmpty()]
            [VMware.VimAutomation.Types.VMHost[]] $VMHost,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, ParameterSetName="SetSecure", HelpMessage = "Execute Set and Secure operation for new NTP Servers")]
            [Switch] $SetSecure,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False,  ParameterSetName="SetSecure", HelpMessage = "Specifies a Array of NTP Servers")]
            [ValidateNotNullorEmpty()] 
            [ipaddress[]] $NTP,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, ParameterSetName="Secure", HelpMessage = "Execute Secure operation for exitsting NTP Servers")]
            [Switch] $Secure

    )
    
    begin {

        function SetNTP ($MyHost) {
            ## Get NTP Service 
            "Get NTP Service from VMHost ..." 
            $NTPService = $MyHost | Get-VMHostService | Where-Object {$_.key -eq "ntpd"}  
            ## Stop NTP Service if running   
            "Stop NTP Service if running  ..."        
            if($NTPService.Running -eq $True){
                Stop-VMHostService -HostService $NTPService -Confirm:$false | Out-Null
            }
            ## Enable NTP Service
            "Enable NTP Service if disabled..."
            if($NTPService.Policy -ne "on"){
                Set-VMHostService -HostService $NTPService -Policy "on" -confirm:$False | Out-Null
            }
            ## Remove all existing NTP Servers
            "Remove all existing NTP Servers ..."
            try {
                $MyHost | Get-VMHostNtpServer | Foreach-Object {
                    Remove-VMHostNtpServer -VMHost $MyHost -NtpServer $_ -Confirm:$false
                }
            }
            catch [System.Exception] {
                Write-Warning "Error during removing existing NTP Servers on Host '$($MyHost.Name)'."
            }
            ## Set New NTP Servers
            "Set New NTP Servers ..."
            foreach ($myNTP in $NTP) {
                $MyHost | Add-VMHostNtpServer -ntpserver $myNTP -confirm:$False | Out-Null
            }
            ## Set Current time on Host
            "Set Current time on VMHost ..."
            $HostTimeSystem = Get-View $MyHost.ExtensionData.ConfigManager.DateTimeSystem
            $HostTimeSystem.UpdateDateTime([DateTime]::UtcNow)
            ## Start NTP Service
            "Start NTP Service ..."
            Start-VMHostService -HostService $NTPService -confirm:$False | Out-Null
            ## Get New NTP Servers
            "Get New NTP Servers ..."
            $NewNTPServers = $MyHost | Get-VMHostNtpServer
            "`tNew NTP Servers: $($NewNTPServers -join ", ")"    

        }

        function SecureNTP ($MyHost) {
            ## Get NTP Servers
            "Get NTP Servers to Secure ..."
            [Array]$CurrentNTPServers = $MyHost | Get-VMHostNtpServer
            "`tNTP Servers: $($CurrentNTPServers -join ", ")"
            ## Get ESXCLI -V2
            $esxcli = Get-ESXCLI -VMHost $MyHost -v2
            ## Get NTP Client Firewall
            "Get NTP Client Firewall ..."
            try {
                $FirewallGet = $esxcli.network.firewall.get.Invoke()
            }
            catch [System.Exception]  {
                Write-Warning "Error during Rule List. See latest errors..."
            }
            "`tLoded: $($FirewallGet.Loaded)"
            "`tEnabled: $($FirewallGet.Enabled)"
            "`tDefaultAction: $($FirewallGet.DefaultAction)"
            ## Get NTP Client Firewall Rule
            "Get NTP Client Firewall RuleSet ..."
            $esxcliargs = $esxcli.network.firewall.ruleset.list.CreateArgs()
            $esxcliargs.rulesetid = "ntpClient"
            try {
                $FirewallRuleList = $esxcli.network.firewall.ruleset.list.Invoke($esxcliargs)
            }
            catch [System.Exception]  {
                Write-Warning "Error during Rule List. See latest errors..."
            }
            "`tEnabled: $($FirewallRuleList.Enabled)"
            ## Set NTP Client Firewall Rule
            "Set NTP Client Firewall Rule ..."
            $esxcliargs = $esxcli.network.firewall.ruleset.set.CreateArgs()
            $esxcliargs.enabled = "true" 
            $esxcliargs.allowedall = "false"
            $esxcliargs.rulesetid = "ntpClient"
            try {
                $esxcli.network.firewall.ruleset.set.Invoke($esxcliargs)
            }
            catch [System.Exception]  {
                $ErrorMessage = $_.Exception.Message
                if ($ErrorMessage -ne "Already use allowed ip list") {
                    Write-Warning "Error during Rule Set. See latest errors..."

                }

            }
            "Get NTP Client Firewall Rule AllowedIP ..."
            $esxcliargs = $esxcli.network.firewall.ruleset.allowedip.list.CreateArgs()
            $esxcliargs.rulesetid = "ntpClient"
            try {
                $FirewallRuleAllowedIPList = $esxcli.network.firewall.ruleset.allowedip.list.Invoke($esxcliargs)
            }
            catch [System.Exception]  {
                Write-Warning "Error during Rule List. See latest errors..."
            }
            "`tAllowed IP Addresses: $($FirewallRuleAllowedIPList.AllowedIPAddresses -join ", ")"    
            ## Remove Existing IP from firewall rule
            "Remove Existing IP from firewall rule ..."
            if ($FirewallRuleAllowedIPList.AllowedIPAddresses -ne "All") {
                foreach ($IP in $FirewallRuleAllowedIPList.AllowedIPAddresses) {
                    $esxcliargs = $esxcli.network.firewall.ruleset.allowedip.remove.CreateArgs()
                    $esxcliargs.rulesetid = "ntpClient"
                    $esxcliargs.ipaddress = $IP
                    try {
                        $esxcli.network.firewall.ruleset.allowedip.remove.Invoke($esxcliargs)
                    }
                    catch [System.Exception]  {
                        Write-Warning "Error during AllowedIP remove. See latest errors..."
                    }
                }
                
            }
            ## Set NTP Client Firewall Rule AllowedIP
            "Set NTP Client Firewall Rule AllowedIP ..."
            foreach ($myNTP in $CurrentNTPServers) {
                $esxcliargs = $esxcli.network.firewall.ruleset.allowedip.add.CreateArgs()
                $esxcliargs.ipaddress = $myNTP
                $esxcliargs.rulesetid = "ntpClient"
                try {
                    $esxcli.network.firewall.ruleset.allowedip.add.Invoke($esxcliargs)
                }
                catch [System.Exception]  {
                    $ErrorMessage = $_.Exception.Message
                    if ($ErrorMessage -ne "Ip address already exist.") {
                        Write-Warning "Error during AllowedIP remove. See latest errors..."
                    }
                }             
            }
            ## Get New NTP Client Firewall Rule AllowedIP
            "Get New NTP Client Firewall Rule AllowedIP ..."
            $esxcliargs = $esxcli.network.firewall.ruleset.allowedip.list.CreateArgs()
            $esxcliargs.rulesetid = "ntpClient"
            try {
                $FirewallRuleAllowedIPList = $esxcli.network.firewall.ruleset.allowedip.list.Invoke($esxcliargs)
            }
            catch [System.Exception]  {
                Write-Warning "Error during Rule List. See latest errors..."
            }
            "`tNew Allowed IP Addresses: $($FirewallRuleAllowedIPList.AllowedIPAddresses -join ", ")"    
            
            
        }
        
    }
    
    process {
        
        if ($SetSecure) {
            "Execute Set and Secure operation for new NTP Servers ..."
            $VMHost | Foreach-Object { Write-Output (SetNTP $_) }
            $VMHost | Foreach-Object { Write-Output (SecureNTP $_) }
        }
        if ($Secure) {
            "Execute Secure operation for exitsting NTP Servers ..."
            $VMHost | Foreach-Object { Write-Output (SecureNTP $_) }
        }
        
    }

}