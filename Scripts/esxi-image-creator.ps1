<#
Script name: esxi-image-creator.ps1
Last update: 24 May 2017
Author: Eric Gray, @eric_gray
Description: Create a VMware ESXi image profile based on
    one or more depots and offline driver bundles.
Dependencies: PowerCLI Image Builder (VMware.ImageBuilder,VMware.VimAutomation.Core)
#>

param(
    [switch]$NewestDate = $false,
    [switch]$WriteZip = $false,
    [switch]$WriteISO = $false,
    [switch]$LeaveCurrentDepotsMounted = $false,
    [string]$NewProfileName = "Custom Image $(Get-Date -Format "yyyyMMddhhmm")",
    [ValidateNotNullOrEmpty()]
    [ValidateSet('VMwareCertified','VMwareAccepted','PartnerSupported','CommunitySupported')]
    [string]$Acceptance = "VMwareCertified",
    [string[]]$Files = "*.zip"
)

#### Specify optional image fine-tuning here ####
# comma-separated list (array) of VIBs to exclude
$removeVibs = @("tools-light")

# force specific VIB version to be included, when more than one version is present
# e.g. "net-enic"="2.1.2.71-1OEM.550.0.0.1331820"
$overrideVibs = @{
   # "net-enic"="2.1.2.71-1OEM.550.0.0.1331820",
}

#### end of optional fine-tuning ####

# may be desirable to manually mount an online depot in advance, such as for HPE
# e.g. Add-EsxSoftwareDepot http://vibsdepot.hpe.com/index-ecli-650.xml
if (! $LeaveCurrentDepotsMounted) {
    Get-EsxSoftwareDepot | Remove-EsxSoftwareDepot
}

foreach ($depot in Get-ChildItem $Files) {
    if ($depot.Name.EndsWith(".zip") ) {
        Add-EsxSoftwareDepot $depot.FullName
    } else {
        Write-Host "Not a zip depot:" $depot.Name
    }
}

if ((Get-EsxImageProfile).count -eq 0) {
    write-host "No image profiles found in the selected files"
    exit 1
}

# either use the native -Newest switch, or try to find latest VIBs by date (NewestDate)
if ($NewestDate) {
    $pkgsAll = Get-EsxSoftwarePackage | sort -Property Name,CreationDate -Descending
    $pkgsNewestDate=@()

    foreach ($pkg in $pkgsAll) {
        if ($pkgsNewestDate.GetEnumerator().name -notcontains $pkg.Name ) {
            $pkgsNewestDate += $pkg
        }
    }
    $pkgs = $pkgsNewestDate

} else {
    $pkgs = Get-ESXSoftwarePackage -Newest
}

# rebuild the package array according to manual fine-tuning
if ($removeVibs) {
    Write-Host "`nThe following VIBs will not be included in ${NewProfileName}:" -ForegroundColor Yellow
    $removeVibs
    $pkgs = $pkgs | ? name -NotIn $removeVibs
}

foreach ($override in $overrideVibs.keys) {
    # check that the override exists, then remove existing and add override
    $tmpOver = Get-EsxSoftwarePackage -Name  $override -Version $overrideVibs.$override
    if ($tmpOver) {
        $pkgs = $pkgs | ? name -NotIn $tmpOver.name
        $pkgs += $tmpOver
    } else {
        Write-host "Did not find:" $override $overrideVibs.$override -ForegroundColor Yellow
    }
}

try {
    New-EsxImageProfile -NewProfile $NewProfileName -SoftwarePackage $pkgs `
     -Vendor Custom  -AcceptanceLevel $Acceptance -Description "Made with esxi-image-creator.ps1" `
     -ErrorAction Stop -ErrorVariable CreationError | Out-Null
}
catch {
    Write-Host "Custom image profile $NewProfileName not created." -ForegroundColor Yellow
    $CreationError
    exit 1
}

Write-Host "`nFinished creating $NewProfileName" -ForegroundColor Yellow

if ($WriteZip) {
    Write-Host "Creating zip bundle..." -ForegroundColor Green
    Export-EsxImageProfile -ImageProfile $NewProfileName -ExportToBundle -FilePath .\${NewProfileName}.zip -Force
}

if ($WriteISO) {
    Write-Host "Creating ISO image..." -ForegroundColor Green
    Export-EsxImageProfile -ImageProfile $NewProfileName -ExportToIso -FilePath .\${NewProfileName}.iso -Force
}
