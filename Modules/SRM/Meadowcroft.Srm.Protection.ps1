# SRM Helper Methods - https://github.com/benmeadowcroft/SRM-Cmdlets

<#
.SYNOPSIS
Get the subset of protection groups matching the input criteria

.PARAMETER Name
Return protection groups matching the specified name

.PARAMETER Type
Return protection groups matching the specified protection group
type. For SRM 5.0-5.5 this is either 'san' for protection groups
consisting of a set of replicated datastores or 'vr' for vSphere
Replication based protection groups.

.PARAMETER RecoveryPlan
Return protection groups associated with a particular recovery
plan

.PARAMETER SrmServer
the SRM server to use for this operation.
#>
Function Get-ProtectionGroup {
    [cmdletbinding()]
    Param(
        [Parameter(position=1)][string] $Name,
        [string] $Type,
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan,
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )
    begin {
        $api = Get-ServerApiEndpoint -SrmServer $SrmServer
        $pgs = @()
    }
    process {
        if ($RecoveryPlan) {
            foreach ($rp in $RecoveryPlan) {
                $pgs += $RecoveryPlan.GetInfo().ProtectionGroups
            }
            $pgs = Select_UniqueByMoRef($pgs)
        } else {
            $pgs += $api.Protection.ListProtectionGroups()
        }
    }
    end {
        $pgs | ForEach-Object {
            $pg = $_
            $pgi = $pg.GetInfo()
            $selected = (-not $Name -or ($Name -eq $pgi.Name)) -and (-not $Type -or ($Type -eq $pgi.Type))
            if ($selected) {
                Add-Member -InputObject $pg -MemberType NoteProperty -Name "Name" -Value $pgi.Name 
                $pg
            }
        }
    }
}

<#
.SYNOPSIS
Get the subset of protected VMs matching the input criteria

.PARAMETER Name
Return protected VMs matching the specified name

.PARAMETER State
Return protected VMs matching the specified state. For protected
VMs on the protected site this is usually 'ready', for
placeholder VMs this is 'shadowing'

.PARAMETER ProtectionGroup
Return protected VMs associated with particular protection
groups
#>
Function Get-ProtectedVM {
    [cmdletbinding()]
    Param(
        [Parameter(position=1)][string] $Name,
        [VMware.VimAutomation.Srm.Views.SrmProtectionGroupProtectionState] $State,
        [VMware.VimAutomation.Srm.Views.SrmProtectionGroupProtectionState] $PeerState,
        [switch] $ConfiguredOnly,
        [switch] $UnconfiguredOnly,
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmProtectionGroup[]] $ProtectionGroup,
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan,
        [string] $ProtectionGroupName,
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    if ($null -eq $ProtectionGroup) {
        $ProtectionGroup = Get-ProtectionGroup -Name $ProtectionGroupName -RecoveryPlan $RecoveryPlan -SrmServer $SrmServer
    }
    $ProtectionGroup | ForEach-Object {
        $pg = $_
        $pg.ListProtectedVms() | ForEach-Object {
            # try and update the view data for the protected VM
            try {
                $_.Vm.UpdateViewData()
            } catch {
                Write-Error $_            
            } finally {
                $_
            }
        } | Where-object { -not $Name -or ($Name -eq $_.Vm.Name) } |
            where-object { -not $State -or ($State -eq $_.State) } |
            where-object { -not $PeerState -or ($PeerState -eq $_.PeerState) } |
            where-object { ($ConfiguredOnly -and $_.NeedsConfiguration -eq $false) -or ($UnconfiguredOnly -and $_.NeedsConfiguration -eq $true) -or (-not $ConfiguredOnly -and -not $UnconfiguredOnly) }
    }
}


<#
.SYNOPSIS
Get the unprotected VMs that are associated with a protection group

.PARAMETER ProtectionGroup
Return unprotected VMs associated with particular protection
groups. For VR protection groups this is VMs that are associated
with the PG but not configured, For ABR protection groups this is
VMs on replicated datastores associated with the group that are not
configured.
#>
Function Get-UnProtectedVM {
    [cmdletbinding()]
    Param(
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmProtectionGroup[]] $ProtectionGroup,
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan,
        [string] $ProtectionGroupName,
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    if ($null -eq $ProtectionGroup) {
        $ProtectionGroup = Get-ProtectionGroup -Name $ProtectionGroupName -RecoveryPlan $RecoveryPlan -SrmServer $SrmServer
    }

    $associatedVMs = @()
    $protectedVmRefs = @()

    $ProtectionGroup | ForEach-Object {
        $pg = $_
        # For VR listAssociatedVms to get list of VMs
        if ($pg.GetInfo().Type -eq 'vr') {
            $associatedVMs += @($pg.ListAssociatedVms() | Get-VIObjectByVIView)
        }
        # TODO test this: For ABR get VMs on GetProtectedDatastore
        if ($pg.GetInfo().Type -eq 'san') {
            $pds = @(Get-ProtectedDatastore -ProtectionGroup $pg)
            $pds | ForEach-Object {
                $ds = Get-Datastore -id $_.MoRef
                $associatedVMs += @(Get-VM -Datastore $ds)
            }
        }

        # get protected VMs
        $protectedVmRefs += @(Get-ProtectedVM -ProtectionGroup $pg | ForEach-Object { $_.Vm.MoRef } | Select-Object -Unique)
    }

    # get associated but unprotected VMs
    $associatedVMs | Where-Object { $protectedVmRefs -notcontains $_.ExtensionData.MoRef }
}


#Untested as I don't have ABR setup in my lab yet
<#
.SYNOPSIS
Get the subset of protected Datastores matching the input criteria

.PARAMETER ProtectionGroup
Return protected datastores associated with particular protection
groups
#>
Function Get-ProtectedDatastore {
    [cmdletbinding()]
    Param(
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmProtectionGroup[]] $ProtectionGroup,
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan,
        [string] $ProtectionGroupName,
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    if (-not $ProtectionGroup) {
        $ProtectionGroup = Get-ProtectionGroup -Name $ProtectionGroupName -RecoveryPlan $RecoveryPlan -SrmServer $SrmServer
    }
    $ProtectionGroup | ForEach-Object {
        $pg = $_
        if ($pg.GetInfo().Type -eq 'san') { # only supported for array based replication datastores
            $pg.ListProtectedDatastores()
        }
    }
}


#Untested as I don't have ABR setup in my lab yet
<#
.SYNOPSIS
Get the replicated datastores that aren't associated with a protection group.
#>
Function Get-ReplicatedDatastore {
    [cmdletbinding()]
    Param(
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    $api = Get-ServerApiEndpoint -SrmServer $SrmServer

    $api.Protection.ListUnassignedReplicatedDatastores()
}

<#
.SYNOPSIS
Protect a VM using SRM

.PARAMETER ProtectionGroup
The protection group that this VM will belong to

.PARAMETER Vm
The virtual machine to protect
#>
Function Protect-VM {
    [cmdletbinding()]
    Param(
        [Parameter (Mandatory=$true)][VMware.VimAutomation.Srm.Views.SrmProtectionGroup] $ProtectionGroup,
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $Vm,
        [Parameter (ValueFromPipeline=$true)][VMware.Vim.VirtualMachine] $VmView
    )

    $moRef = Get_MoRefFromVmObj -Vm $Vm -VmView $VmView

    $pgi = $ProtectionGroup.GetInfo()
    #TODO query protection status first

    if ($moRef) {
        if ($pgi.Type -eq 'vr') {
            $ProtectionGroup.AssociateVms(@($moRef))
        }
        $protectionSpec = New-Object VMware.VimAutomation.Srm.Views.SrmProtectionGroupVmProtectionSpec
        $protectionSpec.Vm = $moRef
        $protectTask = $ProtectionGroup.ProtectVms($protectionSpec)
        while(-not $protectTask.IsComplete()) { Start-Sleep -Seconds 1 }
        $protectTask.GetResult()
    } else {
        throw "Can't protect the VM, no MoRef found."
    }
}


<#
.SYNOPSIS
Unprotect a VM using SRM

.PARAMETER ProtectionGroup
The protection group that this VM will be removed from

.PARAMETER Vm
The virtual machine to unprotect
#>
Function Unprotect-VM {
    [cmdletbinding()]
    Param(
        [Parameter (Mandatory=$true)][VMware.VimAutomation.Srm.Views.SrmProtectionGroup] $ProtectionGroup,
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $Vm,
        [Parameter (ValueFromPipeline=$true)][VMware.Vim.VirtualMachine] $VmView,
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmProtectionGroupProtectedVm] $ProtectedVm
    )

    $moRef = Get_MoRefFromVmObj -Vm $Vm -VmView $VmView -ProtectedVm $ProtectedVm

    $pgi = $ProtectionGroup.GetInfo()
    $protectTask = $ProtectionGroup.UnprotectVms($moRef)
    while(-not $protectTask.IsComplete()) { Start-Sleep -Seconds 1 }
    if ($pgi.Type -eq 'vr') {
        $ProtectionGroup.UnassociateVms(@($moRef))
    }
    $protectTask.GetResult()
}

<#
.SYNOPSIS
Get a protection group folder

.PARAMETER SrmServer
The SRM Server to query for the protection group folder
#>
Function Get-ProtectionGroupFolder {
    [cmdletbinding()]
    Param(
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    $api = Get-ServerApiEndpoint -SrmServer $SrmServer

    $folder = $api.Protection.GetProtectionGroupRootFolder()

    return $folder
}

<#
.SYNOPSIS
Create a new protection group

.PARAMETER Name
The name of the protection group

.PARAMETER Description
Description of the protection group

.PARAMETER Folder
The protection group folder in which to create the new protection group

.PARAMETER ArrayReplication
Set if protection group is for replicating VMs using Array based replication

.PARAMETER vSphereReplication
Set if protection group is for replicating VMs with vSphere Replication

.PARAMETER VMs
For vSphere Replication based protection, the VMs to add to the replication
group. These should already be replicated.

.PARAMETER VMViews
For vSphere Replication based protection, the VMs to add to the replication
group. These should already be replicated.

.PARAMETER SrmServer
The SRM Server to perform the operation against
#>
Function New-ProtectionGroup {
    [cmdletbinding(DefaultParameterSetName="VR", SupportsShouldProcess=$True, ConfirmImpact="Medium")]
    [OutputType([VMware.VimAutomation.Srm.Views.SrmProtectionGroup])]
    Param(
        [Parameter (Mandatory=$true)] $Name,
        $Description,
        [VMware.VimAutomation.Srm.Views.SrmProtectionGroupFolder] $Folder,
        [Parameter (ParameterSetName="ABR", Mandatory=$true)][switch] $ArrayReplication,
        [Parameter (ValueFromPipeline=$true, ParameterSetName="ABR")][VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.Datastore[]] $Datastores,
        [Parameter (ValueFromPipeline=$true, ParameterSetName="ABR")][VMware.Vim.Datastore[]] $DatastoreViews,
        [Parameter (ParameterSetName="VR", Mandatory=$true)][switch] $vSphereReplication,
        [Parameter (ValueFromPipeline=$true, ParameterSetName="VR")][VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VMs,
        [Parameter (ValueFromPipeline=$true, ParameterSetName="VR")][VMware.Vim.VirtualMachine[]] $VMViews,
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    $api = Get-ServerApiEndpoint $SrmServer
    [VMware.VimAutomation.Srm.Views.SrmCreateProtectionGroupTask] $task = $null

    #get root folder if this wasn't specified as a parameter
    if(-not $Folder) {
        $Folder = Get-ProtectionGroupFolder -SrmServer $SrmServer
    }

    if ($vSphereReplication) {
        #create list of managed object references from VM and/or VM view arrays
        [VMware.Vim.ManagedObjectReference[]]$moRefs = @()
        foreach ($vm in $VMs) {
            $moRefs += Get_MoRefFromVmObj -Vm $Vm
        }
        foreach ($VmView in $VMViews) {
            $moRefs += Get_MoRefFromVmObj -VmView $VmView
        }

        if ($pscmdlet.ShouldProcess($Name, "New")) {
            $task = $api.Protection.CreateHbrProtectionGroup($Folder.MoRef, $Name, $Description, $moRefs)
        }
        
    } elseif ($ArrayReplication) {
        #create list of managed object references from VM and/or VM view arrays
        $moRefs = @()
        foreach ($ds in $Datastores) {
            $moRefs += $ds.ExtensionData.MoRef
        }
        foreach ($DsView in $DatastoreViews) {
            $moRefs += $DsView.MoRef
        }

        if ($pscmdlet.ShouldProcess($Name, "New")) {
            $task = $api.Protection.CreateAbrProtectionGroup($Folder.MoRef, $Name, $Description, $moRefs)
        }
        
    } else {
        throw "Undetermined protection group type"
    }

    # Complete task
    while(-not $task.IsCreateProtectionGroupComplete()) { Start-Sleep -Seconds 1 }

    # Retrieve the protection group, and protect associated VMs
    $pg = $task.GetNewProtectionGroup()
    if ($pg) {
        $unProtectedVMs = Get-UnProtectedVM -ProtectionGroup $pg
        $unProtectedVMs | Protect-VM -ProtectionGroup $pg
    }      

    return $pg
}


<#
.SYNOPSIS
Delete a protection group

.PARAMETER ProtectionGroup
The protection group to remove

.PARAMETER SrmServer
The SRM Server to perform the operation against
#>
Function Remove-ProtectionGroup {
    [cmdletbinding(SupportsShouldProcess=$True, ConfirmImpact="High")]
    [OutputType([VMware.VimAutomation.Srm.Views.RemoveProtectionGroupTask])]
    Param(
        [Parameter (Mandatory=$true, ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmProtectionGroup] $ProtectionGroup,
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    $api = Get-ServerApiEndpoint $SrmServer
    [VMware.VimAutomation.Srm.Views.RemoveProtectionGroupTask] $task = $null

    $pginfo = $ProtectionGroup.GetInfo()
    if ($pscmdlet.ShouldProcess($pginfo.Name, "Remove")) {
        $task = $api.Protection.RemoveProtectionGroup($ProtectionGroup.MoRef)
    }

    return $task
}
