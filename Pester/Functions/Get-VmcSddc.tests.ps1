#Requires -Modules Pester, VMware.VMC
Import-Module -Name VMware.VimAutomation.Cis.Core

inModuleScope VMware.VMC {
    $functionName ="Get-VmcSddc"
    Describe "$functionName" -Tag 'Unit' {
        . "$PSScriptRoot/Shared.ps1"

        $global:DefaultVMCServers = $true

        $OrgId = "Mocked OrgID"
        $name = "MockedSDDCName"
        $Notname = "NotTheName"
        $Service = "com.vmware.vmc.orgs.sddcs"

        $MockedList = [PSCustomObject]@{
            "name"         = $name
        }
        $MockedList2 = [PSCustomObject]@{
            "name"         = $Notname
        }

        $object = @(
            @{"Id" = 1}
        )
        $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedList }

        $MockedArray = @($MockedList, $MockedList2)

        Mock -CommandName Get-VMCService -MockWith { $object }

        Mock -CommandName Get-VMCOrg { $object }

        Mock -CommandName Write-Error -MockWith {}

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
                $(Get-VMCSDDC -Org $OrgId).name  | Should -be $name
            }
            # Testing the multiple SDDC response
            It "gets the SDDC details of the SDDC supplied and returns the properties" {
                $object = @{}
                $object | Add-Member -MemberType ScriptMethod -Name "list" -Value { $MockedArray }
                $(Get-VMCSDDC -Org $OrgId -name $name).name  | Should -be $name
            }
            It "gets writes an error if not connected" {
                $global:DefaultVMCServers = $false
                { Get-VMCSDDC -Org $OrgId  } | Should Not Throw
                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It -ParameterFilter { $org -eq $Org -and $Sddc -eq $Sddc  }
            }
        }
    }
}