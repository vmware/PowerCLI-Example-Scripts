<#	
    .NOTES
    ===========================================================================
     Script name: New-ClusterHostGroup.ps1
     Created on: 2016-10-25
     Author: Peter D. Jorgensen (@pjorg, pjorg.com)
     Dependencies: None known
     ===Tested Against Environment====
     vSphere Version: 5.5, 6.0
     PowerCLI Version: PowerCLI 6.5R1
     PowerShell Version: 5.0
     OS Version: Windows 10, Windows 7
    ===========================================================================
	.DESCRIPTION
		Creates a DRS Host Group in a vSphere cluster.
    .Example
    $ProdCluster = Get-Cluster *prod*
	$OddHosts = $ProdCluster | Get-VMHost | ?{ $_.Name -match 'esxi-\d*[13579]+.\lab\.local' }
    .\New-ClusterHostGroup.ps1 -Name 'OddProdHosts' -Cluster $ProdCluster -VMHost $OddHosts
#>
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True,Position=1)]
		[String]$Name,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=2)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster]$Cluster,
	[Parameter(Mandatory=$False,Position=3)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost[]]$VMHost
)

$NewGroup = New-Object VMware.Vim.ClusterHostGroup -Property @{
    'Name'=$Name
    'Host'=$VMHost.Id
}

$spec = New-Object VMware.Vim.ClusterConfigSpecEx -Property @{
    'GroupSpec'=(New-Object VMware.Vim.ClusterGroupSpec -Property @{
        'Info'=$NewGroup
    })
}

$ClusterToReconfig = Get-View -VIObject $Cluster -Property Name
$ClusterToReconfig.ReconfigureComputeResource($spec, $true)