function Konfig-ESXi {
<#	
    .NOTES
    ===========================================================================
    Created by: Markus Kraus
    Twitter: @VMarkus_K
    Private Blog: mycloudrevolution.com
    ===========================================================================
    Changelog:  
    2016.12 ver 1.0 Base Release
    2016.12 ver 1.1 ESXi 6.5 Tests, Minor enhancements  
    ===========================================================================
    External Code Sources: 
    Function My-Logger : http://www.virtuallyghetto.com/
    ===========================================================================
    Tested Against Environment:
    vSphere Version: ESXi 5.5 U2, ESXi 6.5
    PowerCLI Version: PowerCLI 6.3 R1, PowerCLI 6.5 R1
    PowerShell Version: 4.0, 5.0
    OS Version: Windows 8.1, Server 2012 R2
    Keyword: ESXi, NTP, SSH, Syslog, SATP, 
    ===========================================================================

    .DESCRIPTION
    This Function sets the Basic settings for a new ESXi.

    * NTP
    * SSH
    * Syslog
    * Power Management
    * HP 3PAR SATP/PSP Rule
    * ... 

    .Example
    Konfig-ESXi -VMHost myesxi.lan.local -NTP 192.168.2.1, 192.168.2.2 -syslog "udp://loginsight.lan.local:514"

    .PARAMETER VMHost
    Host to configure.

    .PARAMETER NTP
    NTP Server(s) to set.

    .PARAMETER Syslog
    Syslog Server to set, e.g. "udp://loginsight.lan.local:514"

    DNS Name must be resolvable!


#Requires PS -Version 4.0
#Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="6.3.0.0"}
#>

[CmdletBinding()]
param( 
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, Position=0)]
        [String] $VMHost,
    [Parameter(Mandatory=$true, ValueFromPipeline=$False, Position=1)]
        [array]$NTP,
    [Parameter(Mandatory=$true, ValueFromPipeline=$False, Position=2)]
        [String] $syslog
        
)

Begin {
    Function My-Logger {
        param(
        [Parameter(Mandatory=$true)]
        [String]$message
        )

        $timeStamp = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"

        Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
        Write-Host -ForegroundColor Green " $message"
    }
    function Set-MyESXiOption {
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, Position=0)]
            [String] $Name,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, Position=1)]
            [String] $Value     
    )
    process {
        $myESXiOption = Get-AdvancedSetting -Entity $ESXiHost -Name $Name
        if ($myESXiOption.Value -ne $Value) {
            My-Logger "    Setting ESXi Option $Name to Value $Value"
            $myESXiOption | Set-AdvancedSetting -Value $Value -Confirm:$false | Out-Null
        }
        else {
            My-Logger "    ESXi Option $Name already has Value $Value"
        } 
    }
    }
}

Process {
    $Validate = $True

    #region: Start vCenter Connection
    My-Logger "Starting to Process ESXi Server Connection to $VMHost ..."
    if (($global:DefaultVIServers).count -gt 0) {
       Disconnect-VIServer  -Force -Confirm:$False -ErrorAction SilentlyContinue 
    }
    $VIConnection = Connect-VIServer -Server $VMHost
    if (-not $VIConnection.IsConnected) {
        Write-Error "ESXi Connection Failed."
        $Validate = $False
    }
    elseif ($VIConnection.ProductLine -ne "EmbeddedEsx") {
        Write-Error "Connencted System is not an ESXi."
        $Validate = $False
    }
    else {
        $ESXiHost = Get-VMHost
        My-Logger "Connected ESXi Version: $($ESXiHost.Version) $($ESXiHost.Build) "
    }
    #endregion

    if ($Validate -eq $True) {
        
        #region: Enable SSH and disable SSH Warning
        $SSHService = $ESXiHost | Get-VMHostService | where {$_.Key -eq 'TSM-SSH'} 
        My-Logger "Starting SSH Service..."
        if($SSHService.Running -ne $True){
            Start-VMHostService -HostService $SSHService -Confirm:$false | Out-Null
        }
        else {
            My-Logger "    SSH Service is already running"
        }
        My-Logger "Setting SSH Service to Automatic Start..."
        if($SSHService.Policy -ne "automatic"){
            Set-VMHostService -HostService $SSHService -Policy "Automatic" | Out-Null
        }
        else {
            My-Logger "    SSH Service is already set to Automatic Start"
        }
        My-Logger "Disabling SSH Warning..."
        Set-MyESXiOption -Name "UserVars.SuppressShellWarning" -Value "1"
        #endregion

        #region: Config NTP
        My-Logger "Removing existing NTP Server..." 
        try {
            $ESXiHost | Remove-VMHostNtpServer -NtpServer (Get-VMHostNtpServer) -Confirm:$false 
        }
        catch [System.Exception] {
            Write-Warning "Error during removing existing NTP Servers."    
        }
        My-Logger "Setting new NTP Servers..."
        foreach ($myNTP in $NTP) {
            $ESXiHost | Add-VMHostNtpServer -ntpserver $myNTP -confirm:$False | Out-Null
        }

        My-Logger "Configure NTP Service..."
        $NTPService = $ESXiHost | Get-VMHostService| Where-Object {$_.key -eq "ntpd"}
        if($NTPService.Running -eq $True){ 
            Stop-VMHostService -HostService $NTPService -Confirm:$false | Out-Null
        }
        if($NTPService.Policy -ne "on"){ 
            Set-VMHostService -HostService $NTPService -Policy "on" -confirm:$False | Out-Null
        }

        My-Logger "Configure Local Time..."
        $HostTimeSystem = Get-View $ESXiHost.ExtensionData.ConfigManager.DateTimeSystem 
        $HostTimeSystem.UpdateDateTime([DateTime]::UtcNow) 

        My-Logger "Start NTP Service..."
        Start-VMHostService -HostService $NTPService -confirm:$False | Out-Null
        #endregion

        #region: Remove default PG
        My-Logger "Checking for Default Port Group ..."
        if ($defaultPG = $ESXiHost | Get-VirtualSwitch -Name vSwitch0 | Get-VirtualPortGroup -Name "VM Network" -ErrorAction SilentlyContinue ){
            Remove-VirtualPortGroup -VirtualPortGroup $defaultPG -confirm:$False | Out-Null
            My-Logger "    Default PG Removed"
        }
        else {
            My-Logger "    No Default PG found"
        }
        #endregion

        #region: Configure Static HighPower
        My-Logger "Setting PowerProfile to Static HighPower..." 
        try {
            $HostView = ($ESXiHost | Get-View)
            (Get-View $HostView.ConfigManager.PowerSystem).ConfigurePowerPolicy(1)
        }
        catch [System.Exception] {
            Write-Warning "Error during Configure Static HighPower. See latest errors..."    
        }
        #endregion
        
        #region: Conf Syslog
        My-Logger "Setting Syslog Firewall Rule ..."
        $SyslogFW = ($ESXiHost | Get-VMHostFirewallException | where {$_.Name -eq 'syslog'})
        if ($SyslogFW.Enabled -eq $False ){
            $SyslogFW | Set-VMHostFirewallException -Enabled:$true -Confirm:$false | Out-Null
            My-Logger "  Syslog Firewall Rule enabled"
        }
        else {
            My-Logger "  Syslog Firewall Rule already enabled"
        }
        My-Logger "Setting Syslog Server..."
        Set-MyESXiOption -Name "Syslog.global.logHost" -Value $syslog
        #endregion

        #region: Change Disk Scheduler
        My-Logger "Changing Disk Scheduler..."
        Set-MyESXiOption -Name "Disk.SchedulerWithReservation" -Value "0"
        #endregion

        #region: Configure HP 3PAR SATP/PSP Rule
        My-Logger "Configure HP 3PAR SATP/PSP Rule"
        $esxcli2 = Get-ESXCLI -VMHost $ESXiHost -V2
        $arguments = $esxcli2.storage.nmp.satp.rule.add.CreateArgs()
        $arguments.satp = "VMW_SATP_ALUA"
        $arguments.psp = "VMW_PSP_RR"
        $arguments.pspoption = "iops=100"
        $arguments.claimoption = "tpgs_on"
        $arguments.vendor = "3PARdata"
        $arguments.model = "VV"
        $arguments.description = "HP 3PAR custom SATP Claimrule"
        try {
            $esxcli2.storage.nmp.satp.rule.add.Invoke($arguments)
        }
        catch {
             Write-Warning "Error during Configure HP 3PAR SATP/PSP Rule. See latest errors..."  
        }
		#endregion

    }
    }
}
