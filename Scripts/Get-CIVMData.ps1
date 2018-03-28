Function Get-CIVMData
{
<#
	.SYNOPSIS
	Gathers information about a target CIVM

	.DESCRIPTION
	This function gathers CIVM Name, Parent vApp (obj), Parent vApp Name, All network adapters
    (including IP, NIC index, and network), and vCenter VMX path details returning the resulting
    ordered list.

	.PARAMETER CIVM
    The target vCloud VM from which information will be gathered
	
	.NOTES
	Author: Brian Marsh
	Version: 1.0
#>

    [CmdletBinding()]
    Param (
            [Parameter(
                Position=0, 
                Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)
            ]
            [VMware.VimAutomation.Cloud.Types.V1.CIVM] $CIVM
          )
    BEGIN
    {

    }

    PROCESS
    {
        $NewObj = [Ordered]@{}
        $NewObj.GetCIVMData = @{}
        $NewObj.GetCIVMData.Successful = $true
        
        # Get the vCenter VM from the vCloud VM object
        $vm = $civm | Get-VM -Debug:$False -Verbose:$False

        Write-Verbose "Storing CIVM Name: $($CIVM.Name)/ Status: $($CIVM.Status)"
        $NewObj.Name   = $CIVM.Name
        $NewObj.Status = $CIVM.Status

        Write-Verbose "Recording Reservations"
        $NewObj.Reservations        = @{}
        $NewObj.Reservations.CPU    = @{}
        $NewObj.Reservations.Memory = @{}

        $NewObj.Reservations.CPU.Reservation    = $vm.ExtensionData.ResourceConfig.CpuAllocation.Reservation
        $NewObj.Reservations.CPU.Limit          = $vm.ExtensionData.ResourceConfig.CpuAllocation.Limit
        $NewObj.Reservations.Memory.Reservation = $vm.ExtensionData.ResourceConfig.MemoryAllocation.Reservation
        $NewObj.Reservations.Memory.Limit       = $vm.ExtensionData.ResourceConfig.MemoryAllocation.Limit

        # Get the UUid from the Id, split out the UUID and pass it along
        # Sample Id: urn:vcloud:vm:d9ca710d-cdf2-44eb-a274-26e1dcfd01bb
        Write-Verbose "Storing CIVM UUID: $(($CIVM.Id).Split(':')[3])"
        $NewObj.Uuid          = ($CIVM.Id).Split(':')[3]
        
        Write-Verbose "Gathering Network details"
        $vAppNetworkAdapters  = @()
        $NetworkAdapters      = Get-CINetworkAdapter -VM $civm -Debug:$False -Verbose:$False

        foreach ($networkAdapter in $networkAdapters)
        {
            # Remove any existing VMNIC variables
            Remove-Variable -Name VMNic -ErrorAction SilentlyContinue

            $vAppNicInfo = [Ordered]@{}
            $vAppNicInfo.NIC         = ("NIC" + $networkAdapter.Index)
            $vAppNicInfo.Index       = $networkAdapter.Index
            $vAppNicInfo.Connected   = $networkAdapter.Connected
            $vAppNicInfo.ExternalIP  = $networkAdapter.IpAddress
            $vAppNicInfo.InternalIP  = $networkAdapter.ExternalIpAddress
            $vAppNicInfo.MacAddress  = $networkAdapter.MACAddress

            $vAppNicInfo.vAppNetwork      = [Ordered]@{}
            $vAppNicInfo.vAppNetwork.Name = $networkAdapter.VAppNetwork.Name

            <#
                There is a chance that the vApp Network Name may not match a PortGroup which causes issues upon importing the VM after migration.
                To fix this issue, we'll try to find get the PortGroup in this data gathering stage. If it is not found, we'll move on to attempted
                remediation:
                1) Get the vCenter VM network adapter that corresponds to this vCloud Director VM network adapter (where MAC Addresses match)
                2) If the vCenter VM network adapter's network name doesn't match 'none' (indicating the VM is powered off) and the vCenter Network
                   name does not match the vCloud Director network name, set this target object's vAppNetwork Name to the vCenter PortGroup
                3) If the vCenter VM network adapter's network name is 'none' then this VM is probably powered off and the network information is
                   not defined in vCenter. In this case, we mark the get-data as unsuccessful, set an error message and return.
             #>
            try
            {
                $vm | Get-VMHost -Debug:$false -Verbose:$false | Get-VDSwitch -Debug:$false -Verbose:$false -ErrorAction Stop | `
                      Get-VDPortgroup -name $networkAdapter.vAppNetwork.Name -Debug:$false -Verbose:$false -ErrorAction Stop | Out-Null
            }
            catch
            {
                Write-Debug "Portgroup not found by name $($networkAdapter.vAppNetwork.Name), Debug?"
                Write-Verbose "Portgroup not found by name $($networkAdapter.vAppNetwork.Name), attempting fall back."
                # Get VIVM network adapter where adapter mac matches vappnicinfo MacAddress
                $VMNic = $vm | Get-NetworkAdapter -Debug:$false -Verbose:$false | Where-Object { $_.MacAddress -eq $vAppNicInfo.MacAddress }

                # If VMNic Network Name doesn't match 'none' and doesn't match the vAppNetworkName, set vAppNetwork name to VMNic Network name
                If ( ($VMNic.NetworkName -notlike 'none') -and ($VMNic.NetworkName -ne $vAppNicInfo.vAppNetwork.Name))
                {
                    $vAppNicInfo.vAppNetwork.Name = $VMNic.NetworkName
                }
                else
                {
                    Write-Debug "Tried to recover from missing network port group. Failed. Debug?"
                    $ErrorMessage = "VM [ $($CIVM.Name) ] has vAppNetwork connection that doesn't exist in vCenter [ $($vAppNicInfo.vAppNetwork.Name) ]"
                    $NewObj.GetCIVMData.Successful = $False
                    $NewObj.GetCIVMData.Error = $ErrorMessage
                    Write-Error $ErrorMessage

                    #Return whatever object we have at this point
                    $NewObj

                    Return
                }

            }

            $vAppNetworkAdapters += $vAppNicInfo
        }

        Write-Verbose "Checking for Duplicate name upon Import"
        Try
        {
            $DupeVM = Get-VM -Name $NewObj.NewName -Debug:$false -Verbose:$false -ErrorAction Stop -ErrorVariable DupeVM
            If ($DupeVM)
            {
                $NewObj.GetCIVMData.Successful = $False
                $NewObj.GetCIVMData.Error = "VM with name $($NewObj.NewName) already exists in vCenter"
                Write-Error "VM with name $($NewObj.NewName) already exists in vCenter"

                #Return whatever object we have at this point
                $NewObj

                return
            }
        }
        Catch
        {
            Write-Verbose "No Duplicate Name Found!"
        }

        $NewObj.vAppNetworkAdapters = $vAppNetworkAdapters

        Write-Verbose "Setting VIVIM object, parent vApp details, and CIVM object"
        try
        {
            $NewObj.VIVM               = $vm
            $NewObj.ToolsStatus        = $vm.ExtensionData.Guest.ToolsStatus
            $NewObj.ToolsRunningStatus = $vm.ExtensionData.Guest.ToolsRunningStatus
            $NewObj.HasSnapshots       = ($vm | Get-Snapshot -Debug:$false -Verbose:$false -ErrorAction Stop | Select-Object Name, Description,VMId)
            $NewObj.NeedsConsolidation = $vm.ExtensionData.Runtime.ConsolidationNeeded
            $NewObj.OldMoref           = $vm.Id
            $NewObj.VmPathName         = $vm.ExtensionData.Config.Files.VmPathName
            $NewObj.ParentVApp         = $CIVM.VApp.Name
            $NewObj.StorageReservation = ($vm |Get-DatastoreCluster -Debug:$false -Verbose:$false -ErrorAction Stop | Select-Object -ExpandProperty Name)
            $NewObj.CIVMId             = $CIVM.Id
        }
        catch
        {
            $NewObj.GetCIVMData.Successful = $False
            $NewObj.GetCIVMData.Error = "VM [ $($CIVM.Name) ] something went wrong while gathering details: $_"
            Write-Debug "VM [ $($CIVM.Name) ] something went wrong while gathering details: $_, Debug"
            Write-Error "VM [ $($CIVM.Name) ] something went wrong while gathering details: $_. "

            #Return whatever object we have at this point
            $NewObj

            Return
        }

        # If ToolsStatus is not 'toolsOk' and status is not "PoweredOn", bomb out. We won't be able to power this VM off later.
        If ($NewObj.ToolsRunningStatus -ne 'guestToolsRunning' -and $NewObj.status -eq "PoweredOn")
        {
            $NewObj.GetCIVMData.Successful = $False
            $NewObj.GetCIVMData.Error = "VM [ $($CIVM.Name) ] tools are not running but the VM is powered On. Fix and try again."
            Write-Debug "VM [ $($CIVM.Name) ] tools are not running but the VM is powered On, Debug"
            Write-Error "VM [ $($CIVM.Name) ] tools are not running but the VM is powered On. "

            #Return whatever object we have at this point
            $NewObj

            Return
        }

        If ($NewObj.HasSnapshots)
        {
            $NewObj.GetCIVMData.Successful = $False
            $NewObj.GetCIVMData.Error = "VM [ $($CIVM.Name) ] has snapshots. Remove before trying again."
            Write-Debug "VM [ $($CIVM.Name) ] has snapshots. Remove before trying again, Debug"
            Write-Error "VM [ $($CIVM.Name) ] has snapshots. Remove before trying again."

            #Return whatever object we have at this point
            $NewObj

            Return
        }

        Write-Verbose "Determining the VMX Path for this VM"
      
        # Get this VM's path on disk
        $vmPathName   = $vm.ExtensionData.Config.Files.VmPathName

        # Determine in which Datacenter this VM resides
        $datacenter   = $vm | get-Datacenter -Debug:$False -Verbose:$False | Select-Object -expand name

        # Split out the datastore from the path name
        $datastore    = $vmPathName.Split("]")[0].split("[")[1]

        # Split out the folder from the path name
        $vmFolderPath = $vmPathName.Split("/")[0].split("]")[1].trim()

        # Re-combine into a valid folder path
        $vmxPath      = "vmstore:\$($datacenter)\$($datastore)\$vmFolderPath"
        
        Write-Verbose "VMXPath $vmxPath" 
        $NewObj.vmxPath = $vmxPath

        $NewObj

    }

    END
    {
        Write-Debug "About to exit Get-CIVMData, anything else?"
        Write-Verbose "Exited Get-CIVMData"
    }     
}
