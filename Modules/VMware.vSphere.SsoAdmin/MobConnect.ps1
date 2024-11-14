<#
Copyright 2024 JetStream Software, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

class MobConnection {
    <#
        .NOTES
        ===================================================
        MOB3 connection object

        Approach borrowed from https://github.com/lamw/vmware-scripts/blob/master/powershell/GlobalPermissions.ps1
        ===================================================
        Created on:      11/13/2024
        Github:          https://github.com/jetstreamsoft
        ===================================================
        Usage sample:
            $local_user_name = "user@vsphere.local"
            $credential = New-Object System.Management.Automation.PSCredential($adminname, $adminpasswd)
            $role_id = (Get-VIRole -Name $role_name).ExtensionData.RoleId

            $mobconn = New-Object MobConnection($vcenter_server, $credential, $True)
            $mobconn.SetPermissions($local_user_name, $role_id, $True)
            $mobconn.Logout()
    #>

    hidden [object] $session
    hidden [string] $nonce
    hidden [string] $vc_address
    hidden [bool]   $skipCertCheck

    hidden [string] _getLoginUrl() {
        return "https://$($this.vc_address)/invsvc/mob3/?moid=authorizationService&method=AuthorizationService.AddGlobalAccessControlList"
    }

    hidden [string] _getAddGlobalPermUrl() {
        return "https://$($this.vc_address)/invsvc/mob3/?moid=authorizationService&method=AuthorizationService.AddGlobalAccessControlList"
    }

    hidden [string] _getGetGlobalPermUrl() {
        return "https://$($this.vc_address)/invsvc/mob3/?moid=authorizationService&method=AuthorizationService.GetUserGlobalPrivileges"
    }

    hidden [string] _getRemoveGlobalPermUrl() {
        return "https://$($this.vc_address)/invsvc/mob3/?moid=authorizationService&method=AuthorizationService.RemoveGlobalAccess"
    }

    hidden [string] _getLogoutUrl() {
        return "https://$($this.vc_address)/invsvc/mob3/logout"
    }

    hidden [String[]] _executeWebRequest([string] $url, [string] $body) {
        $request_params = @{
            "Uri" = $url
            "WebSession" = $this.session
            "Method" = "POST"
            "Body" = $body
        }
        if ($this.skipCertCheck) {
            $request_params["SkipCertificateCheck"] = $True
        }
        $reply = Invoke-WebRequest @request_params
        if($reply.StatusCode -ne 200) {
            Write-Error "Failed to execute POST on $url with $($reply.StatusCode) - $($reply.Content)" -ErrorAction Stop
        }
        if (!($reply.Content -match 'Method Invocation Result: ?([^<]+)<')) {
            Write-Error "Unexpected reply from MOB." -ErrorAction Stop
        }
        return $matches[1], $reply.Content
    }

    MobConnection([string] $vcenter, [PSCredential] $credential, [bool] $skipCertCheck) {
        if ([string]::IsNullOrEmpty($vcenter)) {
            Write-Error "vcenter parameter is required" -ErrorAction Stop
        }
        if ($null -eq $credential) {
            Write-Error "credential parameter is required." -ErrorAction Stop
        }

        $this.vc_address = $vcenter
        $this.session = $null
        $this.skipCertCheck = $skipCertCheck

        $sessionvar = $null
        # Initial login to vSphere MOB using GET and store session in class variable
        $login_params = @{
            "Uri" = $this._getLoginUrl()
            "SessionVariable" = "sessionvar"
            "Credential" = $credential
            "Method" = "GET"
        }
        if ($this.skipCertCheck) {
            $login_params["SkipCertificateCheck"] = $True
        }
        $results = Invoke-WebRequest @login_params

        # Extract hidden vmware-session-nonce which must be included in future requests to prevent CSRF error
        # Credit to https://blog.netnerds.net/2013/07/use-powershell-to-keep-a-cookiejar-and-post-to-a-web-form/ for parsing vmware-session-nonce via Powershell
        if($results.StatusCode -eq 200) {
            $null = $results -match 'name="vmware-session-nonce" type="hidden" value="?([^\s^"]+)"'
            $this.nonce = $matches[1]
            $this.session = $sessionvar
        } else {
            Write-Error "Failed to login to vSphere MOB with $($results.StatusCode) - $($results.Content)" -ErrorAction Stop
        }
    }

    [string[]] GetGlobalPermissions([string] $user_domain) {
        if ($null -eq $this.session) {
            Write-Error "Object not logged in, please relogin" -ErrorAction Stop
        }
        if ([string]::IsNullOrEmpty($user_domain)){
            Write-Error "user_domain parameter is required" -ErrorAction Stop
        }
        if ($user_domain.Contains('<') -or $user_domain.Contains('>')) {
            Write-Error "Invalid user name provided - $user_domain" -ErrorAction Stop
        }

        $body="vmware-session-nonce=$($this.nonce)&userName=$([uri]::EscapeDataString($user_domain))"
        $reply = $this._executeWebRequest($this._getGetGlobalPermUrl(), $body)

        # If the account has no permissions, there would be no <ul><li></li>...</ul>
        # after the returned "val" field.
        $perm_list = @()
        $reply_start = $reply[1].IndexOf(">val<")
        $reply_end = $reply[1].IndexOf("</tr>", $reply_start)

        $next_perm = 0
        $perm_data = $reply[1].Substring($reply_start, $reply_end-$reply_start)
        while ($next_perm -ge 0) {
            $next_li = $perm_data.IndexOf('<li>', $next_perm)
            if ($next_li -lt 0) {
                $next_perm = -1
                continue
            }
            $next_perm = $perm_data.IndexOf('</li>', $next_li)
            $perm_list += @($perm_data.Substring($next_li + 4, $next_perm - $next_li - 4))
        }
        return $perm_list
    }

    [void] RemoveAllGlobalPermissions([string] $user_domain) {
        if ($null -eq $this.session) {
            Write-Error "Object not logged in, please relogin" -ErrorAction Stop
        }
        if ([string]::IsNullOrEmpty($user_domain)){
            Write-Error "user_domain parameter is required" -ErrorAction Stop
        }
        if ($user_domain.Contains('<') -or $user_domain.Contains('>')) {
            Write-Error "Invalid user name provided - $user_domain" -ErrorAction Stop
        }

        $request_body=@"
<principals>
 <name>$user_domain</name>
 <group>false</group>
</principals>
"@
        # Prepare permissions request
        # The POST data payload must include the vmware-session-nonce variable + URL-encoded request body
        $body="vmware-session-nonce=$($this.nonce)&principals=$([uri]::EscapeDataString($request_body))"
        $this._executeWebRequest($this._getRemoveGlobalPermUrl(), $body)
    }

    [void] SetGlobalPermissions([string] $user_domain, [long] $vc_role_id, [bool] $propagate) {
        if ($null -eq $this.session) {
            Write-Error "Object not logged in, please relogin" -ErrorAction Stop
        }
        if ([string]::IsNullOrEmpty($user_domain)){
            Write-Error "user_domain parameter is required" -ErrorAction Stop
        }
        if ($user_domain.Contains('<') -or $user_domain.Contains('>')) {
            Write-Error "Invalid user name provided - $user_domain" -ErrorAction Stop
        }

        # Prepare permissions request
        $request_body = @"
<permissions>
  <principal>
    <name>$user_domain</name>
    <group>false</group>
  </principal>
  <roles>$vc_role_id</roles>
  <propagate>$propagate</propagate>
</permissions>
"@
        # The POST data payload must include the vmware-session-nonce variable + URL-encoded request body
        $body="vmware-session-nonce=$($this.nonce)&permissions=$([uri]::EscapeDataString($request_body))"
        $reply = $this._executeWebRequest($this._getAddGlobalPermUrl(), $body)
        if ($reply[0] -ne 'void') {
            Write-Error "Invalid role ID $vc_role_id provided." -ErrorAction Stop
        }
    }

    [bool] IsConnected() {
        if ($null -eq $this.session) {
            return $false
        }
        # Validate the session hasn't expired.
        $login_params = @{
            "Uri" = $this._getLoginUrl()
            "WebSession" = $this.session
            "Method" = "GET"
        }
        if ($this.skipCertCheck) {
            $login_params["SkipCertificateCheck"] = $True
        }
        $results = Invoke-WebRequest @login_params

        if($results.StatusCode -ne 200) {
            $this.session = $null
            return $false
        }
        # Replace nonce for the request.
        $null = $results -match 'name="vmware-session-nonce" type="hidden" value="?([^\s^"]+)"'
        $this.nonce = $matches[1]
        return $true
    }

    [void] Logout() {
        if ($null -ne $this.session) {
            Write-Information "Object not logged in"
            return
        }
        # Logout out of vSphere MOB
        $logout_params = @{
            "Uri" = $this._getLogoutUrl()
            "WebSession" = $this.session
            "Method" = "GET"
        }
        if ($this.skipCertCheck) {
            $logout_params["SkipCertificateCheck"] = $True
        }
        $null = Invoke-WebRequest @logout_params
        $this.session = $null
    }
}

function Connect-VcenterServerMOB {
    <#
    .NOTES
    ===========================================================================
    .DESCRIPTION
    This function establishes a connection to a vSphere server managed object browser.

    .PARAMETER Server
    Specifies the IP address or the DNS name of the vSphere server to which you want to connect.

    .PARAMETER User
    Specifies the user name you want to use for authenticating with the server.

    .PARAMETER Password
    Specifies the password you want to use for authenticating with the server.

    .PARAMETER Credential
    Specifies a PSCredential object to for authenticating with the server.

    .PARAMETER SkipCertificateCheck
    Specifies whether server Tls certificate validation will be skipped

    .EXAMPLE
    Connect-VcenterServerMOB -Server my.vc.server -User myAdmin@vsphere.local -Password MyStrongPa$$w0rd

    Returns an object with connection of 'myAdmin@vsphere.local' user to MOB of vCenter server 'my.vc.server'
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'IP address or the DNS name of the vSphere server')]
        [string]
        $Server,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'User name you want to use for authenticating with the server',
            ParameterSetName = 'UserPass')]
        [string]
        $User,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Password you want to use for authenticating with the server',
            ParameterSetName = 'UserPass')]
        [VMware.vSphere.SsoAdmin.Utils.StringToSecureStringArgumentTransformationAttribute()]
        [SecureString]
        $Password,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'PSCredential object to use for authenticating with the server',
            ParameterSetName = 'Credential')]
        [PSCredential]
        $Credential,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Skips server Tls certificate validation')]
        [switch]
        $SkipCertificateCheck)

    Process {
        $vCenterMOB = $null

        try {
            if ($PSBoundParameters.ContainsKey('Credential')) {
                $vCenterMOB = New-Object MobConnection `
                    -ArgumentList @(
                    $Server,
                    $Credential,
                    $SkipCertificateCheck)
            } else {
                $_credential = New-Object System.Management.Automation.PSCredential($User, $Password)
                $vCenterMOB = New-Object MobConnection `
                    -ArgumentList @(
                    $Server,
                    $_credential,
                    $SkipCertificateCheck)
            }
        } catch {
            Write-Error (FormatError $_.Exception) -ErrorAction Stop
        }

        return $vCenterMOB
    }
}

function Set-VcenterServerGlobalPermission {
    <#
    .NOTES
    ===========================================================================
    .DESCRIPTION
    This function assigns global permissions associated with role to the specified user.

    .PARAMETER Server
    Specifies the vSphere server MOB connection

    .PARAMETER TargetUser
    Specifies the full name of the local account to assign permissions to.

    .PARAMETER RoleId
    Specifies the vCenter role ID to assign.
    Acquire with (Get-VIRole -Name $role_name).ExtensionData.RoleId

    .PARAMETER Propagate
    Specifies whether global permission must be propagated to all inventory objects

    .EXAMPLE
    $myMobConnection = Connect-VcenterServerMOB -Server my.vc.server -User ssoAdmin@vsphere.local -Password 'MyStrongPa$$w0rd'
    Set-VcenterServerGlobalPermission -Server $myMobConnection -TargetUser otheruser@vsphere.local -RoleId -9999 -Propagate

    Assign global permissions associated with role '-9999' to the user 'otheruser@vsphere.local'
    propagating the assignment to the whole inventory.
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'MobConnection object')]
        [ValidateNotNull()]
        [MobConnection]
        $Server,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Full name of local user to assign the permission to')]
        [ValidateNotNull()]
        [string]
        $TargetUser,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'vCenter ID of the role to assign')]
        [long]
        $RoleId,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Propagate global permission to all objects')]
        [switch]
        $Propagate
    )
    Process {
        $Server.SetPermissions($TargetUser, $RoleId, $Propagate)
    }
}

function Get-VcenterServerGlobalPermissions {
    <#
    .NOTES
    ===========================================================================
    .DESCRIPTION
    This function gets the list of global permissions granted to the specified user.

    .PARAMETER Server
    Specifies the vSphere server MOB connection

    .PARAMETER TargetUser
    Specifies the full name of the local account to get permissions for.

    .EXAMPLE
    $myMobConnection = Connect-VcenterServerMOB -Server my.vc.server -User ssoAdmin@vsphere.local -Password 'MyStrongPa$$w0rd'
    $perm_list = Get-VcenterServerGlobalPermission -Server $myMobConnection -TargetUser otheruser@vsphere.local

    Get the list of individual permissions in global context associated with the user 'otheruser@vsphere.local'
    into variable $perm_list.
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'MobConnection object')]
        [ValidateNotNull()]
        [MobConnection]
        $Server,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Full name of local user to get the list of permissions for')]
        [ValidateNotNull()]
        [string]
        $TargetUser
    )
    Process {
        $Server.GetGlobalPermissions($TargetUser)
    }
}

function Reset-VcenterServerGlobalPermissions {
    <#
    .NOTES
    ===========================================================================
    .DESCRIPTION
    This function removes all global permissions granted to the specified user.

    .PARAMETER Server
    Specifies the vSphere server MOB connection

    .PARAMETER TargetUser
    Specifies the full name of the local account to remove permissions from.

    .EXAMPLE
    $myMobConnection = Connect-VcenterServerMOB -Server my.vc.server -User ssoAdmin@vsphere.local -Password 'MyStrongPa$$w0rd'
    Reset-VcenterServerGlobalPermission -Server $myMobConnection -TargetUser otheruser@vsphere.local

    Remove all global permissions granted to the user 'otheruser@vsphere.local'
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'MobConnection object')]
        [ValidateNotNull()]
        [MobConnection]
        $Server,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Full name of local user to remove the permissions from')]
        [ValidateNotNull()]
        [string]
        $TargetUser
    )
    Process {
        $Server.RemoveAllGlobalPermissions($TargetUser)
    }
}

function Disconnect-VcenterServerMOB {
    <#
    .NOTES
    ===========================================================================
    .DESCRIPTION
    This function closes the connection to a vSphere server managed object browser.

    .PARAMETER Server
    Specifies the vSphere server MOB connection you want to terminate

    .EXAMPLE
    $myMobConnection = Connect-VcenterServerMOB -Server my.vc.server -User ssoAdmin@vsphere.local -Password 'MyStrongPa$$w0rd'
    Disconnect-VcenterServerMOB -Server $myMobConnection

    Disconnect a vSphere server managed object browser stored in 'myMobConnection' varaible
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'MobConnection object')]
        [ValidateNotNull()]
        [MobConnection]
        $Server
    )

    Process {
        if ($Server.IsConnected()) {
            $Server.Logout()
        }
    }
}
