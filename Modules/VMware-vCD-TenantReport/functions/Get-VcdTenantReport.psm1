function Get-VcdTenantReport {
<#
    .NOTES
    ===========================================================================
    Created by: Markus Kraus
    Twitter: @VMarkus_K
    Private Blog: mycloudrevolution.com
    ===========================================================================
    Changelog:
    1.0.0 - Inital Release
    1.0.1 - Removed "Test-IP" Module
    1.0.2 - More Detailed Console Log
    ===========================================================================
    External Code Sources:
    Examle Usage of BOOTSTRAP with PowerShell
    https://github.com/tdewin/randomsamples/tree/master/powershell-veeamallstat
    BOOTSTRAP with PowerShell
    https://github.com/tdewin/randomsamples/tree/master/powerstarthtml
    ===========================================================================
    Tested Against Environment:
    vCD Version: 8.20
    PowerCLI Version: PowerCLI 6.5.1
    PowerShell Version: 5.0
    OS Version: Windows 8.1
    Keyword: VMware, vCD, Report, HTML
    ===========================================================================

    .DESCRIPTION
    This Function creates a HTML Report for your vCloud Director Organization.

    This Function is fully tested as Organization Administrator.
    With lower permissions a unexpected behavior is possible.

    .Example
    Get-VcdTenantReport -Server $ServerFQDN -Org $OrgName -Credential $MyCedential

    .Example
    Get-VcdTenantReport -Server $ServerFQDN -Org $OrgName -Path "C:\Temp\Report.html"

    .PARAMETER Server
    The FQDN of your vCloud Director Endpoint.

    .PARAMETER Org
    The Organization Name.

    .PARAMETER Credential
    PowerShell Credentials to access the Eénvironment.

    .PARAMETER Path
    The Path of the exported HTML Report.

#>
#Requires -Version 5
#Requires -Modules VMware.VimAutomation.Cloud, @{ModuleName="VMware.VimAutomation.Cloud";ModuleVersion="6.5.1.0"}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False)]
    [ValidateNotNullorEmpty()]
        [String] $Server,
    [Parameter(Mandatory=$True, ValueFromPipeline=$False)]
    [ValidateNotNullorEmpty()]
        [String] $Org,
    [Parameter(Mandatory=$False, ValueFromPipeline=$False)]
    [ValidateNotNullorEmpty()]
        [PSCredential] $Credential,
    [Parameter(Mandatory=$false, ValueFromPipeline=$False)]
    [ValidateNotNullorEmpty()]
        [String] $Path = ".\Report.html"

)

Process {

    # Start Connection to vCD

    if ($global:DefaultCIServers) {
        "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Disconnect existing vCD Server ..."
        $Trash = Disconnect-CIServer -Server * -Force:$true -Confirm:$false -ErrorAction SilentlyContinue
    }

    "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Connect vCD Server ..."
    if ($Credential) {
        $Trash = Connect-CIServer -Server $Server -Org $Org -Credential $Credential -ErrorAction Stop
    }
    else {
        $Trash = Connect-CIServer -Server $Server -Org $Org -ErrorAction Stop
    }
    "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Create HTML Report..."

    # Init HTML Report
    $ps = New-PowerStartHTML -title "vCD Tenant Report"

    #Set CSS Style
    $ps.cssStyles['.bgtitle'] = "background-color:grey"
    $ps.cssStyles['.bgsubsection'] = "background-color:#eee;"

    # Processing Data
    ## Get Main Objects
    [Array] $OrgVdcs = Get-OrgVdc
    [Array] $Catalogs = Get-Catalog
    [Array] $Users = Get-CIUser

    ## Add Header to Report
    $ps.Main().Add("div","jumbotron").N()
    $ps.Append("h1","display-3",("vCD Tenant Report" -f $OrgVdcs.Count)).Append("p","lead","Organization User Count: {0}" -f $Users.Count).Append("p","lead","Organization Catalog Count: {0}" -f $Catalogs.Count).Append("p","lead","Organization VDC Count: {0}" -f $OrgVdcs.Count).Append("hr","my-4").Append("p","font-italic","This Report lists the most important objects in your vCD Environmet. For more details contact your Service Provider").N()

    ## add Org Users to Report
    $ps.Main().Append("h2",$null,"Org Users").N()

    $ps.Add('table','table').Add("tr","bgtitle text-white").Append("th",$null,"User Name").Append("th",$null,"Locked").Append("th",$null,"DeployedVMCount").Append("th",$null,"StoredVMCount").N()
    $ps.Add("tr").N()

    foreach ($User in $Users) {
        $ps.Append("td",$null,$User.Name).N()
        $ps.Append("td",$null,$User.Locked).N()
        $ps.Append("td",$null,$User.DeployedVMCount).N()
        $ps.Append("td",$null,$User.StoredVMCount).N()
        $ps.Up().N()

    }
    $ps.Up().N()

    ## add Org Catalogs to Report
    $ps.Main().Append("h2",$null,"Org Catalogs").N()

    foreach ($Catalog in $Catalogs) {
        $ps.Add('table','table').Add("tr","bgtitle text-white").Append("th",$null,"Catalog Name").N()
        $ps.Add("tr").N()
        $ps.Append("td",$null,$Catalog.Name).Up().N()

        $ps.Add("td","bgsubsection").N()
        $ps.Add("table","table bgcolorsub").N()
        $ps.Add("tr").N()

        $headers = @("Item")
        foreach ($h in $headers) {
            $ps.Append("th",$null,$h).N()
        }
        $ps.Up().N()

        ### add Itens of the Catalog to the Report
        [Array] $Items = $Catalog.ExtensionData.CatalogItems.CatalogItem

        foreach ($Item in $Items) {
            $ps.Add("tr").N()
            $ps.Append("td",$null,$Item.Name).N()

            $ps.Up().N()

        }

        $ps.Up().Up().N()
    }
    $ps.Up().N()

    ## add Org VDC`s to the Report
    $ps.Main().Append("h2",$null,"Org VDCs").N()

    foreach ($OrgVdc in $OrgVdcs) {
        $ps.Main().Add('table','table table-striped table-inverse').Add("tr").Append("th",$null,"VDC Name").Append("th",$null,"Enabled").Append("th",$null,"CpuUsedGHz").Append("th",$null,"MemoryUsedGB").Append("th",$null,"StorageUsedGB").Up().N()
        $ps.Add("tr").N()
        $ps.Append("td",$null,$OrgVdc.Name).Append("td",$null,$OrgVdc.Enabled).Append("td",$null,$OrgVdc.CpuUsedGHz).Append("td",$null,$OrgVdc.MemoryUsedGB).Append("td",$null,[Math]::Round($OrgVdc.StorageUsedGB,2)).Up().N()

        ### add Edge Gateways of this Org VDC to Report
        $ps.Main().Append("h3",$null,"Org VDC Edge Gateways").N()
        [Array] $Edges = Search-Cloud -QueryType EdgeGateway -Filter "Vdc==$($OrgVdc.Id)"

        foreach ($Edge in $Edges) {
            $ps.Add('table','table').Add("tr","bgtitle text-white").Append("th",$null,"Edge Name").N()
            $ps.Add("tr").N()
            $ps.Append("td",$null,$Edge.Name).Up().N()

            $ps.Add("td","bgsubsection").N()
            $ps.Add("table","table bgcolorsub").N()
            $ps.Append("tr").Append("td","font-weight-bold","HaStatus").Append("td",$null,($Edge.HaStatus)).N()
                $ps.Append("td","font-weight-bold","AdvancedNetworkingEnabled").Append("td",$null,$Edge.AdvancedNetworkingEnabled).N()
            $ps.Append("tr").Append("td","font-weight-bold","NumberOfExtNetworks").Append("td",$null,($Edge.NumberOfExtNetworks)).N()
                $ps.Append("td","font-weight-bold","NumberOfOrgNetworks").Append("td",$null,$Edge.NumberOfOrgNetworks).N()

            $ps.Up().Up().N()
        }
        $ps.Up().N()

        ### add Org Networks of this Org VDC to Report
        $ps.Main().Append("h3",$null,"Org VDC Networks").N()
        [Array] $Networks = $OrgVdc | Get-OrgVdcNetwork

        foreach ($Network in $Networks) {
            $ps.Add('table','table').Add("tr","bgtitle text-white").Append("th",$null,"Network Name").N()
            $ps.Add("tr").N()
            $ps.Append("td",$null,$Network.Name).Up().N()

            $ps.Add("td","bgsubsection").N()
            $ps.Add("table","table bgcolorsub").N()
            $ps.Append("tr").Append("td","font-weight-bold","DefaultGateway").Append("td",$null,($Network.DefaultGateway)).N()
                $ps.Append("td","font-weight-bold","Netmask").Append("td",$null,$Network.Netmask).N()
            $ps.Append("tr").Append("td","font-weight-bold","NetworkType").Append("td",$null,($Network.NetworkType)).N()
                $ps.Append("td","font-weight-bold","StaticIPPool").Append("td",$null,$Network.StaticIPPool).N()

            $ps.Up().Up().N()
        }
        $ps.Up().N()

        ### add vApps of this Org VDC to Report
        $ps.Main().Append("h3",$null,"Org VDC vApps").N()

        [Array] $Vapps = $OrgVdc | Get-CIVApp

        foreach ($Vapp in $Vapps) {
            $ps.Add('table','table').Add("tr","bgtitle text-white").Append("th",$null,"vApp Name").Append("th",$null,"Owner").Up().N()
            $ps.Add("tr").N()
            $ps.Append("td",$null,$Vapp.Name).Append("td",$null,$Vapp.Owner).Up().N()

            #### add VMs of this vApp to Report
            $ps.Add("td","bgsubsection").N()
            $ps.Add("table","table bgcolorsub").N()
            $ps.Add("tr").N()

            $headers = @("Name","Status","GuestOSFullName","CpuCount","MemoryGB")
            foreach ($h in $headers) {
                $ps.Append("th",$null,$h).N()
            }
            $ps.Up().N()

            [Array] $VMs = $Vapp | Get-CIVM

            foreach ($VM in $VMs) {
                $ps.Add("tr").N()
                $ps.Append("td",$null,$VM.Name).N()
                $ps.Append("td",$null,$VM.Status).N()
                $ps.Append("td",$null,$VM.GuestOSFullName).N()
                $ps.Append("td",$null,$VM.CpuCount).N()
                $ps.Append("td",$null,$VM.MemoryGB).N()

                $ps.Up().N()

            }
            $ps.Up().Up().N()

        }
        $ps.Up().N()

    }
    $ps.save($Path)

    "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Open HTML Report..."
    Start-Process $Path

}
}
