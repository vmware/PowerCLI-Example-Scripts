<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
Function Get-CSPAccessToken {
    <#
        .NOTES
        ===========================================================================
        Created by:     William Lam
        Date:           07/23/2018
        Organization:   VMware
        Blog:           https://www.virtuallyghetto.com
        Twitter:        @lamw
        ===========================================================================

        .DESCRIPTION
            Converts a Refresh Token from the VMware Console Services Portal
            to CSP Access Token to access CSP API
        .PARAMETER RefreshToken
            The Refresh Token from the VMware Console Services Portal
        .EXAMPLE
            Get-CSPAccessToken -RefreshToken $RefreshToken
    #>
    Param (
        [Parameter(Mandatory=$true)][String]$RefreshToken
    )

    $results = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize" -Method POST -Headers @{accept='application/json'} -Body "refresh_token=$RefreshToken"
    if($results.StatusCode -ne 200) {
        Write-Host -ForegroundColor Red "Failed to retrieve Access Token, please ensure your VMC Refresh Token is valid and try again"
        break
    }
    $accessToken = ($results | ConvertFrom-Json).access_token
    Write-Host "CSP Auth Token has been successfully retrieved and saved to `$env:cspAuthToken"
    $env:cspAuthToken = $accessToken
}

Function Get-CSPServices {
    <#
        .NOTES
        ===========================================================================
        Created by:     William Lam
        Date:           07/23/2018
        Organization:   VMware
        Blog:           https://www.virtuallyghetto.com
        Twitter:        @lamw
        ===========================================================================

        .DESCRIPTION
            Returns the list of CSP Services avialable for given user
        .EXAMPLE
            Get-CSPServices
    #>
    If (-Not $env:cspAuthToken) { Write-error "CSP Auth Token not found, please run Get-CSPAccessToken" } Else {
        $results = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/slc/api/definitions?expand=1" -Method GET -ContentType "application/json" -UseBasicParsing -Headers @{"csp-auth-token"="$env:cspAuthToken"}
        ((($results.Content) | ConvertFrom-Json).results | where {$_.visible -eq $true}).displayName
    }
}

Function Get-CSPRefreshTokenExpiry {
    <#
        .NOTES
        ===========================================================================
        Created by:     William Lam
        Date:           01/10/2019
        Organization:   VMware
        Blog:           https://www.virtuallyghetto.com
        Twitter:        @lamw
        ===========================================================================

        .DESCRIPTION
            Retrieve the expiry for a given CSP Refresh Token
        .PARAMETER RefreshToken
            Retrieve the expiry for a given CSP Refresh Token
        .EXAMPLE
            Get-CSPRefreshTokenExpiry -RefreshToken $RefreshToken
    #>
    Param (
        [Parameter(Mandatory=$true)][String]$RefreshToken
    )

    $body = @{"tokenValue"="$RefreshToken"}
    $json = $body | ConvertTo-Json
    $results = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/details" -Method POST -ContentType "application/json" -UseBasicParsing -Body $json
    $tokenDetails = (($results.Content) | ConvertFrom-Json)

    $createDate = (Get-Date -Date "01/01/1970").AddMilliseconds($tokenDetails.createdAt).ToLocalTime()
    $usedDate = (Get-Date -Date "01/01/1970").AddMilliseconds($tokenDetails.lastUsedAt).ToLocalTime()
    $expiryDate = (Get-Date -Date "01/01/1970").AddMilliseconds($tokenDetails.expiresAt).ToLocalTime()

    $tmp = [pscustomobject] @{
        LastUsedDate = $usedDate;
        CreatedDate = $createDate;
        ExpiryDate = $expiryDate;
    }
    $tmp | Format-List
}
