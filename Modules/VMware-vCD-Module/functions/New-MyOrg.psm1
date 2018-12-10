Function New-MyOrg {
<#
.SYNOPSIS
    Creates a new vCD Org with Default Parameters

.DESCRIPTION
    Creates a new vCD Org with Default Parameters.

    Default Parameters are:
    * Catalog Publishing
    * Catalog Subscription
    * VM Quota
    * Stored VM Quota
    * VM Lease Time
    * Stored VM Lease Time
    * Password Policy Settings

.NOTES
    File Name  : New-MyOrg.ps1
    Author     : Markus Kraus
    Version    : 1.1
    State      : Ready

.LINK
    https://mycloudrevolution.com/

.EXAMPLE
    New-MyOrg -Name "TestOrg" -FullName "Test Org" -Description "PowerCLI Test Org"

.PARAMETER Name
    Name of the New Org as String

.PARAMETER FullName
    Full Name of the New Org as String

.PARAMETER Description
    Description of the New Org as String

.PARAMETER Enabled
    Should the New Org be enabled after creation

    Default:$false

#>
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Name of the New Org as string")]
        [ValidateNotNullorEmpty()]
            [String] $Name,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Full Name of the New Org as string")]
        [ValidateNotNullorEmpty()]
            [String] $FullName,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, HelpMessage="Description of the New Org as string")]
        [ValidateNotNullorEmpty()]
            [String] $Description,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, HelpMessage="Should the New Org be enabled after creation")]
        [ValidateNotNullorEmpty()]
            [Switch]$Enabled
    )
    Process {
        $vcloud = $DefaultCIServers[0].ExtensionData

        ## Create Objects
        $AdminOrg = New-Object VMware.VimAutomation.Cloud.Views.AdminOrg
        $orgGeneralSettings = New-Object VMware.VimAutomation.Cloud.Views.OrgGeneralSettings
        $orgOrgLeaseSettings = New-Object VMware.VimAutomation.Cloud.Views.OrgLeaseSettings
        $orgOrgVAppTemplateLeaseSettings = New-Object VMware.VimAutomation.Cloud.Views.OrgVAppTemplateLeaseSettings
        $orgOrgPasswordPolicySettings = New-Object VMware.VimAutomation.Cloud.Views.OrgPasswordPolicySettings
        $orgSettings = New-Object VMware.VimAutomation.Cloud.Views.OrgSettings

        ## Admin Settings
        $adminOrg.Name = $name
        $adminOrg.FullName = $FullName
        $adminOrg.Description = $description
        $adminOrg.IsEnabled = $Enabled

        ## Org Setting
        ### General Org Settings
        $orgGeneralSettings.CanPublishCatalogs = $False
        $orgGeneralSettings.CanPublishExternally = $False
        $orgGeneralSettings.CanSubscribe = $True
        $orgGeneralSettings.DeployedVMQuota = 0
        $orgGeneralSettings.StoredVmQuota = 0
        $orgSettings.OrgGeneralSettings = $orgGeneralSettings
        ### vApp Org Setting
        $orgOrgLeaseSettings.DeleteOnStorageLeaseExpiration = $false
        $orgOrgLeaseSettings.DeploymentLeaseSeconds = 0
        $orgOrgLeaseSettings.StorageLeaseSeconds = 0
        $orgSettings.VAppLeaseSettings = $orgOrgLeaseSettings
        ### vApp Template Org Setting
        $orgOrgVAppTemplateLeaseSettings.DeleteOnStorageLeaseExpiration = $false
        $orgOrgVAppTemplateLeaseSettings.StorageLeaseSeconds = 0
        $orgSettings.VAppTemplateLeaseSettings = $orgOrgVAppTemplateLeaseSettings
        ### PasswordPolicySettings Org Setting
        $orgOrgPasswordPolicySettings.AccountLockoutEnabled = $True
        $orgOrgPasswordPolicySettings.InvalidLoginsBeforeLockout = 5
        $orgOrgPasswordPolicySettings.AccountLockoutIntervalMinutes = 30
        $orgSettings.OrgPasswordPolicySettings = $orgOrgPasswordPolicySettings

        $adminOrg.Settings = $orgSettings

        $CreateOrg = $vcloud.CreateOrg($adminOrg)

        Get-Org -Name $name | Format-Table -AutoSize
    }
}
