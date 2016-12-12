<#
.SYNOPSIS
    A handy multi purpose tool to get those things done quickly
.DESCRIPTION
    This is an onging VMware tool to help those with an VMware environment to automate certain repetative tasks
.NOTES
    File Name      : vTool.ps1
    Author         : gajendra d ambi
    updated        : August 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

##Start of the script##
Clear-Host  #Clear the screen.

#start of function
function PcliPshell 
{
<#
.SYNOPSIS
    Integrate powercli into powershell
.DESCRIPTION
    This will add pssnapins/modules of vmware powercli into powershell. You will get
    powercli core, vds and vum scriptlets/snapsins/modules in powershell which will enable you
    to create, run powercli scripts into powershell ISE since powercli itself lacks an IDE.
.NOTES
    File Name      : PcliPshell.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/MrAmbiG/vmware
#>
#Start of script#
Import-Module VMware.VimAutomation.Core     -ErrorAction SilentlyContinue
Import-Module VMware.VimAutomation.Vds      -ErrorAction SilentlyContinue
Import-Module VMware.VimAutomation.Cis.Core -ErrorAction SilentlyContinue
Import-Module VMware.VimAutomation.Storage  -ErrorAction SilentlyContinue
Import-Module VMware.VimAutomation.vROps    -ErrorAction SilentlyContinue
Import-Module VMware.VimAutomation.HA       -ErrorAction SilentlyContinue
Import-Module VMware.VimAutomation.License  -ErrorAction SilentlyContinue
Import-Module VMware.VimAutomation.Cloud    -ErrorAction SilentlyContinue
Import-Module VMware.VimAutomation.PCloud   -ErrorAction SilentlyContinue
Import-Module VMware.VumAutomation          -ErrorAction SilentlyContinue
#End of Script#
}#End of function

#------------------------------Start of Collection of Functions of automation------------------------------#

#Start of function
function GetPlink 
{
<#
.SYNOPSIS
    Gets the plink
.DESCRIPTION
    This will make sure plink is either downloaded from the internet if it is not present and if it cannot download
    then it will pause the script till you copy it manually.
.NOTES
    File Name      : GetPlink.ps1
    Author         : gajendra d ambi
    Date           : Audust 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: 
    github.com/mrambig
    [source] http://www.virtu-al.net/2013/01/07/ssh-powershell-tricks-with-plink-exe/

#>
$PlinkLocation = $PSScriptRoot + "\Plink.exe"
$presence = Test-Path $PlinkLocation
if (-not $presence) 
    {
    Write-Host "Missing Plink.exe, trying to download...(10 seconds)" -BackgroundColor White -ForegroundColor Black
    Invoke-RestMethod "http://the.earth.li/~sgtatham/putty/latest/x86/plink.exe" -TimeoutSec 10 -OutFile "plink.exe"
    if (-not $presence)
        {
            do
            {
            Write-Host "Unable to download plink.exe, please download and add it to the same folder as this script" -BackgroundColor Yellow -ForegroundColor Black
            Read-host "Hit Enter/Return once plink is present"
            $presence = Test-Path $PlinkLocation
            } while (-not $presence)
        }
    }

if ($presence) { Write-Host "Detected Plink.exe" -BackgroundColor White -ForegroundColor Black }
} #End of function

#start of function
function FaultToleranceOff 
{
<#
.SYNOPSIS
    Enable vMotion
.DESCRIPTION
    Enable vMotion across the Cluster
.NOTES
    File Name      : FaultToleranceOff.ps1
    Author         : gajendra d ambi
    Date           : Feb 2016
    recommended    : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#start of script
$cluster  = Read-Host "name of the cluster[type * to include all clusters]?"
$pg       = Read-Host "name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost | Get-VMHostNetworkAdapter | where PortGroupname -EQ $pg | Set-VMHostNetworkAdapter -FaultToleranceLoggingEnabled $false -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
Function HostPerf 
{
<#
.SYNOPSIS
    Set esxi host performance level
.DESCRIPTION
    This will change the host's performance level to the following.
.NOTES
    File Name      : VssPmOn.ps1
    Author         : gajendra d ambi
    Date           : August 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "choose a number from below
1. High performance
2. Balanced
3. LowPower
" -BackgroundColor White -ForegroundColor Black
$option = Read-Host "?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

foreach ($vmhost in (get-cluster $cluster | get-vmhost | sort)) 
{$vmhost.Name
(Get-View (Get-VMHost $vmhost | Get-View).ConfigManager.PowerSystem).ConfigurePowerPolicy($option)
}

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#Start of function
function NicStatusPg
{
<#
.SYNOPSIS
    Change nic teaming of nics.
.DESCRIPTION
    This will change the nic status on portgroups
.NOTES
    File Name      : NicStatusPg.ps1
    Author         : gajendra d ambi
    Date           : July 2016
    Prerequisite   : PowerShell v4+, powercli 6.3+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/MrAmbiG/vmware
#>
#Start of Script
$cluster = Read-Host "cluster[type * to include all clusters]?"
$pg      = Read-Host "standard portgroup?"
$nic     = Read-Host "vmnic (ex:vmnic5)?"

Write-host "
1 . MakeNicActive
2 . MakeNicStandby
3 . MakeNicUnused
" -BackgroundColor white -ForegroundColor black
Write-Host choose from 1 to 3 from above -BackgroundColor Yellow -ForegroundColor Black
$option = Read-Host " "

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$vmhosts = get-cluster $cluster | get-vmhost | sort

$vmhosts = get-cluster $cluster | get-vmhost | sort
foreach ($vmhost in $vmhosts)
{
$vmnic = get-vmhost $vmhost | Get-VMHostNetworkAdapter -Physical -Name $nic
    if ($option -eq 1) 
    {#MakeNicActive
    get-vmhost $vmhost | get-virtualportgroup -Name $pg | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $vmnic -Confirm:$false
    }
    if ($option -eq 2)
    {#MakeNicStandby
    get-vmhost $vmhost | get-virtualportgroup -Name $pg | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicStandby $vmnic -Confirm:$false
    }
    if ($option -eq 3)
    {#MakeNicUnused
    get-vmhost $vmhost | get-virtualportgroup -Name $pg | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicUnused $vmnic -Confirm:$false
    }
}
} #end of function

#start of function
function NicStatusVss
{
<#
.SYNOPSIS
    Change nic teaming of nics.
.DESCRIPTION
    This will change the nic status on vSwitchs
.NOTES
    File Name      : NicStatusVss.ps1
    Author         : gajendra d ambi
    Date           : July 2016
    Prerequisite   : PowerShell v4+, powercli 6.3+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/MrAmbiG/vmware
#>

#Start of Script
$cluster = Read-Host "cluster[type * to include all clusters]?"
$vss     = Read-Host "vSphere standard Switch?"
$nic     = Read-Host "vmnic (ex:vmnic5)?"

Write-host "
1 . Add Nic
2 . Remove Nic
3 . MakeNicActive
4 . MakeNicStandby
5 . MakeNicUnused
" -BackgroundColor white -ForegroundColor black
Write-Host choose from 1 to 5 from above -BackgroundColor Yellow -ForegroundColor Black
$option = Read-Host " "


$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$vmhosts = get-cluster $cluster | get-vmhost | sort
foreach ($vmhost in $vmhosts)
{
$vmnic = get-vmhost $vmhost | Get-VMHostNetworkAdapter -Physical -Name $nic
    if ($option -eq 1 ) 
    {
    #add vmnic
    get-vmhost $vmhost | get-virtualswitch -Name $vss | Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $vmnic -confirm:$false
    get-vmhost $vmhost | get-virtualswitch -Name $vss | Get-NicTeamingPolicy
    }
    
    if ($option -eq 2 ) 
    {
    #remove vmnic
    get-vmhost $vmhost | Get-VMHostNetworkAdapter -Physical -Name $nic | Remove-VirtualSwitchPhysicalNetworkAdapter -confirm:$false
    get-vmhost $vmhost | get-virtualswitch -Name $vss | Get-NicTeamingPolicy
    }
    
    if ($option -eq 3 ) 
    {
    #Make active
    Get-VMHost $vmhost | get-virtualswitch -Name $vss | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive $vmnic -confirm:$false
    }
    
    if ($option -eq 4 ) 
    {
    #make standby
    Get-VMHost $vmhost | get-virtualswitch -Name $vss | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicStandby $vmnic -confirm:$false
    }
    
    if ($option -eq 5 ) 
    {
    #make unused
    Get-VMHost $vmhost | get-virtualswitch -Name $vss | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicUnused $vmnic -confirm:$false
    }
}
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function WinSSH
{
<#
.SYNOPSIS
    Run SSH commands from windows
.DESCRIPTION
    This will run commands to be run on VMware/vCenter hosts.
    This needs plink to be in the same folder as this script.
    This will open create a text file, you paste the commands which are to be run on the SSH target.        
.NOTES
    File Name      : WinSSH.ps1
    Author         : gajendra d ambi
    Date           : June 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/MrAmbiG/vmware
    http://www.virtu-al.net/2013/01/07/ssh-powershell-tricks-with-plink-exe/
#>
#Start of Script
GetPlink #custom function gets plink.exe #https://github.com/MrAmbiG/vmware/blob/master/vTool/vToolMenus/MainMenu/vCenterMenu/HostMenu/GetPlink.ps1

#server's credentials
$user     = Read-Host "Host's username?"
$pass     = Read-Host "Host's password?"
$cluster  = Read-Host "name of the cluster[type * to include all clusters]?"
$VMHosts  = get-cluster $cluster | Get-VMHost | sort

#copy plink to c:\ for now
Copy-Item $PSScriptRoot\plink.exe C:\

$name     = "commands"
$commands = "$PSScriptRoot\$name.txt" #create text file
ni -ItemType file $commands -Force
ac $commands "#Paste your each command in a new line which you want to run on each host"
Start-Process $commands

Read-Host "Hit Return/Enter once you are done copying the commands to the pop up text"

$stopWatch = [system.diagnostics.stopwatch]::startNew() #timer start
$stopWatch.Start()

$lines = gc $commands

Copy-Item $PSScriptRoot\plink.exe C:\ #copy plink to c:\ for now

ForEach ($VMHost in $VMHosts)
    {
    Write-Host $vmhost.Name -ForegroundColor Black -BackgroundColor White
    Get-VMHost $VMHost | Get-VMHostService | where {$_.Key -eq "TSM-SSH"} | Start-VMHostService -confirm:$false #start ssh    
    echo y | C:\plink.exe -ssh $user@$VMHost -pw $pass "exit" #store ssh keys    
    foreach ($line in $lines)
        {
        C:\plink.exe -ssh -v -noagent $VMHost -l $user -pw $pass "$line"
        }    
    Get-VMHost $VMHost | Get-VMHostService | where {$_.Key -eq "TSM-SSH"} | Stop-VMHostService -confirm:$false #stop ssh
    }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function DrsVmGroup 
{
<#
.SYNOPSIS
    Create DrsVmGroup DRS Rule.
.DESCRIPTION
    This uses custom functions to create DRS DrsVmGroup rules between VMs where VMs will be made to stay on the same host by the DRS.
.NOTES
    File Name      : DrsVmGroup.ps1
    Author         : gajendra d ambi
    Date           : February 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script
$cluster     = Read-Host "Name of the Cluster?"
$VMs         = Read-Host "Type the Name of the VM/VMs (separated only by a comma and no spaces)"
$VMs         = $VMs.split(',')
$vmgroup     = Read-Host "Type the Name of the VM group"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-VM $VMs | New-DrsVmGroup -Name $vmgroup -Cluster $cluster

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function shAddNic 
{
<#
.SYNOPSIS
    Create New VMware Standard Switch on all hosts
.DESCRIPTION
    This will need the 1st host's ip address and the number of subsequent hosts that you want to configure(which should be in series of the ip address).
    Lets say you have 10 esxi hosts and the 1st host's ip is 1.1.1.1 then you have to provide the 1st host's ip address and the number of hosts
    as an input to this script which will do +1 to the last octet of the 1st host's ip address and connect to all the 10 hosts and 
    Then it will add physical nics to the standard switch.
.NOTES
    File Name      : shAddNic.ps1
    Author         : gajendra d ambi
    Date           : April 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$vss     = Read-Host "name of the vSphere standard Switch?"
$newnic  = Read-Host "Name of the Nic (ex:vmnic5)?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

foreach ($vmhost in (get-cluster $cluster | get-vmhost | sort)) {
 $vmnic = get-vmhost $vmhost | Get-VMHostNetworkAdapter -Physical -Name $newnic
 get-vmhost $vmhost | get-virtualswitch -Name $vss | Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $vmnic -confirm:$false
 }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function l3vmotion
{
<#
.SYNOPSIS
    Configure l3 vmotion.
.DESCRIPTION
    It will
    create the l3 vmotion portgroup
    add vmk to the portgroup
    assign vlan to the portgroup
    add ip, subnet mask to the portgroup
    enable netstack l3 vmotion for the portgroup
    1. update the default gateway manually for now
.NOTES
    File Name      : l3vmotion.ps1
    Author         : gajendra d ambi
    Date           : June 2016
    Prerequisite   : PowerShell v4+, powercli 6.3+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/MrAmbiG/vmware
    https://communities.vmware.com/thread/519794?start=0&tstart=0 (inok)
#>
#Start of Script
Write-Host "
Don't forget to add gateway after it's completion
" -BackgroundColor White -ForegroundColor Black

$cluster = Read-Host "Name of the cluster?"
$vss     = Read-Host "Name of the vSwitch?"
$pg      = Read-Host "name of the portgroup?"
$vlan    = Read-Host "vlan?"
$ip      = Read-Host "What is the 1st vmkernel ip address?"
$mask    = Read-Host "subnet mask?"
$vmk     = Read-Host "vmk number? ex: vmk7?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$a     = $ip.Split('.')[0..2]   
#first 3 octets of the ip address
$b     = [string]::Join(".",$a)

#last octet of the ip address
$c     = $ip.Split('.')[3]
$c     = [int]$c

$vmhosts = get-cluster $cluster | get-vmhost | sort
foreach ($vmhost in $vmhosts)
 {
 Get-VMHost $vmhost | Get-VirtualSwitch -Name $vss | New-VirtualPortGroup $pg -VLanId $vlan -Confirm:$false #creating new VM portgroup
 $esxcli  = get-vmhost $vmhost | get-esxcli
 $esxcli.network.ip.netstack.add($false, "vmotion") #enabling and adding vmotion tcp/ip stack (netstack)
 $esxcli.network.ip.interface.add($null, $null, "$vmk", $null, "1500", "vmotion", "$pg")
 $esxcli.network.ip.interface.ipv4.set("$vmk", "$b.$(($c++))", "$mask", $null, "static") #update ip informaiton to the vmk
 }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

##start of function
function shGetShHosts 
{
<#
.SYNOPSIS
    Connect to standalone hosts
.DESCRIPTION
    This will get the 1st host's ip address and increment it to a number specified by the user and connect to all of them.
.NOTES
    File Name      : shGetShHosts.ps1
    Author         : gajendra d ambi
    Date           : April 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#

$1sthost  = Read-Host "1st host's ip address?"
$max      = Read-Host "total number of esxi hosts that you want to configure?"
$user     = Read-Host "ESXi username?"
$pass     = Read-Host "ESXi password?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

#generate the range of ip addresses of hosts
$fixed = $1sthost.Split('.')[0..2]
$last = [int]($1sthost.Split('.')[3])
$maxhosts = $max - 1
$hosts = 
$last..($last + $maxhosts) | %{
    [string]::Join('.',$fixed) + "." + $_
}

#connect to all hosts
connect-viserver $hosts -User $user -Password $pass

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
}#End of function

#start of function
function shShootVmPg 
{
<#
.SYNOPSIS
    Create New VMware Standard Switch on all hosts
.DESCRIPTION
    This will need the 1st host's ip address and the number of subsequent hosts that you want to configure(which should be in series of the ip address).
    Lets say you have 10 esxi hosts and the 1st host's ip is 1.1.1.1 then you have to provide the 1st host's ip address and the number of hosts
    as an input to this script which will do +1 to the last octet of the 1st host's ip address and connect to all the 10 hosts and 
    Then it will Remove VM portgroup.
.NOTES
    File Name      : shShootVmPg.ps1
    Author         : gajendra d ambi
    Date           : April 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$pg      = Read-Host "Name of the portgroup?"
$pg      = Read-Host "Name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-VMHost | Get-VirtualPortGroup -Name $pg | Remove-VirtualPortGroup -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
function ShootVmkPg
{
<#
.SYNOPSIS
    Remove vmkernel portgroup
.DESCRIPTION
    This will remove the virtual machine portgroup of all the hosts of a cluster/clusters.
.NOTES
    File Name      : ShootVmkPg.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$pg      = Read-Host "Name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 foreach ($vmhost in (get-cluster $cluster | get-vmhost | sort)) 
 {
  $vmk = Get-VMHostNetworkAdapter -VMHost $vmhost | where PortgroupName -eq $pg
  Write-Host "removing vmkernel from the $pg on $vmhost"
  Remove-VMHostNetworkAdapter -Nic $vmk -confirm:$false
 
  Write-Host "removing $pg on $vmhost"
  get-vmhost $vmhost | get-virtualportgroup -Name $pg | Remove-VirtualPortGroup -Confirm:$false 
 }
 
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
function shRenamePg 
{
<#
.SYNOPSIS
    Create New VMware Standard Switch on all hosts
.DESCRIPTION
    This will need the 1st host's ip address and the number of subsequent hosts that you want to configure(which should be in series of the ip address).
    Lets say you have 10 esxi hosts and the 1st host's ip is 1.1.1.1 then you have to provide the 1st host's ip address and the number of hosts
    as an input to this script which will do +1 to the last octet of the 1st host's ip address and connect to them all the 10 hosts.
    Then it will rename the esxi host's portgroup.
.NOTES
    File Name      : shRenamePg.ps1
    Author         : gajendra d ambi
    Date           : April 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$oldpg   = Read-Host "Old Name of the portgroup?"
$newpg   = Read-Host "New Name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-VMHost | Get-VirtualPortGroup -Name $oldpg | Set-VirtualPortGroup -Name $newpg -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function shNewVss 
{
<#
.SYNOPSIS
    Create New VMware Standard Switch on all hosts
.DESCRIPTION
    This will need the 1st host's ip address and the number of subsequent hosts that you want to configure(which should be in series of the ip address).
    Lets say you have 10 esxi hosts and the 1st host's ip is 1.1.1.1 then you have to provide the 1st host's ip address and the number of hosts
    as an input to this script which will do +1 to the last octet of the 1st host's ip address and connect to all of the 10 hosts.
    Then it will create a new vswitch based on your input.
.NOTES
    File Name      : shNewVss.ps1
    Author         : gajendra d ambi
    Date           : April 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$vss = Read-Host "name of the vSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

get-vmhost | New-VirtualSwitch -Name $vss -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

##start of function
function shNewVMPg 
{
<#
.SYNOPSIS
    Create New VMware Standard Swiportgroup on all hosts
.DESCRIPTION
    This will need the 1st host's ip address and the number of subsequent hosts that you want to configure(which should be in series of the ip address).
    Lets say you have 10 esxi hosts and the 1st host's ip is 1.1.1.1 then you have to provide the 1st host's ip address and the number of hosts
    as an input to this script which will do +1 to the last octet of the 1st host's ip address and  connect to all of the 10 hosts and 
    Then it will create a new virtual machine portgroup based on your input.
.NOTES
    File Name      : shNewVMPg.ps1
    Author         : gajendra d ambi
    Date           : April 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$vss  = Read-Host "name of the vSwitch?"
$pg   = Read-Host "name of the portgroup?"
$vlan = Read-Host "vlan?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

get-vmhost | Get-VirtualSwitch -Name $vss | New-VirtualPortGroup -Name $pg -VLanId $vlan -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
function shNewVMkernelPg 
{
<#
.SYNOPSIS
    Create New VMware Standard Swiportgroup on all hosts
.DESCRIPTION
    This will need the 1st host's ip address and the number of subsequent hosts that you want to configure(which should be in series of the ip address).
    Lets say you have 10 esxi hosts and the 1st host's ip is 1.1.1.1 then you have to provide the 1st host's ip address and the number of hosts
    as an input to this script which will do +1 to the last octet of the 1st host's ip address and connect to all of the 10 hosts and 
    Then it will create a new vmkernel portgroup based on your input.
.NOTES
    File Name      : shNewVMkernelPg.ps1
    Author         : gajendra d ambi
    Date           : April 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$vss  = Read-Host "name of the vSwitch?"
$pg   = Read-Host "name of the portgroup?"
$vlan = Read-Host "vlan?"

$ip    = Read-Host "What is the 1st vmkernel ip address?"
$mask  = Read-Host "subnet mask?"
$vmk   = Read-Host "vmk number? ex: vmk7?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

get-vmhost | Get-VirtualSwitch -Name $vss | New-VirtualPortGroup -Name $pg -VLanId $vlan -Confirm:$false

$a     = $ip.Split('.')[0..2]   
#first 3 octets of the ip address
$b     = [string]::Join(".",$a)

#last octet of the ip address
$c     = $ip.Split('.')[3]
$c     = [int]$c

 foreach ($vmhost in (get-vmhost | sort)){
 $esxcli = get-vmhost $vmhost | Get-EsxCli
 $esxcli.network.ip.interface.add($null, $null, "$vmk", $null, "1500", $null, "$pg") #add vmkernel to the portgroup
 $esxcli.network.ip.interface.ipv4.set("$vmk", "$b.$(($c++))", "$mask", $null, "static") #update ip informaiton to the vmkernel

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 }#End of Script#
}#End of function

#start of function
function shShootVmkPg 
{
<#
.SYNOPSIS
    Create New VMware Standard Switch on all hosts
.DESCRIPTION
    This will need the 1st host's ip address and the number of subsequent hosts that you want to configure(which should be in series of the ip address).
    Lets say you have 10 esxi hosts and the 1st host's ip is 1.1.1.1 then you have to provide the 1st host's ip address and the number of hosts
    as an input to this script which will do +1 to the last octet of the 1st host's ip address and connect to all the 10 hosts and 
    Then it will Remove vmkernel portgroup.
.NOTES
    File Name      : ShootVmkPg.ps1
    Author         : gajendra d ambi
    Date           : April 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$pg      = Read-Host "Name of the portgroup?"
 foreach ($vmhost in (get-vmhost | sort)) 
 {
  $vmk = Get-VMHostNetworkAdapter -VMHost $vmhost | where PortgroupName -eq $pg
  Write-Host "removing vmkernel from the $pg on $vmhost"
  Remove-VMHostNetworkAdapter -Nic $vmk -confirm:$false
 
  Write-Host "removing $pg on $vmhost"
  get-vmhost $vmhost | get-virtualportgroup -Name $pg | Remove-VirtualPortGroup -Confirm:$false 
 }#End of Script#
}#End of function

#start of function
function PgSync
{
<#
.SYNOPSIS
    Sync portgroups properties with vSwitch
.DESCRIPTION
    This will make the portgroup to sync itself with the vswitch's settings. this will make the portgroup inherit the following from the vSwitch
    LoadBalancingPolicy
    NetworkFailoverDetectionPolicy
    NotifySwitches
    FailoverOrder
.NOTES
    File Name      : PowerMgmt.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster   = Read-Host "name of the cluster[type * to include all clusters]?"
$pg        = Read-Host "name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

get-cluster $cluster | Get-VMHost | sort | Get-virtualswitch -Standard | Get-VirtualPortGroup -Name $pg | get-nicteamingpolicy | Set-NicTeamingPolicy -InheritLoadBalancingPolicy $true -InheritNetworkFailoverDetectionPolicy $true -InheritNotifySwitches $true -InheritFailback $true -InheritFailoverOrder $true -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function AddHosts 
{
<#
.SYNOPSIS
    Add hosts to cluster.
.DESCRIPTION
    This will add hosts to the specified clusters. The function will create a csv file which can be opened in excel.
    populate the values under their respective headers in the excel. save it. close it. Hit return/enter to proceed.
    Then the script will use the values from csv file and add hosts to the cluster(s).
.NOTES
    File Name      : AddHosts.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script

Write-Host "
A CSV file will be opened (open in excel/spreadsheet)
populate the values,
save & close the file,
Hit Enter to proceed
" -ForegroundColor Blue -BackgroundColor White
$csv = "$PSScriptRoot/addhosts.csv"
get-process | Select-Object cluster,hostname,username,password | Export-Csv -Path $csv -Encoding ASCII -NoTypeInformation
Start-Process $csv
Read-Host "Hit Enter/Return to proceed"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$csv = Import-Csv $csv
 foreach ($line in $csv) 
 {
  $cluster = $($line.cluster)
  $vmhost  = $($line.hostname)
  $user    = $($line.username)
  $pass    = $($line.password)
  Add-VMHost $vmhost -Location (get-cluster -Name $cluster) -User $user -Password $pass -Force -Confirm:$false 
 }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script
} #End of function
 
#start of function
Function ConfigHA 
{
<#
.SYNOPSIS
    Configure HA on the cluster.
.DESCRIPTION
    This will configure Ha on a specified cluster. It will
    enable HA
    disable admission control if the number of hosts is less than or equal to 3
    set the vm monitoring policy.
.NOTES
    File Name      : ConfigHA.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script

$cluster = Read-Host "name of the cluster?"
$HARestartPriority = Read-Host "
choose one of the following as your VM (HA) Restart Priority
0. ClusterRestartPriority
1. Disabled
2. Low
3. Medium (Recommended)
4. High
" -ForegroundColor Blue -BackgroundColor White

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

get-cluster $cluster | Set-Cluster -HAEnabled:$true

if ($HARestartPriority -eq 0 ) { get-cluster $cluster | set-cluster -HARestartPriority ClusterRestartPriority -Confirm:$false }
if ($HARestartPriority -eq 1 ) { get-cluster $cluster | set-cluster -HARestartPriority Disabled               -Confirm:$false }
if ($HARestartPriority -eq 2 ) { get-cluster $cluster | set-cluster -HARestartPriority Low                    -Confirm:$false }
if ($HARestartPriority -eq 3 ) { get-cluster $cluster | set-cluster -HARestartPriority Medium                 -Confirm:$false }
if ($HARestartPriority -eq 4 ) { get-cluster $cluster | set-cluster -HARestartPriority High                   -Confirm:$false }

if ((Get-Cluster $cluster | Get-VMHost).count -lt 4) { Get-Cluster $cluster | Set-Cluster -HAAdmissionControlEnabled:$false }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script
}#End of function

#start of function
Function CreateCluster 
{
<#
.SYNOPSIS
    Create CreateCluster DRS Rule.
.DESCRIPTION
    This uses custom functions to create DRS CreateCluster rules between VMs where VMs will be made to stay on the same host by the DRS.
.NOTES
    File Name      : CreateCluster.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script
$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 $cluster = Read-Host "Name of the Cluster?"
 if ((Get-datacenter).count -gt 1) {
 $dc      = Read-Host "name of the datacenter?"
 get-datacenter -Name $dc | New-Cluster -Name $cluster -Confirm:$false
 }

 if ((Get-datacenter).count -eq 1) {
 get-datacenter | New-Cluster -Name $cluster -Confirm:$false
 }

 if ((Get-datacenter).count -eq 0) {
 Write-Host "Please create a datacenter first" -ForegroundColor DarkYellow -BackgroundColor White
 }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script
} #End of function

#start of function
Function CreateVapp 
{
<#
.SYNOPSIS
    Create new vApp.
.DESCRIPTION
    This will create vApp in a cluster. It is very easy and less time consuming to do manually but
    the motto here is 'manual is an evil when you are automating' and most importantly in future this might have more options where
    you can add VMs and control the startup/shutdown order of VMs.
.NOTES
    File Name      : CreateVapp.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script
$cluster = Read-Host "name of the cluster?"
$vapp    = Read-Host "Name of the vApp?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

New-VApp -Name $vapp -Location (get-cluster $cluster) -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script
}#End of function


#start of function
Function AddDatastores 
{
<#
.SYNOPSIS
    Add datastores to a cluster.
.DESCRIPTION
    This will create a csv file whcih is opened in excel. Once you popuate the details, you have to save & close it. 
    Hit return/enter to proceed and the script will 
    add the datastores to the 1st host of the cluster
    rescan all the hosts of the cluster
.NOTES
    File Name      : AddDatastores.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script

New-VIProperty -Name "Runtime" -ObjectType "ScsiLun" -Value {
  param($scsilun)
  #http://www.lucd.info/2010/10/17/runtime-name-via-extensiondata-and-new-viproperty/
  #twitter/lucd22
  #many a times (for some storages) runtime is empty, thus using this scriptlet to populate/repopulate the same
  $storDev = $scsilun.VMHost.ExtensionData.Config.StorageDevice
  $key = ($storDev.PlugStoreTopology.Device | where {$_.Lun -eq $scsilun.Key}).Key
  $stordev.PlugStoreTopology.Path | where {$_.Device -eq $key} | %{
    $device = $_
    $adapterKey = ($stordev.PlugStoreTopology.Adapter | where {$_.Key -eq $device.Adapter}).Adapter
    $adapter = ($stordev.HostBusAdapter | where {$_.Key -eq $adapterKey}).Device
    $adapter + ":C" + $device.ChannelNumber + ":T" + $device.TargetNumber + ":L" + $device.LunNumber
  }
} -Force


Write-Host "
A CSV file will be opened (open in excel/spreadsheet)
populate the values,
save & close the file,
Hit Enter to proceed
" -ForegroundColor Blue -BackgroundColor White
$csv = "$PSScriptRoot/AddLuns.csv"
get-process | Select-Object Cluster,LunID,DatastoreName,vmhba | Export-Csv -Path $csv -Encoding ASCII -NoTypeInformation
Start-Process $csv
Read-Host "Hit Enter/Return to proceed"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$csv = Import-Csv $csv
 foreach ($line in $csv) #using trim() to make sure unnecessary spaces before or after any values in the csv files are removed
 {
  $cluster = $($line.Cluster)
  $cluster = $cluster.trim()

  $lunid   = $($line.LunID)
  $lunid   = $lunid.trim()

  $ds      = $($line.DatastoreName)
  $ds      = $ds.trim()

  $vmhba   = $($line.vmhba)
  $runtime = ":C0:T0:L$lunid"
  $runtime = $vmhba+$runtime
  $vmhost  = (get-cluster $cluster | get-vmhost)[0]
  $naa     = (Get-SCSILun -VMhost $vmhost -LunType Disk | where Runtime -eq $runtime).CanonicalName
  New-Datastore -VMHost $vmhost -Name $ds -Path $naa -vmfs -Confirm:$false
 }

 $cluster = $csv.Cluster | get-unique
 get-cluster $cluster | get-vmhost | Get-VMHostStorage -RescanAllHba

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script
}#End of function
 
#start of function
Function ConfigDrs 
{
<#
.SYNOPSIS
    Configure DRS on the cluster.
.DESCRIPTION
    This will configure DRS on a specified cluster.
.NOTES
    File Name      : ConfigDrs.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script

$cluster = Read-Host "name of the cluster?"
Write-Host "
choose the DRS Mode
1. FullyAutomated
2. Manual
3. PartiallyAutomated
" -ForegroundColor Blue -BackgroundColor White
$DrsLevel = Read-Host "type 1 or 2 or 3"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

if ($DrsLevel -eq 1) { $DrsLevel = "FullyAutomated" }
if ($DrsLevel -eq 2) { $DrsLevel = "Manual" }
if ($DrsLevel -eq 3) { $DrsLevel = "PartiallyAutomated" }

Get-Cluster $cluster | Set-Cluster -DrsEnabled:$true -DrsAutomationLevel $DrsLevel -confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script
}#End of function


#start of function
Function VMAffinity 
{
<#
.SYNOPSIS
    Create VMAffinity DRS Rule.
.DESCRIPTION
    This uses custom functions to create DRS VMAffinity rules between VMs where VMs will be made to stay on the same host by the DRS.
.NOTES
    File Name      : VMAffinity.ps1
    Author         : gajendra d ambi
    Date           : February 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script
$cluster = Read-Host "Name of the Cluster?"
$drsrule = Read-Host "Type the Name of the DRS Rule"
$vms     = Read-Host "Name of the VMs (separated by comma, no space)?"
$vms     = $vms.split(',')

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

New-DrsRule –Name $drsrule -Cluster $cluster –KeepTogether $true –VM $vms

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script
}#End of function

Function New-DrsVmGroup {
<#
.SYNOPSIS
  Creates a new DRS VM group
.DESCRIPTION
  This function creates a new DRS VM group in the DRS Group Manager
.NOTES
  Author: Arnim van Lieshout
.PARAMETER VM
  The VMs to add to the group. Supports objects from the pipeline.
.PARAMETER Cluster
  The cluster to create the new group on.
.PARAMETER Name
  The name for the new group.
.EXAMPLE
  PS> Get-VM VM001,VM002 | New-DrsVmGroup -Name "VmGroup01" -Cluster CL01
.EXAMPLE
  PS> New-DrsVmGroup -VM VM001,VM002 -Name "VmGroup01" -Cluster (Get-CLuster CL01)
#>
 
    Param(
    #http://www.van-lieshout.com/2011/06/drs-rules/
    #Arnim van Lieshout
        [parameter(valuefrompipeline = $true, mandatory = $true,
        HelpMessage = "Enter a vm entity")]
            [PSObject]$VM,
        [parameter(mandatory = $true,
        HelpMessage = "Enter a cluster entity")]
            [PSObject]$Cluster,
        [parameter(mandatory = $true,
        HelpMessage = "Enter a name for the group")]
            [String]$Name)
 
    begin {
        switch ($Cluster.gettype().name) {
            "String" {$cluster = Get-Cluster $cluster | Get-View}
            "ClusterImpl" {$cluster = $cluster | Get-View}
            "Cluster" {}
            default {throw "No valid type for parameter -Cluster specified"}
        }
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $group = New-Object VMware.Vim.ClusterGroupSpec
        $group.operation = "add"
        $group.Info = New-Object VMware.Vim.ClusterVmGroup
        $group.Info.Name = $Name
    }
 
    Process {
        switch ($VM.gettype().name) {
            "String" {Get-VM -Name $VM | %{$group.Info.VM += $_.Extensiondata.MoRef}}
            "VirtualMachineImpl" {$group.Info.VM += $VM.Extensiondata.MoRef}
            "VirtualMachine" {$group.Info.VM += $VM.MoRef}
            default {throw "No valid type for parameter -VM specified"}
        }
    }
 
    End {
        if ($group.Info.VM) {
            $spec.GroupSpec += $group
            $cluster.ReconfigureComputeResource_Task($spec,$true)
        }
        else {
            throw "No valid VMs specified"
        }
    }

}

#start of function
Function DrsHostGroup 
{
<#
.SYNOPSIS
    Create DrsHostGroup DRS Rule.
.DESCRIPTION
    This uses custom functions to create DRS DrsHostGroup rules between VMs where VMs will be made to stay on the same host by the DRS.
.NOTES
    File Name      : DrsHostGroup.ps1
    Author         : gajendra d ambi
    Date           : February 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script
$cluster    = Read-Host "Name of the Cluster?"
$vmhosts    = Read-Host "Type the Name of the host/hosts (separated only by a comma and no spaces)"
$vmhosts    = $vmhosts.split(',')
$hostgroup  = Read-Host "Type the Name of the Hostgroup"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost $vmhosts | New-DrsHostGroup -Name $hostgroup

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script
}#End of function

#start of function
Function DrsHostGroup 
{
<#
.SYNOPSIS
    Create DrsHostGroup DRS Rule.
.DESCRIPTION
    This uses custom functions to create DRS DrsHostGroup rules between VMs where VMs will be made to stay on the same host by the DRS.
.NOTES
    File Name      : DrsHostGroup.ps1
    Author         : gajendra d ambi
    Date           : February 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script
$cluster    = Read-Host "Name of the Cluster?"
$vmhosts    = Read-Host "Type the Name of the host/hosts (separated only by a comma and no spaces)"
$vmhosts    = $vmhosts.split(',')
$hostgroup  = Read-Host "Type the Name of the Hostgroup"
Get-Cluster $cluster | Get-VMHost $vmhosts | New-DrsHostGroup -Name $hostgroup

#End of Script
}#End of function

#start of function
Function DRSVMToHostRule 
{
<#
.SYNOPSIS
    Create DRSVMToHostRule DRS Rule.
.DESCRIPTION
    This uses custom functions to create DRS DRSVMToHostRule rules between VMs where VMs will be made to stay on the same host by the DRS.
.NOTES
    File Name      : DRSVMToHostRule.ps1
    Author         : gajendra d ambi
    Date           : February 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script
$cluster    = Read-Host "Name of the Cluster?"
$drsrule    = Read-Host "Type the Name of the DRS Rule"
$vmgroup    = Read-Host "Type the Name of the VM group"
$hostgroup  = Read-Host "Type the Name of the Hostgroup"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

New-DrsVMToHostRule -VMGroup $vmgroup -HostGroup $hostgroup -Name $drsrule -Cluster $cluster -AntiAffine -Mandatory

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
Function VMAntiAffinity 
{
<#
.SYNOPSIS
    Create VMAntiAffinity DRS Rule.
.DESCRIPTION
    This uses custom functions to create DRS VMAntiAffinity rules between VMs where VMs will be made to stay on different hosts by the DRS.
.NOTES
    File Name      : VMAntiAffinity.ps1
    Author         : gajendra d ambi
    Date           : February 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script
$cluster = Read-Host "Name of the Cluster?"
$drsrule = Read-Host "Type the Name of the DRS Rule"
$vms     = Read-Host "Name of the VMs (separated by comma, no space)?"
$vms     = $vms.split(',')

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

New-DrsRule –Name $drsrule -Cluster $cluster –KeepTogether $false –VM $vms

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script
}#End of function

Function New-DRSVMToHostRule {
<#
.SYNOPSIS
  Creates a new DRS VM to host rule
.DESCRIPTION
  This function creates a new DRS vm to host rule
.NOTES
  Author: Arnim van Lieshout
.PARAMETER VMGroup
  The VMGroup name to include in the rule.
.PARAMETER HostGroup
  The VMHostGroup name to include in the rule.
.PARAMETER Cluster
  The cluster to create the new rule on.
.PARAMETER Name
  The name for the new rule.
.PARAMETER AntiAffine
  Switch to make the rule an AntiAffine rule. Default rule type is Affine.
.PARAMETER Mandatory
  Switch to make the rule mandatory (Must run rule). Default rule is not mandatory (Should run rule)
.EXAMPLE
  PS> New-DrsVMToHostRule -VMGroup "VMGroup01" -HostGroup "HostGroup01" -Name "VMToHostRule01" -Cluster CL01 -AntiAffine -Mandatory
#>
 
    Param(
    #http://www.van-lieshout.com/2011/06/drs-rules/
    #Arnim van Lieshout
        [parameter(mandatory = $true,
        HelpMessage = "Enter a VM DRS group name")]
            [String]$VMGroup,
        [parameter(mandatory = $true,
        HelpMessage = "Enter a host DRS group name")]
            [String]$HostGroup,
        [parameter(mandatory = $true,
        HelpMessage = "Enter a cluster entity")]
            [PSObject]$Cluster,
        [parameter(mandatory = $true,
        HelpMessage = "Enter a name for the group")]
            [String]$Name,
            [Switch]$AntiAffine,
            [Switch]$Mandatory)
 
    switch ($Cluster.gettype().name) {
        "String" {$cluster = Get-Cluster $cluster | Get-View}
        "ClusterImpl" {$cluster = $cluster | Get-View}
        "Cluster" {}
        default {throw "No valid type for parameter -Cluster specified"}
    }
 
    $spec = New-Object VMware.Vim.ClusterConfigSpecEx
    $rule = New-Object VMware.Vim.ClusterRuleSpec
    $rule.operation = "add"
    $rule.info = New-Object VMware.Vim.ClusterVmHostRuleInfo
    $rule.info.enabled = $true
    $rule.info.name = $Name
    $rule.info.mandatory = $Mandatory
    $rule.info.vmGroupName = $VMGroup
    if ($AntiAffine) {
        $rule.info.antiAffineHostGroupName = $HostGroup
    }
    else {
        $rule.info.affineHostGroupName = $HostGroup
    }
    $spec.RulesSpec += $rule
    $cluster.ReconfigureComputeResource_Task($spec,$true)

}

Function New-DrsHostGroup
{
<#
.SYNOPSIS
  Creates a new DRS host group
.DESCRIPTION
  This function creates a new DRS host group in the DRS Group Manager
.NOTES
  Author: Arnim van Lieshout
.PARAMETER VMHost
  The hosts to add to the group. Supports objects from the pipeline.
.PARAMETER Cluster
  The cluster to create the new group on.
.PARAMETER Name
  The name for the new group.
.EXAMPLE
  PS> Get-VMHost ESX001,ESX002 | New-DrsHostGroup -Name "HostGroup01" -Cluster CL01
.EXAMPLE
  PS> New-DrsHostGroup -Host ESX001,ESX002 -Name "HostGroup01" -Cluster (Get-CLuster CL01)
#>
 
    Param(
    #http://www.van-lieshout.com/2011/06/drs-rules/
    #Arnim van Lieshout
        [parameter(valuefrompipeline = $true, mandatory = $true,
        HelpMessage = "Enter a host entity")]
            [PSObject]$VMHost,
        [parameter(mandatory = $true,
        HelpMessage = "Enter a cluster entity")]
            [PSObject]$Cluster,
        [parameter(mandatory = $true,
        HelpMessage = "Enter a name for the group")]
            [String]$Name)
 
    begin {
        switch ($Cluster.gettype().name) {
            "String" {$cluster = Get-Cluster $cluster | Get-View}
            "ClusterImpl" {$cluster = $cluster | Get-View}
            "Cluster" {}
            default {throw "No valid type for parameter -Cluster specified"}
        }
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $group = New-Object VMware.Vim.ClusterGroupSpec
        $group.operation = "add"
        $group.Info = New-Object VMware.Vim.ClusterHostGroup
        $group.Info.Name = $Name
    }
 
    Process {
        switch ($VMHost.gettype().name) {
            "String" {Get-VMHost -Name $VMHost | %{$group.Info.Host += $_.Extensiondata.MoRef}}
            "VMHostImpl" {$group.Info.Host += $VMHost.Extensiondata.MoRef}
            "HostSystem" {$group.Info.Host += $VMHost.MoRef}
            default {throw "No valid type for parameter -VMHost specified"}
        }
    }
 
    End {
        if ($group.Info.Host) {
            $spec.GroupSpec += $group
            $cluster.ReconfigureComputeResource_Task($spec,$true)
        }
        else {
            throw "No valid hosts specified"
        }
    }

} 

#start of function
function SetDNS 
{
<#
.SYNOPSIS
    Update DNS
.DESCRIPTION
    This will update the DNS, domain and searchdomain for the esxi hosts.
.NOTES
    File Name      : SetDNS.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "This new values will replace the existing values, hence add all the values" -ForegroundColor Yellow 
$dnsadd  = Read-Host "DNS Addresses(separate multiple entries with a comma)?"
$dnsadd  = $dnsadd.split(',')
$domain  = Read-Host "domain name?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

get-cluster $cluster | get-vmhost | Get-VMHostNetwork | Set-VMHostNetwork -DnsAddress $dnsadd -DomainName $domain -SearchDomain $domain -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#Start of function
function CoreDump 
{
<#
.SYNOPSIS
    configure Coredump on esxi hosts
.DESCRIPTION
    This will check the version of the esxi and based on the version of it, it will set the coredump settings on the host
.NOTES
    File Name      : CoreDump.ps1
    Author         : gajendra d ambi
    Date           : January 2016
    recommended    : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware   
#>

#start of the script
#start of the function

$DumpTarget = Read-Host "Type the DumpTarget?:"
$vmk        = Read-Host "Type the vmk number?:"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 foreach ($vmhost in (get-vmhost | sort)) {
  if ((get-vmhost $vmhost).version -match 5.) {
  $esxcli = get-vmhost $VMHost | Get-EsxCli
  $esxcli.system.coredump.network.set($null, $vmk , $DumpTarget , "6500")
  $esxcli.system.coredump.network.set("true")
  $esxcli.system.coredump.network.get()
  }

  if ((get-vmhost $vmhost).version -match 6.) {
  $esxcli = get-vmhost $vmhost | get-esxcli
  $esxcli.system.coredump.network.set($null , $vmk , $null , $DumpTarget , "6500")
  $esxcli.system.coredump.network.set("true")
  $esxcli.system.coredump.network.get()
  }
 }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function EsxiAdvanced 
{
<#
.SYNOPSIS
    Set value to a chosen advancedsettig
.DESCRIPTION
    This will ask set many of the esxi advancedsettings which are exposed in esxi>configuration>advancedsettings.
    It will require 2 inputs from the user.
    name of the advanced setting and value of the advancedsetting.
.NOTES
    File Name      : EsxiAdvanced.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$AdvSet  = Read-Host "name of the advancedsetting[case sensitive]?"
$value   = Read-Host "value for the advancedsetting?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 foreach ($vmhost in (Get-Cluster $cluster)) 
 {
 Get-VMHost $vmhost | get-advancedsetting -Name $AdvSet | Set-AdvancedSetting -Value $value -Confirm:$false
 }
 
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function SetIpv6 
{
<#
.SYNOPSIS
    Update Ipv6
.DESCRIPTION
    This will disable/enable Ipv6 on esxi hosts of a chosen cluster.
.NOTES
    File Name      : SetIpv6.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "
1. Disable IPv6
2. Enable IPv6
" -ForegroundColor Blue -BackgroundColor White
$choice = Read-Host "type between 1 & 2"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

If ($choice -eq 1) { get-cluster $cluster | get-vmhost | Get-VMHostNetwork | Set-VMHostNetwork -IPv6Enabled $false }
If ($choice -eq 2) { get-cluster $cluster | get-vmhost | Get-VMHostNetwork | Set-VMHostNetwork -IPv6Enabled $true }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
function SetNTP 
{
<#
.SYNOPSIS
    Update NTP
.DESCRIPTION
    This will update the NTP servers to the esxi hosts. It will add one NTP server at a time.
    It will not replace or overwrite any existing NTP servers. This will set the ntpd service to on.
.NOTES
    File Name      : SetNTP.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "This new values will replace the existing values, hence add all the values" -ForegroundColor Yellow 
$ntp     = Read-Host "NTP address(separate them with comma,no space..)"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$ntp     = $ntp.split(',')

 foreach ($vmhost in (Get-Cluster $cluster | get-vmhost | sort)) 
 {
 Write-Host "adding ntp server to $vmhost" -ForegroundColor Green
 Add-VMHostNTPServer -NtpServer $ntp -VMHost (Get-VMHost $vmhost) -Confirm:$false
 Write-Host "setting ntp policy to on on $vmhost" -ForegroundColor Green
 Get-VMHostService -VMHost (Get-VMHost $vmhost) | where Key -eq "ntpd" | Restart-VMHostService -Confirm:$false
 Get-VMHostService -VMHost (Get-VMHost $vmhost) | where Key -eq "ntpd" | Set-VMHostService -policy "on" -Confirm:$false
 }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function SetFirewall 
{
<#
.SYNOPSIS
    firewall settings for esxi hosts
.DESCRIPTION
    Configure firewall per host in a cluster. These is a sample firewall setting here. You can populate the rest as per your business
    standards. Run 
    get-vmhost <name of any esxi host> | Get-VmhostFirewallException
    to list the available firewall settings that you can turn on or off.
.NOTES
    File Name      : SetFirewall.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$cluster = Read-Host "name of the cluster[type * to include all clusters]?"

 foreach ($vmhost in (Get-Cluster $cluster)) 
 {
  Get-VMHost $vmhost | Get-VmhostFirewallException -Name "NTP Client" | Set-VMHostFirewallException -enabled:$true -Confirm:$false
 }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function SetEsxiPerf 
{
<#
.SYNOPSIS
    Configure powersaving policy or performance policy on esxi.
.DESCRIPTION
    This will configure 1 of the 3 levels of energy saving or performance setting on your esxi hosts.
    3 valid options are HighPerformance, Balanced, LowPower.
.NOTES
    File Name      : SetEsxiPerf.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#

$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "
1. HighPerformance 
2. Balanced 
3. LowPower
" -ForegroundColor Blue -BackgroundColor White
$perf   = Read-Host "one of the following is a valid choice. Type 1,2 or 3"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

if ($perf -eq 1) {$perf = "HighPerformance"}
if ($perf -eq 2) {$perf = "Balanced"       }
if ($perf -eq 3) {$perf = "LowPower"       }

(Get-View (Get-Cluster $cluster | Get-VMHost | Get-View).ConfigManager.PowerSystem).ConfigurePowerPolicy($perf)

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function SetScratch 
{
<#
.SYNOPSIS
    Create & configure Scratch partition on Esxi hosts
.DESCRIPTION
    This will create scratch location on the local storage of the esxi hosts and then map that as the
    scratch location for that host. Please note that if the local storage of your esxi blades is of different
    format that '*-localstorage' then please change the line
    $ds            = Get-VMHost -name $vmhost | get-datastore -Name '*-localstorage'
    accordingly.
.NOTES
    File Name      : SetScratch.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$resetloc = get-location
$cluster  = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "
Leave blank if there is just one datastore,
to create scratch on a datastore with it's name matching 'localstorage' type localstorage,
" -BackgroundColor White -ForegroundColor Black
$pattern  = Read-Host "?"
$pattern = "*"+$pattern+"*"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

foreach ($vmhost in (get-cluster $cluster | get-vmhost | sort)) {
 $vmhost        = (get-vmhost $vmhost).Name
 $scratchfolder = '.locker_'+($vmhost.Split('.')[0])
 $ds            = Get-VMHost -name $vmhost | get-datastore -Name $pattern
  $location = ($vmhost.Split('.')[0])
  New-PSDrive -Name $location -Root \ -PSProvider VimDatastore -Datastore ($ds) -Scope global
  Set-Location $location":"
  ni $scratchfolder -ItemType directory -ErrorAction SilentlyContinue
  Get-VMhost $vmhost | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation" | Set-AdvancedSetting -Value "/vmfs/volumes/$ds/$scratchfolder" -confirm:$false 
  Set-Location $resetloc
  Remove-PSDrive $location
 }
 get-cluster $cluster | get-vmhost | sort | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation" | select Entity, Value | fl

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function SetSnmp 
{
<#
.SYNOPSIS
    Configure SNMP
.DESCRIPTION
    This will configure SNMP using powercli on esxi hosts. It uses esxcli commands into powercli.
.NOTES
    File Name      : SetSnmp.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$snmp    = Read-Host "Type the snmp target"
$string  = Read-Host "Type the snmp communities string"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

  foreach ($vmhost in (get-cluster $cluster | get-vmhost | sort)) {
  $esxcli = get-vmhost $vmhost | get-esxcli
  $esxcli.system.snmp.set($null,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null,"true",$null,$null,$null,$null)
  $esxcli.system.snmp.set($null,$string,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null)
  $esxcli.system.snmp.set($null,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null,"$snmp/$string","$snmp/$string",$null)
  $esxcli.system.snmp.set($null,$null,"true",$null,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null,$null)
  $esxcli.system.snmp.get()
  }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function SetSyslog 
{
<#
.SYNOPSIS
    Configure Syslog
.DESCRIPTION
    This will configure Syslog using powercli. This only set the syslog servers and enable syslog on the esxi hosts.
    You may however include additional advanced syslog configuarations like Syslog.global.defaultSize and others.
    This will also create a firewall exception for the syslog.
.NOTES
    File Name      : SetSyslog.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$syslog  = Read-Host "Syslog Target?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

foreach ($vmhost in (get-cluster $cluster | get-vmhost | sort)) {
get-vmhost $vmhost | Get-AdvancedSetting -Name Syslog.global.logHost | Set-AdvancedSetting -Value $Syslog -Confirm:$false
get-vmhost $vmhost | Get-VMHostFirewallException -Name "syslog" | Set-VMHostFirewallException -enabled:$true -Confirm:$false
  }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function PowerMgmt
{
<#
.SYNOPSIS
    Perform power actions on esxi
.DESCRIPTION
    When we poweroff, shutdown, reboot a host we need to provide a reason to do so. This is especially
    boring and time consuming if you have a lot of hosts on which you have to do this. This is to ease
    that pain. It has 4 options to choose from
     A. Enter Maintenance Mode
     B. Exit Maintenance Mode
     C. Shutdown
     D. Reboot 
    It will ask the reason to perform that action and it will input that reason before it performs the 
    chosen action.
.NOTES
    File Name      : PowerMgmt.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster   = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "
1.Enter Maintenance Mode
2.Exit Maintenance Mode
3.Shutdown (the hosts which are in maintenance mode)
4.Reboot (the hosts which are in maintenance mode)
" -ForegroundColor Blue -BackgroundColor White
$axn     = Read-Host "Type a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$vmhosts = Get-cluster $cluster | get-vmhost
if ($axn -eq 1) {$vmhosts | set-vmhost -State Maintenance}
if ($axn -eq 2) {$vmhosts | set-vmhost -State Connected}
$vmhosts = get-cluster $cluster | get-vmhost -State Maintenance
if ($axn -eq 3) 
 {Write-Host "enter a reason for this action" -ForegroundColor Yellow
  $reason = Read-Host ""
  foreach ($vmhost in $vmhosts) {
  $esxcli = get-esxcli
  $esxcli.system.shutdown.poweroff($null,$reason)
  }
 }
if ($axn -eq 4) 
 {Write-Host "enter a reason for this action" -ForegroundColor Yellow
  $reason = Read-Host ""
  foreach ($vmhost in $vmhosts) {
  $esxcli = get-esxcli
  $esxcli.system.shutdown.poweroff($null,$reason)
  }
 }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function Setpcscd 
{
<#
.SYNOPSIS
    Configure pcscd [PC/SC Smart Card Daemon]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable pcscd.
    This will disable pcscd.
    This will set pcscd policy to On which will be persistent across reboot.
    This will set pcscd policy to Off which will be persistent across reboot.
.NOTES
    File Name      : Setpcscd.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "pcscd [PC/SC Smart Card Daemon] options
     1. Enable pcscd
     2. Disable pcscd
     3. pcscd Policy On
     4. pcscd Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ pcscd | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ pcscd | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ pcscd | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ pcscd | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function Setsfcbd 
{
<#
.SYNOPSIS
    Configure sfcbd-watchdog [CIM Server]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable sfcbd.
    This will disable sfcbd.
    This will set sfcbd policy to On which will be persistent across reboot.
    This will set sfcbd policy to Off which will be persistent across reboot.
.NOTES
    File Name      : Setsfcbd.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "sfcbd-watchdog [CIM Server] options
     1. Enable sfcbd
     2. Disable sfcbd
     3. sfcbd Policy On
     4. sfcbd Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ sfcbd | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ sfcbd | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ sfcbd | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ sfcbd | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function SetTSM 
{
<#
.SYNOPSIS
    Configure TSM [ESXi Shell]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable TSM.
    This will disable TSM.
    This will set TSM policy to On which will be persistent across reboot.
    This will set TSM policy to Off which will be persistent across reboot.
.NOTES
    File Name      : SetTSM.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "TSM [ESXi Shell] options
     1. Enable TSM
     2. Disable TSM
     3. TSM Policy On
     4. TSM Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ TSM | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ TSM | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ TSM | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ TSM | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function Setvpxa 
{
<#
.SYNOPSIS
    Configure vpxa [VMware vCenter Agent]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable vpxa.
    This will disable vpxa.
    This will set vpxa policy to On which will be persistent across reboot.
    This will set vpxa policy to Off which will be persistent across reboot.
.NOTES
    File Name      : Setvpxa.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "vpxa [VMware vCenter Agent] options
     1. Enable vpxa
     2. Disable vpxa
     3. vpxa Policy On
     4. vpxa Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vpxa | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vpxa | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vpxa | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vpxa | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function Setvprobed 
{
<#
.SYNOPSIS
    Configure vprobed [VProbe Daemon]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable vprobed.
    This will disable vprobed.
    This will set vprobed policy to On which will be persistent across reboot.
    This will set vprobed policy to Off which will be persistent across reboot.
.NOTES
    File Name      : Setvprobed.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "vprobed [VProbe Daemon] options
     1. Enable vprobed
     2. Disable vprobed
     3. vprobed Policy On
     4. vprobed Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vprobed | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vprobed | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vprobed | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vprobed | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function Setntpd 
{
<#
.SYNOPSIS
    Configure ntpd [NTP Daemon]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable ntpd.
    This will disable ntpd.
    This will set ntpd policy to On which will be persistent across reboot.
    This will set ntpd policy to Off which will be persistent across reboot.
.NOTES
    File Name      : Setntpd.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "ntpd [NTP Daemon] options
     1. Enable ntpd
     2. Disable ntpd
     3. ntpd Policy On
     4. ntpd Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ ntpd | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ ntpd | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ ntpd | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ ntpd | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function Setvmsyslogd 
{
<#
.SYNOPSIS
    Configure vmsyslogd [Syslog Server]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable vmsyslogd.
    This will disable vmsyslogd.
    This will set vmsyslogd policy to On which will be persistent across reboot.
    This will set vmsyslogd policy to Off which will be persistent across reboot.
.NOTES
    File Name      : Setvmsyslogd.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "vmsyslogd [Syslog Server] options
     1. Enable vmsyslogd
     2. Disable vmsyslogd
     3. vmsyslogd Policy On
     4. vmsyslogd Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vmsyslogd | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vmsyslogd | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vmsyslogd | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ vmsyslogd | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function Setlwsmd 
{
<#
.SYNOPSIS
    Configure lwsmd [Active Directory Service]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable lwsmd.
    This will disable lwsmd.
    This will set lwsmd policy to On which will be persistent across reboot.
    This will set lwsmd policy to Off which will be persistent across reboot.
.NOTES
    File Name      : Setlwsmd.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "lwsmd [Active Directory Service] options
     1. Enable lwsmd
     2. Disable lwsmd
     3. lwsmd Policy On
     4. lwsmd Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ lwsmd | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ lwsmd | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ lwsmd | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ lwsmd | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function SetSSH 
{
<#
.SYNOPSIS
    Configure TSM-SSH [SSH]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable TSM-SSH.
    This will disable TSM-SSH.
    This will set TSM-SSH policy to On which will be persistent across reboot.
    This will set TSM-SSH policy to Off which will be persistent across reboot.
.NOTES
    File Name      : SetSSH.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "TSM-SSH [SSH] options
     1. Enable TSM-SSH
     2. Disable TSM-SSH
     3. TSM-SSH Policy On
     4. TSM-SSH Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ TSM-SSH | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ TSM-SSH | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ TSM-SSH | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ TSM-SSH | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function Setxorg 
{
<#
.SYNOPSIS
    Configure xorg [X.Org Server]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable xorg.
    This will disable xorg.
    This will set xorg policy to On which will be persistent across reboot.
    This will set xorg policy to Off which will be persistent across reboot.
.NOTES
    File Name      : Setxorg.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "xorg [X.Org Server] options
     1. Enable xorg
     2. Disable xorg
     3. xorg Policy On
     4. xorg Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ xorg | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ xorg | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ xorg | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ xorg | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function Setsnmpd 
{
<#
.SYNOPSIS
    Configure snmpd [SNMP Server]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable snmpd.
    This will disable snmpd.
    This will set snmpd policy to On which will be persistent across reboot.
    This will set snmpd policy to Off which will be persistent across reboot.
.NOTES
    File Name      : Setsnmpd.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "snmpd [SNMP Server] options
     1. Enable snmpd
     2. Disable snmpd
     3. snmpd Policy On
     4. snmpd Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ snmpd | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ snmpd | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ snmpd | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ snmpd | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function SetDCUI 
{
<#
.SYNOPSIS
    Configure DCUI [Direct Console UI]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable DCUI.
    This will disable DCUI.
    This will set DCUI policy to On which will be persistent across reboot.
    This will set DCUI policy to Off which will be persistent across reboot.
.NOTES
    File Name      : SetDCUI.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "DCUI [Direct Console UI] options
     1. Enable DCUI
     2. Disable DCUI
     3. DCUI Policy On
     4. DCUI Policy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ DCUI | Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ DCUI | stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ DCUI | Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ DCUI | Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function Setlbtd
{
<#
.SYNOPSIS
    Configure lbtd[Load-Based Teaming Daemon]
.DESCRIPTION
    Depending upon the choice that you make
    This will enable lbtd.
    This will disable lbtd.
    This will set lbtdpolicy to On which will be persistent across reboot.
    This will set lbtdpolicy to Off which will be persistent across reboot.
.NOTES
    File Name      : SetLbtd.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of script#
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
Write-Host "lbtd[Load-Based Teaming Daemon] options
     1. Enable lbtd
     2. Disable lbtd
     3. lbtdPolicy On
     4. lbtdPolicy Off
     " -BackgroundColor White -ForegroundColor Blue #options to choose from
 $a = Read-Host "Choose a number from 1 to 4"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

 if ($a -eq 1) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ lbtd| Start-VMHostService -Confirm:$false}
 if ($a -eq 2) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ lbtd| stop-VMHostService -Confirm:$false}
 if ($a -eq 3) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ lbtd| Set-VMHostService -Policy On -Confirm:$false}
 if ($a -eq 4) {get-cluster $cluster | get-vmhost | get-vmhostservice | where Key -EQ lbtd| Set-VMHostService -Policy Off -Confirm:$false}
    
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function VMotionOff 
{
<#
.SYNOPSIS
    Enable vMotion
.DESCRIPTION
    Enable vMotion across the Cluster
.NOTES
    File Name      : VMotionOff.ps1
    Author         : gajendra d ambi
    Date           : Feb 2016
    recommended    : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware   
#>
#start of script
$cluster  = Read-Host "name of the cluster[type * to include all clusters]?"
$pg       = Read-Host "name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost | Get-VMHostNetworkAdapter | where PortGroupname -EQ $pg | Set-VMHostNetworkAdapter -VMotionEnabled $false -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function VmotionOn 
{
<#
.SYNOPSIS
    Enable vMotion
.DESCRIPTION
    Enable vMotion across the Cluster
.NOTES
    File Name      : VmotionOn.ps1
    Author         : gajendra d ambi
    Date           : Feb 2016
    recommended    : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware   
#>
#start of script
$cluster  = Read-Host "name of the cluster[type * to include all clusters]?"
$pg       = Read-Host "name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost | Get-VMHostNetworkAdapter | where PortGroupname -EQ $pg | Set-VMHostNetworkAdapter -VMotionEnabled $true -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function FaultToleranceOn 
{
<#
.SYNOPSIS
    Enable vMotion
.DESCRIPTION
    Enable vMotion across the Cluster
.NOTES
    File Name      : FaultToleranceOn.ps1
    Author         : gajendra d ambi
    Date           : Feb 2016
    recommended    : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware   
#>
#start of script
$cluster  = Read-Host "name of the cluster[type * to include all clusters]?"
$pg       = Read-Host "name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost | Get-VMHostNetworkAdapter | where PortGroupname -EQ $pg | Set-VMHostNetworkAdapter -FaultToleranceLoggingEnabled $true -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function VsanTrafficOn 
{
<#
.SYNOPSIS
    Enable VsanTrafficOn
.DESCRIPTION
    Enable vMotion across the Cluster
.NOTES
    File Name      : VsanTrafficOn.ps1
    Author         : gajendra d ambi
    Date           : Feb 2016
    recommended    : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware   
#>
#start of script
$cluster  = Read-Host "name of the cluster[type * to include all clusters]?"
$pg       = Read-Host "name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost | Get-VMHostNetworkAdapter | where PortGroupname -EQ $pg | Set-VMHostNetworkAdapter -VsanTrafficEnabled $true -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function ManagementTrafficOn 
{
<#
.SYNOPSIS
    Enable vMotion
.DESCRIPTION
    Enable vMotion across the Cluster
.NOTES
    File Name      : ManagementTrafficOn.ps1
    Author         : gajendra d ambi
    Date           : Feb 2016
    recommended    : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware   
#>
#start of script
$cluster  = Read-Host "name of the cluster[type * to include all clusters]?"
$pg       = Read-Host "name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost | Get-VMHostNetworkAdapter | where PortGroupname -EQ $pg | Set-VMHostNetworkAdapter -ManagementTrafficEnabled $false -Confirm:$false
$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function ManagementTrafficOff 
{
<#
.SYNOPSIS
    Enable vMotion
.DESCRIPTION
    Enable vMotion across the Cluster
.NOTES
    File Name      : ManagementTrafficOff.ps1
    Author         : gajendra d ambi
    Date           : Feb 2016
    recommended    : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware   
#>
#start of script
$cluster  = Read-Host "name of the cluster[type * to include all clusters]?"
$pg       = Read-Host "name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost | Get-VMHostNetworkAdapter | where PortGroupname -EQ $pg | Set-VMHostNetworkAdapter -ManagementTrafficEnabled $false -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function ManagementTrafficOff 
{
<#
.SYNOPSIS
    Enable vMotion
.DESCRIPTION
    Enable vMotion across the Cluster
.NOTES
    File Name      : ManagementTrafficOff.ps1
    Author         : gajendra d ambi
    Date           : Feb 2016
    recommended    : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware   
#>
#start of script
$cluster  = Read-Host "name of the cluster[type * to include all clusters]?"
$pg       = Read-Host "name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost | Get-VMHostNetworkAdapter | where PortGroupname -EQ $pg | Set-VMHostNetworkAdapter -ManagementTrafficEnabled $false -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
function VsanTrafficOff 
{
<#
.SYNOPSIS
    Enable VsanTrafficOff
.DESCRIPTION
    Enable vMotion across the Cluster
.NOTES
    File Name      : VsanTrafficOff.ps1
    Author         : gajendra d ambi
    Date           : Feb 2016
    recommended    : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware   
#>
#start of script
$cluster  = Read-Host "name of the cluster[type * to include all clusters]?"
$pg       = Read-Host "name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost | Get-VMHostNetworkAdapter | where PortGroupname -EQ $pg | Set-VMHostNetworkAdapter -VsanTrafficEnabled $false -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function

#start of function
Function HostVds 
{
<#
.SYNOPSIS
    Add Esxi host to distributed switch.
.DESCRIPTION
    This will create a csv file whcih is opened in excel. Once you popuate the details, you have to save & close it. 
    Hit return/enter to proceed and the script will 
    add the esxi hosts to a chosen dvswitch.    
.NOTES
    File Name      : HostVds.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script
Write-Host "
A CSV file will be opened (open in excel/spreadsheet)
populate the values,
save & close the file,
Hit Enter to proceed
" -ForegroundColor Blue -BackgroundColor White
$csv = "$PSScriptRoot/HostVds.csv"
get-process | Select-Object dvSwitch,hostname,vmnic | Export-Csv -Path $csv -Encoding ASCII -NoTypeInformation
Start-Process $csv
Read-Host "Hit Enter/Return to proceed"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$csv = Import-Csv $csv
 foreach ($line in $csv) 
 {
  $dvs    = $($line.dvSwitch)
  $vmhost = $($line.hostname)  
  $vmnic  = $($line.vmnic)  
  Get-VDSwitch -Name $dvs | Add-VDSwitchVMHost -VMHost $vmhost
  $vmhostNetworkAdapter = Get-VMHost $vmhost | Get-VMHostNetworkAdapter -Physical -Name $vmnic
  Get-VDSwitch $dvs | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter
 }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function AddDpg 
{
<#
.SYNOPSIS
    Add dvportgroups to a dvswitch.
.DESCRIPTION
    This will create a csv file whcih is opened in excel. Once you popuate the details, you have to save & close it. 
    Hit return/enter to proceed and the script will 
    add the dvportgroups to a chosen dvswitch.    
.NOTES
    File Name      : AddDpg.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>

#Start of Script
Write-Host "
A CSV file will be opened (open in excel/spreadsheet)
populate the values,
save & close the file,
Hit Enter to proceed
" -ForegroundColor Blue -BackgroundColor White

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$csv = "$PSScriptRoot/AddDpg.csv"
get-process | Select-Object dvSwitch,dvPortgroup,VlanId,NumberOfPorts | Export-Csv -Path $csv -Encoding ASCII -NoTypeInformation
Start-Process $csv
Read-Host "Hit Enter/Return to proceed"

$csv = Import-Csv $csv
 foreach ($line in $csv) 
 {
  $dvs    = $($line.dvSwitch)
  $dpg    = $($line.dvPortgroup)
  $vlan   = $($line.VlanId)
  $ports  = $($line.NumberOfPorts)
  Get-VDSwitch -Name $dvs | New-VDPortgroup -Name $dpg -VlanId $vlan -NumPorts $ports
 }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function CreateVds 
{
<#
.SYNOPSIS
    Create VDS.
.DESCRIPTION
    This will create a vds on a chosen datacenter..
.NOTES
    File Name      : CreateVds.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$dc  = Read-Host "name of the datacenter?"
$ul  = Read-Host "number of uplinks?"
$dvs = Read-Host "name of the dvSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

New-VDSwitch -Name $dvs -Location $dc -NumUplinkPorts $ul -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
#End of Script#
}#End of function
 
#start of function
Function Setef 
{
<#
.SYNOPSIS
    Set ExplicitFailover on VDS.
.DESCRIPTION
    This will set the loadbalancing on the vds as ExplicitFailover.
.NOTES
    File Name      : Setef.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$dvs = Read-Host "name of the dvSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-VDSwitch -Name $dvs | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -LoadBalancingPolicy ExplicitFailover -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function Setlbsm 
{
<#
.SYNOPSIS
    Set LoadBalanceSrcMac on VDS.
.DESCRIPTION
    This will set the loadbalancing on the vds as LoadBalanceSrcMac.
.NOTES
    File Name      : Setlbsm.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$dvs = Read-Host "name of the dvSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-VDSwitch -Name $dvs | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -LoadBalancingPolicy LoadBalanceSrcMac -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function
 
#start of function
Function SetLbip 
{
<#
.SYNOPSIS
    Set LoadBalanceIP on VDS.
.DESCRIPTION
    This will set the loadbalancing on the vds as LoadBalanceIP.
.NOTES
    File Name      : SetLbip.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$dvs = Read-Host "name of the dvSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-VDSwitch -Name $dvs | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -LoadBalancingPolicy LoadBalanceIP -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function
 
#start of function
Function Setlbsi 
{
<#
.SYNOPSIS
    Set LoadBalanceSrcId on VDS.
.DESCRIPTION
    This will set the loadbalancing on the vds as LoadBalanceSrcId.
.NOTES
    File Name      : Setlbsi.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$dvs = Read-Host "name of the dvSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-VDSwitch -Name $dvs | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -LoadBalancingPolicy LoadBalanceSrcId -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function
 
#start of function
Function Setllb 
{
<#
.SYNOPSIS
    Set LoadBalanceLoadBased on VDS.
.DESCRIPTION
    This will set the loadbalancing on the vds as LoadBalanceLoadBased.
.NOTES
    File Name      : Setllb.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$dvs = Read-Host "name of the dvSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-VDSwitch -Name $dvs | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -LoadBalancingPolicy LoadBalanceLoadBased -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
function ShootVmkPg
{
<#
.SYNOPSIS
    Remove vmkernel portgroup
.DESCRIPTION
    This will remove the virtual machine portgroup of all the hosts of a cluster/clusters.
.NOTES
    File Name      : ShootVmkPg.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$pg      = Read-Host "Name of the portgroup?"
 foreach ($vmhost in (get-cluster $cluster | get-vmhost | sort)) 
 {
  $vmk = Get-VMHostNetworkAdapter -VMHost $vmhost | where PortgroupName -eq $pg
  Write-Host "removing vmkernel from the $pg on $vmhost"
  Remove-VMHostNetworkAdapter -Nic $vmk -confirm:$false
 
  Write-Host "removing $pg on $vmhost"
  get-vmhost $vmhost | get-virtualportgroup -Name $pg | Remove-VirtualPortGroup -Confirm:$false 
 }#End of Script
}#End of function

#start of function
Function ShootVmPg 
{
<#
.SYNOPSIS
    Remove virtual machine portgroup
.DESCRIPTION
    This will remove the virtual machine portgroup of all the hosts of a cluster/clusters.
.NOTES
    File Name      : ShootVmPg.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$pg      = Read-Host "Name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualPortGroup -Name $pg | Remove-VirtualPortGroup -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function Pglbip 
{
<#
.SYNOPSIS
    update virtual machine portgroup's loadbalancing to LoadBalanceIP on vSwitch.
.DESCRIPTION
    This will update virtual machine portgroup's loadbalancing to LoadBalanceIP on a chosen standard portgroup of hosts of a chosen cluster.    
.NOTES
    File Name      : Pglbip.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$pg      = Read-Host "Name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualPortGroup -Name $pg | Get-NicTeamingPolicy | Set-NicTeamingPolicy -LoadBalancingPolicy LoadBalanceIP -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function CreateVss 
{
<#
.SYNOPSIS
    Create standard vSwitch.
.DESCRIPTION
    This will create a standard vSwitch of hosts of a chosen cluster.    
.NOTES
    File Name      : CreateVss.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$vss     = Read-Host "name of the vSphere standard Switch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost | New-VirtualSwitch -Name $vss -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function Pglbsi 
{
<#
.SYNOPSIS
    update virtual machine portgroup's loadbalancing to LoadBalanceSrcId on vSwitch.
.DESCRIPTION
    This will update virtual machine portgroup's loadbalancing to LoadBalanceSrcId on a chosen standard portgroup of hosts of a chosen cluster.    
.NOTES
    File Name      : Pglbsi.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$pg      = Read-Host "Name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualPortGroup -Name $pg | Get-NicTeamingPolicy | Set-NicTeamingPolicy -LoadBalancingPolicy LoadBalanceSrcId -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function Pglbsm 
{
<#
.SYNOPSIS
    update virtual machine portgroup's loadbalancing to LoadBalanceSrcMac on vSwitch.
.DESCRIPTION
    This will update virtual machine portgroup's loadbalancing to LoadBalanceSrcMac on a chosen standard portgroup of hosts of a chosen cluster.    
.NOTES
    File Name      : Pglbsm.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$pg      = Read-Host "Name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualPortGroup -Name $pg | Get-NicTeamingPolicy | Set-NicTeamingPolicy -LoadBalancingPolicy LoadBalanceSrcMac -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function PgVlan 
{
<#
.SYNOPSIS
    update virtual machine portgroup's Vlan on vSwitch.
.DESCRIPTION
    This will update virtual machine portgroup's Vlan on a chosen portgroup of hosts of a chosen cluster.    
.NOTES
    File Name      : PgVlan.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$pg      = Read-Host "Name of the portgroup?"
$vlan    = Read-Host "New Vlan?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualPortGroup -Name $pg | Set-VirtualPortGroup -VLanId $vlan -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function Pgef 
{
<#
.SYNOPSIS
    update virtual machine portgroup's loadbalancing to ExplicitFailover on vSwitch.
.DESCRIPTION
    This will update virtual machine portgroup's loadbalancing to ExplicitFailover on a chosen standard portgroup of hosts of a chosen cluster.    
.NOTES
    File Name      : Pgef.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$pg      = Read-Host "Name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualPortGroup -Name $pg | Get-NicTeamingPolicy | Set-NicTeamingPolicy -LoadBalancingPolicy ExplicitFailover -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function PgRename 
{
<#
.SYNOPSIS
    update virtual machine portgroup's name on vSwitch.
.DESCRIPTION
    This will update virtual machine portgroup's name on a chosen standard vSwitch of hosts of a chosen cluster.    
.NOTES
    File Name      : PgRename.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$oldpg   = Read-Host "Old Name of the portgroup?"
$newpg   = Read-Host "New Name of the portgroup?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualPortGroup -Name $oldpg | Set-VirtualPortGroup -Name $newpg -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function VssPmOn 
{
<#
.SYNOPSIS
    Allow promiscous mode
.DESCRIPTION
    This will allow promiscous mode on a vswitch.
.NOTES
    File Name      : VssPmOn.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$vss     = Read-Host "Name of the vSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualSwitch -Name $vss | Get-SecurityPolicy | Set-SecurityPolicy -AllowPromiscuous $true -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function VssPmOff
{
<#
.SYNOPSIS
    Allow promiscous mode
.DESCRIPTION
    This will allow promiscous mode on a vswitch.
.NOTES
    File Name      : VssPmOff.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$vss     = Read-Host "Name of the vSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualSwitch -Name $vss | Get-SecurityPolicy | Set-SecurityPolicy -AllowPromiscuous $false -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function VssVmkPg 
{
<#
.SYNOPSIS
    update vmkernel portgroup on vSwitch.
.DESCRIPTION
    This will update vmkernel portgroup on a chosen standard vSwitch of hosts of a chosen cluster.    
.NOTES
    File Name      : VssVmkPg.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$vss     = Read-Host "name of the vSphere standard Switch?"
$pg      = Read-Host "Name of the portgroup?"
$vmk     = Read-Host "vmk number? ex:- vmk9"
$ip      = Read-Host "starting ip address?" 
$mask    = Read-Host "subnet mask"
$vlan    = Read-Host "Vlan?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$a       = $ip.Split('.')[0..2]
   
  #first 3 octets of the ip address
  $b     = [string]::Join(".",$a)
  
  #last octet of the ip address
  $c     = $ip.Split('.')[3]
  $c     = [int]$c

  foreach ($vmhost in (get-cluster $cluster | get-vmhost | sort)) {
  get-vmhost $vmhost | get-virtualswitch -Name $vss | New-VirtualPortGroup -Name $pg -VLanId $vlan -Confirm:$false
  $esxcli = get-vmhost $vmhost | Get-EsxCli
  $esxcli.network.ip.interface.add($null, $null, "$vmk", $null, "1500", $null, "$pg")
  $esxcli.network.ip.interface.ipv4.set("$vmk", "$b.$(($c++))", "$mask", $null, "static")
 }

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function VssPorts 
{
<#
.SYNOPSIS
    update portgroups on vSwitch.
.DESCRIPTION
    This will update portgroups on a chosen standard vSwitch of hosts of a chosen cluster.    
.NOTES
    File Name      : VssPorts.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$vss     = Read-Host "name of the vSphere standard Switch?"
$ports   = Read-Host "number of ports?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | Get-VMHost | Get-VirtualSwitch -Name $vss | Set-VirtualSwitch -NumPorts $ports -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function VssFtOff 
{
<#
.SYNOPSIS
    Allow promiscous mode
.DESCRIPTION
    This will allow promiscous mode on a vswitch.
.NOTES
    File Name      : VssFtOff.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$vss     = Read-Host "Name of the vSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualSwitch -Name $vss | Get-SecurityPolicy | Set-SecurityPolicy -ForgedTransmits $false -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function VssVmPg 
{
<#
.SYNOPSIS
    update virtual machine portgroup on vSwitch.
.DESCRIPTION
    This will update virtual machie portgroup on a chosen standard vSwitch of hosts of a chosen cluster.    
.NOTES
    File Name      : VssVmPg.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$vss     = Read-Host "name of the vSphere standard Switch?"
$pg      = Read-Host "Name of the portgroup?"
$vlan    = read-host "VLAN?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualSwitch -Name $vss | New-VirtualPortGroup -Name $pg -VLanId $vlan -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function VssMcOff
{
<#
.SYNOPSIS
    Allow promiscous mode
.DESCRIPTION
    This will allow promiscous mode on a vswitch.
.NOTES
    File Name      : VssMcOff.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$vss     = Read-Host "Name of the vSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualSwitch -Name $vss | Get-SecurityPolicy | Set-SecurityPolicy -MacChanges $false -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function VssMcOn
{
<#
.SYNOPSIS
    Allow promiscous mode
.DESCRIPTION
    This will allow promiscous mode on a vswitch.
.NOTES
    File Name      : VssMcOn.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$vss     = Read-Host "Name of the vSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualSwitch -Name $vss | Get-SecurityPolicy | Set-SecurityPolicy -MacChanges $true -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function VssFtOn 
{
<#
.SYNOPSIS
    Allow promiscous mode
.DESCRIPTION
    This will allow promiscous mode on a vswitch.
.NOTES
    File Name      : VssFtOn.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$vss     = Read-Host "Name of the vSwitch?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-cluster $cluster | Get-VMHost | Get-VirtualSwitch -Name $vss | Get-SecurityPolicy | Set-SecurityPolicy -ForgedTransmits $true -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#start of function
Function VssMtu 
{
<#
.SYNOPSIS
    update Mtu on vSwitch.
.DESCRIPTION
    This will update Mtu on a chosen standard vSwitch of hosts of a chosen cluster.    
.NOTES
    File Name      : VssMtu.ps1
    Author         : gajendra d ambi
    Date           : March 2016
    Prerequisite   : PowerShell v4+, powercli 6+ over win7 and upper.
    Copyright      - None
.LINK
    Script posted over: github.com/gajuambi/vmware
#>
#Start of Script
$cluster = Read-Host "name of the cluster[type * to include all clusters]?"
$vss     = Read-Host "name of the vSphere standard Switch?"
$mtu     = Read-Host "mtu?"

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

Get-Cluster $cluster | get-vmhost | Get-Virtualswitch -Name $vss | Set-VirtualSwitch -Mtu $mtu -Confirm:$false

$stopWatch.Stop()
Write-Host "Elapsed Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
 #End of Script#
}#End of function

#------------------------------End of Collection of Functions of automation------------------------#

#------------------------------Start of Collection of Menu Functions-------------------------------#

#Start of NicMenu
function NicMenu
{
 do {
 do {     
     Write-Host "`NicMenu" -BackgroundColor White -ForegroundColor Black
     Write-Host "
     A. vSwitch
     B. portgroup
     " #options to choose from
   
     Write-Host "
     X. Previous Menu
     Y. Main Menu
     Z. Exit" -BackgroundColor Black -ForegroundColor Green #return to main menu
    
     $choice = Read-Host "choose one of the above" #Get user's entry
     $ok     = $choice -match '^[abxyz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
    "A" { NicStatusVss }
    "B" { NicStatusPg }

    "X" { vCenterMenu }
    "Y" { MainMenu }  
    }
    } until ( $choice -match "Z" )
} #end of NicMenu

#Start of StandHostsMenu
function StandHostsMenu
{
 do {
 do {     
     Write-Host "`StandHostsMenu" -BackgroundColor White -ForegroundColor Black
     Write-Host "
     A. Connect to standalone hosts
     B. Create virtual Standard Switch
     C. Create virtual Machine Portgroup
     D. Create VMkernel Portgroup
     E. Rename Portgroups
     F. Add Nics to vSwitch
     G. Remove VM portgroup
     H. Remove VMkernel portgroup" #options to choose from
   
     Write-Host "
     X. Previous Menu
     Y. Main Menu
     Z. Exit" -BackgroundColor Black -ForegroundColor Green #return to main menu
    
     $choice = Read-Host "choose one of the above" #Get user's entry
     $ok     = $choice -match '^[abcdefghxyz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
    "A" { shGetShHosts }
    "B" { shNewVss }
    "C" { shNewVMPg }
    "D" { shNewVMkernelPg }
    "E" { shRenamePg }
    "F" { shAddNic }
    "G" { shShootVmPg }
    "H" { shShootVmkPg }

    "X" { vCenterMenu }
    "Y" { MainMenu }  
    }
    } until ( $choice -match "Z" )
}
#end of StandHostsMenu

#Start of vdsLoadBalancingMenu
function vdsLoadBalancingMenu
{
 do {
 do {
     Write-Host "Make sure you are connected to a vCenter" -ForegroundColor Yellow
     Write-Host "`nvdsLoadBalancingMenu" -BackgroundColor White -ForegroundColor Black
     Write-Host "
     A. LoadBalanceIP
     B. LoadBalanceLoadBased
     C. LoadBalanceSrcMac
     D. LoadBalanceSrcId
     E. ExplicitFailover" #options to choose from
   
     Write-Host "
     X. Previous Menu
     Y. Main Menu
     Z. Exit" -BackgroundColor Black -ForegroundColor Green #return to main menu
    
     $choice = Read-Host "choose one of the above"  #Get user's entry
     $ok     = $choice -match '^[abcdexyz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
    "A" { SetLbip }
    "B" { Setllb }
    "C" { Setlbsm }
    "D" { Setlbsi }
    "E" { Setef }
    "X" { vdsMenu }
    "Y" { MainMenu }  
    }
    } until ( $choice -match "Z" )
}
#end of vdsLoadBalancingMenu

#Start of VMKservicesMenu
function VMKservicesMenu
{
 do {
 do {
     Write-Host "Make sure you are connected to a vCenter" -ForegroundColor Yellow
     Write-Host "`nVMKservicesMenu" -BackgroundColor White -ForegroundColor Black
     Write-Host "
     A. Enable VMotion
     B. Enable VsanTraffic
     C. Enable FaultTolerance
     D. Enable ManagementTraffic
     E. Disable VMotion
     F. Disable VsanTraffic
     G. Disable FaultTolerance
     H. Disable ManagementTraffic" #options to choose from
   
     Write-Host "
     X. Previous Menu
     Y. Main Menu
     Z. Exit" -BackgroundColor Black -ForegroundColor Green #return to main menu
    
     $choice = Read-Host "choose one of the above"  #Get user's entry
     $ok     = $choice -match '^[abcdefghxyz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
    "A" { VmotionOn }
    "B" { VsanTrafficOn }
    "C" { FaultToleranceOn }
    "D" { ManagementTrafficOn }
    "E" { VMotionOff }
    "F" { VsanTrafficOff }    
    "G" { FaultToleranceOff }
    "H" { ManagementTrafficOff }
    "X" { HostMenu }
    "Y" { MainMenu } 
    }
    } until ( $choice -match "Z" )
}
#end of VMKservicesMenu

#Start of vdsMenu
function vdsMenu
{
 do {
 do {
     Write-Host "Make sure you are connected to a vCenter" -ForegroundColor Yellow
     Write-Host "`nvdsMenu" -BackgroundColor White -ForegroundColor Black
     Write-Host "
     A. Create VDS
     B. Create dvPortgroup
     C. Add hosts to VDS
     D. Load balancing
     E. (L3)TCP/IP stack" #options to choose from
   
     Write-Host "
     X. Previous Menu
     Y. Main Menu
     Z. Exit" -BackgroundColor Black -ForegroundColor Green #return to main menu
    
     $choice = Read-Host "choose one of the above"  #Get user's entry
     $ok     = $choice -match '^[abcdexyz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
    "A" { CreateVds }
    "B" { AddDpg }
    "C" { HostVds }
    "D" { vdsLoadBalancingMenu }
    "E" { Write-Host This feature is not available yet }
    "X" { vCenterMenu }
    "Y" { MainMenu }  
    }
    } until ( $choice -match "Z" )
}
#end of vdsMenu

#Start of VssMenu
Function VssMenu
{
 do {
 do {         
     Write-Host -BackgroundColor White -ForegroundColor Black "`nVssMenu"
     Write-Host "
     A. Create vSwitch
     B. Update NumPorts
     C. Update Nic
     D  Update MTU
     E. Create VM Portgroup
     F. Create VMkernel Portgroup
     G. Rename Portgroup
     H. Update Portgroup's Vlan
     I. LoadBalanceIP
     J. LoadBalanceSrcMac
     K. LoadBalanceSrcId
     L. ExplicitFailover
     M. Delete VM Portgroup
     N. Enable AllowPromiscuous
     O. Enable ForgedTransmits
     P. Enable MacChanges
     Q. Disable AllowPromiscuous
     R. Disable ForgedTransmits
     S. Disable MacChanges
     T. Delete VMkernel Portgroup  
     U. Sync portgroup with vSwitch(inherit all properties of vswitch to portgroup)
     V. L3 vMotion Portgroup
     " #options to choose from...

     Write-Host "
     X. Previous Menu
     Y. Main Menu
     Z. Exit 
     " -BackgroundColor White -ForegroundColor Black

     $user   = [Environment]::UserName
     $choice = Read-Host "choose one of the above"  #Get user's entry
     $ok     = $choice -match '^[abcdefghijklmnopqrstuvxyz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
     "A" { CreateVss }
     "B" { VssPorts }
     "C" { NicMenu }
     "D" { VssMtu }
     "E" { VssVmPg }
     "F" { VssVmkPg }
     "G" { PgRename }
     "H" { PgVlan }
     "I" { Pglbip }
     "J" { Pglbsm }
     "K" { Pglbsi }
     "L" { Pgef }
     "M" { ShootVmPg }
     "N" { VssPmOn }
     "O" { VssFtOn }
     "P" { VssMcOn }
     "Q" { VssPmOff }
     "R" { VssFtOff }
     "S" { VssMcOff }
     "T" { ShootVmkPg }
     "U" { PgSync }
     "V" { l3vmotion }
     "X" { vCenterMenu }
     "Y" { MainMenu }      
    }
    } until ( $choice -match "Z" )
} #End of VssMenu

#Start of MainMenu
function MainMenu
{
 do {
 do {
     $version = '2016Aug'
     Write-Host -BackgroundColor Black -ForegroundColor Cyan  "`nvTool $version"
     Write-Host -BackgroundColor White -ForegroundColor Black "`nMain Menu"
     Write-Host "
     A. vCenter
     B. Standalone Hosts" #options to choose from...

     write-host "
     Z - Exit" -ForegroundColor Yellow #exits the script

     $user   = [Environment]::UserName     
     $choice = Read-Host "Hi $user, choose one of the above"  #Get user's entry
     $ok     = $choice -match '^[abz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
    "A" { vCenterMenu }
    "B" { StandHostsMenu }
    }
    } until ( $choice -match "Z" )
    #if ($choice -eq "z") { exit }
}
#end of MainMenu

#Start of DrsRulesMenu
function DrsRulesMenu
{
 do {
 do {
     Write-Host "Make sure you are connected to a vCenter" -ForegroundColor Yellow
     Write-Host "`nDrsRulesMenu" -BackgroundColor White -ForegroundColor Black
     Write-Host "
     A. VMAffinity
     B. VMAntiAffinity
     C. DrsVmGroup
     D. DrsHostGroup
     E. DRSVMToHostRule
     " #options to choose from
   
     Write-Host "
     X. Previous Menu
     Y. Main Menu
     Z. Exit" -BackgroundColor Black -ForegroundColor Green #return to main menu
    
     $choice = Read-Host "choose one of the above" #Get user's entry
     $ok     = $choice -match '^[abcdexyz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
    "A" { VMAffinity }
    "B" { VMAntiAffinity }
    "C" { DrsVmGroup }
    "D" { DrsHostGroup }
    "E" { DRSVMToHostRule }
    "X" { ClusterMenu }
    "Y" { MainMenu }  
    }
    } until ( $choice -match "Z" )
}
#end of DrsRulesMenu

#Start of ClusterMenu
function ClusterMenu
{
 do {
 do {
     Write-Host "Make sure you are connected to a vCenter" -ForegroundColor Yellow
     Write-Host "`nClusterMenu" -BackgroundColor White -ForegroundColor Black
     Write-Host "
     A. Create Cluster
     B. Add Hosts
     C. Configure HA
     D. Configure DRS
     E. DRS rules
     F. Create vApp
     G. Add Datastores" #options to choose from
   
     Write-Host "
     X. Previous Menu
     Y. Main Menu
     Z. Exit" -BackgroundColor Black -ForegroundColor Green #return to main menu
    
     $choice = Read-Host "choose one of the above"  #Get user's entry
     $ok     = $choice -match '^[abcdefgxyz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
    "A" { CreateCluster }
    "B" { AddHosts }
    "C" { ConfigHA }
    "D" { ConfigDrs }
    "E" { DrsRulesMenu }
    "F" { CreateVapp }
    "G" { AddDatastores }
    "X" { vCenterMenu }
    "Y" { MainMenu }  
    }
    } until ( $choice -match "Z" )
}
#end of ClusterMenu

#Start of HostServicesMenu
function HostServicesMenu
{
 do {
 do {
     Write-Host "Make sure you are connected to a vCenter" -ForegroundColor Yellow
     Write-Host "`nHostServicesMenu" -BackgroundColor White -ForegroundColor Black
     Write-Host "
     A. DCUI           [Direct Console UI]
     B. TSM            [ESXi Shell]
     C. TSM-SSH        [SSH]
     D. lbtd           [Load-Based Teaming Daemon]
     E. lwsmd          [Active Directory Service]
     F. ntpd           [NTP Daemon]
     G. pcscd          [PC/SC Smart Card Daemon]
     H. sfcbd-watchdog [CIM Server]
     I. snmpd          [SNMP Server]
     J. vmsyslogd      [Syslog Server]
     K. vprobed        [VProbe Daemon]
     L. vpxa           [VMware vCenter Agent]
     M. xorg           [X.Org Server]
     " #options to choose from
   
     Write-Host "
     X. Previous Menu
     Y. Main Menu
     Z. Exit" -BackgroundColor Black -ForegroundColor Green #return to main menu
    
     $choice = Read-Host "choose one of the above"  #Get user's entry
     $ok     = $choice -match '^[abcdefghijklmxyz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
    "A" { SetDCUI }
    "B" { SetTSM }
    "C" { SetSSH }
    "D" { SetLbtd }
    "E" { Setlwsmd }
    "F" { Setntpd }
    "G" { Setpcscd }
    "H" { Setsfcbd }
    "I" { Setsnmpd }
    "J" { Setvmsyslogd }
    "K" { Setvprobed }
    "L" { Setvpxa }
    "M" { Setxorg }
    "X" { HostMenu }
    "Y" { MainMenu }
    }
    } until ( $choice -match "Z" )
}
#end of HostServicesMenu

#Start of HostMenu
function HostMenu
{
 do {
 do {
     Write-Host "Make sure you are connected to a vCenter" -ForegroundColor Yellow
     Write-Host "`nHostMenu" -BackgroundColor White -ForegroundColor Black
     Write-Host "
     A. SNMP
     B. Syslog settings
     C. DNS settings
     D. NTP settings
     E. Any Advanced setting
     F. Firewall Settings
     G. Scratch partition
     H. Performance settings
     I. Core dump settings
     J. Power Management (shutdown, reboot, maintenance)
     k. Enable/disable services
     L. IPv6
     M. VMKernel Services
     N. WinSSH (Run SSH commands on esxi from directly from windows)

     W. Others" #[Others menu is to include miscellaneous settings as per business needs] #options to choose from
   
     Write-Host "
     X. Previous Menu
     Y. Main Menu
     Z. Exit" -BackgroundColor Black -ForegroundColor Green #return to main menu
    
     $choice = Read-Host "choose one of the above"  #Get user's entry
     $ok     = $choice -match '^[abcdefghijklmnwxyz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
    "A" { SetSnmp }
    "B" { SetSyslog }
    "C" { SetDNS }
    "D" { SetNTP }
    "E" { EsxiAdvanced }
    "F" { SetFirewall }
    "G" { SetScratch }
    "H" { HostPerf }
    "I" { CoreDump }
    "J" { PowerMgmt }
    "K" { HostServicesMenu }
    "L" { SetIpv6 }
    "M" { VMKservicesMenu }
    "N" { WinSSH }
    "W" { Write-Host you chose others. This is not implemented yet }
    "X" { vCenterMenu }
    "Y" { MainMenu }  
    }
    } until ( $choice -match "Z" )
}
#end of HostMenu

#Start of vCenterMenu
function vCenterMenu
{
 do {
 do {
     Write-Host "Make sure you are connected to a vCenter" -ForegroundColor Yellow
     Write-Host "`nvCenterMenu" -BackgroundColor White -ForegroundColor Black
     Write-Host "
     A. Cluster
     B. Host
     C. vSwitch
     D. dvSwitch" #options to choose from
   
     Write-Host "
     Y. Main Menu
     Z. Exit" -BackgroundColor Black -ForegroundColor Green #return to main menu
    
     $choice = Read-Host "choose one of the above"  #Get user's entry
     $ok     = $choice -match '^[abcdyz]+$'
     if ( -not $ok) { write-host "Invalid selection" -BackgroundColor Red }
    } until ( $ok )
    switch -Regex ($choice) 
    {
    "A" { ClusterMenu }
    "B" { HostMenu }
    "C" { VssMenu }
    "D" { vdsMenu }
    "Y" { HostMenu }
    }
    } until ( $choice -match "Z" )
}
#end of vCenterMenu

#------------------------------End of Collection of Menu Functions-------------------------------#

PcliPshell
MainMenu
##End of Script##
