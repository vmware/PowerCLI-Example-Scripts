<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
Function Connect-SscServer {
<#
  .NOTES
  ===========================================================================
   Created by:	Brian Wuchner
   Date:		November 27, 2021
   Blog:		www.enterpriseadmins.org
   Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    Use this function to create the cookie/header to connect to SaltStack Config RaaS API
  .DESCRIPTION
    This function will allow you to connect to a vRealize Automation SaltStack Config RaaS API.
    A global variable will be set with the Servername & Cookie/Header value for use by other functions.
  .EXAMPLE
    PS C:\> Connect-SscServer -Server 'salt.example.com' -Username 'root' -Password 'VMware1!'
    This will default to internal user authentication.
  .EXAMPLE
    PS C:\> Connect-SscServer -Server 'salt.example.com' -Username 'bwuchner' -Password 'MyPassword1!' -AuthSource 'LAB Directory'
    This will use the 'Lab Directory' LDAP authentication source.
#>
  param(
    [Parameter(Mandatory=$true)][string]$server,
    [Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$password,
    [string]$AuthSource='internal'
  )
  
  $loginBody = @{'username'=$username; 'password'=$password; 'config_name'=$AuthSource}
  try {
    $webRequest = Invoke-WebRequest -Uri "https://$server/account/login" -SessionVariable ws
    $ws.headers.Add('X-Xsrftoken', $webRequest.headers.'x-xsrftoken')
    $webRequest = Invoke-WebRequest -Uri "https://$server/account/login" -WebSession $ws -method POST -body (ConvertTo-Json $loginBody)
    $webRequestJson = ConvertFrom-JSON $webRequest.Content
    $global:DefaultSscConnection = New-Object psobject -property @{ "SscWebSession"=$ws; "SscServer"=$server; "ConnectionDetail"=$webRequestJson }
    
	# Return a few grains, like the Salt server & version; this will prove the connection worked & provide some context
	Get-SscMaster | Select-Object Host, NodeName, SaltVersion, @{N='Authenticated';E={$global:DefaultSscConnection.ConnectionDetail.authenticated}}, 
  @{N='AuthType';E={$global:DefaultSscConnection.ConnectionDetail.attributes.config_driver}}, @{N='AuthSource';E={$global:DefaultSscConnection.ConnectionDetail.attributes.config_name}}, 
  @{N='UserName';E={$global:DefaultSscConnection.ConnectionDetail.attributes.username}}, @{N='Permissions';E={[string]::Join(', ', $global:DefaultSscConnection.ConnectionDetail.attributes.permissions)}}
  } catch {
    Write-Error ("Failure connecting to $server. " + $_)
  } # end try/catch block
}

Function Disconnect-SscServer { 
<#
  .NOTES
  ===========================================================================
   Created by:	Brian Wuchner
   Date:		November 27, 2021
   Blog:		www.enterpriseadmins.org
   Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This function clears a previously created cookie/header used to connect to SaltStack Config
  .DESCRIPTION
    This function will clear the global variable used to connect to the vRealize Automation SaltStack Config RaaS API
  .EXAMPLE
    PS C:\> Disconnect-SscServer
#>
  if ($global:DefaultSscConnection) {
    $global:DefaultSscConnection = $null 
  } else {
    Write-Error 'Could not find an existing connection.'
  } # end if
}

Function Get-SscData {
<#
  .NOTES
  ===========================================================================
   Created by:	Brian Wuchner
   Date:		November 27, 2021
   Blog:		www.enterpriseadmins.org
   Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    Use this function to call the SaltStack Config API.
    Additional helper functions will call this function, this is where the majority of the logic will happen.
  .DESCRIPTION
    This function will pass resource/method/arguments to the vRealize Automation SaltStack Config RaaS API.
    It depends on a global variable created by Connect-SscServer.
  .EXAMPLE
    PS C:\> Get-SscData -Resource 'minions' -Method 'get_minion_cache'
#>
  param(
    [Parameter(Mandatory=$true)][string]$resource,
    [Parameter(Mandatory=$true)][string]$method,
    [System.Collections.Hashtable]$kwarg
  )

  if (!$global:DefaultSscConnection) {
    Write-Error 'You are not currently connected to any servers. Please connect first using Connect-SscServer.'
    return;
  } # end if

  if (!$kwarg) {
    $body = @{'resource'=$resource; 'method'=$method }
  } else {
    $body = @{'resource'=$resource; 'method'=$method; 'kwarg'=$kwarg }
  }

  try{
    $output = Invoke-WebRequest -WebSession $global:DefaultSscConnection.SscWebSession -Method POST -Uri "https://$($global:DefaultSscConnection.SscServer)/rpc" -body $(ConvertTo-Json $body) -ContentType 'application/json'
    return (ConvertFrom-Json $output.Content)
  } catch {
    Write-Error $_.Exception.Message
  }
}


# Lets include a couple sample/helper functions wrappers
Function Get-SscMaster {
<#
  .NOTES
  ===========================================================================
   Created by:	Brian Wuchner
   Date:		November 27, 2021
   Blog:		www.enterpriseadmins.org
   Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will return grain details about the SaltStack Config master node.
  .DESCRIPTION
    This wrapper function will call Get-SscData master.get_master_grains.
  .EXAMPLE
    PS C:\> Get-SscMaster
#>

  param(
    [ValidateSet('Json','Results')][string]$Output='Results'
  )

  $data = Get-SscData master get_master_grains

  if ($Output -eq 'Results') {
    $data.ret.salt.grains
  } else {
    $data
  } # end if for results parameter
}

Function Get-SscMinionCache {
<#
  .NOTES
  ===========================================================================
   Created by:	Brian Wuchner
   Date:		November 27, 2021
   Blog:		www.enterpriseadmins.org
   Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will return the grain property cache of SaltStack Config minions.
  .DESCRIPTION
    This wrapper function will call Get-SscData minions.get_minion_cache.
  .EXAMPLE
    PS C:\> Get-SscMinion
#>
  param(
    [ValidateSet('Json','Results')][string]$Output='Results'
  )

  $data = Get-SscData minions get_minion_cache

  if ($Output -eq 'Results') {
    $data.ret.results
  } else {
    $data
  } # end if for results parameter
}

Function Get-SscJob {
<#
  .NOTES
  ===========================================================================
   Created by:	Brian Wuchner
   Date:		November 27, 2021
   Blog:		www.enterpriseadmins.org
   Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will return configured SatlStack Config jobs.
  .DESCRIPTION
    This wrapper function will call Get-SscData job.get_jobs.
  .EXAMPLE
    PS C:\> Get-SscJob
#>
  param(
    [ValidateSet('Json','Results')][string]$Output='Results'
  )

  $data = Get-SscData job get_jobs

  if ($Output -eq 'Results') {
    $data.ret.results
  } else {
    $data
  } # end if for results parameter
}

Function Get-SscSchedule {
<#
  .NOTES
  ===========================================================================
   Created by:	Brian Wuchner
   Date:		November 27, 2021
   Blog:		www.enterpriseadmins.org
   Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will return schedules for SaltStack Config.
  .DESCRIPTION
    This wrapper function will call Get-SscData schedule.get.
  .EXAMPLE
    PS C:\> Get-SscSchedule
#>
  param(
    [ValidateSet('Json','Results')][string]$Output='Results'
  )

  $data = Get-SscData schedule get

  if ($Output -eq 'Results') {
    $data.ret.results
  } else {
    $data
  } # end if for results parameter
}

Function Get-SscReturn {
<#
  .NOTES
  ===========================================================================
   Created by:	Brian Wuchner
   Date:		November 27, 2021
   Blog:		www.enterpriseadmins.org
   Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will return job results from the job cache based on the provided arguments.
  .DESCRIPTION
    This wrapper function will call Get-SscData ret.get_returns with either Jid or MinionID.
  .EXAMPLE
    PS C:\> Get-SscReturn
  .EXAMPLE
    PS C:\> Get-SscReturn -Jid '20211122160147314949'
  .EXAMPLE
    PS C:\> Get-SscReturn -MinionID 't147-win22-01.lab.enterpriseadmins.org'
#>
  param(
    [ValidateSet('Json','Results')][string]$Output='Results',
  [string]$jid,
  [string]$minionid
  )
  # ToDo: This should be a parameterset, was having trouble with making the parameters optional.  Use if statement for now
  if ($jid -and $minionid) { Write-Warning 'Please only specify JID or MinionID, not both.'; return; }
  
  if ($jid) {
    $kwarg = @{'jid'=$jid}
  } elseif ($minionid) {
    $kwarg = @{'minion_id'=$minionid}
  } else {
    $kwarg = $null
  }
  
  $data = Get-SscData ret get_returns $kwarg

  if ($Output -eq 'Results') {
    $data.ret.results
  } else {
    $data
  } # end if for results parameter
}

Function Get-SscCommand {
<#
  .NOTES
  ===========================================================================
   Created by:	Brian Wuchner
   Date:		November 27, 2021
   Blog:		www.enterpriseadmins.org
   Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will return SaltStack Config commands that have been issued.
  .DESCRIPTION
    This wrapper function will call Get-SscData cmd.get_cmds.
  .EXAMPLE
    PS C:\> Get-SscCommand
#>
  param(
    [ValidateSet('Json','Results')][string]$Output='Results'
  )
  
  $data = Get-SscData cmd get_cmds

  if ($Output -eq 'Results') {
    $data.ret.results
  } else {
    $data
  } # end if for results parameter
}
