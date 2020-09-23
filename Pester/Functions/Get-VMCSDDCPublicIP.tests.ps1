#Requires -Modules Pester, VMware.VMC
Import-Module -Name VMware.VimAutomation.Cis.Core

inModuleScope VMware.VMC {
    $functionName = "Get-VMCSDDCPublicIP"
    Describe "$functionName" -Tag 'Unit' {
        . "$PSScriptRoot/Shared.ps1"

        $global:DefaultVMCServers = $true

        $OrgId = "Mocked OrgID"
        $SddcName = "MockedSDDCName"
        $public_ip_pool = "MockedPublic_ip_pool"

        $MockedList = [PSCustomObject]@{
            "public_ip_pool"     = $public_ip_pool
        }
        $MockedList2 = [PSCustomObject]@{
            "public_ip_pool"     = $public_ip_pool
        }

        $object = [PSCustomObject]@{
            "resource_config" = @($MockedList)
        }

        $MockedArray = @{ 
            "resource_config" = @($MockedList, $MockedList2)
        }

        Mock -CommandName Get-VMCSDDC -MockWith { $object }

        Mock -CommandName Write-Error -MockWith {}

        Context "Sanity checking" {
            $command = Get-Command -Name $functionName

            defParam $command 'Org'
            defParam $command 'Sddc'
        }

        Context "Behavior testing" {
            # Testing single Org with optional SDDC parameter
            It "calls Get-VMCSDDC with the Org name supplied" {
                { Get-VMCSDDCPublicIP -Org $OrgId -sddc $SddcName} | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCSDDC -Times 1 -Scope It -ParameterFilter { $Org -eq $OrgId -and $name -eq $SddcName }
            }
            # Testing single Org without SDDC parameter.
            It "calls get-VMCSDDC without SDDC name supplied" {
                { Get-VMCSDDCPublicIP -Org $OrgId } | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCSDDC -Times 1 -Scope It -ParameterFilter { $org -eq $OrgId }
            }
            # Testing a single SDDC response
            It "gets the task details via list method and returns the properties" {
                $(Get-VMCSDDCPublicIP -Org $OrgId)  | Should -be $Public_ip_pool
                #Assert-MockCalled -CommandName Select-Object -Times 1 -Scope It
            }
            # Testing the multiple SDDC response
            It "gets the task details of the Org supplied and returns the properties" {
                Mock -CommandName Get-VMCSDDC -MockWith { $MockedArray }
                $(Get-VMCSDDCPublicIP -Org $OrgId)[0]  | Should -be $Public_ip_pool

                $(Get-VMCSDDCPublicIP -Org $OrgId)[1]  | Should -be $Public_ip_pool
                #Assert-MockCalled -CommandName Select-Object -Times 2 -Scope It
            }
            It "writes an error if not connected" {
                $global:DefaultVMCServers = $false
                { Get-VMCSDDCPublicIP -Org $OrgId  } | Should Not Throw
                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It -ParameterFilter { $org -eq $Org -and $Sddc -eq $Sddc  }
            }
        }
    }
}