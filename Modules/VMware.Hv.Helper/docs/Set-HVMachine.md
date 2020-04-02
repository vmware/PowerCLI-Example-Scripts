---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Set-HVMachine

## SYNOPSIS
Sets existing virtual Machine(s).

## SYNTAX

### option
```
Set-HVMachine -MachineName <String> [-Maintenance <String>] [-Key <String>] [-Value <Object>] [-User <String>]
 [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### pipeline
```
Set-HVMachine -Machine <Object> [-Maintenance <String>] [-Key <String>] [-Value <Object>] [-User <String>]
 [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This cmdlet allows user to edit Machine configuration by passing key/value pair.
Allows the machine in to Maintenance mode and vice versa

## EXAMPLES

### EXAMPLE 1
```
Set-HVMachine -MachineName 'Agent_Praveen' -Maintenance ENTER_MAINTENANCE_MODE
```

Moving the machine in to Maintenance mode using machine name

### EXAMPLE 2
```
Get-HVMachine -MachineName 'Agent_Praveen' | Set-HVMachine -Maintenance ENTER_MAINTENANCE_MODE
```

Moving the machine in to Maintenance mode using machine object(s)

### EXAMPLE 3
```
$machine = Get-HVMachine -MachineName 'Agent_Praveen'; Set-HVMachine -Machine $machine -Maintenance EXIT_MAINTENANCE_MODE
```

Moving the machine in to Maintenance mode using machine object(s)

## PARAMETERS

### -MachineName
The name of the Machine to edit.

```yaml
Type: String
Parameter Sets: option
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Machine
Object(s) of the virtual Machine(s) to edit.

```yaml
Type: Object
Parameter Sets: pipeline
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Maintenance
The virtual machine is in maintenance mode.
Users cannot log in or use the virtual machine

PARAMETER Key
Property names path separated by .
(dot) from the root of machine info spec.

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

### -Key
{{ Fill Key Description }}

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

### -Value
Property value corresponds to above key name.

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

### -User
{{ Fill User Description }}

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

### -HvServer
Reference to Horizon View Server to query the virtual machines from.
If the value is not passed or null then
first element from global:DefaultHVServers would be considered in-place of hvServer

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
