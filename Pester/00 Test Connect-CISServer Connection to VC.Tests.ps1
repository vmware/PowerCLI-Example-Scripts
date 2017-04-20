<#
Script name: Test Connect-CISServer to VC.Tests.ps1
Created on: 04/20/2017
Author: Alan Renouf, @alanrenouf
Description: The purpose of this pester test is to ensure the PowerCLI modules are imported and a connection can be made to a vCenter for the CIS Service
Dependencies: Pester Module
Example run:

Invoke-Pester -Script @{ Path = '.\Test Connect-CISServer to VC.Tests.ps1'; Parameters = @{ VCNAME="VC01.local"; VCUSER="Administrator@vsphere.local"; VCPASS="Admin!23"} }

#>

$VCUSER = $Parameters.Get_Item("VCUSER")
$VCPASS = $Parameters.Get_Item("VCPASS")
$VCNAME = $Parameters.Get_Item("VCNAME")

Describe "Checking PowerCLI Cmdlets available" {
    $cmdletname = "Connect-CISServer"
    It "Checking $cmdletname is available" {
        $command = Get-Command $cmdletname
        $command | Select Name, Version
        $command.Name| Should Be $cmdletname
    }
}

Describe "Connect-CISServer Tests" {

    $connection = Connect-CISServer $VCName -User $VCUser -password $VCPass
    It "Connection is active" {
        $Global:DefaultCISServers[0].isconnected  | Should Be $true
    }

    It "Checking connected server name is $VCName" {
        $Global:DefaultCISServers[0] | Select *
        $Global:DefaultCISServers[0].name  | Should Be $VCName
    }
}