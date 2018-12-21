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

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $segmentsURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/tier-1s/cgw/segments"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$segmentsURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $segmentsURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $segmentsURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
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
                $gateway = $subnets.gateway_address
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
#>
    Param (
        [Parameter(Mandatory=$True)]$Name,
        [Parameter(Mandatory=$True)]$Gateway,
        [Parameter(Mandatory=$False)]$DHCPRange,
        [Switch]$DHCP,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        if($DHCP) {
            $dhcpConf = @($DHCPRange)
        } else {
            $dhcpConf = @($null)
        }

        $subnets = @{
            gateway_address = $gateway;
            dhcp_ranges = $dhcpConf;
        }

        $payload = @{
            display_name = $Name;
            subnets = @($subnets)
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
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Succesfully created new NSX-T Segment $Name"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        } else {
            Write-Error "Failed to create new NSX-T Segment"

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
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Succesfully removed NSX-T Segment $Name"
        } else {
            Write-Error "Failed to remove NSX-T Segments"

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
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
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
                            $requests = Invoke-WebRequest -Uri $sourceGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
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
                            $requests = Invoke-WebRequest -Uri $destionationGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
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
                            $requests = Invoke-WebRequest -Uri $serviceGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
                        } catch {
                            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
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

        } else {
            Write-Error "Failed to retrieve NSX-T Firewall Rules"
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
        New-NSXTFirewall -GatewayType MGW -Name TEST -Id TEST -SourceGroupId ESXI -DestinationGroupId ANY -Service ANY -Logged $true -SequenceNumber 7 -Action ALLOW
#>
    Param (
        [Parameter(Mandatory=$True)]$Name,
        [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
        [Parameter(Mandatory=$True)]$Id,
        [Parameter(Mandatory=$True)]$SequenceNumber,
        [Parameter(Mandatory=$True)]$SourceGroupId,
        [Parameter(Mandatory=$True)]$DestinationGroupId,
        [Parameter(Mandatory=$True)]$Service,
        [Parameter(Mandatory=$True)][ValidateSet("ALLOW","DENY")]$Action,
        [Parameter(Mandatory=$false)][Boolean]$Logged=$false,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {

        if($DestinationGroupId -eq "ANY") {
            $destinationGroups = $DestinationGroupId
        } else {
            $destinationGroups = "/infra/domains/$($GatewayType.toLower())/groups/$DestinationGroupId"
        }

        $sourceGroups = @()
        foreach ($group in $SourceGroupId) {
            $tmp = "/infra/domains/$($GatewayType.toLower())/groups/$group"
            $sourceGroups+= $tmp
        }

        $services = @()
        foreach ($serviceName in $Service) {
            if($serviceName -eq "ANY") {
                $tmp = "ANY"
            } else {
                $tmp = "/infra/services/$serviceName"
            }
            $services+=$tmp
        }

        $payload = @{
            display_name = $Name;
            resource_type = "CommunicationEntry";
            id = $Id;
            sequence_number = $SequenceNumber;
            destination_groups = @($destinationGroups);
            source_groups = $sourceGroups;
            logged = $Logged;
            scope = @("/infra/labels/$($GatewayType.toLower())");
            services = $services;
            action = $Action;
        }

        $body = $payload | ConvertTo-Json -depth 5

        $method = "PUT"
        $newFirewallURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/$($GatewayType.toLower())/gateway-policies/default/rules/$Id"

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
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Succesfully created new NSX-T Firewall Rule $Name"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        } else {
            Write-Error "Failed to create new NSX-T Firewall Rule"
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
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Succesfully removed NSX-T Firewall Rule $Name"
        } else {
            Write-Error "Failed to create new NSX-T Firewall Rule"
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
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
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
                }
                $results+=$tmp
            }
            $results
        } else {
            Write-Error "Failed to retrieve NSX-T Groups"
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
#>
    Param (
        [Parameter(Mandatory=$True)]$Name,
        [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
        [Parameter(Mandatory=$True)][String[]]$IPAddress,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $expression = @{
            resource_type = "IPAddressExpression";
            ip_addresses = $IPAddress;
        }

        $payload = @{
            display_name = $Name;
            expression = @($expression);
        }
        $body = $payload | ConvertTo-Json -depth 5

        $method = "PUT"
        $newGroupURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/$($GatewayType.toLower())/groups/$Name"

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
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Succesfully created new NSX-T Group $Name"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        } else {
            Write-Error "Failed to create new NSX-T Group"
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
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Succesfully removed NSX-T Group $Name"
        } else {
            Write-Error "Failed to create new NSX-T Group"
        }
    }
}

Function Get-NSXTService {
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
        Get-NSXTService
    .EXAMPLE
        Get-NSXTService -Name "WINS"
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
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
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
                }
                $results += $tmp
            }
            $results
        } else {
            Write-Error "Failed to retrieve NSX-T Services"
        }
    }
}

Function New-NSXTService {
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
        New-NSXTService -Name "MyHTTP2" -Protocol TCP -DestinationPorts @("8080","8081")
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
            Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
            break
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Succesfully created new NSX-T Service $Name"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        } else {
            Write-Error "Failed to create new NSX-T Service"
        }
    }
}