---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVHealth

## SYNOPSIS
Pulls health information from Horizon View

## SYNTAX

```
Get-HVHealth [[-Servicename] <String>] [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Queries and returns health information from the local Horizon Pod

## EXAMPLES

### EXAMPLE 1
```
Get-HVHealth -service connectionserver
```

Returns health for the connectionserver(s)

### EXAMPLE 2
```
Get-HVHealth -service ViewComposer
```

Returns health for the View composer server(s)

## PARAMETERS

### -Servicename
The name of the service to query the health for.
 This will default to Connection server health.
 Available services are ADDomain,CertificateSSOConnector,ConnectionServer,EventDatabase,SAMLAuthenticator,SecurityServer,ViewComposer,VirtualCenter,Pod

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: ConnectionServer
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
| Horizon View Server Version | 7.3.2,7.4 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
