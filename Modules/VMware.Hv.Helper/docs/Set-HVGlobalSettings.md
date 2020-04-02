---
external help file: VMware.HV.Helper-help.xml
Module Name: VMware.HV.Helper
online version:
schema: 2.0.0
---

# Set-HVGlobalSettings

## SYNOPSIS
Sets the Global Settings of the Connection Server Pod

## SYNTAX

```
Set-HVGlobalSettings [[-Key] <String>] [[-Value] <Object>] [[-Spec] <String>]
 [[-clientMaxSessionTimePolicy] <String>] [[-clientMaxSessionTimeMinutes] <Int32>]
 [[-clientIdleSessionTimeoutPolicy] <String>] [[-clientIdleSessionTimeoutMinutes] <Int32>]
 [[-clientSessionTimeoutMinutes] <Int32>] [[-desktopSSOTimeoutPolicy] <String>]
 [[-desktopSSOTimeoutMinutes] <Int32>] [[-applicationSSOTimeoutPolicy] <String>]
 [[-applicationSSOTimeoutMinutes] <Int32>] [[-viewAPISessionTimeoutMinutes] <Int32>]
 [[-preLoginMessage] <String>] [[-displayWarningBeforeForcedLogoff] <Boolean>]
 [[-forcedLogoffTimeoutMinutes] <Int32>] [[-forcedLogoffMessage] <String>]
 [[-enableServerInSingleUserMode] <Boolean>] [[-storeCALOnBroker] <Boolean>] [[-storeCALOnClient] <Boolean>]
 [[-reauthSecureTunnelAfterInterruption] <Boolean>] [[-messageSecurityMode] <String>]
 [[-enableIPSecForSecurityServerPairing] <Boolean>] [[-HvServer] <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
This cmdlet allows user to set Global Settings by passing key/value pair or by passing specific parameters.
Optionally, user can pass a JSON spec file.

## EXAMPLES

### EXAMPLE 1
```
Set-HVGlobalSettings 'ManualPool' -Spec 'C:\Set-HVGlobalSettings\Set-GlobalSettings.json'
```

### EXAMPLE 2
```
Set-HVGlobalSettings -Key 'generalData.clientMaxSessionTimePolicy' -Value 'NEVER'
```

### EXAMPLE 3
```
Set-HVGlobalSettings -clientMaxSessionTimePolicy "TIMEOUT_AFTER" -clientMaxSessionTimeMinutes 1200
```

## PARAMETERS

### -Key
Property names path separated by .
(dot) from the root of global settings spec.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
Property value corresponds to above key name.

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

### -Spec
Path of the JSON specification file containing key/value pair.

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

### -clientMaxSessionTimePolicy
Client max session lifetime policy.
"TIMEOUT_AFTER" Indicates that the client session times out after a configurable session length (in minutes)
"NEVER" Indicates no absolute client session length (sessions only end due to inactivity)

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

### -clientMaxSessionTimeMinutes
Determines how long a user can keep a session open after logging in to View Connection Server.
The value is set in minutes.
When a session times out, the session is terminated and the View client is disconnected from the resource. 
Default value is 600.
Minimum value is 5.
Maximum value is 600.
This property is required if clientMaxSessionTimePolicy is set to "TIMEOUT_AFTER"

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -clientIdleSessionTimeoutPolicy
Specifies the policy for the maximum time that a that a user can be idle before the broker takes measure to protect the session.
"TIMEOUT_AFTER" Indicates that the user session can be idle for a configurable max time (in minutes) before the broker takes measure to protect the session.
"NEVER" Indicates that the client session is never locked.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -clientIdleSessionTimeoutMinutes
Determines how long a that a user can be idle before the broker takes measure to protect the session.
The value is set in minutes. 
Default value is 15
This property is required if -clientIdleSessionTimeoutPolicy is set to "TIMEOUT_AFTER"

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -clientSessionTimeoutMinutes
Determines the maximum length of time that a Broker session will be kept active if there is no traffic between a client and the Broker.
The value is set in minutes. 
Default value is 1200
Minimum value is 5

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -desktopSSOTimeoutPolicy
The single sign on setting for when a user connects to View Connection Server.
"DISABLE_AFTER" SSO is disabled the specified number of minutes after a user connects to View Connection Server.
"DISABLED" Single sign on is always disabled.
"ALWAYS_ENABLED" Single sign on is always enabled.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -desktopSSOTimeoutMinutes
SSO is disabled the specified number of minutes after a user connects to View Connection Server.
Minimum value is 1
Maximum value is 999

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -applicationSSOTimeoutPolicy
The single sign on timeout policy for application sessions.
"DISABLE_AFTER" SSO is disabled the specified number of minutes after a user connects to View Connection Server.
"DISABLED" Single sign on is always disabled.
"ALWAYS_ENABLED" Single sign on is always enabled.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -applicationSSOTimeoutMinutes
SSO is disabled the specified number of minutes after a user connects to View Connection Server.
Minimum value is 1
Maximum value is 999

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -viewAPISessionTimeoutMinutes
Determines how long (in minutes) an idle View API session continues before the session times out.
Setting the View API session timeout to a high number of minutes increases the risk of unauthorized use of View API.
Use caution when you allow an idle session to persist a long time. 
Default value is 10
Minimum value is 1
Maximum value is 4320

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -preLoginMessage
Displays a disclaimer or another message to View Client users when they log in.
No message will be displayed if this is null.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -displayWarningBeforeForcedLogoff
Displays a warning message when users are forced to log off because a scheduled or immediate update such as a machine-refresh operation is about to start. 
$TRUE or $FALSE

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -forcedLogoffTimeoutMinutes
{{ Fill forcedLogoffTimeoutMinutes Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 16
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -forcedLogoffMessage
The warning to be displayed before logging off the user.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 17
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -enableServerInSingleUserMode
Permits certain RDSServer operating systems to be used for non-RDS Desktops.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 18
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -storeCALOnBroker
Used for configuring whether or not to store the RDS Per Device CAL on Broker. 
$TRUE or $FALSE

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 19
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -storeCALOnClient
Used for configuring whether or not to store the RDS Per Device CAL on client devices.
This value can be true only if the storeCALOnBroker is true. 
$TRUE or $FALSE

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 20
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -reauthSecureTunnelAfterInterruption
Reauthenticate secure tunnel connections after network interruption Determines if user credentials must be reauthenticated after a network interruption when View clients use secure tunnel connections to View resources.
When you select this setting, if a secure tunnel connection ends during a session, View Client requires the user to reauthenticate before reconnecting.
This setting offers increased security.
For example, if a laptop is stolen and moved to a different network, the user cannot automatically gain access to the remote resource because the network connection was temporarily interrupted.
When this setting is not selected, the client reconnects to the resource without requiring the user to reauthenticate.
This setting has no effect when you use direct connection.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 21
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -messageSecurityMode
Determines if signing and verification of the JMS messages passed between View Manager components takes place. 
"DISABLED" Message security mode is disabled.
"MIXED" Message security mode is enabled but not enforced.
You can use this mode to detect components in your View environment that predate View Manager 3.0.
The log files generated by View Connection Server contain references to these components.
"ENABLED" Message security mode is enabled.
Unsigned messages are rejected by View components.
Message security mode is enabled by default.
Note: View components that predate View Manager 3.0 are not allowed to communicate with other View components.
"ENHANCED" Message Security mode is Enhanced.
Message signing and validation is performed based on the current Security Level and desktop Message Security mode.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 22
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -enableIPSecForSecurityServerPairing
Determines whether to use Internet Protocol Security (IPSec) for connections between security servers and View Connection Server instances.
By default, secure connections (using IPSec) for security server connections is enabled. 
$TRUE or $FALSE

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 23
Default value: False
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
Position: 24
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

### None
## NOTES
| | |
|-|-|
| Author | Matt Frey. |
| Author email | mfrey@vmware.com |
| Version | 1.0 |

===Tested Against Environment====
| | |
|-|-|
| Horizon View Server Version | 7.1 |
| PowerCLI Version | PowerCLI 6.5.1 |
| PowerShell Version | 5.0 |

## RELATED LINKS
