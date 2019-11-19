function Get-TriggeredAlarm {
<#
    .SYNOPSIS
        This function lists the triggered alarms for the specified entity in vCenter
    .DESCRIPTION
        List the triggered alarms for the given object
    .NOTES
        Author: Kyle Ruddy, @kmruddy, kmruddy.com
    .PARAMETER VM
        Specifies the name of the VM
    .PARAMETER VMHost
        Specifies the name of the VMHost
    .PARAMETER Datacenter
        Specifies the name of the Datacenter
    .PARAMETER Datastore
        Specifies the name of the Datastore
    .EXAMPLE
        Get-TriggeredAlarm -VM VMname 

        Entity  Alarm   AlarmStatus AlarmMoRef  EntityMoRef
        ----    ----    ----        ----        ----
        VMname  Name    Yellow      Alarm-MoRef Entity-MoRef
#>

    [CmdletBinding()]
    param(
        [string]$VM,
        [string]$VMHost,
        [string]$Datacenter,
        [string]$Datastore
    )
    BEGIN {
        switch ($PSBoundParameters.Keys) {
            'VM' {$entity = Get-VM -Name $vm -ErrorAction SilentlyContinue}
            'VMHost' {$entity = Get-VMHost -Name $VMHost -ErrorAction SilentlyContinue}
            'Datacenter' {$entity = Get-Datacenter -Name $Datacenter -ErrorAction SilentlyContinue}
            'Datastore' {$entity = Get-Datastore -Name $Datastore -ErrorAction SilentlyContinue}
            default {$entity = $null}
        }
                    
        if ($null -eq $entity) {
            Write-Warning "No vSphere object found."
            break
        }
    }
    PROCESS {
        if ($entity.ExtensionData.TriggeredAlarmState -ne "") {
            $alarmOutput = @()
            foreach ($alarm in $entity.ExtensionData.TriggeredAlarmState) {
                $tempObj = "" | Select-Object -Property Entity, Alarm, AlarmStatus, AlarmMoRef, EntityMoRef
                $tempObj.Entity = Get-View $alarm.Entity | Select-Object -ExpandProperty Name
                $tempObj.Alarm = Get-View $alarm.Alarm | Select-Object -ExpandProperty Info | Select-Object -ExpandProperty Name
                $tempObj.AlarmStatus = $alarm.OverallStatus
                $tempObj.AlarmMoRef = $alarm.Alarm
                $tempObj.EntityMoRef = $alarm.Entity
                $alarmOutput += $tempObj
            }
            $alarmOutput | Format-Table -AutoSize
        }
    }

}