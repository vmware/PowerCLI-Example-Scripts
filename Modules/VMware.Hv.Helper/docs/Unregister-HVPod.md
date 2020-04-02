---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Unregister-HVPod

## SYNOPSIS
Removes a pod from a podfederation

## SYNTAX

```
Unregister-HVPod [-PodName] <String> [[-force] <Boolean>] [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Starts the uninitialisation of a Horizon View Pod Federation.
It does NOT remove a pod from a federation.

## EXAMPLES

### EXAMPLE 1
```
Unregister-hvpod -podname PODNAME
```

Checks if you are connected to the pod and gracefully unregisters it from the podfedaration

### EXAMPLE 2
```
Unregister-hvpod -podname PODNAME -force
```

Checks if you are connected to the pod and gracefully unregisters it from the podfedaration

## PARAMETERS

### -PodName
The name of the pod to be removed.

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

### -force
This can be used to forcefully remove a pod from the pod federation.
This can only be done while connected to one of the other pods in the federation

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: False
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
Position: 3
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
| Horizon View Server Version | 7.3.2,7.4 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
