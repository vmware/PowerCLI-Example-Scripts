<#
Script name: ha-vcenter-deploy.ps1
Created on: 30/06/2017
Author: Sam McGeown, @sammcgeown
Description: The purpose of the script is to deploy vCenter in High Availability mode, using the advanced method. See https://www.definit.co.uk/2017/06/powershell-deploying-vcenter-high-availability-in-advanced-mode/
Dependencies: None known
#>
param(
	[Parameter(Mandatory=$true)] [String]$configFile,
	[switch]$deployActive,
	[switch]$licenseVCSA,
	[switch]$addSecondaryNic,
	[switch]$prepareVCHA,
	[switch]$clonePassiveVM,
	[switch]$cloneWitnessVM,
	[switch]$configureVCHA,
	[switch]$resizeWitness,
	[switch]$createDRSRule
)

if($psboundparameters.count -eq 1) {
	# Only the configFile is passed, set all steps to true
	$deployActive = $true
	$licenseVCSA = $true
	$addSecondaryNic = $true
	$prepareVCHA = $true
	$clonePassiveVM = $true
	$cloneWitnessVM = $true
	$configureVCHA = $true
	$resizeWitness = $true
	$createDRSRule = $true
}

# Import the PowerCLI and DNS modules
Get-Module -ListAvailable VMware*,DnsServer | Import-Module
if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
	throw "PowerCLI must be installed"
}
# Written by Sam McGeown @sammcgeown - www.definit.co.uk
# Hat tips and thanks go to...
# William Lam http://www.virtuallyghetto.com/2016/11/vghetto-automated-vsphere-lab-deployment-for-vsphere-6-0u2-vsphere-6-5.html
#             http://www.virtuallyghetto.com/2017/01/exploring-new-vcsa-vami-api-wpowercli-part-1.html

# Get the folder location
$ScriptLocation = Split-Path -Parent $PSCommandPath

# Import the JSON Config File
$podConfig = (get-content $($configFile) -Raw) | ConvertFrom-Json

# Path to VCSA Install Sources
$VCSAInstaller  = "$($podConfig.sources.VCSAInstaller)"

# Log File
$verboseLogFile = $podConfig.general.log

$StartTime = Get-Date

Function Write-Log {
	param(
		[Parameter(Mandatory=$true)]
		[String]$message,
		[switch]$Warning,
		[switch]$Info
	)
	$timeStamp = Get-Date -Format "dd-MM-yyyy hh:mm:ss"
	Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
	if($Warning){
		Write-Host -ForegroundColor Yellow " WARNING: $message"
	} elseif($Info) {
		Write-Host -ForegroundColor White " $message"
	}else {
		Write-Host -ForegroundColor Green " $message"
	}
	$logMessage = "[$timeStamp] $message" | Out-File -Append -LiteralPath $verboseLogFile
}

function Get-VCSAConnection {
	param(
		[string]$vcsaName,
		[string]$vcsaUser,
		[string]$vcsaPassword
	)
	$existingConnection =  $global:DefaultVIServers | where-object -Property Name -eq -Value $vcsaName
	if($existingConnection -ne $null) {
		return $existingConnection;
	} else {
        $connection = Connect-VIServer -Server $vcsaName -User $vcsaUser -Password $vcsaPassword -WarningAction SilentlyContinue;
		if($connection -ne $null) {
			return $connection;
		} else {
			throw "Unable to connect to $($vcsaName)..."
		}
	}
}

function Close-VCSAConnection {
	param(
		[string]$vcsaName
	)
	if($vcsaName.Length -le 0) {
		if($Global:DefaultVIServers -ne $null) {
			Disconnect-VIServer -Server $Global:DefaultVIServers -Confirm:$false -ErrorAction SilentlyContinue
		}
	} else {
		$existingConnection =  $global:DefaultVIServers | where-object -Property Name -eq -Value $vcsaName
        if($existingConnection -ne $null) {
		    Disconnect-VIServer -Server $existingConnection -Confirm:$false;
        } else {
            Write-Warning -Message "Could not find an existing connection named $($vcsaName)"
        }
	}
}

function Get-PodFolder {
	param(
		$vcsaConnection,
		[string]$folderPath
	)
	$folderArray = $folderPath.split("/")
	$parentFolder = Get-Folder -Server $vcsaConnection -Name vm
	foreach($folder in $folderArray) {
		$folderExists = Get-Folder -Server $vcsaConnection | Where-Object -Property Name -eq -Value $folder
		if($folderExists -ne $null) {
			$parentFolder = $folderExists
		} else {
			$parentFolder = New-Folder -Name $folder -Location $parentFolder
		}
	}
	return $parentFolder
}


Close-VCSAConnection

if($deployActive) {
	Write-Log "#### Deploying Active VCSA ####"
	$pVCSA = Get-VCSAConnection -vcsaName $podConfig.target.server -vcsaUser $podConfig.target.user -vcsaPassword $podConfig.target.password
	$pCluster = Get-Cluster -Name $podConfig.target.cluster -Server $pVCSA
	$pDatastore = Get-Datastore -Name $podConfig.target.datastore -Server $pVCSA
	$pPortGroup = Get-VDPortgroup -Name $podConfig.target.portgroup -Server $pVCSA
	$pFolder = Get-PodFolder -vcsaConnection $pVCSA -folderPath $podConfig.target.folder
	
	Write-Log "Disabling DRS on $($podConfig.target.cluster)"
	$pCluster | Set-Cluster -DrsEnabled:$true -DrsAutomationLevel:PartiallyAutomated -Confirm:$false |  Out-File -Append -LiteralPath $verboseLogFile

	
	Write-Log "Creating DNS Record"
	Add-DnsServerResourceRecordA -Name $podConfig.active.name -ZoneName $podConfig.target.network.domain -AllowUpdateAny -IPv4Address $podConfig.active.ip -ComputerName "192.168.1.20" -CreatePtr -ErrorAction SilentlyContinue

	Write-Log "Deploying VCSA"
	$config = (Get-Content -Raw "$($VCSAInstaller)\vcsa-cli-installer\templates\install\embedded_vCSA_on_VC.json") | convertfrom-json
	$config.'new.vcsa'.vc.hostname = $podConfig.target.server
	$config.'new.vcsa'.vc.username = $podConfig.target.user
	$config.'new.vcsa'.vc.password = $podConfig.target.password
	$config.'new.vcsa'.vc.datacenter = @($podConfig.target.datacenter)
	$config.'new.vcsa'.vc.datastore = $podConfig.target.datastore
	$config.'new.vcsa'.vc.target = @($podConfig.target.cluster)
	$config.'new.vcsa'.vc.'deployment.network' = $podConfig.target.portgroup
	$config.'new.vcsa'.os.'ssh.enable' = $podConfig.general.ssh
	$config.'new.vcsa'.os.password = $podConfig.active.rootPassword
	$config.'new.vcsa'.appliance.'thin.disk.mode' = $true
	$config.'new.vcsa'.appliance.'deployment.option' = $podConfig.active.deploymentSize
	$config.'new.vcsa'.appliance.name = $podConfig.active.name
	$config.'new.vcsa'.network.'system.name' = $podConfig.active.hostname
	$config.'new.vcsa'.network.'ip.family' = "ipv4"
	$config.'new.vcsa'.network.mode = "static"
	$config.'new.vcsa'.network.ip = $podConfig.active.ip
	$config.'new.vcsa'.network.'dns.servers'[0] = $podConfig.target.network.dns
	$config.'new.vcsa'.network.prefix = $podConfig.target.network.prefix
	$config.'new.vcsa'.network.gateway = $podConfig.target.network.gateway
	$config.'new.vcsa'.sso.password = $podConfig.active.sso.password
	$config.'new.vcsa'.sso.'domain-name' = $podConfig.active.sso.domain
	$config.'new.vcsa'.sso.'site-name' = $podConfig.active.sso.site
	
	Write-Log "Creating VCSA JSON Configuration file for deployment"
	
	$config | ConvertTo-Json | Set-Content -Path "$($ENV:Temp)\active.json"
	if((Get-VM | Where-Object -Property Name -eq -Value $podConfig.active.name) -eq $null) {
		Write-Log "Deploying OVF, this may take a while..."
		Invoke-Expression "$($VCSAInstaller)\vcsa-cli-installer\win32\vcsa-deploy.exe install --no-esx-ssl-verify --accept-eula --acknowledge-ceip $($ENV:Temp)\active.json"| Out-File -Append -LiteralPath $verboseLogFile
		$vcsaDeployOutput | Out-File -Append -LiteralPath $verboseLogFile
		Write-Log "Moving $($podConfig.active.name) to $($podConfig.target.folder)"
		if((Get-VM | where {$_.name -eq $podConfig.active.name}) -eq $null) {
			throw "Could not find VCSA VM. The script was unable to find the deployed VCSA"
		}
		Get-VM -Name $podConfig.active.name | Move-VM -Destination $pFolder |  Out-File -Append -LiteralPath $verboseLogFile
	} else {
		Write-Log "VCSA exists, skipping" -Warning
	}
	Close-VCSAConnection
}


if($licenseVCSA) {
	Write-Log "#### Configuring VCSA ####"
	Write-Log "Getting connection to the new VCSA"
	$nVCSA = Get-VCSAConnection -vcsaName $podConfig.active.ip -vcsaUser "administrator@$($podConfig.active.sso.domain)" -vcsaPassword $podConfig.active.sso.password

	Write-Log "Installing vCenter License"
	$serviceInstance = Get-View ServiceInstance -Server $nVCSA
	$licenseManagerRef=$serviceInstance.Content.LicenseManager
	$licenseManager=Get-View $licenseManagerRef
	$licenseManager.AddLicense($podConfig.license.vcenter,$null) |  Out-File -Append -LiteralPath $verboseLogFile
	$licenseAssignmentManager = Get-View $licenseManager.LicenseAssignmentManager
	Write-Log "Assigning vCenter Server License"
	try {
		$licenseAssignmentManager.UpdateAssignedLicense($nVCSA.InstanceUuid, $podConfig.license.vcenter, $null) | Out-File -Append -LiteralPath $verboseLogFile
	}
	catch {
		$ErrorMessage = $_.Exception.Message
		Write-Log $ErrorMessage -Warning
	}
	Close-VCSAConnection -vcsaName $podConfig.active.ip
}

if($addSecondaryNic) {
	Write-Log "#### Adding HA Network Adapter ####"
	$pVCSA = Get-VCSAConnection -vcsaName $podConfig.target.server -vcsaUser $podConfig.target.user -vcsaPassword $podConfig.target.password
	
	if((Get-VM -Server $pVCSA -Name $podConfig.active.name | Get-NetworkAdapter).count -le 1) {
		Write-Log "Adding HA interface"
		Get-VM -Server $pVCSA -Name $podConfig.active.name | New-NetworkAdapter -Portgroup (Get-VDPortgroup -Name $podConfig.target."ha-portgroup") -Type Vmxnet3 -StartConnected |  Out-File -Append -LiteralPath $verboseLogFile
	}
	Close-VCSAConnection

	$nVCSA = Get-VCSAConnection -vcsaName $podConfig.active.ip -vcsaUser "administrator@$($podConfig.active.sso.domain)" -vcsaPassword $podConfig.active.sso.password

	Write-Log "Configuring HA interface"
	$CisServer = Connect-CisServer -Server $podConfig.active.ip -User "administrator@$($podConfig.active.sso.domain)" -Password $podConfig.active.sso.password

	$ipv4API = (Get-CisService -Name 'com.vmware.appliance.techpreview.networking.ipv4')
	$specList = $ipv4API.Help.set.config.CreateExample()
	$createSpec = [pscustomobject] @{
		address = $podConfig.active."ha-ip";
		default_gateway = "";
		interface_name = "nic1";
		mode = "is_static";
		prefix = "29";
	}
	$specList += $createSpec
	$ipv4API.set($specList)
	Close-VCSAConnection
}

if($prepareVCHA) {
	Write-Log "#### Preparing vCenter HA mode ####"

	$nVCSA = Get-VCSAConnection -vcsaName $podConfig.active.ip -vcsaUser "administrator@$($podConfig.active.sso.domain)" -vcsaPassword $podConfig.active.sso.password

	Write-Log "Preparing vCenter HA"
	$ClusterConfig = Get-View failoverClusterConfigurator

    $PassiveIpSpec = New-Object VMware.Vim.CustomizationFixedIp
    $PassiveIpSpec.IpAddress = $podConfig.cluster."passive-ip"

	$PassiveNetwork = New-object VMware.Vim.CustomizationIPSettings
	$PassiveNetwork.Ip =  $PassiveIpSpec
	$PassiveNetwork.SubnetMask = $podConfig.cluster."ha-mask"

	$PassiveNetworkSpec = New-Object Vmware.Vim.PassiveNodeNetworkSpec
	$PassiveNetworkSpec.IpSettings = $PassiveNetwork

    $WitnessIpSpec = New-Object VMware.Vim.CustomizationFixedIp
    $WitnessIpSpec.IpAddress = $podConfig.cluster."witness-ip"

	$WitnessNetwork = New-object VMware.Vim.CustomizationIPSettings
	$WitnessNetwork.Ip =  $WitnessIpSpec
	$WitnessNetwork.SubnetMask = $podConfig.cluster."ha-mask"

	$WitnessNetworkSpec = New-Object VMware.Vim.NodeNetworkSpec
	$WitnessNetworkSpec.IpSettings = $WitnessNetwork
	
	$ClusterNetworkSpec = New-Object VMware.Vim.VchaClusterNetworkSpec
	$ClusterNetworkSpec.WitnessNetworkSpec = $WitnessNetworkSpec
	$ClusterNetworkSpec.PassiveNetworkSpec = $PassiveNetworkSpec
	
	$PrepareTask = $ClusterConfig.prepareVcha_task($ClusterNetworkSpec)

	Close-VCSAConnection
}

if($clonePassiveVM) {
	Write-Log "#### Cloning VCSA for Passive Node ####"

	$pVCSA = Get-VCSAConnection -vcsaName $podConfig.target.server -vcsaUser $podConfig.target.user -vcsaPassword $podConfig.target.password
	$pVMHost = Get-Random (Get-VMhost -Location $podConfig.target.cluster)
	$pFolder = Get-PodFolder -vcsaConnection $pVCSA -folderPath $podConfig.target.folder

	$activeVM = Get-VM -Name $podConfig.active.name
	$CloneSpecName = "vCHA_ClonePassive"
	
	Write-Log "Creating customization spec"
	# Clean up any old spec
	Get-OSCustomizationSpec -Name $CloneSpecName -ErrorAction SilentlyContinue | Remove-OSCustomizationSpec -Confirm:$false -ErrorAction SilentlyContinue |  Out-File -Append -LiteralPath $verboseLogFile
	New-OSCustomizationSpec -Name $CloneSpecName -OSType Linux -Domain $podConfig.target.network.domain -NamingScheme fixed -DnsSuffix $podConfig.target.network.domain -NamingPrefix $podConfig.active.hostname -DnsServer $podConfig.target.network.dns -Type NonPersistent |  Out-File -Append -LiteralPath $verboseLogFile
	Get-OSCustomizationNicMapping -OSCustomizationSpec $CloneSpecName | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $podConfig.active.ip -SubnetMask $podConfig.target.network.netmask -DefaultGateway $podConfig.target.network.gateway |  Out-File -Append -LiteralPath $verboseLogFile
	New-OSCustomizationNicMapping -OSCustomizationSpec $CloneSpecName -IpMode UseStaticIP -IpAddress $podConfig.cluster."passive-ip" -SubnetMask $podConfig.cluster."ha-mask" -DefaultGateway $podConfig.target.network.gateway |  Out-File -Append -LiteralPath $verboseLogFile

	Write-Log "Cloning Active VCSA to Passive VCSA"
	$passiveVM = New-VM -Name $podConfig.cluster."passive-name" -VM $activeVM -OSCustomizationSpec $CloneSpecName -VMhost $pVMHost -Server $pVCSA -Location $pFolder | Start-VM | Out-File -Append -LiteralPath $verboseLogFile
	
	# Ensure the network adapters are connected
	$passiveVM | Get-NetworkAdapter | Set-NetworkAdapter -Connected:$true -Confirm:$false

	Write-Log "Waiting for VMware Tools"
	$passiveVM | Wait-Tools

	Close-VCSAConnection
}

if($cloneWitnessVM) {
	Write-Log "#### Cloning VCSA for Witness Node ####"

	$pVCSA = Get-VCSAConnection -vcsaName $podConfig.target.server -vcsaUser $podConfig.target.user -vcsaPassword $podConfig.target.password
	$pVMHost = Get-Random (Get-VMhost -Location $podConfig.target.cluster)
	$pFolder = Get-PodFolder -vcsaConnection $pVCSA -folderPath $podConfig.target.folder

	$activeVM = Get-VM -Name $podConfig.active.name
	$CloneSpecName = "vCHA_CloneWitness"

	Write-Log "Creating customization spec"
	# Clean up any old spec
	Get-OSCustomizationSpec -Name $CloneSpecName -ErrorAction SilentlyContinue | Remove-OSCustomizationSpec -Confirm:$false -ErrorAction SilentlyContinue |  Out-File -Append -LiteralPath $verboseLogFile
	New-OSCustomizationSpec -Name $CloneSpecName -OSType Linux -Domain $podConfig.target.network.domain -NamingScheme fixed -DnsSuffix $podConfig.target.network.domain -NamingPrefix $podConfig.active.hostname -DnsServer $podConfig.target.network.dns -Type NonPersistent |  Out-File -Append -LiteralPath $verboseLogFile
	New-OSCustomizationNicMapping -OSCustomizationSpec $CloneSpecName -IpMode UseStaticIP -IpAddress $podConfig.cluster."witness-ip" -SubnetMask $podConfig.cluster."ha-mask" -DefaultGateway $podConfig.target.network.gateway |  Out-File -Append -LiteralPath $verboseLogFile

	Write-Log "Cloning Active VCSA to Witness VCSA"
	$witnessVM = New-VM -Name $podConfig.cluster."witness-name" -VM $activeVM -OSCustomizationSpec $CloneSpecName -VMhost $pVMHost -Server $pVCSA -Location $pFolder | Start-VM | Out-File -Append -LiteralPath $verboseLogFile
	
	# Ensure the network adapters are connected
	$witnessVM | Get-NetworkAdapter | Set-NetworkAdapter -Connected:$true -Confirm:$false
	
	Write-Log "Waiting for VMware Tools"
	$witnessVM | Wait-Tools

	Close-VCSAConnection
}

if($configureVCHA) {
	Write-Log "#### Configuring vCenter HA mode ####"

	$nVCSA = Get-VCSAConnection -vcsaName $podConfig.active.ip -vcsaUser "administrator@$($podConfig.active.sso.domain)" -vcsaPassword $podConfig.active.sso.password

	$ClusterConfig = Get-View failoverClusterConfigurator
	$ClusterConfigSpec = New-Object VMware.Vim.VchaClusterConfigSpec
	$ClusterConfigSpec.PassiveIp = $podConfig.cluster."passive-ip"
	$ClusterConfigSpec.WitnessIp = $podConfig.cluster."witness-ip"
	$ConfigureTask = $ClusterConfig.configureVcha_task($ClusterConfigSpec)
	Write-Log "Waiting for cluster configuration task"
	Start-Sleep -Seconds 30
	
	Close-VCSAConnection -vcsaName $podConfig.active.ip
}

if($resizeWitness) {
	Write-Log "#### Resizing Witness Node ####"
	$pVCSA = Get-VCSAConnection -vcsaName $podConfig.target.server -vcsaUser $podConfig.target.user -vcsaPassword $podConfig.target.password
	
	$witnessVM = Get-VM -Name $podConfig.cluster."witness-name"
	Write-Log "Waiting for Witness node to shut down"
	$witnessVM | Stop-VMGuest -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
	do {
		Start-Sleep -Seconds 3
		$witnessVM = Get-VM -Name $podConfig.cluster."witness-name"
	} until($witnessVM.PowerState -eq "Poweredoff")
	Write-Log "Setting CPU and Memory"
	$witnessVM | Set-VM -MemoryGB 1 -NumCpu 1 -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
	Write-Log "Starting Witness VM"
	$witnessVM | Start-VM | Out-File -Append -LiteralPath $verboseLogFile
	Close-VCSAConnection
}

if($createDRSRule) {
	Write-Log "#### Creating DRS Rule ####"
	$pVCSA = Get-VCSAConnection -vcsaName $podConfig.target.server -vcsaUser $podConfig.target.user -vcsaPassword $podConfig.target.password
	$pCluster = Get-Cluster $podConfig.target.cluster
	$vCHA = Get-VM -Name $podConfig.active.name,$podConfig.cluster."passive-name",$podConfig.cluster."witness-name" 
	New-DRSRule -Name "vCenter HA" -Cluster $pCluster -VM $vCHA -KeepTogether $false | Out-File -Append -LiteralPath $verboseLogFile
	Write-Log "Enabling DRS on $($podConfig.target.cluster)"
	$pCluster | Set-Cluster -DrsEnabled:$true -DrsAutomationLevel:FullyAutomated -Confirm:$false |  Out-File -Append -LiteralPath $verboseLogFile
	Close-VCSAConnection
}


$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes,2)

Write-Log "Pod Deployment Completed in $($duration) minutes"