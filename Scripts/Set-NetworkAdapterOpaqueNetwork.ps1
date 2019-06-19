function Set-NetworkAdapterOpaqueNetwork {
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
    [VMware.VimAutomation.Types.NetworkAdapter]
    $NetworkAdapter,

    [Parameter(Mandatory = $true, Position = 2)]
    [string]
    $OpaqueNetworkName,

    [Parameter()]
    [switch]
    $Connected,

    [Parameter()]
    [switch]
    $StartConnected
)
process {
    $opaqueNetwork = Get-View -ViewType OpaqueNetwork | ? {$_.Name -eq $OpaqueNetworkName}
    if (-not $opaqueNetwork) {
        throw "'$OpaqueNetworkName' network not found."
    }

    $opaqueNetworkBacking = New-Object VMware.Vim.VirtualEthernetCardOpaqueNetworkBackingInfo
    $opaqueNetworkBacking.OpaqueNetworkId = $opaqueNetwork.Summary.OpaqueNetworkId
    $opaqueNetworkBacking.OpaqueNetworkType = $opaqueNetwork.Summary.OpaqueNetworkType

    $device = $NetworkAdapter.ExtensionData
    $device.Backing = $opaqueNetworkBacking

    if ($StartConnected) {
        $device.Connectable.StartConnected = $true
    }

    if ($Connected) {
        $device.Connectable.Connected = $true
    }
    
    $spec = New-Object VMware.Vim.VirtualDeviceConfigSpec
    $spec.Operation = [VMware.Vim.VirtualDeviceConfigSpecOperation]::edit
    $spec.Device = $device
    $configSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $configSpec.DeviceChange = @($spec)
    $NetworkAdapter.Parent.ExtensionData.ReconfigVM($configSpec)

    # Output
    Get-NetworkAdapter -Id $NetworkAdapter.Id
    }
}
