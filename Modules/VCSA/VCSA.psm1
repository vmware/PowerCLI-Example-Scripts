<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
Function Get-VCSAPasswordPolicy {
<#
    .DESCRIPTION Retrieves vCenter Server Appliance SSO and Local OS Password Policy Configuration
    .NOTES  Author:  William Lam
    .PARAMETER VCSAName
        Inventory name of the VCSA VM
    .PARAMETER VCSARootPassword
        Root password for VCSA VM
    .PARAMETER SSODomain
        SSO Domain of the VCSA VM
    .PARAMETER SSOPassword
        Administrator password for the SSO Domain of the VCSA VM
    .EXAMPLE
        Get-VCSAPasswordPolicy -VCSAName "MGMT-VCSA-01" -VCSARootPassword "VMware1!" -SSODomain "vsphere.local" -SSOPassword "VMware1!"
#>
    Param (
        [Parameter(Mandatory=$true)][String]$VCSAName,
        [Parameter(Mandatory=$true)][String]$VCSARootPassword,
        [Parameter(Mandatory=$true)][String]$SSODomain,
        [Parameter(Mandatory=$true)][String]$SSOPassword
    )

    $vm = Get-Vm -Name $VCSAName

    if($vm) {
        $a,$b = $SSODomain.split(".")

        $ssoPasswordPolicy = Invoke-VMScript -ScriptText "/opt/likewise/bin/ldapsearch -h localhost -w $SSOPassword -x -D `"cn=Administrator,cn=Users,dc=$a,dc=$b`" -b `"cn=password and lockout policy,dc=$a,dc=$b`" | grep vmwPassword" -vm $vm -GuestUser "root" -GuestPassword $VCSARootPassword
        $localOSPasswordPolicy = Invoke-VMScript -ScriptText "cat /etc/login.defs | grep -v '#' | grep PASS" -vm $vm -GuestUser "root" -GuestPassword $VCSARootPassword

        Write-Host -ForegroundColor green "`nSSO Password Policy: "
        $ssoPasswordPolicy

        Write-Host -ForegroundColor green "`nLocalOS Password Policy: "
        $localOSPasswordPolicy
    } else {
        Write-Host "`nUnable to find VCSA named $VCSAName"
    }
}

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