---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVInternalName

## SYNOPSIS
Gets human readable name

## SYNTAX

```
Get-HVInternalName [-EntityId] <EntityId> [[-VcId] <VirtualCenterId>] [[-BaseImageVmId] <BaseImageVmId>]
 [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Converts Horizon API Ids to human readable names.
Horizon API Ids are base64 encoded, this function
will decode and returns internal/human readable names.

## EXAMPLES

### EXAMPLE 1
```
Get-HVInternalName -EntityId $entityId
```

Decodes Horizon API Id and returns human readable name

## PARAMETERS

### -EntityId
Representation of a manageable entity id.

```yaml
Type: EntityId
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VcId
{{ Fill VcId Description }}

```yaml
Type: VirtualCenterId
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BaseImageVmId
{{ Fill BaseImageVmId Description }}

```yaml
Type: BaseImageVmId
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
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
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns human readable name
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
