---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# New-HVPreInstalledApplication

## SYNOPSIS
Creates a application pool from Pre-installed applications on RDS Server(s).

## SYNTAX

```
New-HVPreInstalledApplication -ApplicationName <String> [-ApplicationID <String>] [-DisplayName <String>]
 -FarmName <String> [-EnablePreLaunch <Boolean>] [-ConnectionServerRestrictions <String[]>]
 [-CategoryFolderName <String>] [-clientRestrictions <Boolean>] [-HvServer <Object>] [<CommonParameters>]
```

## DESCRIPTION
Creates a application pool from Pre-installed applications on RDS Server(s).

## EXAMPLES

### EXAMPLE 1
```
New-HVPreInstalledApplication -ApplicationName 'App1' -DisplayName 'DisplayName' -FarmName 'FarmName'
```

Creates a application App1 from the farm specified.

### EXAMPLE 2
```
New-HVPreInstalledApplication -ApplicationName 'App2' -FarmName FarmManual -EnablePreLaunch $True
```

Creates a application App2 from the farm specified and the PreLaunch option will be enabled.

### EXAMPLE 3
```
New-HVPreInstalledApplication -ApplicationName 'Excel 2016' -ApplicationID 'Excel-2016' -DisplayName 'Excel' -FarmName 'RDS-FARM-01'
```

Creates an application, Excel-2016, from the farm RDS-FARM-01.
The application will display as 'Excel' to the end user.

## PARAMETERS

### -ApplicationName
The Application name to search within the Farm for.
This should match the output of (Get-HVPreinstalledApplication).Name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ApplicationID
The unique identifier for this application.
The ApplicationID can only contain alphanumeric characters, dashes, and underscores.
If ApplicationID is not specified, it will be set to match the ApplicationName, with the spaces converted to underscore (_).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $($ApplicationName -replace " ","_")
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DisplayName
The display name is the name that users will see when they connect with the Horizon Client.
If the display name is left blank, it defaults to ApplicationName.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $ApplicationName
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -FarmName
Farm name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -EnablePreLaunch
Application can be pre-launched if value is true.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ConnectionServerRestrictions
Connection server restrictions.
This is a list of tags that access to the application is restricted to.
Empty/Null list means that the application can be accessed from any connection server.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -CategoryFolderName
Name of the category folder in the user's OS containing a shortcut to the application.
Unset if the application does not belong to a category.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -clientRestrictions
Client restrictions to be applied to Application.
Currently it is valid for RDSH pools.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### A success message is displayed when done.
## NOTES
| | |
|-|-|
| Author | Samiullasha S |
| Author email | ssami@vmware.com |
| Version | 1.0 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.8.0 |
| PowerCLI Version | PowerCLI 11.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
