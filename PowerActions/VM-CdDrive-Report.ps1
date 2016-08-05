<#
.MYNGC_REPORT
KEY\(VM\)
.LABEL
VM CD-Drive Report
.DESCRIPTION
PowerActions Report Script that reports on VMs CD-Drive configuration, making it easy to find VMs holding onto ISOs that you 
need to update, or VMs that can't vMotion because they are tied into a physical resource from the ESXi host that is running it.
VM object is key (as it's the first managed object in the output), enabling you the ability to right-click an entry in the 
report to edit the target VM.  Script is able to report on VMs with multiple CD-Drives as well.  Version 1.0, written by
Aaron Smith (@awsmith99), published 07/29/2016.
#>

param
(
   [Parameter(Mandatory=$true)]
   [VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster]
   $vParam
);

[Array] $vmList = @( Get-VM -Location $vParam | Sort Name );

foreach ( $vmItem in $vmList )
{
    [Array] $vmCdDriveList = @( Get-CDDrive -VM $vmItem );

    foreach ( $vmCdDriveItem in $vmCdDriveList )
    {
        [String] $insertedElement = "";
        [String] $connectionType  = "";

        switch ( $vmCdDriveItem )
        {
            { $_.IsoPath      } { $insertedElement = $_.IsoPath;      $connectionType = "ISO";           break; }
            { $_.HostDevice   } { $insertedElement = $_.HostDevice;   $connectionType = "Host Device";   break; }
            { $_.RemoteDevice } { $insertedElement = $_.RemoteDevice; $connectionType = "Remote Device"; break; }
            default             { $insertedElement = "None";          $connectionType = "Client Device"; break; }
        }

        $output = New-Object -TypeName PSObject;

        $output | Add-Member -MemberType NoteProperty -Name "VM"                -Value $vmItem
        $output | Add-Member -MemberType NoteProperty -Name "CD-Drive"          -Value $vmCdDriveItem.Name;
        $output | Add-Member -MemberType NoteProperty -Name "Connection"        -Value $connectionType;
        $output | Add-Member -MemberType NoteProperty -Name "Inserted"          -Value $insertedElement;
        $output | Add-Member -MemberType NoteProperty -Name "Connected"         -Value $vmCdDriveItem.ConnectionState.Connected;
        $output | Add-Member -MemberType NoteProperty -Name "StartConnected"    -Value $vmCdDriveItem.ConnectionState.StartConnected;
        $output | Add-Member -MemberType NoteProperty -Name "AllowGuestControl" -Value $vmCdDriveItem.ConnectionState.AllowGuestControl;
        $output;
    }
}