#Requires -Modules Pester, VMware.VMC
Import-Module -Name VMware.VimAutomation.Cis.Core

inModuleScope VMware.VMC {
    $functionName = "Get-VMCVMHost"
    Describe "$functionName" -Tag 'Unit' {
        . "$PSScriptRoot/Shared.ps1"

        $global:DefaultVMCServers = $true

        $OrgId = "Mocked OrgID"
        $SddcId = "MockedSDDCName"
        $VMhostName = "Mockedvc_url"
        $VMHost_name = "MockedVCmanage_ip"
        $esx_state = "MockedVCpublic_ip"
        $esx_id = "Mocked_esx_id"

        $object = @([PSCustomObject]@{
            "resource_config" = @{
                esx_hosts = @(@{
                    esx_id = $esx_id
                    name = $VMHost_name
                    hostname = $VMhostName
                    esx_state = $esx_state
                })
            }
            "id" = $SddcId
            "Org_Id" = $OrgId
        })

        $MockedArray = @($object, $object)

        Mock -CommandName Get-VMCSDDC -MockWith { $object }

        Mock -CommandName Write-Error -MockWith {}

        Context "Sanity checking" {
            $command = Get-Command -Name $functionName

            defParam $command 'Org'
            defParam $command 'Sddc'
        }

        Context "Behavior testing" {
            # Testing single Org with optional SDDC parameter
            It "calls Get-VMCVMHost with the Org name supplied" {
                { Get-VMCVMHost -Org $OrgId -sddc $SddcName} | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCSDDC -Times 1 -Scope It -ParameterFilter { $Org -eq $OrgId -and $name -eq $SddcName }
            }
            # Testing single Org without SDDC parameter.
            It "calls get-VMCVMHost without SDDC name supplied" {
                { Get-VMCVMHost -Org $OrgId } | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCSDDC -Times 1 -Scope It -ParameterFilter { $org -eq $OrgId }
            }
            # Testing a single SDDC response
            It "gets the task details via list method and returns the properties" {
                $(Get-VMCVMHost -Org $OrgId).esx_id  | Should -be $esx_id
                $(Get-VMCVMHost -Org $OrgId).name  | Should -be $VMHost_name
                $(Get-VMCVMHost -Org $OrgId).hostname  | Should -be $VMhostName
                $(Get-VMCVMHost -Org $OrgId).esx_state  | Should -be $esx_state
                $(Get-VMCVMHost -Org $OrgId).sddc_id  | Should -be $SddcId
                $(Get-VMCVMHost -Org $OrgId).org_id  | Should -be $OrgId
            }
            # Testing the multiple SDDC response
            It "gets the task details of the Org supplied and returns the properties" {
                Mock -CommandName Get-VMCSDDC -MockWith { $MockedArray }
                $(Get-VMCVMHost -Org $OrgId)[0].esx_id  | Should -be $esx_id
                $(Get-VMCVMHost -Org $OrgId)[0].name  | Should -be $VMHost_name
                $(Get-VMCVMHost -Org $OrgId)[0].hostname  | Should -be $VMhostName
                $(Get-VMCVMHost -Org $OrgId)[0].esx_state  | Should -be $esx_state
                $(Get-VMCVMHost -Org $OrgId)[0].sddc_id  | Should -be $SddcId
                $(Get-VMCVMHost -Org $OrgId)[0].org_id  | Should -be $OrgId

                $(Get-VMCVMHost -Org $OrgId)[1].esx_id  | Should -be $esx_id
                $(Get-VMCVMHost -Org $OrgId)[1].name  | Should -be $VMHost_name
                $(Get-VMCVMHost -Org $OrgId)[1].hostname  | Should -be $VMhostName
                $(Get-VMCVMHost -Org $OrgId)[1].esx_state  | Should -be $esx_state
                $(Get-VMCVMHost -Org $OrgId)[1].sddc_id  | Should -be $SddcId
                $(Get-VMCVMHost -Org $OrgId)[1].org_id  | Should -be $OrgId
            }
            It "writes an error if not connected" {
                $global:DefaultVMCServers = $false
                { Get-VMCVMHost -Org $OrgId  } | Should Not Throw
                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It -ParameterFilter { $org -eq $Org -and $Sddc -eq $Sddc  }
            }
        }
    }
}