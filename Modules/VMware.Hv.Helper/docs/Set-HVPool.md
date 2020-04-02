---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Set-HVPool

## SYNOPSIS
Sets the existing pool properties.

## SYNTAX

### option
```
Set-HVPool -PoolName <String> [-Enable] [-Disable] [-Start] [-Stop] [-Key <String>] [-Value <Object>]
 [-Spec <String>] [-globalEntitlement <String>] [-ResourcePool <String>] [-clearGlobalEntitlement]
 [-allowUsersToChooseProtocol <Boolean>] [-enableHTMLAccess <Boolean>] [-HvServer <Object>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### pipeline
```
Set-HVPool [-Pool <Object>] [-Enable] [-Disable] [-Start] [-Stop] [-Key <String>] [-Value <Object>]
 [-Spec <String>] [-globalEntitlement <String>] [-ResourcePool <String>] [-clearGlobalEntitlement]
 [-allowUsersToChooseProtocol <Boolean>] [-enableHTMLAccess <Boolean>] [-HvServer <Object>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This cmdlet allows user to edit pool configuration by passing key/value pair.
Optionally, user can pass a JSON spec file.

## EXAMPLES

### EXAMPLE 1
```
Set-HVPool -PoolName 'ManualPool' -Spec 'C:\Edit-HVPool\EditPool.json' -Confirm:$false
```

Updates pool configuration by using json file

### EXAMPLE 2
```
Set-HVPool -PoolName 'RDSPool' -Key 'base.description' -Value 'update description'
```

Updates pool configuration with given parameters key and value

### EXAMPLE 3
```
Set-HVPool  -PoolName 'LnkClone' -Disable
```

Disables specified pool

### EXAMPLE 4
```
Set-HVPool  -PoolName 'LnkClone' -Enable
```

Enables specified pool

### EXAMPLE 5
```
Set-HVPool  -PoolName 'LnkClone' -Start
```

Enables provisioning to specified pool

### EXAMPLE 6
```
Set-HVPool  -PoolName 'LnkClone' -Stop
```

Disables provisioning to specified pool

## PARAMETERS

### -PoolName
Name of the pool to edit.

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

### -Pool
Object(s) of the pool to edit.

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
Switch parameter to enable the pool.

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
Switch parameter to disable the pool.

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
Switch parameter to start the pool.

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
Switch parameter to stop the pool.

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

### -globalEntitlement
{{ Fill globalEntitlement Description }}

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

### -ResourcePool
{{ Fill ResourcePool Description }}

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

### -clearGlobalEntitlement
{{ Fill clearGlobalEntitlement Description }}

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

### -allowUsersToChooseProtocol
{{ Fill allowUsersToChooseProtocol Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -enableHTMLAccess
{{ Fill enableHTMLAccess Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -HvServer
View API service object of Connect-HVServer cmdlet.

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
| Author | Praveen Mathamsetty. |
| Author email | pmathamsetty@vmware.com |
| Version | 1.2 |
| Updated | Mark Elvers \<mark.elvers@tunbury.org\> |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.0.2, 7.1.0 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
