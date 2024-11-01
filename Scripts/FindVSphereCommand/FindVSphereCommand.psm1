<#
# © 2024 Broadcom.  All Rights Reserved.  Broadcom Confidential.  The term "Broadcom" refers to
# Broadcom Inc. and/or its subsidiaries.
#>

enum HttpMethod {
   Unknown;
   Get;
   Post;
   Patch;
   Put;
   Delete;
   Head;
   Trace;
   Options;
}

class Operation {
   [string] $Name
   [string] $CommandName
   [string] $ApiName
   [string] $Path
   [string[]] $Tags
   [string[]] $RelatedCommands
   [string] $Method

   [string] ToString() {
      return "$($this.Name) $($this.Method) $($this.Path)"
   }
}

function Find-VSphereCommand {
   [CmdletBinding(
      ConfirmImpact = "None",
      DefaultParameterSetName = "Default",
      SupportsPaging = $false,
      PositionalBinding = $false,
      RemotingCapability = "None",
      SupportsShouldProcess = $false,
      SupportsTransactions = $false)]
   [OutputType([Operation])]

   Param (
      [Parameter(Position = 0)]
      [HttpMethod]
      $Method = [HttpMethod]::Unknown,

      [Parameter(Position = 1)]
      [string]
      $Path,

      [Parameter(Position = 2)]
      [string]
      $Name,

      [Parameter(Position = 3)]
      [string]
      $Tag,

      [Parameter(Position = 4)]
      [string]
      $Command
   )

   if ($null -eq $script:powerCLIVsphereSdkCommands) {
      $jsonObjects = ConvertFrom-Json -InputObject $script:powerCLIVsphereSdkCommandsJson
      $script:powerCLIVsphereSdkCommands = $jsonObjects | ForEach-Object {
         $op = [Operation]::new()
         $op.Name = $_.Name
         $op.ApiName = $_.ApiName
         $op.CommandName = $_.CommandInfo
         $op.Method = $_.Method
         $op.Path = $_.Path
         $op.RelatedCommands = $_.RelatedCommandInfos
         $op.Tags = $_.Tags

         Write-Output $op
      }
   }

   $script:powerCLIVsphereSdkCommands | Where-Object {
      ($_.Method -eq $Method -or [HttpMethod]::Unknown -eq $Method) -and `
      ($_.Path -like $Path -or [string]::IsNullOrEmpty($Path)) -and `
      ($_.Name -like $Name -or [string]::IsNullOrEmpty($Name)) -and `
      ($_.Tag -like $Tag -or [string]::IsNullOrEmpty($Tag)) -and `
      ($_.Command -like $Command -or [string]::IsNullOrEmpty($Command))
   }
}

Export-ModuleMember -Function Find-VSphereCommand

$script:powerCLIVsphereSdkCommands = $null

$script:powerCLIVsphereSdkCommandsJson = @"
[
  {
    "Name": "CreateNamespaceDomainSubjectAccess",
    "CommandInfo": "Invoke-CreateNamespaceDomainSubjectAccess",
    "ApiName": "AccessApi",
    "Path": "/api/vcenter/namespaces/instances/{namespace}/access/{domain}/{subject}",
    "Tags": "Access",
    "RelatedCommandInfos": "Initialize-NamespacesAccessCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteNamespaceDomainSubjectAccess",
    "CommandInfo": "Invoke-DeleteNamespaceDomainSubjectAccess",
    "ApiName": "AccessApi",
    "Path": "/api/vcenter/namespaces/instances/{namespace}/access/{domain}/{subject}",
    "Tags": "Access",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetNamespaceDomainSubjectAccess",
    "CommandInfo": "Invoke-GetNamespaceDomainSubjectAccess",
    "ApiName": "AccessApi",
    "Path": "/api/vcenter/namespaces/instances/{namespace}/access/{domain}/{subject}",
    "Tags": "Access",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetNamespaceDomainSubjectAccess",
    "CommandInfo": "Invoke-SetNamespaceDomainSubjectAccess",
    "ApiName": "AccessApi",
    "Path": "/api/vcenter/namespaces/instances/{namespace}/access/{domain}/{subject}",
    "Tags": "Access",
    "RelatedCommandInfos": "Initialize-NamespacesAccessSetSpec",
    "Method": "PUT"
  },
  {
    "Name": "CreateStatsAcqSpecs",
    "CommandInfo": "Invoke-CreateStatsAcqSpecs",
    "ApiName": "AcqSpecsApi",
    "Path": "/api/stats/acq-specs",
    "Tags": "AcqSpecs",
    "RelatedCommandInfos": "Initialize-AcqSpecsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteIdStatsAcqSpecs",
    "CommandInfo": "Invoke-DeleteIdStatsAcqSpecs",
    "ApiName": "AcqSpecsApi",
    "Path": "/api/stats/acq-specs/{id}",
    "Tags": "AcqSpecs",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetIdStatsAcqSpecs",
    "CommandInfo": "Invoke-GetIdStatsAcqSpecs",
    "ApiName": "AcqSpecsApi",
    "Path": "/api/stats/acq-specs/{id}",
    "Tags": "AcqSpecs",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListStatsAcqSpecs",
    "CommandInfo": "Invoke-ListStatsAcqSpecs",
    "ApiName": "AcqSpecsApi",
    "Path": "/api/stats/acq-specs",
    "Tags": "AcqSpecs",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateIdStatsAcqSpecs",
    "CommandInfo": "Invoke-UpdateIdStatsAcqSpecs",
    "ApiName": "AcqSpecsApi",
    "Path": "/api/stats/acq-specs/{id}",
    "Tags": "AcqSpecs",
    "RelatedCommandInfos": "Initialize-AcqSpecsUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetClusterActive",
    "CommandInfo": "Invoke-GetClusterActive",
    "ApiName": "ActiveApi",
    "Path": "/api/vcenter/vcha/cluster/active__action=get",
    "Tags": "Active",
    "RelatedCommandInfos": "Initialize-VchaClusterActiveGetRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CheckMigrateActiveDirectory",
    "CommandInfo": "Invoke-CheckMigrateActiveDirectory",
    "ApiName": "ActiveDirectoryApi",
    "Path": "/api/vcenter/deployment/migrate/active-directory__action=check",
    "Tags": "ActiveDirectory",
    "RelatedCommandInfos": "Initialize-DeploymentMigrateActiveDirectoryCheckSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteClusterDraftSoftwareAddOn",
    "CommandInfo": "Invoke-DeleteClusterDraftSoftwareAddOn",
    "ApiName": "AddOnApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/add-on",
    "Tags": "AddOn",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteHostDraftSoftwareAddOn",
    "CommandInfo": "Invoke-DeleteHostDraftSoftwareAddOn",
    "ApiName": "AddOnApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/add-on",
    "Tags": "AddOn",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterDraftSoftwareAddOn",
    "CommandInfo": "Invoke-GetClusterDraftSoftwareAddOn",
    "ApiName": "AddOnApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/add-on",
    "Tags": "AddOn",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterSoftwareAddOn",
    "CommandInfo": "Invoke-GetClusterSoftwareAddOn",
    "ApiName": "AddOnApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/add-on",
    "Tags": "AddOn",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostDraftSoftwareAddOn",
    "CommandInfo": "Invoke-GetHostDraftSoftwareAddOn",
    "ApiName": "AddOnApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/add-on",
    "Tags": "AddOn",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostSoftwareAddOn",
    "CommandInfo": "Invoke-GetHostSoftwareAddOn",
    "ApiName": "AddOnApi",
    "Path": "/api/esx/settings/hosts/{host}/software/add-on",
    "Tags": "AddOn",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetClusterDraftSoftwareAddOn",
    "CommandInfo": "Invoke-SetClusterDraftSoftwareAddOn",
    "ApiName": "AddOnApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/add-on",
    "Tags": "AddOn",
    "RelatedCommandInfos": "Initialize-SettingsAddOnSpec",
    "Method": "PUT"
  },
  {
    "Name": "SetHostDraftSoftwareAddOn",
    "CommandInfo": "Invoke-SetHostDraftSoftwareAddOn",
    "ApiName": "AddOnApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/add-on",
    "Tags": "AddOn",
    "RelatedCommandInfos": "Initialize-SettingsAddOnSpec",
    "Method": "PUT"
  },
  {
    "Name": "ListDepotContentAddOns",
    "CommandInfo": "Invoke-ListDepotContentAddOns",
    "ApiName": "AddOnsApi",
    "Path": "/api/esx/settings/depot-content/add-ons",
    "Tags": "AddOns",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetTenantBrokerAdminClient",
    "CommandInfo": "Invoke-GetTenantBrokerAdminClient",
    "ApiName": "AdminClientApi",
    "Path": "/api/vcenter/identity/broker/tenants/{tenant}/admin-client",
    "Tags": "AdminClient",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "AddManagementAdministrators",
    "CommandInfo": "Invoke-AddManagementAdministrators",
    "ApiName": "AdministratorsApi",
    "Path": "/api/hvc/management/administrators__action=add",
    "Tags": "Administrators",
    "RelatedCommandInfos": "Initialize-HvcManagementAdministratorsAddRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetHvcManagementAdministrators",
    "CommandInfo": "Invoke-GetHvcManagementAdministrators",
    "ApiName": "AdministratorsApi",
    "Path": "/api/hvc/management/administrators",
    "Tags": "Administrators",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RemoveManagementAdministrators",
    "CommandInfo": "Invoke-RemoveManagementAdministrators",
    "ApiName": "AdministratorsApi",
    "Path": "/api/hvc/management/administrators__action=remove",
    "Tags": "Administrators",
    "RelatedCommandInfos": "Initialize-HvcManagementAdministratorsRemoveRequestBody",
    "Method": "POST"
  },
  {
    "Name": "SetHvcManagementAdministrators",
    "CommandInfo": "Invoke-SetHvcManagementAdministrators",
    "ApiName": "AdministratorsApi",
    "Path": "/api/hvc/management/administrators",
    "Tags": "Administrators",
    "RelatedCommandInfos": "Initialize-HvcManagementAdministratorsSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "GetHealthApplmgmt",
    "CommandInfo": "Invoke-GetHealthApplmgmt",
    "ApiName": "ApplmgmtApi",
    "Path": "/api/appliance/health/applmgmt",
    "Tags": "Applmgmt",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterPoliciesApply",
    "CommandInfo": "Invoke-GetClusterPoliciesApply",
    "ApiName": "ApplyApi",
    "Path": "/api/esx/settings/clusters/{cluster}/policies/apply",
    "Tags": "Apply",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetDefaultsClustersPoliciesApply",
    "CommandInfo": "Invoke-GetDefaultsClustersPoliciesApply",
    "ApiName": "ApplyApi",
    "Path": "/api/esx/settings/defaults/clusters/policies/apply",
    "Tags": "Apply",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetDefaultsHostsPoliciesApply",
    "CommandInfo": "Invoke-GetDefaultsHostsPoliciesApply",
    "ApiName": "ApplyApi",
    "Path": "/api/esx/settings/defaults/hosts/policies/apply",
    "Tags": "Apply",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostPoliciesApply",
    "CommandInfo": "Invoke-GetHostPoliciesApply",
    "ApiName": "ApplyApi",
    "Path": "/api/esx/settings/hosts/{host}/policies/apply",
    "Tags": "Apply",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetClusterPoliciesApply",
    "CommandInfo": "Invoke-SetClusterPoliciesApply",
    "ApiName": "ApplyApi",
    "Path": "/api/esx/settings/clusters/{cluster}/policies/apply",
    "Tags": "Apply",
    "RelatedCommandInfos": "Initialize-SettingsClustersPoliciesApplyConfiguredPolicySpec",
    "Method": "PUT"
  },
  {
    "Name": "SetDefaultsClustersPoliciesApply",
    "CommandInfo": "Invoke-SetDefaultsClustersPoliciesApply",
    "ApiName": "ApplyApi",
    "Path": "/api/esx/settings/defaults/clusters/policies/apply",
    "Tags": "Apply",
    "RelatedCommandInfos": "Initialize-SettingsDefaultsClustersPoliciesApplyConfiguredPolicySpec",
    "Method": "PUT"
  },
  {
    "Name": "SetDefaultsHostsPoliciesApply",
    "CommandInfo": "Invoke-SetDefaultsHostsPoliciesApply",
    "ApiName": "ApplyApi",
    "Path": "/api/esx/settings/defaults/hosts/policies/apply",
    "Tags": "Apply",
    "RelatedCommandInfos": "Initialize-SettingsDefaultsHostsPoliciesApplyConfiguredPolicySpec",
    "Method": "PUT"
  },
  {
    "Name": "SetHostPoliciesApply",
    "CommandInfo": "Invoke-SetHostPoliciesApply",
    "ApiName": "ApplyApi",
    "Path": "/api/esx/settings/hosts/{host}/policies/apply",
    "Tags": "Apply",
    "RelatedCommandInfos": "Initialize-SettingsHostsPoliciesApplyConfiguredPolicySpec",
    "Method": "PUT"
  },
  {
    "Name": "GetClusterSoftwareReportsApplyImpact",
    "CommandInfo": "Invoke-GetClusterSoftwareReportsApplyImpact",
    "ApiName": "ApplyImpactApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/reports/apply-impact",
    "Tags": "ApplyImpact",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostSoftwareReportsApplyImpact",
    "CommandInfo": "Invoke-GetHostSoftwareReportsApplyImpact",
    "ApiName": "ApplyImpactApi",
    "Path": "/api/esx/settings/hosts/{host}/software/reports/apply-impact",
    "Tags": "ApplyImpact",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetSystemNameArchive",
    "CommandInfo": "Invoke-GetSystemNameArchive",
    "ApiName": "ArchiveApi",
    "Path": "/api/appliance/recovery/backup/system-name/{system_name}/archives/{archive}__action=get",
    "Tags": "Archive",
    "RelatedCommandInfos": "Initialize-RecoveryBackupLocationSpec",
    "Method": "POST"
  },
  {
    "Name": "ListSystemNameArchives",
    "CommandInfo": "Invoke-ListSystemNameArchives",
    "ApiName": "ArchiveApi",
    "Path": "/api/appliance/recovery/backup/system-name/{system_name}/archives__action=list",
    "Tags": "Archive",
    "RelatedCommandInfos": "Initialize-RecoveryBackupSystemNameArchiveListRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListRecoveryBackupArchives",
    "CommandInfo": "Invoke-ListRecoveryBackupArchives",
    "ApiName": "ArchivesApi",
    "Path": "/api/vcenter/namespace-management/supervisors/recovery/backup/archives",
    "Tags": "Archives",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateLcmDiscoveryAssociatedProducts",
    "CommandInfo": "Invoke-CreateLcmDiscoveryAssociatedProducts",
    "ApiName": "AssociatedProductsApi",
    "Path": "/api/vcenter/lcm/discovery/associated-products",
    "Tags": "AssociatedProducts",
    "RelatedCommandInfos": "Initialize-LcmDiscoveryAssociatedProductsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteProductDiscoveryAssociatedProducts",
    "CommandInfo": "Invoke-DeleteProductDiscoveryAssociatedProducts",
    "ApiName": "AssociatedProductsApi",
    "Path": "/api/vcenter/lcm/discovery/associated-products/{product}",
    "Tags": "AssociatedProducts",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetProductDiscoveryAssociatedProducts",
    "CommandInfo": "Invoke-GetProductDiscoveryAssociatedProducts",
    "ApiName": "AssociatedProductsApi",
    "Path": "/api/vcenter/lcm/discovery/associated-products/{product}",
    "Tags": "AssociatedProducts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListLcmDiscoveryAssociatedProducts",
    "CommandInfo": "Invoke-ListLcmDiscoveryAssociatedProducts",
    "ApiName": "AssociatedProductsApi",
    "Path": "/api/vcenter/lcm/discovery/associated-products",
    "Tags": "AssociatedProducts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateProductDiscoveryAssociatedProducts",
    "CommandInfo": "Invoke-UpdateProductDiscoveryAssociatedProducts",
    "ApiName": "AssociatedProductsApi",
    "Path": "/api/vcenter/lcm/discovery/associated-products/{product}",
    "Tags": "AssociatedProducts",
    "RelatedCommandInfos": "Initialize-LcmDiscoveryAssociatedProductsUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "AddZoneAssociations",
    "CommandInfo": "Invoke-AddZoneAssociations",
    "ApiName": "AssociationsApi",
    "Path": "/api/vcenter/consumption-domains/zones/cluster/{zone}/associations__action=add",
    "Tags": "Associations",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetZoneClusterAssociations",
    "CommandInfo": "Invoke-GetZoneClusterAssociations",
    "ApiName": "AssociationsApi",
    "Path": "/api/vcenter/consumption-domains/zones/cluster/{zone}/associations",
    "Tags": "Associations",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListAssociations",
    "CommandInfo": "Invoke-ListAssociations",
    "ApiName": "AssociationsApi",
    "Path": "/api/vcenter/tagging/associations",
    "Tags": "Associations",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RemoveZoneAssociations",
    "CommandInfo": "Invoke-RemoveZoneAssociations",
    "ApiName": "AssociationsApi",
    "Path": "/api/vcenter/consumption-domains/zones/cluster/{zone}/associations__action=remove",
    "Tags": "Associations",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateTrustedInfrastructureTrustAuthorityHostsAttestation",
    "CommandInfo": "Invoke-CreateTrustedInfrastructureTrustAuthorityHostsAttestation",
    "ApiName": "AttestationApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-hosts/attestation",
    "Tags": "Attestation",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityHostsAttestationFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "GetHostTrustedInfrastructureAttestation",
    "CommandInfo": "Invoke-GetHostTrustedInfrastructureAttestation",
    "ApiName": "AttestationApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-hosts/{host}/attestation/",
    "Tags": "Attestation",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterConfigurationAuditRecords",
    "CommandInfo": "Invoke-ListClusterConfigurationAuditRecords",
    "ApiName": "AuditRecordsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/audit-records",
    "Tags": "AuditRecords",
    "RelatedCommandInfos": "Initialize-SettingsClustersConfigurationAuditRecordsTimePeriod",
    "Method": "GET"
  },
  {
    "Name": "ValidateRecoveryBackup",
    "CommandInfo": "Invoke-ValidateRecoveryBackup",
    "ApiName": "BackupApi",
    "Path": "/api/appliance/recovery/backup__action=validate",
    "Tags": "Backup",
    "RelatedCommandInfos": "Initialize-RecoveryBackupBackupRequest",
    "Method": "POST"
  },
  {
    "Name": "GetClusterDraftSoftwareBaseImage",
    "CommandInfo": "Invoke-GetClusterDraftSoftwareBaseImage",
    "ApiName": "BaseImageApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/base-image",
    "Tags": "BaseImage",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterSoftwareBaseImage",
    "CommandInfo": "Invoke-GetClusterSoftwareBaseImage",
    "ApiName": "BaseImageApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/base-image",
    "Tags": "BaseImage",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostDraftSoftwareBaseImage",
    "CommandInfo": "Invoke-GetHostDraftSoftwareBaseImage",
    "ApiName": "BaseImageApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/base-image",
    "Tags": "BaseImage",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostSoftwareBaseImage",
    "CommandInfo": "Invoke-GetHostSoftwareBaseImage",
    "ApiName": "BaseImageApi",
    "Path": "/api/esx/settings/hosts/{host}/software/base-image",
    "Tags": "BaseImage",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetClusterDraftSoftwareBaseImage",
    "CommandInfo": "Invoke-SetClusterDraftSoftwareBaseImage",
    "ApiName": "BaseImageApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/base-image",
    "Tags": "BaseImage",
    "RelatedCommandInfos": "Initialize-SettingsBaseImageSpec",
    "Method": "PUT"
  },
  {
    "Name": "SetHostDraftSoftwareBaseImage",
    "CommandInfo": "Invoke-SetHostDraftSoftwareBaseImage",
    "ApiName": "BaseImageApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/base-image",
    "Tags": "BaseImage",
    "RelatedCommandInfos": "Initialize-SettingsBaseImageSpec",
    "Method": "PUT"
  },
  {
    "Name": "DeleteClusterVersionBaseImagesAsync",
    "CommandInfo": "Invoke-DeleteClusterVersionBaseImagesAsync",
    "ApiName": "BaseImagesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/os/esx/base-images/{version}__vmw-task=true",
    "Tags": "BaseImages",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterBaseImagesAsync",
    "CommandInfo": "Invoke-GetClusterBaseImagesAsync",
    "ApiName": "BaseImagesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/os/esx/base-images__vmw-task=true",
    "Tags": "BaseImages",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterVersionBaseImagesAsync",
    "CommandInfo": "Invoke-GetClusterVersionBaseImagesAsync",
    "ApiName": "BaseImagesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/os/esx/base-images/{version}__vmw-task=true",
    "Tags": "BaseImages",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ImportFromImgdbClusterBaseImagesAsync",
    "CommandInfo": "Invoke-ImportFromImgdbClusterBaseImagesAsync",
    "ApiName": "BaseImagesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/os/esx/base-images__action=import-from-imgdb&vmw-task=true",
    "Tags": "BaseImages",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ListDepotContentBaseImages",
    "CommandInfo": "Invoke-ListDepotContentBaseImages",
    "ApiName": "BaseImagesApi",
    "Path": "/api/esx/settings/depot-content/base-images",
    "Tags": "BaseImages",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmHardwareBoot",
    "CommandInfo": "Invoke-GetVmHardwareBoot",
    "ApiName": "BootApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/boot",
    "Tags": "Boot",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmHardwareBoot",
    "CommandInfo": "Invoke-UpdateVmHardwareBoot",
    "ApiName": "BootApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/boot",
    "Tags": "Boot",
    "RelatedCommandInfos": "Initialize-VmHardwareBootUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "CreateClusterTpm2CaCertificatesAsync",
    "CommandInfo": "Invoke-CreateClusterTpm2CaCertificatesAsync",
    "ApiName": "CaCertificatesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/tpm2/ca-certificates__vmw-task=true",
    "Tags": "CaCertificates",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityClustersAttestationTpm2CaCertificatesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteClusterNameCaCertificatesAsync",
    "CommandInfo": "Invoke-DeleteClusterNameCaCertificatesAsync",
    "ApiName": "CaCertificatesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/tpm2/ca-certificates/{name}__vmw-task=true",
    "Tags": "CaCertificates",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterNameCaCertificatesAsync",
    "CommandInfo": "Invoke-GetClusterNameCaCertificatesAsync",
    "ApiName": "CaCertificatesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/tpm2/ca-certificates/{name}__vmw-task=true",
    "Tags": "CaCertificates",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterTpm2CaCertificatesAsync",
    "CommandInfo": "Invoke-GetClusterTpm2CaCertificatesAsync",
    "ApiName": "CaCertificatesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/tpm2/ca-certificates__vmw-task=true",
    "Tags": "CaCertificates",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "AddToUsedByCategoryId",
    "CommandInfo": "Invoke-AddToUsedByCategoryId",
    "ApiName": "CategoryApi",
    "Path": "/api/cis/tagging/category/{category_id}__action=add-to-used-by",
    "Tags": "Category",
    "RelatedCommandInfos": "Initialize-TaggingCategoryAddToUsedByRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CreateCategory",
    "CommandInfo": "Invoke-CreateCategory",
    "ApiName": "CategoryApi",
    "Path": "/api/cis/tagging/category",
    "Tags": "Category",
    "RelatedCommandInfos": "Initialize-TaggingCategoryCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteCategoryId",
    "CommandInfo": "Invoke-DeleteCategoryId",
    "ApiName": "CategoryApi",
    "Path": "/api/cis/tagging/category/{category_id}",
    "Tags": "Category",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetCategoryId",
    "CommandInfo": "Invoke-GetCategoryId",
    "ApiName": "CategoryApi",
    "Path": "/api/cis/tagging/category/{category_id}",
    "Tags": "Category",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListCategory",
    "CommandInfo": "Invoke-ListCategory",
    "ApiName": "CategoryApi",
    "Path": "/api/cis/tagging/category",
    "Tags": "Category",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListUsedCategoriesCategory",
    "CommandInfo": "Invoke-ListUsedCategoriesCategory",
    "ApiName": "CategoryApi",
    "Path": "/api/cis/tagging/category__action=list-used-categories",
    "Tags": "Category",
    "RelatedCommandInfos": "Initialize-TaggingCategoryListUsedCategoriesRequestBody",
    "Method": "POST"
  },
  {
    "Name": "RemoveFromUsedByCategoryId",
    "CommandInfo": "Invoke-RemoveFromUsedByCategoryId",
    "ApiName": "CategoryApi",
    "Path": "/api/cis/tagging/category/{category_id}__action=remove-from-used-by",
    "Tags": "Category",
    "RelatedCommandInfos": "Initialize-TaggingCategoryRemoveFromUsedByRequestBody",
    "Method": "POST"
  },
  {
    "Name": "RevokePropagatingPermissionsCategoryId",
    "CommandInfo": "Invoke-RevokePropagatingPermissionsCategoryId",
    "ApiName": "CategoryApi",
    "Path": "/api/cis/tagging/category/{category_id}__action=revoke-propagating-permissions",
    "Tags": "Category",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "UpdateCategoryId",
    "CommandInfo": "Invoke-UpdateCategoryId",
    "ApiName": "CategoryApi",
    "Path": "/api/cis/tagging/category/{category_id}",
    "Tags": "Category",
    "RelatedCommandInfos": "Initialize-TaggingCategoryUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "ConnectVmCdrom",
    "CommandInfo": "Invoke-ConnectVmCdrom",
    "ApiName": "CdromApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/cdrom/{cdrom}__action=connect",
    "Tags": "Cdrom",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateVmHardwareCdrom",
    "CommandInfo": "Invoke-CreateVmHardwareCdrom",
    "ApiName": "CdromApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/cdrom",
    "Tags": "Cdrom",
    "RelatedCommandInfos": "Initialize-VmHardwareCdromCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmCdromHardware",
    "CommandInfo": "Invoke-DeleteVmCdromHardware",
    "ApiName": "CdromApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/cdrom/{cdrom}",
    "Tags": "Cdrom",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DisconnectVmCdrom",
    "CommandInfo": "Invoke-DisconnectVmCdrom",
    "ApiName": "CdromApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/cdrom/{cdrom}__action=disconnect",
    "Tags": "Cdrom",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetVmCdromHardware",
    "CommandInfo": "Invoke-GetVmCdromHardware",
    "ApiName": "CdromApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/cdrom/{cdrom}",
    "Tags": "Cdrom",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmHardwareCdrom",
    "CommandInfo": "Invoke-ListVmHardwareCdrom",
    "ApiName": "CdromApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/cdrom",
    "Tags": "Cdrom",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmCdromHardware",
    "CommandInfo": "Invoke-UpdateVmCdromHardware",
    "ApiName": "CdromApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/cdrom/{cdrom}",
    "Tags": "Cdrom",
    "RelatedCommandInfos": "Initialize-VmHardwareCdromUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetLibraryItemVersionLibraryChanges",
    "CommandInfo": "Invoke-GetLibraryItemVersionLibraryChanges",
    "ApiName": "ChangesApi",
    "Path": "/api/content/library/item/{library_item}/changes/{version}",
    "Tags": "Changes",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListLibraryItemContentChanges",
    "CommandInfo": "Invoke-ListLibraryItemContentChanges",
    "ApiName": "ChangesApi",
    "Path": "/api/content/library/item/{library_item}/changes",
    "Tags": "Changes",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CheckInTemplateLibraryItemVmCheckOuts",
    "CommandInfo": "Invoke-CheckInTemplateLibraryItemVmCheckOuts",
    "ApiName": "CheckOutsApi",
    "Path": "/api/vcenter/vm-template/library-items/{template_library_item}/check-outs/{vm}__action=check-in",
    "Tags": "CheckOuts",
    "RelatedCommandInfos": "Initialize-VmTemplateLibraryItemsCheckOutsCheckInSpec",
    "Method": "POST"
  },
  {
    "Name": "CheckOutTemplateLibraryItemCheckOuts",
    "CommandInfo": "Invoke-CheckOutTemplateLibraryItemCheckOuts",
    "ApiName": "CheckOutsApi",
    "Path": "/api/vcenter/vm-template/library-items/{template_library_item}/check-outs__action=check-out",
    "Tags": "CheckOuts",
    "RelatedCommandInfos": "Initialize-VmTemplateLibraryItemsCheckOutsCheckOutSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteTemplateLibraryItemVmVmTemplateCheckOuts",
    "CommandInfo": "Invoke-DeleteTemplateLibraryItemVmVmTemplateCheckOuts",
    "ApiName": "CheckOutsApi",
    "Path": "/api/vcenter/vm-template/library-items/{template_library_item}/check-outs/{vm}",
    "Tags": "CheckOuts",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetTemplateLibraryItemVmVmTemplateCheckOuts",
    "CommandInfo": "Invoke-GetTemplateLibraryItemVmVmTemplateCheckOuts",
    "ApiName": "CheckOutsApi",
    "Path": "/api/vcenter/vm-template/library-items/{template_library_item}/check-outs/{vm}",
    "Tags": "CheckOuts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListTemplateLibraryItemVmTemplateCheckOuts",
    "CommandInfo": "Invoke-ListTemplateLibraryItemVmTemplateCheckOuts",
    "ApiName": "CheckOutsApi",
    "Path": "/api/vcenter/vm-template/library-items/{template_library_item}/check-outs",
    "Tags": "CheckOuts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateClusterProviderClientCertificateAsync",
    "CommandInfo": "Invoke-CreateClusterProviderClientCertificateAsync",
    "ApiName": "ClientCertificateApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}/client-certificate__vmw-task=true",
    "Tags": "ClientCertificate",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetClusterProviderClientCertificateAsync",
    "CommandInfo": "Invoke-GetClusterProviderClientCertificateAsync",
    "ApiName": "ClientCertificateApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}/client-certificate__vmw-task=true",
    "Tags": "ClientCertificate",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateClusterProviderClientCertificateAsync",
    "CommandInfo": "Invoke-UpdateClusterProviderClientCertificateAsync",
    "ApiName": "ClientCertificateApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}/client-certificate__vmw-task=true",
    "Tags": "ClientCertificate",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityClustersKmsProvidersClientCertificateUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "DeployVchaClusterAsync",
    "CommandInfo": "Invoke-DeployVchaClusterAsync",
    "ApiName": "ClusterApi",
    "Path": "/api/vcenter/vcha/cluster__action=deploy&vmw-task=true",
    "Tags": "Cluster",
    "RelatedCommandInfos": "Initialize-VchaClusterDeploySpec",
    "Method": "POST"
  },
  {
    "Name": "FailoverVchaClusterAsync",
    "CommandInfo": "Invoke-FailoverVchaClusterAsync",
    "ApiName": "ClusterApi",
    "Path": "/api/vcenter/vcha/cluster__action=failover&vmw-task=true",
    "Tags": "Cluster",
    "RelatedCommandInfos": "Initialize-VchaClusterFailoverTaskRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetCluster",
    "CommandInfo": "Invoke-GetCluster",
    "ApiName": "ClusterApi",
    "Path": "/api/vcenter/cluster/{cluster}",
    "Tags": "Cluster",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVchaCluster",
    "CommandInfo": "Invoke-GetVchaCluster",
    "ApiName": "ClusterApi",
    "Path": "/api/vcenter/vcha/cluster__action=get",
    "Tags": "Cluster",
    "RelatedCommandInfos": "Initialize-VchaClusterGetRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListCluster",
    "CommandInfo": "Invoke-ListCluster",
    "ApiName": "ClusterApi",
    "Path": "/api/vcenter/cluster",
    "Tags": "Cluster",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListConsumptionDomainsZoneAssociationsCluster",
    "CommandInfo": "Invoke-ListConsumptionDomainsZoneAssociationsCluster",
    "ApiName": "ClusterApi",
    "Path": "/api/vcenter/consumption-domains/zone-associations/cluster",
    "Tags": "Cluster",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UndeployVchaClusterAsync",
    "CommandInfo": "Invoke-UndeployVchaClusterAsync",
    "ApiName": "ClusterApi",
    "Path": "/api/vcenter/vcha/cluster__action=undeploy&vmw-task=true",
    "Tags": "Cluster",
    "RelatedCommandInfos": "Initialize-VchaClusterUndeploySpec",
    "Method": "POST"
  },
  {
    "Name": "ListNamespaceManagementSoftwareClusterAvailableVersions",
    "CommandInfo": "Invoke-ListNamespaceManagementSoftwareClusterAvailableVersions",
    "ApiName": "ClusterAvailableVersionsApi",
    "Path": "/api/vcenter/namespace-management/software/cluster-available-versions",
    "Tags": "ClusterAvailableVersions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetNamespaceManagementClusterCompatibilityV2",
    "CommandInfo": "Invoke-GetNamespaceManagementClusterCompatibilityV2",
    "ApiName": "ClusterCompatibilityApi",
    "Path": "/api/vcenter/namespace-management/cluster-compatibility/v2",
    "Tags": "ClusterCompatibility",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNamespaceManagementClusterCompatibility",
    "CommandInfo": "Invoke-ListNamespaceManagementClusterCompatibility",
    "ApiName": "ClusterCompatibilityApi",
    "Path": "/api/vcenter/namespace-management/cluster-compatibility",
    "Tags": "ClusterCompatibility",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "DisableCluster",
    "CommandInfo": "Invoke-DisableCluster",
    "ApiName": "ClustersApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}__action=disable",
    "Tags": "Clusters",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "EnableCluster",
    "CommandInfo": "Invoke-EnableCluster",
    "ApiName": "ClustersApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}__action=enable",
    "Tags": "Clusters",
    "RelatedCommandInfos": "Initialize-NamespaceManagementClustersEnableSpec",
    "Method": "POST"
  },
  {
    "Name": "GetClusterNamespaceManagement",
    "CommandInfo": "Invoke-GetClusterNamespaceManagement",
    "ApiName": "ClustersApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}",
    "Tags": "Clusters",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterNamespaceManagementSoftware",
    "CommandInfo": "Invoke-GetClusterNamespaceManagementSoftware",
    "ApiName": "ClustersApi",
    "Path": "/api/vcenter/namespace-management/software/clusters/{cluster}",
    "Tags": "Clusters",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNamespaceManagementClusters",
    "CommandInfo": "Invoke-ListNamespaceManagementClusters",
    "ApiName": "ClustersApi",
    "Path": "/api/vcenter/namespace-management/clusters",
    "Tags": "Clusters",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNamespaceManagementSoftwareClusters",
    "CommandInfo": "Invoke-ListNamespaceManagementSoftwareClusters",
    "ApiName": "ClustersApi",
    "Path": "/api/vcenter/namespace-management/software/clusters",
    "Tags": "Clusters",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RotatePasswordCluster",
    "CommandInfo": "Invoke-RotatePasswordCluster",
    "ApiName": "ClustersApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}__action=rotate_password",
    "Tags": "Clusters",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "SetClusterNamespaceManagement",
    "CommandInfo": "Invoke-SetClusterNamespaceManagement",
    "ApiName": "ClustersApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}",
    "Tags": "Clusters",
    "RelatedCommandInfos": "Initialize-NamespaceManagementClustersSetSpec",
    "Method": "PUT"
  },
  {
    "Name": "UpdateClusterNamespaceManagement",
    "CommandInfo": "Invoke-UpdateClusterNamespaceManagement",
    "ApiName": "ClustersApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}",
    "Tags": "Clusters",
    "RelatedCommandInfos": "Initialize-NamespaceManagementClustersUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "UpgradeCluster",
    "CommandInfo": "Invoke-UpgradeCluster",
    "ApiName": "ClustersApi",
    "Path": "/api/vcenter/namespace-management/software/clusters/{cluster}__action=upgrade",
    "Tags": "Clusters",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSoftwareClustersUpgradeSpec",
    "Method": "POST"
  },
  {
    "Name": "UpgradeMultipleSoftwareClusters",
    "CommandInfo": "Invoke-UpgradeMultipleSoftwareClusters",
    "ApiName": "ClustersApi",
    "Path": "/api/vcenter/namespace-management/software/clusters__action=upgradeMultiple",
    "Tags": "Clusters",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetNamespaceManagementClusterSizeInfo",
    "CommandInfo": "Invoke-GetNamespaceManagementClusterSizeInfo",
    "ApiName": "ClusterSizeInfoApi",
    "Path": "/api/vcenter/namespace-management/cluster-size-info",
    "Tags": "ClusterSizeInfo",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateClusterNamespaceManagementSupervisorServices",
    "CommandInfo": "Invoke-CreateClusterNamespaceManagementSupervisorServices",
    "ApiName": "ClusterSupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/supervisor-services",
    "Tags": "ClusterSupervisorServices",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorServicesClusterSupervisorServicesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteClusterSupervisorServiceNamespaceManagement",
    "CommandInfo": "Invoke-DeleteClusterSupervisorServiceNamespaceManagement",
    "ApiName": "ClusterSupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/supervisor-services/{supervisor_service}",
    "Tags": "ClusterSupervisorServices",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterSupervisorServiceNamespaceManagement",
    "CommandInfo": "Invoke-GetClusterSupervisorServiceNamespaceManagement",
    "ApiName": "ClusterSupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/supervisor-services/{supervisor_service}",
    "Tags": "ClusterSupervisorServices",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterNamespaceManagementSupervisorServices",
    "CommandInfo": "Invoke-ListClusterNamespaceManagementSupervisorServices",
    "ApiName": "ClusterSupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/supervisor-services",
    "Tags": "ClusterSupervisorServices",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetClusterSupervisorServiceNamespaceManagement",
    "CommandInfo": "Invoke-SetClusterSupervisorServiceNamespaceManagement",
    "ApiName": "ClusterSupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/supervisor-services/{supervisor_service}",
    "Tags": "ClusterSupervisorServices",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorServicesClusterSupervisorServicesSetSpec",
    "Method": "PUT"
  },
  {
    "Name": "GetCliCommand",
    "CommandInfo": "Invoke-GetCliCommand",
    "ApiName": "CommandApi",
    "Path": "/api/vapi/metadata/cli/command__action=get",
    "Tags": "Command",
    "RelatedCommandInfos": "Initialize-MetadataCliCommandGetRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetCliCommandFingerprint",
    "CommandInfo": "Invoke-GetCliCommandFingerprint",
    "ApiName": "CommandApi",
    "Path": "/api/vapi/metadata/cli/command/fingerprint",
    "Tags": "Command",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataCliCommand",
    "CommandInfo": "Invoke-ListMetadataCliCommand",
    "ApiName": "CommandApi",
    "Path": "/api/vapi/metadata/cli/command",
    "Tags": "Command",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterCommitSoftware",
    "CommandInfo": "Invoke-GetClusterCommitSoftware",
    "ApiName": "CommitsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/commits/{commit}",
    "Tags": "Commits",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostCommitSoftware",
    "CommandInfo": "Invoke-GetHostCommitSoftware",
    "ApiName": "CommitsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/commits/{commit}",
    "Tags": "Commits",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CheckCompatibilityNsxDistributedSwitches",
    "CommandInfo": "Invoke-CheckCompatibilityNsxDistributedSwitches",
    "ApiName": "CompatibilityApi",
    "Path": "/api/vcenter/namespace-management/networks/nsx/distributed-switches__action=check_compatibility",
    "Tags": "Compatibility",
    "RelatedCommandInfos": "Initialize-NamespaceManagementNetworksNsxDistributedSwitchesFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "CheckCompatibilityNsxEdges",
    "CommandInfo": "Invoke-CheckCompatibilityNsxEdges",
    "ApiName": "CompatibilityApi",
    "Path": "/api/vcenter/namespace-management/networks/nsx/edges__action=check_compatibility",
    "Tags": "Compatibility",
    "RelatedCommandInfos": "Initialize-NamespaceManagementNetworksNsxEdgesFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "DownloadHclCompatibilityDataAsync",
    "CommandInfo": "Invoke-DownloadHclCompatibilityDataAsync",
    "ApiName": "CompatibilityDataApi",
    "Path": "/api/esx/hcl/compatibility-data__action=download&vmw-task=true",
    "Tags": "CompatibilityData",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetHclCompatibilityDataStatus",
    "CommandInfo": "Invoke-GetHclCompatibilityDataStatus",
    "ApiName": "CompatibilityDataApi",
    "Path": "/api/esx/hcl/compatibility-data/status",
    "Tags": "CompatibilityData",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHostHclCompatibilityReleases",
    "CommandInfo": "Invoke-ListHostHclCompatibilityReleases",
    "ApiName": "CompatibilityReleasesApi",
    "Path": "/api/esx/hcl/hosts/{host}/compatibility-releases",
    "Tags": "CompatibilityReleases",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateHostCompatibilityReportAsync",
    "CommandInfo": "Invoke-CreateHostCompatibilityReportAsync",
    "ApiName": "CompatibilityReportApi",
    "Path": "/api/esx/hcl/hosts/{host}/compatibility-report__vmw-task=true",
    "Tags": "CompatibilityReport",
    "RelatedCommandInfos": "Initialize-HclHostsCompatibilityReportSpec",
    "Method": "POST"
  },
  {
    "Name": "GetHostHclCompatibilityReport",
    "CommandInfo": "Invoke-GetHostHclCompatibilityReport",
    "ApiName": "CompatibilityReportApi",
    "Path": "/api/esx/hcl/hosts/{host}/compatibility-report",
    "Tags": "CompatibilityReport",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CheckVmPolicyCompliance",
    "CommandInfo": "Invoke-CheckVmPolicyCompliance",
    "ApiName": "ComplianceApi",
    "Path": "/api/vcenter/vm/{vm}/storage/policy/compliance__action=check",
    "Tags": "Compliance",
    "RelatedCommandInfos": "Initialize-VmStoragePolicyComplianceCheckSpec",
    "Method": "POST"
  },
  {
    "Name": "GetClusterSoftwareCompliance",
    "CommandInfo": "Invoke-GetClusterSoftwareCompliance",
    "ApiName": "ComplianceApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/compliance",
    "Tags": "Compliance",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostSoftwareCompliance",
    "CommandInfo": "Invoke-GetHostSoftwareCompliance",
    "ApiName": "ComplianceApi",
    "Path": "/api/esx/settings/hosts/{host}/software/compliance",
    "Tags": "Compliance",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmStoragePolicyCompliance",
    "CommandInfo": "Invoke-GetVmStoragePolicyCompliance",
    "ApiName": "ComplianceApi",
    "Path": "/api/vcenter/vm/{vm}/storage/policy/compliance",
    "Tags": "Compliance",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListPoliciesEntitiesCompliance",
    "CommandInfo": "Invoke-ListPoliciesEntitiesCompliance",
    "ApiName": "ComplianceApi",
    "Path": "/api/vcenter/storage/policies/entities/compliance",
    "Tags": "Compliance",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateClusterStorageDeviceOverridesComplianceStatusAsync",
    "CommandInfo": "Invoke-UpdateClusterStorageDeviceOverridesComplianceStatusAsync",
    "ApiName": "ComplianceStatusApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/reports/hardware-compatibility/storage-device-overrides/compliance-status__vmw-task=true",
    "Tags": "ComplianceStatus",
    "RelatedCommandInfos": "Initialize-SettingsClustersSoftwareReportsHardwareCompatibilityStorageDeviceOverridesComplianceStatusUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetComponentIdAuthentication",
    "CommandInfo": "Invoke-GetComponentIdAuthentication",
    "ApiName": "ComponentApi",
    "Path": "/api/vapi/metadata/authentication/component/{component_id}",
    "Tags": "Component",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetComponentIdAuthenticationFingerprint",
    "CommandInfo": "Invoke-GetComponentIdAuthenticationFingerprint",
    "ApiName": "ComponentApi",
    "Path": "/api/vapi/metadata/authentication/component/{component_id}/fingerprint",
    "Tags": "Component",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetComponentIdMetamodel",
    "CommandInfo": "Invoke-GetComponentIdMetamodel",
    "ApiName": "ComponentApi",
    "Path": "/api/vapi/metadata/metamodel/component/{component_id}",
    "Tags": "Component",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetComponentIdMetamodelFingerprint",
    "CommandInfo": "Invoke-GetComponentIdMetamodelFingerprint",
    "ApiName": "ComponentApi",
    "Path": "/api/vapi/metadata/metamodel/component/{component_id}/fingerprint",
    "Tags": "Component",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetComponentIdPrivilege",
    "CommandInfo": "Invoke-GetComponentIdPrivilege",
    "ApiName": "ComponentApi",
    "Path": "/api/vapi/metadata/privilege/component/{component_id}",
    "Tags": "Component",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetComponentIdPrivilegeFingerprint",
    "CommandInfo": "Invoke-GetComponentIdPrivilegeFingerprint",
    "ApiName": "ComponentApi",
    "Path": "/api/vapi/metadata/privilege/component/{component_id}/fingerprint",
    "Tags": "Component",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataAuthenticationComponent",
    "CommandInfo": "Invoke-ListMetadataAuthenticationComponent",
    "ApiName": "ComponentApi",
    "Path": "/api/vapi/metadata/authentication/component",
    "Tags": "Component",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataMetamodelComponent",
    "CommandInfo": "Invoke-ListMetadataMetamodelComponent",
    "ApiName": "ComponentApi",
    "Path": "/api/vapi/metadata/metamodel/component",
    "Tags": "Component",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataPrivilegeComponent",
    "CommandInfo": "Invoke-ListMetadataPrivilegeComponent",
    "ApiName": "ComponentApi",
    "Path": "/api/vapi/metadata/privilege/component",
    "Tags": "Component",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "DeleteClusterDraftComponentSoftware",
    "CommandInfo": "Invoke-DeleteClusterDraftComponentSoftware",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/components/{component}",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteHostDraftComponentSoftware",
    "CommandInfo": "Invoke-DeleteHostDraftComponentSoftware",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/components/{component}",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterComponentSoftware",
    "CommandInfo": "Invoke-GetClusterComponentSoftware",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/components/{component}",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterDraftComponentSoftware",
    "CommandInfo": "Invoke-GetClusterDraftComponentSoftware",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/components/{component}",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostComponentSoftware",
    "CommandInfo": "Invoke-GetHostComponentSoftware",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/components/{component}",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostDraftComponentSoftware",
    "CommandInfo": "Invoke-GetHostDraftComponentSoftware",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/components/{component}",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetSupportBundleComponents",
    "CommandInfo": "Invoke-GetSupportBundleComponents",
    "ApiName": "ComponentsApi",
    "Path": "/api/appliance/support-bundle/components",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterDraftSoftwareComponents",
    "CommandInfo": "Invoke-ListClusterDraftSoftwareComponents",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/components",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterSoftwareComponents",
    "CommandInfo": "Invoke-ListClusterSoftwareComponents",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/components",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListDepotContentComponents",
    "CommandInfo": "Invoke-ListDepotContentComponents",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/depot-content/components",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHostDraftSoftwareComponents",
    "CommandInfo": "Invoke-ListHostDraftSoftwareComponents",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/components",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHostSoftwareComponents",
    "CommandInfo": "Invoke-ListHostSoftwareComponents",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/components",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetClusterDraftComponentSoftware",
    "CommandInfo": "Invoke-SetClusterDraftComponentSoftware",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/components/{component}",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "PUT"
  },
  {
    "Name": "SetHostDraftComponentSoftware",
    "CommandInfo": "Invoke-SetHostDraftComponentSoftware",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/components/{component}",
    "Tags": "Components",
    "RelatedCommandInfos": "",
    "Method": "PUT"
  },
  {
    "Name": "UpdateClusterDraftSoftwareComponents",
    "CommandInfo": "Invoke-UpdateClusterDraftSoftwareComponents",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/components",
    "Tags": "Components",
    "RelatedCommandInfos": "Initialize-SettingsClustersSoftwareDraftsSoftwareComponentsUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "UpdateHostDraftSoftwareComponents",
    "CommandInfo": "Invoke-UpdateHostDraftSoftwareComponents",
    "ApiName": "ComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/components",
    "Tags": "Components",
    "RelatedCommandInfos": "Initialize-SettingsHostsSoftwareDraftsSoftwareComponentsUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetSupervisorNamespaceManagementConditions",
    "CommandInfo": "Invoke-GetSupervisorNamespaceManagementConditions",
    "ApiName": "ConditionsApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/conditions",
    "Tags": "Conditions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ExportInfraprofileConfigs",
    "CommandInfo": "Invoke-ExportInfraprofileConfigs",
    "ApiName": "ConfigsApi",
    "Path": "/api/appliance/infraprofile/configs__action=export",
    "Tags": "Configs",
    "RelatedCommandInfos": "Initialize-InfraprofileConfigsProfilesSpec",
    "Method": "POST"
  },
  {
    "Name": "ImportInfraprofileConfigsAsync",
    "CommandInfo": "Invoke-ImportInfraprofileConfigsAsync",
    "ApiName": "ConfigsApi",
    "Path": "/api/appliance/infraprofile/configs__action=import&vmw-task=true",
    "Tags": "Configs",
    "RelatedCommandInfos": "Initialize-InfraprofileConfigsImportProfileSpec",
    "Method": "POST"
  },
  {
    "Name": "ListInfraprofileConfigs",
    "CommandInfo": "Invoke-ListInfraprofileConfigs",
    "ApiName": "ConfigsApi",
    "Path": "/api/appliance/infraprofile/configs",
    "Tags": "Configs",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ValidateInfraprofileConfigsAsync",
    "CommandInfo": "Invoke-ValidateInfraprofileConfigsAsync",
    "ApiName": "ConfigsApi",
    "Path": "/api/appliance/infraprofile/configs__action=validate&vmw-task=true",
    "Tags": "Configs",
    "RelatedCommandInfos": "Initialize-InfraprofileConfigsImportProfileSpec",
    "Method": "POST"
  },
  {
    "Name": "ApplyClusterConfigurationAsync",
    "CommandInfo": "Invoke-ApplyClusterConfigurationAsync",
    "ApiName": "ConfigurationApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration__action=apply&vmw-task=true",
    "Tags": "Configuration",
    "RelatedCommandInfos": "Initialize-SettingsClustersConfigurationApplySpec",
    "Method": "POST"
  },
  {
    "Name": "CheckComplianceClusterConfigurationAsync",
    "CommandInfo": "Invoke-CheckComplianceClusterConfigurationAsync",
    "ApiName": "ConfigurationApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration__action=checkCompliance&vmw-task=true",
    "Tags": "Configuration",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ExportConfigClusterConfiguration",
    "CommandInfo": "Invoke-ExportConfigClusterConfiguration",
    "ApiName": "ConfigurationApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration__action=exportConfig",
    "Tags": "Configuration",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ExtractHostConfiguration",
    "CommandInfo": "Invoke-ExtractHostConfiguration",
    "ApiName": "ConfigurationApi",
    "Path": "/api/esx/settings/hosts/{host}/configuration__action=extract",
    "Tags": "Configuration",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetClusterConfiguration",
    "CommandInfo": "Invoke-GetClusterConfiguration",
    "ApiName": "ConfigurationApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration",
    "Tags": "Configuration",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterEnablementConfiguration",
    "CommandInfo": "Invoke-GetClusterEnablementConfiguration",
    "ApiName": "ConfigurationApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/configuration",
    "Tags": "Configuration",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetContentConfiguration",
    "CommandInfo": "Invoke-GetContentConfiguration",
    "ApiName": "ConfigurationApi",
    "Path": "/api/content/configuration",
    "Tags": "Configuration",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ImportConfigClusterConfigurationAsync",
    "CommandInfo": "Invoke-ImportConfigClusterConfigurationAsync",
    "ApiName": "ConfigurationApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration__action=importConfig&vmw-task=true",
    "Tags": "Configuration",
    "RelatedCommandInfos": "Initialize-SettingsClustersConfigurationImportSpec",
    "Method": "POST"
  },
  {
    "Name": "PrecheckClusterConfigurationAsync",
    "CommandInfo": "Invoke-PrecheckClusterConfigurationAsync",
    "ApiName": "ConfigurationApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration__action=precheck&vmw-task=true",
    "Tags": "Configuration",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "UpdateContentConfiguration",
    "CommandInfo": "Invoke-UpdateContentConfiguration",
    "ApiName": "ConfigurationApi",
    "Path": "/api/content/configuration",
    "Tags": "Configuration",
    "RelatedCommandInfos": "Initialize-ConfigurationModel",
    "Method": "PATCH"
  },
  {
    "Name": "ValidateClusterConfigurationAsync",
    "CommandInfo": "Invoke-ValidateClusterConfigurationAsync",
    "ApiName": "ConfigurationApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration__action=validate&vmw-task=true",
    "Tags": "Configuration",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetAccessConsolecli",
    "CommandInfo": "Invoke-GetAccessConsolecli",
    "ApiName": "ConsolecliApi",
    "Path": "/api/appliance/access/consolecli",
    "Tags": "Consolecli",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetAccessConsolecli",
    "CommandInfo": "Invoke-SetAccessConsolecli",
    "ApiName": "ConsolecliApi",
    "Path": "/api/appliance/access/consolecli",
    "Tags": "Consolecli",
    "RelatedCommandInfos": "Initialize-AccessConsolecliSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "CreateClusterConsumerPrincipalsAsync",
    "CommandInfo": "Invoke-CreateClusterConsumerPrincipalsAsync",
    "ApiName": "ConsumerPrincipalsApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/consumer-principals__vmw-task=true",
    "Tags": "ConsumerPrincipals",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityClustersConsumerPrincipalsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteClusterProfileConsumerPrincipalsAsync",
    "CommandInfo": "Invoke-DeleteClusterProfileConsumerPrincipalsAsync",
    "ApiName": "ConsumerPrincipalsApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/consumer-principals/{profile}__vmw-task=true",
    "Tags": "ConsumerPrincipals",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterProfileConsumerPrincipalsAsync",
    "CommandInfo": "Invoke-GetClusterProfileConsumerPrincipalsAsync",
    "ApiName": "ConsumerPrincipalsApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/consumer-principals/{profile}__vmw-task=true",
    "Tags": "ConsumerPrincipals",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "QueryClusterConsumerPrincipalsAsync",
    "CommandInfo": "Invoke-QueryClusterConsumerPrincipalsAsync",
    "ApiName": "ConsumerPrincipalsApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/consumer-principals__action=query&vmw-task=true",
    "Tags": "ConsumerPrincipals",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityClustersConsumerPrincipalsFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateSupervisorNamespaceManagementContainerImageRegistries",
    "CommandInfo": "Invoke-CreateSupervisorNamespaceManagementContainerImageRegistries",
    "ApiName": "ContainerImageRegistriesApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/container-image-registries",
    "Tags": "ContainerImageRegistries",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorsContainerImageRegistriesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteSupervisorContainerImageRegistryNamespaceManagementContainerImageRegistries",
    "CommandInfo": "Invoke-DeleteSupervisorContainerImageRegistryNamespaceManagementContainerImageRegistries",
    "ApiName": "ContainerImageRegistriesApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/container-image-registries/{container_image_registry}",
    "Tags": "ContainerImageRegistries",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetSupervisorContainerImageRegistryNamespaceManagementContainerImageRegistries",
    "CommandInfo": "Invoke-GetSupervisorContainerImageRegistryNamespaceManagementContainerImageRegistries",
    "ApiName": "ContainerImageRegistriesApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/container-image-registries/{container_image_registry}",
    "Tags": "ContainerImageRegistries",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListSupervisorNamespaceManagementContainerImageRegistries",
    "CommandInfo": "Invoke-ListSupervisorNamespaceManagementContainerImageRegistries",
    "ApiName": "ContainerImageRegistriesApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/container-image-registries",
    "Tags": "ContainerImageRegistries",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateSupervisorContainerImageRegistryNamespaceManagementContainerImageRegistries",
    "CommandInfo": "Invoke-UpdateSupervisorContainerImageRegistryNamespaceManagementContainerImageRegistries",
    "ApiName": "ContainerImageRegistriesApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/container-image-registries/{container_image_registry}",
    "Tags": "ContainerImageRegistries",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorsContainerImageRegistriesUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetDepotOfflineContent",
    "CommandInfo": "Invoke-GetDepotOfflineContent",
    "ApiName": "ContentApi",
    "Path": "/api/esx/settings/depots/offline/{depot}/content",
    "Tags": "Content",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetDepotOnlineContent",
    "CommandInfo": "Invoke-GetDepotOnlineContent",
    "ApiName": "ContentApi",
    "Path": "/api/esx/settings/depots/online/{depot}/content",
    "Tags": "Content",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetDepotsUmdsContent",
    "CommandInfo": "Invoke-GetDepotsUmdsContent",
    "ApiName": "ContentApi",
    "Path": "/api/esx/settings/depots/umds/content",
    "Tags": "Content",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListSupportBundleCores",
    "CommandInfo": "Invoke-ListSupportBundleCores",
    "ApiName": "CoresApi",
    "Path": "/api/appliance/support-bundle/cores",
    "Tags": "Cores",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetCidCountersMetadataDefault",
    "CommandInfo": "Invoke-GetCidCountersMetadataDefault",
    "ApiName": "CounterMetadataApi",
    "Path": "/api/stats/counters/{cid}/metadata/default",
    "Tags": "CounterMetadata",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetCidMidCountersMetadata",
    "CommandInfo": "Invoke-GetCidMidCountersMetadata",
    "ApiName": "CounterMetadataApi",
    "Path": "/api/stats/counters/{cid}/metadata/{mid}",
    "Tags": "CounterMetadata",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListCidCountersMetadata",
    "CommandInfo": "Invoke-ListCidCountersMetadata",
    "ApiName": "CounterMetadataApi",
    "Path": "/api/stats/counters/{cid}/metadata",
    "Tags": "CounterMetadata",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetCidStatsCounters",
    "CommandInfo": "Invoke-GetCidStatsCounters",
    "ApiName": "CountersApi",
    "Path": "/api/stats/counters/{cid}",
    "Tags": "Counters",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListStatsCounters",
    "CommandInfo": "Invoke-ListStatsCounters",
    "ApiName": "CountersApi",
    "Path": "/api/stats/counters",
    "Tags": "Counters",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetCounterSetStats",
    "CommandInfo": "Invoke-GetCounterSetStats",
    "ApiName": "CounterSetsApi",
    "Path": "/api/stats/counter-sets/{counter_set}",
    "Tags": "CounterSets",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListStatsCounterSets",
    "CommandInfo": "Invoke-ListStatsCounterSets",
    "ApiName": "CounterSetsApi",
    "Path": "/api/stats/counter-sets",
    "Tags": "CounterSets",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmHardwareCpu",
    "CommandInfo": "Invoke-GetVmHardwareCpu",
    "ApiName": "CpuApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/cpu",
    "Tags": "Cpu",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmHardwareCpu",
    "CommandInfo": "Invoke-UpdateVmHardwareCpu",
    "ApiName": "CpuApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/cpu",
    "Tags": "Cpu",
    "RelatedCommandInfos": "Initialize-VmHardwareCpuUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "SetClusterProviderCredentialAsync",
    "CommandInfo": "Invoke-SetClusterProviderCredentialAsync",
    "ApiName": "CredentialApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}/credential__vmw-task=true",
    "Tags": "Credential",
    "RelatedCommandInfos": "",
    "Method": "PUT"
  },
  {
    "Name": "CreateClusterProviderClientCertificateCsrAsync",
    "CommandInfo": "Invoke-CreateClusterProviderClientCertificateCsrAsync",
    "ApiName": "CsrApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}/client-certificate/csr__vmw-task=true",
    "Tags": "Csr",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetClusterProviderClientCertificateCsrAsync",
    "CommandInfo": "Invoke-GetClusterProviderClientCertificateCsrAsync",
    "ApiName": "CsrApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}/client-certificate/csr__vmw-task=true",
    "Tags": "Csr",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterProviderPeerCertsCurrentAsync",
    "CommandInfo": "Invoke-GetClusterProviderPeerCertsCurrentAsync",
    "ApiName": "CurrentPeerCertificatesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}/peer-certs/current__vmw-task=true",
    "Tags": "CurrentPeerCertificates",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmGuestCustomization",
    "CommandInfo": "Invoke-GetVmGuestCustomization",
    "ApiName": "CustomizationApi",
    "Path": "/api/vcenter/vm/{vm}/guest/customization",
    "Tags": "Customization",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetVmGuestCustomization",
    "CommandInfo": "Invoke-SetVmGuestCustomization",
    "ApiName": "CustomizationApi",
    "Path": "/api/vcenter/vm/{vm}/guest/customization",
    "Tags": "Customization",
    "RelatedCommandInfos": "Initialize-VmGuestCustomizationSetSpec",
    "Method": "PUT"
  },
  {
    "Name": "CreateGuestCustomizationSpecs",
    "CommandInfo": "Invoke-CreateGuestCustomizationSpecs",
    "ApiName": "CustomizationSpecsApi",
    "Path": "/api/vcenter/guest/customization-specs",
    "Tags": "CustomizationSpecs",
    "RelatedCommandInfos": "Initialize-GuestCustomizationSpecsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteNameGuestCustomizationSpecs",
    "CommandInfo": "Invoke-DeleteNameGuestCustomizationSpecs",
    "ApiName": "CustomizationSpecsApi",
    "Path": "/api/vcenter/guest/customization-specs/{name}",
    "Tags": "CustomizationSpecs",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "ExportNameCustomizationSpecs",
    "CommandInfo": "Invoke-ExportNameCustomizationSpecs",
    "ApiName": "CustomizationSpecsApi",
    "Path": "/api/vcenter/guest/customization-specs/{name}__action=export",
    "Tags": "CustomizationSpecs",
    "RelatedCommandInfos": "Initialize-GuestCustomizationSpecsExportRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetNameGuestCustomizationSpecs",
    "CommandInfo": "Invoke-GetNameGuestCustomizationSpecs",
    "ApiName": "CustomizationSpecsApi",
    "Path": "/api/vcenter/guest/customization-specs/{name}",
    "Tags": "CustomizationSpecs",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ImportGuestCustomizationSpecs",
    "CommandInfo": "Invoke-ImportGuestCustomizationSpecs",
    "ApiName": "CustomizationSpecsApi",
    "Path": "/api/vcenter/guest/customization-specs__action=import",
    "Tags": "CustomizationSpecs",
    "RelatedCommandInfos": "Initialize-GuestCustomizationSpecsImportSpecificationRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListGuestCustomizationSpecs",
    "CommandInfo": "Invoke-ListGuestCustomizationSpecs",
    "ApiName": "CustomizationSpecsApi",
    "Path": "/api/vcenter/guest/customization-specs",
    "Tags": "CustomizationSpecs",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetNameGuestCustomizationSpecs",
    "CommandInfo": "Invoke-SetNameGuestCustomizationSpecs",
    "ApiName": "CustomizationSpecsApi",
    "Path": "/api/vcenter/guest/customization-specs/{name}",
    "Tags": "CustomizationSpecs",
    "RelatedCommandInfos": "Initialize-GuestCustomizationSpecsSpec",
    "Method": "PUT"
  },
  {
    "Name": "GetStatsData",
    "CommandInfo": "Invoke-GetStatsData",
    "ApiName": "DataApi",
    "Path": "/api/stats/data/dp",
    "Tags": "Data",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHealthDatabase",
    "CommandInfo": "Invoke-GetHealthDatabase",
    "ApiName": "DatabaseApi",
    "Path": "/api/appliance/health/database",
    "Tags": "Database",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHealthDatabaseStorage",
    "CommandInfo": "Invoke-GetHealthDatabaseStorage",
    "ApiName": "DatabasestorageApi",
    "Path": "/api/appliance/health/database-storage",
    "Tags": "Databasestorage",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateDatacenter",
    "CommandInfo": "Invoke-CreateDatacenter",
    "ApiName": "DatacenterApi",
    "Path": "/api/vcenter/datacenter",
    "Tags": "Datacenter",
    "RelatedCommandInfos": "Initialize-DatacenterCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteDatacenter",
    "CommandInfo": "Invoke-DeleteDatacenter",
    "ApiName": "DatacenterApi",
    "Path": "/api/vcenter/datacenter/{datacenter}",
    "Tags": "Datacenter",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetDatacenter",
    "CommandInfo": "Invoke-GetDatacenter",
    "ApiName": "DatacenterApi",
    "Path": "/api/vcenter/datacenter/{datacenter}",
    "Tags": "Datacenter",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListDatacenter",
    "CommandInfo": "Invoke-ListDatacenter",
    "ApiName": "DatacenterApi",
    "Path": "/api/vcenter/datacenter",
    "Tags": "Datacenter",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateVmDataSets",
    "CommandInfo": "Invoke-CreateVmDataSets",
    "ApiName": "DataSetsApi",
    "Path": "/api/vcenter/vm/{vm}/data-sets",
    "Tags": "DataSets",
    "RelatedCommandInfos": "Initialize-VmDataSetsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmDataSet",
    "CommandInfo": "Invoke-DeleteVmDataSet",
    "ApiName": "DataSetsApi",
    "Path": "/api/vcenter/vm/{vm}/data-sets/{data_set}",
    "Tags": "DataSets",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetVmDataSet",
    "CommandInfo": "Invoke-GetVmDataSet",
    "ApiName": "DataSetsApi",
    "Path": "/api/vcenter/vm/{vm}/data-sets/{data_set}",
    "Tags": "DataSets",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmDataSets",
    "CommandInfo": "Invoke-ListVmDataSets",
    "ApiName": "DataSetsApi",
    "Path": "/api/vcenter/vm/{vm}/data-sets",
    "Tags": "DataSets",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmDataSet",
    "CommandInfo": "Invoke-UpdateVmDataSet",
    "ApiName": "DataSetsApi",
    "Path": "/api/vcenter/vm/{vm}/data-sets/{data_set}",
    "Tags": "DataSets",
    "RelatedCommandInfos": "Initialize-VmDataSetsUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetDatastore",
    "CommandInfo": "Invoke-GetDatastore",
    "ApiName": "DatastoreApi",
    "Path": "/api/vcenter/datastore/{datastore}",
    "Tags": "Datastore",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetInventoryDatastore",
    "CommandInfo": "Invoke-GetInventoryDatastore",
    "ApiName": "DatastoreApi",
    "Path": "/api/vcenter/inventory/datastore",
    "Tags": "Datastore",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListDatastore",
    "CommandInfo": "Invoke-ListDatastore",
    "ApiName": "DatastoreApi",
    "Path": "/api/vcenter/datastore",
    "Tags": "Datastore",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetAccessDcui",
    "CommandInfo": "Invoke-GetAccessDcui",
    "ApiName": "DcuiApi",
    "Path": "/api/appliance/access/dcui",
    "Tags": "Dcui",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetAccessDcui",
    "CommandInfo": "Invoke-SetAccessDcui",
    "ApiName": "DcuiApi",
    "Path": "/api/appliance/access/dcui",
    "Tags": "Dcui",
    "RelatedCommandInfos": "Initialize-AccessDcuiSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "GetDatastoreDefaultPolicy",
    "CommandInfo": "Invoke-GetDatastoreDefaultPolicy",
    "ApiName": "DefaultPolicyApi",
    "Path": "/api/vcenter/datastore/{datastore}/default-policy",
    "Tags": "DefaultPolicy",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetDeployment",
    "CommandInfo": "Invoke-GetDeployment",
    "ApiName": "DeploymentApi",
    "Path": "/api/vcenter/deployment",
    "Tags": "Deployment",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RollbackDeployment",
    "CommandInfo": "Invoke-RollbackDeployment",
    "ApiName": "DeploymentApi",
    "Path": "/api/vcenter/deployment__action=rollback",
    "Tags": "Deployment",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetSystemConfigDeploymentType",
    "CommandInfo": "Invoke-GetSystemConfigDeploymentType",
    "ApiName": "DeploymentTypeApi",
    "Path": "/api/vcenter/system-config/deployment-type",
    "Tags": "DeploymentType",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVchaClusterDeploymentType",
    "CommandInfo": "Invoke-GetVchaClusterDeploymentType",
    "ApiName": "DeploymentTypeApi",
    "Path": "/api/vcenter/vcha/cluster/deployment-type",
    "Tags": "DeploymentType",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetSystemConfigDeploymentType",
    "CommandInfo": "Invoke-SetSystemConfigDeploymentType",
    "ApiName": "DeploymentTypeApi",
    "Path": "/api/vcenter/system-config/deployment-type",
    "Tags": "DeploymentType",
    "RelatedCommandInfos": "Initialize-SystemConfigDeploymentTypeReconfigureSpec",
    "Method": "PUT"
  },
  {
    "Name": "AddClusterDepotOverrides",
    "CommandInfo": "Invoke-AddClusterDepotOverrides",
    "ApiName": "DepotOverridesApi",
    "Path": "/api/esx/settings/clusters/{cluster}/depot-overrides__action=add",
    "Tags": "DepotOverrides",
    "RelatedCommandInfos": "Initialize-SettingsClustersDepotOverridesDepot",
    "Method": "POST"
  },
  {
    "Name": "AddHostDepotOverrides",
    "CommandInfo": "Invoke-AddHostDepotOverrides",
    "ApiName": "DepotOverridesApi",
    "Path": "/api/esx/settings/hosts/{host}/depot-overrides__action=add",
    "Tags": "DepotOverrides",
    "RelatedCommandInfos": "Initialize-SettingsHostsDepotOverridesDepot",
    "Method": "POST"
  },
  {
    "Name": "GetClusterDepotOverrides",
    "CommandInfo": "Invoke-GetClusterDepotOverrides",
    "ApiName": "DepotOverridesApi",
    "Path": "/api/esx/settings/clusters/{cluster}/depot-overrides",
    "Tags": "DepotOverrides",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostDepotOverrides",
    "CommandInfo": "Invoke-GetHostDepotOverrides",
    "ApiName": "DepotOverridesApi",
    "Path": "/api/esx/settings/hosts/{host}/depot-overrides",
    "Tags": "DepotOverrides",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RemoveClusterDepotOverrides",
    "CommandInfo": "Invoke-RemoveClusterDepotOverrides",
    "ApiName": "DepotOverridesApi",
    "Path": "/api/esx/settings/clusters/{cluster}/depot-overrides__action=remove",
    "Tags": "DepotOverrides",
    "RelatedCommandInfos": "Initialize-SettingsClustersDepotOverridesDepot",
    "Method": "POST"
  },
  {
    "Name": "RemoveHostDepotOverrides",
    "CommandInfo": "Invoke-RemoveHostDepotOverrides",
    "ApiName": "DepotOverridesApi",
    "Path": "/api/esx/settings/hosts/{host}/depot-overrides__action=remove",
    "Tags": "DepotOverrides",
    "RelatedCommandInfos": "Initialize-SettingsHostsDepotOverridesDepot",
    "Method": "POST"
  },
  {
    "Name": "SyncDepotsAsync",
    "CommandInfo": "Invoke-SyncDepotsAsync",
    "ApiName": "DepotsApi",
    "Path": "/api/esx/settings/depots__action=sync&vmw-task=true",
    "Tags": "Depots",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetClusterSoftwareReportsHardwareCompatibilityDetails",
    "CommandInfo": "Invoke-GetClusterSoftwareReportsHardwareCompatibilityDetails",
    "ApiName": "DetailsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/reports/hardware-compatibility/details",
    "Tags": "Details",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListBackupJobDetails",
    "CommandInfo": "Invoke-ListBackupJobDetails",
    "ApiName": "DetailsApi",
    "Path": "/api/appliance/recovery/backup/job/details",
    "Tags": "Details",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmHardwareBootDevice",
    "CommandInfo": "Invoke-GetVmHardwareBootDevice",
    "ApiName": "DeviceApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/boot/device",
    "Tags": "Device",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetVmHardwareBootDevice",
    "CommandInfo": "Invoke-SetVmHardwareBootDevice",
    "ApiName": "DeviceApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/boot/device",
    "Tags": "Device",
    "RelatedCommandInfos": "Initialize-VmHardwareBootDeviceSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "CreateTemporaryVmFilesystemDirectories",
    "CommandInfo": "Invoke-CreateTemporaryVmFilesystemDirectories",
    "ApiName": "DirectoriesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/filesystem/directories__action=createTemporary",
    "Tags": "Directories",
    "RelatedCommandInfos": "Initialize-VmGuestFilesystemDirectoriesCreateTemporaryRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CreateVmFilesystemDirectories",
    "CommandInfo": "Invoke-CreateVmFilesystemDirectories",
    "ApiName": "DirectoriesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/filesystem/directories__action=create",
    "Tags": "Directories",
    "RelatedCommandInfos": "Initialize-VmGuestFilesystemDirectoriesCreateRequestBody",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmFilesystemDirectories",
    "CommandInfo": "Invoke-DeleteVmFilesystemDirectories",
    "ApiName": "DirectoriesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/filesystem/directories__action=delete",
    "Tags": "Directories",
    "RelatedCommandInfos": "Initialize-VmGuestFilesystemDirectoriesDeleteRequestBody",
    "Method": "POST"
  },
  {
    "Name": "MoveVmFilesystemDirectories",
    "CommandInfo": "Invoke-MoveVmFilesystemDirectories",
    "ApiName": "DirectoriesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/filesystem/directories__action=move",
    "Tags": "Directories",
    "RelatedCommandInfos": "Initialize-VmGuestFilesystemDirectoriesMoveRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CreateVmHardwareDisk",
    "CommandInfo": "Invoke-CreateVmHardwareDisk",
    "ApiName": "DiskApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/disk",
    "Tags": "Disk",
    "RelatedCommandInfos": "Initialize-VmHardwareDiskCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmDiskHardware",
    "CommandInfo": "Invoke-DeleteVmDiskHardware",
    "ApiName": "DiskApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/disk/{disk}",
    "Tags": "Disk",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetVmDiskHardware",
    "CommandInfo": "Invoke-GetVmDiskHardware",
    "ApiName": "DiskApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/disk/{disk}",
    "Tags": "Disk",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmHardwareDisk",
    "CommandInfo": "Invoke-ListVmHardwareDisk",
    "ApiName": "DiskApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/disk",
    "Tags": "Disk",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmDiskHardware",
    "CommandInfo": "Invoke-UpdateVmDiskHardware",
    "ApiName": "DiskApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/disk/{disk}",
    "Tags": "Disk",
    "RelatedCommandInfos": "Initialize-VmHardwareDiskUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "ListNamespaceManagementDistributedSwitchCompatibility",
    "CommandInfo": "Invoke-ListNamespaceManagementDistributedSwitchCompatibility",
    "ApiName": "DistributedSwitchCompatibilityApi",
    "Path": "/api/vcenter/namespace-management/distributed-switch-compatibility",
    "Tags": "DistributedSwitchCompatibility",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNetworksNsxDistributedSwitches",
    "CommandInfo": "Invoke-ListNetworksNsxDistributedSwitches",
    "ApiName": "DistributedSwitchesApi",
    "Path": "/api/vcenter/namespace-management/networks/nsx/distributed-switches",
    "Tags": "DistributedSwitches",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateNetworkingDnsDomains",
    "CommandInfo": "Invoke-CreateNetworkingDnsDomains",
    "ApiName": "DomainsApi",
    "Path": "/api/appliance/networking/dns/domains",
    "Tags": "Domains",
    "RelatedCommandInfos": "Initialize-NetworkingDnsDomainsAddRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListNetworkingDnsDomains",
    "CommandInfo": "Invoke-ListNetworkingDnsDomains",
    "ApiName": "DomainsApi",
    "Path": "/api/appliance/networking/dns/domains",
    "Tags": "Domains",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetNetworkingDnsDomains",
    "CommandInfo": "Invoke-SetNetworkingDnsDomains",
    "ApiName": "DomainsApi",
    "Path": "/api/appliance/networking/dns/domains",
    "Tags": "Domains",
    "RelatedCommandInfos": "Initialize-NetworkingDnsDomainsSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "CancelDownloadSessionId",
    "CommandInfo": "Invoke-CancelDownloadSessionId",
    "ApiName": "DownloadSessionApi",
    "Path": "/api/content/library/item/download-session/{download_session_id}__action=cancel",
    "Tags": "DownloadSession",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateLibraryItemDownloadSession",
    "CommandInfo": "Invoke-CreateLibraryItemDownloadSession",
    "ApiName": "DownloadSessionApi",
    "Path": "/api/content/library/item/download-session",
    "Tags": "DownloadSession",
    "RelatedCommandInfos": "Initialize-LibraryItemDownloadSessionModel",
    "Method": "POST"
  },
  {
    "Name": "DeleteDownloadSessionIdItem",
    "CommandInfo": "Invoke-DeleteDownloadSessionIdItem",
    "ApiName": "DownloadSessionApi",
    "Path": "/api/content/library/item/download-session/{download_session_id}",
    "Tags": "DownloadSession",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "FailDownloadSessionId",
    "CommandInfo": "Invoke-FailDownloadSessionId",
    "ApiName": "DownloadSessionApi",
    "Path": "/api/content/library/item/download-session/{download_session_id}__action=fail",
    "Tags": "DownloadSession",
    "RelatedCommandInfos": "Initialize-LibraryItemDownloadSessionFailRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetDownloadSessionIdItem",
    "CommandInfo": "Invoke-GetDownloadSessionIdItem",
    "ApiName": "DownloadSessionApi",
    "Path": "/api/content/library/item/download-session/{download_session_id}",
    "Tags": "DownloadSession",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "KeepAliveDownloadSessionId",
    "CommandInfo": "Invoke-KeepAliveDownloadSessionId",
    "ApiName": "DownloadSessionApi",
    "Path": "/api/content/library/item/download-session/{download_session_id}__action=keep-alive",
    "Tags": "DownloadSession",
    "RelatedCommandInfos": "Initialize-LibraryItemDownloadSessionKeepAliveRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListLibraryItemDownloadSession",
    "CommandInfo": "Invoke-ListLibraryItemDownloadSession",
    "ApiName": "DownloadSessionApi",
    "Path": "/api/content/library/item/download-session",
    "Tags": "DownloadSession",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ApplyClusterDraft",
    "CommandInfo": "Invoke-ApplyClusterDraft",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts/{draft}__action=apply",
    "Tags": "Drafts",
    "RelatedCommandInfos": "Initialize-SettingsClustersConfigurationDraftsApplySpec",
    "Method": "POST"
  },
  {
    "Name": "CheckComplianceClusterDraftAsync",
    "CommandInfo": "Invoke-CheckComplianceClusterDraftAsync",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts/{draft}__action=checkCompliance&vmw-task=true",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CommitClusterDraftAsync",
    "CommandInfo": "Invoke-CommitClusterDraftAsync",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}__action=commit&vmw-task=true",
    "Tags": "Drafts",
    "RelatedCommandInfos": "Initialize-SettingsClustersSoftwareDraftsCommitSpec",
    "Method": "POST"
  },
  {
    "Name": "CommitHostDraftAsync",
    "CommandInfo": "Invoke-CommitHostDraftAsync",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}__action=commit&vmw-task=true",
    "Tags": "Drafts",
    "RelatedCommandInfos": "Initialize-SettingsHostsSoftwareDraftsCommitSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateClusterConfigurationDrafts",
    "CommandInfo": "Invoke-CreateClusterConfigurationDrafts",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts",
    "Tags": "Drafts",
    "RelatedCommandInfos": "Initialize-SettingsClustersConfigurationDraftsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateClusterSoftwareDrafts",
    "CommandInfo": "Invoke-CreateClusterSoftwareDrafts",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateHostSoftwareDrafts",
    "CommandInfo": "Invoke-CreateHostSoftwareDrafts",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "DeleteClusterDraftConfiguration",
    "CommandInfo": "Invoke-DeleteClusterDraftConfiguration",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts/{draft}",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteClusterDraftSoftware",
    "CommandInfo": "Invoke-DeleteClusterDraftSoftware",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteHostDraftSoftware",
    "CommandInfo": "Invoke-DeleteHostDraftSoftware",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "ExportConfigClusterDraft",
    "CommandInfo": "Invoke-ExportConfigClusterDraft",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts/{draft}__action=exportConfig",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetClusterDraft",
    "CommandInfo": "Invoke-GetClusterDraft",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts/{draft}__action=getSchema",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterDraftConfiguration",
    "CommandInfo": "Invoke-GetClusterDraftConfiguration",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts/{draft}",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterDraftSoftware",
    "CommandInfo": "Invoke-GetClusterDraftSoftware",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterDraft_0",
    "CommandInfo": "Invoke-GetClusterDraft_0",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts/{draft}__action=showChanges",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostDraftSoftware",
    "CommandInfo": "Invoke-GetHostDraftSoftware",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ImportFromHostClusterDraftAsync",
    "CommandInfo": "Invoke-ImportFromHostClusterDraftAsync",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts/{draft}__action=importFromHost&vmw-task=true",
    "Tags": "Drafts",
    "RelatedCommandInfos": "Initialize-SettingsClustersConfigurationDraftsImportFromHostTaskRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ImportSoftwareSpecClusterSoftwareDrafts",
    "CommandInfo": "Invoke-ImportSoftwareSpecClusterSoftwareDrafts",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts__action=import-software-spec",
    "Tags": "Drafts",
    "RelatedCommandInfos": "Initialize-SettingsClustersSoftwareDraftsImportSpec",
    "Method": "POST"
  },
  {
    "Name": "ImportSoftwareSpecHostSoftwareDrafts",
    "CommandInfo": "Invoke-ImportSoftwareSpecHostSoftwareDrafts",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts__action=import-software-spec",
    "Tags": "Drafts",
    "RelatedCommandInfos": "Initialize-SettingsHostsSoftwareDraftsImportSpec",
    "Method": "POST"
  },
  {
    "Name": "ListClusterConfigurationDrafts",
    "CommandInfo": "Invoke-ListClusterConfigurationDrafts",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterSoftwareDrafts",
    "CommandInfo": "Invoke-ListClusterSoftwareDrafts",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHostSoftwareDrafts",
    "CommandInfo": "Invoke-ListHostSoftwareDrafts",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "PrecheckClusterDraftAsync",
    "CommandInfo": "Invoke-PrecheckClusterDraftAsync",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts/{draft}__action=precheck&vmw-task=true",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ScanClusterDraftAsync",
    "CommandInfo": "Invoke-ScanClusterDraftAsync",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}__action=scan&vmw-task=true",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ScanHostDraftAsync",
    "CommandInfo": "Invoke-ScanHostDraftAsync",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}__action=scan&vmw-task=true",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "UpdateClusterDraft",
    "CommandInfo": "Invoke-UpdateClusterDraft",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/drafts/{draft}__action=update",
    "Tags": "Drafts",
    "RelatedCommandInfos": "Initialize-SettingsClustersConfigurationDraftsUpdateSpec",
    "Method": "POST"
  },
  {
    "Name": "ValidateClusterDraftAsync",
    "CommandInfo": "Invoke-ValidateClusterDraftAsync",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}__action=validate&vmw-task=true",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ValidateHostDraftAsync",
    "CommandInfo": "Invoke-ValidateHostDraftAsync",
    "ApiName": "DraftsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}__action=validate&vmw-task=true",
    "Tags": "Drafts",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ListNamespaceManagementEdgeClusterCompatibility",
    "CommandInfo": "Invoke-ListNamespaceManagementEdgeClusterCompatibility",
    "ApiName": "EdgeClusterCompatibilityApi",
    "Path": "/api/vcenter/namespace-management/edge-cluster-compatibility",
    "Tags": "EdgeClusterCompatibility",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNetworksNsxEdges",
    "CommandInfo": "Invoke-ListNetworksNsxEdges",
    "ApiName": "EdgesApi",
    "Path": "/api/vcenter/namespace-management/networks/nsx/edges",
    "Tags": "Edges",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterPoliciesApplyEffective",
    "CommandInfo": "Invoke-GetClusterPoliciesApplyEffective",
    "ApiName": "EffectiveApi",
    "Path": "/api/esx/settings/clusters/{cluster}/policies/apply/effective",
    "Tags": "Effective",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClustersPoliciesApplyEffective",
    "CommandInfo": "Invoke-GetClustersPoliciesApplyEffective",
    "ApiName": "EffectiveApi",
    "Path": "/api/esx/settings/defaults/clusters/policies/apply/effective",
    "Tags": "Effective",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostPoliciesApplyEffective",
    "CommandInfo": "Invoke-GetHostPoliciesApplyEffective",
    "ApiName": "EffectiveApi",
    "Path": "/api/esx/settings/hosts/{host}/policies/apply/effective",
    "Tags": "Effective",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostsPoliciesApplyEffective",
    "CommandInfo": "Invoke-GetHostsPoliciesApplyEffective",
    "ApiName": "EffectiveApi",
    "Path": "/api/esx/settings/defaults/hosts/policies/apply/effective",
    "Tags": "Effective",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterDraftSoftwareEffectiveComponents",
    "CommandInfo": "Invoke-GetClusterDraftSoftwareEffectiveComponents",
    "ApiName": "EffectiveComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/effective-components__with-removed-components",
    "Tags": "EffectiveComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterSoftwareEffectiveComponents",
    "CommandInfo": "Invoke-GetClusterSoftwareEffectiveComponents",
    "ApiName": "EffectiveComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/effective-components__with-removed-components",
    "Tags": "EffectiveComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostDraftSoftwareEffectiveComponents",
    "CommandInfo": "Invoke-GetHostDraftSoftwareEffectiveComponents",
    "ApiName": "EffectiveComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/effective-components__with-removed-components",
    "Tags": "EffectiveComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostSoftwareEffectiveComponents",
    "CommandInfo": "Invoke-GetHostSoftwareEffectiveComponents",
    "ApiName": "EffectiveComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/effective-components__with-removed-components",
    "Tags": "EffectiveComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterDraftSoftwareEffectiveComponents",
    "CommandInfo": "Invoke-ListClusterDraftSoftwareEffectiveComponents",
    "ApiName": "EffectiveComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/effective-components",
    "Tags": "EffectiveComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterSoftwareEffectiveComponents",
    "CommandInfo": "Invoke-ListClusterSoftwareEffectiveComponents",
    "ApiName": "EffectiveComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/effective-components",
    "Tags": "EffectiveComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHostDraftSoftwareEffectiveComponents",
    "CommandInfo": "Invoke-ListHostDraftSoftwareEffectiveComponents",
    "ApiName": "EffectiveComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/effective-components",
    "Tags": "EffectiveComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHostSoftwareEffectiveComponents",
    "CommandInfo": "Invoke-ListHostSoftwareEffectiveComponents",
    "ApiName": "EffectiveComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/effective-components",
    "Tags": "EffectiveComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateClusterTpm2EndorsementKeysAsync",
    "CommandInfo": "Invoke-CreateClusterTpm2EndorsementKeysAsync",
    "ApiName": "EndorsementKeysApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/tpm2/endorsement-keys__vmw-task=true",
    "Tags": "EndorsementKeys",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityClustersAttestationTpm2EndorsementKeysCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteClusterNameEndorsementKeysAsync",
    "CommandInfo": "Invoke-DeleteClusterNameEndorsementKeysAsync",
    "ApiName": "EndorsementKeysApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/tpm2/endorsement-keys/{name}__vmw-task=true",
    "Tags": "EndorsementKeys",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterNameEndorsementKeysAsync",
    "CommandInfo": "Invoke-GetClusterNameEndorsementKeysAsync",
    "ApiName": "EndorsementKeysApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/tpm2/endorsement-keys/{name}__vmw-task=true",
    "Tags": "EndorsementKeys",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterTpm2EndorsementKeysAsync",
    "CommandInfo": "Invoke-GetClusterTpm2EndorsementKeysAsync",
    "ApiName": "EndorsementKeysApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/tpm2/endorsement-keys__vmw-task=true",
    "Tags": "EndorsementKeys",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostTpmKeyHardwareEndorsementKeys",
    "CommandInfo": "Invoke-GetHostTpmKeyHardwareEndorsementKeys",
    "ApiName": "EndorsementKeysApi",
    "Path": "/api/vcenter/trusted-infrastructure/hosts/{host}/hardware/tpm/{tpm}/endorsement-keys/{key}",
    "Tags": "EndorsementKeys",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHostTpmHardwareHostEndorsementKeys",
    "CommandInfo": "Invoke-ListHostTpmHardwareHostEndorsementKeys",
    "ApiName": "EndorsementKeysApi",
    "Path": "/api/vcenter/trusted-infrastructure/hosts/{host}/hardware/tpm/{tpm}/endorsement-keys",
    "Tags": "EndorsementKeys",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UnsealHostTpmKey",
    "CommandInfo": "Invoke-UnsealHostTpmKey",
    "ApiName": "EndorsementKeysApi",
    "Path": "/api/vcenter/trusted-infrastructure/hosts/{host}/hardware/tpm/{tpm}/endorsement-keys/{key}__action=unseal",
    "Tags": "EndorsementKeys",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureHostsHardwareTpmEndorsementKeysUnsealSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmDataSetKeyVmEntries",
    "CommandInfo": "Invoke-DeleteVmDataSetKeyVmEntries",
    "ApiName": "EntriesApi",
    "Path": "/api/vcenter/vm/{vm}/data-sets/{data_set}/entries/{key}",
    "Tags": "Entries",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetVmDataSetKeyVmEntries",
    "CommandInfo": "Invoke-GetVmDataSetKeyVmEntries",
    "ApiName": "EntriesApi",
    "Path": "/api/vcenter/vm/{vm}/data-sets/{data_set}/entries/{key}",
    "Tags": "Entries",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmDataSetVmEntries",
    "CommandInfo": "Invoke-ListVmDataSetVmEntries",
    "ApiName": "EntriesApi",
    "Path": "/api/vcenter/vm/{vm}/data-sets/{data_set}/entries",
    "Tags": "Entries",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetVmDataSetKeyVmEntries",
    "CommandInfo": "Invoke-SetVmDataSetKeyVmEntries",
    "ApiName": "EntriesApi",
    "Path": "/api/vcenter/vm/{vm}/data-sets/{data_set}/entries/{key}",
    "Tags": "Entries",
    "RelatedCommandInfos": "",
    "Method": "PUT"
  },
  {
    "Name": "GetEnumerationIdMetamodel",
    "CommandInfo": "Invoke-GetEnumerationIdMetamodel",
    "ApiName": "EnumerationApi",
    "Path": "/api/vapi/metadata/metamodel/enumeration/{enumeration_id}",
    "Tags": "Enumeration",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataMetamodelEnumeration",
    "CommandInfo": "Invoke-ListMetadataMetamodelEnumeration",
    "ApiName": "EnumerationApi",
    "Path": "/api/vapi/metadata/metamodel/enumeration",
    "Tags": "Enumeration",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmNameEnvironment",
    "CommandInfo": "Invoke-GetVmNameEnvironment",
    "ApiName": "EnvironmentApi",
    "Path": "/api/vcenter/vm/{vm}/guest/environment/{name}__action=get",
    "Tags": "Environment",
    "RelatedCommandInfos": "Initialize-VmGuestEnvironmentGetRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListVmGuestEnvironment",
    "CommandInfo": "Invoke-ListVmGuestEnvironment",
    "ApiName": "EnvironmentApi",
    "Path": "/api/vcenter/vm/{vm}/guest/environment__action=list",
    "Tags": "Environment",
    "RelatedCommandInfos": "Initialize-VmGuestEnvironmentListRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ConnectVmNicEthernet",
    "CommandInfo": "Invoke-ConnectVmNicEthernet",
    "ApiName": "EthernetApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/ethernet/{nic}__action=connect",
    "Tags": "Ethernet",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateVmHardwareEthernet",
    "CommandInfo": "Invoke-CreateVmHardwareEthernet",
    "ApiName": "EthernetApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/ethernet",
    "Tags": "Ethernet",
    "RelatedCommandInfos": "Initialize-VmHardwareEthernetCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmNicHardwareEthernet",
    "CommandInfo": "Invoke-DeleteVmNicHardwareEthernet",
    "ApiName": "EthernetApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/ethernet/{nic}",
    "Tags": "Ethernet",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DisconnectVmNicEthernet",
    "CommandInfo": "Invoke-DisconnectVmNicEthernet",
    "ApiName": "EthernetApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/ethernet/{nic}__action=disconnect",
    "Tags": "Ethernet",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetVmNicHardwareEthernet",
    "CommandInfo": "Invoke-GetVmNicHardwareEthernet",
    "ApiName": "EthernetApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/ethernet/{nic}",
    "Tags": "Ethernet",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmHardwareEthernet",
    "CommandInfo": "Invoke-ListVmHardwareEthernet",
    "ApiName": "EthernetApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/ethernet",
    "Tags": "Ethernet",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmNicHardwareEthernet",
    "CommandInfo": "Invoke-UpdateVmNicHardwareEthernet",
    "ApiName": "EthernetApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/ethernet/{nic}",
    "Tags": "Ethernet",
    "RelatedCommandInfos": "Initialize-VmHardwareEthernetUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetHostTpmHardwareHostEventLog",
    "CommandInfo": "Invoke-GetHostTpmHardwareHostEventLog",
    "ApiName": "EventLogApi",
    "Path": "/api/vcenter/trusted-infrastructure/hosts/{host}/hardware/tpm/{tpm}/event-log",
    "Tags": "EventLog",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListOvfExportFlag",
    "CommandInfo": "Invoke-ListOvfExportFlag",
    "ApiName": "ExportFlagApi",
    "Path": "/api/vcenter/ovf/export-flag",
    "Tags": "ExportFlag",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateUpdateSessionIdItemFile",
    "CommandInfo": "Invoke-CreateUpdateSessionIdItemFile",
    "ApiName": "FileApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}/file",
    "Tags": "File",
    "RelatedCommandInfos": "Initialize-LibraryItemUpdatesessionFileAddSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteUpdateSessionIdFileNameItem",
    "CommandInfo": "Invoke-DeleteUpdateSessionIdFileNameItem",
    "ApiName": "FileApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}/file/{file_name}",
    "Tags": "File",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetDownloadSessionIdFile",
    "CommandInfo": "Invoke-GetDownloadSessionIdFile",
    "ApiName": "FileApi",
    "Path": "/api/content/library/item/download-session/{download_session_id}/file__file_name",
    "Tags": "File",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetLibraryItemIdFile",
    "CommandInfo": "Invoke-GetLibraryItemIdFile",
    "ApiName": "FileApi",
    "Path": "/api/content/library/item/{library_item_id}/file__name",
    "Tags": "File",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetUpdateSessionIdFileNameItem",
    "CommandInfo": "Invoke-GetUpdateSessionIdFileNameItem",
    "ApiName": "FileApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}/file/{file_name}",
    "Tags": "File",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListDownloadSessionIdItemFile",
    "CommandInfo": "Invoke-ListDownloadSessionIdItemFile",
    "ApiName": "FileApi",
    "Path": "/api/content/library/item/download-session/{download_session_id}/file",
    "Tags": "File",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListLibraryItemIdContentFile",
    "CommandInfo": "Invoke-ListLibraryItemIdContentFile",
    "ApiName": "FileApi",
    "Path": "/api/content/library/item/{library_item_id}/file",
    "Tags": "File",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListUpdateSessionIdItemFile",
    "CommandInfo": "Invoke-ListUpdateSessionIdItemFile",
    "ApiName": "FileApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}/file",
    "Tags": "File",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "PrepareDownloadSessionIdFile",
    "CommandInfo": "Invoke-PrepareDownloadSessionIdFile",
    "ApiName": "FileApi",
    "Path": "/api/content/library/item/download-session/{download_session_id}/file__action=prepare",
    "Tags": "File",
    "RelatedCommandInfos": "Initialize-LibraryItemDownloadsessionFilePrepareRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ValidateUpdateSessionIdFile",
    "CommandInfo": "Invoke-ValidateUpdateSessionIdFile",
    "ApiName": "FileApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}/file__action=validate",
    "Tags": "File",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateTemporaryVmFilesystemFiles",
    "CommandInfo": "Invoke-CreateTemporaryVmFilesystemFiles",
    "ApiName": "FilesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/filesystem/files__action=createTemporary",
    "Tags": "Files",
    "RelatedCommandInfos": "Initialize-VmGuestFilesystemFilesCreateTemporaryRequestBody",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmPathFiles",
    "CommandInfo": "Invoke-DeleteVmPathFiles",
    "ApiName": "FilesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/filesystem/files/{path}__action=delete",
    "Tags": "Files",
    "RelatedCommandInfos": "Initialize-VmGuestFilesystemFilesDeleteRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetVmPathFiles",
    "CommandInfo": "Invoke-GetVmPathFiles",
    "ApiName": "FilesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/filesystem/files/{path}__action=get",
    "Tags": "Files",
    "RelatedCommandInfos": "Initialize-VmGuestFilesystemFilesGetRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListVmFilesystemFiles",
    "CommandInfo": "Invoke-ListVmFilesystemFiles",
    "ApiName": "FilesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/filesystem/files__action=list",
    "Tags": "Files",
    "RelatedCommandInfos": "Initialize-VmGuestFilesystemFilesListRequestBody",
    "Method": "POST"
  },
  {
    "Name": "MoveVmFilesystemFiles",
    "CommandInfo": "Invoke-MoveVmFilesystemFiles",
    "ApiName": "FilesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/filesystem/files__action=move",
    "Tags": "Files",
    "RelatedCommandInfos": "Initialize-VmGuestFilesystemFilesMoveRequestBody",
    "Method": "POST"
  },
  {
    "Name": "UpdateVmFilesystemFiles",
    "CommandInfo": "Invoke-UpdateVmFilesystemFiles",
    "ApiName": "FilesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/filesystem/files__action=update",
    "Tags": "Files",
    "RelatedCommandInfos": "Initialize-VmGuestFilesystemFilesUpdateRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ConnectVmFloppy",
    "CommandInfo": "Invoke-ConnectVmFloppy",
    "ApiName": "FloppyApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/floppy/{floppy}__action=connect",
    "Tags": "Floppy",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateVmHardwareFloppy",
    "CommandInfo": "Invoke-CreateVmHardwareFloppy",
    "ApiName": "FloppyApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/floppy",
    "Tags": "Floppy",
    "RelatedCommandInfos": "Initialize-VmHardwareFloppyCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmFloppyHardware",
    "CommandInfo": "Invoke-DeleteVmFloppyHardware",
    "ApiName": "FloppyApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/floppy/{floppy}",
    "Tags": "Floppy",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DisconnectVmFloppy",
    "CommandInfo": "Invoke-DisconnectVmFloppy",
    "ApiName": "FloppyApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/floppy/{floppy}__action=disconnect",
    "Tags": "Floppy",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetVmFloppyHardware",
    "CommandInfo": "Invoke-GetVmFloppyHardware",
    "ApiName": "FloppyApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/floppy/{floppy}",
    "Tags": "Floppy",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmHardwareFloppy",
    "CommandInfo": "Invoke-ListVmHardwareFloppy",
    "ApiName": "FloppyApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/floppy",
    "Tags": "Floppy",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmFloppyHardware",
    "CommandInfo": "Invoke-UpdateVmFloppyHardware",
    "ApiName": "FloppyApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/floppy/{floppy}",
    "Tags": "Floppy",
    "RelatedCommandInfos": "Initialize-VmHardwareFloppyUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "ListFolder",
    "CommandInfo": "Invoke-ListFolder",
    "ApiName": "FolderApi",
    "Path": "/api/vcenter/folder",
    "Tags": "Folder",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetLoggingForwarding",
    "CommandInfo": "Invoke-GetLoggingForwarding",
    "ApiName": "ForwardingApi",
    "Path": "/api/appliance/logging/forwarding",
    "Tags": "Forwarding",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetLoggingForwarding",
    "CommandInfo": "Invoke-SetLoggingForwarding",
    "ApiName": "ForwardingApi",
    "Path": "/api/appliance/logging/forwarding",
    "Tags": "Forwarding",
    "RelatedCommandInfos": "Initialize-LoggingForwardingSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "TestLoggingForwarding",
    "CommandInfo": "Invoke-TestLoggingForwarding",
    "ApiName": "ForwardingApi",
    "Path": "/api/appliance/logging/forwarding__action=test",
    "Tags": "Forwarding",
    "RelatedCommandInfos": "Initialize-LoggingForwardingTestRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetTlsManualParametersGlobal",
    "CommandInfo": "Invoke-GetTlsManualParametersGlobal",
    "ApiName": "GlobalApi",
    "Path": "/api/appliance/tls/manual-parameters/global",
    "Tags": "Global",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetTlsProfilesGlobal",
    "CommandInfo": "Invoke-GetTlsProfilesGlobal",
    "ApiName": "GlobalApi",
    "Path": "/api/appliance/tls/profiles/global",
    "Tags": "Global",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetProfilesGlobalAsync",
    "CommandInfo": "Invoke-SetProfilesGlobalAsync",
    "ApiName": "GlobalApi",
    "Path": "/api/appliance/tls/profiles/global__vmw-task=true",
    "Tags": "Global",
    "RelatedCommandInfos": "Initialize-TlsProfilesGlobalSetSpec",
    "Method": "PUT"
  },
  {
    "Name": "GetSystemGlobalFips",
    "CommandInfo": "Invoke-GetSystemGlobalFips",
    "ApiName": "GlobalFipsApi",
    "Path": "/api/appliance/system/global-fips",
    "Tags": "GlobalFips",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetSystemGlobalFips",
    "CommandInfo": "Invoke-SetSystemGlobalFips",
    "ApiName": "GlobalFipsApi",
    "Path": "/api/appliance/system/global-fips",
    "Tags": "GlobalFips",
    "RelatedCommandInfos": "Initialize-SystemSecurityGlobalFipsUpdateSpec",
    "Method": "PUT"
  },
  {
    "Name": "CreateContentRegistriesHarbor",
    "CommandInfo": "Invoke-CreateContentRegistriesHarbor",
    "ApiName": "HarborApi",
    "Path": "/api/vcenter/content/registries/harbor",
    "Tags": "Harbor",
    "RelatedCommandInfos": "Initialize-ContentRegistriesHarborCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteRegistryRegistriesHarbor",
    "CommandInfo": "Invoke-DeleteRegistryRegistriesHarbor",
    "ApiName": "HarborApi",
    "Path": "/api/vcenter/content/registries/harbor/{registry}",
    "Tags": "Harbor",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetRegistryRegistriesHarbor",
    "CommandInfo": "Invoke-GetRegistryRegistriesHarbor",
    "ApiName": "HarborApi",
    "Path": "/api/vcenter/content/registries/harbor/{registry}",
    "Tags": "Harbor",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListContentRegistriesHarbor",
    "CommandInfo": "Invoke-ListContentRegistriesHarbor",
    "ApiName": "HarborApi",
    "Path": "/api/vcenter/content/registries/harbor",
    "Tags": "Harbor",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmHardware",
    "CommandInfo": "Invoke-GetVmHardware",
    "ApiName": "HardwareApi",
    "Path": "/api/vcenter/vm/{vm}/hardware",
    "Tags": "Hardware",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmHardware",
    "CommandInfo": "Invoke-UpdateVmHardware",
    "ApiName": "HardwareApi",
    "Path": "/api/vcenter/vm/{vm}/hardware",
    "Tags": "Hardware",
    "RelatedCommandInfos": "Initialize-VmHardwareUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "UpgradeVmHardware",
    "CommandInfo": "Invoke-UpgradeVmHardware",
    "ApiName": "HardwareApi",
    "Path": "/api/vcenter/vm/{vm}/hardware__action=upgrade",
    "Tags": "Hardware",
    "RelatedCommandInfos": "Initialize-VmHardwareUpgradeRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CheckClusterReportsHardwareCompatibilityAsync",
    "CommandInfo": "Invoke-CheckClusterReportsHardwareCompatibilityAsync",
    "ApiName": "HardwareCompatibilityApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/reports/hardware-compatibility__action=check&vmw-task=true",
    "Tags": "HardwareCompatibility",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetClusterSoftwareReportsHardwareCompatibility",
    "CommandInfo": "Invoke-GetClusterSoftwareReportsHardwareCompatibility",
    "ApiName": "HardwareCompatibilityApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/reports/hardware-compatibility",
    "Tags": "HardwareCompatibility",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "DeleteClusterDraftSoftwareHardwareSupport",
    "CommandInfo": "Invoke-DeleteClusterDraftSoftwareHardwareSupport",
    "ApiName": "HardwareSupportApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/hardware-support",
    "Tags": "HardwareSupport",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterDraftSoftwareHardwareSupport",
    "CommandInfo": "Invoke-GetClusterDraftSoftwareHardwareSupport",
    "ApiName": "HardwareSupportApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/hardware-support",
    "Tags": "HardwareSupport",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterSoftwareHardwareSupport",
    "CommandInfo": "Invoke-GetClusterSoftwareHardwareSupport",
    "ApiName": "HardwareSupportApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/hardware-support",
    "Tags": "HardwareSupport",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetClusterDraftSoftwareHardwareSupport",
    "CommandInfo": "Invoke-SetClusterDraftSoftwareHardwareSupport",
    "ApiName": "HardwareSupportApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/hardware-support",
    "Tags": "HardwareSupport",
    "RelatedCommandInfos": "Initialize-SettingsHardwareSupportSpec",
    "Method": "PUT"
  },
  {
    "Name": "GetItemHealthMessages",
    "CommandInfo": "Invoke-GetItemHealthMessages",
    "ApiName": "HealthApi",
    "Path": "/api/appliance/health/{item}/messages",
    "Tags": "Health",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetRegistryRegistriesHealth",
    "CommandInfo": "Invoke-GetRegistryRegistriesHealth",
    "ApiName": "HealthApi",
    "Path": "/api/vcenter/content/registries/{registry}/health",
    "Tags": "Health",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHealthSettings",
    "CommandInfo": "Invoke-GetHealthSettings",
    "ApiName": "HealthCheckSettingsApi",
    "Path": "/api/appliance/health/settings",
    "Tags": "HealthCheckSettings",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateHealthSettings",
    "CommandInfo": "Invoke-UpdateHealthSettings",
    "ApiName": "HealthCheckSettingsApi",
    "Path": "/api/appliance/health/settings",
    "Tags": "HealthCheckSettings",
    "RelatedCommandInfos": "Initialize-HealthCheckSettingsUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "ConnectHost",
    "CommandInfo": "Invoke-ConnectHost",
    "ApiName": "HostApi",
    "Path": "/api/vcenter/host/{host}__action=connect",
    "Tags": "Host",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateHost",
    "CommandInfo": "Invoke-CreateHost",
    "ApiName": "HostApi",
    "Path": "/api/vcenter/host",
    "Tags": "Host",
    "RelatedCommandInfos": "Initialize-HostCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteHost",
    "CommandInfo": "Invoke-DeleteHost",
    "ApiName": "HostApi",
    "Path": "/api/vcenter/host/{host}",
    "Tags": "Host",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DisconnectHost",
    "CommandInfo": "Invoke-DisconnectHost",
    "ApiName": "HostApi",
    "Path": "/api/vcenter/host/{host}__action=disconnect",
    "Tags": "Host",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ListHost",
    "CommandInfo": "Invoke-ListHost",
    "ApiName": "HostApi",
    "Path": "/api/vcenter/host",
    "Tags": "Host",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetNetworkingDnsHostname",
    "CommandInfo": "Invoke-GetNetworkingDnsHostname",
    "ApiName": "HostnameApi",
    "Path": "/api/appliance/networking/dns/hostname",
    "Tags": "Hostname",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetNetworkingDnsHostname",
    "CommandInfo": "Invoke-SetNetworkingDnsHostname",
    "ApiName": "HostnameApi",
    "Path": "/api/appliance/networking/dns/hostname",
    "Tags": "Hostname",
    "RelatedCommandInfos": "Initialize-NetworkingDnsHostnameSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "TestDnsHostname",
    "CommandInfo": "Invoke-TestDnsHostname",
    "ApiName": "HostnameApi",
    "Path": "/api/appliance/networking/dns/hostname__action=test",
    "Tags": "Hostname",
    "RelatedCommandInfos": "Initialize-NetworkingDnsHostnameTestRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetNamespaceManagementCapability",
    "CommandInfo": "Invoke-GetNamespaceManagementCapability",
    "ApiName": "HostsConfigApi",
    "Path": "/api/vcenter/namespace-management/capability",
    "Tags": "HostsConfig",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmGuestIdentity",
    "CommandInfo": "Invoke-GetVmGuestIdentity",
    "ApiName": "IdentityApi",
    "Path": "/api/vcenter/vm/{vm}/guest/identity",
    "Tags": "Identity",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "MountIsoImage",
    "CommandInfo": "Invoke-MountIsoImage",
    "ApiName": "ImageApi",
    "Path": "/api/vcenter/iso/image__action=mount",
    "Tags": "Image",
    "RelatedCommandInfos": "Initialize-IsoImageMountRequestBody",
    "Method": "POST"
  },
  {
    "Name": "UnmountIsoImage",
    "CommandInfo": "Invoke-UnmountIsoImage",
    "ApiName": "ImageApi",
    "Path": "/api/vcenter/iso/image__action=unmount",
    "Tags": "Image",
    "RelatedCommandInfos": "Initialize-IsoImageUnmountRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListOvfImportFlag",
    "CommandInfo": "Invoke-ListOvfImportFlag",
    "ApiName": "ImportFlagApi",
    "Path": "/api/vcenter/ovf/import-flag",
    "Tags": "ImportFlag",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CancelDeploymentHistory",
    "CommandInfo": "Invoke-CancelDeploymentHistory",
    "ApiName": "ImportHistoryApi",
    "Path": "/api/vcenter/deployment/history__action=cancel",
    "Tags": "ImportHistory",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetDeploymentHistory",
    "CommandInfo": "Invoke-GetDeploymentHistory",
    "ApiName": "ImportHistoryApi",
    "Path": "/api/vcenter/deployment/history",
    "Tags": "ImportHistory",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "PauseDeploymentHistory",
    "CommandInfo": "Invoke-PauseDeploymentHistory",
    "ApiName": "ImportHistoryApi",
    "Path": "/api/vcenter/deployment/history__action=pause",
    "Tags": "ImportHistory",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ResumeDeploymentHistory",
    "CommandInfo": "Invoke-ResumeDeploymentHistory",
    "ApiName": "ImportHistoryApi",
    "Path": "/api/vcenter/deployment/history__action=resume",
    "Tags": "ImportHistory",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "StartDeploymentHistory",
    "CommandInfo": "Invoke-StartDeploymentHistory",
    "ApiName": "ImportHistoryApi",
    "Path": "/api/vcenter/deployment/history__action=start",
    "Tags": "ImportHistory",
    "RelatedCommandInfos": "Initialize-DeploymentImportHistoryCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "GetNetworkingFirewallInbound",
    "CommandInfo": "Invoke-GetNetworkingFirewallInbound",
    "ApiName": "InboundApi",
    "Path": "/api/appliance/networking/firewall/inbound",
    "Tags": "Inbound",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetNetworkingFirewallInbound",
    "CommandInfo": "Invoke-SetNetworkingFirewallInbound",
    "ApiName": "InboundApi",
    "Path": "/api/appliance/networking/firewall/inbound",
    "Tags": "Inbound",
    "RelatedCommandInfos": "Initialize-NetworkingFirewallInboundSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "CancelDeploymentInstall",
    "CommandInfo": "Invoke-CancelDeploymentInstall",
    "ApiName": "InstallApi",
    "Path": "/api/vcenter/deployment/install__action=cancel",
    "Tags": "Install",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CheckDeploymentInstall",
    "CommandInfo": "Invoke-CheckDeploymentInstall",
    "ApiName": "InstallApi",
    "Path": "/api/vcenter/deployment/install__action=check",
    "Tags": "Install",
    "RelatedCommandInfos": "Initialize-DeploymentInstallInstallSpec",
    "Method": "POST"
  },
  {
    "Name": "GetDeploymentInstall",
    "CommandInfo": "Invoke-GetDeploymentInstall",
    "ApiName": "InstallApi",
    "Path": "/api/vcenter/deployment/install",
    "Tags": "Install",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "StartDeploymentInstall",
    "CommandInfo": "Invoke-StartDeploymentInstall",
    "ApiName": "InstallApi",
    "Path": "/api/vcenter/deployment/install__action=start",
    "Tags": "Install",
    "RelatedCommandInfos": "Initialize-DeploymentInstallInstallSpec",
    "Method": "POST"
  },
  {
    "Name": "ListHostSoftwareInstalledComponents",
    "CommandInfo": "Invoke-ListHostSoftwareInstalledComponents",
    "ApiName": "InstalledComponentsApi",
    "Path": "/api/esx/hosts/{host}/software/installed-components",
    "Tags": "InstalledComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ExtractClusterInstalledImagesAsync",
    "CommandInfo": "Invoke-ExtractClusterInstalledImagesAsync",
    "ApiName": "InstalledImagesApi",
    "Path": "/api/esx/settings/clusters/{cluster}/installed-images__action=extract&vmw-task=true",
    "Tags": "InstalledImages",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetClusterInstalledImages",
    "CommandInfo": "Invoke-GetClusterInstalledImages",
    "ApiName": "InstalledImagesApi",
    "Path": "/api/esx/settings/clusters/{cluster}/installed-images",
    "Tags": "InstalledImages",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ConnectVmToolsInstaller",
    "CommandInfo": "Invoke-ConnectVmToolsInstaller",
    "ApiName": "InstallerApi",
    "Path": "/api/vcenter/vm/{vm}/tools/installer__action=connect",
    "Tags": "Installer",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "DisconnectVmToolsInstaller",
    "CommandInfo": "Invoke-DisconnectVmToolsInstaller",
    "ApiName": "InstallerApi",
    "Path": "/api/vcenter/vm/{vm}/tools/installer__action=disconnect",
    "Tags": "Installer",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetVmToolsInstaller",
    "CommandInfo": "Invoke-GetVmToolsInstaller",
    "ApiName": "InstallerApi",
    "Path": "/api/vcenter/vm/{vm}/tools/installer",
    "Tags": "Installer",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateNamespaceInstancesRegistervm",
    "CommandInfo": "Invoke-CreateNamespaceInstancesRegistervm",
    "ApiName": "InstancesApi",
    "Path": "/api/vcenter/namespaces/instances/{namespace}/registervm",
    "Tags": "Instances",
    "RelatedCommandInfos": "Initialize-NamespacesInstancesRegisterVMSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateNamespacesInstances",
    "CommandInfo": "Invoke-CreateNamespacesInstances",
    "ApiName": "InstancesApi",
    "Path": "/api/vcenter/namespaces/instances",
    "Tags": "Instances",
    "RelatedCommandInfos": "Initialize-NamespacesInstancesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateNamespacesInstancesV2",
    "CommandInfo": "Invoke-CreateNamespacesInstancesV2",
    "ApiName": "InstancesApi",
    "Path": "/api/vcenter/namespaces/instances/v2",
    "Tags": "Instances",
    "RelatedCommandInfos": "Initialize-NamespacesInstancesCreateSpecV2",
    "Method": "POST"
  },
  {
    "Name": "DeleteNamespaceInstances",
    "CommandInfo": "Invoke-DeleteNamespaceInstances",
    "ApiName": "InstancesApi",
    "Path": "/api/vcenter/namespaces/instances/{namespace}",
    "Tags": "Instances",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetNamespaceInstances",
    "CommandInfo": "Invoke-GetNamespaceInstances",
    "ApiName": "InstancesApi",
    "Path": "/api/vcenter/namespaces/instances/{namespace}",
    "Tags": "Instances",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetNamespaceInstancesV2",
    "CommandInfo": "Invoke-GetNamespaceInstancesV2",
    "ApiName": "InstancesApi",
    "Path": "/api/vcenter/namespaces/instances/v2/{namespace}",
    "Tags": "Instances",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetNamespacesInstancesV2",
    "CommandInfo": "Invoke-GetNamespacesInstancesV2",
    "ApiName": "InstancesApi",
    "Path": "/api/vcenter/namespaces/instances/v2",
    "Tags": "Instances",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNamespacesInstances",
    "CommandInfo": "Invoke-ListNamespacesInstances",
    "ApiName": "InstancesApi",
    "Path": "/api/vcenter/namespaces/instances",
    "Tags": "Instances",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNamespacesUser",
    "CommandInfo": "Invoke-ListNamespacesUser",
    "ApiName": "InstancesApi",
    "Path": "/api/vcenter/namespaces-user/namespaces",
    "Tags": "Instances",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetNamespaceInstances",
    "CommandInfo": "Invoke-SetNamespaceInstances",
    "ApiName": "InstancesApi",
    "Path": "/api/vcenter/namespaces/instances/{namespace}",
    "Tags": "Instances",
    "RelatedCommandInfos": "Initialize-NamespacesInstancesSetSpec",
    "Method": "PUT"
  },
  {
    "Name": "UpdateNamespaceInstances",
    "CommandInfo": "Invoke-UpdateNamespaceInstances",
    "ApiName": "InstancesApi",
    "Path": "/api/vcenter/namespaces/instances/{namespace}",
    "Tags": "Instances",
    "RelatedCommandInfos": "Initialize-NamespacesInstancesUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetInterfaceNameNetworking",
    "CommandInfo": "Invoke-GetInterfaceNameNetworking",
    "ApiName": "InterfacesApi",
    "Path": "/api/appliance/networking/interfaces/{interface_name}",
    "Tags": "Interfaces",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNetworkingInterfaces",
    "CommandInfo": "Invoke-ListNetworkingInterfaces",
    "ApiName": "InterfacesApi",
    "Path": "/api/appliance/networking/interfaces",
    "Tags": "Interfaces",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmGuestNetworkingInterfaces",
    "CommandInfo": "Invoke-ListVmGuestNetworkingInterfaces",
    "ApiName": "InterfacesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/networking/interfaces",
    "Tags": "Interfaces",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateDiscoveryInteropReportAsync",
    "CommandInfo": "Invoke-CreateDiscoveryInteropReportAsync",
    "ApiName": "InteropReportApi",
    "Path": "/api/vcenter/lcm/discovery/interop-report__vmw-task=true",
    "Tags": "InteropReport",
    "RelatedCommandInfos": "Initialize-LcmDiscoveryInteropReportSpec",
    "Method": "POST"
  },
  {
    "Name": "GetInterfaceNameNetworkingIpv4",
    "CommandInfo": "Invoke-GetInterfaceNameNetworkingIpv4",
    "ApiName": "Ipv4Api",
    "Path": "/api/appliance/networking/interfaces/{interface_name}/ipv4",
    "Tags": "Ipv4",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetInterfaceNameNetworkingIpv4",
    "CommandInfo": "Invoke-SetInterfaceNameNetworkingIpv4",
    "ApiName": "Ipv4Api",
    "Path": "/api/appliance/networking/interfaces/{interface_name}/ipv4",
    "Tags": "Ipv4",
    "RelatedCommandInfos": "Initialize-NetworkingInterfacesIpv4Config",
    "Method": "PUT"
  },
  {
    "Name": "GetInterfaceNameNetworkingIpv6",
    "CommandInfo": "Invoke-GetInterfaceNameNetworkingIpv6",
    "ApiName": "Ipv6Api",
    "Path": "/api/appliance/networking/interfaces/{interface_name}/ipv6",
    "Tags": "Ipv6",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetInterfaceNameNetworkingIpv6",
    "CommandInfo": "Invoke-SetInterfaceNameNetworkingIpv6",
    "ApiName": "Ipv6Api",
    "Path": "/api/appliance/networking/interfaces/{interface_name}/ipv6",
    "Tags": "Ipv6",
    "RelatedCommandInfos": "Initialize-NetworkingInterfacesIpv6Config",
    "Method": "PUT"
  },
  {
    "Name": "CopySourceLibraryItemId",
    "CommandInfo": "Invoke-CopySourceLibraryItemId",
    "ApiName": "ItemApi",
    "Path": "/api/content/library/item/{source_library_item_id}__action=copy",
    "Tags": "Item",
    "RelatedCommandInfos": "Initialize-LibraryItemModel",
    "Method": "POST"
  },
  {
    "Name": "CreateContentLibraryItem",
    "CommandInfo": "Invoke-CreateContentLibraryItem",
    "ApiName": "ItemApi",
    "Path": "/api/content/library/item",
    "Tags": "Item",
    "RelatedCommandInfos": "Initialize-LibraryItemModel",
    "Method": "POST"
  },
  {
    "Name": "DeleteLibraryItemIdContent",
    "CommandInfo": "Invoke-DeleteLibraryItemIdContent",
    "ApiName": "ItemApi",
    "Path": "/api/content/library/item/{library_item_id}",
    "Tags": "Item",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "FindLibraryItem",
    "CommandInfo": "Invoke-FindLibraryItem",
    "ApiName": "ItemApi",
    "Path": "/api/content/library/item__action=find",
    "Tags": "Item",
    "RelatedCommandInfos": "Initialize-LibraryItemFindSpec",
    "Method": "POST"
  },
  {
    "Name": "GetLibraryItemIdContent",
    "CommandInfo": "Invoke-GetLibraryItemIdContent",
    "ApiName": "ItemApi",
    "Path": "/api/content/library/item/{library_item_id}",
    "Tags": "Item",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListLibraryItem",
    "CommandInfo": "Invoke-ListLibraryItem",
    "ApiName": "ItemApi",
    "Path": "/api/content/library/item__library_id",
    "Tags": "Item",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "PublishLibraryItemId",
    "CommandInfo": "Invoke-PublishLibraryItemId",
    "ApiName": "ItemApi",
    "Path": "/api/content/library/item/{library_item_id}__action=publish",
    "Tags": "Item",
    "RelatedCommandInfos": "Initialize-LibraryItemPublishRequestBody",
    "Method": "POST"
  },
  {
    "Name": "UpdateLibraryItemIdContent",
    "CommandInfo": "Invoke-UpdateLibraryItemIdContent",
    "ApiName": "ItemApi",
    "Path": "/api/content/library/item/{library_item_id}",
    "Tags": "Item",
    "RelatedCommandInfos": "Initialize-LibraryItemModel",
    "Method": "PATCH"
  },
  {
    "Name": "CancelIdJob",
    "CommandInfo": "Invoke-CancelIdJob",
    "ApiName": "JobApi",
    "Path": "/api/appliance/recovery/backup/job/{id}__action=cancel",
    "Tags": "Job",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CancelRestoreJob",
    "CommandInfo": "Invoke-CancelRestoreJob",
    "ApiName": "JobApi",
    "Path": "/api/appliance/recovery/restore/job__action=cancel",
    "Tags": "Job",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateRecoveryBackupJob",
    "CommandInfo": "Invoke-CreateRecoveryBackupJob",
    "ApiName": "JobApi",
    "Path": "/api/appliance/recovery/backup/job",
    "Tags": "Job",
    "RelatedCommandInfos": "Initialize-RecoveryBackupJobBackupRequest",
    "Method": "POST"
  },
  {
    "Name": "CreateRecoveryReconciliationJob",
    "CommandInfo": "Invoke-CreateRecoveryReconciliationJob",
    "ApiName": "JobApi",
    "Path": "/api/appliance/recovery/reconciliation/job",
    "Tags": "Job",
    "RelatedCommandInfos": "Initialize-RecoveryReconciliationJobCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateRecoveryRestoreJob",
    "CommandInfo": "Invoke-CreateRecoveryRestoreJob",
    "ApiName": "JobApi",
    "Path": "/api/appliance/recovery/restore/job",
    "Tags": "Job",
    "RelatedCommandInfos": "Initialize-RecoveryRestoreJobRestoreRequest",
    "Method": "POST"
  },
  {
    "Name": "GetIdBackupJob",
    "CommandInfo": "Invoke-GetIdBackupJob",
    "ApiName": "JobApi",
    "Path": "/api/appliance/recovery/backup/job/{id}",
    "Tags": "Job",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetRecoveryReconciliationJob",
    "CommandInfo": "Invoke-GetRecoveryReconciliationJob",
    "ApiName": "JobApi",
    "Path": "/api/appliance/recovery/reconciliation/job",
    "Tags": "Job",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetRecoveryRestoreJob",
    "CommandInfo": "Invoke-GetRecoveryRestoreJob",
    "ApiName": "JobApi",
    "Path": "/api/appliance/recovery/restore/job",
    "Tags": "Job",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListRecoveryBackupJob",
    "CommandInfo": "Invoke-ListRecoveryBackupJob",
    "ApiName": "JobApi",
    "Path": "/api/appliance/recovery/backup/job",
    "Tags": "Job",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateSupervisorArchiveRestoreJobs",
    "CommandInfo": "Invoke-CreateSupervisorArchiveRestoreJobs",
    "ApiName": "JobsApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/recovery/restore/jobs/{archive}",
    "Tags": "Jobs",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateSupervisorRecoveryBackupJobs",
    "CommandInfo": "Invoke-CreateSupervisorRecoveryBackupJobs",
    "ApiName": "JobsApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/recovery/backup/jobs",
    "Tags": "Jobs",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorsRecoveryBackupJobsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "GetHostTrustedInfrastructureKms",
    "CommandInfo": "Invoke-GetHostTrustedInfrastructureKms",
    "ApiName": "KmsApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-hosts/{host}/kms/",
    "Tags": "Kms",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "QueryTrustAuthorityHostsKms",
    "CommandInfo": "Invoke-QueryTrustAuthorityHostsKms",
    "ApiName": "KmsApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-hosts/kms__action=query",
    "Tags": "Kms",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityHostsKmsFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "GetClusterConfigurationReportsLastApplyResult",
    "CommandInfo": "Invoke-GetClusterConfigurationReportsLastApplyResult",
    "ApiName": "LastApplyResultApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/reports/last-apply-result",
    "Tags": "LastApplyResult",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterSoftwareReportsLastApplyResult",
    "CommandInfo": "Invoke-GetClusterSoftwareReportsLastApplyResult",
    "ApiName": "LastApplyResultApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/reports/last-apply-result",
    "Tags": "LastApplyResult",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostSoftwareReportsLastApplyResult",
    "CommandInfo": "Invoke-GetHostSoftwareReportsLastApplyResult",
    "ApiName": "LastApplyResultApi",
    "Path": "/api/esx/settings/hosts/{host}/software/reports/last-apply-result",
    "Tags": "LastApplyResult",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterSoftwareReportsLastCheckResult",
    "CommandInfo": "Invoke-GetClusterSoftwareReportsLastCheckResult",
    "ApiName": "LastCheckResultApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/reports/last-check-result",
    "Tags": "LastCheckResult",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostSoftwareReportsLastCheckResult",
    "CommandInfo": "Invoke-GetHostSoftwareReportsLastCheckResult",
    "ApiName": "LastCheckResultApi",
    "Path": "/api/esx/settings/hosts/{host}/software/reports/last-check-result",
    "Tags": "LastCheckResult",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterConfigurationReportsLastComplianceResult",
    "CommandInfo": "Invoke-GetClusterConfigurationReportsLastComplianceResult",
    "ApiName": "LastComplianceResultApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/reports/last-compliance-result",
    "Tags": "LastComplianceResult",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterConfigurationReportsLastPrecheckResult",
    "CommandInfo": "Invoke-GetClusterConfigurationReportsLastPrecheckResult",
    "ApiName": "LastPrecheckResultApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/reports/last-precheck-result",
    "Tags": "LastPrecheckResult",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetAuthorizationPrivilegeChecksLatest",
    "CommandInfo": "Invoke-GetAuthorizationPrivilegeChecksLatest",
    "ApiName": "LatestApi",
    "Path": "/api/vcenter/authorization/privilege-checks/latest",
    "Tags": "Latest",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "FindContentLibrary",
    "CommandInfo": "Invoke-FindContentLibrary",
    "ApiName": "LibraryApi",
    "Path": "/api/content/library__action=find",
    "Tags": "Library",
    "RelatedCommandInfos": "Initialize-LibraryFindSpec",
    "Method": "POST"
  },
  {
    "Name": "GetLibraryIdContent",
    "CommandInfo": "Invoke-GetLibraryIdContent",
    "ApiName": "LibraryApi",
    "Path": "/api/content/library/{library_id}",
    "Tags": "Library",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListContentLibrary",
    "CommandInfo": "Invoke-ListContentLibrary",
    "ApiName": "LibraryApi",
    "Path": "/api/content/library",
    "Tags": "Library",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateLibraryIdContent",
    "CommandInfo": "Invoke-UpdateLibraryIdContent",
    "ApiName": "LibraryApi",
    "Path": "/api/content/library/{library_id}",
    "Tags": "Library",
    "RelatedCommandInfos": "Initialize-LibraryModel",
    "Method": "PATCH"
  },
  {
    "Name": "CreateOvfLibraryItem",
    "CommandInfo": "Invoke-CreateOvfLibraryItem",
    "ApiName": "LibraryItemApi",
    "Path": "/api/vcenter/ovf/library-item",
    "Tags": "LibraryItem",
    "RelatedCommandInfos": "Initialize-OvfLibraryItemCreateRequestBody",
    "Method": "POST"
  },
  {
    "Name": "DeployOvfLibraryItemId",
    "CommandInfo": "Invoke-DeployOvfLibraryItemId",
    "ApiName": "LibraryItemApi",
    "Path": "/api/vcenter/ovf/library-item/{ovf_library_item_id}__action=deploy",
    "Tags": "LibraryItem",
    "RelatedCommandInfos": "Initialize-OvfLibraryItemDeployRequestBody",
    "Method": "POST"
  },
  {
    "Name": "FilterOvfLibraryItemId",
    "CommandInfo": "Invoke-FilterOvfLibraryItemId",
    "ApiName": "LibraryItemApi",
    "Path": "/api/vcenter/ovf/library-item/{ovf_library_item_id}__action=filter",
    "Tags": "LibraryItem",
    "RelatedCommandInfos": "Initialize-OvfLibraryItemFilterRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetVmLibraryItem",
    "CommandInfo": "Invoke-GetVmLibraryItem",
    "ApiName": "LibraryItemApi",
    "Path": "/api/vcenter/vm/{vm}/library-item",
    "Tags": "LibraryItem",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateVmTemplateLibraryItems",
    "CommandInfo": "Invoke-CreateVmTemplateLibraryItems",
    "ApiName": "LibraryItemsApi",
    "Path": "/api/vcenter/vm-template/library-items",
    "Tags": "LibraryItems",
    "RelatedCommandInfos": "Initialize-VmTemplateLibraryItemsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeployTemplateLibraryItemLibraryItems",
    "CommandInfo": "Invoke-DeployTemplateLibraryItemLibraryItems",
    "ApiName": "LibraryItemsApi",
    "Path": "/api/vcenter/vm-template/library-items/{template_library_item}__action=deploy",
    "Tags": "LibraryItems",
    "RelatedCommandInfos": "Initialize-VmTemplateLibraryItemsDeploySpec",
    "Method": "POST"
  },
  {
    "Name": "GetTemplateLibraryItemVmTemplate",
    "CommandInfo": "Invoke-GetTemplateLibraryItemVmTemplate",
    "ApiName": "LibraryItemsApi",
    "Path": "/api/vcenter/vm-template/library-items/{template_library_item}",
    "Tags": "LibraryItems",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateHvcLinks",
    "CommandInfo": "Invoke-CreateHvcLinks",
    "ApiName": "LinksApi",
    "Path": "/api/hvc/links",
    "Tags": "Links",
    "RelatedCommandInfos": "Initialize-HvcLinksCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteLink",
    "CommandInfo": "Invoke-DeleteLink",
    "ApiName": "LinksApi",
    "Path": "/api/hvc/links/{link}__action=delete",
    "Tags": "Links",
    "RelatedCommandInfos": "Initialize-HvcLinksDeleteWithCredentialsRequestBody",
    "Method": "POST"
  },
  {
    "Name": "DeleteLinkHvc",
    "CommandInfo": "Invoke-DeleteLinkHvc",
    "ApiName": "LinksApi",
    "Path": "/api/hvc/links/{link}",
    "Tags": "Links",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetLinkHvc",
    "CommandInfo": "Invoke-GetLinkHvc",
    "ApiName": "LinksApi",
    "Path": "/api/hvc/links/{link}",
    "Tags": "Links",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHvcLinks",
    "CommandInfo": "Invoke-ListHvcLinks",
    "ApiName": "LinksApi",
    "Path": "/api/hvc/links",
    "Tags": "Links",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHealthLoad",
    "CommandInfo": "Invoke-GetHealthLoad",
    "ApiName": "LoadApi",
    "Path": "/api/appliance/health/load",
    "Tags": "Load",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterIdNamespaceManagementLoadBalancers",
    "CommandInfo": "Invoke-GetClusterIdNamespaceManagementLoadBalancers",
    "ApiName": "LoadBalancersApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/load-balancers/{id}",
    "Tags": "LoadBalancers",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterNamespaceManagementLoadBalancers",
    "CommandInfo": "Invoke-ListClusterNamespaceManagementLoadBalancers",
    "ApiName": "LoadBalancersApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/load-balancers",
    "Tags": "LoadBalancers",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetClusterIdNamespaceManagementLoadBalancers",
    "CommandInfo": "Invoke-SetClusterIdNamespaceManagementLoadBalancers",
    "ApiName": "LoadBalancersApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/load-balancers/{id}",
    "Tags": "LoadBalancers",
    "RelatedCommandInfos": "Initialize-NamespaceManagementLoadBalancersSetSpec",
    "Method": "PUT"
  },
  {
    "Name": "UpdateClusterIdNamespaceManagementLoadBalancers",
    "CommandInfo": "Invoke-UpdateClusterIdNamespaceManagementLoadBalancers",
    "ApiName": "LoadBalancersApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/load-balancers/{id}",
    "Tags": "LoadBalancers",
    "RelatedCommandInfos": "Initialize-NamespaceManagementLoadBalancersUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "CreateLocalAccounts",
    "CommandInfo": "Invoke-CreateLocalAccounts",
    "ApiName": "LocalAccountsApi",
    "Path": "/api/appliance/local-accounts",
    "Tags": "LocalAccounts",
    "RelatedCommandInfos": "Initialize-LocalAccountsCreateRequestBody",
    "Method": "POST"
  },
  {
    "Name": "DeleteUsernameLocalAccounts",
    "CommandInfo": "Invoke-DeleteUsernameLocalAccounts",
    "ApiName": "LocalAccountsApi",
    "Path": "/api/appliance/local-accounts/{username}",
    "Tags": "LocalAccounts",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetUsernameLocalAccounts",
    "CommandInfo": "Invoke-GetUsernameLocalAccounts",
    "ApiName": "LocalAccountsApi",
    "Path": "/api/appliance/local-accounts/{username}",
    "Tags": "LocalAccounts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListLocalAccounts",
    "CommandInfo": "Invoke-ListLocalAccounts",
    "ApiName": "LocalAccountsApi",
    "Path": "/api/appliance/local-accounts",
    "Tags": "LocalAccounts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetUsernameLocalAccounts",
    "CommandInfo": "Invoke-SetUsernameLocalAccounts",
    "ApiName": "LocalAccountsApi",
    "Path": "/api/appliance/local-accounts/{username}",
    "Tags": "LocalAccounts",
    "RelatedCommandInfos": "Initialize-LocalAccountsConfig",
    "Method": "PUT"
  },
  {
    "Name": "UpdateUsernameLocalAccounts",
    "CommandInfo": "Invoke-UpdateUsernameLocalAccounts",
    "ApiName": "LocalAccountsApi",
    "Path": "/api/appliance/local-accounts/{username}",
    "Tags": "LocalAccounts",
    "RelatedCommandInfos": "Initialize-LocalAccountsUpdateConfig",
    "Method": "PATCH"
  },
  {
    "Name": "GetVmGuestLocalFilesystem",
    "CommandInfo": "Invoke-GetVmGuestLocalFilesystem",
    "ApiName": "LocalFilesystemApi",
    "Path": "/api/vcenter/vm/{vm}/guest/local-filesystem",
    "Tags": "LocalFilesystem",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateContentLocalLibrary",
    "CommandInfo": "Invoke-CreateContentLocalLibrary",
    "ApiName": "LocalLibraryApi",
    "Path": "/api/content/local-library",
    "Tags": "LocalLibrary",
    "RelatedCommandInfos": "Initialize-LibraryModel",
    "Method": "POST"
  },
  {
    "Name": "DeleteLibraryIdContentLocalLibrary",
    "CommandInfo": "Invoke-DeleteLibraryIdContentLocalLibrary",
    "ApiName": "LocalLibraryApi",
    "Path": "/api/content/local-library/{library_id}",
    "Tags": "LocalLibrary",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetLibraryIdContentLocalLibrary",
    "CommandInfo": "Invoke-GetLibraryIdContentLocalLibrary",
    "ApiName": "LocalLibraryApi",
    "Path": "/api/content/local-library/{library_id}",
    "Tags": "LocalLibrary",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListContentLocalLibrary",
    "CommandInfo": "Invoke-ListContentLocalLibrary",
    "ApiName": "LocalLibraryApi",
    "Path": "/api/content/local-library",
    "Tags": "LocalLibrary",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "PublishLibraryIdLocalLibrary",
    "CommandInfo": "Invoke-PublishLibraryIdLocalLibrary",
    "ApiName": "LocalLibraryApi",
    "Path": "/api/content/local-library/{library_id}__action=publish",
    "Tags": "LocalLibrary",
    "RelatedCommandInfos": "Initialize-LocalLibraryPublishRequestBody",
    "Method": "POST"
  },
  {
    "Name": "UpdateLibraryIdContentLocalLibrary",
    "CommandInfo": "Invoke-UpdateLibraryIdContentLocalLibrary",
    "ApiName": "LocalLibraryApi",
    "Path": "/api/content/local-library/{library_id}",
    "Tags": "LocalLibrary",
    "RelatedCommandInfos": "Initialize-LibraryModel",
    "Method": "PATCH"
  },
  {
    "Name": "ListHardwareSupportManagers",
    "CommandInfo": "Invoke-ListHardwareSupportManagers",
    "ApiName": "ManagersApi",
    "Path": "/api/esx/settings/hardware-support/managers",
    "Tags": "Managers",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateAuthorizationVtContainersMappings",
    "CommandInfo": "Invoke-CreateAuthorizationVtContainersMappings",
    "ApiName": "MappingsApi",
    "Path": "/api/vcenter/authorization/vt-containers/mappings",
    "Tags": "Mappings",
    "RelatedCommandInfos": "Initialize-AuthorizationVtContainersMappingsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteMappingVtContainers",
    "CommandInfo": "Invoke-DeleteMappingVtContainers",
    "ApiName": "MappingsApi",
    "Path": "/api/vcenter/authorization/vt-containers/mappings/{mapping}",
    "Tags": "Mappings",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetMappingVtContainers",
    "CommandInfo": "Invoke-GetMappingVtContainers",
    "ApiName": "MappingsApi",
    "Path": "/api/vcenter/authorization/vt-containers/mappings/{mapping}",
    "Tags": "Mappings",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListAuthorizationVtContainersMappings",
    "CommandInfo": "Invoke-ListAuthorizationVtContainersMappings",
    "ApiName": "MappingsApi",
    "Path": "/api/vcenter/authorization/vt-containers/mappings",
    "Tags": "Mappings",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHealthMem",
    "CommandInfo": "Invoke-GetHealthMem",
    "ApiName": "MemApi",
    "Path": "/api/appliance/health/mem",
    "Tags": "Mem",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmHardwareMemory",
    "CommandInfo": "Invoke-GetVmHardwareMemory",
    "ApiName": "MemoryApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/memory",
    "Tags": "Memory",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmHardwareMemory",
    "CommandInfo": "Invoke-UpdateVmHardwareMemory",
    "ApiName": "MemoryApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/memory",
    "Tags": "Memory",
    "RelatedCommandInfos": "Initialize-VmHardwareMemoryUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "ListStatsMetrics",
    "CommandInfo": "Invoke-ListStatsMetrics",
    "ApiName": "MetricsApi",
    "Path": "/api/stats/metrics",
    "Tags": "Metrics",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CancelDeploymentMigrate",
    "CommandInfo": "Invoke-CancelDeploymentMigrate",
    "ApiName": "MigrateApi",
    "Path": "/api/vcenter/deployment/migrate__action=cancel",
    "Tags": "Migrate",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CheckDeploymentMigrate",
    "CommandInfo": "Invoke-CheckDeploymentMigrate",
    "ApiName": "MigrateApi",
    "Path": "/api/vcenter/deployment/migrate__action=check",
    "Tags": "Migrate",
    "RelatedCommandInfos": "Initialize-DeploymentMigrateMigrateSpec",
    "Method": "POST"
  },
  {
    "Name": "GetDeploymentMigrate",
    "CommandInfo": "Invoke-GetDeploymentMigrate",
    "ApiName": "MigrateApi",
    "Path": "/api/vcenter/deployment/migrate",
    "Tags": "Migrate",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "StartDeploymentMigrate",
    "CommandInfo": "Invoke-StartDeploymentMigrate",
    "ApiName": "MigrateApi",
    "Path": "/api/vcenter/deployment/migrate__action=start",
    "Tags": "Migrate",
    "RelatedCommandInfos": "Initialize-DeploymentMigrateMigrateSpec",
    "Method": "POST"
  },
  {
    "Name": "GetVchaClusterMode",
    "CommandInfo": "Invoke-GetVchaClusterMode",
    "ApiName": "ModeApi",
    "Path": "/api/vcenter/vcha/cluster/mode",
    "Tags": "Mode",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetClusterModeAsync",
    "CommandInfo": "Invoke-SetClusterModeAsync",
    "ApiName": "ModeApi",
    "Path": "/api/vcenter/vcha/cluster/mode__vmw-task=true",
    "Tags": "Mode",
    "RelatedCommandInfos": "Initialize-VchaClusterModeSetTaskRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "ListResourceIdMetamodelModel",
    "CommandInfo": "Invoke-ListResourceIdMetamodelModel",
    "ApiName": "ModelApi",
    "Path": "/api/vapi/metadata/metamodel/resource/{resource_id}/model",
    "Tags": "Model",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetMonitoringQuery",
    "CommandInfo": "Invoke-GetMonitoringQuery",
    "ApiName": "MonitoringApi",
    "Path": "/api/appliance/monitoring/query",
    "Tags": "Monitoring",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetStatIdMonitoring",
    "CommandInfo": "Invoke-GetStatIdMonitoring",
    "ApiName": "MonitoringApi",
    "Path": "/api/appliance/monitoring/{stat_id}",
    "Tags": "Monitoring",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMonitoring",
    "CommandInfo": "Invoke-ListMonitoring",
    "ApiName": "MonitoringApi",
    "Path": "/api/appliance/monitoring",
    "Tags": "Monitoring",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetCliNamespace",
    "CommandInfo": "Invoke-GetCliNamespace",
    "ApiName": "NamespaceApi",
    "Path": "/api/vapi/metadata/cli/namespace__action=get",
    "Tags": "Namespace",
    "RelatedCommandInfos": "Initialize-MetadataCliNamespaceGetRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetCliNamespaceFingerprint",
    "CommandInfo": "Invoke-GetCliNamespaceFingerprint",
    "ApiName": "NamespaceApi",
    "Path": "/api/vapi/metadata/cli/namespace/fingerprint",
    "Tags": "Namespace",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataCliNamespace",
    "CommandInfo": "Invoke-ListMetadataCliNamespace",
    "ApiName": "NamespaceApi",
    "Path": "/api/vapi/metadata/cli/namespace",
    "Tags": "Namespace",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterNamespaceManagementWorkloadResourceOptions",
    "CommandInfo": "Invoke-GetClusterNamespaceManagementWorkloadResourceOptions",
    "ApiName": "NamespaceResourceOptionsApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/workload-resource-options",
    "Tags": "NamespaceResourceOptions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ActivateClusterNamespaceSelfService",
    "CommandInfo": "Invoke-ActivateClusterNamespaceSelfService",
    "ApiName": "NamespaceSelfServiceApi",
    "Path": "/api/vcenter/namespaces/namespace-self-service/{cluster}__action=activate",
    "Tags": "NamespaceSelfService",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ActivateWithTemplateClusterNamespaceSelfService",
    "CommandInfo": "Invoke-ActivateWithTemplateClusterNamespaceSelfService",
    "ApiName": "NamespaceSelfServiceApi",
    "Path": "/api/vcenter/namespaces/namespace-self-service/{cluster}__action=activateWithTemplate",
    "Tags": "NamespaceSelfService",
    "RelatedCommandInfos": "Initialize-NamespacesNamespaceSelfServiceActivateTemplateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeactivateClusterNamespaceSelfService",
    "CommandInfo": "Invoke-DeactivateClusterNamespaceSelfService",
    "ApiName": "NamespaceSelfServiceApi",
    "Path": "/api/vcenter/namespaces/namespace-self-service/{cluster}__action=deactivate",
    "Tags": "NamespaceSelfService",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetClusterNamespacesNamespaceSelfService",
    "CommandInfo": "Invoke-GetClusterNamespacesNamespaceSelfService",
    "ApiName": "NamespaceSelfServiceApi",
    "Path": "/api/vcenter/namespaces/namespace-self-service/{cluster}",
    "Tags": "NamespaceSelfService",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNamespacesNamespaceSelfService",
    "CommandInfo": "Invoke-ListNamespacesNamespaceSelfService",
    "ApiName": "NamespaceSelfServiceApi",
    "Path": "/api/vcenter/namespaces/namespace-self-service",
    "Tags": "NamespaceSelfService",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateClusterNamespacesNamespaceTemplates",
    "CommandInfo": "Invoke-CreateClusterNamespacesNamespaceTemplates",
    "ApiName": "NamespaceTemplatesApi",
    "Path": "/api/vcenter/namespaces/namespace-templates/clusters/{cluster}",
    "Tags": "NamespaceTemplates",
    "RelatedCommandInfos": "Initialize-NamespacesNamespaceTemplatesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateSupervisorNamespaceTemplates",
    "CommandInfo": "Invoke-CreateSupervisorNamespaceTemplates",
    "ApiName": "NamespaceTemplatesApi",
    "Path": "/api/vcenter/namespaces/namespace-templates/supervisors/{supervisor}",
    "Tags": "NamespaceTemplates",
    "RelatedCommandInfos": "Initialize-NamespacesNamespaceTemplatesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "GetClusterTemplateNamespaceTemplatesNamespaces",
    "CommandInfo": "Invoke-GetClusterTemplateNamespaceTemplatesNamespaces",
    "ApiName": "NamespaceTemplatesApi",
    "Path": "/api/vcenter/namespaces/namespace-templates/clusters/{cluster}/{template}",
    "Tags": "NamespaceTemplates",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetSupervisorNamespaceTemplates",
    "CommandInfo": "Invoke-GetSupervisorNamespaceTemplates",
    "ApiName": "NamespaceTemplatesApi",
    "Path": "/api/vcenter/namespaces/namespace-templates/supervisors/{supervisor}",
    "Tags": "NamespaceTemplates",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetSupervisorTemplateNamespaceTemplates",
    "CommandInfo": "Invoke-GetSupervisorTemplateNamespaceTemplates",
    "ApiName": "NamespaceTemplatesApi",
    "Path": "/api/vcenter/namespaces/namespace-templates/supervisors/{supervisor}/{template}",
    "Tags": "NamespaceTemplates",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterNamespacesNamespaceTemplates",
    "CommandInfo": "Invoke-ListClusterNamespacesNamespaceTemplates",
    "ApiName": "NamespaceTemplatesApi",
    "Path": "/api/vcenter/namespaces/namespace-templates/clusters/{cluster}",
    "Tags": "NamespaceTemplates",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateClusterTemplateNamespaceTemplatesNamespaces",
    "CommandInfo": "Invoke-UpdateClusterTemplateNamespaceTemplatesNamespaces",
    "ApiName": "NamespaceTemplatesApi",
    "Path": "/api/vcenter/namespaces/namespace-templates/clusters/{cluster}/{template}",
    "Tags": "NamespaceTemplates",
    "RelatedCommandInfos": "Initialize-NamespacesNamespaceTemplatesUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "UpdateSupervisorTemplateNamespaceTemplates",
    "CommandInfo": "Invoke-UpdateSupervisorTemplateNamespaceTemplates",
    "ApiName": "NamespaceTemplatesApi",
    "Path": "/api/vcenter/namespaces/namespace-templates/supervisors/{supervisor}/{template}",
    "Tags": "NamespaceTemplates",
    "RelatedCommandInfos": "Initialize-NamespacesNamespaceTemplatesUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetInventoryNetwork",
    "CommandInfo": "Invoke-GetInventoryNetwork",
    "ApiName": "NetworkApi",
    "Path": "/api/vcenter/inventory/network",
    "Tags": "Network",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNetwork",
    "CommandInfo": "Invoke-ListNetwork",
    "ApiName": "NetworkApi",
    "Path": "/api/vcenter/network",
    "Tags": "Network",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ChangeNetworkingAsync",
    "CommandInfo": "Invoke-ChangeNetworkingAsync",
    "ApiName": "NetworkingApi",
    "Path": "/api/appliance/networking__action=change&vmw-task=true",
    "Tags": "Networking",
    "RelatedCommandInfos": "Initialize-NetworkingChangeSpec",
    "Method": "POST"
  },
  {
    "Name": "GetNetworking",
    "CommandInfo": "Invoke-GetNetworking",
    "ApiName": "NetworkingApi",
    "Path": "/api/appliance/networking",
    "Tags": "Networking",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmGuestNetworking",
    "CommandInfo": "Invoke-GetVmGuestNetworking",
    "ApiName": "NetworkingApi",
    "Path": "/api/vcenter/vm/{vm}/guest/networking",
    "Tags": "Networking",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ResetNetworking",
    "CommandInfo": "Invoke-ResetNetworking",
    "ApiName": "NetworkingApi",
    "Path": "/api/appliance/networking__action=reset",
    "Tags": "Networking",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "UpdateNetworking",
    "CommandInfo": "Invoke-UpdateNetworking",
    "ApiName": "NetworkingApi",
    "Path": "/api/appliance/networking",
    "Tags": "Networking",
    "RelatedCommandInfos": "Initialize-NetworkingUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "CreateClusterNamespaceManagementNetworks",
    "CommandInfo": "Invoke-CreateClusterNamespaceManagementNetworks",
    "ApiName": "NetworksApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/networks",
    "Tags": "Networks",
    "RelatedCommandInfos": "Initialize-NamespaceManagementNetworksCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteClusterNetworkNamespaceManagement",
    "CommandInfo": "Invoke-DeleteClusterNetworkNamespaceManagement",
    "ApiName": "NetworksApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/networks/{network}",
    "Tags": "Networks",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterNetworkNamespaceManagement",
    "CommandInfo": "Invoke-GetClusterNetworkNamespaceManagement",
    "ApiName": "NetworksApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/networks/{network}",
    "Tags": "Networks",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterNamespaceManagementNetworks",
    "CommandInfo": "Invoke-ListClusterNamespaceManagementNetworks",
    "ApiName": "NetworksApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/networks",
    "Tags": "Networks",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetClusterNetworkNamespaceManagement",
    "CommandInfo": "Invoke-SetClusterNetworkNamespaceManagement",
    "ApiName": "NetworksApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/networks/{network}",
    "Tags": "Networks",
    "RelatedCommandInfos": "Initialize-NamespaceManagementNetworksSetSpec",
    "Method": "PUT"
  },
  {
    "Name": "UpdateClusterNetworkNamespaceManagement",
    "CommandInfo": "Invoke-UpdateClusterNetworkNamespaceManagement",
    "ApiName": "NetworksApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/networks/{network}",
    "Tags": "Networks",
    "RelatedCommandInfos": "Initialize-NamespaceManagementNetworksUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetNodeTopology",
    "CommandInfo": "Invoke-GetNodeTopology",
    "ApiName": "NodesApi",
    "Path": "/api/vcenter/topology/nodes/{node}",
    "Tags": "Nodes",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListTopologyNodes",
    "CommandInfo": "Invoke-ListTopologyNodes",
    "ApiName": "NodesApi",
    "Path": "/api/vcenter/topology/nodes",
    "Tags": "Nodes",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetNetworkingNoproxy",
    "CommandInfo": "Invoke-GetNetworkingNoproxy",
    "ApiName": "NoProxyApi",
    "Path": "/api/appliance/networking/noproxy",
    "Tags": "NoProxy",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetNetworkingNoproxy",
    "CommandInfo": "Invoke-SetNetworkingNoproxy",
    "ApiName": "NoProxyApi",
    "Path": "/api/appliance/networking/noproxy",
    "Tags": "NoProxy",
    "RelatedCommandInfos": "Initialize-NetworkingNoProxySetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "ListNamespaceManagementNsxTier0Gateways",
    "CommandInfo": "Invoke-ListNamespaceManagementNsxTier0Gateways",
    "ApiName": "NsxTier0GatewayApi",
    "Path": "/api/vcenter/namespace-management/nsx-tier0-gateways",
    "Tags": "NsxTier0Gateway",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetNtp",
    "CommandInfo": "Invoke-GetNtp",
    "ApiName": "NtpApi",
    "Path": "/api/appliance/ntp",
    "Tags": "Ntp",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetNtp",
    "CommandInfo": "Invoke-SetNtp",
    "ApiName": "NtpApi",
    "Path": "/api/appliance/ntp",
    "Tags": "Ntp",
    "RelatedCommandInfos": "Initialize-NtpSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "TestNtp",
    "CommandInfo": "Invoke-TestNtp",
    "ApiName": "NtpApi",
    "Path": "/api/appliance/ntp__action=test",
    "Tags": "Ntp",
    "RelatedCommandInfos": "Initialize-NtpTestRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CreateVmHardwareAdapterNvme",
    "CommandInfo": "Invoke-CreateVmHardwareAdapterNvme",
    "ApiName": "NvmeApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/nvme",
    "Tags": "Nvme",
    "RelatedCommandInfos": "Initialize-VmHardwareAdapterNvmeCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmAdapterHardwareNvme",
    "CommandInfo": "Invoke-DeleteVmAdapterHardwareNvme",
    "ApiName": "NvmeApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/nvme/{adapter}",
    "Tags": "Nvme",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetVmAdapterHardwareNvme",
    "CommandInfo": "Invoke-GetVmAdapterHardwareNvme",
    "ApiName": "NvmeApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/nvme/{adapter}",
    "Tags": "Nvme",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmHardwareAdapterNvme",
    "CommandInfo": "Invoke-ListVmHardwareAdapterNvme",
    "ApiName": "NvmeApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/nvme",
    "Tags": "Nvme",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateDepotsOfflineAsync",
    "CommandInfo": "Invoke-CreateDepotsOfflineAsync",
    "ApiName": "OfflineApi",
    "Path": "/api/esx/settings/depots/offline__vmw-task=true",
    "Tags": "Offline",
    "RelatedCommandInfos": "Initialize-SettingsDepotsOfflineCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateFromHostDepotsOfflineAsync",
    "CommandInfo": "Invoke-CreateFromHostDepotsOfflineAsync",
    "ApiName": "OfflineApi",
    "Path": "/api/esx/settings/depots/offline__action=createFromHost&vmw-task=true",
    "Tags": "Offline",
    "RelatedCommandInfos": "Initialize-SettingsDepotsOfflineConnectionSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteDepotOffline",
    "CommandInfo": "Invoke-DeleteDepotOffline",
    "ApiName": "OfflineApi",
    "Path": "/api/esx/settings/depots/offline/{depot}",
    "Tags": "Offline",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteDepotOfflineAsync",
    "CommandInfo": "Invoke-DeleteDepotOfflineAsync",
    "ApiName": "OfflineApi",
    "Path": "/api/esx/settings/depots/offline/{depot}__vmw-task=true",
    "Tags": "Offline",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetDepotOffline",
    "CommandInfo": "Invoke-GetDepotOffline",
    "ApiName": "OfflineApi",
    "Path": "/api/esx/settings/depots/offline/{depot}",
    "Tags": "Offline",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListDepotsOffline",
    "CommandInfo": "Invoke-ListDepotsOffline",
    "ApiName": "OfflineApi",
    "Path": "/api/esx/settings/depots/offline",
    "Tags": "Offline",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateDepotsOnline",
    "CommandInfo": "Invoke-CreateDepotsOnline",
    "ApiName": "OnlineApi",
    "Path": "/api/esx/settings/depots/online",
    "Tags": "Online",
    "RelatedCommandInfos": "Initialize-SettingsDepotsOnlineCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteDepotOnline",
    "CommandInfo": "Invoke-DeleteDepotOnline",
    "ApiName": "OnlineApi",
    "Path": "/api/esx/settings/depots/online/{depot}",
    "Tags": "Online",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteDepotOnlineAsync",
    "CommandInfo": "Invoke-DeleteDepotOnlineAsync",
    "ApiName": "OnlineApi",
    "Path": "/api/esx/settings/depots/online/{depot}__vmw-task=true",
    "Tags": "Online",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "FlushDepotOnlineAsync",
    "CommandInfo": "Invoke-FlushDepotOnlineAsync",
    "ApiName": "OnlineApi",
    "Path": "/api/esx/settings/depots/online/{depot}__action=flush&vmw-task=true",
    "Tags": "Online",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetDepotOnline",
    "CommandInfo": "Invoke-GetDepotOnline",
    "ApiName": "OnlineApi",
    "Path": "/api/esx/settings/depots/online/{depot}",
    "Tags": "Online",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListDepotsOnline",
    "CommandInfo": "Invoke-ListDepotsOnline",
    "ApiName": "OnlineApi",
    "Path": "/api/esx/settings/depots/online",
    "Tags": "Online",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateDepotOnline",
    "CommandInfo": "Invoke-UpdateDepotOnline",
    "ApiName": "OnlineApi",
    "Path": "/api/esx/settings/depots/online/{depot}",
    "Tags": "Online",
    "RelatedCommandInfos": "Initialize-SettingsDepotsOnlineUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetServiceIdOperationIdAuthentication",
    "CommandInfo": "Invoke-GetServiceIdOperationIdAuthentication",
    "ApiName": "OperationApi",
    "Path": "/api/vapi/metadata/authentication/service/{service_id}/operation/{operation_id}",
    "Tags": "Operation",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetServiceIdOperationIdMetamodel",
    "CommandInfo": "Invoke-GetServiceIdOperationIdMetamodel",
    "ApiName": "OperationApi",
    "Path": "/api/vapi/metadata/metamodel/service/{service_id}/operation/{operation_id}",
    "Tags": "Operation",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetServiceIdOperationIdPrivilege",
    "CommandInfo": "Invoke-GetServiceIdOperationIdPrivilege",
    "ApiName": "OperationApi",
    "Path": "/api/vapi/metadata/privilege/service/{service_id}/operation/{operation_id}",
    "Tags": "Operation",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListServiceIdAuthenticationOperation",
    "CommandInfo": "Invoke-ListServiceIdAuthenticationOperation",
    "ApiName": "OperationApi",
    "Path": "/api/vapi/metadata/authentication/service/{service_id}/operation",
    "Tags": "Operation",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListServiceIdMetamodelOperation",
    "CommandInfo": "Invoke-ListServiceIdMetamodelOperation",
    "ApiName": "OperationApi",
    "Path": "/api/vapi/metadata/metamodel/service/{service_id}/operation",
    "Tags": "Operation",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListServiceIdPrivilegeOperation",
    "CommandInfo": "Invoke-ListServiceIdPrivilegeOperation",
    "ApiName": "OperationApi",
    "Path": "/api/vapi/metadata/privilege/service/{service_id}/operation",
    "Tags": "Operation",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVchaOperations",
    "CommandInfo": "Invoke-GetVchaOperations",
    "ApiName": "OperationsApi",
    "Path": "/api/vcenter/vcha/operations",
    "Tags": "Operations",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmGuestOperations",
    "CommandInfo": "Invoke-GetVmGuestOperations",
    "ApiName": "OperationsApi",
    "Path": "/api/vcenter/vm/{vm}/guest/operations",
    "Tags": "Operations",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetBrokerTenantsOperatorClient",
    "CommandInfo": "Invoke-GetBrokerTenantsOperatorClient",
    "ApiName": "OperatorClientApi",
    "Path": "/api/vcenter/identity/broker/tenants/operator-client",
    "Tags": "OperatorClient",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetPackageIdAuthentication",
    "CommandInfo": "Invoke-GetPackageIdAuthentication",
    "ApiName": "PackageApi",
    "Path": "/api/vapi/metadata/authentication/package/{package_id}",
    "Tags": "Package",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetPackageIdMetamodel",
    "CommandInfo": "Invoke-GetPackageIdMetamodel",
    "ApiName": "PackageApi",
    "Path": "/api/vapi/metadata/metamodel/package/{package_id}",
    "Tags": "Package",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetPackageIdPrivilege",
    "CommandInfo": "Invoke-GetPackageIdPrivilege",
    "ApiName": "PackageApi",
    "Path": "/api/vapi/metadata/privilege/package/{package_id}",
    "Tags": "Package",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataAuthenticationPackage",
    "CommandInfo": "Invoke-ListMetadataAuthenticationPackage",
    "ApiName": "PackageApi",
    "Path": "/api/vapi/metadata/authentication/package",
    "Tags": "Package",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataMetamodelPackage",
    "CommandInfo": "Invoke-ListMetadataMetamodelPackage",
    "ApiName": "PackageApi",
    "Path": "/api/vapi/metadata/metamodel/package",
    "Tags": "Package",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataPrivilegePackage",
    "CommandInfo": "Invoke-ListMetadataPrivilegePackage",
    "ApiName": "PackageApi",
    "Path": "/api/vapi/metadata/privilege/package",
    "Tags": "Package",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListManagerHardwareSupportPackages",
    "CommandInfo": "Invoke-ListManagerHardwareSupportPackages",
    "ApiName": "PackagesApi",
    "Path": "/api/esx/settings/hardware-support/managers/{manager}/packages",
    "Tags": "Packages",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ConnectVmPortParallel",
    "CommandInfo": "Invoke-ConnectVmPortParallel",
    "ApiName": "ParallelApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/parallel/{port}__action=connect",
    "Tags": "Parallel",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateVmHardwareParallel",
    "CommandInfo": "Invoke-CreateVmHardwareParallel",
    "ApiName": "ParallelApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/parallel",
    "Tags": "Parallel",
    "RelatedCommandInfos": "Initialize-VmHardwareParallelCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmPortHardwareParallel",
    "CommandInfo": "Invoke-DeleteVmPortHardwareParallel",
    "ApiName": "ParallelApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/parallel/{port}",
    "Tags": "Parallel",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DisconnectVmPortParallel",
    "CommandInfo": "Invoke-DisconnectVmPortParallel",
    "ApiName": "ParallelApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/parallel/{port}__action=disconnect",
    "Tags": "Parallel",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetVmPortHardwareParallel",
    "CommandInfo": "Invoke-GetVmPortHardwareParallel",
    "ApiName": "ParallelApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/parallel/{port}",
    "Tags": "Parallel",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmHardwareParallel",
    "CommandInfo": "Invoke-ListVmHardwareParallel",
    "ApiName": "ParallelApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/parallel",
    "Tags": "Parallel",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmPortHardwareParallel",
    "CommandInfo": "Invoke-UpdateVmPortHardwareParallel",
    "ApiName": "ParallelApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/parallel/{port}",
    "Tags": "Parallel",
    "RelatedCommandInfos": "Initialize-VmHardwareParallelUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetIdBackupParts",
    "CommandInfo": "Invoke-GetIdBackupParts",
    "ApiName": "PartsApi",
    "Path": "/api/appliance/recovery/backup/parts/{id}",
    "Tags": "Parts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListRecoveryBackupParts",
    "CommandInfo": "Invoke-ListRecoveryBackupParts",
    "ApiName": "PartsApi",
    "Path": "/api/appliance/recovery/backup/parts",
    "Tags": "Parts",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CheckClusterPassive",
    "CommandInfo": "Invoke-CheckClusterPassive",
    "ApiName": "PassiveApi",
    "Path": "/api/vcenter/vcha/cluster/passive__action=check",
    "Tags": "Passive",
    "RelatedCommandInfos": "Initialize-VchaClusterPassiveCheckSpec",
    "Method": "POST"
  },
  {
    "Name": "RedeployClusterPassiveAsync",
    "CommandInfo": "Invoke-RedeployClusterPassiveAsync",
    "ApiName": "PassiveApi",
    "Path": "/api/vcenter/vcha/cluster/passive__action=redeploy&vmw-task=true",
    "Tags": "Passive",
    "RelatedCommandInfos": "Initialize-VchaClusterPassiveRedeploySpec",
    "Method": "POST"
  },
  {
    "Name": "GetVersionPendingComponents",
    "CommandInfo": "Invoke-GetVersionPendingComponents",
    "ApiName": "PendingApi",
    "Path": "/api/appliance/update/pending/{version}/components",
    "Tags": "Pending",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVersionUpdatePending",
    "CommandInfo": "Invoke-GetVersionUpdatePending",
    "ApiName": "PendingApi",
    "Path": "/api/appliance/update/pending/{version}",
    "Tags": "Pending",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVersionUpdatePending_0",
    "CommandInfo": "Invoke-GetVersionUpdatePending_0",
    "ApiName": "PendingApi",
    "Path": "/api/vcenter/lcm/update/pending/{version}",
    "Tags": "Pending",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "InstallVersionPending",
    "CommandInfo": "Invoke-InstallVersionPending",
    "ApiName": "PendingApi",
    "Path": "/api/appliance/update/pending/{version}__action=install",
    "Tags": "Pending",
    "RelatedCommandInfos": "Initialize-UpdatePendingInstallRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListLcmUpdatePending",
    "CommandInfo": "Invoke-ListLcmUpdatePending",
    "ApiName": "PendingApi",
    "Path": "/api/vcenter/lcm/update/pending",
    "Tags": "Pending",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListUpdatePending",
    "CommandInfo": "Invoke-ListUpdatePending",
    "ApiName": "PendingApi",
    "Path": "/api/appliance/update/pending",
    "Tags": "Pending",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "PrecheckVersionPending",
    "CommandInfo": "Invoke-PrecheckVersionPending",
    "ApiName": "PendingApi",
    "Path": "/api/appliance/update/pending/{version}__action=precheck",
    "Tags": "Pending",
    "RelatedCommandInfos": "Initialize-UpdatePendingPrecheckRequestBody",
    "Method": "POST"
  },
  {
    "Name": "RollbackUpdatePending",
    "CommandInfo": "Invoke-RollbackUpdatePending",
    "ApiName": "PendingApi",
    "Path": "/api/appliance/update/pending__action=rollback",
    "Tags": "Pending",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "StageAndInstallVersionPending",
    "CommandInfo": "Invoke-StageAndInstallVersionPending",
    "ApiName": "PendingApi",
    "Path": "/api/appliance/update/pending/{version}__action=stage-and-install",
    "Tags": "Pending",
    "RelatedCommandInfos": "Initialize-UpdatePendingStageAndInstallRequestBody",
    "Method": "POST"
  },
  {
    "Name": "StageVersionPending",
    "CommandInfo": "Invoke-StageVersionPending",
    "ApiName": "PendingApi",
    "Path": "/api/appliance/update/pending/{version}__action=stage",
    "Tags": "Pending",
    "RelatedCommandInfos": "Initialize-UpdatePendingStageRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ValidateVersionPending",
    "CommandInfo": "Invoke-ValidateVersionPending",
    "ApiName": "PendingApi",
    "Path": "/api/appliance/update/pending/{version}__action=validate",
    "Tags": "Pending",
    "RelatedCommandInfos": "Initialize-UpdatePendingValidateRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CheckCompatibilityPolicyPolicies",
    "CommandInfo": "Invoke-CheckCompatibilityPolicyPolicies",
    "ApiName": "PoliciesApi",
    "Path": "/api/vcenter/storage/policies/{policy}__action=check-compatibility",
    "Tags": "Policies",
    "RelatedCommandInfos": "Initialize-StoragePoliciesCheckCompatibilityRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetVmPolicyComputePolicies",
    "CommandInfo": "Invoke-GetVmPolicyComputePolicies",
    "ApiName": "PoliciesApi",
    "Path": "/api/vcenter/vm/{vm}/compute/policies/{policy}",
    "Tags": "Policies",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListStoragePolicies",
    "CommandInfo": "Invoke-ListStoragePolicies",
    "ApiName": "PoliciesApi",
    "Path": "/api/vcenter/storage/policies",
    "Tags": "Policies",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetLocalAccountsGlobalPolicy",
    "CommandInfo": "Invoke-GetLocalAccountsGlobalPolicy",
    "ApiName": "PolicyApi",
    "Path": "/api/appliance/local-accounts/global-policy",
    "Tags": "Policy",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetUpdatePolicy",
    "CommandInfo": "Invoke-GetUpdatePolicy",
    "ApiName": "PolicyApi",
    "Path": "/api/appliance/update/policy",
    "Tags": "Policy",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmStoragePolicy",
    "CommandInfo": "Invoke-GetVmStoragePolicy",
    "ApiName": "PolicyApi",
    "Path": "/api/vcenter/vm/{vm}/storage/policy",
    "Tags": "Policy",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetLocalAccountsGlobalPolicy",
    "CommandInfo": "Invoke-SetLocalAccountsGlobalPolicy",
    "ApiName": "PolicyApi",
    "Path": "/api/appliance/local-accounts/global-policy",
    "Tags": "Policy",
    "RelatedCommandInfos": "Initialize-LocalAccountsPolicyInfo",
    "Method": "PUT"
  },
  {
    "Name": "SetUpdatePolicy",
    "CommandInfo": "Invoke-SetUpdatePolicy",
    "ApiName": "PolicyApi",
    "Path": "/api/appliance/update/policy",
    "Tags": "Policy",
    "RelatedCommandInfos": "Initialize-UpdatePolicyConfig",
    "Method": "PUT"
  },
  {
    "Name": "UpdateVmStoragePolicy",
    "CommandInfo": "Invoke-UpdateVmStoragePolicy",
    "ApiName": "PolicyApi",
    "Path": "/api/vcenter/vm/{vm}/storage/policy",
    "Tags": "Policy",
    "RelatedCommandInfos": "Initialize-VmStoragePolicyUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetVmGuestPower",
    "CommandInfo": "Invoke-GetVmGuestPower",
    "ApiName": "PowerApi",
    "Path": "/api/vcenter/vm/{vm}/guest/power",
    "Tags": "Power",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVmPower",
    "CommandInfo": "Invoke-GetVmPower",
    "ApiName": "PowerApi",
    "Path": "/api/vcenter/vm/{vm}/power",
    "Tags": "Power",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RebootVmGuestPower",
    "CommandInfo": "Invoke-RebootVmGuestPower",
    "ApiName": "PowerApi",
    "Path": "/api/vcenter/vm/{vm}/guest/power__action=reboot",
    "Tags": "Power",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ResetVmPower",
    "CommandInfo": "Invoke-ResetVmPower",
    "ApiName": "PowerApi",
    "Path": "/api/vcenter/vm/{vm}/power__action=reset",
    "Tags": "Power",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ShutdownVmGuestPower",
    "CommandInfo": "Invoke-ShutdownVmGuestPower",
    "ApiName": "PowerApi",
    "Path": "/api/vcenter/vm/{vm}/guest/power__action=shutdown",
    "Tags": "Power",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "StandbyVmGuestPower",
    "CommandInfo": "Invoke-StandbyVmGuestPower",
    "ApiName": "PowerApi",
    "Path": "/api/vcenter/vm/{vm}/guest/power__action=standby",
    "Tags": "Power",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "StartVmPower",
    "CommandInfo": "Invoke-StartVmPower",
    "ApiName": "PowerApi",
    "Path": "/api/vcenter/vm/{vm}/power__action=start",
    "Tags": "Power",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "StopVmPower",
    "CommandInfo": "Invoke-StopVmPower",
    "ApiName": "PowerApi",
    "Path": "/api/vcenter/vm/{vm}/power__action=stop",
    "Tags": "Power",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "SuspendVmPower",
    "CommandInfo": "Invoke-SuspendVmPower",
    "ApiName": "PowerApi",
    "Path": "/api/vcenter/vm/{vm}/power__action=suspend",
    "Tags": "Power",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateVersionPrecheckReportAsync",
    "CommandInfo": "Invoke-CreateVersionPrecheckReportAsync",
    "ApiName": "PrecheckReportApi",
    "Path": "/api/vcenter/lcm/update/pending/{version}/precheck-report__vmw-task=true",
    "Tags": "PrecheckReport",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetSupervisorSoftwarePrechecks",
    "CommandInfo": "Invoke-GetSupervisorSoftwarePrechecks",
    "ApiName": "PrechecksApi",
    "Path": "/api/vcenter/namespace-management/software/supervisors/{supervisor}/prechecks",
    "Tags": "Prechecks",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RunSupervisorPrechecks",
    "CommandInfo": "Invoke-RunSupervisorPrechecks",
    "ApiName": "PrechecksApi",
    "Path": "/api/vcenter/namespace-management/software/supervisors/{supervisor}/prechecks__action=run",
    "Tags": "Prechecks",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSoftwareSupervisorsPrechecksPrecheckSpec",
    "Method": "POST"
  },
  {
    "Name": "GetTrustedInfrastructurePrincipal",
    "CommandInfo": "Invoke-GetTrustedInfrastructurePrincipal",
    "ApiName": "PrincipalApi",
    "Path": "/api/vcenter/trusted-infrastructure/principal",
    "Tags": "Principal",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListAuthorizationPrivilegeChecks",
    "CommandInfo": "Invoke-ListAuthorizationPrivilegeChecks",
    "ApiName": "PrivilegeChecksApi",
    "Path": "/api/vcenter/authorization/privilege-checks__action=list",
    "Tags": "PrivilegeChecks",
    "RelatedCommandInfos": "Initialize-AuthorizationPrivilegeChecksListRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CreateVmGuestProcesses",
    "CommandInfo": "Invoke-CreateVmGuestProcesses",
    "ApiName": "ProcessesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/processes__action=create",
    "Tags": "Processes",
    "RelatedCommandInfos": "Initialize-VmGuestProcessesCreateRequestBody",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmPidProcesses",
    "CommandInfo": "Invoke-DeleteVmPidProcesses",
    "ApiName": "ProcessesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/processes/{pid}__action=delete",
    "Tags": "Processes",
    "RelatedCommandInfos": "Initialize-VmGuestProcessesDeleteRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetVmPidProcesses",
    "CommandInfo": "Invoke-GetVmPidProcesses",
    "ApiName": "ProcessesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/processes/{pid}__action=get",
    "Tags": "Processes",
    "RelatedCommandInfos": "Initialize-VmGuestProcessesGetRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListVmGuestProcesses",
    "CommandInfo": "Invoke-ListVmGuestProcesses",
    "ApiName": "ProcessesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/processes__action=list",
    "Tags": "Processes",
    "RelatedCommandInfos": "Initialize-VmGuestProcessesListRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListLcmDiscoveryProductCatalog",
    "CommandInfo": "Invoke-ListLcmDiscoveryProductCatalog",
    "ApiName": "ProductCatalogApi",
    "Path": "/api/vcenter/lcm/discovery/product-catalog",
    "Tags": "ProductCatalog",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CheckCompatibilityStorageProfiles",
    "CommandInfo": "Invoke-CheckCompatibilityStorageProfiles",
    "ApiName": "ProfilesApi",
    "Path": "/api/vcenter/namespace-management/storage/profiles__action=check_compatibility",
    "Tags": "Profiles",
    "RelatedCommandInfos": "Initialize-NamespaceManagementStorageProfilesFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "GetProfileTls",
    "CommandInfo": "Invoke-GetProfileTls",
    "ApiName": "ProfilesApi",
    "Path": "/api/appliance/tls/profiles/{profile}",
    "Tags": "Profiles",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListTlsProfiles",
    "CommandInfo": "Invoke-ListApplianceTlsProfiles",
    "ApiName": "ProfilesApi",
    "Path": "/api/appliance/tls/profiles",
    "Tags": "Profiles",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateRegistryHarborProjects",
    "CommandInfo": "Invoke-CreateRegistryHarborProjects",
    "ApiName": "ProjectsApi",
    "Path": "/api/vcenter/content/registries/harbor/{registry}/projects",
    "Tags": "Projects",
    "RelatedCommandInfos": "Initialize-ContentRegistriesHarborProjectsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteRegistryProjectHarbor",
    "CommandInfo": "Invoke-DeleteRegistryProjectHarbor",
    "ApiName": "ProjectsApi",
    "Path": "/api/vcenter/content/registries/harbor/{registry}/projects/{project}",
    "Tags": "Projects",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetRegistryProjectHarbor",
    "CommandInfo": "Invoke-GetRegistryProjectHarbor",
    "ApiName": "ProjectsApi",
    "Path": "/api/vcenter/content/registries/harbor/{registry}/projects/{project}",
    "Tags": "Projects",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListRegistryHarborProjects",
    "CommandInfo": "Invoke-ListRegistryHarborProjects",
    "ApiName": "ProjectsApi",
    "Path": "/api/vcenter/content/registries/harbor/{registry}/projects",
    "Tags": "Projects",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "PurgeRegistryProject",
    "CommandInfo": "Invoke-PurgeRegistryProject",
    "ApiName": "ProjectsApi",
    "Path": "/api/vcenter/content/registries/harbor/{registry}/projects/{project}__action=purge",
    "Tags": "Projects",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateClusterKmsProvidersAsync",
    "CommandInfo": "Invoke-CreateClusterKmsProvidersAsync",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers__vmw-task=true",
    "Tags": "Providers",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityClustersKmsProvidersCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateIdentityProviders",
    "CommandInfo": "Invoke-CreateIdentityProviders",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/identity/providers",
    "Tags": "Providers",
    "RelatedCommandInfos": "Initialize-IdentityProvidersCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateSupervisorNamespaceManagementIdentityProviders",
    "CommandInfo": "Invoke-CreateSupervisorNamespaceManagementIdentityProviders",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/identity/providers",
    "Tags": "Providers",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorsIdentityProvidersCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteClusterProviderAsync",
    "CommandInfo": "Invoke-DeleteClusterProviderAsync",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}__vmw-task=true",
    "Tags": "Providers",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteProviderIdentity",
    "CommandInfo": "Invoke-DeleteProviderIdentity",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/identity/providers/{provider}",
    "Tags": "Providers",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteSupervisorProviderIdentity",
    "CommandInfo": "Invoke-DeleteSupervisorProviderIdentity",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/identity/providers/{provider}",
    "Tags": "Providers",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterKmsProvidersAsync",
    "CommandInfo": "Invoke-GetClusterKmsProvidersAsync",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers__vmw-task=true",
    "Tags": "Providers",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterProviderAsync",
    "CommandInfo": "Invoke-GetClusterProviderAsync",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}__vmw-task=true",
    "Tags": "Providers",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetProviderIdentity",
    "CommandInfo": "Invoke-GetProviderIdentity",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/identity/providers/{provider}",
    "Tags": "Providers",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetSupervisorProviderIdentity",
    "CommandInfo": "Invoke-GetSupervisorProviderIdentity",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/identity/providers/{provider}",
    "Tags": "Providers",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListIdentityProviders",
    "CommandInfo": "Invoke-ListIdentityProviders",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/identity/providers",
    "Tags": "Providers",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListStatsProviders",
    "CommandInfo": "Invoke-ListStatsProviders",
    "ApiName": "ProvidersApi",
    "Path": "/api/stats/providers",
    "Tags": "Providers",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListSupervisorNamespaceManagementIdentityProviders",
    "CommandInfo": "Invoke-ListSupervisorNamespaceManagementIdentityProviders",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/identity/providers",
    "Tags": "Providers",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetSupervisorProviderIdentity",
    "CommandInfo": "Invoke-SetSupervisorProviderIdentity",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/identity/providers/{provider}",
    "Tags": "Providers",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorsIdentityProvidersSetSpec",
    "Method": "PUT"
  },
  {
    "Name": "UpdateClusterProviderAsync",
    "CommandInfo": "Invoke-UpdateClusterProviderAsync",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}__vmw-task=true",
    "Tags": "Providers",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityClustersKmsProvidersUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "UpdateProviderIdentity",
    "CommandInfo": "Invoke-UpdateProviderIdentity",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/identity/providers/{provider}",
    "Tags": "Providers",
    "RelatedCommandInfos": "Initialize-IdentityProvidersUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "UpdateSupervisorProviderIdentity",
    "CommandInfo": "Invoke-UpdateSupervisorProviderIdentity",
    "ApiName": "ProvidersApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/identity/providers/{provider}",
    "Tags": "Providers",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorsIdentityProvidersUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "DeleteProtocolNetworkingProxy",
    "CommandInfo": "Invoke-DeleteProtocolNetworkingProxy",
    "ApiName": "ProxyApi",
    "Path": "/api/appliance/networking/proxy/{protocol}",
    "Tags": "Proxy",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetProtocolNetworkingProxy",
    "CommandInfo": "Invoke-GetProtocolNetworkingProxy",
    "ApiName": "ProxyApi",
    "Path": "/api/appliance/networking/proxy/{protocol}",
    "Tags": "Proxy",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNetworkingProxy",
    "CommandInfo": "Invoke-ListNetworkingProxy",
    "ApiName": "ProxyApi",
    "Path": "/api/appliance/networking/proxy",
    "Tags": "Proxy",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetProtocolNetworkingProxy",
    "CommandInfo": "Invoke-SetProtocolNetworkingProxy",
    "ApiName": "ProxyApi",
    "Path": "/api/appliance/networking/proxy/{protocol}",
    "Tags": "Proxy",
    "RelatedCommandInfos": "Initialize-NetworkingProxyConfig",
    "Method": "PUT"
  },
  {
    "Name": "TestProtocolProxy",
    "CommandInfo": "Invoke-TestProtocolProxy",
    "ApiName": "ProxyApi",
    "Path": "/api/appliance/networking/proxy/{protocol}__action=test",
    "Tags": "Proxy",
    "RelatedCommandInfos": "Initialize-NetworkingProxyTestRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetSystemConfigPscRegistration",
    "CommandInfo": "Invoke-GetSystemConfigPscRegistration",
    "ApiName": "PscRegistrationApi",
    "Path": "/api/vcenter/system-config/psc-registration",
    "Tags": "PscRegistration",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RepointSystemConfigPscRegistration",
    "CommandInfo": "Invoke-RepointSystemConfigPscRegistration",
    "ApiName": "PscRegistrationApi",
    "Path": "/api/vcenter/system-config/psc-registration__action=repoint",
    "Tags": "PscRegistration",
    "RelatedCommandInfos": "Initialize-DeploymentRemotePscSpec",
    "Method": "POST"
  },
  {
    "Name": "AnswerDeploymentQuestion",
    "CommandInfo": "Invoke-AnswerDeploymentQuestion",
    "ApiName": "QuestionApi",
    "Path": "/api/vcenter/deployment/question__action=answer",
    "Tags": "Question",
    "RelatedCommandInfos": "Initialize-DeploymentQuestionAnswerSpec",
    "Method": "POST"
  },
  {
    "Name": "GetDeploymentQuestion",
    "CommandInfo": "Invoke-GetDeploymentQuestion",
    "ApiName": "QuestionApi",
    "Path": "/api/vcenter/deployment/question",
    "Tags": "Question",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterConfigurationReportsRecentTasks",
    "CommandInfo": "Invoke-GetClusterConfigurationReportsRecentTasks",
    "ApiName": "RecentTasksApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/reports/recent-tasks",
    "Tags": "RecentTasks",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GenerateClusterSoftwareRecommendationsAsync",
    "CommandInfo": "Invoke-GenerateClusterSoftwareRecommendationsAsync",
    "ApiName": "RecommendationsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/recommendations__action=generate&vmw-task=true",
    "Tags": "Recommendations",
    "RelatedCommandInfos": "Initialize-SettingsClustersSoftwareRecommendationsFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "GenerateHostSoftwareRecommendationsAsync",
    "CommandInfo": "Invoke-GenerateHostSoftwareRecommendationsAsync",
    "ApiName": "RecommendationsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/recommendations__action=generate&vmw-task=true",
    "Tags": "Recommendations",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetClusterSoftwareRecommendations",
    "CommandInfo": "Invoke-GetClusterSoftwareRecommendations",
    "ApiName": "RecommendationsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/recommendations",
    "Tags": "Recommendations",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostSoftwareRecommendations",
    "CommandInfo": "Invoke-GetHostSoftwareRecommendations",
    "ApiName": "RecommendationsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/recommendations",
    "Tags": "Recommendations",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetRecovery",
    "CommandInfo": "Invoke-GetRecovery",
    "ApiName": "RecoveryApi",
    "Path": "/api/appliance/recovery",
    "Tags": "Recovery",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CheckInstallRemotePsc",
    "CommandInfo": "Invoke-CheckInstallRemotePsc",
    "ApiName": "RemotePscApi",
    "Path": "/api/vcenter/deployment/install/remote-psc__action=check",
    "Tags": "RemotePsc",
    "RelatedCommandInfos": "Initialize-DeploymentRemotePscSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteClusterDraftComponentSoftwareRemovedComponents",
    "CommandInfo": "Invoke-DeleteClusterDraftComponentSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/removed-components/{component}",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteHostDraftComponentSoftwareRemovedComponents",
    "CommandInfo": "Invoke-DeleteHostDraftComponentSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/removed-components/{component}",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterComponentSoftwareRemovedComponents",
    "CommandInfo": "Invoke-GetClusterComponentSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/removed-components/{component}",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterDraftComponentSoftwareRemovedComponents",
    "CommandInfo": "Invoke-GetClusterDraftComponentSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/removed-components/{component}",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostComponentSoftwareRemovedComponents",
    "CommandInfo": "Invoke-GetHostComponentSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/removed-components/{component}",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostDraftComponentSoftwareRemovedComponents",
    "CommandInfo": "Invoke-GetHostDraftComponentSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/removed-components/{component}",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterDraftSoftwareRemovedComponents",
    "CommandInfo": "Invoke-ListClusterDraftSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/removed-components",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterSoftwareRemovedComponents",
    "CommandInfo": "Invoke-ListClusterSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/removed-components",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHostDraftSoftwareRemovedComponents",
    "CommandInfo": "Invoke-ListHostDraftSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/removed-components",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHostSoftwareRemovedComponents",
    "CommandInfo": "Invoke-ListHostSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/removed-components",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetClusterDraftComponentSoftwareRemovedComponents",
    "CommandInfo": "Invoke-SetClusterDraftComponentSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/drafts/{draft}/software/removed-components/{component}",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "PUT"
  },
  {
    "Name": "SetHostDraftComponentSoftwareRemovedComponents",
    "CommandInfo": "Invoke-SetHostDraftComponentSoftwareRemovedComponents",
    "ApiName": "RemovedComponentsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/drafts/{draft}/software/removed-components/{component}",
    "Tags": "RemovedComponents",
    "RelatedCommandInfos": "",
    "Method": "PUT"
  },
  {
    "Name": "CheckPscReplicated",
    "CommandInfo": "Invoke-CheckPscReplicated",
    "ApiName": "ReplicatedApi",
    "Path": "/api/vcenter/deployment/install/psc/replicated__action=check",
    "Tags": "Replicated",
    "RelatedCommandInfos": "Initialize-DeploymentReplicatedPscSpec",
    "Method": "POST"
  },
  {
    "Name": "ListTopologyReplicationStatus",
    "CommandInfo": "Invoke-ListTopologyReplicationStatus",
    "ApiName": "ReplicationStatusApi",
    "Path": "/api/vcenter/topology/replication-status",
    "Tags": "ReplicationStatus",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetReportHcl",
    "CommandInfo": "Invoke-GetReportHcl",
    "ApiName": "ReportsApi",
    "Path": "/api/esx/hcl/reports/{report}",
    "Tags": "Reports",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetReportLcm",
    "CommandInfo": "Invoke-GetReportLcm",
    "ApiName": "ReportsApi",
    "Path": "/api/vcenter/lcm/reports/{report}",
    "Tags": "Reports",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetIdStatsRsrcAddrs",
    "CommandInfo": "Invoke-GetIdStatsRsrcAddrs",
    "ApiName": "ResourceAddressesApi",
    "Path": "/api/stats/rsrc-addrs/{id}",
    "Tags": "ResourceAddresses",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListStatsRsrcAddrs",
    "CommandInfo": "Invoke-ListStatsRsrcAddrs",
    "ApiName": "ResourceAddressesApi",
    "Path": "/api/stats/rsrc-addrs",
    "Tags": "ResourceAddresses",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetIdStatsRsrcAddrSchemas",
    "CommandInfo": "Invoke-GetIdStatsRsrcAddrSchemas",
    "ApiName": "ResourceAddressSchemasApi",
    "Path": "/api/stats/rsrc-addr-schemas/{id}",
    "Tags": "ResourceAddressSchemas",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataMetamodelResource",
    "CommandInfo": "Invoke-ListMetadataMetamodelResource",
    "ApiName": "ResourceApi",
    "Path": "/api/vapi/metadata/metamodel/resource",
    "Tags": "Resource",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateResourcePool",
    "CommandInfo": "Invoke-CreateResourcePool",
    "ApiName": "ResourcePoolApi",
    "Path": "/api/vcenter/resource-pool",
    "Tags": "ResourcePool",
    "RelatedCommandInfos": "Initialize-ResourcePoolCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteResourcePool",
    "CommandInfo": "Invoke-DeleteResourcePool",
    "ApiName": "ResourcePoolApi",
    "Path": "/api/vcenter/resource-pool/{resource_pool}",
    "Tags": "ResourcePool",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetResourcePool",
    "CommandInfo": "Invoke-GetResourcePool",
    "ApiName": "ResourcePoolApi",
    "Path": "/api/vcenter/resource-pool/{resource_pool}",
    "Tags": "ResourcePool",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListResourcePool",
    "CommandInfo": "Invoke-ListResourcePool",
    "ApiName": "ResourcePoolApi",
    "Path": "/api/vcenter/resource-pool",
    "Tags": "ResourcePool",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateResourcePool",
    "CommandInfo": "Invoke-UpdateResourcePool",
    "ApiName": "ResourcePoolApi",
    "Path": "/api/vcenter/resource-pool/{resource_pool}",
    "Tags": "ResourcePool",
    "RelatedCommandInfos": "Initialize-ResourcePoolUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "ListStatsRsrcTypes",
    "CommandInfo": "Invoke-ListStatsRsrcTypes",
    "ApiName": "ResourceTypesApi",
    "Path": "/api/stats/rsrc-types",
    "Tags": "ResourceTypes",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ValidateRecoveryRestore",
    "CommandInfo": "Invoke-ValidateRecoveryRestore",
    "ApiName": "RestoreApi",
    "Path": "/api/appliance/recovery/restore__action=validate",
    "Tags": "Restore",
    "RelatedCommandInfos": "Initialize-RecoveryRestoreRestoreRequest",
    "Method": "POST"
  },
  {
    "Name": "ListVmGuestNetworkingRoutes",
    "CommandInfo": "Invoke-ListVmGuestNetworkingRoutes",
    "ApiName": "RoutesApi",
    "Path": "/api/vcenter/vm/{vm}/guest/networking/routes",
    "Tags": "Routes",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateVmHardwareAdapterSata",
    "CommandInfo": "Invoke-CreateVmHardwareAdapterSata",
    "ApiName": "SataApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/sata",
    "Tags": "Sata",
    "RelatedCommandInfos": "Initialize-VmHardwareAdapterSataCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmAdapterHardwareSata",
    "CommandInfo": "Invoke-DeleteVmAdapterHardwareSata",
    "ApiName": "SataApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/sata/{adapter}",
    "Tags": "Sata",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetVmAdapterHardwareSata",
    "CommandInfo": "Invoke-GetVmAdapterHardwareSata",
    "ApiName": "SataApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/sata/{adapter}",
    "Tags": "Sata",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmHardwareAdapterSata",
    "CommandInfo": "Invoke-ListVmHardwareAdapterSata",
    "ApiName": "SataApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/sata",
    "Tags": "Sata",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateRecoveryBackupSchedules",
    "CommandInfo": "Invoke-CreateRecoveryBackupSchedules",
    "ApiName": "SchedulesApi",
    "Path": "/api/appliance/recovery/backup/schedules",
    "Tags": "Schedules",
    "RelatedCommandInfos": "Initialize-RecoveryBackupSchedulesCreateRequestBody",
    "Method": "POST"
  },
  {
    "Name": "DeleteScheduleBackup",
    "CommandInfo": "Invoke-DeleteScheduleBackup",
    "ApiName": "SchedulesApi",
    "Path": "/api/appliance/recovery/backup/schedules/{schedule}",
    "Tags": "Schedules",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetScheduleBackup",
    "CommandInfo": "Invoke-GetScheduleBackup",
    "ApiName": "SchedulesApi",
    "Path": "/api/appliance/recovery/backup/schedules/{schedule}",
    "Tags": "Schedules",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListRecoveryBackupSchedules",
    "CommandInfo": "Invoke-ListRecoveryBackupSchedules",
    "ApiName": "SchedulesApi",
    "Path": "/api/appliance/recovery/backup/schedules",
    "Tags": "Schedules",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RunSchedule",
    "CommandInfo": "Invoke-RunSchedule",
    "ApiName": "SchedulesApi",
    "Path": "/api/appliance/recovery/backup/schedules/{schedule}__action=run",
    "Tags": "Schedules",
    "RelatedCommandInfos": "Initialize-RecoveryBackupSchedulesRunRequestBody",
    "Method": "POST"
  },
  {
    "Name": "UpdateScheduleBackup",
    "CommandInfo": "Invoke-UpdateScheduleBackup",
    "ApiName": "SchedulesApi",
    "Path": "/api/appliance/recovery/backup/schedules/{schedule}",
    "Tags": "Schedules",
    "RelatedCommandInfos": "Initialize-RecoveryBackupSchedulesUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetClusterConfigurationSchema",
    "CommandInfo": "Invoke-GetClusterConfigurationSchema",
    "ApiName": "SchemaApi",
    "Path": "/api/esx/settings/clusters/{cluster}/configuration/schema",
    "Tags": "Schema",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateVmHardwareAdapterScsi",
    "CommandInfo": "Invoke-CreateVmHardwareAdapterScsi",
    "ApiName": "ScsiApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/scsi",
    "Tags": "Scsi",
    "RelatedCommandInfos": "Initialize-VmHardwareAdapterScsiCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmAdapterHardwareScsi",
    "CommandInfo": "Invoke-DeleteVmAdapterHardwareScsi",
    "ApiName": "ScsiApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/scsi/{adapter}",
    "Tags": "Scsi",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetVmAdapterHardwareScsi",
    "CommandInfo": "Invoke-GetVmAdapterHardwareScsi",
    "ApiName": "ScsiApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/scsi/{adapter}",
    "Tags": "Scsi",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmHardwareAdapterScsi",
    "CommandInfo": "Invoke-ListVmHardwareAdapterScsi",
    "ApiName": "ScsiApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/scsi",
    "Tags": "Scsi",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmAdapterHardwareScsi",
    "CommandInfo": "Invoke-UpdateVmAdapterHardwareScsi",
    "ApiName": "ScsiApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/adapter/scsi/{adapter}",
    "Tags": "Scsi",
    "RelatedCommandInfos": "Initialize-VmHardwareAdapterScsiUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "ListContentSecurityPolicies",
    "CommandInfo": "Invoke-ListContentSecurityPolicies",
    "ApiName": "SecurityPoliciesApi",
    "Path": "/api/content/security-policies",
    "Tags": "SecurityPolicies",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ConnectVmPortSerial",
    "CommandInfo": "Invoke-ConnectVmPortSerial",
    "ApiName": "SerialApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/serial/{port}__action=connect",
    "Tags": "Serial",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateVmHardwareSerial",
    "CommandInfo": "Invoke-CreateVmHardwareSerial",
    "ApiName": "SerialApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/serial",
    "Tags": "Serial",
    "RelatedCommandInfos": "Initialize-VmHardwareSerialCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmPortHardwareSerial",
    "CommandInfo": "Invoke-DeleteVmPortHardwareSerial",
    "ApiName": "SerialApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/serial/{port}",
    "Tags": "Serial",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DisconnectVmPortSerial",
    "CommandInfo": "Invoke-DisconnectVmPortSerial",
    "ApiName": "SerialApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/serial/{port}__action=disconnect",
    "Tags": "Serial",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetVmPortHardwareSerial",
    "CommandInfo": "Invoke-GetVmPortHardwareSerial",
    "ApiName": "SerialApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/serial/{port}",
    "Tags": "Serial",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVmHardwareSerial",
    "CommandInfo": "Invoke-ListVmHardwareSerial",
    "ApiName": "SerialApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/serial",
    "Tags": "Serial",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmPortHardwareSerial",
    "CommandInfo": "Invoke-UpdateVmPortHardwareSerial",
    "ApiName": "SerialApi",
    "Path": "/api/vcenter/vm/{vm}/hardware/serial/{port}",
    "Tags": "Serial",
    "RelatedCommandInfos": "Initialize-VmHardwareSerialUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "CreateNetworkingDnsServers",
    "CommandInfo": "Invoke-CreateNetworkingDnsServers",
    "ApiName": "ServersApi",
    "Path": "/api/appliance/networking/dns/servers",
    "Tags": "Servers",
    "RelatedCommandInfos": "Initialize-NetworkingDnsServersAddRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetNetworkingDnsServers",
    "CommandInfo": "Invoke-GetNetworkingDnsServers",
    "ApiName": "ServersApi",
    "Path": "/api/appliance/networking/dns/servers",
    "Tags": "Servers",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetNetworkingDnsServers",
    "CommandInfo": "Invoke-SetNetworkingDnsServers",
    "ApiName": "ServersApi",
    "Path": "/api/appliance/networking/dns/servers",
    "Tags": "Servers",
    "RelatedCommandInfos": "Initialize-NetworkingDnsServersDNSServerConfig",
    "Method": "PUT"
  },
  {
    "Name": "TestDnsServers",
    "CommandInfo": "Invoke-TestDnsServers",
    "ApiName": "ServersApi",
    "Path": "/api/appliance/networking/dns/servers__action=test",
    "Tags": "Servers",
    "RelatedCommandInfos": "Initialize-NetworkingDnsServersTestRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetService",
    "CommandInfo": "Invoke-GetService",
    "ApiName": "ServiceApi",
    "Path": "/api/vcenter/services/{service}",
    "Tags": "Service",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetServiceIdAuthentication",
    "CommandInfo": "Invoke-GetServiceIdAuthentication",
    "ApiName": "ServiceApi",
    "Path": "/api/vapi/metadata/authentication/service/{service_id}",
    "Tags": "Service",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetServiceIdMetamodel",
    "CommandInfo": "Invoke-GetServiceIdMetamodel",
    "ApiName": "ServiceApi",
    "Path": "/api/vapi/metadata/metamodel/service/{service_id}",
    "Tags": "Service",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetServiceIdPrivilege",
    "CommandInfo": "Invoke-GetServiceIdPrivilege",
    "ApiName": "ServiceApi",
    "Path": "/api/vapi/metadata/privilege/service/{service_id}",
    "Tags": "Service",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetServices",
    "CommandInfo": "Invoke-GetServices",
    "ApiName": "ServiceApi",
    "Path": "/api/vcenter/services",
    "Tags": "Service",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataAuthenticationService",
    "CommandInfo": "Invoke-ListMetadataAuthenticationService",
    "ApiName": "ServiceApi",
    "Path": "/api/vapi/metadata/authentication/service",
    "Tags": "Service",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataMetamodelService",
    "CommandInfo": "Invoke-ListMetadataMetamodelService",
    "ApiName": "ServiceApi",
    "Path": "/api/vapi/metadata/metamodel/service",
    "Tags": "Service",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataPrivilegeService",
    "CommandInfo": "Invoke-ListMetadataPrivilegeService",
    "ApiName": "ServiceApi",
    "Path": "/api/vapi/metadata/privilege/service",
    "Tags": "Service",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RestartService",
    "CommandInfo": "Invoke-RestartService",
    "ApiName": "ServiceApi",
    "Path": "/api/vcenter/services/{service}__action=restart",
    "Tags": "Service",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "StartService",
    "CommandInfo": "Invoke-StartService",
    "ApiName": "ServiceApi",
    "Path": "/api/vcenter/services/{service}__action=start",
    "Tags": "Service",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "StopService",
    "CommandInfo": "Invoke-StopService",
    "ApiName": "ServiceApi",
    "Path": "/api/vcenter/services/{service}__action=stop",
    "Tags": "Service",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "UpdateService",
    "CommandInfo": "Invoke-UpdateService",
    "ApiName": "ServiceApi",
    "Path": "/api/vcenter/services/{service}",
    "Tags": "Service",
    "RelatedCommandInfos": "Initialize-ServicesServiceUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "CreateClusterAttestationServicesAsync",
    "CommandInfo": "Invoke-CreateClusterAttestationServicesAsync",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/attestation/services__vmw-task=true",
    "Tags": "Services",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustedClustersAttestationServicesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateClusterKmsServicesAsync",
    "CommandInfo": "Invoke-CreateClusterKmsServicesAsync",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/kms/services__vmw-task=true",
    "Tags": "Services",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustedClustersKmsServicesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateTrustedInfrastructureAttestationServices",
    "CommandInfo": "Invoke-CreateTrustedInfrastructureAttestationServices",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/attestation/services",
    "Tags": "Services",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureAttestationServicesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateTrustedInfrastructureKmsServices",
    "CommandInfo": "Invoke-CreateTrustedInfrastructureKmsServices",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/kms/services",
    "Tags": "Services",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureKmsServicesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteClusterServiceAsync",
    "CommandInfo": "Invoke-DeleteClusterServiceAsync",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/attestation/services/{service}__vmw-task=true",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteClusterServiceAsync_0",
    "CommandInfo": "Invoke-DeleteClusterServiceAsync_0",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/kms/services/{service}__vmw-task=true",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteServiceAttestation",
    "CommandInfo": "Invoke-DeleteServiceAttestation",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/attestation/services/{service}",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteServiceKms",
    "CommandInfo": "Invoke-DeleteServiceKms",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/kms/services/{service}",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterServiceAttestation",
    "CommandInfo": "Invoke-GetClusterServiceAttestation",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/attestation/services/{service}",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterServiceKms",
    "CommandInfo": "Invoke-GetClusterServiceKms",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/kms/services/{service}",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetService",
    "CommandInfo": "Invoke-ApplianceGetService",
    "ApiName": "ServicesApi",
    "Path": "/api/appliance/services/{service}",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetServiceAttestation",
    "CommandInfo": "Invoke-GetServiceAttestation",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/attestation/services/{service}",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetServiceKms",
    "CommandInfo": "Invoke-GetServiceKms",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/kms/services/{service}",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListServices",
    "CommandInfo": "Invoke-ApplianceListServices",
    "ApiName": "ServicesApi",
    "Path": "/api/appliance/services",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "QueryAttestationServices",
    "CommandInfo": "Invoke-QueryAttestationServices",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/attestation/services__action=query",
    "Tags": "Services",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureAttestationServicesFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "QueryClusterAttestationServices",
    "CommandInfo": "Invoke-QueryClusterAttestationServices",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/attestation/services__action=query",
    "Tags": "Services",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustedClustersAttestationServicesFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "QueryClusterKmsServices",
    "CommandInfo": "Invoke-QueryClusterKmsServices",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/kms/services__action=query",
    "Tags": "Services",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustedClustersKmsServicesFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "QueryKmsServices",
    "CommandInfo": "Invoke-QueryKmsServices",
    "ApiName": "ServicesApi",
    "Path": "/api/vcenter/trusted-infrastructure/kms/services__action=query",
    "Tags": "Services",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureKmsServicesFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "RestartService",
    "CommandInfo": "Invoke-ApplianceRestartService",
    "ApiName": "ServicesApi",
    "Path": "/api/appliance/services/{service}__action=restart",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "StartService",
    "CommandInfo": "Invoke-ApplianceStartService",
    "ApiName": "ServicesApi",
    "Path": "/api/appliance/services/{service}__action=start",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "StopService",
    "CommandInfo": "Invoke-ApplianceStopService",
    "ApiName": "ServicesApi",
    "Path": "/api/appliance/services/{service}__action=stop",
    "Tags": "Services",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "DeleteClusterAttestationServicesAppliedConfigAsync",
    "CommandInfo": "Invoke-DeleteClusterAttestationServicesAppliedConfigAsync",
    "ApiName": "ServicesAppliedConfigApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/attestation/services-applied-config__vmw-task=true",
    "Tags": "ServicesAppliedConfig",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteClusterKmsServicesAppliedConfigAsync",
    "CommandInfo": "Invoke-DeleteClusterKmsServicesAppliedConfigAsync",
    "ApiName": "ServicesAppliedConfigApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/kms/services-applied-config__vmw-task=true",
    "Tags": "ServicesAppliedConfig",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteClusterServicesAppliedConfigAsync",
    "CommandInfo": "Invoke-DeleteClusterServicesAppliedConfigAsync",
    "ApiName": "ServicesAppliedConfigApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/services-applied-config__vmw-task=true",
    "Tags": "ServicesAppliedConfig",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterAttestationServicesAppliedConfigAsync",
    "CommandInfo": "Invoke-GetClusterAttestationServicesAppliedConfigAsync",
    "ApiName": "ServicesAppliedConfigApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/attestation/services-applied-config__vmw-task=true",
    "Tags": "ServicesAppliedConfig",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureNetworkAddress",
    "Method": "GET"
  },
  {
    "Name": "GetClusterKmsServicesAppliedConfigAsync",
    "CommandInfo": "Invoke-GetClusterKmsServicesAppliedConfigAsync",
    "ApiName": "ServicesAppliedConfigApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/kms/services-applied-config__vmw-task=true",
    "Tags": "ServicesAppliedConfig",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterServicesAppliedConfigAsync",
    "CommandInfo": "Invoke-GetClusterServicesAppliedConfigAsync",
    "ApiName": "ServicesAppliedConfigApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/services-applied-config__vmw-task=true",
    "Tags": "ServicesAppliedConfig",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "QueryClusterAttestationServicesAppliedConfigAsync",
    "CommandInfo": "Invoke-QueryClusterAttestationServicesAppliedConfigAsync",
    "ApiName": "ServicesAppliedConfigApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/attestation/services-applied-config__action=query&vmw-task=true",
    "Tags": "ServicesAppliedConfig",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustedClustersAttestationServicesAppliedConfigFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "QueryClusterKmsServicesAppliedConfigAsync",
    "CommandInfo": "Invoke-QueryClusterKmsServicesAppliedConfigAsync",
    "ApiName": "ServicesAppliedConfigApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/kms/services-applied-config__action=query&vmw-task=true",
    "Tags": "ServicesAppliedConfig",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustedClustersKmsServicesAppliedConfigFilterSpec",
    "Method": "POST"
  },
  {
    "Name": "UpdateClusterAttestationServicesAppliedConfigAsync",
    "CommandInfo": "Invoke-UpdateClusterAttestationServicesAppliedConfigAsync",
    "ApiName": "ServicesAppliedConfigApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/attestation/services-applied-config__vmw-task=true",
    "Tags": "ServicesAppliedConfig",
    "RelatedCommandInfos": "",
    "Method": "PATCH"
  },
  {
    "Name": "UpdateClusterKmsServicesAppliedConfigAsync",
    "CommandInfo": "Invoke-UpdateClusterKmsServicesAppliedConfigAsync",
    "ApiName": "ServicesAppliedConfigApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/kms/services-applied-config__vmw-task=true",
    "Tags": "ServicesAppliedConfig",
    "RelatedCommandInfos": "",
    "Method": "PATCH"
  },
  {
    "Name": "UpdateClusterServicesAppliedConfigAsync",
    "CommandInfo": "Invoke-UpdateClusterServicesAppliedConfigAsync",
    "ApiName": "ServicesAppliedConfigApi",
    "Path": "/api/vcenter/trusted-infrastructure/trusted-clusters/{cluster}/services-applied-config__vmw-task=true",
    "Tags": "ServicesAppliedConfig",
    "RelatedCommandInfos": "",
    "Method": "PATCH"
  },
  {
    "Name": "GetClusterAttestationServiceStatusAsync",
    "CommandInfo": "Invoke-GetClusterAttestationServiceStatusAsync",
    "ApiName": "ServiceStatusApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/service-status__vmw-task=true",
    "Tags": "ServiceStatus",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterKmsServiceStatusAsync",
    "CommandInfo": "Invoke-GetClusterKmsServiceStatusAsync",
    "ApiName": "ServiceStatusApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/service-status__vmw-task=true",
    "Tags": "ServiceStatus",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateSession",
    "CommandInfo": "Invoke-CreateSession",
    "ApiName": "SessionApi",
    "Path": "/api/session",
    "Tags": "Session",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "DeleteSession",
    "CommandInfo": "Invoke-DeleteSession",
    "ApiName": "SessionApi",
    "Path": "/api/session",
    "Tags": "Session",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetSession",
    "CommandInfo": "Invoke-GetSession",
    "ApiName": "SessionApi",
    "Path": "/api/session",
    "Tags": "Session",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterTpm2SettingsAsync",
    "CommandInfo": "Invoke-GetClusterTpm2SettingsAsync",
    "ApiName": "SettingsApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/tpm2/settings__vmw-task=true",
    "Tags": "Settings",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateClusterTpm2SettingsAsync",
    "CommandInfo": "Invoke-UpdateClusterTpm2SettingsAsync",
    "ApiName": "SettingsApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/attestation/tpm2/settings__vmw-task=true",
    "Tags": "Settings",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityClustersAttestationTpm2SettingsUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetAccessShell",
    "CommandInfo": "Invoke-GetAccessShell",
    "ApiName": "ShellApi",
    "Path": "/api/appliance/access/shell",
    "Tags": "Shell",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetAccessShell",
    "CommandInfo": "Invoke-SetAccessShell",
    "ApiName": "ShellApi",
    "Path": "/api/appliance/access/shell",
    "Tags": "Shell",
    "RelatedCommandInfos": "Initialize-AccessShellShellConfig",
    "Method": "PUT"
  },
  {
    "Name": "CancelShutdown",
    "CommandInfo": "Invoke-CancelShutdown",
    "ApiName": "ShutdownApi",
    "Path": "/api/appliance/shutdown__action=cancel",
    "Tags": "Shutdown",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetShutdown",
    "CommandInfo": "Invoke-GetShutdown",
    "ApiName": "ShutdownApi",
    "Path": "/api/appliance/shutdown",
    "Tags": "Shutdown",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "PoweroffShutdown",
    "CommandInfo": "Invoke-PoweroffShutdown",
    "ApiName": "ShutdownApi",
    "Path": "/api/appliance/shutdown__action=poweroff",
    "Tags": "Shutdown",
    "RelatedCommandInfos": "Initialize-ShutdownPoweroffRequestBody",
    "Method": "POST"
  },
  {
    "Name": "RebootShutdown",
    "CommandInfo": "Invoke-RebootShutdown",
    "ApiName": "ShutdownApi",
    "Path": "/api/appliance/shutdown__action=reboot",
    "Tags": "Shutdown",
    "RelatedCommandInfos": "Initialize-ShutdownRebootRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetCertificateManagementSigningCertificate",
    "CommandInfo": "Invoke-GetCertificateManagementSigningCertificate",
    "ApiName": "SigningCertificateApi",
    "Path": "/api/vcenter/certificate-management/vcenter/signing-certificate",
    "Tags": "SigningCertificate",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RefreshSigningCertificate",
    "CommandInfo": "Invoke-RefreshSigningCertificate",
    "ApiName": "SigningCertificateApi",
    "Path": "/api/vcenter/certificate-management/vcenter/signing-certificate__action=refresh",
    "Tags": "SigningCertificate",
    "RelatedCommandInfos": "Initialize-CertificateManagementVcenterSigningCertificateRefreshRequestBody",
    "Method": "POST"
  },
  {
    "Name": "SetCertificateManagementSigningCertificate",
    "CommandInfo": "Invoke-SetCertificateManagementSigningCertificate",
    "ApiName": "SigningCertificateApi",
    "Path": "/api/vcenter/certificate-management/vcenter/signing-certificate",
    "Tags": "SigningCertificate",
    "RelatedCommandInfos": "Initialize-CertificateManagementVcenterSigningCertificateSetSpec",
    "Method": "PUT"
  },
  {
    "Name": "ApplyClusterSoftwareAsync",
    "CommandInfo": "Invoke-ApplyClusterSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software__action=apply&vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsClustersSoftwareApplySpec",
    "Method": "POST"
  },
  {
    "Name": "ApplyHostSoftwareAsync",
    "CommandInfo": "Invoke-ApplyHostSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/hosts/{host}/software__action=apply&vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsHostsSoftwareApplySpec",
    "Method": "POST"
  },
  {
    "Name": "CheckClusterEnablementSoftwareAsync",
    "CommandInfo": "Invoke-CheckClusterEnablementSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/software__action=check&vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsClustersEnablementSoftwareCheckSpec",
    "Method": "POST"
  },
  {
    "Name": "CheckClusterSoftwareAsync",
    "CommandInfo": "Invoke-CheckClusterSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software__action=check&vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsClustersSoftwareCheckSpec",
    "Method": "POST"
  },
  {
    "Name": "CheckHostEnablementSoftwareAsync",
    "CommandInfo": "Invoke-CheckHostEnablementSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/hosts/{host}/enablement/software__action=check&vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsHostsEnablementSoftwareCheckSpec",
    "Method": "POST"
  },
  {
    "Name": "CheckHostSoftwareAsync",
    "CommandInfo": "Invoke-CheckHostSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/hosts/{host}/software__action=check&vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsHostsSoftwareCheckSpec",
    "Method": "POST"
  },
  {
    "Name": "ExportClusterSoftware",
    "CommandInfo": "Invoke-ExportClusterSoftware",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software__action=export",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsClustersSoftwareExportSpec",
    "Method": "POST"
  },
  {
    "Name": "ExportHostSoftware",
    "CommandInfo": "Invoke-ExportHostSoftware",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/hosts/{host}/software__action=export",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsHostsSoftwareExportSpec",
    "Method": "POST"
  },
  {
    "Name": "GetClusterEnablementSoftware",
    "CommandInfo": "Invoke-GetClusterEnablementSoftware",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/software",
    "Tags": "Software",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterSoftware",
    "CommandInfo": "Invoke-GetClusterSoftware",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software",
    "Tags": "Software",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostEnablementSoftware",
    "CommandInfo": "Invoke-GetHostEnablementSoftware",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/hosts/{host}/enablement/software",
    "Tags": "Software",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostSoftware",
    "CommandInfo": "Invoke-GetHostSoftware",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/hosts/{host}/software",
    "Tags": "Software",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetSoftware",
    "CommandInfo": "Invoke-GetSoftware",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/software",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-HostsSoftwareHostCredentials",
    "Method": "GET"
  },
  {
    "Name": "ScanClusterSoftwareAsync",
    "CommandInfo": "Invoke-ScanClusterSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software__action=scan&vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ScanHostSoftwareAsync",
    "CommandInfo": "Invoke-ScanHostSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/hosts/{host}/software__action=scan&vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "SetClusterEnablementSoftwareAsync",
    "CommandInfo": "Invoke-SetClusterEnablementSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/software__vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsClustersEnablementSoftwareEnableSpec",
    "Method": "PUT"
  },
  {
    "Name": "SetHostEnablementSoftwareAsync",
    "CommandInfo": "Invoke-SetHostEnablementSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/hosts/{host}/enablement/software__vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsHostsEnablementSoftwareEnableSpec",
    "Method": "PUT"
  },
  {
    "Name": "StageClusterSoftwareAsync",
    "CommandInfo": "Invoke-StageClusterSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software__action=stage&vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsClustersSoftwareStageSpec",
    "Method": "POST"
  },
  {
    "Name": "StageHostSoftwareAsync",
    "CommandInfo": "Invoke-StageHostSoftwareAsync",
    "ApiName": "SoftwareApi",
    "Path": "/api/esx/settings/hosts/{host}/software__action=stage&vmw-task=true",
    "Tags": "Software",
    "RelatedCommandInfos": "Initialize-SettingsHostsSoftwareStageSpec",
    "Method": "POST"
  },
  {
    "Name": "GetHealthSoftwarePackages",
    "CommandInfo": "Invoke-GetHealthSoftwarePackages",
    "ApiName": "SoftwarepackagesApi",
    "Path": "/api/appliance/health/software-packages",
    "Tags": "Softwarepackages",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "DeleteClusterSolutionAsync",
    "CommandInfo": "Invoke-DeleteClusterSolutionAsync",
    "ApiName": "SolutionsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/solutions/{solution}__vmw-task=true",
    "Tags": "Solutions",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteHostSolutionAsync",
    "CommandInfo": "Invoke-DeleteHostSolutionAsync",
    "ApiName": "SolutionsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/solutions/{solution}__vmw-task=true",
    "Tags": "Solutions",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetClusterSolutionSoftware",
    "CommandInfo": "Invoke-GetClusterSolutionSoftware",
    "ApiName": "SolutionsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/solutions/{solution}",
    "Tags": "Solutions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostSolutionSoftware",
    "CommandInfo": "Invoke-GetHostSolutionSoftware",
    "ApiName": "SolutionsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/solutions/{solution}",
    "Tags": "Solutions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListClusterSoftwareSolutions",
    "CommandInfo": "Invoke-ListClusterSoftwareSolutions",
    "ApiName": "SolutionsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/solutions",
    "Tags": "Solutions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHostSoftwareSolutions",
    "CommandInfo": "Invoke-ListHostSoftwareSolutions",
    "ApiName": "SolutionsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/solutions",
    "Tags": "Solutions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetClusterSolutionAsync",
    "CommandInfo": "Invoke-SetClusterSolutionAsync",
    "ApiName": "SolutionsApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/solutions/{solution}__vmw-task=true",
    "Tags": "Solutions",
    "RelatedCommandInfos": "Initialize-SettingsSolutionSpec",
    "Method": "PUT"
  },
  {
    "Name": "SetHostSolutionAsync",
    "CommandInfo": "Invoke-SetHostSolutionAsync",
    "ApiName": "SolutionsApi",
    "Path": "/api/esx/settings/hosts/{host}/software/solutions/{solution}__vmw-task=true",
    "Tags": "Solutions",
    "RelatedCommandInfos": "Initialize-SettingsSolutionSpec",
    "Method": "PUT"
  },
  {
    "Name": "GetAccessSsh",
    "CommandInfo": "Invoke-GetAccessSsh",
    "ApiName": "SshApi",
    "Path": "/api/appliance/access/ssh",
    "Tags": "Ssh",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetAccessSsh",
    "CommandInfo": "Invoke-SetAccessSsh",
    "ApiName": "SshApi",
    "Path": "/api/appliance/access/ssh",
    "Tags": "Ssh",
    "RelatedCommandInfos": "Initialize-AccessSshSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "DeleteUpdateStaged",
    "CommandInfo": "Invoke-DeleteUpdateStaged",
    "ApiName": "StagedApi",
    "Path": "/api/appliance/update/staged",
    "Tags": "Staged",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetUpdateStaged",
    "CommandInfo": "Invoke-GetUpdateStaged",
    "ApiName": "StagedApi",
    "Path": "/api/appliance/update/staged",
    "Tags": "Staged",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CheckPscStandalone",
    "CommandInfo": "Invoke-CheckPscStandalone",
    "ApiName": "StandaloneApi",
    "Path": "/api/vcenter/deployment/install/psc/standalone__action=check",
    "Tags": "Standalone",
    "RelatedCommandInfos": "Initialize-DeploymentStandalonePscSpec",
    "Method": "POST"
  },
  {
    "Name": "GetHealthStorage",
    "CommandInfo": "Invoke-GetHealthStorage",
    "ApiName": "StorageApi",
    "Path": "/api/appliance/health/storage",
    "Tags": "Storage",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetLibraryItemIdStorage",
    "CommandInfo": "Invoke-GetLibraryItemIdStorage",
    "ApiName": "StorageApi",
    "Path": "/api/content/library/item/{library_item_id}/storage__file_name",
    "Tags": "Storage",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListLibraryItemIdContentStorage",
    "CommandInfo": "Invoke-ListLibraryItemIdContentStorage",
    "ApiName": "StorageApi",
    "Path": "/api/content/library/item/{library_item_id}/storage",
    "Tags": "Storage",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListSystemStorage",
    "CommandInfo": "Invoke-ListSystemStorage",
    "ApiName": "StorageApi",
    "Path": "/api/appliance/system/storage",
    "Tags": "Storage",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ResizeExSystemStorage",
    "CommandInfo": "Invoke-ResizeExSystemStorage",
    "ApiName": "StorageApi",
    "Path": "/api/appliance/system/storage__action=resize-ex",
    "Tags": "Storage",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ResizeSystemStorage",
    "CommandInfo": "Invoke-ResizeSystemStorage",
    "ApiName": "StorageApi",
    "Path": "/api/appliance/system/storage__action=resize",
    "Tags": "Storage",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetStructureIdMetamodel",
    "CommandInfo": "Invoke-GetStructureIdMetamodel",
    "ApiName": "StructureApi",
    "Path": "/api/vapi/metadata/metamodel/structure/{structure_id}",
    "Tags": "Structure",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListMetadataMetamodelStructure",
    "CommandInfo": "Invoke-ListMetadataMetamodelStructure",
    "ApiName": "StructureApi",
    "Path": "/api/vapi/metadata/metamodel/structure",
    "Tags": "Structure",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "EvictLibraryItemIdSubscribedItem",
    "CommandInfo": "Invoke-EvictLibraryItemIdSubscribedItem",
    "ApiName": "SubscribedItemApi",
    "Path": "/api/content/library/subscribed-item/{library_item_id}__action=evict",
    "Tags": "SubscribedItem",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "SyncLibraryItemIdSubscribedItem",
    "CommandInfo": "Invoke-SyncLibraryItemIdSubscribedItem",
    "ApiName": "SubscribedItemApi",
    "Path": "/api/content/library/subscribed-item/{library_item_id}__action=sync",
    "Tags": "SubscribedItem",
    "RelatedCommandInfos": "Initialize-LibrarySubscribedItemSyncRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CreateContentSubscribedLibrary",
    "CommandInfo": "Invoke-CreateContentSubscribedLibrary",
    "ApiName": "SubscribedLibraryApi",
    "Path": "/api/content/subscribed-library",
    "Tags": "SubscribedLibrary",
    "RelatedCommandInfos": "Initialize-LibraryModel",
    "Method": "POST"
  },
  {
    "Name": "DeleteLibraryIdContentSubscribedLibrary",
    "CommandInfo": "Invoke-DeleteLibraryIdContentSubscribedLibrary",
    "ApiName": "SubscribedLibraryApi",
    "Path": "/api/content/subscribed-library/{library_id}",
    "Tags": "SubscribedLibrary",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "EvictLibraryIdSubscribedLibrary",
    "CommandInfo": "Invoke-EvictLibraryIdSubscribedLibrary",
    "ApiName": "SubscribedLibraryApi",
    "Path": "/api/content/subscribed-library/{library_id}__action=evict",
    "Tags": "SubscribedLibrary",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetLibraryIdContentSubscribedLibrary",
    "CommandInfo": "Invoke-GetLibraryIdContentSubscribedLibrary",
    "ApiName": "SubscribedLibraryApi",
    "Path": "/api/content/subscribed-library/{library_id}",
    "Tags": "SubscribedLibrary",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListContentSubscribedLibrary",
    "CommandInfo": "Invoke-ListContentSubscribedLibrary",
    "ApiName": "SubscribedLibraryApi",
    "Path": "/api/content/subscribed-library",
    "Tags": "SubscribedLibrary",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ProbeContentSubscribedLibrary",
    "CommandInfo": "Invoke-ProbeContentSubscribedLibrary",
    "ApiName": "SubscribedLibraryApi",
    "Path": "/api/content/subscribed-library__action=probe",
    "Tags": "SubscribedLibrary",
    "RelatedCommandInfos": "Initialize-SubscribedLibraryProbeRequestBody",
    "Method": "POST"
  },
  {
    "Name": "SyncLibraryIdSubscribedLibrary",
    "CommandInfo": "Invoke-SyncLibraryIdSubscribedLibrary",
    "ApiName": "SubscribedLibraryApi",
    "Path": "/api/content/subscribed-library/{library_id}__action=sync",
    "Tags": "SubscribedLibrary",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "UpdateLibraryIdContentSubscribedLibrary",
    "CommandInfo": "Invoke-UpdateLibraryIdContentSubscribedLibrary",
    "ApiName": "SubscribedLibraryApi",
    "Path": "/api/content/subscribed-library/{library_id}",
    "Tags": "SubscribedLibrary",
    "RelatedCommandInfos": "Initialize-LibraryModel",
    "Method": "PATCH"
  },
  {
    "Name": "CreateLibraryContentSubscriptions",
    "CommandInfo": "Invoke-CreateLibraryContentSubscriptions",
    "ApiName": "SubscriptionsApi",
    "Path": "/api/content/library/{library}/subscriptions",
    "Tags": "Subscriptions",
    "RelatedCommandInfos": "Initialize-LibrarySubscriptionsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteLibrarySubscriptionContent",
    "CommandInfo": "Invoke-DeleteLibrarySubscriptionContent",
    "ApiName": "SubscriptionsApi",
    "Path": "/api/content/library/{library}/subscriptions/{subscription}",
    "Tags": "Subscriptions",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetLibrarySubscriptionContent",
    "CommandInfo": "Invoke-GetLibrarySubscriptionContent",
    "ApiName": "SubscriptionsApi",
    "Path": "/api/content/library/{library}/subscriptions/{subscription}",
    "Tags": "Subscriptions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListLibraryContentSubscriptions",
    "CommandInfo": "Invoke-ListLibraryContentSubscriptions",
    "ApiName": "SubscriptionsApi",
    "Path": "/api/content/library/{library}/subscriptions",
    "Tags": "Subscriptions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateLibrarySubscriptionContent",
    "CommandInfo": "Invoke-UpdateLibrarySubscriptionContent",
    "ApiName": "SubscriptionsApi",
    "Path": "/api/content/library/{library}/subscriptions/{subscription}",
    "Tags": "Subscriptions",
    "RelatedCommandInfos": "Initialize-LibrarySubscriptionsUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetSupervisorNamespaceManagementSummary",
    "CommandInfo": "Invoke-GetSupervisorNamespaceManagementSummary",
    "ApiName": "SummaryApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/summary",
    "Tags": "Summary",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNamespaceManagementSupervisorsSummaries",
    "CommandInfo": "Invoke-ListNamespaceManagementSupervisorsSummaries",
    "ApiName": "SummaryApi",
    "Path": "/api/vcenter/namespace-management/supervisors/summaries",
    "Tags": "Summary",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "EnableOnComputeClusterClusterSupervisors",
    "CommandInfo": "Invoke-EnableOnComputeClusterClusterSupervisors",
    "ApiName": "SupervisorsApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{cluster}__action=enable_on_compute_cluster",
    "Tags": "Supervisors",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorsEnableOnComputeClusterSpec",
    "Method": "POST"
  },
  {
    "Name": "EnableOnZonesNamespaceManagementSupervisors",
    "CommandInfo": "Invoke-EnableOnZonesNamespaceManagementSupervisors",
    "ApiName": "SupervisorsApi",
    "Path": "/api/vcenter/namespace-management/supervisors__action=enable_on_zones",
    "Tags": "Supervisors",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorsEnableOnZonesSpec",
    "Method": "POST"
  },
  {
    "Name": "CheckContentNamespaceManagementSupervisorServices",
    "CommandInfo": "Invoke-CheckContentNamespaceManagementSupervisorServices",
    "ApiName": "SupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services__action=checkContent",
    "Tags": "SupervisorServices",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorServicesCheckContentRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CreateNamespaceManagementSupervisorServices",
    "CommandInfo": "Invoke-CreateNamespaceManagementSupervisorServices",
    "ApiName": "SupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services",
    "Tags": "SupervisorServices",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorServicesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteSupervisorServiceNamespaceManagement",
    "CommandInfo": "Invoke-DeleteSupervisorServiceNamespaceManagement",
    "ApiName": "SupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services/{supervisor_service}",
    "Tags": "SupervisorServices",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetSupervisorServiceNamespaceManagement",
    "CommandInfo": "Invoke-GetSupervisorServiceNamespaceManagement",
    "ApiName": "SupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services/{supervisor_service}",
    "Tags": "SupervisorServices",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetSupervisorSupervisorServiceTargetVersionSupervisorServicesPrecheck",
    "CommandInfo": "Invoke-GetSupervisorSupervisorServiceTargetVersionSupervisorServicesPrecheck",
    "ApiName": "SupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/supervisor-services/{supervisor_service}/versions/{target_version}/precheck",
    "Tags": "SupervisorServices",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNamespaceManagementSupervisorServices",
    "CommandInfo": "Invoke-ListNamespaceManagementSupervisorServices",
    "ApiName": "SupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services",
    "Tags": "SupervisorServices",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "PrecheckSupervisorSupervisorService",
    "CommandInfo": "Invoke-PrecheckSupervisorSupervisorService",
    "ApiName": "SupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/supervisor-services/{supervisor_service}__action=precheck",
    "Tags": "SupervisorServices",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorsSupervisorServicesPrecheckSpec",
    "Method": "POST"
  },
  {
    "Name": "UpdateSupervisorService",
    "CommandInfo": "Invoke-UpdateSupervisorService",
    "ApiName": "SupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services/{supervisor_service}__action=activate",
    "Tags": "SupervisorServices",
    "RelatedCommandInfos": "",
    "Method": "PATCH"
  },
  {
    "Name": "UpdateSupervisorServiceNamespaceManagement",
    "CommandInfo": "Invoke-UpdateSupervisorServiceNamespaceManagement",
    "ApiName": "SupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services/{supervisor_service}",
    "Tags": "SupervisorServices",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorServicesUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "UpdateSupervisorService_0",
    "CommandInfo": "Invoke-UpdateSupervisorService_0",
    "ApiName": "SupervisorServicesApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services/{supervisor_service}__action=deactivate",
    "Tags": "SupervisorServices",
    "RelatedCommandInfos": "",
    "Method": "PATCH"
  },
  {
    "Name": "CreateClusterNamespaceManagementSupportBundle",
    "CommandInfo": "Invoke-CreateClusterNamespaceManagementSupportBundle",
    "ApiName": "SupportBundleApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/support-bundle",
    "Tags": "SupportBundle",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateSupportBundleAsync",
    "CommandInfo": "Invoke-CreateSupportBundleAsync",
    "ApiName": "SupportBundleApi",
    "Path": "/api/appliance/support-bundle__vmw-task=true",
    "Tags": "SupportBundle",
    "RelatedCommandInfos": "Initialize-SupportBundleCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteIdSupportBundle",
    "CommandInfo": "Invoke-DeleteIdSupportBundle",
    "ApiName": "SupportBundleApi",
    "Path": "/api/appliance/support-bundle/{id}",
    "Tags": "SupportBundle",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "ListSupportBundle",
    "CommandInfo": "Invoke-ListSupportBundle",
    "ApiName": "SupportBundleApi",
    "Path": "/api/appliance/support-bundle",
    "Tags": "SupportBundle",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHealthSwap",
    "CommandInfo": "Invoke-GetHealthSwap",
    "ApiName": "SwapApi",
    "Path": "/api/appliance/health/swap",
    "Tags": "Swap",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetDepotsSyncSchedule",
    "CommandInfo": "Invoke-GetDepotsSyncSchedule",
    "ApiName": "SyncScheduleApi",
    "Path": "/api/esx/settings/depots/sync-schedule",
    "Tags": "SyncSchedule",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetDepotsSyncSchedule",
    "CommandInfo": "Invoke-SetDepotsSyncSchedule",
    "ApiName": "SyncScheduleApi",
    "Path": "/api/esx/settings/depots/sync-schedule",
    "Tags": "SyncSchedule",
    "RelatedCommandInfos": "Initialize-SettingsDepotsSyncScheduleSpec",
    "Method": "PUT"
  },
  {
    "Name": "GetHealthSystem",
    "CommandInfo": "Invoke-GetHealthSystem",
    "ApiName": "SystemApi",
    "Path": "/api/appliance/health/system",
    "Tags": "System",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHealthSystemLastcheck",
    "CommandInfo": "Invoke-GetHealthSystemLastcheck",
    "ApiName": "SystemApi",
    "Path": "/api/appliance/health/system/lastcheck",
    "Tags": "System",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "HelloSystem",
    "CommandInfo": "Invoke-HelloSystem",
    "ApiName": "SystemApi",
    "Path": "/api/vcenter/system__action=hello",
    "Tags": "System",
    "RelatedCommandInfos": "Initialize-SystemHelloSpec",
    "Method": "POST"
  },
  {
    "Name": "ListBackupSystemName",
    "CommandInfo": "Invoke-ListBackupSystemName",
    "ApiName": "SystemNameApi",
    "Path": "/api/appliance/recovery/backup/system-name__action=list",
    "Tags": "SystemName",
    "RelatedCommandInfos": "Initialize-RecoveryBackupLocationSpec",
    "Method": "POST"
  },
  {
    "Name": "AddToUsedByTagId",
    "CommandInfo": "Invoke-AddToUsedByTagId",
    "ApiName": "TagApi",
    "Path": "/api/cis/tagging/tag/{tag_id}__action=add-to-used-by",
    "Tags": "Tag",
    "RelatedCommandInfos": "Initialize-TaggingTagAddToUsedByRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CreateTag",
    "CommandInfo": "Invoke-CreateTag",
    "ApiName": "TagApi",
    "Path": "/api/cis/tagging/tag",
    "Tags": "Tag",
    "RelatedCommandInfos": "Initialize-TaggingTagCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteTagId",
    "CommandInfo": "Invoke-DeleteTagId",
    "ApiName": "TagApi",
    "Path": "/api/cis/tagging/tag/{tag_id}",
    "Tags": "Tag",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetTagId",
    "CommandInfo": "Invoke-GetTagId",
    "ApiName": "TagApi",
    "Path": "/api/cis/tagging/tag/{tag_id}",
    "Tags": "Tag",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListTag",
    "CommandInfo": "Invoke-ListTag",
    "ApiName": "TagApi",
    "Path": "/api/cis/tagging/tag",
    "Tags": "Tag",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListTagsForCategory",
    "CommandInfo": "Invoke-ListTagsForCategory",
    "ApiName": "TagApi",
    "Path": "/api/cis/tagging/tag__action=list-tags-for-category",
    "Tags": "Tag",
    "RelatedCommandInfos": "Initialize-TaggingTagListTagsForCategoryRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListUsedTags",
    "CommandInfo": "Invoke-ListUsedTags",
    "ApiName": "TagApi",
    "Path": "/api/cis/tagging/tag__action=list-used-tags",
    "Tags": "Tag",
    "RelatedCommandInfos": "Initialize-TaggingTagListUsedTagsRequestBody",
    "Method": "POST"
  },
  {
    "Name": "RemoveFromUsedByTagId",
    "CommandInfo": "Invoke-RemoveFromUsedByTagId",
    "ApiName": "TagApi",
    "Path": "/api/cis/tagging/tag/{tag_id}__action=remove-from-used-by",
    "Tags": "Tag",
    "RelatedCommandInfos": "Initialize-TaggingTagRemoveFromUsedByRequestBody",
    "Method": "POST"
  },
  {
    "Name": "RevokePropagatingPermissionsTagId",
    "CommandInfo": "Invoke-RevokePropagatingPermissionsTagId",
    "ApiName": "TagApi",
    "Path": "/api/cis/tagging/tag/{tag_id}__action=revoke-propagating-permissions",
    "Tags": "Tag",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "UpdateTagId",
    "CommandInfo": "Invoke-UpdateTagId",
    "ApiName": "TagApi",
    "Path": "/api/cis/tagging/tag/{tag_id}",
    "Tags": "Tag",
    "RelatedCommandInfos": "Initialize-TaggingTagUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "AttachMultipleTagsToObjectTagAssociation",
    "CommandInfo": "Invoke-AttachMultipleTagsToObjectTagAssociation",
    "ApiName": "TagAssociationApi",
    "Path": "/api/cis/tagging/tag-association__action=attach-multiple-tags-to-object",
    "Tags": "TagAssociation",
    "RelatedCommandInfos": "Initialize-TaggingTagAssociationAttachMultipleTagsToObjectRequestBody",
    "Method": "POST"
  },
  {
    "Name": "AttachTagIdTagAssociation",
    "CommandInfo": "Invoke-AttachTagIdTagAssociation",
    "ApiName": "TagAssociationApi",
    "Path": "/api/cis/tagging/tag-association/{tag_id}__action=attach",
    "Tags": "TagAssociation",
    "RelatedCommandInfos": "Initialize-TaggingTagAssociationAttachRequestBody",
    "Method": "POST"
  },
  {
    "Name": "AttachTagToMultipleObjectsTagIdTagAssociation",
    "CommandInfo": "Invoke-AttachTagToMultipleObjectsTagIdTagAssociation",
    "ApiName": "TagAssociationApi",
    "Path": "/api/cis/tagging/tag-association/{tag_id}__action=attach-tag-to-multiple-objects",
    "Tags": "TagAssociation",
    "RelatedCommandInfos": "Initialize-TaggingTagAssociationAttachTagToMultipleObjectsRequestBody",
    "Method": "POST"
  },
  {
    "Name": "DetachMultipleTagsFromObjectTagAssociation",
    "CommandInfo": "Invoke-DetachMultipleTagsFromObjectTagAssociation",
    "ApiName": "TagAssociationApi",
    "Path": "/api/cis/tagging/tag-association__action=detach-multiple-tags-from-object",
    "Tags": "TagAssociation",
    "RelatedCommandInfos": "Initialize-TaggingTagAssociationDetachMultipleTagsFromObjectRequestBody",
    "Method": "POST"
  },
  {
    "Name": "DetachTagFromMultipleObjectsTagIdTagAssociation",
    "CommandInfo": "Invoke-DetachTagFromMultipleObjectsTagIdTagAssociation",
    "ApiName": "TagAssociationApi",
    "Path": "/api/cis/tagging/tag-association/{tag_id}__action=detach-tag-from-multiple-objects",
    "Tags": "TagAssociation",
    "RelatedCommandInfos": "Initialize-TaggingTagAssociationDetachTagFromMultipleObjectsRequestBody",
    "Method": "POST"
  },
  {
    "Name": "DetachTagIdTagAssociation",
    "CommandInfo": "Invoke-DetachTagIdTagAssociation",
    "ApiName": "TagAssociationApi",
    "Path": "/api/cis/tagging/tag-association/{tag_id}__action=detach",
    "Tags": "TagAssociation",
    "RelatedCommandInfos": "Initialize-TaggingTagAssociationDetachRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListAttachableTagsTagAssociation",
    "CommandInfo": "Invoke-ListAttachableTagsTagAssociation",
    "ApiName": "TagAssociationApi",
    "Path": "/api/cis/tagging/tag-association__action=list-attachable-tags",
    "Tags": "TagAssociation",
    "RelatedCommandInfos": "Initialize-TaggingTagAssociationListAttachableTagsRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListAttachedObjectsOnTagsTagAssociation",
    "CommandInfo": "Invoke-ListAttachedObjectsOnTagsTagAssociation",
    "ApiName": "TagAssociationApi",
    "Path": "/api/cis/tagging/tag-association__action=list-attached-objects-on-tags",
    "Tags": "TagAssociation",
    "RelatedCommandInfos": "Initialize-TaggingTagAssociationListAttachedObjectsOnTagsRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListAttachedObjectsTagIdTagAssociation",
    "CommandInfo": "Invoke-ListAttachedObjectsTagIdTagAssociation",
    "ApiName": "TagAssociationApi",
    "Path": "/api/cis/tagging/tag-association/{tag_id}__action=list-attached-objects",
    "Tags": "TagAssociation",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ListAttachedTagsOnObjectsTagAssociation",
    "CommandInfo": "Invoke-ListAttachedTagsOnObjectsTagAssociation",
    "ApiName": "TagAssociationApi",
    "Path": "/api/cis/tagging/tag-association__action=list-attached-tags-on-objects",
    "Tags": "TagAssociation",
    "RelatedCommandInfos": "Initialize-TaggingTagAssociationListAttachedTagsOnObjectsRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListAttachedTagsTagAssociation",
    "CommandInfo": "Invoke-ListAttachedTagsTagAssociation",
    "ApiName": "TagAssociationApi",
    "Path": "/api/cis/tagging/tag-association__action=list-attached-tags",
    "Tags": "TagAssociation",
    "RelatedCommandInfos": "Initialize-TaggingTagAssociationListAttachedTagsRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CancelTask",
    "CommandInfo": "Invoke-CancelTask",
    "ApiName": "TasksApi",
    "Path": "/api/cis/tasks/{task}__action=cancel",
    "Tags": "Tasks",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetTask",
    "CommandInfo": "Invoke-GetTask",
    "ApiName": "TasksApi",
    "Path": "/api/cis/tasks/{task}",
    "Tags": "Tasks",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetTaskSnapservice",
    "CommandInfo": "Invoke-GetTaskSnapservice",
    "ApiName": "TasksApi",
    "Path": "/api/snapservice/tasks/{task}",
    "Tags": "Tasks",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListSnapserviceTasks",
    "CommandInfo": "Invoke-ListSnapserviceTasks",
    "ApiName": "TasksApi",
    "Path": "/api/snapservice/tasks",
    "Tags": "Tasks",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListTasks",
    "CommandInfo": "Invoke-ListTasks",
    "ApiName": "TasksApi",
    "Path": "/api/cis/tasks__action=list",
    "Tags": "Tasks",
    "RelatedCommandInfos": "Initialize-TasksListRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetInitialConfigRemotePscThumbprint",
    "CommandInfo": "Invoke-GetInitialConfigRemotePscThumbprint",
    "ApiName": "ThumbprintApi",
    "Path": "/api/vcenter/deployment/install/initial-config/remote-psc/thumbprint",
    "Tags": "Thumbprint",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateVmConsoleTickets",
    "CommandInfo": "Invoke-CreateVmConsoleTickets",
    "ApiName": "TicketsApi",
    "Path": "/api/vcenter/vm/{vm}/console/tickets",
    "Tags": "Tickets",
    "RelatedCommandInfos": "Initialize-VmConsoleTicketsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "GetSystemTime",
    "CommandInfo": "Invoke-GetSystemTime",
    "ApiName": "TimeApi",
    "Path": "/api/appliance/system/time",
    "Tags": "Time",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetNamespaceManagementStatsTimeSeries",
    "CommandInfo": "Invoke-GetNamespaceManagementStatsTimeSeries",
    "ApiName": "TimeSeriesApi",
    "Path": "/api/vcenter/namespace-management/stats/time-series",
    "Tags": "TimeSeries",
    "RelatedCommandInfos": "Initialize-NamespaceManagementStatsTimeSeriesPodIdentifier",
    "Method": "GET"
  },
  {
    "Name": "GetTimesync",
    "CommandInfo": "Invoke-GetTimesync",
    "ApiName": "TimesyncApi",
    "Path": "/api/appliance/timesync",
    "Tags": "Timesync",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetTimesync",
    "CommandInfo": "Invoke-SetTimesync",
    "ApiName": "TimesyncApi",
    "Path": "/api/appliance/timesync",
    "Tags": "Timesync",
    "RelatedCommandInfos": "Initialize-TimesyncSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "GetSystemTimeTimezone",
    "CommandInfo": "Invoke-GetSystemTimeTimezone",
    "ApiName": "TimezoneApi",
    "Path": "/api/appliance/system/time/timezone",
    "Tags": "Timezone",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetSystemTimeTimezone",
    "CommandInfo": "Invoke-SetSystemTimeTimezone",
    "ApiName": "TimezoneApi",
    "Path": "/api/appliance/system/time/timezone",
    "Tags": "Timezone",
    "RelatedCommandInfos": "Initialize-SystemTimeTimezoneSetRequestBody",
    "Method": "PUT"
  },
  {
    "Name": "GetCertificateManagementTls",
    "CommandInfo": "Invoke-GetCertificateManagementTls",
    "ApiName": "TlsApi",
    "Path": "/api/vcenter/certificate-management/vcenter/tls",
    "Tags": "Tls",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RenewTls",
    "CommandInfo": "Invoke-RenewTls",
    "ApiName": "TlsApi",
    "Path": "/api/vcenter/certificate-management/vcenter/tls__action=renew",
    "Tags": "Tls",
    "RelatedCommandInfos": "Initialize-CertificateManagementVcenterTlsRenewRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ReplaceVmcaSignedTls",
    "CommandInfo": "Invoke-ReplaceVmcaSignedTls",
    "ApiName": "TlsApi",
    "Path": "/api/vcenter/certificate-management/vcenter/tls__action=replace-vmca-signed",
    "Tags": "Tls",
    "RelatedCommandInfos": "Initialize-CertificateManagementVcenterTlsReplaceSpec",
    "Method": "POST"
  },
  {
    "Name": "SetCertificateManagementTls",
    "CommandInfo": "Invoke-SetCertificateManagementTls",
    "ApiName": "TlsApi",
    "Path": "/api/vcenter/certificate-management/vcenter/tls",
    "Tags": "Tls",
    "RelatedCommandInfos": "Initialize-CertificateManagementVcenterTlsSpec",
    "Method": "PUT"
  },
  {
    "Name": "CreateCertificateManagementTlsCsr",
    "CommandInfo": "Invoke-CreateCertificateManagementTlsCsr",
    "ApiName": "TlsCsrApi",
    "Path": "/api/vcenter/certificate-management/vcenter/tls-csr",
    "Tags": "TlsCsr",
    "RelatedCommandInfos": "Initialize-CertificateManagementVcenterTlsCsrSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateAuthenticationToken",
    "CommandInfo": "Invoke-CreateAuthenticationToken",
    "ApiName": "TokenApi",
    "Path": "/api/vcenter/authentication/token",
    "Tags": "Token",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetVmTools",
    "CommandInfo": "Invoke-GetVmTools",
    "ApiName": "ToolsApi",
    "Path": "/api/vcenter/vm/{vm}/tools",
    "Tags": "Tools",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmTools",
    "CommandInfo": "Invoke-UpdateVmTools",
    "ApiName": "ToolsApi",
    "Path": "/api/vcenter/vm/{vm}/tools",
    "Tags": "Tools",
    "RelatedCommandInfos": "Initialize-VmToolsUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "UpgradeVmTools",
    "CommandInfo": "Invoke-UpgradeVmTools",
    "ApiName": "ToolsApi",
    "Path": "/api/vcenter/vm/{vm}/tools__action=upgrade",
    "Tags": "Tools",
    "RelatedCommandInfos": "Initialize-VmToolsUpgradeRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetClusterNamespaceManagementTopology",
    "CommandInfo": "Invoke-GetClusterNamespaceManagementTopology",
    "ApiName": "TopologyApi",
    "Path": "/api/vcenter/namespace-management/clusters/{cluster}/topology",
    "Tags": "Topology",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetSupervisorNamespaceManagementTopology",
    "CommandInfo": "Invoke-GetSupervisorNamespaceManagementTopology",
    "ApiName": "TopologyApi",
    "Path": "/api/vcenter/namespace-management/supervisors/{supervisor}/topology",
    "Tags": "Topology",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetHostTpmHardware",
    "CommandInfo": "Invoke-GetHostTpmHardware",
    "ApiName": "TpmApi",
    "Path": "/api/vcenter/trusted-infrastructure/hosts/{host}/hardware/tpm/{tpm}",
    "Tags": "Tpm",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListHostTrustedInfrastructureHardwareTpm",
    "CommandInfo": "Invoke-ListHostTrustedInfrastructureHardwareTpm",
    "ApiName": "TpmApi",
    "Path": "/api/vcenter/trusted-infrastructure/hosts/{host}/hardware/tpm",
    "Tags": "Tpm",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateVmGuestFilesystem",
    "CommandInfo": "Invoke-CreateVmGuestFilesystem",
    "ApiName": "TransfersApi",
    "Path": "/api/vcenter/vm/{vm}/guest/filesystem__action=create",
    "Tags": "Transfers",
    "RelatedCommandInfos": "Initialize-VmGuestFilesystemTransfersCreateRequestBody",
    "Method": "POST"
  },
  {
    "Name": "CancelClusterConfigurationTransition",
    "CommandInfo": "Invoke-CancelClusterConfigurationTransition",
    "ApiName": "TransitionApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/configuration/transition__action=cancel",
    "Tags": "Transition",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CheckEligibilityClusterConfigurationTransitionAsync",
    "CommandInfo": "Invoke-CheckEligibilityClusterConfigurationTransitionAsync",
    "ApiName": "TransitionApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/configuration/transition__action=checkEligibility&vmw-task=true",
    "Tags": "Transition",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "EnableClusterConfigurationTransitionAsync",
    "CommandInfo": "Invoke-EnableClusterConfigurationTransitionAsync",
    "ApiName": "TransitionApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/configuration/transition__action=enable&vmw-task=true",
    "Tags": "Transition",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ExportConfigClusterConfigurationTransition",
    "CommandInfo": "Invoke-ExportConfigClusterConfigurationTransition",
    "ApiName": "TransitionApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/configuration/transition__action=exportConfig",
    "Tags": "Transition",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ExportSchemaClusterConfigurationTransition",
    "CommandInfo": "Invoke-ExportSchemaClusterConfigurationTransition",
    "ApiName": "TransitionApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/configuration/transition__action=exportSchema",
    "Tags": "Transition",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetClusterEnablementConfigurationTransition",
    "CommandInfo": "Invoke-GetClusterEnablementConfigurationTransition",
    "ApiName": "TransitionApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/configuration/transition",
    "Tags": "Transition",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ImportFromFileClusterConfigurationTransition",
    "CommandInfo": "Invoke-ImportFromFileClusterConfigurationTransition",
    "ApiName": "TransitionApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/configuration/transition__action=importFromFile",
    "Tags": "Transition",
    "RelatedCommandInfos": "Initialize-SettingsClustersEnablementConfigurationTransitionFileSpec",
    "Method": "POST"
  },
  {
    "Name": "ImportFromHostClusterConfigurationTransitionAsync",
    "CommandInfo": "Invoke-ImportFromHostClusterConfigurationTransitionAsync",
    "ApiName": "TransitionApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/configuration/transition__action=importFromHost&vmw-task=true",
    "Tags": "Transition",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "PrecheckClusterConfigurationTransitionAsync",
    "CommandInfo": "Invoke-PrecheckClusterConfigurationTransitionAsync",
    "ApiName": "TransitionApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/configuration/transition__action=precheck&vmw-task=true",
    "Tags": "Transition",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "ValidateConfigClusterConfigurationTransitionAsync",
    "CommandInfo": "Invoke-ValidateConfigClusterConfigurationTransitionAsync",
    "ApiName": "TransitionApi",
    "Path": "/api/esx/settings/clusters/{cluster}/enablement/configuration/transition__action=validateConfig&vmw-task=true",
    "Tags": "Transition",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetClusterTrustedInfrastructureTrustAuthorityClusters",
    "CommandInfo": "Invoke-GetClusterTrustedInfrastructureTrustAuthorityClusters",
    "ApiName": "TrustAuthorityClustersApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}",
    "Tags": "TrustAuthorityClusters",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListTrustedInfrastructureTrustAuthorityClusters",
    "CommandInfo": "Invoke-ListTrustedInfrastructureTrustAuthorityClusters",
    "ApiName": "TrustAuthorityClustersApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters",
    "Tags": "TrustAuthorityClusters",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateClusterAsync",
    "CommandInfo": "Invoke-UpdateClusterAsync",
    "ApiName": "TrustAuthorityClustersApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}__vmw-task=true",
    "Tags": "TrustAuthorityClusters",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityClustersUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "CreateContentTrustedCertificates",
    "CommandInfo": "Invoke-CreateContentTrustedCertificates",
    "ApiName": "TrustedCertificatesApi",
    "Path": "/api/content/trusted-certificates",
    "Tags": "TrustedCertificates",
    "RelatedCommandInfos": "Initialize-TrustedCertificatesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteCertificateContentTrustedCertificates",
    "CommandInfo": "Invoke-DeleteCertificateContentTrustedCertificates",
    "ApiName": "TrustedCertificatesApi",
    "Path": "/api/content/trusted-certificates/{certificate}",
    "Tags": "TrustedCertificates",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetCertificateContentTrustedCertificates",
    "CommandInfo": "Invoke-GetCertificateContentTrustedCertificates",
    "ApiName": "TrustedCertificatesApi",
    "Path": "/api/content/trusted-certificates/{certificate}",
    "Tags": "TrustedCertificates",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListContentTrustedCertificates",
    "CommandInfo": "Invoke-ListContentTrustedCertificates",
    "ApiName": "TrustedCertificatesApi",
    "Path": "/api/content/trusted-certificates",
    "Tags": "TrustedCertificates",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetClusterProviderPeerCertsTrustedAsync",
    "CommandInfo": "Invoke-GetClusterProviderPeerCertsTrustedAsync",
    "ApiName": "TrustedPeerCertificatesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}/peer-certs/trusted__vmw-task=true",
    "Tags": "TrustedPeerCertificates",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateClusterProviderPeerCertsTrustedAsync",
    "CommandInfo": "Invoke-UpdateClusterProviderPeerCertsTrustedAsync",
    "ApiName": "TrustedPeerCertificatesApi",
    "Path": "/api/vcenter/trusted-infrastructure/trust-authority-clusters/{cluster}/kms/providers/{provider}/peer-certs/trusted__vmw-task=true",
    "Tags": "TrustedPeerCertificates",
    "RelatedCommandInfos": "Initialize-TrustedInfrastructureTrustAuthorityClustersKmsProvidersTrustedPeerCertificatesUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "CreateCertificateManagementTrustedRootChains",
    "CommandInfo": "Invoke-CreateCertificateManagementTrustedRootChains",
    "ApiName": "TrustedRootChainsApi",
    "Path": "/api/vcenter/certificate-management/vcenter/trusted-root-chains",
    "Tags": "TrustedRootChains",
    "RelatedCommandInfos": "Initialize-CertificateManagementVcenterTrustedRootChainsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteChainCertificateManagementTrustedRootChains",
    "CommandInfo": "Invoke-DeleteChainCertificateManagementTrustedRootChains",
    "ApiName": "TrustedRootChainsApi",
    "Path": "/api/vcenter/certificate-management/vcenter/trusted-root-chains/{chain}",
    "Tags": "TrustedRootChains",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetChainCertificateManagementTrustedRootChains",
    "CommandInfo": "Invoke-GetChainCertificateManagementTrustedRootChains",
    "ApiName": "TrustedRootChainsApi",
    "Path": "/api/vcenter/certificate-management/vcenter/trusted-root-chains/{chain}",
    "Tags": "TrustedRootChains",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListCertificateManagementTrustedRootChains",
    "CommandInfo": "Invoke-ListCertificateManagementTrustedRootChains",
    "ApiName": "TrustedRootChainsApi",
    "Path": "/api/vcenter/certificate-management/vcenter/trusted-root-chains",
    "Tags": "TrustedRootChains",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListContentType",
    "CommandInfo": "Invoke-ListContentType",
    "ApiName": "TypeApi",
    "Path": "/api/content/type",
    "Tags": "Type",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "DeleteDepotsUmds",
    "CommandInfo": "Invoke-DeleteDepotsUmds",
    "ApiName": "UmdsApi",
    "Path": "/api/esx/settings/depots/umds",
    "Tags": "Umds",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteDepotsUmdsAsync",
    "CommandInfo": "Invoke-DeleteDepotsUmdsAsync",
    "ApiName": "UmdsApi",
    "Path": "/api/esx/settings/depots/umds__vmw-task=true",
    "Tags": "Umds",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetDepotsUmds",
    "CommandInfo": "Invoke-GetDepotsUmds",
    "ApiName": "UmdsApi",
    "Path": "/api/esx/settings/depots/umds",
    "Tags": "Umds",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "SetDepotsUmds",
    "CommandInfo": "Invoke-SetDepotsUmds",
    "ApiName": "UmdsApi",
    "Path": "/api/esx/settings/depots/umds",
    "Tags": "Umds",
    "RelatedCommandInfos": "Initialize-SettingsDepotsUmdsSetSpec",
    "Method": "PUT"
  },
  {
    "Name": "UpdateDepotsUmds",
    "CommandInfo": "Invoke-UpdateDepotsUmds",
    "ApiName": "UmdsApi",
    "Path": "/api/esx/settings/depots/umds",
    "Tags": "Umds",
    "RelatedCommandInfos": "Initialize-SettingsDepotsUmdsUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "CancelUpdate",
    "CommandInfo": "Invoke-CancelUpdate",
    "ApiName": "UpdateApi",
    "Path": "/api/appliance/update__action=cancel",
    "Tags": "Update",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "GetUpdate",
    "CommandInfo": "Invoke-GetUpdate",
    "ApiName": "UpdateApi",
    "Path": "/api/appliance/update",
    "Tags": "Update",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CancelUpdateSessionId",
    "CommandInfo": "Invoke-CancelUpdateSessionId",
    "ApiName": "UpdateSessionApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}__action=cancel",
    "Tags": "UpdateSession",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CompleteUpdateSessionId",
    "CommandInfo": "Invoke-CompleteUpdateSessionId",
    "ApiName": "UpdateSessionApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}__action=complete",
    "Tags": "UpdateSession",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateLibraryItemUpdateSession",
    "CommandInfo": "Invoke-CreateLibraryItemUpdateSession",
    "ApiName": "UpdateSessionApi",
    "Path": "/api/content/library/item/update-session",
    "Tags": "UpdateSession",
    "RelatedCommandInfos": "Initialize-LibraryItemUpdateSessionModel",
    "Method": "POST"
  },
  {
    "Name": "DeleteUpdateSessionIdItem",
    "CommandInfo": "Invoke-DeleteUpdateSessionIdItem",
    "ApiName": "UpdateSessionApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}",
    "Tags": "UpdateSession",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "FailUpdateSessionId",
    "CommandInfo": "Invoke-FailUpdateSessionId",
    "ApiName": "UpdateSessionApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}__action=fail",
    "Tags": "UpdateSession",
    "RelatedCommandInfos": "Initialize-LibraryItemUpdateSessionFailRequestBody",
    "Method": "POST"
  },
  {
    "Name": "GetUpdateSessionIdItem",
    "CommandInfo": "Invoke-GetUpdateSessionIdItem",
    "ApiName": "UpdateSessionApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}",
    "Tags": "UpdateSession",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "KeepAliveUpdateSessionId",
    "CommandInfo": "Invoke-KeepAliveUpdateSessionId",
    "ApiName": "UpdateSessionApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}__action=keep-alive",
    "Tags": "UpdateSession",
    "RelatedCommandInfos": "Initialize-LibraryItemUpdateSessionKeepAliveRequestBody",
    "Method": "POST"
  },
  {
    "Name": "ListLibraryItemUpdateSession",
    "CommandInfo": "Invoke-ListLibraryItemUpdateSession",
    "ApiName": "UpdateSessionApi",
    "Path": "/api/content/library/item/update-session",
    "Tags": "UpdateSession",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateUpdateSessionIdItem",
    "CommandInfo": "Invoke-UpdateUpdateSessionIdItem",
    "ApiName": "UpdateSessionApi",
    "Path": "/api/content/library/item/update-session/{update_session_id}",
    "Tags": "UpdateSession",
    "RelatedCommandInfos": "Initialize-LibraryItemUpdateSessionModel",
    "Method": "PATCH"
  },
  {
    "Name": "CancelDeploymentUpgrade",
    "CommandInfo": "Invoke-CancelDeploymentUpgrade",
    "ApiName": "UpgradeApi",
    "Path": "/api/vcenter/deployment/upgrade__action=cancel",
    "Tags": "Upgrade",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CheckDeploymentUpgrade",
    "CommandInfo": "Invoke-CheckDeploymentUpgrade",
    "ApiName": "UpgradeApi",
    "Path": "/api/vcenter/deployment/upgrade__action=check",
    "Tags": "Upgrade",
    "RelatedCommandInfos": "Initialize-DeploymentUpgradeUpgradeSpec",
    "Method": "POST"
  },
  {
    "Name": "GetDeploymentUpgrade",
    "CommandInfo": "Invoke-GetDeploymentUpgrade",
    "ApiName": "UpgradeApi",
    "Path": "/api/vcenter/deployment/upgrade",
    "Tags": "Upgrade",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "StartDeploymentUpgrade",
    "CommandInfo": "Invoke-StartDeploymentUpgrade",
    "ApiName": "UpgradeApi",
    "Path": "/api/vcenter/deployment/upgrade__action=start",
    "Tags": "Upgrade",
    "RelatedCommandInfos": "Initialize-DeploymentUpgradeUpgradeSpec",
    "Method": "POST"
  },
  {
    "Name": "GetSystemUptime",
    "CommandInfo": "Invoke-GetSystemUptime",
    "ApiName": "UptimeApi",
    "Path": "/api/appliance/system/uptime",
    "Tags": "Uptime",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateClusterStorageDeviceOverridesVcgEntriesAsync",
    "CommandInfo": "Invoke-UpdateClusterStorageDeviceOverridesVcgEntriesAsync",
    "ApiName": "VcgEntriesApi",
    "Path": "/api/esx/settings/clusters/{cluster}/software/reports/hardware-compatibility/storage-device-overrides/vcg-entries__vmw-task=true",
    "Tags": "VcgEntries",
    "RelatedCommandInfos": "Initialize-SettingsClustersSoftwareReportsHardwareCompatibilityStorageDeviceOverridesVcgEntriesUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "GetSystemVersion",
    "CommandInfo": "Invoke-GetSystemVersion",
    "ApiName": "VersionApi",
    "Path": "/api/appliance/system/version",
    "Tags": "Version",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "CreateSupervisorServiceNamespaceManagementVersions",
    "CommandInfo": "Invoke-CreateSupervisorServiceNamespaceManagementVersions",
    "ApiName": "VersionsApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services/{supervisor_service}/versions",
    "Tags": "Versions",
    "RelatedCommandInfos": "Initialize-NamespaceManagementSupervisorServicesVersionsCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteSupervisorServiceVersionNamespaceManagement",
    "CommandInfo": "Invoke-DeleteSupervisorServiceVersionNamespaceManagement",
    "ApiName": "VersionsApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services/{supervisor_service}/versions/{version}",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "DeleteTemplateLibraryItemVersionVmTemplate",
    "CommandInfo": "Invoke-DeleteTemplateLibraryItemVersionVmTemplate",
    "ApiName": "VersionsApi",
    "Path": "/api/vcenter/vm-template/library-items/{template_library_item}/versions/{version}",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetManagerPkgVersionPackages",
    "CommandInfo": "Invoke-GetManagerPkgVersionPackages",
    "ApiName": "VersionsApi",
    "Path": "/api/esx/settings/hardware-support/managers/{manager}/packages/{pkg}/versions/{version}",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetNameVersionAddOns",
    "CommandInfo": "Invoke-GetNameVersionAddOns",
    "ApiName": "VersionsApi",
    "Path": "/api/esx/settings/depot-content/add-ons/{name}/versions/{version}",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetNameVersionComponents",
    "CommandInfo": "Invoke-GetNameVersionComponents",
    "ApiName": "VersionsApi",
    "Path": "/api/esx/settings/depot-content/components/{name}/versions/{version}",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetSupervisorServiceVersionNamespaceManagement",
    "CommandInfo": "Invoke-GetSupervisorServiceVersionNamespaceManagement",
    "ApiName": "VersionsApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services/{supervisor_service}/versions/{version}",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetTemplateLibraryItemVersionVmTemplate",
    "CommandInfo": "Invoke-GetTemplateLibraryItemVersionVmTemplate",
    "ApiName": "VersionsApi",
    "Path": "/api/vcenter/vm-template/library-items/{template_library_item}/versions/{version}",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "GetVersionBaseImages",
    "CommandInfo": "Invoke-GetVersionBaseImages",
    "ApiName": "VersionsApi",
    "Path": "/api/esx/settings/depot-content/base-images/versions/{version}",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListSupervisorServiceNamespaceManagementVersions",
    "CommandInfo": "Invoke-ListSupervisorServiceNamespaceManagementVersions",
    "ApiName": "VersionsApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services/{supervisor_service}/versions",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListTemplateLibraryItemVmTemplateVersions",
    "CommandInfo": "Invoke-ListTemplateLibraryItemVmTemplateVersions",
    "ApiName": "VersionsApi",
    "Path": "/api/vcenter/vm-template/library-items/{template_library_item}/versions",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RollbackTemplateLibraryItemVersion",
    "CommandInfo": "Invoke-RollbackTemplateLibraryItemVersion",
    "ApiName": "VersionsApi",
    "Path": "/api/vcenter/vm-template/library-items/{template_library_item}/versions/{version}__action=rollback",
    "Tags": "Versions",
    "RelatedCommandInfos": "Initialize-VmTemplateLibraryItemsVersionsRollbackSpec",
    "Method": "POST"
  },
  {
    "Name": "UpdateSupervisorServiceVersion",
    "CommandInfo": "Invoke-UpdateSupervisorServiceVersion",
    "ApiName": "VersionsApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services/{supervisor_service}/versions/{version}__action=activate",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "PATCH"
  },
  {
    "Name": "UpdateSupervisorServiceVersion_0",
    "CommandInfo": "Invoke-UpdateSupervisorServiceVersion_0",
    "ApiName": "VersionsApi",
    "Path": "/api/vcenter/namespace-management/supervisor-services/{supervisor_service}/versions/{version}__action=deactivate",
    "Tags": "Versions",
    "RelatedCommandInfos": "",
    "Method": "PATCH"
  },
  {
    "Name": "CreateNamespaceManagementVirtualMachineClasses",
    "CommandInfo": "Invoke-CreateNamespaceManagementVirtualMachineClasses",
    "ApiName": "VirtualMachineClassesApi",
    "Path": "/api/vcenter/namespace-management/virtual-machine-classes",
    "Tags": "VirtualMachineClasses",
    "RelatedCommandInfos": "Initialize-NamespaceManagementVirtualMachineClassesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVmClassNamespaceManagementVirtualMachineClasses",
    "CommandInfo": "Invoke-DeleteVmClassNamespaceManagementVirtualMachineClasses",
    "ApiName": "VirtualMachineClassesApi",
    "Path": "/api/vcenter/namespace-management/virtual-machine-classes/{vm_class}",
    "Tags": "VirtualMachineClasses",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetVmClassNamespaceManagementVirtualMachineClasses",
    "CommandInfo": "Invoke-GetVmClassNamespaceManagementVirtualMachineClasses",
    "ApiName": "VirtualMachineClassesApi",
    "Path": "/api/vcenter/namespace-management/virtual-machine-classes/{vm_class}",
    "Tags": "VirtualMachineClasses",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListNamespaceManagementVirtualMachineClasses",
    "CommandInfo": "Invoke-ListNamespaceManagementVirtualMachineClasses",
    "ApiName": "VirtualMachineClassesApi",
    "Path": "/api/vcenter/namespace-management/virtual-machine-classes",
    "Tags": "VirtualMachineClasses",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "UpdateVmClassNamespaceManagementVirtualMachineClasses",
    "CommandInfo": "Invoke-UpdateVmClassNamespaceManagementVirtualMachineClasses",
    "ApiName": "VirtualMachineClassesApi",
    "Path": "/api/vcenter/namespace-management/virtual-machine-classes/{vm_class}",
    "Tags": "VirtualMachineClasses",
    "RelatedCommandInfos": "Initialize-NamespaceManagementVirtualMachineClassesUpdateSpec",
    "Method": "PATCH"
  },
  {
    "Name": "CloneVm",
    "CommandInfo": "Invoke-CloneVm",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/vm__action=clone",
    "Tags": "Vm",
    "RelatedCommandInfos": "Initialize-VMCloneSpec",
    "Method": "POST"
  },
  {
    "Name": "CloneVmAsync",
    "CommandInfo": "Invoke-CloneVmAsync",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/vm__action=clone&vmw-task=true",
    "Tags": "Vm",
    "RelatedCommandInfos": "Initialize-VMCloneSpec",
    "Method": "POST"
  },
  {
    "Name": "CreateVm",
    "CommandInfo": "Invoke-CreateVm",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/vm",
    "Tags": "Vm",
    "RelatedCommandInfos": "Initialize-VMCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteVm",
    "CommandInfo": "Invoke-DeleteVm",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/vm/{vm}",
    "Tags": "Vm",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetVm",
    "CommandInfo": "Invoke-GetVm",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/vm/{vm}",
    "Tags": "Vm",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "InstantCloneVm",
    "CommandInfo": "Invoke-InstantCloneVm",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/vm__action=instant-clone",
    "Tags": "Vm",
    "RelatedCommandInfos": "Initialize-VMInstantCloneSpec",
    "Method": "POST"
  },
  {
    "Name": "ListPoliciesComplianceVm",
    "CommandInfo": "Invoke-ListPoliciesComplianceVm",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/storage/policies/compliance/vm",
    "Tags": "Vm",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListPolicyPoliciesVm",
    "CommandInfo": "Invoke-ListPolicyPoliciesVm",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/storage/policies/{policy}/vm",
    "Tags": "Vm",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListVm",
    "CommandInfo": "Invoke-ListVm",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/vm",
    "Tags": "Vm",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "RegisterVm",
    "CommandInfo": "Invoke-RegisterVm",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/vm__action=register",
    "Tags": "Vm",
    "RelatedCommandInfos": "Initialize-VMRegisterSpec",
    "Method": "POST"
  },
  {
    "Name": "RelocateVm",
    "CommandInfo": "Invoke-RelocateVm",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/vm/{vm}__action=relocate",
    "Tags": "Vm",
    "RelatedCommandInfos": "Initialize-VMRelocateSpec",
    "Method": "POST"
  },
  {
    "Name": "RelocateVmAsync",
    "CommandInfo": "Invoke-RelocateVmAsync",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/vm/{vm}__action=relocate&vmw-task=true",
    "Tags": "Vm",
    "RelatedCommandInfos": "Initialize-VMRelocateSpec",
    "Method": "POST"
  },
  {
    "Name": "UnregisterVm",
    "CommandInfo": "Invoke-UnregisterVm",
    "ApiName": "VmApi",
    "Path": "/api/vcenter/vm/{vm}__action=unregister",
    "Tags": "Vm",
    "RelatedCommandInfos": "",
    "Method": "POST"
  },
  {
    "Name": "CreateCertificateManagementVmcaRoot",
    "CommandInfo": "Invoke-CreateCertificateManagementVmcaRoot",
    "ApiName": "VmcaRootApi",
    "Path": "/api/vcenter/certificate-management/vcenter/vmca-root",
    "Tags": "VmcaRoot",
    "RelatedCommandInfos": "Initialize-CertificateManagementVcenterVmcaRootCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "CheckClusterWitness",
    "CommandInfo": "Invoke-CheckClusterWitness",
    "ApiName": "WitnessApi",
    "Path": "/api/vcenter/vcha/cluster/witness__action=check",
    "Tags": "Witness",
    "RelatedCommandInfos": "Initialize-VchaClusterWitnessCheckSpec",
    "Method": "POST"
  },
  {
    "Name": "RedeployClusterWitnessAsync",
    "CommandInfo": "Invoke-RedeployClusterWitnessAsync",
    "ApiName": "WitnessApi",
    "Path": "/api/vcenter/vcha/cluster/witness__action=redeploy&vmw-task=true",
    "Tags": "Witness",
    "RelatedCommandInfos": "Initialize-VchaClusterWitnessRedeploySpec",
    "Method": "POST"
  },
  {
    "Name": "CreateConsumptionDomainsZones",
    "CommandInfo": "Invoke-CreateConsumptionDomainsZones",
    "ApiName": "ZonesApi",
    "Path": "/api/vcenter/consumption-domains/zones",
    "Tags": "Zones",
    "RelatedCommandInfos": "Initialize-ConsumptionDomainsZonesCreateSpec",
    "Method": "POST"
  },
  {
    "Name": "DeleteZoneConsumptionDomains",
    "CommandInfo": "Invoke-DeleteZoneConsumptionDomains",
    "ApiName": "ZonesApi",
    "Path": "/api/vcenter/consumption-domains/zones/{zone}",
    "Tags": "Zones",
    "RelatedCommandInfos": "",
    "Method": "DELETE"
  },
  {
    "Name": "GetZoneConsumptionDomains",
    "CommandInfo": "Invoke-GetZoneConsumptionDomains",
    "ApiName": "ZonesApi",
    "Path": "/api/vcenter/consumption-domains/zones/{zone}",
    "Tags": "Zones",
    "RelatedCommandInfos": "",
    "Method": "GET"
  },
  {
    "Name": "ListConsumptionDomainsZones",
    "CommandInfo": "Invoke-ListConsumptionDomainsZones",
    "ApiName": "ZonesApi",
    "Path": "/api/vcenter/consumption-domains/zones",
    "Tags": "Zones",
    "RelatedCommandInfos": "",
    "Method": "GET"
  }
]
"@