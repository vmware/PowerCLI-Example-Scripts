---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVQueryResult

## SYNOPSIS
Returns the query results from ViewApi Query Service

## SYNTAX

```
Get-HVQueryResult [-EntityType] <String> [[-Filter] <QueryFilter>] [[-SortBy] <String>]
 [[-SortDescending] <Boolean>] [[-Limit] <Int16>] [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Get-HVQueryResult is a API to query the results using ViewApi.
The filtering of the returned
list would be done based on input parameters filter, sortDescending, sortyBy, limit

## EXAMPLES

### EXAMPLE 1
```
Get-HVQueryResult DesktopSummaryView
```

Returns query results of entityType DesktopSummaryView(position 0)

### EXAMPLE 2
```
Get-HVQueryResult DesktopSummaryView (Get-HVQueryFilter data.name -Eq vmware)
```

Returns query results of entityType DesktopSummaryView(position 0) with given filter(position 1)

### EXAMPLE 3
```
Get-HVQueryResult -EntityType DesktopSummaryView -Filter (Get-HVQueryFilter desktopSummaryData.name -Eq vmware)
```

Returns query results of entityType DesktopSummaryView with given filter

### EXAMPLE 4
```
$myFilter = Get-HVQueryFilter data.name -Contains vmware
```

Get-HVQueryResult -EntityType DesktopSummaryView -Filter $myFilter -SortBy desktopSummaryData.displayName -SortDescending $false
Returns query results of entityType DesktopSummaryView with given filter and also sorted based on dispalyName

### EXAMPLE 5
```
Get-HVQueryResult DesktopSummaryView -Limit 10
```

Returns query results of entityType DesktopSummaryView, maximum count equal to limit

## PARAMETERS

### -EntityType
ViewApi Queryable entity type which is being queried for.The return list would be containing objects of entityType

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

### -Filter
Filter to used for filtering the results, See Get-HVQueryFilter for more information

```yaml
Type: QueryFilter
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SortBy
Data field path used for sorting the results

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SortDescending
If the value is set to true (default) then the results will be sorted in descending order
If the value is set to false then the results will be sorted in ascending order

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Limit
Max number of objects to retrieve.
Default would be 0 which means retieve all the results

```yaml
Type: Int16
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -HvServer
Reference to Horizon View Server to query the data from.
If the value is not passed or null then
first element from global:DefaultHVServers would be considered in-place of hvServer

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns the list of objects of entityType
## NOTES
| | |
|-|-|
| Author | Kummara Ramamohan. |
| Author email | kramamohan@vmware.com |
| Version | 1.1 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.0.2, 7.1.0,7.4 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1, PowerCLI 10.1.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
