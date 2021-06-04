<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
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

# Updated Function style below

Function Get-NSXTTransportNode {
  <#
    .Synopsis
       Retrieves the transport_node information
    .DESCRIPTION
       Retrieves transport_node information for a single or multiple IDs. Execute with no parameters to get all ports, specify a transport_node if known.
    .EXAMPLE
       Get-NSXTTransportNode
    .EXAMPLE
       Get-NSXTThingTemplate -Tranport_node_id "TN ID"
#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id","Tranportnode_id")]
        [string]$transport_node_id
    )

    begin
    {
        $NSXTransportNodesService = Get-NsxtService -Name "com.vmware.nsx.transport_nodes"

        class NSXTransportNode {
            [string]$Name
            [string]$Transport_node_id
            [string]$maintenance_mode
            hidden $tags = [System.Collections.Generic.List[string]]::new()
            hidden $host_switches = [System.Collections.Generic.List[string]]::new()
            hidden [string]$host_switch_spec
            hidden $transport_zone_endpoints = [System.Collections.Generic.List[string]]::new()
        }
    }

    Process
    {
        if($transport_node_id) {
            $NSXTransportNodes = $NSXTransportNodesService.get($transport_node_id)
        } else {
            $NSXTransportNodes = $NSXTransportNodesService.list().results
        }

        foreach ($NSXTransportNode in $NSXTransportNodes) {

            $results = [NSXTransportNode]::new()
            $results.Name = $NSXTransportNode.display_name;
            $results.Transport_node_id = $NSXTransportNode.Id;
            $results.maintenance_mode = $NSXTransportNode.maintenance_mode;
            $results.Tags = $NSXTransportNode.tags;
            $results.host_switches = $NSXTransportNode.host_switches;
            $results.host_switch_spec = $NSXTransportNode.host_switch_spec;
            $results.transport_zone_endpoints = $NSXTransportNode.transport_zone_endpoints;
            $results.host_switches = $NSXTransportNode.host_switches
            $results
        }
    }
}

Function Get-NSXTTraceFlow {
  <#
    .Synopsis
       Retrieves traceflow information
    .DESCRIPTION
       Retrieves traceflow information for a single or multiple traceflows. Execute with no parameters to get all traceflows, specify a traceflow_id if known.
    .EXAMPLE
       Get-NSXTTraceFlow
    .EXAMPLE
       Get-NSXTTraceFlow -traceflow_id "TF ID
#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [Alias("Id")]
        [string]$traceflow_id
    )

    $NSXTraceFlowsService = Get-NsxtService -Name "com.vmware.nsx.traceflows"

    if($traceflow_id) {
        $NSXTraceFlows = $NSXTraceFlowsService.get($traceflow_id)
    } else {
        $NSXTraceFlows = $NSXTraceFlowsService.list().results
    }

    class NSXTraceFlow {
        [string]$traceflow_id
        hidden [string]$lport_id
        [string]$Operation_State
        [int]$Forwarded
        [int]$Delivered
        [int]$Received
        [int]$Dropped
        [string]$Analysis
    }

    foreach ($NSXTraceFlow in $NSXTraceFlows) {

        $results = [NSXTraceFlow]::new()
        $results.traceflow_id = $NSXTraceFlow.Id;
        $results.Operation_State = $NSXTraceFlow.operation_state;
        $results.forwarded = $NSXTraceFlow.Counters.forwarded_count;
        $results.delivered = $NSXTraceFlow.Counters.delivered_count;
        $results.received = $NSXTraceFlow.Counters.received_count;
        $results.dropped = $NSXTraceFlow.Counters.dropped_count;
        $results.analysis = $NSXTraceFlow.analysis
         $results
    }
}

Function Get-NSXTTraceFlowObservations {
  <#
    .Synopsis
       Retrieves traceflow observations information
    .DESCRIPTION
       Retrieves traceflow observations information for a single traceflow. Must specify a current traceflow_id
    .EXAMPLE
        Get-NSXTTraceFlowObservations -traceflow_id "TF ID"
    .EXAMPLE
       Get-NSXTTraceFlow | Get-NSXTTraceFlowObservations
#>

    Param (
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$traceflow_id
    )

    begin
    {
        $NSXTraceFlowsObservService = Get-NsxtService -Name "com.vmware.nsx.traceflows.observations"
    }

    Process
    {
        if($traceflow_id) {
            $NSXTraceFlowsObserv = $NSXTraceFlowsObservService.list($traceflow_id)
        } else {
            throw "TraceFlow ID required"
        }

        $NSXTraceFlowsObserv.results | select transport_node_name,component_name,@{N='PacketEvent';E={($_.resource_type).TrimStart("TraceflowObservation")}}
    }
}

Function Get-NSXTEdgeCluster {
  <#
    .Synopsis
       Retrieves the Edge cluster information
    .DESCRIPTION
       Retrieves Edge cluster information for a single or multiple clusterss. Execute with no parameters to get all ports, specify a edge_cluster_id if known.
    .EXAMPLE
       Get-NSXTEdgeCluster
    .EXAMPLE
       Get-NSXTEdgeCluster -edge_cluster_id "Edge Cluster ID"
    .EXAMPLE
       Get-NSXTThingTemplate | where name -eq "My Edge Cluster Name"
#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$edge_cluster_id
    )

    Begin
    {
        $NSXTEdgeClustersService = Get-NsxtService -Name "com.vmware.nsx.edge_clusters"

        class NSXEdgeCluster {
            [string]$Name
            hidden [string]$Protection
            hidden [string]$Tags
            [string]$edge_cluster_id
            [string]$resource_type
            [string]$deployment_type
            [string]$member_node_type
            $members = [System.Collections.Generic.List[string]]::new()
            $cluster_profile_bindings = [System.Collections.Generic.List[string]]::new()
        }
    }

    Process
    {
        if ($edge_cluster_id) {
            $NSXEdgeClusters = $NSXTEdgeClustersService.get($edge_cluster_id)
        }
        else {
            $NSXEdgeClusters = $NSXTEdgeClustersService.list().results
        }

        foreach ($NSXEdgeCluster in $NSXEdgeClusters) {

            $results = [NSXEdgeCluster]::new()
            $results.Name = $NSXEdgeCluster.display_name;
            $results.Protection = $NSXEdgeCluster.Protection;
            $results.edge_cluster_id = $NSXEdgeCluster.Id;
            $results.resource_type = $NSXEdgeCluster.resource_type;
            $results.Tags = $NSXEdgeCluster.tags;
            $results.deployment_type = $NSXEdgeCluster.deployment_type;
            $results.member_node_type = $NSXEdgeCluster.member_node_type;
            $results.members = $NSXEdgeCluster.members;
            $results.cluster_profile_bindings = $NSXEdgeCluster.cluster_profile_bindings
             $results
        }
    }
}

Function Get-NSXTLogicalRouter {
  <#
    .Synopsis
       Retrieves the Logical Router information
    .DESCRIPTION
       Retrieves Logical Router information for a single or multiple LR's. This includes corresponding SR's and transport_node_id. Execute with no parameters to get all ports, specify a Logical_router_id if known.
    .EXAMPLE
       Get-NSXTLogicalRouter
    .EXAMPLE
       Get-NSXTLogicalRouter -Logical_router_id "LR ID"
    .EXAMPLE
       Get-NSXTLogicalRouter | where name -eq "LR Name"
    .EXAMPLE
       (Get-NSXTLogicalRouter -Logical_router_id "LR ID").per_node_status
#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$Logical_router_id
    )

    begin
    {
        $NSXTLogicalRoutersService = Get-NsxtService -Name "com.vmware.nsx.logical_routers"
        $NSXTLogicalRoutersStatusService = Get-NsxtService -Name "com.vmware.nsx.logical_routers.status"

        class per_node_status {
            $service_router_id
            [ValidateSet("ACTIVE","STANDBY","DOWN","SYNC","UNKNOWN")]
            $high_availability_status
            $transport_node_id

            per_node_status(){}

            per_node_status(
                $service_router_id,
                $high_availability_status,
                $transport_node_id
            ) {
                $this.service_router_id = $service_router_id
                $this.high_availability_status = $high_availability_status
                $this.transport_node_id = $transport_node_id
            }
        }

        class NSXTLogicalRouter {
            [string]$Name
            [string]$Logical_router_id
            [string]$protection
            hidden [string]$Tags
            [string]$edge_cluster_id
            [ValidateSet("TIER0","TIER1")]
            [string]$router_type
            [ValidateSet("ACTIVE_ACTIVE","ACTIVE_STANDBY","")]
            [string]$high_availability_mode
            [ValidateSet("PREEMPTIVE","NON_PREEMPTIVE","")]
            [string]$failover_mode
            [string]$external_transit
            [string]$internal_transit
            hidden [string]$advanced_config = [System.Collections.Generic.List[string]]::new()
            hidden [string]$firewall_sections = [System.Collections.Generic.List[string]]::new()
            $per_node_status = [System.Collections.Generic.List[string]]::new()
        }
    }

    Process
    {
        if($Logical_router_id) {
            $NSXLogicalRouters = $NSXTLogicalRoutersService.get($Logical_router_id)
        } else {
            $NSXLogicalRouters = $NSXTLogicalRoutersService.list().results
        }

        foreach ($NSXLogicalRouter in $NSXLogicalRouters) {

            $NSXTLogicalRoutersStatus = $NSXTLogicalRoutersStatusService.get($NSXLogicalRouter.id)
            $results = [NSXTLogicalRouter]::new()

            foreach ($NSXTLogicalRouterStatus in $NSXTLogicalRoutersStatus.per_node_status) {
                $results.per_node_status += [per_node_status]::new($NSXTLogicalRouterStatus.service_router_id,$NSXTLogicalRouterStatus.high_availability_status,$NSXTLogicalRouterStatus.transport_node_id)
            }

            $results.Name = $NSXLogicalRouter.display_name;
            $results.Logical_router_id = $NSXLogicalRouter.Id;
            $results.protection = $NSXLogicalRouter.protection;
            $results.Tags = $NSXLogicalRouter.tags;
            $results.edge_cluster_id = $NSXLogicalRouter.edge_cluster_id;
            $results.router_type = $NSXLogicalRouter.router_type;
            $results.high_availability_mode = $NSXLogicalRouter.high_availability_mode;
            $results.failover_mode =$NSXLogicalRouter.failover_mode;
            $results.external_transit = $NSXLogicalRouter.advanced_config.external_transit_networks;
            $results.internal_transit = $NSXLogicalRouter.advanced_config.internal_transit_network;
            $results.advanced_config =$NSXLogicalRouter.advanced_config;
            $results.firewall_sections =$NSXLogicalRouter.firewall_sections
             $results
        }
    }
}

Function Get-NSXTRoutingTable {
  <#
    .Synopsis
       Retrieves the routing table information
    .DESCRIPTION
       Retrieves routing table for a single LR including LR type (SR/DR) and next_hop. Must specify Logical_router_id & transport_node_id. Pipeline input supported.
    .EXAMPLE
       Get-NSXTRoutingTable -Logical_router_id "LR ID" -transport_node_id "TN ID" | format-table -autosize
    .EXAMPLE
       Get-NSXTLogicalRouter | where name -eq "LR Name" | Get-NSXTRoutingTable -transport_node_id "TN ID"
    .EXAMPLE
       Get-NSXTLogicalRouter | where name -eq INT-T1 | Get-NSXTRoutingTable -transport_node_id ((Get-NSXTTransportNode | where name -match "INT")[0].transport_node_id)
    .EXAMPLE
       Get-NSXTLogicalRouter | where name -eq INT-T1 | Get-NSXTRoutingTable -transport_node_id (((Get-NSXTLogicalRouter | where name -eq INT-T1).per_node_status | where high_availability_status -eq ACTIVE).transport_node_id)
#>

    Param (
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Logical_router_id,
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$transport_node_id
    )

    Begin
    {
        $NSXTRoutingTableService = Get-NsxtService -Name "com.vmware.nsx.logical_routers.routing.route_table"

    class NSXTRoutingTable {
            hidden [string]$Logical_router_id
            [string]$lr_component_id
            [string]$lr_component_type
            [string]$network
            [string]$next_hop
            [string]$route_type
            hidden [string]$logical_router_port_id
            [long]$admin_distance
    }
    }

    Process
    {
        $NSXTRoutingTable = $NSXTRoutingTableService.list($Logical_router_id,$transport_node_id,$null,$null,$null,$null,$null,'realtime')

        foreach ($NSXTRoute in $NSXTRoutingTable.results) {

            $results = [NSXTRoutingTable]::new()
            $results.Logical_router_id = $Logical_router_id;
            $results.lr_component_type = $NSXTRoute.lr_component_type;
            $results.lr_component_id = $NSXTRoute.lr_component_id;
            $results.next_hop = $NSXTRoute.next_hop;
            $results.route_type = $NSXTRoute.route_type;
            $results.logical_router_port_id = $NSXTRoute.logical_router_port_id;
            $results.admin_distance = $NSXTRoute.admin_distance;
            $results.network = $NSXTRoute.network
            $results
        }
    }
}

Function Get-NSXTFabricVM {
 <#
    .Synopsis
       Retrieves the VM's attached to the fabric.
    .DESCRIPTION
       Retrieves all VM's attached to the fabric.
    .EXAMPLE
       Get-NSXTFabricVM
#>
    Begin
    {
        $NSXTVMService = Get-NsxtService -Name "com.vmware.nsx.fabric.virtual_machines"

        class NSXVM {
            [string]$Name
            $resource_type
            hidden [string]$Tags
            hidden $compute_ids
            hidden [string]$external_id
            [string]$host_id
            [string]$power_state
            [string]$type
            hidden $source
        }
    }

    Process
    {

        $NSXTVMs = $NSXTVMService.list().results

        foreach ($NSXTVM in $NSXTVMs) {

            $results = [NSXVM]::new()
            $results.Name = $NSXTVM.display_name;
            $results.resource_type = $NSXTVM.resource_type;
            $results.compute_ids = $NSXTVM.compute_ids;
            $results.resource_type = $NSXTVM.resource_type;
            $results.Tags = $NSXTVM.tags;
            $results.external_id = $NSXTVM.external_id;
            $results.host_id = $NSXTVM.host_id;
            $results.power_state = $NSXTVM.power_state;
            $results.type = $NSXTVM.type;
            $results.source = $NSXTVM.source
             $results
        }
    }
}

Function Get-NSXTBGPNeighbors {
  <#
    .Synopsis
       Retrieves the BGP neighbor information
    .DESCRIPTION
       Retrieves BGP neighbor information for a single logical router. Must specify logical_router_id parameter. Pipeline input supported
    .EXAMPLE
       Get-NSXTBGPNeighbors -logical_router_id "LR ID"
    .EXAMPLE
       Get-NSXTLogicalRouter | where name -eq "LR Name" | Get-NSXTBGPNeighbors
#>

    Param (
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$logical_router_id
    )

    begin
    {
        $NSXTThingsService = Get-NsxtService -Name "com.vmware.nsx.logical_routers.routing.bgp.neighbors"

        class NSXTBGPNeighbors {
            [string]$Name
            [string]$logical_router_id
            hidden $tags = [System.Collections.Generic.List[string]]::new()
            [string]$protection
            [string]$resource_type
            [string]$address_families = [System.Collections.Generic.List[string]]::new()
            hidden $bfd_config
            [bool]$enable_bfd
            [bool]$enabled
            hidden $filter_in_ipprefixlist_id
            hidden $filter_in_routemap_id
            hidden $filter_out_ipprefixlist_id
            hidden $filter_out_routemap_id
            hidden [long]$hold_down_timer
            hidden [long]$keep_alive_timer
            hidden [long]$maximum_hop_limit
            [string]$neighbor_address
            hidden [string]$password
            [long]$remote_as
            [string]$remote_as_num
            [string]$source_address
            [string]$source_addresses = [System.Collections.Generic.List[string]]::new()
        }
    }

    Process
    {
        $NSXTThings = $NSXTThingsService.list($logical_router_id).results

        foreach ($NSXTThing in $NSXTThings) {

            $results = [NSXTBGPNeighbors]::new()
            $results.Name = $NSXTThing.display_name;
            $results.logical_router_id = $NSXTThing.logical_router_id;
            $results.tags = $NSXTThing.tags;
            $results.protection = $NSXTThing.protection;
            $results.resource_type = $NSXTThing.resource_type;
            $results.address_families = $NSXTThing.address_families;
            $results.bfd_config = $NSXTThing.bfd_config;
            $results.enable_bfd = $NSXTThing.enable_bfd;
            $results.enabled = $NSXTThing.enabled;
            $results.filter_in_ipprefixlist_id = $NSXTThing.filter_in_ipprefixlist_id;
            $results.filter_in_routemap_id = $NSXTThing.filter_in_routemap_id;
            $results.filter_out_ipprefixlist_id = $NSXTThing.filter_out_ipprefixlist_id;
            $results.filter_out_routemap_id = $NSXTThing.filter_out_routemap_id;
            $results.hold_down_timer = $NSXTThing.hold_down_timer;
            $results.keep_alive_timer = $NSXTThing.keep_alive_timer;
            $results.maximum_hop_limit = $NSXTThing.maximum_hop_limit;
            $results.neighbor_address = $NSXTThing.neighbor_address;
            $results.password = $NSXTThing.password;
            $results.remote_as = $NSXTThing.remote_as;
            $results.remote_as_num = $NSXTThing.remote_as_num;
            $results.source_address = $NSXTThing.source_address;
            $results.source_addresses = $NSXTThing.source_addresses
             $results
        }
    }
}

Function Get-NSXTForwardingTable {
 <#
    .Synopsis
       Retrieves the forwarding table information
    .DESCRIPTION
       Retrieves forwarding table for a single LR including LR type (SR/DR) and next_hop. Must specify Logical_router_id & transport_node_id. Pipeline input supported.
    .EXAMPLE
       Get-Get-NSXTForwardingTable -Logical_router_id "LR ID" -transport_node_id "TN ID" | format-table -autosize
    .EXAMPLE
       Get-NSXTLogicalRouter | where name -eq "LR Name" | Get-NSXTForwardingTable -transport_node_id "TN ID"
    .EXAMPLE
       Get-NSXTLogicalRouter | where name -eq "LR Name" | Get-NSXTForwardingTable -transport_node_id ((Get-NSXTTransportNode | where name -match "Edge Name")[0].transport_node_id)
    .EXAMPLE
       Get-NSXTLogicalRouter | where name -eq "LR Name" | Get-NSXTForwardingTable -transport_node_id (((Get-NSXTLogicalRouter | where name -eq "Edge Name").per_node_status | where high_availability_status -eq ACTIVE).transport_node_id)
#>

    Param (
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Logical_router_id,
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$transport_node_id
    )

    Begin
    {
        $NSXTForwardingTableService = Get-NsxtService -Name "com.vmware.nsx.logical_routers.routing.forwarding_table"

        class NSXTForwardingTable {
                hidden [string]$Logical_router_id
                [string]$lr_component_id
                [string]$lr_component_type
                [string]$network
                [string]$next_hop
                [string]$route_type
                hidden [string]$logical_router_port_id
        }
    }

    Process
    {
        $NSXTForwardingTable = $NSXTForwardingTableService.list($Logical_router_id,$transport_node_id,$null,$null,$null,$null,$null,$null,'realtime')

        foreach ($NSXTForwarding in $NSXTForwardingTable.results) {

            $results = [NSXTForwardingTable]::new()
            $results.Logical_router_id = $Logical_router_id;
            $results.lr_component_type = $NSXTForwarding.lr_component_type;
            $results.lr_component_id = $NSXTForwarding.lr_component_id;
            $results.network = $NSXTForwarding.network;
            $results.next_hop = $NSXTForwarding.next_hop;
            $results.route_type = $NSXTForwarding.route_type;
            $results.logical_router_port_id = $NSXTForwarding.logical_router_port_id
             $results
        }
    }
}

Function Get-NSXTNetworkRoutes {
<#
    .Synopsis
       Retrieves the network routes information
    .DESCRIPTION
       Retrieves the network routes information for a single or multiple routes.
    .EXAMPLE
       Get-NSXTNetworkRoutes
    .EXAMPLE
       Get-NSXTNetworkRoutes -route_id "Route ID"
#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$route_id
    )

    Begin
    {
        $NSXTNetworkRoutesService = Get-NsxtService -Name "com.vmware.nsx.node.network.routes"

    class NSXTNetworkRoutes {
            [string]$route_id
            $route_type
            $interface_id
            $gateway
            $from_address
            $destination
            $netmask
            $metric
            $proto
            $scope
            $src
    }
    }

    Process
    {
        if ($route_id) {
            $NSXTNetworkRoutes = $NSXTNetworkRoutesService.get($route_id)
        }
        else {
            $NSXTNetworkRoutes = $NSXTNetworkRoutesService.list().results
        }

        foreach ($NSXTRoute in $NSXTNetworkRoutes) {

            $results = [NSXTNetworkRoutes]::new()
            $results.route_id = $NSXTRoute.route_id;
            $results.route_type = $NSXTRoute.route_type;
            $results.interface_id = $NSXTRoute.interface_id;
            $results.gateway = $NSXTRoute.gateway;
            $results.from_address = $NSXTRoute.from_address;
            $results.destination = $NSXTRoute.destination;
            $results.netmask = $NSXTRoute.netmask;
            $results.metric = $NSXTRoute.metric;
            $results.proto = $NSXTRoute.proto;
            $results.scope = $NSXTRoute.scope;
            $results.src = $NSXTRoute.src
             $results
        }
    }
}

Function Get-NSXTLogicalRouterPorts {
<#
    .Synopsis
       Retrieves the logical router port information
    .DESCRIPTION
       Retrieves logical router port information for a single or multiple ports. Execute with no parameters to get all ports, specify a single port if known, or feed a logical switch for filtered output.
    .EXAMPLE
       Get-NSXTLogicalRouterPorts
    .EXAMPLE
       Get-NSXTLogicalRouterPorts -logical_router_port_id "LR Port Name"
    .EXAMPLE
       Get-NSXTLogicalRouterPorts -logical_router_id "LR Name"
    .EXAMPLE
       Get-NSXTLogicalRouterPorts -logical_router_id (Get-NSXTLogicalRouter | where name -eq "LR Name")
#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$logical_router_port_id,
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$logical_router_id
    )

    begin
    {
        $NSXTLogicalRouterPortsService = Get-NsxtService -Name "com.vmware.nsx.logical_router_ports"

        class subnets {
            $ip_addresses
            $prefix_length

            subnets(){}

            subnets(
                $ip_addresses,
                $prefix_length
            ) {
                $this.ip_addresses = $ip_addresses
                $this.prefix_length = $prefix_length
            }
        }

        class NSXTLogicalRouterPorts {
            [string]$Name
            $Id
            [string]$logical_router_id
            $resource_type
            [string]$protection
            $mac_address
            $subnets = [System.Collections.Generic.List[string]]::new()
            hidden [string]$Tags
            hidden $linked_logical_switch_port_id
        }
    }

    Process
    {
        if($logical_router_port_id) {
            $NSXTLogicalRouterPorts = $NSXTLogicalRouterPortsService.get($logical_router_port_id)
        } else {
            if ($logical_router_id) {
                $NSXTLogicalRouterPorts = $NSXTLogicalRouterPortsService.list().results | where {$_.logical_router_id -eq $Logical_router_id}
            }
            else {
                $NSXTLogicalRouterPorts = $NSXTLogicalRouterPortsService.list().results
            }
        }

        foreach ($NSXTLogicalRouterPort in $NSXTLogicalRouterPorts) {

            $results = [NSXTLogicalRouterPorts]::new()

            foreach ($subnet in $NSXTLogicalRouterPort.subnets) {
                $results.subnets += [subnets]::new($subnet.ip_addresses,$subnet.prefix_length)
            }

            $results.Name = $NSXTLogicalRouterPort.display_name
            $results.Id = $NSXTLogicalRouterPort.Id
            $results.Logical_router_id = $NSXTLogicalRouterPort.Logical_router_id
            $results.resource_type = $NSXTLogicalRouterPort.resource_type
            $results.protection = $NSXTLogicalRouterPort.protection
            $results.Tags = $NSXTLogicalRouterPort.tags
            $results.mac_address = $NSXTLogicalRouterPort.mac_address
            $results.linked_logical_switch_port_id = $NSXTLogicalRouterPort.linked_logical_switch_port_id
            $results
        }
    }
}

Function Get-NSXTTransportZone {
 <#
    .Synopsis
       Retrieves the Transport Zone information
    .DESCRIPTION
       Retrieves THING information for a single or multiple ports. Execute with no parameters to get all ports, specify a PARAM if known.
    .EXAMPLE
       Get-NSXTTransportZone
    .EXAMPLE
       Get-NSXTTransportZone -zone_id "Zone ID"
    .EXAMPLE
        Get-NSXTTransportZone -name "Zone1"
#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$zone_id,
        [parameter(Mandatory=$false)]
        [string]$name
    )

    begin
    {
        $NSXTTransportZoneService = Get-NsxtService -Name "com.vmware.nsx.transport_zones"

        class NSXTTransportZone {
            [string]$Name
            [string]$ID
            hidden [string]$description
            hidden $tags
            $resource_type
            $host_switch_name
            $transport_type
            hidden $transport_zone_profile_ids
            $host_switch_mode
            $protection
            hidden $uplink_teaming_policy_names
        }
    }

    Process
    {
        if($zone_id) {
            $NSXTTransportZones = $NSXTTransportZoneService.get($zone_id)
        } else {
            if ($name) {
                $NSXTTransportZones = $NSXTTransportZoneService.list().results | where {$_.display_name -eq $name}
            }
            else {
                $NSXTTransportZones = $NSXTTransportZoneService.list().results
            }
        }

        foreach ($NSXTTransportZone in $NSXTTransportZones) {

            $results = [NSXTTransportZone]::new()
            $results.Name = $NSXTTransportZone.display_name;
            $results.ID = $NSXTTransportZone.Id;
            $results.description = $NSXTTransportZone.description;
            $results.tags = $NSXTTransportZone.tags;
            $results.resource_type = $NSXTTransportZone.resource_type;
            $results.host_switch_name = $NSXTTransportZone.host_switch_name;
            $results.transport_type = $NSXTTransportZone.transport_type;
            $results.transport_zone_profile_ids = $NSXTTransportZone.transport_zone_profile_ids;
            $results.host_switch_mode = $NSXTTransportZone.host_switch_mode;
            $results.protection = $NSXTTransportZone.protection;
            $results.uplink_teaming_policy_names = $NSXTTransportZone.uplink_teaming_policy_names
            $results
        }
    }
}

Function Get-NSXTLogicalSwitch {
 <#
    .Synopsis
       Retrieves the Logical Switch information
    .DESCRIPTION
       Retrieves Logical Switch information for a single or multiple switches. Execute with no parameters to get all ports, specify a name or lswitch_id if known.
    .EXAMPLE
       Get-NSXTLogicalSwitch
    .EXAMPLE
       Get-NSXTLogicalSwitch -lswitch_id "switch id"
    .EXAMPLE
       Get-NSXTLogicalSwitch -name "switch name"
#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$lswitch_id,
        [parameter(Mandatory=$false)]
        [string]$name
    )

    begin
    {
        $NSXTLogicalSwitchService = Get-NsxtService -Name "com.vmware.nsx.logical_switches"

        class NSXTLogicalSwitch {
            [string]$Name
            [string]$ID
            $tags
            $resource_type
            hidden $description
            $vni
            $transport_zone_id
            $admin_state
            $replication_mode
            hidden $address_bindings
            $protection
            hidden $extra_configs
            $ip_pool_id
            hidden $mac_pool_id
            hidden $uplink_teaming_policy_name
            hidden $vlan
            hidden $vlan_trunk_spec
        }
    }

    Process
    {
        if($lswitch_id) {
            $NSXTLogicalSwitches = $NSXTLogicalSwitchService.get($lswitch_id)
        } else {
            if ($name) {
                $NSXTLogicalSwitches = $NSXTLogicalSwitchService.list().results | where {$_.display_name -eq $name}
            }
            else {
                $NSXTLogicalSwitches = $NSXTLogicalSwitchService.list().results
            }
        }

        foreach ($NSXTLogicalSwitch in $NSXTLogicalSwitches) {

            $results = [NSXTLogicalSwitch]::new()
            $results.Name = $NSXTLogicalSwitch.display_name;
            $results.Id = $NSXTLogicalSwitch.Id;
            $results.Tags = $NSXTLogicalSwitch.tags;
            $results.resource_type = $NSXTLogicalSwitch.resource_type;
            $results.description = $NSXTLogicalSwitch.description;
            $results.vni = $NSXTLogicalSwitch.vni;
            $results.transport_zone_id = $NSXTLogicalSwitch.transport_zone_id;
            $results.admin_state = $NSXTLogicalSwitch.admin_state;
            $results.replication_mode = $NSXTLogicalSwitch.replication_mode;
            $results.address_bindings = $NSXTLogicalSwitch.address_bindings;
            $results.protection = $NSXTLogicalSwitch.protection;
            $results.extra_configs = $NSXTLogicalSwitch.extra_configs;
            $results.ip_pool_id = $NSXTLogicalSwitch.ip_pool_id;
            $results.mac_pool_id = $NSXTLogicalSwitch.mac_pool_id;
            $results.uplink_teaming_policy_name = $NSXTLogicalSwitch.uplink_teaming_policy_name;
            $results.vlan = $NSXTLogicalSwitch.vlan;
            $results.vlan_trunk_spec = $NSXTLogicalSwitch.vlan_trunk_spec
            $results
        }
    }
}

Function Get-NSXTIPPool {
 <#
    .Synopsis
       Retrieves the THING information
    .DESCRIPTION
       Retrieves THING information for a single or multiple ports. Execute with no parameters to get all ports, specify a PARAM if known.
    .EXAMPLE
       Get-NSXTIPPool
    .EXAMPLE
       Get-NSXTThingTemplate -pool_id "Pool ID"
#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$pool_id,
        [parameter(Mandatory=$false)]
        [string]$name
    )

    begin
    {
        $NSXTIPPoolService = Get-NsxtService -Name "com.vmware.nsx.pools.ip_pools"

        class NSXTIPPool {
            [string]$Name
            [string]$id
            $total_ids
            $free_ids
            $allocated_ids
            $Network
            $Gateway
            $DNS
            $RangeStart
            $RangeEnd
        }
    }

    Process
    {
        if($pool_id) {
            $NSXTIPPools = $NSXTIPPoolService.get($pool_id)
        } else {
            if ($name) {
                $NSXTIPPools = $NSXTIPPoolService.list().results | where {$_.display_name -eq $name}
            }
            else {
                $NSXTIPPools = $NSXTIPPoolService.list().results
            }
        }

        foreach ($NSXTIPPool in $NSXTIPPools) {

            $results = [NSXTIPPool]::new()
            $results.Name = $NSXTIPPool.display_name;
            $results.ID = $NSXTIPPool.id;
            $results.total_ids = $NSXTIPPool.pool_usage.total_ids;
            $results.free_ids = $NSXTIPPool.pool_usage.free_ids;
            $results.allocated_ids = $NSXTIPPool.pool_usage.allocated_ids;
            $results.Network = $NSXTIPPool.subnets.cidr;
            $results.Gateway = $NSXTIPPool.subnets.gateway_ip;
            $results.DNS = $NSXTIPPool.subnets.dns_nameservers;
            $results.RangeStart = $NSXTIPPool.subnets.allocation_ranges.start;
            $results.RangeEnd = $NSXTIPPool.subnets.allocation_ranges.end
            $results
        }
    }
}

Function Get-NSXTIPAMIPBlock {
 <#
    .Synopsis
       Retrieves the IPAM IP Block information
    .DESCRIPTION
       Retrieves IPAM IP Block information for a single or multiple ports. Execute with no parameters to get all ports, specify a PARAM if known.
    .EXAMPLE
       Get-NSXTIPAMIPBlock
    .EXAMPLE
       Get-NSXTIPAMIPBlock -block_id "Block Id"
    .EXAMPLE
       Get-NSXTIPAMIPBlock -name "Block Name"

#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$block_id,
        [parameter(Mandatory=$false)]
        [string]$name
    )

    begin
    {
        $NSXTIPAMIPBlocksService = Get-NsxtService -Name "com.vmware.nsx.pools.ip_blocks"

        class ip_block {
            [string]$Name
            [string]$block_id
            hidden [string]$Tags = [System.Collections.Generic.List[string]]::new()
            [string]$protection
            #[ValidateSet("TIER0","TIER1")]
            [string]$cidr
            hidden [string]$resource_type
        }
    }

    Process
    {
        if($block_id) {
            $NSXTIPAMIPBlocks = $NSXTIPAMIPBlocksService.get($block_id)
        } else {
            if ($name) {
                $NSXTIPAMIPBlocks = $NSXTIPAMIPBlocksService.list().results | where {$_.display_name -eq $name}
            }
            else {
                $NSXTIPAMIPBlocks = $NSXTIPAMIPBlocksService.list().results
            }
        }

        foreach ($NSXTIPAMIPBlock in $NSXTIPAMIPBlocks) {

            $results = [ip_block]::new()
            $results.Name = $NSXTIPAMIPBlock.display_name;
            $results.block_id = $NSXTIPAMIPBlock.id;
            $results.Tags = $NSXTIPAMIPBlock.tags;
            $results.protection = $NSXTIPAMIPBlock.protection;
            $results.cidr = $NSXTIPAMIPBlock.cidr;
            $results.resource_type = $NSXTIPAMIPBlock.resource_type

            $results
        }
    }
}

Function Get-NSXTClusterNode {
 <#
    .Synopsis
       Retrieves the cluster node information
    .DESCRIPTION
       Retrieves cluster node information including manager and controller nodes.
    .EXAMPLE
       Get-NSXTClusterNode
    .EXAMPLE
       Get-NSXTClusterNode -node_id "Node Id"
    .EXAMPLE
       Get-NSXTClusterNode -name "Name"
#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$node_id,
        [parameter(Mandatory=$false)]
        [string]$name
    )

    begin
    {
        $NSXTClusterNodesService = Get-NsxtService -Name "com.vmware.nsx.cluster.nodes"

        class NSXTClusterNode {
            [string]$Name
            [string]$node_id
            hidden [array]$Tags = [System.Collections.Generic.List[string]]::new()
            hidden [string]$controller_role
            hidden [array]$manager_role
            [string]$protection
            [string]$appliance_mgmt_listen_addr
            hidden [string]$external_id
            hidden [string]$description
            [string]$role
        }
    }

    Process
    {
        if($node_id) {
            $NSXTThings = $NSXTClusterNodesService.get($node_id)
        } else {
            if ($name) {
                $NSXTClusterNodes = $NSXTClusterNodesService.list().results | where {$_.display_name -eq $name}
            }
            else {
                $NSXTClusterNodes = $NSXTClusterNodesService.list().results
            }
        }

        foreach ($NSXTClusterNode in $NSXTClusterNodes) {

            $results = [NSXTClusterNode]::new()
            $results.Name = $NSXTClusterNode.display_name;
            $results.node_id = $NSXTClusterNode.Id;
            $results.Tags = $NSXTClusterNode.tags;
            $results.controller_role = $NSXTClusterNode.controller_role;
            $results.manager_role = $NSXTClusterNode.manager_role;
            $results.protection = $NSXTClusterNode.protection;
            $results.appliance_mgmt_listen_addr = $NSXTClusterNode.appliance_mgmt_listen_addr;
            $results.external_id = $NSXTClusterNode.external_id;
            $results.description = $NSXTClusterNode.description

            if ($NSXTClusterNode.manager_role -ne $null) {
                $results.role = "Manager"
            }
            elseif ($NSXTClusterNode.controller_role -ne $null) {
                $results.role = "Controller"
            }

            $results
        }
    }
}

# Working Set Functions
Function Set-NSXTLogicalRouter {
 <#
    .Synopsis
       Creates a Logical Router
    .DESCRIPTION
       Create a TIER0 or TIER1 logical router
    .EXAMPLE
       Set-NSXTLogicalRouter -display_name "Name" -high_availability_mode "ACTIVE_STANDBY" -router_type "TIER1"
    .EXAMPLE
       Set-NSXTLogicalRouter -display_name "Name" -high_availability_mode "ACTIVE_ACTIVE" -router_type "TIER0" -edge_cluster_id "Edge Cluster ID"
    .EXAMPLE
       Set-NSXTLogicalRouter -display_name "Name" -high_availability_mode "ACTIVE_STANDBY" -router_type "TIER1" -description "this is my new tier1 lr"
#>

    [CmdletBinding(SupportsShouldProcess=$true,
                  ConfirmImpact='Medium')]

    # Paramameter Set variants will be needed Multicast & Broadcast Traffic Types as well as VM & Logical Port Types
    Param (
            [parameter(Mandatory=$false,
                        ParameterSetName='TIER0')]
            [parameter(Mandatory=$false,
                        ParameterSetName='TIER1')]
            [string]$description,

            [parameter(Mandatory=$true,
                        ParameterSetName='TIER0')]
            [parameter(Mandatory=$true,
                        ParameterSetName='TIER1')]
            [string]$display_name,

            [parameter(Mandatory=$true,
                        ParameterSetName='TIER0')]
            [parameter(Mandatory=$true,
                        ParameterSetName='TIER1')]
            [ValidateSet("ACTIVE_ACTIVE","ACTIVE_STANDBY")]
            [string]$high_availability_mode,

            [parameter(Mandatory=$true,
                        ParameterSetName='TIER0')]
            [parameter(Mandatory=$true,
                        ParameterSetName='TIER1')]
            [ValidateSet("TIER0","TIER1")]
            [string]$router_type,

            [parameter(Mandatory=$true,
                        ParameterSetName='TIER0')]
            [string]$edge_cluster_id
    )

    Begin
    {
        if (-not $global:DefaultNsxtServers.isconnected)
        {
            try
            {
                Connect-NsxtServer -Menu -ErrorAction Stop
            }

            catch
            {
                throw "Could not connect to an NSX-T Manager, please try again"
            }
        }

        $NSXTLogicalRouterService = Get-NsxtService -Name "com.vmware.nsx.logical_routers"
    }

    Process
    {
        $logical_router_request = $NSXTLogicalRouterService.help.create.logical_router.Create()

        $logical_router_request.display_name = $display_name
        $logical_router_request.description = $description
        $logical_router_request.router_type = $router_type
        $logical_router_request.high_availability_mode = $high_availability_mode
        $logical_router_request.resource_type = "LogicalRouter"
        $logical_router_request.failover_mode = "NON_PREEMPTIVE"

        if ($edge_cluster_id) {
            $logical_router_request.edge_cluster_id = $edge_cluster_id
        }

        try
        {
            # Should process
            if ($pscmdlet.ShouldProcess($logical_router_request.display_name, "Create logical router"))
            {
                $NSXTLogicalRouter = $NSXTLogicalRouterService.create($logical_router_request)
            }
        }

        catch
        {
            throw $Error[0].Exception.ServerError.data
            # more error data found in the NSX-T Manager /var/log/vmware/nsx-manager.log file.
        }

        $NSXTLogicalRouter
    }
}

Function Set-NSXTLogicalSwitch {
 <#
    .Synopsis
       Creates a Logical Switch
    .DESCRIPTION
       Creates a Logical Switch with a number of required parameters.  IP Pool is necessary even for an overlay logical switch
    .EXAMPLE
       Set-NSXTLogicalSwitch -display_name "Name" -transport_zone_id "TP Zone ID"
    .EXAMPLE
       Set-NSXTLogicalSwitch -display_name "Name" -transport_zone_id "TP Zone ID" -admin_state "UP" -replication_mode "MTEP" -ip_pool_id "IP Pool Name"
#>

    [CmdletBinding(SupportsShouldProcess=$true,
                  ConfirmImpact='Medium')]

    # Paramameter Set variants will be needed Multicast & Broadcast Traffic Types as well as VM & Logical Port Types
    Param (
            [parameter(Mandatory=$false)]
            [string]$description,

            [parameter(Mandatory=$true)]
            [string]$display_name,

            [parameter(Mandatory=$true)]
            [string]$transport_zone_id,

            [parameter(Mandatory=$true)]
            [ValidateSet("UP","DOWN")]
            [string]$admin_state,

            [parameter(Mandatory=$false)]
            [ValidateSet("MTEP","SOURCE")]
            [string]$replication_mode,

            [parameter(Mandatory=$true)]
            [string]$ip_pool_id
    )

    Begin
    {
        if (-not $global:DefaultNsxtServers.isconnected)
        {
            try
            {
                Connect-NsxtServer -Menu -ErrorAction Stop
            }

            catch
            {
                throw "Could not connect to an NSX-T Manager, please try again"
            }
        }

        $NSXTLogicalSwitchService = Get-NsxtService -Name "com.vmware.nsx.logical_switches"
    }

    Process
    {
        $logical_switch_request = $NSXTLogicalSwitchService.help.create.logical_switch.Create()

        $logical_switch_request.display_name = $display_name
        $logical_switch_request.description = $description
        $logical_switch_request.admin_state = $admin_state
        $logical_switch_request.transport_zone_id = $transport_zone_id
        $logical_switch_request.resource_type = "LogicalSwitch"
        $logical_switch_request.replication_mode = $replication_mode
        $logical_switch_request.ip_pool_id = $ip_pool_id

        try
        {
            # Should process
            if ($pscmdlet.ShouldProcess($logical_switch_request.display_name, "Create logical switch"))
            {
                $NSXTLogicalSwitch = $NSXTLogicalSwitchService.create($logical_switch_request)
            }

        }

        catch
        {
            throw $Error[0].Exception.ServerError.data
            # more error data found in the NSX-T Manager /var/log/vmware/nsx-manager.log file.
        }

        $NSXTLogicalSwitch
    }
}

Function Set-NSXTIPAMIPBlock {
 <#
    .Synopsis
       Creates an IPAM IP Block
    .DESCRIPTION
       Creates a IPAM IP Block with a cidr parameter.
    .EXAMPLE
       Set-NSXTIPAMIPBlock -name "IPAM Block Name" -cidr "192.168.0.0/24"
#>

    [CmdletBinding(SupportsShouldProcess=$true,
                  ConfirmImpact='Medium')]

    # Paramameter Set variants will be needed Multicast & Broadcast Traffic Types as well as VM & Logical Port Types
    Param (
            [parameter(Mandatory=$false)]
            [string]$description,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$display_name,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$cidr
    )

    Begin
    {
        if (-not $global:DefaultNsxtServers.isconnected)
        {
            try
            {
                Connect-NsxtServer -Menu -ErrorAction Stop
            }

            catch
            {
                throw "Could not connect to an NSX-T Manager, please try again"
            }
        }

        $NSXTIPAMIPBlockService = Get-NsxtService -Name "com.vmware.nsx.pools.ip_blocks"
    }

    Process
    {
        $IPAMIPBlock_request = $NSXTIPAMIPBlockService.help.create.ip_block.Create()

        $IPAMIPBlock_request.display_name = $display_name
        $IPAMIPBlock_request.description = $description
        $IPAMIPBlock_request.resource_type = "IpBlock"
        $IPAMIPBlock_request.cidr = $cidr


        try
        {
            # Should process
            if ($pscmdlet.ShouldProcess($ip_pool.display_name, "Create IP Pool"))
            {
                $NSXTIPAMIPBlock = $NSXTIPAMIPBlockService.create($IPAMIPBlock_request)
            }
        }

        catch
        {
            throw $Error[0].Exception.ServerError.data
            # more error data found in the NSX-T Manager /var/log/vmware/nsx-manager.log file.
        }

        $NSXTIPAMIPBlock
    }
}

Function Set-NSXTIPPool {
 <#
    .Synopsis
       Creates an IP Pool
    .DESCRIPTION
       Creates a IP Pool with a number of required parameters. Supported IP formats include 192.168.1.1, 192.168.1.1-192.168.1.100, 192.168.0.0/24
    .EXAMPLE
       Set-NSXTIPPool -display_name "Pool Name" -allocation_start "192.168.1.2" -allocation_end "192.168.1.100" -cidr "192.168.1.0/24"
    .EXAMPLE
       Set-NSXTIPPool -display_name "Test Pool Name" -allocation_start "192.168.1.2" -allocation_end "192.168.1.100" -cidr "192.168.1.0/24" -dns_nameservers "192.168.1.1" -gateway_ip "192.168.1.1" -dns_suffix "evil corp"
#>

    [CmdletBinding(SupportsShouldProcess=$true,
                  ConfirmImpact='High')]

    # Paramameter Set variants will be needed Multicast & Broadcast Traffic Types as well as VM & Logical Port Types
    Param (
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$display_name,

            [parameter(Mandatory=$false)]
            [string]$description,

            [parameter(Mandatory=$false)]
            [string]$dns_nameservers,

            [parameter(Mandatory=$false)]
            [string]$dns_suffix,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$allocation_start,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$allocation_end,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$cidr,

            [parameter(Mandatory=$false)]
            [string]$gateway_ip
    )

    Begin
    {
        if (-not $global:DefaultNsxtServers.isconnected)
        {
            try
            {
                Connect-NsxtServer -Menu -ErrorAction Stop
            }

            catch
            {
                throw "Could not connect to an NSX-T Manager, please try again"
            }
        }

        $NSXTIPPoolService = Get-NsxtService -Name "com.vmware.nsx.pools.ip_pools"

        # Classes unused - part of early testing
        class allocation_ranges {
            [string]$start
            [string]$end
            #$self
        }

        class subnets {
            [array]$allocation_ranges = [allocation_ranges]::new()
            [array]$dns_nameservers
            [string]$dns_suffix
            [string]$cidr
            [string]$gateway_ip
            #hidden $self
        }

        class ip_pool {
            [string]$display_name
            [string]$description
            [string]$resource_type = 'IpPool'
            [long]$revision = '0'
            [array]$subnets = [subnets]::new()
            hidden $pool_usage
            hidden [array]$tags
            # hidden $self
            hidden $links
        }
    }

    Process
    {
        $sample_ip_pool = $NSXTIPPoolService.help.create.ip_pool.Create()
        $sample_ip_pool.subnets = @($NSXTIPPoolService.help.create.ip_pool.subnets.Create())
        $sample_ip_pool.subnets = @($NSXTIPPoolService.help.create.ip_pool.subnets.Element.Create())
        $sample_ip_pool.subnets[0].allocation_ranges = @($NSXTIPPoolService.help.create.ip_pool.subnets.Element.allocation_ranges.create())
        $sample_ip_pool.subnets[0].allocation_ranges = @($NSXTIPPoolService.help.create.ip_pool.subnets.Element.allocation_ranges.element.create())

        #Remove buggy self object
        $ip_pool = $sample_ip_pool | select -Property * -ExcludeProperty self
        $ip_pool.subnets[0] = $sample_ip_pool.subnets[0] | select -Property * -ExcludeProperty self
        $ip_pool.subnets[0].allocation_ranges[0] = $sample_ip_pool.subnets[0].allocation_ranges[0] | select -Property * -ExcludeProperty self

        # Assign objects
        $ip_pool.display_name = $display_name
        $ip_pool.description = $description
        $ip_pool.resource_type = "IpPool"
        $ip_pool.subnets[0].dns_nameservers = @($dns_nameservers)
        $ip_pool.subnets[0].dns_suffix = $dns_suffix
        $ip_pool.subnets[0].allocation_ranges[0].start = $allocation_start
        $ip_pool.subnets[0].allocation_ranges[0].end = $allocation_end
        $ip_pool.subnets[0].cidr = $cidr
        $ip_pool.subnets[0].gateway_ip = $gateway_ip
        $ip_pool.revision = 0
        $ip_pool.tags = @()

        try
        {
            # Should process
            if ($pscmdlet.ShouldProcess($ip_pool.display_name, "Create IP Pool"))
            {
                $NSXTIPPoolService.create($ip_pool)
            }
        }

        catch
        {
            $Error[0].Exception.ServerError.data
            # more error data found in the NSX-T Manager /var/log/vmware/nsx-manager.log file; grep POOL-MGMT
            throw
        }
    }
}

# Remove functions
Function Remove-NSXTIPAMIPBlock {
 <#
    .Synopsis
       Removes an IPAM IP Block
    .DESCRIPTION
       Removes a IPAM IP Block with a block_id parameter.
    .EXAMPLE
       Remove-NSXTIPAMIPBlock -block_id "id"
    .EXAMPLE
        Get-NSXTIPAMIPBlock | where name -eq "IPAM Test2" | Remove-NSXTIPAMIPBlock
#>

    [CmdletBinding(SupportsShouldProcess=$true,
                  ConfirmImpact='High')]

    Param (
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")]
        [string]$block_id
    )

    Begin
    {
        if (-not $global:DefaultNsxtServers.isconnected)
        {
            try
            {
                Connect-NsxtServer -Menu -ErrorAction Stop
            }

            catch
            {
                throw "Could not connect to an NSX-T Manager, please try again"
            }
        }

        $NSXTIPAMIPBlockService = Get-NsxtService -Name "com.vmware.nsx.pools.ip_blocks"
    }

    Process
    {
        try
        {
            # Should process
            if ($pscmdlet.ShouldProcess($block_id, "Delete IP Pool"))
            {
                $NSXTIPAMIPBlockService.delete($block_id)
            }
        }

        catch
        {
            throw $Error[0].Exception.ServerError.data
            # more error data found in the NSX-T Manager /var/log/vmware/nsx-manager.log file.
        }
    }
}

# Non-working Set Functions
Function Set-NSXTTraceFlow {
 <#
    .Synopsis
       Creates a TraceFlow
    .DESCRIPTION
       Create a TraceFlow for later observation.
    .EXAMPLE
       Set-NSXTTraceFlow -transport_type "UNICAST" -lport_id "LP ID" -src_ip "IP Address" -src_mac "MAC" -dst_ip "IP Address" -dst_mac "MAC"
    .EXAMPLE
       Set-NSXTTraceFlow -transport_type "UNICAST" -lport_id "LP ID" -src_ip "IP Address" -src_mac "MAC" -dst_ip "IP Address" -dst_mac "MAC" | Get-NSXTTraceFlow
    .EXAMPLE
       Set-NSXTTraceFlow -transport_type "UNICAST" -lport_id "LP ID" -src_ip "IP Address" -src_mac "MAC" -dst_ip "IP Address" -dst_mac "MAC" | Get-NSXTTraceFlow | Get-NSXTTraceFlowObservations
#>

    [CmdletBinding(SupportsShouldProcess=$true,
                  ConfirmImpact='Medium')]

    # Paramameter Set variants will be needed Multicast & Broadcast Traffic Types as well as VM & Logical Port Types
    Param (
            [parameter(Mandatory=$true,
                        ParameterSetName='Parameter Set VM Type')]
            [ValidateSet("UNICAST")]
            [string]
            $transport_type = "UNICAST",
            [parameter(Mandatory=$true,
                        ValueFromPipeline=$true,
                        ParameterSetName='Parameter Set VM Type')]
            [ValidateNotNullOrEmpty()]
            #[ValidateScript({Get-NSXTLogicalPort -Id $_}]
            [string]
            $lport_id,
            [parameter(Mandatory=$true,
                        ValueFromPipeline=$true,
                        ParameterSetName='Parameter Set VM Type')]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({$_ -match [IPAddress]$_})]
            [string]
            $src_ip,
            [parameter(Mandatory=$true,
                        ValueFromPipeline=$true,
                        ParameterSetName='Parameter Set VM Type')]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({$pattern = '^(([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2}))|(([0-9A-Fa-f]{2}[-]){5}([0-9A-Fa-f]{2}))$'
                            if ($_ -match ($pattern -join '|')) {$true} else {
                                    throw "The argument '$_' does not match a valid MAC address format."
                                }
                            })]
            [string]
            $src_mac,
            [parameter(Mandatory=$true,
                        ValueFromPipeline=$true,
                        ParameterSetName='Parameter Set VM Type')]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({$_ -match [IPAddress]$_ })]
            [string]
            $dst_ip,
            [parameter(Mandatory=$true,
                        ValueFromPipeline=$true,
                        ParameterSetName='Parameter Set VM Type')]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({$pattern = '^(([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2}))|(([0-9A-Fa-f]{2}[-]){5}([0-9A-Fa-f]{2}))$'
                            if ($_ -match ($pattern -join '|')) {$true} else {
                                    throw "The argument '$_' does not match a valid MAC address format."
                                }
                            })]
            [string]
            $dst_mac)

    Begin
    {
        if (-not $global:DefaultNsxtServers.isconnected)
        {

            try
            {
                Connect-NsxtServer -Menu -ErrorAction Stop
            }

            catch
            {
                throw "Could not connect to an NSX-T Manager, please try again"
            }
        }

        $NSXTraceFlowsService = Get-NsxtService -Name "com.vmware.nsx.traceflows"

         # Comment out custom classes
        <#
        class ip_header {
            [string]$src_ip
            [string]$dst_ip
        }

        class eth_header {
            [string]$src_mac
            [string]$dst_mac
        }

        class packet_data {
            [boolean]$routed
            [ValidateSet("UNICAST","BROADCAST","MULTICAST","UNKNOWN")]
            [string]$transport_type
            [ValidateSet("BINARYPACKETDATA","FIELDSPACKETDATA")]
            [string]$resource_type
            [long]$frame_size
            [eth_header]$eth_header = [eth_header]::new()
            [ip_header]$ip_header = [ip_header]::new()

            packet_data(){
                $this.routed = 'true'
                $this.transport_type = 'UNICAST'
                $this.resource_type = 'FieldsPacketData'
            }
        }

        class traceflow_request {
            [string]$lport_id
            [long]$timeout
            [packet_data]$packet = [packet_data]::new()

            traceflow_request(){
                $this.timeout = '15000'
            }
        }
#>
    }

    Process
    {
        $traceflow_request = $NSXTraceFlowsService.Help.create.traceflow_request.Create()

        $traceflow_request.lport_id = $lport_id
        $traceflow_request.packet.transport_type = $transport_type

        $eth_header = [ordered]@{'src_mac' = $src_mac;'eth_type' = '2048';'dst_mac' = $dst_mac}
        $ip_header  = [ordered]@{src_ip = $src_ip;protocol = '1';ttl = '64';dst_ip = $dst_ip}
        $traceflow_request.packet | Add-Member -NotePropertyMembers $eth_header -TypeName eth_header
        $traceflow_request.packet | Add-Member -NotePropertyMembers $ip_header  -TypeName ip_header

        try
        {
            # Should process
            if ($pscmdlet.ShouldProcess($traceflow_request.lport_id, "Create traceflow"))
            {
                # This does not work, bug report submitted to PowerCLI team
                $NSXTraceFlow = $NSXTraceFlowService.create($traceflow_request)
            }
        }

        catch
        {
            throw $Error[0].Exception.ServerError.data
            # more error data found in the NSX-T Manager /var/log/vmware/nsx-manager.log file.  Filter by MONITORING.
        }

        $NSXTraceFlow
    }
}



###########################
#                         #
#       TEMPLATES!!       #
#                         #
###########################

# Get Template
Function Get-NSXTThingTemplate {
 <#
    .Synopsis
       Retrieves the THING information
    .DESCRIPTION
       Retrieves THING information for a single or multiple ports. Execute with no parameters to get all ports, specify a PARAM if known.
    .EXAMPLE
       Get-NSXTThingTemplate
    .EXAMPLE
       Get-NSXTThingTemplate -param1 "LR Port Name"
    .EXAMPLE
       Get-NSXTThingTemplate -param2 "LR Name"
    .EXAMPLE
       Get-NSXTThingTemplate -param2 (Get-NSXTLogicalRouter | where name -eq "LR Name")
#>

    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$Thing_id,
        [parameter(Mandatory=$false)]
        [string]$name
    )

    begin
    {
        $NSXTThingsService = Get-NsxtService -Name "com.vmware.nsx.API.Thing"

        class NSXTThing {
            [string]$Name
            [string]$Thing1
            hidden [string]$Tags = [System.Collections.Generic.List[string]]::new()
            [string]$Thing2
            #[ValidateSet("TIER0","TIER1")]
            [string]$Thing3
            #[ValidateSet("ACTIVE_ACTIVE","ACTIVE_STANDBY","")]
            [string]$Thing4
            #[ValidateSet("PREEMPTIVE","NON_PREEMPTIVE","")]
            [string]$Thing5
            [string]$Thing6
            [string]$Thing7
        }
    }

    Process
    {
        if($Thing_id) {
            $NSXTThings = $NSXTThingsService.get($Thing_id)
        } else {
            if ($name) {
                $NSXTThings = $NSXTThingsService.list().results | where {$_.display_name -eq $name}
            }
            else {
                $NSXTThings = $NSXTThingsService.list().results
            }
        }

        foreach ($NSXTThing in $NSXTThings) {

            $results = [NSXTThing]::new()
            $results.Name = $NSXTThing.display_name;
            $results.Logical_router_id = $NSXTThing.Id;
            $results.Tags = $NSXTThing.tags;
            $results.thing1 = $NSXTThing.thing1;
            $results.thing2 = $NSXTThing.thing2

             $results
        }
    }
}

# Set Template
Function Set-NSXTThingTemplate {
 <#
    .Synopsis
       Creates a THING
    .DESCRIPTION
       Creates a THING with a number of required parameters.
    .EXAMPLE
       Set-NSXTThingTemplateh -param1 "Name" -param2 "TP Zone ID"
    .EXAMPLE
       Set-NSXTThingTemplateh -param1 "Name" -param2 "TP Zone ID"
#>

    [CmdletBinding(SupportsShouldProcess=$true,
                  ConfirmImpact='Medium')]

    # Paramameter Set variants will be needed Multicast & Broadcast Traffic Types as well as VM & Logical Port Types
    Param (
            [parameter(Mandatory=$false)]
            [string]$description,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$display_name,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$transport_zone_id,

            [parameter(Mandatory=$true)]
            [ValidateSet("UP","DOWN")]
            [string]$admin_state,

            [parameter(Mandatory=$false)]
            [ValidateSet("MTEP","SOURCE")]
            [string]$replication_mode,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$ip_pool_id
    )

    Begin
    {
        if (-not $global:DefaultNsxtServers.isconnected)
        {
            try
            {
                Connect-NsxtServer -Menu -ErrorAction Stop
            }

            catch
            {
                throw "Could not connect to an NSX-T Manager, please try again"
            }
        }

        $NSXTTHINGService = Get-NsxtService -Name "com.vmware.nsx.THING"
    }

    Process
    {
        $logical_THING_request = $NSXTTHINGService.help.create.logical_switch.Create()

        $logical_THING_request.display_name = $display_name
        $logical_THING_request.description = $description
        $logical_THING_request.admin_state = $admin_state
        $logical_THING_request.transport_zone_id = $transport_zone_id
        $logical_THING_request.resource_type = "LogicalSwitch"
        $logical_THING_request.replication_mode = $replication_mode
        $logical_THING_request.ip_pool_id = $ip_pool_id

        try
        {
            # Should process
            if ($pscmdlet.ShouldProcess($ip_pool.display_name, "Create IP Pool"))
            {
                $NSXTTHING = $NSXTTHINGService.create($logical_THING_request)
            }
        }

        catch
        {
            throw $Error[0].Exception.ServerError.data
            # more error data found in the NSX-T Manager /var/log/vmware/nsx-manager.log file.
        }

        $NSXTTHING
    }
}

# Remove Template
Function Remove-NSXTThingTemplate {
 <#
    .Synopsis
       Removes an IPAM IP Block
    .DESCRIPTION
       Removes a IPAM IP Block with a block_id parameter.
    .EXAMPLE
       Remove-NSXTIPAMIPBlock -block_id "id"
#>

    [CmdletBinding(SupportsShouldProcess=$true,
                  ConfirmImpact='High')]

    Param (
            [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [ValidateNotNullOrEmpty()]
            [Alias("Id")]
            [string]$thing_id
    )

    Begin
    {
        if (-not $global:DefaultNsxtServers.isconnected)
        {
            try
            {
                Connect-NsxtServer -Menu -ErrorAction Stop
            }

            catch
            {
                throw "Could not connect to an NSX-T Manager, please try again"
            }
        }

        $NSXTTHINGkService = Get-NsxtService -Name "com.vmware.nsx.THING"
    }

    Process
    {
        try
        {
            # Should process
            if ($pscmdlet.ShouldProcess($thing_id, "Delete IP Pool"))
            {
                $NSXTTHINGkService.delete($thing_id)
            }
        }

        catch
        {
            throw $Error[0].Exception.ServerError.data
            # more error data found in the NSX-T Manager /var/log/vmware/nsx-manager.log file.
        }
    }
}



