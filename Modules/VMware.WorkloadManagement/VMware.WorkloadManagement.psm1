<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
Function New-WorkloadManagement {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          05/19/2020
        Organization:  VMware
        Blog:          http://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Enable Workload Management on vSphere 7 Cluster
        .DESCRIPTION
            Enable Workload Management on vSphere 7 Cluster
        .PARAMETER ClusterName
            Name of vSphere Cluster to enable Workload Management
        .PARAMETER ControlPlaneSize
            Size of Control Plane VMs (TINY, SMALL, MEDIUM, LARGE)
        .PARAMETER MgmtNetwork
            Management Network for Control Plane VMs
        .PARAMETER MgmtNetworkStartIP
            Starting IP Address for Control Plane VMs (5 consecutive free addresses)
        .PARAMETER MgmtNetworkSubnet
            Netmask for Management Network
        .PARAMETER MgmtNetworkGateway
            Gateway for Management Network
        .PARAMETER MgmtNetworkDNS
            DNS Server(s) to use for Management Network
        .PARAMETER MgmtNetworkDNSDomain
            DNS Domain(s)
        .PARAMETER MgmtNetworkNTP
            NTP Server(s)
        .PARAMETER WorkloadNetworkVDS
            Name of vSphere 7 Distributed Virtual Switch (VDS) configured with NSX-T
        .PARAMETER WorkloadNetworkEdgeCluster
            Name of NSX-T Edge Cluster
        .PARAMETER WorkloadNetworkDNS
            DNS Server(s) to use for Workloads
        .PARAMETER WorkloadNetworkPodCIDR
            K8s POD CIDR (default: 10.244.0.0/21)
        .PARAMETER WorkloadNetworkServiceCIDR
            K8S Service CIDR (default: 10.96.0.0/24)
        .PARAMETER WorkloadNetworkIngressCIDR
            CIDR for Workload Ingress (recommend /27 or larger)
        .PARAMETER WorkloadNetworkEgressCIDR
            CIDR for Workload Egress (recommend /27 or larger)
        .PARAMETER ControlPlaneStoragePolicy
            Name of VM Storage Policy to use for Control Plane VMs
        .PARAMETER EphemeralDiskStoragePolicy
            Name of VM Storage Policy to use for Ephemeral Disk
        .PARAMETER ImageCacheStoragePolicy
            Name of VM Storage Policy to use for Image Cache
        .PARAMETER LoginBanner
            Login message to show during kubectl login
        .EXAMPLE
            New-WorkloadManagement `
                -ClusterName "Workload-Cluster" `
                -ControlPlaneSize TINY `
                -MgmtNetwork "DVPG-Management Network" `
                -MgmtNetworkStartIP "172.17.36.51" `
                -MgmtNetworkSubnet "255.255.255.0" `
                -MgmtNetworkGateway "172.17.36.253" `
                -MgmtNetworkDNS "172.17.31.5" `
                -MgmtNetworkDNSDomain "cpub.corp" `
                -MgmtNetworkNTP "5.199.135.170" `
                -WorkloadNetworkVDS "Pacific-VDS" `
                -WorkloadNetworkEdgeCluster "Edge-Cluster-01" `
                -WorkloadNetworkDNS "172.17.31.5" `
                -WorkloadNetworkIngressCIDR "172.17.36.64/27" `
                -WorkloadNetworkEgressCIDR "172.17.36.96/27" `
                -ControlPlaneStoragePolicy "pacific-gold-storage-policy" `
                -EphemeralDiskStoragePolicy "pacific-gold-storage-policy" `
                -ImageCacheStoragePolicy "pacific-gold-storage-policy"

    #>
    Param (
        [Parameter(Mandatory=$True)]$ClusterName,
        [Parameter(Mandatory=$True)][ValidateSet("TINY","SMALL","MEDIUM","LARGE")][string]$ControlPlaneSize,
        [Parameter(Mandatory=$True)]$MgmtNetwork,
        [Parameter(Mandatory=$True)]$MgmtNetworkStartIP,
        [Parameter(Mandatory=$True)]$MgmtNetworkSubnet,
        [Parameter(Mandatory=$True)]$MgmtNetworkGateway,
        [Parameter(Mandatory=$True)][string[]]$MgmtNetworkDNS,
        [Parameter(Mandatory=$True)][string[]]$MgmtNetworkDNSDomain,
        [Parameter(Mandatory=$True)]$MgmtNetworkNTP,
        [Parameter(Mandatory=$True)]$WorkloadNetworkVDS,
        [Parameter(Mandatory=$True)]$WorkloadNetworkEdgeCluster,
        [Parameter(Mandatory=$True)][string[]]$WorkloadNetworkDNS,
        [Parameter(Mandatory=$False)]$WorkloadNetworkPodCIDR="10.244.0.0/21",
        [Parameter(Mandatory=$False)]$WorkloadNetworkServiceCIDR="10.96.0.0/24",
        [Parameter(Mandatory=$True)]$WorkloadNetworkIngressCIDR,
        [Parameter(Mandatory=$True)]$WorkloadNetworkEgressCIDR,
        [Parameter(Mandatory=$True)]$ControlPlaneStoragePolicy,
        [Parameter(Mandatory=$True)]$EphemeralDiskStoragePolicy,
        [Parameter(Mandatory=$True)]$ImageCacheStoragePolicy,
        [Parameter(Mandatory=$False)]$LoginBanner
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CiS Connection found, please use Connect-CisServer`n" } Else {

        # Management Network Moref
        $networkService = Get-CisService "com.vmware.vcenter.network"
        $networkFilterSpec = $networkService.help.list.filter.Create()
        $networkFilterSpec.names = @("$MgmtNetwork")
        $mgmtNetworkMoRef = $networkService.list($networkFilterSpec).network.Value
        if ($mgmtNetworkMoRef -eq $NULL) {
            Write-Host -ForegroundColor Red "Unable to find vSphere Cluster ${MgmtNetwork}"
            break
        }

        # Cluster Moref
        $clusterService = Get-CisService "com.vmware.vcenter.cluster"
        $clusterFilterSpec = $clusterService.help.list.filter.Create()
        $clusterFilterSpec.names = @("$ClusterName")
        $clusterMoRef = $clusterService.list($clusterFilterSpec).cluster.Value
        if ($clusterMoRef -eq $NULL) {
            Write-Host -ForegroundColor Red "Unable to find vSphere Cluster ${ClusterName}"
            break
        }

        # VDS MoRef
        $vdsCompatService = Get-CisService "com.vmware.vcenter.namespace_management.distributed_switch_compatibility"
        $vdsMoRef = ($vdsCompatService.list($clusterMoref)).distributed_switch.Value
        if ($vdsMoRef -eq $NULL) {
            Write-Host -ForegroundColor Red "Unable to find VDS ${WorkloadNetworkVDS}"
            break
        }

        # NSX-T Edge Cluster
        $edgeClusterService = Get-CisService "com.vmware.vcenter.namespace_management.edge_cluster_compatibility"
        $edgeClusterMoRef = ($edgeClusterService.list($clusterMoref,$vdsMoRef)).edge_cluster.Value
        if ($edgeClusterMoRef -eq $NULL) {
            Write-Host -ForegroundColor Red "Unable to find NSX-T Edge Cluster ${WorkloadNetworkEdgeCluster}"
            break
        }

        # VM Storage Policy MoRef
        $storagePolicyService = Get-CisService "com.vmware.vcenter.storage.policies"
        $sps= $storagePolicyService.list()
        $cpSP = ($sps | where {$_.name -eq $ControlPlaneStoragePolicy}).Policy.Value
        $edSP = ($sps | where {$_.name -eq $EphemeralDiskStoragePolicy}).Policy.Value
        $icSP = ($sps | where {$_.name -eq $ImageCacheStoragePolicy}).Policy.Value
        if ($cpSP -eq $NULL) {
            Write-Host -ForegroundColor Red "Unable to find VM Storage Policy ${ControlPlaneStoragePolicy}"
            break
        }

        if ($edSP -eq $NULL) {
            Write-Host -ForegroundColor Red "Unable to find VM Storage Policy ${EphemeralDiskStoragePolicy}"
            break
        }

        if ($icSP -eq $NULL) {
            Write-Host -ForegroundColor Red "Unable to find VM Storage Policy ${ImageCacheStoragePolicy}"
            break
        }

        $nsmClusterService = Get-CisService "com.vmware.vcenter.namespace_management.clusters"
        $spec = $nsmClusterService.help.enable.spec.Create()

        $spec.size_hint = $ControlPlaneSize
        $spec.network_provider = "NSXT_CONTAINER_PLUGIN"

        $mgmtNetworkSpec = $nsmClusterService.help.enable.spec.master_management_network.Create()
        $mgmtNetworkSpec.mode = "STATICRANGE"
        $mgmtNetworkSpec.network =  $mgmtNetworkMoRef
        $mgmtNetworkSpec.address_range.starting_address = $MgmtNetworkStartIP
        $mgmtNetworkSpec.address_range.address_count = 5
        $mgmtNetworkSpec.address_range.subnet_mask = $MgmtNetworkSubnet
        $mgmtNetworkSpec.address_range.gateway = $MgmtNetworkGateway

        $spec.master_management_network = $mgmtNetworkSpec
        $spec.master_DNS = $MgmtNetworkDNS
        $spec.master_DNS_search_domains = $MgmtNetworkDNSDomain
        $spec.master_NTP_servers = $MgmtNetworkNTP

        $spec.ncp_cluster_network_spec.cluster_distributed_switch = $vdsMoRef
        $spec.ncp_cluster_network_spec.nsx_edge_cluster = $edgeClusterMoRef

        $spec.worker_DNS = $WorkloadNetworkDNS

        $serviceCidrSpec = $nsmClusterService.help.enable.spec.service_cidr.Create()
        $serviceAddress,$servicePrefix = $WorkloadNetworkServiceCIDR.split("/")
        $serviceCidrSpec.address = $serviceAddress
        $serviceCidrSpec.prefix = $servicePrefix
        $spec.service_cidr = $serviceCidrSpec

        $podCidrSpec = $nsmClusterService.help.enable.spec.ncp_cluster_network_spec.pod_cidrs.Element.Create()
        $podAddress,$podPrefix = $WorkloadNetworkPodCIDR.split("/")
        $podCidrSpec.address = $podAddress
        $podCidrSpec.prefix = $podPrefix
        $spec.ncp_cluster_network_spec.pod_cidrs = @($podCidrSpec)

        $egressCidrSpec = $nsmClusterService.help.enable.spec.ncp_cluster_network_spec.egress_cidrs.Element.Create()
        $egressAddress,$egressPrefix = $WorkloadNetworkEgressCIDR.split("/")
        $egressCidrSpec.address = $egressAddress
        $egressCidrSpec.prefix = $egressPrefix
        $spec.ncp_cluster_network_spec.egress_cidrs = @($egressCidrSpec)

        $ingressCidrSpec = $nsmClusterService.help.enable.spec.ncp_cluster_network_spec.ingress_cidrs.Element.Create()
        $ingressAddress,$ingressPrefix = $WorkloadNetworkIngressCIDR.split("/")
        $ingressCidrSpec.address = $ingressAddress
        $ingressCidrSpec.prefix = $ingressPrefix
        $spec.ncp_cluster_network_spec.ingress_cidrs = @($ingressCidrSpec)

        $spec.master_storage_policy = $cpSP
        $spec.ephemeral_storage_policy = $edSP

        $imagePolicySpec = $nsmClusterService.help.enable.spec.image_storage.Create()
        $imagePolicySpec.storage_policy = $icSP
        $spec.image_storage = $imagePolicySpec

        if($LoginBanner -eq $NULL) {
            $LoginBanner = "

            " + [char]::ConvertFromUtf32(0x1F973) + "vSphere with Kubernetes Cluster enabled by virtuallyGhetto " + [char]::ConvertFromUtf32(0x1F973) + "

"
        }
        $spec.login_banner = $LoginBanner

        try {
            Write-Host -Foreground Green "`nEnabling Workload Management on vSphere Cluster ${ClusterName} ..."
            $nsmClusterService.enable($clusterMoRef,$spec)
        } catch {
            Write-Error "Error in attempting to enable Workload Management on vSphere Cluster ${ClusterName}"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }
        Write-Host -Foreground Green "Please refer to the Workload Management UI in vCenter Server to monitor the progress of this operation"
    }
}

Function Get-WorkloadManagement {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          05/19/2020
        Organization:  VMware
        Blog:          http://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Retrieve all Workload Management Clusters
        .DESCRIPTION
            Retrieve all Workload Management Clusters
        .PARAMETER Stats
            Output additional stats pertaining to CPU, Memory and Storage
        .EXAMPLE
            Get-WorkloadManagement
        .EXAMPLE
            Get-WorkloadManagement -Stats
    #>
    Param (
        [Switch]$Stats
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CiS Connection found, please use Connect-CisServer`n" } Else {
        If (-Not $global:DefaultVIServers) { Write-error "No VI Connection found, please use Connect-VIServer`n" } Else {
            $nssClusterService = Get-CisService "com.vmware.vcenter.namespace_management.software.clusters"
            $nsInstanceService = Get-CisService "com.vmware.vcenter.namespaces.instances"
            $nsmClusterService = Get-CisService "com.vmware.vcenter.namespace_management.clusters"
            $wlClusters = $nsmClusterService.list()

            $results = @()
            foreach ($wlCluster in $wlClusters) {
                $workloadClusterId = $wlCluster.cluster
                $vSphereCluster = Get-Cluster | where {$_.id -eq "ClusterComputeResource-${workloadClusterId}"}
                $workloadCluster = $nsmClusterService.get($workloadClusterId)

                $nsCount = ($nsInstanceService.list() | where {$_.cluster -eq $workloadClusterId}).count
                $hostCount = ($vSphereCluster.ExtensionData.Host).count
                if($workloadCluster.kubernetes_status -ne "ERROR") {
                $k8sVersion = $nssClusterService.get($workloadClusterId).current_version
                } else { $k8sVersion = "UNKNOWN" }

                $tmp = [pscustomobject] @{
                    NAME = $vSphereCluster.name;
                    NAMESPACES = $nsCount;
                    HOSTS = $hostCount;
                    CONTROL_PLANE_IP = $workloadCluster.api_server_cluster_endpoint;
                    CLUSTER_STATUS = $workloadCluster.config_status;
                    K8S_STATUS = $workloadCluster.kubernetes_status;
                    VERSION = $k8sVersion;
                }

                if($Stats) {
                    $tmp | Add-Member -NotePropertyName CPU_CAPACITY -NotePropertyValue $workloadCluster.stat_summary.cpu_capacity
                    $tmp | Add-Member -NotePropertyName MEM_CAPACITY -NotePropertyValue $workloadCluster.stat_summary.memory_capacity
                    $tmp | Add-Member -NotePropertyName STORAGE_CAPACITY -NotePropertyValue $workloadCluster.stat_summary.storage_capacity
                    $tmp | Add-Member -NotePropertyName CPU_USED -NotePropertyValue $workloadCluster.stat_summary.cpu_used
                    $tmp | Add-Member -NotePropertyName MEM_USED -NotePropertyValue $workloadCluster.stat_summary.memory_used
                    $tmp | Add-Member -NotePropertyName STORAGE_USED -NotePropertyValue $workloadCluster.stat_summary.storage_used
                }

                $results+=$tmp
            }
            $results
        }
    }
}

Function Remove-WorkloadManagement {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          05/19/2020
        Organization:  VMware
        Blog:          http://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Disable Workload Management on vSphere Cluster
        .DESCRIPTION
            Disable Workload Management on vSphere Cluster
        .PARAMETER ClusterName
            Name of vSphere Cluster to disable Workload Management
        .EXAMPLE
            Remove-WorkloadManagement -ClusterName "Workload-Cluster"
    #>
    Param (
        [Parameter(Mandatory=$True)]$ClusterName
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CiS Connection found, please use Connect-CisServer`n" } Else {

        $vSphereCluster = Get-Cluster | where {$_.Name -eq $ClusterName}
        if($vSphereCluster -eq $null) {
            Write-Host -ForegroundColor Red "Unable to find vSphere Cluster ${ClusterName}"
            break
        }
        $vSphereClusterID = ($vSphereCluster.id).replace("ClusterComputeResource-","")

        $nsmClusterService = Get-CisService "com.vmware.vcenter.namespace_management.clusters"
        $workloadClusterID = ($nsmClusterService.list() | where {$_.cluster -eq $vSphereClusterID}).cluster.Value
        if($workloadClusterID -eq $null) {
            Write-Host -ForegroundColor Red "Unable to find Workload Management Cluster ${ClusterName}"
            break
        }

        try {
            Write-Host -Foreground Green "`nDisabling Workload Management on vSphere Cluster ${ClusterName} ..."
            $nsmClusterService.disable($workloadClusterID)
        } catch {
            Write-Error "Error in attempting to disable Workload Management on vSphere Cluster ${ClusterName}"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }
        Write-Host -Foreground Green "Please refer to the Workload Management UI in vCenter Server to monitor the progress of this operation"
    }
}