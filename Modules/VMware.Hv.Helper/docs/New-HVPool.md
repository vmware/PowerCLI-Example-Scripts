---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# New-HVPool

## SYNOPSIS
Creates new desktop pool.

## SYNTAX

### INSTANT_CLONE
```
New-HVPool [-InstantClone] -PoolName <String> [-PoolDisplayName <String>] [-Description <String>]
 [-AccessGroup <String>] [-GlobalEntitlement <String>] -UserAssignment <String>
 [-AutomaticAssignment <Boolean>] [-Enable <Boolean>] [-ConnectionServerRestrictions <String[]>]
 [-AutomaticLogoffPolicy <String>] [-AutomaticLogoffMinutes <Int32>] [-allowUsersToResetMachines <Boolean>]
 [-allowMultipleSessionsPerUser <Boolean>] [-deleteOrRefreshMachineAfterLogoff <String>]
 [-supportedDisplayProtocols <String[]>] [-defaultDisplayProtocol <String>]
 [-allowUsersToChooseProtocol <Int32>] [-enableHTMLAccess <Boolean>] [-renderer3D <String>] [-Quality <String>]
 [-Throttling <String>] [-Vcenter <String>] -ParentVM <String> -SnapshotVM <String> -VmFolder <String>
 -HostOrCluster <String> -ResourcePool <String> [-datacenter <String>] -Datastores <String[]>
 [-StorageOvercommit <String[]>] [-UseVSAN <Boolean>] [-UseSeparateDatastoresReplicaAndOSDisks <Boolean>]
 [-ReplicaDiskDatastore <String>] [-UseNativeSnapshots <Boolean>] [-ReclaimVmDiskSpace <Boolean>]
 [-RedirectWindowsProfile <Boolean>] [-Nics <DesktopNetworkInterfaceCardSettings[]>]
 [-EnableProvisioning <Boolean>] [-StopProvisioningOnError <Boolean>] [-TransparentPageSharingScope <String>]
 -NamingMethod <String> [-NamingPattern <String>] [-MaximumCount <Int32>] [-SpareCount <Int32>]
 [-ProvisioningTime <String>] [-MinimumCount <Int32>] [-SpecificNames <String[]>]
 [-StartInMaintenanceMode <Boolean>] [-NumUnassignedMachinesKeptPoweredOn <Int32>] [-AdContainer <Object>]
 -NetBiosName <String> [-DomainAdmin <String>] [-ReusePreExistingAccounts <Boolean>]
 [-PowerOffScriptName <String>] [-PowerOffScriptParameters <String>] [-PostSynchronizationScriptName <String>]
 [-PostSynchronizationScriptParameters <String>] [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### LINKED_CLONE
```
New-HVPool [-LinkedClone] -PoolName <String> [-PoolDisplayName <String>] [-Description <String>]
 [-AccessGroup <String>] [-GlobalEntitlement <String>] -UserAssignment <String>
 [-AutomaticAssignment <Boolean>] [-Enable <Boolean>] [-ConnectionServerRestrictions <String[]>]
 [-PowerPolicy <String>] [-AutomaticLogoffPolicy <String>] [-AutomaticLogoffMinutes <Int32>]
 [-allowUsersToResetMachines <Boolean>] [-allowMultipleSessionsPerUser <Boolean>]
 [-deleteOrRefreshMachineAfterLogoff <String>] [-refreshOsDiskAfterLogoff <String>]
 [-refreshPeriodDaysForReplicaOsDisk <Int32>] [-refreshThresholdPercentageForReplicaOsDisk <Int32>]
 [-supportedDisplayProtocols <String[]>] [-defaultDisplayProtocol <String>]
 [-allowUsersToChooseProtocol <Int32>] [-enableHTMLAccess <Boolean>] [-renderer3D <String>]
 [-enableGRIDvGPUs <Boolean>] [-vRamSizeMB <Int32>] [-maxNumberOfMonitors <Int32>]
 [-maxResolutionOfAnyOneMonitor <String>] [-Quality <String>] [-Throttling <String>]
 [-overrideGlobalSetting <Boolean>] [-enabled <Boolean>] [-url <String>] [-Vcenter <String>] -ParentVM <String>
 -SnapshotVM <String> -VmFolder <String> -HostOrCluster <String> -ResourcePool <String> [-datacenter <String>]
 -Datastores <String[]> [-StorageOvercommit <String[]>] [-UseVSAN <Boolean>]
 [-UseSeparateDatastoresReplicaAndOSDisks <Boolean>] [-ReplicaDiskDatastore <String>]
 [-UseNativeSnapshots <Boolean>] [-ReclaimVmDiskSpace <Boolean>] [-ReclamationThresholdGB <Int32>]
 [-RedirectWindowsProfile <Boolean>] [-UseSeparateDatastoresPersistentAndOSDisks <Boolean>]
 [-PersistentDiskDatastores <String[]>] [-PersistentDiskStorageOvercommit <String[]>] [-DiskSizeMB <Int32>]
 [-DiskDriveLetter <String>] [-redirectDisposableFiles <Boolean>] [-NonPersistentDiskSizeMB <Int32>]
 [-NonPersistentDiskDriveLetter <String>] [-UseViewStorageAccelerator <Boolean>]
 [-ViewComposerDiskTypes <String>] [-RegenerateViewStorageAcceleratorDays <Int32>]
 [-BlackoutTimes <DesktopBlackoutTime[]>] [-Nics <DesktopNetworkInterfaceCardSettings[]>]
 [-EnableProvisioning <Boolean>] [-StopProvisioningOnError <Boolean>] [-TransparentPageSharingScope <String>]
 -NamingMethod <String> [-NamingPattern <String>] [-MinReady <Int32>] [-MaximumCount <Int32>]
 [-SpareCount <Int32>] [-ProvisioningTime <String>] [-MinimumCount <Int32>] [-SpecificNames <String[]>]
 [-StartInMaintenanceMode <Boolean>] [-NumUnassignedMachinesKeptPoweredOn <Int32>] [-AdContainer <Object>]
 [-NetBiosName <String>] [-DomainAdmin <String>] -CustType <String> [-ReusePreExistingAccounts <Boolean>]
 [-SysPrepName <String>] [-PowerOffScriptName <String>] [-PowerOffScriptParameters <String>]
 [-PostSynchronizationScriptName <String>] [-PostSynchronizationScriptParameters <String>] [-HvServer <Object>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### FULL_CLONE
```
New-HVPool [-FullClone] -PoolName <String> [-PoolDisplayName <String>] [-Description <String>]
 [-AccessGroup <String>] [-GlobalEntitlement <String>] -UserAssignment <String>
 [-AutomaticAssignment <Boolean>] [-Enable <Boolean>] [-ConnectionServerRestrictions <String[]>]
 [-Quality <String>] [-Throttling <String>] [-Vcenter <String>] -Template <String> -VmFolder <String>
 -HostOrCluster <String> -ResourcePool <String> [-datacenter <String>] -Datastores <String[]>
 [-StorageOvercommit <String[]>] [-UseVSAN <Boolean>] [-Nics <DesktopNetworkInterfaceCardSettings[]>]
 [-EnableProvisioning <Boolean>] [-StopProvisioningOnError <Boolean>] [-TransparentPageSharingScope <String>]
 -NamingMethod <String> [-NamingPattern <String>] [-MaximumCount <Int32>] [-SpareCount <Int32>]
 [-ProvisioningTime <String>] [-MinimumCount <Int32>] [-SpecificNames <String[]>]
 [-StartInMaintenanceMode <Boolean>] [-NumUnassignedMachinesKeptPoweredOn <Int32>] [-NetBiosName <String>]
 -CustType <String> [-SysPrepName <String>] [-DoNotPowerOnVMsAfterCreation <Boolean>] [-HvServer <Object>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### MANUAL
```
New-HVPool [-Manual] -PoolName <String> [-PoolDisplayName <String>] [-Description <String>]
 [-AccessGroup <String>] [-GlobalEntitlement <String>] -UserAssignment <String>
 [-AutomaticAssignment <Boolean>] [-Enable <Boolean>] [-ConnectionServerRestrictions <String[]>]
 [-allowUsersToResetMachines <Boolean>] [-supportedDisplayProtocols <String[]>]
 [-defaultDisplayProtocol <String>] [-allowUsersToChooseProtocol <Int32>] [-enableHTMLAccess <Boolean>]
 [-Quality <String>] [-Throttling <String>] [-Vcenter <String>] [-TransparentPageSharingScope <String>]
 -Source <String> -VM <String[]> [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### RDS
```
New-HVPool [-Rds] -PoolName <String> [-PoolDisplayName <String>] [-Description <String>]
 [-AccessGroup <String>] [-GlobalEntitlement <String>] [-Enable <Boolean>]
 [-ConnectionServerRestrictions <String[]>] [-Farm <String>] [-HvServer <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### JSON_FILE
```
New-HVPool -Spec <String> [-PoolName <String>] [-PoolDisplayName <String>] [-Description <String>]
 [-AccessGroup <String>] [-GlobalEntitlement <String>] [-Enable <Boolean>]
 [-ConnectionServerRestrictions <String[]>] [-NamingPattern <String>]
 [-NumUnassignedMachinesKeptPoweredOn <Int32>] [-VM <String[]>] [-HvServer <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### CLONED_POOL
```
New-HVPool -ClonePool <Object> -PoolName <String> [-PoolDisplayName <String>] [-Description <String>]
 [-AccessGroup <String>] [-GlobalEntitlement <String>] [-Enable <Boolean>]
 [-ConnectionServerRestrictions <String[]>] [-NamingMethod <String>] [-NamingPattern <String>]
 [-SpecificNames <String[]>] [-VM <String[]>] [-Farm <String>] [-HvServer <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Creates new desktop pool, the type and user assignment type would be
determined based on input parameters.

## EXAMPLES

### EXAMPLE 1
```
New-HVPool -LinkedClone -PoolName 'vmwarepool' -UserAssignment FLOATING -ParentVM 'Agent_vmware' -SnapshotVM 'kb-hotfix' -VmFolder 'vmware' -HostOrCluster 'CS-1' -ResourcePool 'CS-1' -Datastores 'datastore1' -NamingMethod PATTERN -PoolDisplayName 'vmware linkedclone pool' -Description  'created linkedclone pool from ps' -EnableProvisioning $true -StopProvisioningOnError $false -NamingPattern  "vmware2" -MinReady 0 -MaximumCount 1 -SpareCount 1 -ProvisioningTime UP_FRONT -SysPrepName vmwarecust -CustType SYS_PREP -NetBiosName adviewdev -DomainAdmin root
```

Create new automated linked clone pool with naming method pattern

### EXAMPLE 2
```
New-HVPool -Spec C:\VMWare\Specs\LinkedClone.json -Confirm:$false
```

Create new automated linked clone pool by using JSON spec file

### EXAMPLE 3
```
Get-HVPool -PoolName 'vmwarepool' | New-HVPool -PoolName 'clonedPool' -NamingPattern 'clonelnk1';
```

(OR)
$vmwarepool = Get-HVPool -PoolName 'vmwarepool';  New-HVPool -ClonePool $vmwarepool -PoolName 'clonedPool' -NamingPattern 'clonelnk1';
Clones new pool by using existing pool configuration

### EXAMPLE 4
```
New-HVPool -InstantClone -PoolName "InsPoolvmware" -PoolDisplayName "insPool" -Description "create instant pool" -UserAssignment FLOATING -ParentVM 'Agent_vmware' -SnapshotVM 'kb-hotfix' -VmFolder 'vmware' -HostOrCluster  'CS-1' -ResourcePool 'CS-1' -NamingMethod PATTERN -Datastores 'datastore1' -NamingPattern "inspool2" -NetBiosName 'adviewdev' -DomainAdmin root
```

Create new automated instant clone pool with naming method pattern

### EXAMPLE 5
```
New-HVPool -FullClone -PoolName "FullClone" -PoolDisplayName "FullClonePra" -Description "create full clone" -UserAssignment DEDICATED -Template 'powerCLI-VM-TEMPLATE' -VmFolder 'vmware' -HostOrCluster 'CS-1' -ResourcePool 'CS-1'  -Datastores 'datastore1' -NamingMethod PATTERN -NamingPattern 'FullCln1' -SysPrepName vmwarecust -CustType SYS_PREP -NetBiosName adviewdev -DomainAdmin root
```

Create new automated full clone pool with naming method pattern

### EXAMPLE 6
```
New-HVPool -MANUAL -PoolName 'manualVMWare' -PoolDisplayName 'MNLPUL' -Description 'Manual pool creation' -UserAssignment FLOATING -Source VIRTUAL_CENTER -VM 'PowerCLIVM1', 'PowerCLIVM2'
```

Create new managed manual pool from virtual center managed VirtualMachines.

### EXAMPLE 7
```
New-HVPool -MANUAL -PoolName 'unmangedVMWare' -PoolDisplayName 'unMngPl' -Description 'unmanaged Manual Pool creation' -UserAssignment FLOATING -Source UNMANAGED -VM 'myphysicalmachine.vmware.com'
```

Create new unmanaged manual pool from unmanaged VirtualMachines.

### EXAMPLE 8
```
New-HVPool -spec 'C:\Json\InstantClone.json' -PoolName 'InsPool1'-NamingPattern 'INSPool-'
```

Creates new instant clone pool by reading few parameters from json and few parameters from command line.

## PARAMETERS

### -InstantClone
Switch to Create Instant Clone pool.

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

### -LinkedClone
Switch to Create Linked Clone pool.

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

### -FullClone
Switch to Create Full Clone pool.

```yaml
Type: SwitchParameter
Parameter Sets: FULL_CLONE
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Manual
Switch to Create Manual Clone pool.

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

### -Rds
Switch to Create RDS pool.

```yaml
Type: SwitchParameter
Parameter Sets: RDS
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Spec
Path of the JSON specification file.

```yaml
Type: String
Parameter Sets: JSON_FILE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClonePool
Existing pool info to clone a new pool.

```yaml
Type: Object
Parameter Sets: CLONED_POOL
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PoolName
Name of the pool.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE, MANUAL, RDS, CLONED_POOL
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

### -PoolDisplayName
Display name of pool.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $poolName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Description of pool.

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
View access group can organize the desktops in the pool.
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

### -GlobalEntitlement
Description of pool.
Global entitlement to associate the pool.

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

### -UserAssignment
User Assignment type of pool.
Set to DEDICATED for dedicated desktop pool.
Set to FLOATING for floating desktop pool.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE, MANUAL
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AutomaticAssignment
Automatic assignment of a user the first time they access the machine.
Applicable to dedicated desktop pool.

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE, MANUAL
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Enable
Set true to enable the pool otherwise set to false.

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

### -ConnectionServerRestrictions
Connection server restrictions.
This is a list of tags that access to the desktop is restricted to.
No list means that the desktop can be accessed from any connection server.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PowerPolicy
Power policy for the machines in the desktop after logoff.
This setting is only relevant for managed machines

```yaml
Type: String
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: TAKE_NO_POWER_ACTION
Accept pipeline input: False
Accept wildcard characters: False
```

### -AutomaticLogoffPolicy
Automatically log-off policy after disconnect. 
This property has a default value of "NEVER".

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: NEVER
Accept pipeline input: False
Accept wildcard characters: False
```

### -AutomaticLogoffMinutes
The timeout in minutes for automatic log-off after disconnect.
This property is required if automaticLogoffPolicy is set to "AFTER".

```yaml
Type: Int32
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: 120
Accept pipeline input: False
Accept wildcard characters: False
```

### -allowUsersToResetMachines
Whether users are allowed to reset/restart their machines.

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, MANUAL
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -allowMultipleSessionsPerUser
Whether multiple sessions are allowed per user in case of Floating User Assignment.

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -deleteOrRefreshMachineAfterLogoff
Whether machines are to be deleted or refreshed after logoff in case of Floating User Assignment.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: NEVER
Accept pipeline input: False
Accept wildcard characters: False
```

### -refreshOsDiskAfterLogoff
Whether and when to refresh the OS disks for dedicated-assignment, linked-clone machines.

```yaml
Type: String
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: NEVER
Accept pipeline input: False
Accept wildcard characters: False
```

### -refreshPeriodDaysForReplicaOsDisk
Regular interval at which to refresh the OS disk.

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: 120
Accept pipeline input: False
Accept wildcard characters: False
```

### -refreshThresholdPercentageForReplicaOsDisk
With the 'AT_SIZE' option for refreshOsDiskAfterLogoff, the size of the linked clone's OS disk in the datastore is compared to its maximum allowable size.

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -supportedDisplayProtocols
The list of supported display protocols for the desktop.

```yaml
Type: String[]
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, MANUAL
Aliases:

Required: False
Position: Named
Default value: @('RDP', 'PCOIP', 'BLAST')
Accept pipeline input: False
Accept wildcard characters: False
```

### -defaultDisplayProtocol
The default display protocol for the desktop.
For a managed desktop, this will default to "PCOIP".
For an unmanaged desktop, this will default to "RDP".

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, MANUAL
Aliases:

Required: False
Position: Named
Default value: PCOIP
Accept pipeline input: False
Accept wildcard characters: False
```

### -allowUsersToChooseProtocol
Whether the users can choose the protocol.

```yaml
Type: Int32
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, MANUAL
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -enableHTMLAccess
HTML Access, enabled by VMware Blast technology, allows users to connect to View machines from Web browsers.

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, MANUAL
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -renderer3D
Specify 3D rendering dependent types hardware, software, vsphere client etc.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: DISABLED
Accept pipeline input: False
Accept wildcard characters: False
```

### -enableGRIDvGPUs
Whether GRIDvGPUs enabled or not

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

### -vRamSizeMB
VRAM size for View managed 3D rendering.
More VRAM can improve 3D performance.

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: 96
Accept pipeline input: False
Accept wildcard characters: False
```

### -maxNumberOfMonitors
The greater these values are, the more memory will be consumed on the associated ESX hosts

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: 2
Accept pipeline input: False
Accept wildcard characters: False
```

### -maxResolutionOfAnyOneMonitor
The greater these values are, the more memory will be consumed on the associated ESX hosts.

```yaml
Type: String
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: WUXGA
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quality
This setting determines the image quality that the flash movie will render.
Lower quality results in less bandwidth usage.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE, MANUAL
Aliases:

Required: False
Position: Named
Default value: NO_CONTROL
Accept pipeline input: False
Accept wildcard characters: False
```

### -Throttling
This setting affects the frame rate of the flash movie.
If enabled, the frames per second will be reduced based on the aggressiveness level.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE, MANUAL
Aliases:

Required: False
Position: Named
Default value: DISABLED
Accept pipeline input: False
Accept wildcard characters: False
```

### -overrideGlobalSetting
Mirage configuration specified here will be used for this Desktop

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

### -enabled
Whether a Mirage server is enabled.

```yaml
Type: Boolean
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -url
The URL of the Mirage server.
This should be in the form "\<(DNS name)|(IPv4)|(IPv6)\>\<:(port)\>".
IPv6 addresses must be enclosed in square brackets.

```yaml
Type: String
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Vcenter
Virtual Center server-address (IP or FQDN) where the pool virtual machines are located.
This should be same as provided to the Connection Server while adding the vCenter server.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE, MANUAL
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Template
Virtual machine Template name to clone Virtual machines.
Applicable only to Full Clone pools.

```yaml
Type: String
Parameter Sets: FULL_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParentVM
Parent Virtual Machine to clone Virtual machines.
Applicable only to Linked Clone and Instant Clone pools.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SnapshotVM
Base image VM for Linked Clone pool and current Image for Instant Clone Pool.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VmFolder
VM folder to deploy the VMs to.
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HostOrCluster
Host or cluster to deploy the VMs in.
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourcePool
Resource pool to deploy the VMs.
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -datacenter
desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.datacenter if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Datastores
Datastore names to store the VM
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: String[]
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StorageOvercommit
Storage overcommit determines how View places new VMs on the selected datastores. 
Supported values are 'UNBOUNDED','AGGRESSIVE','MODERATE','CONSERVATIVE','NONE' and are case sensitive.

```yaml
Type: String[]
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
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
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseSeparateDatastoresReplicaAndOSDisks
Whether to use separate datastores for replica and OS disks.

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReplicaDiskDatastore
Datastore to store replica disks for View Composer and Instant clone engine sourced machines.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseNativeSnapshots
Native NFS Snapshots is a hardware feature, specify whether to use or not

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReclaimVmDiskSpace
virtual machines can be configured to use a space efficient disk format that supports reclamation of unused disk space.

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReclamationThresholdGB
Initiate reclamation when unused space on VM exceeds the threshold.

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

### -RedirectWindowsProfile
Windows profiles will be redirected to persistent disks, which are not affected by View Composer operations such as refresh, recompose and rebalance.

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseSeparateDatastoresPersistentAndOSDisks
Whether to use separate datastores for persistent and OS disks.
This must be false if redirectWindowsProfile is false.

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

### -PersistentDiskDatastores
Name of the Persistent disk datastore

```yaml
Type: String[]
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersistentDiskStorageOvercommit
Storage overcommit determines how view places new VMs on the selected datastores. 
Supported values are 'UNBOUNDED','AGGRESSIVE','MODERATE','CONSERVATIVE','NONE' and are case sensitive.

```yaml
Type: String[]
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DiskSizeMB
Size of the persistent disk in MB.

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: 2048
Accept pipeline input: False
Accept wildcard characters: False
```

### -DiskDriveLetter
Persistent disk drive letter.

```yaml
Type: String
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: D
Accept pipeline input: False
Accept wildcard characters: False
```

### -redirectDisposableFiles
Redirect disposable files to a non-persistent disk that will be deleted automatically when a user's session ends.

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

### -NonPersistentDiskSizeMB
Size of the non persistent disk in MB.

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: 4096
Accept pipeline input: False
Accept wildcard characters: False
```

### -NonPersistentDiskDriveLetter
Non persistent disk drive letter.

```yaml
Type: String
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: Auto
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseViewStorageAccelerator
Whether to use View Storage Accelerator.

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

### -ViewComposerDiskTypes
Disk types to enable for the View Storage Accelerator feature.

```yaml
Type: String
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: OS_DISKS
Accept pipeline input: False
Accept wildcard characters: False
```

### -RegenerateViewStorageAcceleratorDays
How often to regenerate the View Storage Accelerator cache.

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: 7
Accept pipeline input: False
Accept wildcard characters: False
```

### -BlackoutTimes
A list of blackout times.

```yaml
Type: DesktopBlackoutTime[]
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Nics
desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterNetworkingSettings.nics

```yaml
Type: DesktopNetworkInterfaceCardSettings[]
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableProvisioning
desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.enableProvsioning if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -StopProvisioningOnError
Set to true to stop provisioning of all VMs on error.
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
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
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE, MANUAL
Aliases:

Required: False
Position: Named
Default value: VM
Accept pipeline input: False
Accept wildcard characters: False
```

### -NamingMethod
Determines how the VMs in the desktop are named.
Set SPECIFIED to use specific name.
Set PATTERN to use naming pattern.
The default value is PATTERN.
For Instant Clone pool the value must be PATTERN.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: True
Position: Named
Default value: PATTERN
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: CLONED_POOL
Aliases:

Required: False
Position: Named
Default value: PATTERN
Accept pipeline input: False
Accept wildcard characters: False
```

### -NamingPattern
Virtual machines will be named according to the specified naming pattern.
Value would be considered only when $namingMethod = PATTERN.
The default value is poolName + '{n:fixed=4}'.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE, JSON_FILE, CLONED_POOL
Aliases:

Required: False
Position: Named
Default value: $poolName + '{n:fixed=4}'
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinReady
Minimum number of ready (provisioned) machines during View Composer maintenance operations.
The default value is 0.
Applicable to Linked Clone Pools.

```yaml
Type: Int32
Parameter Sets: LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaximumCount
Maximum number of machines in the pool.
The default value is 1.
Applicable to Full, Linked, Instant Clone Pools

```yaml
Type: Int32
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -SpareCount
Number of spare powered on machines in the pool.
The default value is 1.
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: Int32
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProvisioningTime
Determines when machines are provisioned.
Supported values are ON_DEMAND, UP_FRONT.
The default value is UP_FRONT.
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: UP_FRONT
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumCount
The minimum number of machines to have provisioned if on demand provisioning is selected.
The default value is 0.
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: Int32
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SpecificNames
Specified names of VMs in the pool.
The default value is \<poolName\>-1
Applicable to Full, Linked and Cloned Pools.

```yaml
Type: String[]
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE, CLONED_POOL
Aliases:

Required: False
Position: Named
Default value: $poolName + '-1'
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartInMaintenanceMode
Set this to true to allow virtual machines to be customized manually before users can log
in and access them.
the default value is false
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NumUnassignedMachinesKeptPoweredOn
Number of unassigned machines kept powered on.
value should be less than max number of vms in the pool.
The default value is 1.
Applicable to Full, Linked, Instant Clone Pools.
When JSON Spec file is used for pool creation, the value will be read from JSON spec.

```yaml
Type: Int32
Parameter Sets: INSTANT_CLONE, LINKED_CLONE, FULL_CLONE, JSON_FILE
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdContainer
This is the Active Directory container which the machines will be added to upon creation.
The default value is 'CN=Computers'.
Applicable to Instant Clone Pool.

```yaml
Type: Object
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: CN=Computers
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetBiosName
Domain Net Bios Name.
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: LINKED_CLONE, FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainAdmin
Domain Administrator user name which will be used to join the domain.
Default value is null.
Applicable to Full, Linked, Instant Clone Pools.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustType
Type of customization to use.
Supported values are 'CLONE_PREP','QUICK_PREP','SYS_PREP','NONE'.
Applicable to Full, Linked Clone Pools.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, FULL_CLONE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReusePreExistingAccounts
desktopSpec.automatedDesktopSpec.customizationSettings.reusePreExistingAccounts if LINKED_CLONE, INSTANT_CLONE

```yaml
Type: Boolean
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SysPrepName
The customization spec to use.
Applicable to Full, Linked Clone Pools.

```yaml
Type: String
Parameter Sets: LINKED_CLONE, FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotPowerOnVMsAfterCreation
desktopSpec.automatedDesktopSpec.customizationSettings.noCustomizationSettings.doNotPowerOnVMsAfterCreation if FULL_CLONE

```yaml
Type: Boolean
Parameter Sets: FULL_CLONE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PowerOffScriptName
Power off script.
ClonePrep/QuickPrep can run a customization script on instant/linked clone machines before they are powered off.
Provide the path to the script on the parent virtual machine.
Applicable to Linked, Instant Clone pools.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
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
Applicable to Linked, Instant Clone pools.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PostSynchronizationScriptName
Post synchronization script.
ClonePrep/QuickPrep can run a customization script on instant/linked clone machines after they are created or recovered or a new image is pushed.
Provide the path to the script on the parent virtual machine.
Applicable to Linked, Instant Clone pools.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
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
Applicable to Linked, Instant Clone pools.

```yaml
Type: String
Parameter Sets: INSTANT_CLONE, LINKED_CLONE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Source
Source of the Virtual machines for manual pool.
Supported values are 'VIRTUAL_CENTER','UNMANAGED'.
Set VIRTUAL_CENTER for vCenter managed VMs.
Set UNMANAGED for Physical machines or VMs which are not vCenter managed VMs.
Applicable to Manual Pools.

```yaml
Type: String
Parameter Sets: MANUAL
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VM
List of existing virtual machine names to add into manual pool.
Applicable to Manual Pools.

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

```yaml
Type: String[]
Parameter Sets: JSON_FILE, CLONED_POOL
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Farm
Farm to create RDS pools
Applicable to RDS Pools.

```yaml
Type: String
Parameter Sets: RDS, CLONED_POOL
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HvServer
Reference to Horizon View Server to query the pools from.
If the value is not passed or null then
first element from global:DefaultHVServers would be considered in-place of hvServer.

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
| Author | Praveen Mathamsetty. |
| Author email | pmathamsetty@vmware.com |
| Version | 1.1 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.0.2, 7.1.0 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
