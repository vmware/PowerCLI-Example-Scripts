Function Connect-NSXTProxy {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/11/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Retrieves NSX-T Proxy URL + acquire CSP Access Token to then be used with NSXT-T Policy API
    .DESCRIPTION
        This cmdlet creates $global:nsxtProxyConnection object containing the NSX-T Proxy URL along with CSP Token
    .EXAMPLE
        Connect-NSXTProxy -RefreshToken $RefreshToken -OrgName $OrgName -SDDCName $SDDCName
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
        if($sddc.resource_config.nsxt) {
            $nsxtProxyURL = $sddc.resource_config.nsx_api_public_endpoint_url
        } else {
            Write-Host -ForegroundColor Red "This is not an NSX-T based SDDC"
            break
        }
    }

    $results = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize?refresh_token=$RefreshToken" -Method POST -ContentType "application/json" -UseBasicParsing -Headers @{"csp-auth-token"="$RefreshToken"}
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
    $global:nsxtProxyConnection = new-object PSObject -Property @{
        'Server' = $nsxtProxyURL
        'headers' = $headers
    }
    $global:nsxtProxyConnection
}

Function Get-NSXTSegment {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/11/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns all NSX-T Segments (Logical Networks)
    .DESCRIPTION
        This cmdlet retrieves all NSX-T Segments (Logical Networks)
    .EXAMPLE
        Get-NSXTSegment
    .EXAMPLE
        Get-NSXTSegment -Name "sddc-cgw-network-1"
#>
    Param (
        [Parameter(Mandatory=$False)]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection  found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $segmentsURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/networks/cgw/segments"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$segmentsURL`n"
        }

        if($PSVersionTable.PSEdition -eq "Core") {
            $requests = Invoke-WebRequest -Uri $segmentsURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
        } else {
            $requests = Invoke-WebRequest -Uri $segmentsURL -Method $method -Headers $global:nsxtProxyConnection.headers
        }

        if($requests.StatusCode -eq 200) {
            $segments = ($requests.Content | ConvertFrom-Json).results

            if ($PSBoundParameters.ContainsKey("Name")){
                $segments = $segments | where {$_.display_name -eq $Name}
            }

            $results = @()
            foreach ($segment in $segments) {

                $subnets = $segment.subnets
                $network = $subnets.network
                $gateway = $subnets.gateway_addresses
                $dhcpRange = $subnets.dhcp_ranges

                $tmp = [pscustomobject] @{
                    Name = $segment.display_name;
                    ID = $segment.Id;
                    Network = $network;
                    Gateway = $gateway;
                    DHCPRange = $dhcpRange;
                }
                $results+=$tmp
            }
            $results
        } else {
            Write-Error "Failed to retrieve NSX-T Segments"
        }
    }
}