<#	
	.NOTES
	===========================================================================
	 Script name: Stop-VMHostSsh.ps1
	 Created on: 2016-07-01
	 Author: Peter D. Jorgensen (@pjorg, pjorg.com)
	 Dependencies: None known
	 ===Tested Against Environment====
	 vSphere Version: 5.5, 6.0
	 PowerCLI Version: PowerCLI 6.5R1
	 PowerShell Version: 5.0
	 OS Version: Windows 10, Windows 7
	===========================================================================
	.DESCRIPTION
		Stops the TSM-SSH service on VMHosts.
    .Example
	.\Stop-VMHostSsh -VMHost (Get-VMHost -Name 'esxi-001.lab.local')
    .Example
	$EvenHosts = Get-VMHost | ?{ $_.Name -match 'esxi-\d*[02468]+.\lab\.local' }
	.\Stop-VMHost -VMHost $EvenHosts
#>
[CmdletBinding()]
Param(
	[Parameter(ValueFromPipeline=$True,Mandatory=$True,Position=0)]
		[VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl[]]$VMHost
)

Process {
    $svcSys = Get-View $VMHost.ExtensionData.ConfigManager.ServiceSystem
    $svcSys.StopService('TSM-SSH')
}
