---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Start-HVPool

## SYNOPSIS
Perform maintenance tasks on Pool.

## SYNTAX

### REFRESH
```
Start-HVPool -Pool <Object> [-Refresh] [-StartTime <DateTime>] -LogoffSetting <String>
 [-StopOnFirstError <Boolean>] [-Machines <String[]>] [-HvServer <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### RECOMPOSE
```
Start-HVPool -Pool <Object> [-Recompose] [-StartTime <DateTime>] -LogoffSetting <String>
 [-StopOnFirstError <Boolean>] [-Machines <String[]>] -ParentVM <String> -SnapshotVM <String>
 [-Vcenter <String>] [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### REBALANCE
```
Start-HVPool -Pool <Object> [-Rebalance] [-StartTime <DateTime>] -LogoffSetting <String>
 [-StopOnFirstError <Boolean>] [-Machines <String[]>] [-HvServer <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### PUSH_IMAGE
```
Start-HVPool -Pool <Object> [-SchedulePushImage] [-StartTime <DateTime>] [-LogoffSetting <String>]
 [-StopOnFirstError <Boolean>] [-ParentVM <String>] [-SnapshotVM <String>] [-Vcenter <String>]
 [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CANCEL_PUSH_IMAGE
```
Start-HVPool -Pool <Object> [-CancelPushImage] [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This cmdlet is used to perform maintenance tasks like enable/disable the pool, enable/disable the provisioning of a pool, refresh, rebalance, recompose, push image and cancel image.
Push image and Cancel image tasks only applies for instant clone pool.

## EXAMPLES

### EXAMPLE 1
```
Start-HVPool -Recompose -Pool 'LCPool3' -LogoffSetting FORCE_LOGOFF -ParentVM 'View-Agent-Win8' -SnapshotVM 'Snap_USB'
```

Requests a recompose of machines in the specified pool

### EXAMPLE 2
```
Start-HVPool -Refresh -Pool 'LCPool3' -LogoffSetting FORCE_LOGOFF -Confirm:$false
```

Requests a refresh of machines in the specified pool

### EXAMPLE 3
```
$myTime = Get-Date '10/03/2016 12:30:00'
```

Start-HVPool -Rebalance -Pool 'LCPool3' -LogoffSetting FORCE_LOGOFF -StartTime $myTime
Requests a rebalance of machines in a pool with specified time

### EXAMPLE 4
```
Start-HVPool -SchedulePushImage -Pool 'InstantPool' -LogoffSetting FORCE_LOGOFF -ParentVM 'InsParentVM' -SnapshotVM 'InsSnapshotVM'
```

Requests an update of push image operation on the specified Instant Clone Engine sourced pool

### EXAMPLE 5
```
Start-HVPool -CancelPushImage -Pool 'InstantPool'
```

Requests a cancellation of the current scheduled push image operation on the specified Instant Clone Engine sourced pool

## PARAMETERS

### -Pool
Name/Object(s) of the pool.

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

### -Refresh
Switch parameter to refresh operation.

```yaml
Type: SwitchParameter
Parameter Sets: REFRESH
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recompose
Switch parameter to recompose operation.

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

### -Rebalance
Switch parameter to rebalance operation.

```yaml
Type: SwitchParameter
Parameter Sets: REBALANCE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SchedulePushImage
Switch parameter to push image operation.

```yaml
Type: SwitchParameter
Parameter Sets: PUSH_IMAGE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CancelPushImage
Switch parameter to cancel push image operation.

```yaml
Type: SwitchParameter
Parameter Sets: CANCEL_PUSH_IMAGE
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartTime
Specifies when to start the operation.
If unset, the operation will begin immediately.

```yaml
Type: DateTime
Parameter Sets: REFRESH, RECOMPOSE, REBALANCE, PUSH_IMAGE
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
'FORCE_LOGOFF' - Users will be forced to log off when the system is ready to operate on their virtual machines.
'WAIT_FOR_LOGOFF' - Wait for connected users to disconnect before the task starts.
The operation starts immediately on machines without active sessions.

```yaml
Type: String
Parameter Sets: REFRESH, RECOMPOSE, REBALANCE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: PUSH_IMAGE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StopOnFirstError
Indicates that the operation should stop on first error.

```yaml
Type: Boolean
Parameter Sets: REFRESH, RECOMPOSE, REBALANCE, PUSH_IMAGE
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Machines
The machine names to recompose.
These must be associated with the pool.

```yaml
Type: String[]
Parameter Sets: REFRESH, RECOMPOSE, REBALANCE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParentVM
New base image VM for the desktop.
This must be in the same datacenter as the base image of the desktop.

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
Parameter Sets: PUSH_IMAGE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SnapshotVM
Name of the snapshot used in pool deployment.

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
Parameter Sets: PUSH_IMAGE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Vcenter
Virtual Center server-address (IP or FQDN) of the given pool.
This should be same as provided to the Connection Server while adding the vCenter server.

```yaml
Type: String
Parameter Sets: RECOMPOSE, PUSH_IMAGE
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HvServer
View API service object of Connect-HVServer cmdlet.

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
