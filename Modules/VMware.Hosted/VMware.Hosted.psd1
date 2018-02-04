@{
	ModuleToProcess = 'VMware.Hosted.psm1'
	ModuleVersion = '1.0.0.0'
	GUID = '11393D09-D6B8-4E79-B9BC-247F1BE66683'
	Author = 'William Lam'
	CompanyName = 'primp-industries.com'
	Copyright = '(c) 2017. All rights reserved.'
	Description = 'Powershell Module for VMware Fusion 10 REST API'
	PowerShellVersion = '5.0'
    FunctionsToExport = 'Get-HostedCommand','Connect-HostedServer','Disconnect-HostedServer','Get-HostedVM','Start-HostedVM','Stop-HostedVM','Suspend-HostedVM','Resume-HostedVM','New-HostedVM','Remove-HostedVM','Get-HostedVMSharedFolder','New-HostedVMSharedFolder','Remove-HostedVMSharedFolder','Get-HostedVMNic','Get-HostedNetworks'
	PrivateData = @{
		PSData = @{
			Tags = @('Fusion','REST','vmrest')
			LicenseUri = 'https://www.tldrlegal.com/l/mit'
			ProjectUri = 'https://github.com/lamw/PowerCLI-Example-Scripts/tree/master/Modules/VMware.Hosted'
		}
	}
}