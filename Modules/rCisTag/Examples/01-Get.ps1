<#
Copyright 2016-2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

# Fetch Cis Server hostname and credentials
.\CisConfig.ps1


Connect-rCisServer -Server $cisServer -User $cisUser -Password $cisPswd

# Get Tag information
Get-rCisTag

# Get Tag Category information
Get-rCisTagCategory

# Get Tag Assignment information
Get-rCisTagAssignment

Disconnect-rCisServer -Server $cisServer -Confirm:$false
