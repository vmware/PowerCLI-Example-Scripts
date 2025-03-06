<#
Copyright (c) 2025 JetStream Software Inc.
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

# Global test variables
#$testUser  = $null
#$testRole  = $null
#$viServer  = $null
#$ssoServer = $null

#$TESTUSERNAME='testuser_'
#$TESTUSERDOMAIN="${TESTUSERNAME}@vsphere.local"
#$TESTROLENAME='testrole_'

Describe "MOB Connect Tests" {
   BeforeAll {
      $testUser  = $null
      $testRole  = $null
      $viServer  = $null
      $ssoServer = $null
      $trid = $null

      $TESTUSERNAME='testuser_'
      $TESTUSERDOMAIN="${TESTUSERNAME}@vsphere.local"
      $TESTROLENAME='testrole_'

      $ssoServer = Connect-SsoAdminServer `
         -Server $VcAddress `
         -User $User `
         -Password $Password `
         -SkipCertificateCheck

      $viServer = Connect-VIServer `
         -Server $VcAddress `
         -User $User `
         -Password $Password `

      try {
        $testUser = Get-SsoPersonUser -name $TESTUSERNAME -Domain 'vsphere.local'
      } catch {}
      if (!$testUser) {
        $testUser = New-SsoPersonUser -UserName $TESTUSERNAME -Password 'TestP@$$w0rdXXX'
      }

      try {
         $testRole = Get-VIRole -Name $TESTROLENAME -ErrorAction SilentlyContinue
      } catch { }
      if (!$testRole) {
        $testPriv = Get-VIPrivilege -Id "System.View"
        $testRole = New-VIRole -Privilege $testPriv -Name $TESTROLENAME
        $testRole = Get-VIRole -Name $TESTROLENAME
      }
      $trid = $testRole.ExtensionData.RoleId
   }

   AfterAll {
      Remove-SsoPersonUser -User $testUser
      Remove-VIRole -Role $testRole -Confirm:$False
      Disconnect-VIServer -Server $viServer -Confirm:$False
      Disconnect-SsoAdminServer -Server $ssoServer
   }

   Context "Check Command Operation" {
      It 'Verifies MOB connection' {
         # Try bad credentials
         {
             $vCenterMOB1 = Connect-VcenterServerMOB -Server $VcAddress -User $User -Password "${Password}++" -SkipCertificateCheck
         } | Should -Throw

         # Act
         $vCenterMOB1 = Connect-VcenterServerMOB -Server $VcAddress -User $User -Password $Password -SkipCertificateCheck

         # Assert
         $vCenterMOB1 | Should -Not -Be $null
         $vCenterMOB1.IsConnected() | Should -Be $True

         # Act
         $vCenterMOB1 | Disconnect-VcenterServerMOB

         # Assert
         $vCenterMOB1.IsConnected() | Should -Be $False
      }

      It 'Verifies Global policy assignment' {
         $vCenterMOB2 = Connect-VcenterServerMOB -Server $VcAddress -User $User -Password $Password -SkipCertificateCheck
         $vCenterMob2 | Should -Not -Be $null
         $vCenterMob2.IsConnected() | Should -Be $True

         # Set global permission.
         $vCenterMob2 | Set-VcenterServerGlobalPermission -TargetUser $TESTUSERDOMAIN -RoleId $trid -Propagate
         $perms = $vCenterMOB2 | Get-VcenterServerGlobalPermissions -TargetUser $TESTUSERDOMAIN
         $perms | Should -Contain "System.View"

         # Drop all global permissions.
         $vCenterMob2 | Reset-VcenterServerGlobalPermissions -TargetUser $TESTUSERDOMAIN
         $perms = $vCenterMOB2 | Get-VcenterServerGlobalPermissions -TargetUser $TESTUSERDOMAIN
         $perms | Should -BeNullOrEmpty

         Disconnect-VcenterServerMOB $vCenterMOB2
         $vCenterMob2.IsConnected() | Should -Be $False
      }
   }
}
