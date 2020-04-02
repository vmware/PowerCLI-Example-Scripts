---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Remove-HVEntitlement

## SYNOPSIS
Deletes association data between a user/group and a resource

## SYNTAX

```
Remove-HVEntitlement [-User] <String> [-ResourceName] <String> [[-Type] <String>] [[-ResourceType] <String>]
 [[-HvServer] <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Removes entitlement between a single user/group and a resource that already been assigned.

## EXAMPLES

### EXAMPLE 1
```
Remove-HVEntitlement -User 'administrator@adviewdev'  -ResourceName LnkClnJSon -Confirm:$false
```

Deletes entitlement between a user/group and a pool resource

### EXAMPLE 2
```
Remove-HVEntitlement -User 'adviewdev\puser2' -ResourceName 'calculator' -ResourceType Application
```

Deletes entitlement between a user/group and a Application resource

### EXAMPLE 3
```
Remove-HVEntitlement -User 'adviewdev\administrator' -ResourceName 'GEAPP1' -ResourceType GlobalApplicationEntitlement
```

Deletes entitlement between a user/group and a GlobalApplicationEntitlement resource

## PARAMETERS

### -User
User principal name of user or group

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

### -ResourceName
The resource(Application, Desktop etc.) name.
Supports only wildcard character '*' when resource type is desktop.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
Whether or not this is a group or a user.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: User
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceType
Type of Resource(Application, Desktop etc)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Desktop
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
Position: 5
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
