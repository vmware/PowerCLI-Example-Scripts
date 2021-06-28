<# 
.SYNOPSIS 
    Creates HTML report of snapshots , Poweroff and PoweredOn VMS

.DESCRIPTION
    The purpose of the script is to get a list of all VM Snaphots, Powered On VMs and Powered Off VMs. Utilises css and converts to a good looking html report. HTML format highlights large/old snapshots. This can be scheduled via taks scheduler and emailed to administrators or uplaoded to an IIS web location. 

.NOTES 
    Script name: VMsStatusReport.ps1
    Created on: 20/06/2021
    Author: Jimit Gohel, @PsJimKG
    Dependencies: Along with PowerCli, this script also requires Don Jones EnhancedHTML2 module. https://www.powershellgallery.com/packages/EnhancedHTML2/2.1.0.1
    ===Tested Against Environment====
    vSphere Version: 6.7
    PowerCLI Version: PowerCLI 11.5.0
    PowerShell Version: 5.1
    OS Version: Windows 10
   
.INPUTS
   VIServerFilePath
   
.OUTPUTS
   html file named VMStatusReport.html
    
.PARAMETER VIServerFilePath
   csv file path to list of viservers
   
.PARAMETER Outpath
   Output path to html report.
   
.EXAMPLE
 	PS> Get-VMSnapshotReport -VIServerFilePath "C:\Temp\viservers.csv" -OutPath "C:\MyReports"

.EXAMPLE
  PS> Get-VMSnapshotReport "C:\temp\viserverslist.csv" C:\VMReports"
  
 #>
function Get-VMSnapshotReport {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$VIServerFilePath,
	
        [Parameter(Mandatory = $True, Position = 2)]
        [string]$OutPath
    )
    # path to CSV list of viservers

    $viservers = (Get-Content "$VIServerFilePath")

    Connect-VIServer $viservers

    $CSS2 = "body {
        color: #333333;
        font-family: Tahoma;
        font-size: 10pt;
      }
      h1 {
        text-align: center;
      }
      h2 {
        border-top: 1px solid #666666;
      }
      th {
        font-weight: bold;
        color: #eeeeee;
        background-color: #333333;
        cursor: pointer;
      }
      .odd {
        background-color: #ffffff;
      }
      .even {
        background-color: #bfbfbf;
      }
      
      .paginate_enabled_next,
      .paginate_enabled_previous {
        cursor: pointer;
        border: 1px solid #222222;
        background-color: #dddddd;
        padding: 2px;
        margin: 4px;
        border-radius: 2px;
      }
      .paginate_disabled_previous,
      .paginate_disabled_next {
        color: #666666;
        cursor: pointer;
        background-color: #dddddd;
        padding: 2px;
        margin: 4px;
        border-radius: 2px;
      }
      .dataTables_info {
        margin-bottom: 4px;
      }
      .sectionheader {
        cursor: pointer;
      }
      .sectionheader:hover {
        color: red;
      }
      .grid {
        width: 100%;
      }
      .smallgrid {
        width: 50%;
      }
      .red {
        color: #ff3333;
        font-weight: bold;
      }
      .green {
        background-color: #00cc44;
        font-weight: bold;
      }      
    "

    #Capturing VMs data
    $vms = Get-VM

    #reportgeneratedtag
    $reportgeneratedtag = (Get-Date -Format "dd MMMM yyyy HH:mm:ss")

    #Capturing data for snapshots

    $paramsSnapshotFragment = @{'As' = 'Table';
        'PreContent'                 = '<h2>VM Snapshots</h2>';
        'MakeTableDynamic'           = $true;
        'TableCssClass'              = 'grid';
        'Properties'                 = 'VM', @{Name = 'SnapshotName'; Expression = { $_.Name } }, 'Created', @{Name = 'AgeDays'; Expression = { ((New-TimeSpan -Start $_.Created -End (get-date)).Days) }; css = { if (((New-TimeSpan -Start $_.Created -End (get-date)).Days) -gt 120) { 'red' } } }, 'Description', @{name = 'SizeGB'; expression = { [math]::Round($_.sizegb, 2) }; css = { if ($_.sizegb -gt 100) { 'red' } } }, 'PowerState', 'IsCurrent', 'ParentSnapshot', 'Children'
    }
    $snapshots = $vms | Get-Snapshot | ConvertTo-EnhancedHTMLFragment @paramsSnapshotFragment 

    #PoweredOff

    $paramsPoweredoff = @{'As' = 'Table';
        'PreContent'           = '<h2>Powered Off VMs</h2>';
        'MakeTableDynamic'     = $true;
        'TableCssClass'        = 'grid';
        'Properties'           = 'Name', 'PowerState', 'Notes' , 'Folder'
    }
    $poweredoffvms = $vms | Where-Object { $_.PowerState -ne 'PoweredOn' } | ConvertTo-EnhancedHTMLFragment @paramsPoweredoff   

    #PoweredOn

    $paramsPoweredon = @{'As' = 'Table';
        'PreContent'          = '<h2>Powered On VMs</h2>';
        'MakeTableDynamic'    = $true;
        'TableCssClass'       = 'grid';
        'Properties'          = 'Name', 'PowerState', 'Notes' , 'Folder'
    }
    $poweredonvms = $vms | Where-Object { $_.PowerState -eq 'PoweredOn' } | ConvertTo-EnhancedHTMLFragment @paramsPoweredon   


    # Finalising main html report
    $paramsMainHTML = @{
        'HTMLFragments' = $reportgeneratedtag, $snapshots, $poweredoffvms, $poweredonvms
        'CssStyleSheet' = $CSS2;
        'Title'         = 'VM Status Report';
        'PreContent'    = "<h1>VM Status Report</h1>"
    }
    ConvertTo-EnhancedHTML  @paramsMainHTML | Out-File "$OutPath\VMStatusReport.html" -Encoding utf8


    Disconnect-VIServer -Server $viservers -Force -Confirm:$false
}

