<#
# © 2024 Broadcom.  All Rights Reserved.  Broadcom.  The term "Broadcom" refers to
# Broadcom Inc. and/or its subsidiaries.
#>

<#
.SYNOPSIS

This script creates a NSX edge cluster on a cluster in a VI workload domain

.DESCRIPTION

This script creates an NSX edge cluster on a cluster in a VI workload domain to provide connectivity
from external networks to Supervisor Cluster objects.

To create NSX Edge Cluster on multiple VI workload domain clusters the script should be modified and
executed multiple times.

.NOTES

Prerequisites:
 - VI workload domain (vCenter server instance)
 - VI workload domain cluster

"Global parameters", "Workload domain parameters", "Edge Cluster deployment parameters" should be updated to
reflect the environment they are run in. This may require altering the spec creation script.

#>

$ErrorActionPreference = 'Stop'
$SCRIPTROOT = ($PWD.ProviderPath, $PSScriptRoot)[!!$PSScriptRoot]
. (Join-Path $SCRIPTROOT 'utils/Wait-VcfTask.ps1')
. (Join-Path $SCRIPTROOT 'utils/Wait-VcfValidation.ps1')

# --------------------------------------------------------------------------------------------------------------------------
# Global parameters
# --------------------------------------------------------------------------------------------------------------------------

$domainName = 'sfo-w01'

$domain = 'vrack.vsphere.local'
$sddcManager = @{
   Fqdn = "sddc-manager.$domain"
   User = 'administrator@vsphere.local'
   Password = 'VMware123!'
}

# --------------------------------------------------------------------------------------------------------------------------
# Workload domain parameters - stripped down version of $domainSpec from 01-deploy-vcf-workload-domain.ps1
$domainSpec = @{
   VCenterSpec = @{
      RootPassword = "VMware123!"
      NetworkDetailsSpec = @{
         DnsName = "$DomainName-vc01.$domain"
      }
   }
}

# Connect to SDDC manager
$sddcConn = Connect-VcfSddcManagerServer `
   -Server $sddcManager.Fqdn `
   -User $sddcManager.User `
   -Password $sddcManager.Password

############################################################################################################################
# Deploy Edge Cluster in the created workload domain
############################################################################################################################

# --------------------------------------------------------------------------------------------------------------------------
# Edge Cluster deployment parameters

# The VI workload cluster on which the NSX Edge Cluster will be created
$ClusterName = "$DomainName-cl01"

$edgeName = "$ClusterName-ec01"

$vcfCluster = Invoke-VcfGetClusters | `
   Select-Object -ExpandProperty Elements | `
   Where-Object { $_.Name -eq $ClusterName } | `
   Select-Object -First 1

$EdgeClusterParams = @{
   Asn = 65004
   EdgeAdminPassword = 'VMware123!VMware123!'
   EdgeAuditPassword = 'VMware123!VMware123!'
   EdgeClusterName = $edgeName
   EdgeClusterProfileType = "CUSTOM"
   EdgeClusterType = "NSX-T"
   EdgeFormFactor = "MEDIUM"
   EdgeNodeSpecs = @(
      @{
         ClusterId = $vcfCluster.Id
         EdgeNodeName = "$edgeName-en01.vrack.vsphere.local"
         EdgeTep1IP = "192.168.52.12/24"
         EdgeTep2IP = "192.168.52.13/24"
         EdgeTepGateway = "192.168.52.1"
         EdgeTepVlan = 1252
         InterRackCluster = $false
         ManagementGateway = "10.0.0.250"
         ManagementIP = "10.0.0.52/24"
         UplinkNetwork = @(
            @{
               UplinkInterfaceIP = "192.168.18.2/24"
               UplinkVlan = 2083
               AsnPeer = 65001
               PeerIP = "192.168.18.10/24"
               BgpPeerPassword = "VMware1!"
            }
            @{
               UplinkInterfaceIP = "192.168.19.2/24"
               UplinkVlan = 2084
               AsnPeer = 65001
               PeerIP = "192.168.19.10/24"
               BgpPeerPassword = "VMware1!"
            }
         )
      }
      @{
         ClusterId = $vcfCluster.Id
         EdgeNodeName = "$edgeName-en02.vrack.vsphere.local"
         EdgeTep1IP = "192.168.52.14/24"
         EdgeTep2IP = "192.168.52.15/24"
         EdgeTepGateway = "192.168.52.1"
         EdgeTepVlan = 1252
         InterRackCluster = $false
         ManagementGateway = "10.0.0.250"
         ManagementIP = "10.0.0.53/24"
         UplinkNetwork = @(
            @{
               UplinkInterfaceIP = "192.168.18.3/24"
               UplinkVlan = 2083
               AsnPeer = 65001
               PeerIP = "192.168.18.10/24"
               BgpPeerPassword = "VMware1!"
            }
            @{
               UplinkInterfaceIP = "192.168.19.3/24"
               UplinkVlan = 2084
               AsnPeer = 65001
               PeerIP = "192.168.19.10/24"
               BgpPeerPassword = "VMware1!"
            }
         )
      }
   )
   EdgeRootPassword = 'VMware123!VMware123!'
   Mtu = 9000
   SkipTepRoutabilityCheck = $true
   Tier0Name = "$edgeName-t0"
   Tier0RoutingType = "EBGP"
   Tier0ServicesHighAvailability = "ACTIVE_ACTIVE"
   Tier1Name = "$edgeName-t1"
   EdgeClusterProfileSpec = @{
      BfdAllowedHop = 255
      BfdDeclareDeadMultiple = 3
      BfdProbeInterval = 1000
      EdgeClusterProfileName = "$ClusterName-ecp01"
      StandbyRelocationThreshold = 30
   }
}
# --------------------------------------------------------------------------------------------------------------------------

# Edge cluster deployment spec construction
$edgeClusterCreationSpec = Initialize-VcfEdgeClusterCreationSpec `
   -Asn $EdgeClusterParams.Asn `
   -EdgeAdminPassword $EdgeClusterParams.EdgeAdminPassword `
   -EdgeAuditPassword $EdgeClusterParams.EdgeAuditPassword `
   -EdgeClusterName $EdgeClusterParams.EdgeClusterName `
   -EdgeClusterProfileType "CUSTOM" `
   -EdgeClusterType "NSX-T" `
   -EdgeFormFactor $EdgeClusterParams.EdgeFormFactor `
   -EdgeNodeSpecs (
      $EdgeClusterParams.EdgeNodeSpecs | ForEach-Object {
         Initialize-VcfNsxTEdgeNodeSpec `
            -ClusterId $_.ClusterId `
            -EdgeNodeName $_.EdgeNodeName `
            -EdgeTep1IP $_.EdgeTep1IP `
            -EdgeTep2IP $_.EdgeTep2IP `
            -EdgeTepGateway $_.EdgeTepGateway `
            -EdgeTepVlan $_.EdgeTepVlan `
            -InterRackCluster $_.InterRackCluster `
            -ManagementGateway $_.ManagementGateway `
            -ManagementIP $_.ManagementIP `
            -UplinkNetwork (
               $_.UplinkNetwork | ForEach-Object {
                  Initialize-VcfNsxTEdgeUplinkNetwork `
                     -UplinkInterfaceIP $_.UplinkInterfaceIP `
                     -UplinkVlan $_.UplinkVlan `
                     -AsnPeer $_.AsnPeer `
                     -PeerIP $_.PeerIP `
                     -BgpPeerPassword $_.BgpPeerPassword
               })
      }
   ) `
   -EdgeRootPassword $EdgeClusterParams.EdgeRootPassword `
   -Mtu $EdgeClusterParams.Mtu `
   -SkipTepRoutabilityCheck $EdgeClusterParams.SkipTepRoutabilityCheck `
   -Tier0Name $EdgeClusterParams.Tier0Name `
   -Tier0RoutingType $EdgeClusterParams.Tier0RoutingType `
   -Tier0ServicesHighAvailability $EdgeClusterParams.Tier0ServicesHighAvailability `
   -Tier1Name $EdgeClusterParams.Tier1Name `
   -EdgeClusterProfileSpec (Initialize-VcfNsxTEdgeClusterProfileSpec `
      -BfdAllowedHop $EdgeClusterParams.EdgeClusterProfileSpec.BfdAllowedHop `
      -BfdDeclareDeadMultiple $EdgeClusterParams.EdgeClusterProfileSpec.BfdDeclareDeadMultiple `
      -BfdProbeInterval $EdgeClusterParams.EdgeClusterProfileSpec.BfdProbeInterval `
      -EdgeClusterProfileName $EdgeClusterParams.EdgeClusterProfileSpec.EdgeClusterProfileName `
      -StandbyRelocationThreshold $EdgeClusterParams.EdgeClusterProfileSpec.StandbyRelocationThreshold)

$edgeClusterCreationSpec.EdgeClusterProfileType = $EdgeClusterParams.EdgeClusterProfileType
if ($EdgeClusterParams.EdgeClusterProfileType -eq "DEFAULT") {
   $edgeClusterCreationSpec.EdgeClusterProfileSpec = $null
}

# Edge cluster deployment spec validation
$edgeValidationResult = Invoke-VcfValidateEdgeClusterCreationSpec -edgeCreationSpec $edgeClusterCreationSpec
$edgeValidationResult =  Wait-VcfValidation `
   -Validation $edgeValidationResult `
   -UpdateValidation { param($id) Invoke-VcfGetEdgeClusterValidationByID -id $id } `
   -UpdateValidationArguments $edgeValidationResult.Id `
   -ThrowOnError

# Edge cluster deployment
$taskResult = Invoke-VcfCreateEdgeCluster -edgeCreationSpec $edgeClusterCreationSpec
$taskResult = Wait-VcfTask $taskResult -ThrowOnError

Disconnect-VcfSddcManagerServer $sddcConn