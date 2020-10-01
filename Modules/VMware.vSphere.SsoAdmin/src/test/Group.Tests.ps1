# **************************************************************************
#  Copyright 2020 VMware, Inc.
# **************************************************************************

param(
    [Parameter(Mandatory = $true)]
    [string]
    $VcAddress,

    [Parameter(Mandatory = $true)]
    [string]
    $User,

    [Parameter(Mandatory = $true)]
    [string]
    $Password
)

# Import Vmware.vSphere.SsoAdmin Module
$modulePath = Join-Path (Split-Path $PSScriptRoot | Split-Path) "VMware.vSphere.SsoAdmin.psd1"
Import-Module $modulePath

Describe "Get-Group Tests" {
   BeforeEach {
      Connect-SsoAdminServer `
         -Server $VcAddress `
         -User $User `
         -Password $Password `
         -SkipCertificateCheck
   }

   AfterEach {
      $connectionsToCleanup = $global:DefaultSsoAdminServers.ToArray()
      foreach ($connection in $connectionsToCleanup) {
         Disconnect-SsoAdminServer -Server $connection
      }
   }

   Context "Get-Group" {
      It 'Gets groups without filters' {
         # Act
         $actual = Get-Group

         # Assert
         $actual | Should Not Be $null
         $actual.Count | Should BeGreaterThan 0
         $actual[0].Name | Should Not Be $null
         $actual[0].Domain | Should Be 'localos'
      }

      It 'Gets groups for default domain' {
         # Arrange
         $newUserName = "NewUser1"
         $password = '$tr0NG_TestPa$$w0rd'

         ## Create Person User to determine default domain name
         ## Person Users are created in the default domain
         $newPersonUser = New-PersonUser `
            -UserName $newUserName `
            -Password $password

         # Act
         $actual = Get-Group `
            -Domain $newPersonUser.Domain

         # Assert
         $actual | Should Not Be $null
         $actual.Count | Should BeGreaterThan 0
         $actual[0].Name | Should Not Be $null
         $actual[0].Domain | Should Be $newPersonUser.Domain

         # Cleanup
         Remove-PersonUser -User $newPersonUser
      }
   }
}