<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
Function Connect-DRaas {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          05/23/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        This cmdlet creates $global:draasConnection object containing the DRaaS URL along with CSP Token Header
    .DESCRIPTION
        This cmdlet creates $global:draasConnection object containing the DRaaS URL along with CSP Token Header
    .EXAMPLE
        Connect-DRaaS -RefreshToken $RefreshToken -OrgName $OrgName -SDDCName $SDDCName
    .NOTES
        You must be logged into VMC using Connect-VmcServer cmdlet
#>
    Param (
        [Parameter(Mandatory=$true)][String]$RefreshToken,
        [Parameter(Mandatory=$true)][String]$OrgName,
        [Parameter(Mandatory=$true)][String]$SDDCName
    )

    If (-Not $global:DefaultVMCServers.IsConnected) { Write-error "No valid VMC Connection found, please use the Connect-VMC to connect"; break } Else {
        $sddcService = Get-VmcService "com.vmware.vmc.orgs.sddcs"
        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id
        $sddc = $sddcService.get($orgId,$sddcId)

    }

    $results = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize" -Method POST -Headers @{accept='application/json'} -Body "refresh_token=$RefreshToken"
    if($results.StatusCode -ne 200) {
        Write-Host -ForegroundColor Red "Failed to retrieve Access Token, please ensure your VMC Refresh Token is valid and try again"
        break
    }
    $accessToken = ($results | ConvertFrom-Json).access_token

    $headers = @{
        "csp-auth-token"="$accessToken"
        "Content-Type"="application/json"
        "Accept"="application/json"
    }
    $global:draasConnection = new-object PSObject -Property @{
        'Server' = "https://vmc.vmware.com/vmc/draas/api/orgs/$orgId/sddcs/$sddcId/site-recovery"
        'headers' = $headers
    }
    $global:draasConnection
}

Function Get-DRaas {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          05/23/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns information about DRaaS configuration for a given SDDC
    .DESCRIPTION
        This cmdlet returns information about DRaaS configuration for a given SDDC. Can be used to monitor both activate and deactivate operations.
    .EXAMPLE
        Get-DRaas
#>
    Param (
        [Switch]$Troubleshoot
    )

    If (-Not $global:draasConnection) { Write-error "No DRaaS Connection found, please use Connect-DRaaS" } Else {
        $method = "GET"
        $draasUrl = $global:draasConnection.Server
        $draasVersionUrl = $global:draasConnection.Server + "/versions"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$draasUrl`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $draasUrl -Method $method -Headers $global:draasConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $draasUrl -Method $method -Headers $global:draasConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe CSP session is no longer valid, please re-run the Connect-DRaaS cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving DRaaS Information"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $json = ($requests.Content | ConvertFrom-Json)

            $draasId = $json.id;
            $draasState = $json.site_recovery_state;
            $srmNode = $json.srm_node.ip_address;
            $srmNodeState = $json.site_recovery_state;
            $vrNode = $json.vr_node.ip_address;
            $vrNodeState = $json.vr_node.state;
            $draasUrl = $json.draas_h5_url;

            if($srmNodeState -eq "ACTIVATED") {
                if($Troubleshoot) {
                    Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$draasVersionUrl`n"
                }

                try {
                    if($PSVersionTable.PSEdition -eq "Core") {
                        $requests = Invoke-WebRequest -Uri $draasVersionUrl -Method $method -Headers $global:draasConnection.headers -SkipCertificateCheck
                    } else {
                        $requests = Invoke-WebRequest -Uri $draasVersionUrl -Method $method -Headers $global:draasConnection.headers
                    }
                } catch {
                    if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                        Write-Host -ForegroundColor Red "`nThe CSP session is no longer valid, please re-run the Connect-DRaaS cmdlet to retrieve a new token`n"
                        break
                    } else {
                        Write-Error "Error in retrieving DRaaS Information"
                        Write-Error "`n($_.Exception.Message)`n"
                        break
                    }
                }

                if($requests.StatusCode -eq 200) {
                    $json = ($requests.Content | ConvertFrom-Json).node_versions

                    $srmVersion,$srmDescription = ($json | where {$_.node_ip -eq $srmNode}).full_version.split("`n")
                    $vrVersion,$vrDescription = ($json | where {$_.node_ip -eq $vrNode}).full_version.split("`n")

                    $results = [pscustomobject] @{
                        ID = $draasId;
                        DRaaSState = $draasState;
                        SRMNode = $srmNode;
                        SRMVersion = $srmVersion;
                        SRMNodeState = $srmNodeState;
                        VRNode = $vrNode;
                        VRVersion = $vrVersion;
                        VRNodeState = $vrNodeState;
                        DRaaSURL = $draasUrl;
                    }

                    $results
                }
            } elseif ($srmNodeState -eq "ACTIVATING" -or $srmNodeState -eq "DEACTIVATING") {
                $results = [pscustomobject] @{
                    ID = $draasId;
                    DRaaSState = $draasState;
                    SRMNode = $srmNode;
                    SRMNodeState = $srmNodeState;
                    VRNode = $vrNode;
                    VRNodeState = $vrNodeState;
                    DRaaSURL = $draasUrl;
                }

                $results
            } else {
                Write-Host "`nDRaaS is currently deactivated, please run Set-DRaas -Activate`n"
            }
        } else {
            Write-Host "`nDRaaS has not been activated before, please run Set-DRaas -Activate`n"
        }
    }
}


Function Set-DRaas {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          05/23/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Activate or deactivate DRaaS for a given SDDC
    .DESCRIPTION
        This cmdlet activates or deactivates DRaaS for a given SDDC
    .EXAMPLE
        Get-DRaas
#>
    Param (
        [Switch]$Activate,
        [Switch]$Deactivate,
        [Switch]$Troubleshoot
    )

    If (-Not $global:draasConnection) { Write-error "No DRaaS Connection found, please use Connect-DRaaS" } Else {
        $draasUrl = $global:draasConnection.server

        if($Activate) {
            $method = "POST"

            if($Troubleshoot) {
                Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$draasUrl`n"
            }

            try {
                if($PSVersionTable.PSEdition -eq "Core") {
                    $requests = Invoke-WebRequest -Uri $draasUrl -Method $method -Headers $global:draasConnection.headers -SkipCertificateCheck
                } else {
                    $requests = Invoke-WebRequest -Uri $draasUrl -Method $method -Headers $global:draasConnection.headers
                }
            } catch {
                if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                    Write-Host -ForegroundColor Red "`nThe CSP session is no longer valid, please re-run the Connect-DRaaS cmdlet to retrieve a new token`n"
                    break
                } else {
                    Write-Error "Error in activating DRaaS"
                    Write-Error "`n($_.Exception.Message)`n"
                    break
                }
            }
            Write-Host "`nActivating DRaaS, this will take some time and you can monitor the progress using Get-DRaaS or using the VMC Console UI`n"
        } elseif ($Deactivate) {
            $method = "DELETE"

            if($Troubleshoot) {
                Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$draasUrl`n"
            }

            try {
                if($PSVersionTable.PSEdition -eq "Core") {
                    $requests = Invoke-WebRequest -Uri $draasUrl -Method $method -Headers $global:draasConnection.headers -SkipCertificateCheck
                } else {
                    $requests = Invoke-WebRequest -Uri $draasUrl -Method $method -Headers $global:draasConnection.headers
                }
            } catch {
                if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                    Write-Host -ForegroundColor Red "`nThe CSP session is no longer valid, please re-run the Connect-DRaaS cmdlet to retrieve a new token`n"
                    break
                } else {
                    Write-Error "Error in deactivating DRaaS"
                    Write-Error "`n($_.Exception.Message)`n"
                    break
                }
            }
            Write-Host "`nDeactivating DRaaS, this will take some time and you can monitor the progress using Get-DRaaS or the VMC Console UI`n"
        } else {
            Write-Error "Invalid Operation"
        }
    }
}