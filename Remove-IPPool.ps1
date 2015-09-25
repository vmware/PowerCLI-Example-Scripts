Function Remove-IPPool {
	<#
	.Synopsis
	This function will remove IP-Pools from vCenter
	.Description
	This function will remove IP-Pools from vCenter based on the inputs provided
	.Example
	Assuming my datacenter was 'westwing' and my IPPool was 'IPPool1'
	remove-ippool westwing IPPool1
	.Notes
	Author: Brian Graf
	Role: Technical Marketing Engineer, VMware
	Last Edited: 05/01/2014

	#>
	[cmdletbinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, valuefrompipelinebypropertyname = $true)]
		[String]$Datacenter,
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[String]$PoolName
	)
	
	Process {
	$dc = (Get-datacenter $Datacenter)
	$dcenter = New-Object VMware.Vim.ManagedObjectReference
	$dcenter.type = $dc.ExtensionData.moref.type
	$dcenter.Value = $dc.ExtensionData.moref.value

	$IPPoolManager = Get-View -Id 'IpPoolManager'
	$SelectedPool = ($IPPoolManager.QueryIpPools($dc.ID) | Where-Object { $_.Name -like $PoolName })

	$IPPool = Get-View -Id 'IpPoolManager-IpPoolManager'
	$IPPool.DestroyIpPool($dcenter, $SelectedPool.id, $true)

	}
}

