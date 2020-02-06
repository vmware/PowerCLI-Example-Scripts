---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Connect-HVEvent

## SYNOPSIS
This function is used to connect to the event database configured on Connection Server.

## SYNTAX

```
Connect-HVEvent [[-DbPassword] <SecureString>] [[-HvServer] <Object>] [[-DbUserName] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
This function queries the specified Connection Server for event database configuration and returns the connection object to it.
If event database is not configured on specified connection server, it will return null.
Currently, Horizon 7 is supporting SQL server and Oracle 12c as event database servers.
To configure event database, goto 'Event Database Configuration' tab in Horizon admin UI.

## EXAMPLES

### EXAMPLE 1
```
Connect-HVEvent -HvServer $hvServer
```

Connecting to the database with default username configured on Connection Server $hvServer.

### EXAMPLE 2
```
$hvDbServer = Connect-HVEvent -HvServer $hvServer -DbUserName 'system'
```

Connecting to the database configured on Connection Server $hvServer with customised user name 'system'.

### EXAMPLE 3
```
$hvDbServer = Connect-HVEvent -HvServer $hvServer -DbUserName 'system' -DbPassword 'censored'
```

Connecting to the database with customised user name and password.

### EXAMPLE 4
```
$password = Read-Host 'Database Password' -AsSecureString
```

$hvDbServer = Connect-HVEvent -HvServer $hvServer -DbUserName 'system' -DbPassword $password
Connecting to the database with customised user name and password, with password being a SecureString.

## PARAMETERS

### -DbPassword
Password corresponds to 'dbUserName' user.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DbUserName
User name to be used in database connection.
If not passed, default database user name on the Connection Server will be used.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns a custom object that has database connection as 'dbConnection' property.
## NOTES
| | |
|-|-|
| Author | Paramesh Oddepally. |
| Author email | poddepally@vmware.com |
| Version | 1.1 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.0.2, 7.1.0 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
