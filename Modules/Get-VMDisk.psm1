function Get-VMDisk {
<#	
    .NOTES
    ===========================================================================
    Created by: Markus Kraus
    Twitter: @VMarkus_K
    Private Blog: mycloudrevolution.com
    ===========================================================================
    Changelog:  
    2016.09 ver 1.0 Base Release 
    2016.11 ver 1.1 VM pipe
    ===========================================================================
    External Code Sources:  
    http://www.lucd.info/2011/04/22/get-the-maximum-iops/
    ===========================================================================
    Tested Against Environment:
    vSphere Version: 5.5 U2, 6.0
    PowerCLI Version: PowerCLI 6.3 R1, PowerCLI 6.5 R1
    PowerShell Version: 4.0, 5.0
    OS Version: Windows 8.1, Server 2012 R2
    ===========================================================================
    Keywords vSphere, ESXi, VM, vDisk
    ===========================================================================

    .DESCRIPTION
    This Function reports VM vDisks and Datastores:

    Name    PowerState Datastore     VMDK                       StorageFormat CapacityGB
    ----    ---------- ---------     ----                       ------------- ----------
    TST0003 PoweredOff DS02         TST0003/TST0003.vmdk           Thick         16
    TST0004 PoweredOff DS02         TST0004/TST0004.vmdk           Thick         16
    TST0004 PoweredOff DS02         TST0004/TST0004_1.vmdk         Thick          1
    TST0001  PoweredOn DS02         TST0001/TST0001.vmdk           Thick         16
    TST0039 PoweredOff DS02         TST0039/TST0039.vmdk           Thick         60
    TST0002  PoweredOn DS02         TST0002/TST0002.vmdk           Thick         16     

    .Example
    Get-VM -Name TST* | Get-VMDisk

    .Example
    Get-Folder -Name TST | Get-VM | Get-VMDisk | ft -AutoSize

#Requires PS -Version 4.0
#Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="6.3.0.0"}
#>

[CmdletBinding()]
    param( 
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage = "VMs to process")]
        [ValidateNotNullorEmpty()]
        	[VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]] $myVMs
    )
Process {
        $View = @()
        foreach ($myVM in $myVMs){
            $VMDKs = $myVM | get-HardDisk
            foreach ($VMDK in $VMDKs) {
                if ($VMDK -ne $null){
                    [int]$CapacityGB = $VMDK.CapacityKB/1024/1024
                    $Report = [PSCustomObject] @{
                            Name = $myVM.name 
                            PowerState = $myVM.PowerState
                            Datastore = $VMDK.FileName.Split(']')[0].TrimStart('[')
                            VMDK = $VMDK.FileName.Split(']')[1].TrimStart('[')
                            StorageFormat = $VMDK.StorageFormat
                            CapacityGB = $CapacityGB
                        }
                        $View += $Report
                    }   
                }
            }
    $View | Sort-Object VMname, PowerState, Datastore, VMDK, StorageFormat, CapacityGB
    }
}

