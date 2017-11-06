<#
Script name: Get-CISTag.ps1
Created on: 10/05/2017
Author: Kyle Ruddy, @kmruddy
Description: The purpose of the script is to obtain either all of the vCenter’s tags or just a specific tag with the ‘TagName’ parameter
Dependencies: None known

===Tested Against Environment====
vSphere Version: 6.5U1
PowerCLI Version: PowerCLI 6.5.3
PowerShell Version: 5.1
OS Version: Windows 10
Keyword: Tag
#>

[CmdletBinding(SupportsShouldProcess=$True)] 
    param(
        [Parameter(Mandatory=$false,Position=0)]
        [String]$TagName
    )

    Begin {

        #Checking for connection to a CIS Server endpoint
        if ($global:DefaultCisServers.IsConnected -ne $true) {Write-Warning "Currently not connected to a CIS Server. Please use 'Connect-CisServer' to establish a connection and try again."; Exit}
        #Create an array to store output prior to return
        $output = @()
        #Establishing variables to the neccessary services, exiting if they don't respond
        $tagSvc = Get-CisService -Name com.vmware.cis.tagging.tag -ErrorAction SilentlyContinue
        if ($tagSvc -eq $null) {Write-Warning "Warning: Check connection to the CIS Server."; Exit}

    }

    Process {
    
        #Retreiving all available tags 
        $tagList = $tagSvc.list()

        if ($TagName -eq "") {
            foreach ($t in $tagList) {
                $output += $tagSvc.Get($t)
            }
        }
        else {

            $tags = @()
            foreach ($t in $tagList) {
                $tags += $tagSvc.Get($t)
            }
            #Searches for a tag with the name given as a parameter
            $output = $tags | Where-Object {$_.Name -eq $tagName}

        }
    }

    End {
        #Returns the output to the current session
        return $output

    }
