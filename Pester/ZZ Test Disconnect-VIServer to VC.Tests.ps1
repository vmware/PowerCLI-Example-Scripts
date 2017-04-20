<#
Script name: Test Disconnect-VIServer to VC.ps1
Created on: 04/20/2017
Author: Alan Renouf, @alanrenouf
Description: The purpose of this pester test is to ensure the Disconnect-VIServer cmdlet disconnects
Dependencies: Pester Module
Example run:

Invoke-Pester -Script @{ Path = '.\Test Disconnect-VISServer to VC.ps1'; Parameters = @{ VCNAME="VC01.local" } }

#>

$VCNAME = $Parameters.Get_Item("VCNAME")

Describe "Disconnect-VIServer Tests" {
    It "Disconnect from $VCName" {
        Disconnect-VIServer $VCName -confirm:$false
        $Global:DefaultVIServer | Should Be $null
    }
}