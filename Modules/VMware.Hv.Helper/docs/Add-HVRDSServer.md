---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Add-HVRDSServer

## SYNOPSIS
Add RDS Servers to an existing farm.

## SYNTAX

```
Add-HVRDSServer [-FarmName] <Object> [-RdsServers] <String[]> [[-HvServer] <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Add-HVRDSServer adds RDS Servers to already exiting farms by using view API service object(hvServer) of Connect-HVServer cmdlet.
We can add RDSServers to manual farm type only.
This advanced function do basic checks for farm and view API service connection existance.
This hvServer is bound to specific connection server.

## EXAMPLES

### EXAMPLE 1
```
Add-HVRDSServer -Farm "manualFarmTest" -RdsServers "vm-for-rds","vm-for-rds-2" -Confirm:$false
```

Add RDSServers to manual farm

## PARAMETERS

### -FarmName
farm name to which new RDSServers are to be added.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -RdsServers
RDS servers names which need to be added to the given farm.
Provide a comma separated list for multiple names.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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
Position: 3
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
| Dependencies | Make sure farm already exists before adding RDSServers to it. |

### Tested Against Environment
| | |
|-|-|
| Horizon View Server Version | 7.0.2, 7.1.0 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
