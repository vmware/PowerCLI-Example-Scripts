function Get-BiosBootStatus {
    <#
        .NOTES
        ===========================================================================
        Created by: Brian Graf
        Organization: VMware
        Official Blog: blogs.vmware.com/PowerCLI
        Personal Blog: www.vtagion.com
        Twitter: @vBrianGraf
        ===========================================================================

        .DESCRIPTION
        This will return the boot status of Virtual Machines, whether they
        are booting to the Guest OS or being forced to boot into BIOS.

        .Example
        # Returns all VMs and where they are booting
        Get-BiosBootStatus -VMs (Get-VM)

        .Example
        # Only returns VMs that are booting to BIOS
        Get-BiosBootStatus (Get-VM) -IsSetup
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   Position = 0)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]
        $VM,

        [switch]$IsSetup
    )
    Process {
        if($IsSetup)
        {
            $Execute = $VM |
            Where-Object -FilterScript {$_.ExtensionData.Config.BootOptions.EnterBiosSetup -eq 'true'} |
            Select-Object -Property Name, @{
                Name       = 'EnterBiosSetup'
                Expression = {$_.ExtensionData.config.BootOptions.EnterBiosSetup}
            }
        }
        else
        {
            $Execute = $VM | Select-Object -Property Name, @{
                Name       = 'EnterBiosSetup'
                Expression = {$_.ExtensionData.config.BootOptions.EnterBiosSetup}
            }
        }
    }
    End {$Execute}
}
