function Remove-HostClient {
    <#
        .NOTES
        ===========================================================================
        Created on:   	8/13/2015 9:12 AM
        Created by:   	Brian Graf
        Github:        http://www.github.com/vtagion
        Twitter:       @vBrianGraf
        Website:     	http://www.vtagion.com
        ===========================================================================

        .DESCRIPTION
        This advanced function will allow you to remove the ESXi Host Client
        on all the hosts in a specified cluster.

        .Example
        Remove-HostClient -Cluster (Get-Cluster Management-CL)

        .Example
        $Cluster = Main-CL
        Remove-HostClient -Cluster $cluster
    #>
    [CmdletBinding()]
    param(
        [ValidateScript({Get-Cluster $_})]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.ComputeResourceImpl]$Cluster
    )
    Process {
        # Get all ESX hosts in cluster that meet criteria
        Get-VMHost -Location $Cluster |
            Where-Object -FilterScript { $_.PowerState -eq 'PoweredOn' -and $_.ConnectionState -eq 'Connected' } |
            ForEach-Object -Process {
                Write-Host -Object "Preparing to remove Host Client from $($_.Name)" -ForegroundColor Yellow

                # Prepare ESXCLI variable
                $ESXCLI = Get-EsxCli -VMHost $_

                # Check to see if VIB is installed on the host
                if (($ESXCLI.software.vib.list() |
                    Where-Object -FilterScript {$_.Name -match 'esx-ui'}))
                {
                    Write-Host -Object "Removing ESXi Embedded Host Client on $($_.Name)" -ForegroundColor Yellow

                    # Command saved to variable for future verification
                    $action = $ESXCLI.software.vib.remove($null,$null,$null,$null,'esx-ui')

                    # Verify VIB removed successfully
                    if ($action.Message -eq 'Operation finished successfully.')
                    {
                        Write-Host -Object "Action Completed successfully on $($_.Name)" -ForegroundColor Green
                    }
                    else
                    {
                        Write-Host -Object $action.Message -ForegroundColor Red
                    }
                }
                else
                {
                    Write-Host -Object 'It appears Host Client is not installed on this host. Skipping...' -ForegroundColor Yellow
                }
            }
    }
    End {Write-Host -Object 'Function complete' -ForegroundColor Green}
}
