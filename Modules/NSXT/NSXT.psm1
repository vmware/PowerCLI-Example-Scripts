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

        class NSXTLogicalRouter {
            [string]$Name
            [string]$Logical_router_id
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
            
            $results = [NSXTLogicalRouter]::new()
            $results.Name = $NSXLogicalRouter.display_name;
            $results.Logical_router_id = $NSXLogicalRouter.Id;
            $results.Tags = $NSXLogicalRouter.tags;
            $results.edge_cluster_id = $NSXLogicalRouter.edge_cluster_id;
            $results.router_type = $NSXLogicalRouter.router_type;
            $results.high_availability_mode = $NSXLogicalRouter.high_availability_mode;
            $results.failover_mode =$NSXLogicalRouter.failover_mode;
            $results.external_transit = $NSXLogicalRouter.advanced_config.external_transit_networks;
            $results.internal_transit = $NSXLogicalRouter.advanced_config.internal_transit_network
            write-output $results
        }  
    }
}

Function Get-NSXTRoutingTable {
    Param (
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Logical_router_id,
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Tranport_node_id
    )

    Begin
    {
        $NSXTRoutingTableService = Get-NsxtService -Name "com.vmware.nsx.logical_routers.routing.route_table"

        class NSXTRoutingTable {
                [string]$Name
                hidden [string]$Id
                hidden $tags = [System.Collections.Generic.List[string]]::new()
                #more things need to be added when .list actually works
        }
    }    
    
    Process
    {
        $NSXTRoutingTable = [NSXTRoutingTable]::new()
        
        # this does not work, bug report submitted to PowerCLI team
        $NSXTRoutingTable = $NSXTRoutingTableService.list($Logical_router_id, $transport_node_id)

        write-output $NSXTRoutingTable
    }
}
