function Get-VmfsDatastoreInfo
{
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $True)]
		[PSObject]$Datastore
	)
	
	Process
	{
		if ($Datastore -is [String])
		{
			$Datastore = Get-Datastore -Name $Datastore -ErrorAction SilentlyContinue
		}
		if ($Datastore -isnot [VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.Datastore])
		{
			Write-Error 'Invalid value for Datastore.'
			return
		}
		if ($Datastore.Type -ne 'VMFS')
		{
			Write-Error "$($Datastore.Name) is not a VMFS datastore"
			return
		}
		
		# Get the Datastore System Manager from an ESXi that has the Datastore
		$esx = Get-View -Id ($Datastore.ExtensionData.Host | Get-Random | Select -ExpandProperty Key)
		$hsSys = Get-View -Id $esx.ConfigManager.StorageSystem
		
		foreach ($extent in $Datastore.ExtensionData.Info.Vmfs.Extent)
		{
			$lun = $esx.Config.StorageDevice.ScsiLun | where{ $_.CanonicalName -eq $extent.DiskName }
			
			$hdPartInfo = $hsSys.RetrieveDiskPartitionInfo($lun.DeviceName)
			$hdPartInfo[0].Layout.Partition | %{
				New-Object PSObject -Property ([ordered]@{
						Datastore = $Datastore.Name
						CanonicalName = $lun.CanonicalName
						Model = "$($lun.Vendor.TrimEnd(' ')).$($lun.Model.TrimEnd(' ')).$($lun.Revision.TrimEnd(' '))"
						DiskSizeGB = $hdPartInfo[0].Layout.Total.BlockSize * $hdPartInfo[0].Layout.Total.Block / 1GB
						DiskBlocks = $hdPartInfo[0].Layout.Total.Block
						DiskBlockMB = $hdPartInfo[0].Layout.Total.BlockSize/1MB
						PartitionFormat = $hdPartInfo[0].Spec.PartitionFormat
						Partition = if ($_.Partition -eq '') { '<free>' }else{ $_.Partition }
						Used = $extent.Partition -eq $_.Partition
						Type = $_.Type
						PartitionSizeGB = [math]::Round(($_.End.Block - $_.Start.Block + 1) * $_.Start.BlockSize / 1GB, 1)
						PartitionBlocks = $_.End.Block - $_.Start.Block + 1
						PartitionBlockMB = $_.Start.BlockSize/1MB
						Start = $_.Start.Block
						End = $_.End.Block
					})
			}
		}
	}
}

function Get-VmfsDatastoreIncrease
{
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $True)]
		[PSObject]$Datastore
	)
	
	Process
	{
		if ($Datastore -is [String])
		{
			$Datastore = Get-Datastore -Name $Datastore -ErrorAction SilentlyContinue
		}
		if ($Datastore -isnot [VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.Datastore])
		{
			Write-Error 'Invalid value for Datastore.'
			return
		}
		
		if ($Datastore.Type -ne 'VMFS')
		{
			Write-Error "$($Datastore.Name) is not a VMFS datastore"
			return
		}
		
		# Get the Datastore System Manager from an ESXi that has the Datastore
		$esx = Get-View -Id ($Datastore.ExtensionData.Host | Get-Random | Select -ExpandProperty Key)
		$hsSys = Get-View -Id $esx.ConfigManager.StorageSystem
		$hdSys = Get-View -Id $esx.ConfigManager.DatastoreSystem
		
		$extents = $Datastore.ExtensionData.Info.Vmfs.Extent | Select -ExpandProperty DiskName
		
		$hScsiDisk = $hdSys.QueryAvailableDisksForVmfs($Datastore.ExtensionData.MoRef)
		foreach ($disk in $hScsiDisk)
		{
			$partInfo = $hsSys.RetrieveDiskPartitionInfo($disk.DeviceName)
			$partUsed = ($partInfo[0].Layout.Partition | where{ $_.Type -eq 'VMFS' } | %{ ($_.End.Block - $_.Start.Block + 1) * $_.Start.BlockSize } |
				Measure-Object -Sum | select -ExpandProperty Sum)/1GB
			if ($extents -contains $disk.CanonicalName)
			{
				$incType = 'Expand'
				$vmfsExpOpt = $hdSys.QueryVmfsDatastoreExpandOptions($Datastore.ExtensionData.MoRef)
				$PartMax = ($vmfsExpOpt[0].Info.Layout.Partition | where{ $_.Type -eq 'VMFS' } | %{ ($_.End.Block - $_.Start.Block + 1) * $_.Start.BlockSize } |
					Measure-Object -Sum | select -ExpandProperty Sum)/1GB
			}
			else
			{
				$incType = 'Extend'
				$vmfsExtOpt = $hdSys.QueryVmfsDatastoreExtendOptions($Datastore.ExtensionData.MoRef, $disk.DevicePath, $null)
				$partMax = ($vmfsExpOpt[0].Info.Layout.Partition | where{ $_.Type -eq 'VMFS' } | %{ ($_.End.Block - $_.Start.Block + 1) * $_.Start.BlockSize } |
					Measure-Object -Sum | select -ExpandProperty Sum)/1GB
			}
			New-Object PSObject -Property ([ordered]@{
					Datastore = $Datastore.Name
					CanonicalName = $disk.CanonicalName
					Model = "$($disk.Vendor.TrimEnd(' ')).$($disk.Model.TrimEnd(' ')).$($disk.Revision.TrimEnd(' '))"
					DiskSizeGB = $partInfo[0].Layout.Total.BlockSize * $partInfo[0].Layout.Total.Block / 1GB
					DiskBlocks = $partInfo[0].Layout.Total.Block
					DiskBlockMB = $partInfo[0].Layout.Total.BlockSize/1MB
					AvailableGB = [math]::Round($partMax - $partUsed, 2)
					Type = $incType
				})
		}
	}
}

function New-VmfsDatastoreIncrease
{
	[CmdletBinding(SupportsShouldProcess = $True)]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $True)]
		[PSObject]$Datastore,
		[int]$IncreaseSizeGB,
		[Parameter(Position = 1)]
		[string]$CanonicalName,
		[Parameter(Mandatory = $true, ParameterSetName = 'Expand')]
		[switch]$Expand,
		[Parameter(Mandatory = $true, ParameterSetName = 'ExTend')]
		[switch]$Extend
	)
	
	Process
	{
		if ($Datastore -is [String])
		{
			$Datastore = Get-Datastore -Name $Datastore -ErrorAction SilentlyContinue
		}
		if ($Datastore -isnot [VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.Datastore])
		{
			Write-Error 'Invalid value for Datastore.'
			return
		}
		
		if ($Datastore.Type -ne 'VMFS')
		{
			Write-Error "$($Datastore.Name) is not a VMFS datastore"
			return
		}
		
		# Get the Datastore System Manager from an ESXi that has the Datastore
		$esx = Get-View -Id ($Datastore.ExtensionData.Host | Get-Random | Select -ExpandProperty Key)
		$hsSys = Get-View -Id $esx.ConfigManager.StorageSystem
		$hdSys = Get-View -Id $esx.ConfigManager.DatastoreSystem
		
		$extents = $Datastore.ExtensionData.Info.Vmfs.Extent | Select -ExpandProperty DiskName
		
		$hScsiDisk = $hdSys.QueryAvailableDisksForVmfs($Datastore.ExtensionData.MoRef)
		
		# Expand or Extend
		switch ($PSCmdlet.ParameterSetName)
		{
			'Expand' {
				$expOpt = $hdSys.QueryVmfsDatastoreExpandOptions($Datastore.ExtensionData.MoRef)
				if ($CanonicalName)
				{
					$dsOpt = $expOpt | where{ $_.Spec.Extent.DiskName -eq $CanonicalName }
				}
				else
				{
					$dsOpt = $expOpt | Sort-Object -Property { $_.Spec.Extent.Diskname } | select -first 1
				}
				if ($IncreaseSizeGB -ne 0)
				{
					$lun = $hScsiDisk | where{ $_.CanonicalName -eq $dsOpt.Spec.Extent.DiskName }
					$partInfo = $hsSys.RetrieveDiskPartitionInfo($lun.DeviceName)
					$partMax = ($expOpt[0].Info.Layout.Partition | where{ $_.Type -eq 'VMFS' } | %{ ($_.End.Block - $_.Start.Block + 1) * $_.Start.BlockSize } |
						Measure-Object -Sum | select -ExpandProperty Sum)/1GB
					$partUsed = ($partInfo[0].Layout.Partition | where{ $_.Type -eq 'VMFS' } | %{ ($_.End.Block - $_.Start.Block + 1) * $_.Start.BlockSize } |
						Measure-Object -Sum | select -ExpandProperty Sum)/1GB
					if (($partMax - $partUsed) -ge $IncreaseSizeGB)
					{
						$spec = $dsOpt.Spec
						$spec.Partition.Partition[0].EndSector -= ([math]::Floor(($partMax - $partUsed - $IncreaseSizeGB) * 1GB/512))
					}
					else
					{
						Write-Error "Requested expand size $($IncreaseSizeGB)GB not available on $($lun.CanonicalName)"
						return
					}
				}
				else
				{
					$spec = $dsOpt.Spec
				}
				$hdSys.ExpandVmfsDatastore($Datastore.ExtensionData.MoRef, $spec)
			}
			'Extend' {
				if ($CanonicalName)
				{
					$lun = $hScsiDisk | where{ $extents -notcontains $_.CanonicalName -and $_.CanonicalName -eq $CanonicalName }
				}
				else
				{
					$lun = $hScsiDisk | where{ $extents -notcontains $_.CanonicalName } | Sort-Object -Property CanonicalName | select -First 1
				}
				if (!$lun)
				{
					Write-Error "No valid LUN provided or found for extent"
					return
				}
				$vmfsExtOpt = $hdSys.QueryVmfsDatastoreExtendOptions($Datastore.ExtensionData.MoRef, $lun.DevicePath, $null)
				if ($IncreaseSizeGB -ne 0)
				{
					$partInfo = $hsSys.RetrieveDiskPartitionInfo($lun.DeviceName)
					$partMax = ($vmfsExpOpt[0].Info.Layout.Partition | where{ $_.Type -eq 'VMFS' } | %{ ($_.End.Block - $_.Start.Block + 1) * $_.Start.BlockSize } |
						Measure-Object -Sum | select -ExpandProperty Sum)/1GB
					if ($partMax -ge $IncreaseSizeGB)
					{
						$spec = $vmfsExtOpt[0].Spec
						$spec.Partition.Partition[0].EndSector = $spec.Partition.Partition[0].StartSector + [math]::Floor($IncreaseSizeGB * 1GB / 512)
					}
					else
					{
						Write-Error "No valid LUN for extent with $($IncreaseSizeGB)GB space found"
						return
					}
				}
				else
				{
					$spec = $vmfsExtOpt.Spec
				}
				
				$hdSys.ExtendVmfsDatastore($Datastore.ExtensionData.MoRef, $spec)
			}
		}
	}
}

Export-ModuleMember -Function Get-VmfsDatastoreInfo,Get-VmfsDatastoreIncrease,New-VmfsDatastoreIncrease
