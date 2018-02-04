# Fetch Cis Server hostname and credentials
.\CisConfig.ps1

Connect-rCisServer -Server $cisServer -User $cisUser -Password $cisPswd

Get-rCisTagAssignment -Tag MyNewTag1 | Remove-rCisTagAssignment -Confirm:$false

Get-rCisTag -Name MyNewTag1 | Remove-rCisTag -Confirm:$false

Get-rCisTagCategory -Name MyNewCat1 | Remove-rCisTagCategory -Confirm:$false

Disconnect-rCisServer -Server $cisServer -Confirm:$false
 