<#
.MYNGC_REPORT
KEY\(VM\)
.LABEL
VM Snapshot Report
.DESCRIPTION
PowerActions Report Script that reports on VMs with snapshots along with their description, date of the snapshot, age in days of the snapshot, size of the snapshot in GB, 
the VM's provisioned vs. used space in GB, if the snapshot is the current one being used, its parent snapshot (if there is one), and the Power state of the VM itself. VM 
object is key (as it's the first managed object in the output), enabling you the ability to right-click an entry in the report to edit the target VM. Version 1.0, written 
by Aaron Smith (@awsmith99), published 08/10/2016.
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
    [Array] $vmSnapshotList = @( Get-Snapshot -VM $vmItem );

    foreach ( $snapshotItem in $vmSnapshotList )
    {
        $vmProvisionedSpaceGB = [Math]::Round( $vmItem.ProvisionedSpaceGB, 2 );
        $vmUsedSpaceGB        = [Math]::Round( $vmItem.UsedSpaceGB,        2 );
        $snapshotSizeGB       = [Math]::Round( $snapshotItem.SizeGB,       2 );
        $snapshotAgeDays      = ((Get-Date) - $snapshotItem.Created).Days;

        $output = New-Object -TypeName PSObject;

        $output | Add-Member -MemberType NoteProperty -Name "VM"                 -Value $vmItem;
        $output | Add-Member -MemberType NoteProperty -Name "Name"               -Value $snapshotItem.Name;
        $output | Add-Member -MemberType NoteProperty -Name "Description"        -Value $snapshotItem.Description;
        $output | Add-Member -MemberType NoteProperty -Name "Created"            -Value $snapshotItem.Created;
        $output | Add-Member -MemberType NoteProperty -Name "AgeDays"            -Value $snapshotAgeDays;
        $output | Add-Member -MemberType NoteProperty -Name "ParentSnapshot"     -Value $snapshotItem.ParentSnapshot.Name;
        $output | Add-Member -MemberType NoteProperty -Name "IsCurrentSnapshot"  -Value $snapshotItem.IsCurrent;
        $output | Add-Member -MemberType NoteProperty -Name "SnapshotSizeGB"     -Value $snapshotSizeGB;
        $output | Add-Member -MemberType NoteProperty -Name "ProvisionedSpaceGB" -Value $vmProvisionedSpaceGB;
        $output | Add-Member -MemberType NoteProperty -Name "UsedSpaceGB"        -Value $vmUsedSpaceGB;
        $output | Add-Member -MemberType NoteProperty -Name "PowerState"         -Value $snapshotItem.PowerState;

        $output;
    }
}