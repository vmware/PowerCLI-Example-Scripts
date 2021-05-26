<#
Copyright 2020-2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-SsoTokenLifetime {
    <#
       .NOTES
       ===========================================================================
       Created on:   	9/30/2020
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function gets HoK and Bearer Token lifetime settings.

       .PARAMETER Server
       Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
       If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

       .EXAMPLE
       Get-SsoTokenLifetime

       Gets HoK and Bearer Token lifetime settings for the server connections available in $global:defaultSsoAdminServers
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

                $connection.Client.GetTokenLifetime();
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}

function Set-SsoTokenLifetime {
    <#
       .NOTES
       ===========================================================================
       Created on:   	9/30/2020
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function updates HoK or Bearer token lifetime settings.

       .PARAMETER TokenLifetime
       Specifies the TokenLifetime instance to update.

       .PARAMETER MaxHoKTokenLifetime

       .PARAMETER MaxBearerTokenLifetime

       .EXAMPLE
       Get-SsoTokenLifetime | Set-SsoTokenLifetime -MaxHoKTokenLifetime 60

       Updates HoK token lifetime setting
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'TokenLifetime instance you want to update')]
        [VMware.vSphere.SsoAdminClient.DataTypes.TokenLifetime]
        $TokenLifetime,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int64]]
        $MaxHoKTokenLifetime,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [Nullable[System.Int64]]
        $MaxBearerTokenLifetime)

    Process {

        try {
            foreach ($tl in $TokenLifetime) {

                $ssoAdminClient = $tl.GetClient()
                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$tl' is from disconnected server"
                    continue
                }

                $ssoAdminClient.SetTokenLifetime(
                    $MaxHoKTokenLifetime,
                    $MaxBearerTokenLifetime
                );
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}
