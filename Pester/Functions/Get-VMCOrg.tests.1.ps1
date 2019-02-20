#Requires -Modules Pester, VMware.VMC
$functionName = $MyInvocation.MyCommand.Name.TrimEnd(".Tests.ps1")
Import-Module -Name VMware.VimAutomation.Cis.Core

Describe "$functionName" -Tag 'Unit' {
    . "$PSScriptRoot/Shared.ps1"

    $global:DefaultVMCServers = $true

    $display_name = "MockedDisplayName"
    $user_name = "MockedUserName"
    $OrgName = "MockedDisplayName"
    $created = "MockedDate"
    $id = "MockedId"
    $Service = "com.vmware.vmc.orgs"

    $MockedList = [PSCustomObject]@{
        "display_name" = $display_name
        "name"         = $OrgName
        "created"      = $created
        "user_name"    = $user_name
        "id"           = $id
    }
    #$object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedList }


    $MockedArray = @()
    $MockedArray += $MockedList
    $MockedArray += $MockedList

    Mock -CommandName Get-VMCService -MockWith { $object }

    Context "Sanity checking" {
        $command = Get-Command -Name $functionName

        defParam $command 'Name'
    }

    Context "Behavior testing" {
        It "calls get-service to com.vmware.vmc.orgs" {
            { Get-VMCOrg -name $OrgName } | Should Not Throw
            Assert-MockCalled -CommandName Get-VMCService -Times 1 -Scope It -ParameterFilter { $name -eq $Service }
        }
        # Testing a single SDDC response
        It "gets the orgs via list method and returns the properties" {
            $object = [PSCustomObject]@{}
            $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedList }
            $(Get-VMCOrg -name $OrgName).display_name  | Should -be $display_name
            $(Get-VMCOrg -name $OrgName).name  | Should -be $OrgName
            $(Get-VMCOrg -name $OrgName).user_name  | Should -be $user_name
            $(Get-VMCOrg -name $OrgName).created  | Should -be $created
            $(Get-VMCOrg -name $OrgName).id  | Should -be $id
        }
        # Testing the multiple SDDC response
        It "calls the Connect-CisServer" {
            $object = [PSCustomObject]@{}
            $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedArray }
            { Get-VMCOrg -name $OrgName } | Should Not Throw

            $(Get-VMCOrg -name $OrgName)[0].display_name  | Should -be $display_name
            $(Get-VMCOrg -name $OrgName)[0].name  | Should -be $OrgName
            $(Get-VMCOrg -name $OrgName)[0].user_name  | Should -be $user_name
            $(Get-VMCOrg -name $OrgName)[0].created  | Should -be $created
            $(Get-VMCOrg -name $OrgName)[0].id  | Should -be $id

            $(Get-VMCOrg -name $OrgName)[1].display_name  | Should -be $display_name
            $(Get-VMCOrg -name $OrgName)[1].name  | Should -be $OrgName
            $(Get-VMCOrg -name $OrgName)[1].user_name  | Should -be $user_name
            $(Get-VMCOrg -name $OrgName)[1].created  | Should -be $created
            $(Get-VMCOrg -name $OrgName)[1].id  | Should -be $id
        }
    }
}
