---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Disconnect-HVEvent

## SYNOPSIS
This function is used to disconnect the database connection.

## SYNTAX

```
Disconnect-HVEvent [-HvDbServer] <PSObject> [<CommonParameters>]
```

## DESCRIPTION
This function will disconnect the database connection made earlier during Connect-HVEvent function.

## EXAMPLES

### EXAMPLE 1
```
Disconnect-HVEvent -HvDbServer $hvDbServer
```

Disconnecting the database connection on $hvDbServer.

## PARAMETERS

### -HvDbServer
Connection object returned by Connect-HVEvent advanced function.
This is a mandatory input.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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
| Horizon View Server Version | 7.0.2, 7.1.0 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
