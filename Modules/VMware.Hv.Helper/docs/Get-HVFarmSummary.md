---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVFarmSummary

## SYNOPSIS
This function is used to find farms based on the search criteria provided by the user.

## SYNTAX

```
Get-HVFarmSummary [[-FarmName] <String>] [[-FarmDisplayName] <String>] [[-FarmType] <String>]
 [[-Enabled] <Boolean>] [[-SuppressInfo] <Boolean>] [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
This function queries the specified Connection Server for farms which are configured on the server.
If no farm is configured on the specified connection server or no farm matches the given search criteria, it will return null.

## EXAMPLES

### EXAMPLE 1
```
Get-HVFarmSummary -FarmName 'Farm-01'
```

Queries and returns farmSummary objects based on given parameter farmName

### EXAMPLE 2
```
Get-HVFarmSummary -FarmName 'Farm-01' -FarmDisplayName 'Sales RDS Farm'
```

Queries and returns farmSummary objects based on given parameters farmName, farmDisplayName

### EXAMPLE 3
```
Get-HVFarmSummary -FarmName 'Farm-01' -FarmType 'MANUAL'
```

Queries and returns farmSummary objects based on given parameters farmName, farmType

### EXAMPLE 4
```
Get-HVFarmSummary -FarmName 'Farm-01' -FarmType 'MANUAL' -Enabled $true
```

Queries and returns farmSummary objects based on given parameters farmName, FarmType etc

### EXAMPLE 5
```
Get-HVFarmSummary -FarmName 'Farm-0*'
```

Queries and returns farmSummary objects based on given parameter farmName with wild character *

## PARAMETERS

### -FarmName
FarmName to be searched

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

### -FarmDisplayName
FarmDisplayName to be searched

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

### -FarmType
FarmType to be searched.
It can take following values:
"AUTOMATED"	- search for automated farms only
'MANUAL' - search for manual farms only

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

### -Enabled
Search for farms which are enabled

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SuppressInfo
Suppress text info, when no farm found with given search parameters

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -HvServer
Reference to Horizon View Server to query the data from.
If the value is not passed or null then first element from global:DefaultHVServers would be considered in-place of hvServer.

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

### Returns the list of FarmSummary object matching the query criteria.
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
