<#
Script name: Test Disconnect-CISServer to VC.Tests.ps1
Created on: 04/20/2017
Author: Alan Renouf, @alanrenouf
Description: The purpose of this pester test is to ensure the Disconnect-CISServer cmdlet disconnects
Dependencies: Pester Module
Example run:

Invoke-Pester -Script @{ Path = '.\Test Disconnect-CISServer to VC.Tests.ps1'; Parameters = @{ VCNAME="VC01.local" } }

#>

$VCNAME = $Parameters.Get_Item("VCNAME")

Describe "Disconnect-CISServer Tests" {
    It "Disconnect from $VCName" {
        Disconnect-CISServer $VCName -confirm:$false
        $Global:DefaultCISServers | Should Be $null
    }
}