Function New-PHAProvider {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.DESCRIPTION
		Function to register a new Proactive HA Provider with vCenter Server
    .PARAMETER ProviderName
        Name of ProactiveHA Provider
    .PARAMETER ComponentType
        Name of a supported ComponentType that ProactiveHA supports (Fan, Memory, Network, Power or Storage)
    .PARAMETER ComponentDescription
        Description of the health check for the given component
    .PARAMETER ComponentId
        Unique identifier for the given component within a ProactiveHA Provider
	.EXAMPLE
        New-PHAProvider -ProviderName "virtuallyGhetto" -ComponentType Power -ComponentDescription "Simulated ProactiveHA Provider" -ComponentId "Power"
#>
    param(
        [Parameter(Mandatory=$true)][String]$ProviderName,
        [Parameter(Mandatory=$true)][ValidateSet("Fan","Memory","Network","Power","Storage")][String]$ComponentType,
        [Parameter(Mandatory=$true)][String]$ComponentDescription,
        [Parameter(Mandatory=$true)][String]$ComponentId
    )
    Write-Host -ForegroundColor Red "`n******************** DISCLAIMER ********************"
    Write-Host -ForegroundColor Red "****   THIS IS NOT INTENDED FOR PRODUCTION USE  ****"
    Write-Host -ForegroundColor Red "****          LEARNING PURPOSES ONLY            ****"
    Write-Host -ForegroundColor Red "******************** DISCLAIMER ********************`n"

    $healthManager = Get-View $global:DefaultVIServer.ExtensionData.Content.HealthUpdateManager

    $healthInfo = [VMware.Vim.HealthUpdateInfo] @{
        ComponentType = $ComponentType
        description = $ComponentDescription
        Id = $ComponentId
    }

    try {
        Write-Host "`nRegistering new Proactive HA Provider $ProviderName ..."
        $providerId = $healthManager.RegisterHealthUpdateProvider($ProviderName,$healthInfo)
    } catch {
        Write-host -ForegroundColor Red $Error[0].Exception
    }
}

Function Get-PHAProvider {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.DESCRIPTION
        Function to return list of all Proactive HA Providers registered with vCenter Server
	.EXAMPLE
        Get-PHAProvider
#>
    $healthManager = Get-View $global:DefaultVIServer.ExtensionData.Content.HealthUpdateManager

    $healthProviderResults = @()
    $hpIDs = $healthManager.QueryProviderList()

    foreach ($hpID in $hpIDs) {
        $hpName = $healthManager.QueryProviderName($hpID)
        $hpConfig = $healthManager.QueryHealthUpdateInfos($hpID)

        $hp = [pscustomobject] @{
            ProviderName = $hpName
            ProviderID = $hpID
            ComponentType = $hpConfig.componentType
            ComponentID = $hpConfig.id
            Description = $hpConfig.description
        }
        $healthProviderResults+=$hp
    }
    $healthProviderResults
}

Function Remove-PHAProvider {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.DESCRIPTION
        Function to remove a registered Proactive HA Provider from vCenter Server
    .PARAMETER ProviderId
        The ProactiveHA provider ID (retrieved from Get-PHAProvider) to unregister
	.EXAMPLE
        Remove-PHAProvider -ProviderID "52 85 22 c2 f2 6a e7 b9-fc ff 63 9e 10 81 00 79"
#>
    param(
        [Parameter(Mandatory=$true)][String]$ProviderId
    )

    Write-Host -ForegroundColor Red "`n******************** DISCLAIMER ********************"
    Write-Host -ForegroundColor Red "****   THIS IS NOT INTENDED FOR PRODUCTION USE  ****"
    Write-Host -ForegroundColor Red "****          LEARNING PURPOSES ONLY            ****"
    Write-Host -ForegroundColor Red "******************** DISCLAIMER ********************`n"

    $healthManager = Get-View $global:DefaultVIServer.ExtensionData.Content.HealthUpdateManager

    try {
        Write-Host "`nUnregistering Proactive HA Provider $ProviderId ... "
        $healthManager.UnregisterHealthUpdateProvider($providerId)
    } catch {
        if($Error[0].Exception.InnerException.MethodFault.getType().Name -eq "InvalidState") {
            Write-host -ForegroundColor Red "The Proactive HA Provider is still in use, please disable it before unregistering"
        } else {
            Write-host -ForegroundColor Red $Error[0].Exception
        }
    }
}

Function Set-PHAConfig {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.DESCRIPTION
        Function to enable/disable Proactive HA for vSphere Cluster
    .PARAMETER Cluster
        Name of the vSphere Cluster to enable Proactive HA
    .PARAMETER ProviderId
        Proactive HA Provider ID to enable in vSphere Cluster
    .PARAMETER ClusterMode
        Whether Proactive HA should be "Automated" or "Manual" for actions it will take
    .PARAMETER ModerateRemediation
        Type of operation (Maintenance Mode or Quaratine Mode) to perform when a Moderate issue is observed
    .PARAMETER SevereRemediation
        Type of operation (Maintenance Mode or Quaratine Mode) to perform when a Severe issue is observed
	.EXAMPLE
        Set-PHAConfig -Cluster VSAN-Cluster -Enabled -ClusterMode Automated -ModerateRemediation QuarantineMode -SevereRemediation QuarantineMode -ProviderID "52 85 22 c2 f2 6a e7 b9-fc ff 63 9e 10 81 00 79"
	.EXAMPLE
        Set-PHAConfig -Cluster VSAN-Cluster -Disabled -ProviderID "52 85 22 c2 f2 6a e7 b9-fc ff 63 9e 10 81 00 79"
#>
    param(
        [Parameter(Mandatory=$true)][String]$ProviderId,
        [Parameter(Mandatory=$true)][String]$Cluster,
        [Parameter(Mandatory=$false)][ValidateSet("Automated","Manual")]$ClusterMode="Manual",
        [Parameter(Mandatory=$false)][ValidateSet("MaintenanceMode","QuarantineMode")]$ModerateRemediation="QuarantineMode",
        [Parameter(Mandatory=$false)][ValidateSet("MaintenanceMode","QuarantineMode")]$SevereRemediation="QuarantineMode",
        [Switch]$Enabled,
        [Switch]$Disabled
    )

    $ClusterView = Get-View -ViewType ClusterComputeResource -Property Name,Host,ConfigurationEx -Filter @{"Name" = $Cluster}

    if($ClusterView -eq $null) {
        Write-Host -ForegroundColor Red "Unable to find vSphere Cluster $cluster ..."
        break
    }

    $vmhosts = $ClusterView.host

    $healthManager = Get-View $global:DefaultVIServer.ExtensionData.Content.HealthUpdateManager

    if($Enabled) {
        try {
            $entities = @()
            foreach ($vmhost in $vmhosts) {
                if(-not $healthManager.HasMonitoredEntity($ProviderId,$vmhost)) {
                    $entities += $vmhost
                }
            }

            Write-Host "Enabling Proactive HA monitoring for all ESXi hosts in cluster ..."
            $healthManager.AddMonitoredEntities($ProviderId,$entities)
        } catch {
            Write-host -ForegroundColor Red $Error[0].Exception
        }

        try {
            $healthProviders = @()

            # Make sure not to remove existing ProactiveHA providers
            if($ClusterView.ConfigurationEx.InfraUpdateHaConfig.Providers -ne $null) {
                $currentHPs = $ClusterView.ConfigurationEx.infraUpdateHaConfig.providers
                foreach ($currentHP in $currentHPs) {
                    $healthProviders+=$currentHP
                }
                if(-not ($healthProviders -contains $ProviderID)) {
                    $healthProviders+=$ProviderId
                }
            } else {
                $healthProviders+=$ProviderId
            }

            $PHASpec = [VMware.Vim.ClusterInfraUpdateHaConfigInfo] @{
                enabled = $true
                behavior = $ClusterMode
                moderateRemediation = $ModerateRemediation
                severeRemediation = $SevereRemediation
                providers = $healthProviders
            }

            $spec = [VMware.Vim.ClusterConfigSpecEx] @{
                infraUpdateHaConfig = $PHASpec
            }

            Write-Host "Enabling Proactive HA Provider $ProviderId on $Cluster ..."
            $task = $ClusterView.ReconfigureComputeResource_Task($spec,$True)
            $task1 = Get-Task -Id ("Task-$($task.value)")
            $task1 | Wait-Task | Out-Null
        } catch {
            Write-host -ForegroundColor Red $Error[0].Exception
        }
    }

    if($Disabled) {
        foreach ($vmhost in $vmhosts) {
            if($vmhost.runtime.inQuarantineMode) {
                Write-Host -ForegroundColor Red $vmhost.name " is currently still in Quaratine Mode, please remediate this before disabling Proactive HA"
                break
            }
        }

        try {
            $healthProviders = @()

            # Make sure not to remove existing ProactiveHA providers
            if($ClusterView.ConfigurationEx.InfraUpdateHaConfig.Providers -ne $null) {
                $currentHPs = $ClusterView.ConfigurationEx.infraUpdateHaConfig.providers
                foreach ($currentHP in $currentHPs) {
                    if($currentHP -ne $ProviderId) {
                        $healthProviders+=$currentHP
                    }
                }
            }

            $PHASpec = [VMware.Vim.ClusterInfraUpdateHaConfigInfo] @{
                enabled = $true
                behavior = $ClusterMode
                moderateRemediation = $ModerateRemediation
                severeRemediation = $SevereRemediation
                providers = $healthProviders
            }

            $spec = [VMware.Vim.ClusterConfigSpecEx] @{
                infraUpdateHaConfig = $PHASpec
            }

            Write-Host "Disabling Proactive HA Provider $ProviderId on $Cluster ..."
            $task = $ClusterView.ReconfigureComputeResource_Task($spec,$True)
            $task1 = Get-Task -Id ("Task-$($task.value)")
            $task1 | Wait-Task | Out-Null
        } catch {
            Write-host -ForegroundColor Red $Error[0].Exception
        }

        $ClusterView.UpdateViewData()

        try {
            $entities = @()
            foreach ($vmhost in $vmhosts) {
                if($healthManager.HasMonitoredEntity($ProviderId,$vmhost)) {
                    $entities += $vmhost
                }
            }

            Write-Host "Disabling Proactive HA monitoring for all ESXi hosts in cluster ..."
            $healthManager.RemoveMonitoredEntities($ProviderId,$entities)
        } catch {
            Write-host -ForegroundColor Red $Error[0].Exception
        }
    }
}

Function Get-PHAConfig {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.DESCRIPTION
        Function to retrieve Proactive HA configuration for a vSphere Cluster
    .PARAMETER Cluster
        Name of the vSphere Cluster to check Proactive HA configuration
	.EXAMPLE
        Get-PHAConfig -Cluster VSAN-Cluster
#>
    param(
        [Parameter(Mandatory=$true)][String]$Cluster
    )

    $ClusterView = Get-View -ViewType ClusterComputeResource -Property Name,ConfigurationEx -Filter @{"Name" = $Cluster}

    if($ClusterView -eq $null) {
        Write-Host -ForegroundColor Red "Unable to find vSphere Cluster $cluster ..."
        break
    }

    if($ClusterView.ConfigurationEx.InfraUpdateHaConfig.Providers -ne $null) {
        $healthManager = Get-View $global:DefaultVIServer.ExtensionData.Content.HealthUpdateManager

        $phSettings = $ClusterView.ConfigurationEx.InfraUpdateHaConfig
        $providers = $ClusterView.ConfigurationEx.InfraUpdateHaConfig.Providers
        $healthProviders = @()
        foreach ($provider in $providers) {
            $providerName = $healthManager.QueryProviderName($provider)
            $healthProviders+=$providerName
        }

        $pHAConfig = [pscustomobject] @{
            Enabled = $phSettings.Enabled
            ClusterMode = $phSettings.behavior
            ModerateRemediation = $phSettings.ModerateRemediation
            SevereRemediation = $phSettings.SevereRemediation
            HealthProviders = $healthProviders
        }
        $pHAConfig
    } else {
        Write-Host "Proactive HA has not been configured on this vSphere Cluster"
    }
}

Function Get-PHAHealth {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.DESCRIPTION
		Function to retrieve the Proactive HA health info for all ESXi hosts in vSphere Cluster
    .PARAMETER Cluster
        Name of the vSphere Cluster to check Proactive HA health information
	.EXAMPLE
        Get-PHAHealth -Cluster VSAN-Cluster
#>
    param(
        [Parameter(Mandatory=$true)][String]$Cluster
    )

    $ClusterView = Get-View -ViewType ClusterComputeResource -Property Name,ConfigurationEx -Filter @{"Name" = $Cluster}

    if($ClusterView -eq $null) {
        Write-Host -ForegroundColor Red "Unable to find vSphere Cluster $cluster ..."
        break
    }

    if($ClusterView.ConfigurationEx.InfraUpdateHaConfig.Providers -ne $null) {
        $healthManager = Get-View $global:DefaultVIServer.ExtensionData.Content.HealthUpdateManager

        $providers = $ClusterView.ConfigurationEx.InfraUpdateHaConfig.Providers

        foreach ($provider in $providers) {
            $providerName = $healthManager.QueryProviderName($provider)
            $healthUpdates = $healthManager.QueryHealthUpdates($provider)

            $healthResults = @()
            Write-Host -NoNewline -ForegroundColor Magenta "Health summary for Proactive HA Provider $providerName`:`n"
            foreach ($healthUpdate in $healthUpdates) {
                $vmhost = Get-View $healthUpdate.Entity

                $hr = [PSCustomObject] @{
                    Entity = $vmhost.name
                    Status = $healthUpdate.status
                    HealthComponentId = $healthUpdate.HealthUpdateInfoId
                    HealthUpdateId = $healthUpdate.Id
                    Remediation = $healthUpdate.Remediation
                }
                $healthResults+=$hr
            }
            $healthResults
        }
    } else {
        Write-Host "Proactive HA has not been configured on this vSphere Cluster"
    }
}

Function New-PHASimulation {
<#
    .NOTES
    ===========================================================================
	 Created by:   	William Lam
	 Organization: 	VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
	.DESCRIPTION
		Function to return VCHA Configuration
    .PARAMETER ProviderId
        The Proactive HA Provider ID that you like to simulate a health update from
    .PARAMETER EsxiHost
        The name of ESXi host to update the health on
    .PARAMETER Component
        The name of the matching component ID from Proactive HA Provider to simulate a health update from
    .PARAMETER HealthStatus
        The health value (green, yellow or red) for the given simulated health Update
    .PARAMETER Remediation
        The remediation message associated with simulated health update
	.EXAMPLE
        New-PHASimulation -EsxiHost vesxi65-4.primp-industries.com -Component Power -HealthStatus green -Remediation "" -ProviderId "52 85 22 c2 f2 6a e7 b9-fc ff 63 9e 10 81 00 79"
	.EXAMPLE
        New-PHASimulation -EsxiHost vesxi65-4.primp-industries.com -Component Power -HealthStatus red -Remediation "Please replace my virtual PSU" -ProviderId "52 85 22 c2 f2 6a e7 b9-fc ff 63 9e 10 81 00 79"
#>
    param(
        [Parameter(Mandatory=$true)][String]$ProviderId,
        [Parameter(Mandatory=$true)][String]$EsxiHost,
        [Parameter(Mandatory=$true)][String]$Component,
        [Parameter(Mandatory=$true)][ValidateSet("green","red","yellow")][String]$HealthStatus,
        [Parameter(Mandatory=$false)][String]$Remediation
    )

    Write-Host -ForegroundColor Red "`n******************** DISCLAIMER ********************"
    Write-Host -ForegroundColor Red "****   THIS IS NOT INTENDED FOR PRODUCTION USE  ****"
    Write-Host -ForegroundColor Red "****          LEARNING PURPOSES ONLY            ****"
    Write-Host -ForegroundColor Red "******************** DISCLAIMER ********************`n"

    $vmhost = Get-View -ViewType HostSystem -Property Name -Filter @{"name" = $EsxiHost}

    if($vmhost -eq $null) {
        Write-Host -ForegroundColor Red "`nUnable to find ESXi host $EsxiHost ..."
        break
    }

    $healthManager = Get-View $global:DefaultVIServer.ExtensionData.Content.HealthUpdateManager

    # Randomly generating an ID for Health Update
    # In general, you would want to generate a specific ID
    # which can be referenced between ProactiveHA Provider
    # and VMware logs for troubleshooting purposes
    $HealthUpdateID = "vghetto-" + (Get-Random -Minimum 1 -Maximum 100000)

    # All other Health Status can have a remediation message
    # but for green, it must be an empty string or API call will fail
    if($HealthStatus -eq "green") {
        $Remediation = ""
    }

    $healthUpdate = [VMware.Vim.HealthUpdate] @{
        Entity = $vmhost.moref
        HealthUpdateInfoId = $Component
        Id = $HealthUpdateId
        Status = $HealthStatus
        Remediation = $Remediation
    }

    try {
        Write-Host "`nSimulating Proactive HA Health Update to ..."
        Write-Host "`tHost: $EsxiHost "
        Write-Host -NoNewline "`tStatus: "
        Write-Host -ForegroundColor $HealthStatus "$HealthStatus"
        Write-Host "`tRemediation Messsage: $Remediation"
        $healthManager.PostHealthUpdates($providerId,$healthUpdate)
    } catch {
        Write-host -ForegroundColor Red $Error[0].Exception
    }
}