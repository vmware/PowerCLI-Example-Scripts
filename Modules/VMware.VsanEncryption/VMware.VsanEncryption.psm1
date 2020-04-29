# Script Module : VMware.VsanEncryption
# Version       : 1.0
# Author        : Jase McCarty, VMware Storage & Availability Business Unit

# Copyright © 2018 VMware, Inc. All Rights Reserved.

# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


Function Invoke-VsanEncryptionRekey {
   <#
   .SYNOPSIS
      This function will initiate a ReKey of a vSAN Cluster. Shallow ReKeying (KEK Only) or Deep ReKeying (DEK Also) are supported, as well as Reduced Redundancy if necessary. 

   .DESCRIPTION
      This function will initiate a ReKey of a vSAN Cluster. Shallow ReKeying (KEK Only) or Deep ReKeying (DEK Also) are supported, as well as Reduced Redundancy if necessary. 

   .PARAMETER Cluster
      Specifies the Cluster to perform the rekey process on

   .PARAMETER DeepRekey
      Use to invoke a Deep Rekey ($true) or a Shallow ($false or omit)
    
   .PARAMETER ReducedRedundancy
      For clusters that have 4 or more hosts, this will allow for reduced redundancy. 
      For clusters that have 2 or 3 hosts, this does not need to be set (can be).

   .EXAMPLE
      C:\PS>Invoke-VsanEncryptionRekey -Cluster "ClusterName" -DeepRekey $true/$false -ReducedRedundancy $true/$false

   #>

    # Set our Parameters
    [CmdletBinding()]Param(
    [Parameter(Mandatory = $True)][String]$Cluster,
    [Parameter(Mandatory = $False)][Boolean]$DeepRekey,
    [Parameter(Mandatory = $False)][Boolean]$ReducedRedundancy
    )

    # Get the Cluster 
    $VsanCluster = Get-Cluster -Name $Cluster

    # Get the vSAN Cluster Configuration View
    $VsanVcClusterConfig = Get-VsanView -Id "VsanVcClusterConfigSystem-vsan-cluster-config-system"

    # Get Encryption State
    $EncryptedVsan = $VsanVcClusterConfig.VsanClusterGetConfig($VsanCluster.ExtensionData.MoRef).DataEncryptionConfig

    # If vSAN is enabled and it is Encrypted
    If($VsanCluster.vSanEnabled -And $EncryptedVsan.EncryptionEnabled){

    # Get a count of hosts to guarantee reduced redundancy for 2 and 3 node clusters
    $HostCount = $VsanCluster | Select @{n="count";e={($_ | Get-VMHost).Count}}

    # If reduced redundancy is specified, or there are less than 4 hosts, force reduced redundancy
    If (($ReducedRedundancy -eq $true) -or ($HostCount.Value -lt 4)) {

    }
    # Determine Rekey Type for messaging
    Switch ($DeepRekey) {
        $true   { $ReKeyType = "deep"}
        default { $ReKeyType = "shallow"}
    }

    # Determine Reduced Redundancy for messaging
    Switch ($ReducedRedundancy) {
        $true   { $RRMessage = "with reduced redundancy"}
        default { $RRMessage = ""}
    }

    # Echo task being performed
    Write-Host "Executing $ReKeyType rekey of vSAN Cluster $VsanCluster $RRMessage"

    # Execute the rekeying task
        $ReKeyTask = $VsanVcClusterConfig.VsanEncryptedClusterRekey_Task($VsanCluster.ExtensionData.MoRef,$DeepRekey,$ReducedRedundancy)
    }
}

Function Set-VsanEncryptionKms {
    <#
    .SYNOPSIS
       This function will set the KMS to be used with vSAN Encryption 
 
    .DESCRIPTION
       This function will set the KMS to be used with vSAN Encryption 
 
    .PARAMETER Cluster
       Specifies the Cluster to set the KMS server for
 
    .PARAMETER KmsCluster
       Use to set the KMS Cluster to be used with vSAN Encryption
      
    .EXAMPLE
       C:\PS>Set-VsanEncryptionKms -Cluster "ClusterName" -KmsCluster "vCenter KMS Cluster Entry"
 
    #>
 
     # Set our Parameters
     [CmdletBinding()]Param(
     [Parameter(Mandatory = $True)][String]$Cluster,
     [Parameter(Mandatory = $False)][String]$KmsCluster
     )
 
     # Get the Cluster 
     $VsanCluster = Get-Cluster -Name $Cluster
 
     # Get the list of KMS Servers that are included 
     $KmsClusterList = Get-KmsCluster

     # Was a KMS Cluster Specified? 
     #     Specified: Is it in the list?
     #                Is it not in the list?
     # Not Specified: Present a list 
     If ($KmsCluster) {
        If ($KmsClusterList.Name.Contains($KmsCluster)) {
            Write-Host "$KmsCluster In the list, proceeding" -ForegroundColor Green
            $KmsClusterProfile = $KmsClusterList | Where-Object {$_.Name -eq $KmsCluster}
        } else {
            
            $Count = 0
            Foreach ($KmsClusterItem in $KmsClusterList) {
                Write-Host "$Count) $KmsClusterItem "
                $Count = $Count + 1
            }
            $KmsClusterEntry = Read-Host -Prompt "$KmsCluster is not valid, please select one of the existing KMS Clusters to use" 
            Write-Host $KmsClusterList[$KmsClusterEntry]
            $KmsClusterProfile = $KmsClusterList[$KmsClusterEntry]
        }
     } else {
            
        $Count = 0
        Foreach ($KmsClusterItem in $KmsClusterList) {
            Write-Host "$Count) $KmsClusterItem "
            $Count = $Count + 1
        }
        $KmsClusterEntry = Read-Host -Prompt "No KMS provided, please select one of the existing KMS Clusters to use" 
        Write-Host $KmsClusterList[$KmsClusterEntry]
        $KmsClusterProfile = $KmsClusterList[$KmsClusterEntry]
    }

     # Get the vSAN Cluster Configuration View
     $VsanVcClusterConfig = Get-VsanView -Id "VsanVcClusterConfigSystem-vsan-cluster-config-system"
 
     # Get Encryption State
     $EncryptedVsan = $VsanVcClusterConfig.VsanClusterGetConfig($VsanCluster.ExtensionData.MoRef).DataEncryptionConfig
 
     # If vSAN is enabled and it is Encrypted
     If($VsanCluster.vSanEnabled -And $EncryptedVsan.EncryptionEnabled){

        If ($EncryptedVsan.KmsProviderId.Id -eq $KmsClusterProfile.Name) {
            # If the Specified KMS Profile is the KMS Profile being used, then don't do anything
            Write-Host $EncryptedVsan.KmsProviderId.Id "is already the assigned KMS Cluster Profile, exiting"
        } else {
            Write-Host "Changing the KMS Profile to $KmsClusterProfile on Cluster $VsanCluster"

            # Setup the KMS Provider Id Specification
            $KmsProviderIdSpec = New-Object VMware.Vim.KeyProviderId
            $KmsProviderIdSpec.Id = $KmsClusterProfile.Name

            # Setup the Data Encryption Configuration Specification
            $DataEncryptionConfigSpec = New-Object VMware.Vsan.Views.VsanDataEncryptionConfig
            $DataEncryptionConfigSpec.KmsProviderId = $KmsProviderIdSpec
            $DataEncryptionConfigSpec.EncryptionEnabled = $true

            # Set the Reconfigure Specification to use the Data Encryption Configuration Spec
            $vsanReconfigSpec = New-Object VMware.Vsan.Views.VimVsanReconfigSpec
            $vsanReconfigSpec.DataEncryptionConfig = $DataEncryptionConfigSpec
            
            # Execute the task of changing the KMS Cluster Profile Being Used
            $ChangeKmsTask = $VsanVcClusterConfig.VsanClusterReconfig($VsanCluster.ExtensionData.MoRef,$vsanReconfigSpec)
        }

     }
 }

 Function Get-VsanEncryptionKms {
    <#
    .SYNOPSIS
       This function will set the KMS to be used with vSAN Encryption 
 
    .DESCRIPTION
       This function will set the KMS to be used with vSAN Encryption 
 
    .PARAMETER Cluster
       Specifies the Cluster to set the KMS server for
       
    .EXAMPLE
       C:\PS>Get-VsanEncryptionKms -Cluster "ClusterName"
    #>
 
    # Set our Parameters
    [CmdletBinding()]Param([Parameter(Mandatory = $True)][String]$Cluster)
 
    # Get the Cluster 
    $VsanCluster = Get-Cluster -Name $Cluster
 
    # Get the vSAN Cluster Configuration View
    $VsanVcClusterConfig = Get-VsanView -Id "VsanVcClusterConfigSystem-vsan-cluster-config-system"
 
    # Get Encryption State
    $EncryptedVsan = $VsanVcClusterConfig.VsanClusterGetConfig($VsanCluster.ExtensionData.MoRef).DataEncryptionConfig
 
    # If vSAN is enabled and it is Encrypted
    If($VsanCluster.vSanEnabled -And $EncryptedVsan.EncryptionEnabled){

        $EncryptedVsan.KmsProviderId.Id 
    }
}

Function Set-VsanEncryptionDiskWiping {
    <#
    .SYNOPSIS
       This function will update the Disk Wiping option in vSAN Encryption 
 
    .DESCRIPTION
       This function will update the Disk Wiping option in vSAN Encryption 
 
    .PARAMETER Cluster
       Specifies the Cluster set the Disk Wiping Setting on
 
    .PARAMETER DiskWiping
       Use to set the Disk Wiping setting for vSAN Encryption
      
    .EXAMPLE
       C:\PS>Set-VsanEncryptionDiskWiping -Cluster "ClusterName" -DiskWiping $true

    .EXAMPLE 
       C:\PS>Set-VsanEncryptionDiskWiping -Cluster "ClusterName" -DiskWiping $false
 
    #>
 
    # Set our Parameters
    [CmdletBinding()]Param(
    [Parameter(Mandatory = $True)][String]$Cluster,
    [Parameter(Mandatory = $True)][Boolean]$DiskWiping
    )
 
    # Get the Cluster 
    $VsanCluster = Get-Cluster -Name $Cluster

    # Get the vSAN Cluster Configuration View
    $VsanVcClusterConfig = Get-VsanView -Id "VsanVcClusterConfigSystem-vsan-cluster-config-system"
 
    # Get Encryption State
    $EncryptedVsan = $VsanVcClusterConfig.VsanClusterGetConfig($VsanCluster.ExtensionData.MoRef).DataEncryptionConfig
 
    # If vSAN is enabled and it is Encrypted
    If($VsanCluster.vSanEnabled -And $EncryptedVsan.EncryptionEnabled){

        # Determine Rekey Type for messaging
        Switch ($DiskWiping) {
            $true   { $DiskWipingSetting = "enabled" }
            default { $DiskWipingSetting = "disabled" }
        }

        # Check to see the current Disk Wiping value
        If ($DiskWiping -eq $EncryptedVsan.EraseDisksBeforeUse) {
            Write-Host "Disk Wiping is already $DiskWipingSetting" -ForegroundColor "Green"
            Write-Host "No action necessary" -ForegroundColor "Green"

        } else {

            Write-Host "Disk Wiping is not set to $DiskWipingSetting" -ForegroundColor "Yellow"
            Write-Host "Changing Disk Wiping setting on Cluster $VsanCluster" -ForegroundColor "Blue"

                # Setup the Data Encryption Configuration Specification
                $DataEncryptionConfigSpec = New-Object VMware.Vsan.Views.VsanDataEncryptionConfig
                $DataEncryptionConfigSpec.EncryptionEnabled = $true
                $DataEncryptionConfigSpec.EraseDisksBeforeUse = $DiskWiping

                # Set the Reconfigure Specification to use the Data Encryption Configuration Spec
                $vsanReconfigSpec = New-Object VMware.Vsan.Views.VimVsanReconfigSpec
                $vsanReconfigSpec.DataEncryptionConfig = $DataEncryptionConfigSpec
                
                # Execute the task of changing the KMS Cluster Profile Being Used
                $VsanVcClusterConfig.VsanClusterReconfig($VsanCluster.ExtensionData.MoRef,$vsanReconfigSpec)

            }
        }
}

Function Get-VsanEncryptionDiskWiping {
    <#
    .SYNOPSIS
       This function will retrieve the Disk Wiping option setting in vSAN Encryption 
 
    .DESCRIPTION
       This function will retrieve the Disk Wiping option setting in vSAN Encryption 
 
    .PARAMETER Cluster
       Specifies the Cluster set the Disk Wiping Setting on
      
    .EXAMPLE
       C:\PS>Get-VsanEncryptionDiskWiping -Cluster "ClusterName"
 
    #>
 
    # Set our Parameters
    [CmdletBinding()]Param([Parameter(Mandatory = $True)][String]$Cluster)
 
    # Get the Cluster 
    $VsanCluster = Get-Cluster -Name $Cluster

    # Get the vSAN Cluster Configuration View
    $VsanVcClusterConfig = Get-VsanView -Id "VsanVcClusterConfigSystem-vsan-cluster-config-system"
 
    # Get Encryption State
    $EncryptedVsan = $VsanVcClusterConfig.VsanClusterGetConfig($VsanCluster.ExtensionData.MoRef).DataEncryptionConfig
 
    # If vSAN is enabled and it is Encrypted
    If($VsanCluster.vSanEnabled -And $EncryptedVsan.EncryptionEnabled){

        # Change the setting
        $EncryptedVsan.EraseDisksBeforeUse
    }
}



# Export Function for vSAN Rekeying
Export-ModuleMember -Function Invoke-VsanEncryptionRekey
Export-ModuleMember -Function Set-VsanEncryptionKms
Export-ModuleMember -Function Get-VsanEncryptionKms
Export-ModuleMember -Function Set-VsanEncryptionDiskWiping
Export-ModuleMember -Function Get-VsanEncryptionDiskWiping