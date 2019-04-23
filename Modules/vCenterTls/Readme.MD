# vCenterTls Powershell Module

Powershell module to manage vCenter TLS certificates and trust store.  These module use the new REST APIs introduced in vCenter 6.7 Update 2

## Available Cmdlets
``Get-vCenterTrustedRootChain``
``Add-vCenterTrustedRootChain``
``Remove-vCenterTrustedRootChain``
``New-vCenterCertificateSigningRequest``
``Get-vCenterCertificate``
``Set-vCenterCertificate``

## Requirements
vCenter 6.7 Update 2
PowerCLI

## Usage
First create a connection to the CIS Server using ``Connect-CisServer``

All cmdlets take a ``-Server`` argument which is a reference to the CisServer connection.  If ``-Server`` is not specified, the last CIS connection
established will be used (``$global:DefaultCisServers[0]``)

**If the current vCenter Server certificate is not trusted, then you will need to disable certificate validation for the .NET Service Point.**
I've provided a cmdlet to do this in the module for convenience
``Set-NetCertificatePolicy -Policy TrustAll``

Please use get-help for detailed usage of each of the cmdlets

## Notes
When uploading the private key with ``Set-vCenterCertificate`` the key MUST be in PCKS8 format.  This is in contrast to the certicate management UI tool
in the H5 client which will accept both PKCS1 or PKCS8 formatted keys.


