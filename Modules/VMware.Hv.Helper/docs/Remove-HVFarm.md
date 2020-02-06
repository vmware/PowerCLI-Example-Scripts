---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Remove-HVFarm

## SYNOPSIS
Deletes specified farm(s).

## SYNTAX

### option
```
Remove-HVFarm -FarmName <String> [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### pipeline
```
Remove-HVFarm -Farm <Object> [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function deletes the farm(s) with the specified name/object(s) from the Connection Server.
Optionally, user can pipe the farm object(s) as input to this function.

## EXAMPLES

### EXAMPLE 1
```
Remove-HVFarm -FarmName 'Farm-01' -HvServer $hvServer -Confirm:$false
```

Delete a given farm.
For an automated farm, all the RDS Server VMs are deleted from disk whereas for a manual farm only the RDS Server associations are removed.

### EXAMPLE 2
```
$farm_array | Remove-HVFarm -HvServer $hvServer
```

Deletes a given Farm object(s).
For an automated farm, all the RDS Server VMs are deleted from disk whereas for a manual farm only the RDS Server associations are removed.

### EXAMPLE 3
```
$farm1 = Get-HVFarm -FarmName 'Farm-01'
```

Remove-HVFarm -Farm $farm1
Deletes a given Farm object.
For an automated farm, all the RDS Server VMs are deleted from disk whereas for a manual farm only the RDS Server associations are removed.

## PARAMETERS

### -FarmName
Name of the farm to be deleted.

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

### -Farm
Object(s) of the farm to be deleted.
Object(s) should be of type FarmSummaryView/FarmInfo.

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
