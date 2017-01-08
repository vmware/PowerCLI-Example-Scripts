Function Get-VsanHclDatabase {
<#
    .NOTES
    ===========================================================================
	 Created by:   	Alan Renouf
     Organization: 	VMware
     Blog:          http://virtu-al.net
     Twitter:       @alanrenouf
	===========================================================================
	.SYNOPSIS
		This function will allow you to view and download the VSAN Hardware Compatability List (HCL) Database
	
	.DESCRIPTION
		Use this function to view or download the VSAN HCL
	.EXAMPLE
        View the latest online HCL Database from online source
		PS C:\> Get-VsanHclDatabase | Format-Table
	.EXAMPLE
        Download the latest HCL Database from online source and store locally
		PS C:\> Get-VsanHclDatabase -filepath ~/hcl.json
#>
param ($filepath)
    $uri = "https://partnerweb.vmware.com/service/vsan/all.json"
    If ($filepath) {
        Invoke-WebRequest -Uri $uri -OutFile $filepath
    } Else {
        Invoke-WebRequest -Uri $uri | ConvertFrom-Json | Select-Object -ExpandProperty Data | Select-object -ExpandProperty Controller
    }
}