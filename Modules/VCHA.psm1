Function Get-VCHAConfig {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
     Date:          Nov 20, 2016
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.SYNOPSIS
		This function retrieves the VCHA Configuration which provides you with
        the current state, mode as well as the IP Addresses of the Active,
        Passive & Witness Node. This is only available on VCSA 6.5 (vSphere 6.5 or greater)
	.DESCRIPTION
		Function to return VCHA Configuration
	.EXAMPLE
        Get-VCHAConfig
#>
    $vcHAClusterConfig = Get-View failoverClusterConfigurator
    $vcHAConfig = $vcHAClusterConfig.getVchaConfig()

    $vcHAState = $vcHAConfig.State
    switch($vcHAState) {
        configured {
            $activeIp = $vcHAConfig.FailoverNodeInfo1.ClusterIpSettings.Ip.IpAddress
            $passiveIp = $vcHAConfig.FailoverNodeInfo2.ClusterIpSettings.Ip.IpAddress
            $witnessIp = $vcHAConfig.WitnessNodeInfo.IpSettings.Ip.IpAddress

            $vcHAClusterManager = Get-View failoverClusterManager
            $vcHAMode = $vcHAClusterManager.getClusterMode()

            Write-Host ""
            Write-Host -NoNewline -ForegroundColor Green "VCHA State: "
            Write-Host -ForegroundColor White "$vcHAState"
            Write-Host -NoNewline -ForegroundColor Green " VCHA Mode: "
            Write-Host -ForegroundColor White "$vcHAMode"
            Write-Host -NoNewline -ForegroundColor Green "  ActiveIP: "
            Write-Host -ForegroundColor White "$activeIp"
            Write-Host -NoNewline -ForegroundColor Green " PassiveIP: "
            Write-Host -ForegroundColor White "$passiveIp"
            Write-Host -NoNewline -ForegroundColor Green " WitnessIP: "
            Write-Host -ForegroundColor White "$witnessIp`n"
            ;break
        }
        invalid { Write-Host -ForegroundColor Red "VCHA State is in invalid state ...";break}
        notConfigured { Write-Host "VCHA is not configured";break}
        prepared { Write-Host "VCHA is being prepared, please try again in a little bit ...";break}
    }
}

Function Get-VCHAClusterHealth {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
     Date:          Nov 20, 2016
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.SYNOPSIS
		This function retrieves the VCHA Cluster Health which provides more info
        on each of the individual. This is only available on VCSA 6.5 (vSphere 6.5 or greater)
	.DESCRIPTION
		Function to return VCHA Cluster Health
	.EXAMPLE
        Get-VCHAClusterHealth
#>
    $vcHAClusterConfig = Get-View failoverClusterConfigurator
    $vcHAConfig = $vcHAClusterConfig.getVchaConfig()
    $vcHAState = $vcHAConfig.State

    switch($vcHAState) {
        invalid { Write-Host -ForegroundColor Red "VCHA State is in invalid state ...";break}
        notConfigured { Write-Host "VCHA is not configured";break}
        prepared { Write-Host "VCHA is being prepared ...";break}
        configured {
            $vcHAClusterManager = Get-View failoverClusterManager
            $healthInfo = $vcHAClusterManager.GetVchaClusterHealth()

            $vcClusterState = $healthInfo.RuntimeInfo.ClusterState
            $nodeState = $healthInfo.RuntimeInfo.NodeInfo

            Write-Host ""
            Write-Host -NoNewline -ForegroundColor Green "VCHA Cluster State: "
            Write-Host -ForegroundColor White "$vcClusterState"
            Write-Host -NoNewline -ForegroundColor Green "VCHA Node Information: "
            $nodeState | Select NodeIp, NodeRole, NodeState
            ;break
        }
    }
}

Function Set-VCHAClusterMode {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
     Date:          Nov 20, 2016
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.SYNOPSIS
		This function allows you to set the mode of the VCHA Cluster whether
        that is Enabled, Disabled or in Maintenance Mode. This is only available on VCSA 6.5 (vSphere 6.5 or greater)
	.DESCRIPTION
		Function to set VCHA Cluster Mode
	.EXAMPLE
        Set-VCHAClusterMode -Enabled $true
	.EXAMPLE
        Set-VCHAClusterMode -Disabled $true
	.EXAMPLE
        Set-VCHAClusterMode -Maintenance $true
#>
    param(
        [Switch]$Enabled,
        [Switch]$Disabled,
        [Switch]$Maintenance
    )

    $vcHAClusterManager = Get-View failoverClusterManager

    if($Enabled) {
        Write-Host "Setting VCHA Cluster to Enabled ..."
        $task = $vcHAClusterManager.setClusterMode_Task("enabled")
        $task1 = Get-Task -Id ("Task-$($task.value)")
        $task1 | Wait-Task
    } elseIf($Maintenance) {
        Write-Host "Setting VCHA Cluster to Maintenance ..."
        $task = $vcHAClusterManager.setClusterMode_Task("maintenance")
        $task1 = Get-Task -Id ("Task-$($task.value)")
        $task1 | Wait-Task
    } elseIf($Disabled) {
        Write-Host "`nSetting VCHA Cluster to Disabled ...`n"
        $task = $vcHAClusterManager.setClusterMode_Task("disabled")
        $task1 = Get-Task -Id ("Task-$($task.value)")
        $task1 | Wait-Task
    }
}

Function New-VCHABasicConfig {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
     Date:          Nov 20, 2016
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.SYNOPSIS
		This function allows you create a new "Basic" VCHA Cluster, it does not
        cover the "Advanced" use case. You will need to ensure that you have a
        "Self Managed" vCenter Server before attempting this workflow.
        This is only available on VCSA 6.5 (vSphere 6.5 or greater)
	.DESCRIPTION
		Function to create "Basic" VCHA Cluster
    .PARAMETER VCSAVM
        The name of the vCenter Server Appliance (VCSA) in which you wish to enable VCHA on (must be self-managed)
    .PARAMETER HANetwork
        The name of the Virtual Portgroup or Distributed Portgroup used for the HA Network
    .PARAMETER ActiveHAIp
        The IP Address for the Active VCSA node
    .PARAMETER ActiveNetmask
        The Netmask for the Active VCSA node
    .PARAMETER PassiveHAIp
        The IP Address for the Passive VCSA node
    .PARAMETER PassiveNetmask
        The Netmask for the Passive VCSA node
    .PARAMETER WitnessHAIp
        The IP Address for the Witness VCSA node
    .PARAMETER WitnessNetmask
        The Netmask for the Witness VCSA node
    .PARAMETER PassiveDatastore
        The name of the datastore to deploy the Passive node to
    .PARAMETER WitnessDatastore
        The name of the datastore to deploy the Witness node to
    .PARAMETER VCUsername
        The VCSA username (e.g. administrator@vghetto.local)
    .PARAMETER VCPassword
        The VCSA password
	.EXAMPLE
        New-VCHABasicConfig -VCSAVM "vcenter65-1" -HANetwork "DVPG-VCHA-Network" `
            -ActiveHAIp 192.168.1.70 `
            -ActiveNetmask 255.255.255.0 `
            -PassiveHAIp 192.168.1.71 `
            -PassiveNetmask 255.255.255.0 `
            -WitnessHAIp 192.168.1.72 `
            -WitnessNetmask 255.255.255.0 `
            -PassiveDatastore "vsanDatastore" `
            -WitnessDatastore "vsanDatastore" `
            -VCUsername "administrator@vghetto.local" `
            -VCPassword "VMware1!"
#>
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String]$VCSAVM,
        [String]$HANetwork,
        [String]$ActiveHAIp,
        [String]$ActiveNetmask,
        [String]$PassiveHAIp,
        [String]$PassiveNetmask,
        [String]$PassiveDatastore,
        [String]$WitnessHAIp,
        [String]$WitnessNetmask,
        [String]$WitnessDatastore,
        # Crappy Implementation but need to research more into using PSH Credential
        [String]$VCUsername,
        [String]$VCPassword
     )

    $VCSAVMView = Get-View -ViewType VirtualMachine -Filter @{"name"=$VCSAVM}
    if($VCSAVMView -eq $null) {
        Write-Host -ForegroundColor Red "Error: Unable to find Virtual Machine $VCSAVM"
        return
    }

    $HANetworkView = Get-View -ViewType Network -Filter @{"name"=$HANetwork}
    if($HANetworkView -eq $null) {
        Write-Host -ForegroundColor Red "Error: Unable to find Network $HANetwork"
        return
    }

    $PassiveDatastoreView = Get-View -ViewType Datastore -Filter @{"name"=$PassiveDatastore}
    if($PassiveDatastoreView -eq $null) {
        Write-Host -ForegroundColor Red "Error: Unable to find Passive Datastore $PassiveDatastore"
        return
    }

    $WitnessDatastoreView = Get-View -ViewType Datastore -Filter @{"name"=$WitnessDatastore}
    if($WitnessDatastoreView -eq $null) {
        Write-Host -ForegroundColor Red "Error: Unable to find Witness Datastore $WitnessDatastore"
        return
    }

    $vcIP = $VCSAVMView.Guest.IpAddress
    if($vcIP -eq $null) {
        Write-Host -ForegroundColor Red "Error: Unable to automatically retrieve the IP Address of $VCSAVM which is needed to use this function"
        return
    }

    # Retrieve Source VC SSL Thumbprint
    $vcurl = "https://$vcIP"
add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;

            public class IDontCarePolicy : ICertificatePolicy {
            public IDontCarePolicy() {}
            public bool CheckValidationResult(
                ServicePoint sPoint, X509Certificate cert,
                WebRequest wRequest, int certProb) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy
    # Need to do simple GET connection for this method to work
    Invoke-RestMethod -Uri $VCURL -Method Get | Out-Null

    $endpoint_request = [System.Net.Webrequest]::Create("$vcurl")
    # Get Thumbprint + add colons for a valid Thumbprint
    $vcSSLThumbprint = ($endpoint_request.ServicePoint.Certificate.GetCertHashString()) -replace '(..(?!$))','$1:'

    $vcHAClusterConfig = Get-View failoverClusterConfigurator
    $spec = New-Object VMware.Vim.VchaClusterDeploymentSpec

    $activeNetworkConfig = New-Object VMware.Vim.ClusterNetworkConfigSpec
    $activeNetworkConfig.NetworkPortGroup = $HANetworkView.MoRef
    $ipSettings = New-Object Vmware.Vim.CustomizationIPSettings
    $ipSettings.SubnetMask = $ActiveNetmask
    $activeIpSpec = New-Object VMware.Vim.CustomizationFixedIp
    $activeIpSpec.IpAddress = $ActiveHAIp
    $ipSettings.Ip = $activeIpSpec
    $activeNetworkConfig.IpSettings = $ipSettings
    $spec.ActiveVcNetworkConfig = $activeNetworkConfig

    $activeVCConfig = New-Object Vmware.Vim.SourceNodeSpec
    $activeVCConfig.ActiveVc = $VCSAVMView.MoRef
    $serviceLocator = New-Object Vmware.Vim.ServiceLocator
    $credential = New-Object VMware.Vim.ServiceLocatorNamePassword
    $credential.username = $VCUsername
    $credential.password = $VCPassword
    $serviceLocator.Credential = $credential
    $serviceLocator.InstanceUuid = $global:DefaultVIServer.InstanceUuid
    $serviceLocator.Url = $vcurl
    $serviceLocator.SslThumbprint = $vcSSLThumbprint
    $activeVCConfig.ManagementVc = $serviceLocator
    $spec.ActiveVcSpec = $activeVCConfig

    $passiveSpec = New-Object VMware.Vim.PassiveNodeDeploymentSpec
    $passiveSpec.Folder = (Get-View (Get-Folder vm)).MoRef
    $passiveIpSettings = New-object Vmware.Vim.CustomizationIPSettings
    $passiveIpSettings.SubnetMask = $passiveNetmask
    $passiveIpSpec = New-Object VMware.Vim.CustomizationFixedIp
    $passiveIpSpec.IpAddress = $passiveHAIp
    $passiveIpSettings.Ip = $passiveIpSpec
    $passiveSpec.IpSettings = $passiveIpSettings
    $passiveSpec.NodeName = $VCSAVMView.Name + "-Passive"
    $passiveSpec.datastore = $PassiveDatastoreView.MoRef
    $spec.PassiveDeploymentSpec = $passiveSpec

    $witnessSpec = New-Object VMware.Vim.NodeDeploymentSpec
    $witnessSpec.Folder = (Get-View (Get-Folder vm)).MoRef
    $witnessSpec.NodeName = $VCSAVMView.Name + "-Witness"
    $witnessIpSettings = New-object Vmware.Vim.CustomizationIPSettings
    $witnessIpSettings.SubnetMask = $witnessNetmask
    $witnessIpSpec = New-Object VMware.Vim.CustomizationFixedIp
    $witnessIpSpec.IpAddress = $witnessHAIp
    $witnessIpSettings.Ip = $witnessIpSpec
    $witnessSpec.IpSettings = $witnessIpSettings
    $witnessSpec.datastore = $WitnessDatastoreView.MoRef
    $spec.WitnessDeploymentSpec = $witnessSpec

    Write-Host "`nDeploying VCHA Cluster ...`n"
    $task = $vcHAClusterConfig.deployVcha_Task($spec)
    $task1 = Get-Task -Id ("Task-$($task.value)")
    $task1 | Wait-Task -Verbose
}

Function Remove-VCHAConfig {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
     Date:          Nov 20, 2016
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.SYNOPSIS
		This function allows you destroy a VCHA Cluster. In addition, you have
        the option to specify whether you would like both the Passive & Witness
        Virtual Machines be deleted after the VCHA Cluster has been destroyed.
        This is only available on VCSA 6.5 (vSphere 6.5 or greater)
	.DESCRIPTION
		Function to destroy a VCHA Cluster Mode
	.EXAMPLE
        Remove-VCHAConfig
	.EXAMPLE
        Remove-VCHAConfig -Confirm:$false
	.EXAMPLE
        Remove-VCHAConfig -DeleteVM $true -Confirm:$false
    .NOTES
        Before you can destroy a VCHA Cluster, you must make sure it is first
        disabled. Run the Set-VCHAClusterMode -Disabled $true to do so
#>
    param(
        [Boolean]$Confirm=$true,
        [Switch]$DeleteVM=$false
    )

    $Verified = $false
    if($Confirm -eq $true) {
        Write-Host -ForegroundColor Yellow "`nDo you want to destroy VCHA Cluster?"
        $answer = Read-Host -Prompt "Do you accept (Y or N)"
        if($answer -eq "Y" -or $answer -eq "y") {
            $Verified = $true
        }
    } else {
        $Verified = $true
    }

    if($Verified) {
        $vcHAClusterManager = Get-View failoverClusterManager
        $vcHAMode = $vcHAClusterManager.getClusterMode()

        if($vcHAMode -ne "disabled") {
            Write-Host -ForegroundColor Yellow "To destroy VCHA Cluster, you must first set the VCHA Cluster Mode to `"Disabled`""
            Exit
        }

        # Query BIOS UUID of the Passive/Witness to be able to delete
        if($DeleteVM) {
            $vcHAClusterConfig = Get-View failoverClusterConfigurator
            $vcHAConfig = $vcHAClusterConfig.getVchaConfig()
            $passiveBiosUUID = $vcHAConfig.FailoverNodeInfo2.biosUuid
            $witnessBiosUUID = $vcHAConfig.WitnessNodeInfo.biosUuid
        }

        $vcHAClusterConfig = Get-View failoverClusterConfigurator

        Write-Host "Destroying VCHA Cluster ..."
        $task = $vcHAClusterConfig.destroyVcha_Task()
        $task1 = Get-Task -Id ("Task-$($task.value)")
        $task1 | Wait-Task

        # After VCHA Cluster has been destroyed, we can now delete the VMs we had queried earlier
        if($DeleteVM) {
            if($passiveBiosUUID -ne $null -and $witnessBiosUUID -ne $null) {
                $searchIndex = Get-View searchIndex

                $passiveVM = $searchIndex.FindByUuid($null,$passiveBiosUUID,$true,$null)
                $witnessVM = $searchIndex.FindByUuid($null,$witnessBiosUUID,$true,$null)

                if($passiveVM -ne $null -and $witnessVM -ne $null) {
                    Write-Host "Powering off & deleting Passive VM ..."
                    Stop-VM -VM (Get-View $passiveVM).Name -Confirm:$false | Out-Null
                    Remove-VM (Get-View $passiveVM).Name -DeletePermanently -Confirm:$false
                    Write-Host "Powering off & deleting Witness VM ..."
                    Stop-VM -VM (Get-View $witnessVM).Name -Confirm:$false | Out-Null
                    Remove-VM (Get-View $witnessVM).Name -DeletePermanently -Confirm:$false
                }
            }
        }
    }
}
