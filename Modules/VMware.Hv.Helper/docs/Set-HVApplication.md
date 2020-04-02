---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Set-HVApplication

## SYNOPSIS
Updates settings for an existing Application Pool.

## SYNTAX

```
Set-HVApplication [-HvServer <ViewServerImpl>] [-Name] <String> [-DisplayName <String>] [-Description <String>]
 [-ExecutablePath <String>] [-Version <String>] [-Publisher <String>] [-Enabled <Boolean>]
 [-EnablePreLaunch <Boolean>] [-ConnectionServerRestrictions <String[]>] [-CategoryFolderName <String>]
 [-clientRestrictions <Boolean>] [-ShortcutLocations <String[]>] [-StartFolder <String>] [-Args <String>]
 [-AutoUpdateFileTypes <Boolean>] [-AutoUpdateOtherFileTypes <Boolean>]
 [-GlobalApplicationEntitlement <String>] [<CommonParameters>]
```

## DESCRIPTION
Updates settings for an existing Application Pool.
It does not update the Application Icon.
See Set-HVApplicationIcon for a function to update icons.
This function specifically targets ApplicationInfo.Data and Application.ExecutionData properties.

## EXAMPLES

### EXAMPLE 1
```
New-HVManualApplication -Name 'App1' -DisplayName 'DisplayName' -Description 'ApplicationDescription' -ExecutablePath "PathOfTheExecutable" -Version 'AppVersion' -Publisher 'PublisherName' -Farm 'FarmName'
```

Creates a manual application App1 in the farm specified.

## PARAMETERS

### -HvServer
View API service object of Connect-HVServer cmdlet.

```yaml
Type: ViewServerImpl
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
The Application name is the unique identifier used to identify this Application.
This cannot be updated but is used to specify which application should be updated.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DisplayName
The display name is the name that users will see when they connect to view client.
If the display name is left blank, it defaults to Name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $Name
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Description
The description is a set of notes about the Application.

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

### -ExecutablePath
Path to Application executable.

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

### -Version
Application version.

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

### -Publisher
Application publisher.

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

### -Enabled
Indicates if Application is enabled.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
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

### -ShortcutLocations
Locations of the category folder in the user's OS containing a shortcut to the desktop.
The value must be set if categoryFolderName is provided.

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

### -StartFolder
Starting folder for Application.

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

### -Args
Parameters to pass to application when launching.

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

### -AutoUpdateFileTypes
Whether or not the file types supported by this application should be allowed to automatically update to reflect changes reported by the agent.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -AutoUpdateOtherFileTypes
Whether or not the other file types supported by this application should be allowed to automatically update to reflect changes reported by the agent.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -GlobalApplicationEntitlement
The name of a Global Application Entitlement to associate this Application pool with.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### A success message is displayed when done.
## NOTES
| | |
|-|-|
| Author | Matt Frey |
| Author email | mfrey@vmware.com |
| Version | 1.0 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.8.0 |
| PowerCLI Version | PowerCLI 11.1 |
| PowerShell Version | 5.1 |

## RELATED LINKS
