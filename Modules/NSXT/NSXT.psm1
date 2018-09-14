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

Function Get-NSXTTransportNode {
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
            [string]$Tranport_node_id
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
            $results.Tranport_node_id = $NSXTransportNode.Id;
            $results.maintenance_mode = $NSXTransportNode.maintenance_mode;
            $results.Tags = $NSXTransportNode.tags;
            $results.host_switches = $NSXTransportNode.host_switches;
            $results.host_switch_spec = $NSXTransportNode.host_switch_spec;
            $results.transport_zone_endpoints = $NSXTransportNode.transport_zone_endpoints;
            $results.host_switches = $NSXTransportNode.host_switches
            write-output $results
        } 
    }
}

Function Get-NSXTTraceFlow {
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
        write-output $results
    } 
}

Function Get-NSXTTraceFlowObservations {
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

Function Set-NSXTTraceFlow {
    [CmdletBinding()]

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
    }

    Process
    {
        [traceflow_request]$traceflow_request = [traceflow_request]::new()

        $traceflow_request.lport_id = $lport_id
        $traceflow_request.packet.transport_type = $transport_type
        $traceflow_request.packet.eth_header.src_mac = $src_mac
        $traceflow_request.packet.eth_header.dst_mac = $dst_mac
        $traceflow_request.packet.ip_header.src_ip = $src_ip
        $traceflow_request.packet.ip_header.dst_ip = $dst_ip

        try
        {
            # This does not work, bug report submitted to PowerCLI team
            $NSXTraceFlow = $NSXTraceFlowService.create($traceflow_request)
        }

        catch
        {
            $Error[0].Exception.ServerError.data
            # more error data found in the NSX-T Manager /var/log/vmware/nsx-manager.log file.  Filter by MONITORING.
        }
    }

    End
    {
        # Likely don't need this and will replace with write-output $NSXTraceFlow but I can't test right now due to bug
        if ($NSXTraceFlow)
        {
            Get-NSXttraceflow
        }
    }
}

Function Get-NSXTEdgeCluster {
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
            write-output $results
        }
    }
}

Function Get-NSXTLogicalRouter {
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
            $service_router_id = [System.Collections.ArrayList]::new()
            [ValidateSet("ACTIVE","STANDBY","DOWN","SYNC","UNKNOWN")]
            $high_availability_status = [System.Collections.ArrayList]::new()
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
            $per_node_status = [per_node_status]::new()
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
                $results.per_node_status.service_router_id.add($NSXTLogicalRouterStatus.service_router_id) 1>$null
                $results.per_node_status.high_availability_status.add($NSXTLogicalRouterStatus.high_availability_status) 1>$null
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
            write-output $results
        }  
    }
}

Function Get-NSXTRoutingTable {
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
            write-output $results
        }
    }
}

Function Get-NSXTFabricVM {

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
            write-output $results
        }
    }
}

Function Get-NSXTBGPNeighbors {
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
            write-output $results
        }  
    }
}

Function Get-NSXTForwardingTable {
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
            write-output $results
        }
    }
}

 Function Get-NSXTNetworkRoutes {
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
            write-output $results
        }
    }
}

# Get Template
Function Get-NSXTThingTemplate {
    Param (
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Alias("Id")]
        [string]$Thing_id
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
            $NSXTThings = $NSXTThingsService.list().results
        }

        foreach ($NSXTThing in $NSXTThings) {
            
            $results = [NSXTThing]::new()
            $results.Name = $NSXTThing.display_name;
            $results.Logical_router_id = $NSXTThing.Id;
            $results.Tags = $NSXTThing.tags;
            $results.thing1 = $NSXTThing.thing1;
            $results.thing2 = $NSXTThing.thing2

            write-output $results
        }  
    }
}