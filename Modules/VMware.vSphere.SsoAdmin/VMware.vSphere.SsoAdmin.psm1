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
   $subModuleRoot = Join-Path -Path $PSModuleRoot -ChildPath 'netcoreapp2.0'
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