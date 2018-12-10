$MyRefreshToken = "XXXX-XXXX-XXXX-XXXX"
Connect-VMC -RefreshToken $MyRefreshToken

#List the user firewall Rules for MGW
Get-VMCFirewallRule -SDDCName "vGhetto" -OrgName "BashFest - Red Team" -GatewayType MGW

#List the firewall rules including system firewall rules for MGW
Get-VMCFirewallRule -SDDCName "vGhetto" -OrgName "BashFest - Red Team" -GatewayType MGW -ShowAll

#Export Firewall Rules from original SDDC
Export-VMCFirewallRule -SDDCName "vGhetto" -OrgName "BashFest - Red Team" -GatewayType MGW -Path ~/Desktop/VMCFirewallRules.json

#Import Firewall Rules to new SDDC
Import-VMCFirewallRule -SDDCName “Single-Host-SDDC” -OrgName "BashFest - Red Team" -GatewayType MGW -Path ~/Desktop/VMCFirewallRules.json

#Remove the firewall Rules we just created for the SDDC
$Rules = Get-VMCFirewallRule -SDDCName "Single-Host-SDDC" -OrgName "BashFest - Red Team" -GatewayType MGW
Foreach ($rule in $rules){
    Remove-VMCFirewallRule  -SDDCName “Single-Host-SDDC” -OrgName "BashFest - Red Team" -GatewayType MGW -RuleId $rule.id
}