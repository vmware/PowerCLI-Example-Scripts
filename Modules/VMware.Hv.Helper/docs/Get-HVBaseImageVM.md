---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVBaseImageVM

## SYNOPSIS
Gets a list of compatible base image virtual machines.

## SYNTAX

### Type (Default)
```
Get-HVBaseImageVM [-HvServer <Object>] [-VirtualCenter <Object>] [-Type <Object>] [<CommonParameters>]
```

### Name
```
Get-HVBaseImageVM [-HvServer <Object>] [-VirtualCenter <Object>] [-Name <String>] [<CommonParameters>]
```

## DESCRIPTION
Queries and returns BaseImageVmInfo for the specified vCenter Server.

## EXAMPLES

### EXAMPLE 1
```
Get-HVBaseImageVM -VirtualCenter 'vCenter1' -Type VDI
```

### EXAMPLE 2
```
Get-HVBaseImageVM -VirtualCenter $vCenter1 -Type ALL
```

### EXAMPLE 3
```
Get-HVBaseImageVM -Name '*WIN10*'
```

## PARAMETERS

### -HvServer
Reference to Horizon View Server to query the virtual machines from.
If the value is not passed or null then
first element from global:DefaultHVServers would be considered in place of hvServer.

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

### -VirtualCenter
A parameter to specify which vCenter Server to check base image VMs for.
It can be specified as a String,
containing the name of the vCenter, or as a vCenter object as returned by Get-HVvCenterServer.
If the value is
not passed or null then first element returned from Get-HVvCenterServer would be considered in place of VirtualCenter.

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

### -Type
A parameter to define the type of compatability to check the base image VM list against.
Valid options are 'VDI', 'RDS', or 'ALL'
'VDI' will return all desktop compatible Base Image VMs.
'RDS' will return all RDSH compatible Base Image VMs.
'ALL' will return all Base Image VMs, regardless of compatibility.
The default value is 'ALL'.

```yaml
Type: Object
Parameter Sets: Type
Aliases:

Required: False
Position: Named
Default value: VDI
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of a virtual machine (if known), to filter Base Image VMs on.
Wildcards are accepted.
If Name is specified, then Type
is not considered for filtering.

```yaml
Type: String
Parameter Sets: Name
Aliases:

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

### Returns array of object type VMware.Hv.BaseImageVmInfo
## NOTES
| | |
|-|-|
| Author | Matt Frey. |
| Author email | mfrey@vmware.com |
| Version | 1.0 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.7 |
| PowerCLI Version | PowerCLI 11.2.0 |
| PowerShell Version | 5.1 |

## RELATED LINKS
