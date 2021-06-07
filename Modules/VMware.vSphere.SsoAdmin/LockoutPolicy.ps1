<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Get-SsoLockoutPolicy {
    <#
       .NOTES
       ===========================================================================
       Created on:   	9/30/2020
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function gets lockout policy.

       .PARAMETER Server
       Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
       If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

       .EXAMPLE
       Get-SsoLockoutPolicy

       Gets lockout policy for the server connections available in $global:defaultSsoAdminServers
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
        if ($Server -ne $null) {
            $serversToProcess = $Server
        }

        try {
            foreach ($connection in $serversToProcess) {
                if (-not $connection.IsConnected) {
                    Write-Error "Server $connection is disconnected"
                    continue
                }

                $connection.Client.GetLockoutPolicy();
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}

function Set-SsoLockoutPolicy {
    <#
       .NOTES
       ===========================================================================
       Created on:   	9/30/2020
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function updates lockout policy settings.

       .PARAMETER LockoutPolicy
       Specifies the LockoutPolicy instance which will be used as original policy. If some properties are not specified they will be updated with the properties from this object.

       .PARAMETER Description

       .PARAMETER AutoUnlockIntervalSec

       .PARAMETER FailedAttemptIntervalSec

       .PARAMETER MaxFailedAttempts

       .EXAMPLE
       Get-SsoLockoutPolicy | Set-SsoLockoutPolicy -AutoUnlockIntervalSec 15 -MaxFailedAttempts 4

       Updates lockout policy auto unlock interval seconds and maximum failed attempts
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'LockoutPolicy instance you want to update')]
        [VMware.vSphere.SsoAdminClient.DataTypes.LockoutPolicy]
        $LockoutPolicy,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'LockoutPolicy description')]
        [string]
        $Description,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int64]]
        $AutoUnlockIntervalSec,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int64]]
        $FailedAttemptIntervalSec,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int32]]
        $MaxFailedAttempts)

    Process {
        try {
            foreach ($lp in $LockoutPolicy) {

                $ssoAdminClient = $lp.GetClient()
                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$lp' is from disconnected server"
                    continue
                }

                if ([string]::IsNullOrEmpty($Description)) {
                    $Description = $lp.Description
                }

                if ($AutoUnlockIntervalSec -eq $null) {
                    $AutoUnlockIntervalSec = $lp.AutoUnlockIntervalSec
                }

                if ($FailedAttemptIntervalSec -eq $null) {
                    $FailedAttemptIntervalSec = $lp.FailedAttemptIntervalSec
                }

                if ($MaxFailedAttempts -eq $null) {
                    $MaxFailedAttempts = $lp.MaxFailedAttempts
                }

                $ssoAdminClient.SetLockoutPolicy(
                    $Description,
                    $AutoUnlockIntervalSec,
                    $FailedAttemptIntervalSec,
                    $MaxFailedAttempts);
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}
