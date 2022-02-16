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
  .EXAMPLE
    PS C:\> Connect-SscServer -Server 'salt.example.com'
    This will prompt for credentials
  .EXAMPLE
    $creds = Get-Credential
    PS C:\> Connect-SscServer -Server 'salt.example.com' -Credential $creds -AuthSource 'LAB Directory'
    This will connect to the 'LAB Directory' LDAP authentication source using a specified credential.
#>
  param(
    [Parameter(Mandatory=$true, Position=0)][string]$server,
    [Parameter(Mandatory=$true, ParameterSetName='PlainText', Position=1)][string]$username,
    [Parameter(Mandatory=$true, ParameterSetName='PlainText', Position=2)][ValidateNotNullOrEmpty()][string]$password,
    [Parameter(Mandatory=$false, Position=3)][string]$AuthSource='internal',
    [Parameter(Mandatory=$false, ParameterSetName='Credential')][PSCredential]$Credential,
    [Parameter(Mandatory=$false)][Switch]$SkipCertificateCheck,
    [Parameter(Mandatory=$false)][System.Net.SecurityProtocolType]$SslProtocol
  )

  if ($PSCmdlet.ParameterSetName -eq 'Credential' -AND $Credential -eq $null) { $Credential = Get-Credential}
  if ($Credential) {
    $username = $Credential.GetNetworkCredential().username
    $password = $Credential.GetNetworkCredential().password
  }

  if ($SkipCertificateCheck) {
    # This if statement is using example code from https://stackoverflow.com/questions/11696944/powershell-v3-invoke-webrequest-https-error
    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
  } # end if SkipCertificate Check
  
  if ($SslProtocol) {
    [System.Net.ServicePointManager]::SecurityProtocol = $SslProtocol
  }

  $loginBody = @{'username'=$username; 'password'=$password; 'config_name'=$AuthSource}
  try {
    $webRequest = Invoke-WebRequest -Uri "https://$server/account/login" -SessionVariable ws
    $ws.headers.Add('X-Xsrftoken', $webRequest.headers.'x-xsrftoken')
    $webRequest = Invoke-WebRequest -Uri "https://$server/account/login" -WebSession $ws -method POST -body (ConvertTo-Json $loginBody)
    $webRequestJson = ConvertFrom-JSON $webRequest.Content
    $global:DefaultSscConnection = New-Object psobject -property @{ 'SscWebSession'=$ws; 'Name'=$server; 'ConnectionDetail'=$webRequestJson; 
      'User'=$webRequestJson.attributes.config_name +'\'+ $username; 'Authenticated'=$webRequestJson.authenticated; PSTypeName='SscConnection' }
    
	  # Return the connection object
	  $global:DefaultSscConnection
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
    $jsonBody = $(ConvertTo-Json $body -Depth 4 -Compress )
    write-debug "JSON Body: $jsonBody"
    $output = Invoke-WebRequest -WebSession $global:DefaultSscConnection.SscWebSession -Method POST -Uri "https://$($global:DefaultSscConnection.Name)/rpc" -body $jsonBody -ContentType 'application/json'
    $outputJson = (ConvertFrom-Json $output.Content)

    if ($outputJson.error) { Write-Error $outputJson.error }
    if ($outputJson.warnings) { Write-Warning $outputJson.warnings }
    return $outputJson.ret

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

  (Get-SscData master get_master_grains).salt.grains
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

  (Get-SscData minions get_minion_cache).results
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

  (Get-SscData job get_jobs).results
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

  (Get-SscData schedule get).results
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
  .EXAMPLE
    PS C:\> Get-SscReturn -MinionID 't147-win22-01.lab.enterpriseadmins.org' -Jid '20211122160147314949'
#>
  param(
    [string]$jid,
    [string]$MinionID
  )
  
  $kwarg = @{}
  if ($jid) { $kwarg += @{'jid'=$jid} }
  if ($MinionID) { $kwarg += @{'minion_id'=$MinionID} }
  
  (Get-SscData ret get_returns $kwarg).results
}

Function Get-SscActivity {
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
    In the web interface this is similar to the Activity button.
  .DESCRIPTION
    This wrapper function will call Get-SscData cmd.get_cmds.
  .EXAMPLE
    PS C:\> Get-SscActivity
#>
  
  (Get-SscData cmd get_cmds).results
}

Function Get-SscFile {
<#
  .NOTES
  ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 12, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will return file contents from the file server based on the provided arguments.
  .DESCRIPTION
    This wrapper function will call Get-SscData fs get_file and pass in specified saltenv and path parameters.
  .EXAMPLE
    PS C:\> Get-SscFile -saltenv 'sse' -path '/myfiles/file.sls'
  .EXAMPLE
    PS C:\> Get-SscFile -fileuuid '5e2483e8-a981-4e8c-9e83-01d1930413db'
#>
  param(
    [Parameter(Mandatory=$true, ParameterSetName='ByFileUUID', ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias('fileuuid')][string]$uuid,
    [Parameter(Mandatory=$true, ParameterSetName='ByFilePath')][string]$saltenv,
    [Parameter(Mandatory=$true, ParameterSetName='ByFilePath')][string]$path
  )
  
  $kwarg = @{}
  if ($uuid) { $kwarg += @{'file_uuid'=$uuid } }
  if ($saltenv) {
    $kwarg += @{'saltenv'=$saltenv}
    $kwarg += @{'path'=$path}
  }
  
  if ( Get-SscData fs file_exists $kwarg ) {
    Get-SscData fs get_file $kwarg
  } else {
    Write-Warning "File $path not found in $saltenv"
  }
}

Function Set-SscFile {
<#
  .NOTES
  ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 12, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will update file contents on the file server based on the provided arguments.
  .DESCRIPTION
    This wrapper function will call Get-SscData fs update_file and pass in specified fileuuid or saltenv and path parameters.
  .EXAMPLE
    PS C:\> Set-SscFile -saltenv 'sse' -path '/myfiles/file.sls' "#This is my content. `n#And so is this"
  .EXAMPLE
    PS C:\> Get-SscFile -saltenv 'sse' -path '/myfiles/file.sls' | Set-SscFile -contenttype 'text/x-yaml'
#>
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
  param(
    [Parameter(Mandatory=$true, ParameterSetName='ByFileUUID', ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias('fileuuid','file_uuid')][string]$uuid,
    [Parameter(Mandatory=$true, ParameterSetName='ByFilePath')][string]$saltenv,
    [Parameter(Mandatory=$true, ParameterSetName='ByFilePath')][string]$path,
    [string]$content,
    [ValidateSet('text/plain','text/x-python','application/json','text/x-yaml')][string]$contenttype
  )
  
  $kwarg = @{}
  if ($uuid) { $kwarg += @{'file_uuid'=$uuid } }
  if ($saltenv) {
    $kwarg += @{'saltenv'=$saltenv}
    $kwarg += @{'path'=$path}
  }

  # if the file exists, get its contents based on the correct parameterset.  If it does not exist recommend the correct function.
  if ( Get-SscData fs file_exists $kwarg ) {
    if ( $PSCmdlet.ParameterSetName -eq 'ByFileUUID' ) {
      $currentFile = Get-SscFile -fileuuid $uuid
    } else {
      $currentFile = Get-SscFile -saltenv $saltenv -path $path
    }
  } else {
    Write-Warning "Specified file does not exist, use New-SscFile instead."
    return $null
  }

  if (!$content) { $content = $currentFile.contents }
  $kwarg += @{'contents'=$content}

  if (!$contenttype) { $contenttype = $currentfile.content_type }
  $kwarg += @{'content_type'=$contenttype}
  
  if ($PSCmdlet.ShouldProcess( "$($currentFile.saltenv)$($currentFile.path) ($($currentFile.uuid))" , 'update')) {
    Get-SscData fs update_file $kwarg
  }
}

Function New-SscFile {
<#
  .NOTES
  ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 12, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will create a new file on the file server based on the provided arguments.
  .DESCRIPTION
    This wrapper function will call Get-SscData fs save_file and pass in specified saltenv and path parameters.
  .EXAMPLE
    PS C:\> New-SscFile -saltenv 'sse' -path '/myfiles/file.sls' -content '#this is my file content' -contenttype 'text/plain'
#>
  param(
    [Parameter(Mandatory=$true)][string]$saltenv,
    [Parameter(Mandatory=$true)][string]$path,
    [string]$content,
    [ValidateSet('text/plain','text/x-python','application/json','text/x-yaml')][string]$contenttype
  )
  
  $kwarg = @{}
  $kwarg += @{'saltenv'=$saltenv}
  $kwarg += @{'path'=$path}

  # if the file exists, get its contents based on the correct parameterset.  If it does not exist recommend the correct function.
  if ( Get-SscData fs file_exists $kwarg ) {
    write-warning "Specified file already exists, use Set-SscFile instead."
    return $null
  }

  if ($content) { $kwarg += @{'contents'=$content} }

  if ($contenttype) {
    # if a contenttype is passed to the function we'll use it
    $kwarg += @{'content_type'=$contenttype}
  } else {
    # and finally we'll default to text
    $kwarg += @{'content_type' = 'text/plain' }
  }

  Get-SscData fs save_file $kwarg
}

Function Remove-SscFile {
<#
  .NOTES
  ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 12, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will delete a specified file from the file server based on the provided arguments.
  .DESCRIPTION
    This wrapper function will call Get-SscData fs delete_file and pass in specified fileuuid or saltenv and path parameters.
  .EXAMPLE
    PS C:\> Remove-SscFile -saltenv 'sse' -path '/myfiles/file.sls'
  .EXAMPLE
    PS C:\> Get-SscFile -saltenv 'sse' -path '/myfiles/file.sls' | Remove-SscFile
#>
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
  param(
    [Parameter(Mandatory=$true, ParameterSetName='ByFileUUID', ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias('fileuuid')][string]$uuid,
    [Parameter(Mandatory=$true, ParameterSetName='ByFilePath')][string]$saltenv,
    [Parameter(Mandatory=$true, ParameterSetName='ByFilePath')][string]$path
  )
  
  $kwarg = @{}
  if ($uuid) { $kwarg += @{'file_uuid'=$uuid } }
  if ($saltenv) {
    $kwarg += @{'saltenv'=$saltenv}
    $kwarg += @{'path'=$path}
  }

  if ( Get-SscData fs file_exists $kwarg ) {
    if ($PSCmdlet.ShouldProcess( $(if ($uuid) {$uuid} else {"$saltenv $path"}) , 'delete')) {
      Get-SscData fs delete_file $kwarg
    }
  } else {
    Write-Warning "Specified file does not exist."
    return $null
  }
}
  
Function Get-SscLicense {
<#
  .NOTES
  ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 12, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will return license information for SaltStack Config.
  .DESCRIPTION
    This wrapper function will call Get-SscData license.get_current_license and return the desc property.
  .EXAMPLE
    PS C:\> Get-SscLicense
#>

  (Get-SscData license get_current_license).desc
}

Function Get-SscvRALicense {
<#
  .NOTES
  ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 12, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
  ===========================================================================
  .SYNOPSIS
    This wrapper function will return vRealize Automation license information for SaltStack Config.
  .DESCRIPTION
    This wrapper function will call Get-SscData license.get_vra_license and return the serial and edition property.
  .EXAMPLE
    PS C:\> Get-SscvRALicense
#>

  Get-SscData license get_vra_license
}

Function Get-SscMinionKeyState {
  <#
    .NOTES
    ===========================================================================
      Created by:	Brian Wuchner
      Date:		February 12, 2022
      Blog:		www.enterpriseadmins.org
      Twitter:		@bwuch
    ===========================================================================
    .SYNOPSIS
      This wrapper function will return minion key state information for SaltStack Config.
    .DESCRIPTION
      This wrapper function will call Get-SscData minions.get_minion_key_state and return the minions key states.  
      Optionally a key state can be provided and the results will be filtered to only return the requested state.
    .EXAMPLE
      PS C:\> Get-SscMinionKeyState
    .EXAMPLE
      PS C:\> Get-SscMinionKeyState -key_state pending
  #>
  param(
    [ValidateSet('accepted','rejected','pending','denied')][string]$key_state
  )
  
  $kwarg = @{}
  if ($key_state) { $kwarg.add('key_state',$key_state) }
  
  (Get-SscData minions get_minion_key_state $kwarg).results
}


Function Set-SscMinionKeyState {
  <#
    .NOTES
    ===========================================================================
      Created by:	Brian Wuchner
      Date:		February 12, 2022
      Blog:		www.enterpriseadmins.org
      Twitter:		@bwuch
    ===========================================================================
    .SYNOPSIS
      This wrapper function will set minion key state information for SaltStack Config.
    .DESCRIPTION
      This wrapper function will call Get-SscData minions.set_minion_key_state and update the states for specific minions.  
    .EXAMPLE
      PS C:\> Get-SscMinionKeyState |?{$_.name -eq 'server2022a'} | Set-SscMinionKeyState -state accept
    .EXAMPLE
      PS C:\> Set-SscMinionKeyState -master 'salt' -minion 'server2022a' -state reject -confirm:$false
  #>
  [cmdletbinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string]$master,
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string]$minion,
    [Parameter(Mandatory=$true)][ValidateSet('accept','reject')][string]$state
  )

  begin {
    $collection = @()
  }

  process {
    if ($PSCmdlet.ShouldProcess("$master : $minion" , $state)) {
      $collection += ,@($master, $minion)
    }
  }
  
  end {
    $kwarg = @{}
    $kwarg.Add('state', $state)
    if ($state -eq 'reject') {$kwarg.Add('include_accepted', $true)}
    if ($state -eq 'accept') {$kwarg.Add('include_rejected', $true)}
    if ($state -eq 'accept' -OR $state -eq 'reject') {$kwarg.Add('include_denied',$true)}
    $kwarg.Add('minions', @( $collection ) )

    (Get-SscData minions set_minion_key_state $kwarg).task_ids
  }
}

Function Remove-SscMinionKeyState {
  <#
    .NOTES
    ===========================================================================
      Created by:	Brian Wuchner
      Date:		February 12, 2022
      Blog:		www.enterpriseadmins.org
      Twitter:		@bwuch
    ===========================================================================
    .SYNOPSIS
      This wrapper function will delete a minion key for SaltStack Config.
    .DESCRIPTION
      This wrapper function will call Get-SscData minions.set_minion_key_state and remove the specified minion keys.  
    .EXAMPLE
      PS C:\> Get-SscMinionKeyState |?{$_.name -eq 'server2022a'} | Remove-SscMinionKeyState
    .EXAMPLE
      PS C:\> Remove-SscMinionKeyState -master 'salt' -minion 'server2022a' -confirm:$false
  #>
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string]$master,
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string]$minion
  )

  begin {
    $collection = @()
  }

  process {
    if ($PSCmdlet.ShouldProcess("$master : $minion" , 'delete')) {
      $collection += ,@($master, $minion)
    }
  }

  end {
    $kwarg = @{}
    $kwarg.Add('state','delete')
    $kwarg.Add('minions', @( $collection ) )

    (Get-SscData minions set_minion_key_state $kwarg).task_ids
  }
}
