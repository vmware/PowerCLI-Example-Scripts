---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Get-HVApplication

## SYNOPSIS
Gets the application information.

## SYNTAX

```
Get-HVApplication [[-ApplicationName] <String>] [[-HvServer] <Object>] [[-FormatList] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Gets the application information.
This will be useful to find out whether the specified application exists or not.
If the application name is not specified, this will lists all the applications in the Pod.

## EXAMPLES

### EXAMPLE 1
```
Get-HVApplication -ApplicationName 'App1' -HvServer $HvServer
```

Queries and returns 'App1' information.

### EXAMPLE 2
```
Get-HVApplication -HvServer $HvServer -FormatList:$True
```

Lists all the applications in the Pod.

## PARAMETERS

### -ApplicationName
Name of the application.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -HvServer
View API service object of Connect-HVServer cmdlet.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -FormatList
Displays the list of the available applications in Table Format if this parameter is set to True.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns the information of the specified application if it specified, else displays all the available applications.
## NOTES
| | |
|-|-|
| Author | Samiullasha S |
| Author email | ssami@vmware.com |
| Version | 1.2 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.8.0 |
| PowerCLI Version | PowerCLI 11.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
