@{
	ModuleToProcess = 'VMFSIncrease.psm1'
	ModuleVersion = '1.0.0.0'
	GUID = '9f167385-c5c6-4a65-ac14-949c67519001'
	Author = 'Luc Dekens '
	CompanyName = 'Community'
	Copyright = '(c) 2016. All rights reserved.'
	Description = 'Expand and Extend VMFS DatastoresModule description'
	PowerShellVersion = '3.0'
	FunctionsToExport = 'Get-VmfsDatastoreInfo','Get-VmfsDatastoreIncrease','New-VmfsDatastoreIncrease'
	PrivateData = @{
		PSData = @{
			Tags = @('VMFS','Expand','Extend','vSphere')
			LicenseUri = 'https://www.tldrlegal.com/l/mit'
			ProjectUri = 'https://github.com/lucdekens/VMFSIncrease'
		}
	}
}
