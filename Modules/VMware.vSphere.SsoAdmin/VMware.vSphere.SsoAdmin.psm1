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

# Global variables
$global:DefaultSsoAdminServers = New-Object System.Collections.ArrayList

# Module Advanced Functions Implementation

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
   $mySsoAdminConnection = Connect-SsoAdminServer -Server my.vc.server -User myAdmin@vsphere.local -Password MyStrongPa$$w0rd
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