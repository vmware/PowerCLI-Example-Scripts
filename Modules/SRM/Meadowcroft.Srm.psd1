#
# Module manifest for module 'Meadowcroft.Srm'
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'Meadowcroft.Srm.psm1'

# Version number of this module.
ModuleVersion = '0.2'

# ID used to uniquely identify this module
GUID = 'f9247009-9168-4a21-831b-819f82884ffe'

# Author of this module
Author = 'Ben Meadowcroft'

# Company or vendor of this module
CompanyName = 'VMware, Inc'

# Copyright statement for this module
Copyright = '(c) 2014 - 2017. All rights reserved.'

# Description of the functionality provided by this module
# Description = ''

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @{ModuleName='VMware.VimAutomation.Srm'; ModuleVersion='6.5'}

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = 'Meadowcroft.Srm.Recovery.ps1','Meadowcroft.Srm.Protection.ps1','Meadowcroft.Srm.Storage.ps1'
# NestedModules = @()

# Functions to export from this module, note that internal functions use '_' not '-' as separator
FunctionsToExport = '*-*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
DefaultCommandPrefix = 'Srm'

}
