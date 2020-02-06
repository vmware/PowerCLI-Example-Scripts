---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Reset-HVMachine

## SYNOPSIS
Resets Horizon View desktops.

## SYNTAX

```
Reset-HVMachine [-MachineName] <String> [[-HvServer] <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Queries and resets virtual machines, the machines list would be determined
 based on queryable fields machineName.
Use an asterisk (*) as wildcard.
If the result has multiple machines all will be reset.
 Please note that on an Instant Clone Pool this will do the same as a recover of the machine.

## EXAMPLES

### EXAMPLE 1
```
reset-HVMachine -MachineName 'PowerCLIVM'
```

Queries VM(s) with given parameter machineName

### EXAMPLE 2
```
reset-HVMachine -MachineName 'PowerCLIVM*'
```

Queries VM(s) with given parameter machinename with wildcard character *

## PARAMETERS

### -MachineName
The name of the Machine(s) to query for.
This is a required value.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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
Position: 2
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

## NOTES
| | |
|-|-|
| Author | Wouter Kursten |
| Author email | wouter@retouw.nl |
| Version | 1.0 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.3.2 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
