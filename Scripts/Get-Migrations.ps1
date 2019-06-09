<#
Script name: get-migrations.ps1
Created on: 20/12/2018
Author: Chris Bradshaw @aldershotchris
Description: The purpose of the script is to list the currently running + recently finished VM migrations.
Dependencies: None known
#>
Function Get-Migrations{
    Get-Task | 
        Where-Object{$_.Name -eq "RelocateVM_Task"} | 
        Select-Object @{Name="VM";Expression={Get-VM -Id $_.ObjectID}}, State, @{Name="% Complete";Expression={$_.PercentComplete}},StartTime
}
