---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVEvent

## SYNOPSIS
Queries the events from event database configured on Connection Server.

## SYNTAX

```
Get-HVEvent [-HvDbServer] <PSObject> [[-TimePeriod] <String>] [[-FilterType] <String>] [[-UserFilter] <String>]
 [[-SeverityFilter] <String>] [[-TimeFilter] <String>] [[-ModuleFilter] <String>] [[-MessageFilter] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
This function is used to query the events information from event database.
It returns the object that has events in five columns as UserName, Severity, EventTime, Module and Message.
EventTime will show the exact time when the event got registered in the database and it follows timezone on database server.
User can apply different filters on the event columns using the filter parameters userFilter, severityFilter, timeFilter, moduleFilter, messageFilter.
Mention that when multiple filters are provided then rows which satisify all the filters will be returned.

## EXAMPLES

### EXAMPLE 1
```
$e = Get-HVEvent -hvDbServer $hvDbServer
```

$e.Events
Querying all the database events on database $hvDbServer.

### EXAMPLE 2
```
$e = Get-HVEvent -HvDbServer $hvDbServer -TimePeriod 'all' -FilterType 'startsWith' -UserFilter 'aduser' -SeverityFilter 'err' -TimeFilter 'HH:MM:SS.fff' -ModuleFilter 'broker' -MessageFilter 'aduser'
```

$e.Events | Export-Csv -Path 'myEvents.csv' -NoTypeInformation
Querying all the database events where user name startswith 'aduser', severity is of 'err' type, having module name as 'broker', message starting with 'aduser' and time starting with 'HH:MM:SS.fff'.
The resulting events will be exported to a csv file 'myEvents.csv'.

## PARAMETERS

### -HvDbServer
Connection object returned by Connect-HVEvent advanced function.

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

### -TimePeriod
Timeperiod of the events that user is interested in.
It can take following four values:
   'day' - Lists last one day events from database
   'week' - Lists last 7 days events from database
   'month' - Lists last 30 days events from database
   'all' - Lists all the events stored in database

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilterType
Type of filter action to be applied.
The parameters userfilter, severityfilter, timefilter, modulefilter, messagefilter can be used along with this.
It can take following values:
   'contains' - Retrieves the events that contains the string specified in filter parameters
   'startsWith' - Retrieves the events that starts with the string specified in filter parameters
   'isExactly' - Retrieves the events that exactly match with the string specified in filter parameters

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Contains
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserFilter
String that can applied in filtering on 'UserName' column.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SeverityFilter
String that can applied in filtering on 'Severity' column.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeFilter
String that can applied in filtering on 'EventTime' column.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleFilter
String that can applied in filtering on 'Module' column.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MessageFilter
String that can applied in filtering on 'Message' column.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns a custom object that has events information in 'Events' property. Events property will have events information with five columns: UserName, Severity, EventTime, Module and Message.
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
