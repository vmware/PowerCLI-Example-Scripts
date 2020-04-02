---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVPoolSummary

## SYNOPSIS
Gets pool summary with given search parameters.

## SYNTAX

```
Get-HVPoolSummary [[-PoolName] <String>] [[-PoolDisplayName] <String>] [[-PoolType] <String>]
 [[-UserAssignment] <String>] [[-Enabled] <Boolean>] [[-ProvisioningEnabled] <Boolean>]
 [[-SuppressInfo] <Boolean>] [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Queries and returns pools information, the pools list would be determined based on
queryable fields poolName, poolDisplayName, poolType, userAssignment, enabled,
provisioningEnabled.
When more than one fields are used for query the pools which
satisfy all fields criteria would be returned.

## EXAMPLES

### EXAMPLE 1
```
Get-HVPoolSummary -PoolName 'mypool' -PoolType MANUAL -UserAssignment FLOATING -Enabled $true -ProvisioningEnabled $true
```

Queries and returns desktopSummaryView based on given parameters poolName, poolType etc.

### EXAMPLE 2
```
Get-HVPoolSummary -PoolType AUTOMATED -UserAssignment FLOATING
```

Queries and returns desktopSummaryView based on given parameters poolType, userAssignment.

### EXAMPLE 3
```
Get-HVPoolSummary -PoolName 'myrds' -PoolType RDS -UserAssignment DEDICATED -Enabled $false
```

Queries and returns desktopSummaryView based on given parameters poolName, poolType, userAssignment etc.

### EXAMPLE 4
```
Get-HVPoolSummary -PoolName 'myrds' -PoolType RDS -UserAssignment DEDICATED -Enabled $false -HvServer $mycs
```

Queries and returns desktopSummaryView based on given parameters poolName, HvServer etc.

## PARAMETERS

### -PoolName
Pool name to query for.
If the value is null or not provided then filter will not be applied,
otherwise the pools which has name same as value will be returned.

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

### -PoolDisplayName
Pool display name to query for.
If the value is null or not provided then filter will not be applied,
otherwise the pools which has display name same as value will be returned.

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

### -PoolType
Pool type to filter with.
If the value is null or not provided then filter will not be applied.
If the value is MANUAL then only manual pools would be returned.
If the value is AUTOMATED then only automated pools would be returned
If the value is RDS then only Remote Desktop Service Pool pools would be returned

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

### -UserAssignment
User Assignment of pool to filter with.
If the value is null or not provided then filter will not be applied.
If the value is DEDICATED then only dedicated pools would be returned.
If the value is FLOATING then only floating pools would be returned

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

### -Enabled
Pool enablement to filter with.
If the value is not provided then then filter will not be applied.
If the value is true then only pools which are enabled would be returned.
If the value is false then only pools which are disabled would be returned.

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

### -ProvisioningEnabled
{{ Fill ProvisioningEnabled Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SuppressInfo
Suppress text info, when no pool found with given search parameters

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -HvServer
Reference to Horizon View Server to query the pools from.
If the value is not passed or null then
first element from global:DefaultHVServers would be considered in-place of hvServer

```yaml
Type: Object
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

### Returns list of DesktopSummaryView
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
