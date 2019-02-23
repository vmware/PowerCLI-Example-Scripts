#Requires -Modules Pester, VMware.VMC
$functionName = $MyInvocation.MyCommand.Name.TrimEnd(".Tests.ps1")
Import-Module -Name VMware.VimAutomation.Cis.Core

Describe "$functionName" -Tag 'Unit' {
    . "$PSScriptRoot/Shared.ps1"

    $global:DefaultVMCServers = $true

    $display_name = "MockedDisplayName"
    $user_name = "MockedUserName"
    $OrgName = "MockedOrgName"
    $created = "MockedDate"
    $OrgId = "Mocked OrgID"
    $name = "MockedSDDCName"
    $Notname = "NotTheName"
    $id = "MockedId"
    $Service = "com.vmware.vmc.orgs.sddcs"

    $MockedList = [PSCustomObject]@{
        "display_name" = $display_name
        "name"         = $name
        "created"      = $created
        "user_name"    = $user_name
        "id"           = $id
    }
    $MockedList2 = [PSCustomObject]@{
        "display_name" = $display_name
        "name"         = $Notname
        "created"      = $created
        "user_name"    = $user_name
        "id"           = $id
    }

    $object = @(
        @{"Id" = $Id}
    )
    $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedList }

    $MockedArray = @($MockedList, $MockedList2)

    Mock -CommandName Get-VMCService -MockWith { $object }

    Mock -CommandName Get-VMCOrg { $object }

    Context "Sanity checking" {
        $command = Get-Command -Name $functionName

        defParam $command 'Name'
        defParam $command 'Org'
    }

    Context "Behavior testing" {

        It "calls Get-VMCOrg" {
            { Get-VMCSDDC -Org $OrgId } | Should Not Throw
            Assert-MockCalled -CommandName Get-VMCOrg -Times 1 -Scope It
        }
        It "calls Get-VMCOrg with the SDDC name supplied" {
            { Get-VMCSDDC -Org $OrgId -name $name} | Should Not Throw
            Assert-MockCalled -CommandName Get-VMCOrg -Times 1 -Scope It -ParameterFilter { $name -eq $name }
        }
        # Testing with single "Org" so assert call twice.
        It "calls get-service to com.vmware.vmc.orgs.sddcs" {
            { Get-VMCSDDC -Org $OrgId } | Should Not Throw
            Assert-MockCalled -CommandName Get-VMCService -Times 1 -Scope It -ParameterFilter { $name -eq $Service }
        }

        # Testing with two "Orgs" so assert call twice.
        It "calls get-service to com.vmware.vmc.orgs.sddcs" {
            $object = @(
                @{"Id" = 1}
                @{"Id" = 2}
            )
            $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedArray }
            { Get-VMCSDDC -Org $OrgId } | Should Not Throw
            Assert-MockCalled -CommandName Get-VMCService -Times 2 -Scope It -ParameterFilter { $name -eq $Service }
        }

        # Testing a single SDDC response
        It "gets the SDDC details via list method and returns the properties" {
            $object = [PSCustomObject]@{}
            $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedList }
            $(Get-VMCSDDC -Org $OrgId).display_name  | Should -be $display_name
        }
        # Testing the multiple SDDC response
        It "gets the SDDC details of the SDDC supplied and returns the properties" {
            $object = @{}
            $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedArray }
            $(Get-VMCSDDC -Org $OrgId -name $name).name  | Should -be $name
        }
    }
}
