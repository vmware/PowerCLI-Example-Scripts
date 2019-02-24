#Requires -Modules Pester, VMware.VMC
Import-Module -Name VMware.VimAutomation.Cis.Core

inModuleScope VMware.VMC {
    $functionName = "Get-VMCSDDCDefaultCredential"
    Describe "$functionName" -Tag 'Unit' {
        . "$PSScriptRoot/Shared.ps1"

        $global:DefaultVMCServers = $true

        $OrgId = "Mocked OrgID"
        $SddcName = "MockedSDDCName"
        $vc_url = "Mockedvc_url"
        $vc_management_ip = "MockedVCmanage_ip"
        $vc_public_ip = "MockedVCpublic_ip"
        $cloud_username = "MockedCloudUser"
        $cloud_password = "MockedCloudPass"

        $MockedList = [PSCustomObject]@{
            "vc_url"           = $vc_url
            "vc_management_ip" = $vc_management_ip
            "vc_public_ip"     = $vc_public_ip
            "cloud_username"   = $cloud_username
            "cloud_password"   = $cloud_password
        }
        $MockedList2 = [PSCustomObject]@{
            "vc_url"           = $vc_url
            "vc_management_ip" = $vc_management_ip
            "vc_public_ip"     = $vc_public_ip
            "cloud_username"   = $cloud_username
            "cloud_password"   = $cloud_password
        }

        $object = [PSCustomObject]@{
            "resource_config" = @($MockedList)
        }

        $MockedArray = @{ 
            "resource_config" = @($MockedList, $MockedList2)
        }

        Mock -CommandName Get-VMCSDDC -MockWith { $object }

        Mock -CommandName Write-Error -MockWith {}

        Mock -CommandName Select-Object { $MockedList }

        Context "Sanity checking" {
            $command = Get-Command -Name $functionName

            defParam $command 'Org'
            defParam $command 'Sddc'
        }

        Context "Behavior testing" {
            # Testing single Org with optional SDDC parameter
            It "calls Get-VMCSDDC with the Org name supplied" {
                { Get-VMCSDDCDefaultCredential -Org $OrgId -sddc $SddcName} | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCSDDC -Times 1 -Scope It -ParameterFilter { $Org -eq $OrgId -and $name -eq $SddcName }
            }
            # Testing single Org without SDDC parameter.
            It "calls get-VMCSDDC without SDDC name supplied" {
                { Get-VMCSDDCDefaultCredential -Org $OrgId } | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCSDDC -Times 1 -Scope It -ParameterFilter { $org -eq $OrgId }
            }
            # Testing a single SDDC response
            It "gets the task details via list method and returns the properties" {
                $(Get-VMCSDDCDefaultCredential -Org $OrgId).vc_url  | Should -be $vc_url
                $(Get-VMCSDDCDefaultCredential -Org $OrgId).vc_management_ip  | Should -be $vc_management_ip
                $(Get-VMCSDDCDefaultCredential -Org $OrgId).vc_public_ip  | Should -be $vc_public_ip
                $(Get-VMCSDDCDefaultCredential -Org $OrgId).cloud_username  | Should -be $cloud_username
                $(Get-VMCSDDCDefaultCredential -Org $OrgId).cloud_password  | Should -be $cloud_password
                Assert-MockCalled -CommandName Select-Object -Times 1 -Scope It
            }
            # Testing the multiple SDDC response
            It "gets the task details of the Org supplied and returns the properties" {
                Mock -CommandName Get-VMCSDDC -MockWith { $MockedArray }
                $(Get-VMCSDDCDefaultCredential -Org $OrgId)[0].vc_url  | Should -be $vc_url
                $(Get-VMCSDDCDefaultCredential -Org $OrgId)[0].vc_management_ip  | Should -be $vc_management_ip
                $(Get-VMCSDDCDefaultCredential -Org $OrgId)[0].vc_public_ip  | Should -be $vc_public_ip
                $(Get-VMCSDDCDefaultCredential -Org $OrgId)[0].cloud_username  | Should -be $cloud_username
                $(Get-VMCSDDCDefaultCredential -Org $OrgId)[0].cloud_password  | Should -be $cloud_password

                $(Get-VMCSDDCDefaultCredential -Org $OrgId)[1].vc_url  | Should -be $vc_url
                $(Get-VMCSDDCDefaultCredential -Org $OrgId)[1].vc_management_ip  | Should -be $vc_management_ip
                $(Get-VMCSDDCDefaultCredential -Org $OrgId)[1].vc_public_ip  | Should -be $vc_public_ip
                $(Get-VMCSDDCDefaultCredential -Org $OrgId)[1].cloud_username  | Should -be $cloud_username
                $(Get-VMCSDDCDefaultCredential -Org $OrgId)[1].cloud_password  | Should -be $cloud_password
                Assert-MockCalled -CommandName Select-Object -Times 2 -Scope It
            }
            It "writes an error if not connected" {
                $global:DefaultVMCServers = $false
                { Get-VMCSDDCDefaultCredential -Org $OrgId  } | Should Not Throw
                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It -ParameterFilter { $org -eq $Org -and $Sddc -eq $Sddc  }
            }
        }
    }
}