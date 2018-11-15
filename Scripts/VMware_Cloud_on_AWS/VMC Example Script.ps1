#List the commands available for the VMC module
Get-VMCCommand

#Connect to VMC
$MyRefreshToken = "XXXX-XXXX-XXXX-XXXX"
Connect-VMC -RefreshToken $MyRefreshToken

#List the Orgs available to us
Get-VMCOrg

#List the SDDCs
Get-VMCSDDC -Org BashFest*

#List the Tasks for a particular Org
Get-VMCTask -Org BashFest* | Select-Object task_type, Sub_Status, start_time, End_time, user_name | Sort-Object Start_Time | Format-Table

#Get the Public IPs for a SDDC
Get-VMCSDDCPublicIPPool -org bashfest*

#Get all ESXi hosts for given SDDC
Get-VMCVMHost -org bashfest* -Sddc virtu-al

#Get the credentials of a SDDC so we can login via vSphere cmdlets
Get-VMCSDDCDefaultCredential -org bashfest* -Sddc virtu-al

#Connect to your VMC vCenter with default creds
Connect-VmcVIServer -org bashfest* -Sddc virtu-al

#Run some vSphere cmdlets

#List all VMs from On-Premises and VMC SDDC
Get-VM | Select vCenterServer, Name, PowerState, VMHost


