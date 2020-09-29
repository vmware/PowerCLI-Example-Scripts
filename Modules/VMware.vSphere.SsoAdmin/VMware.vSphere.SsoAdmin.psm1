#
# Script module for module 'VMware.vSphere.SsoAdmin'
#
Set-StrictMode -Version Latest

$moduleFileName = 'VMware.vSphere.SsoAdmin.psd1'

# Set up some helper variables to make it easier to work with the module
$PSModule = $ExecutionContext.SessionState.Module
$PSModuleRoot = $PSModule.ModuleBase

# Import the appropriate nested binary module based on the current PowerShell version
$subModuleRoot = $PSModuleRoot

if (($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne 'Desktop')) {
   $subModuleRoot = Join-Path -Path $PSModuleRoot -ChildPath 'netcoreapp2.0'
}
else {
   $subModuleRoot = Join-Path -Path $PSModuleRoot -ChildPath 'net45'
}

$subModulePath = Join-Path -Path $subModuleRoot -ChildPath $moduleFileName
$subModule = Import-Module -Name $subModulePath -PassThru

# When the module is unloaded, remove the nested binary module that was loaded with it
$PSModule.OnRemove = {
   Remove-Module -ModuleInfo $subModule
}

# Internal helper functions
function HasWildcardSymbols {
param(
   [string]
   $stringToVerify
)
   (-not [string]::IsNullOrEmpty($stringToVerify) -and `
    ($stringToVerify -match '\*' -or `
     $stringToVerify -match '\?'))
}

function RemoveWildcardSymbols {
param(
   [string]
   $stringToProcess
)
   if (-not [string]::IsNullOrEmpty($stringToProcess)) {
      $stringToProcess.Replace('*','').Replace('?','')
   } else {
      [string]::Empty
   }
}

# Global variables
$global:DefaultSsoAdminServers = New-Object System.Collections.ArrayList

# Module Advanced Functions Implementation

#region Connection Management
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

   .PARAMETER SkipCertificateCheck
   Specifies whether server Tls certificate validation will be skipped

   .EXAMPLE
   Connect-SsoAdminServer -Server my.vc.server -User myAdmin@vsphere.local -Password MyStrongPa$$w0rd

   Connects 'myAdmin@vsphere.local' user to Sso Admin server 'my.vc.server'
#>
[CmdletBinding()]
 param(
   [Parameter(
      Mandatory=$true,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='IP address or the DNS name of the vSphere server')]
   [string]
   $Server,

   [Parameter(
      Mandatory=$true,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='User name you want to use for authenticating with the server')]
   [string]
   $User,

   [Parameter(
      Mandatory=$true,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Password you want to use for authenticating with the server')]
   [string]
   $Password,

   [Parameter(
      Mandatory=$false,
      HelpMessage='Skips server Tls certificate validation')]
   [switch]
   $SkipCertificateCheck)

   Process {
      $certificateValidator = $null
      if ($SkipCertificateCheck) {
         $certificateValidator = New-Object 'VMware.vSphere.SsoAdmin.Utils.AcceptAllX509CertificateValidator'
      }

      $ssoAdminServer = New-Object `
         'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer' `
         -ArgumentList @(
         $Server,
         $User,
         (ConvertTo-SecureString -String $Password -AsPlainText -Force),
         $certificateValidator)

      # Update $global:DefaultSsoAdminServers varaible
      $global:DefaultSsoAdminServers.Add($ssoAdminServer) | Out-Null

      # Function Output
      Write-Output $ssoAdminServer
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
      Mandatory=$true,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='SsoAdminServer object')]
   [ValidateNotNull()]
   [VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer]
   $Server)

   Process {
      if ($global:DefaultSsoAdminServers.Contains($Server)) {
         $global:DefaultSsoAdminServers.Remove($Server)
      }

      if ($Server.IsConnected) {
         $Server.Disconnect()
      }
   }
}
#endregion

#region Person User Management
function New-PersonUser {
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
   New-PersonUser -Server $ssoAdminConnection -User myAdmin -Password 'MyStrongPa$$w0rd'

   Creates person user account with user name 'myAdmin' and password 'MyStrongPa$$w0rd'

   .EXAMPLE
   New-PersonUser -User myAdmin -Password 'MyStrongPa$$w0rd' -EmailAddress 'myAdmin@mydomain.com' -FirstName 'My' -LastName 'Admin'

   Creates person user account with user name 'myAdmin', password 'MyStrongPa$$w0rd', and details against connections available in 'DefaultSsoAdminServers'
#>
[CmdletBinding(ConfirmImpact='Low')]
 param(
   [Parameter(
      Mandatory=$true,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='User name of the new person user account')]
   [string]
   $UserName,

   [Parameter(
      Mandatory=$true,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Password of the new person user account')]
   [string]
   $Password,

   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Description of the new person user account')]
   [string]
   $Description,

   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='EmailAddress of the new person user account')]
   [string]
   $EmailAddress,

   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='FirstName of the new person user account')]
   [string]
   $FirstName,

   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='LastName of the new person user account')]
   [string]
   $LastName,

   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Connected SsoAdminServer object')]
   [ValidateNotNull()]
   [VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer]
   $Server)

   Process {
      $serversToProcess = $global:DefaultSsoAdminServers
      if ($Server -ne $null) {
         $serversToProcess = $Server
      }

      foreach ($connection in $serversToProcess) {
         if (-not $connection.IsConnected) {
            Write-Error "Server $connection is disconnected"
            continue
         }

         # Output is the result of 'CreateLocalUser'
         $connection.Client.CreateLocalUser(
            $UserName,
            $Password,
            $Description,
            $EmailAddress,
            $FirstName,
            $LastName
         )
      }
   }
}

function Get-PersonUser {
<#
   .NOTES
   ===========================================================================
   Created on:   	9/29/2020
   Created by:   	Dimitar Milov
    Twitter:       @dimitar_milov
    Github:        https://github.com/dmilov
   ===========================================================================
   .DESCRIPTION
   This function gets new person user account.

   .PARAMETER Name
   Specifies Name to filter on when searching for person user accounts.

   .PARAMETER Domain
   Specifies the Domain in which search will be applied, default is 'localos'.


   .PARAMETER Server
   Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
   If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

   .EXAMPLE
   Get-PersonUser -Name admin -Domain vsphere.local

   Gets person user accounts which contain name 'admin' in 'vsphere.local' domain
#>
[CmdletBinding()]
 param(
   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Name filter to be applied when searching for person user accounts')]
   [string]
   $Name,

   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Domain name to search in, default is "localos"')]
   [string]
   $Domain = 'localos',

   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Connected SsoAdminServer object')]
   [ValidateNotNull()]
   [VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer]
   $Server)

   Process {
      $serversToProcess = $global:DefaultSsoAdminServers
      if ($Server -ne $null) {
         $serversToProcess = $Server
      }

      if ($Name -eq $null) {
         $Name = [string]::Empty
      }

      foreach ($connection in $serversToProcess) {
         if (-not $connection.IsConnected) {
            Write-Error "Server $connection is disconnected"
            continue
         }

         foreach ($personUser in $connection.Client.GetLocalUsers(
            (RemoveWildcardSymbols $Name),
            $Domain)) {


            if ([string]::IsNullOrEmpty($Name) ) {
               Write-Output $personUser
            } else {
               # Apply Name filtering
               if ((HasWildcardSymbols $Name) -and `
                   $personUser.Name -like $Name) {
                   Write-Output $personUser
               } elseif ($personUser.Name -eq $Name) {
                  # Exactly equal
                  Write-Output $personUser
               }
            }
         }
      }
   }
}

function Set-PersonUser {
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

   Nota Bene! Have in mind PersonUser objects don't carry information about the connection.
   If you specify PersonUser and on the server there is user with same Id it will be deleted.

   .PARAMETER User
   Specifies the PersonUser instance to update.

   Nota Bene! Have in mind PersonUser objects don't carry information about the connection.
   If you specify PersonUser and on the server there is user with same Id it will be deleted.

   .PARAMETER Group
   Specifies the Group you want to add or remove PwersonUser from.

   Nota Bene! Have in mind Group objects don't carry information about the connection.
   If you specify Group and on the server there is user with same Id it will be deleted.

   .PARAMETER Add
   Specifies user will be added to the spcified group.

   .PARAMETER Remove
   Specifies user will be removed from the spcified group.

   .PARAMETER Unlock
   Specifies user will be unloacked.

   .PARAMETER NewPassword
   Specifies new password for the specified user.

   .PARAMETER Server
   Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
   If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

   .EXAMPLE
   Set-PersonUser -User $myPersonUser -Group $myExampleGroup -Add -Server $ssoAdminConnection

   Adds $myPersonUser to $myExampleGroup

   .EXAMPLE
   Set-PersonUser -User $myPersonUser -Group $myExampleGroup -Remove -Server $ssoAdminConnection

   Removes $myPersonUser from $myExampleGroup

   .EXAMPLE
   Set-PersonUser -User $myPersonUser -Unlock -Server $ssoAdminConnection

   Unlocks $myPersonUser

   .EXAMPLE
   Set-PersonUser -User $myPersonUser -NewPassword 'MyBrandNewPa$$W0RD' -Server $ssoAdminConnection

   Resets $myPersonUser password
#>
[CmdletBinding(ConfirmImpact='Medium')]
 param(
   [Parameter(
      Mandatory=$true,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Person User instance you want to update')]
   [VMware.vSphere.SsoAdminClient.DataTypes.PersonUser]
   $User,

   [Parameter(
      ParameterSetName = 'AddToGroup',
      Mandatory=$true,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Group instance you want user to be added to or removed from')]
   [Parameter(
      ParameterSetName = 'RemoveFromGroup',
      Mandatory=$true,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Group instance you want user to be added to or removed from')]
   [ValidateNotNull()]
   [VMware.vSphere.SsoAdminClient.DataTypes.Group]
   $Group,

   [Parameter(
      ParameterSetName = 'AddToGroup',
      Mandatory=$true)]
   [switch]
   $Add,

   [Parameter(
      ParameterSetName = 'RemoveFromGroup',
      Mandatory=$true)]
   [switch]
   $Remove,

   [Parameter(
      ParameterSetName = 'ResetPassword',
      Mandatory=$true,
      HelpMessage='New password for the specified user.')]
   [ValidateNotNull()]
   [string]
   $NewPassword,

   [Parameter(
      ParameterSetName = 'UnlockUser',
      Mandatory=$true,
      HelpMessage='Specifies to unlock user account.')]
   [switch]
   $Unlock,

   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Connected SsoAdminServer object')]
   [ValidateNotNull()]
   [VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer]
   $Server)

   Process {
      $serversToProcess = $global:DefaultSsoAdminServers
      if ($Server -ne $null) {
         $serversToProcess = $Server
      }

      foreach ($connection in $serversToProcess) {
         if (-not $connection.IsConnected) {
            Write-Error "Server $connection is disconnected"
            continue
         }

         if ($Add) {
            $result = $connection.Client.AddPersonUserToGroup($User, $Group)
            if ($result) {
               Write-Output $User
            }
         }

         if ($Remove) {
            $result = $connection.Client.RemovePersonUserFromGroup($User, $Group)
            if ($result) {
               Write-Output $User
            }
         }

         if ($Unlock) {
            $result = $connection.Client.UnlockPersonUser($User)
            if ($result) {
               Write-Output $User
            }
         }

         if ($NewPassword) {
            $connection.Client.ResetPersonUserPassword($User, $NewPassword)
            Write-Output $User
         }
      }
   }
}

function Remove-PersonUser {
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

   Nota Bene! Have in mind PersonUser objects don't carry information about the connection.
   If you specify PersonUser and on the server there is user with same Id it will be deleted.

   .PARAMETER User
   Specifies the PersonUser instance to remove.

   Nota Bene! Have in mind PersonUser objects don't carry information about the connection.
   If you specify PersonUser and on the server there is user with same Id it will be deleted.

   .PARAMETER Server
   Specifies the vSphere Sso Admin Server on which you want to run the cmdlet.
   If not specified the servers available in $global:DefaultSsoAdminServers variable will be used.

   .EXAMPLE
   $ssoAdminConnection = Connect-SsoAdminServer -Server my.vc.server -User ssoAdmin@vsphere.local -Password 'ssoAdminStrongPa$$w0rd'
   $myNewPersonUser = New-PersonUser -Server $ssoAdminConnection -User myAdmin -Password 'MyStrongPa$$w0rd'
   Remove-PersonUser -User $myNewPersonUser -Server $ssoAdminConnection

   Remove person user account with user name 'myAdmin' and password 'MyStrongPa$$w0rd'

   .EXAMPLE
   New-PersonUser -User myAdmin -Password 'MyStrongPa$$w0rd' -EmailAddress 'myAdmin@mydomain.com' -FirstName 'My' -LastName 'Admin'

   Creates person user account with user name 'myAdmin', password 'MyStrongPa$$w0rd', and details against connections available in 'DefaultSsoAdminServers'
#>
[CmdletBinding(ConfirmImpact='High')]
 param(
   [Parameter(
      Mandatory=$true,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Person User instance you want to remove from specified servers')]
   [VMware.vSphere.SsoAdminClient.DataTypes.PersonUser]
   $User,

   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Connected SsoAdminServer object')]
   [ValidateNotNull()]
   [VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer]
   $Server)

   Process {
      $serversToProcess = $global:DefaultSsoAdminServers
      if ($Server -ne $null) {
         $serversToProcess = $Server
      }

      foreach ($connection in $serversToProcess) {
         if (-not $connection.IsConnected) {
            Write-Error "Server $connection is disconnected"
            continue
         }

         $connection.Client.DeleteLocalUser($User)
      }
   }
}
#endregion

#region Group cmdlets
function Get-Group {
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
   Get-Group -Name administrators -Domain vsphere.local

   Gets 'adminsitrators' group in 'vsphere.local' domain
#>
[CmdletBinding()]
 param(
   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Name filter to be applied when searching for group')]
   [string]
   $Name,

   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Domain name to search in, default is "localos"')]
   [string]
   $Domain = 'localos',

   [Parameter(
      Mandatory=$false,
      ValueFromPipeline=$false,
      ValueFromPipelineByPropertyName=$false,
      HelpMessage='Connected SsoAdminServer object')]
   [ValidateNotNull()]
   [VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer]
   $Server)

   Process {
      $serversToProcess = $global:DefaultSsoAdminServers
      if ($Server -ne $null) {
         $serversToProcess = $Server
      }

      if ($Name -eq $null) {
         $Name = [string]::Empty
      }

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
            } else {
               # Apply Name filtering
               if ((HasWildcardSymbols $Name) -and `
                   $group.Name -like $Name) {
                   Write-Output $group
               } elseif ($group.Name -eq $Name) {
                  # Exactly equal
                  Write-Output $group
               }
            }
         }
      }
   }
}
#endregion