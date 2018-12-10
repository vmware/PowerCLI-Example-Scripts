# Fetch Cis Server hostname and credentials
.\CisConfig.ps1

Connect-rCisServer -Server $cisServer -User $cisUser -Password $cisPswd

New-rCisTagCategory -Name MyCat1 -Cardinality Single -Description 'Test Tag Category' -EntityType 'VirtualMachine'
New-rCisTag -Name MyTag1 -Category MyCat1 -Description 'Test Tag'
$vm = Get-VM | Get-Random
New-rCisTagAssignment -Entity $vm -Tag MyTag1

Get-rCisTagAssignment -Tag MyTag1

Disconnect-rCisServer -Server $cisServer -Confirm:$false
 