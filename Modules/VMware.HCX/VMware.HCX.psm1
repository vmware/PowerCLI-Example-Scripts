<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
Function Connect-HcxServer {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Connect to the HCX Enterprise Manager
    .DESCRIPTION
        This cmdlet connects to the HCX Enterprise Manager
    .EXAMPLE
        Connect-HcxServer -Server $HCXServer -Username $Username -Password $Password
#>
    Param (
        [Parameter(Mandatory=$true)][String]$Server,
        [Parameter(Mandatory=$true)][String]$Username,
        [Parameter(Mandatory=$true)][String]$Password
    )

    $payload = @{
        "username" = $Username
        "password" = $Password
    }
    $body = $payload | ConvertTo-Json

    $hcxLoginUrl = "https://$Server/hybridity/api/sessions"

    if($PSVersionTable.PSEdition -eq "Core") {
        $results = Invoke-WebRequest -Uri $hcxLoginUrl -Body $body -Method POST -UseBasicParsing -ContentType "application/json" -SkipCertificateCheck
    } else {
        $results = Invoke-WebRequest -Uri $hcxLoginUrl -Body $body -Method POST -UseBasicParsing -ContentType "application/json"
    }

    if($results.StatusCode -eq 200) {
        $hcxAuthToken = $results.Headers.'x-hm-authorization'

        $headers = @{
            "x-hm-authorization"="$hcxAuthToken"
            "Content-Type"="application/json"
            "Accept"="application/json"
        }

        $global:hcxConnection = new-object PSObject -Property @{
            'Server' = "https://$server/hybridity/api";
            'headers' = $headers
        }
        $global:hcxConnection
    } else {
        Write-Error "Failed to connect to HCX Manager, please verify your vSphere SSO credentials"
    }
}

Function Get-HcxCloudConfig {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns the Cloud HCX information that is registerd with HCX Manager
    .DESCRIPTION
        This cmdlet returns the Cloud HCX information that is registerd with HCX Manager
    .EXAMPLE
        Get-HcxCloudConfig
#>
    If (-Not $global:hcxConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxServer " } Else {
        $cloudConfigUrl = $global:hcxConnection.Server + "/cloudConfigs"

        if($PSVersionTable.PSEdition -eq "Core") {
            $cloudvcRequests = Invoke-WebRequest -Uri $cloudConfigUrl -Method GET -Headers $global:hcxConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $cloudvcRequests = Invoke-WebRequest -Uri $cloudConfigUrl -Method GET -Headers $global:hcxConnection.headers -UseBasicParsing
        }

        $cloudvcData = ($cloudvcRequests.content | ConvertFrom-Json).data.items

        $tmp = [pscustomobject] @{
            Name = $cloudvcData.cloudName;
            Version = $cloudvcData.version;
            Build = $cloudvcData.buildNumber;
            HCXUUID = $cloudvcData.endpointId;
        }
        $tmp
    }
}

Function Get-HcxEndpoint {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/24/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        List all HCX endpoints (onPrem and Cloud)
    .DESCRIPTION
        This cmdlet lists all HCX endpoints (onPrem and Cloud)
    .EXAMPLE
        Get-HcxEndpoint -cloudVCConnection $cloudVCConnection
#>
    Param (
        [Parameter(Mandatory=$true)]$cloudVCConnection
    )

    If (-Not $global:hcxConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxManager " } Else {
        #Cloud HCX Manager
        $cloudHCXConnectionURL = $global:hcxConnection.Server + "/cloudConfigs"

        if($PSVersionTable.PSEdition -eq "Core") {
            $cloudRequests = Invoke-WebRequest -Uri $cloudHCXConnectionURL -Method GET -Headers $global:hcxConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $cloudRequests = Invoke-WebRequest -Uri $cloudHCXConnectionURL -Method GET -Headers $global:hcxConnection.headers -UseBasicParsing
        }
        $cloudData = ($cloudRequests.Content | ConvertFrom-Json).data.items[0]

        $hcxInventoryUrl = $global:hcxConnection.Server + "/service/inventory/resourcecontainer/list"

        $payload = @{
            "cloud" = @{
                "local"="true";
                "remote"="true";
            }
        }
        $body = $payload | ConvertTo-Json

        if($PSVersionTable.PSEdition -eq "Core") {
            $requests = Invoke-WebRequest -Uri $hcxInventoryUrl -Body $body -Method POST -Headers $global:hcxConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $requests = Invoke-WebRequest -Uri $hcxInventoryUrl -Body $body -Method POST -Headers $global:hcxConnection.headers -UseBasicParsing
        }
        if($requests.StatusCode -eq 200) {
            $items = ($requests.Content | ConvertFrom-Json).data.items

            $results = @()
            foreach ($item in $items) {
                $tmp = [pscustomobject] @{
                    SourceResourceName = $item.resourceName;
                    SourceResourceType = $item.resourceType;
                    SourceResourceId = $item.resourceId;
                    SourceEndpointName = $item.endpoint.name;
                    SourceEndpointType = "VC"
                    SourceEndpointId = $item.endpoint.endpointId;
                    RemoteResourceName = $cloudVCConnection.name;
                    RemoteResourceType = "VC"
                    RemoteResourceId = $cloudVCConnection.InstanceUuid
                    RemoteEndpointName = $cloudData.cloudName;
                    RemoteEndpointType = $cloudData.cloudType;
                    RemoteEndpointId = $cloudData.endpointId;
                }
                $results+=$tmp
            }
            return $results
        } else {
            Write-Error "Failed to list HCX Connection Resources"
        }
    }
}

Function New-HcxMigration {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/24/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Initiate a "Bulk" migrations supporting Cold, vMotion, VR or new Cloud Motion
    .DESCRIPTION
        This cmdlet initiates a "Bulk" migrations supporting Cold, vMotion, VR or new Cloud Motionn
    .EXAMPLE
        Validate Migration request only

        New-HcxMigration -onPremVCConnection $onPremVC -cloudVCConnection $cloudVC `
            -MigrationType bulkVMotion `
            -VMs @("SJC-CNA-34","SJC-CNA-35","SJC-CNA-36") `
            -NetworkMappings @{"SJC-CORP-WORKLOADS"="sddc-cgw-network-1";"SJC-CORP-INTERNAL-1"="sddc-cgw-network-2";"SJC-CORP-INTERNAL-2"="sddc-cgw-network-3"} `
            -StartTime "Sep 24 2018 1:30 PM" `
            -EndTime "Sep 24 2018 2:30 PM"
    .EXAMPLE
        Start Migration request

        New-HcxMigration -onPremVCConnection $onPremVC -cloudVCConnection $cloudVC `
            -MigrationType bulkVMotion `
            -VMs @("SJC-CNA-34","SJC-CNA-35","SJC-CNA-36") `
            -NetworkMappings @{"SJC-CORP-WORKLOADS"="sddc-cgw-network-1";"SJC-CORP-INTERNAL-1"="sddc-cgw-network-2";"SJC-CORP-INTERNAL-2"="sddc-cgw-network-3"} `
            -StartTime "Sep 24 2018 1:30 PM" `
            -EndTime "Sep 24 2018 2:30 PM" `
            -MigrationType bulkVMotion
#>
    Param (
        [Parameter(Mandatory=$true)][String[]]$VMs,
        [Parameter(Mandatory=$true)][Hashtable]$NetworkMappings,
        [Parameter(Mandatory=$true)]$onPremVCConnection,
        [Parameter(Mandatory=$true)]$cloudVCConnection,
        [Parameter(Mandatory=$true)][String]$StartTime,
        [Parameter(Mandatory=$true)][String]$EndTime,
        [Parameter(Mandatory=$true)][ValidateSet("Cold","vMotion","VR","bulkVMotion")][String]$MigrationType,
        [Parameter(Mandatory=$false)]$ValidateOnly=$true
    )

    If (-Not $global:hcxConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxManager " } Else {
        $hcxEndpointInfo = Get-HcxEndpoint -cloudVCConnection $cloudVCConnection

        $inputArray = @()
        foreach ($vm in $VMs) {
            $vmView = Get-View -Server $onPremVCConnection -ViewType VirtualMachine -Filter @{"name"=$vm}

            $cloudResourcePoolName = "Compute-ResourcePool"
            $cloudFolderName = "Workloads"
            $cloudDatastoreName = "WorkloadDatastore"
            $cloudDatacenterName = "SDDC-Datacenter"

            $cloudResourcePool = (Get-ResourcePool -Server $cloudVCConnection -Name $cloudResourcePoolName).ExtensionData
            $cloudFolder = (Get-Folder -Server $cloudVCConnection -Name $cloudFolderName).ExtensionData
            $cloudDatastore = (Get-Datastore -Server $cloudVCConnection -Name $cloudDatastoreName).ExtensionData
            $cloudDatacenter = (Get-Datacenter -Server $cloudVCConnection -Name $cloudDatacenterName).ExtensionData

            $placementArray = @()
            $placement = @{
                "containerType"="folder";
                "containerId"=$cloudFolder.MoRef.Value;
                "containerName"=$cloudFolderName;
            }
            $placementArray+=$placement
            $placement = @{
                "containerType"="resourcePool";
                "containerId"=$cloudResourcePool.MoRef.Value;
                "containerName"=$cloudResourcePoolName;
            }
            $placementArray+=$placement
            $placement = @{
                "containerType"="dataCenter";
                "containerId"=$cloudDatacenter.MoRef.Value;
                "containerName"=$cloudDatacenterName;
            }
            $placementArray+=$placement

            $networkArray = @()
            $vmNetworks = $vmView.Network
            foreach ($vmNetwork in $vmNetworks) {
                if($vmNetwork.Type -eq "Network") {
                    $sourceNetworkType = "VirtualNetwork"
                } else { $sourceNetworkType = $vmNetwork.Type }

                $sourceNetworkRef = New-Object VMware.Vim.ManagedObjectReference
                $sourceNetworkRef.Type = $vmNetwork.Type
                $sourceNetworkRef.Value = $vmNetwork.Value
                $sourceNetwork = Get-View -Server $onPremVCConnection $sourceNetworkRef

                $sourceNetworkName = $sourceNetwork.Name
                $destNetworkName = $NetworkMappings[$sourceNetworkName]

                $destNetwork = Get-VDPortGroup -Server $cloudVCConnection -Name $destNetworkName

                if($destNetwork.Id -match "DistributedVirtualPortgroup") {
                    $destNetworkType = "DistributedVirtualPortgroup"
                    $destNetworkId = ($destNetwork.Id).Replace("DistributedVirtualPortgroup-","")
                } else {
                    $destNetworkType = "Network"
                    $destNetworkId = ($destNetwork.Id).Replace("Network-","")
                }

                $tmp = @{
                    "srcNetworkType" = $sourceNetworkType;
                    "srcNetworkValue" = $vmNetwork.Value;
                    "srcNetworkHref" = $vmNetwork.Value;
                    "srcNetworkName" = $sourceNetworkName;
                    "destNetworkType" = $destNetworkType;
                    "destNetworkValue" = $destNetworkId;
                    "destNetworkHref" = $destNetworkId;
                    "destNetworkName" = $destNetworkName;
                }
                $networkArray+=$tmp
            }

            $input = @{
                "input" = @{
                    "migrationType"=$MigrationType;
                    "entityDetails" = @{
                        "entityId"=$vmView.MoRef.Value;
                        "entityName"=$vm;
                    }
                    "source" = @{
                        "endpointType"=$hcxEndpointInfo.SourceEndpointType;
                        "endpointId"=$hcxEndpointInfo.SourceEndpointId;
                        "endpointName"=$hcxEndpointInfo.SourceEndpointName;
                        "resourceType"=$hcxEndpointInfo.SourceResourceType;
                        "resourceId"=$hcxEndpointInfo.SourceResourceId;
                        "resourceName"=$hcxEndpointInfo.SourceResourceName;
                    }
                    "destination" = @{
                        "endpointType"=$hcxEndpointInfo.RemoteEndpointType;
                        "endpointId"=$hcxEndpointInfo.RemoteEndpointId;
                        "endpointName"=$hcxEndpointInfo.RemoteEndpointName;
                        "resourceType"=$hcxEndpointInfo.RemoteResourceType;
                        "resourceId"=$hcxEndpointInfo.RemoteResourceId;
                        "resourceName"=$hcxEndpointInfo.RemoteResourceName;
                    }
                    "placement" = $placementArray
                    "storage" = @{
                        "datastoreId"=$cloudDatastore.Moref.Value;
                        "datastoreName"=$cloudDatastoreName;
                        "diskProvisionType"="thin";
                    }
                    "networks" = @{
                        "retainMac" = $true;
                        "targetNetworks" =  $networkArray;
                    }
                    "decisionRules" = @{
                        "removeSnapshots"=$true;
                        "removeISOs"=$true;
                        "forcePowerOffVm"=$false;
                        "upgradeHardware"=$false;
                        "upgradeVMTools"=$false;
                    }
                    "schedule" = @{}
                }
            }
            $inputArray+=$input
        }

        $spec = @{
            "migrations"=$inputArray
        }
        $body = $spec | ConvertTo-Json -Depth 20

        Write-Verbose -Message "Pre-Validation JSON Spec: $body"
        $hcxMigrationValiateUrl = $global:hcxConnection.Server+ "/migrations?action=validate"

        if($PSVersionTable.PSEdition -eq "Core") {
            $requests = Invoke-WebRequest -Uri $hcxMigrationValiateUrl -Body $body -Method POST -Headers $global:hcxConnection.headers -UseBasicParsing -ContentType "application/json" -SkipCertificateCheck
        } else {
            $requests = Invoke-WebRequest -Uri $hcxMigrationValiateUrl -Body $body -Method POST -Headers $global:hcxConnection.headers -UseBasicParsing -ContentType "application/json"
        }

        if($requests.StatusCode -eq 200) {
            $validationErrors = ($requests.Content|ConvertFrom-Json).migrations.validationInfo.validationResult.errors
            if($validationErrors -ne $null) {
                Write-Host -Foreground Red "`nThere were validation errors found for this HCX Migration Spec ..."
                foreach ($message in $validationErrors) {
                    Write-Host -Foreground Yellow "`t" $message.message
                }
            } else {
                Write-Host -Foreground Green "`nHCX Pre-Migration Spec successfully validated"
                if($ValidateOnly -eq $false) {
                    try {
                        $startDateTime = $StartTime | Get-Date
                    } catch {
                        Write-Host -Foreground Red "Invalid input for -StartTime, please check for typos"
                        exit
                    }

                    try {
                        $endDateTime = $EndTime | Get-Date
                    } catch {
                        Write-Host -Foreground Red "Invalid input for -EndTime, please check for typos"
                        exit
                    }

                    $offset = (Get-TimeZone).GetUtcOffset($startDateTime).TotalMinutes
                    $offset = [int]($offSet.toString().replace("-",""))

                    $schedule = @{
                        scheduledFailover = $true;
                        startYear = $startDateTime.Year;
                        startMonth = $startDateTime.Month;
                        startDay = $startDateTime.Day;
                        startHour = $startDateTime | Get-Date -UFormat %H;
                        startMinute = $startDateTime | Get-Date -UFormat %M;
                        endYear = $endDateTime.Year;
                        endMonth = $endDateTime.Month;
                        endDay = $endDateTime.Day;
                        endHour = $endDateTime  | Get-Date -UFormat %H;
                        endMinute = $endDateTime  | Get-Date -UFormat %M;
                        timezoneOffset = $offset;
                    }

                    foreach ($migration in $spec.migrations) {
                        $migration.input.schedule = $schedule
                    }
                    $body = $spec | ConvertTo-Json -Depth 8

                    Write-Verbose -Message "Validated JSON Spec: $body"
                    $hcxMigrationStartUrl = $global:hcxConnection.Server+ "/migrations?action=start"

                    if($PSVersionTable.PSEdition -eq "Core") {
                        $requests = Invoke-WebRequest -Uri $hcxMigrationStartUrl -Body $body -Method POST -Headers $global:hcxConnection.headers -UseBasicParsing -ContentType "application/json" -SkipCertificateCheck
                    } else {
                        $requests = Invoke-WebRequest -Uri $hcxMigrationStartUrl -Body $body -Method POST -Headers $global:hcxConnection.headers -UseBasicParsing -ContentType "application/json"
                    }

                    if($requests.StatusCode -eq 200) {
                        $migrationIds = ($requests.Content | ConvertFrom-Json).migrations.migrationId
                        Write-Host -ForegroundColor Green "Starting HCX Migration ..."
                        foreach ($migrationId in $migrationIds) {
                            Write-Host -ForegroundColor Green "`tMigrationID: $migrationId"
                        }
                    } else {
                        Write-Error "Failed to start HCX Migration"
                    }
                }
            }
        } else {
            Write-Error "Failed to validate HCX Migration spec"
        }
    }
}

Function Get-HcxMigration {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/24/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        List all HCX Migrations that are in-progress, have completed or failed
    .DESCRIPTION
        This cmdlet lists ist all HCX Migrations that are in-progress, have completed or failed
    .EXAMPLE
        List all HCX Migrations

        Get-HcxMigration
    .EXAMPLE
        List all running HCX Migrations

        Get-HcxMigration -RunningMigrations
    .EXAMPLE
        List all HCX Migrations

        Get-HcxMigration -MigrationId <MigrationID>
#>
    Param (
        [Parameter(Mandatory=$false)][String[]]$MigrationId,
        [Switch]$RunningMigrations
    )

    If (-Not $global:hcxConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxManager " } Else {
        If($PSBoundParameters.ContainsKey("MigrationId")){
            $spec = @{
                filter = @{
                    migrationId = $MigrationId
                }
                paging =@{
                    pageSize = $MigrationId.Count
                }
            }
        } Else {
            $spec = @{}
        }
        $body = $spec | ConvertTo-Json

        $hcxQueryUrl = $global:hcxConnection.Server + "/migrations?action=query"
        if($PSVersionTable.PSEdition -eq "Core") {
            $requests = Invoke-WebRequest -Uri $hcxQueryUrl -Method POST -body $body -Headers $global:hcxConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $requests = Invoke-WebRequest -Uri $hcxQueryUrl -Method POST -Headers $global:hcxConnection.headers -UseBasicParsing
        }

        if($PSBoundParameters.ContainsKey("MigrationId")){
            $migrations = ($requests.content | ConvertFrom-Json).items
        } else {
            $migrations = ($requests.content | ConvertFrom-Json).rows
        }

        if($RunningMigrations){
            $migrations = $migrations | where { $_.jobInfo.state -ne "MIGRATE_FAILED" -and $_.jobInfo.state -ne "MIGRATE_CANCELED"-and $_.jobInfo.state -ne "MIGRATED" }
        }

        $results = @()
        foreach ($migration in $migrations) {
            $tmp = [pscustomobject] @{
                ID = $migration.migrationId;
                VM = $migration.migrationInfo.entityDetails.entityName;
                State = $migration.jobInfo.state;
                Progress = ($migration.migrationInfo.progressDetails.progressPercentage).toString() + " %";
                DataCopied = ([math]::round($migration.migrationInfo.progressDetails.diskCopyBytes/1Gb, 2)).toString() + " GB";
                Message = $migration.migrationInfo.message;
                InitiatedBy = $migration.jobInfo.username;
                CreateDate = $migration.jobInfo.creationDate;
                LastUpdated = $migration.jobInfo.lastUpdated;
            }
            $results+=$tmp
        }
        $results
    }
}

Function Connect-HcxVAMI {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Connect to the HCX Enterprise Manager VAMI
    .DESCRIPTION
        This cmdlet connects to the HCX Enterprise Manager VAMI
    .EXAMPLE
        Connect-HcxVAMI -Server $HCXServer -Username $VAMIUsername -Password $VAMIPassword
#>
    Param (
        [Parameter(Mandatory=$true)][String]$Server,
        [Parameter(Mandatory=$true)][String]$Username,
        [Parameter(Mandatory=$true)][String]$Password
    )

    $pair = "${Username}:${Password}"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"

    $headers = @{
        "authorization"="$basicAuthValue"
        "Content-Type"="application/json"
        "Accept"="application/json"
    }

    $global:hcxVAMIConnection = new-object PSObject -Property @{
        'Server' = "https://${server}:9443";
        'headers' = $headers
    }
    $global:hcxVAMIConnection
}

Function Get-HcxVCConfig {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns the onPrem vCenter Server registered with HCX Manager
    .DESCRIPTION
        This cmdlet returns the onPrem vCenter Server registered with HCX Manager
    .EXAMPLE
        Get-HcxVCConfig
#>
    If (-Not $global:hcxVAMIConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $vcConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/vcenter"
        $pscConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/lookupservice"

        if($PSVersionTable.PSEdition -eq "Core") {
            $vcRequests = Invoke-WebRequest -Uri $vcConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
            $ssoRequests = Invoke-WebRequest -Uri $pscConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $vcRequests = Invoke-WebRequest -Uri $vcConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
            $ssoRequests = Invoke-WebRequest -Uri $pscConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
        }
        $vcData = ($vcRequests.content | ConvertFrom-Json).data.items
        $ssoData = ($ssoRequests.content | ConvertFrom-Json).data.items

        $tmp = [pscustomobject] @{
            Name = $vcData.config.name;
            UserName = $vcData.Config.userName
            LookupServiceUrl = $ssoData.config.lookupServiceUrl
            Version = $vcData.config.version;
            Build = $vcData.config.buildNumber;
            UUID = $vcData.config.vcuuid;
            HCXUUID = $vcData.config.uuid;
        }
        $tmp
    }
}

Function Get-HcxLicense {
    <#
        .NOTES
        ===========================================================================
        Created by:    Mark McGilly
        Date:          4/29/2019
        Organization:  Liberty Mutual Insurance
        ===========================================================================

        .SYNOPSIS
            Returns the license key that is registered with HCX Manager
        .DESCRIPTION
            This cmdlet returns the license key registered with HCX Manager
        .EXAMPLE
            Get-HcxLicense
    #>

        If (-Not $global:hcxVAMIConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $hcxConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/hcx"

        if($PSVersionTable.PSEdition -eq "Core") {
            $licenseRequests = Invoke-WebRequest -Uri $hcxConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $licenseRequests = Invoke-WebRequest -Uri $hcxConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
        }
        $license = ($licenseRequests.content | ConvertFrom-Json).data.items
        if($licenseRequests) {
            $license.config.activationKey
        }
    }
}

Function Set-HcxLicense {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Activate HCX Manager with HCX Cloud
    .DESCRIPTION
        This cmdlet activates HCX Manager with HCX Cloud
    .EXAMPLE
        Set-HcxLicense -LicenseKey <KEY>
#>
    Param (
        [Parameter(Mandatory=$True)]$LicenseKey
    )

    If (-Not $global:hcxVAMIConnection) { Write-error "HCX VAMI Auth Token not found, please run Connect-HcxVAMI " } Else {
        $hcxConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/hcx"
        $method = "POST"

        $hcxConfig = @{
            config = @{
                url = "https://connect.hcx.vmware.com";
                activationKey = $LicenseKey;
            }
        }

        $payload = @{
            data = @{
                items = @($hcxConfig)
            }
        }

        $body = $payload | ConvertTo-Json -Depth 5

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$vcConfigUrl`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $results = Invoke-WebRequest -Uri $hcxConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
            } else {
                $results = Invoke-WebRequest -Uri $hcxConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
            }
        } catch {
            Write-Host -ForegroundColor Red "`nRequest failed: ($_.Exception)`n"
            break
        }

        if($results.StatusCode -eq 200) {
            Write-Host -ForegroundColor Green "Successfully registered HCX Manager with HCX Cloud"
            if($Troubleshoot) { ($results.Content | ConvertFrom-Json).data.items }
        } else {
            Write-Error "Failed to registered HCX Manager"
        }
    }
}

Function Set-HcxVCConfig {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Registers on-prem vCenter Server with HCX Manager
    .DESCRIPTION
        This cmdlet registers on-prem vCenter Server with HCX Manager
    .EXAMPLE
        Set-HcxVC -VIServer <hostname> -VIUsername <username> -VIPassword <password>
#>
    Param (
        [Parameter(Mandatory=$True)]$VIServer,
        [Parameter(Mandatory=$True)]$PSCServer,
        [Parameter(Mandatory=$True)]$VIUsername,
        [Parameter(Mandatory=$True)]$VIPassword,
        [Switch]$Troubleshoot
    )

    If (-Not $global:hcxVAMIConnection) { Write-error "HCX VAMI Auth Token not found, please run Connect-HcxVAMI " } Else {
        $vcConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/vcenter"
        $pscConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/lookupservice"
        $method = "POST"


        $bytes = [System.Text.Encoding]::ASCII.GetBytes($VIPassword)
        $base64 = [System.Convert]::ToBase64String($bytes)

        $vcConfig = @{
            config = @{
                url = "https://$VIServer";
                userName = $VIUsername;
                password = $base64;
            }
        }

        $payload = @{
            data = @{
                items = @($vcConfig)
            }
        }

        $body = $payload | ConvertTo-Json -Depth 5

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$vcConfigUrl`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $results = Invoke-WebRequest -Uri $vcConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
            } else {
                $results = Invoke-WebRequest -Uri $vcConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
            }
        } catch {
            Write-Host -ForegroundColor Red "`nRequest failed: ($_.Exception)`n"
            break
        }

        if($results.StatusCode -eq 200) {
            Write-Host -ForegroundColor Green "Successfully registered vCenter Server with HCX Manager"
            if($Troubleshoot) { ($results.Content | ConvertFrom-Json).data.items.config }

            $pscConfig = @{
                config = @{
                    lookupServiceUrl = "https://$PSCServer"
                    providerType = "PSC"
                }
            }

            $payload = @{
                data = @{
                    items = @($pscConfig)
                }
            }

            $body = $payload | ConvertTo-Json -Depth 5

            if($Troubleshoot) {
                Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$pscConfigUrl`n"
                Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
            }

            try {
                if($PSVersionTable.PSEdition -eq "Core") {
                    $results = Invoke-WebRequest -Uri $pscConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
                } else {
                    $results = Invoke-WebRequest -Uri $pscConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
                }
            } catch {
                Write-Host -ForegroundColor Red "`nRequest failed: ($_.Exception)`n"
                break
            }

            if($results.StatusCode -eq 200) {
                Write-Host -ForegroundColor Green "Successfully registered PSC with HCX Manager"
                if($Troubleshoot) { ($results.Content | ConvertFrom-Json).data.items.config }

            } else {
                Write-Error "Failed to registered PSC Server"
            }
        } else {
            Write-Error "Failed to registered vCenter Server"
        }
    }
}

Function Get-HcxNSXConfig {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns the onPrem NSX-V Server registered with HCX Manager
    .DESCRIPTION
        This cmdlet returns the onPrem NSX-V Server registered with HCX Manager
    .EXAMPLE
        Get-HcxNSXConfig
#>
    If (-Not $global:hcxVAMIConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $nsxConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/nsx"

        if($PSVersionTable.PSEdition -eq "Core") {
            $nsxRequests = Invoke-WebRequest -Uri $nsxConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $nsxRequests = Invoke-WebRequest -Uri $nsxConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
        }
        $nsxData = ($nsxRequests.content | ConvertFrom-Json).data.items

        $tmp = [pscustomobject] @{
            Name = $nsxData.config.url;
            UserName = $nsxData.config.userName
            Version = $nsxData.config.version;
            HCXUUID = $nsxData.config.uuid;
        }
        $tmp
    }
}

Function Set-HcxNSXConfig {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Registers on-prem NSX-V Server with HCX Manager
    .DESCRIPTION
        This cmdlet registers on-prem NSX-V Server with HCX Manager
    .EXAMPLE
        Set-HcxNSXConfig -NSXServer <hostname> -NSXUsername <username> -NSXPassword <password>
#>
    Param (
        [Parameter(Mandatory=$True)]$NSXServer,
        [Parameter(Mandatory=$True)]$NSXUsername,
        [Parameter(Mandatory=$True)]$NSXPassword,
        [Switch]$Troubleshoot
    )

    If (-Not $global:hcxVAMIConnection) { Write-error "HCX VAMI Auth Token not found, please run Connect-HcxVAMI " } Else {
        $nsxConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/nsx"
        $method = "POST"

        $bytes = [System.Text.Encoding]::ASCII.GetBytes($NSXPassword)
        $base64 = [System.Convert]::ToBase64String($bytes)

        $nsxConfig = @{
            config = @{
                url = "https://$NSXServer";
                userName = $NSXUsername;
                password = $base64;
            }
        }

        $payload = @{
            data = @{
                items = @($nsxConfig)
            }
        }

        $body = $payload | ConvertTo-Json -Depth 5

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$nsxConfigUrl`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $results = Invoke-WebRequest -Uri $nsxConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
            } else {
                $results = Invoke-WebRequest -Uri $nsxConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
            }
        } catch {
            Write-Host -ForegroundColor Red "`nRequest failed: ($_.Exception)`n"
            break
        }

        if($results.StatusCode -eq 200) {
            Write-Host -ForegroundColor Green "Successfully registered NSX Server with HCX Manager"
            if($Troubleshoot) { ($results.Content | ConvertFrom-Json).data.items.config }
        } else {
            Write-Error "Failed to registered NSX Server"
        }
        return $config
    }
}

Function Get-HcxCity {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          09/16/2018
        Organization:  VMware
        Blog:          http://www.virtuallyghetto.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Returns the available HCX Location based on user City and Country input
        .DESCRIPTION
            This cmdlet returns the available HCX Location based on user City and Country input
        .EXAMPLE
            Get-HcxCity -City <City> -Country <Country>
    #>
        Param (
            [Parameter(Mandatory=$True)]$City,
            [Switch]$Troubleshoot
        )

        If (-Not $global:hcxVAMIConnection) { Write-error "HCX VAMI Auth Token not found, please run Connect-HcxVAMI " } Else {
            $citySearchUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/searchCities?searchString=$City"
            $method = "GET"

            if($Troubleshoot) {
                Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$citySearchUrl`n"
            }

            try {
                if($PSVersionTable.PSEdition -eq "Core") {
                    $results = Invoke-WebRequest -Uri $citySearchUrl -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
                } else {
                    $results = Invoke-WebRequest -Uri $citySearchUrl -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
                }
            } catch {
                Write-Host -ForegroundColor Red "`nRequest failed: ($_.Exception)`n"
                break
            }

            if($results.StatusCode -eq 200) {
                Write-Host -ForegroundColor Green "Successfully returned results for City search: $City"

                $cityDetails = ($results.Content | ConvertFrom-Json).items
                $cityDetails | select City,Country
            } else {
                Write-Error "Failed to search for city $City"
            }
        }
    }

Function Get-HcxLocation {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns the registered City/Country location for HCX Manager
    .DESCRIPTION
        This cmdlet returns the registered City/Country location for HCX Manager
    .EXAMPLE
        Get-HcxLocation
#>
    If (-Not $global:hcxVAMIConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $locationConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/location"

        if($PSVersionTable.PSEdition -eq "Core") {
            $locationRequests = Invoke-WebRequest -Uri $locationConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $locationRequests = Invoke-WebRequest -Uri $locationConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
        }
        ($locationRequests.content | ConvertFrom-Json)
    }
}

Function Set-HcxLocation {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Register HCX Manager to a specific City/Country
    .DESCRIPTION
        This cmdlet register HCX Manager to a specific City/Country
    .EXAMPLE
        Set-HcxLocation -City <City> -Country <Country>
#>
    Param (
        [Parameter(Mandatory=$True)]$City,
        [Parameter(Mandatory=$True)]$Country,
        [Switch]$Troubleshoot
    )

    If (-Not $global:hcxVAMIConnection) { Write-error "HCX VAMI Auth Token not found, please run Connect-HcxVAMI " } Else {
        $citySearchUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/searchCities?searchString=$City"
        $method = "GET"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$citySearchUrl`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $results = Invoke-WebRequest -Uri $citySearchUrl -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
            } else {
                $results = Invoke-WebRequest -Uri $citySearchUrl -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
            }
        } catch {
            Write-Host -ForegroundColor Red "`nRequest failed: ($_.Exception)`n"
            break
        }

        if($results.StatusCode -eq 200) {
            if($Troubleshoot) { ($results.Content | ConvertFrom-Json).items }

            $locationConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/location"
            $method = "PUT"

            $cityDetails = ($results.Content | ConvertFrom-Json).items
            $cityDetails = $cityDetails | where { $_.city -eq $City -and $_.country -match $Country }

            if(-not $cityDetails) {
                Write-Host -ForegroundColor Red "Invalid input for City and/or Country, please provide the exact input from Get-HcxCity cmdlet"
                break
            }

            $locationConfig = @{
                city = $cityDetails.city;
                country = $cityDetails.country;
                province = $cityDetails.province;
                latitude = $cityDetails.latitude;
                longitude = $cityDetails.longitude;
            }

            $body = $locationConfig | ConvertTo-Json -Depth 5

            if($Troubleshoot) {
                Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$locationConfigUrl`n"
                Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
            }

            try {
                if($PSVersionTable.PSEdition -eq "Core") {
                    $results = Invoke-WebRequest -Uri $locationConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
                } else {
                    $results = Invoke-WebRequest -Uri $locationConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
                }
            } catch {
                Write-Host -ForegroundColor Red "`nRequest failed: ($_.Exception)`n"
                break
            }

            if($results.StatusCode -eq 204) {
                Write-Host -ForegroundColor Green "Successfully registered datacenter location $City to HCX Manager"
            } else {
                Write-Error "Failed to registerd datacenter location in HCX Manager"
            }
        } else {
            Write-Error "Failed to search for city $City"
        }
    }
}
Function Get-HcxRoleMapping {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns the System Admin and Enterprise User Group role mappings for HCX Manager
    .DESCRIPTION
        This cmdlet returns the System Admin and Enterprise User Group role mappings for HCX Manager
    .EXAMPLE
        Get-HcxRoleMapping
#>
    If (-Not $global:hcxVAMIConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $roleConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/roleMappings"

        if($PSVersionTable.PSEdition -eq "Core") {
            $roleRequests = Invoke-WebRequest -Uri $roleConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $roleRequests = Invoke-WebRequest -Uri $roleConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
        }
        ($roleRequests.content | ConvertFrom-Json)
    }
}

Function Set-HcxRoleMapping {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          09/16/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Configures the System Admin and Enterprise User Group role mappings for HCX Manager
    .DESCRIPTION
        This cmdlet configures the System Admin and Enterprise User Group role mappings for HCX Manager
    .EXAMPLE
        Set-HcxRoleMapping -SystemAdminGroup @("DOMAIN\GROUP") -EnterpriseAdminGroup @("DOMAIN\GROUP")
#>
    Param (
        [Parameter(Mandatory=$True)][String[]]$SystemAdminGroup,
        [Parameter(Mandatory=$True)][String[]]$EnterpriseAdminGroup,
        [Switch]$Troubleshoot
    )

    If (-Not $global:hcxVAMIConnection) { Write-error "HCX VAMI Auth Token not found, please run Connect-HcxVAMI " } Else {
        $roleConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/roleMappings"
        $method = "PUT"

        $roleConfig = @()
        $systemAdminRole = @{
            role = "System Administrator";
            userGroups = $SystemAdminGroup
        }
        $enterpriseAdminRole = @{
            role = "Enterprise Administrator"
            userGroups = $EnterpriseAdminGroup
        }
        $roleConfig+=$systemAdminRole
        $roleConfig+=$enterpriseAdminRole

        $body = $roleConfig | ConvertTo-Json -Depth 5

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$locationConfigUrl`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $results = Invoke-WebRequest -Uri $roleConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
            } else {
                $results = Invoke-WebRequest -Uri $roleConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
            }
        } catch {
            Write-Host -ForegroundColor Red "`nRequest failed: ($_.Exception)`n"
            break
        }

        if($results.StatusCode -eq 200) {
            Write-Host -ForegroundColor Green "Successfully updated vSphere Group Mappings in HCX Manager"
        } else {
            Write-Error "Failed to update vSphere Group Mappings"
        }
    }
}

Function Get-HcxProxy {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          10/31/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns the proxy settings for HCX Manager
    .DESCRIPTION
        This cmdlet returns the proxy settings for HCX Manager
    .EXAMPLE
        Get-HcxProxy
#>
    If (-Not $global:hcxVAMIConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $proxyConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/proxy"

        if($PSVersionTable.PSEdition -eq "Core") {
            $proxyRequests = Invoke-WebRequest -Uri $proxyConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $proxyRequests = Invoke-WebRequest -Uri $proxyConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
        }
        $proxySettings = ($proxyRequests.content | ConvertFrom-Json).data.items
        if($proxyRequests) {
            $proxySettings.config
        }
    }
}

Function Set-HcxProxy {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          10/31/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Configure proxy settings on HCX Manager
    .DESCRIPTION
        This cmdlet configure proxy settings on HCX Manager
    .EXAMPLE
        Set-HcxProxy -ProxyServer proxy.vmware.com -ProxyPort 3124
    .EXAMPLE
        Set-HcxProxy -ProxyServer proxy.vmware.com -ProxyPort 3124 -ProxyUser foo -ProxyPassword bar
#>
    Param (
        [Parameter(Mandatory=$True)]$ProxyServer,
        [Parameter(Mandatory=$True)]$ProxyPort,
        [Parameter(Mandatory=$False)]$ProxyUser,
        [Parameter(Mandatory=$False)]$ProxyPassword,
        [Parameter(Mandatory=$False)]$ProxyExclusions,
        [Switch]$Troubleshoot
    )

    If (-Not $global:hcxVAMIConnection) { Write-error "HCX VAMI Auth Token not found, please run Connect-HcxVAMI " } Else {
        $proxyConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/proxy"
        $method = "POST"

        if(-not $ProxyUser) { $ProxyUser = ""}
        if(-not $ProxyPassword) { $ProxyPassword = ""}

        $proxyConfig = @{
            config = @{
                proxyHost = "$ProxyServer";
                proxyPort = "$ProxyPort";
                nonProxyHosts = "$ProxyExclusions";
                userName = "$ProxyUser";
                password = "$ProxyPassword";
            }
        }

        $payload = @{
            data = @{
                items = @($proxyConfig)
            }
        }

        $body = $payload | ConvertTo-Json -Depth 5

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $method`n$proxyConfigUrl`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $results = Invoke-WebRequest -Uri $proxyConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
            } else {
                $results = Invoke-WebRequest -Uri $proxyConfigUrl -Body $body -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
            }
        } catch {
            Write-Host -ForegroundColor Red "`nRequest failed: ($_.Exception)`n"
            break
        }

        if($results.StatusCode -eq 200) {
            Write-Host -ForegroundColor Green "Successfully updated proxy settings in HCX Manager"
            if($Troubleshoot) { ($results.Content | ConvertFrom-Json).data.items.config }
        } else {
            Write-Error "Failed to update proxy settings"
        }
    }
}

Function Remove-HcxProxy {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          10/31/2018
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns the proxy settings for HCX Manager
    .DESCRIPTION
        This cmdlet returns the proxy settings for HCX Manager
    .EXAMPLE
        Remove-HcxProxy
#>
    If (-Not $global:hcxVAMIConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $roleConfigUrl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/proxy"

        if($PSVersionTable.PSEdition -eq "Core") {
            $proxyRequests = Invoke-WebRequest -Uri $roleConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $proxyRequests = Invoke-WebRequest -Uri $roleConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
        }
        $proxySettings = ($proxyRequests.content | ConvertFrom-Json).data.items
        if($proxyRequests) {
            $proxyUUID = $proxySettings.config.UUID

            $deleteProxyConfigURl = $global:hcxVAMIConnection.Server + "/api/admin/global/config/proxy/$proxyUUID"
            $method = "DELETE"

            try {
                if($PSVersionTable.PSEdition -eq "Core") {
                    $results = Invoke-WebRequest -Uri $deleteProxyConfigURl -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
                } else {
                    $results = Invoke-WebRequest -Uri $deleteProxyConfigURl -Method $method -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
                }
            } catch {
                Write-Host -ForegroundColor Red "`nRequest failed: ($_.Exception)`n"
                break
            }

            if($results.StatusCode -eq 200) {
                Write-Host -ForegroundColor Green "Successfully deleted proxy settings in HCX Manager"
            } else {
                Write-Error "Failed to delete proxy settings"
            }
        } else {
            Write-Warning "No proxy settings were configured"
        }
    }
}

Function Connect-HcxCloudServer {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          06/19/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Connect to the HCX Cloud Service
    .DESCRIPTION
        This cmdlet connects to the HCX Cloud Service
    .EXAMPLE
        Connect-HcxCloudServer -RefreshToken
#>
    Param (
        [Parameter(Mandatory=$true)][String]$RefreshToken,
        [Switch]$Troubleshoot
    )

    $results = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize" -Method POST -Headers @{accept='application/json'} -Body "refresh_token=$RefreshToken"
    if($results.StatusCode -ne 200) {
        Write-Host -ForegroundColor Red "Failed to retrieve Access Token, please ensure your VMC Refresh Token is valid and try again"
        break
    }
    $accessToken = ($results | ConvertFrom-Json).access_token

    $payload = @{
        token = $accessToken;
    }
    $body = $payload | ConvertTo-Json

    $hcxCloudLoginUrl = "https://connect.hcx.vmware.com/provider/csp/api/sessions"

    if($PSVersionTable.PSEdition -eq "Core") {
        $results = Invoke-WebRequest -Uri $hcxCloudLoginUrl -Body $body -Method POST -UseBasicParsing -ContentType "application/json" -SkipCertificateCheck
    } else {
        $results = Invoke-WebRequest -Uri $hcxCloudLoginUrl -Body $body -Method POST -UseBasicParsing -ContentType "application/json"
    }

    if($results.StatusCode -eq 200) {
        $hcxAuthToken = $results.Headers.'x-hm-authorization'

        $headers = @{
            "x-hm-authorization"="$hcxAuthToken"
            "Content-Type"="application/json"
            "Accept"="application/json"
        }

        $global:hcxCloudConnection = new-object PSObject -Property @{
            'Server' = "https://connect.hcx.vmware.com/provider/csp/consumer/api";
            'headers' = $headers
        }
        $global:hcxCloudConnection
    } else {
        Write-Error "Failed to connect to HCX Cloud Service, please verify your CSP Refresh Token is valid"
    }
}

Function Get-HCXCloudActivationKey {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          06/19/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns the activation keys from HCX Cloud
    .DESCRIPTION
        This cmdlet returns the activation keys from HCX Cloud
    .EXAMPLE
        Get-HCXCloudActivationKeys
    .EXAMPLE
        Get-HCXCloudActivationKeys -Type [AVAILABLE|CONSUMED|DEACTIVATED|DELETED]
#>
    Param (
        [Parameter(Mandatory=$false)][ValidateSet("AVAILABLE","CONSUMED","DEACTIVATED","DELETED")][String]$Type,
        [Switch]$Troubleshoot
    )

    If (-Not $global:hcxCloudConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $method = "GET"
        $hcxLicenseUrl = $global:hcxCloudConnection.Server + "/activationKeys"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$hcxLicenseUrl`n"
        }

        if($PSVersionTable.PSEdition -eq "Core") {
            $results = Invoke-WebRequest -Uri $hcxLicenseUrl -Method $method -Headers $global:hcxCloudConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $results = Invoke-WebRequest -Uri $hcxLicenseUrl -Method $method -Headers $global:hcxCloudConnection.headers -UseBasicParsing
        }
        if($Type) {
            ($results.content | ConvertFrom-Json).result.activationKeys | where { $_.status -eq $Type}
        } else {
            ($results.content | ConvertFrom-Json).result.activationKeys
        }
    }
}

Function Get-HCXCloudSubscription {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          06/19/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns the subscription information for HCX CLoud Service
    .DESCRIPTION
        This cmdlet returns the subscription information for HCX Cloud Service
    .EXAMPLE
        Get-HCXCloudSubscription
#>
    Param (
        [Switch]$Troubleshoot
    )

    If (-Not $global:hcxCloudConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $method = "GET"
        $hcxSubscriptionUrl = $global:hcxCloudConnection.Server + "/subscriptions"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$hcxSubscriptionUrl`n"
        }

        if($PSVersionTable.PSEdition -eq "Core") {
            $results = Invoke-WebRequest -Uri $hcxSubscriptionUrl -Method $method -Headers $global:hcxCloudConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $results = Invoke-WebRequest -Uri $hcxSubscriptionUrl -Method $method -Headers $global:hcxCloudConnection.headers -UseBasicParsing
        }

        ($results.content | ConvertFrom-Json).subscriptions | select @{Name = "SID"; Expression = {$_.sid}},@{Name = "STATUS"; Expression = {$_.status}},@{Name = 'OfferName'; Expression = {$_.subscriptionComponents.offerName}}
    }
}

Function New-HCXCloudActivationKey {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          06/19/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Requests new HCX Activation License Key
    .DESCRIPTION
        This cmdlet requests new HCX Activation License Key
    .EXAMPLE
        Get-HCXCloudActivationKey -SID <SID> -SystemType [HCX-CLOUD|HCX-ENTERPRISE]
#>
    Param (
        [Parameter(Mandatory=$true)][String]$SID,
        [Parameter(Mandatory=$true)][ValidateSet("HCX-CLOUD","HCX-ENTERPRISE")][String]$SystemType,
        [Switch]$Troubleshoot
    )

    If (-Not $global:hcxCloudConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $method = "POST"
        $hcxLicenseUrl = $global:hcxCloudConnection.Server + "/activationKeys"

        $payload = @{
            numberOfKeys = "1";
            sid = $SID;
            systemType = ($SystemType).toLower();
        }
        $body = $payload | ConvertTo-Json

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$hcxSubscriptionUrl`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $hcxLicenseUrl -Method $method -Body $body -Headers $global:hcxCloudConnection.headers -UseBasicParsing -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $hcxLicenseUrl -Method $method -Body $body -Headers $global:hcxCloudConnection.headers -UseBasicParsing
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe HCX Cloud session is no longer valid, please re-run the Connect-HCXCloudServer cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in requesting new HCX license key"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            Write-Host "Successfully requestd new $SystemType License Key"
            ($requests.content | ConvertFrom-Json).activationKeys
        }
    }
}

Function Get-HCXCloud {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          06/19/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Returns HCX deployment information for all SDDCs
    .DESCRIPTION
        This cmdlet returns HCX deployment information for all SDDCs
    .EXAMPLE
        Get-HCXCloud
#>
    Param (
        [Switch]$Troubleshoot
    )

    If (-Not $global:hcxCloudConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $method = "GET"
        $hcxCloudSDDCUrl = $global:hcxCloudConnection.Server + "/sddcs"

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$hcxSubscriptionUrl`n"
        }

        if($PSVersionTable.PSEdition -eq "Core") {
            $results = Invoke-WebRequest -Uri $hcxCloudSDDCUrl -Method $method -Headers $global:hcxCloudConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $results = Invoke-WebRequest -Uri $hcxCloudSDDCUrl -Method $method -Headers $global:hcxCloudConnection.headers -UseBasicParsing
        }

        ($results.content | ConvertFrom-Json).sddcs | Sort-Object -Property Name | select @{Name = "SDDCName"; Expression = {$_.name}}, @{Name = "SDDCID"; Expression = {$_.id}}, @{Name = "HCXStatus"; Expression = {$_.activationStatus}}, @{Name = "Region"; Expression = {$_.region}}
    }
}

Function Set-HCXCloud {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Date:          06/19/2019
    Organization:  VMware
    Blog:          http://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Activate or Deactivate HCX for given VMC SDDC
    .DESCRIPTION
        This cmdlet activates or deactivates HCX for given VMC SDDC
    .EXAMPLE
        Set-HCXCloud -Activate -SDDCID $SDDCID
    .EXAMPLE
        Set-HCXCloud -Deactivate -SDDCID $SDDCID
#>
    Param (
        [Parameter(Mandatory=$true)][String]$SDDCID,
        [Switch]$Activate,
        [Switch]$Deactivate,
        [Switch]$Troubleshoot
    )

    If (-Not $global:hcxCloudConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxVAMI " } Else {
        $method = "POST"

        if($Activate) {
            $HcxSid = (Get-HCXCloudSubscription | where {$_.STATUS -eq "ACTIVE"}).SID

            # Check to see if there is an available HCX-Cloud Key
            $HcxKey = ((Get-HCXCloudActivationKey -Type AVAILABLE | where {$_.systemType -eq 'hcx-cloud'}) | select -First 1).activationKey
            if($HcxKey -eq $null) {
                $HcxKey = New-HCXCloudActivationKey -SID $HcxSid -SystemType HCX-CLOUD
            }

            if($HCXKey -eq $null -or $HcxSid -eq $null) {
                Write-Error "Failed to retrieve HCX Subscription ID or request HCX Cloud License Key"
                break
            }

            $hcxSDDCUrl = $global:hcxCloudConnection.Server + "/sddcs/$($SDDCID)?action=activate"

            $payload = @{
                activationKey = $HcxKey;
            }
        } else {
            $payload = ""

            $hcxSDDCUrl = $global:hcxCloudConnection.Server + "/sddcs/$($SDDCID)?action=deactivate"
        }

        $body = $payload | ConvertTo-Json

        if($Troubleshoot) {
            Write-Host -ForegroundColor cyan "`n[DEBUG] - $METHOD`n$hcxSDDCUrl`n"
            Write-Host -ForegroundColor cyan "[DEBUG]`n$body`n"
        }

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri $hcxSDDCUrl -Method $method -Body $body -Headers $global:hcxCloudConnection.headers -UseBasicParsing -SkipCertificateCheck
            } else {
                $requests = Invoke-WebRequest -Uri $hcxSDDCUrl -Method $method -Body $body -Headers $global:hcxCloudConnection.headers -UseBasicParsing
            }
        } catch {
            if($_.Exception.Response.StatusCode -eq "Unauthorized") {
                Write-Host -ForegroundColor Red "`nThe HCX Cloud session is no longer valid, please re-run the Connect-HCXCloudServer cmdlet to retrieve a new token`n"
                break
            } else {
                Write-Error "Error in attempting to activate or deactivate HCX"
                Write-Error "`n($_.Exception.Message)`n"
                break
            }
        }

        if($requests.StatusCode -eq 200) {
            if($Activate) {
                Write-Host "Activating HCX for SDDC: $SDDCID, starting deployment. You can monitor the status using the HCX Cloud Console"
            } else {
                Write-Host "Deactivating HCX for SDDC: $SDDCID, starting un-deploymentt. You can monitor the status using the HCX Cloud Console"
            }
            ($requests.content | ConvertFrom-Json)
        }
    }
}