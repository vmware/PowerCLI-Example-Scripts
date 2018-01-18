<#  
.SYNOPSIS  
    Finds the local ESXi network Port-ID where a VM is assigned 
.DESCRIPTION 
    Reports back a VM's Port-ID according to the local ESXi host. This correlates to the Port-ID which is displayed via ESXTop
.NOTES  
    Author:  Kyle Ruddy, @kmruddy, thatcouldbeaproblem.com
.PARAMETER vm
	The name of the desired VM 
.EXAMPLE
	PS> .\Get-VMNetworkPortId.ps1 -vm vmname 
.EXAMPLE
	PS> Get-VM -Name vmname | .\Get-VMNetworkPortId.ps1 
#>
[CmdletBinding(SupportsShouldProcess=$True)] 
	param(
		[Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
        [Alias('Name')]
		[String[]]$vm
  	)

    Begin {
		#Create an array to store output prior to return
		$output = @()
	
	}

	Process {
		#Loop through each of the input values
		foreach ($v in $vm) {
			#Validate the input is a valid VM
			$vmobj = Get-VM -Name $v -erroraction silentlycontinue
			if (!$vmobj) {Write-Verbose "No VM found by the name $v."}
			else {
				#Create a temporary object to store individual ouput
				$tempout = "" | select VM,PortId
				#Start an ESXCLI session with the host where the VM resides
				$esxcli = Get-EsxCli -VMHost $vmobj.VMHost -v2
				#ESXCLI call to obtain information about the VM, specifically its WorldID
				$vmNetInfo = $esxcli.network.vm.list.Invoke() | ?{$_.Name -eq $vmobj.Name}
				#Create spec to poll the host for the network information of the VM
				$portArgs = $esxcli.network.vm.port.list.CreateArgs()
				$portArgs.worldid = $vmNetInfo.WorldID
				#Output the values to the temporary object
				$tempout.VM = $vmobj.Name 
				$tempout.PortId = $esxcli.network.vm.port.list.Invoke($portArgs).PortId
				$output += $tempout
			}
		}
	}

    End {

        return $output

    }
