---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# New-HVEntitlement

## SYNOPSIS
Associates a user/group with a resource

## SYNTAX

### Default
```
New-HVEntitlement -User <String> -ResourceName <String> [-ResourceType <String>] [-Type <String>]
 [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PipeLine
```
New-HVEntitlement -User <String> -Resource <Object> [-ResourceType <String>] [-Type <String>]
 [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This represents a simple association between a single user/group and a resource that they can be assigned.

## EXAMPLES

### EXAMPLE 1
```
New-HVEntitlement  -User 'administrator@adviewdev.eng.vmware.com' -ResourceName 'InsClnPol' -Confirm:$false
```

Associate a user/group with a pool

### EXAMPLE 2
```
New-HVEntitlement  -User 'adviewdev\administrator' -ResourceName 'Calculator' -ResourceType Application
```

Associate a user/group with a application

### EXAMPLE 3
```
New-HVEntitlement  -User 'adviewdev.eng.vmware.com\administrator' -ResourceName 'UrlSetting1' -ResourceType URLRedirection
```

Associate a user/group with a URLRedirection settings

### EXAMPLE 4
```
New-HVEntitlement  -User 'adviewdev.eng.vmware.com\administrator' -ResourceName 'GE1' -ResourceType GlobalEntitlement
```

Associate a user/group with a desktop entitlement

### EXAMPLE 5
```
New-HVEntitlement  -User 'adviewdev\administrator' -ResourceName 'GEAPP1' -ResourceType GlobalApplicationEntitlement
```

Associate a user/group with a application entitlement

### EXAMPLE 6
```
$pools = Get-HVPool; $pools | New-HVEntitlement  -User 'adviewdev\administrator' -Confirm:$false
```

Associate a user/group with list of pools

## PARAMETERS

### -User
User principal name of user or group

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceName
The resource(Application, Desktop etc.) name.
Supports only wildcard character '*' when resource type is desktop.

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

### -Resource
Object(s) of the resource(Application, Desktop etc.) to entitle

```yaml
Type: Object
Parameter Sets: PipeLine
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ResourceType
Type of Resource(Application, Desktop etc)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Desktop
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
Position: Named
Default value: User
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
