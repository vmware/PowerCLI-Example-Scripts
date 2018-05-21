Function Get-XVCMStatus {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function returns whether Cross vCenter Workload Migration Utility is running or not
    .EXAMPLE
        Get-XVCMStatus
#>
    $Uri = "http://localhost:8080/api/status" #Updated for 2.0, Old: "http://localhost:8080/api/ping" 

    $results = Invoke-WebRequest -Uri $Uri -Method GET -TimeoutSec 5

    if($results.StatusCode -eq 200) {
        Write-Host -ForegroundColor Green $results.Content
    } else { Write-Host -ForegroundColor Red "Cross vCenter Workload Migration Utility is probably not running" }
}

Function Get-XVCMSite {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function returns all registered vCenter Servers
    .EXAMPLE
        Get-XVCMSite
#>
    $Uri = "http://localhost:8080/api/sites"

    $results = Invoke-WebRequest -Uri $Uri -Method GET

    if($results.StatusCode -eq 200) {
        ($results.Content | ConvertFrom-Json)|select sitename,hostname,username
    } else { Write-Host -ForegroundColor Red "Failed to retrieve VC Site Registration details" }
}

Function New-XVCMSite {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function registers a new vCenter Server endpoint
    .PARAMETER SiteName
        The display name for the particular vCenter Server to be registered
    .PARAMETER VCHostname
        The Hostname/IP Address of vCenter Server
    .PARAMETER VCUsername
        The VC Username of vCenter Server
    .PARAMETER VCPassword
        The VC Password of vCenter Server
    .PARAMETER Insecure
        Flag to disable SSL Verification checking, useful for lab environments
    .EXAMPLE
        New-XVCMSite -SiteName "SiteA" -VCHostname "vcenter65-1.primp-industries.com" -VCUsername "administrator@vsphere.local" -VCPassword "VMware1!" -Insecure
#>
    param(
        [Parameter(Mandatory=$true)][String]$SiteName,
        [Parameter(Mandatory=$true)][String]$VCHostname,
        [Parameter(Mandatory=$true)][String]$VCUsername,
        [Parameter(Mandatory=$true)][String]$VCPassword,
        [Parameter(Mandatory=$false)][Switch]$Insecure
    )

    $Uri = "http://localhost:8080/api/sites"

    $insecureFlag = $false
    if($Insecure) {
        $insecureFlag = $true
    }

    $body = @{
        "sitename"=$SiteName;
        "hostname"=$VCHostname;
        "username"=$VCUsername;
        "password"=$VCPassword;
        "insecure"=$insecureFlag;
    }

    $body = $body | ConvertTo-Json

    Write-Host -ForegroundColor Cyan "Registering vCenter Server $VCHostname as $SiteName ..."
    $results = Invoke-WebRequest -Uri $Uri -Method POST -Body $body -ContentType "application/json"

    if($results.StatusCode -eq 200) {
        Write-Host -ForegroundColor Green "Successfully registered $SiteName"
    } else { Write-Host -ForegroundColor Red "Failed to register $SiteName" }
}

Function Remove-XVCMSite {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function removes vCenter Server endpoint
    .PARAMETER SiteName
        The name of the registered vCenter Server to remove
    .EXAMPLE
        Remove-XVCMSite -SiteName "SiteA"
#>
    param(
        [Parameter(Mandatory=$true)][String]$SiteName
    )

    $Uri = "http://localhost:8080/api/sites/$SiteName"

    Write-Host -ForegroundColor Cyan  "Deleting vCenter Server Site Registerion $SiteName ..."
    $results = Invoke-WebRequest -Uri $Uri -Method DELETE

    if($results.StatusCode -eq 200) {
        Write-Host -ForegroundColor Green "Successfully deleted $SiteName"
    } else { Write-Host -ForegroundColor Red "Failed to deleted $SiteName" }
}

Function New-XVCMRequest {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function initiates a migration request
	.PARAMETER opType
		The type of task, Relocate or Clone
	.PARAMETER SrcSite
        The name of the source vCenter Server
    .PARAMETER DstSite
        The name of the destination vCenter Server
    .PARAMETER SrcDatacenter
        The name of the source vSphere Datacenter
    .PARAMETER DstDatacenter
        The name of the destination vSphere Datacenter
    .PARAMETER SrcCluster
         <Not needed for v2.0,removed from code>
    .PARAMETER DstCluster
        The name of the destination vSphere Cluster, set to null if DstHost is defined
    .PARAMETER DstDatastore
        The name of the destination Datastore
	.PARAMETER DstHost
		The name of the destination host. Set to null if DstCluster is defined
	.PARAMETER srcVMs
        List of VMs to migrate
    .PARAMETER NetworkMapping
        Hash table of the VM network mappings between your source and destination vCenter Server
    .EXAMPLE
        New-XVCMRequest -opType Relocate -SrcSite SiteA -DstSite SiteB `
            -SrcDatacenter Datacenter-SiteA -DstDatacenter Datacenter-SiteB `
            -DstCluster $null -DstHost VMhost1.test.lab `
            -DstDatastore vsanDatastore `
            -srcVMs @("PhotonOS-01","PhotonOS-02","PhotonOS-03","PhotonOS-04") `
            -NetworkMapping @{"DVPG-VM Network 1"="DVPG-Internal Network";"DVPG-VM Network 2"="DVPG-External Network"}
#>
    param(
		[Parameter(Mandatory=$true)][String]$opType, #Added by CPM for 2.0
        [Parameter(Mandatory=$true)][String]$SrcSite,
        [Parameter(Mandatory=$true)][String]$DstSite,
        [Parameter(Mandatory=$true)][String]$SrcDatacenter,
        [Parameter(Mandatory=$true)][String]$DstDatacenter,
        #[Parameter(Mandatory=$true)][String]$SrcCluster, #Removed by CPM for 2.0
        [Parameter(Mandatory=$true)][AllowNull()] $DstCluster, #Added [AllowNull()], removed [String] by CPM for 2.0
        [Parameter(Mandatory=$true)][String]$DstDatastore,
		[Parameter(Mandatory=$true)][AllowNull()] $DstHost, #Added by CPM for 2.0
        [Parameter(Mandatory=$true)][String[]]$srcVMs,
        [Parameter(Mandatory=$true)][Hashtable]$NetworkMapping
    )

    $Uri = "http://localhost:8080/api/tasks"

    $body = @{
        "sourceSite"=$SrcSite;
        "targetSite"=$DstSite;
        "sourceDatacenter"=$SrcDatacenter;
        "targetDatacenter"=$dstDatacenter;
        #"sourceCluster"=$SrcCluster; #Removed by CPM for 2.0
        "targetCluster"=$DstCluster;
        "targetDatastore"=$DstDatastore;
		"targetHost"=$DstHost; #Added by CPM for 2.0
        "networkMap"=$NetworkMapping;
        "vmList"=$srcVMs;
		"operationType"=$opType; #Added by CPM for 2.0
    }

    $body = $body | ConvertTo-Json

    Write-Host -ForegroundColor Cyan "Initiating migration request ..."
    $results = Invoke-WebRequest -Uri $Uri -Method POST -Body $body -ContentType "application/json"

    if($results.StatusCode -eq 200) {
        $taskId = ($results.Content | ConvertFrom-Json).requestId
        Write-Host -ForegroundColor Green "Successfully issued migration with TaskID: $taskId"
    } else { Write-Host -ForegroundColor Red "Failed to initiate migration request" }
}

Function Get-XVCMTask {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function retrieves either all migration tasks and/or a specific migration task
    .PARAMETER Id
        The task ID returned from initiating a migration
    .EXAMPLE
        Get-XVCMTask -Id <Task ID>
#>
    param(
        [Parameter(Mandatory=$false)][String]$Id
    )

    $Uri = "http://localhost:8080/api/tasks"

    if($Id) {
        $body = @{"requestId"=$Id}

        $results = Invoke-WebRequest -Uri $Uri -Method GET -Body $body -ContentType "application/json"
    } else {
        $results = Invoke-WebRequest -Uri $Uri -Method GET
    }

    if($results.StatusCode -eq 200) {
        $results.Content | ConvertFrom-Json
    } else { Write-Host -ForegroundColor Red "Failed to retrieve tasks" }
}

Function Get-VMNetwork {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function returns the list of all VM Networks attached to
        given VMs to help with initiating migration
    .PARAMETER srcVMs
        List of VMs to query their current VM Networks
    .EXAMPLE
        Get-VMNetwork -srcVMs @("PhotonOS-01","PhotonOS-02","PhotonOS-03","PhotonOS-04")
#>
    param(
        [Parameter(Mandatory=$false)][String[]]$srcVMs
    )

    if (-not $global:DefaultVIServers) { Write-Host -ForegroundColor red "No vCenter Server Connection found, please connect to your source vCenter Server using Connect-VIServer"; break }

    $results = @()
    if($srcVMs) {
        foreach ($srcVM in $srcVMs) {
            $vm = Get-VM -Name $srcVM
            $networkDetails = $vm | Get-NetworkAdapter
            $tmp = [pscustomobject] @{
                Name = $srcVM;
                Adapter = $networkDetails.name;
                Network = $networkDetails.NetworkName;
            }
            $results+=$tmp
        }
    } else {
        foreach ($vm in Get-VM) {
            $networkDetails = $vm | Get-NetworkAdapter
            $tmp = [pscustomobject] @{
                Name = $vm.Name;
                Adapter = $networkDetails.name;
                Network = $networkDetails.NetworkName;
            }
            $results+=$tmp
        }
    }
    $results
}
