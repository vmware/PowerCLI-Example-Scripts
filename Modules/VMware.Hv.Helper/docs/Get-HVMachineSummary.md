---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVMachineSummary

## SYNOPSIS
Gets virtual Machine(s) summary with given search parameters.

## SYNTAX

```
Get-HVMachineSummary [[-PoolName] <String>] [[-MachineName] <String>] [[-DnsName] <String>] [[-State] <String>]
 [[-JsonFilePath] <String>] [[-SuppressInfo] <Boolean>] [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Queries and returns virtual machines information, the machines list would be determined
based on queryable fields poolName, dnsName, machineName, state.
When more than one
fields are used for query the virtual machines which satisfy all fields criteria would be returned.

## EXAMPLES

### EXAMPLE 1
```
Get-HVMachineSummary -PoolName 'ManualPool'
```

Queries VM(s) with given parameter poolName

### EXAMPLE 2
```
Get-HVMachineSummary -MachineName 'PowerCLIVM'
```

Queries VM(s) with given parameter machineName

### EXAMPLE 3
```
Get-HVMachineSummary -State CUSTOMIZING
```

Queries VM(s) with given parameter vm state

### EXAMPLE 4
```
Get-HVMachineSummary -DnsName 'powercli-*'
```

Queries VM(s) with given parameter dnsName with wildcard character *

## PARAMETERS

### -PoolName
Pool name to query for.
If the value is null or not provided then filter will not be applied,
otherwise the virtual machines which has name same as value will be returned.

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

### -MachineName
The name of the Machine to query for.
If the value is null or not provided then filter will not be applied,
otherwise the virtual machines which has display name same as value will be returned.

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

### -DnsName
DNS name for the Machine to filter with.
If the value is null or not provided then filter will not be applied,
otherwise the virtual machines which has display name same as value will be returned.

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

### -State
The basic state of the Machine to filter with.
If the value is null or not provided then filter will not be applied,
otherwise the virtual machines which has display name same as value will be returned.

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

### -JsonFilePath
{{ Fill JsonFilePath Description }}

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

### -SuppressInfo
Suppress text info, when no machine found with given search parameters

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

### -HvServer
Reference to Horizon View Server to query the virtual machines from.
If the value is not passed or null then
first element from global:DefaultHVServers would be considered in-place of hvServer

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns list of objects of type MachineNamesView
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
