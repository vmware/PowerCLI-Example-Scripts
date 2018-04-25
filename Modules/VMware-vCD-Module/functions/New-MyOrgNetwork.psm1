Function New-MyOrgNetwork {
    <#
    .SYNOPSIS
        Creates a new Org Network with Default Parameters

    .DESCRIPTION

    .NOTES
        File Name  : New-MyOrgNetwork.ps1
        Author     : Markus Kraus
        Version    : 1.1
        State      : Ready

    .LINK
        https://mycloudrevolution.com

    .EXAMPLE
        New-MyOrgNetwork -Name Test -OrgVdcName "Test-OrgVDC" -OrgName "Test-Org" -EdgeName "Test-OrgEdge" -SubnetMask 255.255.255.0 -Gateway 192.168.66.1 -IPRangeStart 192.168.66.100 -IPRangeEnd 192.168.66.200

    .EXAMPLE
        New-MyOrgNetwork -Name Test -OrgVdcName "Test-OrgVDC" -OrgName "Test-Org" -EdgeName "Test-OrgEdge" -SubnetMask 255.255.255.0 -Gateway 192.168.66.1 -IPRangeStart 192.168.66.100 -IPRangeEnd 192.168.66.200 -Shared:$False

    .EXAMPLE
        $params = @{ 'Name' = 'Test';
                    'OrgVdcName'= 'Test-OrgVDC';
                    'OrgName'='Test-Org';
                    'EdgeName'='Test-OrgEdge';
                    'SubnetMask' = '255.255.255.0';
                    'Gateway' = '192.168.66.1';
                    'IPRangeStart' = '192.168.66.100';
                    'IPRangeEnd' = '192.168.66.200'
                    }
        New-MyOrgNetwork @params -Verbose

    .PARAMETER Name
        Name of the New Org Network as String

    .PARAMETER OrgVDCName
        OrgVDC where the new Org Network should be created as string

    .PARAMETER OrgName
        Org where the newOrg Networkshould be created as string

    .PARAMETER EdgeName
        Edge Gateway Name for the new Org Network as String

    .PARAMETER SubnetMask
         Subnet Mask of the New Org Network as IP Address

    .PARAMETER Gateway
         Gateway of the New Org Network as IP Address

    .PARAMETER IPRangeStart
        IP Range Start of the New Org Network as IP Address

    .PARAMETER IPRangeEnd
         IP Range End of the New Org Network as IP Address

    .PARAMETER Shared
         Switch for Shared OrgVDC Network

         Default: $True

    .PARAMETER Timeout
        Timeout for the Org Network to become Ready

        Default: 120s

    #>
        Param (
            [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Name of the New Org Network as String")]
            [ValidateNotNullorEmpty()]
                [String] $Name,
            [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="OrgVDC where the new Org Network should be created as string")]
            [ValidateNotNullorEmpty()]
                [String] $OrgVdcName,
            [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Org where the new Org Network should be created as string")]
            [ValidateNotNullorEmpty()]
                [String] $OrgName,
            [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Edge Gateway Name for the new Org Network as String")]
            [ValidateNotNullorEmpty()]
                [String] $EdgeName,
            [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Subnet Mask of the New Org Network as IP Address")]
            [ValidateNotNullorEmpty()]
                [IPAddress] $SubnetMask,
            [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Gateway of the New Org Network as IP Address")]
            [ValidateNotNullorEmpty()]
                [IPAddress] $Gateway,
            [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="IP Range Start the New Org Network as IP Address")]
            [ValidateNotNullorEmpty()]
                [IPAddress] $IPRangeStart,
            [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="IP Range End the New Org Network as IP Address")]
            [ValidateNotNullorEmpty()]
                [IPAddress] $IPRangeEnd,
            [Parameter(Mandatory=$False, ValueFromPipeline=$False, HelpMessage="Switch for Shared OrgVDC Network")]
            [ValidateNotNullorEmpty()]
                [Bool] $Shared = $True,
            [Parameter(Mandatory=$False, ValueFromPipeline=$False,HelpMessage="Timeout for the Org Network to become Ready")]
            [ValidateNotNullorEmpty()]
                [int] $Timeout = 120
        )
        Process {

        ## Get Org vDC
        Write-Verbose "Get Org vDC"
        [Array] $orgVdc = Get-Org -Name $OrgName | Get-OrgVdc -Name $OrgVdcName

        if ( $orgVdc.Count -gt 1) {
            throw "Multiple OrgVdcs found!"
            }
            elseif ( $orgVdc.Count -lt 1) {
                throw "No OrgVdc found!"
                }
        $orgVdcView = $orgVdc| Get-CIView

        ## Get EdgeGateway
        Write-Verbose "Get EdgeGateway"
        [Array] $edgeGateway = Search-Cloud -QueryType EdgeGateway -Name $EdgeName | Get-CIView
        if ( $edgeGateway.Count -gt 1) {
            throw "Multiple EdgeGateways found!"
            }
            elseif ( $edgeGateway.Count -lt 1) {
                throw "No EdgeGateway found!"
                }

        ## Define Org Network
        Write-Verbose "Define Org Network"
        $OrgNetwork = new-object vmware.vimautomation.cloud.views.orgvdcnetwork
        $OrgNetwork.name = $Name
        $OrgNetwork.edgegateway = $edgeGateway.id
        $OrgNetwork.isshared = $Shared

        $OrgNetwork.configuration = new-object vmware.vimautomation.cloud.views.networkconfiguration
        $OrgNetwork.configuration.fencemode = "natRouted"
        $OrgNetwork.configuration.ipscopes = new-object vmware.vimautomation.cloud.views.ipscopes

        $Scope = new-object vmware.vimautomation.cloud.views.ipScope
        $Scope.gateway = $Gateway
        $Scope.netmask = $SubnetMask

        $Scope.ipranges = new-object vmware.vimautomation.cloud.views.ipranges
        $Scope.ipranges.iprange = new-object vmware.vimautomation.cloud.views.iprange
        $Scope.ipranges.iprange[0].startaddress = $IPRangeStart
        $Scope.ipranges.iprange[0].endaddress = $IPRangeEnd

        $OrgNetwork.configuration.ipscopes.ipscope += $Scope

        ## Create Org Network
        Write-Verbose "Create Org Network"
        $CreateOrgNetwork = $orgVdcView.CreateNetwork($OrgNetwork)

        ## Wait for Org Network to become Ready
        Write-Verbose "Wait for Org Network to become Ready"
        while(!(Get-OrgVdcNetwork -Id $CreateOrgNetwork.Id -ErrorAction SilentlyContinue)){
            $i++
            Start-Sleep 5
            if($i -gt $Timeout) { Write-Error "Creating Org Network."; break}
            Write-Progress -Activity "Creating Org Network" -Status "Wait for Network to become Ready..."
        }
        Write-Progress -Activity "Creating Org Network" -Completed
        Start-Sleep 1

        Get-OrgVdcNetwork -Id $CreateOrgNetwork.Id | Select-Object Name, OrgVdc, NetworkType, DefaultGateway, Netmask, StaticIPPool, @{ N='isShared'; E = {$_.ExtensionData.isShared} } | Format-Table -AutoSize

        }
    }
