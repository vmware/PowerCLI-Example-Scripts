---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Set-HVGlobalEntitlement

## SYNOPSIS
Sets the existing pool properties.

## SYNTAX

### option
```
Set-HVGlobalEntitlement -displayName <String> [-Key <String>] [-Value <Object>] [-Spec <String>] [-Enable]
 [-Disable] [-enableHTMLAccess <Boolean>] [-HvServer <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### pipeline
```
Set-HVGlobalEntitlement [-GlobalEntitlements <Object>] [-Key <String>] [-Value <Object>] [-Spec <String>]
 [-Enable] [-Disable] [-enableHTMLAccess <Boolean>] [-HvServer <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
This cmdlet allows user to edit global entitlements.

## EXAMPLES

### EXAMPLE 1
```
Set-HVGlobalEntitlement -DisplayName 'MyGlobalEntitlement' -Spec 'C:\Edit-HVPool\EditPool.json' -Confirm:$false
```

Updates pool configuration by using json file

### EXAMPLE 2
```
Set-HVGlobalEntitlement -DisplayName 'MyGlobalEntitlement' -Key 'base.description' -Value 'update description'
```

Updates pool configuration with given parameters key and value

### EXAMPLE 3
```
Set-HVGlobalEntitlement -DisplayName 'MyGlobalEntitlement' -enableHTMLAccess $true
```

Set Allow HTML Access on a global entitlement. 
Note that it must also be enabled on the Pool and as of 7.3.0 Allow User to Choose Protocol must be enabled (which is unfortunately read-only)

### EXAMPLE 4
```
Get-HVGlobalEntitlement | Set-HVGlobalEntitlement -Disable
```

Disable all global entitlements

## PARAMETERS

### -displayName
Display Name of Global Entitlement.

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

### -GlobalEntitlements
{{ Fill GlobalEntitlements Description }}

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

### -Enable
{{ Fill Enable Description }}

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
{{ Fill Disable Description }}

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

### -enableHTMLAccess
If set to true, the desktops that are associated with this GlobalEntitlement must also have HTML Access enabled.

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
Author                      : Mark Elvers
Author email                : mark.elvers@tunbury.org
Version                     : 1.0

===Tested Against Environment====
| | |
|-|-|
Horizon View Server Version : 7.3.0, 7.3.1
PowerCLI Version            : PowerCLI 6.5.1
PowerShell Version          : 5.0

## RELATED LINKS
