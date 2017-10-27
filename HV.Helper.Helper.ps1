<#this is a module designed to complement the Hv.Helper module on Git.
Who knows?! They may even merge someday.
It uses the HorizonView API and the vmware PowerShell from the PS Gallery

Roger P Seekell, 10-20-17, 10-24-17

Goals:
Session
	Get
		Query/filter
		From Machine
        From Session(ID)
	Logoff
		From Session(ID)
		From Machine
	Disconnect
		From Session(ID)
		From Machine
	Reset
		From Session(ID)
		From Machine

Machine
	Restart
	Refresh
	Recompose

Task
	Get
	Restart
    Cancel

#>
#requires -module VMware.VimAutomation.HorizonView
#requires -module VMware.Hv.Helper 

#region initialConnect
if ($hvservices -eq $null) {
    Import-Module VMware.VimAutomation.HorizonView
    Import-Module VMware.Hv.Helper 
    $hvconnection = Connect-HVServer horizon2.jefferson.kyschools.us
    $hvservices = $hvconnection.ExtensionData
}
#endregion

function reset-HVMachine {
<#
.SYNOPSIS
 Given a machine name, sends the command to reset the desktop
.DESCRIPTION
 Roger P Seekell, 10-20-17
.PARAMETER MachineName
 A string of the machine's name to reset; just like in get-HVMachine(Summary)
.OUTPUTS
 None
.NOTES
 The what-if/confirm for MachineID is pretty vague for now
#>
[cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact="medium")]
Param(
    [string]$MachineName,
    [parameter(ValueFromPipelineByPropertyName)][vmware.hv.machineId]$ID
)
process {
if ($ID -ne $null) {
    if ($PSCmdlet.ShouldProcess($ID)) { #user may confirm or use whatIf
        $hvservices.machine.Machine_Reset($ID)
    }
    #else take no action
}
else {
    $myDesktop = Get-HVMachineSummary -MachineName $MachineName
    if ($null -ne $myDesktop) {
        if ($PSCmdlet.ShouldProcess($myDesktop.base.name)) { #user may confirm or use whatIf
            $hvservices.machine.Machine_Reset($myDesktop.Id)
        }
        #else take no action
    }
    else {
        Write-Error "Could not find specified desktop $MachineName to reset it"
    }
}#end else
}#end process
}#end function
#----------------------
function remove-HVMachine {
<#
.SYNOPSIS
 Given a machine name, sends the command to delete the desktop from disk
.DESCRIPTION
 Roger P Seekell, 10-20-17
.PARAMETER MachineName
 A string of the machine's name to remove/delete; just like in get-HVMachine(Summary)
.OUTPUTS
 None
#>
[cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact="medium")]
Param(
    [string]$MachineName
)
$spec = New-Object VMware.Hv.machinedeletespec #required object parameter of delete
$spec.deleteFromDisk=$TRUE #completely delete

$myDesktop = Get-HVMachineSummary -MachineName $MachineName
if ($null -ne $myDesktop) {
    if ($PSCmdlet.ShouldProcess($myDesktop.base.name)) { #user may confirm or use whatIf
        #$hvservices.machine.Machine_Reset($myDesktop.Id)
        $hvservices.machine.machine_delete($myDesktop.id, $spec)
    }
    #else take no action
}
else {
    Write-Error "Could not find specified desktop $MachineName to reset it"
}
}#end function
#----------------------

function logoff-HVMachine {
<#
.SYNOPSIS
 Given a machine name, sends the command to log off the session
.DESCRIPTION
 Roger P Seekell, 10-20-17
.PARAMETER MachineName
 A string of the machine's name to reset; just like in get-HVMachine(Summary)
.OUTPUTS
 None
#>
[cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact="medium")]
Param(
    [string]$MachineName
)
#first get desktop object
$myDesktop = Get-HVMachineSummary -MachineName $MachineName 
if ($null -ne $myDesktop) { #confirm desktop object
    #second, get session off desktop
    $sessionID = $mydesktop.Base.Session
    if ($null -ne $sessionID) { #confirm session ID
        if ($PSCmdlet.ShouldProcess($myDesktop.base.name)) { #user may confirm or use whatIf
            $hvservices.Session.Session_Logoff($sessionID) #send logoff command
        }
        #else take no action
    }
    else {
        Write-Error "Could not get session ID from specified desktop $MachineName; maybe no one is logged on"
    }
}
else {
    Write-Error "Could not find specified desktop $MachineName to log off"
}
}#end function
#----------------------


function get-HVSession {
<#
.SYNOPSIS
 List all sessions on connected Horizon server, up to specified limit
.DESCRIPTION
 Retrives a certain number of session objects from the server; outputs the full object.
 Retrieved on 10-20-17 from http://www.simonlong.co.uk/blog/horizon-view-api/#Quick_View (1. Sessions)
 Adapted by Roger P Seekell, 10-20-17, 10-24, 10-25
.PARAMETER ResultSize
 How many total sessions to return; the server probably limits to 1000
.EXAMPLE
 get-HVSession -ResultSize 20 
 Gets the first 20 sessions, usually in alphabetical order by username
.OUTPUTS
 A VMware.Hv.SessionLocalSummaryView that includes ID, NamesData, ReferenceData, and SessionData
.NOTES
 Don't know how to filter on the server-side, so use your own WHERE-OBJECT conditions to filter the output.
#>
[cmdletBinding()]
Param(
    [int]$ResultSize = 500
)
#required query objects
$query_service = New-Object "Vmware.Hv.QueryServiceService"
$query = New-Object "Vmware.Hv.QueryDefinition"
#specify type of data
$query.queryEntityType = 'SessionLocalSummaryView'
#give size limit of query
$query.Limit = $ResultSize
#conduct the query
$Sessions = $query_service.QueryService_Query($hvservices,$query)
#output results with selected fields
$Sessions.Results
}#end function
#----------------------
function get-HVSessionSummary {
<#
.SYNOPSIS
 List all sessions on connected Horizon server, up to specified limit
.DESCRIPTION
 Retrives a certain number of session objects from the server; outputs selected properties instead of the full object.
 Retrieved on 10-20-17 from http://www.simonlong.co.uk/blog/horizon-view-api/#Quick_View (1. Sessions)
 Adapted by Roger P Seekell, 10-20-17, 10-24-17
.PARAMETER ResultSize
 How many total sessions to return; the server probably limits to 1000
.EXAMPLE
 get-HVSession -ResultSize 20 | sort-object protocol, starttime | format-table
 Gets the first 20 sessions, usually in alphabetical order by username, sorts by protocol then oldest session first, and displays it all in a table view
.EXAMPLE
 Here's one way to reset stale sessions:
 get-HVSessionSummary -ResultSize 200 | where starttime -lt (Get-Date).addHours(-12) -OutVariable oldsess
 $hvservices.Session.Session_ResetSessions($oldsess.SessionId)
 The first command gets all sessions older than twelve hours; the second one uses the API command to reset all the sessions at once, using the SessionId property.
.OUTPUTS
 A Selected.VMware.Hv.SessionLocalSummaryView that includes ClientMacAddress, MachineName, PoolName, Protocol, SessionState, SessionType, StartTime, Duration (script property), and UserName
.NOTES
 Don't know how to filter on the server-side, so use your own WHERE-OBJECT conditions to filter the output.
#>
[cmdletBinding()]
Param(
    [int]$ResultSize = 500
)
#required query objects
$query_service = New-Object "Vmware.Hv.QueryServiceService"
$query = New-Object "Vmware.Hv.QueryDefinition"
#specify type of data
$query.queryEntityType = 'SessionLocalSummaryView'
#give size limit of query
$query.Limit = $ResultSize
#conduct the query
$Sessions = $query_service.QueryService_Query($hvservices,$query)
#output results with selected fields
$Sessions.Results | Select-Object -Property @{l="UserName";e={$_.namesData.UserName}},
    @{l="SessionId";e={$_.ID}},
    @{l="SessionType";e={$_.sessionData.SessionType}},
    @{l="PoolName";e={$_.namesData.DesktopName}}, 
    @{l="MachineName";e={$_.namesData.MachineOrRDSServerName}},
    @{l="ClientMacAddress";e={$_.namesData.ClientLocationID}},
    @{l="StartTime";e={$_.sessionData.StartTime}},
    @{l="SessionState";e={$_.sessionData.SessionState}},
    @{l="Protocol";e={$_.sessionData.SessionProtocol}} | 
    Add-Member -MemberType ScriptProperty -Name Duration -Value {(Get-Date).Subtract($this.StartTime)} -PassThru
}#end function
#----------------------

function enable-HVPool {
<#
.SYNOPSIS
 Activate a pool to create desktops and allow users to log in
.DESCRIPTION
 Given a Pool Name, enables it and provisioning so it starts creating desktops as needed and is accessible to users.
 Uses Set-HVPool to set the Enabled and EnableProvisioning attribute to True
 Roger P Seekell, 10-20-17
.PARAMETER PoolName
 A string of the pool's name to enable and start provisioning; just like in get/set-HVPool
.EXAMPLE
 Enable-HVPool -PoolName VDN-LC-580
 Enables the pool and provisioning on the pool named VDN-LC-580, effective immediately
.OUTPUTS
 None
#>
[cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact="medium")]
Param(
    [parameter(Mandatory)][string]$PoolName    
)
if ($PSCmdlet.ShouldProcess($PoolName)) {
    Set-HVPool -PoolName $PoolName -Key 'desktopSettings.Enabled' -Value $true
    Set-HVPool -PoolName $PoolName -Key 'automatedDesktopData.virtualCenterProvisioningSettings.enableProvisioning' -Value $true
}
#else take no action
}#end function
#----------------------
function disable-HVPool {
<#
.SYNOPSIS
 Deactivate a pool to stop creating desktops and not allow users to log in
.DESCRIPTION
 Given a Pool Name, disables it and provisioning so it stops creating desktops and is no longer accessible to users.
 Uses Set-HVPool to set the Enabled and EnableProvisioning attribute to False
 Roger P Seekell, 10-24-17
.PARAMETER PoolName
 A string of the pool's name to disable and stop provisioning; just like in get/set-HVPool
.EXAMPLE
 Disable-HVPool -PoolName VDN-LC-580
 Disables the pool and provisioning on the pool named VDN-LC-580, effective immediately
.OUTPUTS
 None
#>
[cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact="medium")]
Param(
    [parameter(Mandatory)][string]$PoolName    
)
if ($PSCmdlet.ShouldProcess($PoolName)) {
    Set-HVPool -PoolName $PoolName -Key 'desktopSettings.Enabled' -Value $false
    Set-HVPool -PoolName $PoolName -Key 'automatedDesktopData.virtualCenterProvisioningSettings.enableProvisioning' -Value $false
}
#else take no action
}#end function
#----------------------

function logoff-HVSession {
<#
.SYNOPSIS
 Logs off a given desktop session
.PARAMETER SessionID
 Session ID can be obtained from Get-HVSession > SessionID or Get-HVMachine > Base > Session
.DESCRIPTION
 Given a sessionID, logs off that session "gracefully"
 Supports pipeline by property from get-HVSession
 Roger P Seekell, 10-24-17
.EXAMPLE
 get-HVSession -ResultSize 400 | where username -like "*rseeke1" | logoff-HVSession -Confirm
 Looks through many sessions with this username, and asks before logging off each one
.OUTPUTS
 None
.NOTES
 The what-if/confirm isn't very informative yet
#>
[cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact="medium")]
Param(
    [parameter(ValueFromPipeline)][VMware.Hv.SessionLocalSummaryView]$sessionObj,
    [parameter(ValueFromPipelineByPropertyName)][VMware.Hv.SessionId]$SessionID    
)
process {
    if ($null -eq $sessionObj -and $null -eq $SessionID) {
        Write-Error "Please provide sessionID or SessionLocalSummaryView to logoff a session"
    }
    elseif ($null -ne $sessionObj) {
        #easy to read summary
        $sessionString = $sessionObj.NamesData.UserName + " on " + $sessionObj.NamesData.MachineOrRDSServerName
        if ($PSCmdlet.ShouldProcess($sessionString)) {
            $hvservices.Session.Session_Logoff($sessionObj.Id)
        }
        #else take no action
    }
    elseif ($PSCmdlet.ShouldProcess($SessionID)) {
        $hvservices.Session.Session_Logoff($SessionId)
    }
    #else take no action
}#end process
}#end function
#----------------------
function disconnect-HVSession {
<#
.SYNOPSIS
 Disconnects a given desktop session
.PARAMETER SessionID
 Session ID can be obtained from Get-HVSession > SessionID or Get-HVMachine > Base > Session
.DESCRIPTION
 Given a sessionID, disconnects that session, but it will still run for the specified time limit before logging off
 Supports pipeline by property from get-HVSession
 Roger P Seekell, 10-24-17
.EXAMPLE
 get-HVSession -ResultSize 400 | where username -like "*rseeke1" | disconnect-HVSession -Confirm
 Looks through many sessions with this username, and asks before disconnecting each one
.OUTPUTS
 None
.NOTES
 The what-if/confirm isn't very informative yet
#>
[cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact="medium")]
Param(
    [parameter(ValueFromPipeline)][VMware.Hv.SessionLocalSummaryView]$sessionObj,
    [parameter(ValueFromPipelineByPropertyName)][VMware.Hv.SessionId]$SessionID  
)
process {
    if ($null -eq $sessionObj -and $null -eq $SessionID) {
        Write-Error "Please provide sessionID or SessionLocalSummaryView to disconnect a session"
    }
    elseif ($null -ne $sessionObj) {
        #easy to read summary
        $sessionString = $sessionObj.NamesData.UserName + " on " + $sessionObj.NamesData.MachineOrRDSServerName
        if ($PSCmdlet.ShouldProcess($sessionString)) {
            $hvservices.Session.Session_Disconnect($sessionObj.Id)
        }
        #else take no action
    }
    elseif ($PSCmdlet.ShouldProcess($SessionID)) {
        $hvservices.Session.Session_Disconnect($SessionId)
    }
    #else take no action
}#end process
}#end function
#----------------------
function reset-HVSession {
<#
.SYNOPSIS
 Resets a given desktop session
.PARAMETER SessionID
 Session ID can be obtained from Get-HVSession > SessionID or Get-HVMachine > Base > Session
.DESCRIPTION
 Given a sessionID, resets that session to end it "ungracefully"
 Supports pipeline by property from get-HVSession
 Roger P Seekell, 10-24-17, 10-27
.EXAMPLE
 get-HVSession -ResultSize 400 | where username -like "*rseeke1" | reset-HVSession -Confirm
 Looks through many sessions with this username, and asks before resetting each one
.OUTPUTS
 None
.NOTES
 The what-if/confirm for ID isn't very informative yet
#>
[cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact="medium")]
Param(
    [parameter(ValueFromPipeline)][VMware.Hv.SessionLocalSummaryView]$sessionObj,
    [parameter(ValueFromPipelineByPropertyName)][VMware.Hv.SessionId]$SessionID  
)
process {
    if ($null -eq $sessionObj -and $null -eq $SessionID) {
        Write-Error "Please provide sessionID or SessionLocalSummaryView to reset a session"
    }
    elseif ($null -ne $sessionObj) {
        #easy to read summary
        $sessionString = $sessionObj.NamesData.UserName + " on " + $sessionObj.NamesData.MachineOrRDSServerName
        if ($PSCmdlet.ShouldProcess($sessionString)) {
            $hvservices.Session.Session_Reset($sessionObj.Id)
        }
        #else take no action
    }
    elseif ($PSCmdlet.ShouldProcess($SessionID)) {
        $hvservices.Session.Session_Reset($SessionId)
    }
    #else take no action
}#end process
}#end function
#----------------------
