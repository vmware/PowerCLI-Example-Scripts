# SRM Helper Methods - https://github.com/benmeadowcroft/SRM-Cmdlets

<#
.SYNOPSIS
Trigger Discover Devices for Site Recovery Manager

.OUTPUTS
Returns discover devices task
#>
Function Start-DiscoverDevice {
    [cmdletbinding(SupportsShouldProcess=$True, ConfirmImpact="Medium")]
    [OutputType([VMware.VimAutomation.Srm.Views.DiscoverDevicesTask])]
    Param(
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    $api = Get-ServerApiEndpoint -SrmServer $SrmServer
    $name = $SrmServer.Name
    [VMware.VimAutomation.Srm.Views.DiscoverDevicesTask] $task = $null
    if ($pscmdlet.ShouldProcess($name, "Rescan Storage Devices")) {
        $task = $api.Storage.DiscoverDevices()
    }
    return $task
}
