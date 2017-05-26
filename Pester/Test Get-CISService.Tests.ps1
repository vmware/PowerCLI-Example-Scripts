<#
Script name: Test Connect-CISService.Tests.ps1
Created on: 04/20/2017
Author: Alan Renouf, @alanrenouf
Description: The purpose of this pester test is to ensure the CIS Service cmdlet works correctly
Dependencies: Pester Module
Example run:

Invoke-Pester -Script @{ Path = '.\Test Get-CISService.ps1' }

#>

Describe "Checking PowerCLI Cmdlets available" {
    $cmdletname = "Get-CISService"
    It "Checking $cmdletname is available" {
        $command = Get-Command $cmdletname
        $command | Select Name, Version
        $command.Name| Should Be $cmdletname
    }
}

Describe "Get-CISService Tests for services" {

    It "Checking CIS connection is active" {
        $Global:DefaultCISServers[0].isconnected  | Should Be $true
    }

    It "Checking Get-CISService returns services" {
        Get-CISService | Should Be $true
    }

    # Checking some known services which have a Get Method
    $servicestocheck = "com.vmware.appliance.system.version", "com.vmware.appliance.health.system"
    Foreach ($service in $servicestocheck) {
        It "Checking $service get method returns data" {
            Get-CisService -Name $service | Should Be $true
            (Get-CisService -Name $service).get() | Should Be $true
        }
    }

    # Checking some known services which have a List Method
    $servicestocheck = "com.vmware.vcenter.folder", "com.vmware.vcenter.vm"
    Foreach ($service in $servicestocheck) {
        It "Checking $service list method returns data" {
            Get-CisService -Name $service | Should Be $true
            (Get-CisService -Name $service).list() | Should Be $true
        }
    }
}