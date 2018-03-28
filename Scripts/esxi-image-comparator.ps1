<#
Script name: esxi-image-comparator.ps1
Last update: 24 May 2017
Author: Eric Gray, @eric_gray
Description: Compare contents (VIBs) of multiple VMware ESXi image profiles.
Dependencies: PowerCLI Image Builder (VMware.ImageBuilder,VMware.VimAutomation.Core)
#>

param(
    [switch]$ShowAllVIBs=$false,
    [switch]$HideDates=$false,
    [switch]$Interactive=$false,
    [switch]$Grid=$false,
    [string]$ProfileInclude,
    [string]$ProfileExclude
)

$profileList = Get-EsxImageProfile | sort -Property Name

if ($ProfileInclude) {
    $profileList = $profileList | ? Name -Match $ProfileInclude
}

if ($ProfileExclude) {
    $profileList = $profileList | ? Name -NotMatch $ProfileExclude
}

if ($profileList.Count -eq 0) {
    Write-Host "No ESXi image profiles available in current session."
    Write-Host "Use Add-EsxSoftwareDepot for each depot zip bundle you would like to compare."
    exit 1
}

if ($Interactive) {
    $keep = @()
    Write-Host "Found the following profiles:" -ForegroundColor Yellow
    $profileList | % { write-host $_.Name }
    
    if ($profileList.Count -gt 7) {
        Write-Host "Found $($profileList.Count) profiles!" -ForegroundColor Yellow
        Write-Host "Note: List filtering is possible through -ProfileInclude / -ProfileExclude" -ForegroundColor DarkGreen
    }

    write-host "`nType 'y' next to each profile to compare..." -ForegroundColor Yellow

    foreach ($profile in $profileList) {
        $want = Read-Host -Prompt $profile.Name 
        if ($want.StartsWith("y") ) {
            $keep += $profile
        }

    }
    $profileList = $keep

}

# go thru each profile and build a hash of the vib name and hash of profile name + version
$diffResults = @{}
foreach ($profile in $profileList ) {
    foreach ($vib in $profile.VibList) {
      $vibValue = $vib.Version
      if (! $HideDates) {
        $vibValue += " "+ $vib.CreationDate.ToShortDateString()
      }
      $diffResults.($vib.name) += @{$profile.name = $vibValue}

    }

}

# create an object that will neatly output as CSV or table
$outputTable=@()
foreach ($row in $diffResults.keys | sort) {
    $vibRow = new-object PSObject
    $vibRow | add-member -membertype NoteProperty -name "VIB" -Value $row
    $valueCounter = @{}

    foreach ($profileName in $profileList.name) {
        #populate this hash to decide if all profiles have same version of VIB
        $valueCounter.($diffResults.$row.$profileName) = 1
        $vibRow | add-member -membertype NoteProperty -name $profileName -Value $diffResults.$row.$profileName
    }

    if ($valueCounter.Count -gt 1 -or $ShowAllVIBs) {
       $outputTable += $vibRow        
    }
}

# useful for debugging
#$diffResults | ConvertTo-Json
#$outputTable|Export-Csv -Path .\image-diff-results.csv -NoTypeInformation

if ($Grid) {
    $outputTable | Out-GridView -Title "VMware ESXi Image Profile Comparator"
} else {
    $outputTable
}