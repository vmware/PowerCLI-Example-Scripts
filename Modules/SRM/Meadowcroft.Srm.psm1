# SRM Helper Methods - https://github.com/benmeadowcroft/SRM-Cmdlets

<#
.SYNOPSIS
This is intended to be an "internal" function only. It filters a
pipelined input of objects and elimiates duplicates as identified
by the MoRef property on the object.

.LINK
https://github.com/benmeadowcroft/SRM-Cmdlets/
#>
Function Select_UniqueByMoRef {

    Param(
        [Parameter (ValueFromPipeline=$true)] $in
    )
    process {
        $moref = New-Object System.Collections.ArrayList
        $in | Sort-Object | Select-Object MoRef -Unique | ForEach-Object { $moref.Add($_.MoRef) } > $null
        $in | ForEach-Object {
            if ($_.MoRef -in $moref) {
                $moref.Remove($_.MoRef)
                $_ #output
            }
        }
    }
}

<#
.SYNOPSIS
This is intended to be an "internal" function only. It gets the
MoRef property of a VM from either a VM object, a VM view, or the
protected VM object.
#>
Function Get_MoRefFromVmObj {
    Param(
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $Vm,
        [Parameter (ValueFromPipeline=$true)][VMware.Vim.VirtualMachine] $VmView,
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmProtectionGroupProtectedVm] $ProtectedVm
    )


    $moRef = $null
    if ($Vm.ExtensionData.MoRef) { # VM object
        $moRef = $Vm.ExtensionData.MoRef
    } elseif ($VmView.MoRef) { # VM view
        $moRef = $VmView.MoRef
    } elseif ($protectedVm) {
        $moRef = $ProtectedVm.Vm.MoRef
    }

    $moRef
}

<#
.SYNOPSIS
Lookup the srm instance for a specific server.
#>
Function Get-Server {
    [cmdletbinding()]
    Param(
        [string] $SrmServerAddress,
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    $found = $null

    if ($SrmServer) {
        $found = $SrmServer
    } elseif ($SrmServerAddress) {
        # search for server address in default servers
        $global:DefaultSrmServers | ForEach-Object {
            if ($_.Name -ieq $SrmServerAddress) {
                $found = $_
            }
        }
        if (-not $found) {
            throw "SRM server $SrmServerAddress not found. Connect-Server must be called first."
        }
    }

    if (-not $found) {
        #default result
        $found = $global:DefaultSrmServers[0]
    }

    return $found;
}

<#
.SYNOPSIS
Retrieve the SRM Server Version
#>
Function Get-ServerVersion {
    [cmdletbinding()]
    Param(
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )
    $srm = Get-Server $SrmServer
    $srm.Version
}

<#
.SYNOPSIS
Lookup the SRM API endpoint for a specific server.
#>
Function Get-ServerApiEndpoint {
    [cmdletbinding()]
    Param(
        [string] $SrmServerAddress,
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    [VMware.VimAutomation.Srm.Types.V1.SrmServer] $server = Get-Server -SrmServerAddress $SrmServerAddress -SrmServer $SrmServer

    return $server.ExtensionData
}

<#
.SYNOPSIS
Get the placeholder VMs that are associated with SRM
#>
Function Get-PlaceholderVM {
    [cmdletbinding()]
    Param()
    Get-VM @Args | Where-Object {$_.ExtensionData.Config.ManagedBy.extensionKey -like "com.vmware.vcDr*" -and $_.ExtensionData.Config.ManagedBy.Type -ieq 'placeholderVm'}
}

<#
.SYNOPSIS
Get the test VMs that are associated with SRM
#>
Function Get-TestVM {
    [cmdletbinding()]
    Param()
    Get-VM @Args | Where-Object {$_.ExtensionData.Config.ManagedBy.extensionKey -like "com.vmware.vcDr*" -and $_.ExtensionData.Config.ManagedBy.Type -ieq 'testVm'}
}

<#
.SYNOPSIS
Get the VMs that are replicated using vSphere Replication. These may not be SRM
protected VMs.
#>
Function Get-ReplicatedVM {
    [cmdletbinding()]
    Param()
    Get-VM @Args | Where-Object {($_.ExtensionData.Config.ExtraConfig | Where-Object { $_.Key -eq 'hbr_filter.destination' -and $_.Value } )}
}
