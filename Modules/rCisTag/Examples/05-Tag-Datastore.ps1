<#
Copyright 2016-2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

# Fetch Cis Server hostname and credentials
.\CisConfig.ps1

Connect-rCisServer -Server $cisServer -User $cisUser -Password $cisPswd

$catName = 'Homelab'

# Clean up
Get-rCisTagCategory -Name $catName | Remove-rCisTagCategory -Confirm:$false

# Tag all datastores with their type
New-rCisTagCategory -Name HomeLab -Description 'Homelab datastores' -Cardinality Single -EntityType 'Datastore' |
New-rCisTag -Name 'VMFS','NFS' -Description 'Datastore type'

Get-Cluster -Name Cluster1 | Get-Datastore | %{
    New-rCisTagAssignment -Entity $_ -Tag "$($_.Type)"
}

Disconnect-rCisServer -Server $cisServer -Confirm:$false
