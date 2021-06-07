<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

Function Connect-WorkspaceOneAccess {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          02/04/2020
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Log into Workspace One Access (formally VMware Identity Manager)
    .DESCRIPTION
        This cmdlet creates $global:workspaceOneAccessConnection object containing valid refresh token to vIDM/Workspace One Access
    .EXAMPLE
        Connect-WorkspaceOneAccess -Tenant $Tenant -ClientId $ClientId -ClientSecret $ClientSecret
#>
    Param (
        [Parameter(Mandatory=$true)][String]$Tenant,
        [Parameter(Mandatory=$true)][String]$ClientId,
        [Parameter(Mandatory=$true)][String]$ClientSecret,
        [Switch]$Troubleshoot
    )

    $text = "${ClientId}:${ClientSecret}"
    $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))

    $headers = @{
        "Authorization"="Basic $base64";
        "Content-Type"="application/x-www-form-urlencoded";
    }

    $oauthUrl = "https://${Tenant}/SAAS/auth/oauthtoken?grant_type=client_credentials"
    $method = "POST"

    if($Troubleshoot) {
        Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$oauthUrl`n"
    }

    $results = Invoke-WebRequest -Uri $oauthUrl -Method $method -Headers $headers
    if($results.StatusCode -ne 200) {
        Write-Host -ForegroundColor Red "Failed to retrieve Access Token, please ensure your ClientId and Client Secret is valid"
        break
    }
    $accessToken = ($results.Content | ConvertFrom-Json).access_token

    $authHeader = @{
        "Authorization"="Bearer $accessToken";
    }

    $global:workspaceOneAccessConnection = new-object PSObject -Property @{
        'Server' = "https://$Tenant"
        'headers' = $authHeader
    }
    $global:workspaceOneAccessConnection
}

Function Get-WSDirectory {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          02/04/2020
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Retrieves all Directories within Workspace One Access
    .DESCRIPTION
        This cmdlet retrieves all Directories within Workspace One Access
    .EXAMPLE
        Get-WSDirectory
    .EXAMPLE
        Get-WSDirectory -Name <DIRECTORY>
#>
    Param (
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    $directoryHeaders = @{
        "Accept"="application/vnd.vmware.horizon.manager.connector.management.directory.list+json";
        "Content-Type"="application/vnd.vmware.horizon.manager.connector.management.directory.list+json";
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }

    $directoryUrl = $global:workspaceOneAccessConnection.Server + "/SAAS/jersey/manager/api/connectormanagement/directoryconfigs?includeJitDirectories=true"
    $method = "GET"

    if($Troubleshoot) {
        Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$directoryUrl`n"
    }

    try {
        if($PSVersionTable.PSEdition -eq "Core") {
            $results = Invoke-Webrequest -Uri $directoryUrl -Method $method -UseBasicParsing -Headers $directoryHeaders -SkipCertificateCheck
        } else {
            $results = Invoke-Webrequest -Uri $directoryUrl -Method $method -UseBasicParsing -Headers $directoryHeaders
        }
    } catch {
        if($_.Exception.Response.StatusCode -eq "Unauthorized") {
            Write-Host -ForegroundColor Red "`nThe Workspace One session is no longer valid, please re-run the Connect-WorkspaceOne cmdlet to retrieve a new token`n"
            break
        } else {
            Write-Error "Error in retrieving Directory"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }
    }

    if($results.StatusCode -eq 200) {
        $directories = ([System.Text.Encoding]::ASCII.GetString($results.Content) | ConvertFrom-Json).items

        if ($PSBoundParameters.ContainsKey("Name")){
            $directories = $directories | where {$_.name -eq $Name}
        }

        $directories
    }
}

Function Remove-WSDirectory {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          02/04/2020
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Deletes a specific Workspace One Access Directory
    .DESCRIPTION
        This cmdlet deletes a specific directory within Workspace One Access
    .EXAMPLE
        Remove-WSDirectory -Name <DIRECTORY>
#>
    Param (
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    $directory = Get-WSDirectory -Name $Name

    if($directory) {

        $directoryHeaders = @{
            "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
        }

        $directoryUrl = $global:workspaceOneAccessConnection.Server + "/SAAS/jersey/manager/api/connectormanagement/directoryconfigs/$($directory.directoryId)?asyncDelete=true"
        $method = "DELETE"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$directoryUrl`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $results = Invoke-Webrequest -Uri $directoryUrl -Method $method -UseBasicParsing -Headers $directoryHeaders -SkipCertificateCheck
            } else {
                $results = Invoke-Webrequest -Uri $directoryUrl -Method $method -UseBasicParsing -Headers $directoryHeaders
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe Workspace One session is no longer valid, please re-run the Connect-WorkspaceOne cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in deleting new Directory"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($results.StatusCode -eq 200) {
            Write-Host "`nSuccessfully deleted Directory $Name ..."
        }
    } else {
        Write-Host "`nUnable to find Directory $Name"
    }
}

Function New-WSJitDirectory {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          02/04/2020
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Creates a Just-in-Time (Jit) Directory in Workspace One Access
    .DESCRIPTION
        This cmdlet creates a Just-in-Time (Jit) Directory in Workspace One Access
    .EXAMPLE
        New-WSJitDirectory -Name <DIRECTORY>
#>
    Param (
        [Parameter(Mandatory=$false)][String]$Name,
        [Parameter(Mandatory=$false)][String]$Domain,
        [Switch]$Troubleshoot
    )

    $directoryHeaders = @{
        "Accept"="application/vnd.vmware.horizon.manager.connector.management.directory.jit+json";
        "Content-Type"="application/vnd.vmware.horizon.manager.connector.management.directory.jit+json"
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }

    $directoryUrl = $global:workspaceOneAccessConnection.Server + "/SAAS/jersey/manager/api/connectormanagement/directoryconfigs"
    $method = "POST"

    $json = @{
        name = $Name
        domains = @($Domain)
    }

    $body = $json | ConvertTo-Json

    if($Troubleshoot) {
        Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$directoryUrl`n"
        Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
    }

    try {
        if($PSVersionTable.PSEdition -eq "Core") {
            $results = Invoke-Webrequest -Uri $directoryUrl -Method $method -UseBasicParsing -Headers $directoryHeaders -Body $body -SkipCertificateCheck
        } else {
            $results = Invoke-Webrequest -Uri $directoryUrl -Method $method -UseBasicParsing -Headers $directoryHeaders -Body $body
        }
    } catch {
        if($_.Exception.Response.StatusCode -eq "Unauthorized") {
            Write-Host -ForegroundColor Red "`nThe Workspace One session is no longer valid, please re-run the Connect-WorkspaceOne cmdlet to retrieve a new token`n"
            break
        } else {
            Write-Error "Error in creating new Jit Directory"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }
    }

    if($results.StatusCode -eq 201) {
        Write-Host "`nSuccessfully created Jit Directory $Name ..."
        ([System.Text.Encoding]::ASCII.GetString($results.Content) | ConvertFrom-Json)
    }
}

Function Get-WSOrgNetwork {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          02/04/2020
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Retreives all Org Networks within Workspace One Access
    .DESCRIPTION
        This cmdlet retreives all Org Networks within Workspace One Access
    .EXAMPLE
        Get-WSOrgNetwork
    .EXAMPLE
        Get-WSOrgNetwork -Name <NETWORK>
#>
    Param (
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    $listOrgNetworkHeaders = @{
        "Accept"="application/vnd.vmware.horizon.manager.orgnetwork.list+json";
        "Content-Type"="application/vnd.vmware.horizon.manager.orgnetwork.list+json"
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }

    $orgNetworkUrl = $global:workspaceOneAccessConnection.Server + "/SAAS/jersey/manager/api/orgnetworks"
    $method = "GET"

    if($Troubleshoot) {
        Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$orgNetworkUrl`n"
    }

    try {
        if($PSVersionTable.PSEdition -eq "Core") {
            $results = Invoke-Webrequest -Uri $orgNetworkUrl -Method $method -UseBasicParsing -Headers $listOrgNetworkHeaders -SkipCertificateCheck
        } else {
            $results = Invoke-Webrequest -Uri $orgNetworkUrl -Method $method -UseBasicParsing -Headers $listOrgNetworkHeaders
        }
    } catch {
        if($_.Exception.Response.StatusCode -eq "Unauthorized") {
            Write-Host -ForegroundColor Red "`nThe Workspace One session is no longer valid, please re-run the Connect-WorkspaceOne cmdlet to retrieve a new token`n"
            break
        } else {
            Write-Error "Error in creating new Directory"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }
    }

    if($results.StatusCode -eq 200) {
        $networks = ([System.Text.Encoding]::ASCII.GetString($results.Content) | ConvertFrom-Json).items

        if ($PSBoundParameters.ContainsKey("Name")){
            $networks = $networks | where {$_.name -eq $Name}
        }

        $networks
    }
}

Function Get-WSIdentityProvider {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          02/04/2020
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Retreives all Identity Providers within Workspace One Access
    .DESCRIPTION
        This cmdlet retreives all Identity Providers within Workspace One Access
    .EXAMPLE
        Get-WSIdentityProvider
    .EXAMPLE
        Get-WSIdentityProvider -Name <PROVIDER>
#>
    Param (
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    $listOrgNetworkHeaders = @{
        "Accept"="application/vnd.vmware.horizon.manager.identityprovider.summary.list+json";
        "Content-Type"="application/vnd.vmware.horizon.manager.identityprovider.summary.list+json"
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }

    $providerUrl = $global:workspaceOneAccessConnection.Server + "/SAAS/jersey/manager/api/identityProviders?onlyEnabledAdapters=true"
    $method = "GET"

    if($Troubleshoot) {
        Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$providerUrl`n"
    }

    try {
        if($PSVersionTable.PSEdition -eq "Core") {
            $results = Invoke-Webrequest -Uri $providerUrl -Method $method -UseBasicParsing -Headers $listOrgNetworkHeaders -SkipCertificateCheck
        } else {
            $results = Invoke-Webrequest -Uri $providerUrl -Method $method -UseBasicParsing -Headers $listOrgNetworkHeaders
        }
    } catch {
        if($_.Exception.Response.StatusCode -eq "Unauthorized") {
            Write-Host -ForegroundColor Red "`nThe Workspace One session is no longer valid, please re-run the Connect-WorkspaceOne cmdlet to retrieve a new token`n"
            break
        } else {
            Write-Error "Error in retrieving Directory"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }
    }

    if($results.StatusCode -eq 200) {
        $providers = ([System.Text.Encoding]::ASCII.GetString($results.Content) | ConvertFrom-Json).items

        if ($PSBoundParameters.ContainsKey("Name")){
            $providers = $providers | where {$_.name -eq $Name}
        }

        $providers
    }
}

Function New-WS3rdPartyIdentityProvider {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          02/04/2020
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Creates a new 3rd Party Identity Providers within Workspace One Access
    .DESCRIPTION
        This cmdlet creates a new 3rd party Identity Provider within Workspace One Access
    .EXAMPLE
        New-WS3rdPartyIdentityProvider
    .EXAMPLE
        New-WS3rdPartyIdentityProvider -Name "AWS Directory Service" -DirectoryName "VMware" -NetworkName "ALL RANGES" -MetadataFile FederationMetadata.xml
#>
    Param (
        [Parameter(Mandatory=$true)][String]$Name,
        [Parameter(Mandatory=$true)][String]$DirectoryName,
        [Parameter(Mandatory=$true)][String]$NetworkName,
        [Parameter(Mandatory=$true)][String]$MetadataFile,
        [Switch]$Troubleshoot
    )

    $idpDirectory = Get-WSDirectory -Name $DirectoryName
    $network = Get-WSOrgNetwork -Name $NetworkName
    $metadataXML = Get-Content -Raw $MetadataFile

    $idpBody = [pscustomobject] @{
        "authMethods" = @(
            @{
                "authMethodId" = 1;
                "authScore" = 1;
                "defaultMethod" = $false;
                "authMethodOrder" = 0;
                "authMethodName" = "adfsPassword";
                "samlAuthnContext" = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport";
            }
        );
        "identityProviderType" = "MANUAL";
        "nameIdFormatType" = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress";
        "identityFromSamlAttribute" = $false;
        "friendlyName" = $Name;
        "metaData" = "$metadataXML";
        "preferredBinding" = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST";
        "jitEnabled" = "true";
        "saml2IdPSLOConfiguration" = @{
            "sendSLORequest" = $true;
        }
        "directoryConfigurations" = @(
            [pscustomobject] @{
                "type" = $idpDirectory.type;
                "name" = $idpDirectory.name;
                "directoryId" = $idpDirectory.directoryId;
                "userstoreId" = $idpDirectory.userstoreId;
                "countDomains" = $idpDirectory.countDomains;
                "deleteInProgress" = $false;
                "migratedToEnterpriseService" = $false;
                "syncConfigurationEnabled" = $false;
            }
        );
        "nameIdFormatAttributeMappings" = [pscustomobject] @{
            "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress" = "emails";
            "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent" = "id";
            "urn:oasis:names:tc:SAML:2.0:nameid-format:transient" = "userName";
        };
        "orgNetworks" = @(
            [pscustomobject] @{
                "name" = $network.name;
                "ipAddressRanges" = $network.ipAddressRanges;
                "uuid" = $network.uuid;
                "description" = $network.description;
                "defaultNetwork" = $network.defaultNetwork;
            }
        );
        "description" = "";
        "nIDPStatus" = 1;
        "idpUrl" = $null;
        "name" = $Name;
    }

    $idpHeaders = @{
        "Accept"="application/vnd.vmware.horizon.manager.external.identityprovider+json";
        "Content-Type"="application/vnd.vmware.horizon.manager.external.identityprovider+json";
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }

    $body = $idpBody | ConvertTo-Json -Depth 10

    $identityProviderUrl = $global:workspaceOneAccessConnection.Server + "/SAAS/jersey/manager/api/identityProviders"
    $method = "POST"

    if($Troubleshoot) {
        Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$directoryUrl`n"
        Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
    }

    try {
        if($PSVersionTable.PSEdition -eq "Core") {
            $results = Invoke-Webrequest -Uri $identityProviderUrl -Method $method -UseBasicParsing -Headers $idpHeaders -Body $body -SkipCertificateCheck
        } else {
            $results = Invoke-Webrequest -Uri $identityProviderUrl -Method $method -UseBasicParsing -Headers $idpHeaders -Body $body
        }
    } catch {
        if($_.Exception.Response.StatusCode -eq "Unauthorized") {
            Write-Host -ForegroundColor Red "`nThe Workspace One session is no longer valid, please re-run the Connect-WorkspaceOne cmdlet to retrieve a new token`n"
            break
        } else {
            Write-Error "Error in creating new Identity Provider"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }
    }

    if($results.StatusCode -eq 201) {
        Write-Host "`nSuccessfully created new Identity Provider $Name ..."
        ([System.Text.Encoding]::ASCII.GetString($results.Content) | ConvertFrom-Json) | Select Name, Id
    }
}

Function Remove-WS3rdPartyIdentityProvider {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          02/04/2020
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Deletes a specific 3rd Party Identity Provider within Workspace One Access
    .DESCRIPTION
        This cmdlet deletes a specific 3rd Party Identity Provider within Workspace One Access
    .EXAMPLE
        Remove-WS3rdPartyIdentityProvider -Name <IDP>
#>
    Param (
        [Parameter(Mandatory=$true)][String]$Name,
        [Switch]$Troubleshoot
    )

    $idp = Get-WSIdentityProvider -Name $Name

    if($idp) {
        $identityProviderHeaders = @{
            "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
        }

        $identityProviderURL = $global:workspaceOneAccessConnection.Server + "/SAAS/jersey/manager/api/identityProviders/$($idp.id)"
        $method = "DELETE"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$identityProviderURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $results = Invoke-Webrequest -Uri $identityProviderURL -Method $method -UseBasicParsing -Headers $identityProviderHeaders -SkipCertificateCheck
            } else {
                $results = Invoke-Webrequest -Uri $identityProviderURL -Method $method -UseBasicParsing -Headers $identityProviderHeaders
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe Workspace One session is no longer valid, please re-run the Connect-WorkspaceOne cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in deleting Identity Provider"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($results.StatusCode -eq 200) {
            Write-Host "`nSuccessfully deleted Identity Provider $Name ..."
        }
    } else {
        Write-Host "`nUnable to find Identity Provider $Name"
    }
}

Function Get-UEMConfig {
<#
    .NOTES
    ===========================================================================
    Created by:    Alan Renouf
    Date:          04/15/2020
    Organization:  VMware
    Blog:          http://virtu-al.net
    Twitter:       @alanrenouf
    ===========================================================================

    .SYNOPSIS
        Retrieves UEM Configuration from Workspace One Access
    .DESCRIPTION
        This cmdlet retrieves the UEM Configuration from Workspace One Access
    .EXAMPLE
        Get-UEMConfig
    .EXAMPLE
        Get-UEMConfig
#>
    Param (
        [Switch]$Troubleshoot
    )

    $directoryHeaders = @{
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }

    $directoryUrl = $global:workspaceOneAccessConnection.Server + "/SAAS/jersey/manager/api/tenants/tenant/airwatchoptin/config"
    $method = "GET"

    if($Troubleshoot) {
        Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$directoryUrl`n"
    }

    try {
        if($PSVersionTable.PSEdition -eq "Core") {
            $results = Invoke-Webrequest -Uri $directoryUrl -Method $method -UseBasicParsing -Headers $directoryHeaders -SkipCertificateCheck
        } else {
            $results = Invoke-Webrequest -Uri $directoryUrl -Method $method -UseBasicParsing -Headers $directoryHeaders
        }
    } catch {
        if($_.Exception.Response.StatusCode -eq "Unauthorized") {
            Write-Host -ForegroundColor Red "`nThe Workspace One session is no longer valid, please re-run the Connect-WorkspaceOne cmdlet to retrieve a new token`n"
            break
        } else {
            Write-Error "Error in retrieving UEM Configuration"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }
    }

    if($results.StatusCode -eq 200) {
        $config = ([System.Text.Encoding]::ASCII.GetString($results.Content) | ConvertFrom-Json)
        $config
    }
}

Function Remove-UEMConfig {
<#
    .NOTES
    ===========================================================================
    Created by:    Alan Renouf
    Date:          04/15/2020
    Organization:  VMware
    Blog:          http://virtu-al.net
    Twitter:       @alanrenouf
    ===========================================================================

    .SYNOPSIS
        Removes the UEM Configuration from Workspace One Access
    .DESCRIPTION
        This cmdlet removes the UEM Configuration from Workspace One Access, there can only be one configuration.
    .EXAMPLE
        Remove-UEMConfig
    .EXAMPLE
        Remove-UEMConfig
#>
    Param (
        [Switch]$Troubleshoot
    )

    $directoryHeaders = @{
        "Authorization"=$global:workspaceOneAccessConnection.headers.Authorization;
    }

    $directoryUrl = $global:workspaceOneAccessConnection.Server + "/SAAS/jersey/manager/api/tenants/tenant/airwatchoptin/config"
    $method = "DELETE"

    if($Troubleshoot) {
        Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$directoryUrl`n"
    }

    try {
        if($PSVersionTable.PSEdition -eq "Core") {
            $results = Invoke-Webrequest -Uri $directoryUrl -Method $method -UseBasicParsing -Headers $directoryHeaders -SkipCertificateCheck
        } else {
            $results = Invoke-Webrequest -Uri $directoryUrl -Method $method -UseBasicParsing -Headers $directoryHeaders
        }
    } catch {
        if($_.Exception.Response.StatusCode -eq "Unauthorized") {
            Write-Host -ForegroundColor Red "`nThe Workspace One session is no longer valid, please re-run the Connect-WorkspaceOne cmdlet to retrieve a new token`n"
            break
        } else {
            Write-Error "Error in deleting UEM Configuration"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }
    }

    if($results.StatusCode -eq 200) {
        Write-Host "`nSuccessfully deleted UEM Configuration"
    }
}