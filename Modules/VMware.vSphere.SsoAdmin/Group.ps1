<#
Copyright 2020-2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Get-SsoGroup {
    <#
       .NOTES
       ===========================================================================
       Created on:   	9/29/2020
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function gets domain groups.

       .PARAMETER Name
       Specifies Name to filter on when searching for groups.

       .PARAMETER Domain
       Specifies the Domain in which search will be applied, default is 'localos'.


       .PARAMETER Server
       Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
       If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

       .EXAMPLE
       Get-SsoGroup -Name administrators -Domain vsphere.local

       Gets 'adminsitrators' group in 'vsphere.local' domain
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Name filter to be applied when searching for group')]
        [string]
        $Name,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Domain name to search in, default is "localos"')]
        [string]
        $Domain = 'localos',

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

        if ($Name -eq $null) {
            $Name = [string]::Empty
        }

        try {
            foreach ($connection in $serversToProcess) {
                if (-not $connection.IsConnected) {
                    Write-Error "Server $connection is disconnected"
                    continue
                }

                foreach ($group in $connection.Client.GetGroups(
                        (RemoveWildcardSymbols $Name),
                        $Domain)) {


                    if ([string]::IsNullOrEmpty($Name) ) {
                        Write-Output $group
                    }
                    else {
                        # Apply Name filtering
                        if ((HasWildcardSymbols $Name) -and `
                                $group.Name -like $Name) {
                            Write-Output $group
                        }
                        elseif ($group.Name -eq $Name) {
                            # Exactly equal
                            Write-Output $group
                        }
                    }
                }
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}
