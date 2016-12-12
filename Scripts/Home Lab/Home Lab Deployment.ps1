# ESX Start Host deployment Settings
$ESXIP = "192.168.1.201"
$ESXUser = "root"
$ESXPWD = "VMware1!"

# VCSA Configuration
$VCSACDDrive = "D:\"
$SSODomainName = "corp.local"
$VCNAME = "VC01"
$VCUser = "Administrator@$SSODomainName"
$VCPass = "VMware1!"
$VCIP = "192.168.1.200"
$VCDNS = "192.168.1.1"
$VCGW = "192.168.1.1"
$VCNetPrefix = "24"
$VCSADeploymentSize = "tiny"

# vCenter Configuration
$SSOSiteName = "Site01"
$datacenter = "DC01"
$cluster = "Cluster01"
$ntpserver = "pool.ntp.org"

# VSAN Configuration
$VSANPolicy = '(("hostFailuresToTolerate" i1) ("forceProvisioning" i1))'
$VMKNetforVSAN = "Management Network"

# General Settings
$verboseLogFile = "$ENV:Temp\vsphere65-NUC-lab-deployment.log"

# End of configuration
Function My-Logger {
    param(
    [Parameter(Mandatory=$true)]
    [String]$message
    )

    $timeStamp = Get-Date -Format "MM-dd-yyyy_hh:mm:ss"

    Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
    Write-Host -ForegroundColor Green " $message"
    $logMessage = "[$timeStamp] $message"
    $logMessage | Out-File -Append -LiteralPath $verboseLogFile
}

$StartTime = Get-Date

Write-Host "Writing Log files to $verboselogfile" -ForegroundColor Yellow
Write-Host ""

If (-not (Test-Path "$($VCSACDDrive)vcsa-cli-installer\win32\vcsa-deploy.exe")){
    Write-Host "VCSA media not found at $($VCSACDDrive) please mount it and try again"
    return
}
My-Logger "Connecting to ESXi Host: $ESXIP ..."
$connection = Connect-viserver $ESXIP -user $ESXUser -Password $ESXPWD -WarningAction SilentlyContinue

My-Logger "Enabling SSH Service for future troubleshooting ..."
Start-VMHostService -HostService (Get-VMHost | Get-VMHostService | Where { $_.Key -eq "TSM-SSH"} ) | Out-File -Append -LiteralPath $verboseLogFile

My-Logger "Configuring NTP server to $ntpserver and retarting service ..."
Get-VMHost | Add-VMHostNtpServer $ntpserver | Out-File -Append -LiteralPath $verboseLogFile
Get-VMHost | Get-VMHostFirewallException | where {$_.Name -eq "NTP client"} | Set-VMHostFirewallException -Enabled:$true | Out-File -Append -LiteralPath $verboseLogFile
Get-VMHost | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService | Out-File -Append -LiteralPath $verboseLogFile
Get-VMhost | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "automatic" | Out-File -Append -LiteralPath $verboseLogFile

#Configure VSAN Bootstrap (http://www.virtuallyghetto.com/2013/09/how-to-bootstrap-vcenter-server-onto_9.html)
My-Logger "Setting the VSAN Policy for ForceProvisiong ..."
$esxcli = get-esxcli -V2
$VSANPolicyDefaults = $esxcli.vsan.policy.setdefault.CreateArgs()
$VSANPolicyDefaults.policy = $VSANPolicy
$VSANPolicyDefaults.policyclass = "vdisk"
$esxcli.vsan.policy.setdefault.Invoke($VSANPolicyDefaults) | Out-File -Append -LiteralPath $verboseLogFile
$VSANPolicyDefaults.policyclass = "vmnamespace"
$esxcli.vsan.policy.setdefault.Invoke($VSANPolicyDefaults) | Out-File -Append -LiteralPath $verboseLogFile

# Create new VSAN Cluster
My-Logger "Creating a new VSAN Cluster ..."
$esxcli.vsan.cluster.new.Invoke() | Out-File -Append -LiteralPath $verboseLogFile
$VSANDisks = $esxcli.storage.core.device.list.invoke() | Where {$_.isremovable -eq "false"} | Sort size
"Found the following disks to use for VSAN:" | Out-File -Append -LiteralPath $verboseLogFile
$VSANDisks | FT | Out-File -Append -LiteralPath $verboseLogFile
$Performance = $VSANDisks[0]
"Using $($Performance.Model) for Performance disk" | Out-File -Append -LiteralPath $verboseLogFile
$Capacity = $VSANDisks[1]
"Using $($Capacity.Model) for Capacity disk" | Out-File -Append -LiteralPath $verboseLogFile

My-Logger "Tagging $($Capacity.Model) as Capacity ..."
$capacitytag = $esxcli.vsan.storage.tag.add.CreateArgs()
$capacitytag.disk = $Capacity.Device
$capacitytag.tag = "capacityFlash"
$esxcli.vsan.storage.tag.add.Invoke($capacitytag) | Out-File -Append -LiteralPath $verboseLogFile

My-Logger "Create VSAN Diskgroup to back VSAN Cluster ..."
$addvsanstorage = $esxcli.vsan.storage.add.CreateArgs()
$addvsanstorage.ssd = $Performance.Device
$addvsanstorage.disks = $Capacity.device
$esxcli.vsan.storage.add.Invoke($addvsanstorage) | Out-File -Append -LiteralPath $verboseLogFile

My-Logger "Deploying VCSA using Script CLI + JSON ..."
$config = (get-content –raw “$($VCSACDDrive)vcsa-cli-installer\templates\install\embedded_vCSA_on_ESXi.json” ) | convertfrom-json
$config.'new.vcsa'.esxi.hostname = $ESXIP
$config.'new.vcsa'.esxi.username = $ESXUser
$config.'new.vcsa'.esxi.password = $ESXPWD
$config.'new.vcsa'.esxi.datastore = "vsanDatastore"
$config.'new.vcsa'.network.ip = $VCIP
$config.'new.vcsa'.network.'dns.servers'[0] = $VCDNS
$config.'new.vcsa'.network.gateway = $VCGW
$config.'new.vcsa'.network.'system.name' = $VCIP #Change to $VCName if you have DNS setup
$config.'new.vcsa'.network.prefix = $VCNetPrefix
$config.'new.vcsa'.os.password = $VCPass
$config.'new.vcsa'.appliance.'deployment.option' = $VCSADeploymentSize
$config.'new.vcsa'.sso.password = $VCPass
$config.'new.vcsa'.sso.'site-name' = $SSOSiteName
$config.'new.vcsa'.sso.'domain-name' = $SSODomainName
$config | convertto-json | set-content –path “$($ENV:Temp)\jsontemplate.json”
invoke-expression “$($VCSACDDrive)vcsa-cli-installer\win32\vcsa-deploy.exe install --no-esx-ssl-verify --accept-eula --acknowledge-ceip $($ENV:Temp)\jsontemplate.json” | Out-File -Append -LiteralPath $verboseLogFile

My-Logger "Enable VSAN Traffic on VMKernel Network ..."
$VMKernel = Get-VMHost $ESXIP | Get-VMHostNetworkAdapter -VMKernel | Where {$_.PortGroupName -eq $VMKNetforVSAN }
$IsVSANEnabled = $VMKernel | Where { $_.VsanTrafficEnabled}
If (-not $IsVSANEnabled) {
    My-Logger "Enabling VSAN Kernel on $VMKernel ..."
    $VMKernel | Set-VMHostNetworkAdapter -VsanTrafficEnabled $true -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
} Else {
    My-Logger "VSAN Kernel already enabled on $VmKernel ..."
}

My-Logger "Disconnecting from ESXi Host: $ESXIP ..."
Disconnect-VIServer $ESXIP -Force -Confirm:$false -WarningAction SilentlyContinue

My-Logger "Connecting to vCenter: $VCIP ..."
$connection = Connect-VIServer -Server $VCIP -User $VCUser -Password $vcpass -WarningAction SilentlyContinue

My-Logger "Creating Datacenter: $datacenter ..."
New-Datacenter -Name $datacenter -Location (Get-Folder -Type Datacenter) | Out-File -Append -LiteralPath $verboseLogFile
My-Logger "Creating Cluster: $cluster ..."
New-Cluster -Name $cluster -Location (Get-Datacenter -Name $datacenter) -DrsEnabled -VsanEnabled | Out-File -Append -LiteralPath $verboseLogFile
My-Logger "Adding ESXi Host $ESXIP to vCenter ..."
Add-VMHost -Location (Get-Cluster -Name $cluster) -User $ESXUser -Password $ESXPWD -Name $ESXIP -Force | Out-File -Append -LiteralPath $verboseLogFile

My-Logger "Setting the VCSA NTP server to: $NTPServer ..."
Connect-CISServer -Server $VCIP -User $VCUser -Password $VCPass
(Get-CISService com.vmware.appliance.techpreview.ntp.server).set(@($NTPServer)) | Out-File -Append -LiteralPath $verboseLogFile

My-Logger "Configuring Host syslog to VC ..."
Get-VMHost | Set-VMHostSysLogServer -SysLogServer $VCIP | Out-File -Append -LiteralPath $verboseLogFile

My-Logger "Acknowledging Alarms on the cluster ..."
$alarmMgr = Get-View AlarmManager 
Get-Cluster | where {$_.ExtensionData.TriggeredAlarmState} | %{
    $cluster = $_
    $Cluster.ExtensionData.TriggeredAlarmState | %{
        $alarmMgr.AcknowledgeAlarm($_.Alarm,$vm.ExtensionData.MoRef) | Out-File -Append -LiteralPath $verboseLogFile
    }
}

My-Logger "Creating @lamw Content Library with Nested ESXi Images ..."

# Get a Datastore to create the content library on
$datastoreID = (Get-Datastore "vsanDatastore").extensiondata.moref.value

# Get the Service that works with Subscribed content libraries
$ContentCatalog = Get-CisService com.vmware.content.subscribed_library
 
# Create a Subscribed content library on an existing datastore
$createSpec = $ContentCatalog.help.create.create_spec.CreateExample()
$createSpec.subscription_info.authentication_method = "NONE"
$createSpec.subscription_info.ssl_thumbprint = "69:d9:9e:e9:0b:4b:68:24:09:2b:ce:14:d7:4a:f9:8c:bd:c6:5a:e9"
$createSpec.subscription_info.automatic_sync_enabled = $true
$createSpec.subscription_info.subscription_url = "https://s3-us-west-1.amazonaws.com/vghetto-content-library/lib.json"
$createSpec.subscription_info.on_demand = $false
$createSpec.subscription_info.password = $null
$createSpec.server_guid = $null
$createspec.name = "virtuallyGhetto CL"
$createSpec.description = "@lamw CL: http://www.virtuallyghetto.com/2015/04/subscribe-to-vghetto-nested-esxi-template-content-library-in-vsphere-6-0.html"
$createSpec.type = "SUBSCRIBED"
$createSpec.publish_info = $null
$datastoreID = [VMware.VimAutomation.Cis.Core.Types.V1.ID]$datastoreID
$StorageSpec = New-Object PSObject -Property @{
    datastore_id = $datastoreID
    type         = "DATASTORE"
    }
$CreateSpec.storage_backings.Add($StorageSpec)
$UniqueID = [guid]::NewGuid().tostring()
$ContentCatalog.create($UniqueID, $createspec) | Out-File -Append -LiteralPath $verboseLogFile

My-Logger "Changing the default VSAN VM Storage Policy to FTT=0 & Force Provisioning to Yes ..."
$VSANPolicy = Get-SpbmStoragePolicy "Virtual SAN Default Storage Policy"
$Ruleset = New-SpbmRuleSet -Name “Rule-set 1” -AllOfRules @((New-SpbmRule -Capability VSAN.forceProvisioning $True), (New-SpbmRule -Capability VSAN.hostFailuresToTolerate 0))
$VSANPolicy | Set-SpbmStoragePolicy -RuleSet $Ruleset | Out-File -Append -LiteralPath $verboseLogFile

My-Logger "Enabling VM Autostart for the VCSA VM ..."
$VCVM = Get-VM
$vmstartpolicy = Get-VMStartPolicy -VM $VCVM
Set-VMHostStartPolicy (Get-VMHost $ESXIP | Get-VMHostStartPolicy) -Enabled:$true | Out-File -Append -LiteralPath $verboseLogFile
Set-VMStartPolicy -StartPolicy $vmstartpolicy -StartAction PowerOn -StartDelay 0 | Out-File -Append -LiteralPath $verboseLogFile

My-Logger "Enabling SSH on VCSA for easier troubleshooting ..."
$vcsassh = Get-CIsService com.vmware.appliance.access.ssh
$vcsassh.set($true)

$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes,2)

My-Logger "================================"
My-Logger "vSphere Lab Deployment Complete!"
My-Logger "StartTime: $StartTime"
My-Logger "  EndTime: $EndTime"
My-Logger " Duration: $duration minutes"
Write-Host ""
My-Logger "Access the vSphere Web Client at https://$VCIP/vsphere-client/"
My-Logger "Access the HTML5 vSphere Web Client at https://$VCIP/ui/"
My-Logger "Browse the vSphere REST APIs using the API Explorer here: https://$VCIP/apiexplorer/"
My-Logger "================================"
