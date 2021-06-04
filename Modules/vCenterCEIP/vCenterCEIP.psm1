<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

Function Get-VCenterCEIP {
    <#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          01/23/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Retrieves the the Customer Experience Improvement Program (CEIP) setting for vCenter Server
    .DESCRIPTION
        This cmdlet retrieves the the CEIP setting for vCenter Server
    .EXAMPLE
        Get-VCenterCEIP
    #>
    If (-Not $global:DefaultVIServer.IsConnected) { Write-error "No valid VC Connection found, please use the Connect-VIServer to connect"; break } Else {
        $ceipSettings = (Get-AdvancedSetting -Entity $global:DefaultVIServer -Name VirtualCenter.DataCollector.ConsentData).Value.toString() | ConvertFrom-Json
        $ceipEnabled = $ceipSettings.consentConfigurations[0].consentAccepted

        $tmp = [pscustomobject] @{
            VCENTER = $global:DefaultVIServer.Name;
            CEIP = $ceipEnabled;
        }
        $tmp
    }
}
Function Set-VCenterCEIP {
    <#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          01/23/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Enables or Disables the Customer Experience Improvement Program (CEIP) setting for vCenter Server
    .DESCRIPTION
        This cmdlet enables or disables the CEIP setting for vCenter Server
    .EXAMPLE
        Set-VCenterCEIP  -Enabled
    .EXAMPLE
        Set-VCenterCEIP  -Disabled
    #>
    Param (
        [Switch]$Enabled,
        [Switch]$Disabled
    )
    If (-Not $global:DefaultVIServer.IsConnected) { Write-error "No valid VC Connection found, please use the Connect-VIServer to connect"; break } Else {
        $ceipSettings = (Get-AdvancedSetting -Entity $global:DefaultVIServer -Name VirtualCenter.DataCollector.ConsentData).Value.toString() | ConvertFrom-Json
        If($Enabled) {
            $originalVersion = $ceipSettings.version
            $ceipSettings.version = [int]$originalVersion + 1
            $ceipSettings.consentConfigurations[0].consentAccepted = $True
            $ceipSettings.consentConfigurations[1].consentAccepted = $True
            $updatedceipSettings = $ceipSettings | ConvertTo-Json
            Write-Host "Enabling Customer Experience Improvement Program (CEIP) ..."
            Get-AdvancedSetting -Entity $global:DefaultVIServer -Name VirtualCenter.DataCollector.ConsentData | Set-AdvancedSetting -Value $updatedceipSettings -Confirm:$false
        } else {
            $originalVersion = $ceipSettings.version
            $ceipSettings.version = [int]$originalVersion + 1
            $ceipSettings.consentConfigurations[0].consentAccepted = $False
            $ceipSettings.consentConfigurations[1].consentAccepted = $False
            $updatedceipSettings = $ceipSettings | ConvertTo-Json
            Write-Host "Disablng Customer Experience Improvement Program (CEIP) ..."
            Get-AdvancedSetting -Entity $global:DefaultVIServer -Name VirtualCenter.DataCollector.ConsentData | Set-AdvancedSetting -Value $updatedceipSettings -Confirm:$false
        }
    }
}
