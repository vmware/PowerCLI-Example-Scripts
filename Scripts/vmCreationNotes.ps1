<# 
.SYNOPSIS 
   VM_CreationNotes to replace the Notes on newly deployed virtual machines with
   information regarding there deployment, including date, time, user and method
   of deployment.
   
.DESCRIPTION
   VM_CreationNotes is run daily as a scheduled task requiring no interaction. 
   The script will take in vCenter events for the latest 24 hour period filtering
   for vm creation, clone or vapp deployment and parse the data.
   Utilizes GET-VIEventsPlus by Luc Dekens for faster event gathering
.NOTES 
   File Name  : VM_CreationNotes.ps1 
   Author     : KWH
   Version    : 1.03
   License    : GNU GPL 3.0 www.gnu.org/licenses/gpl-3.0.en.html
   
.INPUTS
   No inputs required
.OUTPUTS
   No Output is produced
    
.PARAMETER config
   No Parameters
   
.PARAMETER Outputpath
   No Parameters
   
.PARAMETER job
   No Parameters
.CHANGE LOG
	#20170301	KWH - Removed canned VM Initialize script in favor of get-module
	#20170303	KWH - Change VIEvent Call to date range rather than maxSamples
	#		KWH - Optimized event call where to array match
	#		KWH - Updated Synopsis and Description
	#		KWH - Changed vcenter list to text file input
	#		KWH - Added Register Events to list
	#		KWH - Included Get-VIEventPlus by LucD
	#20170321       KWH - Added event $VIEvent array declaration/reset and $VM reset on loops
	#               KWH - Converted returned events to Local Time
#>

<#   
 .SYNOPSIS  Function GET-VIEventPlus Returns vSphere events    
 .DESCRIPTION The function will return vSphere events. With
 	the available parameters, the execution time can be
 	improved, compered to the original Get-VIEvent cmdlet. 
 .NOTES  Author:  Luc Dekens   
 .PARAMETER Entity
 	When specified the function returns events for the
 	specific vSphere entity. By default events for all
 	vSphere entities are returned. 
 .PARAMETER EventType
 	This parameter limits the returned events to those
 	specified on this parameter. 
 .PARAMETER Start
 	The start date of the events to retrieve 
 .PARAMETER Finish
 	The end date of the events to retrieve. 
 .PARAMETER Recurse
 	A switch indicating if the events for the children of
 	the Entity will also be returned 
 .PARAMETER User
 	The list of usernames for which events will be returned 
 .PARAMETER System
 	A switch that allows the selection of all system events. 
 .PARAMETER ScheduledTask
 	The name of a scheduled task for which the events
 	will be returned 
 .PARAMETER FullMessage
 	A switch indicating if the full message shall be compiled.
 	This switch can improve the execution speed if the full
 	message is not needed.   
 .EXAMPLE
 	PS> Get-VIEventPlus -Entity $vm
 .EXAMPLE
 	PS> Get-VIEventPlus -Entity $cluster -Recurse:$true
 #>
 function Get-VIEventPlus {
 	 
 	param(
 		[VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]$Entity,
 		[string[]]$EventType,
 		[DateTime]$Start,
 		[DateTime]$Finish = (Get-Date),
 		[switch]$Recurse,
 		[string[]]$User,
 		[Switch]$System,
 		[string]$ScheduledTask,
 		[switch]$FullMessage = $false
 	)
 
 	process {
 		$eventnumber = 100
 		$events = @()
 		$eventMgr = Get-View EventManager
 		$eventFilter = New-Object VMware.Vim.EventFilterSpec
 		$eventFilter.disableFullMessage = ! $FullMessage
 		$eventFilter.entity = New-Object VMware.Vim.EventFilterSpecByEntity
 		$eventFilter.entity.recursion = &{if($Recurse){"all"}else{"self"}}
 		$eventFilter.eventTypeId = $EventType
 		if($Start -or $Finish){
 			$eventFilter.time = New-Object VMware.Vim.EventFilterSpecByTime
 			if($Start){
 				$eventFilter.time.beginTime = $Start
 			}
 			if($Finish){
 				$eventFilter.time.endTime = $Finish
 			}
 		}
 		if($User -or $System){
 			$eventFilter.UserName = New-Object VMware.Vim.EventFilterSpecByUsername
 			if($User){
 				$eventFilter.UserName.userList = $User
 			}
 			if($System){
 				$eventFilter.UserName.systemUser = $System
 			}
 		}
 		if($ScheduledTask){
 			$si = Get-View ServiceInstance
 			$schTskMgr = Get-View $si.Content.ScheduledTaskManager
 			$eventFilter.ScheduledTask = Get-View $schTskMgr.ScheduledTask |
 			where {$_.Info.Name -match $ScheduledTask} |
 			Select -First 1 |
 			Select -ExpandProperty MoRef
 		}
 		if(!$Entity){
 			$Entity = @(Get-Folder -Name Datacenters)
 		}
 		$entity | %{
 			$eventFilter.entity.entity = $_.ExtensionData.MoRef
 			$eventCollector = Get-View ($eventMgr.CreateCollectorForEvents($eventFilter))
 			$eventsBuffer = $eventCollector.ReadNextEvents($eventnumber)
 			while($eventsBuffer){
 				$events += $eventsBuffer
 				$eventsBuffer = $eventCollector.ReadNextEvents($eventnumber)
 			}
 			$eventCollector.DestroyCollector()
 		}
 		$events
 	}
 }

#Run parameters - Change below if username or vcenter list source changes
$dayBtwnRuns = 1
$AdminName = "username"
$credfile = "c:\Scripts\common\credentials\runtime-cred.txt"
$vcfile = "c:\Scripts\Common\inputlists\vcenterlist.txt"

$vmCreationTypes = @() #Remark out any event types not desired below
$vmCreationTypes += "VmCreatedEvent" 
$vmCreationTypes += "VmBeingClonedEvent" 
$vmCreationTypes += "VmBeingDeployedEvent" 
$vmCreationTypes += "VmRegisteredEvent"
$newline = "`r`n"

#Convert Password and username to credential object
$password = Get-Content $CredFile | ConvertTo-SecureString
$Cred = New-Object -Typename System.Management.Automation.PSCredential -argumentlist $AdminName,$password

#Load vCenter List
$vCenterServers = Get-Content $vcfile

If ($daysBtwnRuns -gt 0) {$daysBtwnRuns = -$daysBtwnRuns}
$Today = Get-Date
$StartDate = ($Today).AddDays($dayBtwnRuns)

ForEach ($vcenter in $vCenterServers){
	Connect-VIServer $vcenter  -Credential $Cred -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
	$TargetVM = $null
	$VIEvent = @()
	$Today = Get-Date
	$StartDate = ($Today).AddDays($dayBtwnRuns)
	$VIEvent = Get-VIEventPlus -Start $StartDate -Finish $Today -EventType $vmCreationTypes

	$VIEvent|%{
		$NewNote = ""
		$VM = $null
		$VM = Get-View -Id $_.VM.Vm -Server $vcenter -Property Name,Config	
		
		If ($VM){
			$NewNote = $VM.Config.GuestFullName+$newline
			$NewNote += "Deployed: "+$_.CreatedTime.ToLocaltime().DateTime+$newline
			$NewNote += "Deployed by "+$_.UserName+$newline
			$NewNote += $_.FullFormattedMessage
			Set-VM -VM $VM.Name -Notes $NewNote -Confirm:$false
		}
	}

Disconnect-VIServer -Confirm:$false}
