---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVGlobalSettings

## SYNOPSIS
Gets a list of Global Settings

## SYNTAX

```
Get-HVGlobalSettings [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Queries and returns the Global Settings for the pod of the specified HVServer.

## EXAMPLES

### EXAMPLE 1
```
Get-HVGlobalSettings
```

## PARAMETERS

### -HvServer
Reference to Horizon View Server to query the virtual machines from.
If the value is not passed or null then
first element from global:DefaultHVServers would be considered inplace of hvServer

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns list of object type VMware.Hv.GlobalSettingsInfo
## NOTES
| | |
|-|-|
| Author | Matt Frey. |
| Author email | mfrey@vmware.com |
| Version | 1.0 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.1 |
| PowerCLI Version | PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
