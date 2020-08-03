function Apply-OMRightsizing {
<#	
    .NOTES
    ===========================================================================
    Created by: Markus Kraus
    ===========================================================================
    Changelog:  
    2020.07 ver 1.0 Base Release  
    ===========================================================================
    External Code Sources: 
    -
    ===========================================================================
    Tested Against Environment:
    vSphere Version: vSphere 6.7 U3
    PowerCLI Version: PowerCLI 11.5
    PowerShell Version: 5.1
    OS Version: Windows 10
    Keyword: vSphere, vRealize, Rightsizing
    ===========================================================================

    .DESCRIPTION
    This function views or applies rightsizing recommendations from vRealize Operations to your vSphere VMs.

    .Example
    Get-VM -Name test-* | Get-OMResource | Apply-OMRightsizing -ViewOnly  | Sort-Object DownSizeMemGB, DownSizeCPU -Descending | Format-Table -AutoSize

    .Example
    Get-VM -Name test-* | Get-OMResource | Apply-OMRightsizing -Apply -NoUpsizing

    .PARAMETER OMResources
    vRealize Operations Ressources to process

    .PARAMETER ViewOnly
    View Recommendations

    .PARAMETER Apply
    Apply Recommendations

    .PARAMETER NoUpsizing
    Apply only Downsizing Recommendations

#Requires PS -Version 5.1
#Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="11.5.0.0"}
#>

    [CmdletBinding()]
        param(
            [Parameter(Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage = "OM Ressources to process")]
            [ValidateNotNullorEmpty()]
                $OMResources,
            [Parameter(Mandatory=$False, ValueFromPipeline=$False, ParameterSetName="ViewOnly", HelpMessage = "View Recommendations")]
                [Switch] $ViewOnly,
            [Parameter(Mandatory=$False, ValueFromPipeline=$False, ParameterSetName="Apply", HelpMessage = "Apply Recommendations")]
                [Switch] $Apply,
            [Parameter(Mandatory=$False, ValueFromPipeline=$False, ParameterSetName="Apply", HelpMessage = "Apply only Downsizing Recommendations")]
                [Switch] $NoUpsizing
        )
    Process {
        if ($ViewOnly -or $Apply){
            "Collecting Report ..."

            $View = @()

            foreach ($OMResource in $OMResources){
                $DownSize = ($OMResource | Get-OMStat -Key "summary|oversized" -From ([DateTime]::Now).AddMinutes(-120) | Select-Object -Last 1).Value
                $UpSize = ($OMResource | Get-OMStat -Key "summary|undersized" -From ([DateTime]::Now).AddMinutes(-120) | Select-Object -Last 1).Value

                # Mem is in KB
                if($DownSize -gt 0){
                    $DownSizeMem = ($OMResource | Get-OMStat -Key "summary|oversized|memory" -From ([DateTime]::Now).AddMinutes(-120) | Select-Object -Last 1).Value
                    $DownSizeCPU = ($OMResource | Get-OMStat -Key "summary|oversized|vcpus" -From ([DateTime]::Now).AddMinutes(-120) | Select-Object -Last 1).Value
                }
                else {
                    $DownSizeMem = 0
                    $DownSizeCPU = 0
                }

                # Mem is in KB
                if($UpSize -gt 0){
                    $UpSizeMem = ($OMResource | Get-OMStat -Key "summary|undersized|memory" -From ([DateTime]::Now).AddMinutes(-120) | Select-Object -Last 1).Value
                    $UpSizeCPU = ($OMResource | Get-OMStat -Key "summary|undersized|vcpus" -From ([DateTime]::Now).AddMinutes(-120) | Select-Object -Last 1).Value
                }
                else {
                    $UpSizeMem = 0
                    $UpSizeCPU = 0
                }

                $Report = [PSCustomObject] @{
                        Name = $OMResource.name
                        DownSize = $DownSize
                        UpSize = $UpSize
                        DownSizeMem = $DownSizeMem
                        DownSizeMemGB = [Math]::Round(($DownSizeMem / 1048576), 0)
                        DownSizeCPU = $DownSizeCPU
                        UpSizeMem = $UpSizeMem
                        UpSizeMemGB = [Math]::Round(($UpSizeMem / 1048576), 0)
                        UpSizeCPU = $upSizeCPU

                    }
                    $View += $Report
                }

        }
        if ($ViewOnly){
            $View
        }
        if ($Apply){
            foreach ($Object in $View) {

                if ($Object.DownSize -gt 0 -or $Object.UpSize -gt 0){
                    "Processing '$($Object.Name)' ..."
                    $VM = Get-VM -Name $Object.Name
                    "Shut down '$($Object.Name)' ..."
                    $VM | Shutdown-VMGuest -Confirm:$False
                    $i = 0
                    while((Get-VM -Name $VM.Name).PowerState -eq "PoweredOn"){
                        $i++
                        Start-Sleep 1
                        Write-Progress -Activity "Check PowerState" -Status "Wait for PowerState Task..."
                    }
                    "Create Snapshot for '$($Object.Name)' ..."
                    $VM | New-Snapshot -Name "Pre Resize" -Memory:$false -Quiesce:$false
                    if ($Object.DownSize -gt 0){
                        "Downsize '$($Object.Name)' ..."
                        $VM | Set-VM -NumCPU $($VM.NumCpu - $Object.DownSizeCPU) -MemoryGB $($VM.MemoryGB - $Object.DownSizeMemGB) -Confirm:$False

                    }
                    if ($Object.UpSize -gt 0 -and $NoUpsizing -eq $False){
                        "Upsize '$($Object.Name)' ..."
                        $VM = Get-VM -Name $Object.Name
                        $VM | Set-VM -NumCPU $($VM.NumCpu + $Object.UpSizeCPU) -MemoryGB $($VM.MemoryGB + $Object.UpSizeMemGB) -Confirm:$False

                    }
                    #$VM = Get-VM -Name $Object.Name
                    #$VM | Get-VMResourceConfiguration | Set-VMResourceConfiguration -CpuReservationMhz $($VM.NumCpu * 200) -MemReservationGB $($VM.MemoryGB / 2) -Confirm:$False
                    "Power on '$($Object.Name)' ..."
                    $VM | Start-VM -Confirm:$False
                }

            }

        }

    }
}