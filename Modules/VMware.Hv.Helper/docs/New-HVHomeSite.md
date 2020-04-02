---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# New-HVHomeSite

## SYNOPSIS
Defines a homesite within a Horizon View Cloud Pod architecture

## SYNTAX

### Default (Default)
```
New-HVHomeSite -Group <String> -Site <String> [-HvServer <Object>] [<CommonParameters>]
```

### globalApplicationEntitlement
```
New-HVHomeSite [-Group <String>] [-Site <String>] [-globalApplicationEntitlement <String>] [-HvServer <Object>]
 [<CommonParameters>]
```

### globalEntitlement
```
New-HVHomeSite [-Group <String>] [-Site <String>] [-globalEntitlement <String>] [-HvServer <Object>]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a new homesite within a Cloud Pod Archtitecture.
By default it will be applied to everything 
but the choice can be made to only apply for a single global entitlement or singel global application entitlement

## EXAMPLES

### EXAMPLE 1
```
New-HVHomeSite -group group@domain -site SITE
```

### EXAMPLE 2
```
New-HVHomeSite -group group@domain -site SITE -globalapplicationentitlement ge-ap01
```

### EXAMPLE 3
```
New-HVHomeSite -group group@domain -site SITE -globalentitlement GE_Production
```

## PARAMETERS

### -Group
User principal name of a group

```yaml
Type: String
Parameter Sets: Default
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: globalApplicationEntitlement, globalEntitlement
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Site
Name of the Horizon View Site

```yaml
Type: String
Parameter Sets: Default
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: globalApplicationEntitlement, globalEntitlement
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -globalEntitlement
Name of the global entitlement

```yaml
Type: String
Parameter Sets: globalEntitlement
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -globalApplicationEntitlement
Name of the global application entitlement

```yaml
Type: String
Parameter Sets: globalApplicationEntitlement
Aliases:

Required: False
Position: Named
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
Position: Named
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
| PowerCLI Version | PowerCLI 10.1.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
