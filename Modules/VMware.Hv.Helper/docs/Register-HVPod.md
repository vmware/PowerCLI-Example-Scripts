---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Register-HVPod

## SYNOPSIS
Registers a pod in a Horizon View Pod Federation (Cloud Pod Architecture)

## SYNTAX

```
Register-HVPod [-remoteconnectionserver] <String> [-ADUserName] <String> [-ADpassword] <SecureString>
 [[-HvServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Registers a pod in a Horizon View Pod Federation.
You have to be connected to the pod you are joining to the federation.

## EXAMPLES

### EXAMPLE 1
```
$adpassword = Read-Host 'Domain Password' -AsSecureString
```

register-hvpod -remoteconnectionserver "servername" -username "user\domain" -password $adpassword

### EXAMPLE 2
```
register-hvpod -remoteconnectionserver "servername" -username "user\domain"
```

It will now ask for the password

## PARAMETERS

### -remoteconnectionserver
Servername of a connectionserver that already belongs to the PodFederation

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

### -ADUserName
User principal name of user this is required to be in the domain\username format

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ADpassword
Password of the type Securestring.
Can be created with:
$password = Read-Host 'Domain Password' -AsSecureString

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
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
Position: 4
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
| Horizon View Server Version | 7.3.2,7.4 |
| PowerCLI Version | PowerCLI 6.5, PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
