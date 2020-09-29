#**************************************************************************
# Copyright (c) VMware, Inc. All rights reserved.
#**************************************************************************

param(
    [Parameter(Mandatory = $true)]
    [string]
    $VcAddress,

    [Parameter(Mandatory = $true)]
    [string]
    $VcUser,

    [Parameter(Mandatory = $true)]
    [string]
    $VcUserPassword
)

# Import Vmware.vSphere.SsoAdmin Module
$modulePath = Join-Path (Split-Path $PSScriptRoot | Split-Path) "VMware.vSphere.SsoAdmin.psd1"
Import-Module $modulePath

Describe "New-PersonUser, Remove-PersonUser Tests" {
   BeforeEach {
      $script:usersToCleanup = @()
   }
   AfterEach {
      foreach ($user in $script:usersToCleanup) {
         Remove-PersonUser -User $user
      }

      $connectionsToCleanup = $global:DefaultSsoAdminServers.ToArray()
      foreach ($connection in $connectionsToCleanup) {
         Disconnect-SsoAdminServer -Server $connection
      }
   }

   Context "New-PersonUser" {
      It 'Creates person user with details' {
         # Arrange
         $expectedUserName = "TestPersonUser1"
         $expectedPassword = '$tr0NG_TestPa$$w0rd'
         $expectedDescription = "Test Description"
         $expectedEmailAddress = "testuser@testdomain.com"
         $expectedFirstName = "Test"
         $expectedLastName = "User"
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $VcUser `
            -Password $VcUserPassword `
            -SkipCertificateCheck

         # Act
         $actual = New-PersonUser `
            -Server $connection `
            -UserName $expectedUserName `
            -Password $expectedPassword `
            -Description $expectedDescription `
            -EmailAddress $expectedEmailAddress `
            -FirstName $expectedFirstName `
            -LastName $expectedLastName

         $script:usersToCleanup += $actual

         # Assert
         $actual | Should Not Be $null
         $actual.GetType().FullName | Should Be 'VMware.vSphere.SsoAdminClient.DataTypes.PersonUser'
         $actual.Name | Should Be $expectedUserName
         $actual.Domain | Should Not Be $null
         $actual.Description | Should Be $expectedDescription
         $actual.FirstName | Should Be $expectedFirstName
         $actual.LastName | Should Be $expectedLastName
         $actual.EmailAddress | Should Be $expectedEmailAddress
      }

      It 'Creates person user without details' {
         # Arrange
         $expectedUserName = "TestPersonUser2"
         $expectedPassword = '$tr0NG_TestPa$$w0rd'
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $VcUser `
            -Password $VcUserPassword `
            -SkipCertificateCheck

         # Act
         $actual = New-PersonUser `
            -Server $connection `
            -UserName $expectedUserName `
            -Password $expectedPassword

         $script:usersToCleanup += $actual

         # Assert
         $actual | Should Not Be $null
         $actual.GetType().FullName | Should Be 'VMware.vSphere.SsoAdminClient.DataTypes.PersonUser'
         $actual.Name | Should Be $expectedUserName
         $actual.Domain | Should Not Be $null
         $actual.Description | Should Be $null
         $actual.FirstName | Should Be $null
         $actual.LastName | Should Be $null
         $actual.EmailAddress | Should Be $null
      }

      It 'Try create person against disconnected server' {
      }
   }

   Context "Get-PersonUser" {
      It 'Gets person users without filters' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $VcUser `
            -Password $VcUserPassword `
            -SkipCertificateCheck

         # Act
         $actual = Get-PersonUser

         # Assert
         $actual | Should Not Be $null
         $actual.Count | Should BeGreaterThan 0
         $actual[0].Name | Should Not Be $null
         $actual[0].Domain | Should Be 'localos'
      }

      It 'Gets person users by name (exact match) and domain filters' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $VcUser `
            -Password $VcUserPassword `
            -SkipCertificateCheck

         $expectedUserName = "TestPersonUser3"
         $secondUserName = "TestPersonUser4"
         $password = '$tr0NG_TestPa$$w0rd'

         $personUserToSearch = New-PersonUser `
            -UserName $expectedUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $personUserToSearch

         $secondPersonUserToSearch = New-PersonUser `
            -UserName $secondUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $secondPersonUserToSearch

         # Act
         $actual = Get-PersonUser `
            -Name $expectedUserName `
            -Domain $personUserToSearch.Domain `
            -Server $connection

         # Assert
         $actual | Should Not Be $null
         $actual.Name | Should Be $expectedUserName
         $actual.Domain | Should Not Be $null
         $actual.Domain | Should Be $personUserToSearch.Domain
      }

      It 'Gets person users by name (* wildcard match) and domain filters' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $VcUser `
            -Password $VcUserPassword `
            -SkipCertificateCheck

         $expectedUserName = "TestPersonUser3"
         $secondUserName = "TestPersonUser4"
         $password = '$tr0NG_TestPa$$w0rd'

         $personUserToSearch = New-PersonUser `
            -UserName $expectedUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $personUserToSearch

         $secondPersonUserToSearch = New-PersonUser `
            -UserName $secondUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $secondPersonUserToSearch

         # Act
         $actual = Get-PersonUser `
            -Name "Test*" `
            -Domain $personUserToSearch.Domain `
            -Server $connection

         # Assert
         $actual | Should Not Be $null
         $actual.Count | Should Be 2
         $actual.Name | Should Contain $expectedUserName
         $actual.Name | Should Contain $secondUserName
      }

      It 'Gets person users by name (? wildcard match) and domain filters' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $VcUser `
            -Password $VcUserPassword `
            -SkipCertificateCheck

         $expectedUserName = "TestPersonUser3"
         $secondUserName = "TestPersonUser4"
         $password = '$tr0NG_TestPa$$w0rd'

         $personUserToSearch = New-PersonUser `
            -UserName $expectedUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $personUserToSearch

         $secondPersonUserToSearch = New-PersonUser `
            -UserName $secondUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $secondPersonUserToSearch

         # Act
         $actual = Get-PersonUser `
            -Name "TestPersonUser?" `
            -Domain $personUserToSearch.Domain `
            -Server $connection

         # Assert
         $actual | Should Not Be $null
         $actual.Count | Should Be 2
         $actual.Name | Should Contain $expectedUserName
         $actual.Name | Should Contain $secondUserName
      }

      It 'Gets person users by unexisting name does not return' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $VcUser `
            -Password $VcUserPassword `
            -SkipCertificateCheck

         $expectedUserName = "TestPersonUser3"
         $password = '$tr0NG_TestPa$$w0rd'

         $personUserToSearch = New-PersonUser `
            -UserName $expectedUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $personUserToSearch


         # Act
         $actual = Get-PersonUser `
            -Name "TestPersonUser" `
            -Domain $personUserToSearch.Domain `
            -Server $connection

         # Assert
         $actual | Should Be $null
      }
   }

   Context "Remove-PersonUser" {
      It 'Removes person user' {
         # Arrange
         $userName = "TestPersonUser4"
         $password = '$tr0NG_TestPa$$w0rd'
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $VcUser `
            -Password $VcUserPassword `
            -SkipCertificateCheck


         $personUserToRemove = New-PersonUser `
            -UserName $userName `
            -Password $password `
            -Server $connection

         # Act
         Remove-PersonUser -User $personUserToRemove -Server $connection

         # Assert
         $personUserToRemove | Should Not Be $null
         $userFromServer = Get-PersonUser `
            -Name $personUserToRemove.Name `
            -Domain $personUserToRemove.Domain `
            -Server $connection
         $userFromServer | Should Be $null
      }
   }
}