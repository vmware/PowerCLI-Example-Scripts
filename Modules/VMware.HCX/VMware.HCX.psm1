Function Connect-HcxServer {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Connect to the HCX Enterprise Manager
    .DESCRIPTION
        This cmdlet connects to the HCX Enterprise Manager
    .EXAMPLE
        Connect-HcxServer -Server $HCXServer -Username $Username -Password $Password
#>
    Param (
        [Parameter(Mandatory=$true)][String]$Server,
        [Parameter(Mandatory=$true)][String]$Username,
        [Parameter(Mandatory=$true)][String]$Password
    )

    $payload = @{
        "username" = $Username
        "password" = $Password
    }
    $body = $payload | ConvertTo-Json

    $hcxLoginUrl = "https://$Server/hybridity/api/sessions"

    if($PSVersionTable.PSEdition -eq "Core") {
        $results = Invoke-WebRequest -Uri $hcxLoginUrl -Body $body -Method POST -UseBasicParsing -ContentType "application/json" -SkipCertificateCheck
    } else {
        $results = Invoke-WebRequest -Uri $hcxLoginUrl -Body $body -Method POST -UseBasicParsing -ContentType "application/json"
    }

    if($results.StatusCode -eq 200) {
        $hcxAuthToken = $results.Headers.'x-hm-authorization'

        $headers = @{
            "x-hm-authorization"="$hcxAuthToken"
            "Content-Type"="application/json"
            "Accept"="application/json"
        }

        $global:hcxConnection = new-object PSObject -Property @{
            'Server' = "https://$server/hybridity/api";
            'headers' = $headers
        }
        $global:hcxConnection
    } else {
        Write-Error "Failed to connect to HCX Manager, please verify your vSphere SSO credentials"
    }
}

Function Get-HcxCloudConfig {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns the Cloud HCX information that is registerd with HCX Manager
    .DESCRIPTION
        This cmdlet returns the Cloud HCX information that is registerd with HCX Manager
    .EXAMPLE
        Get-HcxCloudConfig
#>
    If (-Not $global:hcxConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxServer " } Else {
        $cloudConfigUrl = $global:hcxConnection.Server + "/cloudConfigs"

        if($PSVersionTable.PSEdition -eq "Core") {
            $cloudvcRequests = Invoke-WebRequest -Uri $cloudConfigUrl -Method GET -Headers $global:hcxConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $cloudvcRequests = Invoke-WebRequest -Uri $cloudConfigUrl -Method GET -Headers $global:hcxConnection.headers -UseBasicParsing
        }

        $cloudvcData = ($cloudvcRequests.content | ConvertFrom-Json).data.items

        $tmp = [pscustomobject] @{
            Name = $cloudvcData.cloudName;
            Version = $cloudvcData.version;
            Build = $cloudvcData.buildNumber;
            HCXUUID = $cloudvcData.endpointId;
        }
        $tmp
    }
}

Function Connect-HcxVAMI {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Connect to the HCX Enterprise Manager VAMI
    .DESCRIPTION
        This cmdlet connects to the HCX Enterprise Manager VAMI
    .EXAMPLE
        Connect-HcxVAMI -Server $HCXServer -Username $VAMIUsername -Password $VAMIPassword
#>
    Param (
        [Parameter(Mandatory=$true)][String]$Server,
        [Parameter(Mandatory=$true)][String]$Username,
        [Parameter(Mandatory=$true)][String]$Password
    )

    $pair = "${Username}:${Password}"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"

    $headers = @{
        "authorization"="$basicAuthValue"
        "Content-Type"="application/json"
        "Accept"="application/json"
    }

    $global:hcxVAMIConnection = new-object PSObject -Property @{
        'Server' = "https://${server}:9443";
        'headers' = $headers
    }
    $global:hcxVAMIConnection
}

Function Get-HcxVAMIVCConfig {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns the onPrem vCenter Server registered with HCX Manager
    .DESCRIPTION
        This cmdlet returns the onPrem vCenter Server registered with HCX Manager
    .EXAMPLE
        Get-HcxVAMIVCConfig
#>
    If (-Not $global:hcxVAMIConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $vcConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/vcenter"

        if($PSVersionTable.PSEdition -eq "Core") {
            $vcRequests = Invoke-WebRequest -Uri $vcConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $vcRequests = Invoke-WebRequest -Uri $vcConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
        }
        $vcData = ($vcRequests.content | ConvertFrom-Json).data.items

        $tmp = [pscustomobject] @{
            Name = $vcData.config.name;
            Version = $vcData.config.version;
            Build = $vcData.config.buildNumber;
            UUID = $vcData.config.vcuuid;
            HCXUUID = $vcData.config.uuid;
        }
        $tmp
    }
}