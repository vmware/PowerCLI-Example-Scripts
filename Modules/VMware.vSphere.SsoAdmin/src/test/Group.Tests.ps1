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

Describe "SsoGroup Tests" {
    BeforeEach {
        Connect-SsoAdminServer `
            -Server $VcAddress `
            -User $User `
            -Password $Password `
            -SkipCertificateCheck

        $script:testGroupsToDelete = @()
    }

    AfterEach {

        foreach ($group in $script:testGroupsToDelete) {
            Remove-SsoGroup -Group $group
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
            $actual | Should -Not -Be $
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
}