---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Set-HVApplicationIcon

## SYNOPSIS
Used to create/update an icon association for a given application.

## SYNTAX

```
Set-HVApplicationIcon [-ApplicationName] <String> [-IconPath] <Object> [[-HvServer] <Object>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function is used to create an application icon and associate it with the given application.
If the specified icon already exists in the LDAP, it will just updates the icon association to the application.
Any of the existing customized icon association to the given application will be overwritten.

## EXAMPLES

### EXAMPLE 1
```
Creating the icon I1 and associating with application A1. Same command is used for update icon also.
```

Set-HVApplicationIcon -ApplicationName A1 -IconPath C:\I1.ico -HvServer $hvServer

## PARAMETERS

### -ApplicationName
Name of the application to which the association to be made.

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

### -IconPath
Path of the icon.

```yaml
Type: Object
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
| Author | Paramesh Oddepally. |
| Author email | poddepally@vmware.com |
| Version | 1.1 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.1 |
| PowerCLI Version | PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
