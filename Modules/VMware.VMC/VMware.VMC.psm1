Function Get-VMCCommand {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Returns all cmdlets for VMware Cloud on AWS
    .DESCRIPTION
        This cmdlet will allow you to return all cmdlets included in the VMC module
    .EXAMPLE
        Get-VMCCommand
    .EXAMPLE
        Get-Command -Module VMware.VMC
    .NOTES
        You can either use this cmdlet or the Get-Command cmdlet as seen in Example 2
#>
    Get-command -Module VMware.VimAutomation.Vmc
    Get-Command -Module VMware.VMC

}
Function Connect-VMCVIServer {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Cmdlet to connect to your VMC vCenter Server
    .DESCRIPTION
        This will connect you to both the VMC ViServer as well as the CiSServer at the same time.
    .EXAMPLE
        Connect-VMCVIServer -Server <VMC vCenter address> -User <Username> -Password <Password>
    .NOTES
        Easiest way is to pipe through your credentials from Get-VMCSDDCDefaultCredential
#>
    Param (
        [Parameter(Mandatory=$true)]$Org,
        [Parameter(Mandatory=$true)]$Sddc,
        [switch]$Autologin
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        $creds = Get-VMCSDDCDefaultCredential -Org $Org -Sddc $Sddc
        Write-Host "Connecting to VMC vCenter Server" $creds.vc_public_ip
        Connect-VIServer -Server $creds.vc_public_ip -User $creds.cloud_username -Password $creds.cloud_password | Add-Member -MemberType Noteproperty -Name Location -Value "VMC"
        Write-Host "Connecting to VMC CIS Endpoint" $creds.vc_public_ip
        Connect-CisServer -Server $creds.vc_public_ip -User $creds.cloud_username -Password $creds.cloud_password | Add-Member -MemberType Noteproperty -Name Location -Value "VMC"
    }
}
Function Get-VMCOrg {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Return the Orgs that you are a part of
    .DESCRIPTION
        Depending on what you've purchased, you may be a part of one or more VMC Orgs. This will return your orgs
    .EXAMPLE
        Get-VMCOrg
    .EXAMPLE
        Get-VMCOrg -Name <Org Name>
    .NOTES
        Return all the info about the orgs you are a part of
#>
    Param (
       [Parameter(Mandatory=$false)]$Name
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use Connect-VMC to connect" } Else {
        $orgService = Get-VMCService com.vmware.vmc.orgs
        if ($PSBoundParameters.ContainsKey("Name")){
            $orgs = $orgService.list() | Where {$_.display_name -match $Name}
        } Else {
            $orgs = $orgService.list()
        }
        $Orgs | Select display_name, name, user_name, created, id
    }
}
Function Get-VMCSDDC {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Returns all of the SDDCs you are associated to
    .DESCRIPTION
        Returns all of the SDDCs ayou are associated to
    .EXAMPLE
        Get-VMCSDDC -Org <Org Name>
    .EXAMPLE
        Get-VMCSDDC -Name <SDDC Name> -Org <Org Name>
#>
    Param (
        [Parameter(Mandatory=$True)]$Org,
        [Parameter(Mandatory=$false)]$Name
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Org")){
            $orgs = Get-VMCOrg -Name $Org
        } else {
            $orgs = Get-VMCOrg
        }

        foreach ($org in $orgs) {
            $orgID = $org.ID
            $sddcService = Get-VMCService com.vmware.vmc.orgs.sddcs
            if ($PSBoundParameters.ContainsKey("Name")){
                $sddcService.list($OrgID) | Where {$_.name -match $Name}
            } Else {
                $sddcService.list($OrgID)
            }
        }
    }
}
Function Get-VMCTask {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Returns all of the VMC Tasks
    .DESCRIPTION
        Returns all of the VMC Tasks that have either occurred or are in process
    .EXAMPLE
        Get-VMCTask
#>
    Param (
        [Parameter(Mandatory=$True)]$Org
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Org")){
            $orgs = Get-VMCOrg -Name $Org
        } else {
            $orgs = Get-VMCOrg
        }

        foreach ($org in $orgs) {
            $orgID = $org.ID
            $taskService = Get-VMCService com.vmware.vmc.orgs.tasks
            $taskService.list($OrgID) | Select * -ExcludeProperty Help
        }
    }
}
Function Get-VMCSDDCDefaultCredential {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Returns the default credential for the SDDC
    .DESCRIPTION
        Returns the default credential for the sddc
    .EXAMPLE
        Get-VMCSDDCDefaultCredential -Org <Org Name>
    .EXAMPLE
        Get-VMCSDDCDefaultCredential -Sddc <SDDC Name> -Org <Org Name>
#>
    Param (
        [Parameter(Mandatory=$true)]$Org,
        [Parameter(Mandatory=$false)]$Sddc
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Sddc")){
            $sddcs = Get-VMCSDDC -Name $Sddc -Org $Org
        } else {
            $sddcs = Get-VMCSDDC -Org $Org
        }

        foreach ($sddc in $sddcs) {
            $sddc.resource_config | Select-object vc_url, vc_management_ip, vc_public_ip, cloud_username, cloud_password
        }
    }
}
Function Get-VMCSDDCPublicIP {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================

    .SYNOPSIS
        Returns your Public IPs
    .DESCRIPTION
        Returns your Public IPs
    .EXAMPLE
        Get-VMCSDDCPublicIP -Org <Org Name>
    .EXAMPLE
        Get-VMCSDDCPublicIP -Sddc <SDDC Name> -Org <Org Name>
    .NOTES
        Return your Public IPs that you have assigned to your account
#>
    Param (
        [Parameter(Mandatory=$true)]$Org,
        [Parameter(Mandatory=$false)]$Sddc
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Sddc")){
            $sddcs = Get-VMCSDDC -Name $Sddc -Org $Org
        } else {
            $sddcs = Get-VMCSDDC -Org $Org
        }

        foreach ($sddc in $sddcs) {
            $sddc.resource_config.Public_ip_pool
        }
    }
}
Function Get-VMCVMHost {
    Param (
        [Parameter(Mandatory=$false)]$Sddc,
        [Parameter(Mandatory=$true)]$Org
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Sddc")){
            $sddcs = Get-VMCSDDC -Name $Sddc -Org $Org
        } else {
            $sddcs = Get-VMCSDDC -Org $Org
        }

        $results = @()
        foreach ($sddc in $sddcs) {
            foreach ($vmhost in $sddc.resource_config.esx_hosts) {
                $tmp = [pscustomobject] @{
                    esx_id = $vmhost.esx_id;
                    name = $vmhost.name;
                    hostname = $vmhost.hostname;
                    esx_state = $vmhost.esx_state;
                    sddc_id = $sddc.id;
                    org_id = $sddc.org_id;
                }
                $results += $tmp
            }
            $results
        }
    }
}
Function Get-VMCSDDCVersion {
<#
    .NOTES
    ===========================================================================
    Created by:    VMware
    Date:          11/17/2017
    Organization:  VMware
    Blog:          http://vmware.com/go/powercli
    Twitter:       @powercli
    ===========================================================================
    
    .SYNOPSIS
        Returns SDDC Version
    .DESCRIPTION
        Returns Version of the SDDC
    .EXAMPLE
        Get-VMCSDDCVersion -Name <SDDC Name> -Org <Org Name>
#>
    Param (
        [Parameter(Mandatory=$True)]$Org,
        [Parameter(Mandatory=$false)]$Name
    )

    If (-Not $global:DefaultVMCServers) { Write-error "No VMC Connection found, please use the Connect-VMC to connect" } Else {
        if ($PSBoundParameters.ContainsKey("Org")){
            $orgs = Get-VMCOrg -Name $Org
        } else {
            $orgs = Get-VMCOrg
        }

        foreach ($org in $orgs) {
            $orgID = $org.ID
            $sddcService = Get-VMCService com.vmware.vmc.orgs.sddcs
            if ($PSBoundParameters.ContainsKey("Name")){
                ($sddcService.list($OrgID) | Where {$_.name -match $Name}).resource_config.sddc_manifest | Select *version
            } Else {
                ($sddcService.list($OrgID)).resource_config.sddc_manifest | Select *version
            }
        }
    }
}
Export-ModuleMember -Function 'Get-VMCCommand', 'Connect-VMCVIServer', 'Get-VMCOrg', 'Get-VMCSDDC', 'Get-VMCTask', 'Get-VMCSDDCDefaultCredential', 'Get-VMCSDDCPublicIP', 'Get-VMCVMHost', 'Get-VMCSDDCVersion'