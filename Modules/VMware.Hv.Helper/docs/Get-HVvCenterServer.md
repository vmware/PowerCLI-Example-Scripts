---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVvCenterServer

## SYNOPSIS
Gets a list of all configured vCenter Servers

## SYNTAX

```
Get-HVvCenterServer [[-HvServer] <Object>] [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION
Queries and returns the vCenter Servers configured for the pod of the specified HVServer.

## EXAMPLES

### EXAMPLE 1
```
Get-HVvCenterServer
```

### EXAMPLE 2
```
Get-HVvCenterServer -Name 'vCenter1'
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

### -Name
A string value to query a vCenter Server by Name, if it is known.

```yaml
Type: String
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

### Returns array of object type VMware.Hv.VirtualCenterInfo
## NOTES
| | |
|-|-|
| Author | Matt Frey. |
| Author email | mfrey@vmware.com |
| Version | 1.0 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.7 |
| PowerCLI Version | PowerCLI 11.2.0 |
| PowerShell Version | 5.1 |

## RELATED LINKS
