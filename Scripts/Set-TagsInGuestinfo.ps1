<#
.NOTES
  Script name: Set-TagsInGuestinfo.ps1
  Created on: 10/02/2018
  Author: Doug Taliaferro, @virtually_doug
  Description: Gets the vSphere Tags assigned to a VM and makes them available to the guest OS.
  Dependencies: None known

  ===Tested Against Environment====
  vSphere Version: 6.5
  PowerCLI Version: 10.0.0.7893909
  PowerShell Version: 5.1.14409.1005
  OS Version: Windows 7, 10
  Keyword: VM, Tags, Guestinfo

.SYNOPSIS
  Gets the vSphere Tags assigned to a VM and makes them available to the guest OS.

.DESCRIPTION
  Gets the tags assigned to one or more VMs from one or more categories and sets the tag values
  in the VM's 'guestinfo' advanced settings.  This makes the tags available within the guest OS
  using VM tools (vmtoolsd.exe) and allows the tags to be used as metadata for applications or
  management agents that run inside the guest.
  
  For example, if a VM has a tag named 'Accounting' from the
  category 'Departments', the advanced setting becomes:
    guestinfo.Departments = Accounting
  
  This can be retrieved in the guest OS by running:
    vmtoolsd.exe --cmd "info-get guestinfo.Departments"

  If multiple tags are assigned from the same category, they are joined using the specified
  delimter (a semicolon by default):
    guestinfo.Departments = Accounting;Sales

.PARAMETER VMs
  One or more VMs returned from the Get-VM cmdlet.

.PARAMETER Categories
  The names of tag categories that should be set in the advanced settings.
 
 .PARAMETER Delimiter
  The delimiting character used for multiple tags of the same category.  Defaults to a
  semicolon.

.PARAMETER vCenter
  The vCenter server to connect to.  Optional if you are already connected.

.EXAMPLE
  .\Set-TagsInGuestInfo.ps1 -VM (get-vm testvm01) -Categories Departments, Environment
  
  Gets tags assigned to 'testvm01' in the Departments and Environment categories and
  sets their values in 'guestinfo.Departments' and 'guestinfo.Environment'.

.EXAMPLE
  .\Set-TagsInGuestInfo.ps1 -VM (get-cluster Dev-01 | get-vm) -Categories Departments
  
  Gets tags assigned to all VMs in the Dev-01 cluster and sets 'guestinfo.Departments'
  on each VM.
#>
#Requires -modules VMware.VimAutomation.Core
[CmdletBinding()]
param (
  [Parameter(Mandatory=$true,Position=0)]
  $VMs,
  [Parameter(Mandatory=$true,Position=1)]
  [string[]]$Categories,
  [string]$Delimiter = ';',
  [string]$vCenter
)
if ($vCenter) {
  Connect-VIServer $vCenter
}

ForEach ($categoryName in $Categories) {
  $category = Get-TagCategory -Name  $categoryName
  if ($category) {
    $guestinfoName = "guestinfo.$category"

    # Get Tag assignments for the VMs
    $tags = Get-TagAssignment -Entity $VMs -Category $category
    
    # Group the tags by VM (in this case the Entity property of Group-Object)
    $groups = $tags | Group-Object -Property Entity
    
    # Get each VM and set the guestinfo
    ForEach ($item in $groups) {
      $vm = get-vm $item.Name
      # Multiple tags of the same category are joined
      $guestinfoValue = $item.Group.Tag.Name -join $Delimiter
      
      Write-Host "$($vm): setting '$guestinfoName' = '$guestinfoValue'"
      New-AdvancedSetting -Entity $vm -Name $guestinfoName -Value $guestinfoValue -Confirm:$false -Force | Out-Null
    }
  } else {
      Write-Host "Category '$categoryName' was not found."
  }
}
