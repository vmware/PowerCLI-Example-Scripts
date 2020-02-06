---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Remove-HVMachine

## SYNOPSIS
Remove a Horizon View desktop or desktops.

## SYNTAX

```
Remove-HVMachine [-MachineNames] <Array> [-DeleteFromDisk] [[-HVServer] <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Deletes a VM or an array of VM's from Horizon.
Utilizes an Or query filter to match machine names.

## EXAMPLES

### EXAMPLE 1
```
Remove-HVMachine -HVServer 'horizonserver123' -MachineNames 'LAX-WIN10-002'
```

Deletes VM 'LAX-WIN10-002' from HV Server 'horizonserver123'

### EXAMPLE 2
```
Remove-HVMachine -HVServer 'horizonserver123' -MachineNames $machines
```

Deletes VM's contained within an array of machine names from HV Server 'horizonserver123'

### EXAMPLE 3
```
Remove-HVMachine -HVServer 'horizonserver123' -MachineNames 'ManualVM01' -DeleteFromDisk:$false
```

Deletes VM 'ManualVM01' from Horizon inventory, but not from vSphere.
Note this only works for Full Clone VMs.

## PARAMETERS

### -MachineNames
The name or names of the machine(s) to be deleted.
Accepts a single VM or an array of VM names.This is a mandatory parameter.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeleteFromDisk
Determines whether the Machine VM should be deleted from vCenter Server.
This is only applicable for managed machines.
This must always be true for machines in linked and instant clone desktops.
This defaults to true for linked and instant clone machines and false for all other types.

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

### -HVServer
The Horizon server where the machine to be deleted resides.
Parameter is not mandatory,
      but if you do not specify the server, than make sure you are connected to a Horizon server
      first with connect-hvserver.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
| Author | Jose Rodriguez |
| Author email | jrodsguitar@gmail.com |
| Version | 1.0 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.1.1 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
