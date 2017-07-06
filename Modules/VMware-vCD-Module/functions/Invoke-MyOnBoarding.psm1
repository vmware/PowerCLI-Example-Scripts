#Requires -Version 4
#Requires -Modules VMware.VimAutomation.Cloud, @{ModuleName="VMware.VimAutomation.Cloud";ModuleVersion="6.3.0.0"}
Function Invoke-MyOnBoarding {
<#
.SYNOPSIS
    Creates all vCD Objecst for a new IAAS Customer

.DESCRIPTION
    Creates all vCD Objects for a new IAAS Customer

    All Objects are:
    * Org
    * Default Org Admin
    * Org VDC
    ** Private Catalog
    ** Optional Bridged Network

    JSON Config Example:

    {
    "Org": {
            "Name":"TestOrg",
            "FullName": "Test Org",
            "Description":"Automation Test Org"
        },
    "OrgAdmin": {
            "Name":"TestOrgAdmin",
            "Pasword": "myPassword1!",
            "FullName":"Test OrgAdmin",
            "EmailAddress":"test@admin.org"
        },
    "OrgVdc": {
            "Name":"TestOrgVdc",
            "FixedSize": "M",
            "CPULimit": "1000",
            "MEMLimit":"1000",
            "StorageLimit":"1000",
            "StorageProfile":"Standard-DC01",
            "ProviderVDC":"Provider-VDC-DC01",
            "NetworkPool":"Provider-VDC-DC01-NetPool",
            "ExternalNetwork": "External_OrgVdcNet"
        }
    }

.NOTES
    File Name  : Invoke-MyOnBoarding.ps1
    Author     : Markus Kraus
    Version    : 1.2
    State      : Ready

.LINK
    https://mycloudrevolution.com/

.EXAMPLE
    Invoke-MyOnBoarding -ConfigFile ".\OnBoarding.json" -Enabled:$true

.EXAMPLE
    Invoke-MyOnBoarding -ConfigFile ".\OnBoarding.json" -Enabled:$false

.PARAMETER ConfigFile
    Full Path to the JSON Config File

.PARAMETER Enabled
    Should the Customer be enabled after creation

    Default: $False

#>
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Full Path to the JSON Config File")]
        [ValidateNotNullorEmpty()]
            [String] $ConfigFile,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, HelpMessage="Should the Customer be enabled after creation")]
        [ValidateNotNullorEmpty()]
            [Switch]$Enabled
    )
    Process {

    $Valid = $true

    Write-Verbose "## Import JSON Config"
    Write-Host  "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Importing JSON Config...`n"
    $Configs = Get-Content -Raw -Path $ConfigFile -ErrorAction Continue | ConvertFrom-Json -ErrorAction Continue

    if (!($Configs)) {
        $Valid = $false
        Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Importing JSON Config Failed" -ForegroundColor Red
        }
        else {
            Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Importing JSON Config OK" -ForegroundColor Green
            }

    if ($Valid) {
        try{
            Write-Verbose "## Create Org"
            Write-Host  "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Creating new Org...`n" -ForegroundColor Yellow
            $Trash = New-MyOrg -Name $Configs.Org.Name -FullName $Configs.Org.Fullname -Description $Configs.Org.Description -Enabled:$Enabled
            Write-Host  "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Creating new Org OK" -ForegroundColor Green
            Get-Org -Name $Configs.Org.Name | Select-Object Name, FullName, Enabled | Format-Table -AutoSize
            }
            catch {
                $Valid = $false
                Write-Host  "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Creating new Org Failed" -ForegroundColor Red
            }
        }

    if ($Valid) {
        try{
            Write-Verbose "## Create OrgAdmin"
            Write-Host  "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Creating new OrgAdmin...`n" -ForegroundColor Yellow
            $Trash = New-MyOrgAdmin -Name $Configs.OrgAdmin.Name -Pasword $Configs.OrgAdmin.Pasword -FullName $Configs.OrgAdmin.FullName  -EmailAddress $Configs.OrgAdmin.EmailAddress -Org $Configs.Org.Name -Enabled:$Enabled
            Write-Host  "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Creating new OrgAdmin OK" -ForegroundColor Green
            Get-CIUser -Org $Configs.Org.Name -Name $Configs.OrgAdmin.Name  | Select-Object Name, FullName, Email | Format-Table -AutoSize
            }
            catch {
                $Valid = $false
                Write-Host  "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Creating new OrgAdmin Failed" -ForegroundColor Red
            }
        }
    if ($Valid) {
        try{
            Write-Verbose "## Create OrgVdc"
            Write-Host  "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Creating new OrgVdc...`n" -ForegroundColor Yellow

            if ($Configs.OrgVdc.FixedSize){

                Write-Host "Fixed Size (T-Shirt Size) '$($Configs.OrgVdc.FixedSize)' Org VDC Requested!"

                switch ($Configs.OrgVdc.FixedSize) {
                    M {
                        [String]$CPULimit = 36000
                        [String]$MEMLimit = 122880
                        [String]$StorageLimit = 1048576
                    }
                    L {
                        [String]$CPULimit = 36000
                        [String]$MEMLimit = 245760
                        [String]$StorageLimit = 1048576
                    }
                    default {throw "Invalid T-Shirt Size!"}
                    }

                }
                else{
                Write-Host "Custom Org VDC Size Requested!"

                $CPULimit = $Configs.OrgVdc.CPULimit
                $MEMLimit = $Configs.OrgVdc.MEMLimit
                $StorageLimit = $Configs.OrgVdc.StorageLimit

                }

            if ($Configs.OrgVdc.ExternalNetwork){
                $Trash = New-MyOrgVdc -Name $Configs.OrgVdc.Name -CPULimit $CPULimit -MEMLimit $MEMLimit -StorageLimit $StorageLimit -Networkpool $Configs.OrgVdc.NetworkPool -StorageProfile $Configs.OrgVdc.StorageProfile -ProviderVDC $Configs.OrgVdc.ProviderVDC -ExternalNetwork $Configs.OrgVdc.ExternalNetwork  -Org $Configs.Org.Name -Enabled:$Enabled
                }
                else {
                    $Trash = New-MyOrgVdc -Name $Configs.OrgVdc.Name -CPULimit $CPULimit -MEMLimit $MEMLimit -StorageLimit $StorageLimit -Networkpool $Configs.OrgVdc.NetworkPool -StorageProfile $Configs.OrgVdc.StorageProfile -ProviderVDC $Configs.OrgVdc.ProviderVDC -Org $Configs.Org.Name -Enabled:$Enabled
                }
            Write-Host  "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Creating new OrgVdc OK" -ForegroundColor Green
            Get-OrgVdc -Org $Configs.Org.Name -Name $Configs.OrgVdc.Name  | Select-Object Name, Enabled, CpuAllocationGhz, MemoryLimitGB, StorageLimitGB, AllocationModel, ThinProvisioned, UseFastProvisioning, `
            @{N="StorageProfile";E={$_.ExtensionData.VdcStorageProfiles.VdcStorageProfile.Name}}, `
            @{N='VCpuInMhz';E={$_.ExtensionData.VCpuInMhz}} | Format-Table -AutoSize
            }
            catch {
                $Valid = $false
                Write-Host  "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Creating new OrgVdc Failed" -ForegroundColor Red
            }
        }

    Write-Output "Overall Execution was Valid: $Valid"
    }
}
