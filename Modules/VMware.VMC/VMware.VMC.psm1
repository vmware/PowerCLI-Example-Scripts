Function Get-VMCCommand {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Returns all cmdlets for VMware Cloud on AWS
    .DESCRIPTION
        This cmdlet will allow you to return all cmdlets included in the VMC module
    .EXAMPLE
        Get-VMCCommand
    .EXAMPLE
        Get-Command -Module VMware.VMC
    .NOTES
        You can either use this cmdlet or the Get-Command cmdlet as seen in Example 2
#>
    Get-command -Module VMware.VimAutomation.Vmc
    Get-Command -Module VMware.VMC

}
Function Connect-VMCVIServer {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Cmdlet to connect to your VMC vCenter Server
    .DESCRIPTION
        This will connect you to both the VMC ViServer as well as the CiSServer at the same time.
    .EXAMPLE
        Connect-VMCVIServer -Server <VMC vCenter address> -User <Username> -Password <Password>
    .NOTES
        Easiest way is to pipe through your credentials from Get-VMCSDDCDefaultCredential
#>
    Param (
        [Parameter(Mandatory=$true)]$Org,
        [Parameter(Mandatory=$true)]$Sddc,
        [switch]$Autologin
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        $creds = Get-VMCSDDCDefaultCredential -Org $Org -Sddc $Sddc
        Write-Host "Connecting to VMC vCenter Server" $creds.vc_public_ip
        Connect-VIServer -Server $creds.vc_public_ip -User $creds.cloud_username -Password $creds.cloud_password | Add-Member -MemberType Noteproperty -Name Location -Value "VMC"
        Write-Host "Connecting to VMC CIS Endpoint" $creds.vc_public_ip
        Connect-CisServer -Server $creds.vc_public_ip -User $creds.cloud_username -Password $creds.cloud_password | Add-Member -MemberType Noteproperty -Name Location -Value "VMC"
    }
}
Function Get-VMCOrg {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Return the Orgs that you are a part of
    .DESCRIPTION
        Depending on what you've purchased, you may be a part of one or more VMC Orgs. This will return your orgs
    .EXAMPLE
        Get-VMCOrg
    .EXAMPLE
        Get-VMCOrg -Name <Org Name>
    .NOTES
        Return all the info about the orgs you are a part of
#>
    Param (
       [Parameter(Mandatory=$false)]$Name
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use Connect-VMC to connect" } Else {
        $orgService = Get-VMCService com.vmware.vmc.orgs
        if ($PSBoundParameters.ContainsKey("Name")){
            $orgs = $orgService.list() | Where {$_.display_name -match $Name}
        } Else {
            $orgs = $orgService.list()
        }
        $Orgs | Select display_name, name, user_name, created, id
    }
}
Function Get-VMCSDDC {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Returns all of the SDDCs you are associated to
    .DESCRIPTION
        Returns all of the SDDCs ayou are associated to
    .EXAMPLE
        Get-VMCSDDC -Org <Org Name>
    .EXAMPLE
        Get-VMCSDDC -Name <SDDC Name> -Org <Org Name>
#>
    Param (
        [Parameter(Mandatory=$True)]$Org,
        [Parameter(Mandatory=$false)]$Name
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Org")){
            $orgs = Get-VMCOrg -Name $Org
        } else {
            $orgs = Get-VMCOrg
        }

        foreach ($org in $orgs) {
            $orgID = $org.ID
            $sddcService = Get-VMCService com.vmware.vmc.orgs.sddcs
            if ($PSBoundParameters.ContainsKey("Name")){
                $sddcService.list($OrgID) | Where {$_.name -match $Name}
            } Else {
                $sddcService.list($OrgID)
            }
        }
    }
}
Function Get-VMCTask {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Returns all of the VMC Tasks
    .DESCRIPTION
        Returns all of the VMC Tasks that have either occurred or are in process
    .EXAMPLE
        Get-VMCTask
#>
    Param (
        [Parameter(Mandatory=$True)]$Org
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Org")){
            $orgs = Get-VMCOrg -Name $Org
        } else {
            $orgs = Get-VMCOrg
        }

        foreach ($org in $orgs) {
            $orgID = $org.ID
            $taskService = Get-VMCService com.vmware.vmc.orgs.tasks
            $taskService.list($OrgID) | Select * -ExcludeProperty Help
        }
    }
}
Function Get-VMCSDDCDefaultCredential {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Returns the default credential for the SDDC
    .DESCRIPTION
        Returns the default credential for the sddc
    .EXAMPLE
        Get-VMCSDDCDefaultCredential -Org <Org Name>
    .EXAMPLE
        Get-VMCSDDCDefaultCredential -Sddc <SDDC Name> -Org <Org Name>
#>
    Param (
        [Parameter(Mandatory=$true)]$Org,
        [Parameter(Mandatory=$false)]$Sddc
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Sddc")){
            $sddcs = Get-VMCSDDC -Name $Sddc -Org $Org
        } else {
            $sddcs = Get-VMCSDDC -Org $Org
        }

        foreach ($sddc in $sddcs) {
            $sddc.resource_config | Select-object vc_url, vc_management_ip, vc_public_ip, cloud_username, cloud_password
        }
    }
}
Function Get-VMCSDDCPublicIP {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Returns your Public IPs
    .DESCRIPTION
        Returns your Public IPs
    .EXAMPLE
        Get-VMCSDDCPublicIP -Org <Org Name>
    .EXAMPLE
        Get-VMCSDDCPublicIP -Sddc <SDDC Name> -Org <Org Name>
    .NOTES
        Return your Public IPs that you have assigned to your account
#>
    Param (
        [Parameter(Mandatory=$true)]$Org,
        [Parameter(Mandatory=$false)]$Sddc
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Sddc")){
            $sddcs = Get-VMCSDDC -Name $Sddc -Org $Org
        } else {
            $sddcs = Get-VMCSDDC -Org $Org
        }

        foreach ($sddc in $sddcs) {
            $sddc.resource_config.Public_ip_pool
        }
    }
}
Function Get-VMCVMHost {
    Param (
        [Parameter(Mandatory=$false)]$Sddc,
        [Parameter(Mandatory=$true)]$Org
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Sddc")){
            $sddcs = Get-VMCSDDC -Name $Sddc -Org $Org
        } else {
            $sddcs = Get-VMCSDDC -Org $Org
        }

        $results = @()
        foreach ($sddc in $sddcs) {
            foreach ($vmhost in $sddc.resource_config.esx_hosts) {
                $tmp = [pscustomobject] @{
                    esx_id = $vmhost.esx_id;
                    name = $vmhost.name;
                    hostname = $vmhost.hostname;
                    esx_state = $vmhost.esx_state;
                    sddc_id = $sddc.id;
                    org_id = $sddc.org_id;
                }
                $results += $tmp
            }
            $results
        }
    }
}
Function Get-VMCSDDCVersion {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================
    
    .SYNOPSIS
        Returns SDDC Version
    .DESCRIPTION
        Returns Version of the SDDC
    .EXAMPLE
        Get-VMCSDDCVersion -Name <SDDC Name> -Org <Org Name>
#>
    Param (
        [Parameter(Mandatory=$True)]$Org,
        [Parameter(Mandatory=$false)]$Name
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Org")){
            $orgs = Get-VMCOrg -Name $Org
        } else {
            $orgs = Get-VMCOrg
        }

        foreach ($org in $orgs) {
            $orgID = $org.ID
            $sddcService = Get-VMCService com.vmware.vmc.orgs.sddcs
            if ($PSBoundParameters.ContainsKey("Name")){
                ($sddcService.list($OrgID) | Where {$_.name -match $Name}).resource_config.sddc_manifest | Select *version
            } Else {
                ($sddcService.list($OrgID)).resource_config.sddc_manifest | Select *version
            }
        }
    }
}

Function Get-VMCFirewallRule {
    <#
        .NOTES
        ===========================================================================
        Created by:     William Lam
        Date:          11/19/2017
        Organization: 	VMware
        Blog:          https://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Retruns VMC Firewall Rules for a given Gateway (MGW or CGW)
        .DESCRIPTION
            Retruns VMC Firewall Rules for a given Gateway (MGW or CGW)
        .EXAMPLE
            Get-VMCFirewallRule -OrgName <Org Name> -SDDCName <SDDC Name> -GatewayType <MGW or CGW>
        .EXAMPLE
            Get-VMCFirewallRule -OrgName <Org Name> -SDDCName <SDDC Name> -GatewayType <MGW or CGW> -ShowAll
    #>
        param(
            [Parameter(Mandatory=$false)][String]$SDDCName,
            [Parameter(Mandatory=$false)][String]$OrgName,
            [Parameter(Mandatory=$false)][Switch]$ShowAll,
            [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType
        )

        if($GatewayType -eq "MGW") {
            $EdgeId = "edge-1"
        } else {
            $EdgeId = "edge-2"
        }

        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id

        $firewallConfigService = Get-VmcService com.vmware.vmc.orgs.sddcs.networks.edges.firewall.config

        $firewallRules = ($firewallConfigService.get($orgId, $sddcId, $EdgeId)).firewall_rules.firewall_rules
        if(-not $ShowAll) {
            $firewallRules = $firewallRules | where { $_.rule_type -ne "default_policy" -and $_.rule_type -ne "internal_high" -and $_.name -ne "vSphere Cluster HA" -and $_.name -ne "Outbound Access" } | Sort-Object -Property rule_tag
        } else {
            $firewallRules = $firewallRules | Sort-Object -Property rule_tag
        }

        $results = @()
        foreach ($firewallRule in $firewallRules) {
            if($firewallRule.source.ip_address.Count -ne 0) {
                $source = $firewallRule.source.ip_address
            } else { $source = "ANY" }

            if($firewallRule.application.service.protocol -ne $null) {
                $protocol = $firewallRule.application.service.protocol
            } else { $protocol = "ANY" }

            if($firewallRule.application.service.port -ne $null) {
                $port = $firewallRule.application.service.port
            } else { $port = "ANY" }

            $tmp = [pscustomobject] @{
                ID = $firewallRule.rule_id;
                Name = $firewallRule.name;
                Type = $firewallRule.rule_type;
                Action = $firewallRule.action;
                Protocol = $protocol;
                Port = $port;
                SourceAddress = $source
                DestinationAddress = $firewallRule.destination.ip_address;
            }
            $results+=$tmp
        }
        $results
    }

    Function Export-VMCFirewallRule {
    <#
        .NOTES
        ===========================================================================
        Created by:     William Lam
        Date:          11/19/2017
        Organization: 	VMware
        Blog:          https://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Exports all "customer" created VMC Firewall Rules to JSON file
        .DESCRIPTION
            Exports all "customer" created VMC Firewall Rules to JSON file
        .EXAMPLE
            Export-VMCFirewallRule -OrgName <Org Name> -SDDCName <SDDC Name> -GatewayType <MGW or CGW> -Path "C:\Users\lamw\Desktop\VMCFirewallRules.json"
    #>
        param(
            [Parameter(Mandatory=$false)][String]$SDDCName,
            [Parameter(Mandatory=$false)][String]$OrgName,
            [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
            [Parameter(Mandatory=$false)][String]$Path
        )

        if (-not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect"; break }

        if($GatewayType -eq "MGW") {
            $EdgeId = "edge-1"
        } else {
            $EdgeId = "edge-2"
        }

        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id

        if(-not $orgId) {
            Write-Host -ForegroundColor red "Unable to find Org $OrgName, please verify input"
            break
        }
        if(-not $sddcId) {
            Write-Host -ForegroundColor red "Unable to find SDDC $SDDCName, please verify input"
            break
        }

        $firewallConfigService = Get-VmcService com.vmware.vmc.orgs.sddcs.networks.edges.firewall.config

        $firewallRules = ($firewallConfigService.get($orgId, $sddcId, $EdgeId)).firewall_rules.firewall_rules
        if(-not $ShowAll) {
            $firewallRules = $firewallRules | where { $_.rule_type -ne "default_policy" -and $_.rule_type -ne "internal_high" -and $_.name -ne "vSphere Cluster HA" -and $_.name -ne "Outbound Access" } | Sort-Object -Property rule_tag
        } else {
            $firewallRules = $firewallRules | Sort-Object -Property rule_tag
        }

        $results = @()
        $count = 0
        foreach ($firewallRule in $firewallRules) {
            if($firewallRule.source.ip_address.Count -ne 0) {
                $source = $firewallRule.source.ip_address
            } else {
                $source = "ANY"
            }

            $tmp = [pscustomobject] @{
                Name = $firewallRule.name;
                Action = $firewallRule.action;
                Protocol = $firewallRule.application.service.protocol;
                Port = $firewallRule.application.service.port;
                SourcePort = $firewallRule.application.service.source_port;
                ICMPType = $firewallRule.application.service.icmp_type;
                SourceAddress = $firewallRule.source.ip_address;
                DestinationAddress = $firewallRule.destination.ip_address;
                Enabled = $firewallRule.enabled;
                Logging = $firewallRule.logging_enabled;
            }
            $count+=1
            $results+=$tmp
        }
        if($Path) {
            Write-Host -ForegroundColor Green "Exporting $count VMC Firewall Rules to $Path ..."
            $results | ConvertTo-Json | Out-File $Path
        } else {
            $results | ConvertTo-Json
        }
    }

    Function Import-VMCFirewallRule {
    <#
        .NOTES
        ===========================================================================
        Created by:     William Lam
        Date:          11/19/2017
        Organization: 	VMware
        Blog:          https://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Imports VMC Firewall Rules from exported JSON configuration file
        .DESCRIPTION
            Imports VMC Firewall Rules from exported JSON configuration file
        .EXAMPLE
            Import-VMCFirewallRule -OrgName <Org Name> -SDDCName <SDDC Name> -GatewayType <MGW or CGW> -Path "C:\Users\lamw\Desktop\VMCFirewallRules.json"
    #>
        param(
            [Parameter(Mandatory=$false)][String]$SDDCName,
            [Parameter(Mandatory=$false)][String]$OrgName,
            [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
            [Parameter(Mandatory=$false)][String]$Path
        )

        if (-not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect"; break }

        if($GatewayType -eq "MGW") {
            $EdgeId = "edge-1"
        } else {
            $EdgeId = "edge-2"
        }

        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id

        if(-not $orgId) {
            Write-Host -ForegroundColor red "Unable to find Org $OrgName, please verify input"
            break
        }
        if(-not $sddcId) {
            Write-Host -ForegroundColor red "Unable to find SDDC $SDDCName, please verify input"
            break
        }

        $firewallService = Get-VmcService com.vmware.vmc.orgs.sddcs.networks.edges.firewall.config.rules

        $vmcFirewallRulesJSON = Get-Content -Raw $Path | ConvertFrom-Json

        # Create top level Firewall Rules Object
        $firewallRules = $firewallService.Help.add.firewall_rules.Create()
        # Create top top level Firewall Rule Spec which will be an array of individual Firewall rules as we process them in next section
        $ruleSpec = $firewallService.Help.add.firewall_rules.firewall_rules.Create()

        foreach ($vmcFirewallRule in $vmcFirewallRulesJSON) {
            # Create Individual Firewall Rule Element Spec
            $ruleElementSpec = $firewallService.Help.add.firewall_rules.firewall_rules.Element.Create()

            # AppSpec
            $appSpec = $firewallService.Help.add.firewall_rules.firewall_rules.Element.application.Create()
            # ServiceSpec
            $serviceSpec = $firewallService.Help.add.firewall_rules.firewall_rules.Element.application.service.Element.Create()

            $protocol = $null
            if($vmcFirewallRule.Protocol -ne $null) {
                $protocol = $vmcFirewallRule.Protocol
            }
            $serviceSpec.protocol = $protocol

            # Process ICMP Type from JSON
            $icmpType = $null
            if($vmcFirewallRule.ICMPType -ne $null) {
                $icmpType = $vmcFirewallRule.ICMPType
            }
            $serviceSpec.icmp_type = $icmpType

            # Process Source Ports from JSON
            $sourcePorts = @()
            if($vmcFirewallRule.SourcePort -eq "any" -or $vmcFirewallRule.SourcePort -ne $null) {
                foreach ($port in $vmcFirewallRule.SourcePort) {
                    $sourcePorts+=$port
                }
            } else {
                $sourcePorts = @("any")
            }
            $serviceSpec.source_port = $sourcePorts

            # Process Ports from JSON
            $ports = @()
            if($vmcFirewallRule.Port -ne "null") {
                foreach ($port in $vmcFirewallRule.Port) {
                    $ports+=$port
                }
            }
            $serviceSpec.port = $ports
            $addSpec = $appSpec.service.Add($serviceSpec)

            # Create Source Spec
            $srcSpec = $firewallService.Help.add.firewall_rules.firewall_rules.Element.source.Create()
            $srcSpec.exclude = $false
            # Process Source Address from JSON
            $sourceAddess = @()
            if($vmcFirewallRule.SourceAddress -ne "null") {
                foreach ($address in $vmcFirewallRule.SourceAddress) {
                    $sourceAddess+=$address
                }
            }
            $srcSpec.ip_address = $sourceAddess;

            # Create Destination Spec
            $destSpec = $firewallService.Help.add.firewall_rules.firewall_rules.Element.destination.Create()
            $destSpec.exclude = $false
            # Process Destination Address from JSON
            $destinationAddess = @()
            if($vmcFirewallRule.DestinationAddress -ne "null") {
                foreach ($address in $vmcFirewallRule.DestinationAddress) {
                    $destinationAddess+=$address
                }
            }
            $destSpec.ip_address = $destinationAddess

            # Add various specs
            if($vmcFirewallRule.Protocol -ne $null -and $vmcFirewallRule.port -ne $null) {
                $ruleElementSpec.application = $appSpec
            }

            $ruleElementSpec.source = $srcSpec
            $ruleElementSpec.destination = $destSpec
            $ruleElementSpec.rule_type = "user"

            # Process Enabled from JSON
            $fwEnabled = $false
            if($vmcFirewallRule.Enabled -eq "true") {
                $fwEnabled = $true
            }
            $ruleElementSpec.enabled = $fwEnabled

            # Process Logging from JSON
            $loggingEnabled = $false
            if($vmcFirewallRule.Logging -eq "true") {
                $loggingEnabled = $true
            }
            $ruleElementSpec.logging_enabled = $loggingEnabled

            $ruleElementSpec.action = $vmcFirewallRule.Action
            $ruleElementSpec.name = $vmcFirewallRule.Name

            # Add the individual FW rule spec into our overall firewall rules array
            Write-host "Creating VMC Firewall Rule Spec:" $vmcFirewallRule.Name "..."
            $ruleSpecAdd = $ruleSpec.Add($ruleElementSpec)
        }
        $firewallRules.firewall_rules = $ruleSpec

        Write-host "Adding VMC Firewall Rules ..."
        $firewallRuleAdd = $firewallService.add($orgId,$sddcId,$EdgeId,$firewallRules)
    }

    Function Remove-VMCFirewallRule {
    <#
        .NOTES
        ===========================================================================
        Created by:     William Lam
        Date:          11/19/2017
        Organization: 	VMware
        Blog:          https://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Removes VMC Firewall Rule given Rule Id
        .DESCRIPTION
            Removes VMC Firewall Rule given Rule Id
        .EXAMPLE
            Remove-VMCFirewallRule -OrgName <Org Name> -SDDCName <SDDC Name> -GatewayType <MGW or CGW> -RuleId <Rule Id>
    #>
        param(
            [Parameter(Mandatory=$false)][String]$SDDCName,
            [Parameter(Mandatory=$false)][String]$OrgName,
            [Parameter(Mandatory=$true)][ValidateSet("MGW","CGW")][String]$GatewayType,
            [Parameter(Mandatory=$false)][String]$RuleId
        )

        if (-not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect"; break }

        if($GatewayType -eq "MGW") {
            $EdgeId = "edge-1"
        } else {
            $EdgeId = "edge-2"
        }

        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id

        if(-not $orgId) {
            Write-Host -ForegroundColor red "Unable to find Org $OrgName, please verify input"
            break
        }
        if(-not $sddcId) {
            Write-Host -ForegroundColor red "Unable to find SDDC $SDDCName, please verify input"
            break
        }

        $firewallService = Get-VmcService com.vmware.vmc.orgs.sddcs.networks.edges.firewall.config.rules
        Write-Host "Removing VMC Firewall Rule Id $RuleId ..."
        $firewallService.delete($orgId,$sddcId,$EdgeId,$RuleId)
    }

Function Get-VMCLogicalNetwork {
    <#
        .NOTES
        ===========================================================================
        Created by:     Kyle Ruddy
        Date:          03/06/2018
        Organization: 	VMware
        Blog:          https://thatcouldbeaproblem.com
        Twitter:       @kmruddy
        ===========================================================================

        .SYNOPSIS
            Retruns VMC Logical Networks for a given SDDC
        .DESCRIPTION
            Retruns VMC Logical Networks for a given SDDC
        .EXAMPLE
            Get-VMCLogicalNetwork -OrgName <Org Name> -SDDCName <SDDC Name> 
        .EXAMPLE
            Get-VMCLogicalNetwork -OrgName <Org Name> -SDDCName <SDDC Name> -LogicalNetworkName <Logical Network Name>
    #>
    param(
        [Parameter(Mandatory=$true)][String]$SDDCName,
        [Parameter(Mandatory=$true)][String]$OrgName,
        [Parameter(Mandatory=$false)][String]$LogicalNetworkName

    )

    $orgId = (Get-VMCOrg -Name $OrgName).Id
    $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id

    if(-not $orgId) {
        Write-Host -ForegroundColor red "Unable to find Org $OrgName, please verify input"
        break
    }
    if(-not $sddcId) {
        Write-Host -ForegroundColor red "Unable to find SDDC $SDDCName, please verify input"
        break
    }

    $logicalNetworkService = Get-VmcService com.vmware.vmc.orgs.sddcs.networks.logical

    $logicalNetworks = ($logicalNetworkService.get_0($orgId, $sddcId)).data | Sort-Object -Property id

    if($LogicalNetworkName) {
        $logicalNetworks = $logicalNetworks | Where-Object {$_.Name -eq $LogicalNetworkName}
    }

    $results = @()
    foreach ($logicalNetwork in $logicalNetworks) {
        $tmp = [pscustomobject] @{
            ID = $logicalNetwork.id;
            Name = $logicalNetwork.name;
            SubnetMask = $logicalNetwork.subnets.address_groups.prefix_length;
            Gateway = $logicalNetwork.subnets.address_groups.primary_address;
            DHCPipRange = $logicalNetwork.dhcp_configs.ip_pools.ip_range;
            DHCPdomain = $logicalNetwork.dhcp_configs.ip_pools.domain_name;
            CGatewayID = $logicalNetwork.cgw_id;
            CGateway = $logicalNetwork.cgw_name;
        }
        $results+=$tmp
    }
    $results
}

Function Remove-VMCLogicalNetwork {
    <#
        .NOTES
        ===========================================================================
        Created by:     Kyle Ruddy
        Date:          03/06/2018
        Organization: 	VMware
        Blog:          https://thatcouldbeaproblem.com
        Twitter:       @kmruddy
        ===========================================================================

        .SYNOPSIS
            Removes Logical Network given ID
        .DESCRIPTION
            Removes Logical Network given ID
        .EXAMPLE
            Remove-VMCLogicalNetwork -OrgName <Org Name> -SDDCName <SDDC Name> -LogicalNetworkName <LogicalNetwork Name>
    #>
    [cmdletbinding(SupportsShouldProcess = $true,ConfirmImpact='High')]
    param(
        [Parameter(Mandatory=$true)][String]$SDDCName,
        [Parameter(Mandatory=$true)][String]$OrgName,
        [Parameter(Mandatory=$true)][String]$LogicalNetworkName
    )

    if (-not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect"; break }

    $orgId = (Get-VMCOrg -Name $OrgName).Id
    $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id
    $lsId = (Get-VMCLogicalNetwork -OrgName $OrgName -SDDCName $SDDCName -LogicalNetworkName $LogicalNetworkName).Id

    if(-not $orgId) {
        Write-Host -ForegroundColor red "Unable to find Org $OrgName, please verify input"
        break
    }
    if(-not $sddcId) {
        Write-Host -ForegroundColor red "Unable to find SDDC $SDDCName, please verify input"
        break
    }
    if(-not $lsId) {
        Write-Host -ForegroundColor red "Unable to find SDDC $LogicalNetworkName, please verify input"
        break
    }

    $logicalNetworkService = Get-VmcService com.vmware.vmc.orgs.sddcs.networks.logical
    $logicalNetworkService.delete($orgId,$sddcId,$lsId)
}

Function New-VMCLogicalNetwork {
    <#
        .NOTES
        ===========================================================================
        Created by:     Kyle Ruddy
        Date:          03/06/2018
        Organization: 	VMware
        Blog:          https://thatcouldbeaproblem.com
        Twitter:       @kmruddy
        ===========================================================================

        .SYNOPSIS
            Creates a new Logical Network
        .DESCRIPTION
            Creates a new Logical Network
        .EXAMPLE
            New-VMCLogicalNetwork -OrgName <Org Name> -SDDCName <SDDC Name> -LogicalNetworkName <LogicalNetwork Name> -SubnetMask <Subnet Mask Prefix> -Gateway <Gateway IP Address>
    #>
    [cmdletbinding(SupportsShouldProcess = $true,ConfirmImpact='High')]
    param(
        [Parameter(Mandatory=$true)][String]$SDDCName,
        [Parameter(Mandatory=$true)][String]$OrgName,
        [Parameter(Mandatory=$true)][String]$LogicalNetworkName,
        [Parameter(Mandatory=$true)][String]$SubnetMask,
        [Parameter(Mandatory=$true)][String]$Gateway
    )

    if (-not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect"; break }

    $orgId = (Get-VMCOrg -Name $OrgName).Id
    $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id
    
    if(-not $orgId) {
        Write-Host -ForegroundColor red "Unable to find Org $OrgName, please verify input"
        break
    }
    if(-not $sddcId) {
        Write-Host -ForegroundColor red "Unable to find SDDC $SDDCName, please verify input"
        break
    }

    $logicalNetworkService = Get-VmcService com.vmware.vmc.orgs.sddcs.networks.logical
    $logicalNetworkSpec = $logicalNetworkService.Help.create.sddc_network.Create()
    $logicalNetworkSpec.name = $LogicalNetworkName
    $logicalNetworkSpec.cgw_id = "edge-2"
    $logicalNetworkSpec.cgw_name = "SDDC-CGW-1"
    $logicalNetworkAddressGroupSpec = $logicalNetworkService.Help.create.sddc_network.subnets.address_groups.Element.Create()
    $logicalNetworkAddressGroupSpec.prefix_length = $SubnetMask
    $logicalNetworkAddressGroupSpec.primary_address = $Gateway

    $logicalNetworkSpec.subnets.address_groups.Add($logicalNetworkAddressGroupSpec) | Out-Null
    $logicalNetworkService.create($orgId, $sddcId, $logicalNetworkSpec)
    Get-VMCLogicalNetwork -OrgName $OrgName -SDDCName $SDDCName -LogicalNetworkName $LogicalNetworkName
}

Export-ModuleMember -Function 'Get-VMCCommand', 'Connect-VMCVIServer', 'Get-VMCOrg', 'Get-VMCSDDC', 'Get-VMCTask', 'Get-VMCSDDCDefaultCredential', 'Get-VMCSDDCPublicIP', 'Get-VMCVMHost', 'Get-VMCSDDCVersion', 'Get-VMCFirewallRule', 'Export-VMCFirewallRule', 'Import-VMCFirewallRule', 'Remove-VMCFirewallRule', 'Get-VMCLogicalNetwork', 'Remove-VMCLogicalNetwork', 'New-VMCLogicalNetwork'