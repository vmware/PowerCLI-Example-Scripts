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

Describe "PasswordPolicy Tests" {
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

   Context "Get-SsoPasswordPolicy" {
      It 'Gets password policy' {
         # Act
         $actual = Get-SsoPasswordPolicy

         # Assert
         $actual | Should -Not -Be $null
      }
   }

   Context "Set-SsoPasswordPolicy" {
      It 'Updates password policy MaxLength and PasswordLifetimeDays' {
         # Arrange
         $passwordPolicyToUpdate = Get-SsoPasswordPolicy
         $expectedMaxLength = 17
         $expectedPasswordLifetimeDays = 77

         # Act
         $actual = Set-SsoPasswordPolicy `
            -PasswordPolicy $passwordPolicyToUpdate `
            -MaxLength $expectedMaxLength `
            -PasswordLifetimeDays $expectedPasswordLifetimeDays

         # Assert
         $actual | Should -Not -Be $null
         $actual.MaxLength | Should -Be $expectedMaxLength
         $actual.PasswordLifetimeDays | Should -Be $expectedPasswordLifetimeDays
         $actual.Description | Should -Be $passwordPolicyToUpdate.Description
         $actual.ProhibitedPreviousPasswordsCount | Should -Be $passwordPolicyToUpdate.ProhibitedPreviousPasswordsCount
         $actual.MinLength | Should -Be $passwordPolicyToUpdate.MinLength
         $actual.MaxIdenticalAdjacentCharacters | Should -Be $passwordPolicyToUpdate.MaxIdenticalAdjacentCharacters
         $actual.MinNumericCount | Should -Be $passwordPolicyToUpdate.MinNumericCount
         $actual.MinSpecialCharCount | Should -Be $passwordPolicyToUpdate.MinSpecialCharCount
         $actual.MinAlphabeticCount | Should -Be $passwordPolicyToUpdate.MinAlphabeticCount
         $actual.MinUppercaseCount | Should -Be $passwordPolicyToUpdate.MinUppercaseCount
         $actual.MinLowercaseCount | Should -Be $passwordPolicyToUpdate.MinLowercaseCount

         # Cleanup
         $passwordPolicyToUpdate | Set-SsoPasswordPolicy
      }

      It 'Updates password policy Description and MinUppercaseCount' {
         # Arrange
         $passwordPolicyToUpdate = Get-SsoPasswordPolicy
         $expectedMinUppercaseCount = 0
         $expectedDescription = "Test Description"

         # Act
         $actual = $passwordPolicyToUpdate | Set-SsoPasswordPolicy `
            -Description $expectedDescription `
            -MinUppercaseCount $expectedMinUppercaseCount

         # Assert
         $actual | Should -Not -Be $null
         $actual.Description | Should -Be $expectedDescription
         $actual.MinUppercaseCount | Should -Be $expectedMinUppercaseCount
         $actual.MaxLength | Should -Be $passwordPolicyToUpdate.MaxLength
         $actual.PasswordLifetimeDays | Should -Be $passwordPolicyToUpdate.PasswordLifetimeDays
         $actual.ProhibitedPreviousPasswordsCount | Should -Be $passwordPolicyToUpdate.ProhibitedPreviousPasswordsCount
         $actual.MinLength | Should -Be $passwordPolicyToUpdate.MinLength
         $actual.MaxIdenticalAdjacentCharacters | Should -Be $passwordPolicyToUpdate.MaxIdenticalAdjacentCharacters
         $actual.MinNumericCount | Should -Be $passwordPolicyToUpdate.MinNumericCount
         $actual.MinSpecialCharCount | Should -Be $passwordPolicyToUpdate.MinSpecialCharCount
         $actual.MinAlphabeticCount | Should -Be $passwordPolicyToUpdate.MinAlphabeticCount
         $actual.MinLowercaseCount | Should -Be $passwordPolicyToUpdate.MinLowercaseCount

         # Cleanup
         $passwordPolicyToUpdate | Set-SsoPasswordPolicy
      }
   }
}