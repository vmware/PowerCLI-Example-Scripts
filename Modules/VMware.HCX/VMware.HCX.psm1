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
        [Parameter(Mandatory=$false)][String]$MigrationId,
        [Switch]$RunningMigrations
    )

    If (-Not $global:hcxConnection) { Write-error "HCX Auth Token not found, please run Connect-HcxManager " } Else {
        $spec = @{}
        $body = $spec | ConvertTo-Json

        $hcxQueryUrl = $global:hcxConnection.Server + "/migrations?action=query"
        if($PSVersionTable.PSEdition -eq "Core") {
            $requests = Invoke-WebRequest -Uri $hcxQueryUrl -Method POST -body $body -Headers $global:hcxConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $requests = Invoke-WebRequest -Uri $hcxQueryUrl -Method POST -Headers $global:hcxConnection.headers -UseBasicParsing
        }

        $migrations = ($requests.content | ConvertFrom-Json).rows

        if($PSBoundParameters.ContainsKey("MigrationId")){
            $migrations = $migrations | where { $_.migrationId -eq $MigrationId }
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

        if($PSVersionTable.PSEdition -eq "Core") {
            $vcRequests = Invoke-WebRequest -Uri $vcConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing -SkipCertificateCheck
        } else {
            $vcRequests = Invoke-WebRequest -Uri $vcConfigUrl -Method GET -Headers $global:hcxVAMIConnection.headers -UseBasicParsing
        }
        $vcData = ($vcRequests.content | ConvertFrom-Json).data.items

        $tmp = [pscustomobject] @{
            Name = $vcData.config.name;
            Version = $vcData.config.version;
            Build = $vcData.config.buildNumber;
            UUID = $vcData.config.vcuuid;
            HCXUUID = $vcData.config.uuid;
        }
        $tmp
    }
}