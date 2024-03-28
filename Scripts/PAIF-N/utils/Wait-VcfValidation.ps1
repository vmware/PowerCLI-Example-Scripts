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

function Wait-VcfValidation {
   [CmdletBinding(
      ConfirmImpact = "None",
      DefaultParameterSetName = "Default",
      SupportsPaging = $false,
      PositionalBinding = $false,
      RemotingCapability = "None",
      SupportsShouldProcess = $false,
      SupportsTransactions = $false)]
   [OutputType([VMware.Bindings.Vcf.SddcManager.Model.Validation])]

   Param (
      [Parameter(
         Mandatory = $true,
         ValueFromPipeline = $true,
         Position = 0)]
      [VMware.Bindings.Vcf.SddcManager.Model.Validation]
      $Validation,

      [Parameter(
         Position = 1)]
      [scriptblock]
      $UpdateValidation,

      [Parameter(
         Position = 2)]
      [object[]]
      $UpdateValidationArguments,

      [Parameter()]
      [switch]
      $ThrowOnError
   )

   $Validation | ConvertTo-Json -Depth 10 | Write-Verbose

   $validationDescription = $Validation.Description

   Write-Progress -Id 0 $validationDescription

   while ($Validation.ExecutionStatus -eq 'IN_PROGRESS' -or $Validation.ExecutionStatus -eq 'CANCELLATION_IN_PROGRESS') {

      Write-Verbose "$validationDescription in progress"
      $Validation | ConvertTo-Json -Depth 10 | Write-Verbose

      if ($Validation.ValidationChecks -and $Validation.ValidationChecks.Count -gt 0) {
         $completedSubTask = $Validation.ValidationChecks | Where-Object {
            $_.ResultStatus -eq 'SUCCEEDED'
         } | Measure-Object | Select-Object -ExpandProperty Count

         $currentSubTaskName = $Validation.ValidationChecks | Where-Object {
            $_.ResultStatus -eq 'IN_PROGRESS'
         } | Select-Object -First 1 -ExpandProperty Name

         if ($currentSubTaskName) {
            Write-Progress -Id 0 $validationDescription -Status $currentSubTaskName -PercentComplete (($completedSubTask * 100) / $Validation.ValidationChecks.Count)
         } else {
            Write-Progress -Id 0 $validationDescription -PercentComplete (($completedSubTask * 100) / $Validation.ValidationChecks.Count)
         }
      }

      Start-Sleep -Seconds 1
      if ($UpdateValidation) {
         $Validation = Invoke-Command -ScriptBlock $UpdateValidation -ArgumentList $UpdateValidationArguments
      }
      $validationDescription = $Validation.Description
   }

   if ($Validation.ResultStatus -ne 'SUCCEEDED') {
      Write-Progress -Id 0 "$validationDescription failed" -Completed
      Write-Verbose "$validationDescription failed"
      $Validation | ConvertTo-Json -Depth 10 | Write-Verbose

      $Validation.validationChecks | ForEach-Object {
         Write-Verbose "[$(if($_.ResultStatus -eq 'SUCCEEDED'){"+"}else{"-"})][$($_.Severity)] $($_.Description)"
      }

      if ($ThrowOnError) {
         throw $Validation
      } else {
         Write-Output $Validation
      }
   } else {
      Write-Progress -Id 0 "$validationDescription succeeded" -Completed
      Write-Verbose "$validationDescription succeeded"

      Write-Output $Validation
   }
}