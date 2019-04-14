<#
Script name: backup-esxi-host-configuration.ps1
Created on: 09/10/2018
Author: Gerasimos Alexiou, @jerrak0s
Description: The purpose of the script is to backup esxi host configuration for restore purposes.
Dependencies: None known

===Tested Against Environment====
vSphere Version: 6.5 U2
PowerCLI Version: PowerCLI 10.1.1
PowerShell Version: 5.1
OS Version: Windows 10
Keyword: Backup Configuration ESXi Host
#>


$serverIp = Read-Host 'What is the server ip address:'
$path = Read-Host 'Give path where backup configuration will be stored:'
$serverPass = Read-Host 'What is the server root password:' -AsSecureString
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Connect-VIServer serverip -user "root" -password $serverPass
Get-VMHostFirmware -vmhost serverip -BackupConfiguration -DestinationPath $path 