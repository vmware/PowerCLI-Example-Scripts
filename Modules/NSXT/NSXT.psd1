@{
	ModuleToProcess = 'NSXT.psm1'
	ModuleVersion = '1.0.0.0'
	GUID = 'c72f4e3d-5d1d-498f-ba86-6fa03e4ae6dd'
	Author = 'William Lam'
	CompanyName = 'primp-industries.com'
	Copyright = '(c) 2017. All rights reserved.'
	Description = 'Powershell Module for NSX-T REST API Functions'
	PowerShellVersion = '5.0'
    FunctionsToExport = 'Get-NSXTComputeManager','Get-NSXTFabricNode','Get-NSXTFirewallRule','Get-NSXTIPPool','Get-NSXTLogicalSwitch','Get-NSXTManager','Get-NSXTTransportZone','Get-NSXTController'
	PrivateData = @{
		PSData = @{
			Tags = @('NSX-T','REST')
			LicenseUri = 'https://www.tldrlegal.com/l/mit'
			ProjectUri = 'https://github.com/lamw/PowerCLI-Example-Scripts/tree/master/Modules/NSXT'
		}
	}
}