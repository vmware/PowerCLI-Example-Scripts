function Save-PowerCLI {
<#  
.SYNOPSIS  
    Advanced function which can be used to easily download specific versions of PowerCLI from an online gallery
.DESCRIPTION 
    Downloads a specific version of PowerCLI and all the dependencies at the appropriate version
.NOTES  
    Author: 1.0 - Dimitar Milov 
    Author: 2.0 - Kyle Ruddy, @kmruddy
    Author: 2.1 - Luc Dekens, @LucD22
        - fixed issue with downloading the correct versions
        - added a working cleanup of unwanted versions
.PARAMETER RequiredVersion
    Dynamic parameter used to specify the PowerCLI version
.PARAMETER Path
    Directory path where the modules should be downloaded
.PARAMETER Repository
    Repository to access the PowerCLI modules
.PARAMETER Simple
    Switch used to specify the nested version folders should be removed (therefore adding PowerShell 3/4 compatibility)
.EXAMPLE
    Save-PowerCLI -RequiredVersion '10.0.0.7895300' -Path .\Downloads\ 
    Downloads PowerCLI 10.0.0 to the Downloads folder 
.EXAMPLE
    Save-PowerCLI -RequiredVersion '6.5.2.6268016' -Path .\Downloads\ -Simple
    Downloads PowerCLI 6.5.2 to the Downloads folder and removes the nested version folders
#>
    [CmdletBinding(SupportsShouldProcess = $True)] 
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateScript( { Test-Path $_} )]
        $Path,
        [Parameter(Mandatory = $false, Position = 2)]
        [string]$Repository = 'PSGallery',
        [Parameter(Mandatory = $false, Position = 3)]
        [Switch]$Simple
    )
    DynamicParam
    {
        # Set the dynamic parameters name
        $ParameterName = 'RequiredVersion'
 
        # Create the dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
 
        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
 
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.ValueFromPipeline = $true
        $ParameterAttribute.ValueFromPipelineByPropertyName = $true
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 0
 
        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)
 
        # Generate and set the ValidateSet
        $pcliVersions = Find-Module -Name 'VMware.PowerCLI' -AllVersions
        $arrSet = $pcliVersions | select-Object -ExpandProperty Version
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
 
        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)
 
        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [String], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin {
        $powercliModuleName = 'VMware.PowerCLI'
        $desiredPowerCLIModule = Find-Module -Name $powercliModuleName -RequiredVersion $PSBoundParameters.RequiredVersion -Repository $Repository

        $depsOrder = 'VMware.VimAutomation.Sdk', 'VMware.VimAutomation.Common', 'VMware.Vim', 'VMware.VimAutomation.Cis.Core', 'VMware.VimAutomation.Core', 'VMware.VimAutomation.Nsxt', 'VMware.VimAutomation.Vmc', 'VMware.VimAutomation.Vds', 'VMware.VimAutomation.Srm', 'VMware.ImageBuilder', 'VMware.VimAutomation.Storage', 'VMware.VimAutomation.StorageUtility', 'VMware.VimAutomation.License', 'VMware.VumAutomation', 'VMware.VimAutomation.HorizonView', 'VMware.DeployAutomation', 'VMware.VimAutomation.vROps', 'VMware.VimAutomation.PCloud'
        $orderedDependencies = @()
        foreach ($depModuleName in $depsOrder) {
            $orderedDependencies +=  $desiredPowerCLIModule.Dependencies | Where-Object {$_.Name -eq $depModuleName}
        }

        foreach ($remainingDep in $desiredPowerCLIModule.Dependencies) {
            if ($orderedDependencies.Name -notcontains $remainingDep.Name) {
                $orderedDependencies +=  $remainingDep
            }
    
        }
    }

    process {
        # Save PowerCLI Module Version
        $desiredPowerCLIModule | Save-Module -Path $Path
    
        # Working with the depenent modules 
        foreach ($dependency in $orderedDependencies) {
            if (Get-ChildItem -Path (Join-Path $path $dependency.Name) | Where-Object {$_.Name -ne $dependency.MinimumVersion}) {
                # Save dependencies with minimum version
                Find-Module $dependency.Name -RequiredVersion $dependency.MinimumVersion | Save-Module -Path $Path
            }
        }
    }

    end {
        Get-Item -Path "$($Path)\*" -PipelineVariable dir |
        ForEach-Object -Process {
            $children = Get-ChildItem -Path $dir.FullName -Directory
            if($children.Count -gt 1){
                $tgtVersion = $orderedDependencies.GetEnumerator() | where {$_.Name -eq $dir.Name}
                $children | where{$_.Name -ne $tgtVersion.MinimumVersion} |
                ForEach-Object -Process {
                    Remove-Item -Path $_.FullName -Recurse -Force -Confirm:$false 
                }
            }
        }
                       
        if ($Simple) {

            function FolderCleanup {
                param(
                    [Parameter(Mandatory = $true, Position = 0)]
                    [ValidateScript( { Test-Path $_} )]
                    $ParentFolder,
                    [Parameter(Mandatory = $true, Position = 1)]
                    [String]$ModuleName,
                    [Parameter(Mandatory = $true, Position = 2)]
                    $Version
                )
            
            
                $topFolder = Get-Item -Path (Join-Path $ParentFolder $ModuleName)
                $versionFolder = $topFolder | Get-ChildItem -Directory | Where-Object {$_.Name -eq $Version} 
                $versionFolder | Get-ChildItem | Copy-Item -Destination $topFolder
            
                # Checking for any nested folders within the PowerCLI module version folder
                if ($versionFolder| Get-ChildItem -Directory) {
            
                    # Obtaining and storing the child items to a variable, then copying the items to the parent folder's nested folder
                    $nestFolder = $versionFolder| Get-ChildItem -Directory
                    foreach ($nestDir in $nestFolder) {
                        $nestDir | Get-ChildItem | Copy-Item -Destination (Join-Path $topFolder $nestDir.Name)
                    }
            
                }
            
                # Removing any of the former, no longer needed, directory structure
                $versionFolder| Remove-Item -Recurse -Force
            }

            FolderCleanup -ParentFolder $Path -ModuleName $desiredPowerCLIModule.Name -Version $desiredPowerCLIModule.Version
            foreach ($cleanUp in $orderedDependencies) {

                FolderCleanup -ParentFolder $Path -ModuleName $cleanUp.Name -Version $cleanUp.MinimumVersion    
            }

        }
    }
}
