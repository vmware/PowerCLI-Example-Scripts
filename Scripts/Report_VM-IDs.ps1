<#
Script name: Report_VM-IDs.ps1
Created on: 07/27/2016
Author: Markus Kraus, @vMarkus_K, http://mycloudrevolution.com/
Description: The purpose of the script is to report all VM IDs
Dependencies: None known
===Tested Against Environment====
vSphere Version: 5.5 U2
PowerCLI Version: PowerCLI 6.3 R1
PowerShell Version: 5.0, 4.0
OS Version: Windows 2012 R2, Windows 8.1
Keyword: VM
#>
$myVMs = Get-VM | sort Name

$MyView = @()
ForEach ($myVM in $myVMs){
	$UUIDReport = [PSCustomObject] @{
			Name = $myVM.name 
			UUID = $myVM.extensiondata.Config.UUID
			InstanceUUID = $myVM.extensiondata.config.InstanceUUID
			LocationID = $myVM.extensiondata.config.LocationId
			MoRef = $myVM.extensiondata.Moref.Value
			}
	$MyView += $UUIDReport
	}
$MyView | ft -AutoSize