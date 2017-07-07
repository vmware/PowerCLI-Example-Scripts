<#
.SYNOPSIS Datastore Functions
.DESCRIPTION A collection of functions to manipulate datastore Mount + Attach status
.EXAMPLE Get-Datastore | Get-DatastoreMountInfo | Sort Datastore, VMHost | FT -AutoSize
.EXAMPLE Get-Datastore IX2ISCSI01 | Unmount-Datastore
.EXAMPLE Get-Datastore IX2ISCSI01 | Get-DatastoreMountInfo | Sort Datastore, VMHost | FT -AutoSize
.EXAMPLE Get-Datastore IX2iSCSI01 | Mount-Datastore
.EXAMPLE Get-Datastore IX2iSCSI01 | Get-DatastoreMountInfo | Sort Datastore, VMHost | FT -AutoSize
.EXAMPLE Get-Datastore IX2iSCSI01 | Detach-Datastore
.EXAMPLE Get-Datastore IX2iSCSI01 | Get-DatastoreMountInfo | Sort Datastore, VMHost | FT -AutoSize
.EXAMPLE Get-Datastore IX2iSCSI01 | Attach-datastore
.EXAMPLE Get-Datastore IX2iSCSI01 | Get-DatastoreMountInfo | Sort Datastore, VMHost | FT -AutoSize
.NOTES Written by Alan Renouf, originally published at https://blogs.vmware.com/vsphere/2012/01/automating-datastore-storage-device-detachment-in-vsphere-5.html
.NOTES May 2017: Modified by Jason Coleman (virtuallyjason.blogspot.com), to improve performance when dealing with a large number of hosts and datastores
#>
Function Get-HostViews {
	[CmdletBinding()]
	Param (
		$Datastore
	)
	Begin{
		$allDatastores = @()
	}
	Process {
		$allDatastores += $Datastore
	}
	End {
		#Build the array of Datastore Objects
		if (-not $Datastore) {
			$allDatastores = Get-Datastore
		}
		$allDatastores = $allDatastores | ? {$_.pstypenames -contains "VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.DatastoreImpl"}
		if (-not $allDatastores){
			Throw "No Datastores found.`nIs ""$Datastore"" a Datastore Object?"
		}
		$allHosts = @()
		$DShostsKeys = $allDatastores.extensiondata.host.key.value | sort | get-unique -asstring
		$DShosts = foreach ($thisKey in $DShostsKeys) {($allDatastores.extensiondata.host | ? {$_.key.value -eq $thisKey})[0]}
		$i = 1
		foreach ($DSHost in $DSHosts){
			write-progress -activity "Collecting ESXi Host Views" -status "Querying $($dshost.key)..." -percentComplete ($i++/$DSHosts.count*100)
			$hostObj = "" | select keyValue,hostView,storageSys
			$hostObj.hostView = get-view $DSHost.key
			$hostObj.keyValue = $DSHost.key.value
			$hostObj.storageSys = Get-View $hostObj.hostView.ConfigManager.StorageSystem
			$allHosts += $hostObj
		}
		write-progress -activity "Collecting ESXi Host Views" -completed
		$allHosts
	}           
}

Function Get-DatastoreMountInfo {
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline=$true)]
		$Datastore
	)
	#Roll back up an unrolled array from a pipeline
	Begin{
		$allDatastores = @()
	}
	Process {
		$allDatastores += $Datastore
	}
	End {
		$AllInfo = @()
		#Build the array of Datastore Objects
		if (-not $Datastore) {
			$allDatastores = Get-Datastore
		}
		$allDatastores = $allDatastores | ? {$_.pstypenames -contains "VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.DatastoreImpl"}
		if (-not $allDatastores){
			Throw "No Datastores found.`nIs ""$Datastore"" a Datastore Object?"
		}
		$allDatastoreNAAs = foreach ($ds in $allDatastores) {$ds.ExtensionData.Info.vmfs.extent[0].diskname}
		
		#Build the array of custom Host Objects
		$allHosts = Get-HostViews -datastore $allDatastores
		$output = @()
		$i = 1
		foreach ($dsHost in $allHosts){
			write-progress -activity "Checking Datastore access" -status "Checking $($dshost.hostview.name)..." -percentComplete ($i++ / $allHosts.count * 100)
			#Get all devices on the host that match the list of $allDatastoreNAAs
			$devices = $dsHost.storagesys.StorageDeviceInfo.ScsiLun
			foreach ($device in $devices){
				if ($allDatastoreNAAs -contains $device.canonicalName){
					#Record information about this device/host combo
					$thisDatastore = $alldatastores | ? {$_.ExtensionData.Info.vmfs.extent[0].diskname -eq $device.canonicalName}
					$hostviewDSAttachState = ""
					if ($device.operationalState[0] -eq "ok") {
						$hostviewDSAttachState = "Attached"						    
					} elseif ($device.operationalState[0] -eq "off") {
						$hostviewDSAttachState = "Detached"						   
					} else {
						$hostviewDSAttachState = $device.operationalstate[0]
					}
					$Info = "" | Select Datastore, VMHost, Lun, Mounted, State
					$Info.VMHost = $dsHost.hostview.name
					$Info.Datastore = $thisDatastore.name
					$Info.Lun = $device.canonicalName
					$Info.mounted = ($thisDatastore.extensiondata.host | ? {$_.key.value -eq $dshost.keyvalue}).mountinfo.mounted
					$Info.state = $hostviewDSAttachState
					$output += $info
				}
			}
		}
		write-progress -activity "Checking Datastore access" -completed
		$output
	}
}

Function Detach-Datastore {
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline=$true)]
		$Datastore
	)
	Begin{
		$allDatastores = @()
	}
	Process {
		$allDatastores += $Datastore
	}
	End {
		$allDatastores = $allDatastores | ? {$_.pstypenames -contains "VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.DatastoreImpl"}
		if (-not $allDatastores){
			Throw "No Datastores found.`nIs ""$Datastore"" a Datastore Object?"
		}
		$allDatastoreNAAs = foreach ($ds in $allDatastores) {$ds.ExtensionData.Info.vmfs.extent[0].diskname}
		$allHosts = Get-HostViews -datastore $allDatastores
		$j = 1
		foreach ($dsHost in $allHosts){
			#Get all devices on the host that match the list of $allDatastoreNAAs
			write-progress -id 1 -activity "Detaching Datastores" -status "Removing device(s) from $($dsHost.hostview.name)" -percentComplete ($j++ / $allHosts.count * 100)
			$devices = $dsHost.storagesys.StorageDeviceInfo.ScsiLun | ? {$allDatastoreNAAs -contains $_.canonicalName}
			$i = 1
			foreach ($device in $devices){
				write-progress -parentid 1 -activity "Detaching Datastores" -status "Removing device: $(($allDatastores | ? {$_.ExtensionData.Info.vmfs.extent[0].diskname -eq $device.canonicalName}).name)" -percentComplete ($i++ / $allDatastoreNAAs.count * 100)
				$LunUUID = $Device.Uuid
				$dsHost.storageSys.DetachScsiLun($LunUUID);
			}
		}
		write-progress -activity "Detaching Datastores" -completed
	}
}

Function Attach-Datastore {
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline=$true)]
		$Datastore
	)
	Begin{
		$allDatastores = @()
	}
	Process {
		$allDatastores += $Datastore
	}
	End {
		$allDatastores = $allDatastores | ? {$_.pstypenames -contains "VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.DatastoreImpl"}
		if (-not $allDatastores){
			Throw "No Datastores found.`nIs ""$Datastore"" a Datastore Object?"
		}
		$allDatastoreNAAs = foreach ($ds in $allDatastores) {$ds.ExtensionData.Info.vmfs.extent[0].diskname}
		$allHosts = Get-HostViews -datastore $allDatastores
		$j = 1
		foreach ($dsHost in $allHosts){
			#Get all devices on the host that match the list of $allDatastoreNAAs
			write-progress -id 1 -activity "Attaching Datastores" -status "Attaching devices to $($dsHost.hostview.name)" -percentComplete ($j++ / $allHosts.count * 100)
			$devices = $dsHost.storagesys.StorageDeviceInfo.ScsiLun
			$i = 1
			foreach ($device in $devices){
				write-progress -parentid 1 -activity "Attaching Datastores" -status "Attaching device: $($Device.Uuid)" -percentComplete ($i++ / $devices.count * 100)
				if ($allDatastoreNAAs -contains $device.canonicalName){
					$LunUUID = $Device.Uuid
					$dsHost.storageSys.AttachScsiLun($LunUUID);
				}
			}
		}
		write-progress -activity "Attaching Datastores" -completed
	}
}

Function Unmount-Datastore {
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline=$true)]
		$Datastore
	)
	Begin{
		$allDatastores = @()
	}
	Process {
		$allDatastores += $Datastore
	}
	End {
		$allDatastores = $allDatastores | ? {$_.pstypenames -contains "VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.DatastoreImpl"}
		if (-not $allDatastores){
			Throw "No Datastores found.`nIs ""$Datastore"" a Datastore Object?"
		}
		$allHosts = Get-HostViews -datastore $allDatastores
		$j = 1
		foreach ($dsHost in $allHosts){
			write-progress -id 1 -activity "Unmounting Datastores" -status "Unmounting devices from $($dsHost.hostview.name)" -percentComplete ($j++ / $allHosts.count * 100)
			$i = 1
			foreach ($ds in $allDatastores){
				write-progress -parentid 1 -activity "Unmounting Datastores" -status "Unmounting device: $($ds.name)" -percentComplete ($i++ / $allDatastores.count * 100)
				$dsHost.storageSys.UnmountVmfsVolume($DS.ExtensionData.Info.vmfs.uuid);
			}
		}
		write-progress -activity "Unmounting Datastores" -completed
	}
}

Function Mount-Datastore {
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline=$true)]
		$Datastore
	)
	Begin{
		$allDatastores = @()
	}
	Process {
		$allDatastores += $Datastore
	}
	End {
		$allDatastores = $allDatastores | ? {$_.pstypenames -contains "VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.DatastoreImpl"}
		if (-not $allDatastores){
			Throw "No Datastores found.`nIs ""$Datastore"" a Datastore Object?"
		}
		$allHosts = Get-HostViews -datastore $allDatastores
		$j = 0
		foreach ($dsHost in $allHosts){
			write-progress -activity "Mounting Datastores" -status "Mounting devices to $($dsHost.hostview.name)" -percentComplete ($j++ / $allHosts.count * 100)
			$i = 1
			foreach ($ds in $allDatastores){
				write-progress -activity "Mounting Datastores" -status "Mounting device: $($DS.ExtensionData.Info.vmfs.uuid)" -percentComplete ($i++ / $allDatastores.count * 100)
				$dsHost.storageSys.MountVmfsVolume($DS.ExtensionData.Info.vmfs.uuid);
			}
		}
		write-progress -activity "Mounting Datastores" -completed
	}
}
