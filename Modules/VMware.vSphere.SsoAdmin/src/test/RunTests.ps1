<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

param(
    [Parameter(Mandatory = $true)]
    [string]
    $VcAddress,

    [Parameter(Mandatory = $true)]
    [string]
    $User,

    [Parameter(Mandatory = $true)]
    [string]
    $Password
)

function Test-PesterIsAvailable() {
   $pesterModules = Get-Module Pester -ListAvailable
   $pesterModule = $null
   # Search for Pester 4.X
   foreach ($p in $pesterModules) {
      if ($p.Version -ge [version]"5.0.0") {
         $pesterModule = $p
         break
      }
   }

   if ($pesterModule -eq $null) {
      throw "Pester Module version 5.X is not available"
   }

   Import-Module -Name $pesterModule.Name -RequiredVersion $pesterModule.RequiredVersion
}

Test-PesterIsAvailable

$testsData = @{
    VcAddress = $VcAddress
    User = $User
    Password = $Password
}

$pesterContainer = New-PesterContainer -Path $PSScriptRoot -Data $testsData
$pesterConfiguration = [PesterConfiguration]::Default

$pesterConfiguration.Run.Path = $PSScriptRoot
$pesterConfiguration.Run.Container = $pesterContainer

Invoke-Pester -Configuration $pesterConfiguration