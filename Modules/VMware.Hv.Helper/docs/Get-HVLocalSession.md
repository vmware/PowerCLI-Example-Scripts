---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVLocalSession

## SYNOPSIS
Provides a list with all sessions on the local pod (works in CPA and non-CPA)

## SYNTAX

```
Get-HVLocalSession [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
The Get-HVLocalSession gets all local session by using view API service object(hvServer) of Connect-HVServer cmdlet.

## EXAMPLES

### EXAMPLE 1
```
Get-HVLocalSession
```

Get all local sessions

## PARAMETERS

### -HvServer
View API service object of Connect-HVServer cmdlet.

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

## NOTES
| | |
|-|-|
Author                      : Wouter Kursten.
Author email                : wouter@retouw.nl
Version                     : 1.0

===Tested Against Environment====
| | |
|-|-|
Horizon View Server Version : 7.0.2, 7.1.0, 7.3.2
PowerCLI Version            : PowerCLI 6.5, PowerCLI 6.5.1
PowerShell Version          : 5.0

## RELATED LINKS
