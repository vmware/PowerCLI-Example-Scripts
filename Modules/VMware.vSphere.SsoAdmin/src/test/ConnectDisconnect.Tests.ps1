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

Describe "Connect-SsoAdminServer and Disconnect-SsoAdminServer Tests" {
   AfterEach {
      $connectionsToCleanup = $global:DefaultSsoAdminServers.ToArray()
      foreach ($connection in $connectionsToCleanup) {
         Disconnect-SsoAdminServer -Server $connection
      }
   }

   Context "Connect-SsoAdminServer" {
      It 'Connect-SsoAdminServer returns SsoAdminServer object and updates DefaultSsoAdminServers variable' {
         # Act
         $actual = Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

         # Assert
         $actual | Should -Not -Be $null
         $actual.GetType().FullName | Should -Be 'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer'
         $actual.IsConnected | Should -Be $true
         $actual.Name | Should -Be $VcAddress
         $global:DefaultSsoAdminServers | Should -Contain $actual
      }

      It 'Connect-SsoAdminServer connects the server with PSCredential object' {
        # Act
        $securePassword = ConvertTo-SecureString -AsPlainText -Force -String $Password
        $credential = New-Object `
            -TypeName System.Management.Automation.PSCredential `
            -ArgumentList $User, $securePassword
        $actual = Connect-SsoAdminServer `
           -Server $VcAddress `
           -Credential $credential `
           -SkipCertificateCheck

        # Assert
        $actual | Should -Not -Be $null
        $actual.GetType().FullName | Should -Be 'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer'
        $actual.IsConnected | Should -Be $true
        $actual.Name | Should -Be $VcAddress
        $global:DefaultSsoAdminServers | Should -Contain $actual
     }


      It 'Connect-SsoAdminServer throws error on invalid password' {
         # Act
         # Assert
         { Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password ($Password + "invalid") `
            -SkipCertificateCheck `
            -ErrorAction Stop } | `
         Should -Throw "Invalid credentials"
      }

      It 'Connect-SsoAdminServer throws error on invalid Tls Certificate' {
         # Act
         # Assert
         { Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -ErrorAction Stop } | `
         Should -Throw "*The SSL connection could not be established, see inner exception.*"
      }
   }

   Context "Disconnect-SsoAdminServer" {
      It 'Diconnect-SsoAdminServer removes server from DefaultSsoAdminServers and makes the object not connected' {
         # Arrange
         $expected = Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck

         # Act
         $expected | Disconnect-SsoAdminServer

         # Assert
         $global:DefaultSsoAdminServers | Should -Not -Contain $expected
         $expected.IsConnected | Should -Be $false
      }

      It 'Diconnect-SsoAdminServer disconnects the currently connected SSO in case there is 1 SSO server' {
         # Arrange
         $expected = Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck

         # Act
         Disconnect-SsoAdminServer -server $expected

         # Assert
         $global:DefaultSsoAdminServers | Should -Not -Contain $expected
         $expected.IsConnected | Should -Be $false
      }

      It 'Diconnect-SsoAdminServer does not disconnect if connected to more than 1 SSO server' {
         # Arrange
         $connection1 = Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck
         $connection2 = Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck

         # Act

         # Assert
         $connection2 | Should -Be $connection1
         $connection2.RefCount | Should -Be 2

         Disconnect-SsoAdminServer

         $connection2.IsConnected | Should -Contain $true
         $connection2.RefCount | Should -Be 1
      }

      It 'Diconnect-SsoAdminServer does disconnect via pipeline if connected to more than 1 SSO server' {
         # Arrange
         $connection1 = Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck
         $connection2 = Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck

         # Act
         $connection1, $connection2 | Disconnect-SsoAdminServer
         # Assert
         $global:DefaultSsoAdminServers.Count | Should -Be 0
         $connection1.IsConnected | Should -Be $false
         $connection2.IsConnected | Should -Be $false
      }

      It 'Disconnects disconnected object' {
         # Arrange
         $expected = Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck

         $expected | Disconnect-SsoAdminServer

         # Act
         { Disconnect-SsoAdminServer -Server $expected } | `
         Should -Not -Throw

         # Assert
         $global:DefaultSsoAdminServers | Should -Not -Contain $expected
         $expected.IsConnected | Should -Be $false
      }

      It 'Disconnects DefaultSsoAdminServers when * is specified on -Server parameter' {
         # Arrange
         $expected = Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck

         # Act
         Disconnect-SsoAdminServer -Server "*"


         # Assert
         $global:DefaultSsoAdminServers.Count | Should -Be 0
         $expected.IsConnected | Should -Be $false
      }

      It 'Disconnects server specified as string that is equal to VC Address' {
         # Arrange
         $expected = Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck

         # Act
         Disconnect-SsoAdminServer -Server $VcAddress


         # Assert
         $global:DefaultSsoAdminServers.Count | Should -Be 0
         $expected.IsConnected | Should -Be $false
      }

      It 'Disconnect-SsoAdminServer fails when string that does not match any servers is specified' {
         # Arrange
         $expected = Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck

         # Act
         { Disconnect-SsoAdminServer -Server "testserver" } | Should -Throw


         # Assert
         $global:DefaultSsoAdminServers.Count | Should -Be 1
         $global:DefaultSsoAdminServers[0] | Should -Be $expected
         $expected.IsConnected | Should -Be $true

         # Cleanup
         Disconnect-SsoAdminServer -Server $expected
      }
   }
}