# Depends on SRM Helper Methods - https://github.com/benmeadowcroft/SRM-Cmdlets
# It is assumed that the connections to active VC and SRM Server have already been made

Import-Module Meadowcroft.SRM -Prefix Srm

$TagCategoryName = 'Meadowcroft.SRM.VM'
$TagCategoryDescription = 'Tag category for tagging VMs with SRM state'

# If the tag category doesn't exist, create it and the relevant tags
$TagCategory = Get-TagCategory -Name $TagCategoryName -ErrorAction SilentlyContinue
if (-Not $TagCategory) {
    Write-Output "Creating Tag Category $TagCategoryName"
    $TagCategory = New-TagCategory -Name $TagCategoryName -Description $TagCategoryDescription -EntityType 'VirtualMachine'

    Write-Output "Creating Tag SrmProtectedVm"
    New-Tag -Name 'SrmProtectedVm' -Category $TagCategory -Description "VM protected by VMware SRM"
    Write-Output "Creating Tag SrmTestVm"
    New-Tag -Name 'SrmTestVm' -Category $TagCategory -Description "Test VM instantiated by VMware SRM"
    Write-Output "Creating Tag SrmPlaceholderVm"
    New-Tag -Name 'SrmPlaceholderVm' -Category $TagCategory -Description "Placeholder VM used by VMware SRM"
}

$protectedVmTag = Get-Tag -Name 'SrmProtectedVm' -Category $TagCategory
$testVmTag = Get-Tag -Name 'SrmTestVm' -Category $TagCategory
$placeholderVmTag = Get-Tag -Name 'SrmPlaceholderVm' -Category $TagCategory

# Assign protected tag to a VM, use ready state to get "local" protected VMs
Get-SrmProtectedVM -State Ready | %{ New-TagAssignment -Tag $protectedVmTag -Entity $(Get-VIObjectByVIView $_.Vm) | Out-Null }

# Assign test tag to a VM
Get-SrmTestVM | %{ New-TagAssignment -Tag $testVmTag -Entity $_ | Out-Null }

# Assign placeholder tag to a VM
Get-SrmPlaceholderVM | %{ New-TagAssignment -Tag $placeholderVmTag -Entity $_ | Out-Null }
