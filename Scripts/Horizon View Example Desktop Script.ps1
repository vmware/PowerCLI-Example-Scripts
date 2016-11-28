Function Get-HVDesktop {
    <#  
    .SYNOPSIS  
        This cmdlet retrieves the virtual desktops on a horizon view Server.
    .DESCRIPTION 
        This cmdlet retrieves the virtual desktops on a horizon view Server.
    .NOTES  
        Author:  Alan Renouf, @alanrenouf,virtu-al.net
    .PARAMETER State
        Hash table containing states to filter on
    .EXAMPLE
	    List All Desktops
        Get-HVDesktop

    .EXAMPLE
        List All Problem Desktops
        Get-HVDesktop -state @('PROVISIONING_ERROR', 
                        'ERROR', 
                        'AGENT_UNREACHABLE', 
                        'AGENT_ERR_STARTUP_IN_PROGRESS',
                        'AGENT_ERR_DISABLED', 
                        'AGENT_ERR_INVALID_IP', 
                        'AGENT_ERR_NEED_REBOOT', 
                        'AGENT_ERR_PROTOCOL_FAILURE', 
                        'AGENT_ERR_DOMAIN_FAILURE', 
                        'AGENT_CONFIG_ERROR', 
                        'UNKNOWN')
    #>
Param (
        $State
    )
    
    $ViewAPI = $global:DefaultHVServers[0].ExtensionData
    $query_service = New-Object "Vmware.Hv.QueryServiceService"
    $query = New-Object "Vmware.Hv.QueryDefinition"
    $query.queryEntityType = 'MachineSummaryView'
    if ($State) {
        [VMware.Hv.QueryFilter []] $filters = @()
        foreach ($filterstate in $State) {
            $filters += new-object VMware.Hv.QueryFilterEquals -property @{'memberName' = 'base.basicState'; 'value' = $filterstate}
        }
        $orFilter = new-object VMware.Hv.QueryFilterOr -property @{'filters' =  $filters}
        $query.Filter = $orFilter
    }
    $Desktops = $query_service.QueryService_Query($ViewAPI,$query)
    $Desktops.Results.Base
}


