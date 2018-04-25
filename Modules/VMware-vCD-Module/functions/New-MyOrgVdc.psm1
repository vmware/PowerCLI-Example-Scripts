Function New-MyOrgVdc {
<#
.SYNOPSIS
    Creates a new vCD Org VDC with Default Parameters

.DESCRIPTION
    Creates a new vCD Org VDC with Default Parameters

    Default Parameters are:
    * Network Quota
    * VM Quota
    * 'vCpu In Mhz'
    * Fast Provisioning
    * Thin Provisioning
    * private Catalog

.NOTES
    File Name  : New-MyOrgVdc.ps1
    Author     : Markus Kraus
    Version    : 1.3
    State      : Ready

.LINK
    https://mycloudrevolution.com/

.EXAMPLE
    New-MyOrgVdc -Name "TestVdc" -AllocationModel AllocationPool -CPULimit 1000 -MEMLimit 1000 -StorageLimit 1000 -StorageProfile "Standard-DC01" -NetworkPool "NetworkPool-DC01" -ProviderVDC "Provider-VDC-DC01" -Org "TestOrg" -ExternalNetwork "External_OrgVdcNet"

.EXAMPLE
    New-MyOrgVdc -Name "TestVdc" -AllocationModel AllocationVApp -StorageLimit 1000 -StorageProfile "Standard-DC01" -NetworkPool "NetworkPool-DC01" -ProviderVDC "Provider-VDC-DC01" -Org "TestOrg"

.PARAMETER Name
    Name of the New Org VDC as String

.PARAMETER AllocationModel
    Allocation Model of the New Org VDC as String

.PARAMETER CPULimit
    CPU Limit (MHz) of the New Org VDC as String

    Default: 0 (Unlimited)

    Note: If AllocationModel is not AllocationVApp (Pay as you go), a limit needs to be set

.PARAMETER MEMLimit
    Memory Limit (MB) of the New Org VDC as String

    Default: 0 (Unlimited)

    Note: If AllocationModel is not AllocationVApp (Pay as you go), a limit needs to be set

.PARAMETER StorageLimit
    Storage Limit (MB) of the New Org VDC as String

.PARAMETER StorageProfile
     Storage Profile of the New Org VDC as String

.PARAMETER NetworkPool
     Network Pool of the New Org VDC as String

.PARAMETER ExternalNetwork
     Optional External Network of the New Org VDC as String

.PARAMETER Enabled
    Should the New Org VDC be enabled after creation

    Default:$false

    Note: If an External Network is requested the Org VDC will be enabled during External Network Configuration

.PARAMETER ProviderVDC
    ProviderVDC where the new Org VDC should be created as string

.PARAMETER Org
    Org where the new Org VDC should be created as string

.PARAMETER Timeout
    Timeout for the Org VDC to get Ready

    Default: 120s

#>
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Name of the New Org VDC as String")]
        [ValidateNotNullorEmpty()]
            [String] $Name,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Allocation Model of the New Org VDC as String")]
        [ValidateNotNullorEmpty()]
        [ValidateSet("AllocationPool","AllocationVApp")]
            [String] $AllocationModel,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, HelpMessage="CPU Limit (MHz) of the New Org VDC as String")]
        [ValidateNotNullorEmpty()]
            [int] $CPULimit = 0,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, HelpMessage="Memory Limit (MB) of the New Org VDC as String")]
        [ValidateNotNullorEmpty()]
            [int] $MEMLimit = 0,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Storage Limit (MB) of the New Org VDC as String")]
        [ValidateNotNullorEmpty()]
            [int] $StorageLimit,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Storage Profile of the New Org VDC as String")]
        [ValidateNotNullorEmpty()]
            [String] $StorageProfile,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Network Pool of the New Org VDC as String")]
        [ValidateNotNullorEmpty()]
            [String] $NetworkPool,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, HelpMessage="Optional External Network of the New Org VDC as String")]
        [ValidateNotNullorEmpty()]
            [String] $ExternalNetwork,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False, HelpMessage="Should the New Org VDC be enabled after creation")]
        [ValidateNotNullorEmpty()]
            [Switch]$Enabled,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="ProviderVDC where the new Org VDC should be created as string")]
        [ValidateNotNullorEmpty()]
            [String] $ProviderVDC,
        [Parameter(Mandatory=$True, ValueFromPipeline=$False, HelpMessage="Org where the new Org VDC should be created as string")]
        [ValidateNotNullorEmpty()]
            [String] $Org,
        [Parameter(Mandatory=$False, ValueFromPipeline=$False,HelpMessage="Timeout for the Org VDC to get Ready")]
        [ValidateNotNullorEmpty()]
            [int] $Timeout = 120
    )
    Process {
        ## Create Objects and all Settings
        Write-Verbose "Create Objects and all Settings"
        $adminVdc = New-Object VMware.VimAutomation.Cloud.Views.AdminVdc
        $adminVdc.Name = $name
        $adminVdc.IsEnabled = $Enabled
        $OrgVdcproviderVdc = Get-ProviderVdc $ProviderVDC
        $providerVdcRef = New-Object VMware.VimAutomation.Cloud.Views.Reference
        $providerVdcRef.Href = $OrgVdcproviderVdc.Href
        $adminVdc.ProviderVdcReference = $providerVdcRef
        $adminVdc.AllocationModel = $AllocationModel
        $adminVdc.ComputeCapacity = New-Object VMware.VimAutomation.Cloud.Views.ComputeCapacity
        $adminVdc.ComputeCapacity.Cpu = New-Object VMware.VimAutomation.Cloud.Views.CapacityWithUsage
        $adminVdc.ComputeCapacity.Cpu.Units = "MHz"
        $adminVdc.ComputeCapacity.Cpu.Limit = $CPULimit
        $adminVdc.ComputeCapacity.Cpu.Allocated = $CPULimit
        $adminVdc.ComputeCapacity.Memory = New-Object VMware.VimAutomation.Cloud.Views.CapacityWithUsage
        $adminVdc.ComputeCapacity.Memory.Units = "MB"
        $adminVdc.ComputeCapacity.Memory.Limit = $MEMLimit
        $adminVdc.ComputeCapacity.Memory.Allocated = $MEMLimit
        $adminVdc.StorageCapacity = New-Object VMware.VimAutomation.Cloud.Views.CapacityWithUsage
        $adminVdc.StorageCapacity.Units = "MB"
        $adminVdc.StorageCapacity.Limit = $StorageLimit
        $adminVdc.NetworkQuota = 10
        $adminVdc.VmQuota = 0
        $adminVdc.VCpuInMhz = 2000
        $adminVdc.VCpuInMhz2 = 2000
        $adminVdc.UsesFastProvisioning = $false
        $adminVdc.IsThinProvision = $true

        ## Create Org vDC
        Write-Verbose "Create Org vDC"
        $OrgED = (Get-Org $Org).ExtensionData
        $orgVdc = $orgED.CreateVdc($adminVdc)

        ## Wait for getting Ready
        Write-Verbose "Wait for OrgVdc getting Ready after creation"
        $i = 0
        while(($orgVdc = Get-OrgVdc -Name $Name -Verbose:$false).Status -eq "NotReady"){
            $i++
            Start-Sleep 2
            if($i -gt $Timeout) { Write-Error "Creating OrgVdc Failed."; break}
            Write-Progress -Activity "Creating OrgVdc" -Status "Wait for OrgVdc to become Ready..."
            }
        Write-Progress -Activity "Creating OrgVdc" -Completed
        Start-Sleep 2

        ## Search given Storage Profile
        Write-Verbose "Search given Storage Profile"
        $Filter = "ProviderVdc==" + $OrgVdcproviderVdc.Id
        $ProVdcStorageProfile = search-cloud -QueryType ProviderVdcStorageProfile -Name $StorageProfile -Filter $Filter | Get-CIView

        ## Create Storage Profile Object with Settings
        Write-Verbose "Create Storage Profile Object with Settings"
        $spParams = new-object VMware.VimAutomation.Cloud.Views.VdcStorageProfileParams
        $spParams.Limit = $StorageLimit
        $spParams.Units = "MB"
        $spParams.ProviderVdcStorageProfile = $ProVdcStorageProfile.href
        $spParams.Enabled = $true
        $spParams.Default = $true
        $UpdateParams = new-object VMware.VimAutomation.Cloud.Views.UpdateVdcStorageProfiles
        $UpdateParams.AddStorageProfile = $spParams

        ## Update Org vDC
        $orgVdc = Get-OrgVdc -Name $name
        $orgVdc.ExtensionData.CreateVdcStorageProfile($UpdateParams)

        ## Wait for getting Ready
        Write-Verbose "Wait for OrgVdc getting Ready after update"
        while(($orgVdc = Get-OrgVdc -Name $name -Verbose:$false).Status -eq "NotReady"){
            $i++
            Start-Sleep 1
            if($i -gt $Timeout) { Write-Error "Update OrgVdc Failed."; break}
            Write-Progress -Activity "Updating OrgVdc" -Status "Wait for OrgVdc to become Ready..."
            }
        Write-Progress -Activity "Updating OrgVdc" -Completed
        Start-Sleep 1

        ## Search Any-StorageProfile
        Write-Verbose "Search Any-StorageProfile"
        $orgvDCAnyProfile = search-cloud -querytype AdminOrgVdcStorageProfile | Where-Object {($_.Name -match '\*') -and ($_.VdcName -eq $orgVdc.Name)} | Get-CIView

        ## Disable Any-StorageProfile
        Write-Verbose "Disable Any-StorageProfile"
        $orgvDCAnyProfile.Enabled = $False
        $return = $orgvDCAnyProfile.UpdateServerData()

        ## Remove Any-StorageProfile
        Write-Verbose "Remove Any-StorageProfile"
        $ProfileUpdateParams = new-object VMware.VimAutomation.Cloud.Views.UpdateVdcStorageProfiles
        $ProfileUpdateParams.RemoveStorageProfile = $orgvDCAnyProfile.href
        $remove = $orgvdc.extensiondata.CreatevDCStorageProfile($ProfileUpdateParams)

         ## Wait for getting Ready
        Write-Verbose "Wait for getting Ready"
        while(($orgVdc = Get-OrgVdc -Name $name -Verbose:$false).Status -eq "NotReady"){
            $i++
            Start-Sleep 1
            if($i -gt $Timeout) { Write-Error "Update Org Failed."; break}
            Write-Progress -Activity "Updating Org" -Status "Wait for Org to become Ready..."
            }
        Write-Progress -Activity "Updating Org" -Completed
        Start-Sleep 1

        ## Set NetworkPool for correct location
        Write-Verbose "Set NetworkPool for correct location"
        $orgVdc = Get-OrgVdc -Name $name
        $ProVdcNetworkPool = Get-NetworkPool -ProviderVdc $ProviderVDC -Name $NetworkPool
        $set = Set-OrgVdc -OrgVdc $orgVdc -NetworkPool $ProVdcNetworkPool -NetworkMaxCount "10"

        ## Create private Catalog
        Write-Verbose "Create private Catalog Object"
        $OrgCatalog = New-Object VMware.VimAutomation.Cloud.Views.AdminCatalog
        $OrgCatalog.name = "$Org Private Catalog"
        if (!(Get-Org $org | Get-Catalog -Name $OrgCatalog.name -ErrorAction SilentlyContinue)) {
            Write-Verbose "Create private Catalog"
            $CreateCatalog = (Get-Org $org  | Get-CIView).CreateCatalog($OrgCatalog)
            $AccessControlRule = New-CIAccessControlRule -Entity $CreateCatalog.name -EveryoneInOrg -AccessLevel ReadWrite -Confirm:$False
            }
            else {
            Write-Output "Catalog '$($OrgCatalog.name)' aleady exists!"
                }

        ## Create a direct connect network
        if ($ExternalNetwork) {
            Write-Verbose "Create a direct connect network"
            Write-Output "Org VDC '$Name' needs to be enabled to add an external Network!"
            $EnableOrgVdc = Set-OrgVdc -OrgVdc $Name -Enabled:$True
            $orgVdcView = Get-OrgVdc $Name | Get-CIView
            $extNetwork = $_.externalnetwork
            $extNetwork = Get-ExternalNetwork | Get-CIView -Verbose:$false | Where-Object {$_.name -eq $ExternalNetwork}
            $orgNetwork = new-object vmware.vimautomation.cloud.views.orgvdcnetwork
            $orgNetwork.name = $ExternalNetwork
            $orgNetwork.Configuration = New-Object VMware.VimAutomation.Cloud.Views.NetworkConfiguration
            $orgNetwork.Configuration.FenceMode = 'bridged'
            $orgNetwork.configuration.ParentNetwork = New-Object vmware.vimautomation.cloud.views.reference
            $orgNetwork.configuration.ParentNetwork.href = $extNetwork.href

            $result = $orgVdcView.CreateNetwork($orgNetwork)
            }

        Get-OrgVdc -Name $name | Format-Table -AutoSize
    }
}
