<#
Script name: Set-CISVMTagAssociation.ps1
Created on: 10/05/2017
Author: Kyle Ruddy, @kmruddy
Description: The purpose of the script is to assign a tag to a VM
Dependencies: None known

===Tested Against Environment====
vSphere Version: 6.5U1
PowerCLI Version: PowerCLI 6.5.3
PowerShell Version: 5.1
OS Version: Windows 10
Keyword: VM, Tag
#>

[CmdletBinding(SupportsShouldProcess=$True)] 
	param(
		[Parameter(Mandatory=$true,Position=0)]
		[String]$vmName, 
        [Parameter(Mandatory=$true,Position=1)]
        [String]$TagName
  	)

    Begin {
        #Checking for connection to a CIS Server endpoint
        if ($global:DefaultCisServers.IsConnected -ne $true) {Write-Warning "Currently not connected to a CIS Server. Please use 'Connect-CisServer' to establish a connection and try again."; Exit}
        #Create an array to store output prior to return
        $tags = @()
        $output = @()
        #Establishing variables to the neccessary services, exiting if they don't respond
        $vmSvc = Get-CisService -Name com.vmware.vcenter.vm -ErrorAction SilentlyContinue
        if ($vmSvc -eq $null) {Write-Warning "Warning: Check connection to the CIS Server."; Exit}
        $tagSvc = Get-CisService -Name com.vmware.cis.tagging.tag -ErrorAction SilentlyContinue
        if ($tagSvc -eq $null) {Write-Warning "Warning: Check connection to the CIS Server."; Exit}
        $tagAssoc = Get-CisService -Name com.vmware.cis.tagging.tag_association -ErrorAction SilentlyContinue
        if ($tagAssoc -eq $null) {Write-Warning "Warning: Check connection to the CIS Server."; Exit}
	}

    Process {
        #Retreiving all available tags 
        $tagList = $tagSvc.list()
        foreach ($t in $tagList) {
            $tags += $tagSvc.Get($t)
        }
        #Searches for a tag with the name given as a parameter
        $tag = $tags | Where-Object {$_.Name -eq $tagName}
        if ($tag -eq $null) {Write-Warning "No tag found with a name of: $tagName"; exit}
        #Searches for a VM with the name given as a parameter 
        $vm = $vmSvc.list() | Where-Object {$_.Name -eq $vmName}
        if ($vm -eq $null) {Write-Warning "No VM found with a name of: $vmName"; exit}
        #Creates the neccessary Object ID object for the association command
        $objId = $tagAssoc.Help.attach.object_id.Create()
        $objId.type = "VirtualMachine"
        $objId.id = $vm.vm
        #Performs the tag association 
        $tagAssoc.attach($tag.id.Value, $objId)
        #Gathers and then outputs the tags associated to that VM
        $attachedTags = $tagAssoc.list_attached_tags($objId)
        foreach ($at in $attachedTags) {
            $output = $tagSvc.Get($at)
        }

    }

    End {
        #Returns the output to the current session
        return $output

    }