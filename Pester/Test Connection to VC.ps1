<#
Script name: Test Connection to VC.ps1
Created on: 07/15/2016
Author: Alan Renouf, @alanrenouf
Description: The purpose of this pester test is to ensure the PowerCLI modules are imported and a connection and disconnection can be made to a vCenter
Dependencies: Pester Module
Example run:

Invoke-Pester -Script @{ Path = '.\Test Connection to VC.ps1'; Parameters = @{ VCNAME="VC01.local"; VCUSER="Administrator@vsphere.local"; VCPASS="Admin!23"} }

#>

$VCUSER = $Parameters.Get_Item("VCUSER")
$VCPASS = $Parameters.Get_Item("VCPASS")
$VCNAME = $Parameters.Get_Item("VCNAME")

Describe "PowerCLI Tests" {
    It "Importing PowerCLI Modules" {
        Get-Module VMware* | Foreach {
        	Write-Host "Importing Module $($_.name) Version $($_.Version)"
    	    $_ | Import-Module
	        Get-Module $_ | Should Be $true
        }
    }
}

Describe "Connect-VIServer Tests" {

    $connection = Connect-VIServer $VCName -User $VCUser -password $VCPass
    It "Connection is active" {
        $Global:DefaultVIServer[0].isconnected  | Should Be $true
    }

    It "Checking connected server name is $VCName" {
        $Global:DefaultVIServer[0].name  | Should Be $VCName
    }
}

Describe "Disconnect-VIServer Tests" {
    It "Disconnect from $VCName" {
        Disconnect-VIServer $VCName -confirm:$false
        $Global:DefaultVIServer | Should Be $null
    }
}