# Author: Kyle Ruddy
# Product: VMware Cloud on AWS
# Description: VMware Cloud on AWS Firewall Rule Accelerator for PowerCLI
# Requirements:
#  - PowerShell 3.x or newer
#  - PowerCLI 6.5.4 or newer
#  - Use Default IP Addresses
#  - Use NSX-V on VMware Cloud on AWS

#---------- USER VARIABLES ----------------------------------------

$oauthToken = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
$orgId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx'
$sddcId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx'

# ---------- DO NOT MODIFY BELOW THIS ------------------------------


Connect-Vmc -RefreshToken $oauthToken | Out-Null

$orgSvc = Get-VmcService -Name com.vmware.vmc.orgs

if ($orgId) {
    $org = $orgSvc.List() | where {$_.id -eq $orgId}
}
else {$org = $orgSvc.List()}

if ($org -eq $null) {Write-Output "No Org Found. Exiting."; break}

$sddcSvc = Get-VmcService -Name com.vmware.vmc.orgs.sddcs

if ($sddcId) {
    $sddc = $sddcSvc.Get($org.id, $sddcId)
}
else {$sddc = $sddcSvc.List($org.id)}

if ($sddc -eq $null) {Write-Output "No SDDC Found. Exiting."; break}
elseif ($sddc -is [array]) {Write-Output "Multiple SDDCs Found. Please Specify an SDDC ID. Exiting."; break}

$edgeSvc = Get-VmcService com.vmware.vmc.orgs.sddcs.networks.edges
$mgwEdge = ($edgeSvc.Get($org.id,$sddcId,'gatewayServices') | Select-Object -ExpandProperty edge_page).data | where {$_.id -eq 'edge-1'}

$ipsecSvc = Get-VmcService com.vmware.vmc.orgs.sddcs.networks.edges.ipsec.config
$ipsecVPN = $ipsecSvc.Get($org.id, $sddcId, $mgwEdge.id)

$localSubnet = $ipsecVPN.sites.sites.local_subnets.subnets
$vpnSubnet = $ipsecVPN.sites.sites.peer_subnets.subnets
$vcMgmtIP = $sddc.resource_config.vc_management_ip
$vcPublicIP = $sddc.resource_config.vc_public_ip
$esxSubnet = $sddc.resource_config.esx_host_subnet
$ipsecVPNname = $ipsecVPN.sites.sites.name 

function Add-VMCFirewallRule {
    <#
        .NOTES
        ===========================================================================
        Created by:    Kyle Ruddy
        Date:          08/22/2018
        Organization:  VMware
        Blog:          https://www.kmruddy.com
        Twitter:       @kmruddy
        ===========================================================================
        .SYNOPSIS
            Creates a Firewall Rule for a given SDDC
        .DESCRIPTION
            Creates a Firewall Rule for a given SDDC
        .EXAMPLE
            Add-VMCFirewallRule -OrgId <org id> -sddcId <sddc id> -FwRuleName <firewall rule name> -SourceIpAddress <source ip address> -DestIpAddress <destination ip address> -Service <service>

    #>
    param(
        [Parameter(Mandatory=$true)]
        [String]$OrgId,
        [Parameter(Mandatory=$true)]
        [String]$SddcId,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Management Gateway','Compute Gateway')]
        [String]$Edge = 'Management Gateway',
        [Parameter(Mandatory=$true)]
        [String]$FwRuleName,
        [Parameter(Mandatory=$false)]
        $SourceIpAddress,
        [Parameter(Mandatory=$false)]
        $DestIpAddress,
        [Parameter(Mandatory=$true)]
        [ValidateSet('HTTPS','ICMP','SSO','Provisioning','Any','Remote Console')]
        [String]$Service,
        [Parameter(Mandatory=$false)]
        [ValidateSet('accept')]
        $FwAction = 'accept'

    )

    if ($edge -eq 'Management Gateway') {$EdgeId = 'edge-1'}
    elseif ($edge -eq 'Compute Gateway') {$EdgeId = 'edge-2'}
    else {Write-Output "No Valid Edge Input Found."}

    $fwRuleSvc = Get-VmcService com.vmware.vmc.orgs.sddcs.networks.edges.firewall.config.rules
    
    $ruleElementSpec = $fwRuleSvc.Help.add.firewall_rules.firewall_rules.Element.Create()
    $fwRules = $fwRuleSvc.Help.add.firewall_rules.Create()
    $ruleSpec = $fwRuleSvc.Help.add.firewall_rules.firewall_rules.Create()

    # AppSpec
    $appSpec = $fwRuleSvc.Help.add.firewall_rules.firewall_rules.Element.application.Create()
    # ServiceSpec
    $serviceSpec = $fwRuleSvc.Help.add.firewall_rules.firewall_rules.Element.application.service.Element.Create()

    if ($Service -eq 'HTTPS') {
        $protocol = 'TCP'
        $port = @("443")
    }
    elseif ($Service -eq 'ICMP') {
        $protocol = 'ICMP'
        $icmpType = 'any'

    }
    elseif ($Service -eq 'SSO') {
        $protocol = 'TCP'
        $port = @("7444")
    }
    elseif ($Service -eq 'Provisioning') {
        $protocol = 'TCP'
        $port = @("902")
    }
    elseif ($Service -eq 'Any') {
        $protocol = 'Any'
        $port = $null
    }
    elseif ($Service -eq 'Remote Console') {
        $protocol = 'TCP'
        $port = @("903")
    }
    else {Write-Output "No Protocol Found."; break}

    $serviceSpec.protocol = $protocol

    # Process ICMP Type from JSON
    $icmpType = $null
    if($protocol -eq 'ICMP') {
        $icmpType = 'any'
    }
    
    if ($icmpType) {
        $serviceSpec.icmp_type = $icmpType}
    if ($port) {
        $serviceSpec.port = $port
        $serviceSpec.source_port = @("any")
    }

    $addSpec = $ruleElementSpec.application.service.Add($serviceSpec)


    # Create Source Spec
    if($SourceIpAddress) {
        $srcSpec = $fwRuleSvc.Help.add.firewall_rules.firewall_rules.Element.source.Create()
        $srcSpec.exclude = $false
        $srcSpec.ip_address = @($SourceIpAddress)
        $ruleElementSpec.source = $srcSpec
    }
    

    # Create Destination Spec
    if($DestIpAddress) {        
        $destSpec = $fwRuleSvc.Help.add.firewall_rules.firewall_rules.Element.destination.Create()
        $destSpec.exclude = $false
        $destSpec.ip_address = @($DestIpAddress)
        $ruleElementSpec.destination = $destSpec

    }

    
    $ruleElementSpec.rule_type = "user"
    $ruleElementSpec.enabled = $true
    $ruleElementSpec.logging_enabled = $false

    $ruleElementSpec.action = $FwAction
    $ruleElementSpec.name = $FwRuleName

    # Add the individual FW rule spec into our overall firewall rules array
    Write-Output "Creating VMC Firewall Rule: $FwRuleName"
    $ruleSpecAdd = $ruleSpec.Add($ruleElementSpec)

    $fwRules.firewall_rules = $ruleSpec
    $fwRuleAdd = $fwRuleSvc.add($orgId,$sddcId,$EdgeId,$fwRules)

}


# vCenter (ANY) to VPN
Add-VMCFirewallRule -OrgId $org.Id -sddcId $sddc.id -FwRuleName "vCenter (ANY) to $ipsecVPNname" -SourceIpAddress $vcMgmtIP -DestIpAddress $vpnSubnet -Service 'Any'

# ESXi (ANY) to VPN
Add-VMCFirewallRule -OrgId $org.Id -sddcId $sddc.id -FwRuleName "ESXi (ANY) to $ipsecVPNname" -SourceIpAddress $esxSubnet,'10.2.16.0/20' -DestIpAddress $vpnSubnet -Service 'Any'

# VPN to vCenter (HTTPS)
Add-VMCFirewallRule -OrgId $org.Id -sddcId $sddc.id -FwRuleName "$ipsecVPNname to vCenter (HTTPS)" -SourceIpAddress $vpnSubnet -DestIpAddress $vcMgmtIP -Service 'HTTPS'

# VPN to vCenter (ICMP)
Add-VMCFirewallRule -OrgId $org.Id -sddcId $sddc.id -FwRuleName "$ipsecVPNname to vCenter (ICMP)" -SourceIpAddress $vpnSubnet -DestIpAddress $vcMgmtIP -Service 'ICMP'

# VPN to ESXi (Provisioning)
Add-VMCFirewallRule -OrgId $org.Id -sddcId $sddc.id -FwRuleName "$ipsecVPNname to ESXi (Provisioning)" -SourceIpAddress $vpnSubnet -DestIpAddress $esxSubnet,'10.2.16.0/20' -Service 'Provisioning'

# VPN to ESXi (Remove Console)
Add-VMCFirewallRule -OrgId $org.Id -sddcId $sddc.id -FwRuleName "$ipsecVPNname to ESXi (Remote Console)" -SourceIpAddress $vpnSubnet -DestIpAddress $esxSubnet,'10.2.16.0/20' -Service 'Remote Console'

# VPN to ESXi (ICMP)
Add-VMCFirewallRule -OrgId $org.Id -sddcId $sddc.id -FwRuleName "$ipsecVPNname to ESXi (ICMP)" -SourceIpAddress $vpnSubnet -DestIpAddress $esxSubnet,'10.2.16.0/20' -Service 'ICMP'