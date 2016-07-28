# To run: "Invoke-Pester <path>\Get-DatastoreProvisioned.Tests.ps1"

<#
Script name: Get-DatastoreProvisioned.Tests.ps1
Created on: 2016/07/27
Author: Brian Bunke, @brianbunke
Description: Help validate that any changes to Get-DatastoreProvisioned.ps1 do not break existing functionality
Dependencies: Pester

===Tested Against Environment====
vSphere Version: 6.0 U1/U2
PowerCLI Version: PowerCLI 6.3 R1
PowerShell Version: 5.0
OS Version: Windows 7/10
#>

# Tests file stored separately from actual script
# Find where this file is running from, replace parent folder 'Pester' with 'Scripts'
$Path = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace("Pester","Scripts")
# Remove the '.Tests.' from the file name
$File = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
# With changes made to the path, dot-source the function for testing
. "$Path\$File"

Describe 'Get-DatastoreProvisioned' {
    # Need to create a few example objects to proxy Get-Datastore pipeline input
    $1 = [PSCustomObject]@{
        Name          = 'iSCSI-spin'
        CapacityGB    = 38.40
        FreeSpaceGB   = 15.55
        ExtensionData = @{
            Summary = @{
                Capacity    = 41234567890
                FreeSpace   = 16696685366
                Uncommitted = 12345678999
    }}}
    $2 = [PSCustomObject]@{
        Name          = 'iSCSI-ssd'
        CapacityGB    = 51.74
        FreeSpaceGB   = 10.35
        ExtensionData = @{
            Summary = @{
                Capacity    = 55555555555
                FreeSpace   = 11111111111
                Uncommitted = 23456765432
    }}}
    $3 = [PSCustomObject]@{
        Name          = 'FC-ssd'
        CapacityGB    = 10.35
        FreeSpaceGB   = 4.14
        ExtensionData = @{
            Summary = @{
                Capacity    = 11111111111
                FreeSpace   = 4444444444
                Uncommitted = 2222222222
    }}}

    It "Doesn't change existing functionality" {
        $StillWorks = $1,$2,$3 | Get-DatastoreProvisioned
        $StillWorks | Should Not BeNullOrEmpty
        ($StillWorks | Measure-Object).Count | Should Be 3
        ($StillWorks | Get-Member -MemberType NoteProperty).Count | Should Be 6
        'Name','FreeSpaceGB','CapacityGB','ProvisionedGB','UsedPct','ProvisionedPct' | ForEach-Object {
            ($StillWorks | Get-Member -MemberType NoteProperty).Name -contains $_ | Should Be $true
        }
    }

    It 'Still calculates correctly' {
        $calc = $1 | Get-DatastoreProvisioned
        $calc | Should Not BeNullOrEmpty
        $calc.ProvisionedGB | Should Be 34.35
        $calc.UsedPct | Should Be 59.51
        $calc.ProvisionedPct | Should Be 89.45
    }

    # Get-Datastore | Get-DatastoreProvisioned | Format-Table -AutoSize
    It 'Follows Help Example 1' {
        $Help1 = $1,$2,$3 | Get-DatastoreProvisioned
        $Help1 | Should Not BeNullOrEmpty
        ($Help1 | Measure-Object).Count | Should Be 3
        # not testing Format-Table
    }

    # Get-Datastore -Name '*ssd' | Get-DatastoreProvisioned | Where-Object ProvisionedPct -ge 100
    It 'Follows Help Example 2' {
        $Help2 = $1,$2,$3 | Where Name -like '*ssd' | Get-DatastoreProvisioned | Where ProvisionedPct -ge 100
        $Help2 | Should Not BeNullOrEmpty
        ($Help2 | Measure-Object).Count | Should Be 1
        $Help2.Name | Should BeExactly 'iSCSI-ssd'
        $Help2.ProvisionedPct | Should BeGreaterThan 100
    }
}
