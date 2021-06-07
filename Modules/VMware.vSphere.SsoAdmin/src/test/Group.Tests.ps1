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

Describe "SsoGroup Tests" {
    BeforeEach {
        Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

        $script:testGroupsToDelete = @()
        $script:testUsersToDelete = @()
    }

    AfterEach {

        foreach ($group in $script:testGroupsToDelete) {
            Remove-SsoGroup -Group $group
        }

        foreach ($user in $script:testUsersToDelete) {
            Remove-SsoPersonUser -User $user
        }

        $connectionsToCleanup = $global:DefaultSsoAdminServers.ToArray()
        foreach ($connection in $connectionsToCleanup) {
            Disconnect-SsoAdminServer -Server $connection
        }
    }

    Context "Get-SsoGroup" {
        It 'Gets groups without filters' {
            # Act
            $actual = Get-SsoGroup

            # Assert
            $actual | Should -Not -Be $null
            $actual.Count | Should -BeGreaterThan 0
            $actual[0].Name | Should -Not -Be $null
            $actual[0].Domain | Should -Be 'localos'
        }

        It 'Gets groups for default domain' {
            # Arrange
            $newUserName = "NewUser1"
            $password = '$tr0NG_TestPa$$w0rd'

            ## Create Person User to determine default domain name
            ## Person Users are created in the default domain
            $newPersonUser = New-SsoPersonUser `
                -UserName $newUserName `
                -Password $password

            # Act
            $actual = Get-SsoGroup `
                -Domain $newPersonUser.Domain

            # Assert
            $actual | Should -Not -Be $null
            $actual.Count | Should -BeGreaterThan 0
            $actual[0].Name | Should -Not -Be $null
            $actual[0].Domain | Should -Be $newPersonUser.Domain

            # Cleanup
            Remove-SsoPersonUser -User $newPersonUser
        }
    }

    Context "New-SsoGroup" {
        It 'Should create SsoGroup specifying only the name of the group' {
            # Arrange
            $expectedName = 'TestGroup1'

            # Act
            $actual = New-SsoGroup -Name $expectedName

            # Assert
            $actual | Should -Not -Be $null
            $script:testGroupsToDelete += $actual
            $actual.Name | Should -Be $expectedName
            $actual.Domain | Should -Be 'vsphere.local'
            $actual.Description | Should -Be ([string]::Empty)
        }

        It 'Should create SsoGroup specifying name and description' {
            # Arrange
            $expectedName = 'TestGroup2'
            $expectedDescription = 'Test Description 2'

            # Act
            $actual = New-SsoGroup -Name $expectedName -Description $expectedDescription

            # Assert
            $actual | Should -Not -Be $null
            $script:testGroupsToDelete += $actual
            $actual.Name | Should -Be $expectedName
            $actual.Domain | Should -Be 'vsphere.local'
            $actual.Description | Should -Be $expectedDescription
        }
    }

    Context "Remove-SsoGroup" {
        It 'Should remove SsoGroup' {
            # Arrange
            $groupName = 'TestGroup3'
            $groupToRemove = New-SsoGroup -Name $groupName

            # Act
            $groupToRemove | Remove-SsoGroup

            # Assert
            Get-SsoGroup -Name $groupName -Domain 'vsphere.local' | Should -Be $null
        }
    }

    Context "Set-SsoGroup" {
        It 'Should update a SsoGroup with new description' {
            # Arrange
            $groupName = 'TestGroup4'
            $expectedDescription = 'Test Description 4'
            $groupToUpdate = New-SsoGroup -Name $groupName

            # Act
            $actual = $groupToUpdate | Set-SsoGroup -Description $expectedDescription

            # Assert
            $actual | Should -Not -Be $null
            $script:testGroupsToDelete += $actual
            $actual.Description | Should -Be $expectedDescription
        }
    }

    Context "Add-GroupToSsoGroup" {
        It 'Should add a newly created SsoGroup to another SsoGroup' {
            # Arrange
            $expectedGroup = New-SsoGroup -Name 'TestGroup5'
            $script:testGroupsToDelete += $expectedGroup

            $targetGroup = Get-SsoGroup -Name 'Administrators' -Domain 'vsphere.local'

            # Act
            $expectedGroup | Add-GroupToSsoGroup -TargetGroup $targetGroup

            # Assert
            $actualGroups = $targetGroup | Get-SsoGroup
            $actualGroups | Where-Object { $_.Name -eq $expectedGroup.Name} | Should -Not -Be $null
        }
    }

    Context "Remove-GroupFromSsoGroup" {
        It 'Should remove a SsoGroup from another SsoGroup' {
            # Arrange
            $expectedGroup = New-SsoGroup -Name 'TestGroup6'
            $script:testGroupsToDelete += $expectedGroup

            $targetGroup = Get-SsoGroup -Name 'Administrators' -Domain 'vsphere.local'
            $expectedGroup | Add-GroupToSsoGroup -TargetGroup $targetGroup

            # Act
            $expectedGroup | Remove-GroupFromSsoGroup -TargetGroup $targetGroup

            # Assert
            $actualGroups = $targetGroup | Get-SsoGroup
            $actualGroups | Where-Object { $_.Name -eq $expectedGroup.Name} | Should -Be $null
        }
    }

    Context "Add-UserToSsoGroup" {
        It 'Should add a newly created PersonUser to SsoGroup' {
            # Arrange
            $expectedUser = New-SsoPersonUser -User 'GroupTestUser1' -Password 'MyStrongPa$$w0rd'
            $script:testUsersToDelete += $expectedUser

            $targetGroup = Get-SsoGroup -Name 'Administrators' -Domain 'vsphere.local'

            # Act
            $expectedUser | Add-UserToSsoGroup -TargetGroup $targetGroup

            # Assert
            $actualUsers = $targetGroup | Get-SsoPersonUser
            $actualUsers | Where-Object { $_.Name -eq $expectedUser.Name} | Should -Not -Be $null
        }
    }

    Context "Remove-GroupFromSsoGroup" {
        It 'Should remove a SsoGroup from another SsoGroup' {
            # Arrange
            $expectedUser = New-SsoPersonUser -User 'GroupTestUser2' -Password 'MyStrongPa$$w0rd'
            $script:testUsersToDelete += $expectedUser

            $targetGroup = Get-SsoGroup -Name 'Administrators' -Domain 'vsphere.local'
            $expectedUser | Add-UserToSsoGroup -TargetGroup $targetGroup

            # Act
            $expectedUser | Remove-UserFromSsoGroup -TargetGroup $targetGroup

            # Assert
            $actualUsers = $targetGroup | Get-SsoPersonUser
            $actualUsers | Where-Object { $_.Name -eq $expectedUser.Name} | Should -Be $null
        }
    }
}