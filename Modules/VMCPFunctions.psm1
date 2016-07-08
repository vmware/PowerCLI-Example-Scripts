function Get-VMCPSettings {
<#	
	.NOTES
	===========================================================================
	 Created on:   	10/27/2015 9:25 PM
	 Created by:   	Brian Graf
     Twitter:       @vBrianGraf
     VMware Blog:   blogs.vmware.com/powercli
     Personal Blog: www.vtagion.com
	===========================================================================
	.DESCRIPTION
		This function will allow users to view the VMCP settings for their clusters

    .Example
    # This will show you the VMCP settings of your cluster
    Get-VMCPSettings -cluster LAB-CL

    .Example
    # This will show you the VMCP settings of your cluster
    Get-VMCPSettings -cluster (Get-Cluster Lab-CL)  
#>
[CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
      HelpMessage='What is the Cluster Name?')]
    $cluster
   )
   Begin {
        # Determine input and convert to ClusterImpl object
        Switch ($cluster.GetType().Name)
        {
            "string" {$CL = Get-Cluster $cluster}
            "ClusterImpl" {$CL = $cluster}
        }
   }
   Process {
        # Work with the Cluster View
        $ClusterMod = Get-View -Id "ClusterComputeResource-$($cl.ExtensionData.MoRef.Value)"

        # Create Hashtable with desired properties to return
        $properties = [ordered]@{
        'Cluster' = $ClusterMod.Name;
        'VMCP Status' = $clustermod.Configuration.DasConfig.VmComponentProtecting;
        'Protection For APD' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForAPD;
        'APD Timeout Enabled' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.EnableAPDTimeoutForHosts;
        'APD Timeout (Seconds)' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmTerminateDelayForAPDSec;
        'Reaction on APD Cleared' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmReactionOnAPDCleared;
        'Protection For PDL' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForPDL
        }

        # Create PSObject with the Hashtable
        $object = New-Object -TypeName PSObject -Prop $properties

        # Show object
        return $object
   }
   End {}

}

function Set-VMCPSettings {
<#	
	.NOTES
	===========================================================================
	 Created on:   	10/27/2015 9:25 PM
	 Created by:   	Brian Graf
     Twitter:       @vBrianGraf
     VMware Blog:   blogs.vmware.com/powercli
     Personal Blog: www.vtagion.com
	===========================================================================
	.DESCRIPTION
		This function will allow users to enable/disable VMCP and also allow
    them to configure the additional VMCP settings
    For each parameter, users should use the 'Tab' button to auto-fill the
    possible values.

    .Example
    # This will enable VMCP and configure the Settings
    Set-VMCPSettings -cluster LAB-CL -enableVMCP:$True -VmStorageProtectionForPDL `
    restartAggressive -VmStorageProtectionForAPD restartAggressive `
    -VmTerminateDelayForAPDSec 2000 -VmReactionOnAPDCleared reset 

    .Example
    # This will disable VMCP and configure the Settings
    Set-VMCPSettings -cluster LAB-CL -enableVMCP:$False -VmStorageProtectionForPDL `
    disabled -VmStorageProtectionForAPD disabled `
    -VmTerminateDelayForAPDSec 600 -VmReactionOnAPDCleared none 
#>
 [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
      HelpMessage='What is the Cluster Name?')]
    $cluster,
    
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$False,
      HelpMessage='True=Enabled False=Disabled')]
    [switch]$enableVMCP,

    [Parameter(Mandatory=$True,
    ValueFromPipeline=$False,
      HelpMessage='Actions that can be taken in response to a PDL event')]
      [ValidateSet("disabled","warning","restartAggressive")]
    [string]$VmStorageProtectionForPDL,
    
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$False,
      HelpMessage='Options available for an APD response')]
      [ValidateSet("disabled","restartConservative","restartAggressive","warning")]
    [string]$VmStorageProtectionForAPD,
    
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$False,
      HelpMessage='Value in seconds')]
    [Int]$VmTerminateDelayForAPDSec,
    
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$False,
      HelpMessage='This setting will instruct vSphere HA to take a certain action if an APD event is cleared')]
      [ValidateSet("reset","none")]
    [string]$VmReactionOnAPDCleared

  )
Begin{  

    # Determine input and convert to ClusterImpl object
    Switch ($cluster.GetType().Name)
    {
        "string" {$CL = Get-Cluster $cluster}
        "ClusterImpl" {$CL = $cluster}
    }
}
Process{
    # Create the object we will configure
    $settings = New-Object VMware.Vim.ClusterConfigSpecEx
    $settings.dasConfig = New-Object VMware.Vim.ClusterDasConfigInfo
    
    # Based on $enableVMCP switch 
        if ($enableVMCP -eq $false)  { 
            $settings.dasConfig.vmComponentProtecting = "disabled"
        } 
        elseif ($enableVMCP -eq $true) { 
            $settings.dasConfig.vmComponentProtecting = "enabled" 
        }  

            #Create the VMCP object to work with
            $settings.dasConfig.defaultVmSettings = New-Object VMware.Vim.ClusterDasVmSettings
            $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings = New-Object VMware.Vim.ClusterVmComponentProtectionSettings

            #Storage Protection For PDL
            $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmStorageProtectionForPDL = "$VmStorageProtectionForPDL"

            #Storage Protection for APD
            switch ($VmStorageProtectionForAPD) {
                "disabled" {
                    # If Disabled, there is no need to set the Timeout Value
                    $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmStorageProtectionForAPD = 'disabled'
                    $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.enableAPDTimeoutForHosts = $false
                }

                "restartConservative" {
                    $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmStorageProtectionForAPD = 'restartConservative'
                    $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.enableAPDTimeoutForHosts = $true
                    $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmTerminateDelayForAPDSec = $VmTerminateDelayForAPDSec
                }

                "restartAggressive" {
                    $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmStorageProtectionForAPD = 'restartAggressive'
                    $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.enableAPDTimeoutForHosts = $true
                    $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmTerminateDelayForAPDSec = $VmTerminateDelayForAPDSec
                }

                "warning" {
                    # If Warning, there is no need to set the Timeout Value
                    $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmStorageProtectionForAPD = 'warning'
                    $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.enableAPDTimeoutForHosts = $false
                }

            }
       
            # Reaction On APD Cleared
            $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmReactionOnAPDCleared = "$VmReactionOnAPDCleared"

            # Execute API Call
            $modify = $true
            $ClusterMod = Get-View -Id "ClusterComputeResource-$($cl.ExtensionData.MoRef.Value)"
            $ClusterMod.ReconfigureComputeResource_Task($settings, $modify) | out-null
  


}
End{
    # Update variable data after API call
    $ClusterMod.updateViewData()

    # Create Hashtable with desired properties to return
    $properties = [ordered]@{
    'Cluster' = $ClusterMod.Name;
    'VMCP Status' = $clustermod.Configuration.DasConfig.VmComponentProtecting;
    'Protection For APD' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForAPD;
    'APD Timeout Enabled' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.EnableAPDTimeoutForHosts;
    'APD Timeout (Seconds)' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmTerminateDelayForAPDSec;
    'Reaction on APD Cleared' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmReactionOnAPDCleared;
    'Protection For PDL' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForPDL
    }

    # Create PSObject with the Hashtable
    $object = New-Object -TypeName PSObject -Prop $properties

    # Show object
    return $object

}
}
