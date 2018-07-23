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

    $results = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize?refresh_token=$RefreshToken" -Method POST -ContentType "application/json" -UseBasicParsing -Headers @{"csp-auth-token"="$RefreshToken"}
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