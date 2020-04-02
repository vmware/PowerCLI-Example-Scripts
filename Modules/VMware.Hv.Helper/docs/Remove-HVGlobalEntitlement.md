---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Remove-HVGlobalEntitlement

## SYNOPSIS
Deletes a Global Entitlement.

## SYNTAX

### Default
```
Remove-HVGlobalEntitlement -DisplayName <String> [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### pipeline
```
Remove-HVGlobalEntitlement -GlobalEntitlement <Object> [-HvServer <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Deletes global entitlement(s) and global application entitlement(s). 
Optionally, user can pipe the global entitlement(s) as input to this function.

## EXAMPLES

### EXAMPLE 1
```
Remove-HVGlobalEntitlement -DisplayName 'GE_APP'
```

Deletes global application/desktop entitlement with displayName 'GE_APP'

### EXAMPLE 2
```
Get-HVGlobalEntitlement -DisplayName 'GE_*' | Remove-HVGlobalEntitlement
```

Deletes global application/desktop entitlement(s), if displayName matches with 'GE_*'

## PARAMETERS

### -DisplayName
Display Name of Global Entitlement.

```yaml
Type: String
Parameter Sets: Default
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GlobalEntitlement
{{ Fill GlobalEntitlement Description }}

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
Reference to Horizon View Server.
If the value is not passed or null then
first element from global:DefaultHVServers would be considered inplace of hvServer

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
