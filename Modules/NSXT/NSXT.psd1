<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
@{
	ModuleToProcess = 'NSXT.psm1'
	ModuleVersion = '1.0.0.0'
	GUID = 'c72f4e3d-5d1d-498f-ba86-6fa03e4ae6dd'
	Author = 'William Lam'
	CompanyName = 'primp-industries.com'
	Copyright = '(c) 2017. All rights reserved.'
	Description = 'Powershell Module for NSX-T REST API Functions'
	PowerShellVersion = '5.0'
    FunctionsToExport = 'Get-NSXTBGPNeighbors',
                        'Get-NSXTComputeManager',
                        'Get-NSXTController',
                        'Get-NSXTEdgeCluster',
                        'Get-NSXTFabricNode',
                        'Get-NSXTFabricVM',
                        'Get-NSXTFirewallRule',
                        'Get-NSXTForwardingTable',
                        'Get-NSXTIPPool',
                        'Get-NSXTLogicalRouter',
                        'Get-NSXTLogicalRouterPorts',
                        'Get-NSXTLogicalSwitch',
                        'Get-NSXTManager',
                        'Get-NSXTNetworkRoutes',
                        'Get-NSXTRoutingTable',
                        'Get-NSXTTraceFlow',
                        'Get-NSXTTraceFlowObservations',
                        'Get-NSXTTransportNode',
                        'Get-NSXTTransportZone',
                        'Get-NSXTClusterNode',
                        'Set-NSXTIPPool',
                        'Set-NSXTLogicalRouter',
                        'Set-NSXTLogicalSwitch',
                        'Set-NSXTTraceFlow',
                        'Get-NSXTIPAMIPBlock',
                        'Set-NSXTIPAMIPBlock',
                        'Remove-NSXTIPAMIPBlock'


	PrivateData = @{
		PSData = @{
			Tags = @('NSX-T','REST')
			LicenseUri = 'https://www.tldrlegal.com/l/mit'
			ProjectUri = 'https://github.com/lamw/PowerCLI-Example-Scripts/tree/master/Modules/NSXT'
		}
	}
}