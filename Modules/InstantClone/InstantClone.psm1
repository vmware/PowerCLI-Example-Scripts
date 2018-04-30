Function New-InstantClone {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Apr 29, 2018
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
    ===========================================================================
    .SYNOPSIS
        This function demonstrates the use of the new "Parentless" Instant Clone
        API that was introduced in vSphere 6.7
    .DESCRIPTION
        Function to create new "Parentless" Instant Clones in vSphere 6.7
    .EXAMPLE
        $SourceVM = "Foo"
        $newVMName = Foo-IC-1
        $guestCustomizationValues = @{
            "guestinfo.ic.hostname" = $newVMName
            "guestinfo.ic.ipaddress" = "192.168.30.10"
            "guestinfo.ic.netmask" = "255.255.255.0"
            "guestinfo.ic.gateway" = "192.168.30.1"
            "guestinfo.ic.dns" = "192.168.30.1"
        }
        New-InstantClone -SourceVM $SourceVM -DestinationVM $newVMName -CustomizationFields $guestCustomizationValues
    .NOTES
        Make sure that you have both a vSphere 6.7 env (VC/ESXi) as well as
        as the latest PowerCLI 10.1 installed which is reuqired to use vSphere 6.7 APIs
#>
    param(
        [Parameter(Mandatory=$true)][String]$SourceVM,
        [Parameter(Mandatory=$true)][String]$DestinationVM,
        [Parameter(Mandatory=$true)][Hashtable]$CustomizationFields
    )
    $vm = Get-VM -Name $SourceVM

    $config = @()
    $CustomizationFields.GetEnumerator() | Foreach-Object {
        $optionValue = New-Object VMware.Vim.OptionValue
        $optionValue.Key = $_.Key
        $optionValue.Value = $_.Value
        $config += $optionValue
    }

    # SourceVM must either be running or running but in Frozen State
    if($vm.PowerState -ne "PoweredOn") {
        Write-Host -ForegroundColor Red "Instant Cloning is only supported on a PoweredOn or Frozen VM"
        break
    }

    # SourceVM == Powered On
    if((Get-VM $SourceVM).ExtensionData.Runtime.InstantCloneFrozen -eq $false) {
        Write-Host -ForegroundColor Red "Instant Cloning from a PoweredOn VM has not been implemented"
        break
    }

    $spec = New-Object VMware.Vim.VirtualMachineInstantCloneSpec
    $locationSpec = New-Object VMware.Vim.VirtualMachineRelocateSpec
    $spec.Config = $config
    $spec.Location = $locationSpec
    $spec.Name = $DestinationVM

    Write-Host "Creating Instant Clone $DestinationVM ..."
    $task = $vm.ExtensionData.InstantClone_Task($spec)
    $task1 = Get-Task -Id ("Task-$($task.value)")
    $task1 | Wait-Task | Out-Null
}