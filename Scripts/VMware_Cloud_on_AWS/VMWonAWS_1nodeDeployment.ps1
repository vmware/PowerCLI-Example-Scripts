# Author: Kyle Ruddy
# Product: VMware Cloud on AWS
# Description: VMware Cloud on AWS Single Host Deployment Script using PowerCLI
# Requirements:
#  - PowerShell 3.x or newer
#  - PowerCLI 6.5.4 or newer

# Set details for SDDC
$oauthToken = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
$sddcName = "PowerCLI-1Host-SDDC"
$hostCount = "1"
$awsRegion = "US_WEST_2"
$useAwsAccount = $false

# --- Deployment code  ---
# Connect to VMware Cloud Service
Connect-Vmc -RefreshToken $oauthToken | Out-Null

# Get ORG ID
$orgSvc = Get-VmcService -Name com.vmware.vmc.orgs
$org = $orgSvc.List()
Write-Output -InputObject "Org: $($org.display_name) ID: $($org.id)"

# Check to use the already existing AWS account connection
if ($useAwsAccount -eq $true) {
    # Get Linked Account ID
    $connAcctSvc = Get-VmcService -Name com.vmware.vmc.orgs.account_link.connected_accounts
    $connAcctId = $connAcctSvc.get($org.id) | Select-Object -ExpandProperty id
    Write-Output -InputObject "Account ID: $connAcctId"

    # Get Subnet ID
    $compSubnetSvc = Get-VmcService -Name com.vmware.vmc.orgs.account_link.compatible_subnets
    $vpcMap = $compSubnetSvc.Get($org.id, $connAcctId, $region) | Select-Object -ExpandProperty vpc_map 
    $compSubnets = $vpcMap | Select-Object -ExpandProperty Values | Select-Object -ExpandProperty subnets
    $compSubnet = $compSubnets | where {$_.name -ne $null} | Select-Object -first 1
    Write-Output -InputObject "Subnet CIDR $($compSubnet.subnet_cidr_block) ID: $($compSubnet.subnet_id)"
}
elseif ($useAwsAccount -eq $false) {
    Write-Output -InputObject "AWS Account Not Configured - you must connect to an AWS account within 14 days of creating this SDDC"
}

# Deploy the SDDC
$sddcSvc = Get-VmcService com.vmware.vmc.orgs.sddcs
$sddcCreateSpec = $sddcSvc.Help.create.sddc_config.Create()
$sddcCreateSpec.region = $awsRegion
$sddcCreateSpec.Name = $sddcName
$sddcCreateSpec.num_hosts = $hostCount
if ($org.properties.values.sddcTypes) {$sddcCreateSpec.sddc_type = "1NODE"}
$sddcCreateSpec.Provider = "AWS"

if ($useAwsAccount -eq $true) {
    $accountLinkSpec = $sddcSvc.Help.create.sddc_config.account_link_sddc_config.Element.Create()
    $accountLinkSpec.connected_account_id = $connAcctId
    $custSubId0 = $sddcSvc.Help.create.sddc_config.account_link_sddc_config.Element.customer_subnet_ids.Element.Create()
    $custSubId0 = $compSubnet.subnet_id
    $accountLinkSpec.customer_subnet_ids.Add($custSubId0) | Out-Null
    $sddcCreateSpec.account_link_sddc_config.Add($accountLinkSpec) | Out-Null
}
elseif ($useAwsAccount -eq $false) {
    $accountLinkDelaySpec = $sddcSvc.Help.create.sddc_config.account_link_config.delay_account_link.Create()
    $accountLinkDelaySpec = $true
    $sddcCreateSpec.account_link_config.delay_account_link = $accountLinkDelaySpec
}

$newSddc = $sddcSvc.create($org.Id, $sddcCreateSpec)
$newSddc | Select-Object resource_id,status,task_type,start_time,task_id