<#
Copyright 2018 VMware, Inc.  All rights reserved.
#>

# Class to manage Host resources
Class HostResource {
    [VMware.VimAutomation.Types.VMHost] $vmhost
    [string] $vcname
    [string] $clustername
    [string] $dcname
    [string] $hostname
    [string] $apitype
    [string] $powerstatus
    [string] $productname
    [string] $version
    [string] $fullname
    [string] $connectionstatus
    [string] $checkRelease
    [int] $port
    [Array] $ComponentResource = @()
    [Array] $JsonProperties = @('__type__', 'dcname', 'vcname','clustername','hostname', 'apitype',
        'powerstatus', 'productname', 'version', 'fullname', 'connectionstatus','checkRelease')

    HostResource(
        [VMware.VimAutomation.Types.VMHost] $vmhost) {
        $this.vmhost = $vmhost
        $view =$vmhost|Get-View
        $vCenter_IP = $view.Summary.ManagementServerIp
        if($vCenter_IP){
            $this.vcname =$vCenter_IP
            $this.dcname = (Get-Datacenter -VMHost $vmhost).Name
            $this.clustername = (Get-Cluster -VMHost $vmhost).Name
        }else{
            $this.vcname =$this.vmhost.Name
        }
        $this.hostname = $this.vmhost.Name
        $summary = $this.vmhost.ExtensionData.Summary
        $this.powerstatus = $summary.runtime.powerState
        $this.connectionstatus = $summary.runtime.connectionState
        $this.apitype = $summary.Config.Product.apiType
        $this.fullname = $summary.Config.Product.FullName
        $this.version = $summary.Config.Product.version
        $this.productname = $summary.Config.Product.licenseProductName
        $this.port = 443
    }

    [Array]  query_components() {
        if ($this.ComponentResource.Count -eq 0) {
            # Get server info
            for($count_retry=0;$count_retry -lt 3;$count_retry ++){
                try{
                    $svrResoure = [ServerResource]::new()
                    $svrResoure.set_data($this.vmhost)
                    $this.ComponentResource += $svrResoure
                    break
                }catch{
                    error('query components server for '+$this.vmhost.Name +' error, retry it ' +($count_retry+1) +' times')
                }
            }
            # Get PCI devices
            for($count_retry=0;$count_retry -lt 3;$count_retry ++){
                try{
                    $this.query_pcidevices()
                    break
                }catch{
                    error('query components pcidevice for '+$this.vmhost.Name +' error, retry it ' +($count_retry+1) +' times')
                    if($count_retry -eq 2){
                        error('query components pcidevice for '+$this.vmhost.Name +' faild')
                    }
                }
            }
        }
        return $this.ComponentResource
    }

    [void] query_pcidevices() {
        $EsxCliV2 = Get-EsxCli -V2 -VMHost $this.vmhost
        $AllPciDevice = $EsxCliV2.hardware.pci.list.invoke()
        foreach ($Pci in $AllPciDevice) {
            # Ignore USB controllers, iLO/iDRAC devices
            if ($Pci.DeviceName -like "*USB*" -or $Pci.DeviceName -like "*iLO*" -or $Pci.DeviceName -like "*iDRAC*") {
                continue
            }
            # Get the NICs and storage adapters.
            # We found NIC and storage adapters usually have module ID other than 0 or 1
            $pciDevice = [IoDeviceResource]::new()
            if ($Pci.ModuleID -ne 0 -and $Pci.ModuleID -ne -1) {
                if (!$this.is_pcidevice_exist($Pci)) {
                    $pciDevice.set_data($Pci, $EsxCliV2)
                    $this.ComponentResource += $pciDevice
                }
            }
        }
    }

    [boolean] is_pcidevice_exist($device) {
        foreach ($pci in $this.ComponentResource) {
            if ($pci.psobject.TypeNames[0] -eq "IoDeviceResource") {
                $vid = [String]::Format("{0:x4}", [int]$device.VendorID)
                $did = [String]::Format("{0:x4}", [int]$device.DeviceID)
                $svid = [String]::Format("{0:x4}", [int]$device.SubVendorID)
                $ssid = [String]::Format("{0:x4}", [int]$device.SubDeviceID)
                if ($pci.vid -eq $vid -and $pci.did -eq $did -and
                    $pci.svid -eq $svid -and $pci.ssid -eq $ssid) {
                    return $true
                }
            }
        }
        return $false
    }

    [object] to_jsonobj() {
        $Json = $this | Select-Object -Property $this.JsonProperties
        $ComponentChildren = @()
        $this.ComponentResource | ForEach-Object {$ComponentChildren += $_.to_jsonobj()}
        $Json | Add-Member -Name "ComponentResource" -Value $ComponentChildren -MemberType NoteProperty

        return $Json
    }

    [string]  get_host_status() {
        if ($this.powerstatus -and $this.powerstatus -ne 'unknown') {
            return $this.powerstatus
        }
        if ($this.connectionstatus) {
            return ("Server " + $this.connectionstatus)
        }
        else {
            return "Server status is unknown"
        }
    }

    [string]  get_prompt_name() {
        if ($this.apitype) {
            $start = $this.apitype
        }
        else {
            $start = "Host"
        }
        return $start + " " + $this.hostname
    }
}


# Class to manage server resources
Class ServerResource {
    [string] $type
    [string] $model
    [string] $vendor
    [string] $biosversion
    [string] $cpumodel
    [string] $cpufeatureid
    [string] $uuid
    [string] $status
    [array] $matchResult
    [array] $warnings
    [string] $vcgLink
    [array] $updateRelease

    [VMware.VimAutomation.Types.VMHost] $vmhost
    [Array] $JsonProperties = @('__type__','type', 'model', 'vendor', 'biosversion',
        'cpumodel', 'cpufeatureid', 'uuid','status','matchResult','warnings','vcgLink','updateRelease')


    [void] set_data(
        [VMware.VimAutomation.Types.VMHost] $vmhost) {
        $this.vmhost = $vmhost
        $this.type = "Server"
        $this.model = $this.vmhost.Model
        $this.vendor = $this.vmhost.Manufacturer
        $this.biosversion = $this.vmhost.ExtensionData.Hardware.BiosInfo.BiosVersion
        $this.cpumodel = $this.vmhost.ProcessorType
        $cpuFeature = $this.vmhost.ExtensionData.Hardware.CpuFeature
        if ($cpuFeature -and $cpuFeature.Count -gt 2) {
            $this.cpufeatureid = $this.vmhost.ExtensionData.Hardware.CpuFeature[1].Eax
        }
        $this.uuid = $this.vmhost.ExtensionData.Hardware.systeminfo.uuid
    }

    [object] to_jsonobj() {
        return $this | Select-Object -Property $this.JsonProperties
    }

}

# Class to manage each IO device
Class IoDeviceResource {

    [string] $type
    [string] $model
    [string] $deviceid
    [string] $device
    [string] $comptype
    [string] $vid
    [string] $did
    [string] $svid
    [string] $ssid
    [string] $pciid
    [string] $vendor
    [string] $driver
    [string] $driverversion
    [string] $firmware
    [string] $status
    [array] $matchResult
    [array] $warnings
    [string] $vcgLink
    [array] $updateRelease

    [Array] $JsonProperties = @('__type__','type', 'model', 'deviceid', 'device',
        'comptype', 'vid', 'did', 'svid', 'ssid', 'pciid',
        'vendor', 'driver', 'driverversion', 'firmware','status','matchResult','warnings','vcgLink','updateRelease')

    [void] set_data(
        [object] $pci,
        [object] $EsxCli) {
        $this.type = "IO Device"
        $this.model = $Pci.DeviceName
        $this.deviceid = $pci.Address
        $this.device = $pci.VMKernelName
        $this.vid = [String]::Format("{0:x4}", [int]$Pci.VendorID)
        $this.did = [String]::Format("{0:x4}", [int]$Pci.DeviceID)
        $this.svid = [String]::Format("{0:x4}", [int]$Pci.SubVendorID)
        $this.ssid = [String]::Format("{0:x4}", [int]$Pci.SubDeviceID)
        $this.pciid = $this.vid + ":" + $this.did + ":" + $this.svid + ":" + $this.ssid
        $this.vendor = $pci.VendorName
        $this.driver = $Pci.ModuleName
        $this.driverversion = "N/A"
        $this.firmware = "N/A"


        # Set component type and driverversion, firmware
        if ($this.device -match 'nic') {
            $arg = @{}
            $arg['nicname'] = $this.device
            $nic = $EsxCli.network.nic.get.invoke($arg)
            $this.comptype = "Physical NIC"
            $this.driverversion = $nic.driverinfo.Version
            $this.firmware = $nic.driverinfo.FirmwareVersion
        }
        elseif ($this.device -match 'hba') {
            $arg = @{}
            $arg['module'] = $this.driver
            $module = $EsxCli.system.module.get.invoke($arg)
            $this.comptype = "Storage Adapter"
            $this.driverversion = $module.Version
        }
    }

    [object] to_jsonobj() {
        return $this | Select-Object -Property $this.JsonProperties
    }

    [string]  get_id_detail() {
        return $this.driver + " (PCIId:" + $this.pciid + ")"
    }
}

# Class to manage IO device group
Class IoDeviceResourceGroup {
    [Array] $iodevices = @()
    [Array] $nics = @()
    [Array] $adapters = @()

    [void]  append_nic([IODeviceResource] $nic) {
        $this.iodevices += $nic
        $this.nics += $nic
    }

    [void]  append_storage_adapter([IODeviceResource] $adapter) {
        $this.iodevices += $adapter
        $this.adapters += $adapter
    }

    [boolean]  has_nics() {
        return $this.nics.Count > 0
    }

    [boolean]  has_storage_adapters() {
        return $this.adapters.Count > 0
    }

}


#
# Collect hardware inventory data from all the hosts
#
Function Get-VCGHWInfo {
    Param(
        [Parameter(Mandatory=$true)] $vmHosts
    )
    # Collect the hardware data
    $Data = @()
    foreach($vmHost in $vmHosts) {
        $vm = [HostResource]::new($vmHost)
        try {
            info ("Collecting hardware data from " + $vm.hostname)
            $null = $vm.query_components()
            if($vm.powerstatus -eq 'poweredOn' -and $vm.connectionstatus -eq 'connected'){
                $Data += $vm
                info ("Collecting hardware data from " + $vm.hostname +' success')
            }
        }
        catch {
            error ("Failed to collect hardware data from " + $vm.hostname)
        }
    }

    return $Data
}