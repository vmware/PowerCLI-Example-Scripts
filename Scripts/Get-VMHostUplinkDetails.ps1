function Get-VMHostUplinkDetails {
<#	
    .NOTES
    ===========================================================================
    Created by: Markus Kraus
    ===========================================================================
    Changelog:  
    2017.03 ver 1.0 Base Release  
    2020.03 ver 1.1 Add LLDP Support
    ===========================================================================
    External Code Sources: 
    Get-CDP Version from @LucD22
    https://communities.vmware.com/thread/319553
	
	LLDP PowerCLI Tweak
	https://tech.zsoldier.com/2018/05/vmware-get-cdplldp-info-from.html
    ===========================================================================
    Tested Against Environment:
    vSphere Version: vSphere 6.7 U3
    PowerCLI Version: PowerCLI 11.5
    PowerShell Version: 5.1
    OS Version: Server 2016
    Keyword: ESXi, Network, CDP, LLDP, VDS, vSwitch, VMNIC 
    ===========================================================================

    .DESCRIPTION
    This Function collects detailed informations about your ESXi Host connections to pSwitch and VDS / vSwitch. 
    LLDP Informations might only be available when uplinks are connected to a VDS.

    .Example
    Get-VMHost -Name MyHost | Get-VMHostUplinkDetails -Type LLDP | Where-Object {$_.VDS -ne "-No Backing-"}  | Format-Table -AutoSize

    .Example
    Get-VMHost -Name MyHost | Get-VMHostUplinkDetails -Type CDP | Where-Object {$_.VDS -ne "-No Backing-"}  | Sort-Object ClusterName, HostName, vmnic | Format-Table -AutoSize

    .Example
    Get-Cluster -Name MyCluster | Get-VMHost | Get-VMHostUplinkDetails -Type LLDP | Format-Table -AutoSize

    .Example
    Get-Cluster -Name MyCluster | Get-VMHost | Get-VMHostUplinkDetails -Type CDP | Format-Table -AutoSize

    .PARAMETER myHosts
    Hosts to process


#Requires PS -Version 5.0
#Requires -Modules VMware.VimAutomation.Core, @{ModuleName="VMware.VimAutomation.Core";ModuleVersion="6.3.0.0"}
#>

[CmdletBinding()]
param( 
    [Parameter(Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage = "Specifies the hosts for which you want to retrieve the uplink details.")]
        [ValidateNotNullorEmpty()]
        [Alias("myHosts")]
        [VMware.VimAutomation.Types.VMHost[]] $VMHost,
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, Position=1, HelpMessage = "Type of infos you want to collect (CDP / LLDP)")]
        [ValidateSet("CDP","LLDP")]
        [String] $Type
        
)

Begin {


    function Get-Info ($VMhostToProcess){
        $VMhostProxySwitch = $VMhostToProcess.NetworkInfo.ExtensionData.ProxySwitch 
        $VMhostSwitch = $VMhostToProcess.NetworkInfo.VirtualSwitch

        $objReport = @()
        $VMhostToProcess| ForEach-Object{Get-View $_.ID} | 
        ForEach-Object{ Get-View $_.ConfigManager.NetworkSystem} | 
        ForEach-Object{ foreach($physnic in $_.NetworkInfo.Pnic){ 
            
            if($Type -eq "CDP"){
                $obj = "" | Select-Object ClusterName,HostName,vmnic,PCI,MAC,VDS,vSwitch,CDP_Port,CDP_Device,CDP_Address
            }
            elseif($Type -eq "LLDP"){
                $obj = "" | Select-Object ClusterName,HostName,vmnic,PCI,MAC,VDS,vSwitch,LLDP_Port,LLDP_Chassis,LLDP_SystemName
                }
                else {
                    Throw "Invalide Type"
                    }
     
            $pnicInfo = $_.QueryNetworkHint($physnic.Device) 
            foreach($hint in $pnicInfo){ 
                $obj.ClusterName = $VMhostToProcess.parent.name
                $obj.HostName = $VMhostToProcess.name 
                $obj.vmnic = $physnic.Device
                $obj.PCI = $physnic.PCI
                $obj.MAC = $physnic.Mac
                if ($backing = ($VMhostProxySwitch | Where-Object {$_.Spec.Backing.PnicSpec.PnicDevice -eq $physnic.Device})) {
                    $obj.VDS = $backing.DvsName
                    } 
                    else {
                        $obj.VDS = "-No Backing-"
                        }
                if ($backing = ($VMhostSwitch | Where-Object {$_.Nic -eq $physnic.Device})) {
                    $obj.vSwitch = $backing.name
                    } 
                    else {
                        $obj.vSwitch = "-No Backing-"
                        }
                if($Type -eq "CDP"){
                    if( $hint.ConnectedSwitchPort ) { 
                        $obj.CDP_Port = $hint.ConnectedSwitchPort.PortId
                        $obj.CDP_Device = $hint.ConnectedSwitchPort.DevId
                        $obj.CDP_Address = $hint.ConnectedSwitchPort.Address  
                        } 
                        else { 
                            $obj.CDP_Port = "-No Info-" 
                            $obj.CDP_Device = "-No Info-" 
                            $obj.CDP_Address = "-No Info-" 
                            }
                        }
                if($Type -eq "LLDP"){ 
                    if( $hint.LldpInfo ) { 
                        $obj.LLDP_Port = $hint.LldpInfo.PortId
                        $obj.LLDP_Chassis = $hint.LldpInfo.ChassisId
                        $obj.LLDP_SystemName = ($hint.LldpInfo.Parameter | Where-Object key -eq "System Name").Value
                        } 
                        else { 
                            $obj.LLDP_Port = "-No Info-" 
                            $obj.LLDP_Chassis = "-No Info-" 
                            $obj.LLDP_SystemName = "-No Info-" 
                            }
                        } 
                

            } 
            $objReport += $obj 
            } 
        } 
        $objReport 
    } 
  
}

Process {

    $VMHost | Foreach-Object { Write-Output (Get-Info $_) }

}

}
