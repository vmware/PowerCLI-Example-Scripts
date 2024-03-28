<#
# © 2024 Broadcom.  All Rights Reserved.  Broadcom.  The term "Broadcom" refers to
# Broadcom Inc. and/or its subsidiaries.
#>

<#
.SYNOPSIS

This script configures the ESXi host for AI workloads

.DESCRIPTION

This script configures the ESXi host for AI workloads which includes installing the
NVIDIA AI Enterprise vGPU driver and NVIDIA GPU Management Daemon on the ESXi hosts.
vLCM is used for that purpose.

The script changes the default graphics type of the GPU devices to Shared Direct. The Xorg
service is then restarted. Finally, the vLCM is used to install the NVIDIA GPU driver and
management daemon.

.NOTES

Prerequisites:
 - VI workload domain (vCenter server instance)
 - ESXi hosts with GPUs

"Global parameters", "Workload domain parameters", "GPU parameters" should be updated to
reflect the environment they are run in. This may require altering the spec creation script.

#>

$ErrorActionPreference = 'Stop'

# --------------------------------------------------------------------------------------------------------------------------
# Global parameters
# --------------------------------------------------------------------------------------------------------------------------

# Name of the workload domain - used as a prefix for nested inventory items
$domainName = 'sfo-w01'

$domain = 'vrack.vsphere.local'

# --------------------------------------------------------------------------------------------------------------------------
# Workload domain parameters - stripped down version of $domainSpec from 01-deploy-vcf-workload-domain.ps1

$domainSpec = @{
   VCenterSpec = @{
      RootPassword = "VMware123!"
      NetworkDetailsSpec = @{
         DnsName = "$DomainName-vc01.$domain"
      }
   }
   ComputeSpec = @{
      ClusterSpecs = @(
         @{
            Name = "$DomainName-cl01"
         }
      )
   }
}
# --------------------------------------------------------------------------------------------------------------------------
# GPU parameters

$nvidiaDriverLocation = "http://NVIDIA-VGPU-DRIVER-LOCATION/"
$gpuParameters = @{
   EsxiImageName = "8.0 U2b - 23305546"
   NVIDIA = @(
      @{
         Location = "$nvidiaDriverLocation/NVD-AIE-800_550.54.16-1OEM.800.1.0.20613240_23471877.zip"
         Name = "NVIDIA AI Enterprise vGPU driver for VMWare ESX-8.0.0"
         Version = "550.54.16"
         Description = 'NVIDIA AI Enterprise vGPU driver for VMWare ESX-8.0.0'
      },
      @{
         Location = "$nvidiaDriverLocation/nvd-gpu-mgmt-daemon_550.54.16-0.0.0000_23475823.zip"
         Name = "NVIDIA GPU monitoring and management daemon"
         Version = "550.54.16 - Build 0000"
         Description = "NVIDIA GPU monitoring and management daemon"
      }
   )
   GraphicsType = 'sharedDirect'
   HostDefaultGraphicsType = 'sharedDirect'
   SharedPassthruAssignmentPolicy = 'performance'
}
# --------------------------------------------------------------------------------------------------------------------------

# Connect to the VC of the workload domain
$vcConn = Connect-VIServer `
   -Server $domainSpec.VCenterSpec.NetworkDetailsSpec.DnsName `
   -User 'administrator@vsphere.local' `
   -Password $domainSpec.VCenterSpec.RootPassword

$esxHosts = $domainSpec.ComputeSpec.ClusterSpecs | ForEach-Object { Get-VMHost -Location $_.Name }

# Preparing the GPU Device for the vGPU Driver
$esxHosts | ForEach-Object {
   $graphicsManager = Get-View -Id $_.ExtensionData.ConfigManager.GraphicsManager

   # Preparing the GPU Device for the vGPU Driver
   # change the default graphics type to Shared Direct
   $_.ExtensionData.Config.GraphicsInfo | `
      Where-Object { $_.GraphicsType -ne $gpuParameters.GraphicsType } | `
      ForEach-Object {
         $config = New-Object VMware.Vim.HostGraphicsConfig
         $config.DeviceType = New-Object VMware.Vim.HostGraphicsConfigDeviceType[] (1)
         $config.DeviceType[0] = New-Object VMware.Vim.HostGraphicsConfigDeviceType
         $config.DeviceType[0].DeviceId = $_.PciId
         $config.DeviceType[0].GraphicsType = $gpuParameters.GraphicsType
         $config.HostDefaultGraphicsType = $gpuParameters.HostDefaultGraphicsType
         $config.SharedPassthruAssignmentPolicy = $gpuParameters.SharedPassthruAssignmentPolicy
         $graphicsManager.UpdateGraphicsConfig($config)
      }

   # Restart xorg service
   $_this = Get-View -Id $_.ExtensionData.ConfigManager.ServiceSystem
   $_this.RestartService('xorg')
}

$uploadTasksId = $gpuParameters.NVIDIA | ForEach-Object {
   # Upload the driver to vLCM
   $SettingsDepotsOfflineCreateSpec = Initialize-SettingsDepotsOfflineCreateSpec `
      -SourceType "PULL" `
      -Location $_.Location `
      -Description $_.Description

   Invoke-CreateDepotsOfflineAsync -SettingsDepotsOfflineCreateSpec $SettingsDepotsOfflineCreateSpec
}

$uploadTasks = $uploadTasksId | ForEach-Object { Invoke-GetTask -task $_ }

Write-Progress -Id 0 "Uploading NVIDIA vGPU driver into vLCM"
$inProgress = $true
while ($inProgress) {
   Write-Verbose "Waiting for NVIDIA driver upload into vLCM"
   $uploadTasks | ConvertTo-Json -Depth 5 | Write-Verbose

   $subprocess = ''
   $completed = 0
   $total = 0

   $inProgress = $false

   foreach ($t in $uploadTasks) {
      if ($t -and $t.status -ne 'SUCCEEDED' -and $t.status -ne 'FAILED') {
         $inProgress = $true

         if ($t.progress) {
            if ($t.progress.message -and `
               $t.progress.message.default_message) {
               if ($subprocess.Length -gt 0) {
                  $subprocess += ','
               }
               $subprocess += $t.progress.message.default_message
            }
            $completed += $t.progress.completed
            $total += $t.progress.total
         }
      }
   }

   if ($total -eq 0) { $total = 100 }

   Write-Progress -Id 0 "Uploading NVIDIA vGPU driver into vLCM" -Status $subprocess -PercentComplete (($completed * 100) / $total)

   Start-Sleep -Seconds 1
   $uploadTasks = $uploadTasksId | ForEach-Object { Invoke-GetTask -task $_ }
}
Write-Progress -Id 0 "Uploading NVIDIA vGPU driver into vLCM" -Completed

# 3 vSphere LifeCycle Management Configuration
$esxiBaseImage = Get-LcmImage `
   -Type BaseImage `
   -Version $gpuParameters.EsxiImageName
$allComponents = Get-LcmImage -Type Component
$components = $gpuParameters.NVIDIA | ForEach-Object {
   $nvd = $_
   $allComponents | `
      Where-Object {
         $_.Name -eq $nvd.Name -and `
         $_.Version -eq $nvd.Version
      }
}

if (($components -isnot [array]) -or ($components.Length -ne $gpuParameters.NVIDIA.Length)) {
   throw "Not all Nvidia components found"
}

$domainSpec.ComputeSpec.ClusterSpecs | ForEach-Object {
   $cluster = Get-Cluster -Name $_.Name
   $cluster = $cluster | Set-Cluster -BaseImage $esxiBaseImage -Component $components -Confirm:$false
   $cluster = $cluster | Set-Cluster -AcceptEULA -Remediate -Confirm:$false
}


Disconnect-VIServer $vcConn