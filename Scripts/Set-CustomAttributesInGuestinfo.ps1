<#
.NOTES
  Script name: Set-CustomAttributesInGuestinfo.ps1
  Created on: 10/04/2018
  Author: Doug Taliaferro, @virtually_doug
  Description: Gets Custom Attributes assigned to a VM and makes them available to the guest OS.
  Dependencies: None known

  ===Tested Against Environment====
  vSphere Version: 6.5
  PowerCLI Version: 10.0.0.7893909
  PowerShell Version: 5.1.14409.1005
  OS Version: Windows 7, 10
  Keyword: VM, Attributes, Guestinfo

.SYNOPSIS
  Gets Custom Attributes assigned to a VM and makes them available to the guest OS.

.DESCRIPTION
  Gets the custom attributes assigned to one or more VMs and sets their values in the 
  VM's 'guestinfo' advanced settings.  This makes the attributes available within the 
  guest OS using VM tools (vmtoolsd.exe) and allows the attributes to be used as metadata 
  for applications or management agents that run inside the guest.  If the attribute name
  contains spaces they are removed in naming the advanced setting.
  
  For example, if a VM has a custom attribute named 'Created On', the advanced setting 
  becomes:
    'guestinfo.CreatedOn' = '08/08/2018 14:24:17'
  
  This can be retrieved in the guest OS by running:
    vmtoolsd.exe --cmd "info-get guestinfo.CreatedOn"

.PARAMETER VMs
  One or more VMs returned from the Get-VM cmdlet.

.PARAMETER Attributes
  The names of the Custom Attributes to get.  If the names contain spaces they must be
  enclosed in quotes.  The spaces will be removed to name the advanced setting.
  
.PARAMETER vCenter
  The vCenter server to connect to.  Optional if you are already connected.

.EXAMPLE
  .\Set-CustomAttributesInGuestInfo.ps1 -VM (get-vm testvm01) -Attributes 'Created On', 'Created By'
  
  Gets the custom attributes 'Created On' and 'Created By' for 'testvm01' and sets their 
  values in 'guestinfo.CreatedOn' and 'guestinfo.CreatedBy'.

.EXAMPLE
  .\Set-CustomAttributesInGuestInfo.ps1-VM (get-cluster Dev-01 | get-vm) -Attributes 'Created On'
  
  Gets the custom attribute 'Created On' for all VMs in the Dev-01 cluster and sets 'guestinfo.CreatedOn'
  on each VM.
#>
#Requires -modules VMware.VimAutomation.Core
[CmdletBinding()]
param (
  [Parameter(Mandatory=$true,Position=0)]
  $VMs,
  [Parameter(Mandatory=$true,Position=1)]
  [string[]]$Attributes,
  [string]$vCenter
)
if ($vCenter) {
  Connect-VIServer $vCenter
}

ForEach ($vm in $VMs) {
  ForEach ($attributeName in $Attributes) {
    # Get the custom attribute with a matcing key name
    $customField = $vm.CustomFields | Where-Object Key -eq $attributeName
    if ($customField) {
      # Remove white space from the attribute name because the advanced 
      # setting name cannot contain spaces
      $attributeNameNoSpaces = $customField.Key -replace '\s',''
      $guestinfoName = "guestinfo.$attributeNameNoSpaces"
      $guestinfoValue = $customField.Value
      Write-Host "$($vm): setting '$guestinfoName' = '$guestinfoValue'"
      New-AdvancedSetting -Entity $vm -Name $guestinfoName -Value $guestinfoValue -Confirm:$false -Force | Out-Null
    } else {
      Write-Host "$($vm): custom attribute '$attributeName' not set on this VM"
    }
  }
}
