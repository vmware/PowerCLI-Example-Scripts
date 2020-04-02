---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# New-HVFarm

## SYNOPSIS
Creates a new farm.

## SYNTAX

### LINKED_CLONE
```
New-HVFarm [-LinkedClone] -FarmName <String> [-FarmDisplayName <String>] [-Description <String>]
 [-AccessGroup <String>] [-Enable <Boolean>] [-DisconnectedSessionTimeoutPolicy <String>]
 [-DisconnectedSessionTimeoutMinutes <Int32>] [-EmptySessionTimeoutPolicy <String>]
 [-EmptySessionTimeoutMinutes <Int32>] [-LogoffAfterTimeout <Boolean>] [-DefaultDisplayProtocol <String>]
 [-AllowDisplayProtocolOverride <Boolean>] [-EnableHTMLAccess <Boolean>] [-EnableCollaboration <Boolean>]
 [-EnableGRIDvGPUs <Boolean>] [-VGPUGridProfile <String>] [-ServerErrorThreshold <Object>]
 [-OverrideGlobalSetting <Boolean>] [-MirageServerEnabled <Boolean>] [-Url <String>] [-Vcenter <String>]
 -ParentVM <String> -SnapshotVM <String> -VmFolder <String> -HostOrCluster <String> -ResourcePool <String>
 [-dataCenter <String>] -Datastores <String[]> [-StorageOvercommit <String[]>] [-UseVSAN <Boolean>]
 [-EnableProvisioning <Boolean>] [-StopProvisioningOnError <Boolean>] [-TransparentPageSharingScope <String>]
 [-NamingMethod <String>] [-NamingPattern <String>] [-MinReady <Int32>] [-MaximumCount <Int32>]
 [-UseSeparateDatastoresReplicaAndOSDisks <Boolean>] [-ReplicaDiskDatastore <String>]
 [-UseNativeSnapshots <Boolean>] [-ReclaimVmDiskSpace <Boolean>] [-ReclamationThresholdGB <Int32>]
 [-BlackoutTimes <FarmBlackoutTime[]>] [-AdContainer <String>] -NetBiosName <String> [-DomainAdmin <String>]
 [-ReusePreExistingAccounts <Boolean>] -SysPrepName <String> [-MaxSessionsType <String>] [-MaxSessions <Int32>]
 [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### INSTANT_CLONE
```
New-HVFarm [-InstantClone] -FarmName <String> [-FarmDisplayName <String>] [-Description <String>]
 [-AccessGroup <String>] [-Enable <Boolean>] [-DisconnectedSessionTimeoutPolicy <String>]
 [-DisconnectedSessionTimeoutMinutes <Int32>] [-EmptySessionTimeoutPolicy <String>]
 [-EmptySessionTimeoutMinutes <Int32>] [-LogoffAfterTimeout <Boolean>] [-DefaultDisplayProtocol <String>]
 [-AllowDisplayProtocolOverride <Boolean>] [-EnableHTMLAccess <Boolean>] [-EnableCollaboration <Boolean>]
 [-EnableGRIDvGPUs <Boolean>] [-VGPUGridProfile <String>] [-ServerErrorThreshold <Object>]
 [-OverrideGlobalSetting <Boolean>] [-MirageServerEnabled <Boolean>] [-Url <String>] [-Vcenter <String>]
 -ParentVM <String> -SnapshotVM <String> -VmFolder <String> -HostOrCluster <String> -ResourcePool <String>
 [-dataCenter <String>] -Datastores <String[]> [-StorageOvercommit <String[]>] [-UseVSAN <Boolean>]
 [-EnableProvisioning <Boolean>] [-StopProvisioningOnError <Boolean>] [-TransparentPageSharingScope <String>]
 [-NamingMethod <String>] [-NamingPattern <String>] [-MinReady <Int32>] [-MaximumCount <Int32>]
 [-UseSeparateDatastoresReplicaAndOSDisks <Boolean>] [-ReplicaDiskDatastore <String>]
 [-UseNativeSnapshots <Boolean>] [-ReclaimVmDiskSpace <Boolean>] [-AdContainer <String>] -NetBiosName <String>
 [-DomainAdmin <String>] [-PowerOffScriptName <String>] [-PowerOffScriptParameters <String>]
 [-PostSynchronizationScriptName <String>] [-PostSynchronizationScriptParameters <String>]
 [-MaxSessionsType <String>] [-MaxSessions <Int32>] [-HvServer <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### MANUAL
```
New-HVFarm [-Manual] -FarmName <String> [-FarmDisplayName <String>] [-Description <String>]
 [-AccessGroup <String>] [-Enable <Boolean>] [-DisconnectedSessionTimeoutPolicy <String>]
 [-DisconnectedSessionTimeoutMinutes <Int32>] [-EmptySessionTimeoutPolicy <String>]
 [-EmptySessionTimeoutMinutes <Int32>] [-LogoffAfterTimeout <Boolean>] [-DefaultDisplayProtocol <String>]
 [-AllowDisplayProtocolOverride <Boolean>] [-EnableHTMLAccess <Boolean>] [-EnableCollaboration <Boolean>]
 [-EnableGRIDvGPUs <Boolean>] [-VGPUGridProfile <String>] [-ServerErrorThreshold <Object>]
 [-OverrideGlobalSetting <Boolean>] [-MirageServerEnabled <Boolean>] [-Url <String>] -RdsServers <String[]>
 [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### JSON_FILE
```
New-HVFarm [-FarmName <String>] [-FarmDisplayName <String>] [-Description <String>] [-AccessGroup <String>]
 [-Enable <Boolean>] [-DisconnectedSessionTimeoutPolicy <String>] [-DisconnectedSessionTimeoutMinutes <Int32>]
 [-EmptySessionTimeoutPolicy <String>] [-EmptySessionTimeoutMinutes <Int32>] [-LogoffAfterTimeout <Boolean>]
 [-DefaultDisplayProtocol <String>] [-AllowDisplayProtocolOverride <Boolean>] [-EnableHTMLAccess <Boolean>]
 [-EnableCollaboration <Boolean>] [-EnableGRIDvGPUs <Boolean>] [-VGPUGridProfile <String>]
 [-ServerErrorThreshold <Object>] [-OverrideGlobalSetting <Boolean>] [-MirageServerEnabled <Boolean>]
 [-Url <String>] [-NamingPattern <String>] [-Spec <String>] [-HvServer <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a new farm, the type would be determined based on input parameters.

## EXAMPLES

### EXAMPLE 1
```
New-HVFarm -LinkedClone -FarmName 'LCFarmTest' -ParentVM 'Win_Server_2012_R2' -SnapshotVM 'Snap_RDS' -VmFolder 'PoolVM' -HostOrCluster 'cls' -ResourcePool 'cls' -Datastores 'datastore1 (5)' -FarmDisplayName 'LC Farm Test' -Description 'created LC Farm from PS' -EnableProvisioning $true -StopProvisioningOnError $false -NamingPattern "LCFarmVM_PS" -MinReady 1 -MaximumCount 1  -SysPrepName "RDSH_Cust2" -NetBiosName "adviewdev"
```

Creates new linkedClone farm by using naming pattern

### EXAMPLE 2
```
New-HVFarm -InstantClone -FarmName 'ICFarmCL' -ParentVM 'vm-rdsh-ic' -SnapshotVM 'Snap_5' -VmFolder 'Instant_Clone_VMs' -HostOrCluster 'vimal-cluster' -ResourcePool 'vimal-cluster' -Datastores 'datastore1' -FarmDisplayName 'IC Farm using CL' -Description 'created IC Farm from PS command-line' -EnableProvisioning $true -StopProvisioningOnError $false -NamingPattern "ICFarmCL-" -NetBiosName "ad-vimalg"
```

Creates new linkedClone farm by using naming pattern

### EXAMPLE 3
```
New-HVFarm -Spec C:\VMWare\Specs\LinkedClone.json -Confirm:$false
```

Creates new linkedClone farm by using json file

### EXAMPLE 4
```
New-HVFarm -Spec C:\VMWare\Specs\InstantCloneFarm.json -Confirm:$false
```

Creates new instantClone farm by using json file

### EXAMPLE 5
```
New-HVFarm -Manual -FarmName "manualFarmTest" -FarmDisplayName "manualFarmTest" -Description "Manual PS Test" -RdsServers "vm-for-rds.eng.vmware.com","vm-for-rds-2.eng.vmware.com" -Confirm:$false
```

Creates new manual farm by using rdsServers names

### EXAMPLE 6
```
New-HVFarm -Spec C:\VMWare\Specs\AutomatedInstantCloneFarm.json -FarmName 'InsPool' -NamingPattern 'InsFarm-'
```

Creates new instant clone farm by reading few parameters from json and few parameters from command line.

## PARAMETERS

### -LinkedClone
Switch to Create Automated Linked Clone farm.

```yaml
Type: SwitchParameter
Parameter Sets: LINKED_CLONE
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstantClone
Switch to Create Automated Instant Clone farm.

```yaml
Type: SwitchParameter
Parameter Sets: INSTANT_CLONE
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Manual
Switch to Create Manual farm.

```yaml
Type: SwitchParameter
Parameter Sets: MANUAL
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -FarmName
Name of the farm.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE, MANUAL
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: JSON_FILE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FarmDisplayName
Display name of the farm.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $farmName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Description of the farm.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccessGroup
View access group can organize the servers in the farm.
Default Value is 'Root'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Root
Accept pipeline input: False
Accept wildcard characters: False
```

### -Enable
Set true to enable the farm otherwise set to false.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisconnectedSessionTimeoutPolicy
farmSpec.data.settings.disconnectedSessionTimeoutPolicy

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: NEVER
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisconnectedSessionTimeoutMinutes
farmSpec.data.settings.disconnectedSessionTimeoutMinutes

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmptySessionTimeoutPolicy
farmSpec.data.settings.emptySessionTimeoutPolicy

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: AFTER
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmptySessionTimeoutMinutes
farmSpec.data.settings.emptySessionTimeoutMinutes

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogoffAfterTimeout
farmSpec.data.settings.logoffAfterTimeout

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultDisplayProtocol
farmSpec.data.displayProtocolSettings.defaultDisplayProtocol

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: PCOIP
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowDisplayProtocolOverride
farmSpec.data.displayProtocolSettings.allowDisplayProtocolOverride

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableHTMLAccess
farmSpec.data.displayProtocolSettings.enableHTMLAccess

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableCollaboration
farmSpec.data.displayProtocolSettings.EnableCollaboration

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableGRIDvGPUs
farmSpec.data.displayProtocolSettings.EnableGRIDvGPUs

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VGPUGridProfile
farmSpec.data.displayProtocolSettings.VGPUGridProfile

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServerErrorThreshold
farmSpec.data.serverErrorThreshold

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -OverrideGlobalSetting
farmSpec.data.mirageConfigurationOverrides.overrideGlobalSetting

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -MirageServerEnabled
farmSpec.data.mirageConfigurationOverrides.enabled

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Url
farmSpec.data.mirageConfigurationOverrides.url

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Vcenter
Virtual Center server-address (IP or FQDN) where the farm RDS Servers are located.
This should be same as provided to the Connection Server while adding the vCenter server.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParentVM
Base image VM for RDS Servers.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SnapshotVM
Base image snapshot for RDS Servers.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VmFolder
VM folder to deploy the RDSServers to.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HostOrCluster
Host or cluster to deploy the RDSServers in.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourcePool
Resource pool to deploy the RDSServers.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -dataCenter
farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.dataCenter if LINKED_CLONE, INSTANT_CLONE

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Datastores
Datastore names to store the RDSServer.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: String[]
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StorageOvercommit
farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.datastores.storageOvercommit if LINKED_CLONE, INSTANT_CLONE

```yaml
Type: String[]
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseVSAN
Whether to use vSphere VSAN.
This is applicable for vSphere 5.5 or later.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: Boolean
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableProvisioning
Set to true to enable provision of RDSServers immediately in farm.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: Boolean
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -StopProvisioningOnError
Set to true to stop provisioning of all RDSServers on error.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: Boolean
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -TransparentPageSharingScope
The transparent page sharing scope.
The default value is 'VM'.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: VM
Accept pipeline input: False
Accept wildcard characters: False
```

### -NamingMethod
Determines how the VMs in the farm are named.
Set PATTERN to use naming pattern.
The default value is PATTERN.
Currently only PATTERN is allowed.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: PATTERN
Accept pipeline input: False
Accept wildcard characters: False
```

### -NamingPattern
RDS Servers will be named according to the specified naming pattern.
Value would be considered only when $namingMethod = PATTERN
The default value is farmName + '{n:fixed=4}'.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE, JSON_FILE
Aliases:

Required: False
Position: Named
Default value: $farmName + '{n:fixed=4}'
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinReady
Minimum number of ready (provisioned) Servers during View Composer maintenance operations.
The default value is 0.
Applicable to Linked Clone farms.

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaximumCount
Maximum number of Servers in the farm.
The default value is 1.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseSeparateDatastoresReplicaAndOSDisks
farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.useSeparateDatastoresReplicaAndOSDisks if INSTANT_CLONE, LINKED_CLONE

```yaml
Type: Boolean
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReplicaDiskDatastore
farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.replicaDiskDatastore, if LINKED_CLONE, INSTANT_CLONE

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseNativeSnapshots
farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.useNativeSnapshots, if LINKED_CLONE, INSTANT_CLONE

```yaml
Type: Boolean
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReclaimVmDiskSpace
farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.spaceReclamationSettings.reclaimVmDiskSpace, if LINKED_CLONE, INSTANT_CLONE

```yaml
Type: Boolean
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReclamationThresholdGB
farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.spaceReclamationSettings.reclamationThresholdGB

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -BlackoutTimes
farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.spaceReclamationSettings.blackoutTimes

```yaml
Type: FarmBlackoutTime[]
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdContainer
This is the Active Directory container which the Servers will be added to upon creation.
The default value is 'CN=Computers'.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: CN=Computers
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetBiosName
Domain Net Bios Name.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainAdmin
Domain Administrator user name which will be used to join the domain.
Default value is null.
Applicable to Linked Clone and Instant Clone farms.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReusePreExistingAccounts
farmSpec.automatedfarmSpec.customizationSettings.reusePreExistingAccounts

```yaml
Type: Boolean
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SysPrepName
The customization spec to use.
Applicable to Linked Clone farms.

```yaml
Type: String
Parameter Sets: LINKED_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PowerOffScriptName
Power off script.
ClonePrep can run a customization script on instant-clone machines before they are powered off.
Provide the path to the script on the parent virtual machine.
Applicable to Instant Clone farms.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PowerOffScriptParameters
Power off script parameters.
Example: p1 p2 p3 
Applicable to Instant Clone farms.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PostSynchronizationScriptName
Post synchronization script.
ClonePrep can run a customization script on instant-clone machines after they are created or recovered or a new image is pushed.
Provide the path to the script on the parent virtual machine.
Applicable to Instant Clone farms.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PostSynchronizationScriptParameters
Post synchronization script parameters.
Example: p1 p2 p3 
Applicable to Instant Clone farms.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxSessionsType
farmSpec.automatedfarmSpec.rdsServerMaxSessionsData.maxSessionsType if LINKED_CLONE, INSTANT_CLONE

```yaml
Type: String
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: UNLIMITED
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxSessions
farmSpec.automatedfarmSpec.rdsServerMaxSessionsData.maxSessionsType if LINKED_CLONE, INSTANT_CLONE

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE, INSTANT_CLONE
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -RdsServers
List of existing registered RDS server names to add into manual farm.
Applicable to Manual farms.

```yaml
Type: String[]
Parameter Sets: MANUAL
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Spec
Path of the JSON specification file.

```yaml
Type: String
Parameter Sets: JSON_FILE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HvServer
Reference to Horizon View Server to query the farms from.
If the value is not passed or null then first element from global:DefaultHVServers would be considered in-place of hvServer.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### None
## NOTES
| | |
|-|-|
| Author | praveen mathamsetty. |
| Author email | pmathamsetty@vmware.com |
| Version | 1.1 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.0.2, 7.1.0 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
