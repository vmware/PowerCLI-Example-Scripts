function Set-VMHostSecureNTP {
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage = "Specifies the hosts to configure.")]
            [ValidateNotNullorEmpty()]
            [VMware.VimAutomation.Types.VMHost[]] $VMHost,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, Position=1, HelpMessage = "Type of confugration")]
            [ValidateSet("SetSecure","Secure")]
            [String] $Type = "SetSecure",
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, Position=2, HelpMessage = "Array of NTP Serbers")]
            [ValidateNotNullorEmpty()] 
            [Array] $NTP   
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
            "Get NTP Client Firewall Rule AllowedIP ..."
            $esxcliargs = $esxcli.network.firewall.ruleset.allowedip.list.CreateArgs()
            $esxcliargs.rulesetid = "ntpClient"
            try {
                $FirewallRuleAllowedIPList = $esxcli.network.firewall.ruleset.allowedip.list.Invoke($esxcliargs)
                }
                catch [System.Exception]  {
                    Write-Warning "Error during Rule List. See latest errors..."
                }
            "`tAllowed IP Addresses: $($FirewallRuleAllowedIPList.AllowedIPAddresses)"
            ## Remove Existing IP from firewall rule
            ## BUG: If AllowedIP was enabled and is disabled now, old IPs will not be removed
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
            ## Set NTP Client Firewall Rule
            "Set NTP Client Firewall Rule ..."
            if ($FirewallRuleList.Enabled -ne $True -or $FirewallRuleAllowedIPList.AllowedIPAddresses -eq "All") {
                $esxcliargs = $esxcli.network.firewall.ruleset.set.CreateArgs()
                if ($FirewallRuleList.Enabled -ne $True) {
                    $esxcliargs.enabled = "true" 
                }
                if ($FirewallRuleAllowedIPList.AllowedIPAddresses -eq "All") {
                    $esxcliargs.allowedall = "false"
                }
                $esxcliargs.rulesetid = "ntpClient"
                try {
                    $esxcli.network.firewall.ruleset.set.Invoke($esxcliargs)
                    }
                    catch [System.Exception]  {
                        Write-Warning "Error during Rule Set. See latest errors..."
                    }
            }
            ## Set NTP Client Firewall Rule AllowedIP
            ### BUG: If AllowedIP was enabled and is disabled now, a duplicate Ip Cannot be added --> Workarund done
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
                    if ($ErrorMessage -eq "Ip address already exist.") {
                     
                        $esxcliargs = $esxcli.network.firewall.ruleset.allowedip.list.CreateArgs()
                        $esxcliargs.rulesetid = "ntpClient"
                        try {
                            $FirewallRuleAllowedIPList = $esxcli.network.firewall.ruleset.allowedip.list.Invoke($esxcliargs)
                            }
                            catch [System.Exception]  {
                                Write-Warning "Error during Rule List. See latest errors..."
                            }
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
                            $esxcliargs = $esxcli.network.firewall.ruleset.allowedip.add.CreateArgs()
                            $esxcliargs.ipaddress = $myNTP
                            $esxcliargs.rulesetid = "ntpClient"
                            try {
                                $esxcli.network.firewall.ruleset.allowedip.add.Invoke($esxcliargs)
                            }
                            catch [System.Exception]  {
                                Write-Warning "Error during Rule AllowedIP Update. '$ErrorMessage' See latest errors..."

                            }
            
                    }
                }             
            }
        }
        
    }
    
    process {
        
        if ($Type -eq "SetSecure") {
            "Executing Set and Secure operation..."
            $VMHost | Foreach-Object { Write-Output (SetSecure $_) }
        }
        
    }
    
    end {
        
    }
}