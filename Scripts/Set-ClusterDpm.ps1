<#
.NOTES
  Script name: Set-ClusterDpm.ps1
  Created on: 10/10/2019
  Author: Doug Taliaferro, @virtually_doug
  Description: Configures Distributed Power Management (DPM) on a cluster.
  Dependencies: None known

  ===Tested Against Environment====
  vSphere Version: 6.7
  PowerCLI Version: 11.3.0
  PowerShell Version: 5.1
  OS Version: Windows 7, 10
  Keyword: Cluster, DPM
.SYNOPSIS
	Configures Distributed Power Management (DPM).

.DESCRIPTION
	Enables/disables Distributed Power Management (DPM) for one or more clusters and optionally sets the automation level.

.PARAMETER Clusters
	Specifies the name of the cluster(s) you want to configure.

.PARAMETER DpmEnabled
	Indicates whether Distributed Power Management (DPM) should be enabled/disabled.

.PARAMETER DpmAutomationLevel
  Specifies the Distributed Power Management (DPM) automation level. The valid values are 'automated' and 'manual'.

.EXAMPLE
	Set-ClusterDpm -Cluster 'Cluster01' -DpmEnabled:$true

.EXAMPLE
	Get-Cluster | Set-ClusterDpm -DpmEnabled:$true -DpmAutomationLevel 'automated'
#>
[CmdletBinding()]
param (
  [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
  [Alias('Name')]
  [string[]]$Clusters,

  [Parameter(Mandatory=$true)]
  [bool]$DpmEnabled,

  [Parameter(Mandatory = $false)]
  [ValidateSet('automated','manual')]
  [string]$DpmAutomationLevel
)
Begin {
  # Create a configuration spec
  $spec = New-Object VMware.Vim.ClusterConfigSpecEx
  $spec.dpmConfig = New-Object VMware.Vim.ClusterDpmConfigInfo
  $spec.dpmConfig.enabled = $DpmEnabled
  if ($DpmAutomationLevel) {
      $spec.dpmConfig.defaultDpmBehavior = $DpmAutomationLevel
  }
}
Process {
  ForEach ($cluster in $Clusters) {
    # Configure the cluster
    (Get-Cluster $cluster).ExtensionData.ReconfigureComputeResource_Task($spec, $true)
  }
}
