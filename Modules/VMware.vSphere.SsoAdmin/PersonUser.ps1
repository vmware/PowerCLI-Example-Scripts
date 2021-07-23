<#
Copyright 2020-2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function New-SsoPersonUser {
    <#
    .NOTES
    ===========================================================================
    Created on:   	9/29/2020
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================
    .DESCRIPTION
    This function creates new person user account.

    .PARAMETER UserName
    Specifies the UserName of the requested person user account.

    .PARAMETER Password
    Specifies the Password of the requested person user account.

    .PARAMETER Description
    Specifies the Description of the requested person user account.

    .PARAMETER EmailAddress
    Specifies the EmailAddress of the requested person user account.

    .PARAMETER FirstName
    Specifies the FirstName of the requested person user account.

    .PARAMETER LastName
    Specifies the FirstName of the requested person user account.

    .PARAMETER Server
    Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
    If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

    .EXAMPLE
    $ssoAdminConnection = Connect-SsoAdminServer -Server my.vc.server -User ssoAdmin@vsphere.local -Password 'ssoAdminStrongPa$$w0rd'
    New-SsoPersonUser -Server $ssoAdminConnection -User myAdmin -Password 'MyStrongPa$$w0rd'

    Creates person user account with user name 'myAdmin' and password 'MyStrongPa$$w0rd'

    .EXAMPLE
    New-SsoPersonUser -User myAdmin -Password 'MyStrongPa$$w0rd' -EmailAddress 'myAdmin@mydomain.com' -FirstName 'My' -LastName 'Admin'

    Creates person user account with user name 'myAdmin', password 'MyStrongPa$$w0rd', and details against connections available in 'DefaultSsoAdminServers'
#>
    [CmdletBinding(ConfirmImpact = 'Low')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'User name of the new person user account')]
        [string]
        $UserName,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Password of the new person user account')]
        [string]
        $Password,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Description of the new person user account')]
        [string]
        $Description,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'EmailAddress of the new person user account')]
        [string]
        $EmailAddress,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'FirstName of the new person user account')]
        [string]
        $FirstName,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'LastName of the new person user account')]
        [string]
        $LastName,

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

            # Output is the result of 'CreateLocalUser'
            try {
                $connection.Client.CreateLocalUser(
                    $UserName,
                    $Password,
                    $Description,
                    $EmailAddress,
                    $FirstName,
                    $LastName
                )
            }
            catch {
                Write-Error (FormatError $_.Exception)
            }
        }
    }
}

function Get-SsoPersonUser {
    <#
    .NOTES
    ===========================================================================
    Created on:   	9/29/2020
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================
    .DESCRIPTION
    This function gets person user account.

    .PARAMETER Name
    Specifies Name to filter on when searching for person user accounts.

    .PARAMETER Domain
    Specifies the Domain in which search will be applied, default is 'localos'.

    .PARAMETER Group
    Specifies the group in which search for person user members will be applied.

    .PARAMETER Server
    Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
    If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

    .EXAMPLE
    Get-SsoPersonUser -Name admin -Domain vsphere.local

    Gets person user accounts which contain name 'admin' in 'vsphere.local' domain

    .EXAMPLE
    Get-SsoGroup -Name 'Administrators' -Domain 'vsphere.local' | Get-SsoPersonUser

    Gets person user accounts members of 'Administrators' group
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Name filter to be applied when searching for person user accounts')]
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
            HelpMessage = 'Searches members of the specified group')]
        [VMware.vSphere.SsoAdminClient.DataTypes.Group]
        $Group,

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

                $personUsers = $null

                if ($Group -ne $null) {
                    $personUsers = $connection.Client.GetPersonUsersInGroup(
                        (RemoveWildcardSymbols $Name),
                        $Group)
                }
                else {
                    $personUsers = $connection.Client.GetLocalUsers(
                        (RemoveWildcardSymbols $Name),
                        $Domain)
                }

                if ($personUsers -ne $null) {
                    foreach ($personUser in $personUsers) {
                        if ([string]::IsNullOrEmpty($Name) ) {
                            Write-Output $personUser
                        }
                        else {
                            # Apply Name filtering
                            if ((HasWildcardSymbols $Name) -and `
                                    $personUser.Name -like $Name) {
                                Write-Output $personUser
                            }
                            elseif ($personUser.Name -eq $Name) {
                                # Exactly equal
                                Write-Output $personUser
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

function Set-SsoPersonUser {
    <#
    .NOTES
    ===========================================================================
    Created on:   	9/29/2020
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================
    .DESCRIPTION
    Updates person user account.

    .PARAMETER User
    Specifies the PersonUser instance to update.

    .PARAMETER Group
    Specifies the Group you want to add or remove PwersonUser from.

    .PARAMETER Add
    Specifies user will be added to the spcified group.

    .PARAMETER Remove
    Specifies user will be removed from the spcified group.

    .PARAMETER Unlock
    Specifies user will be unlocked.

    .PARAMETER NewPassword
    Specifies new password for the specified user.

    .PARAMETER Enable
    Specifies user to be enabled or disabled.

    .EXAMPLE
    Set-SsoPersonUser -User $myPersonUser -Group $myExampleGroup -Add -Server $ssoAdminConnection

    Adds $myPersonUser to $myExampleGroup

    .EXAMPLE
    Set-SsoPersonUser -User $myPersonUser -Group $myExampleGroup -Remove -Server $ssoAdminConnection

    Removes $myPersonUser from $myExampleGroup

    .EXAMPLE
    Set-SsoPersonUser -User $myPersonUser -Unlock -Server $ssoAdminConnection

    Unlocks $myPersonUser

     .EXAMPLE
    Set-SsoPersonUser -User $myPersonUser -Enable $false -Server $ssoAdminConnection

    Disable user account

    .EXAMPLE
    Set-SsoPersonUser -User $myPersonUser -NewPassword 'MyBrandNewPa$$W0RD' -Server $ssoAdminConnection

    Resets $myPersonUser password
#>
    [CmdletBinding(ConfirmImpact = 'Medium')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Person User instance you want to update')]
        [VMware.vSphere.SsoAdminClient.DataTypes.PersonUser]
        $User,

        [Parameter(
            ParameterSetName = 'AddToGroup',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Group instance you want user to be added to or removed from')]
        [Parameter(
            ParameterSetName = 'RemoveFromGroup',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Group instance you want user to be added to or removed from')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.Group]
        $Group,

        [Parameter(
            ParameterSetName = 'AddToGroup',
            Mandatory = $true)]
        [switch]
        $Add,

        [Parameter(
            ParameterSetName = 'RemoveFromGroup',
            Mandatory = $true)]
        [switch]
        $Remove,

        [Parameter(
            ParameterSetName = 'ResetPassword',
            Mandatory = $true,
            HelpMessage = 'New password for the specified user.')]
        [ValidateNotNull()]
        [string]
        $NewPassword,

        [Parameter(
            ParameterSetName = 'UnlockUser',
            Mandatory = $true,
            HelpMessage = 'Specifies to unlock user account.')]
        [switch]
        $Unlock,

        [Parameter(
            ParameterSetName = 'EnableDisableUserAccount',
            Mandatory = $true,
            HelpMessage = 'Specifies to enable or disable user account.')]
        [bool]
        $Enable)

    Process {
        try {
            foreach ($u in $User) {
                $ssoAdminClient = $u.GetClient()
                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$u' is from disconnected server"
                    continue
                }

                if ($Add) {
                    $result = $ssoAdminClient.AddPersonUserToGroup($u, $Group)
                    if ($result) {
                        Write-Output $u
                    }
                }

                if ($Remove) {
                    $result = $ssoAdminClient.RemovePersonUserFromGroup($u, $Group)
                    if ($result) {
                        Write-Output $u
                    }
                }

                if ($Unlock) {
                    $result = $ssoAdminClient.UnlockPersonUser($u)
                    if ($result) {
                        Write-Output $u
                    }
                }

                if ($NewPassword) {
                    $ssoAdminClient.ResetPersonUserPassword($u, $NewPassword)
                    Write-Output $u
                }

                if ($PSBoundParameters.ContainsKey('Enable')) {
                    $result = $false
                    if ($Enable) {
                        $result = $ssoAdminClient.EnablePersonUser($u)
                    } else {
                        $result = $ssoAdminClient.DisablePersonUser($u)
                    }
                    if ($result) {
                        # Return update person user
                        Write-Output ($ssoAdminClient.GetLocalUsers($u.Name, $u.Domain))
                    }
                }
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}

function Set-SsoSelfPersonUserPassword {
    <#
    .NOTES
    ===========================================================================
    Created on:   	2/19/2021
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================
    .DESCRIPTION
    Resets connected person user password.


    .PARAMETER NewPassword
    Specifies new password for the connected person user.


    .EXAMPLE
    Set-SsoSelfPersonUserPassword -Password 'MyBrandNewPa$$W0RD' -Server $ssoAdminConnection

    Resets password
#>
    [CmdletBinding(ConfirmImpact = 'High')]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'New password for the connected user.')]
        [ValidateNotNull()]
        [SecureString]
        $Password,

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

            try {
                $connection.Client.ResetSelfPersonUserPassword($Password)
            }
            catch {
                Write-Error (FormatError $_.Exception)
            }
        }
    }
}

function Remove-SsoPersonUser {
    <#
    .NOTES
    ===========================================================================
    Created on:   	9/29/2020
    Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
    ===========================================================================
    .DESCRIPTION
    This function removes existing person user account.

    .PARAMETER User
    Specifies the PersonUser instance to remove.

    .EXAMPLE
    $ssoAdminConnection = Connect-SsoAdminServer -Server my.vc.server -User ssoAdmin@vsphere.local -Password 'ssoAdminStrongPa$$w0rd'
    $myNewPersonUser = New-SsoPersonUser -Server $ssoAdminConnection -User myAdmin -Password 'MyStrongPa$$w0rd'
    Remove-SsoPersonUser -User $myNewPersonUser

    Remove person user account with user name 'myAdmin'
#>
    [CmdletBinding(ConfirmImpact = 'High')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Person User instance you want to remove')]
        [VMware.vSphere.SsoAdminClient.DataTypes.PersonUser]
        $User)

    Process {
        try {
            foreach ($u in $User) {
                $ssoAdminClient = $u.GetClient()
                if ((-not $ssoAdminClient)) {
                    Write-Error "Object '$u' is from disconnected server"
                    continue
                }

                $ssoAdminClient.DeleteLocalUser($u)
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}
