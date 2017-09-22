<#	
	
	===========================================================================
	Created by: 	Jason Robinson
	Created on:		05/2017
	Twitter:		@jrob24
	Filename:  New-vCenterAlarms.ps1   	
	===========================================================================
	.DESCRIPTION
		Examples of creating alarms using vCenter.Alarm module
#>

Import-Module -Name vCenter.Alarms

Write-Verbose -Message "Example 1 : Creating new Host CPU Usage alarm (Metric based alarm)"
Write-Verbose -Message "Finding the metric id for 'cpu.usage.average'"
$MetricId = (Get-MetricId -MetricGroup CPU | Where-Object -FilterScript { $_.Name -eq 'cpu.usage.average' }).Key
Write-Verbose -Message "Creating an alarm trigger for cpu.usage.average of 90% for 15mins (Warning) & 95% for 10mins (Alert) on the HostSystem object type"
$Trigger = New-AlarmTrigger -MetricId $MetricId -MetricOperator isAbove -ObjectType HostSystem -Yellow 90 -YellowInterval 15 -Red 95 -RedInterval 10
Write-Verbose -Message "Creates a new alarm called 'Host CPU Usage' at the root level of vCenter"
New-AlarmDefinition -Name "Host CPU Usage" -Description "Alarm on 95%" -Entity Datacenters -Trigger $Trigger -ActionRepeatMinutes 10
Write-Verbose -Message "Configures the alarm to send snmp traps"
Get-AlarmDefinition -Name "Host CPU Usage" | vSphere.Alarms\New-AlarmAction -Snmp -GreenToYellow Once -YellowToRed Repeat

Write-Verbose -Message "Example 2 : Creating new HA Disabled alarm (Event based alarm)"
Write-Verbose -Message "Finding the event type for 'HA disabled for cluster'"
$EventType = (Get-EventId | Where-Object -FilterScript { $_.Description -match 'HA disabled for cluster' }).EventType
Write-Verbose -Message "Creating an alarm trigger for 'DasDisabledEvent' on the ClusterComputeResource object type"
$Trigger = New-AlarmTrigger -EventType $EventType -Status Red -ObjectType ClusterComputeResource
Write-Verbose -Message "Creates a new alarm called 'HA Disabled' at the root level of vCenter"
New-AlarmDefinition -Name "HA Disabled" -Description "Alarm on HA" -Entity Datacenters -Trigger $Trigger -ActionRepeatMinutes 30
Write-Verbose -Message "Configures the alarm to send an email every 30mins"
$EmailParams = @{
	Email	= $true
	To		= 'helpdesk@company.com'
	Subject = 'HA Disabled'
}
Get-AlarmDefinition -Name "HA Disabled" | vCenter.Alarms\New-AlarmAction @EmailParams -YellowToRed Repeat

Write-Verbose -Message "Example 3 : Creating new Host Connection State alarm (State based alarm)"
Write-Verbose -Message "Creating an alarm trigger for StateType of 'runtime.connectionState' on the HostSystem object type"
$Trigger = New-AlarmTrigger -StateType runtime.connectionState -StateOperator isEqual -YellowStateCondition disconnected -RedStateCondition notResponding -ObjectType HostSystem
Write-Verbose -Message "Creates a new alarm called 'Host Connection State' at the root level of vCenter"
New-AlarmDefinition -Name "Host Connection State" -Description "Connection State" -Entity Datacenters -Trigger $Trigger
Write-Verbose -Message "Configures the alarm to send an email once"
$EmailParams = @{
	Email    = $true
	To	     = 'helpdesk@company.com'
	Subject  = 'Host Connection Lost'
}
Get-AlarmDefinition -Name "Host Connection State" | vCenter.Alarms\New-AlarmAction @EmailParams -YellowToRed Once

Write-Verbose -Message "Example 4 : Creating new Lost Storage Connectivity (Event based alarm)"
Write-Verbose -Message "Find the event type for 'Lost Storage Connectivity'"
Get-EventId | Where-Object -FilterScript { $_.Description -match 'Lost Storage Connectivity' }
Write-Verbose -Message "Two results returned, we want esx not vprob"
	<#
	EventType   : EventEx
	EventTypeId : esx.problem.storage.connectivity.lost
	Category    : error
	Description : Lost Storage Connectivity
	FullFormat  : Lost connectivity to storage device { 1 }. Path { 2 } is down. Affected datastores: { 3 }.
	vCenter     : vCenter01

	EventType   : EventEx
	EventTypeId : vprob.storage.connectivity.lost
	Category    : error
	Description : Lost Storage Connectivity
	FullFormat  : Lost connectivity to storage device { 1 }. Path { 2 } is down. Affected datastores: { 3 }.
	vCenter     : vCenter01
	#>
Write-Verbose -Message "Since the event type is EventEx, we need both the EventType & EventTypeId to create the trigger"
$EventType = Get-EventId | Where-Object -FilterScript { $_.EventTypeId -eq 'esx.problem.storage.connectivity.lost' }
Write-Verbose -Message "Creating an alarm trigger for 'DasDisabledEvent' on the ClusterComputeResource object type"
$Trigger = New-AlarmTrigger -EventType $EventType.EventType -EventTypeId $EventType.EventTypeId -Status Red -ObjectType HostSystem
Write-Verbose -Message "Creates a new alarm called 'Lost Storage Connectivity' at the root level of vCenter"
New-AlarmDefinition -Name "Lost Storage Connectivity" -Description "Lost Storage" -Entity Datacenters -Trigger $Trigger -ActionRepeatMinutes 5
Write-Verbose -Message "Configures the alarm to send an snmp every 5mins"
Get-AlarmDefinition -Name "Lost Storage Connectivity" | vCenter.Alarms\New-AlarmAction -Snmp -YellowToRed Repeat