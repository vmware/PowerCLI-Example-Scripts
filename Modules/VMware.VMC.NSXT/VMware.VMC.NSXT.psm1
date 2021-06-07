<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
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

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $segmentsURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-1s/cgw/segments?page_size=100"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$segmentsURL`n"
        }

        try {
            Write-Host "Retrieving NSX-T Segments ..."
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $segmentsURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $segmentsURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Segments"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $baseSegmentsURL = $segmentsURL
            $totalSegmentCount = ($requests.Content | ConvertFrom-Json).result_count

            if($Troubleshoot) {
                Write-Host -ForegroundColor cyan "`n[DEBUG] totalSegmentCount = $totalSegmentCount"
            }
            $totalSegments = ($requests.Content | ConvertFrom-Json).results
            $seenSegments = $totalSegments.count

            if($Troubleshoot) {
                Write-Host -ForegroundColor cyan "`n[DEBUG] $segmentsURL (currentCount = $seenSegments)"
            }

            while ( $seenSegments -lt $totalSegmentCount) {
                $segmentsURL = $baseSegmentsURL + "&cursor=$(($requests.Content | ConvertFrom-Json).cursor)"

                try {
                    if($PSVersionTable.PSEdition -eq "Core") {
                        $requests = Invoke-WebRequest -Uri $segmentsURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
                    } else {
                        $requests = Invoke-WebRequest -Uri $segmentsURL -Method $method -Headers $global:nsxtProxyConnection.headers
                    }
                } catch {
                    if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                        Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                        break
                    } else {
                        Write-Error "Error in retrieving NSX-T Segments"
                        Write-Error "`n($_.Exception.Message)`n"
                        break
                    }
                }
                $segments = ($requests.Content | ConvertFrom-Json).results
                $totalSegments += $segments
                $seenSegments += $segments.count

                if($Troubleshoot) {
                    Write-Host -ForegroundColor cyan "`n[DEBUG] $segmentsURL (currentCount = $seenSegments)"
                }
            }

            if ($PSBoundParameters.ContainsKey("Name")){
                $totalSegments = $totalSegments | where {$_.display_name -eq $Name}
            }

            $results = @()
            foreach ($segment in $totalSegments) {

                $subnets = $segment.subnets
                $network = $subnets.network
                $gateway = $subnets.gateway_address
                $dhcpRange = $subnets.dhcp_ranges
                $type = $segment.type

                $tmp = [pscustomobject] @{
                    Name = $segment.display_name;
                    ID = $segment.Id;
                    TYPE = $type;
                    Network = $network;
                    Gateway = $gateway;
                    DHCPRange = $dhcpRange;
                }
                $results+=$tmp
            }
            $results
        }
    }
}

Function New-NSXTSegment {
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
        Creates a new NSX-T Segment (Logical Networks)
    .DESCRIPTION
        This cmdlet creates a new NSX-T Segment (Logical Networks)
    .EXAMPLE
        New-NSXTSegment -Name "sddc-cgw-network-4" -Gateway "192.168.4.1/24" -DHCP -DHCPRange "192.168.4.2-192.168.4.254"
    .EXAMPLE
        New-NSXTSegment -Name "sddc-cgw-network-4" -Gateway "192.168.4.1/24" -DHCP -DHCPRange "192.168.4.2-192.168.4.254" -DomainName 'vmc.local'
    .EXAMPLE
        New-NSXTSegment -Name "sddc-cgw-network-5" -Gateway "192.168.5.1/24"
    .EXAMPLE
        New-NSXTSegment -Name "sddc-cgw-network-5" -Gateway "192.168.5.1/24" -Disconnected
#>
    Param (
        [Parameter(Mandatory=$True)]$Name,
        [Parameter(Mandatory=$True)]$Gateway,
        [Parameter(Mandatory=$False)]$DHCPRange,
        [Parameter(Mandatory=$False)]$DomainName,
        [Switch]$DHCP,
        [Switch]$Disconnected,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        if($DHCP) {
            $subnets = @{
                gateway_address = $gateway;
                dhcp_ranges = @($DHCPRange)
            }
        } else {
            $subnets = @{
                gateway_address = $gateway;
            }
        }

        if($Disconnected) {
            $payload = @{
                display_name = $Name;
                subnets = @($subnets)
                advanced_config = @{
                    local_egress = "False"
                    connectivity = "OFF";
                }
                type = "DISCONNECTED";
            }
        } else {
            $payload = @{
                display_name = $Name;
                subnets = @($subnets)
            }
        }

        if($DomainName) {
            $payload.domain_name = $DomainName
        }

        $body = $payload | ConvertTo-Json -depth 4

        $method = "PUT"
        $newSegmentsURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-1s/cgw/segments/$Name"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$newSegmentsURL`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $newSegmentsURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $newSegmentsURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in creating new NSX-T Segment"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully created new NSX-T Segment $Name"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        }
    }
}

Function Set-NSXTSegment {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          03/04/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Set a NSX-T Segment (Logical Networks) to either connected or disconnected
    .DESCRIPTION
        This cmdlet set an NSX-T Segment (Logical Networks) to either connected or disconnected
    .EXAMPLE
        New-NSXTSegment -Name "sddc-cgw-network-4" -Disconnected
    .EXAMPLE
        New-NSXTSegment -Name "sddc-cgw-network-4" -Connected

#>
    Param (
        [Parameter(Mandatory=$True)]$Name,
        [Switch]$Disconnected,
        [Switch]$Connected,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $SegmentId = (Get-NSXTSegment -Name $Name).Id

        if($Disconnected) {
            $type = "DISCONNECTED"
            $connectivity = "OFF"
            $localEgress = "False"
            $gateway = (Get-NSXTSegment -Name $Name).Gateway
        }

        If($Connected) {
            $type = "ROUTED"
            $connectivity = "ON"
            $localEgress = "True"
            $gateway = (Get-NSXTSegment -Name $Name).Gateway
        }

        $subnets = @{
            gateway_address = $gateway;
        }

        $payload = @{
            advanced_config = @{
                local_egress = $localEgress;
                connectivity = $connectivity;
            }
            type = $type;
            subnets = @($subnets)
        }

        $body = $payload | ConvertTo-Json -depth 4

        $method = "PATCH"
        $aegmentsURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-1s/cgw/segments/$SegmentId"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$newSegmentsURL`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $aegmentsURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $aegmentsURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in updating NSX-T Segment connectivity"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully updated NSX-T Segment $Name"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        }
    }
}

Function Remove-NSXTSegment {
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
        Removes an NSX-T Segment (Logical Networks)
    .DESCRIPTION
        This cmdlet removes an NSX-T Segment (Logical Networks)
    .EXAMPLE
        Remove-NSXTSegment -Id "sddc-cgw-network-4"
#>
    Param (
        [Parameter(Mandatory=$True)]$Id,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection  found, please use Connect-NSXTProxy" } Else {
        $method = "DELETE"
        $deleteSegmentsURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-1s/cgw/segments/$Id"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$deleteSegmentsURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $deleteSegmentsURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $deleteSegmentsURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in removing NSX-T Segments"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully removed NSX-T Segment $Name"
        }
    }
}

Function Get-NSXTFirewall {
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
        Returns all NSX-T Firewall Rules on MGW or CGW
    .DESCRIPTION
        This cmdlet retrieves all NSX-T Firewall Rules on MGW or CGW
    .EXAMPLE
        Get-NSXTFirewall -GatewayType MGW
    .EXAMPLE
        Get-NSXTFirewall -GatewayType MGW -Name "Test"
#>
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection  found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $edgeFirewallURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/$($GatewayType.toLower())/gateway-policies/default"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$edgeFirewallURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $edgeFirewallURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $edgeFirewallURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Firewall Rules"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $rules = ($requests.Content | ConvertFrom-Json).rules

            if ($PSBoundParameters.ContainsKey("Name")){
                $rules = $rules | where {$_.display_name -eq $Name}
            }

            $results = @()
            foreach ($rule in $rules | Sort-Object -Property sequence_number) {
                $sourceGroups = $rule.source_groups
                $source = @()
                foreach ($sourceGroup in $sourceGroups) {
                    if($sourceGroup -eq "ANY") {
                        $source += $sourceGroup
                        break
                    } else {
                        $sourceGroupURL = $global:nsxtProxyConnection.Server + "/policy/api/v1" + $sourceGroup
                        if($Troubleshoot) {
                            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$sourceGroupURL`n"
                        }
                        try {
                            if($PSVersionTable.PSEdition -eq "Core") {
                                $requests = Invoke-WebRequest -Uri $sourceGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
                            } else {
                                $requests = Invoke-WebRequest -Uri $sourceGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers
                            }
                        } catch {
                            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                            break
                        }
                        $group = ($requests.Content | ConvertFrom-Json)
                        $source += $group.display_name
                    }
                }

                $destinationGroups = $rule.destination_groups
                $destination = @()
                foreach ($destinationGroup in $destinationGroups) {
                    if($destinationGroup -eq "ANY") {
                        $destination += $destinationGroup
                        break
                    } else {
                        $destionationGroupURL = $global:nsxtProxyConnection.Server + "/policy/api/v1" + $destinationGroup
                        if($Troubleshoot) {
                            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$destionationGroupURL`n"
                        }
                        try {
                            if($PSVersionTable.PSEdition -eq "Core") {
                                $requests = Invoke-WebRequest -Uri $destionationGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
                            } else {
                                $requests = Invoke-WebRequest -Uri $destionationGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers
                            }
                        } catch {
                            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                            break
                        }
                        $group = ($requests.Content | ConvertFrom-Json)
                        $destination += $group.display_name
                    }
                }

                $serviceGroups = $rule.services
                $service = @()
                foreach ($serviceGroup in $serviceGroups) {
                    if($serviceGroup -eq "ANY") {
                        $service += $serviceGroup
                        break
                    } else {
                        $serviceGroupURL = $global:nsxtProxyConnection.Server + "/policy/api/v1" + $serviceGroup
                        if($Troubleshoot) {
                            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$serviceGroupURL`n"
                        }
                        try {
                            if($PSVersionTable.PSEdition -eq "Core") {
                                $requests = Invoke-WebRequest -Uri $serviceGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
                            } else {
                                $requests = Invoke-WebRequest -Uri $serviceGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers
                            }
                        } catch {
                            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                            break
                        }
                        $group = ($requests.Content | ConvertFrom-Json)
                        $service += $group.display_name
                    }
                }

                $scopeEntries = $rule.scope
                $scopes = @()
                foreach ($scopeEntry in $scopeEntries) {
                    $scopeLabelURL = $global:nsxtProxyConnection.Server + "/policy/api/v1" + $scopeEntry
                    if($Troubleshoot) {
                        Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$scopeLabelURL`n"
                    }
                    try {
                        if($PSVersionTable.PSEdition -eq "Core") {
                            $requests = Invoke-WebRequest -Uri $scopeLabelURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
                        } else {
                            $requests = Invoke-WebRequest -Uri $scopeLabelURL -Method $method -Headers $global:nsxtProxyConnection.headers
                        }
                    } catch {
                        Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                        break
                    }
                    $scope = ($requests.Content | ConvertFrom-Json)
                    $scopes += $scope.display_name
                }

                $tmp = [pscustomobject] @{
                    SequenceNumber = $rule.sequence_number;
                    Name = $rule.display_name;
                    ID = $rule.id;
                    Source = $source;
                    Destination = $destination;
                    Services = $service;
                    Scope = $scopes;
                    Action = $rule.action;
                }
                $results+=$tmp
            }
            $results

        }
    }
}

Function New-NSXTFirewall {
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
        Creates a new NSX-T Firewall Rule on MGW or CGW
    .DESCRIPTION
        This cmdlet creates a new NSX-T Firewall Rule on MGW or CGW
    .EXAMPLE
        New-NSXTFirewall -GatewayType MGW -Name TEST -SourceGroup @("ANY") -DestinationGroup @("ESXI") -Service ANY -Logged $true -SequenceNumber 0 -Action ALLOW
#>
    Param (
        [Parameter(Mandatory=$True)]$Name,
        [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
        [Parameter(Mandatory=$True)]$SequenceNumber,
        [Parameter(Mandatory=$False)]$SourceGroup,
        [Parameter(Mandatory=$False)]$DestinationGroup,
        [Parameter(Mandatory=$True)]$Service,
        [Parameter(Mandatory=$True)][ValidateSet("ALLOW","DROP")]$Action,
        [Parameter(Mandatory=$false)]$InfraScope,
        [Parameter(Mandatory=$false)]$SourceInfraGroup,
        [Parameter(Mandatory=$false)]$DestinationInfraGroup,
        [Parameter(Mandatory=$false)][Boolean]$Logged=$false,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {

        $generatedId = (New-Guid).Guid

        $destinationGroups = @()
        foreach ($group in $DestinationGroup) {
            if($group -eq "ANY") {
                $destinationGroups = @("ANY")
            } else {
                $tmp = (Get-NSXTGroup -GatewayType $GatewayType -Name $group).Path
                $destinationGroups+= $tmp
            }
        }

        if($DestinationInfraGroup) {
            foreach ($group in $DestinationInfraGroup) {
                $tmp = (Get-NSXTInfraGroup -Name $group).Path
                $destinationGroups+= $tmp
            }
        }

        $sourceGroups = @()
        foreach ($group in $SourceGroup) {
            if($group -eq "ANY") {
                $sourceGroups = @("ANY")
            } else {
                $tmp = (Get-NSXTGroup -GatewayType $GatewayType -Name $group).Path
                $sourceGroups+= $tmp
            }
        }

        if($SourceInfraGroup) {
            foreach ($group in $SourceInfraGroup) {
                $tmp = (Get-NSXTInfraGroup -Name $group).Path
                $sourceGroups+= $tmp
            }
        }

        $services = @()
        foreach ($serviceName in $Service) {
            if($serviceName -eq "ANY") {
                $services = @("ANY")
            } else {
                $tmp = (Get-NSXTServiceDefinition -Name "$serviceName").Path
                $services+=$tmp
            }
        }

        $scopeLabels = @()
        if(!$InfraScope) {
            if($GatewayType.toLower() -eq "cgw") {
                $scopeLabels = @("/infra/labels/$($GatewayType.toLower())-all")
            } else {
                $scopeLabels = @("/infra/labels/$($GatewayType.toLower())")
            }
        } else {
            foreach ($infraScopeName in $InfraScope) {
                $scope = Get-NSXTInfraScope -Name $infraScopeName
                $scopeLabels += $scope.Path
            }
        }

        $payload = @{
            display_name = $Name;
            resource_type = "CommunicationEntry";
            sequence_number = $SequenceNumber;
            destination_groups = $destinationGroups;
            source_groups = $sourceGroups;
            logged = $Logged;
            scope = $scopeLabels;
            services = $services;
            action = $Action;
        }

        $body = $payload | ConvertTo-Json -depth 5

        $method = "PUT"
        $newFirewallURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/$($GatewayType.toLower())/gateway-policies/default/rules/$generatedId"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$newFirewallURL`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $newFirewallURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $newFirewallURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in creating new NSX-T Firewall Rule"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully created new NSX-T Firewall Rule $Name"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        }
    }
}

Function Remove-NSXTFirewall {
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
        Removes an NSX-T Firewall Rule on MGW or CGW
    .DESCRIPTION
        This cmdlet removes an NSX-T Firewall Rule on MGW or CGW
    .EXAMPLE
        Remove-NSXTFirewall -Id TEST -GatewayType MGW -Troubleshoot
#>
    Param (
        [Parameter(Mandatory=$True)]$Id,
        [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection  found, please use Connect-NSXTProxy" } Else {
        $method = "DELETE"
        $deleteGgroupURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/$($GatewayType.toLower())/gateway-policies/default/rules/$Id"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$deleteGgroupURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $deleteGgroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $deleteGgroupURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in creating new NSX-T Firewall Rule"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully removed NSX-T Firewall Rule"
        }
    }
}

Function Get-NSXTGroup {
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
        Returns all NSX-T Groups for MGW or CGW
    .DESCRIPTION
        This cmdlet retrieves all NSX-T Groups for MGW or CGW
    .EXAMPLE
        Get-NSXTGroup -GatewayType MGW
    .EXAMPLE
        Get-NSXTGroup -GatewayType MGW -Name "Test"
#>
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection  found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $edgeFirewallGroupsURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/$($GatewayType.toLower())/groups"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$edgeFirewallGroupsURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $edgeFirewallGroupsURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $edgeFirewallGroupsURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Groups"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $groups = ($requests.Content | ConvertFrom-Json).results

            if ($PSBoundParameters.ContainsKey("Name")){
                $groups = $groups | where {$_.display_name -eq $Name}
            }

            $results = @()
            foreach ($group in $groups) {
                if($group.tags.tag -eq $null) {
                    $groupType = "USER_DEFINED"
                } else { $groupType = $group.tags.tag }

                $members = @()
                foreach ($member in $group.expression) {
                    if($member.ip_addresses) {
                        $members += $member.ip_addresses
                    } else {
                        if($member.resource_type -eq "Condition") {
                            $members += $member.value
                        }
                    }
                }

                $tmp = [pscustomobject] @{
                    Name = $group.display_name;
                    ID = $group.id;
                    Type = $groupType;
                    Members = $members;
                    Path = $group.path;
                }
                $results+=$tmp
            }
            $results
        }
    }
}

Function New-NSXTGroup {
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
        Creates a new NSX-T Group on MGW or CGW
    .DESCRIPTION
        This cmdlet creates a new NSX-T Firewall Rule on MGW or CGW
    .EXAMPLE
        New-NSXTGroup -GatewayType MGW -Name Foo -IPAddress @("172.31.0.0/24")
    .EXAMPLE
        New-NSXTGroup -GatewayType CGW -Name Foo -Tag Bar
    .EXAMPLE
        New-NSXTGroup -GatewayType CGW -Name Foo -VmName Bar -Operator CONTAINS
    .EXAMPLE
        New-NSXTGroup -GatewayType CGW -Name Foo -VmName Bar -Operator STARTSWITH
#>
    [CmdletBinding(DefaultParameterSetName = 'IPAddress')]
    Param (
        [Parameter(Mandatory=$True)]$Name,
        [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
        [Parameter(Mandatory=$true, ParameterSetName='IPAddress')][String[]]$IPAddress,
        [Parameter(Mandatory=$true, ParameterSetName='Tag')][String]$Tag,
        [Parameter(Mandatory=$true, ParameterSetName='VmName')][String]$VmName,
        [Parameter(Mandatory=$true, ParameterSetName='VmName')][ValidateSet('CONTAINS','STARTSWITH','EQUALS')][String]$Operator,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        if ($PSCmdlet.ParameterSetName -eq 'Tag') {
            $expression = @{
                resource_type = 'Condition'
                member_type   = 'VirtualMachine'
                value         = $Tag
                key           = 'Tag'
                operator      = 'EQUALS'
            }
        } elseif ($PSCmdlet.ParameterSetName -eq 'VmName') {
            $expression = @{
                resource_type = 'Condition'
                member_type   = 'VirtualMachine'
                value         = $VmName
                key           = 'Name'
                operator      = $Operator.ToUpper()
            }
        } else {
            $expression = @{
                resource_type = "IPAddressExpression";
                ip_addresses  = $IPAddress;
            }
        }

        $payload = @{
            display_name = $Name;
            expression = @($expression);
        }
        $body = $payload | ConvertTo-Json -depth 5

        $method = "PUT"
        $generatedId = (New-Guid).Guid
        $newGroupURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/$($GatewayType.toLower())/groups/$generatedId"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$newGroupURL`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $newGroupURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $newGroupURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in creating new NSX-T Group"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully created new NSX-T Group $Name"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        }
    }
}

Function Remove-NSXTGroup {
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
        Removes an NSX-T Group
    .DESCRIPTION
        This cmdlet removes an NSX-T Group
    .EXAMPLE
        Remove-NSXTGroup -Id Foo -GatewayType MGW -Troubleshoot
#>
    Param (
        [Parameter(Mandatory=$True)]$Id,
        [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection  found, please use Connect-NSXTProxy" } Else {
        $method = "DELETE"
        $deleteGgroupURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/$($GatewayType.toLower())/groups/$Id"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$deleteGgroupURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $deleteGgroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $deleteGgroupURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in creating new NSX-T Group"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully removed NSX-T Group $Name"
        }
    }
}

Function Get-NSXTServiceDefinition {
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
        Returns all NSX-T Services
    .DESCRIPTION
        This cmdlet retrieves all NSX-T Services
    .EXAMPLE
        Get-NSXTServiceDefinition
    .EXAMPLE
        Get-NSXTServiceDefinition -Name "WINS"
#>
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection  found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $serviceGroupsURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/services"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$serviceGroupsURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $serviceGroupsURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $serviceGroupsURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Services"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $services = ($requests.Content | ConvertFrom-Json).results

            if ($PSBoundParameters.ContainsKey("Name")){
                $services = $services | where {$_.display_name -eq $Name}
            }

            $results = @()
            foreach ($service in $services | Sort-Object -Propert display_name) {
                $serviceEntry = $service.service_entries
                $serviceProtocol = $serviceEntry.l4_protocol
                $serviceSourcePorts = $serviceEntry.source_ports
                $serviceDestinationPorts = $serviceEntry.destination_ports

                $tmp = [pscustomobject] @{
                    Name = $service.display_name;
                    Id = $service.id;
                    Protocol = $serviceProtocol;
                    Source = $serviceSourcePorts;
                    Destination = $serviceDestinationPorts;
                    Path = $service.path;
                }
                $results += $tmp
            }
            $results
        }
    }
}

Function Remove-NSXTServiceDefinition {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          04/10/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Removes an NSX-T Service
    .DESCRIPTION
        This cmdlet removes an NSX-T Service
    .EXAMPLE
        Remove-NSXTServiceDefinition -Id VMware-Blast -Troubleshoot
#>
    Param (
        [Parameter(Mandatory=$True)]$Id,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection  found, please use Connect-NSXTProxy" } Else {
        $method = "DELETE"
        $deleteServiceURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/services/$Id"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$deleteServiceURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $deleteServiceURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $deleteServiceURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in removing NSX-T Service"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully removed NSX-T Service $Id"
        }
    }
}

Function New-NSXTServiceDefinition {
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
        Creates a new NSX-T Service
    .DESCRIPTION
        This cmdlet creates a new NSX-T Service
    .EXAMPLE
        New-NSXTServiceDefinition -Name "MyHTTP2" -Protocol TCP -DestinationPorts @("8080","8081")
#>
    Param (
        [Parameter(Mandatory=$True)]$Name,
        [Parameter(Mandatory=$True)][String[]]$DestinationPorts,
        [Parameter(Mandatory=$True)][ValidateSet("TCP","UDP")][String]$Protocol,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection  found, please use Connect-NSXTProxy" } Else {
        $serviceEntry = @()
        $entry = @{
            display_name = $name + "-$destinationPort"
            resource_type = "L4PortSetServiceEntry";
            destination_ports = @($DestinationPorts);
            l4_protocol = $Protocol;
        }
        $serviceEntry+=$entry

        $payload = @{
            display_name = $Name;
            service_entries = $serviceEntry;
        }
        $body = $payload | ConvertTo-Json -depth 5

        $method = "PUT"
        $newServiceURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/services/$Name"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$newServiceURL`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $newServiceURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $newServiceURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in creating new NSX-T Service"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully created new NSX-T Service $Name"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        }
    }
}

Function New-NSXTDistFirewallSection {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          04/19/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Creates new NSX-T Distributed Firewall Section
    .DESCRIPTION
        This cmdlet to create new NSX-T Distributed Firewall Section
    .EXAMPLE
        Get-NSXTDistFirewallSection -Name "App Section 1" -Category Application
#>
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Parameter(Mandatory=$false)][ValidateSet("Emergency","Infrastructure","Environment","Application")][String]$Category,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $payload = @{
            display_name = $Name;
            category = $Category;
            resource_type = "CommunicationMap";
        }

        $body = $payload | ConvertTo-Json -depth 5

        $method = "PUT"
        $generatedId = (New-Guid).Guid
        $distFirewallSectionURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/cgw/communication-maps/$generatedId"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$distFirewallSectionURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $distFirewallSectionURL -Method $method -Body $body -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $distFirewallSectionURL -Method $method -Body $body -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in creating NSX-T Distributed Firewall Section"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully created new NSX-T Distributed Firewall Section $Section"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        }
    }
}

Function Get-NSXTDistFirewallSection {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          04/19/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns all NSX-T Distributed Firewall Sections
    .DESCRIPTION
        This cmdlet retrieves all NSX-T Distributed Firewall Sections
    .EXAMPLE
        Get-NSXTDistFirewallSection
#>
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $distFirewallSectionURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/cgw/communication-maps"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$distFirewallSectionURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $distFirewallSectionURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $distFirewallSectionURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Distributed Firewall Section"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $sections = ($requests.Content | ConvertFrom-Json).results

            if ($PSBoundParameters.ContainsKey("Name")){
                $sections = $sections | where {$_.display_name -eq $Name}
            }

            $sections | Sort-Object -Propert display_name | select display_name, id
        }
    }
}

Function Remove-NSXTDistFirewallSection {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          04/20/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Removes an NSX-T Distributed Firewall Section
    .DESCRIPTION
        This cmdlet removes an NSX-T Distributed Firewall Section
    .EXAMPLE
        Remove-NSXTDistFirewallSection -Id <ID> -Troubleshoot
#>
    Param (
        [Parameter(Mandatory=$True)]$Id,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection  found, please use Connect-NSXTProxy" } Else {
        $method = "DELETE"
        $deleteDistFirewallSectioneURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/cgw/communication-maps/$Id"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$deleteDistFirewallSectioneURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $deleteDistFirewallSectioneURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $deleteDistFirewallSectioneURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in removing NSX-T Distributed Firewall Section"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully removed NSX-T Distributed Firewall Section $Id"
        }
    }
}

Function Get-NSXTDistFirewall {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          01/01/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns all NSX-T Distributed Firewall Rules for a given Section
    .DESCRIPTION
        This cmdlet retrieves all NSX-T Distributed Firewall Rules for a given Section
    .EXAMPLE
        Get-NSXTDistFirewall -SectionName "App Section 1"
#>
    param(
        [Parameter(Mandatory=$true)][String]$SectionName,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        try {
            $distGroupId = (Get-NSXTDistFirewallSection -Name $SectionName).Id
        }
        catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Host -ForegroundColor Red "`nUnable to find NSX-T Distributed Firewall Section named $SectionName`n"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        $method = "GET"
        $distFirewallURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/cgw/communication-maps/$distGroupId"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$distFirewallURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $distFirewallURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $distFirewallURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Distributed Firewall Rules"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $rules = ($requests.Content | ConvertFrom-Json).communication_entries

            $results = @()
            foreach ($rule in $rules | Sort-Object -Property sequence_number) {
                $sourceGroups = $rule.source_groups
                $source = @()
                foreach ($sourceGroup in $sourceGroups) {
                    if($sourceGroup -eq "ANY") {
                        $source += $sourceGroup
                        break
                    } else {
                        $sourceGroupURL = $global:nsxtProxyConnection.Server + "/policy/api/v1" + $sourceGroup
                        if($Troubleshoot) {
                            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$sourceGroupURL`n"
                        }
                        try {
                            if($PSVersionTable.PSEdition -eq "Core") {
                                $requests = Invoke-WebRequest -Uri $sourceGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
                            } else {
                                $requests = Invoke-WebRequest -Uri $sourceGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers
                            }
                        } catch {
                            Write-Host -ForegroundColor Red "`nFailed to retrieve Source Group Rule mappings`n"
                            break
                        }
                        $group = ($requests.Content | ConvertFrom-Json)
                        $source += $group.display_name
                    }
                }

                $destinationGroups = $rule.destination_groups
                $destination = @()
                foreach ($destinationGroup in $destinationGroups) {
                    if($destinationGroup -eq "ANY") {
                        $destination += $destinationGroup
                        break
                    } else {
                        $destionationGroupURL = $global:nsxtProxyConnection.Server + "/policy/api/v1" + $destinationGroup
                        if($Troubleshoot) {
                            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$destionationGroupURL`n"
                        }
                        try {
                            if($PSVersionTable.PSEdition -eq "Core") {
                                $requests = Invoke-WebRequest -Uri $destionationGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
                            } else {
                                $requests = Invoke-WebRequest -Uri $destionationGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers
                            }
                        } catch {
                            Write-Host -ForegroundColor Red "`nFailed to retireve Destination Group Rule mappings`n"
                            break
                        }
                        $group = ($requests.Content | ConvertFrom-Json)
                        $destination += $group.display_name
                    }
                }

                $serviceGroups = $rule.services
                $service = @()
                foreach ($serviceGroup in $serviceGroups) {
                    if($serviceGroup -eq "ANY") {
                        $service += $serviceGroup
                        break
                    } else {
                        $serviceGroupURL = $global:nsxtProxyConnection.Server + "/policy/api/v1" + $serviceGroup
                        if($Troubleshoot) {
                            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$serviceGroupURL`n"
                        }
                        try {
                            if($PSVersionTable.PSEdition -eq "Core") {
                                $requests = Invoke-WebRequest -Uri $serviceGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
                            } else {
                                $requests = Invoke-WebRequest -Uri $serviceGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers
                            }
                        } catch {
                            Write-Host -ForegroundColor Red "`nFailed to retrieve Services Rule mappings`n"
                            break
                        }
                        $group = ($requests.Content | ConvertFrom-Json)
                        $service += $group.display_name
                    }
                }

                $tmp = [pscustomobject] @{
                    SequenceNumber = $rule.sequence_number;
                    Name = $rule.display_name;
                    ID = $rule.id;
                    Source = $source;
                    Destination = $destination;
                    Services = $service;
                    Action = $rule.action;
                }
                $results+=$tmp
            }
            $results
        }
    }
}

Function New-NSXTDistFirewall {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          01/03/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Creates a new NSX-T Distribuged Firewall Rule
    .DESCRIPTION
        This cmdlet creates a new NSX-T Distribuged Firewall Rule
    .EXAMPLE
        New-NSXTDistFirewall -Name "App1 to Web1" -Section "App Section 1" `
            -SourceGroup "App Server 1" `
            -DestinationGroup "Web Server 1" `
            -Service HTTPS -Logged $true `
            -SequenceNumber 10 `
            -Action ALLOW
#>
    Param (
        [Parameter(Mandatory=$True)]$Name,
        [Parameter(Mandatory=$True)]$Section,
        [Parameter(Mandatory=$True)]$SequenceNumber,
        [Parameter(Mandatory=$True)]$SourceGroup,
        [Parameter(Mandatory=$True)]$DestinationGroup,
        [Parameter(Mandatory=$True)]$Service,
        [Parameter(Mandatory=$True)][ValidateSet("ALLOW","DROP")]$Action,
        [Parameter(Mandatory=$false)][Boolean]$Logged=$false,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {

        $sectionId = (Get-NSXTDistFirewallSection -Name $Section)[0].Id

        $destinationGroups = @()
        foreach ($group in $DestinationGroup) {
            if($group -eq "ANY") {
                $destinationGroups = @("ANY")
            } else {
                $tmp = (Get-NSXTGroup -GatewayType CGW -Name $group).Path
                $destinationGroups+= $tmp
            }
        }

        $sourceGroups = @()
        foreach ($group in $SourceGroup) {
            if($group -eq "ANY") {
                $sourceGroups = @("ANY")
            } else {
                $tmp = (Get-NSXTGroup -GatewayType CGW -Name $group).Path
                $sourceGroups+= $tmp
            }
        }

        $services = @()
        foreach ($serviceName in $Service) {
            if($serviceName -eq "ANY") {
                $services = @("ANY")
            } else {
                $tmp = "/infra/services/$serviceName"
                $services+=$tmp
            }
        }

        $payload = @{
            display_name = $Name;
            sequence_number = $SequenceNumber;
            destination_groups = $destinationGroups;
            source_groups = $sourceGroups;
            logged = $Logged;
            scope = @("ANY");
            services = $services;
            action = $Action.ToUpper();
        }

        $body = $payload | ConvertTo-Json -depth 5

        $method = "PUT"
        $generatedId = (New-Guid).Guid
        $newDistFirewallURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/cgw/communication-maps/$($sectionId)/communication-entries/$generatedId"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$newDistFirewallURL`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $newDistFirewallURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $newDistFirewallURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in creating new NSX-T Distributed Firewall Rule"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully created new NSX-T Distributed Firewall Rule $Name"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        }
    }
}

Function Remove-NSXTDistFirewall {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          01/03/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Removes an NSX-T Distributed Firewall Rule
    .DESCRIPTION
        This cmdlet removes an NSX-T Distributed Firewall Rule
    .EXAMPLE
        Remove-NSXTFirewall -Id TEST -Troubleshoot
#>
    Param (
        [Parameter(Mandatory=$True)]$Id,
        [Parameter(Mandatory=$True)]$Section,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $sectionId = (Get-NSXTDistFirewallSection -Name $Section).Id
        $dfwId = (Get-NSXTDistFirewall -SectionName $Section | where { $_.id -eq $Id}).Id

        $method = "DELETE"
        $deleteDistFirewallURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/cgw/communication-maps/$sectionId/communication-entries/$dfwId"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$deleteDistFirewallURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $deleteDistFirewallURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $deleteDistFirewallURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in removing NSX-T Distributed Firewall Rule"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully removed NSX-T Distributed Firewall Rule"
        }
    }
}

Function Get-NSXTRouteTable {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          02/02/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Retrieves NSX-T Routing Table
    .DESCRIPTION
        This cmdlet retrieves NSX-T Routing Table. By default, it shows all routes but you can filter by BGP, CONNECTED or STATIC routes
    .EXAMPLE
        Get-NSXTRouteTable
    .EXAMPLE
        Get-NSXTRouteTable -RouteSource BGP
    .EXAMPLE
        Get-NSXTRouteTable -RouteSource CONNECTED
    .EXAMPLE
        Get-NSXTRouteTable -RouteSource STATIC
    .EXAMPLE
        Get-NSXTRouteTable -RouteSource BGP -Troubleshoot
#>
    Param (
        [Parameter(Mandatory=$False)][ValidateSet("BGP","CONNECTED","STATIC")]$RouteSource,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $routeTableURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-0s/vmc/routing-table?enforcement_point_path=/infra/deployment-zones/default/enforcement-points/vmc-enforcementpoint"

        if($RouteSource) {
            $routeTableURL = $routeTableURL + "&route_source=$RouteSource"
        }

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$routeTableURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $routeTableURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $routeTableURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Routing Table"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully retrieved NSX-T Routing Table`n"
            $routeTables = ($requests.Content | ConvertFrom-Json).results

            foreach ($routeTable in $routeTables) {
                Write-Host "EdgeNode: $($routeTable.edge_node)"
                Write-Host "Entries: $($routeTable.count)"

                $routeEntries = $routeTable.route_entries
                $routeEntryResults = @()
                foreach ($routeEntry in $routeEntries) {
                    $routeEntryResults += $routeEntry
                }
                $routeEntryResults | select network,next_hop,admin_distance,route_type | ft
            }
        }
    }
}

Function Get-NSXTOverviewInfo {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          02/02/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Retrieves NSX-T Overview including the VPN internet IP Address and SDDC Infra/Mgmt Subnets, etc.
    .DESCRIPTION
        This cmdlet retrieves NSX-T Overview details including the VPN internet IP Address and SDDC Infra/Mgmt Subnets, etc.
    .EXAMPLE
        Get-NSXTOverviewInfo
#>
Param (
    [Parameter(Mandatory=$False)][ValidateSet("BGP","CONNECTED","STATIC")]$RouteSource,
    [Switch]$Troubleshoot
)

If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
    $method = "GET"
    $overviewURL = $global:nsxtProxyConnection.Server + "/cloud-service/api/v1/infra/sddc-user-config"

    if($Troubleshoot) {
        Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$overviewURL`n"
    }

    try {
        if($PSVersionTable.PSEdition -eq "Core") {
            $requests = Invoke-WebRequest -Uri $overviewURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
        } else {
            $requests = Invoke-WebRequest -Uri $overviewURL -Method $method -Headers $global:nsxtProxyConnection.headers
        }
    } catch {
        if($_.Exception.Response.StatusCode -eq "Unauthorized") {
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
        } else {
            Write-Error "Error in retrieving NSX-T Overview Information"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }
    }

    if($requests.StatusCode -eq 200) {
        Write-Host "Successfully retrieved NSX-T Overview Information"
        ($requests.Content | ConvertFrom-Json)
    }
}
}

Function Get-NSXTInfraScope {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          03/14/2019
        Organization:  VMware
        Blog:          http://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Returns all NSX-T Infrastructure Scopes
        .DESCRIPTION
            This cmdlet retrieves all NSX-T Infrastructure Scopes
        .EXAMPLE
            Get-NSXTInfraScope
        .EXAMPLE
            Get-NSXTInfraGroup -Name "VPN Tunnel Interface"
    #>
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $infraLabelURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/labels"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$infraLabelURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $infraLabelURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $infraLabelURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Infrastructure Scopes"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $infraLables = ($requests.Content | ConvertFrom-Json).results

            if ($PSBoundParameters.ContainsKey("Name")){
                $infraLables = $infraLables | where {$_.display_name -eq $Name}
            }

            $results = @()
            foreach ($infraLabel in $infraLables) {
                $tmp = [pscustomobject] @{
                    Name = $infraLabel.display_name;
                    Id = $infraLabel.Id;
                    Path = $infraLabel.Path;
                }
                $results+=$tmp
            }
            $results
        }
    }
}

Function Get-NSXTInfraGroup {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          03/14/2019
        Organization:  VMware
        Blog:          http://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Returns all NSX-T Infrastructure Groups for CGW
        .DESCRIPTION
            This cmdlet retrieves all NSX-T Infrastructure Groups for CGW
        .EXAMPLE
            Get-NSXTInfraGroup
        .EXAMPLE
            Get-NSXTInfraGroup -Name "S3 Prefixes"
    #>
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $infraGroupsURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-0s/vmc/groups"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$infraGroupsURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $infraGroupsURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $infraGroupsURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Infrastructure Groups"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $groups = ($requests.Content | ConvertFrom-Json).results

            if ($PSBoundParameters.ContainsKey("Name")){
                $groups = $groups | where {$_.display_name -eq $Name}
            }

            $results = @()
            foreach ($group in $groups) {
                $tmp = [pscustomobject] @{
                    Name = $group.display_name;
                    ID = $group.id;
                    Path = $group.path;
                }
                $results+=$tmp
            }
            $results
        }
    }
}

Function New-NSXTRouteBasedVPN {
    <#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          04/13/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns all NSX-T Infrastructure Scopes
    .DESCRIPTION
        This cmdlet retrieves all NSX-T Infrastructure Scopes
    .EXAMPLE
        New-NSXTRouteBasedVPN -Name VPN3 `
            -PublicIP 18.184.241.223 `
            -RemotePublicIP 18.194.148.62 `
            -BGPLocalIP 169.254.51.2 `
            -BGPRemoteIP 169.254.51.1 `
            -BGPLocalASN 65056 `
            -BGPremoteASN 64512 `
            -BGPNeighborID 60 `
            -TunnelEncryption AES_256 `
            -TunnelDigestEncryption SHA2_256 `
            -IKEEncryption AES_256 `
            -IKEDigestEncryption SHA2_256 `
            -DHGroup GROUP14 `
            -IKEVersion IKE_V1 `
            -PresharedPassword VMware123. `
            -Troubleshoot
    #>
    param(
        [Parameter(Mandatory=$true)][String]$Name,
        [Parameter(Mandatory=$true)][String]$PublicIP,
        [Parameter(Mandatory=$true)][String]$RemotePublicIP,
        [Parameter(Mandatory=$true)][String]$BGPLocalIP,
        [Parameter(Mandatory=$true)][String]$BGPRemoteIP,
        [Parameter(Mandatory=$false)][int]$BGPLocalPrefix=30,
        [Parameter(Mandatory=$true)][ValidateRange(64512,65534)][int]$BGPLocalASN,
        [Parameter(Mandatory=$true)][ValidateRange(64512,65534)][int]$RemoteBGPASN,
        [Parameter(Mandatory=$true)][String]$BGPNeighborID,
        [Parameter(Mandatory=$true)][String][ValidateSet("AES_128","AES_256","AES_GCM_128","AES_GCM_192","AES_GCM_256")]$TunnelEncryption,
        [Parameter(Mandatory=$true)][String][ValidateSet("SHA1","SHA2_256")]$TunnelDigestEncryption,
        [Parameter(Mandatory=$true)][String][ValidateSet("AES_128","AES_256","AES_GCM_128","AES_GCM_192","AES_GCM_256")]$IKEEncryption,
        [Parameter(Mandatory=$true)][String][ValidateSet("SHA1","SHA2_256")]$IKEDigestEncryption,
        [Parameter(Mandatory=$true)][String][ValidateSet("GROUP2","GROUP5","GROUP14","GROUP15","GROUP16")]$DHGroup,
        [Parameter(Mandatory=$true)][String][ValidateSet("IKE_V1","IKE_V2","IKE_FLEX")]$IKEVersion,
        [Parameter(Mandatory=$true)][String]$PresharedPassword,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {

        ## Configure BGP ASN

        $payload = @{
            local_as_num = $BGPLocalASN;
        }
        $body = $payload | ConvertTo-Json -Depth 5

        $ASNmethod = "patch"
        $bgpAsnURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/bgp"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $ASNmethod`n$bgpAsnURL`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $bgpAsnURL -Body $body -Method $ASNmethod -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $bgpAsnURL -Body $body -Method $ASNmethod -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in updating BGP ASN"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            ## Configure BGP Neighbor

            $payload = @{
                resource_type = "BgpNeighborConfig";
                id = $BGPNeighborID;
                remote_as_num = $RemoteBGPASN;
                neighbor_address = $BGPRemoteIP;
            }
            $body = $payload | ConvertTo-Json -Depth 5

            $method = "put"
            $bgpNeighborURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/bgp/neighbors/$BGPNeighborID"

            if($Troubleshoot) {
                Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$bgpNeighborURL`n"
                Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
            }

            try {
                if($PSVersionTable.PSEdition -eq "Core") {
                    $requests = Invoke-WebRequest -Uri $bgpNeighborURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
                } else {
                    $requests = Invoke-WebRequest -Uri $bgpNeighborURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers
                }
            } catch {
                if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                    Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                    break
                } else {
                    Write-Error "Error in configuring BGP Neighbor"
                    Write-Error "`n($_.Exception.Message)`n"
                    break
                }
            }

            if($requests.StatusCode -eq 200) {
                ## Configure Route Based Policy VPN

                $TunnelSubnets = @{
                    ip_addresses = @("$BGPLocalIP");
                    prefix_length = $BGPLocalPrefix;
                }

                $payload = @{
                    display_name = $Name;
                    enabled = $true;
                    local_address = $PublicIP;
                    remote_private_address = $RemotePublicIP;
                    remote_public_address = $RemotePublicIP;
                    passphrases = @("$PresharedPassword");
                    tunnel_digest_algorithms = @("$TunnelDigestEncryption");
                    ike_digest_algorithms = @("$IKEDigestEncryption");
                    ike_encryption_algorithms = @("$IKEEncryption");
                    enable_perfect_forward_secrecy = $true;
                    dh_groups = @("$DHGroup");
                    ike_version = $IKEVersion;
                    l3vpn_session = @{
                        resource_type = "RouteBasedL3VpnSession";
                        tunnel_subnets = @($TunnelSubnets);
                        default_rule_logging = $false;
                        force_whitelisting = $false;
                        routing_config_path = "/infra/tier-0s/vmc/locale-services/default/bgp/neighbors/$BGPNeighborID";
                    };
                    tunnel_encryption_algorithms = @("$TunnelEncryption");
                }
                $body = $payload | ConvertTo-Json -Depth 5

                $routeBasedVPNURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/l3vpns/$Name"

                if($Troubleshoot) {
                    Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$bgpNeighborURL`n"
                    Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
                }

                try {
                    if($PSVersionTable.PSEdition -eq "Core") {
                        $requests = Invoke-WebRequest -Uri $routeBasedVPNURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
                    } else {
                        $requests = Invoke-WebRequest -Uri $routeBasedVPNURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers
                    }
                } catch {
                    if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                        Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                        break
                    } else {
                        Write-Error "Error in configuring Route Based VPN"
                        Write-Error "`n($_.Exception.Message)`n"
                        break
                    }
                }

                if($requests.StatusCode -eq 200) {
                    Write-Host "Successfully created Route Based VPN"
                    ($requests.Content | ConvertFrom-Json)
                }
            }
        }
    }
}

Function Get-NSXTRouteBasedVPN {
    <#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          04/13/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns all NSX-T Route Based VPN Tunnels
    .DESCRIPTION
        This cmdlet retrieves all NSX-T Route Based VPN Tunnels description
    .EXAMPLE
        Get-NSXTRouteBasedVPN
    .EXAMPLE
        Get-NSXTRouteBasedVPN -Name "VPN-T1"
    #>
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $routeBaseVPNURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/l3vpns"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$routeBaseVPNURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $routeBaseVPNURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $routeBaseVPNURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Route Based VPN Tunnels"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $groups = ($requests.Content | ConvertFrom-Json).results
            if ($PSBoundParameters.ContainsKey("Name")){
                $groups = $groups | where {$_.display_name -eq $Name}
            }

            $results = @()
            foreach ($group in $groups) {
                if($group.l3vpn_session.resource_type -eq "RouteBasedL3VpnSession") {
                    $tmp = [pscustomobject] @{
                        Name = $group.display_name;
                        ID = $group.id;
                        Path = $group.path;
                        Routing_Config_Path = $group.l3vpn_session.routing_config_path;
                        Local_IP = $group.local_address;
                        Remote_Public_IP = $group.remote_public_address;
                        Tunnel_IP_Address = $group.l3vpn_session.tunnel_subnets.ip_addresses
                        IKE_Version = $group.ike_version;
                        IKE_Encryption = $group.ike_encryption_algorithms;
                        IKE_Digest = $group.ike_digest_algorithms;
                        Tunnel_Encryption = $group.tunnel_encryption_algorithms;
                        Tunnel_Digest = $group.tunnel_digest_algorithms;
                        DH_Group = $group.dh_groups;
                        Created_by = $group._create_user;
                        Last_Modified_by = $group._last_modified_user;
                    }
                    $results+=$tmp
                }
            }
            $results
        }
    }
}

Function Remove-NSXTRouteBasedVPN {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          04/13/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Removes a route based VPN Tunnel and it's associated BGP neighbor
    .DESCRIPTION
        This cmdlet removes a route based VPN Tunnel and it's associated BGP neighbor
    .EXAMPLE
        Remove-NSXTRouteBasedVPN -Name VPN1 -Troubleshoot
#>
    Param (
        [Parameter(Mandatory=$True)]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $TunnelId = (Get-NSXTRouteBasedVPN -Name $Name).ID
        $path = (Get-NSXTRouteBasedVPN -Name $Name).RoutingConfigPath

        # Delete IPSEC tunnel
        $method = "DELETE"
        $deleteVPNtunnelURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/l3vpns/$TunnelId"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$deleteVPNtunnelURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $deleteVPNtunnelURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $deleteVPNtunnelURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in removing NSX-T IPSEC Tunnel: $Name"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully removed NSX-T IPSEC Tunnel: $Name"
        }

        # Delete BGP Neighbor
        $method = "DELETE"
        $deleteBGPnbURL = $global:nsxtProxyConnection.Server + "/policy/api/v1$path"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$deleteBGPnbURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $deleteBGPnbURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $deleteBGPnbURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in removing NSX-T BGP Neighbor"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully removed NSX-T BGP Neighbor"
        }
    }
}

Function New-NSXTPolicyBasedVPN {
<#
.NOTES
===========================================================================
Created by:    William Lam
Date:          05/09/2019
Organization:  VMware
Blog:          http://www.virtuallyghetto.com
Twitter:       @lamw
===========================================================================

.SYNOPSIS
    Creates a new NSX-T Policy Based VPN
.DESCRIPTION
    This cmdlet creates a new NSX-T Policy Based VPN
.EXAMPLE
    New-NSXTPolicyBasedVPN -Name Policy1 `
        -LocalIP 18.194.102.229 `
        -RemotePublicIP 3.122.124.16 `
        -RemotePrivateIP 169.254.90.1 `
        -SequenceNumber 0 `
        -SourceIPs @("192.168.4.0/24", "192.168.5.0/24") `
        -DestinationIPs @("172.204.10.0/24", "172.204.20.0/24") `
        -TunnelEncryption AES_256 `
        -TunnelDigestEncryption SHA2_256 `
        -IKEEncryption AES_256 `
        -IKEDigestEncryption SHA2_256 `
        -DHGroup GROUP14 `
        -IKEVersion IKE_V1 `
        -PresharedPassword VMware123. `
        -Troubleshoot
#>
    param(
        [Parameter(Mandatory=$true)][String]$Name,
        [Parameter(Mandatory=$true)][String]$LocalIP,
        [Parameter(Mandatory=$true)][String]$RemotePublicIP,
        [Parameter(Mandatory=$true)][String]$RemotePrivateIP,
        [Parameter(Mandatory=$True)]$SequenceNumber,
        [Parameter(Mandatory=$true)][String[]]$SourceIPs,
        [Parameter(Mandatory=$true)][String[]]$DestinationIPs,
        [Parameter(Mandatory=$true)][String][ValidateSet("AES_128","AES_256","AES_GCM_128","AES_GCM_192","AES_GCM_256")]$TunnelEncryption,
        [Parameter(Mandatory=$true)][String][ValidateSet("SHA1","SHA2_256")]$TunnelDigestEncryption,
        [Parameter(Mandatory=$true)][String][ValidateSet("AES_128","AES_256","AES_GCM_128","AES_GCM_192","AES_GCM_256")]$IKEEncryption,
        [Parameter(Mandatory=$true)][String][ValidateSet("SHA1","SHA2_256")]$IKEDigestEncryption,
        [Parameter(Mandatory=$true)][String][ValidateSet("GROUP2","GROUP5","GROUP14","GROUP15","GROUP16")]$DHGroup,
        [Parameter(Mandatory=$true)][String][ValidateSet("IKE_V1","IKE_V2","IKE_FLEX")]$IKEVersion,
        [Parameter(Mandatory=$true)][String]$PresharedPassword,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {

        $generatedId = (New-Guid).Guid

        $sources = @()
        foreach ($source in $SourceIPs) {
            $tmp = @{ subnet = $source}
            $sources+=$tmp
        }

        $destinations = @()
        foreach ($destination in $DestinationIPs) {
            $tmp = @{ subnet = $destination}
            $destinations+=$tmp
        }

        $payload = @{
            display_name = $Name;
            enabled = $true;
            local_address = $LocalIP;
            remote_private_address = $RemotePrivateIP;
            remote_public_address = $RemotePublicIP;
            passphrases = @("$PresharedPassword");
            tunnel_digest_algorithms = @("$TunnelDigestEncryption");
            tunnel_encryption_algorithms = @("$TunnelEncryption");
            ike_digest_algorithms = @("$IKEDigestEncryption");
            ike_encryption_algorithms = @("$IKEEncryption");
            enable_perfect_forward_secrecy = $true;
            dh_groups = @("$DHGroup");
            ike_version = $IKEVersion;

            l3vpn_session = @{
                resource_type = "PolicyBasedL3VpnSession";
                rules = @(
                    @{
                        id = $generatedId;
                        display_name = $generatedId;
                        sequence_number = $SequenceNumber;
                        sources = @($sources)
                        destinations = @($destinations)
                    }
                )
            }
        }
        $body = $payload | ConvertTo-Json -Depth 5

        $method = "put"
        $policyBasedVPNURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/l3vpns/$Name"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$policyBasedVPNURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $policyBasedVPNURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $policyBasedVPNURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in configuring Policy Based VPN"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully created Policy Based VPN"
            ($requests.Content | ConvertFrom-Json)
        }
    }
}

Function Get-NSXTPolicyBasedVPN {
<#
.NOTES
===========================================================================
Created by:    William Lam
Date:          05/09/2019
Organization:  VMware
Blog:          http://www.virtuallyghetto.com
Twitter:       @lamw
===========================================================================

.SYNOPSIS
    Returns all NSX-T Policy Based VPN Tunnels
.DESCRIPTION
    This cmdlet retrieves all NSX-T Policy Based VPN Tunnels description
.EXAMPLE
    Get-NSXTPolicyBasedVPN
.EXAMPLE
    Get-NSXTPolicyBasedVPN -Name "VPN-T1"
#>
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $policyBaseVPNURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/l3vpns"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$routeBaseVPNURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $policyBaseVPNURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $policyBaseVPNURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Policy Based VPN Tunnels"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $groups = ($requests.Content | ConvertFrom-Json).results
            if ($PSBoundParameters.ContainsKey("Name")){
                $groups = $groups | where {$_.display_name -eq $Name}
            }

            $results = @()
            foreach ($group in $groups) {
                if($group.l3vpn_session.resource_type -eq "PolicyBasedL3VpnSession") {
                    $tmp = [pscustomobject] @{
                        Name = $group.display_name;
                        ID = $group.id;
                        Path = $group.path;
                        Local_IP = $group.local_address;
                        Remote_Public_IP = $group.remote_public_address;
                        Tunnel_IP_Address = $group.remote_private_address;
                        IKE_Version = $group.ike_version;
                        IKE_Encryption = $group.ike_encryption_algorithms;
                        IKE_Digest = $group.ike_digest_algorithms;
                        Tunnel_Encryption = $group.tunnel_encryption_algorithms;
                        Tunnel_Digest = $group.tunnel_digest_algorithms;
                        DH_Group = $group.dh_groups;
                        IP_Sources = $group.l3vpn_session.rules.sources.subnet;
                        IP_Destinations = $group.l3vpn_session.rules.destinations.subnet
                        Created_by = $group._create_user;
                        Last_Modified_by = $group._last_modified_user;
                    }
                $results+=$tmp
                }
            }
            $results
        }
    }
}

Function Remove-NSXTPolicyBasedVPN {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          05/09/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Removes a policy based VPN Tunnel
    .DESCRIPTION
        This cmdlet removes a policy based VPN Tunnel
    .EXAMPLE
        Remove-NSXTPolicyBasedVPN -Name "Policy1" -Troubleshoot
#>
    Param (
        [Parameter(Mandatory=$True)]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $TunnelId = (Get-NSXTPolicyBasedVPN -Name $Name).ID

        # Delete IPSEC tunnel
        $method = "DELETE"
        $deleteVPNtunnelURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-0s/vmc/locale-services/default/l3vpns/$TunnelId"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$deleteVPNtunnelURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $deleteVPNtunnelURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $deleteVPNtunnelURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in removing NSX-T VPN Tunnel: $Name"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully removed NSX-T VPN Tunnel: $Name"
        }
    }
}

Function Get-NSXTDNS {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          06/08/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns DNS Zone configuration for MGW or CGW
    .DESCRIPTION
        This cmdlet retrieves DNS Zone configuration for MGW or CGW
    .EXAMPLE
        Get-NSXTDNS -GatewayType MGW
    .EXAMPLE
        Get-NSXTDNS -GatewayType CGW
#>
    param(
        [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $dnsURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/dns-forwarder-zones/$($GatewayType.toLower())-dns-zone"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$dnsURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $dnsURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $dnsURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T DNS Zones"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $dnsZone = ($requests.Content | ConvertFrom-Json)

            $results = [pscustomobject] @{
                Name = $dnsZone.display_name;
                DNS1 = $dnsZone.upstream_servers[0];
                DNS2 = $dnsZone.upstream_servers[1];
                Domain = $dnsZone.dns_domain_names;
            }
            $results
        }
    }
}

Function Set-NSXTDNS {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          06/08/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns DNS Zone configuration for MGW or CGW
    .DESCRIPTION
        This cmdlet retrieves DNS Zone configuration for MGW or CGW
    .EXAMPLE
        Set-NSXTDNS -GatewayType MGW -DNS @("192.168.1.14","192.168.1.15")
    .EXAMPLE
        Set-NSXTDNS -GatewayType CGW -DNS @("8.8.8.8")
#>
    param(
        [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
        [Parameter(Mandatory=$true)][String[]]$DNS,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "PATCH"
        $dnsURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/dns-forwarder-zones/$($GatewayType.toLower())-dns-zone"

        $payload = @{
            upstream_servers = @($DNS)
        }

        $body = $payload | ConvertTo-Json -Depth 5

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$dnsURL`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $dnsURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $dnsURL -Body $body -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in updating NSX-T DNS Zones"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully updated NSX-T DNS for $GatewayType"
        }
    }
}

Function Get-NSXTPublicIP {
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $publicIPURL = ($global:nsxtProxyConnection.Server).replace("/sks-nsxt-manager","") + "/cloud-service/api/v1/infra/public-ips"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$publicIPURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $publicIPURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $publicIPURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Public IPs"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $results = ($requests.Content | ConvertFrom-Json).results | select display_name,id,ip

            if ($PSBoundParameters.ContainsKey("Name")){
                $results | where {$_.display_name -eq $Name}
            } else {
                $results
            }
        }
    }
}

Function New-NSXTPublicIP {
    Param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "PUT"
        $publicIPURL = ($global:nsxtProxyConnection.Server).replace("/sks-nsxt-manager","") + "/cloud-service/api/v1/infra/public-ips/$($Name)"

        $payload = @{
            display_name = "$Name";
        }

        $body = $payload | ConvertTo-Json

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$publicIPURL`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $publicIPURL -Method $method -Body $body -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $publicIPURL -Method $method -Body $body -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Public IPs"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully requested new NSX-T Public IP Address"
            ($requests.Content | ConvertFrom-Json) | select display_name,id,ip
        }
    }
}

Function Remove-NSXTPublicIP {
    Param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "DELETE"
        $publicIPURL = ($global:nsxtProxyConnection.Server).replace("/sks-nsxt-manager","") + "/cloud-service/api/v1/infra/public-ips/$($Name)"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$publicIPURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $publicIPURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $publicIPURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in deleting NSX-T Public IPs"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully deleted NSX-T Public IP Address $Name"
        }
    }
}

Function Get-NSXTNatRule {
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $natURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-1s/cgw/nat/USER/nat-rules"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$natURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $natURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $natURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Public IPs"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $results = ($requests.Content | ConvertFrom-Json).results | select id,display_name,sequence_number,source_network,translated_network,destination_network,translated_ports,service,scope

            if ($PSBoundParameters.ContainsKey("Name")){
                $results | where {$_.display_name -eq $Name}
            } else {
                $results
            }
        }
    }
}

Function New-NSXTNatRule {
    Param(
        [Parameter(Mandatory=$true)][String]$Name,
        [Parameter(Mandatory=$true)][String]$PublicIP,
        [Parameter(Mandatory=$true)][String]$InternalIP,
        [Parameter(Mandatory=$true)][String]$Service,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "PUT"
        $natURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-1s/cgw/nat/USER/nat-rules/$($Name)"

        if($service -eq "ANY") {
            $payload = @{
                display_name = $Name;
                action = "REFLEXIVE";
                service = "";
                translated_network = $PublicIP;
                source_network = $InternalIP;
                scope = @("/infra/labels/cgw-public");
                firewall_match = "MATCH_INTERNAL_ADDRESS";
                logging = $false;
                enabled = $true;
                sequence_number = 0;
            }
        } else {
            $nsxtService = Get-NSXTServiceDefinition -Name $Service
            $servicePath = $nsxtService.path
            $servicePort = $nsxtService.Destination

            $payload = @{
                display_name = $Name;
                action = "DNAT";
                service = $servicePath;
                translated_network = $InternalIP;
                translated_ports = $servicePort;
                destination_network = $PublicIP
                scope = @("/infra/labels/cgw-public");
                firewall_match = "MATCH_EXTERNAL_ADDRESS";
                logging = $false;
                enabled = $true;
                sequence_number = 0;
            }
        }

        $body = $payload | ConvertTo-Json -Depth 5

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$natURL`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $natURL -Method $method -Body $body -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $natURL -Method $method -Body $body -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in creating NSX-T NAT Rule"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully create new NAT Rule"
            ($requests.Content | ConvertFrom-Json) | select id,display_name,sequence_number,source_network,translated_network,destination_network,translated_ports,service,scope
        }
    }
}

Function Remove-NSXTNatRule {
    Param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {

        $natRuleId = (Get-NSXTNatRule -Name $Name).id

        $method = "DELETE"
        $natURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-1s/cgw/nat/USER/nat-rules/$($natRuleId)"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$natURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $natURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $natURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in deleting NSX-T NAT Rule"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully deleted NAT Rule $Name"
        }
    }
}
