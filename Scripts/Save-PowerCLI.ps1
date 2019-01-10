function Save-PowerCLI {
<#  
.SYNOPSIS  
    Function which can be used to easily download specific versions of PowerCLI from an online gallery
.DESCRIPTION 
    Downloads a specific version of PowerCLI and all the dependencies at the appropriate version
.NOTES  
    Author: 1.0 - Dimitar Milov 
.PARAMETER RequiredVersion
    Specify the PowerCLI version
.PARAMETER Path
    Directory path where the modules should be downloaded
.PARAMETER Repository
    Repository to access the PowerCLI modules
.EXAMPLE
	Save-PowerCLI -RequiredVersion '10.0.0.7895300' -Path .\Downloads\ 
    Downloads PowerCLI 10.0.0 to the Downloads folder 
#>
    param(
        [Parameter(Mandatory = $true)]
        [version]$RequiredVersion,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_} )]
        [string]
        $Path,

        [Parameter()]
        [string]$Repository = 'PSGallery'
    )
   $powercliModuleName = 'VMware.PowerCLI'
   $desiredPowerCLIModule = Find-Module -Name $powercliModuleName -RequiredVersion $RequiredVersion
   if (-not $desiredPowerCLIModule) {
      throw "'VMware.PowerCLI' with version $RequiredVersion' was not found."
   }

   $depsOrder = 'VMware.VimAutomation.Sdk', 'VMware.VimAutomation.Common', 'VMware.Vim', 'VMware.VimAutomation.Cis.Core', 'VMware.VimAutomation.Core', 'VMware.VimAutomation.Nsxt', 'VMware.VimAutomation.Vmc', 'VMware.VimAutomation.Vds', 'VMware.VimAutomation.Srm', 'VMware.ImageBuilder', 'VMware.VimAutomation.Storage', 'VMware.VimAutomation.StorageUtility', 'VMware.VimAutomation.License', 'VMware.VumAutomation', 'VMware.VimAutomation.HorizonView', 'VMware.DeployAutomation', 'VMware.VimAutomation.vROps', 'VMware.VimAutomation.PCloud'
   $orderedDependncies = @()
   foreach ($depModuleName in $depsOrder) {
      $orderedDependncies +=  $desiredPowerCLIModule.Dependencies | ? {$_.Name -eq $depModuleName}
   }

   # Save PowerCLI Module Version
   Find-Module -Name $powercliModuleName -RequiredVersion $RequiredVersion | Save-Module -Path $Path

   # Save dependencies with minimum version
   foreach ($dependency in $orderedDependncies) {
      Find-Module $dependency.Name -RequiredVersion $dependency.MinimumVersion | Save-Module -Path $Path
   }

   # Remove newer dependencies versoin
   foreach ($dependency in $orderedDependncies) {
      Get-ChildItem -Path (Join-Path $path $dependency.Name) | `
      Where-Object {$_.Name -ne $dependency.MinimumVersion} | `
      Remove-Item -Confirm:$false -Force -Recurse
   }
}