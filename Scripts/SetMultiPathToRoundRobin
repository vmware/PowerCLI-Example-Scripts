<#
Script name: SetMultiPathToRoundRobin.ps1
Created on: 09/13/2017
Author: Alan Comstock, @Mr_Uptime
Description: Set the MultiPath policy for FC devices to RoundRobin
Dependencies: None known
PowerCLI Version: VMware PowerCLI 6.5 Release 1 build 4624819
PowerShell Version: 5.1.14393.1532
OS Version: Windows 10
#>

#Check a host for any Fibre Channel devices that are not set to Round Robin.  Modify to check clusters if needed.
Get-VMhost HOSTNAME | Get-VMHostHba -Type "FibreChannel" | Get-ScsiLun -LunType disk | Where { $_.MultipathPolicy -notlike "RoundRobin" } | Select CanonicalName,MultipathPolicy

#Set the Multipathing Policy on a host to Round Robin for any Fibre Channel devices that are not Round Robin
$scsilun = Get-VMhost HOSTNAME | Get-VMHostHba -Type "FibreChannel" | Get-ScsiLun -LunType disk | Where { $_.MultipathPolicy -notlike "RoundRobin" }
Set-ScsiLun -ScsiLun $scsilun -MultipathPolicy RoundRobin
