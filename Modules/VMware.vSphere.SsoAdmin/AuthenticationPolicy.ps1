<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Get-SsoAuthenticationPolicy {
    <#
    .NOTES
       ===========================================================================
       Created on:   	7/28/2021
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================

    .SYNOPSIS
    Gets Authentication Policy

    .DESCRIPTION
    Gets Authentication Policy.

    .PARAMETER Server
    Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
    If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

    .EXAMPLE
    Get-SsoAuthenticationPolicy

    Gets the Authentication Policy for the connected servers

    #>

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Connected SsoAdminServer object')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer]
        $Server)

    Process {
        $serversToProcess = $global:DefaultSsoAdminServers.ToArray()
        if ($null -ne $Server) {
            $serversToProcess = $Server
        }

        foreach ($connection in $serversToProcess) {
            if (-not $connection.IsConnected) {
                Write-Error "Server $connection is disconnected"
                continue
            }

            # Output is the result of 'GetAuthenticationPolicy'
            try {
                $connection.Client.GetAuthenticationPolicy()
            }
            catch {
                Write-Error (FormatError $_.Exception)
            }
        }
    }
}

function Set-SsoAuthenticationPolicy {
    <#
    .NOTES
       ===========================================================================
       Created on:   	7/28/2021
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================

    .SYNOPSIS
    Updates Authentication Policy

    .DESCRIPTION
    Updates Authentication Policy settings

    .PARAMETER AuthenticationPolicy
    An AuthenticationPolicy to update retrieved from  Set-SsoAuthenticationPolicy cmdlet

    .PARAMETER PasswordAuthnEnabled
    Enables or disables Password Authentication

    .PARAMETER WindowsAuthnEnabled
    Enables or disables Windows Authentication

    .PARAMETER SmartCardAuthnEnabled
    Enables or disables Smart Card Authentication

    .PARAMETER CRLCacheSize
    Specifies CRL Cache size

    .PARAMETER CRLUrl
    Specifies CRL Url

    .PARAMETER OCSPEnabled
    Enables or disables OCSP

    .PARAMETER OCSPResponderSigningCert
    OCSP Responder Signing Certificate

    .PARAMETER OCSPUrl

    .PARAMETER OIDs

    .PARAMETER SendOCSPNonce

    .PARAMETER TrustedCAs

    .PARAMETER UseCRLAsFailOver,

    .PARAMETER UseInCertCRL

    .EXAMPLE
    $myServer = Connect-SsoAdminServer -Server MyServer -User myUser -Password myPassword
    Get-SsoAuthenticationPolicy -Server $myServer | Set-SsoAuthenticationPolicy -SmartCardAuthnEnabled $true

    Enables SmartCard Authnetication on server $myServer

    #>

    [CmdletBinding(ConfirmImpact = 'Medium')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'AuthenticationPolicy object to update')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.AuthenticationPolicy]
        $AuthenticationPolicy,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Enables or disables Password Authentication')]
        [bool]
        $PasswordAuthnEnabled,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Enables or disables Windows Authentication')]
        [bool]
        $WindowsAuthnEnabled,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Enables or disables Smart Card Authentication')]
        [bool]
        $SmartCardAuthnEnabled,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'CRL Cache size')]
        [int]
        $CRLCacheSize,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'CRL Url')]
        [string]
        $CRLUrl,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Enables or disables OCSP')]
        [bool]
        $OCSPEnabled,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'OCSP Responder Signing Certificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $OCSPResponderSigningCert,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'OCSP Url')]
        [string]
        $OCSPUrl,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'OIDs')]
        [string[]]
        $OIDs,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Enables or disables seinding OCSP Nonce')]
        [bool]
        $SendOCSPNonce,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'List of trusted CAs')]
        [string[]]
        $TrustedCAs,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Specifies whether to use CRL fail over')]
        [bool]
        $UseCRLAsFailOver,


        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Specifiеs whether to use CRL from certificate')]
        [bool]
        $UseInCertCRL)

    Process {

        try {
            foreach ($a in $AuthenticationPolicy) {
                $ssoAdminClient = $a.GetClient()

                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$a' is from disconnected server"
                    continue
                }

                if (-not $PSBoundParameters.ContainsKey('PasswordAuthnEnabled')) {
                    $PasswordAuthnEnabled = $a.PasswordAuthnEnabled
                }

                if (-not $PSBoundParameters.ContainsKey('WindowsAuthnEnabled')) {
                    $WindowsAuthnEnabled = $a.WindowsAuthnEnabled
                }

                if (-not $PSBoundParameters.ContainsKey('SmartCardAuthnEnabled')) {
                    $SmartCardAuthnEnabled = $a.SmartCardAuthnEnabled
                }

                if (-not $PSBoundParameters.ContainsKey('CRLCacheSize')) {
                    $CRLCacheSize = $a.CRLCacheSize
                }

                if (-not $PSBoundParameters.ContainsKey('CRLUrl')) {
                    $CRLUrl = $a.CRLUrl
                }

                if (-not $PSBoundParameters.ContainsKey('OCSPEnabled')) {
                    $OCSPEnabled = $a.OCSPEnabled
                }

                if (-not $PSBoundParameters.ContainsKey('OCSPResponderSigningCert')) {
                    $OCSPResponderSigningCert = $a.OCSPResponderSigningCert
                }

                if (-not $PSBoundParameters.ContainsKey('OCSPUrl')) {
                    $OCSPUrl = $a.OCSPUrl
                }

                if (-not $PSBoundParameters.ContainsKey('OIDs')) {
                    $OIDs = $a.OIDs
                }

                if (-not $PSBoundParameters.ContainsKey('SendOCSPNonce')) {
                    $SendOCSPNonce = $a.SendOCSPNonce
                }

                if (-not $PSBoundParameters.ContainsKey('TrustedCAs')) {
                    $TrustedCAs = $a.TrustedCAs
                }

                if (-not $PSBoundParameters.ContainsKey('UseCRLAsFailOver')) {
                    $UseCRLAsFailOver = $a.UseCRLAsFailOver
                }

                if (-not $PSBoundParameters.ContainsKey('UseInCertCRL')) {
                    $UseInCertCRL = $a.UseInCertCRL
                }

                $ssoAdminClient.SetAuthenticationPolicy(
                    $PasswordAuthnEnabled,
                    $WindowsAuthnEnabled,
                    $SmartCardAuthnEnabled,
                    $CRLCacheSize,
                    $CRLUrl,
                    $OCSPEnabled,
                    $OCSPResponderSigningCert,
                    $OCSPUrl,
                    $OIDs,
                    $SendOCSPNonce,
                    $TrustedCAs,
                    $UseCRLAsFailOver,
                    $UseInCertCRL
                )

                # Output updated policy
                Write-Output ($ssoAdminClient.GetAuthenticationPolicy())
            }
        } catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}
