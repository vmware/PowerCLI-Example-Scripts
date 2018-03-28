# SRM PowerCLI Cmdlets

Helper functions for working with VMware SRM 6.5 with PowerCLI 6.5.1 or later. PowerShell 5.0 and above is required.

This module is provided for illustrative/educational purposes to explain how the PowerCLI access to the SRM public API can be used.

## Getting Started

### Getting the SRM cmdlets

The latest version of the software can be cloned from the git repository:

    git clone https://github.com/benmeadowcroft/SRM-Cmdlets.git

Or downloaded as a [zip file](https://github.com/benmeadowcroft/SRM-Cmdlets/archive/master.zip).

Specific releases (compatible with earlier PowerCLI and SRM versions) can be downloaded via the [release page](https://github.com/benmeadowcroft/SRM-Cmdlets/releases).

### Deploy SRM-Cmdlets module

After cloning (or downloading and extracting) the PowerShell module, you can import the module into your current PowerShell session by by passing the path to `Meadowcroft.Srm.psd1` to the `Import-Module` cmdlet, e.g.:

    Import-Module -Name .\SRM-Cmdlets\Meadowcroft.Srm.psd1

You can also install the module into the PowerShell path so it can be loaded implicitly. See [Microsoft's Installing Modules instructions](http://msdn.microsoft.com/en-us/library/dd878350) for more details on how to do this.

The module uses the default prefix of `Srm` for the custom functions it defines. This can be overridden when importing the module by setting the value of the `-Prefix` parameter when calling `Import-Module`.

### Connecting to SRM

After installing the module the next step is to connect to the SRM server. Details of how to do this are located in the [PowerCLI 6.5.1 User's Guide](http://pubs.vmware.com/vsphere-65/topic/com.vmware.powercli.ug.doc/GUID-A5F206CF-264D-4565-8CB9-4ED1C337053F.html)

    $credential = Get-Credential
    Connect-VIServer -Server vc-a.example.com -Credential $credential
    Connect-SrmServer -Credential $credential -RemoteCredential $credential

At this point we've just been using the cmdlets provided by PowerCLI, the PowerCLI documentation also provides some examples of how to call the SRM API to perform various tasks. In the rest of this introduction we'll perform some of those tasks using the custom functions defined in this project.

### Report the Protected Virtual Machines and Their Protection Groups

Goal: Create a simple report listing the VMs protected by SRM and the protection group they belong to.

    Get-SrmProtectionGroup | %{
        $pg = $_
        Get-SrmProtectedVM -ProtectionGroup $pg } | %{
            $output = "" | select VmName, PgName
            $output.VmName = $_.Vm.Name
            $output.PgName = $pg.GetInfo().Name
            $output
        } | Format-Table @{Label="VM Name"; Expression={$_.VmName} },
                         @{Label="Protection group name"; Expression={$_.PgName}
    }

### Report the Last Recovery Plan Test

Goal: Create a simple report listing the state of the last test of a recovery plan

    Get-SrmRecoveryPlan | %{ $_ |
        Get-SrmRecoveryPlanResult -RecoveryMode Test | select -First 1
    } | Select Name, StartTime, RunMode, ResultState | Format-Table


### Execute a Recovery Plan Test

Goal: for a specific recovery plan, execute a test failover. Note the "local" SRM server we are connected to should be the recovery site in order for this to be successful.

    Get-SrmRecoveryPlan -Name "Name of Plan" | Start-SrmRecoveryPlan -RecoveryMode Test

### Export the Detailed XML Report of the Last Recovery Plan Workflow

Goal: get the XML report of the last recovery plan execution for a specific recovery plan.

    Get-SrmRecoveryPlan -Name "Name of Plan" | Get-SrmRecoveryPlanResult |
        select -First 1 | Export-SrmRecoveryPlanResultAsXml

### Protect a Replicated VM

Goal: Take a VM replicated using vSphere Replication or Array Based Replication, add it to an appropriate protection group and configure it for protection

    $pg = Get-SrmProtectionGroup "Name of Protection Group"
    Get-VM vm-01a | Protect-SrmVM -ProtectionGroup $pg
