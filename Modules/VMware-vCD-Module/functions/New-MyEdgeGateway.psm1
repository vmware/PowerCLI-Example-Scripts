Function New-MyEdgeGateway {
<#
.SYNOPSIS
    Creates a new Edge Gateway with Default Parameters

.DESCRIPTION
    Creates a new Edge Gateway with Default Parameters

    Default Parameters are:
    * HA State
    * DNS Relay


.NOTES
    File Name  : New-MyEdgeGateway.ps1
    Author     : Markus Kraus
    Version    : 1.1
    State      : Ready

.LINK
    https://mycloudrevolution.com/

.EXAMPLE
    New-MyEdgeGateway -Name "TestEdge" -OrgVDCName "TestVDC" -OrgName "TestOrg" -Size compact -ExternalNetwork "ExternalNetwork" -IPAddress "192.168.100.1" -SubnetMask "255.255.255.0" -Gateway "192.168.100.254" -IPRangeStart ""192.168.100.2" -IPRangeEnd ""192.168.100.3" -Verbose

.PARAMETER Name
    Name of the New Edge Gateway as String

.PARAMETER OrgVDCName
    OrgVDC where the new Edge Gateway should be created as string

.PARAMETER OrgName
    Org where the new Edge Gateway should be created as string

.PARAMETER Size
    Size of the new Edge Gateway as string

.PARAMETER ExternalNetwork
     External Network of the new Edge Gateway as String

.PARAMETER IPAddress
     IP Address of the New Edge Gateway as IP Address

.PARAMETER SubnetMask
     Subnet Mask of the New Edge Gateway as IP Address

.PARAMETER Gateway
     Gateway of the New Edge Gateway as IP Address

.PARAMETER IPRangeStart
     Sub Allocation IP Range Start of the New Edge Gateway as IP Address

.PARAMETER IPRangeEnd
     Sub Allocation IP Range End of the New Edge Gateway as IP Address

.PARAMETER Timeout
    Timeout for the Edge Gateway to get Ready

    Default: 120s

#>
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Name of the New Edge Gateway as String")]
        [ValidateNotNullorEmpty()]
            [String] $Name,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="OrgVDC where the new Edge Gateway should be created as string")]
        [ValidateNotNullorEmpty()]
            [String] $OrgVdcName,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Org where the new Edge Gateway should be created as string")]
        [ValidateNotNullorEmpty()]
            [String] $OrgName,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Size of the new Edge Gateway as string")]
        [ValidateNotNullorEmpty()]
        [ValidateSet("compact","full")]
            [String] $Size,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="External Network of the New Edge Gateway as String")]
        [ValidateNotNullorEmpty()]
            [String] $ExternalNetwork,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="IP Address of the New Edge Gateway as IP Address")]
        [ValidateNotNullorEmpty()]
            [IPAddress] $IPAddress,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Subnet Mask of the New Edge Gateway as IP Address")]
        [ValidateNotNullorEmpty()]
            [IPAddress] $SubnetMask,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Gateway of the New Edge Gateway as IP Address")]
        [ValidateNotNullorEmpty()]
            [IPAddress] $Gateway,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Sub Allocation IP Range Start the New Edge Gateway as IP Address")]
        [ValidateNotNullorEmpty()]
            [IPAddress] $IPRangeStart,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Sub Allocation IP Range End the New Edge Gateway as IP Address")]
        [ValidateNotNullorEmpty()]
            [IPAddress] $IPRangeEnd,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False,HelpMessage="Timeout for the Edge Gateway to get Ready")]
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
    ## Get External Network
    Write-Verbose "Get External Network"
    $extNetwork = Get-ExternalNetwork | Get-CIView -Verbose:$False | Where-Object {$_.name -eq $ExternalNetwork}

    ## Build EdgeGatway Configuration
    Write-Verbose "Build EdgeGatway Configuration"
    $EdgeGateway = New-Object VMware.VimAutomation.Cloud.Views.Gateway
    $EdgeGateway.Name = $Name
    $EdgeGateway.Configuration = New-Object VMware.VimAutomation.Cloud.Views.GatewayConfiguration
    #$EdgeGateway.Configuration.BackwardCompatibilityMode = $false
    $EdgeGateway.Configuration.GatewayBackingConfig = $Size
    $EdgeGateway.Configuration.UseDefaultRouteForDnsRelay = $false
    $EdgeGateway.Configuration.HaEnabled = $false

    $EdgeGateway.Configuration.EdgeGatewayServiceConfiguration = New-Object VMware.VimAutomation.Cloud.Views.GatewayFeatures
    $EdgeGateway.Configuration.GatewayInterfaces = New-Object VMware.VimAutomation.Cloud.Views.GatewayInterfaces

    $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface = New-Object VMware.VimAutomation.Cloud.Views.GatewayInterface
    $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].name = $extNetwork.Name
    $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].DisplayName = $extNetwork.Name
    $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].Network = $extNetwork.Href
    $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].InterfaceType = "uplink"
    $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].UseForDefaultRoute = $true
    $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].ApplyRateLimit = $false

    $ExNetexternalSubnet = New-Object VMware.VimAutomation.Cloud.Views.SubnetParticipation
    $ExNetexternalSubnet.Gateway = $Gateway.IPAddressToString
    $ExNetexternalSubnet.Netmask = $SubnetMask.IPAddressToString
    $ExNetexternalSubnet.IpAddress = $IPAddress.IPAddressToString
    $ExNetexternalSubnet.IpRanges = New-Object VMware.VimAutomation.Cloud.Views.IpRanges
    $ExNetexternalSubnet.IpRanges.IpRange = New-Object VMware.VimAutomation.Cloud.Views.IpRange
    $ExNetexternalSubnet.IpRanges.IpRange[0].StartAddress = $IPRangeStart.IPAddressToString
    $ExNetexternalSubnet.IpRanges.IpRange[0].EndAddress =   $IPRangeEnd.IPAddressToString

    $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].SubnetParticipation = $ExNetexternalSubnet

    ## Create EdgeGatway
    Write-Verbose "Create EdgeGatway"
    $CreateEdgeGateway = $orgVdc.ExtensionData.CreateEdgeGateway($EdgeGateway)

    ## Wait for EdgeGatway to become Ready
    Write-Verbose "Wait for EdgeGatway to become Ready"
    while((Search-Cloud -QueryType EdgeGateway -Name $Name -Verbose:$False).IsBusy -eq $True){
        $i++
        Start-Sleep 5
        if($i -gt $Timeout) { Write-Error "Creating Edge Gateway."; break}
        Write-Progress -Activity "Creating Edge Gateway" -Status "Wait for Edge to become Ready..."
    }
    Write-Progress -Activity "Creating Edge Gateway" -Completed
    Start-Sleep 1

    Search-Cloud -QueryType EdgeGateway -Name $Name | Select-Object Name, IsBusy, GatewayStatus, HaStatus | Format-Table -AutoSize


    }
}
