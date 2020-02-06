---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVEntitlement

## SYNOPSIS
Gets association data between a user/group and a resource

## SYNTAX

```
Get-HVEntitlement [[-User] <String>] [[-Type] <String>] [[-ResourceName] <String>] [[-ResourceType] <String>]
 [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Provides entitlement Info between a single user/group and a resource that they can be assigned.

## EXAMPLES

### EXAMPLE 1
```
Get-HVEntitlement -ResourceType Application
```

Gets all the entitlements related to application pool

### EXAMPLE 2
```
Get-HVEntitlement -User 'adviewdev.eng.vmware.com\administrator' -ResourceName 'calculator' -ResourceType Application
```

Gets entitlements specific to user or group name and application resource

### EXAMPLE 3
```
Get-HVEntitlement -User 'adviewdev.eng.vmware.com\administrator' -ResourceName 'UrlSetting1' -ResourceType URLRedirection
```

Gets entitlements specific to user or group and URLRedirection resource

### EXAMPLE 4
```
Get-HVEntitlement -User 'administrator@adviewdev.eng.vmware.com' -ResourceName 'GE1' -ResourceType GlobalEntitlement
```

Gets entitlements specific to user or group and GlobalEntitlement resource

## PARAMETERS

### -User
User principal name of user or group

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

### -Type
Whether or not this is a group or a user.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: User
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

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceType
Type of Resource(Application, Desktop etc.)

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
