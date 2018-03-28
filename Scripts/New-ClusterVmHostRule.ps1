<#	
    .NOTES
    ===========================================================================
     Script name: New-ClusterVmHostRule.ps1
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
        Creates a VM to Host affinity rule in a vSphere cluster.
    .Example
    $ProdCluster = Get-Cluster *prod*
    .\New-ClusterVmHostRule.ps1 -Name 'Even VMs to Odd Hosts' -AffineHostGroupName 'OddHosts' -VMGroupName 'EvenVMs' -Enabled:$true -Cluster $ProdCluster
#>
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True,Position=1)]
		[String]$Name,
	[Parameter(Mandatory=$True,Position=2)]
		[String]$AffineHostGroupName,
	[Parameter(Mandatory=$True,Position=3)]
        [String]$VMGroupName,
	[Parameter(Mandatory=$False,Position=4)]
        [Switch]$Enabled=$True,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=5)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster]$Cluster
)

$NewRule = New-Object VMware.Vim.ClusterVmHostRuleInfo -Property @{
    'AffineHostGroupName'=$AffineHostGroupName
    'VmGroupName'=$VMGroupName
    'Enabled'=$Enabled
    'Name'=$Name
}

$spec = New-Object VMware.Vim.ClusterConfigSpecEx -Property @{
    'RulesSpec'=(New-Object VMware.Vim.ClusterRuleSpec -Property @{
        'Info'=$NewRule
    })
}

$ClusterToReconfig = Get-View -VIObject $Cluster -Property Name
$ClusterToReconfig.ReconfigureComputeResource($spec, $true)