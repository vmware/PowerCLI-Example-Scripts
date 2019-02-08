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
            Write-Host "Succesfully created new NSX-T Segment $Name"
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
            Write-Host "Succesfully removed NSX-T Segment $Name"
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
        [Parameter(Mandatory=$True)]$SourceGroup,
        [Parameter(Mandatory=$True)]$DestinationGroup,
        [Parameter(Mandatory=$True)]$Service,
        [Parameter(Mandatory=$True)][ValidateSet("ALLOW","DENY")]$Action,
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

        $sourceGroups = @()
        foreach ($group in $SourceGroup) {
            if($group -eq "ANY") {
                $sourceGroups = @("ANY")
            } else {
                $tmp = (Get-NSXTGroup -GatewayType $GatewayType -Name $group).Path
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
            resource_type = "CommunicationEntry";
            sequence_number = $SequenceNumber;
            destination_groups = $destinationGroups;
            source_groups = $sourceGroups;
            logged = $Logged;
            scope = @("/infra/labels/$($GatewayType.toLower())");
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
            Write-Host "Succesfully created new NSX-T Firewall Rule $Name"
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
            Write-Host "Succesfully removed NSX-T Firewall Rule"
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
            Write-Host "Succesfully created new NSX-T Group $Name"
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
            Write-Host "Succesfully removed NSX-T Group $Name"
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
                }
                $results += $tmp
            }
            $results
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
            Write-Host "Succesfully created new NSX-T Service $Name"
            ($requests.Content | ConvertFrom-Json) | select display_name, id
        }
    }
}

Function Get-NSXTDistFirewallSection {
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
        Returns all NSX-T Distributed Firewall Groups
    .DESCRIPTION
        This cmdlet retrieves all NSX-T Distributed Firewall Sections
    .EXAMPLE
        Get-NSXTDistFirewallSection
    .EXAMPLE
        Get-NSXTDistFirewallSection -Name "App Section 1"
    .EXAMPLE
        et-NSXTDistFirewallSection -Category Emergency
#>
    param(
        [Parameter(Mandatory=$false)][String]$Name,
        [Parameter(Mandatory=$false)][ValidateSet("Emergency","Infrastructure","Environment","Application")][String]$Category,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {
        $method = "GET"
        $distFirewallGroupURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/cgw/communication-maps"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$distFirewallGroupURL`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $distFirewallGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $distFirewallGroupURL -Method $method -Headers $global:nsxtProxyConnection.headers
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe NSX-T Proxy session is no longer valid, please re-run the Connect-NSXTProxy cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in retrieving NSX-T Distributed Firewall Sections"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            $groups = ($requests.Content | ConvertFrom-Json).results

            if ($PSBoundParameters.ContainsKey("Name")){
                $groups = $groups | where {$_.display_name -eq $Name}
            }

            if ($PSBoundParameters.ContainsKey("Category")){
                $groups = $groups | where {$_.category -eq $Category}
            }

            $results = @()
            foreach ($group in $groups | Sort-Object -Property category) {
                $tmp = [pscustomobject] @{
                    Id = $group.id;
                    Section = $group.display_name;
                    Category = $group.category;
                    Precedence = $group.precedence;
                }
                $results+=$tmp
            }
            $results
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
        [Parameter(Mandatory=$True)][ValidateSet("ALLOW","DENY")]$Action,
        [Parameter(Mandatory=$false)][Boolean]$Logged=$false,
        [Switch]$Troubleshoot
    )

    If (-Not $global:nsxtProxyConnection) { Write-error "No NSX-T Proxy Connection found, please use Connect-NSXTProxy" } Else {

        $sectionId = (Get-NSXTDistFirewallSection -Name $Section).Id

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
            action = $Action;
        }

        $body = $payload | ConvertTo-Json -depth 5

        $method = "PUT"
        $generatedId = (New-Guid).Guid
        $newDistFirewallURL = $global:nsxtProxyConnection.Server + "/policy/api/v1/infra/domains/cgw/communication-maps/$sectionId/communication-entries/$generatedId"

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
            Write-Host "Succesfully created new NSX-T Distributed Firewall Rule $Name"
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
            Write-Host "Succesfully removed NSX-T Distributed Firewall Rule"
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
            Write-Host "Succesfully retrieved NSX-T Routing Table`n"
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
        Write-Host "Succesfully retrieved NSX-T Overview Information"
        ($requests.Content | ConvertFrom-Json)
    }
}
}