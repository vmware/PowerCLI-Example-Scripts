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

Describe "AuthentcicationPolicy Tests" {
   BeforeEach {
    $connection = Connect-SsoAdminServer `
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

   Context "Get-SsoAuthenticationPolicy" {
      It 'Retrieves Authentication Policy' {
         # Act
         $actual = Get-SsoAuthenticationPolicy

         # Assert
         $actual | Should -Not -Be $null
         $actual.GetType().FullName | Should -Be 'VMware.vSphere.SsoAdminClient.DataTypes.AuthenticationPolicy'
         $actual.PasswordAuthnEnabled | Should -Be $true
      }
   }

   Context "Set-SsoAuthenticationPolicy" {
      It 'Updates AuthenticationPolicy enabling and disabling Smart Card authetication' {
        # Arrange
        $expected = Get-SsoAuthenticationPolicy

        # Act
        $actual = $expected | Set-SsoAuthenticationPolicy -SmartCardAuthnEnabled $true

        # Assert
        $actual | Should -Not -Be $null
        $actual.GetType().FullName | Should -Be 'VMware.vSphere.SsoAdminClient.DataTypes.AuthenticationPolicy'
        $actual.SmartCardAuthnEnabled | Should -Be $true
        ## Assert other properties are not modified
        $actual.PasswordAuthnEnabled | Should -Be  $expected.PasswordAuthnEnabled
        $actual.WindowsAuthnEnabled  | Should -Be  $expected.WindowsAuthnEnabled
        $actual.CRLCacheSize | Should -Be  $expected.CRLCacheSize
        $actual.CRLUrl | Should -Be  $expected.CRLUrl
        $actual.OCSPEnabled | Should -Be  $expected.OCSPEnabled
        $actual.OCSPResponderSigningCert | Should -Be  $expected.OCSPResponderSigningCert
        $actual.OCSPUrl | Should -Be  $expected.OCSPUrl
        $actual.OIDs | Should -Be  $expected.OIDs
        $actual.SendOCSPNonce | Should -Be  $expected.SendOCSPNonce
        $actual.TrustedCAs | Should -Be  $expected.TrustedCAs
        $actual.UseCRLAsFailOver | Should -Be  $expected.UseCRLAsFailOver
        $actual.UseInCertCRL | Should -Be  $expected.UseInCertCRL

        # Revert SmartCardAuthnEnabled to $false
        $actual = $actual | Set-SsoAuthenticationPolicy -SmartCardAuthnEnabled $false
        $actual.SmartCardAuthnEnabled | Should -Be $false
        ## Assert other properties are not modified
        $actual.PasswordAuthnEnabled | Should -Be  $expected.PasswordAuthnEnabled
        $actual.WindowsAuthnEnabled  | Should -Be  $expected.WindowsAuthnEnabled
        $actual.CRLCacheSize | Should -Be  $expected.CRLCacheSize
        $actual.CRLUrl | Should -Be  $expected.CRLUrl
        $actual.OCSPEnabled | Should -Be  $expected.OCSPEnabled
        $actual.OCSPResponderSigningCert | Should -Be  $expected.OCSPResponderSigningCert
        $actual.OCSPUrl | Should -Be  $expected.OCSPUrl
        $actual.OIDs | Should -Be  $expected.OIDs
        $actual.SendOCSPNonce | Should -Be  $expected.SendOCSPNonce
        $actual.TrustedCAs | Should -Be  $expected.TrustedCAs
        $actual.UseCRLAsFailOver | Should -Be  $expected.UseCRLAsFailOver
        $actual.UseInCertCRL | Should -Be  $expected.UseInCertCRL
      }
   }
}