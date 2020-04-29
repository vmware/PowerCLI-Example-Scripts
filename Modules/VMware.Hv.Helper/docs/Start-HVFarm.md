---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Start-HVFarm

## SYNOPSIS
Performs maintenance tasks on the farm(s).

## SYNTAX

### RECOMPOSE
```
Start-HVFarm -Farm <Object> [-Recompose] [-StartTime <DateTime>] -LogoffSetting <String>
 [-StopOnFirstError <Boolean>] [-Servers <String[]>] -ParentVM <String> -SnapshotVM <String>
 [-Vcenter <String>] [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### SCHEDULEMAINTENANCE
```
Start-HVFarm -Farm <Object> [-ScheduleMaintenance] [-StartTime <DateTime>] [-LogoffSetting <String>]
 [-StopOnFirstError <Boolean>] [-ParentVM <String>] [-SnapshotVM <String>] [-Vcenter <String>]
 -MaintenanceMode <String> [-MaintenanceStartTime <String>] [-MaintenancePeriod <String>] [-StartInt <Int32>]
 [-EveryInt <Int32>] [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CANCELMAINTENANCE
```
Start-HVFarm -Farm <Object> [-CancelMaintenance] -MaintenanceMode <String> [-HvServer <Object>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function is used to perform maintenance tasks like enable/disable, start/stop and recompose the farm.
This function is also used for scheduling maintenance operation on instant-clone farm(s).

## EXAMPLES

### EXAMPLE 1
```
Start-HVFarm -Recompose -Farm 'Farm-01' -LogoffSetting FORCE_LOGOFF -ParentVM 'View-Agent-Win8' -SnapshotVM 'Snap_USB' -Confirm:$false
```

Requests a recompose of RDS Servers in the specified automated farm

### EXAMPLE 2
```
$myTime = Get-Date '10/03/2016 12:30:00'
```

Start-HVFarm -Farm 'Farm-01' -Recompose -LogoffSetting 'FORCE_LOGOFF' -ParentVM 'ParentVM' -SnapshotVM 'SnapshotVM' -StartTime $myTime
Requests a recompose task for automated farm in specified time

### EXAMPLE 3
```
Start-HVFarm -Farm 'ICFarm-01' -ScheduleMaintenance -MaintenanceMode IMMEDIATE
```

Requests a ScheduleMaintenance task for instant-clone farm.
Schedules an IMMEDIATE maintenance.

### EXAMPLE 4
```
Start-HVFarm -ScheduleMaintenance -Farm 'ICFarm-01' -MaintenanceMode RECURRING -MaintenancePeriod WEEKLY -MaintenanceStartTime '11:30' -StartInt 6 -EveryInt 1 -ParentVM 'vm-rdsh-ic' -SnapshotVM 'Snap_Updated'
```

Requests a ScheduleMaintenance task for instant-clone farm.
Schedules a recurring weekly maintenace every Saturday night at 23:30 and updates the parentVM and snapshot.

### EXAMPLE 5
```
Start-HVFarm -CancelMaintenance -Farm 'ICFarm-01' -MaintenanceMode RECURRING
```

Requests a CancelMaintenance task for instant-clone farm.
Cancels recurring maintenance.

## PARAMETERS

### -Farm
Name/Object(s) of the farm.
Object(s) should be of type FarmSummaryView/FarmInfo.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Recompose
Switch for recompose operation.
Requests a recompose of RDS Servers in the specified 'AUTOMATED' farm.
This marks the RDS Servers for recompose, which is performed asynchronously.

```yaml
Type: SwitchParameter
Parameter Sets: RECOMPOSE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScheduleMaintenance
Switch for ScheduleMaintenance operation.
Requests for scheduling maintenance operation on RDS Servers in the specified Instant clone farm.
This marks the RDS Servers for scheduled maintenance, which is performed according to the schedule.

```yaml
Type: SwitchParameter
Parameter Sets: SCHEDULEMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CancelMaintenance
Switch for cancelling maintenance operation.
Requests for cancelling a scheduled maintenance operation on the specified Instant clone farm.
This stops further maintenance operation on the given farm.

```yaml
Type: SwitchParameter
Parameter Sets: CANCELMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartTime
Specifies when to start the recompose/ScheduleMaintenance operation.
If unset, the recompose operation will begin immediately.
For IMMEDIATE maintenance if unset, maintenance will begin immediately.
For RECURRING maintenance if unset, will be calculated based on recurring maintenance configuration.
If in the past, maintenance will begin immediately.

```yaml
Type: DateTime
Parameter Sets: RECOMPOSE, SCHEDULEMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogoffSetting
Determines when to perform the operation on machines which have an active session.
This property will be one of:
"FORCE_LOGOFF" - Users will be forced to log off when the system is ready to operate on their RDS Servers.
Before being forcibly logged off, users may have a grace period in which to save their work (Global Settings).
This is the default value.
"WAIT_FOR_LOGOFF" - Wait for connected users to disconnect before the task starts.
The operation starts immediately on RDS Servers without active sessions.

```yaml
Type: String
Parameter Sets: RECOMPOSE
Aliases:

Required: True
Position: Named
Default value: FORCE_LOGOFF
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: SCHEDULEMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: FORCE_LOGOFF
Accept pipeline input: False
Accept wildcard characters: False
```

### -StopOnFirstError
Indicates that the operation should stop on first error.
Defaults to true.

```yaml
Type: Boolean
Parameter Sets: RECOMPOSE, SCHEDULEMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Servers
The RDS Server(s) id to recompose.
Provide a comma separated list for multiple RDSServerIds.

```yaml
Type: String[]
Parameter Sets: RECOMPOSE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParentVM
New base image VM for automated farm's RDS Servers.
This must be in the same datacenter as the base image of the RDS Server.

```yaml
Type: String
Parameter Sets: RECOMPOSE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: SCHEDULEMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SnapshotVM
Base image snapshot for the Automated Farm's RDS Servers.

```yaml
Type: String
Parameter Sets: RECOMPOSE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: SCHEDULEMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Vcenter
Virtual Center server-address (IP or FQDN) of the given farm.
This should be same as provided to the Connection Server while adding the vCenter server.

```yaml
Type: String
Parameter Sets: RECOMPOSE, SCHEDULEMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaintenanceMode
The mode of schedule maintenance for Instant Clone Farm.
This property will be one of:
"IMMEDIATE"	- All server VMs will be refreshed once, immediately or at user scheduled time.
"RECURRING"	- All server VMs will be periodically refreshed based on MaintenancePeriod and MaintenanceStartTime.

```yaml
Type: String
Parameter Sets: SCHEDULEMAINTENANCE, CANCELMAINTENANCE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaintenanceStartTime
Configured start time for the recurring maintenance.
This property must be in the form hh:mm in 24 hours format.

```yaml
Type: String
Parameter Sets: SCHEDULEMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaintenancePeriod
This represents the frequency at which to perform recurring maintenance.
This property will be one of:
"DAILY"	- Daily recurring maintenance
"WEEKLY" - Weekly recurring maintenance
"MONTHLY" - Monthly recurring maintenance

```yaml
Type: String
Parameter Sets: SCHEDULEMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartInt
Start index for weekly or monthly maintenance.
Weekly: 1-7 (Sun-Sat), Monthly: 1-31.
This property is required if maintenancePeriod is set to "WEEKLY"or "MONTHLY".
This property has values 1-7 for maintenancePeriod "WEEKLY".
This property has values 1-31 for maintenancePeriod "MONTHLY".

```yaml
Type: Int32
Parameter Sets: SCHEDULEMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -EveryInt
How frequently to repeat maintenance, expressed as a multiple of the maintenance period.
e.g.
Every 2 weeks.
This property has a default value of 1.
This property has values 1-100.

```yaml
Type: Int32
Parameter Sets: SCHEDULEMAINTENANCE
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -HvServer
Reference to Horizon View Server to query the data from.
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
