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
         $actual | Should Not Be $null
         $actual.GetType().FullName | Should Be 'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer'
         $actual.IsConnected | Should Be $true
         $actual.Name | Should Be $VcAddress
         $global:DefaultSsoAdminServers | Should Contain $actual
      }

      It 'Connect-SsoAdminServer throws error on invalid password' {
         # Act
         # Assert
         { Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password ($Password + "invalid") `
            -SkipCertificateCheck } | `
         Should Throw "Invalid credentials"
      }

      It 'Connect-SsoAdminServer throws error on invalid Tls Certificate' {
         # Act
         # Assert
         { Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password} | `
         Should Throw "The SSL connection could not be established, see inner exception."
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
         $global:DefaultSsoAdminServers | Should Not Contain $expected
         $expected.IsConnected | Should Be $false
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
         $global:DefaultSsoAdminServers | Should Not Contain $expected
         $expected.IsConnected | Should Be $false
      }

      It 'Diconnect-SsoAdminServer does not disconnect if connected to more than 1 SSO server' {
         # Arrange
         $expected += @(Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck)
         $expected += @(Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck)

         # Act
         {Disconnect-SsoAdminServer} | should -Throw
         # Assert
         (Compare-Object $global:DefaultSsoAdminServers $expected -IncludeEqual).Count | Should Be 2
         $expected.IsConnected | Should -Contain $true
      }

      It 'Diconnect-SsoAdminServer does disconnect via pipeline if connected to more than 1 SSO server' {
         # Arrange
         $expected += @(Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck)
         $expected += @(Connect-SsoAdminServer `
               -Server $VcAddress `
               -User $User `
               -Password $Password `
               -SkipCertificateCheck)

         # Act
         $expected | Disconnect-SsoAdminServer
         # Assert
         $global:DefaultSsoAdminServers.count | Should Be 0
         $expected.IsConnected | Should -not -Contain $true
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
         Should Not Throw

         # Assert
         $global:DefaultSsoAdminServers | Should Not Contain $expected
         $expected.IsConnected | Should Be $false
      }
   }
}