---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Add-HVDesktop

## SYNOPSIS
Adds virtual machine to existing pool

## SYNTAX

```
Add-HVDesktop [-PoolName] <String> [-Machines] <String[]> [[-Users] <String[]>] [[-Vcenter] <String>]
 [[-HvServer] <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Add-HVDesktop adds virtual machines to already exiting pools by using view API service object(hvServer) of Connect-HVServer cmdlet.
VMs can be added to any of unmanaged manual, managed manual or Specified name.
This advanced function do basic checks for pool and view API service connection existance, hvServer object is bound to specific connection server.

## EXAMPLES

### EXAMPLE 1
```
Add-HVDesktop -PoolName 'ManualPool' -Machines 'manualPool1', 'manualPool2' -Confirm:$false
```

Add managed manual VMs to existing manual pool

### EXAMPLE 2
```
Add-HVDesktop -PoolName 'SpecificNamed' -Machines 'vm-01', 'vm-02' -Users 'user1', 'user2'
```

Add virtual machines to automated specific named dedicated pool

### EXAMPLE 3
```
Add-HVDesktop -PoolName 'SpecificNamed' -Machines 'vm-03', 'vm-04'
```

Add machines to automated specific named Floating pool

### EXAMPLE 4
```
Add-HVDesktop -PoolName 'Unmanaged' -Machines 'desktop-1.eng.vmware.com'
```

Add machines to unmanged manual pool

## PARAMETERS

### -PoolName
Pool name to which new VMs are to be added.

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

### -Machines
List of virtual machine names which need to be added to the given pool.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Users
List of virtual machine users for given machines.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Vcenter
Virtual Center server-address (IP or FQDN) of the given pool.
This should be same as provided to the Connection Server while adding the vCenter server.

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

### -HvServer
View API service object of Connect-HVServer cmdlet.

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
| Author | Praveen Mathamsetty |
| Author email | pmathamsetty@vmware.com |
| Version | 1.1 |
| Dependencies | Make sure pool already exists before adding VMs to it. |


### Tested Against Environment
| | |
|-|-|
| Horizon View Server Version |  7.0.2, 7.1.0 |
| PowerCLI Version |  PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version |  5.0 |

## RELATED LINKS
