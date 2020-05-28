function Set-VMHostSecureNTP {
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, HelpMessage = "Specifies the hosts to configure.")]
            [ValidateNotNullorEmpty()]
            [VMware.VimAutomation.Types.VMHost[]] $VMHost,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, ParameterSetName="SetSecure", HelpMessage = "Execute Set and Secure operation for new NTP Servers")]
            [Switch] $SetSecure,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False,  ParameterSetName="SetSecure", HelpMessage = "Array of NTP Serbers")]
            [ValidateNotNullorEmpty()] 
            [Array] $NTP,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, ParameterSetName="SetSecure", HelpMessage = "Execute Secure operation for exitsting NTP Servers")]
            [Switch] $Secure

    )
    
    begin {

        function SetSecure ($MyHost) {
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
            ## Remove all existiing NTP Servers
            "Remove all existiing NTP Servers ..."
            try {
                foreach ($OldNtpServer in ($MyHost | Get-VMHostNtpServer)) {
                    $MyHost | Remove-VMHostNtpServer -NtpServer $OldNtpServer -Confirm:$false
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
            foreach ($myNTP in $NTP) {
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
            ## Get New NTP Servers
            "Get New NTP Servers ..."
            $NewNTPServers = $MyHost | Get-VMHostNtpServer
            "`tNew NTP Servers: $($NewNTPServers -join ", ")"    

        }
        
    }
    
    process {
        
        if ($SetSecure) {
            "Execute Set and Secure operation for new NTP Servers ..."
            $VMHost | Foreach-Object { Write-Output (SetSecure $_) }
        }
        if ($Secure) {
            "Execute Secure operation for exitsting NTP Servers ..."
            $VMHost | Foreach-Object { Write-Output (Secure $_) }
        }
        
    }
    
    end {
        
    }
}