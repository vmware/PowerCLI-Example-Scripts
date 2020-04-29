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
        [switch]$Autologin,
        [switch]$UseManagementIP
    )
    
    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        $creds = Get-VMCSDDCDefaultCredential -Org $Org -Sddc $Sddc
        If($UseManagementIP){
            $Server = $creds.vc_management_ip
        }Else{
            $Server = $creds.vc_public_ip
        }

        Write-Host "Connecting to VMC vCenter Server" $Server
        Connect-VIServer -Server $Server -User $creds.cloud_username -Password $creds.cloud_password | Add-Member -MemberType Noteproperty -Name Location -Value "VMC"
        Write-Host "Connecting to VMC CIS Endpoint" $Server
        Connect-CisServer -Server $Server -User $creds.cloud_username -Password $creds.cloud_password | Add-Member -MemberType Noteproperty -Name Location -Value "VMC"
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
            $orgs = $orgService.list() | Where {$_.display_name -eq $Name}
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
                $sddcService.list($OrgID) | Where {$_.name -eq $Name}
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
        Blog:          https://www.kmruddy.com
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

    # @LucD22 - 21/10/18 - Fix for issue #176 VMware.VMC module only lists firts 20 Logical networks
    # Loop until entries (total_count) are returned

    $index = [long]0

    $logicalNetworks = do{
        $netData = $logicalNetworkService.get_0($orgId,$sddcId,$pagesize,$index)
        $netData.data | Sort-Object -Property id
        $index = $index + $netdata.paging_info.page_size    
    }
    until($index -ge $netData.paging_info.total_count)

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
        Blog:          https://www.kmruddy.com
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
    Blog:          https://www.kmruddy.com
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
Function Get-VMCSDDCSummary {
    <#
        .NOTES
        ===========================================================================
        Created by:    VMware
        Date:          09/04/18
        Organization:  VMware
        Blog:          https://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Returns a number of useful informational data about a given SDDC within VMC Org
        .DESCRIPTION
            Returns Version, Create/Expiration Date, Deployment Type, Region, AZ, Instance Type, VPC CIDR & NSX-T
        .EXAMPLE
            Get-VMCSDDCSummary -Name <SDDC Name> -Org <Org Name>
    #>
        Param (
            [Parameter(Mandatory=$True)]$Org,
            [Parameter(Mandatory=$True)]$Name
        )

        If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
            $orgId = (Get-VMCOrg -Name $Org).Id
            $sddcId = (Get-VMCSDDC -Name $Name -Org $Org).Id

            $sddcService = Get-VmcService "com.vmware.vmc.orgs.sddcs"
            $sddc = $sddcService.get($orgId,$sddcId)

            $results = [pscustomobject] @{
                Version = $sddc.resource_config.sddc_manifest.vmc_version;
                CreateDate = $sddc.created;
                ExpirationDate = $sddc.expiration_date;
                DeploymentType = $sddc.resource_config.deployment_type;
                Region = $sddc.resource_config.region;
                AvailabilityZone = $sddc.resource_config.availability_zones;
                InstanceType = $sddc.resource_config.sddc_manifest.esx_ami.instance_type;
                VpcCIDR = $sddc.resource_config.vpc_info.vpc_cidr;
                NSXT = $sddc.resource_config.nsxt;
                VPC_VGW = $sddc.resource_config.vpc_info.vgw_id;
            }
            $results
        }
}
Function Get-VMCPublicIP {
    <#
        .NOTES
        ===========================================================================
        Created by:    William LamVPC_VGW
        Date:          09/12/2018
        Organization:  VMware
        Blog:          http://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Retrieves all public IP Addresses for a given SDDC
        .DESCRIPTION
            This cmdlet retrieves all public IP Address for a given SDDC
        .EXAMPLE
            Get-VMCPublicIP -OrgName $OrgName -SDDCName $SDDCName
    #>
    Param (
        [Parameter(Mandatory=$True)]$OrgName,
        [Parameter(Mandatory=$True)]$SDDCName
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id

        $publicIPService = Get-VmcService "com.vmware.vmc.orgs.sddcs.publicips"
        $publicIPs = $publicIPService.list($orgId,$sddcId)

        $publicIPs | select public_ip, name, allocation_id
    }
}

Function New-VMCPublicIP {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          09/12/2018
        Organization:  VMware
        Blog:          http://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Request a new public IP Address for a given SDDC
        .DESCRIPTION
            This cmdlet requests a new public IP Address for a given SDDC
        .EXAMPLE
            New-VMCPublicIP -OrgName $OrgName -SDDCName $SDDCName -Description "Test for Randy"
    #>
    Param (
        [Parameter(Mandatory=$True)]$OrgName,
        [Parameter(Mandatory=$True)]$SDDCName,
        [Parameter(Mandatory=$False)]$Description
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id

        $publicIPService = Get-VmcService "com.vmware.vmc.orgs.sddcs.publicips"

        $publicIPSpec = $publicIPService.Help.create.spec.Create()
        $publicIPSpec.count = 1
        $publicIPSpec.names = @($Description)

        Write-Host "Requesting a new public IP Address for your SDDC ..."
        $results = $publicIPService.create($orgId,$sddcId,$publicIPSpec)
    }
}

Function Remove-VMCPublicIP {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          09/12/2018
        Organization:  VMware
        Blog:          http://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Removes a specific public IP Addresses for a given SDDC
        .DESCRIPTION
            This cmdlet removes a specific public IP Address for a given SDDC
        .EXAMPLE
            Remove-VMCPublicIP -OrgName $OrgName -SDDCName $SDDCName -AllocationId "eipalloc-0567acf34e436c01f"
    #>
    Param (
        [Parameter(Mandatory=$True)]$OrgName,
        [Parameter(Mandatory=$True)]$SDDCName,
        [Parameter(Mandatory=$True)]$AllocationId
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id

        $publicIPService = Get-VmcService "com.vmware.vmc.orgs.sddcs.publicips"

        Write-Host "Deleting public IP Address with ID $AllocationId ..."
        $results = $publicIPService.delete($orgId,$sddcId,$AllocationId)
    }
}

Function Set-VMCSDDC {
    <#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          01/12/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Rename an SDDC
    .DESCRIPTION
        This cmdlet renames an SDDC
    .EXAMPLE
        Set-VMCSDDC -SDDC $SDDCName -OrgName $OrgName -Name $NewSDDCName
    #>
    Param (
        [Parameter(Mandatory=$True)]$SDDCName,
        [Parameter(Mandatory=$True)]$OrgName,
        [Parameter(Mandatory=$True)]$Name
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        $sddc = Get-VMCSDDC -Org $OrgName -Name $SDDCName
        if($sddc) {
            $sddcService = Get-VmcService com.vmware.vmc.orgs.sddcs
            $renameSpec = $sddcService.help.patch.sddc_patch_request.Create()
            $renameSpec.name = $Name

            Write-Host "`nRenaming SDDC `'$SDDCName`' to `'$Name`' ...`n"
            $results = $sddcService.patch($sddc.org_id,$sddc.id,$renameSpec)
        }
    }
}

Function New-VMCPublicIP {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/12/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Request a new public IP Address for a given SDDC
    .DESCRIPTION
        This cmdlet requests a new public IP Address for a given SDDC
    .EXAMPLE
        New-VMCPublicIP -OrgName $OrgName -SDDCName $SDDCName -Description "Test for Randy"
#>
    Param (
        [Parameter(Mandatory=$True)]$OrgName,
        [Parameter(Mandatory=$True)]$SDDCName,
        [Parameter(Mandatory=$False)]$Description
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id

        $publicIPService = Get-VmcService "com.vmware.vmc.orgs.sddcs.publicips"

        $publicIPSpec = $publicIPService.Help.create.spec.Create()
        $publicIPSpec.count = 1
        $publicIPSpec.names = @($Description)

        Write-Host "Requesting a new public IP Address for your SDDC ..."
        $results = $publicIPService.create($orgId,$sddcId,$publicIPSpec)
    }
}

Function Remove-VMCPublicIP {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/12/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Removes a specific public IP Addresses for a given SDDC
    .DESCRIPTION
        This cmdlet removes a specific public IP Address for a given SDDC
    .EXAMPLE
        Remove-VMCPublicIP -OrgName $OrgName -SDDCName $SDDCName -AllocationId "eipalloc-0567acf34e436c01f"
#>
    Param (
        [Parameter(Mandatory=$True)]$OrgName,
        [Parameter(Mandatory=$True)]$SDDCName,
        [Parameter(Mandatory=$True)]$AllocationId
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id

        $publicIPService = Get-VmcService "com.vmware.vmc.orgs.sddcs.publicips"

        Write-Host "Deleting public IP Address with ID $AllocationId ..."
        $results = $publicIPService.delete($orgId,$sddcId,$AllocationId)
    }
}

Function Get-VMCEdge {
<#
.NOTES
===========================================================================
Created by:    Luc Dekens
Date:          23/10/2018
Organization:  Community
Blog:          http://lucd.info
Twitter:       @LucD22
===========================================================================

.SYNOPSIS
    Returns all the VMC Edges
.DESCRIPTION
    Returns all the VMC Edges
.EXAMPLE
    Get-VMCEdge -OrgName $orgName -SddcName $SDDCName -EdgeType gatewayServices
#>
    Param (
        [Parameter(Mandatory=$True)]
        [string]$OrgName,
        [Parameter(Mandatory=$True)]
        [string]$SDDCName,
        [ValidateSet('gatewayServices','distributedRouter')]
        [string]$EdgeType = ''
    )

    If (-Not $global:DefaultVMCServers) {
        Write-error "No VMC Connection found, please use the Connect-VMC to connect"
    }
    Else {
        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id

        $edgeService = Get-VmcService -Name 'com.vmware.vmc.orgs.sddcs.networks.edges'
        $index = [long]0
        $edges = do{
            $edgeData = $edgeService.get($orgId,$sddcId,$EdgeType,'',$index)
            $edgeData.edge_page.data | Sort-Object -Property id
            $index = $index + $edgeData.edge_page.paging_info.page_size    
        }
        until($index -ge $edgeData.paging_info.total_count)
        $edges | %{
            [pscustomobject]@{
                Name = $_.Name
                Id = $_.id
                Type = $_.edge_type
                State = $_.state
                Status = $_.edge_status
                VNics = $_.number_of_connected_vnics
                TenantId = $_.tenant_id
            }
        }
    }
}

Function Get-VMCEdgeStatus {
<#
.NOTES
===========================================================================
Created by:    Luc Dekens
Date:          23/10/2018
Organization:  Community
Blog:          http://lucd.info
Twitter:       @LucD22
===========================================================================

.SYNOPSIS
    Returns the status of the gateway
.DESCRIPTION
     Retrieve the status of the specified management or compute gateway (NSX Edge).
.EXAMPLE
    Get-VMCEdgeStatus -OrgName $orgName -SddcName $SDDCName -Edge $EdgeName
#>
    Param (
        [Parameter(Mandatory=$True)]
        [string]$OrgName,
        [Parameter(Mandatory=$True)]
        [string]$SDDCName,
        [Parameter(Mandatory=$True)]
        [string]$EdgeName
    )

    If (-Not $global:DefaultVMCServers) {
        Write-error "No VMC Connection found, please use the Connect-VMC to connect"
    }
    Else {
        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id
        $edgeId = Get-VMCEdge -SDDCName $SDDCName -Org $OrgName | where{$_.Name -eq $EdgeName} | select -ExpandProperty Id

        $statusService = Get-VmcService -Name 'com.vmware.vmc.orgs.sddcs.networks.edges.status'
        $status = $statusService.get($orgId,$sddcId,$edgeId)

        $vmStatus = $status.edge_vm_status | %{
            [pscustomobject]@{
                Name = $_.name
                State = $_.edge_VM_status
                HAState = $_.ha_state
                Index = $_.index
            }        
        }
        $featureStatus = $status.feature_statuses | %{
            [pscustomobject]@{
                Service = $_.service
                Status = $_.status
            }
        }
        [pscustomobject]@{
            Time = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($status.timestamp/1000))
            Status = $status.edge_status
            PublishStatus = $status.publish_status
            SystemStatus = $_.system_status
            NicInUse = $status.ha_vnic_in_use
        }
    }
}

Function Get-VMCEdgeNic {
<#
.NOTES
===========================================================================
Created by:    Luc Dekens
Date:          23/10/2018
Organization:  Community
Blog:          http://lucd.info
Twitter:       @LucD22
===========================================================================

.SYNOPSIS
    Returns all interfaces for the gateway
.DESCRIPTION
    Retrieve all interfaces for the specified management or compute gateway (NSX Edge).
.EXAMPLE
    Get-VMCEdgeNic -OrgName $orgName -SddcName $SDDCName -Edge $EdgeName
#>
    Param (
        [Parameter(Mandatory=$True)]
        [string]$OrgName,
        [Parameter(Mandatory=$True)]
        [string]$SDDCName,
        [Parameter(Mandatory=$True)]
        [string]$EdgeName
    )

    If (-Not $global:DefaultVMCServers) {
        Write-error "No VMC Connection found, please use the Connect-VMC to connect"
    }
    Else {
        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id
        $edgeId = Get-VMCEdge -SDDCName $SDDCName -Org $OrgName | where{$_.Name -eq $EdgeName} | select -ExpandProperty Id

        $vnicService = Get-VmcService -Name 'com.vmware.vmc.orgs.sddcs.networks.edges.vnics'
        $vnicService.get($orgId,$sddcId,$edgeId) | select -ExpandProperty vnics | %{
            [pscustomobject]@{
                Label = $_.label
                Name = $_.Name
                Type = $_.type
                Index = $_.index
                IsConnected = $_.is_connected
                Portgroup = $_.portgroup_name
            }
        }
    }
}

Function Get-VMCEdgeNicStat {
<#
.NOTES
===========================================================================
Created by:    Luc Dekens
Date:          23/10/2018
Organization:  Community
Blog:          http://lucd.info
Twitter:       @LucD22
===========================================================================

.SYNOPSIS
    Returns statistics for the gateway interfaces
.DESCRIPTION
     Retrieve interface statistics for a management or compute gateway (NSX Edge).
.EXAMPLE
    Get-VMCEdgeNicStat -OrgName $orgName -SddcName $SDDCName -Edge $EdgeName
#>
    [CmdletBinding(DefaultParameterSetName='Default')]
    Param (
        [Parameter(Mandatory=$True)]
        [string]$OrgName,
        [Parameter(Mandatory=$True)]
        [string]$SDDCName,
        [Parameter(Mandatory=$True)]
        [string]$EdgeName
#        [DateTime]$Start,
#        [DateTime]$Finish
    )

    If (-Not $global:DefaultVMCServers) {
        Write-error "No VMC Connection found, please use the Connect-VMC to connect"
    }
    Else {
        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id
        $edgeId = Get-VMCEdge -SDDCName $SDDCName -Org $OrgName | where{$_.Name -eq $EdgeName} | select -ExpandProperty Id

#        $epoch = Get-Date 01/01/1970
#        
#        if($start){
#            $startEpoch = (New-TimeSpan -Start $epoch -End $Start.ToUniversalTime()).TotalMilliseconds
#        }
#        if($Finish){
#            $finishEpoch = (New-TimeSpan -Start $epoch -End $Finish.ToUniversalTime()).TotalMilliseconds
#        }

        $vnicStatService = Get-VmcService -Name 'com.vmware.vmc.orgs.sddcs.networks.edges.statistics.interfaces'
#        $stats = $vnicStatService.get($orgId,$sddcId,$edgeId,[long]$startEpoch,[long]$finishEpoch)
        $stats = $vnicStatService.get($orgId,$sddcId,$edgeId)

        $stats.data_dto | Get-Member -MemberType NoteProperty | where{$_.Name -ne 'Help'} | %{$_.Name} | %{
            $stats.data_dto."$_" | %{
                [pscustomobject]@{
                    vNIC = $_.vnic
                    Timestamp = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.timestamp))
                    In = $_.in
                    Out = $_.out
                    Unit = 'Kbps'
                    Interval = $stats.meta_dto.interval
                }
            }
        }
    }
}

Function Get-VMCEdgeUplinkStat {
<#
.NOTES
===========================================================================
Created by:    Luc Dekens
Date:          23/10/2018
Organization:  Community
Blog:          http://lucd.info
Twitter:       @LucD22
===========================================================================

.SYNOPSIS
    Returns statistics for the uplink interfaces
.DESCRIPTION
     Retrieve uplink interface statistics for a management or compute gateway (NSX Edge).
.EXAMPLE
    Get-VMCEdgeUplinkStat -OrgName $orgName -SddcName $SDDCName -Edge $EdgeName
#>
    Param (
        [Parameter(Mandatory=$True)]
        [string]$OrgName,
        [Parameter(Mandatory=$True)]
        [string]$SDDCName,
        [Parameter(Mandatory=$True)]
        [string]$EdgeName
#        [DateTime]$Start,
#        [DateTime]$Finish
    )

    If (-Not $global:DefaultVMCServers) {
        Write-error "No VMC Connection found, please use the Connect-VMC to connect"
    }
    Else {
        $orgId = (Get-VMCOrg -Name $OrgName).Id
        $sddcId = (Get-VMCSDDC -Name $SDDCName -Org $OrgName).Id
        $edgeId = Get-VMCEdge -SDDCName $SDDCName -Org $OrgName | where{$_.Name -eq $EdgeName} | select -ExpandProperty Id

#        $epoch = Get-Date 01/01/1970
#        
#        if($start){
#            $startEpoch = (New-TimeSpan -Start $epoch -End $Start.ToUniversalTime()).TotalMilliseconds
#        }
#        if($Finish){
#            $finishEpoch = (New-TimeSpan -Start $epoch -End $Finish.ToUniversalTime()).TotalMilliseconds
#        }

        $uplinkStatService = Get-VmcService -Name 'com.vmware.vmc.orgs.sddcs.networks.edges.statistics.interfaces.uplink'
#        $stats = $uplinkStatService.get($orgId,$sddcId,$edgeId,[long]$startEpoch,[long]$finishEpoch)
        $stats = $uplinkStatService.get($orgId,$sddcId,$edgeId)

        $stats.data_dto | Get-Member -MemberType NoteProperty | where{$_.Name -ne 'Help'} | %{$_.Name} | %{
            if($stats.data_dto."$_".Count -ne 0){
                $stats.data_dto."$_" | %{
                    [pscustomobject]@{
                        vNIC = $_.vnic
                        Timestamp = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.timestamp))
                        In = $_.in
                        Out = $_.out
                        Unit = 'Kbps'
                        Interval = $stats.meta_dto.interval
                    }
                }
            }
        }
    }
}
Function New-VMCSDDCCluster {
    <#
        .NOTES
        ===========================================================================
        Created by:     Kyle Ruddy
        Date:          03/16/2019
        Organization: 	VMware
        Blog:          https://www.kmruddy.com
        Twitter:       @kmruddy
        ===========================================================================
    
        .SYNOPSIS
            Creates a new cluster for the designated SDDC
        .DESCRIPTION
            Creates a new cluster
        .EXAMPLE
            New-VMCSDDCCluster -OrgName <Org Name> -SDDCName <SDDC Name> -HostCount 1 -CPUCoreCount 8
    #>
        [cmdletbinding(SupportsShouldProcess = $true,ConfirmImpact='High')]
        param(
            [Parameter(Mandatory=$true)][String]$OrgName,
            [Parameter(Mandatory=$true)][String]$SDDCName,
            [Parameter(Mandatory=$true)][Int]$HostCount,
            [Parameter(Mandatory=$true)][ValidateSet("8","16","32")]$CPUCoreCount
        )

        if (-not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect"; break }

        $orgId = Get-VMCOrg -Name $OrgName | Select-Object -ExpandProperty Id
        $sddcId = Get-VMCSDDC -Name $SDDCName -Org $OrgName | Select-Object -ExpandProperty Id

        if(-not $orgId) {
            Write-Host -ForegroundColor red "Unable to find Org $OrgName, please verify input"
            break
        }
        if(-not $sddcId) {
            Write-Host -ForegroundColor red "Unable to find SDDC $SDDCName, please verify input"
            break
        }

        $sddcClusterSvc = Get-VmcService -Name com.vmware.vmc.orgs.sddcs.clusters

        $sddcClusterCreateSpec = $sddcClusterSvc.Help.create.cluster_config.Create()
        $sddcClusterCreateSpec.host_cpu_cores_count = $CPUCoreCount
        $sddcClusterCreateSpec.num_hosts = $HostCount

        $sddcClusterTask = $sddcClusterSvc.Create($org.Id, $sddc.Id, $sddcClusterCreateSpec)
        $sddcClusterTask | Select-Object Id,Task_Type,Status,Created | Format-Table
}
Function Get-VMCSDDCCluster {
    <#
        .NOTES
        ===========================================================================
        Created by:     Kyle Ruddy
        Date:          03/16/2019
        Organization: 	VMware
        Blog:          https://www.kmruddy.com
        Twitter:       @kmruddy
        ===========================================================================
    
        .SYNOPSIS
            Retreives cluster information for the designated SDDC
        .DESCRIPTION
            Lists cluster information for an SDDC
        .EXAMPLE
            Get-VMCSDDCCluster -OrgName <Org Name> -SDDCName <SDDC Name> -HostCount 1 -CPUCoreCount 8
    #>
        [cmdletbinding(SupportsShouldProcess = $true,ConfirmImpact='Low')]
        param(
            [Parameter(Mandatory=$true)][String]$OrgName,
            [Parameter(Mandatory=$true)][String]$SddcName
        )

        if (-not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect"; break }

        $orgId = Get-VMCOrg -Name $OrgName | Select-Object -ExpandProperty Id
        $sddcId = Get-VMCSDDC -Name $SDDCName -Org $OrgName | Select-Object -ExpandProperty Id

        if(-not $orgId) {
            Write-Host -ForegroundColor red "Unable to find Org $OrgName, please verify input"
            break
        }
        if(-not $sddcId) {
            Write-Host -ForegroundColor red "Unable to find SDDC $SDDCName, please verify input"
            break
        }

        $clusterOutput = @()
        $sddcClusters = Get-VMCSDDC -Org $OrgName -Name $SDDCName | Select-Object -ExpandProperty resource_config | Select-Object -ExpandProperty clusters
        foreach ($c in $sddcClusters) {
            $tempCluster = "" | Select-Object Id, Name, State
            $tempCluster.Id = $c.cluster_id
            $tempCluster.Name = $c.cluster_name
            $tempCluster.State = $c.cluster_state
            $clusterOutput += $tempCluster
        }
        return $clusterOutput
}
Function New-VMCSDDCCluster {
    <#
        .NOTES
        ===========================================================================
        Created by:     Kyle Ruddy
        Date:          03/16/2019
        Organization: 	VMware
        Blog:          https://www.kmruddy.com
        Twitter:       @kmruddy
        ===========================================================================
    
        .SYNOPSIS
            Creates a new cluster for the designated SDDC
        .DESCRIPTION
            Creates a new cluster
        .EXAMPLE
            New-VMCSDDCCluster -OrgName <Org Name> -SDDCName <SDDC Name> -HostCount 1 -CPUCoreCount 8
    #>
        [cmdletbinding(SupportsShouldProcess = $true,ConfirmImpact='High')]
        param(
            [Parameter(Mandatory=$true)][String]$OrgName,
            [Parameter(Mandatory=$true)][String]$SddcName,
            [Parameter(Mandatory=$true)][Int]$HostCount,
            [Parameter(Mandatory=$false)][ValidateSet("8","16","36","48")]$CPUCoreCount
        )

        if (-not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect"; break }

        $orgId = Get-VMCOrg -Name $OrgName | Select-Object -ExpandProperty Id
        $sddcId = Get-VMCSDDC -Name $SDDCName -Org $OrgName | Select-Object -ExpandProperty Id

        if(-not $orgId) {
            Write-Host -ForegroundColor red "Unable to find Org $OrgName, please verify input"
            break
        }
        if(-not $sddcId) {
            Write-Host -ForegroundColor red "Unable to find SDDC $SDDCName, please verify input"
            break
        }

        $sddcClusterSvc = Get-VmcService -Name com.vmware.vmc.orgs.sddcs.clusters

        $sddcClusterCreateSpec = $sddcClusterSvc.Help.create.cluster_config.Create()
        $sddcClusterCreateSpec.host_cpu_cores_count = $CPUCoreCount
        $sddcClusterCreateSpec.num_hosts = $HostCount

        $sddcClusterTask = $sddcClusterSvc.Create($org.Id, $sddc.Id, $sddcClusterCreateSpec)
        $sddcClusterTask | Select-Object Id,Task_Type,Status,Created | Format-Table
}
Function Remove-VMCSDDCCluster {
    <#
        .NOTES
        ===========================================================================
        Created by:     Kyle Ruddy
        Date:          03/16/2019
        Organization: 	VMware
        Blog:          https://www.kmruddy.com
        Twitter:       @kmruddy
        ===========================================================================
    
        .SYNOPSIS
            Removes a specified cluster from the designated SDDC
        .DESCRIPTION
            Deletes a cluster from an SDDC
        .EXAMPLE
            Remove-VMCSDDCCluster -OrgName <Org Name> -SDDCName <SDDC Name> -Cluster <Cluster Name>
    #>
        [cmdletbinding(SupportsShouldProcess = $true,ConfirmImpact='High')]
        param(
            [Parameter(Mandatory=$true)][String]$OrgName,
            [Parameter(Mandatory=$true)][String]$SDDCName,
            [Parameter(Mandatory=$true)][String]$ClusterName
        )

        if (-not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect"; break }

        $orgId = Get-VMCOrg -Name $OrgName | Select-Object -ExpandProperty Id
        $sddcId = Get-VMCSDDC -Name $SDDCName -Org $OrgName | Select-Object -ExpandProperty Id
        $clusterId = Get-VMCSDDCCluster -SddcName $SDDCName -OrgName $OrgName | Where-Object {$_.Name -eq $ClusterName} | Select-Object -ExpandProperty Id

        if(-not $orgId) {
            Write-Host -ForegroundColor red "Unable to find Org $OrgName, please verify input"
            break
        }
        if(-not $sddcId) {
            Write-Host -ForegroundColor red "Unable to find SDDC $SDDCName, please verify input"
            break
        }
        if(-not $clusterId) {
            Write-Host -ForegroundColor red "Unable to find cluster $ClusterName, please verify input"
            break
        }

        $sddcClusterTask = $sddcClusterSvc.Delete($orgId, $sddcId, $clusterId)
        $sddcClusterTask | Select-Object Id,Task_Type,Status,Created | Format-Table
}

Export-ModuleMember -Function 'Get-VMCCommand', 'Connect-VMCVIServer', 'Get-VMCOrg', 'Get-VMCSDDC',
    'Get-VMCTask', 'Get-VMCSDDCDefaultCredential', 'Get-VMCSDDCPublicIP', 'Get-VMCVMHost',
    'Get-VMCSDDCVersion', 'Get-VMCFirewallRule', 'Export-VMCFirewallRule', 'Import-VMCFirewallRule',
    'Remove-VMCFirewallRule', 'Get-VMCLogicalNetwork', 'Remove-VMCLogicalNetwork', 'New-VMCLogicalNetwork',
    'Get-VMCSDDCSummary', 'Get-VMCPublicIP', 'New-VMCPublicIP', 'Remove-VMCPublicIP', 'Set-VMCSDDC',
    'Get-VMCEdge', 'Get-VMCEdgeNic', 'Get-VMCEdgeStatus', 'Get-VMCEdgeNicStat', 'Get-VMCEdgeUplinkStat',
    'Get-VMCSDDCCluster', 'New-VMCSDDCCluster', 'Remove-VMCSDDCCluster'