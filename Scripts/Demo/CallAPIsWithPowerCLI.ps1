<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

# This is a Demo Script for different ways to call different vSphere APIs with PowerCLI 12.4
# It is an interactive script that is supposed to be executed step by step in an Interactive PowerShell
# session with PowerCLI 12.4 installed

#region 1. Connect to a vCenter Server with PowerCLI
# Specify VC Server Here
$VCServerAddress = ''


Connect-VIServer -Server $VCServerAddress
#endregion

#region 2. Open vSphere APIs web documentation pages
# The entry point to all APIs documentation
Start-Process https://developer.vmware.com

# Access SOAP API
Start-Process https://code.vmware.com/apis/968
#endregion

#region 3. vSphere SOAP APIs through PowerCLI

# Managed Objects - objects with operations
# DataObject - structures of data
# Get-View - retrieves Managed Object Instance

## Retrive Managed Object Instance by Managed Object Name with Get-View
Get-View ServiceInstance
Get-View AlarmManager

## Discover API Operations
$alarmManagerMO = Get-View AlarmManager
$alarmManagerMO | Get-Member -MemberType Method

# Get Data Object
## Get the VCenter SOAP API Service Instance
$serviceInstance = Get-View ServiceInstance

## Get vCenter Server About Info through the SOAP API
$serviceInstance.Content.About
#endregion

#region 4. vSphere Automation APIs (JSON RPC)
Start-Process https://developer.vmware.com/docs/vsphere-automation/latest/
# Access JRPC API
Start-Process https://code.vmware.com/docs/13551/vsphere-automation-java-api-reference-7-0u2

## JRPC vSphere Automation SDK is exposed through Get-CISService
## Needs a CIS Connection
Connect-CISServer -Server $VCServerAddress
# Exploer services and check the integrated help for reference-7-0u2
Get-CisService

# Find appliance health services
Get-CisService com.vmware.appliance.health*

# Get appliance health check settings services
$health_check_settings = Get-CisService com.vmware.appliance.health_check_settings

$health_check_settings | Get-Member -MemberType CodeMethod
$health_check_settings.get()

Disconnect-CisServer
#endregion

#region 5. vSphere Automation REST APIs through PowerCLI

# PowerCLI 12.4 Exposes vSphere Automation REST APIs
# Access REST API
Start-Process https://developer.vmware.com/docs/vsphere-automation/latest/
Invoke-GetHealthSettings

$HealthCheckSettingsUpdateSpec = Initialize-HealthCheckSettingsUpdateSpec -DbHealthCheckStateManualBackup $false -DbHealthCheckStateScheduledBackup $true
Invoke-UpdateHealthSettings -HealthCheckSettingsUpdateSpec $HealthCheckSettingsUpdateSpec

# Using pipeline of initialize and invoke
Initialize-HealthCheckSettingsUpdateSpec -DbHealthCheckStateManualBackup $true -DbHealthCheckStateScheduledBackup $true | Invoke-UpdateHealthSettings; Invoke-GetHealthSettings

# Initialize/Invoke concept

# Online Help
Get-Help Invoke-UpdateHealthSettings -Online

# vSphere SDK Modules
Get-Module VMware.Sdk.vSphere* -ListAvailable

# Explore Availalable modules for vSphere Automation SDK API
Get-Module VMware.Sdk.vSphere* -ListAvailable | Select Name

# Explore Invoke commands available for the Appliance APIs
Get-Command -Module VMware.Sdk.vSphere.Appliance -Name Invoke*

# Create Appliance Local Account

$LocalAccountsConfig = Initialize-LocalAccountsConfig -Password 'Tes$TPa$$w0Rd' -Roles 'superAdmin'
$LocalAccountsCreateRequestBody = Initialize-LocalAccountsCreateRequestBody -Username 'dmilov' -Config $LocalAccountsConfig
Invoke-CreateLocalAccounts -LocalAccountsCreateRequestBody $LocalAccountsCreateRequestBody

# Get Appliance Local Account
Invoke-GetUsernameLocalAccounts -UserName 'dmilov'

# Update Appliance Local Account
$LocalAccountsUpdateConfig = Initialize-LocalAccountsUpdateConfig -FullName "Dimitar Milov" -Email "dmilov@vmware.com"
Invoke-UpdateUsernameLocalAccounts -Username 'dmilov' -LocalAccountsUpdateConfig $LocalAccountsUpdateConfig

# Delete Appliance Local Account
Invoke-DeleteUsernameLocalAccounts -Username 'dmilov'
#endregion

#region 6. Bindings vs Invoke-RestMethod
## Create Session
$UserName = 'administrator@vsphere.local'
$Password = Read-Host "Passowrd:" -MaskInput
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($UserName):$($Password)"))
$sessionKey = Invoke-RestMethod `
    -Method Post `
    -Uri https://$VCServerAddress/api/session `
    -Headers @{"Authorization"= "Basic $encodedCreds"} `
    -ContentType 'application/json' `
    -SkipCertificateCheck

## Prepare input for Local Account Creation

$requestBody = @{
   "config"= @{
        "password"= '$$$$TtRr0000NgGgg'
        "roles"=@("admin")
    }
    "username"= "dimitar"
}

## Invoke POST api/appliance/local-accounts to Create a local account
Invoke-RestMethod `
    -Method POST `
    -Uri https://$VCServerAddress/api/appliance/local-accounts `
    -Headers @{"vmware-api-session-id" = $sessionKey} `
    -ContentType 'application/json' `
    -SkipCertificateCheck `
    -Body ($requestBody | ConvertTo-Json)

## Invoke GET api/appliance/local-accounts to Get the new local account
Invoke-RestMethod `
    -Method GET `
    -Uri "https://$VCServerAddress/api/appliance/local-accounts/dimitar" `
    -Headers @{"vmware-api-session-id" = $sessionKey} `
    -ContentType 'application/json' `
    -SkipCertificateCheck

## Invoke Delete api/appliance/local-accounts to Delete the new local account
Invoke-RestMethod `
    -Method DELETE `
    -Uri "https://$VCServerAddress/api/appliance/local-accounts/dimitar" `
    -Headers @{"vmware-api-session-id" = $sessionKey} `
    -ContentType 'application/json' `
    -SkipCertificateCheck
#endregion

#region 7. Create Advanced functions with PowerCLI 12.4 REST APIs bindings
function New-ApplianceUserAccount {
    param(
        [Parameter(Mandatory)]
        [string]
        $UserName,

        [Parameter(Mandatory)]
        [string]
        $Password,

        [Parameter(Mandatory)]
        [ValidateSet('admin', 'superAdmin')]
        [string]
        $Roles
    )

    # Create
    $LocalAccountsConfig = Initialize-LocalAccountsConfig -Password $Password -Roles $Roles
    $LocalAccountsCreateRequestBody = Initialize-LocalAccountsCreateRequestBody -Username $UserName -Config $LocalAccountsConfig
    Invoke-CreateLocalAccounts -LocalAccountsCreateRequestBody $LocalAccountsCreateRequestBody

    # Get
    Get-ApplianceUserAccount -UserName $UserName
}

function Get-ApplianceUserAccount {
    param(
        [Parameter(Mandatory)]
        [string]
        $UserName)

    # Get
    $accountApiResult = Invoke-GetUsernameLocalAccounts -UserName $UserName

    # Output
    [PSCustomObject]@{
        'PSTypeName' = 'ApplianceUserAccount'
        'UserName' = $UserName
        'Roles' = $accountApiResult.roles
        'FullName' = $accountApiResult.fullname
        'Email' = $accountApiResult.email
        'Enabled' = $accountApiResult.enabled
    }
}

function Set-ApplianceUserAccount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [PSCustomObject]
        [PSTypeName('ApplianceUserAccount')]
        $UserAccount,

        [Parameter()]
        [string]
        $Email,

        [Parameter()]
        [string]
        $FullName
    )

    # Update
    $LocalAccountsUpdateConfig = Initialize-LocalAccountsUpdateConfig -FullName $FullName -Email $Email
    Invoke-UpdateUsernameLocalAccounts -Username $UserAccount.UserName -LocalAccountsUpdateConfig $LocalAccountsUpdateConfig

    # Get
    Get-ApplianceUserAccount -UserName $UserAccount.UserName
}

function Remove-ApplianceUserAccount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [PSCustomObject]
        [PSTypeName('ApplianceUserAccount')]
        $UserAccount
    )

    # Check account is available on the server
    $accountOnTheServer = Get-ApplianceUserAccount -UserName $UserAccount.UserName

    # Delete
    if ($null -ne $accountOnTheServer) {
        Invoke-DeleteUsernameLocalAccounts -Username $UserAccount.UserName
    }
}


# User the new advanced functions
Get-Command *-ApplianceUserAccount

New-ApplianceUserAccount -UserName dmilov -Password 'Tes$TPa$$w0Rd' -Roles admin

Get-ApplianceUserAccount -UserName dmilov | Set-ApplianceUserAccount -Email dmilov@vmware.com -FullName 'Dimitar Milov'
Get-ApplianceUserAccount -UserName dmilov | Remove-ApplianceUserAccount
#endregion
