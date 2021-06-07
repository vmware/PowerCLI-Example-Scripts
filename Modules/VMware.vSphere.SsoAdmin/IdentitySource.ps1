<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

function Add-ExternalDomainIdentitySource {
    <#
       .NOTES
       ===========================================================================
       Created on:   	2/11/2021
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function adds Identity Source of ActiveDirectory, OpenLDAP or NIS type.

       .PARAMETER Name
       Name of the identity source

       .PARAMETER DomainName
       Domain name

       .PARAMETER DomainAlias
       Domain alias

       .PARAMETER PrimaryUrl
       Primary Server URL

       .PARAMETER BaseDNUsers
       Base distinguished name for users

       .PARAMETER BaseDNGroups
       Base distinguished name for groups

       .PARAMETER Username
       Domain authentication user name

       .PARAMETER Passowrd
       Domain authentication password

       .PARAMETER DomainServerType
       Type of the ExternalDomain, one of 'ActiveDirectory','OpenLdap','NIS'

       .PARAMETER Server
       Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
       If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

       .EXAMPLE
       Add-ExternalDomainIdentitySource `
          -Name 'sof-powercli' `
          -DomainName 'sof-powercli.vmware.com' `
          -DomainAlias 'sof-powercli' `
          -PrimaryUrl 'ldap://sof-powercli.vmware.com:389' `
          -BaseDNUsers 'CN=Users,DC=sof-powercli,DC=vmware,DC=com' `
          -BaseDNGroups 'CN=Users,DC=sof-powercli,DC=vmware,DC=com' `
          -Username 'sofPowercliAdmin' `
          -Password '$up3R$Tr0Pa$$w0rD'

       Adds External Identity Source
    #>
    [CmdletBinding()]
    [Alias("Add-ActiveDirectoryIdentitySource")]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Friendly name of the identity source')]
        [ValidateNotNull()]
        [string]
        $Name,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [ValidateNotNull()]
        [string]
        $DomainName,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [string]
        $DomainAlias,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [ValidateNotNull()]
        [string]
        $PrimaryUrl,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Base distinguished name for users')]
        [ValidateNotNull()]
        [string]
        $BaseDNUsers,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Base distinguished name for groups')]
        [ValidateNotNull()]
        [string]
        $BaseDNGroups,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Domain authentication user name')]
        [ValidateNotNull()]
        [string]
        $Username,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Domain authentication password')]
        [ValidateNotNull()]
        [string]
        $Password,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'External domain server type')]
        [ValidateSet('ActiveDirectory')]
        [string]
        $DomainServerType = 'ActiveDirectory',

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Connected SsoAdminServer object')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer]
        $Server)

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

            $connection.Client.AddActiveDirectoryExternalDomain(
                $DomainName,
                $DomainAlias,
                $Name,
                $PrimaryUrl,
                $BaseDNUsers,
                $BaseDNGroups,
                $Username,
                $Password,
                $DomainServerType);
        }
    }
    catch {
        Write-Error (FormatError $_.Exception)
    }
}

function Add-LDAPIdentitySource {
    <#
       .NOTES
       ===========================================================================
       Created on:   	2/11/2021
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function adds LDAP Identity Source of ActiveDirectory, OpenLDAP or NIS type.

       .PARAMETER Name
       Friendly name of the identity source

       .PARAMETER DomainName
       Domain name

       .PARAMETER DomainAlias
       Domain alias

       .PARAMETER PrimaryUrl
       Primary Server URL

       .PARAMETER SecondaryUrl
       Secondary Server URL

       .PARAMETER BaseDNUsers
       Base distinguished name for users

       .PARAMETER BaseDNGroups
       Base distinguished name for groups

       .PARAMETER Username
       Domain authentication user name

       .PARAMETER Passowrd
       Domain authentication password

       .PARAMETER ServerType
       Type of the ExternalDomain, one of 'ActiveDirectory','OpenLdap','NIS'

       .PARAMETER Certificates
       List of X509Certicate2 LDAP certificates

       .PARAMETER Server
       Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
       If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

       Adds LDAP Identity Source

       .EXAMPLE
       Add-LDAPIdentitySource `
          -Name 'sof-powercli' `
          -DomainName 'sof-powercli.vmware.com' `
          -DomainAlias 'sof-powercli' `
          -PrimaryUrl 'ldap://sof-powercli.vmware.com:389' `
          -BaseDNUsers 'CN=Users,DC=sof-powercli,DC=vmware,DC=com' `
          -BaseDNGroups 'CN=Users,DC=sof-powercli,DC=vmware,DC=com' `
          -Username 'sofPowercliAdmin@sof-powercli.vmware.com' `
          -Password '$up3R$Tr0Pa$$w0rD' `
          -Certificates 'C:\Temp\test.cer'
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Friendly name of the identity source')]
        [ValidateNotNull()]
        [string]
        $Name,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [ValidateNotNull()]
        [string]
        $DomainName,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [string]
        $DomainAlias,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [string]
        $SecondaryUrl,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [ValidateNotNull()]
        [string]
        $PrimaryUrl,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Base distinguished name for users')]
        [ValidateNotNull()]
        [string]
        $BaseDNUsers,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Base distinguished name for groups')]
        [ValidateNotNull()]
        [string]
        $BaseDNGroups,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Domain authentication user name')]
        [ValidateNotNull()]
        [string]
        $Username,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Domain authentication password')]
        [ValidateNotNull()]
        [string]
        $Password,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Ldap Certificates')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2[]]
        $Certificates,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Ldap Server type')]
        [ValidateSet('ActiveDirectory')]
        [string]
        $ServerType = 'ActiveDirectory',

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Connected SsoAdminServer object')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer]
        $Server)

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

            $connection.Client.AddLdapIdentitySource(
                $DomainName,
                $DomainAlias,
                $Name,
                $PrimaryUrl,
                $SecondaryUrl,
                $BaseDNUsers,
                $BaseDNGroups,
                $Username,
                $Password,
                $ServerType,
                $Certificates);
        }
    }
    catch {
        Write-Error (FormatError $_.Exception)
    }
}

function Set-LDAPIdentitySource {
    <#
       .NOTES
       ===========================================================================
       Created on:   	2/17/2021
       Created by:   	Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function adds LDAP Identity Source of ActiveDirectory, OpenLDAP or NIS type.

       .PARAMETER IdentitySource
       Identity Source to update

       .PARAMETER Certificates
       List of X509Certicate2 LDAP certificates

       .PARAMETER Server
       Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
       If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

       Updates LDAP Identity Source

       .EXAMPLE

       Updates certificate of a LDAP identity source

       Get-IdentitySource -External | `
       Set-LDAPIdentitySource `
          -Certificates 'C:\Temp\test.cer'
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Identity source to update')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.ActiveDirectoryIdentitySource]
        $IdentitySource,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Ldap Certificates')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2[]]
        $Certificates,

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

                $connection.Client.UpdateLdapIdentitySource(
                    $IdentitySource.Name,
                    $IdentitySource.FriendlyName,
                    $IdentitySource.PrimaryUrl,
                    $IdentitySource.FailoverUrl,
                    $IdentitySource.UserBaseDN,
                    $IdentitySource.GroupBaseDN,
                    $Certificates);
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}

function Get-IdentitySource {
    <#
       .NOTES
       ===========================================================================
       Created on:   11/26/2020
       Created by:   Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function gets Identity Source.

       .PARAMETER Localos
       Filter parameter to return only the localos domain identity source

       .PARAMETER System
       Filter parameter to return only the system domain identity source

       .PARAMETER External
       Filter parameter to return only the external domain identity sources

       .PARAMETER Server
       Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
       If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

       .EXAMPLE
       Get-IdentitySource -External

       Gets all external domain identity source
    #>
    [CmdletBinding()]
    param(

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Returns only the localos domain identity source')]
        [Switch]
        $Localos,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Returns only the system domain identity source')]
        [Switch]
        $System,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Returns only the external domain identity sources')]
        [Switch]
        $External,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Connected SsoAdminServer object')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer]
        $Server)

    $serversToProcess = $global:DefaultSsoAdminServers.ToArray()
    if ($Server -ne $null) {
        $serversToProcess = $Server
    }
    foreach ($connection in $serversToProcess) {
        if (-not $connection.IsConnected) {
            Write-Error "Server $connection is disconnected"
            continue
        }

        $resultIdentitySources = @()
        $allIdentitySources = $connection.Client.GetDomains()

        if (-not $Localos -and -not $System -and -not $External) {
            $resultIdentitySources = $allIdentitySources
        }

        if ($Localos) {
            $resultIdentitySources += $allIdentitySources | Where-Object { $_ -is [VMware.vSphere.SsoAdminClient.DataTypes.LocalOSIdentitySource] }
        }

        if ($System) {
            $resultIdentitySources += $allIdentitySources | Where-Object { $_ -is [VMware.vSphere.SsoAdminClient.DataTypes.SystemIdentitySource] }
        }

        if ($External) {
            $resultIdentitySources += $allIdentitySources | Where-Object { $_ -is [VMware.vSphere.SsoAdminClient.DataTypes.ActiveDirectoryIdentitySource] }
        }

        #Return result
        $resultIdentitySources
    }
}

function Remove-IdentitySource {
    <#
       .NOTES
       ===========================================================================
       Created on:   03/19/2021
       Created by:   Dimitar Milov
        Twitter:       @dimitar_milov
        Github:        https://github.com/dmilov
       ===========================================================================
       .DESCRIPTION
       This function removes Identity Source.

       .PARAMETER IdentitySource
       The identity source to remove

       .PARAMETER Server
       Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
       If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

       .EXAMPLE
       Get-IdentitySource -External | Remove-IdentitySource

       Removes all external domain identity source
    #>
    [CmdletBinding()]
    param(

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Identity source to remove')]
        [ValidateNotNull()]
        [VMware.vSphere.SsoAdminClient.DataTypes.IdentitySource]
        $IdentitySource,

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

                $connection.Client.DeleteDomain($IdentitySource.Name)
            }
        }
        catch {
            Write-Error (FormatError $_.Exception)
        }
    }
}
