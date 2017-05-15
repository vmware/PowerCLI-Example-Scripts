Prerequisites/Steps to use this module:

1. This module only works for Horizon product E.g. Horizon 7.0.2 and later.
2. Install the latest version of Powershell, PowerCLI(6.5) or (later version via psgallery).
3. Import HorizonView module by running: Import-Module VMware.VimAutomation.HorizonView.
4. Import "VMware.Hv.Helper" module by running: Import-Module -Name "location of this module" or Get-Module -ListAvailable 'VMware.Hv.Helper' | Import-Module.
5. Get-Command -Module "This module Name" to list all available functions or Get-Command -Module 'VMware.Hv.Helper'.

# Example script to connect view API service of Connection Server:

Import-Module VMware.VimAutomation.HorizonView
# Connection to view API service
$hvServer = Connect-HVServer -server <connection server IP/FQDN>
$hvServices = $hvserver.ExtensionData
$csList = $hvServices.ConnectionServer.ConnectionServer_List()
# Load this module
Get-Module -ListAvailable 'VMware.Hv.Helper' | Import-Module
Get-Command -Module 'VMware.Hv.Helper'
# Use advanced functions of this module
New-HVPool -spec 'path to InstantClone.json file'
