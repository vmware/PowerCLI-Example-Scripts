---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVHomeSite

## SYNOPSIS
Gets the configured Horizon View Homesites

## SYNTAX

```
Get-HVHomeSite [[-Group] <String>] [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Gets the configured Horizon View Homesites

## EXAMPLES

### EXAMPLE 1
```
Get-HVHomeSite
```

### EXAMPLE 2
```
Get-HVHomeSite -group group@domain
```

## PARAMETERS

### -Group
User principal name of a group

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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
| Horizon View Server Version | 7.4 |
| PowerCLI Version | PowerCLI 10 |
| PowerShell Version | 5.0 |

## RELATED LINKS
