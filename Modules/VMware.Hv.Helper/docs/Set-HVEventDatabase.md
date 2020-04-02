---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Set-HVEventDatabase

## SYNOPSIS
Registers or changes a Horizon View Event database.

## SYNTAX

```
Set-HVEventDatabase [-ServerName] <String> [[-DatabaseType] <String>] [[-DatabasePort] <Int32>]
 [-DatabaseName] <String> [[-TablePrefix] <String>] [-UserName] <String> [-password] <SecureString>
 [[-eventtime] <String>] [[-eventnewtime] <Int32>] [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Registers or changes a Horizon View Event database

## EXAMPLES

### EXAMPLE 1
```
register-hveventdatabase -server SERVER@domain -database DATABASENAME -username USER@domain -password $password
```

## PARAMETERS

### -ServerName
Name of the database server (Required)

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

### -DatabaseType
Database type, possible options: MYSQL,SQLSERVER,ORACLE.
Defaults to SQLSERVER

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: SQLSERVER
Accept pipeline input: False
Accept wildcard characters: False
```

### -DatabasePort
Port number on the database server to which View will send events.
Defaults to 1433.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 1433
Accept pipeline input: False
Accept wildcard characters: False
```

### -DatabaseName
Name of the Database (required)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TablePrefix
Prefix to use for the Event Databse.
Allowed characters are letters, numbers, and the characters @, $, #,  _, and may not be longer than 6 characters.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserName
UserName to connect to the database (required)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -password
Password of the user connecting to the database in Securestring format.
Can be created with:  $password = Read-Host 'Domain Password' -AsSecureString

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -eventtime
Time to show the events for.
Possible options are ONE_WEEK, TWO_WEEKS, THREE_WEEKS, ONE_MONTH,TWO_MONTHS, THREE_MONTHS, SIX_MONTHS

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: TWO_WEEKS
Accept pipeline input: False
Accept wildcard characters: False
```

### -eventnewtime
Time in days to classify events for new.
Range 1-3

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: 2
Accept pipeline input: False
Accept wildcard characters: False
```

### -HvServer
Reference to Horizon View Server to query the virtual machines from.
If the value is not passed or null then
first element from global:DefaultHVServers would be considered in-place of hvServer

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
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
| Author | Wouter Kursten |
| Author email | wouter@retouw.nl |
| Version | 1.0 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.4 |
| PowerCLI Version | PowerCLI 10 |
| PowerShell Version | 5.0 |

## RELATED LINKS
