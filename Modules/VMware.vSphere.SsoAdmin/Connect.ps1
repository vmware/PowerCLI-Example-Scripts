<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Connect-SsoAdminServer {
    <#
    .NOTES
    ===========================================================================
    Created on:   	9/29/2020
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================
    .DESCRIPTION
    This function establishes a connection to a vSphere SSO Admin server.

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
    Connect-SsoAdminServer -Server my.vc.server -User myAdmin@vsphere.local -Password MyStrongPa$$w0rd

    Connects 'myAdmin@vsphere.local' user to Sso Admin server 'my.vc.server'
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
        $certificateValidator = $null
        if ($SkipCertificateCheck) {
            $certificateValidator = New-Object 'VMware.vSphere.SsoAdmin.Utils.AcceptAllX509CertificateValidator'
        }

        $ssoAdminServer = $null
        try {
            if ($PSBoundParameters.ContainsKey('Credential')) {
                $ssoAdminServer = New-Object `
                    'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer' `
                    -ArgumentList @(
                    $Server,
                    $Credential.UserName,
                    $Credential.Password,
                    $certificateValidator)
            } else {
                $ssoAdminServer = New-Object `
                    'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer' `
                    -ArgumentList @(
                    $Server,
                    $User,
                    $Password,
                    $certificateValidator)
            }

        }
        catch {
            Write-Error (FormatError $_.Exception)
        }

        if ($ssoAdminServer -ne $null) {
            $existingConnectionIndex = $global:DefaultSsoAdminServers.IndexOf($ssoAdminServer)
            if ($existingConnectionIndex -ge 0) {
                $global:DefaultSsoAdminServers[$existingConnectionIndex].RefCount++
                $ssoAdminServer = $global:DefaultSsoAdminServers[$existingConnectionIndex]
            }
            else {
                # Update $global:DefaultSsoAdminServers varaible
                $global:DefaultSsoAdminServers.Add($ssoAdminServer) | Out-Null
            }

            # Function Output
            Write-Output $ssoAdminServer
        }
    }
}

function Disconnect-SsoAdminServer {
    <#
    .NOTES
    ===========================================================================
    Created on:   	9/29/2020
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================
    .DESCRIPTION
    This function closes the connection to a vSphere SSO Admin server.

    .PARAMETER Server
    Specifies the vSphere SSO Admin systems you want to disconnect from

    .EXAMPLE
    $mySsoAdminConnection = Connect-SsoAdminServer -Server my.vc.server -User ssoAdmin@vsphere.local -Password 'ssoAdminStrongPa$$w0rd'
    Disconnect-SsoAdminServer -Server $mySsoAdminConnection

    Disconnect a SSO Admin connection stored in 'mySsoAdminConnection' varaible
#>
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'SsoAdminServer object')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdmin.Utils.StringToSsoAdminServerArgumentTransformationAttribute()]
        [VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer[]]
        $Server
    )

    Process {
        if (-not $PSBoundParameters['Server']) {
            switch (@($global:DefaultSsoAdminServers).count) {
                { $_ -eq 1 } { $server = ($global:DefaultSsoAdminServers).ToArray()[0] ; break }
                { $_ -gt 1 } {
                    Throw 'Connected to more than 1 SSO server, please specify a SSO server via -Server parameter'
                    break
                }
                Default {
                    Throw 'Not connected to SSO server.'
                }
            }
        }

        foreach ($requestedServer in $Server) {
            if ($requestedServer.IsConnected) {
                $requestedServer.Disconnect()
            }

            if ($global:DefaultSsoAdminServers.Contains($requestedServer) -and $requestedServer.RefCount -eq 0) {
                $global:DefaultSsoAdminServers.Remove($requestedServer) | Out-Null
            }
        }
    }
}
