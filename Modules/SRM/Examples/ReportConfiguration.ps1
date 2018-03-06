# Depends on SRM Helper Methods - https://github.com/benmeadowcroft/SRM-Cmdlets
# It is assumed that the connection to VC and SRM Server have already been made

Function Get-SrmConfigReportSite {
    Param(
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    Get-SrmServer $SrmServer |
        Format-Table -Wrap -AutoSize @{Label="SRM Site Name"; Expression={$_.ExtensionData.GetSiteName()} },
            @{Label="SRM Host"; Expression={$_.Name} },
            @{Label="SRM Port"; Expression={$_.Port} },
            @{Label="Version"; Expression={$_.Version} },
            @{Label="Build"; Expression={$_.Build} },
            @{Label="SRM Peer Site Name"; Expression={$_.ExtensionData.GetPairedSite().Name} }
}

Function Get-SrmConfigReportPlan {
    Param(
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    Get-SrmRecoveryPlan -SrmServer $SrmServer | %{
        $rp = $_
        $rpinfo = $rp.GetInfo()
        $peerState = $rp.GetPeer().State
        $pgs = Get-SrmProtectionGroup -RecoveryPlan $rp
        $pgnames = $pgs | %{ $_.GetInfo().Name }

        $output = "" | select plan, state, peerState, groups
        $output.plan = $rpinfo.Name
        $output.state = $rpinfo.State
        $output.peerState = $peerState
        if ($pgnames) {
            $output.groups = [string]::Join(",`r`n", $pgnames)
        } else {
            $output.groups = "NONE"
        }

        $output
    } | Format-Table -Wrap -AutoSize @{Label="Recovery Plan Name"; Expression={$_.plan} },
                                   @{Label="Recovery State"; Expression={$_.state} },
                                   @{Label="Peer Recovery State"; Expression={$_.peerState} },
                                   @{Label="Protection Groups"; Expression={$_.groups}}
}


Function Get-SrmConfigReportProtectionGroup {
    Param(
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    Get-SrmProtectionGroup -SrmServer $SrmServer | %{
        $pg = $_
        $pginfo = $pg.GetInfo()
        $pgstate = $pg.GetProtectionState()
        $peerState = $pg.GetPeer().State
        $rps = Get-SrmRecoveryPlan -ProtectionGroup $pg
        $rpnames = $rps | %{ $_.GetInfo().Name }

        $output = "" | select name, type, state, peerState, plans
        $output.name = $pginfo.Name
        $output.type = $pginfo.Type
        $output.state = $pgstate
        $output.peerState = $peerState
        if ($rpnames) {
            $output.plans = [string]::Join(",`r`n", $rpnames)
        } else {
            $output.plans = "NONE"
        }

        $output
    } | Format-Table -Wrap -AutoSize @{Label="Protection Group Name"; Expression={$_.name} },
                                   @{Label="Type"; Expression={$_.type} },
                                   @{Label="Protection State"; Expression={$_.state} },
                                   @{Label="Peer Protection State"; Expression={$_.peerState} },
                                   @{Label="Recovery Plans"; Expression={$_.plans} }
}


Function Get-SrmConfigReportProtectedDatastore {
    Param(
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    Get-SrmProtectionGroup -SrmServer $SrmServer -Type "san" | %{
        $pg = $_
        $pginfo = $pg.GetInfo()
        $pds = Get-SrmProtectedDatastore -ProtectionGroup $pg
        $pds | %{
            $pd = $_
            $output = "" | select datacenter, group, name, capacity, free
            $output.datacenter = $pd.Datacenter.Name
            $output.group = $pginfo.Name
            $output.name = $pd.Name
            $output.capacity = $pd.CapacityGB
            $output.free = $pd.FreeSpaceGB

            $output

        }
    } | Format-Table -Wrap -AutoSize -GroupBy "datacenter" @{Label="Datastore Name"; Expression={$_.name} },
                                   @{Label="Capacity GB"; Expression={$_.capacity} },
                                   @{Label="Free GB"; Expression={$_.free} },
                                   @{Label="Protection Group"; Expression={$_.group} }
}


Function Get-SrmConfigReportProtectedVm {
    Param(
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    $srmversion = Get-SrmServerVersion -SrmServer $SrmServer
    $srmMajorVersion, $srmMinorVersion = $srmversion -split "\."

    Get-SrmProtectionGroup -SrmServer $SrmServer | %{
        $pg = $_
        $pginfo = $pg.GetInfo()
        $pvms = Get-SrmProtectedVM -ProtectionGroup $pg
        $rps = Get-SrmRecoveryPlan -ProtectionGroup $pg
        $rpnames = $rps | %{ $_.GetInfo().Name }
        $pvms | %{
            $pvm = $_
            if ($srmMajorVersion -ge 6 -or ($srmMajorVersion -eq 5 -and $srmMinorVersion -eq 8)) {
                $rs = $rps | Select -First 1 | %{ $_.GetRecoverySettings($pvm.Vm.MoRef) }
            }
            $output = "" | select group, name, moRef, needsConfiguration, state, plans, priority, finalPowerState, preCallouts, postCallouts
            $output.group = $pginfo.Name
            $output.name = $pvm.Vm.Name
            $output.moRef = $pvm.Vm.MoRef # this is necessary in case we can't retrieve the name when VC is unavailable
            $output.needsConfiguration = $pvm.NeedsConfiguration
            $output.state = $pvm.State
            $output.plans = [string]::Join(",`r`n", $rpnames)
            if ($rs) {
                $output.priority = $rs.RecoveryPriority
                $output.finalPowerState = $rs.FinalPowerState
                $output.preCallouts = $rs.PrePowerOnCallouts.Count
                $output.postCallouts = $rs.PostPowerOnCallouts.Count
            }
            $output

        }
    } | Format-Table -Wrap -AutoSize @{Label="VM Name"; Expression={$_.name} },
                                   @{Label="VM MoRef"; Expression={$_.moRef} },
                                   @{Label="Needs Config"; Expression={$_.needsConfiguration} },
                                   @{Label="VM Protection State"; Expression={$_.state} },
                                   @{Label="Protection Group"; Expression={$_.group} },
                                   @{Label="Recovery Plans"; Expression={$_.plans} },
                                   @{Label="Recovery Priority"; Expression={$_.priority} },
                                   @{Label="Final Power State"; Expression={$_.finalPowerState} },
                                   @{Label="Pre-PowerOn Callouts"; Expression={$_.preCallouts} },
                                   @{Label="Post-PowerOn Callouts"; Expression={$_.postCallouts} }
    
}

Function Get-SrmConfigReport {
    Param(
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    Get-SrmConfigReportSite -SrmServer $SrmServer
    Get-SrmConfigReportPlan -SrmServer $SrmServer
    Get-SrmConfigReportProtectionGroup -SrmServer $SrmServer
    Get-SrmConfigReportProtectedDatastore -SrmServer $SrmServer
    Get-SrmConfigReportProtectedVm -SrmServer $SrmServer
}
