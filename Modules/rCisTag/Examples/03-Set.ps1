# Fetch Cis Server hostname and credentials
.\CisConfig.ps1

Connect-rCisServer -Server $cisServer -User $cisUser -Password $cisPswd

Get-rCisTag -Name MyTag1 | Set-rCisTag -Name MyNewTag1 -Description 'Name changed'

Get-rCisTagCategory -Name MyCat1 | Set-rCisTagCategory -Cardinality Multiple -Name MyNewCat1 -Description 'Name changed'

Disconnect-rCisServer -Server $cisServer -Confirm:$false
 