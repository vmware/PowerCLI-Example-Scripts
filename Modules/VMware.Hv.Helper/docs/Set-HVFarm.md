---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Set-HVFarm

## SYNOPSIS
Edit farm configuration by passing key/values as parameters/json.

## SYNTAX

### option
```
Set-HVFarm -FarmName <String> [-Enable] [-Disable] [-Start] [-Stop] [-Key <String>] [-Value <Object>]
 [-Spec <String>] [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### pipeline
```
Set-HVFarm [-Farm <Object>] [-Enable] [-Disable] [-Start] [-Stop] [-Key <String>] [-Value <Object>]
 [-Spec <String>] [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function allows user to edit farm configuration by passing key/value pairs.
Optionally, user can pass a JSON spec file.
User can also pipe the farm object(s) as input to this function.

## EXAMPLES

### EXAMPLE 1
```
Set-HVFarm -FarmName 'Farm-01' -Spec 'C:\Edit-HVFarm\ManualEditFarm.json' -Confirm:$false
```

Updates farm configuration by using json file

### EXAMPLE 2
```
Set-HVFarm -FarmName 'Farm-01' -Key 'base.description' -Value 'updated description'
```

Updates farm configuration with given parameters key and value

### EXAMPLE 3
```
$farm_array | Set-HVFarm -Key 'base.description' -Value 'updated description'
```

Updates farm(s) configuration with given parameters key and value

### EXAMPLE 4
```
Set-HVFarm -farm 'Farm2' -Start
```

Enables provisioning to specified farm

### EXAMPLE 5
```
Set-HVFarm -farm 'Farm2' -Enable
```

Enables specified farm

## PARAMETERS

### -FarmName
Name of the farm to edit.

```yaml
Type: String
Parameter Sets: option
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Farm
Object(s) of the farm to edit.
Object(s) should be of type FarmSummaryView/FarmInfo.

```yaml
Type: Object
Parameter Sets: pipeline
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Enable
Switch to enable the farm(s).

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Disable
Switch to disable the farm(s).

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Start
Switch to enable provisioning immediately for the farm(s).
It's applicable only for 'AUTOMATED' farm type.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Stop
Switch to disable provisioning immediately for the farm(s).
It's applicable only for 'AUTOMATED' farm type.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Key
Property names path separated by .
(dot) from the root of desktop spec.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
Property value corresponds to above key name.

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

### -Spec
Path of the JSON specification file containing key/value pair.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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

### None
## NOTES
| | |
|-|-|
| Author | praveen mathamsetty. |
| Author email | pmathamsetty@vmware.com |
| Version | 1.1 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.0.2, 7.1.0 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
