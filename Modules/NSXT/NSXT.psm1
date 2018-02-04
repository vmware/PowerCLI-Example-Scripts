Function Get-NSXTController {
    Param (
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$Id
    )

    $clusterNodeService = Get-NsxtService -Name "com.vmware.nsx.cluster.nodes"
    $clusterNodeStatusService = Get-NsxtService -Name "com.vmware.nsx.cluster.nodes.status"
    if($Id) {
        $nodes = $clusterNodeService.get($Id)
    } else {
        $nodes = $clusterNodeService.list().results | where { $_.manager_role -eq $null }
    }
    
    $results = @()
    foreach ($node in $nodes) {
        $nodeId = $node.id
        $nodeName = $node.controller_role.control_plane_listen_addr.ip_address
        $nodeStatusResults = $clusterNodeStatusService.get($nodeId)

        $tmp = [pscustomobject] @{
            Id = $nodeId;
            Name = $nodeName;
            ClusterStatus = $nodeStatusResults.control_cluster_status.control_cluster_status;
            Version = $nodeStatusResults.version;

        }
        $results+=$tmp
    }
    $results
}

Function Get-NSXTFabricNode {
    Param (
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$Id,
        [Switch]$ESXi,
        [Switch]$Edge
    )

    $fabricNodeService = Get-NsxtService -Name "com.vmware.nsx.fabric.nodes"
    $fabricNodeStatusService = Get-NsxtService -Name "com.vmware.nsx.fabric.nodes.status"
    if($Id) {
        $nodes = $fabricNodeService.get($Id)
    } else {
        if($ESXi) {
            $nodes = $fabricNodeService.list().results | where { $_.resource_type -eq "HostNode" }
        } elseif ($Edge) {
            $nodes = $fabricNodeService.list().results | where { $_.resource_type -eq "EdgeNode" }
        } else {
            $nodes = $fabricNodeService.list().results
        }
    }

    $results = @()
    foreach ($node in $nodes) {
        $nodeStatusResult = $fabricNodeStatusService.get($node.id)

        $tmp = [pscustomobject] @{
            Id = $node.id;
            Name = $node.display_name;
            Type = $node.resource_type;
            Address = $node.ip_addresses;
            NSXVersion = $nodeStatusResult.software_version
            OS = $node.os_type;
            Version = $node.os_version;
            Status = $nodeStatusResult.host_node_deployment_status
            ManagerStatus = $nodeStatusResult.mpa_connectivity_status
            ControllerStatus = $nodeStatusResult.lcp_connectivity_status           
        }
        $results+=$tmp
    }
    $results
}

Function Get-NSXTIPPool {
    Param (
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$Id
    )

    $ipPoolService = Get-NsxtService -Name "com.vmware.nsx.pools.ip_pools"

    if($Id) {
        $ipPools = $ipPoolService.get($Id)
    } else {
        $ipPools = $ipPoolService.list().results
    }

    $results = @()
    foreach ($ipPool in $ipPools) {
        $tmp = [pscustomobject] @{
            Id = $ipPool.Id;
            Name = $ipPool.Display_Name;
            Total = $ipPool.pool_usage.total_ids;
            Free = $ipPool.pool_usage.free_ids;
            Network = $ipPool.subnets.cidr;
            Gateway = $ipPool.subnets.gateway_ip;
            DNS = $ipPool.subnets.dns_nameservers;
            RangeStart = $ipPool.subnets.allocation_ranges.start;
            RangeEnd = $ipPool.subnets.allocation_ranges.end
        }
        $results+=$tmp
    }
    $results
}

Function Get-NSXTTransportZone {
    Param (
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$Id
    )

    $transportZoneService = Get-NsxtService -Name "com.vmware.nsx.transport_zones"

    if($Id) {
        $transportZones = $transportZoneService.get($Id)
    } else {
        $transportZones = $transportZoneService.list().results
    }

    $results = @()
    foreach ($transportZone in $transportZones) {
        $tmp = [pscustomobject] @{
            Id = $transportZone.Id;
            Name = $transportZone.display_name;
            Type = $transportZone.transport_type;
            HostSwitchName = $transportZone.host_switch_name;
        }
        $results+=$tmp
    }
    $results
}

Function Get-NSXTComputeManager {
    Param (
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$Id
    )

    $computeManagerSerivce = Get-NsxtService -Name "com.vmware.nsx.fabric.compute_managers"
    $computeManagerStatusService = Get-NsxtService -Name "com.vmware.nsx.fabric.compute_managers.status"

    if($Id) {
        $computeManagers = $computeManagerSerivce.get($id)
    } else {
        $computeManagers = $computeManagerSerivce.list().results
    }

    $results = @()
    foreach ($computeManager in $computeManagers) {
        $computeManagerStatus = $computeManagerStatusService.get($computeManager.Id)

        $tmp = [pscustomobject] @{
            Id = $computeManager.Id;
            Name = $computeManager.display_name;
            Server = $computeManager.server
            Type = $computeManager.origin_type;
            Version = $computeManagerStatus.Version;
            Registration = $computeManagerStatus.registration_status;
            Connection = $computeManagerStatus.connection_status;
        }
        $results+=$tmp
    }
    $results
}

Function Get-NSXTLogicalSwitch {
    Param (
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$Id
    )

    $logicalSwitchService = Get-NsxtService -Name "com.vmware.nsx.logical_switches"
    $logicalSwitchSummaryService = Get-NsxtService -Name "com.vmware.nsx.logical_switches.summary"

    if($Id) {
        $logicalSwitches = $logicalSwitchService.get($Id)
    } else {
        $logicalSwitches = $logicalSwitchService.list().results
    }

    $results = @()
    foreach ($logicalSwitch in $logicalSwitches) {
        $transportZone = (Get-NSXTTransportZone -Id $logicalSwitch.transport_zone_id | Select Name | ft -HideTableHeaders | Out-String).trim()
        $ports = $logicalSwitchSummaryService.get($logicalSwitch.id).num_logical_ports

        $tmp = [pscustomobject] @{
            Id = $logicalSwitch.Id;
            Name = $logicalSwitch.display_name;
            VLAN = $logicalSwitch.vlan;
            AdminStatus = $logicalSwitch.admin_state;
            Ports = $ports;
            TransportZone = $transportZone;
        }
        $results+=$tmp
    }
    $results
}

Function Get-NSXTFirewallRule {
    Param (
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$Id
    )

    $firewallService = Get-NsxtService -Name "com.vmware.nsx.firewall.sections"
    $firewallRuleService = Get-NsxtService -Name "com.vmware.nsx.firewall.sections.rules"

    if($Id) {
        $firewallRuleSections = $firewallService.get($Id)
    } else {
        $firewallRuleSections = $firewallService.list().results
    }

    $sectionResults = @()
    foreach ($firewallRuleSection in $firewallRuleSections) {
        $tmp = [pscustomobject] @{
            Id = $firewallRuleSection.Id;
            Name = $firewallRuleSection.display_name;
            Type = $firewallRuleSection.section_type;
            Stateful = $firewallRuleSection.stateful;
            RuleCount = $firewallRuleSection.rule_count;
        }
        $sectionResults+=$tmp
    }
    $sectionResults

    $firewallResults = @()
    if($id) {
        $firewallRules = $firewallRuleService.list($id).results
        foreach ($firewallRule in $firewallRules) {
            $tmp = [pscustomobject] @{
                Id = $firewallRule.id;
                Name = $firewallRule.display_name;
                Sources = if($firewallRule.sources -eq $null) { "ANY" } else { $firewallRule.sources};
                Destination = if($firewallRule.destinations -eq $null) { "ANY" } else { $firewallRule.destinations };
                Services = if($firewallRule.services -eq $null) { "ANY" } else { $firewallRule.services } ;
                Action = $firewallRule.action;
                AppliedTo = if($firewallRule.applied_tos -eq $null) { "ANY" } else { $firewallRule.applied_tos };
                Log = $firewallRule.logged;
            }
            $firewallResults+=$tmp
        }
    }
    $firewallResults
}

Function Get-NSXTManager {
    $clusterNodeService = Get-NsxtService -Name "com.vmware.nsx.cluster.nodes"

    $nodes = $clusterNodeService.list().results

    $results = @()
    foreach ($node in $nodes) {
        if($node.manager_role -ne $null) {
            $tmp = [pscustomobject] @{
                Id = $node.id;
                Name = $node.display_name;
                Address = $node.appliance_mgmt_listen_addr;
                SHA256Thumbprint = $node.manager_role.api_listen_addr.certificate_sha256_thumbprint;
            }
            $results+=$tmp
        }
    }
    $results
}