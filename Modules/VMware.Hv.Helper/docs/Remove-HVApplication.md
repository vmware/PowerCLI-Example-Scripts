---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Remove-HVApplication

## SYNOPSIS
Removes the specified application if exists.

## SYNTAX

```
Remove-HVApplication [-ApplicationName] <String> [[-HvServer] <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Removes the specified application if exists.

## EXAMPLES

### EXAMPLE 1
```
Remove-HVApplication -ApplicationName 'App1' -HvServer $HvServer
```

Removes 'App1', if exists.

## PARAMETERS

### -ApplicationName
Application to be deleted.
The name of the application must be given that is to be searched for and remove if exists.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -HvServer
View API service object of Connect-HVServer cmdlet.

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

### Removes the specified application if exists.
## NOTES
| | |
|-|-|
| Author | Samiullasha S |
| Author email | ssami@vmware.com |
| Version | 1.2 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.8.0 |
| PowerCLI Version | PowerCLI 11.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
