<#
Copyright 2021 VMware, Inc.
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
    Specifies an optional description of the group.

    .PARAMETER Server
    Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
    If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

    .EXAMPLE
    New-SsoGroup -Name 'myGroup' -Description 'My Group Description'

    Creates a local group with name 'myGroup' and description 'My Group Description'

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

       .PARAMETER Group
        Specifies the group in which search for person user members will be applied.

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
            ParameterSetName = 'ByNameAndDomain',
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Domain name to search in, default is "localos"')]
        [string]
        $Domain = 'localos',

        [Parameter(
            ParameterSetName = 'ByGroup',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Searches group members of the specified group')]
        [VMware.vSphere.SsoAdminClient.DataTypes.Group]
        $Group,

        [Parameter(
            ParameterSetName = 'ByNameAndDomain',
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

        if ($null -eq $Name) {
            $Name = [string]::Empty
        }

        try {
            if ($null -ne $Group) {

                foreach ($g in $Group) {
                    $ssoAdminClient = $g.GetClient()
                    if ((-not $ssoAdminClient)) {
                        Write-Error "Object '$g' is from disconnected server"
                        continue
                    }

                    foreach ($resultGroup in $ssoAdminClient.GetGroupsInGroup(
                            (RemoveWildcardSymbols $Name),
                            $Group)) {

                        if ([string]::IsNullOrEmpty($Name) ) {
                            Write-Output $resultGroup
                        }
                        else {
                            # Apply Name filtering
                            if ((HasWildcardSymbols $Name) -and `
                                    $resultGroup.Name -like $Name) {
                                Write-Output $resultGroup
                            }
                            elseif ($resultGroup.Name -eq $Name) {
                                # Exactly equal
                                Write-Output $resultGroup
                            }
                        }
                    }
                }

            } else {
                foreach ($connection in $serversToProcess) {
                    if (-not $connection.IsConnected) {
                        Write-Error "Server $connection is disconnected"
                        continue
                    }

                    foreach ($resultGroup in $connection.Client.GetGroups(
                            (RemoveWildcardSymbols $Name),
                            $Domain)) {


                        if ([string]::IsNullOrEmpty($Name) ) {
                            Write-Output $resultGroup
                        }
                        else {
                            # Apply Name filtering
                            if ((HasWildcardSymbols $Name) -and `
                                    $resultGroup.Name -like $Name) {
                                Write-Output $resultGroup
                            }
                            elseif ($resultGroup.Name -eq $Name) {
                                # Exactly equal
                                Write-Output $resultGroup
                            }
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

function Set-SsoGroup {
    <#
    .NOTES
       ===========================================================================
       Created on:   	5/25/2021
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================

    .SYNOPSIS
    Updates Local Sso Group

    .DESCRIPTION
    Updates Local Sso Group details

    .PARAMETER Group
    Specifies the group instace to update.

    .PARAMETER Description
    Specifies a description of the group.

    .EXAMPLE
    $myGroup = New-SsoGroup -Name 'myGroup'
    $myGroup | Set-SsoGroup -Description 'My Group Description'

    Updates local group $myGroup with description 'My Group Description'

    #>

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Group instance you want to update')]
        [VMware.vSphere.SsoAdminClient.DataTypes.Group]
        $Group,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Specifies the description of the group')]
        [string]
        $Description)

    Process {
        try {
            foreach ($g in $Group) {
                $ssoAdminClient = $g.GetClient()
                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$g' is from disconnected server"
                    continue
                }

                $ssoAdminClient.UpdateLocalGroup($g, $Description)
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
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
            HelpMessage = 'Group instance you want to remove')]
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

function Add-GroupToSsoGroup {
    <#
    .NOTES
    ===========================================================================
    Created on:   	5/26/2021
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================


    .SYNOPSIS
    Adds a group to another group

    .DESCRIPTION
    Adds the specified group on $Group parameter to target group specified on $TargetGroup parameter

    .PARAMETER Group
    A Group instance to be added to the $TargetGroup

    .PARAMETER TargetGroup
    A target group to which the $Group will be added.

    .EXAMPLE
    $administratosGroup = Get-SsoGroup -Name 'Administrators' -Domain 'vsphere.local'
    Get-SsoGroup -Name 'TestGroup' -Domain 'MyDomain' | Add-GroupToSsoGroup -TargetGroup $administratosGroup

    Adds 'TestGroup' from 'MyDomain' domain to vsphere.local Administrators group.
    #>
    [CmdletBinding(ConfirmImpact = 'Medium')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'SsoGroup instance you want to add to the target group')]
        [VMware.vSphere.SsoAdminClient.DataTypes.Group]
        $Group,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Target SsoGroup instance where the $Group wtill be added')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.Group]
        $TargetGroup)

    Process {
        try {
            foreach ($g in $Group) {
                $ssoAdminClient = $g.GetClient()
                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$g' is from disconnected server"
                    continue
                }

                if ($g.GetClient().ServiceUri -ne $TargetGroup.GetClient().ServiceUri) {
                    Write-Error "Group '$g' is not from the same server as the target group"
                    continue
                }

                $result = $ssoAdminClient.AddGroupToGroup($g, $TargetGroup)
                if (-not $result) {
                    Write-Error "Group '$g' was not added to the target group. The Server operation result doesn't indicate success"
                    continue
                }
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}

function Remove-GroupFromSsoGroup {
    <#
    .NOTES
    ===========================================================================
    Created on:   	5/26/2021
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================


    .SYNOPSIS
    Removes a group to another group

    .DESCRIPTION
    Removes the specified group on $Group parameter from target group specified on $TargetGroup parameter

    .PARAMETER Group
    A Group instance to be removed from the $TargetGroup

    .PARAMETER TargetGroup
    A target group from which the $Group will be removed.

    .EXAMPLE
    $administratosGroup = Get-SsoGroup -Name 'Administrators' -Domain 'vsphere.local'
    Get-SsoGroup -Name 'TestGroup' -Domain 'MyDomain' | Remove-GroupFromSsoGroup -TargetGroup $administratosGroup

    Removes 'TestGroup' from 'MyDomain' domain from vsphere.local Administrators group.
    #>
    [CmdletBinding(ConfirmImpact = 'Medium')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'SsoGroup instance you want to remove from the target group')]
        [VMware.vSphere.SsoAdminClient.DataTypes.Group]
        $Group,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Target SsoGroup instance from which the $Group wtill be removed')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.Group]
        $TargetGroup)

    Process {
        try {
            foreach ($g in $Group) {
                $ssoAdminClient = $g.GetClient()
                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$g' is from disconnected server"
                    continue
                }

                if ($g.GetClient().ServiceUri -ne $TargetGroup.GetClient().ServiceUri) {
                    Write-Error "Group '$g' is not from the same server as the target group"
                    continue
                }

                $result = $ssoAdminClient.RemoveGroupFromGroup($g, $TargetGroup)
                if (-not $result) {
                    Write-Error "Group '$g' was not removed to the target group. The Server operation result doesn't indicate success"
                    continue
                }
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}

function Add-UserToSsoGroup {
    <#
    .NOTES
    ===========================================================================
    Created on:   	5/26/2021
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================


    .SYNOPSIS
    Adds an user to a group

    .DESCRIPTION
    Adds the user on $User parameter to target group specified on $TargetGroup parameter

    .PARAMETER User
    A PersonUser instance to be added to the $TargetGroup

    .PARAMETER TargetGroup
    A target group to which the $User will be added.

    .EXAMPLE
    $administratosGroup = Get-SsoGroup -Name 'Administrators' -Domain 'vsphere.local'
    Get-SsoPersonUser -Name 'TestUser' -Domain 'MyDomain' | Add-UserToSsoGroup -TargetGroup $administratosGroup

    Adds 'TestUser' from 'MyDomain' domain to vsphere.local Administrators group.
    #>
    [CmdletBinding(ConfirmImpact = 'Medium')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'PersonUser instance you want to add to the target group')]
        [VMware.vSphere.SsoAdminClient.DataTypes.PersonUser]
        $User,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Target SsoGroup instance where the $Group wtill be added')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.Group]
        $TargetGroup)

    Process {
        try {
            foreach ($u in $User) {
                $ssoAdminClient = $u.GetClient()
                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$u' is from disconnected server"
                    continue
                }

                if ($u.GetClient().ServiceUri -ne $TargetGroup.GetClient().ServiceUri) {
                    Write-Error "User '$u' is not from the same server as the target group"
                    continue
                }

                $result = $ssoAdminClient.AddPersonUserToGroup($u, $TargetGroup)
                if (-not $result) {
                    Write-Error "User '$u' was not added to the target group. The Server operation result doesn't indicate success"
                    continue
                }
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}

function Remove-UserFromSsoGroup {
    <#
    .NOTES
    ===========================================================================
    Created on:   	5/26/2021
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================


    .SYNOPSIS
    Removes a person user from group

    .DESCRIPTION
    Removes the specified person user on $User parameter from target group specified on $TargetGroup parameter

    .PARAMETER User
    A PersonUser instance to be removed from the $TargetGroup

    .PARAMETER TargetGroup
    A target group from which the $User will be removed.

    .EXAMPLE
    $administratosGroup = Get-SsoGroup -Name 'Administrators' -Domain 'vsphere.local'
    Get-SsoPersonUser -Name 'TestUser' -Domain 'MyDomain' | Remove-UserFromSsoGroup -TargetGroup $administratosGroup

    Removes 'TestUser' from 'MyDomain' domain from vsphere.local Administrators group.
    #>
    [CmdletBinding(ConfirmImpact = 'Medium')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'PersonUser instance you want to remove from the target group')]
        [VMware.vSphere.SsoAdminClient.DataTypes.PersonUser]
        $User,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Target SsoGroup instance from which the $User wtill be removed')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.Group]
        $TargetGroup)

    Process {
        try {
            foreach ($u in $User) {
                $ssoAdminClient = $u.GetClient()
                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$u' is from disconnected server"
                    continue
                }

                if ($u.GetClient().ServiceUri -ne $TargetGroup.GetClient().ServiceUri) {
                    Write-Error "User '$u' is not from the same server as the target group"
                    continue
                }

                $result = $ssoAdminClient.RemovePersonUserFromGroup($u, $TargetGroup)
                if (-not $result) {
                    Write-Error "User '$u' was not removed to the target group. The Server operation result doesn't indicate success"
                    continue
                }
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}
