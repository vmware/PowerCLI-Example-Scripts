#Requires -Modules Pester, VMware.VMC
Import-Module -Name VMware.VimAutomation.Cis.Core

inModuleScope VMware.VMC {
    $functionName = "Get-VMCSDDCVersion"
    Describe "$functionName" -Tag 'Unit' {
        . "$PSScriptRoot/Shared.ps1"

        $global:DefaultVMCServers = $true

        $Service = "com.vmware.vmc.orgs.sddcs"
        $OrgId = "Mocked OrgID"
        $SddcName = "MockedSDDCName"
        $version = "MockedVersion"

        $orgs = @(
            [PSCustomObject]@{
            "Id" = $OrgId
            "Org_Id" = $OrgId
        })

        $MockedServiceObj = [PSCustomObject]{}

        $ServicesObject = @([PSCustomObject]@{
            "resource_config" = @{
                sddc_manifest = [PSCustomObject]@{
                    version = $version
                }
            }
        })

        Mock -CommandName Get-VMCOrg -MockWith { $orgs }

        Mock -CommandName Get-VMCService -MockWith { $MockedServiceObj }

        $MockedServiceObj | Add-Member -MemberType ScriptMethod -Name "list" -Value { $ServicesObject }

        Mock -CommandName Write-Error -MockWith {}

        Context "Sanity checking" {
            $command = Get-Command -Name $functionName

            defParam $command 'Org'
            defParam $command 'Name'
        }

        Context "Behavior testing" {
            # Testing single Org with optional SDDC parameter
            It "calls Get-VMCSDDCVersion with the Org name supplied" {
                { Get-VMCSDDCVersion -Org $OrgId -Name $SddcName} | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCOrg -Times 1 -Scope It -ParameterFilter { $Name -eq $OrgId }
            }
            It "calls get-service to com.vmware.vmc.orgs.sddcs" {
                { Get-VMCSDDCVersion -Org $OrgId } | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCService -Times 1 -Scope It -ParameterFilter { $name -eq $Service }
            }
            # Testing a single SDDC response
            It "gets the task details via list method and returns the properties" {
                $(Get-VMCSDDCVersion -Org $OrgId).version  | Should -be $version
            }
            # Testing the multiple SDDC response
            It "gets the task details of the Org supplied and returns the properties" {
                Mock -CommandName Get-VMCOrg -MockWith { @($orgs, $orgs) }

                $(Get-VMCSDDCVersion -Org $OrgId)[0].version  | Should -be $version
                $(Get-VMCSDDCVersion -Org $OrgId)[1].version  | Should -be $version
            }
            It "writes an error if not connected" {
                $global:DefaultVMCServers = $false
                { Get-VMCSDDCVersion -Org $OrgId  } | Should Not Throw
                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It -ParameterFilter { $org -eq $Org -and $Sddc -eq $Sddc  }
            }
        }
    }
}