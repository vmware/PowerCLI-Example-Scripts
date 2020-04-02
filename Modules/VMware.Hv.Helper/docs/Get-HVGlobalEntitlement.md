---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVGlobalEntitlement

## SYNOPSIS
Gets Global Entitlement(s) with given search parameters.

## SYNTAX

```
Get-HVGlobalEntitlement [[-DisplayName] <String>] [[-Description] <String>] [[-SuppressInfo] <Boolean>]
 [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Queries and returns global entitlement(s) and global application entitlement(s).
Global entitlements are used to route users to their resources across multiple pods.

## EXAMPLES

### EXAMPLE 1
```
Get-HVGlobalEntitlement -DisplayName 'GEAPP'
```

Retrieves global application/desktop entitlement(s) with displayName 'GEAPP'

## PARAMETERS

### -DisplayName
Display Name of Global Entitlement.

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

### -Description
Description of Global Entitlement.

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

### -SuppressInfo
Suppress text info, when no global entitlement(s) found with given search parameters

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -HvServer
Reference to Horizon View Server.
If the value is not passed or null then
first element from global:DefaultHVServers would be considered in-place of hvServer

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
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
| Author | Praveen Mathamsetty. |
| Author email | pmathamsetty@vmware.com |
| Version | 1.1 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.0.2, 7.1.0 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
