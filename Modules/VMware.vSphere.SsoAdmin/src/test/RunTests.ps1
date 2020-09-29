#**************************************************************************
# Copyright (c) VMware, Inc. All rights reserved.
#**************************************************************************

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
   $pesterModule = Get-Module Pester -List
   if ($pesterModule -eq $null) {
      throw "Pester Module is not available"
   }
}

Test-PesterIsAvailable

$testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1"

Invoke-Pester `
   -Script @{
       Path = $PSScriptRoot
       Parameters = @{
         VcAddress = $VcAddress
         User = $User
         Password = $Password
      }
   }