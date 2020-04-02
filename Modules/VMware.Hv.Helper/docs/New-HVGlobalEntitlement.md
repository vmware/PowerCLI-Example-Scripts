---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# New-HVGlobalEntitlement

## SYNOPSIS
Creates a Global Entitlement.

## SYNTAX

```
New-HVGlobalEntitlement [-DisplayName] <String> [-Type] <String> [[-Description] <String>] [[-Scope] <String>]
 [[-Dedicated] <Boolean>] [[-FromHome] <Boolean>] [[-RequireHomeSite] <Boolean>]
 [[-MultipleSessionAutoClean] <Boolean>] [[-Enabled] <Boolean>] [[-SupportedDisplayProtocols] <String[]>]
 [[-DefaultDisplayProtocol] <String>] [[-AllowUsersToChooseProtocol] <Boolean>]
 [[-AllowUsersToResetMachines] <Boolean>] [[-EnableHTMLAccess] <Boolean>] [[-HvServer] <Object>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Global entitlements are used to route users to their resources across multiple pods.
These are persisted in a global ldap instance that is replicated across all pods in a linked mode view set.

## EXAMPLES

### EXAMPLE 1
```
New-HVGlobalEntitlement -DisplayName 'GE_APP' -Type APPLICATION_ENTITLEMENT
```

Creates new global application entitlement

### EXAMPLE 2
```
New-HVGlobalEntitlement -DisplayName 'GE_DESKTOP' -Type DESKTOP_ENTITLEMENT
```

Creates new global desktop entitlement

## PARAMETERS

### -DisplayName
Display Name of Global Entitlement.

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

### -Type
Specify whether to create desktop/app global entitlement

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

### -Description
Description of Global Entitlement.

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

### -Scope
Scope for this global entitlement.
Visibility and Placement policies are defined by this value.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: ANY
Accept pipeline input: False
Accept wildcard characters: False
```

### -Dedicated
Specifies whether dedicated/floating resources associated with this global entitlement.

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

### -FromHome
This value defines the starting location for resource placement and search.
When true, a pod in the user's home site is used to start the search.
When false, the current site is used.

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

### -RequireHomeSite
This value determines whether we fail if a home site isn't defined for this global entitlement.

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

### -MultipleSessionAutoClean
This value is used to determine if automatic session clean up is enabled.
This cannot be enabled when this Global Entitlement is associated with a Desktop that has dedicated user assignment.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Enabled
If this Global Entitlement is enabled.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SupportedDisplayProtocols
The set of supported display protocols for the global entitlement.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: @("PCOIP","BLAST")
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultDisplayProtocol
The default display protocol for the global entitlement.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: PCOIP
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowUsersToChooseProtocol
Whether the users can choose the protocol used.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowUsersToResetMachines
Whether users are allowed to reset/restart their machines.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableHTMLAccess
If set to true, the desktops that are associated with this GlobalEntitlement must also have HTML Access enabled.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: False
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
Position: 15
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
