# Script Module : VMware.VMEncryption
# Version       : 1.2

# Copyright © 2016 VMware, Inc. All Rights Reserved.

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


New-VIProperty -Name AESNIStatus -ObjectType VMHost -Value {
    Param ($VMHost)
    $FeatureCap = $VMHost.ExtensionData.Config.FeatureCapability
    foreach ($Feature in $FeatureCap) {
       if ($Feature.FeatureName -eq "cpuid.AES") {
          ($Feature.Value -eq "1")
       }
    }
} -BasedOnExtensionProperty 'Config.FeatureCapability' -Force | Out-Null

New-VIProperty -Name CryptoSafeSupported -ObjectType VMHost -Value {
    Param ($VMHost)
       $VMHost.ExtensionData.Runtime.CryptoState -ne $null
} -BasedOnExtensionProperty 'Runtime.CryptoState' -Force

New-VIProperty -Name CryptoSafe -ObjectType VMHost -Value {
    Param ($VMHost)
        $VMHost.ExtensionData.Runtime.CryptoState -eq "safe"
} -BasedOnExtensionProperty 'Runtime.CryptoState' -Force

New-VIProperty -Name Encrypted -ObjectType VirtualMachine -Value {
    Param ($VM)
       $VM.ExtensionData.Config.KeyId -ne $null
} -BasedOnExtensionProperty 'Config.KeyId' -Force | Out-Null

New-VIProperty -Name EncryptionKeyId -ObjectType VirtualMachine -Value {
    Param ($VM)
    if ($VM.Encrypted) {
      $VM.ExtensionData.Config.KeyId
    }
} -BasedOnExtensionProperty 'Config.KeyId' -Force | Out-Null

New-VIProperty -Name Locked -ObjectType VirtualMachine -Value  {
    Param ($VM)
    if ($vm.ExtensionData.Runtime.CryptoState) {
        $vm.ExtensionData.Runtime.CryptoState -eq "locked"
    }
    else {
        ($vm.extensiondata.Runtime.ConnectionState -eq "invalid") -and ($vm.extensiondata.Config.KeyId)
    }
} -BasedOnExtensionProperty 'Runtime.CryptoState', 'Runtime.ConnectionState','Config.KeyId' -Force | Out-Null

New-VIProperty -Name vMotionEncryption -ObjectType VirtualMachine -Value {
    Param ($VM)
       $VM.ExtensionData.Config.MigrateEncryption
} -BasedOnExtensionProperty 'Config.MigrateEncryption' -Force | Out-Null

New-VIProperty -Name KMSserver -ObjectType VirtualMachine -Value {
    Param ($VM)
    if ($VM.Encrypted) {
      $VM.EncryptionKeyId.ProviderId.Id
    }
} -BasedOnExtensionProperty 'Config.KeyId' -Force | Out-Null

New-VIProperty -Name Encrypted -ObjectType HardDisk -Value {
    Param ($hardDisk)
    $hardDisk.ExtensionData.Backing.KeyId -ne $null
} -BasedOnExtensionProperty 'Backing.KeyId' -Force | Out-Null

New-VIProperty -Name EncryptionKeyId -ObjectType HardDisk -Value {
    Param ($Disk)
    if ($Disk.Encrypted) {
      $Disk.ExtensionData.Backing.KeyId
    }
} -BasedOnExtensionProperty 'Backing.KeyId' -Force | Out-Null

New-VIProperty -Name KMSserver -ObjectType VMHost -Value {
    Param ($VMHost)
    if ($VMHost.CryptoSafe) {
        $VMHost.ExtensionData.Runtime.CryptoKeyId.ProviderId.Id
    }
} -BasedOnExtensionProperty 'Runtime.CryptoKeyId.ProviderId.Id' -Force | Out-Null

Function Enable-VMHostCryptoSafe {
    <#
    .SYNOPSIS
       This cmdlet enables the VMHost's CryptoSate to safe.

    .DESCRIPTION
       This cmdlet enables the VMHost's CryptoSate to safe.

    .PARAMETER VMHost
       Specifies the VMHost you want to enable.

    .PARAMETER KMSClusterId
       Specifies the KMS cluster ID which you want to use to generate the encrytion key.

    .EXAMPLE
       C:\PS>$VMHost = Get-VMHost -name $VMHostName
       C:\PS>Enable-VMHostCryptoSafe -VMHost $VMHost

       Enables the specified VMHost's CryptoSate to safe.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost] $VMHost,

        [Parameter(Mandatory=$False)]
        [String] $KMSClusterId
    )

    Process {
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter

       if (!$VMHost.CryptoSafeSupported) {
          Write-Error "The VMHost: $VMHost does not support CryptoSafe!`n"
          return
       }

       if ($VMHost.CryptoSafe) {
          Write-Error "The VMHost: $VMHost CryptoSafe already enabled!`n"
          return
       }

       # Generate key from the specified KMS cluster
       try {
          $KeyResult = NewEncryptionKey -KMSClusterId $KMSClusterId
       } catch {
          Throw "Key generation failed, make sure the KMS Cluster exists!`n"
       }

       $VMHostView = Get-View $VMHost
       $VMHostView.ConfigureCryptoKey($KeyResult.KeyId)
    }
}

Function Set-VMHostCryptoKey {
    <#
    .SYNOPSIS
       This cmdlet changes the VMHost CryptoKey.

    .DESCRIPTION
       This cmdlet changes the VMHost CryptoKey if VMHost is already in Crypto safe state.

    .PARAMETER VMHost
       Specifies the VMHost whose CryptoKey you want to update.

    .PARAMETER KMSClusterId
       Specifies the KMS cluster ID which you want to use to generate the encryption key.

    .EXAMPLE
       C:\PS>$VMHost = Get-VMHost -Name $VMHostName
       C:\PS>Set-VMHostCryptoKey -VMHost $VMHost

       Changes the VMHost CryptoKey to a new CryptoKey.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost] $VMHost,

        [Parameter(Mandatory=$False)]
        [String] $KMSClusterId
    )

    Begin {
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter
    }

    Process {
       if (!$VMHost.CryptoSafeSupported) {
          Write-Error "The VMHost: $VMHost does not support CryptoSafe!`n"
          return
       }

       if (!$VMHost.CryptoSafe) {
          Write-Error "The VMHost: $VMHost has not enabled the CrytoSate to safe!"
          return
       }

       $VMHostView = Get-View $VMHost
       $OldKey = $VMHostView.Runtime.CryptoKeyId

       # Generate key from the specified KMSCluster
       try {
          $KeyResult = NewEncryptionKey -KMSClusterId $KMSClusterId
       } catch {
          Throw "Key generation failed, make sure the KMS Cluster exists!`n"
       }

       try {
          $VMHostView.ConfigureCryptoKey($KeyResult.KeyId)
          Write-Verbose "Change Crypto Key on VMHost: $VMHost succeeded!`n"
       } catch {
          Write-Error "Change Crypto Key on VMHost: $VMHost failed.$_!`n"
          return
       }

       # Remove the old host key
       Write-Verbose "Removing the old hostKey: $($OldKey.KeyId) on $VMHost...`n"
       $VMHostCM = Get-View $VMHostView.ConfigManager.CryptoManager
       $VMHostCM.RemoveKeys($OldKey, $true)
    }
}

Function Set-vMotionEncryptionConfig {
    <#
    .SYNOPSIS
       This cmdlet sets the vMotionEncryption property of a VM.

    .DESCRIPTION
       Use this function to set the vMotionEncryption settings for a VM.
       The 'Encryption' parameter is set up with Tab-Complete for the available
       options.

    .PARAMETER VM
       Specifies the VM you want to set the vMotionEncryption property.

    .PARAMETER Encryption
       Specifies the value you want to set to the vMotionEncryption property.
       The Encryption options are: disabled, opportunistic, and required.

    .EXAMPLE
       PS C:\> Get-VM | Set-vMotionEncryptionConfig -Encryption opportunistic

       Sets the vMotionEncryption of all the VMs

    .NOTES
       Author                                    : Brian Graf, Carrie Yang.
       Author email                              : grafb@vmware.com, yangm@vmware.com
    #>

    [CmdLetBinding()]

    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,

        [Parameter(Mandatory=$True)]
        [ValidateSet("disabled", "opportunistic", "required")]
        [String]$Encryption
    )

    process{
        if ($VM.vMotionEncryption -eq $Encryption) {
           Write-Warning "The encrypted vMotion state is already $Encrypted, no need to change it."
           return
        }

        if ($VM.Encrypted) {
           Write-Error "Cannot change encrypted vMotion state for an encrypted VM."
           return
        }

        $VMView = $VM | get-view
        $Config = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Config.MigrateEncryption = New-Object VMware.Vim.VirtualMachineConfigSpecEncryptedVMotionModes
        $Config.MigrateEncryption = $Encryption

        $VMView.ReconfigVM($config)

        $VM.ExtensionData.UpdateViewData()
        $VM.vMotionEncryption
    }
}

Function Enable-VMEncryption {
    <#
    .SYNOPSIS
       This cmdlet encrypts the specified VM.

    .DESCRIPTION
       This cmdlet encrypts the specified VM.

    .PARAMETER SkipHardDisks
       If specified, skips the encryption of the hard disks of the specified VM.

    .PARAMETER VM
       Specifies the VM you want to encrypt.

    .PARAMETER Policy
       Specifies the encryption policy you want to use.

    .PARAMETER KMSClusterId
       Specifies the KMS clusterId you want to use to generate new key for encryption.

    .EXAMPLE
       C:\PS>Get-VM -Name win2012|Enable-VMEncryption

       Encrypts the whole VM with default encryption policy.

    .EXAMPLE
       C:\PS>$SP = Get-SpbmStoragePolicy -name "EncryptionPol"
       C:\PS>Get-VM -Name win2012 |Enable-VMEncryption -Policy $SP -SkipHardDisks

       Encrypts the VM Home with the encryption policy 'EncryptionPol' and skips hard disks encryption.

    .NOTES
       This cmdlet assumes there already is KMS defined in vCenter Server.
       If VM Home is already encrypted, the cmdlet quits.
       If VM Home is not encrypted, encrypt VM Home if SkipHardDisks specified. Otherwise encrypt the VM Home and VM-attached disks.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM,

        [Parameter(Mandatory=$False,ValueFromPipeline=$False,ValueFromPipelinebyPropertyName=$False)]
        [VMware.VimAutomation.Storage.Types.V1.Spbm.SpbmStoragePolicy] $Policy,

        [Parameter(Mandatory=$False,ValueFromPipeline=$False,ValueFromPipelinebyPropertyName=$False)]
        [String] $KMSClusterId,

        [Parameter(Mandatory=$False)]
        [switch]$SkipHardDisks=$False
    )

    Begin {
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter
    }

    Process {
        # VM Home is already encrypted
        if ($VM.Encrypted) {
           $ErrMsg = "VM $VM is already encrypted, please use: "+
                     "Enable-VMDiskEncryption if you want to "+
                     "encrypt disks which not encrypted yet!`n"
           Write-Error $ErrMsg
           return
        }

        Write-Verbose "Checking if the VMHost supports CryptoSafe...`n"
        $VMhost = $VM|Get-VMHost
        if (!$VMHost.CryptoSafeSupported) {
           Write-Error "The VMHost: $VMHost does not support CryptoSafe.`n"
           return
        }

        Write-Verbose "Checking if $VM has no snapshots...`n"
        if ($VM|Get-Snapshot) {
           Write-Error "$VM has snapshots, please remove all snapshots and try again!`n"
           return
        }

        Write-Verbose "Checking if $VM powered off...`n"
        if ($VM.PowerState -ne "PoweredOff") {
           $ErrMsg = "The VM can only be encrypted when powered off, "+
                     "but the current power state of $VM is $($VM.PowerState)!`n"
           Write-Error $ErrMsg
           return
        }

        $PolicyToBeUsed = $null
        $BuiltInEncPolicy = Get-SpbmStoragePolicy -Name "VM Encryption Policy"

        if ($Policy) {
           # Known issue: If the provided policy is created/cloned from
           # the default "VM Encryption Policy",
           # Or When creating the policy you didn't select 'Custom',
           # there will be null-valued Exception.
           Write-Verbose "Checking if the provided policy: $Policy is an encryption policy`n"
           if (($Policy.Name -ne "VM Encryption Policy") -and !$Policy.CommonRule.Capability.Category.Contains("ENCRYPTION")) {
              Write-Error "The policy $Policy is not an encryption policy, exit!"
              return
           }
           $PolicyToBeUsed = $Policy
        } else {
           Write-Verbose "No storage policy specified, try to use the built-in policy.`n"
           if ($BuiltInEncPolicy) {
              $PolicyToBeUsed = $BuiltInEncPolicy
           } else {
              Throw "The built-in policy does not exist, please use: New-SpbmStoragePolicy to create one first!`n"
           }
        }

        # Encrypt the VM disks if SkipHardDisk not specified
        if (!$SkipHardDisks) {
           $Disks = $VM|Get-HardDisk
        }

        $VMView = Get-View $VM
        $ProfileSpec = New-Object VMware.Vim.VirtualMachineDefinedProfileSpec
        $ProfileSpec.ProfileId = $PolicyToBeUsed.Id
        $VMCfgSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $VMCfgSpec.VmProfile = $ProfileSpec

        if ($KMSClusterId) {
           # Generate a new key from KMS
           try {
              $KeyResult = NewEncryptionKey -KMSClusterId $KMSClusterId
           } catch {
              Throw "Key generation failed, make sure the specified KMS Cluster exists!`n"
           }

           $CryptoKeyId = $KeyResult.KeyId
           $CryptoSpec = New-Object VMware.Vim.CryptoSpecEncrypt
           $CryptoSpec.CryptoKeyId = $CryptoKeyId
           $VMCfgSpec.Crypto = $CryptoSpec
        }

        $DeviceChanges = @()
        foreach ($Disk in $Disks) {
           Write-Verbose "Attaching policy: $PolicyToBeUsed to $Disk`n"
           $DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
           $BackingSpec = New-Object VMware.Vim.VirtualDeviceConfigSpecBackingSpec
           $DeviceChange.operation = "edit"
           $DeviceChange.device = $Disk.extensiondata
           $DeviceChange.Profile = $ProfileSpec
           $BackingSpec.Crypto = $CryptoSpec
           $DeviceChange.Backing = $BackingSpec
           $DeviceChanges += $deviceChange
        }

        if ($Devicechanges) {
           $VMCfgSpec.deviceChange = $Devicechanges
        }

        return $VMView.ReconfigVM_Task($VMCfgSpec)
     }
}

Function Enable-VMDiskEncryption {
    <#
    .SYNOPSIS
       This cmdlet encrypts the specified hard disks.

    .DESCRIPTION
       This cmdlet encrypts the specified hard disks.

    .PARAMETER VM
       Specifies the VM whose hard disks you want to encrypt.

    .PARAMETER Policy
       Specifies the encryption policy you want to use.

    .PARAMETER HardDisk
       Specifies the hard disks you want to encrypt.

    .PARAMETER KMSClusterId
       Specifies the KMS clusterId you want to use to generate new key for encryption.

    .EXAMPLE
       C:\PS>$VM = Get-VM -Name win2012
       C:\PS>$VMDisks= $VM|Get-Harddisk|Select -last 2
       C:\PS>Enable-VMDiskEncryption -VM $VM -$HardDisk $VMDisks

       Encrypts the VM disks with the default encryption policy and use the VM encryption key.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM,

        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.VirtualDevice.HardDisk[]] $HardDisk,

        [Parameter(Mandatory=$False)]
        [VMware.VimAutomation.Storage.Types.V1.Spbm.SpbmStoragePolicy] $Policy,

        [Parameter(Mandatory=$False)]
        [String] $KMSClusterId
    )

    Begin {
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter
    }

    Process {
       Write-Verbose "Checking if $VM is encrypted..."
       if (!$VM.Encrypted) {
          Write-Error "$VM is not encrypted, please use:Enable-VMEncryption to encrypt the VM.`n"
          return
       }

       # Validate the hard disks
       Write-Verbose "Checking the hard disks...`n"
       ConfirmHardDiskIsValid -VM $VM -HardDisk $HardDisk

       Write-Verbose "Checking if $VM has no snapshots..."
       if ($VM|Get-Snapshot) {
          Write-Error "$VM has snapshots, please remove all snapshots!`n"
          return
       }

       Write-Verbose "Checking if $VM is powered off..."
       if ($VM.powerstate -ne "PoweredOff") {
          $ErrMsg = "The VM can only be ecrypted when powered off, "+
                    "but the current power state of $VM is $($VM.PowerState)!`n"
          Write-Error $ErrMsg
          return
       }

       $PolicyToBeUsed = $null

       if ($Policy) {
          # Known issue: If the provided policy is created/cloned from
          # the default "VM Encryption Policy",
          # Or When creating the policy you didn't select 'Custom',
          # there will be null-valued Exception.
          Write-Verbose "Checking if the provided policy: $Policy is an encryption policy`n"
          if (($Policy.Name -ne "VM Encryption Policy") -and !$Policy.CommonRule.Capability.Category.Contains("ENCRYPTION")) {
             Throw "The policy $Policy is not an encryption policy, exit!"
          }
          $PolicyToBeUsed = $Policy
       } else {
          Write-Verbose "No storage policy specified, try to use the VM Home policy.`n"
          $PolicyToBeUsed = (Get-SpbmEntityConfiguration -VM $VM).StoragePolicy
          if (!$PolicyToBeUsed) {
             Write-Warning "The VM Home policy is not available, try to use the built-in policy.`n"
             $BuiltInEncPolicy = Get-SpbmStoragePolicy -Name "VM Encryption Policy"
             if ($BuiltInEncPolicy) {
                $PolicyToBeUsed = $BuiltInEncPolicy
             } else {
                Throw "The built-in policy does not exist, please use: New-SpbmStoragePolicy to create one first!`n"
             }
          }
       }

       # Specify the key used to encrypt disk
       if ($KMSClusterId) {
          # Generate a new key from KMS
          try {
             $KeyResult = NewEncryptionKey -KMSClusterId $KMSClusterId
          } catch {
             Throw "Key generation failed, make sure the KMS Cluster exists!`n"
          }

          $CryptoKeyId = $KeyResult.KeyId
          $CryptoSpec = New-Object VMware.Vim.CryptoSpecEncrypt
          $CryptoSpec.CryptoKeyId = $CryptoKeyId
       }

       Write-Verbose "Encrypting the hard disks: $HardDisk...`n"

       $VMView = Get-View $VM
       $VMCfgSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
       $ProfileSpec = New-Object VMware.Vim.VirtualMachineDefinedProfileSpec
       $ProfileSpec.ProfileId = $PolicyToBeUsed.Id

       $DeviceChanges = @()

       foreach ($Disk in $HardDisk) {
          Write-Verbose "Attaching policy: $PolicyToBeUsed to $Disk`n"
          $DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
          $BackingSpec = New-Object VMware.Vim.VirtualDeviceConfigSpecBackingSpec
          $DeviceChange.operation = "edit"
          $DeviceChange.device = $Disk.extensiondata
          $DeviceChange.Profile = $ProfileSpec
          $BackingSpec.Crypto = $CryptoSpec
          $DeviceChange.Backing = $BackingSpec
          $DeviceChanges += $DeviceChange
       }

       if ($DeviceChanges) {
          $VMCfgSpec.deviceChange = $DeviceChanges
       }

       return $VMView.ReconfigVM_Task($VMCfgSpec)
    }
}

Function Disable-VMEncryption {
    <#
    .SYNOPSIS
       This cmdlet decrypts the specified VM.

    .DESCRIPTION
       This cmdlet decrypts the specified VM.

    .PARAMETER VM
       Specifies the VM you want to decrypt.

    .EXAMPLE
       C:\PS>Get-VM -Name win2012 | Disable-VMEncryption

       Decrypts the VM Home and all encrypted disks.

    .EXAMPLE
       C:\PS>$VM = Get-VM -Name win2012
       C:\PS>Disable-VMEncryption -VM $VM

       Decrypts the whole VM, including the encrypted disks.

    .NOTES
       If the VM is not encrypted, the cmdlet quits.

    .NOTES
       Author                                    : Carrie Yang.
       Author email                              : yangm@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM
    )

    Begin {
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter
    }

    Process {
        Write-Verbose "Checking if $VM is encrypted..."
        if (!$VM.Encrypted) {
           Write-Error "$VM is not encrypted.`n"
           return
        }

        Write-Verbose "Checking if $VM has no snapshots..."
        if ($VM|Get-Snapshot) {
           Write-Error "$VM has snapshots, it can not be decrypted!`n"
           return
        }

        Write-Verbose "Checking if $VM is powered off..."
        if ($VM.powerstate -ne "PoweredOff") {
           $ErrMsg = "The VM can only be decrypted when powered off, "+
                     "but the current power state of $VM is $($VM.PowerState)!`n"
           Write-Error $ErrMsg
           return
        }

        $VMCfgSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Profile = New-Object VMware.Vim.VirtualMachineEmptyProfileSpec
        $DecryptCrypto = New-Object VMware.Vim.CryptoSpecDecrypt
        $DisksToDecrypt = $VM|Get-HardDisk|Where {$_.Encrypted}

        $VMCfgSpec.VmProfile = $Profile
        $VMCfgSpec.Crypto = $DecryptCrypto

        $DeviceChanges = @()
        foreach ($Disk in $DisksToDecrypt) {
           $DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
           $DeviceChange.operation = "edit"
           $DeviceChange.device = $Disk.extensiondata
           $DeviceChange.Profile = $Profile
           $DeviceChange.Backing = New-Object VMware.Vim.VirtualDeviceConfigSpecBackingSpec
           $DeviceChange.Backing.Crypto = $DecryptCrypto
           $DeviceChanges += $DeviceChange
        }

        if ($Devicechanges) {
           $VMCfgSpec.deviceChange = $Devicechanges
        }

        return (Get-View $VM).ReconfigVM_Task($VMCfgSpec)
    }
}

Function Disable-VMDiskEncryption {
    <#
    .SYNOPSIS
       This cmdlet decrypts the specified hard disks in a given VM.

    .DESCRIPTION
       This cmdlet decrypts the specified hard disks in a given VM.

    .PARAMETER VM
       Specifies the VM which the hard disks belong to.

    .PARAMETER HardDisk
       Specifies the hard disks you want to decrypt.

    .EXAMPLE
       C:\PS>$VM = Get-VM -Name win2012
       C:\PS>$HardDisk = $VM|Get-HardDisk|select -last 1
       C:\PS>Disable-VMDiskEncryption -VM $VM -HardDisk $HardDisk

       Decrypts the last hard disk in the VM.

    .NOTES
       If the VM is not encrypted, the cmdlet quits.

    .NOTES
       Author                                    : Carrie Yang.
       Author email                              : yangm@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM,

        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.VirtualDevice.HardDisk[]] $HardDisk
    )

    Begin {
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter
    }

    Process {
        Write-Verbose "Checking if $VM is encrypted..."
        if (!$VM.Encrypted) {
           Write-Error "$VM is not encrypted.`n"
           return
        }

        # Validate the hard disks
        Write-Verbose "Checking the hard disks...`n"
        ConfirmHardDiskIsValid -VM $VM -HardDisk $HardDisk

        $DisksToDecrypt = $HardDisk |Where {$_.Encrypted}

        if ($DisksToDecrypt.Length -eq 0) {
           Write-Error "The provided disks are not encrypted.`n"
           return
        }

        Write-Verbose "Checking if $VM has no snapshots..."
        if ($VM|Get-Snapshot) {
           Write-Error "$VM has snapshots, it can not be decrypted!`n"
           return
        }

        Write-Verbose "Checking if $VM is powered off..."
        if ($VM.powerstate -ne "PoweredOff") {
           $ErrMsg = "The VM can only be decrypted when powered off, "+
                     "but the current power state of $VM is $($VM.PowerState)!`n"
           Write-Error $ErrMsg
           return
        }

        $VMCfgSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $Profile = New-Object VMware.Vim.VirtualMachineEmptyProfileSpec
        $DecryptCrypto = New-Object VMware.Vim.CryptoSpecDecrypt


        $DeviceChanges = @()
        foreach ($Disk in $DisksToDecrypt) {
           $DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
           $DeviceChange.operation = "edit"
           $DeviceChange.device = $Disk.extensiondata
           $DeviceChange.Profile = $Profile
           $DeviceChange.Backing = New-Object VMware.Vim.VirtualDeviceConfigSpecBackingSpec
           $DeviceChange.Backing.Crypto = $DecryptCrypto
           $DeviceChanges += $DeviceChange
        }

        $VMCfgSpec.deviceChange = $DeviceChanges

        return (Get-View $VM).ReconfigVM_Task($VMCfgSpec)
    }
}

Function Set-VMEncryptionKey {
    <#
    .SYNOPSIS
       This cmdlet sets the encryption key of VM or hard disks.

    .DESCRIPTION
       This cmdlet sets the encryption key of VM or hard disks.

    .PARAMETER VM
       Specifies the VM you want to rekey.

    .PARAMETER KMSClusterId
       Specifies the KMS clusterId you want to use for getting a new key for rekey operation.

    .PARAMETER Deep
       When it's specified, both the key encryption key (KEK) and
       the internal data encryption key (DEK) will be updated.
       This is implemented through a full copy; It's a slow operation that
       must be performed while the virtual machine is powered off.
       A shallow key change will only update the KEK and the operation can be performed
       while the virtual machine is running.

    .PARAMETER SkipHardDisks
       Skip updating the hard disk keys.

    .EXAMPLE
       C:\PS>Get-VM -Name win2012 | Set-VMEncryptionKey

       Rekeys the VM win2012 VM Home and all its disks.

    .EXAMPLE
       C:\PS>$VM = Get-VM -Name win2012
       C:\PS>$VM|Set-VMEncryptionKey -SkipHardDisks

       Rekeys the VM Home only.

    .EXAMPLE
       C:\PS>$VM = Get-VM -Name win2012
       C:\PS>$VM|Set-VMEncryptionKey -Deep

       Rekeys the VM Home and all its disks with Deep option.

    .EXAMPLE
       C:\PS>$KMSCluster = Get-KMSCluster | select -last 1
       C:\PS>$VM = Get-VM -Name win2012
       C:\PS>$VM|Set-VMEncryptionKey -KMSClusterId $KMSCluster.Id -Deep

       Deep rekeys the VM Home and all its disks using a new key.
       The key is generated from the KMS whose clusterId is $KMSCluster.Id.

    .NOTES
       This cmdlet assumes there is already a KMS in vCenter Server. If VM is not encrypted, the cmdlet quits.
       You should use Enable-VMEncryption cmdlet to encrypt the VM first.

    .NOTES
       Author                                    : Carrie Yang.
       Author email                              : yangm@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM,

        [Parameter(Mandatory=$False)]
        [String] $KMSClusterId,

        [Parameter(Mandatory=$False)]
        [switch]$Deep = $FALSE,

        [Parameter(Mandatory=$False)]
        [switch]$SkipHardDisks = $False
    )

    Begin {
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter
    }

    Process {
        Write-Verbose "Checking if $VM is encrypted...`n"
        if (!$VM.Encrypted) {
           Write-Error "$VM is not encrypted."
           return
        }

        Write-Verbose "Checking if $VM has no snapshots...`n"
        if ($VM|Get-Snapshot) {
           Write-Error "$VM has snapshot, please remove all snapshots and try again!`n"
           return
        }

        if ($Deep) {
           Write-Verbose "Checking if $VM powered off...`n"
           if ($VM.powerstate -ne "PoweredOff") {
              $ErrMsg = "The VM can only be recrypted when powered off, "+
                        "but the current power state of $VM is $($VM.PowerState)!`n"
              Write-Error $ErrMsg
              return
           }
        }

        $VMCfgSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $ProfileSpec = New-Object VMware.Vim.VirtualMachineDefinedProfileSpec
        $CryptoSpec = New-Object VMware.Vim.CryptoSpecShallowRecrypt

        if ($Deep) {
           $CryptoSpec = New-Object VMware.Vim.CryptoSpecDeepRecrypt
           $VMPolicy = (Get-SpbmEntityConfiguration -VM $VM).StoragePolicy
           $ProfileSpec.ProfileId = $VMPolicy.Id
           $VMCfgSpec.VmProfile = $ProfileSpec
        }

        # Generate a key from KMS
        try {
           $KeyResult = NewEncryptionKey -KMSClusterId $KMSClusterId
        } catch {
           Throw "Key generation failed, make sure the KMS Cluster exists!`n"
        }
        $CryptoSpec.NewKeyId = $KeyResult.KeyId
        $VMCfgSpec.Crypto = $CryptoSpec

        if (!$SkipHardDisks) {
           $DisksToRecrypt = $VM|Get-HardDisk|Where {$_.Encrypted}

           $DeviceChanges = @()
           foreach ($disk in $DisksToRecrypt) {
              $DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
              $DeviceChange.operation = "edit"
              $DeviceChange.device = $Disk.extensiondata
              if ($Deep) {
                 $DiskProfileSpec = New-Object VMware.Vim.VirtualMachineDefinedProfileSpec
                 $DiskProfileSpec.ProfileId = ($Disk|Get-SpbmEntityConfiguration).StoragePolicy.Id
                 $DeviceChange.Profile = $DiskProfileSpec
              }
              $DeviceChange.Backing = New-Object VMware.Vim.VirtualDeviceConfigSpecBackingSpec
              $DeviceChange.Backing.Crypto = $CryptoSpec
              $DeviceChanges += $DeviceChange
           }

           if ($DeviceChanges.Length -gt 0) {
              $VMCfgSpec.deviceChange = $DeviceChanges
           }
        }

        return (Get-View $VM).ReconfigVM_Task($VMCfgSpec)
    }
}

Function Set-VMDiskEncryptionKey {
    <#
    .SYNOPSIS
       This cmdlet sets the encryption key of the hard disks in the VM.

    .DESCRIPTION
       This cmdlet sets the encryption key of the hard disks in the VM.

    .PARAMETER VM
       Specifies the VM from which you want to rekey its disks.

    .PARAMETER HardDisk
       Specifies the hard disks you want to rekey.

    .PARAMETER KMSClusterId
       Specifies the KMS clusterId you want to use for getting a new key for rekey operation.

    .PARAMETER Deep
       When it's specified, both the key encryption key (KEK) and
       the internal data encryption key (DEK) will be updated.
       This is implemented through a full copy; It's a slow operation that
       must be performed while the virtual machine is powered off.
       A shallow key change will only update the KEK and the operation can be performed
       while the virtual machine is running.

    .EXAMPLE
       C:\PS>$VM = Get-VM -Name win2012
       C:\PS>$HardDisk = $VM|Get-HardDisk|select -last 2
       C:\PS>Set-VMDiskEncryptionKey -VM $VM -HardDisk $HardDisk

       Rekeys the last 2 hard disks in the VM.

    .EXAMPLE
       C:\PS>$VM=Get-VM -Name win2012
       C:\PS>$HardDisk = get-vm $vm|Get-HardDisk|Select -last 2
       C:\PS>Set-VMDiskEncryptionKey -VM $VM -HardDisk $HardDisk -Deep

       Deep rekeys the last 2 hard disks in the VM.

    .EXAMPLE
       C:\PS>$KMSCluster = Get-KMSCluster | select -last 1
       C:\PS>$VM = Get-VM -Name win2012
       C:\PS>$HardDisk = get-vm $vm|Get-HardDisk
       C:\PS>$HardDisk| Set-VMDiskEncryptionKey -VM $VM -KMSClusterId $KMSCluster.Id -Deep

       Deep rekeys all the disks of the $VM  using a new key.
       The key is generated from the KMS whose clusterId is $KMSCluster.Id.

    .NOTES
       This cmdlet assumes there is already a KMS in vCenter Server.
       If VM is not encrypted, the cmdlet quits.
       You should use Enable-VMEncryption cmdlet to encrypt the VM first.

    .NOTES
       Author                                    : Carrie Yang.
       Author email                              : yangm@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM,

        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.VirtualDevice.HardDisk[]] $HardDisk,

        [Parameter(Mandatory=$False)]
        [String] $KMSClusterId,

        [Parameter(Mandatory=$False)]
        [switch]$Deep = $FALSE
    )

    Begin {
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter
    }

    Process {
        Write-Verbose "Checking if $VM is encrypted...`n"
        if (!$VM.Encrypted) {
           Write-Error "$VM is not encrypted."
           return
        }

        # Valid the hard disks
        Write-Verbose "Checking the hard disks...`n"
        ConfirmHardDiskIsValid -VM $VM -HardDisk $HardDisk

        Write-Verbose "Checking if $VM has no snapshots...`n"
        if ($VM|Get-Snapshot) {
           Write-Error "$VM has snapshot, please remove all snapshots and try again!`n"
           return
        }

        if ($Deep) {
           Write-Verbose "Checking if $VM powered off...`n"
           if ($VM.powerstate -ne "PoweredOff") {
              $ErrMsg = "Deep rekey could be done only when VM powered off,"+
                        "but current VM power state is: $($VM.powerstate)!`n"
              Write-Error $ErrMsg
              return
           }
        }

        $VMCfgSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $CryptoSpec = New-Object VMware.Vim.CryptoSpecShallowRecrypt
        if ($Deep) {
           $CryptoSpec = New-Object VMware.Vim.CryptoSpecDeepRecrypt
        }

        # Generate a key from KMS
        try {
           $KeyResult = NewEncryptionKey -KMSClusterId $KMSClusterId
        } catch {
           Throw "Key generation failed, make sure the KMS Cluster exists!`n"
        }
        $CryptoSpec.NewKeyId = $KeyResult.KeyId

        $DeviceChanges = @()
        foreach ($disk in $HardDisk) {
           $DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
           $DeviceChange.operation = "edit"
           $DeviceChange.device = $Disk.extensiondata
           if ($Deep) {
              $ProfileSpec = New-Object VMware.Vim.VirtualMachineDefinedProfileSpec
              $ProfileSpec.ProfileId = ($Disk|Get-SpbmEntityConfiguration).StoragePolicy.Id
              $DeviceChange.Profile = $ProfileSpec
           }
           $DeviceChange.Backing = New-Object VMware.Vim.VirtualDeviceConfigSpecBackingSpec
           $DeviceChange.Backing.Crypto = $CryptoSpec
           $DeviceChanges += $DeviceChange
        }

        $VMCfgSpec.deviceChange = $DeviceChanges

        return (Get-View $VM).ReconfigVM_Task($VMCfgSpec)
    }
}

Function Get-VMEncryptionInfo {
    <#
    .SYNOPSIS
       This cmdlet gets the encryption information of VM and its disks.

    .DESCRIPTION
       This cmdlet gets the encryption information of VM and its disks.

    .PARAMETER VM
       Specifies the VM for which you want to retrieve the encryption information.

    .PARAMETER HardDisk
       Specifies the hard disks for which you want to retrieve the encryption information.

    .EXAMPLE
       C:\PS>Get-VM|Get-VMEncryptionInfo

       Retrieves all VM's encryption information.

    .EXAMPLE
       C:\PS>Get-VMEncryptionInfo -VM $vm -HardDisk $HardDisks

       Retrieves only disks' encryption information.

    .NOTES
       If $HardDisk is specified, then only the encryption information of the disks specified in $HardDisk is obtained.
       Otherwise, all disks' encryption information of the specified VM is returned.

    .NOTES
       Author                                    : Carrie Yang.
       Author email                              : yangm@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM,

        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.VirtualDevice.HardDisk[]] $HardDisk
    )

    Process {
       $DisksInfo = @()

       if ($HardDisk) {
          # Validate the hard disks
          Write-Verbose "Checking the hard disks...`n"
          ConfirmHardDiskIsValid -VM $VM -HardDisk $HardDisk
       }

       foreach ($DK in $HardDisk) {
          $DKInfo = @{}
          $DKInfo.index = $DK.ExtensionData.Key
          $DKInfo.label = $DK.ExtensionData.DeviceInfo.Label
          $diskSize = $DK.ExtensionData.CapacityInKB
          $formattedSize = "{0:N0}" -f $diskSize
          $DKInfo.summary = "$formattedSize KB"
          $DKInfo.profile = ($DK|Get-SpbmEntityConfiguration).StoragePolicy
          $DKInfo.fileName = $DK.Filename
          $DKInfo.uuid = $DK.ExtensionData.Backing.Uuid
          $DKInfo.keyId = $DK.ExtensionData.Backing.KeyId
          $DKInfo.iofilter = $DK.ExtensionData.Iofilter
          $DisksInfo += $DKInfo
       }

       $VMInfo = @{}
       $VMInfo.name = $VM.Name
       $VMInfo.connectState = $VM.ExtensionData.Runtime.ConnectionState
       $VMInfo.profile = ($VM | Get-SpbmEntityConfiguration).StoragePolicy
       $VMInfo.keyId = $VM.ExtensionData.Config.KeyId
       $VMInfo.disks = $DisksInfo

       return $VMInfo
    }
}

Function Get-EntityByCryptoKey {
    <#
    .SYNOPSIS
       This cmdlet gets all the related objects in which it has the key associated.

    .DESCRIPTION
       This cmdlet gets all the related objects in which it has the key associated.

    .PARAMETER KeyId
       Specifies the KeyId string.

    .PARAMETER KMSClusterId
       Specifies the KMSClusterId string.

    .PARAMETER SearchVMHosts
       Specifies whether to search the VMHosts.

    .PARAMETER SearchVMs
       Specifies whether to search the VMs.

    .PARAMETER SearchDisks
       Specifies whether to search the HardDisks.

    .EXAMPLE
       C:\PS>Get-EntityByCryptoKeyId -SearchVMHosts -KeyId 'keyId'

       Gets the VMHosts whose CryptoKeyId's KeyId matches exactly the 'keyId'.

    .EXAMPLE
       C:\PS>Get-EntityByCryptoKeyId -SearchVMs -KMSClusterId 'clusterId'

       Gets the VMs whose CryptoKeyId's ProfileId.Id matches exactly the 'clusterId'.

    .EXAMPLE
       C:\PS>Get-EntityByCryptoKey -SearchVMHosts -SearchVMs -KMSClusterId 'clusterId'

       Gets VMHosts and VMs whose CryptoKeyId's ProviderId.Id matches the 'clusterId'.

    .NOTES
       At least one of the KeyId and KMSClusterId parameters is required.
       If the SearchVMHosts, SearchVMs and SearchDisks all not specified, the cmdlet return $null.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$false,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [String] $keyId,

        [Parameter(Mandatory=$false,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [String] $KMSClusterId,

        [Parameter(Mandatory=$False)]
        [switch] $SearchVMHosts,

        [Parameter(Mandatory=$False)]
        [switch] $SearchVMs,

        [Parameter(Mandatory=$False)]
        [switch] $SearchDisks
    )

    if (!$KeyId -and !$KMSClusterId) {
       Throw "One of the keyId or KMSClusterId must be specified!`n"
    }

    # The returned Items
    $Entities = @{}

    # Find VMHosts
    $CryptoSafeVMHosts = Get-VMHost|Where {$_.CryptoSafe}

    # Quit if no VMHosts found.
    if (!$CryptoSafeVMHosts) {
       Throw "No VMHosts enabled the CrytoState to Safe!`n"
    }

    if ($SearchVMHosts) {
       Write-Verbose "Starting to search VMHosts...`n"
       $VMHostList = $CryptoSafeVMHosts| Where {$_.ExtensionData.Runtime.CryptoKeyId|MatchKeys -KeyId $KeyId -KMSClusterId $KMSClusterId}
       $Entities.VMHostList = $VMHostList
    }

    # Find the VMs which encrypted: Look for both VMHome and Disks
    $VMs = Get-VM|Where {$_.Encrypted}
    if ($SearchVMs) {
       Write-Verbose "Starting to search VMs...`n"
       $VMList = @()
       $Disks = $VMs|Get-HardDisk|Where {$_.Encrypted}
       $VMDiskList = $Disks|Where {$_.EncryptionKeyId|MatchKeys -KeyId $keyId -KMSClusterId $KMSClusterId}

       $VMList += $VMs|Where {$_.EncryptionKeyId|MatchKeys -KeyId $keyId -KMSClusterId $KMSClusterId}
       $VMList += $VMDiskList.Parent
       $VMList = $VMList|sort|Get-Unique
       $Entities.VMList = $VMList
    }

    # Find the Disks
    if ($SearchDisks) {
       Write-Verbose "Starting to search Disks...`n"
       if ($SearchVMs) {
          $DiskList = $VMDiskList
       } else {
          $Disks = $VMs|Get-HardDisk|Where {$_.Encrypted}
          $DiskList = $Disks|Where {$_.EncryptionKeyId|MatchKeys -KeyId $keyId -KMSClusterId $KMSClusterId}
       }

       $Entities.DiskList = $DiskList
    }

    return $Entities
}

Function New-KMServer {
    <#
    .SYNOPSIS
       This cmdlet adds a Key Management Server.

    .DESCRIPTION
       This cmdlet adds a Key Management Server to vCenter Server and verifies it.

    .PARAMETER KMServer
       Specifies the Key Management Server IP address or FQDN.

    .PARAMETER KMSClusterId
       Specifies the ID of the KMS cluster. KMSs with the same cluster ID are in one cluster and provide the same keys for redundancy.

    .PARAMETER UserName
       Specifies user name to authenticate to the KMS.

    .PARAMETER Password
       Specifies password to authenticate to the KMS.

    .PARAMETER Name
       Specifies the name of the KMS.

    .PARAMETER Port
       Specifies the port of the KMS.

    .PARAMETER ProxyServer
       Specifies the address of the proxy server.

    .PARAMETER ProxyPort
       Specifies the port of the proxy server.

    .PARAMETER Protocol
       Specifies the KMS library protocol handler, for example KMS1.

    .EXAMPLE
       C:\PS>New-KMServer -KMServer 1.1.1.1 -KMSClusterId clsName  -UserName "YourKMSUserName" -Password '***' -Name "KMS1"

       Adds the Key Management Server 1.1.1.1 into vCenter with the cluster name 'clsname' and KMS name 'KMS1'.

    .NOTES
       This cmdlet only supports PyKMIP Server. For other KMS vendors, modify the script accordingly.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [String]$KMServer,

        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [String]$KMSClusterId,

        [Parameter(Mandatory=$False)]
        [String] $UserName,

        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [String] $Name,

        [Parameter(Mandatory=$False)]
        [String] $Password,

        [Parameter(Mandatory=$False)]
        [Int] $Port=5696,

        [Parameter(Mandatory=$False)]
        [String] $ProxyServer,

        [Parameter(Mandatory=$False)]
        [Int] $ProxyPort,

        [Parameter(Mandatory=$False)]
        [String] $Protocol
    )

    Begin {
       write-warning "This cmdlet is deprecated and will be removed in future release. Use VMware.VimAutomation.Storage\Add-KeyManagementServer instead"
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter

       # Get the cryptoManager of vCenter Server
       $CM = GetCryptoManager
    }

    Process {
       if ([string]::IsNullOrWhiteSpace($KMSClusterId)) {
          Write-Error "The KMSClusterId parameter is mandatory, please specify a valid value!`n"
          return
       }

       if ([string]::IsNullOrWhiteSpace($KMServer)) {
          Write-Error "The KMServer parameter is mandatory, please specify a valid value!`n"
          return
       }

       if ([string]::IsNullOrWhiteSpace($Name)) {
          Write-Error "The KMSName parameter is mandatory. Please specify a valid value!`n"
          return
       }

       Write-Verbose "Starting to add Key Management Server: $KMServer......`n"
       # Construct KMServerInfo and Spec
       $KMServerInfo = New-Object VMware.Vim.KmipServerInfo
       $KMServerSpec = New-Object VMware.Vim.KmipServerSpec
       $KMServerInfo.Address = $KMServer
       $KMServerInfo.Name = $Name

       if ($UserName) {
          $KMServerInfo.UserName = $UserName
       }

       if ($KMSPassword) {
          $KMServerSpec.Password = $Password
       }

       if ($Port) {
          $KMServerInfo.Port = $Port
       }

       if ($ProxyServer) {
          $KMServerInfo.ProxyAddress = $ProxyServer
       }

       if ($ProxyPort) {
          $KMServerInfo.ProxyPort = $ProxyPort
       }

       if ($Protocol) {
          $KMServerInfo.Protocol = $Protocol
       }

       $ProviderID = New-Object VMware.Vim.KeyProviderId
       $ProviderID.Id = $KMSClusterId
       $KMServerSpec.ClusterId = $ProviderID
       $KMServerSpec.Info = $KMServerInfo

       Write-Verbose "Registering $KMServer to vCenter Server....`n"

       try {
          $CM.RegisterKmipServer($KMServerSpec)
       } catch {
          Write-Error "Exception:  $_ !"
          return
       }

       Write-Verbose "Establishing trust between vCenter Server and the Key Management Server: $KMServer`n"
       try {
          $KMServerCert = $CM.RetrieveKmipServerCert($providerID,$KMServerInfo)
          $CM.UploadKmipServerCert($providerID,$KMServerCert.Certificate)
       } catch {
          Write-Error "Error occurred while retrieveing and uploading certification!`n"
          return
       }

       $CM.updateviewdata()
       if (!(Get-DefaultKMSCluster) -and
            ($CM.KmipServers|foreach {$_.servers}|foreach {$_.Address}) -contains $KMServer) {
          Write-Verbose "No default Key Management Server yet. Marking $KMServer as default!`n"
          Set-DefaultKMSCluster -KMSClusterId $ProviderID.Id
       }

       Write-Verbose "Verifying KMS registration.....`n"
       $CM.updateviewdata()
       $KMServers = $CM.Kmipservers|where {($_.servers|foreach {$_.Address}) -contains $KMServer}
       if ($KMServers) {
          Write-Verbose "Key Management Server registered successfully!`n"
          $KMServers
       } else {
          Write-Error "Key Management Server registration failed!`n"
       }
    }
}

Function Remove-KMServer {
    <#
    .SYNOPSIS
       This cmdlet removes a Key Management Server.

    .DESCRIPTION
       This cmdlet removes a Key Management Server from vCenter Server.

    .PARAMETER Name
       Specifies the name or alias of the Key Management Server.

    .PARAMETER KMSClusterId
       Specifies the KMS cluster ID string to be used as Key Management Server cluster.

    .EXAMPLE
       C:\PS>Remove-KMServer -KMSClusterId "ClusterIdString" -KMSName "KMServerName"

       Removes the KMS from vCenter Server which has the KMS name and KMS cluster ID.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True)]
        [String]$KMSClusterId,

        [Parameter(Mandatory=$True)]
        [String]$Name
    )

    Begin {
       write-warning "This cmdlet is deprecated and will be removed in future release. Use VMware.VimAutomation.Storage\Remove-KeyManagementServer instead"
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter

       # Get the cryptoManager of vCenter Server
       $CM = GetCryptoManager
    }

    Process {
       if ([string]::IsNullOrWhiteSpace($Name) -Or
           [string]::IsNullOrWhiteSpace($KMSClusterId)) {
          $ErrMsg = "The KMSName and KMSClusterId parameters are mandatory "+
                    "and should not be null or empty!`n"
          Write-Error $ErrMsg
          return
       }

       $KMServers = $CM.KmipServers
       if (!$KMServers) {
          Write-Error "There are no Key Managerment Servers in vCenter Server!`n"
          return
       }

       if ($KMServers|Where { ($_.ClusterId.Id -eq $KMSClusterId) -and ($_.Servers|Where {$_.Name -eq $Name})}) {
          #Start to remove the specified Km Server
          try {
             $ProviderID = New-Object VMware.Vim.KeyProviderId
             $ProviderID.Id = $KMSClusterId
             $CM.RemoveKmipServer($providerID, $Name)
          } catch {
             Write-Error "Exception: $_!`n"
             return
          }
       } else {
          $KMSNotFounErrMsg = "Cannot find the KMS with Name:$Name and KMS ClusterId:$KMSClusterId,"+
                              "please make sure you specified correct parameters!`n"
          Write-Error $KMSNotFounErrMsg
          return
       }
    }
}

Function Get-KMSCluster {
    <#
    .SYNOPSIS
       This cmdlet retrieves all KMS clusters.

    .DESCRIPTION
       This cmdlet retrieves all KMS clusters.

    .EXAMPLE
       C:\PS>Get-KMSCluster

       Retrieves all KMS clusters.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    write-warning "This cmdlet is deprecated and will be removed in future release. Use VMware.VimAutomation.Storage\Get-KmsCluster instead"
    # Confirm the connected VIServer is vCenter Server
    ConfirmIsVCenter

    # Get the cryptoManager of vCenter Server
    $CM = GetCryptoManager

    # Get all KMS Clusters
    return $CM.KmipServers.ClusterId
}

Function Get-KMSClusterInfo {
    <#
    .SYNOPSIS
       This cmdlet retrieves the KMS cluster information.

    .DESCRIPTION
       This cmdlet retrieves the KMS cluster Information by providing the KMS cluster ID string.

    .PARAMETER KMSClusterId
       Specifies the KMS cluster ID.

    .EXAMPLE
       C:\PS>Get-KMSClusterInfo

       Retrieves all KMS cluster information.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [String] $KMSClusterId
    )

    Begin {
       write-warning "This cmdlet is deprecated and will be removed in future release. Use VMware.VimAutomation.Storage\Get-KmsCluster instead"
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter

       # Get the cryptoManager of vCenter Server
       $CM = GetCryptoManager
    }

    Process {
       # Get all Km Clusters if no KMSClusterId specified
       if (!$KMSClusterId) {
          return $CM.KmipServers
       }
       return $CM.KmipServers|where {$_.ClusterId.Id -eq $KMSClusterId}
    }
}

Function Get-KMServerInfo {
    <#
    .SYNOPSIS
       This cmdlet retireves the Key Management Servers' information.

    .DESCRIPTION
       This cmdlet retireves the Key Management Servers' information by providing the KMS cluster ID string.

    .PARAMETER KMSClusterId
       Specifies the KMS cluster ID.

    .EXAMPLE
       C:\PS>Get-KMServerInfo

       Retrieves information about all Key Management Servers.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [String] $KMSClusterId
    )

    Begin {
       write-warning "This cmdlet is deprecated and will be removed in future release. Use VMware.VimAutomation.Storage\Get-KeyManagementServer instead"
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter

       # Get the cryptoManager of vCenter Server
       $CM = GetCryptoManager
    }

    Process {
       # Get all KMS Info if no clusterId specified
       if ($KMSClusterId) {
          $FindCluster = (Get-KMSCluster).Contains($KMSClusterId)
          if (!$FindCluster) {
             Write-Error "Cannot find the specified KMS ClusterId in vCenter Server!"
             return
          }

          $ClsInfo = Get-KMSClusterInfo -KMSClusterId $KMSClusterId

          return $ClsInfo.Servers
       }

       return $CM.KmipServers.Servers
    }
}

Function Get-KMServerStatus {
    <#
    .SYNOPSIS
       This cmdlet retrieves the KMS status.

    .DESCRIPTION
       This cmdlet retrieves the KMS status by providing the KMS cluster ID String

    .PARAMETER KMSClusterId
       Specifies the KMS cluster ID from which to retrieve the servers' status.

    .EXAMPLE
       C:\PS>Get-KMServerStatus -KMSClusterId 'ClusterIdString'

       Retrieves the specified KMS cluster 'ClusterIdString' server status.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [String] $KMSClusterId
    )

    Begin {
       # Confirm the connected VIServer is vCenter Server
       ConfirmIsVCenter

       # Get the cryptoManager of vCenter Server
       $CM = GetCryptoManager
    }

    Process {
       $ClusterInfo = @()
       if ($KMSClusterId) {
          # Quit if the ClusterID cannot be found
          $FindCluster = (Get-KMSCluster).Contains($KMSClusterId)
          if (!$FindCluster) {
             Write-Error "Cannot find the specified KMS ClusterId in vCenter Server!"
             return
          }

          $ClsInfo = New-Object VMware.Vim.KmipClusterInfo
          $ProviderId = New-Object VMware.Vim.KeyProviderId
          $ProviderId.Id = $KMSClusterId
          $ClsInfo.ClusterId = $providerId
          $ClsInfo.Servers = (Get-KMSClusterInfo -KMSClusterId $KMSClusterId).Servers
          $ClusterInfo += $ClsInfo
          $KMSClsStatus = $CM.RetrieveKmipServersStatus($ClusterInfo)
       } else {
          $ClusterInfo = Get-KMSClusterInfo
          $KMSClsStatus = $CM.RetrieveKmipServersStatus($ClusterInfo)
       }

       if ($KMSClsStatus) {
          return $KMSClsStatus
       } else {
          Write-Error "Failed to get the KMS status`n"
          return $null
       }
    }
}

Function Get-DefaultKMSCluster {
    <#
    .SYNOPSIS
       This cmdlet retrieves the default KMS cluster.

    .DESCRIPTION
       This cmdlet retrieves the default KMS cluster.

    .EXAMPLE
       C:\PS>Get-DefaultKMSCluster

       Retrieves the default KMS cluster.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

    write-warning "This cmdlet is deprecated and will be removed in future release. Use VMware.VimAutomation.Storage\Get-KmsCluster instead"
    # Confirm the connected VIServer is vCenter Server
    ConfirmIsVCenter

    # Get the cryptoManager of vCenter Server
    $CM = GetCryptoManager

    return ($CM.KmipServers|where {$_.UseAsDefault}).ClusterId.Id
}

Function Set-DefaultKMSCluster {
    <#
    .SYNOPSIS
       This cmdlet sets the provided KMS cluster as the default KMS cluster.

    .DESCRIPTION
       This cmdlet sets the provided KMS cluster as the default KMS cluster.

    .PARAMETER KMSClusterId
       Specifies KMS cluster ID which will be used to mark as default KMS cluster.

    .EXAMPLE
       C:\PS>Set-DefaultKMSCluster -KMSClusterId 'ClusterIdString'

       Sets the KMS cluster whose cluster ID is 'ClusterIdString' as the default KMS cluster.

    .NOTES
       Author                                    : Baoyin Qiao.
       Author email                              : bqiao@vmware.com
    #>

   [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True)]
        [String] $KMSClusterId
    )

    write-warning "This cmdlet is deprecated and will be removed in future release. Use VMware.VimAutomation.Storage\Set-KmsCluster instead"
    # Confirm the connected VIServer is vCenter Server
    ConfirmIsVCenter

    # Get the cryptoManager of vCenter Server
    $CM = GetCryptoManager
    $ProviderId = New-Object VMware.Vim.KeyProviderId
    $ProviderId.Id = $KMSClusterId

    $CM.MarkDefault($ProviderId)
}

Function Set-VMCryptoUnlock {
    <#
    .SYNOPSIS
       This cmdlet unlocks a locked vm

    .DESCRIPTION
       This cmdlet unlocks a locked vm

    .PARAMETER VM
       Specifies the VM you want to unlock

    .EXAMPLE
       PS C:\> Get-VM |where {$_.locked}| Set-VMCryptoUnlock

       Unlock all locked vms

    .NOTES
       Author                                    : Fangying Zhang
       Author email                              : fzhang@vmware.com
    #>

    [CmdLetBinding()]

    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]]$VM
    )

    Begin {
        # Confirm the connected VIServer is vCenter Server
        ConfirmIsVCenter
    }

    Process {
        foreach ($thisvm in $vm) {
            if (!$thisvm.encrypted) {
                write-warning "$thisvm is not encrypted, will skip $thisvm"
                continue
            }
            if (!$thisvm.Locked) {
                write-warning "$thisvm may not be locked!"
                # $thisvm.locked could be false on old 6.5.0 build (bug 1931370), so do not skip $thisvm
            }
            write-verbose "try to CryptoUnlock $thisvm"
            $thisvm.ExtensionData.CryptoUnlock()
        }
    }
}

Function Add-Vtpm {
    <#
    .SYNOPSIS
       This cmdlet adds a Virtual TPM to the specified VM.

    .DESCRIPTION
       This cmdlet adds a Virtual TPM to the specified VM.

    .PARAMETER VM
       Specifies the VM you want to add Virtual TPM to.

    .EXAMPLE
       C:\PS>$vm1 = Get-VM -Name win2016
       C:\PS>Add-Vtpm $vm1

       Encrypts $vm1's VM home and adds Virtual TPM

    .NOTES
       If VM home is already encrypted, the cmdlet will add a Virtual TPM to the VM.
       If VM home is not encrypted, VM home will be encrypted and Virtual TPM will be added.

    .NOTES
       Author                                    : Chong Yeo.
       Author email                              : cyeo@vmware.com
    #>
    [CmdLetBinding()]

    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM
    )

    Begin {
        # Confirm the connected VIServer is vCenter Server
        ConfirmIsVCenter
    }
    Process {
        $deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $deviceChange.operation = "add"
        $deviceChange.device = new-object VMware.Vim.VirtualTPM
        $VMCfgSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $VMCfgSpec.DeviceChange = $deviceChange

        return $VM.ExtensionData.ReconfigVM_task($VMCfgSpec)
    }
}

Function Remove-Vtpm {
    <#
    .SYNOPSIS
       This cmdlet removes a Virtual TPM from the specified VM.

    .DESCRIPTION
       This cmdlet removes a Virtual TPM from the specified VM.

    .PARAMETER VM
       Specifies the VM you want to remove Virtual TPM from.

    .EXAMPLE
       C:\PS>$vm1 = Get-VM -Name win2016
       C:\PS>Remove-Vtpm $vm1

    .EXAMPLE
       C:\PS>Get-VM -Name win2016 |Remove-Vtpm

       Remove Virtual TPM from VM named win2016

    .NOTES
       Removing VirtualTPM will render all encrypted data on this VM unrecoverable.
       VM home encryption state will be returned to the original state before Virtual TPM is added

    .NOTES
       Author                                    : Chong Yeo.
       Author email                              : cyeo@vmware.com
    #>
    [CmdLetBinding(SupportsShouldProcess=$true, ConfirmImpact = "High")]

    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM
    )

    Begin {
        # Confirm the connected VIServer is vCenter Server
        ConfirmIsVCenter
    }
    Process {
        $message = "Removing Virtual TPM will render all encrypted data on this VM unrecoverable"
        if ($PSCmdlet.ShouldProcess($message, $message + "`n Do you want to proceed", "WARNING")) {
            $deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
            $deviceChange.operation = "remove"
            $deviceChange.device = $vtpm
            $VMCfgSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
            $VMCfgSpec.DeviceChange = $deviceChange
            return $VM.ExtensionData.ReconfigVM_task($VMCfgSpec)
        }
    }
}

Function Get-VtpmCsr {
    <#
    .SYNOPSIS
       This cmdlet gets certficate signing requests(CSR) from Virtual TPM.

    .DESCRIPTION
       This cmdlet gets certficate signing requests(CSR) from Virtual TPM.
       The CSR is a ComObject X509enrollment.CX509CertificateRequestPkcs10

    .PARAMETER VM
       Specifies the VM you want to get the CSRs Virtual TPM from.

    .PARAMETER KeyType [RSA | ECC]
       Specify that only get CSR with public key RSA algorithm.
       If none is specified, both CSR will get returned

    .EXAMPLE
       C:\PS>$vm1 = Get-VM -Name win2016
       C:\PS>Get-VtpmCsr $vm1 -KeyType RSA

    .NOTES
       Both RSA and ECC CSRs objects will be returned.  If ECC or RSA is specified,
       only the corresponding object will be returned

    .NOTES
       Author                                    : Chong Yeo.
       Author email                              : cyeo@vmware.com
    #>
    [CmdLetBinding()]

    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM,

        [Parameter(Mandatory=$False)]
        [String]$KeyType
    )

    Begin {
        # Confirm the connected VIServer is vCenter Server
        ConfirmIsVCenter
    }

    process {
        # Get vTPM from VM
        $vtpm = $VM.ExtensionData.Config.Hardware.Device |Where {$_ -is [VMware.Vim.VirtualTPM]}

        # Check if vTPM is already present
        if (!$vtpm) {
            Write-Error "$VM does not contains a Virtual TPM"
            return
        }

        $CSRs = @()
        foreach ($csrArray in $vtpm.EndorsementKeyCertificateSigningRequest) {
            $csrString = [System.Convert]::ToBase64String($csrArray)
            $csr = New-Object -ComObject X509enrollment.CX509CertificateRequestPkcs10

            #decode a base64 string into a CSR object
            $csr.InitializeDecode($csrString,6)
            if ($keyType) {
                if ($csr.PublicKey.Algorithm.FriendlyName -eq $KeyType){
                    return $csr
                }
            } else {
                $CSRs += $csr
            }
        }
        return $CSRs
    }
}

Function Set-VtpmCert{
    <#
    .SYNOPSIS
       This cmdlet replaces certificates of Virtual TPM in the specified VM.

    .DESCRIPTION
       This cmdlet replaces certificates to Virtual TPM in the specified VM.

    .PARAMETER VM
       Specifies the VM with Virtual TPM where you want to replace the certificates to.

    .PARAMETER Cert
       Specifies the certificate object (System.Security.Cryptography.X509Certificates.X509Certificate)

    .EXAMPLE
       C:\PS>$vm1 = Get-VM -Name win2016
       C:\PS>Set-VtpmCert $vm1 $certObj

    .EXAMPLE
       C:\PS>Get-VM -Name win2016 | Set-VtpmCert $certObj

       Replace the appropriate certificate specified

    .NOTES
       Only RSA or ECC certs will be overwritten

    .NOTES
       Author                                    : Chong Yeo.
       Author email                              : cyeo@vmware.com
    #>
    [CmdLetBinding()]

    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,

        [Parameter(Mandatory=$True)]
        [System.Security.Cryptography.X509Certificates.X509Certificate] $Cert
    )

    Begin {
        # Confirm the connected VIServer is vCenter Server
        ConfirmIsVCenter
    }

    process {
        # Get vTPM from VM
        $vtpm = $VM.ExtensionData.Config.Hardware.Device |Where {$_ -is [VMware.Vim.VirtualTPM]}

        #check if vTPM is already present
        if (!$vtpm) {
            Write-Error "$VM does not contains a Virtual TPM"
            return
        }

        $certOid = New-Object System.Security.Cryptography.Oid($Cert.GetKeyAlgorithm())

        # Check which certificate to overwrite
        $certLocation = GetKeyIndex $vtpm.EndorsementKeyCertificate $certOid.FriendlyName
        if ($certLocation -eq -1) {
            Write-Error "No Certificate with Matching Algorithm $($certOid.FriendlyName) found"
            return
        }

        $vtpm.EndorsementKeyCertificate[$certLocation] = $cert.GetRawCertData()
        $deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $deviceChange.Operation = "edit"
        $deviceChange.Device = $vtpm
        $VMCfgSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $VMCfgSpec.DeviceChange = $deviceChange

        return $VM.ExtensionData.ReconfigVM_task($VMCfgSpec)
    }
}

Function Get-VtpmCert{
    <#
    .SYNOPSIS
       This cmdlet gets certificates of Virtual TPM in the specified VM.

    .DESCRIPTION
       This cmdlet gets certificates of Virtual TPM in the specified VM.

    .PARAMETER VM
       Specifies the VM with Virtual TPM where you want to get the certificate from

    .EXAMPLE
       C:\PS>$vm1 = Get-VM -Name win2016
       C:\PS>$certs = Get-VtpmCert $vm1

    .NOTES
       An array of certificate object (System.Security.Cryptography.X509Certificates.X509Certificate)
	   will be returned

    .NOTES
       Author                                    : Chong Yeo.
       Author email                              : cyeo@vmware.com
    #>
    [CmdLetBinding()]
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM
    )
    Begin {
        # Confirm the connected VIServer is vCenter Server
        ConfirmIsVCenter
    }
    Process {
        # Get vTPM from VM
        $vtpm = $VM.ExtensionData.Config.Hardware.Device |Where {$_ -is [VMware.Vim.VirtualTPM]}

        # check if vTPM is already present
        if (!$vtpm) {
            Write-Error "$VM does not contain a Virtual TPM"
            return
        }

        $certs = @()
        $vtpm.EndorsementKeyCertificate|foreach {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate
            $cert.Import($_)
            $certs += $cert
        }
        return $certs
    }
}

Function ConfirmIsVCenter{
    <#
    .SYNOPSIS
       This function confirms the connected VI server is vCenter Server.

    .DESCRIPTION
       This function confirms the connected VI server is vCenter Server.

    .EXAMPLE
       C:\PS>ConfirmIsVCenter

       Throws exception if the connected VIServer is not vCenter Server.
    #>

    $SI = Get-View Serviceinstance
    $VIType = $SI.Content.About.ApiType

    if ($VIType -ne "VirtualCenter") {
       Throw "Operation requires vCenter Server!"
    }
}

Function ConfirmHardDiskIsValid {
    <#
    .SYNOPSIS
       This function confirms the hard disks is valid.

    .DESCRIPTION
       This function confirms the hard disks is valid.

    .PARAMETER VM
       Specifies the VM which you want to used to validate against.

    .PARAMETER HardDisk
       Specifies the hard disks which you want to use to validate.
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM,

        [Parameter(Mandatory=$True)]
        [VMware.VimAutomation.ViCore.Types.V1.VirtualDevice.HardDisk[]] $HardDisk
    )

    $NonVMHardDisks = $HardDisk|Where {$_.Parent -ne $VM}

    if ($NonVMHardDisks.Length -ge 1) {
       Throw "Some of the provided hard disks: $($NonVMHardDisks.FileName) do not belong to VM: $VM`n"
    }
}

Function MatchKeys {
   <#
    .SYNOPSIS
       This function checks whether the given keys matched or not.

    .DESCRIPTION
       This function checks whether the given keys matched or not with the provided KeyId or KMSClusterId.

    .PARAMETER KeyToMatch
       Specifies the CryptoKey to match for.

    .PARAMETER KeyId
       Specifies the keyId should be matched.

    .PARAMETER KMSClusterId
       Specifies the KMSClusterId should be matched.

    .NOTES
       Returns the true/false depends on the match result.
       One of keyId or KMSClusterId parameter must be specified.
    #>

    [CmdLetBinding()]

    Param (
       [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
       [VMware.Vim.CryptoKeyId] $KeyToMatch,

       [Parameter(Mandatory=$false)]
       [String] $KeyId,

       [Parameter(Mandatory=$false)]
       [String] $KMSClusterId
    )

    Process {
       if (!$KeyId -and !$KMSClusterId) {
          Throw "One of the keyId or KMSClusterId must be specified!`n"
       }

       $Match = $True
       if ($KeyId -and ($KeyId -ne $KeyToMatch.KeyId)) {
           $Match = $false
       }

       if ($KMSClusterId) {
          if (!$KeyToMatch.ProviderId) {
              $Match = $false
          }

          if ($KMSClusterId -ne $KeyToMatch.ProviderId.Id) {
              $Match = $false
          }
       }
       return $Match
    }
}

Function NewEncryptionKey {
    <#
    .SYNOPSIS
       This function generates new encryption key from KMS.

    .DESCRIPTION
       This function generates new encryption from KMS, if no KMSClusterId specified the default KMS will be used.

    .PARAMETER KMSClusterId
       Specifies the KMS cluster id.

    .EXAMPLE
       C:\PS>NewEncryptionKey -KMSClusterId 'ClusterIdString'

       Generates a new encryption key from the specified KMS which cluster id is 'ClusterIdString'.
    #>

    Param (
        [Parameter(Mandatory=$False)]
        [String]$KMSClusterId
    )

    # Confirm the connected VIServer is vCenter
    ConfirmIsVCenter

    # Get the cryptoManager of vCenter Server
    $CM = GetCryptoManager
    $ProviderId = New-Object VMware.Vim.KeyProviderId

    Write-Verbose "Generate a CryptoKey.`n"
    if ($KMSClusterId) {
       $ProviderId.Id = $KMSClusterId
    } else {
       $ProviderId = $null
    }

    $KeyResult = $CM.GenerateKey($ProviderId)
    if (!$keyResult.Success) {
       Throw "Key generation failed, make sure the KMS Cluster exists!`n"
    }
    return $KeyResult
}

Function GetCryptoManager {
    <#
    .SYNOPSIS
       This function retrieves the cryptoManager according to the given type.

    .DESCRIPTION
       This function retrieves the cryptoManager according to the given type.

    .PARAMETER Type
       Specifies the type of CryptoManager instance to get, the default value is KMS.

    .EXAMPLE
       C:\PS>GetCryptoManager -Type "CryptoManagerKmip"

       Retrieves the 'CryptoManagerKmip' type CryptoManager.
    #>

    Param (
        [Parameter(Mandatory=$false)]
        [String] $Type
    )

    Process {
       $SI = Get-View Serviceinstance
       $CM = Get-View $SI.Content.CryptoManager
       $cryptoMgrType = $CM.GetType().Name

       if (!$Type) {
          # As the type is not cared, so return the CM directly
          return $CM
       }
       if ($cryptoMgrType -eq $Type) {
          return $CM
       }

       Throw "Failed to get CryptoManager instance of the required type {$Type}!"
    }
}

Function GetKeyIndex{
    <#
    .SYNOPSIS
       This cmdlet returns the index to the key with a matching algorithm as the KeyType parameter

    .DESCRIPTION
       This cmdlet returns the index to the key with a matching algorithm as the KeyType parameter

    .PARAMETER Certs
       Specifies the list of certificats.  Expected format is byte[][]

    .PARAMETER KeyType
       Specifies the keytype to search for

    .EXAMPLE
       C:\PS>$keyIndex = GetKeyIndex $Certs RSA
       C:\PS>$keyIndex = GetKeyIndex $Certs ECC

    .NOTES
       Author                                    : Chong Yeo.
       Author email                              : cyeo@vmware.com
    #>

    [CmdLetBinding()]

    param (
        [Parameter(Mandatory=$True)]
        [byte[][]] $Certs,

        [Parameter(Mandatory=$True)]
        [String] $KeyType
    )
    process {
        for ($i=0;$i -lt $Certs.Length; $i++) {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate
            $cert.Import($Certs.Get($i))
            $certType = New-Object System.Security.Cryptography.Oid($cert.GetKeyAlgorithm())
            if ( $certType.FriendlyName -eq $keyType) {
                return $i
            }
        }
        return -1
    }
}

Export-ModuleMember *-*
