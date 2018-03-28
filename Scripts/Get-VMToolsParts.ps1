$vms = Get-VM | where {$_.PowerState -eq "PoweredOn" -and $_.GuestId -match "Windows"}
 
ForEach ($vm in $vms){
	Write-Host $vm
	$namespace = "root\CIMV2"
	$componentPattern = "hcmon|vmci|vmdebug|vmhgfs|VMMEMCTL|vmmouse|vmrawdsk|vmxnet|vmx_svga"
	(Get-WmiObject -class Win32_SystemDriver -computername $vm -namespace $namespace |
		where-object { $_.Name -match $componentPattern } |
		Format-Table -Auto Name,State,StartMode,DisplayName
	)
}
