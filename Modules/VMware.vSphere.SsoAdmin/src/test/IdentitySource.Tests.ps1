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

Describe "Get-IdentitySource Tests" {
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

   Context "Get-IdentitySource" {
      It 'Gets all available identity sources' {
         # Act
         $actual = Get-IdentitySource

         # Assert
         $actual | Should -Not -Be $null
         $actual.Count | Should -BeGreaterThan 1
         $actual[0].NAme | Should -Be 'localos'
      }

      It 'Gets localos only identity source' {
         # Act
         $actual = Get-IdentitySource -Localos

         # Assert
         $actual | Should -Not -Be $null
         $actual.Count | Should -Be 1
         $actual[0].Name | Should -Be 'localos'
      }

       It 'Gets all available identity sources' {
         # Act
         $actual = Get-IdentitySource -Localos -System

         # Assert
         $actual | Should -Not -Be $null
         $actual.Count | Should -Be 2
         $actual[0].Name | Should -Be 'localos'
         $actual[0].Name | Should -Not -Be $null
      }
   }
}