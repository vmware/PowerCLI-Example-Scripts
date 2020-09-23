#Requires -Modules Pester, VMware.VMC
Import-Module -Name VMware.VimAutomation.Cis.Core

inModuleScope VMware.VMC {
    $functionName = "Get-VMCFirewallRule"
    Describe "$functionName" -Tag 'Unit' {
        . "$PSScriptRoot/Shared.ps1"

        $global:DefaultVMCServers = $true

        $Service = "com.vmware.vmc.orgs.sddcs.networks.edges.firewall.config"
        $OrgId = "Mocked OrgID"
        $GatewayType = "MGW"
        $SddcName = "MockedSDDCName"
        $OrgName = "MockedOrgName"
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
        Mock -CommandName Get-VMCSDDC -MockWith { $orgs }

        Mock -CommandName Get-VMCService -MockWith { $MockedServiceObj }

        $MockedServiceObj | Add-Member -MemberType ScriptMethod -Name "Get" -Value { $ServicesObject }
        $MockedServiceObj | Add-Member -MemberType ScriptMethod -Name "list" -Value { $ServicesObject }

        Mock -CommandName Write-Error -MockWith {}

        Context "Sanity checking" {
            $command = Get-Command -Name $functionName

            defParam $command 'OrgName'
            defParam $command 'SDDCName'
            defParam $command 'ShowAll'
            defParam $command 'GatewayType'
        }

        Context "Behavior testing" {
            # Testing single Org with optional SDDC parameter
            It "calls Get-VMCFirewallRule with the Org name supplied" {
                { Get-VMCFirewallRule -GatewayType $GatewayType -SDDCName $SddcName -OrgName $OrgName} | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCOrg -Times 1 -Scope It #-ParameterFilter { $Name -eq $SddcName }
                Assert-MockCalled -CommandName Get-VMCSDDC -Times 1 -Scope It -ParameterFilter { $Name -eq $SddcName -and $Org -eq $OrgName }
            }
            It "calls get-service to com.vmware.vmc.orgs.sddcs" {
                { Get-VMCFirewallRule -GatewayType $GatewayType } | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCService -Times 1 -Scope It -ParameterFilter { $name -eq $Service }
            }
            # Testing a single SDDC response
            It "gets the task details via list method and returns the properties" {
                $(Get-VMCFirewallRule -GatewayType $GatewayType).version  | Should -be $version
            }
            It "writes an error if not connected" {
                $global:DefaultVMCServers = $false
                { Get-VMCFirewallRule -GatewayType $GatewayType } | Should Not Throw
                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It -ParameterFilter { $org -eq $Org -and $Sddc -eq $Sddc  }
            }
        }
    }
}