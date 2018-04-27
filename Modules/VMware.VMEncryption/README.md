Prerequisites/Steps to use this module:

1. This module only works for vSphere products that support VM Encryption. E.g. vSphere 6.5 and later.
2. All the functions in this module only work for KMIP Servers.
3. Install the latest version of Powershell and PowerCLI.
4. Import this module by running: Import-Module -Name "location of this module"
5. Get-Command -Module "This module Name" to list all available functions.

Note:
Deprecating the below functions related to KMServer and KMSCluster from VMware.VMEncryption and using instead the ones from VMware.VimAutomation.Storage,

1, VMware.VMEncryption\Get-DefaultKMSCluster, use instead
VMware.VimAutomation.Storage\Get-KmsCluster|where {$_.UseAsDefaultKeyProvider}|foreach {$_.id}

2, VMware.VMEncryption\Get-KMSCluster, use instead
VMware.VimAutomation.Storage\Get-KmsCluster|select id

3, VMware.VMEncryption\Get-KMSClusterInfo, use instead
VMware.VimAutomation.Storage\Get-KmsCluster|foreach {$_.extensiondata}

4, VMware.VMEncryption\Get-KMServerInfo, use instead
VMware.VimAutomation.Storage\Get-KeyManagementServer|foreach {$_.extensiondata}

5, VMware.VMEncryption\New-KMServer, use instead
VMware.VimAutomation.Storage\Add-KeyManagementServer

6, VMware.VMEncryption\Remove-KMServer, use instead
VMware.VimAutomation.Storage\Remove-KeyManagementServer

7, VMware.VMEncryption\Set-DefaultKMSCluster, use instead
VMware.VimAutomation.Storage\Set-KmsCluster -UseAsDefaultKeyProvider

