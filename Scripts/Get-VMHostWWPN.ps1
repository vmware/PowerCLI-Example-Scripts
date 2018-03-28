function Get-VMHostWWPN {
<#
Script name: Get-VMHostWWPN.ps1
Created on: 08/31/2017
Author: Robin Haberstroh, @strohland
Description: This script returns the WWPN of the hosts FiberChannel HBA in a readable format that corresponds to what storage team expects
Dependencies: None known
#>
    param(
        [string]$cluster
    )

    Get-Cluster $cluster | get-vmhost | get-vmhosthba -type FibreChannel | 
    format-table VMHost, Device, @{
        n='WorldWidePortName';e={[convert]::ToString($_.PortWorldWideName, 16)}
    }
}