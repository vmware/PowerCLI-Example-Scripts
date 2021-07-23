<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

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

Describe "PersonUser Tests" {
   BeforeEach {
      $script:usersToCleanup = @()
   }
   AfterEach {
      foreach ($personUser in $script:usersToCleanup) {
         Remove-SsoPersonUser -User $personUser
      }

      $connectionsToCleanup = $global:DefaultSsoAdminServers.ToArray()
      foreach ($connection in $connectionsToCleanup) {
         Disconnect-SsoAdminServer -Server $connection
      }
   }

   Context "New-SsoPersonUser" {
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
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         # Act
         $actual = New-SsoPersonUser `
            -Server $connection `
            -UserName $expectedUserName `
            -Password $expectedPassword `
            -Description $expectedDescription `
            -EmailAddress $expectedEmailAddress `
            -FirstName $expectedFirstName `
            -LastName $expectedLastName

         $script:usersToCleanup += $actual

         # Assert
         $actual | Should -Not -Be $null
         $actual.GetType().FullName | Should -Be 'VMware.vSphere.SsoAdminClient.DataTypes.PersonUser'
         $actual.Name | Should -Be $expectedUserName
         $actual.Domain | Should -Not -Be $null
         $actual.Description | Should -Be $expectedDescription
         $actual.FirstName | Should -Be $expectedFirstName
         $actual.LastName | Should -Be $expectedLastName
         $actual.EmailAddress | Should -Be $expectedEmailAddress
      }

      It 'Creates person user without details' {
         # Arrange
         $expectedUserName = "TestPersonUser2"
         $expectedPassword = '$tr0NG_TestPa$$w0rd'
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         # Act
         $actual = New-SsoPersonUser `
            -Server $connection `
            -UserName $expectedUserName `
            -Password $expectedPassword

         $script:usersToCleanup += $actual

         # Assert
         $actual | Should -Not -Be $null
         $actual.GetType().FullName | Should -Be 'VMware.vSphere.SsoAdminClient.DataTypes.PersonUser'
         $actual.Name | Should -Be $expectedUserName
         $actual.Domain | Should -Not -Be $null
         $actual.Description | Should -Be $null
         $actual.FirstName | Should -Be $null
         $actual.LastName | Should -Be $null
         $actual.EmailAddress | Should -Be $null
         $actual.PasswordExpirationRemainingDays | Should -Not -Be $null
      }
   }

   Context "Get-SsoPersonUser" {
      It 'Gets person users without filters' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         # Act
         $actual = Get-SsoPersonUser

         # Assert
         $actual | Should -Not -Be $null
         $actual.Count | Should -BeGreaterThan 0
         $actual[0].Name | Should -Not -Be $null
         $actual[0].Domain | Should -Be 'localos'
         $actual[0].PasswordExpirationRemainingDays | Should -Not -Be $null
      }

      It 'Gets person users by name (exact match) and domain filters' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         $expectedUserName = "TestPersonUser3"
         $secondUserName = "TestPersonUser4"
         $password = '$tr0NG_TestPa$$w0rd'

         $personUserToSearch = New-SsoPersonUser `
            -UserName $expectedUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $personUserToSearch

         $secondPersonUserToSearch = New-SsoPersonUser `
            -UserName $secondUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $secondPersonUserToSearch

         # Act
         $actual = Get-SsoPersonUser `
            -Name $expectedUserName `
            -Domain $personUserToSearch.Domain `
            -Server $connection

         # Assert
         $actual | Should -Not -Be $null
         $actual.Name | Should -Be $expectedUserName
         $actual.Domain | Should -Not -Be $null
         $actual.Domain | Should -Be $personUserToSearch.Domain
      }

      It 'Gets person users by name (* wildcard match) and domain filters' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         $expectedUserName = "TestPersonUser3"
         $secondUserName = "TestPersonUser4"
         $password = '$tr0NG_TestPa$$w0rd'

         $personUserToSearch = New-SsoPersonUser `
            -UserName $expectedUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $personUserToSearch

         $secondPersonUserToSearch = New-SsoPersonUser `
            -UserName $secondUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $secondPersonUserToSearch

         # Act
         $actual = Get-SsoPersonUser `
            -Name "Test*" `
            -Domain $personUserToSearch.Domain `
            -Server $connection

         # Assert
         $actual | Should -Not -Be $null
         $actual.Count | Should -Be 2
         $actual.Name | Should -Contain $expectedUserName
         $actual.Name | Should -Contain $secondUserName
      }

      It 'Gets person users by name (? wildcard match) and domain filters' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         $expectedUserName = "TestPersonUser3"
         $secondUserName = "TestPersonUser4"
         $password = '$tr0NG_TestPa$$w0rd'

         $personUserToSearch = New-SsoPersonUser `
            -UserName $expectedUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $personUserToSearch

         $secondPersonUserToSearch = New-SsoPersonUser `
            -UserName $secondUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $secondPersonUserToSearch

         # Act
         $actual = Get-SsoPersonUser `
            -Name "TestPersonUser?" `
            -Domain $personUserToSearch.Domain `
            -Server $connection

         # Assert
         $actual | Should -Not -Be $null
         $actual.Count | Should -Be 2
         $actual.Name | Should -Contain $expectedUserName
         $actual.Name | Should -Contain $secondUserName
      }

      It 'Gets person users by unexisting name does not return' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         $expectedUserName = "TestPersonUser3"
         $password = '$tr0NG_TestPa$$w0rd'

         $personUserToSearch = New-SsoPersonUser `
            -UserName $expectedUserName `
            -Password $password `
            -Server $connection
         $script:usersToCleanup += $personUserToSearch


         # Act
         $actual = Get-SsoPersonUser `
            -Name "TestPersonUser" `
            -Domain $personUserToSearch.Domain `
            -Server $connection

         # Assert
         $actual | Should -Be $null
      }

      It 'Gets person users members of Administrators group' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         # Act
         $actual = Get-SsoGroup -Name 'Administrators' -Domain 'vsphere.local' | Get-SsoPersonUser

         # Assert
         $actual | Should -Not -Be $null
         $actual.Count | Should -BeGreaterThan 0
         $actual[0].Name | Should -Not -Be $null
         $actual[0].Domain | Should -Be 'vsphere.local'
         $actual[0].PasswordExpirationRemainingDays | Should -Not -Be $null
      }
   }

   Context "Set-SsoPersonUser" {
      It 'Adds person user to group' {
         # Arrange
         $userName = "TestAddGroupPersonUserName"
         $userPassword = '$tr0NG_TestPa$$w0rd'
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         $personUserToUpdate = New-SsoPersonUser `
            -UserName $userName `
            -Password $userPassword `
            -Server $connection

         $script:usersToCleanup += $personUserToUpdate

         $groupUserToBeAddedTo = Get-SsoGroup `
            -Name 'Administrators' `
            -Domain $personUserToUpdate.Domain `
            -Server $connection

         # Act
         $actual = Set-SsoPersonUser `
            -User $personUserToUpdate `
            -Group $groupUserToBeAddedTo `
            -Add

         # Assert
         $actual | Should -Not -Be $null
      }

      It 'Removes person user from group' {
         # Arrange
         $userName = "TestRemoveGroupPersonUserName"
         $userPassword = '$tr0NG_TestPa$$w0rd'
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         $personUserToUpdate = New-SsoPersonUser `
            -UserName $userName `
            -Password $userPassword `
            -Server $connection

         $script:usersToCleanup += $personUserToUpdate

         $groupToBeUsed = Get-SsoGroup `
            -Name 'Administrators' `
            -Domain $personUserToUpdate.Domain `
            -Server $connection

         Set-SsoPersonUser `
            -User $personUserToUpdate `
            -Group $groupToBeUsed `
            -Add

         # Act
         $actual = Set-SsoPersonUser `
            -User $personUserToUpdate `
            -Group $groupToBeUsed `
            -Remove

         # Assert
         $actual | Should -Not -Be $null
      }

      It 'Resets person user password' {
         # Arrange
         $userName = "TestResetPassPersonUserName"
         $userPassword = '$tr0NG_TestPa$$w0rd'
         $newPassword = 'Update_TestPa$$w0rd'
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         $personUserToUpdate = New-SsoPersonUser `
            -UserName $userName `
            -Password $userPassword `
            -Server $connection

         $script:usersToCleanup += $personUserToUpdate

         # Act
         $actual = Set-SsoPersonUser `
            -User $personUserToUpdate `
            -NewPassword $newPassword

         # Assert
         $actual | Should -Not -Be $null
      }

      It 'Unlocks not locked person user' {
         # Arrange
         $userName = "TestResetPassPersonUserName"
         $userPassword = '$tr0NG_TestPa$$w0rd'
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         $personUserToUpdate = New-SsoPersonUser `
            -UserName $userName `
            -Password $userPassword `
            -Server $connection

         $script:usersToCleanup += $personUserToUpdate

         # Act
         $actual = Set-SsoPersonUser `
            -User $personUserToUpdate `
            -Unlock

         # Assert
         $actual | Should -Be $null
      }

      It 'Disables and enables person user' {
        # Arrange
        $userName = "TestEnablePersonUserName"
        $userPassword = '$tr0NG_TestPa$$w0rd'
        $connection = Connect-SsoAdminServer `
           -Server $VcAddress `
           -User $User `
           -Password $Password `
           -SkipCertificateCheck

        $personUserToUpdate = New-SsoPersonUser `
           -UserName $userName `
           -Password $userPassword `
           -Server $connection

        $script:usersToCleanup += $personUserToUpdate

        # Act
        $personUserToUpdate.Disabled | Should -Be $false
        $actual = Set-SsoPersonUser `
           -User $personUserToUpdate `
           -Enable $false

        # Assert
        $actual.Disabled | Should -Be $true

        # Act
        $actual = Set-SsoPersonUser `
           -User $actual `
           -Enable $true

        # Assert
        $actual.Disabled | Should -Be $false
     }
   }

   Context "Remove-SsoPersonUser" {
      It 'Removes person user' {
         # Arrange
         $userName = "TestPersonUser4"
         $userPassword = '$tr0NG_TestPa$$w0rd'
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck


         $personUserToRemove = New-SsoPersonUser `
            -UserName $userName `
            -Password $userPassword `
            -Server $connection

         # Act
         Remove-SsoPersonUser -User $personUserToRemove

         # Assert
         $personUserToRemove | Should -Not -Be $null
         $userFromServer = Get-SsoPersonUser `
            -Name $personUserToRemove.Name `
            -Domain $personUserToRemove.Domain `
            -Server $connection
         $userFromServer | Should -Be $null
      }
   }

   Context "Set-SsoSelfPersonUserPassword" {
      It 'Reset self person user password' {
         # Arrange
         $userName = "TestResetSelfPassPersonUserName"
         $userPassword = '$tr0NG_TestPa$$w0rd'
         $newUserPassword = ConvertTo-SecureString '$tr0NG_TestPa$$w0rd2' –AsPlainText –Force
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         $personUserToUpdate = New-SsoPersonUser `
            -UserName $userName `
            -Password $userPassword `
            -Server $connection

         $script:usersToCleanup += $personUserToUpdate

         Disconnect-SsoAdminServer -Server $connection

         ## Connect with the new user
         $testConnection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User "$userName@vsphere.local" `
            -Password $userPassword `
            -SkipCertificateCheck

         # Act
         $actual = Set-SsoSelfPersonUserPassword `
            -Password $newUserPassword

         # Assert
         $actual | Should -Be $null

         ## Cleanup
         Disconnect-SsoAdminServer -Server $testConnection

         ## Restore Connection
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck
      }
   }
}