---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVResourceStructure

## SYNOPSIS
Output the structure of the resource pools available to a HV. 
Primarily this is for debugging

PS\> Get-HVResourceStructure
vCenter vc.domain.local
Container DC path /DC/host
HostOrCluster Servers path /DC/host/Servers
HostOrCluster VDI path /DC/host/VDI
ResourcePool Servers path /DC/host/Servers/Resources
ResourcePool VDI path /DC/host/VDI/Resources
ResourcePool RP1 path /DC/host/VDI/Resources/RP1
ResourcePool RP2 path /DC/host/VDI/Resources/RP1/RP2

| Author | Mark Elvers \<mark.elvers@tunbury.org\> |

## SYNTAX

```
Get-HVResourceStructure [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -HvServer
{{ Fill HvServer Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS