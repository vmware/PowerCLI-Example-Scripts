function Set-LockdownLevel {
<#
.SYNOPSIS
  Set the Lockdown Level of ESX Hosts if PowerCLI connected to vCenter Server
.PARAMETER VMHost
  The target ESX host 
.PARAMETER Disabled
  Sets the Lockdown level to Disabled
.PARAMETER Normal
  Sets the Lockdown level to Normal
.PARAMETER Strict
  Sets the Lockdown level to Strict
.PARAMETER SuppressWarning
  Removes the messagebox popup verifying you want to proceed
.EXAMPLE
  Set the Lockdown level to Normal on Host 10.144.99.231
  Set-LockdownLevel -VMhost 10.144.99.231 -Normal
.EXAMPLE
  Set all ESX hosts Lockdown level to Disabled
  Get-VMhost | foreach { Set-LockdownLevel $_ -Disabled }
.EXAMPLE
  Sets all ESX hosts Lockdown level to Normal and saves data to CSV, Suppresses warning 
  Get-VMhost | foreach { Set-LockdownLevel $_ -filepath c:\temp\lockdowndata.csv -Disabled -SuppressWarning }
  .NOTES
	===========================================================================
	 Created on:   	3/13/2015 5:55 AM
	 Created by:   	Brian Graf
	 Twitter: @vBrianGraf
	 Email: grafb@vmware.com
	 THIS SCRIPT IS NOT OFFICIALLY SUPPORTED BY VMWARE. USE AT YOUR OWN RISK
	===========================================================================
#>

[CmdletBinding(DefaultParametersetName="Disabled")]
Param(
  [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True)]
  [ValidateNotNullOrEmpty()]
  [string]$VMhost,
	
  [Parameter(Mandatory=$False)]
  [string]$filePath,
   
  [Parameter(ParameterSetName='Disabled')]
  [switch]$Disabled,
	
  [Parameter(ParameterSetName='Normal')]
  [switch]$Normal,
  
  [Parameter(ParameterSetName='Strict')]
  [switch]$Strict,
  
  [switch]$SuppressWarning
)

Process {
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$Actions = @()

#Create an object to store changes and information in
$Historical = New-Object -TypeName PSObject

#Specify the Three parameters to be used
switch ($PsCmdlet.ParameterSetName) {
"Disabled" {$level = "lockdownDisabled"}
"Normal" {$level = "lockdownNormal"}
"Strict" {$level = "lockdownStrict"}
}
Write-Host "you are changing the lockdown mode on host [$VMHost] to $level" -ForegroundColor Yellow
if ((!($SuppressWarning)) -and ($level -ne "lockdownDisabled")) {

$OUTPUT = [System.Windows.Forms.MessageBox]::Show("By changing the Lockdown Mode level you may be locking yourself out of your host. If you understand the risks and would like to continue, click YES. If you wish to Cancel, click NO." , "CAUTION" , 4)

if ($OUTPUT -eq "NO" ) 
{

Throw "User Aborted Lockdown Mode Level Change"

} 
}
#If a Filepath was given, echo that it will save the info to CSV
if ($Filepath) {
Write-Host "Saving current Lockdown Mode level to CSV" -ForegroundColor Yellow}

#Retrieve the VMhost as a view object
$lockdown = Get-View (Get-View -ViewType HostSystem -Filter @{"Name"="$VMHost"}).ConfigManager.HostAccessManager

#Add info to our object
$Historical | Add-Member -MemberType NoteProperty -Name Timestamp -Value (Get-Date -Format g)
$Historical | Add-Member -MemberType NoteProperty -Name Host -Value $VMhost
$Historical | Add-Member -MemberType NoteProperty -Name OriginalValue -Value $lockdown.LockdownMode

#Perform Lockdown Mode change
$lockdown.ChangeLockdownMode($level)

#Refresh View data
$lockdown.UpdateViewData()

#Verify change happened
if ($lockdown.LockdownMode -eq $level) { 
Write-Host "Lockdown Mode Level Updated Successfully on host [$VMHost]" -ForegroundColor Green} else {Write-Host "Uh Oh... Looks like the Lockdown Mode Level did not update for host [$VMHost]" -ForegroundColor Red}
$Historical | Add-Member -MemberType NoteProperty -Name NewValue -Value $lockdown.LockdownMode
$Actions += $Historical

#Export to CSV if filepath was given
if ($filePath) {$Actions | Export-Csv "$filePath" -NoTypeInformation -NoClobber -Append}
}
}
