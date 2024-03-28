<#
# © 2024 Broadcom.  All Rights Reserved.  Broadcom.  The term "Broadcom" refers to
# Broadcom Inc. and/or its subsidiaries.
#>

<#
.SYNOPSIS

This script enables Workload Management (Kubernetes)

.DESCRIPTION

This script enables Workload Management (Kubernetes) and sets it up for AI workloads.

The script:

  1. Enables the Supervisor cluster
  2. Creates content library for the deep learning VM template
  3. Creates GPU-enabled VMClass
  4. Creates namespace(s) and assigns the created VMClass and assigns deep learning VM content library

.NOTES

Prerequisites:
 - VI workload domain (vCenter server instance)
 - NSX Edge Cluster

"Global parameters", "Workload domain parameters", "WCP enablement parameters" should be updated to
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

$dnsServer = '10.0.0.250'
$ntpServer = '10.0.0.250'

$domain = 'vrack.vsphere.local'

# --------------------------------------------------------------------------------------------------------------------------
# Workload domain parameters - stripped down version of $domainSpec from 01-deploy-vcf-workload-domain.ps1
$domainSpec = @{
   VCenterSpec = @{
      RootPassword = "VMware123!"
      NetworkDetailsSpec = @{
         DnsName = "$DomainName-vc01.$domain"
      }
   }
   ComputeSpec = @{
      ClusterSpecs = @(
         @{
            DatastoreSpec = @{
               VSanDatastoreSpec = @{
                  DatastoreName = "$DomainName-ds01"
               }
            }
            Name = "$DomainName-cl01"
            NetworkSpec = @{
               VdsSpecs = @(
                  @{
                     Name = "$DomainName-vds01"
                     PortGroups = @(
                        @{
                           Name = 'management'
                           TransportType = 'MANAGEMENT'
                        }
                     )
                  }
                  @{
                     Name = "$DomainName-vds02"
                  }
               )
            }
         }
      )
      NsxTSpec = @{
         NSXManagerAdminPassword = "VMware123!123"
         VipFqdn = "$domainName-nsx01.$domain"
      }
   }
}

$EdgeClusterParams = @{
   EdgeClusterName = "$($domainSpec.ComputeSpec.ClusterSpecs[0].Name)-ec01"
}

############################################################################################################################
# Enable WCP
############################################################################################################################

# --------------------------------------------------------------------------------------------------------------------------
# WCP enablement parameters
$ContentLibraryParams = @{
   Name = "$DomainName-lib01"
   Url = 'https://wp-content.vmware.com/v2/latest/lib.json'
   SslThumbprint = 'AD:DA:3D:B9:99:75:1D:FF:2E:28:CA:92:83:64:38:20:5B:55:94:DC'
   DownloadOnDemand = $true
   Datastore = $domainSpec.ComputeSpec.ClusterSpecs[0].DatastoreSpec.VSanDatastoreSpec.DatastoreName
}
$DeepLearningVMContentLibraryParams = @{
   Name = "$DomainName-lib02"
   Url = 'https://packages.vmware.com/dl-vm/lib.json'
   SslThumbprint = 'AD:DA:3D:B9:99:75:1D:FF:2E:28:CA:92:83:64:38:20:5B:55:94:DC'
   DownloadOnDemand = $true
   Datastore = $domainSpec.ComputeSpec.ClusterSpecs[0].DatastoreSpec.VSanDatastoreSpec.DatastoreName
}

$ClusterName = $domainSpec.ComputeSpec.ClusterSpecs[0].Name

$WcpClusterParams = @{
   SizeHint = 'Small'
   ManagementNetwork = @{
      Name = (
         $domainSpec.ComputeSpec.ClusterSpecs[0].
            NetworkSpec.VdsSpecs[0].
               PortGroups | Where-Object {$_.TransportType -eq 'MANAGEMENT'} | ForEach-Object { $_.Name } )
      Mode = 'StaticRange'
      StartIpAddress = "10.0.0.150"
      Gateway = "10.0.0.250"
      SubnetMask = '255.255.255.0'
      RangeSize = 5
   }
   MasterDnsNames = @(, "$ClusterName.$domain")
   MasterNtpServer = @(, $ntpServer)
   Cluster = $ClusterName
   EphemeralStoragePolicy = "$ClusterName vSAN Storage Policy"
   ImageStoragePolicy = "$ClusterName vSAN Storage Policy"
   MasterStoragePolicy = "$ClusterName vSAN Storage Policy"
   NcpClusterNetworkSpec = @{
      NsxEdgeClusterId = ''
      DistributedSwitch = $domainSpec.ComputeSpec.ClusterSpecs[0].NetworkSpec.VdsSpecs[1].Name
      PodCIDRs = @(, "10.244.10.0/23")
      ExternalIngressCIDRs = @(, "10.10.11.0/24")
      ExternalEgressCIDRs = @(, "10.10.10.0/24")
   }
   ServiceCIDR = "10.10.12.0/24"
   WorkerDnsServer = @(, $dnsServer)
   MasterDnsServerIpAddress = @(, $dnsServer)
   MasterDnsSearchDomain = @(, $domain)
   ContentLibrary = $null
   LicenseKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
   Namespace = @("$DomainName-wmn01", "$DomainName-tkc01")
   NamespaceStoragePolicy = "$ClusterName vSAN Storage Policy"
   NamespaceEditUserGroup = "gg-kub-admins"
   NamespaceViewUserGroup = "gg-kub-readonly"
   VmClassNamespace = @{
      "$DomainName-tkc01" = @(, "best-effort-small-vgpu")
   }
   ContentLibraryNamespace = @{
      "$DomainName-tkc01" = @()
   }
   VmClass = @(
      @{
         Id = "best-effort-small-vgpu"
         CpuCount = 2
         MemoryMB = 4096
         MemoryReservation = 100
         VGpuProfiles = @(
            'grid_a100-4c',
            'grid_a100-8c'
         )
      }
   )
}
# --------------------------------------------------------------------------------------------------------------------------

# Get Edge cluster Id from NSXt manager
$nsxtConn = Connect-NsxtServer -Server $domainSpec.ComputeSpec.NsxTSpec.vipFqdn -User 'admin' -password $domainSpec.ComputeSpec.NsxTSpec.NSXManagerAdminPassword
$svc = Get-NsxtService 'com.vmware.nsx.edge_clusters'
$nsxEdgeCluster = $svc.list().results | Where-Object { $_.display_name -eq $EdgeClusterParams.EdgeClusterName }
$WcpClusterParams.NcpClusterNetworkSpec.NsxEdgeClusterId = $nsxEdgeCluster.Id
$nsxtConn | Disconnect-NsxtServer -Confirm:$false

# Connect to the VCF Workload domain VC
$vcConn = Connect-ViServer -Server $domainSpec.VCenterSpec.NetworkDetailsSpec.DnsName `
   -User administrator@vsphere.local `
   -Password $domainSpec.VCenterSpec.RootPassword

# Create subscribed content library to https://wp-content.vmware.com/v2/latest/lib.json
$contentLibrary = New-ContentLibrary `
   -Name $ContentLibraryParams.Name `
   -Datastore $ContentLibraryParams.Datastore `
   -SubscriptionUrl $ContentLibraryParams.Url `
   -DownloadContentOnDemand:($ContentLibraryParams.DownloadOnDemand) `
   -SslThumbprint $ContentLibraryParams.SslThumbprint

$WcpClusterParams.ContentLibrary = $contentLibrary

# Create subscribed content library to https://packages.vmware.com/dl-vm/lib.json
$dlvmContentLibrary = New-ContentLibrary `
   -Name $DeepLearningVMContentLibraryParams.Name `
   -Datastore $DeepLearningVMContentLibraryParams.Datastore `
   -SubscriptionUrl $DeepLearningVMContentLibraryParams.Url `
   -DownloadContentOnDemand:($DeepLearningVMContentLibraryParams.DownloadOnDemand) `
   -SslThumbprint $DeepLearningVMContentLibraryParams.SslThumbprint

$WcpClusterParams.ContentLibraryNamespace["$DomainName-tkc01"] = @(, $dlvmContentLibrary.Id)

# Enable WCP in the VCF workload domain VC
$wcpCluster = Enable-WMCluster `
   -SizeHint $WcpClusterParams.SizeHint `
   -ManagementVirtualNetwork (Get-VirtualNetwork -Name $WcpClusterParams.ManagementNetwork.Name) `
   -ManagementNetworkMode $WcpClusterParams.ManagementNetwork.Mode `
   -ManagementNetworkStartIpAddress $WcpClusterParams.ManagementNetwork.StartIpAddress `
   -ManagementNetworkAddressRangeSize $WcpClusterParams.ManagementNetwork.RangeSize `
   -ManagementNetworkGateway $WcpClusterParams.ManagementNetwork.Gateway `
   -ManagementNetworkSubnetMask $WcpClusterParams.ManagementNetwork.SubnetMask `
   -MasterDnsNames $WcpClusterParams.MasterDnsNames `
   -MasterNtpServer $WcpClusterParams.MasterNtpServer `
   -Cluster (Get-Cluster -Name $WcpClusterParams.Cluster) `
   -EphemeralStoragePolicy (Get-SpbmStoragePolicy -Name $WcpClusterParams.EphemeralStoragePolicy) `
   -ImageStoragePolicy (Get-SpbmStoragePolicy -Name $WcpClusterParams.ImageStoragePolicy) `
   -MasterStoragePolicy (Get-SpbmStoragePolicy -Name $WcpClusterParams.MasterStoragePolicy) `
   -NsxEdgeClusterId $WcpClusterParams.NcpClusterNetworkSpec.NsxEdgeClusterId `
   -DistributedSwitch (Get-VDSwitch -Name $WcpClusterParams.NcpClusterNetworkSpec.DistributedSwitch) `
   -PodCIDRs $WcpClusterParams.NcpClusterNetworkSpec.PodCIDRs `
   -ServiceCIDR $WcpClusterParams.ServiceCIDR `
   -ExternalIngressCIDRs $WcpClusterParams.NcpClusterNetworkSpec.ExternalIngressCIDRs `
   -ExternalEgressCIDRs $WcpClusterParams.NcpClusterNetworkSpec.ExternalEgressCIDRs `
   -WorkerDnsServer $WcpClusterParams.WorkerDnsServer `
   -MasterDnsServerIpAddress $WcpClusterParams.MasterDnsServerIpAddress `
   -MasterDnsSearchDomain $WcpClusterParams.MasterDnsSearchDomain `
   -ContentLibrary $contentLibrary

# Create VM classes
$WcpClusterParams.VmClass | ForEach-Object {
   Invoke-CreateNamespaceManagementVirtualMachineClasses `
      -NamespaceManagementVirtualMachineClassesCreateSpec (
         Initialize-NamespaceManagementVirtualMachineClassesCreateSpec `
            -Id $_.Id `
            -CpuCount $_.CpuCount `
            -MemoryMB $_.MemoryMB `
            -MemoryReservation $_.MemoryReservation `
            -Devices (
               Initialize-NamespaceManagementVirtualMachineClassesVirtualDevices `
                  -VgpuDevices (
                     $_.VGpuProfiles | ForEach-Object {
                        Initialize-NamespaceManagementVirtualMachineClassesVGPUDevice -ProfileName $_
                     })))
}

# Deploy Namespaces
$WcpClusterParams.Namespace | ForEach-Object {
   $wmNamespace = New-WMNamespace `
      -Name $_ `
      -Cluster (Get-Cluster -Name $WcpClusterParams.Cluster)
   $wmNamespace | New-WMNamespaceStoragePolicy `
      -StoragePolicy (Get-SpbmStoragePolicy -Name $WcpClusterParams.NamespaceStoragePolicy) | Out-Null

   # Assign the Supervisor Namespace Roles to Active Directory Groups
   $wmNamespace | New-WMNamespacePermission `
      -Role 'Edit' `
      -Domain $domain `
      -PrincipalType 'Group' `
      -PrincipalName $WcpClusterParams.NamespaceEditUserGroup `
      -ErrorAction SilentlyContinue | Out-Null

   $wmNamespace | New-WMNamespacePermission `
      -Role 'View' `
      -Domain $domain `
      -PrincipalType 'Group' `
      -PrincipalName $WcpClusterParams.NamespaceViewUserGroup `
      -ErrorAction SilentlyContinue | Out-Null

   if ($WcpClusterParams.VmClassNamespace.ContainsKey($_)) {
      Invoke-UpdateNamespaceInstances -Namespace $_ -NamespacesInstancesUpdateSpec (
         Initialize-NamespacesInstancesUpdateSpec -VmServiceSpec (
            Initialize-NamespacesInstancesVMServiceSpec -VmClasses $WcpClusterParams.VmClassNamespace[$_] -ContentLibraries $WcpClusterParams.ContentLibraryNamespace[$_]
         )
      )
   }
}

$vcConn | Disconnect-VIServer -Confirm:$false