<#
# © 2024 Broadcom.  All Rights Reserved.  Broadcom.  The term "Broadcom" refers to
# Broadcom Inc. and/or its subsidiaries.
#>

<#
.SYNOPSIS

This script deploys a VI workload domain

.DESCRIPTION

This script creates a VI workload domain using the PowerCLI SDK module for VCF SDDC Manager.

The script can be broken into two main parts. First, the ESXi hosts are being commissioned.
Then, the actual VI domain is created using the commissioned ESXi hosts.

Both steps - ESXi host commissioning and VI domain creations - are three-stage operations themselves.
The commissioning/creation specs are constructed. The specs are validated. The actual operation is invoked.
The validation and operation invocation are long-running tasks. This requires awaiting and status tracking
until their completion. The waiting for validation and the actual operation is done using helper cmdlets -
Wait-VcfValidation and Wait-VcfTask, located in utils sub-folder.

On completion a new VI workload domain reflecting the given parameters should be created.

.NOTES

Prerequisites:
 - A VCF Management Domain
 - A minimum of three free hosts marked with the appropriate storage and at least 4 NICs.
 Two of the NICs will be used for Frontend/Management and the other two for workloads.

"Global parameters", "Host commissioning parameters", "Workload domain creation parameters" should be updated to
reflect the environment they are run in. This may require altering the spec creation script.

#>

$ErrorActionPreference = 'Stop'
$SCRIPTROOT = ($PWD.ProviderPath, $PSScriptRoot)[!!$PSScriptRoot]
. (Join-Path $SCRIPTROOT 'utils/Wait-VcfTask.ps1')
. (Join-Path $SCRIPTROOT 'utils/Wait-VcfValidation.ps1')

# --------------------------------------------------------------------------------------------------------------------------
# Global parameters
# --------------------------------------------------------------------------------------------------------------------------

# Organization name of the workload domain
$OrgName = 'VMware'

# Name of the workload domain - used as a prefix for nested inventory items
$domainName = 'sfo-w01'

$domain = 'vrack.vsphere.local'
$gateway = '10.0.0.250'
$sddcManager = @{
   Fqdn = "sddc-manager.$domain"
   User = 'administrator@vsphere.local'
   Password = 'VMware123!'
}

############################################################################################################################
# Host commissioning
############################################################################################################################

# --------------------------------------------------------------------------------------------------------------------------
# Host commissioning parameters

$esxiHosts = @(
   @{
      Fqdn = "esxi-5.$domain"
      Username = 'root'
      Password = "ESXiSddc123!"
      StorageType = "VSAN"
      LicenseKey = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
   }
   @{
      Fqdn = "esxi-6.$domain"
      Username = 'root'
      Password = "ESXiSddc123!"
      StorageType = "VSAN"
      LicenseKey = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
   }
   @{
      Fqdn = "esxi-7.$domain"
      Username = 'root'
      Password = "ESXiSddc123!"
      StorageType = "VSAN"
      LicenseKey = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
   }
   @{
      Fqdn = "esxi-8.$domain"
      Username = 'root'
      Password = "ESXiSddc123!"
      StorageType = "VSAN"
      LicenseKey = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
   }
)

# The network pool to associate the host with
$networkPoolName = 'networkpool'

# --------------------------------------------------------------------------------------------------------------------------

# Connect to SDDC manager
$sddcConn = Connect-VcfSddcManagerServer `
   -Server $sddcManager.Fqdn `
   -User $sddcManager.User `
   -Password $sddcManager.Password

## Host commissioning spec construction
$NetworkPool = Invoke-VcfGetNetworkPool | `
   Select-Object -ExpandProperty Elements | `
   Where-Object { $_.Name -eq $NetworkPoolName }

$hostCommissionSpecs = $esxiHosts | % {
   Initialize-VcfHostCommissionSpec -Fqdn $_.Fqdn `
                                    -NetworkPoolId $NetworkPool.Id `
                                    -Password $_.Password `
                                    -StorageType $_.StorageType `
                                    -Username $_.Username
}

## Host commissioning validation
$hostValidationResult = Invoke-VcfValidateHostCommissionSpec -HostCommissionSpecs $hostCommissionSpecs
$hostValidationResult =  Wait-VcfValidation `
   -Validation $hostValidationResult `
   -UpdateValidation { param($id) Invoke-VcfGetHostCommissionValidationByID -id $id } `
   -UpdateValidationArguments $hostValidationResult.Id `
   -ThrowOnError

## Host commissioning
$commisionTask = Invoke-VcfCommissionHosts -hostCommissionSpecs $hostCommissionSpecs
$commisionTask = Wait-VcfTask $commisionTask -ThrowOnError


############################################################################################################################
# Workload domain creation
############################################################################################################################

# --------------------------------------------------------------------------------------------------------------------------
# Workload domain creation parameters

$domainSpec = @{
   DomainName = $DomainName
   OrgName = $OrgName
   VCenterSpec = @{
      Name = "$DomainName-vc01"
      DatacenterName = "$DomainName-dc01"
      RootPassword = "VMware123!"
      NetworkDetailsSpec = @{
         DnsName = "$DomainName-vc01.$domain"
         IpAddress = "10.0.0.40"
         SubnetMask = "255.255.255.0"
         Gateway = $gateway
      }
   }
   ComputeSpec = @{
      ClusterSpecs = @(
         @{
            DatastoreSpec = @{
               VSanDatastoreSpec = @{
                  DatastoreName = "$DomainName-ds01"
                  FailuresToTolerate = 1
                  LicenseKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
               }
            }
            NetworkSpec = @{
               VdsSpecs = @(
                  @{
                     Name = "$DomainName-vds01"
                     PortGroups = @(
                        @{
                           Name = 'vSAN'
                           TransportType = 'VSAN'
                        }
                        @{
                           Name = 'management'
                           TransportType = 'MANAGEMENT'
                        }
                        @{
                           Name = 'vmotion'
                           TransportType = 'VMOTION'
                        }
                     )
                  }
                  @{
                     Name = "$DomainName-vds02"
                     IsUsedByNsxt = $true
                  }
               )
               NsxClusterSpec = @{
                  NsxTClusterSpec = @{
                     GeneveVlanId = 0
                  }
               }
            }
            Name = "$DomainName-cl01"
         }
      )
   }
   NsxTSpec = @{
      NsxManagerSpecs = @(
         @{
            Name = "$domainName-nsx01a"
            NetworkDetailsSpec = @{
               DnsName = "$domainName-nsx01a.$domain"
               IpAddress = "10.0.0.41"
               SubnetMask = "255.255.255.0"
               Gateway = $gateway
            }
         }
         @{
            Name = "$domainName-nsx01b"
            NetworkDetailsSpec = @{
               DnsName = "$domainName-nsx01b.$domain"
               IpAddress = "10.0.0.42"
               SubnetMask = "255.255.255.0"
               Gateway = $gateway
            }
         }
         @{
            Name = "$domainName-nsx01c"
            NetworkDetailsSpec = @{
               DnsName = "$domainName-nsx01c.$domain"
               IpAddress = "10.0.0.43"
               SubnetMask = "255.255.255.0"
               Gateway = $gateway
            }
         }
      )
      FormFactor = 'large'
      LicenseKey = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
      NSXManagerAdminPassword = "VMware123!123"
      Vip = '10.0.0.44'
      VipFqdn = "$domainName-nsx01.$domain"
   }
}
# --------------------------------------------------------------------------------------------------------------------------

## Workload domain spec construction
$esxiFqdns = $esxiHosts | Select-Object -ExpandProperty Fqdn
$VcfHost = Invoke-VcfGetHosts -status "UNASSIGNED_USEABLE" | `
   Select-Object -ExpandProperty Elements | `
   Where-Object { $esxiFqdns -contains $_.Fqdn }

$ComputeSpec = Initialize-VcfComputeSpec -ClusterSpecs (
   $domainSpec.ComputeSpec.ClusterSpecs | ForEach-Object {
      $_clusterSpec = $_

      Initialize-VcfClusterSpec `
         -DatastoreSpec (
            Initialize-VcfDatastoreSpec `
               -VsanDatastoreSpec (
                  Initialize-VcfVsanDatastoreSpec `
                     -DatastoreName $_.DatastoreSpec.VSanDatastoreSpec.DatastoreName `
                     -FailuresToTolerate $_.DatastoreSpec.VSanDatastoreSpec.FailuresToTolerate `
                     -LicenseKey $_.DatastoreSpec.VSanDatastoreSpec.LicenseKey
               )) `
         -HostSpecs (
            $VcfHost | ForEach-Object {
               $esxiHost = $esxiHosts | Where-Object { $_.Fqdn -eq $_.Fqdn } | Select-Object -First 1

               Initialize-VcfHostSpec `
                  -Id $_.Id `
                  -LicenseKey $esxiHost.LicenseKey `
                  -HostNetworkSpec (
                     Initialize-VcfHostNetworkSpec -VmNics @(
                        Initialize-VcfVmNic -Id 'vmnic0' -VdsName $_clusterSpec.NetworkSpec.VdsSpecs[0].Name
                        Initialize-VcfVmNic -Id 'vmnic1' -VdsName $_clusterSpec.NetworkSpec.VdsSpecs[0].Name
                        Initialize-VcfVmNic -Id 'vmnic2' -VdsName $_clusterSpec.NetworkSpec.VdsSpecs[1].Name
                        Initialize-VcfVmNic -Id 'vmnic3' -VdsName $_clusterSpec.NetworkSpec.VdsSpecs[1].Name
                     ))
            }
         ) `
         -Name $_.Name `
         -NetworkSpec (
            Initialize-VcfNetworkSpec `
               -NsxClusterSpec (
                  Initialize-VcfNsxClusterSpec -NsxTClusterSpec (
                     Initialize-VcfNsxTClusterSpec `
                        -GeneveVlanId $_.NetworkSpec.NsxClusterSpec.NsxTClusterSpec.GeneveVlanId
                        )
                  ) `
               -VdsSpecs @(
                  Initialize-VcfVdsSpec -Name $_.NetworkSpec.VdsSpecs[0].Name `
                     -PortGroupSpecs (
                        $_.NetworkSpec.VdsSpecs[0].PortGroups | ForEach-Object {
                           Initialize-VcfPortgroupSpec `
                              -Name $_.Name `
                              -TransportType $_.TransportType
                        })
                  Initialize-VcfVdsSpec -Name $_.NetworkSpec.VdsSpecs[1].Name `
                     -IsUsedByNsxt $_.NetworkSpec.VdsSpecs[1].IsUsedByNsxt
                     ))
   })


$DomainCreationSpec = Initialize-VcfDomainCreationSpec `
   -ComputeSpec $ComputeSpec `
   -DomainName $domainSpec.DomainName `
   -NsxTSpec (
      Initialize-VcfNsxTSpec `
         -FormFactor $domainSpec.NsxTSpec.FormFactor `
         -LicenseKey $domainSpec.NsxTSpec.LicenseKey `
         -NsxManagerAdminPassword $domainSpec.NsxTSpec.NSXManagerAdminPassword `
         -NsxManagerSpecs (
            $domainSpec.NsxTSpec.NsxManagerSpecs | ForEach-Object {
               Initialize-VcfNsxManagerSpec `
                  -Name $_.Name `
                  -NetworkDetailsSpec (
                     Initialize-VcfNetworkDetailsSpec `
                        -DnsName $_.NetworkDetailsSpec.DnsName `
                        -IpAddress $_.NetworkDetailsSpec.IpAddress `
                        -SubnetMask $_.NetworkDetailsSpec.SubnetMask `
                        -Gateway $_.NetworkDetailsSpec.Gateway)
            }
         ) `
         -Vip $domainSpec.NsxTSpec.Vip `
         -VipFqdn $domainSpec.NsxTSpec.VipFqdn) `
   -OrgName $domainSpec.OrgName `
   -VcenterSpec (
      Initialize-VcfVcenterSpec `
         -DatacenterName $domainSpec.VCenterSpec.DatacenterName `
         -Name $domainSpec.VCenterSpec.Name `
         -NetworkDetailsSpec (
            Initialize-VcfNetworkDetailsSpec `
               -DnsName $domainSpec.VCenterSpec.NetworkDetailsSpec.DnsName `
               -IpAddress $domainSpec.VCenterSpec.NetworkDetailsSpec.IpAddress `
               -SubnetMask $domainSpec.VCenterSpec.NetworkDetailsSpec.SubnetMask `
               -Gateway $domainSpec.VCenterSpec.NetworkDetailsSpec.Gateway
         ) `
         -RootPassword $domainSpec.VCenterSpec.RootPassword)

# Workload domain spec validation
$domainValidationResult = Invoke-VcfValidateDomainCreationSpec -domainCreationSpec $DomainCreationSpec
$domainValidationResult =  Wait-VcfValidation `
   -Validation $domainValidationResult `
   -ThrowOnError

# Workload domain creation
$creationTask = Invoke-VcfCreateDomain -domainCreationSpec $DomainCreationSpec
$creationTask = Wait-VcfTask $creationTask -ThrowOnError

Disconnect-VcfSddcManagerServer $sddcConn