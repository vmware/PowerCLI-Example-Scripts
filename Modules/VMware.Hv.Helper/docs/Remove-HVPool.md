---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Remove-HVPool

## SYNOPSIS
Deletes specified pool(s).

## SYNTAX

### option
```
Remove-HVPool -poolName <String> [-TerminateSession] [-DeleteFromDisk] [-HvServer <Object>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### pipeline
```
Remove-HVPool [-Pool <Object>] [-TerminateSession] [-DeleteFromDisk] [-HvServer <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
This function deletes the pool(s) with the specified name/object(s) from Connection Server.
This can be used for deleting any pool irrespective of its type.
Optionally, user can pipe the pool object(s) as input to this function.

## EXAMPLES

### EXAMPLE 1
```
Remove-HVPool -HvServer $hvServer -PoolName 'FullClone' -DeleteFromDisk -Confirm:$false
```

Deletes pool from disk with given parameters PoolName etc.

### EXAMPLE 2
```
$pool_array | Remove-HVPool -HvServer $hvServer  -DeleteFromDisk
```

Deletes specified pool from disk

### EXAMPLE 3
```
Remove-HVPool -Pool $pool1
```

Deletes specified pool and VM(s) associations are removed from view Manager

## PARAMETERS

### -poolName
Name of the pool to be deleted.

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

### -Pool
Object(s) of the pool to be deleted.

```yaml
Type: Object
Parameter Sets: pipeline
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -TerminateSession
Logs off a session forcibly to virtual machine(s).
This operation will also log off a locked session.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeleteFromDisk
Switch parameter to delete the virtual machine(s) from the disk.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
