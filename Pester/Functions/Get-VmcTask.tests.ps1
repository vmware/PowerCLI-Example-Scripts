#Requires -Modules Pester, VMware.VMC
Import-Module -Name VMware.VimAutomation.Cis.Core

inModuleScope VMware.VMC {
    $functionName = "Get-VMCTask"
    Describe "$functionName" -Tag 'Unit' {
        . "$PSScriptRoot/Shared.ps1"

        $global:DefaultVMCServers = $true

        $OrgId = "Mocked OrgID"
        $name = "MockedSDDCName"
        $Notname = "NotTheName"
        $id = "MockedId"
        $Service = "com.vmware.vmc.orgs.tasks"

        $MockedList = [PSCustomObject]@{
            "name"         = $name
        }
        $MockedList2 = [PSCustomObject]@{
            "name"         = $Notname
        }

        $object = @(
            @{"Id" = $Id}
        )
        $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedList }

        $MockedArray = @($MockedList, $MockedList2)

        Mock -CommandName Get-VMCService -MockWith { $object }

        Mock -CommandName Get-VMCOrg { $object }

        Mock -CommandName Write-Error -MockWith {}

        Context "Sanity checking" {
            $command = Get-Command -Name $functionName

            defParam $command 'Org'
        }

        Context "Behavior testing" {

            It "calls Get-VMCOrg with the Org name supplied" {
                { Get-VMCTask -Org $name} | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCOrg -Times 1 -Scope It -ParameterFilter { $name -eq $name }
            }

            # Testing with single "Org" so assert call twice.
            It "calls get-service to com.vmware.vmc.orgs.tasks" {
                { Get-VMCTask -Org $OrgId } | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCService -Times 1 -Scope It -ParameterFilter { $name -eq $Service }
            }

            # Testing with two "Orgs" so assert call twice.
            It "calls get-service to com.vmware.vmc.orgs.tasks" {
                $object = @(
                    @{"Id" = 1}
                    @{"Id" = 2}
                )
                $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedArray }
                { Get-VMCTask -Org $OrgId } | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCService -Times 2 -Scope It -ParameterFilter { $name -eq $Service }
            }

            # Testing a single SDDC response
            It "gets the task details via list method and returns the properties" {
                $object = [PSCustomObject]@{}
                $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedList }
                $(Get-VMCTask -Org $OrgId).name  | Should -be $name
            }
            # Testing the multiple SDDC response
            It "gets the task details of the SDDC supplied and returns the properties" {
                $object = @{}
                $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedArray }
                $(Get-VMCTask -Org $OrgId)[0].name  | Should -be $name
                $(Get-VMCTask -Org $OrgId)[1].name  | Should -be $Notname
            }
            It "gets writes an error if not connected" {
                $global:DefaultVMCServers = $false
                { Get-VMCTask -Org $OrgId  } | Should Not Throw
                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It -ParameterFilter { $org -eq $Org -and $Sddc -eq $Sddc  }
            }
        }
    }
}