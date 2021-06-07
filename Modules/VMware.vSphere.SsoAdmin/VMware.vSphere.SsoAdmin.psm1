<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

#
# Script module for module 'VMware.vSphere.SsoAdmin'
#
Set-StrictMode -Version Latest

$moduleFileName = 'VMware.vSphere.SsoAdmin.psd1'

# Set up some helper variables to make it easier to work with the module
$PSModule = $ExecutionContext.SessionState.Module
$PSModuleRoot = $PSModule.ModuleBase

# Import the appropriate nested binary module based on the current PowerShell version
$subModuleRoot = $PSModuleRoot

if (($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne 'Desktop')) {
    $subModuleRoot = Join-Path -Path $PSModuleRoot -ChildPath 'netcoreapp3.1'
}
else {
    $subModuleRoot = Join-Path -Path $PSModuleRoot -ChildPath 'net45'
}

$subModulePath = Join-Path -Path $subModuleRoot -ChildPath $moduleFileName
$subModule = Import-Module -Name $subModulePath -PassThru

# When the module is unloaded, remove the nested binary module that was loaded with it
$PSModule.OnRemove = {
    Remove-Module -ModuleInfo $subModule
}

# Internal helper functions
function HasWildcardSymbols {
    param(
        [string]
        $stringToVerify
    )
    (-not [string]::IsNullOrEmpty($stringToVerify) -and `
        ($stringToVerify -match '\*' -or `
                $stringToVerify -match '\?'))
}

function RemoveWildcardSymbols {
    param(
        [string]
        $stringToProcess
    )
    if (-not [string]::IsNullOrEmpty($stringToProcess)) {
        $stringToProcess.Replace('*', '').Replace('?', '')
    }
    else {
        [string]::Empty
    }
}

function FormatError {
    param(
        [System.Exception]
        $exception
    )
    if ($exception -ne $null) {
        if ($exception.InnerException -ne $null) {
            $exception = $exception.InnerException
        }

        # result
        $exception.Message
    }

}

# Global variables
$global:DefaultSsoAdminServers = New-Object System.Collections.Generic.List[VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer]

# Import Module Advanced Functions Implementation

Get-ChildItem -Path $PSScriptRoot -Filter '*.ps1' | ForEach-Object {
    Write-Debug "Importing file: $($_.BaseName)"
    try {
        . $_.FullName
    }
    catch {
        Write-Error -Message "Failed to import functions from $($_.Fullname): $_"
    }
}
