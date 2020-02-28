Function Get-VCSAIdentitySource {
<#
    .DESCRIPTION Retrieves vCenter Server Appliance Identity Source Configuration
    .NOTES  Author:  William Lam
    .PARAMETER VCSAName
        Inventory name of the VCSA VM
    .PARAMETER VCSARootPassword
        Root password for VCSA VM
    .EXAMPLE
        Get-VCSAIdentitySource -VCSAName "MGMT-VCSA-01" -VCSARootPassword "VMware1!"
#>
    Param (
        [Parameter(Mandatory=$true)][String]$VCSAName,
        [Parameter(Mandatory=$true)][String]$VCSARootPassword
    )

    $vm = Get-Vm -Name $VCSAName

    if($vm) {
        $identitySources = Invoke-VMScript -ScriptText "/opt/vmware/bin/sso-config.sh -get_identity_sources 2> /dev/null | sed -ne '/^*/,$ p'" -vm $vm -GuestUser "root" -GuestPassword $VCSARootPassword

        Write-Host -ForegroundColor green "`nIdentity Sources: "
        $identitySources

    } else {
        Write-Host "`nUnable to find VCSA named $VCSAName"
    }
}