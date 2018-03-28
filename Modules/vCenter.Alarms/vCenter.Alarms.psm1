<#	
	===========================================================================
	Created by: 	Jason Robinson
	Created on:		05/2017
	Twitter:		@jrob24
	===========================================================================
	.DESCRIPTION
		PowerShell Module to help with creation of vCenter Alarms
	.NOTES
		See New-vCenterAlarms.ps1 for examples of alarm creation

		* Tested against PowerShell 5.0
		* Tested against PowerCLI 6.5.1 build 5377412
		* Tested against vCenter 6.0
		* Tested against ESXi 5.5/6.0
#>

function New-AlarmDefinition {
<#
	.SYNOPSIS
		This cmdlet creates a new alarm defintion on the specified entity in vCenter.
	.DESCRIPTION
		This cmdlet creates a new alarm defintion on the specified entity in vCenter.
		An alarm trigger is required in order to create a new alarm definition.
		They can be created by using the New-AlarmTrigger cmdlet.
	
		After the alarm definition is created, if alarm actions are required use
		the cmdlet New-AlarmAction to create actions for the alarm.
	.PARAMETER Name
		Specifies the name of the alarm you want to create.
	.PARAMETER Description
		Specifies the description for the alarm.
	.PARAMETER Entity
		Specifies where to create the alarm. To create the alarm at the root
		level of vCenter use the entity 'Datacenters', otherwise specify any
		object name.
	.PARAMETER Trigger
		Specifies the alarm event, state, or metric trigger(s). The alarm
		trigger(s) are created with the New-AlarmTrigger cmdlet. For more
		information about triggers, run Get-Help New-AlarmTrigger.
	.PARAMETER Enabled
		Specifies if the alarm is enabled when it is created. If unset, the
		default value is true.	
	.PARAMETER ActionRepeatMinutes
		Specifies the frequency how often the actions should repeat when an alarm
		does not change state.
	.PARAMETER ReportingFrequency
		Specifies how often the alarm is triggered, measured in minutes. A zero
		value means the alarm is allowed to trigger as often as possible. A
		nonzero value means that any subsequent triggers are suppressed for a
		period of minutes following a reported trigger. 
	
		If unset, the default value is 0. Allowed range is 0 - 60. 
	.PARAMETER ToleranceRange
		Specifies the tolerance range for the metric triggers, measure in
		percentage. A zero value means that the alarm triggers whenever the metric
		value is above or below the specified value. A nonzero means that the
		alarm triggers only after reaching a certain percentage above or below
		the nominal trigger value.
	
		If unset, the default value is 0. Allowed range is 0 - 100.
	.PARAMETER Server
		Specifies the vCenter Server system on which you want to run the cmdlet.
		If no value is passed to this parameter, the command runs on the default
		server, $DefaultVIServer. For more information about default servers,
		see the description of Connect-VIServer.
	.OUTPUTS
		VMware.Vim.ManagedObjectReference
	.NOTES
		This cmdlet requires a connection to vCenter to create the alarm action.
	.LINKS
		http://pubs.vmware.com/vsphere-6-0/topic/com.vmware.wssdk.apiref.doc/vim.alarm.AlarmSpec.html
	.EXAMPLE
		PS C:\> $trigger = New-AlarmTrigger -StateType runtime.connectionState -StateOperator isEqual -YellowStateCondition disconnected -RedStateCondition notResponding -ObjectType HostSystem
		PS C:\> New-AlarmDefinition -Name 'Host Connection' -Description 'Host Connection State Alarm -Entity Datacenters -Trigger $trigger -ActionRepeatMinutes 10

		Type  Value
		----  -----
		Alarm alarm-1801
	
		This will create a host connection state alarm trigger and store it in
		the variable $trigger. Then it will create a new alarm 'Host Connection'
		on the root level of vCenter and set the action to repeat every 10 mins.
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('AlarmName')]
		[string]$Name,
		
		[string]$Description,
		
		[Parameter(Mandatory = $true)]
		[string]$Entity,
		
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[VMware.Vim.AlarmExpression[]]$Trigger,
		
		[boolean]$Enabled = $true,
		
		[ValidateRange(0, 60)]
		[int32]$ActionRepeatMinutes,
		
		[ValidateRange(0, 60)]
		[int32]$ReportingFrequency = 0,
		
		[ValidateRange(0, 100)]
		[int32]$ToleranceRange = 0,
		
		[string]$Server
	)
	BEGIN {
		Write-Verbose -Message "Adding parameters with default values to PSBoundParameters"
		foreach ($Key in $MyInvocation.MyCommand.Parameters.Keys) {
			$Value = Get-Variable $Key -ValueOnly -ErrorAction SilentlyContinue
			if ($Value -and !$PSBoundParameters.ContainsKey($Key)) {
				$PSBoundParameters[$Key] = $Value
			}
		}
	}
	PROCESS {
		try {
			if ($PSBoundParameters.ContainsKey('Server')) {
				$Object = Get-Inventory -Name $PSBoundParameters['Entity'] -ErrorAction Stop -Server $PSBoundParameters['Server']
				$AlarmMgr = Get-View AlarmManager -ErrorAction Stop -Server $PSBoundParameters['Server']
			} else {
				$Object = Get-Inventory -Name $PSBoundParameters['Entity'] -ErrorAction Stop -Server $global:DefaultVIServer
				$AlarmMgr = Get-View AlarmManager -ErrorAction Stop -Server $global:DefaultVIServer
			}
			
			if ($PSCmdlet.ShouldProcess($global:DefaultVIServer, "Create alarm $($PSBoundParameters['Name'])")) {
				$Alarm = New-Object -TypeName VMware.Vim.AlarmSpec
				$Alarm.Name = $PSBoundParameters['Name']
				$Alarm.Description = $PSBoundParameters['Description']
				$Alarm.Enabled = $PSBoundParameters['Enabled']
				$Alarm.Expression = New-Object -TypeName VMware.Vim.OrAlarmExpression
				$Alarm.Expression.Expression += $PSBoundParameters['Trigger']
				$Alarm.Setting = New-Object -TypeName VMware.Vim.AlarmSetting
				$Alarm.Setting.ReportingFrequency = $PSBoundParameters['ReportingFrequency'] * 60
				$Alarm.Setting.ToleranceRange = $PSBoundParameters['ToleranceRange'] * 100
				$Alarm.ActionFrequency = $PSBoundParameters['ActionRepeatMinutes'] * 60
				$AlarmMgr.CreateAlarm($Object.Id, $Alarm)
			}
		} catch {
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
} #End of New-AlarmDefinition function

function New-AlarmAction {
<#
	.SYNOPSIS
		This cmdlet creates an alarm action on the specified alarm definition.
	.DESCRIPTION
		This cmdlet creates an alarm action on the specified alarm definition.
		This cmdlet differs from the VMware PowerCLI New-AlarmAction cmdlet as it
		will create the transitions of the alarm state.	It requires an alarm
		action and at least one transition to be specified.
		
		The transition indicates when the action executes and if it repeats.
		There are only four	acceptable transitions: green to yellow, yellow to
		red, red to yellow, and yellow to green. At least one pair must be
		specified or the results will be an invalid.
	
		If an alarm action already exists on the alarm definition, it will be
		overwritten if the same alarm action is specified. For example if the
		alarm definition already has an alarm action of Snmp on the transition
		of green to yellow and the cmdlet is used to create a new action of
		Snmp on the transition of yellow to red, it will overwrite the existing
		action and transition. The end result will be one Snmp action on the
		transition of yellow to red. If you want the old to transition to remain
		both should be specified during the usage of the cmdlet.	
	.PARAMETER AlarmDefinition
		Specifies the alarm definition for which you want to configure actions.
		The alarm definition can be retreived by using the Get-AlarmDefinition
		cmdlet.
	.PARAMETER Snmp
		Indicates that a SNMP message is sent when the alarm is activated.
	.PARAMETER Email
		Indicates that when the alarm is activated, the system sends an email
		message to the specified address. Use the Subject, To, CC, and Body
		parameters to customize the alarm message.
	.PARAMETER To
		Specifies the email address to which you want to send a message.
	.PARAMETER Cc
		Specifies the email address you want to add to the CC field of the email
		message.
	.PARAMETER Subject
		Specifies a subject for the email address message you want to send.
	.PARAMETER Body
		Specifies the text of the email message.
	.PARAMETER GreenToYellow
		Specifies the alarm action for the green to yellow transition. Allowed
		values are 'Once' and 'Repeat'. If parameter is not set transition will
		remain unset.
	.PARAMETER YellowToRed
		Specifies the alarm action for the yellow to red transition. Allowed
		values are 'Once' and 'Repeat'. If parameter is not set transition will
		remain unset.
	.PARAMETER RedToYellow
		Specifies the alarm action for the red to yellow transition. Allowed
		values are 'Once' and 'Repeat'. If parameter is not set transition will
		remain unset.
	.PARAMETER YellowToGreen
		Specifies the alarm action for the yellow to green transition. Allowed
		values are 'Once' and 'Repeat'. If parameter is not set transition will
		remain unset.
	.NOTES
		This cmdlet requires a connection to vCenter to create the alarm action.
		
		When using this cmdlet specify the Module-Qualified cmdlet name to avoid
		using the New-AlarmAction cmdlet with VMware PowerCLI.
	.EXAMPLE
		PS C:\> vCenter.Alarms\New-AlarmAction -AlarmDefinition (Get-AlarmDefintion "Host CPU Usage") -Snmp -YellowToRed Repeat
		
		This will create an Snmp alarm action on the "Host CPU Usage" alarm
		transition of yellow to red. The alarm action will also repeat, as per
		the action frequency defined on the alarm.
	.EXAMPLE
		PS C:\> Get-AlarmDefintion "Cluster HA Status" | vCenter.Alarms\New-AlarmAction -Email -To helpdesk@company.com -GreenToYellow Once -YellowToRed Once
	
		This will create an Email alarm action on the "Cluster HA Status" alarm
		transition of green to yellow and yellow to red. The alarm action will
		send an email to helpdesk@company.com one time per transition.
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[VMware.VimAutomation.ViCore.Types.V1.Alarm.AlarmDefinition]$AlarmDefinition,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Snmp')]
		[switch]$Snmp,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Email')]
		[switch]$Email,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Email')]
		[string[]]$To,
		
		[Parameter(ParameterSetName = 'Email')]
		[string[]]$Cc,
		
		[Parameter(ParameterSetName = 'Email')]
		[string]$Subject,
		
		[Parameter(ParameterSetName = 'Email')]
		[string]$Body,
		
		[ValidateSet('Once', 'Repeat')]
		[string]$GreenToYellow,
		
		[ValidateSet('Once', 'Repeat')]
		[string]$YellowToRed,
		
		[ValidateSet('Once', 'Repeat')]
		[string]$RedToYellow,
		
		[ValidateSet('Once', 'Repeat')]
		[string]$YellowToGreen
	)
	
	BEGIN {
	}
	PROCESS {
		try {
			$AlarmView = Get-View -Id $PSBoundParameters['AlarmDefinition'].Id -Server ($PSBoundParameters['AlarmDefinition'].Uid.Split('@:')[1])
			$Alarm = New-Object -TypeName VMware.Vim.AlarmSpec
			$Alarm.Name = $AlarmView.Info.Name
			$Alarm.Description = $AlarmView.Info.Description
			$Alarm.Enabled = $AlarmView.Info.Enabled
			$Alarm.ActionFrequency = $AlarmView.Info.ActionFrequency
			$Alarm.Action = New-Object VMware.Vim.GroupAlarmAction
			$Trigger = New-Object VMware.Vim.AlarmTriggeringAction
			
			Write-Verbose -Message "Defining alarm actions"
			if ($PSCmdlet.ParameterSetName -eq 'Snmp') {
				$Trigger.Action = New-Object -TypeName VMware.Vim.SendSNMPAction
			} elseif ($PSCmdlet.ParameterSetName -eq 'Email') {
				$Trigger.Action = New-Object -TypeName VMware.Vim.SendEmailAction
				$Trigger.Action.ToList = $PSBoundParameters['To'].GetEnumerator() | ForEach-Object -Process {
					"$_;"
				}
				if ($PSBoundParameters.ContainsKey('Cc')) {
					$Trigger.Action.CcList = $PSBoundParameters['Cc'].GetEnumerator() | ForEach-Object -Process {
						"$_;"
					}
				} else {
					$Trigger.Action.CcList = $null
				}
				$Trigger.Action.Subject = $PSBoundParameters['Subject']
				$Trigger.Action.Body = $PSBoundParameters['Body']
			}
			
			Write-Verbose -Message "Defining alarm transitions"
			if ($PSBoundParameters.ContainsKey('GreenToYellow')) {
				$Trans1 = New-Object -TypeName VMware.Vim.AlarmTriggeringActionTransitionSpec
				$Trans1.StartState = 'green'
				$Trans1.FinalState = 'yellow'
				if ($PSBoundParameters['GreenToYellow'] -eq 'Repeat') {
					$Trans1.Repeats = $true
				}
				$Trigger.TransitionSpecs += $Trans1
			}
			
			if ($PSBoundParameters.ContainsKey('YellowToRed')) {
				$Trans2 = New-Object -TypeName VMware.Vim.AlarmTriggeringActionTransitionSpec
				$Trans2.StartState = 'yellow'
				$Trans2.FinalState = 'red'
				if ($PSBoundParameters['YellowToRed'] -eq 'Repeat') {
					$Trans2.Repeats = $true
				} else {
					$Trans2.Repeats = $false
				}
				$Trigger.TransitionSpecs += $Trans2
			}
			
			if ($PSBoundParameters.ContainsKey('RedToYellow')) {
				$Trans3 = New-Object -TypeName VMware.Vim.AlarmTriggeringActionTransitionSpec
				$Trans3.StartState = 'red'
				$Trans3.FinalState = 'yellow'
				if ($PSBoundParameters['RedToYellow'] -eq 'Repeat') {
					$Trans3.Repeats = $true
				} else {
					$Trans3.Repeats = $false
				}
				$Trigger.TransitionSpecs += $Trans3
			}
			
			if ($PSBoundParameters.ContainsKey('YellowToGreen')) {
				$Trans4 = New-Object -TypeName VMware.Vim.AlarmTriggeringActionTransitionSpec
				$Trans4.StartState = 'yellow'
				$Trans4.FinalState = 'green'
				if ($PSBoundParameters['YellowToGreen'] -eq 'Repeat') {
					$Trans4.Repeats = $true
				} else {
					$Trans4.Repeats = $false
				}
				$Trigger.TransitionSpecs += $Trans4
			}
			
			$Alarm.Action.Action += $Trigger
			$Alarm.Expression = New-Object -TypeName VMware.Vim.OrAlarmExpression
			$Alarm.Expression.Expression += $AlarmView.Info.Expression.Expression
			$Alarm.Setting += $AlarmView.Info.Setting
			$AlarmView.ReconfigureAlarm($Alarm)
		} catch {
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
} #End of New-AlarmAction function

function New-AlarmTrigger {
<#
	.SYNOPSIS
		This cmdlet creates a vCenter event, state, or metric alarm trigger.
	.DESCRIPTION
		This cmdlet creates a vCenter event, state, or metric alarm trigger.
		The trigger is used with the New-AlarmDefinition cmdlet to create a new
		alarm in vCenter. This cmdlet will only create one alarm trigger. If more
		triggers are required store the triggers in an array.
	.PARAMETER EventType
		Specifies the type of the event to trigger on. The event types can be
		discovered by using the Get-EventId cmdlet. If the the event type is
		'EventEx' or 'ExtendedEvent' the EventTypeId parameter is required.
	.PARAMETER EventTypeId
		Specifies the id of the event type. Only used when the event type is an
		'EventEx' or 'ExtendedEvent'.
	.PARAMETER Status
		Specifies the status of the event. Allowed values are green, yellow, or
		red.
	.PARAMETER StateType
		Specifies the state type to trigger on. Allowed values are
		runtime.powerstate (HostSystem), summary.quickStats.guestHeartbeatStatus
		(VirtualMachine), or runtime.connectionState (VirtualMachine).
	.PARAMETER StateOperator
		Specifies the operator condition on the target state. Allowed values are
		'isEqual' or 'isUnequal'.
	.PARAMETER YellowStateCondition
		Specifies the yellow state condition. When creating a state alarm
		trigger at least one condition must be specified for a valid trigger to
		be created. If the parameter is not set, the yellow condition is unset.
	.PARAMETER RedStateCondition
		Specifies the red state condition. When creating a state alarm trigger
		at least one condition must be specified for a valid trigger to be
		created. If the parameter is not set, the red condition is unset.
	.PARAMETER MetricId
		Specifies the id of the metric to trigger on. The metric ids can be
		discovered by using the Get-MetricId cmdlet.
	.PARAMETER MetricOperator
		Specifies the operator condition on the target metric. Allowed values
		are 'isAbove' or 'isBelow'.
	.PARAMETER Yellow
		Specifies the threshold value that triggers a yellow status. Allowed
		range is 1% - 100%.
	.PARAMETER YellowInterval
		Specifies the time interval in minutes for which the yellow condition
		must be true before the yellow status is triggered. If unset, the yellow
		status is triggered immediately when the yellow condition becomes true.
	.PARAMETER Red
		Specifies the threshold value that triggers a red status. Allowed range
		is 1% - 100%.
	.PARAMETER RedInterval
		Specifies the time interval in minutes for which the red condition must
		be true before the red status is triggered. If unset, the red status is
		triggered immediately when the red condition becomes true.
	.PARAMETER ObjectType
		Specifies the type of object on which the event is logged, the object
		type containing the state condition or the type of object containing the
		metric. 
		
		When creating a state alarm trigger the only acceptable values are
		'HostSystem' or 'VirtualMachine'. The supported state types for each object
		are as follows:
			VirtualMachine type: runtime.powerState or summary.quickStats.guestHeartbeatStatus
			HostSystem type: runtime.connectionState
	.OUTPUTS
		(Event|State|Metric)AlarmExpression	
	.NOTES
		This cmdlet requires the PowerCLI module to be imported. 
	.LINK
		Event Alarm Trigger
		http://pubs.vmware.com/vsphere-6-0/topic/com.vmware.wssdk.apiref.doc/vim.alarm.EventAlarmExpression.html
		
		State Alarm Trigger
		http://pubs.vmware.com/vsphere-6-0/topic/com.vmware.wssdk.apiref.doc/vim.alarm.StateAlarmExpression.html
	
		Metric Alarm Trigger
		http://pubs.vmware.com/vsphere-6-0/topic/com.vmware.wssdk.apiref.doc/vim.alarm.MetricAlarmExpression.html
	.EXAMPLE
		PS C:\> New-AlarmTrigger -EventType "DasDisabledEvent" -Status Red -ObjectType ClusterComputeResource
		
		Comparisons :
		EventType   : DasDisabledEvent
		ObjectType  : ClusterComputeResource
		Status      : red
		
		Creates an event trigger on 'DasDisabledEvent' (HA Disabled) with a
		status on 'Red'. The object type is a ClusterComputerResource because
		this event occurs at a cluster level.
	.EXAMPLE
		PS C:\> New-AlarmTrigger -MetricId (Get-MetricId | Where Name -EQ 'cpu.usage.average').Key -Operator isAbove -Yellow 90 -YellowInterval 30 -Red 98 -RedInterval 15 -ObjectType HostSytem
		
		Operator       : isAbove
		Type           : HostSytem
		Metric         : VMware.Vim.PerfMetricId
		Yellow         : 9000
		YellowInterval : 30
		Red            : 9800
		RedInterval    : 15
		
		Creates a trigger on the 'cpu.usage.average' metric where the warning
		condition must be above 90% for 30mins and the alert condition must be
		above 98% for 15mins. The object type is a HostSystem.
	.EXAMPLE
		PS C:\temp> New-AlarmTrigger -StateType runtime.connectionState -StateOperator isEqual -YellowStateCondition Disconnected -RedStateCondition notResponding -ObjectType HostSystem

		Operator  : isEqual
		Type      : HostSystem
		StatePath : runtime.connectionState
		Yellow    : Disconnected
		Red       : notResponding
		
		Creates a trigger on the 'runtime.connectionState' condition where the
		warning condition is 'disconnected' and the alert condition is
		'notResponding'. The object type is a HostSystem.
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Event')]
		[string]$EventType,
		
		[Parameter(ParameterSetName = 'Event')]
		[string]$EventTypeId,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Event')]
		[ValidateSet('Green', 'Yellow', 'Red')]
		[string]$Status,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'State')]
		[ValidateSet('runtime.powerState', 'summary.quickStats.guestHeartbeatStatus', 'runtime.connectionState')]
		[string]$StateType,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'State')]
		[VMware.Vim.StateAlarmOperator]$StateOperator,
		
		[Parameter(ParameterSetName = 'State')]
		[ValidateSet('disconnected', 'notResponding', 'connected', 'noHeartbeat', 'intermittentHeartbeat', 'poweredOn', 'poweredOff', 'suspended')]
		[string]$YellowStateCondition,
		
		[Parameter(ParameterSetName = 'State')]
		[ValidateSet('disconnected', 'notResponding', 'connected', 'noHeartbeat', 'intermittentHeartbeat', 'poweredOn', 'poweredOff', 'suspended')]
		[string]$RedStateCondition,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Metric')]
		[string]$MetricId,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Metric')]
		[VMware.Vim.MetricAlarmOperator]$MetricOperator,
		
		[Parameter(ParameterSetName = 'Metric')]
		[ValidateRange(1, 100)]
		[int32]$Yellow,
		
		[Parameter(ParameterSetName = 'Metric')]
		[ValidateRange(1, 90)]
		[int32]$YellowInterval,
		
		[Parameter(ParameterSetName = 'Metric')]
		[ValidateRange(1, 100)]
		[int32]$Red,
		
		[Parameter(ParameterSetName = 'Metric')]
		[ValidateRange(1, 90)]
		[int32]$RedInterval,
		
		[Parameter(Mandatory = $true)]
		[ValidateSet('ClusterComputeResource', 'Datacenter', 'Datastore', 'DistributedVirtualSwitch', 'HostSystem', 'Network', 'ResourcePool', 'VirtualMachine')]
		[string]$ObjectType
	)
	try {
		if ($PSCmdlet.ShouldProcess("vCenter alarm", "Create $($PSCmdlet.ParameterSetName) trigger")) {
			if ($PSCmdlet.ParameterSetName -eq 'Event') {
				$Expression = New-Object -TypeName VMware.Vim.EventAlarmExpression
				$Expression.EventType = $PSBoundParameters['EventType']
				if ($PSBoundParameters.ContainsKey('EventTypeId')) {
					$Expression.EventTypeId = $PSBoundParameters['EventTypeId']
				}
				$Expression.ObjectType = $PSBoundParameters['ObjectType']
				$Expression.Status = $PSBoundParameters['Status']
				$Expression
			} elseif ($PSCmdlet.ParameterSetName -eq 'Metric') {
				$Expression = New-Object -TypeName VMware.Vim.MetricAlarmExpression
				$Expression.Metric = New-Object -TypeName VMware.Vim.PerfMetricId
				$Expression.Metric.CounterId = $PSBoundParameters['MetricId']
				$Expression.Metric.Instance = ""
				$Expression.Operator = $PSBoundParameters['MetricOperator']
				$Expression.Red = ($PSBoundParameters['Red'] * 100)
				$Expression.RedInterval = ($PSBoundParameters['RedInterval'] * 60)
				$Expression.Yellow = ($PSBoundParameters['Yellow'] * 100)
				$Expression.YellowInterval = ($PSBoundParameters['YellowInterval'] * 60)
				$Expression.Type = $PSBoundParameters['ObjectType']
				$Expression
			} elseif ($PSCmdlet.ParameterSetName -eq 'State') {
				$Expression = New-Object -TypeName VMware.Vim.StateAlarmExpression
				$Expression.Operator = $PSBoundParameters['StateOperator']
				$Expression.Type = $PSBoundParameters['ObjectType']
				$Expression.StatePath = $PSBoundParameters['StateType']
				
				if ($PSBoundParameters.ContainsKey('RedStateCondition')) {
					if ($PSBoundParameters['RedStateCondition'] -eq 'intermittentHeartbeat') {
						$Expression.Red = 'yellow'
					} elseif ($PSBoundParameters['RedStateCondition'] -eq 'noHeartbeat') {
						$Expression.Red = 'red'
					} else {
						$Expression.Red = $PSBoundParameters['RedStateCondition']
					}
				}
				
				if ($PSBoundParameters.ContainsKey('YellowStateCondition')) {
					if ($PSBoundParameters['YellowStateCondition'] -eq 'intermittentHeartbeat') {
						$Expression.Yellow = 'yellow'
					} elseif ($PSBoundParameters['YellowStateCondition'] -eq 'noHeartbeat') {
						$Expression.Yellow = 'red'
					} else {
						$Expression.Yellow = $PSBoundParameters['YellowStateCondition']
					}
				}
				$Expression
			}
		}
	} catch {
		$PSCmdlet.ThrowTerminatingError($_)
	}
} #End of New-AlarmTrigger function

function Get-MetricId {
<#
	.SYNOPSIS
		This cmdlet collects all of the available metrics from vCenter.
	.DESCRIPTION
		This cmdlet collects all of the available metrics from vCenter. It will
		provide the metric name, key, stats level, and summary of the metric.
		The information can be used to identify the available metrics on vCenter
		as well as gathering the metric key needed for configuring an alarm. 
	
		The metric keys are unique across vCenters. If you are connected to 
		more than one vCenter metrics from each vCenter will be generated. A
		vCenter property is available to help determine the correct metric key
		on a given vCenter. This is extrememly useful when trying to create
		a metric based vCenter alarm. 
	.PARAMETER MetricGroup
		Specifies the name of the metric group you would like to see. Allowed
		values are 'CPU', 'Mem', 'Disk', 'Net', and 'Datastore'.
	.OUTPUTS
		System.Management.Automation.PSCustomObject
	.NOTES
		This cmdlet requires a connection to vCenter to collect metric data.
	.EXAMPLE
		PS C:\> Get-MetricId -MetricGroup Mem

		Name    : mem.usage.none
		Key     : 23
		Level   : 4
		Summary : Memory usage as percentage of total configured or available memory
		vCenter : vCenter01

		Name    : mem.usage.average
		Key     : 24
		Level   : 1
		Summary : Memory usage as percentage of total configured or available memory
		vCenter : vCenter01

		Name    : mem.usage.minimum
		Key     : 25
		Level   : 4
		Summary : Memory usage as percentage of total configured or available memory
		vCenter : vCenter01
		.....
	
		Collects all of the available memory metrics on the connected vCenter.
#>
	[CmdletBinding()]
	param (
		[ValidateSet('CPU', 'Mem', 'Disk', 'Net', 'Datastore')]
		[string]$MetricGroup
	)
	
	foreach ($Mgr in (Get-View PerformanceManager-PerfMgr)) {
		$vCenter = $Mgr.Client.ServiceUrl.Split('/')[2]
		if ($PSBoundParameters.ContainsKey('MetricGroup')) {
			$Metrics += $Mgr.PerfCounter | Where-Object -FilterScript {
				$_.GroupInfo.Key -eq $PSBoundParameters['MetricGroup']
			}
		} else {
			$Metrics += $Mgr.PerfCounter
		}
		
		$Metrics | ForEach-Object -Process {
			[pscustomobject] @{
				Name  = $_.GroupInfo.Key + "." + $_.NameInfo.key + "." + $_.RollupType
				Key   = $_.Key
				Level = $_.Level
				Summary = $_.NameInfo.Summary
				vCenter = $vCenter
			}
		}
	}
} #End of Get-MetricId function

function Get-EventId {
<#
	.SYNOPSIS
		This cmdlet collects all of the available events from vCenter.
	.DESCRIPTION
		This cmdlet collects all of the available events from vCenter. It will
		provide the event type, event type id (if applicable), category,
		description, and summary of the event. The information can be used to
		identify the available events on vCenter as well as gathering the event
		type and event type id (if applicable) required for configuring an alarm.
	
		If the event type is 'EventEx' or 'ExtendedEvent' both the event type
		and event type id will be required to create a new event based vCenter
		alarm.
	
		The event types can be unique across vCenters. If you are connected to 
		more than one vCenter events from each vCenter will be generated. A
		vCenter property is available to help determine the correct event type
		on a given vCenter. This is extrememly useful when trying to create
		a event based vCenter alarm.
	.PARAMETER Category
		Specifies the name of the event category you would like to see. Allowed
		values are 'info', 'warning', 'error', and 'user'.
	.OUTPUTS
		System.Management.Automation.PSCustomObject
	.NOTES
		This cmdlet requires a connection to vCenter to collect event data.
	.EXAMPLE
		PS C:\> Get-EventId -Category Error
		
		EventType   : ExtendedEvent
		EventTypeId : ad.event.ImportCertFailedEvent
		Category    : error
		Description : Import certificate failure
		FullFormat  : Import certificate failed.
		vCenter		: vCenter01

		EventType   : ExtendedEvent
		EventTypeId : ad.event.JoinDomainFailedEvent
		Category    : error
		Description : Join domain failure
		FullFormat  : Join domain failed.
		vCenter		: vCenter01

		EventType   : ExtendedEvent
		EventTypeId : ad.event.LeaveDomainFailedEvent
		Category    : error
		Description : Leave domain failure
		FullFormat  : Leave domain failed.
		vCenter		: vCenter01
		.....
#>
	[CmdletBinding()]
	param (
		[VMware.Vim.EventCategory]$Category
	)
	
	foreach ($Mgr in (Get-View EventManager)) {
		$vCenter = $Mgr.Client.ServiceUrl.Split('/')[2]
		if ($PSBoundParameters.ContainsKey('Category')) {
			$Events += $Mgr.Description.EventInfo | Where-Object -FilterScript {
				$_.Category -eq $PSBoundParameters['Category']
			}
		} else {
			$Events += $Mgr.Description.EventInfo
		}
		
		$Events | ForEach-Object -Process {
			$Hash = [ordered]@{}
			$Hash.Add('EventType', $_.Key)
			if ($_.Key -eq 'ExtendedEvent' -or $_.Key -eq 'EventEx') {
				$Hash.Add('EventTypeId', $_.FullFormat.Split('|')[0])
			}
			$Hash.Add('Category', $_.Category)
			$Hash.Add('Description', $_.Description)
			if ($Hash['EventType'] -eq 'ExtendedEvent' -or $Hash['EventType'] -eq 'EventEx') {
				$Hash.Add('FullFormat', $_.FullFormat.Split('|')[1])
			} else {
				$Hash.Add('FullFormat', $_.FullFormat)
			}
			$Hash.Add('vCenter', $vCenter)
			New-Object -TypeName System.Management.Automation.PSObject -Property $Hash
		}
	}
} #End of Get-EventId function