<#	
    .NOTES
    ===========================================================================
     Script name: New-ClusterVmGroup.ps1
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
		Creates a DRS VM Group in a vSphere cluster.
    .Example
    $ProdCluster = Get-Cluster *prod*
	$EvenVMs = $ProdCluster | Get-VM | ?{ $_.Name -match 'MyVM-\d*[02468]+' }
    .\New-ClusterVmGroup.ps1 -Name 'EvenVMs' -Cluster $ProdCluster -VM $EvenVMs
#>
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True,Position=1)]
		[String]$Name,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=2)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster]$Cluster,
	[Parameter(Mandatory=$False,Position=3)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]]$VM
)

$NewGroup = New-Object VMware.Vim.ClusterVmGroup -Property @{
    'Name'=$Name
    'VM'=$VM.Id
}

$spec = New-Object VMware.Vim.ClusterConfigSpecEx -Property @{
    'GroupSpec'=(New-Object VMware.Vim.ClusterGroupSpec -Property @{
        'Info'=$NewGroup
    })
}

$ClusterToReconfig = Get-View -VIObject $Cluster -Property Name
$ClusterToReconfig.ReconfigureComputeResource($spec, $true)