---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVQueryFilter

## SYNOPSIS
Creates a VMware.Hv.QueryFilter based on input provided.

## SYNTAX

### ne
```
Get-HVQueryFilter [-MemberName] <String> [-Ne] [-MemberValue] <Object> [<CommonParameters>]
```

### startswith
```
Get-HVQueryFilter [-MemberName] <String> [-Startswith] [-MemberValue] <Object> [<CommonParameters>]
```

### contains
```
Get-HVQueryFilter [-MemberName] <String> [-Contains] [-MemberValue] <Object> [<CommonParameters>]
```

### eq
```
Get-HVQueryFilter [-MemberName] <String> [-Eq] [-MemberValue] <Object> [<CommonParameters>]
```

### not
```
Get-HVQueryFilter [-Not] [-Filter] <QueryFilter> [<CommonParameters>]
```

### and
```
Get-HVQueryFilter [-And] [-Filters] <QueryFilter[]> [<CommonParameters>]
```

### or
```
Get-HVQueryFilter [-Or] [-Filters] <QueryFilter[]> [<CommonParameters>]
```

## DESCRIPTION
This is a factory method to create a VMware.Hv.QueryFilter.
The type of the QueryFilter would be determined based on switch used.

## EXAMPLES

### EXAMPLE 1
```
Get-HVQueryFilter data.name -Eq vmware
```

Creates queryFilterEquals with given parameters memberName(position 0) and memberValue(position 2)

### EXAMPLE 2
```
Get-HVQueryFilter -MemberName data.name -Eq -MemberValue vmware
```

Creates queryFilterEquals with given parameters memberName and memberValue

### EXAMPLE 3
```
Get-HVQueryFilter data.name -Ne vmware
```

Creates queryFilterNotEquals filter with given parameters memberName and memberValue

### EXAMPLE 4
```
Get-HVQueryFilter data.name -Contains vmware
```

Creates queryFilterContains with given parameters memberName and memberValue

### EXAMPLE 5
```
Get-HVQueryFilter data.name -Startswith vmware
```

Creates queryFilterStartsWith with given parameters memberName and memberValue

### EXAMPLE 6
```
$filter = Get-HVQueryFilter data.name -Startswith vmware
```

Get-HVQueryFilter -Not $filter
Creates queryFilterNot with given parameter filter

### EXAMPLE 7
```
$filter1 = Get-HVQueryFilter data.name -Startswith vmware
```

$filter2 = Get-HVQueryFilter data.name -Contains pool
Get-HVQueryFilter -And @($filter1, $filter2)

Creates queryFilterAnd with given parameter filters array

### EXAMPLE 8
```
$filter1 = Get-HVQueryFilter data.name -Startswith vmware
```

$filter2 = Get-HVQueryFilter data.name -Contains pool
Get-HVQueryFilter -Or @($filter1, $filter2)
Creates queryFilterOr with given parameter filters array

## PARAMETERS

### -MemberName
Property path separated by .
(dot) from the root of queryable data object which is being queried for

```yaml
Type: String
Parameter Sets: ne, startswith, contains, eq
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Eq
Switch to create QueryFilterEquals filter

```yaml
Type: SwitchParameter
Parameter Sets: eq
Aliases:

Required: True
Position: 2
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Contains
Switch to create QueryFilterContains filter

```yaml
Type: SwitchParameter
Parameter Sets: contains
Aliases:

Required: True
Position: 2
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Startswith
Switch to create QueryFilterStartsWith filter

```yaml
Type: SwitchParameter
Parameter Sets: startswith
Aliases:

Required: True
Position: 2
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Ne
Switch to create QueryFilterNotEquals filter

```yaml
Type: SwitchParameter
Parameter Sets: ne
Aliases:

Required: True
Position: 2
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -MemberValue
Value of property (memberName) which is used for filtering

```yaml
Type: Object
Parameter Sets: ne, startswith, contains, eq
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Not
Switch to create QueryFilterNot filter, used for negating existing filter

```yaml
Type: SwitchParameter
Parameter Sets: not
Aliases:

Required: True
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Filter to used in QueryFilterNot to negate the result

```yaml
Type: QueryFilter
Parameter Sets: not
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -And
Switch to create QueryFilterAnd filter, used for joing two or more filters

```yaml
Type: SwitchParameter
Parameter Sets: and
Aliases:

Required: True
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Or
Switch to create QueryFilterOr filter, used for joing two or more filters

```yaml
Type: SwitchParameter
Parameter Sets: or
Aliases:

Required: True
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filters
List of filters to join using QueryFilterAnd or QueryFilterOr

```yaml
Type: QueryFilter[]
Parameter Sets: and, or
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns the QueryFilter object
## NOTES
| | |
|-|-|
| Author | Kummara Ramamohan. |
| Author email | kramamohan@vmware.com |
| Version | 1.1 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.0.2, 7.1.0 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
