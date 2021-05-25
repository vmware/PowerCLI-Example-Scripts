<#
Copyright 2020-2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function New-SsoGroup {
    <#
    .NOTES
       ===========================================================================
       Created on:   	5/25/2021
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================

    .SYNOPSIS
    Creates Local Sso Group

    .DESCRIPTION
    Creates Local Sso Group

    .PARAMETER Name
    Specifies the name of the group.

    .PARAMETER Description
    Specifies optionaldescription of the group.

    .PARAMETER Server
    Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
    If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

    .EXAMPLE
    New-SsoGroup -Name 'myGroup' -Description 'My Group Description'

    Creates local groupwith user  'myGroup' and description 'My Group Description'

    #>

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Specifies the name of the group')]
        [string]
        $Name,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Specifies the description of the group')]
        [string]
        $Description,

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

        foreach ($connection in $serversToProcess) {
            if (-not $connection.IsConnected) {
                Write-Error "Server $connection is disconnected"
                continue
            }

            # Output is the result of 'CreateLocalGroup'
            try {
                $connection.Client.CreateLocalGroup(
                    $Name,
                    $Description
                )
            }
            catch {
                Write-Error (FormatError $_.Exception)
            }
        }
    }
}

function Set-SsoGroup {
}

function Remove-SsoGroup {
    <#
    .NOTES
    ===========================================================================
    Created on:   	5/25/2021
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================
    .DESCRIPTION
    This function removes existing local group.

    .PARAMETER Group
    Specifies the Group instance to remove.

    .EXAMPLE
    $ssoAdminConnection = Connect-SsoAdminServer -Server my.vc.server -User ssoAdmin@vsphere.local -Password 'ssoAdminStrongPa$$w0rd'
    $myNewGroup = New-SsoGroup -Server $ssoAdminConnection -Name 'myGroup'
    Remove-SsoGroup -Group $myNewGroup

    Remove plocal group with name 'myGroup'
#>
    [CmdletBinding(ConfirmImpact = 'High')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Group instance you want to remove from specified servers')]
        [VMware.vSphere.SsoAdminClient.DataTypes.Group]
        $Group)

    Process {
        try {
            foreach ($g in $Group) {
                $ssoAdminClient = $g.GetClient()
                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$g' is from disconnected server"
                    continue
                }

                $ssoAdminClient.RemoveLocalGroup($g)
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}

function Add-PrincipalToSsoGroup {
}

function Remove-PrincipalFromSsoGroup {
}

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
