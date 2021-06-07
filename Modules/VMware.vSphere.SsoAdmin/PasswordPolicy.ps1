<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Get-SsoPasswordPolicy {
    <#
       .NOTES
       ===========================================================================
       Created on:   	9/30/2020
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function gets password policy.

       .PARAMETER Server
       Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
       If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

       .EXAMPLE
       Get-SsoPasswordPolicy

       Gets password policy for the server connections available in $global:defaultSsoAdminServers
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

                $connection.Client.GetPasswordPolicy();
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}

function Set-SsoPasswordPolicy {
    <#
       .NOTES
       ===========================================================================
       Created on:   	9/30/2020
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function updates password policy settings.

       .PARAMETER PasswordPolicy
       Specifies the PasswordPolicy instance which will be used as original policy. If some properties are not specified they will be updated with the properties from this object.

       .PARAMETER Description

       .PARAMETER ProhibitedPreviousPasswordsCount

       .PARAMETER MinLength

       .PARAMETER MaxLength

       .PARAMETER MaxIdenticalAdjacentCharacters

       .PARAMETER MinNumericCount

       .PARAMETER MinSpecialCharCount

       .PARAMETER MinAlphabeticCount

       .PARAMETER MinUppercaseCount

       .PARAMETER MinLowercaseCount

       .PARAMETER PasswordLifetimeDays

       .EXAMPLE
       Get-SsoPasswordPolicy | Set-SsoPasswordPolicy -MinLength 10 -PasswordLifetimeDays 45

       Updates password policy setting minimum password length to 10 symbols and password lifetime to 45 days
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'PasswordPolicy instance you want to update')]
        [VMware.vSphere.SsoAdminClient.DataTypes.PasswordPolicy]
        $PasswordPolicy,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'PasswordPolicy description')]
        [string]
        $Description,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int32]]
        $ProhibitedPreviousPasswordsCount,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int32]]
        $MinLength,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int32]]
        $MaxLength,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int32]]
        $MaxIdenticalAdjacentCharacters,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int32]]
        $MinNumericCount,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int32]]
        $MinSpecialCharCount,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int32]]
        $MinAlphabeticCount,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int32]]
        $MinUppercaseCount,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int32]]
        $MinLowercaseCount,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int32]]
        $PasswordLifetimeDays)

    Process {

        try {
            foreach ($pp in $PasswordPolicy) {

                $ssoAdminClient = $pp.GetClient()
                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$pp' is from disconnected server"
                    continue
                }

                if ([string]::IsNullOrEmpty($Description)) {
                    $Description = $pp.Description
                }

                if ($ProhibitedPreviousPasswordsCount -eq $null) {
                    $ProhibitedPreviousPasswordsCount = $pp.ProhibitedPreviousPasswordsCount
                }

                if ($MinLength -eq $null) {
                    $MinLength = $pp.MinLength
                }

                if ($MaxLength -eq $null) {
                    $MaxLength = $pp.MaxLength
                }

                if ($MaxIdenticalAdjacentCharacters -eq $null) {
                    $MaxIdenticalAdjacentCharacters = $pp.MaxIdenticalAdjacentCharacters
                }

                if ($MinNumericCount -eq $null) {
                    $MinNumericCount = $pp.MinNumericCount
                }

                if ($MinSpecialCharCount -eq $null) {
                    $MinSpecialCharCount = $pp.MinSpecialCharCount
                }

                if ($MinAlphabeticCount -eq $null) {
                    $MinAlphabeticCount = $pp.MinAlphabeticCount
                }

                if ($MinUppercaseCount -eq $null) {
                    $MinUppercaseCount = $pp.MinUppercaseCount
                }

                if ($MinLowercaseCount -eq $null) {
                    $MinLowercaseCount = $pp.MinLowercaseCount
                }

                if ($PasswordLifetimeDays -eq $null) {
                    $PasswordLifetimeDays = $pp.PasswordLifetimeDays
                }

                $ssoAdminClient.SetPasswordPolicy(
                    $Description,
                    $ProhibitedPreviousPasswordsCount,
                    $MinLength,
                    $MaxLength,
                    $MaxIdenticalAdjacentCharacters,
                    $MinNumericCount,
                    $MinSpecialCharCount,
                    $MinAlphabeticCount,
                    $MinUppercaseCount,
                    $MinLowercaseCount,
                    $PasswordLifetimeDays);
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}
