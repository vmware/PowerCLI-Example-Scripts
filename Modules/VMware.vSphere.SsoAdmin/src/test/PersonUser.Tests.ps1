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

Describe "PersonUser Tests" {
   BeforeEach {
      $script:usersToCleanup = @()
   }
   AfterEach {
      foreach ($personUser in $script:usersToCleanup) {
         Remove-PersonUser -User $personUser
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
            -User $User `
            -Password $Password `
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
            -User $User `
            -Password $Password `
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
   }

   Context "Get-PersonUser" {
      It 'Gets person users without filters' {
         # Arrange
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
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
            -User $User `
            -Password $Password `
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
            -User $User `
            -Password $Password `
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
            -User $User `
            -Password $Password `
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
            -User $User `
            -Password $Password `
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

   Context "Set-PersonUser" {
      It 'Adds person user to group' {
         # Arrange
         $userName = "TestAddGroupPersonUserName"
         $userPassword = '$tr0NG_TestPa$$w0rd'
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         $personUserToUpdate = New-PersonUser `
            -UserName $userName `
            -Password $userPassword `
            -Server $connection

         $script:usersToCleanup += $personUserToUpdate

         $groupUserToBeAddedTo = Get-Group `
            -Name 'Administrators' `
            -Domain $personUserToUpdate.Domain `
            -Server $connection

         # Act
         $actual = Set-PersonUser `
            -User $personUserToUpdate `
            -Group $groupUserToBeAddedTo `
            -Add

         # Assert
         $actual | Should Not Be $null
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

         $personUserToUpdate = New-PersonUser `
            -UserName $userName `
            -Password $userPassword `
            -Server $connection

         $script:usersToCleanup += $personUserToUpdate

         $groupToBeUsed = Get-Group `
            -Name 'Administrators' `
            -Domain $personUserToUpdate.Domain `
            -Server $connection

         Set-PersonUser `
            -User $personUserToUpdate `
            -Group $groupToBeUsed `
            -Add

         # Act
         $actual = Set-PersonUser `
            -User $personUserToUpdate `
            -Group $groupToBeUsed `
            -Remove

         # Assert
         $actual | Should Not Be $null
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

         $personUserToUpdate = New-PersonUser `
            -UserName $userName `
            -Password $userPassword `
            -Server $connection

         $script:usersToCleanup += $personUserToUpdate

         # Act
         $actual = Set-PersonUser `
            -User $personUserToUpdate `
            -NewPassword $newPassword

         # Assert
         $actual | Should Not Be $null
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

         $personUserToUpdate = New-PersonUser `
            -UserName $userName `
            -Password $userPassword `
            -Server $connection

         $script:usersToCleanup += $personUserToUpdate

         # Act
         $actual = Set-PersonUser `
            -User $personUserToUpdate `
            -Unlock

         # Assert
         $actual | Should Be $null
      }
   }

   Context "Remove-PersonUser" {
      It 'Removes person user' {
         # Arrange
         $userName = "TestPersonUser4"
         $userPassword = '$tr0NG_TestPa$$w0rd'
         $connection = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck


         $personUserToRemove = New-PersonUser `
            -UserName $userName `
            -Password $userPassword `
            -Server $connection

         # Act
         Remove-PersonUser -User $personUserToRemove

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