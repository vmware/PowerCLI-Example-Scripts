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
            $NTPService = $MyHost | Get-VMHostService | Where-Object {$_.key -eq "ntpd"}  
            ## Stop NTP Service if running           
            if($NTPService.Running -eq $True){
                Stop-VMHostService -HostService $NTPService -Confirm:$false | Out-Null
            }
            ## Enable NTP Service
            if($NTPService.Policy -ne "on"){
                Set-VMHostService -HostService $NTPService -Policy "on" -confirm:$False | Out-Null
            }
            ## Remove all existiing NTP Servers
            try {
                foreach ($OldNtpServer in ($MyHost | Get-VMHostNtpServer)) {
                    $MyHost | Remove-VMHostNtpServer -NtpServer $OldNtpServer -Confirm:$false
                }
            }
            catch [System.Exception] {
                Write-Warning "Error during removing existing NTP Servers on Host '$($MyHost.Name)'."
            }
            ## Set New NTP Servers
            foreach ($myNTP in $NTP) {
                $MyHost | Add-VMHostNtpServer -ntpserver $myNTP -confirm:$False | Out-Null
            }
            ## Set Current time on Host
            $HostTimeSystem = Get-View $MyHost.ExtensionData.ConfigManager.DateTimeSystem
            $HostTimeSystem.UpdateDateTime([DateTime]::UtcNow)
            ## Start NTP Service
            Start-VMHostService -HostService $NTPService -confirm:$False | Out-Null
            ## Get NTP CLient Forewall Rule
            $esxcli = Get-ESXCLI -VMHost $MyHost -v2
            $esxcliargs = $esxcli.network.firewall.ruleset.rule.list.CreateArgs()
            $esxcliargs.rulesetid = "ntpClient"
            try {
                $esxcli.network.firewall.ruleset.rule.list.Invoke($esxcliargs)
                }
                catch [System.Exception]  {
                    Write-Warning "Error during Rule List. See latest errors..."
                }
            ## Set NTP Client Firewall Rule
            $esxcliargs = $esxcli.network.firewall.ruleset.set.CreateArgs()
            $esxcliargs.enabled = "true"
            $esxcliargs.allowedall = "false"
            $esxcliargs.rulesetid = "ntpClient"
            try {
                $esxcli.network.firewall.ruleset.set.Invoke($esxcliargs)
                }
                catch [System.Exception]  {
                    Write-Warning "Error during Rule Set. See latest errors..."
                }
            ## Set NTP Client Firewall Rule AllowedIP
            foreach ($myNTP in $NTP) {
                $esxcliargs = $esxcli.network.firewall.ruleset.allowedip.add.CreateArgs()
                $esxcliargs.ipaddress = $myNTP
                $esxcliargs.rulesetid = "ntpClient"
                try {
                    $esxcli.network.firewall.ruleset.allowedip.add.Invoke($esxcliargs)
                }
                catch [System.Exception]  {
                    Write-Warning "Error during Rule Update. See latest errors..."
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