function Install-HostClient {
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
        This advanced function will allow you to install the ESXi Host Client on
        all the hosts in a specified cluster.

        .Example
        Install-HostClient -Cluster (Get-Cluster Management-CL) -Datastore (Get-Datastore NFS-SAS-300GB-A) -vibfullpath c:\temp\esxui-2976804.vib

        .Example
        $ds = Get-Datastore Main-shared
        $Cluster = Main-CL
        Install-HostClient -Cluster $cluster -Datastore $ds -vibfullpath c:\temp\esxui-2976804.vib

        .Notes
        You must use shared storage for this to work correctly, otherwise only a
        single host will be able to install the vib and all others will fail
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = 'Must be shared storage across all hosts')]
        [ValidateScript({Get-Datastore $_})]
        [VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.NasDatastoreImpl]$Datastore,

        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = 'Please specify a Cluster object')]
        [ValidateScript({Get-Cluster $_})]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.ComputeResourceImpl]$Cluster,

        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = 'Specify the full path of the ESXi Host Client Vib')]
        [ValidateScript({Get-Item $_})]
        [String]$vibfullpath
    )
    Begin {

        $VIBFile = Get-Item $vibfullpath -ErrorAction SilentlyContinue

        # Verify that VIB location is correct
        if ($VIBFile -eq $null){Throw "oops! looks like $VIBFile doesn't exist in this location."}

        # Save filename to variable
        $VIBFilename = $VIBFile.PSChildname

        # Save datacenter to variable for Datastore path
        $dc = $Cluster | Get-Datacenter

        #Get-Datastore -Name $Datastore

        # Create Datastore Path string
        $Datastorepath = 'vmstore:\' + $dc + '\' + $Datastore.Name + '\'

        # Verbose info for debugging
        Write-Verbose -Message "DatastorePath = $Datastorepath"
        Write-Verbose -Message "Vibfile = $VIBFile"
        Write-Verbose -Message "Vibfullpath = $vibfullpath"
        Write-Verbose -Message "VibFilename = $VIBFilename"

        # check to see if file already exists or not before copying
        if (!(Test-Path -Path $Datastorepath)) {Copy-DatastoreItem $VIBFile $Datastorepath -Force}

        # validate the copy worked. If not, stop script
        if (!(Test-Path -Path $Datastorepath)) {Throw "Looks like the VIB did not copy to $Datastorepath. Check the filename and datastore path again and rerun this function."}

        # Create VIB path string for ESXCLI
        $VIBPATH = '/vmfs/volumes/' + $Datastore.name + '/' + "$VIBFilename"
    }

    Process {
        #$VIBPATH = "/vmfs/volumes/NFS-SAS-300GB-A/esxui-2976804.vib"

        # Get each host in specified cluster that meets criteria
        Get-VMHost -Location $Cluster |
            Where-Object -FilterScript { $_.PowerState -eq 'PoweredOn' -and $_.ConnectionState -eq 'Connected' } |
            ForEach-Object -Process {
                Write-Host -Object "Preparing $($_.Name) for ESXCLI" -ForegroundColor Yellow

                # Create ESXCLI variable for host for actions
                $ESXCLI = Get-EsxCli -VMHost $_

                # Check to see if ESX-UI is already installed
                if (($ESXCLI.software.vib.list() |
                    Select-Object -Property AcceptanceLevel, ID, InstallDate, Name, ReleaseDate, Status, Vendor, Version |
                    Where-Object -FilterScript {$_.Name -match 'esx-ui'}))
                {
                    Write-Host -Object "It appears ESX-UI is already installed on $_. Skipping..." -ForegroundColor Yellow
                }
                else
                {
                    Write-Host -Object "Installing ESXi Embedded Host Client on $($_.Name)" -ForegroundColor Yellow

                    # Saving command to variable to use for verification after command is run
                    $action = $ESXCLI.software.vib.install($null,$null,$null,$null,$null,$null,$null,$null,$VIBPATH)

                    # Verify VIB installed successfully
                    if ($action.Message -eq 'Operation finished successfully.')
                    {
                        Write-Host -Object "Action Completed successfully on $($_.Name)" -ForegroundColor Green
                    }
                    else
                    {
                        Write-Host -Object $action.Message -ForegroundColor Red
                    }
                }
            }
    }
    End {
        Write-Host -Object 'Function Complete' -ForegroundColor Green
        Write-Host -Object 'You may access your hosts at https://<host ipaddress>/ui' -ForegroundColor Green
    }
}
