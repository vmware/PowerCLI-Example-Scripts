---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVPreInstalledApplication

## SYNOPSIS
Gets the list of Pre-installed Applications from the RDS Server(s).

## SYNTAX

```
Get-HVPreInstalledApplication [-FarmName] <String> [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Gets the list of Pre-installed Applications from the RDS Server(s).

## EXAMPLES

### EXAMPLE 1
```
Get-HVPreInstalledApplication -FarmName 'Farm1' -HvServer $HvServer
```

Gets the list of Applications present in 'Farm1', if exists.

## PARAMETERS

### -FarmName
Name of the Farm on which to discover installed applications.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Gets the list of Applications from the specified Farm if exists.
## NOTES
| | |
|-|-|
| Author | Samiullasha S |
| Author email | ssami@vmware.com |
| Version | 1.0 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.8.0 |
| PowerCLI Version | PowerCLI 11.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
