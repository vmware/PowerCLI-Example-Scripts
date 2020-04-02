---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVvCenterServerHealth

## SYNOPSIS
Gets a the health info for a given vCenter Server.

## SYNTAX

```
Get-HVvCenterServerHealth [[-HvServer] <Object>] [[-VirtualCenter] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Queries and returns the VirtualCenterHealthInfo specified HVServer.

## EXAMPLES

### EXAMPLE 1
```
Get-HVvCenterServerHealth -VirtualCenter 'vCenter1'
```

### EXAMPLE 2
```
Get-HVvCenterServerHealth -VirtualCenter $vCenter1
```

### EXAMPLE 3
```
Get-HVvCenterServerHealth
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

### -VirtualCenter
A parameter to specify which vCenter Server to check health for.
If not specified, this function will return the
health info for all vCenter Servers.

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
