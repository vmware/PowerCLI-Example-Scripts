Function New-MyOrgAdmin {
<#
.SYNOPSIS
    Creates a new vCD Org Admin with Default Parameters

.DESCRIPTION
    Creates a new vCD Org Admin with Default Parameters

    Default Parameters are:
    * User Role

.NOTES
    File Name  : New-MyOrgAdmin.ps1
    Author     : Markus Kraus
    Version    : 1.1
    State      : Ready

.LINK
    https://mycloudrevolution.com/

.EXAMPLE
    New-MyOrgAdmin -Name "OrgAdmin" -Pasword "Anfang!!" -FullName "Org Admin" -EmailAddress "OrgAdmin@TestOrg.local" -Org "TestOrg"

.PARAMETER Name
    Name of the New Org Admin as String

.PARAMETER FullName
    Full Name of the New Org Admin as String

.PARAMETER Password
    Password of the New Org Admin as String

.PARAMETER EmailAddress
    EmailAddress of the New Org Admin as String

.PARAMETER Enabled
    Should the New Org be enabled after creation

    Default:$false

.PARAMETER Org
    Org where the new Org Admin should be created as string

#>
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Name of the New Org Admin as String")]
        [ValidateNotNullorEmpty()]
            [String] $Name,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Password of the New Org Admin as String")]
        [ValidateNotNullorEmpty()]
            [String] $Pasword,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Full Name of the New Org Admin as String")]
        [ValidateNotNullorEmpty()]
            [String] $FullName,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="EmailAddress of the New Org Admin as String")]
        [ValidateNotNullorEmpty()]
            [String] $EmailAddress,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Org where the new Org Admin should be created as string")]
        [ValidateNotNullorEmpty()]
            [String] $Org,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, HelpMessage="Should the New Org be enabled after creation")]
        [ValidateNotNullorEmpty()]
            [Switch]$Enabled
    )
    Process {

        ## Create Objects
        $OrgED = (Get-Org $Org).ExtensionData
        $orgAdminUser = New-Object VMware.VimAutomation.Cloud.Views.User

        ## Settings
        $orgAdminUser.Name = $Name
        $orgAdminUser.FullName = $FullName
        $orgAdminUser.EmailAddress = $EmailAddress
        $orgAdminUser.Password = $Pasword
        $orgAdminUser.IsEnabled = $Enabled

        $vcloud = $DefaultCIServers[0].ExtensionData

        ## Find Role
        $orgAdminRole = $vcloud.RoleReferences.RoleReference | Where-Object {$_.Name -eq "Organization Administrator"}
        $orgAdminUser.Role = $orgAdminRole

        ## Create User
        $user = $orgED.CreateUser($orgAdminUser)

        Get-CIUser -Org $Org -Name $Name | Format-Table -AutoSize
    }
}
