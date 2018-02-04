<#
Script name: PowerCLI_FixNestedFolders.ps1
Created on: 01/11/2018
Author: Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com 
Description: The purpose of the script is to remove the nested Version based folders when using Powercli on systems using older versions of PowerShell
Dependencies: None known

===Tested Against Environment====
PowerCLI Version: PowerCLI 6.5.4
PowerShell Version: 5.1, 4.0
OS Version: Server 2016, Server 2012 R2
#>

# Variable used to store where the PowerCLI module folders exist 
$pcliFolder = @()

# Variable used to store the current PSModulePath locations 
$downloadDir = $env:PSModulePath.Split(';')

# Loop to detect PowerCLI module folders in any of the PSModulePath locations
foreach ($possPath in $downloadDir) {

    # Verifying the PSModulePath location exists
    if ((Test-Path -Path $possPath) -eq $true) {

        # Searching for folders with the name of 'VMware.*'
        $tempFolder = Get-ChildItem -Path $possPath -Name "VMware.*"
        
        # If a VMware.* module folder is found, the full path is added to the pcliFolder variable
        if ($tempFolder) {
            
            foreach ($moduleName in $tempFolder) {
                $pcliFolder += $possPath + "\" + $moduleName
            }
        }

    }
}

# Verifying that there were PowerCLI module folders found
if ($pcliFolder) {

    # Looping through each of the found PowerCLI module folders
    foreach ($dir in $pcliFolder) {

        # Variable to be used if there are several PowerCLI module versions available
        $historicDir = $null

        # Varibale used to store the PowerCLI module version folder
        $tempDir = Get-ChildItem -Path $dir

        # Verifying whether or not there are several PowerCLI module versions available by checking for a type of 'array'
        if ($tempDir -is [array]) {

            # Variable used to store the current folder structure
            $historicDir = $tempDir
            # Updating the tempDir variable to only contain the newest PowerCLI module version folder
            $tempDir = $tempDir | Sort-Object Name -Descending | select-Object -First 1

        }

        # Verifying the child item is indeed a folder
        if ($tempDir.GetType().Name -eq "DirectoryInfo") {

            # Obtaining the child objects of the PowerCLI module version folder and copying them to the parent folder
            $tempDir | Get-ChildItem | Copy-Item -Destination $dir -ErrorAction Stop

            # Checking for any nested folders within the PowerCLI module version folder
            if ($tempDir | Get-ChildItem -Directory) {

                # Obtaining and storing the child items to a variable, then copying the items to the parent folder's nested folder
                $nestFolder = $tempDir | Get-ChildItem -Directory
                foreach ($nestDir in $nestFolder) {
                    $nestDir | Get-ChildItem | Copy-Item -Destination ($dir + "\" + $nestDir.Name) -ErrorAction Stop
                }

            }

            # Detecting whether the historicDir variable was used
            if ($historicDir) {

                # Removing any of the former, no longer needed, directory structure
                $historicDir | Remove-Item -Recurse -Force

            }
            else {

                # Removing any of the former, no longer needed, directory structure
                $tempDir | Remove-Item -Recurse -Force

            }
        }
    }

}
else {Write-Host 'No PowerCLI module folders founds in the $PSModulePath directories.'}