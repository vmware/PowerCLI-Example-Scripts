function Get-PowerCLIInitialization {
<#  
.SYNOPSIS  
    Gathers information on PowerShell resources which refer to the old PowerCLI Initialization Script
.DESCRIPTION 
    Will provide an inventory of scripts, modules, etc refering to the old vSphere PowerCLI directory
.NOTES  
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com
.PARAMETER Path
    Directory path to be searched
.EXAMPLE
	Get-PowerCLIInitialization -Path C:\Temp\Scripts 
	Gathers information from the 'C:\Temp\Scripts\' directory 
#>
[CmdletBinding()] 
	param(
	[Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
        [string]$Path
  	)

	Process {

        #Validate whether a path was passed as a parameter or not
        if (!$Path) {$FullName = (Get-Location).ProviderPath}
        else {
            
            #Validate whether the path passed as a parameter was a literal path or not, then establish the FullName of the desired path
            if ((Test-Path -Path $Path -ErrorAction SilentlyContinue) -eq $true -and $Path -is [System.IO.DirectoryInfo]) {$FullName = (Get-Item -Path $Path).FullName}
            elseif ((Test-Path -Path $Path -ErrorAction SilentlyContinue) -eq $true -and $Path -isnot [System.IO.DirectoryInfo]) {$FullName = (Get-Item -LiteralPath $Path).FullName}
            else {
                $currdir = (Get-Location).ProviderPath
                Write-Warning "No valid path found at - $currdir\$Path"
            }

        }

        if ($FullName) {
    
            #Gather scripts using ps1 extension and have a string matching "\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
            $scripts = Get-ChildItem -Path $FullName -Recurse -Filter *.ps1 -File -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Select-String -Pattern "\\VMware\\Infrastructure\\vSphere PowerCLI\\Scripts\\Initialize-PowerCLIEnvironment.ps1"

            #Create a report of neccessary output based on the scripts gathered above
            $scriptreport = @()
            foreach ($script in $scripts) {

                $singleitem = New-Object System.Object
                $singleitem | Add-Member -Type NoteProperty -Name Filename -Value $script.Filename
                $singleitem | Add-Member -Type NoteProperty -Name LineNumber -Value $script.LineNumber
                $singleitem | Add-Member -Type NoteProperty -Name Path -Value $script.Path.TrimEnd($script.Filename)
                $singleitem | Add-Member -Type NoteProperty -Name FullPath -Value $script.Path
                $scriptreport += $singleitem

            }
            return $scriptreport

        }

    } # End of process
} # End of function

function Get-PowerCLISnapinUse {
<#  
.SYNOPSIS  
    Gathers information on PowerShell resources which refer to the old PowerCLI Snapins
.DESCRIPTION 
    Will provide an inventory of scripts, modules, etc refering to the old PowerCLI Snapins
.NOTES  
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com
.PARAMETER Path
    Directory path to be searched
.EXAMPLE
	Get-PowerCLISnapinUse -Path C:\Temp\Scripts
    Gathers information from the 'C:\Temp\Scripts\' directory 
#>
[CmdletBinding()] 
	param(
		[Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
        [string]$Path
  	)

	Process {

        #Validate whether a path was passed as a parameter or not
        if (!$Path) {$FullName = (Get-Location).ProviderPath}
        else {
        
            #Validate whether the path passed as a parameter was a literal path or not, then establish the FullName of the desired path
            if ((Test-Path -Path $Path -ErrorAction SilentlyContinue) -eq $true -and $Path -is [System.IO.DirectoryInfo]) {$FullName = (Get-Item -Path $Path).FullName}
            elseif ((Test-Path -Path $Path -ErrorAction SilentlyContinue) -eq $true -and $Path -isnot [System.IO.DirectoryInfo]) {$FullName = (Get-Item -LiteralPath $Path).FullName}
            else {
                $currdir = (Get-Location).ProviderPath
                Write-Warning "No valid path found at - $currdir\$Path"
            }

        }

        if ($FullName) {
    
            #Gather scripts using ps1 extension and have a string matching "add-pssnapin" and "VMware." on the same line
            $scripts = Get-ChildItem -Path $FullName -Recurse -Filter *.ps1 -File -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Select-String -Pattern "add-pssnapin" | Where-Object {$_ | Select-String -Pattern "VMware."}

            #Create a report of neccessary output based on the scripts gathered above
            $scriptreport = @()
            foreach ($script in $scripts) {

                $singleitem = New-Object System.Object
                $singleitem | Add-Member -Type NoteProperty -Name Filename -Value $script.Filename
                $singleitem | Add-Member -Type NoteProperty -Name LineNumber -Value $script.LineNumber
                $singleitem | Add-Member -Type NoteProperty -Name Path -Value $script.Path.TrimEnd($script.Filename)
                $singleitem | Add-Member -Type NoteProperty -Name FullPath -Value $script.Path
                $scriptreport += $singleitem

            }

            return $scriptreport

        }

    } # End of process
} # End of function

function Update-PowerCLIInitialization {
<#  
.SYNOPSIS  
    Updates the information in PowerShell resources which refer to the old PowerCLI Initialization Script
.DESCRIPTION 
    Will update scripts, modules, etc refering to the old vSphere PowerCLI directory
.NOTES  
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com
.PARAMETER Path
    Directory path to be searched
.EXAMPLE
    Update-PowerCLIInitialization -Path C:\Temp\Scripts
    Gathers information from the 'C:\Temp\Scripts\' directory 
#>
[CmdletBinding(SupportsShouldProcess)] 
	param(
	[Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
        [string]$Path
  	)

	Process {

        #Gather scripts using ps1 extension and have a string matching "\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
        $scripts = Get-PowerCLIInitialization -Path $Path

        #Check to see if any scripts are found
        if (!$scripts) {Write-Warning "No PowerShell resources found requiring update within $Path"}
        else {

            foreach ($script in $scripts) {

                #Finds and updates the string to the new location of the Initialize-PowerCLIEnvironment.ps1 script
                (Get-Content $script.FullPath).Replace("\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1","\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1") | Set-Content $script.FullPath

            }

        }


    } # End of process
} # End of function

function Update-PowerCLISnapinUse {
<#  
.SYNOPSIS  
    Updates the information in PowerShell resources which refer to the old PowerCLI Initialization Script
.DESCRIPTION 
    Will update scripts, modules, etc refering to the old vSphere PowerCLI directory
.NOTES  
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com
.PARAMETER Path
    Directory path to be searched
.EXAMPLE
	Update-PowerCLISnapinUse -Path C:\Temp\Scripts
    Gathers information from the 'C:\Temp\Scripts\' directory 
#>
[CmdletBinding(SupportsShouldProcess)] 
	param(
		[Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
        [string]$Path
  	)

	Process {

        #Gather scripts using ps1 extension and have a string matching "\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
        $scripts = Get-PowerCLISnapinUse -Path $Path | select -Unique FullPath

        #Check to see if any scripts are found
        if (!$scripts) {Write-Warning "No PowerShell resources found requiring update within $Path"}
        else {

            foreach ($script in $scripts) {

                #Finds and updates the string to import the PowerCLI modules
                $scriptcontent = (Get-Content $script.FullPath)
                
                $newoutput = @()
                [int]$counter = 0
                foreach ($line in $scriptcontent) {
                    
                    #Checks to see if the line includes adding in the VMware PSSnapins and, if so, comments it out
                    #On first discovery, adds the invokation of get-module for the PowerCLI modules
                    if ($line -like "Add-PSSnapin*VMware*" -and $counter -eq 0) {

                        $newoutput += "Get-Module -ListAvailable VMware* | Import-Module"
                        $newoutput += $line.Insert(0,'#')
                        $counter = 1

                    }
                    elseif ($line -like "Add-PSSnapin*VMware*" -and $counter -eq 1) {

                        $newoutput += $line.Insert(0,'#')

                    }
                    else {$newoutput += $line}

                }

                #Updates the script
                Set-Content -Value $newoutput -Path $script.FullPath

            }

        }
        
    } # End of process
} # End of function
