<#
# © 2024 Broadcom.  All Rights Reserved.  Broadcom.  The term "Broadcom" refers to
# Broadcom Inc. and/or its subsidiaries.
#>

using namespace VMware.Bindings.Vcf.SddcManager.Model

<#
.SYNOPSIS

This cmdlet waits for VCF task to complete or fail.

.DESCRIPTION

This cmdlet waits for VCF task to complete or fail.

.PARAMETER Task
Specifies the task to be waited for.

.PARAMETER ThrowOnError
Specifies if an error will be thrown if the task fails.

.EXAMPLE
PS C:\> Wait-VcfTask -Task $task -ThrowOnError

Waits for the $task to complete or fails.

.OUTPUTS
Zero or more VMware.Bindings.Vcf.SddcManager.Model.Task object

.LINK

#>

function Wait-VcfTask {
   [CmdletBinding(
      ConfirmImpact = "None",
      DefaultParameterSetName = "Default",
      SupportsPaging = $false,
      PositionalBinding = $false,
      RemotingCapability = "None",
      SupportsShouldProcess = $false,
      SupportsTransactions = $false)]
   [OutputType([VMware.Bindings.Vcf.SddcManager.Model.Task])]

   Param (
      [Parameter(
         Mandatory = $true,
         Position = 0)]
      [VMware.Bindings.Vcf.SddcManager.Model.Task]
      $Task,

      [Parameter()]
      [switch]
      $ThrowOnError
   )

   $Task | ConvertTo-Json -Depth 10 | Write-Verbose

   $taskName = $Task.Name

   Write-Progress -Id 0 $taskName

   while ($Task.Status -eq "In Progress" -or $Task.Status -eq 'IN_PROGRESS' -or $Task.Status -eq 'PENDING' -or $Task.Status -eq 'Pending') {

      Write-Verbose "$taskName in progress"
      $Task | ConvertTo-Json -Depth 10 | Write-Verbose

      if ($Task.SubTasks -and $Task.SubTasks.Count -gt 0) {
         $completedSubTask = $Task.SubTasks | Where-Object {
            $_.Status -eq 'SUCCESSFUL' -or $_.Status -eq 'Successful'
         } | Measure-Object | Select-Object -ExpandProperty Count

         $currentSubTaskName = $Task.SubTasks | Where-Object {
            $_.Status -eq 'RUNNING' -or $_.Status -eq 'Running' -or $_.Status -eq "IN_PROGRESS" -or $_.Status -eq "In Progress"
         } | Select-Object -First 1 -ExpandProperty Name

         if ($currentSubTaskName) {
            Write-Progress -Id 0 $taskName -Status $currentSubTaskName -PercentComplete (($completedSubTask * 100) / $Task.SubTasks.Count)
         } else {
            Write-Progress -Id 0 $taskName -PercentComplete (($completedSubTask * 100) / $Task.SubTasks.Count)
         }
      }

      Start-Sleep -Seconds 1
      $Task = Invoke-VcfGetTask -id $Task.Id
      $taskName = $Task.Name
   }
   if ($Task.Status -ne "Successful" -and $Task.Status -ne 'SUCCESSFUL') {
      Write-Progress -Id 0 "$taskName failed" -Completed
      Write-Verbose "$taskName failed"
      $Task | ConvertTo-Json -Depth 10 | Write-Verbose

      $Task.SubTasks | ForEach-Object {
         Write-Verbose "[$(if($_.Status -eq 'SUCCESSFUL' -or $_.Status -eq "Successful"){"+"}else{"-"})] $($_.Description)"
      }

      if ($ThrowOnError) {
         throw $Task
      } else {
         Write-Output $Task
      }
   } else {
      Write-Progress -Id 0 "$taskName succeeded" -Completed
      Write-Verbose "$taskName succeeded"

      Write-Output $Task
   }
}