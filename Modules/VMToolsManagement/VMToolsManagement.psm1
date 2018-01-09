# Script Module : VMToolsManagement
# Version       : 1.0

# Copyright © 2017 VMware, Inc. All Rights Reserved.

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

New-VIProperty -Name ToolsBuildNumber -Object VirtualMachine -Value {
    Param ($VM)

    foreach ($item in $VM.ExtensionData.Config.ExtraConfig.GetEnumerator()) {
        if ($item.Key -eq "guestinfo.vmtools.buildNumber") {
            $toolsBuildNumber = $item.value
            break
        }
    }

    return $toolsBuildNumber
} -BasedOnExtensionProperty 'Config.ExtraConfig' -Force | Out-Null

Function Get-VMToolsInfo {
<#
.SYNOPSIS
    This advanced function retrieves the VMTools info of specified virtual machines.

.DESCRIPTION
    This advanced function retrieves the VMTools version and build number info of specified virtual machines.

.PARAMETER VM
    Specifies the virtual machines which you want to get the VMTools info of.

.EXAMPLE
    C:\PS> Import-Module .\VMToolsManagement.psm1
    C:\PS> $VCServer = Connect-VIServer -Server <vCenter Server IP> -User <vCenter User> -Password <vCenter Password>
    C:\PS> Get-VM -Server $VCServer | Get-VMToolsInfo

    Retrieves VMTools info of all virtual machines which run in the $VCServer vCenter Server.

.EXAMPLE
    C:\PS> Get-VM "*rhel*" | Get-VMToolsInfo

    Name                   ToolsVersion ToolsBuildNumber
    ------                 ------------ ----------------
    111394-RHEL-6.8-0      10.2.0       6090153
    111394-RHEL-6.8-1      9.0.15
    111393-RHEL-Server-7.2 10.1.0

    Retrieves VMTools info of virtual machines with name containing "rhel".

.EXAMPLE
    C:\PS> Get-VM -Location "MyClusterName" | Get-VMToolsInfo

    Retrieves VMTools info from virtual machines which run in the "MyClusterName" cluster.

.EXAMPLE
    C:\PS> Get-VMHost "MyESXiHostName" | Get-VM | Get-VMToolsInfo

    Retrieves VMTools info of virtual machines which run on the "MyESXiHostName" ESXi host.

.NOTES
    This advanced function assumes that you are connected to at least one vCenter Server system.
    The tools build number is not supported in VMTools before 10.2.0

.NOTES
    Author                                    : Daoyuan Wang
    Author email                              : daoyuanw@vmware.com
    Version                                   : 1.0
    ==========Tested Against Environment==========
    VMware vSphere Hypervisor(ESXi) Version   : 6.5 (build 4564106)
    VMware vCenter Server Version             : 6.5 (build 4602587)
    PowerCLI Version                          : PowerCLI 6.5 (build 4624819)
    PowerShell Version                        : 5.1
#>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true,
                    ValueFromPipelinebyPropertyName=$True,
                    Position = 0)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VM
    )

    Process {
        Get-VM $VM | Select-Object Name, @{Name="ToolsVersion"; Expression={$_.Guest.ToolsVersion}}, ToolsBuildNumber
    }
}

Function Get-VMToolsInstallLastError {
<#
.SYNOPSIS
    This advanced function retrieves the error code of last VMTools installation.

.DESCRIPTION
    This advanced function retrieves the error code of last VMTools installation on specified virtual machines.

.PARAMETER VM
    Specifies the virtual machines which you want to get the error code of.

.EXAMPLE
    C:\PS> Import-Module .\VMToolsManagement.psm1
    C:\PS> $VCServer = Connect-VIServer -Server <vCenter Server IP> -User <vCenter User> -Password <vCenter Password>
    C:\PS> Get-VM -Server $VCServer | Get-VMToolsInstallLastError

    Retrieves the last VMTools installation error code of all virtual machines which run in the $VCServer vCenter Server.

.EXAMPLE
    C:\PS> Get-VM "*win*" | Get-VMToolsInstallLastError

    Name                                       LastToolsInstallErrCode
    ------                                     -----------------------
    111167-Win-7-Sp1-64-Enterprise-NoTools
    111323-Windows-8.1U3-32-Enterprise-Tools
    111305-Windows-Server2016                  1641

    Retrieves the last VMTools installation error code of virtual machines with name containing "win".

.EXAMPLE
    C:\PS> Get-VM -Location "MyClusterName" | Get-VMToolsInstallLastError

    Retrieves the last VMTools installation error code of virtual machines which run in the "MyClusterName" cluster.

.EXAMPLE
    C:\PS> Get-VMHost "MyESXiHostName" | Get-VM | Get-VMToolsInstallLastError

    Retrieves the last VMTools installation error code of virtual machines which run on the "MyESXiHostName" ESXi host.

.NOTES
    This advanced function assumes that you are connected to at least one vCenter Server system.

.NOTES
    Author                                    : Daoyuan Wang
    Author email                              : daoyuanw@vmware.com
    Version                                   : 1.0
    ==========Tested Against Environment==========
    VMware vSphere Hypervisor(ESXi) Version   : 6.5 (build 4564106)
    VMware vCenter Server Version             : 6.5 (build 4602587)
    PowerCLI Version                          : PowerCLI 6.5 (build 4624819)(build 4624819)
    PowerShell Version                        : 5.1
#>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true,
                    ValueFromPipelinebyPropertyName=$True,
                    Position = 0)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VM
    )

    Process {
        $result = @()
        foreach ($_ in $VM) {
            $errorCodeInfo = $_.ExtensionData.Config.ExtraConfig.GetEnumerator() | Where-Object {$_.Key -eq "guestinfo.toolsInstallErrCode"}

            $info = New-Object PSObject
            $info | Add-Member -type NoteProperty -name VmName -value $_.Name
            $info | Add-Member -type NoteProperty -name LastToolsInstallErrCode -value $errorCodeInfo.Value

            $result += $info
        }
        $result
    }
}

Function Get-VMToolsGuestInfo {
<#
.SYNOPSIS
    This advanced function retrieves the guest info of specified virtual machines.

.DESCRIPTION
    This advanced function retrieves the guest info such as HostName, IP, ToolsStatus, ToolsVersion,
    ToolsInstallType and GuestFamily of specified virtual machines.

.PARAMETER VM
    Specifies the virtual machines which you want to get the guest info of.

.EXAMPLE
    C:\PS> Import-Module .\VMToolsManagement.psm1
    C:\PS> $VCServer = Connect-VIServer -Server <vCenter Server IP> -User <vCenter User> -Password <vCenter Password>
    C:\PS> Get-VM -Server $VCServer | Get-VMToolsGuestInfo

    Retrieves guest info of all virtual machines which run in the $VCServer vCenter Server.

.EXAMPLE
    C:\PS> Get-VM "*win*" | Get-VMToolsGuestInfo

    Name             : 111323-Windows-8.1U3-32-Enterprise-Tools
    HostName         : win81u3
    IP               :
    ToolsStatus      : toolsNotRunning
    ToolsVersion     : 10.2.0
    ToolsInstallType : guestToolsTypeMSI
    GuestFamily      : windowsGuest
    VMPowerState     : PoweredOff

    Name             : 111305-Windows-Server2016
    HostName         : WIN-ULETOOSSB7U
    IP               : 10.160.59.99
    ToolsStatus      : toolsOk
    ToolsVersion     : 10.1.0
    ToolsInstallType : guestToolsTypeMSI
    GuestFamily      : windowsGuest
    VMPowerState     : PoweredOn

    Retrieves guest info of virtual machines with name containing "win".

.EXAMPLE
    C:\PS> Get-VM -Location "MyClusterName" | Get-VMToolsGuestInfo

    Retrieves guest info of virtual machines which run in the "MyClusterName" cluster.

.EXAMPLE
    C:\PS> Get-VMHost "MyESXiHostName" | Get-VM | Get-VMToolsGuestInfo

    Retrieves guest info of virtual machines which run on the "MyESXiHostName" ESXi host.

.NOTES
    This advanced function assumes that you are connected to at least one vCenter Server system.

.NOTES
    Author                                    : Daoyuan Wang
    Author email                              : daoyuanw@vmware.com
    Version                                   : 1.0
    ==========Tested Against Environment==========
    VMware vSphere Hypervisor(ESXi) Version   : 6.5 (build 4564106)
    VMware vCenter Server Version             : 6.5 (build 4602587)
    PowerCLI Version                          : PowerCLI 6.5 (build 4624819)(build 4624819)
    PowerShell Version                        : 5.1
#>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true,
                    ValueFromPipelinebyPropertyName=$True,
                    Position = 0)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VM
    )

    Process {
        Get-VM $VM | Select-Object Name, @{Name="HostName"; Expression={$_.Guest.HostName}},
                            @{Name="IP"; Expression={$_.Guest.ExtensionData.IpAddress}},
                            @{Name="ToolsStatus"; Expression={$_.Guest.ExtensionData.ToolsStatus}},
                            @{Name="ToolsVersion"; Expression={$_.Guest.ToolsVersion}},
                            @{Name="ToolsInstallType"; Expression={$_.Guest.ExtensionData.ToolsInstallType}},
                            @{Name="GuestFamily"; Expression={$_.Guest.GuestFamily}},
                            PowerState
    }
}

Function Get-VMByToolsInfo {
<#
.SYNOPSIS
    This advanced function retrieves the virtual machines with specified VMTools info.

.DESCRIPTION
    This advanced function retrieves the virtual machines with specified VMTools version,
    running status or version status.

.PARAMETER VM
    Specifies the virtual machines which you want to query VMTools status of.

.PARAMETER ToolsVersion
    Specifies the VMTools version.

.PARAMETER ToolsRunningStatus
    Specifies the VMTools running status.

.PARAMETER ToolsVersionStatus
    Specifies the VMTools version status.

.EXAMPLE
    C:\PS> Import-Module .\VMToolsManagement.psm1
    C:\PS> $VCServer = Connect-VIServer -Server <vCenter Server IP> -User <vCenter User> -Password <vCenter Password>
    C:\PS> Get-VM -Server $VCServer | Get-VMByToolsInfo

    Retrieves the virtual machines with VMTools not running in vCenter Server $VCServer.

.EXAMPLE
    C:\PS> Get-VM | Get-VMByToolsInfo -ToolsRunningStatus guestToolsNotRunning

    Name              PowerState Num CPUs MemoryGB
    ----              ---------- -------- --------
    111394-RHEL-6.8-1 PoweredOff 4        2.000

    Retrieves all the virtual machines with VMTools not running.

.EXAMPLE
    C:\PS> Get-VM | Get-VMByToolsInfo -ToolsVersion '10.1.0'

    Name              PowerState Num CPUs MemoryGB
    ----              ---------- -------- --------
    111394-RHEL-6.8-1 PoweredOff 4        2.000

    Retrieves the virtual machines with VMTools version 10.1.0.

.EXAMPLE
    C:\PS> Get-VM -Location "MyClusterName" | Get-VMByToolsInfo -ToolsVersionStatus guestToolsNeedUpgrade

    Retrieves the virtual machines with VMTools that need to upgrade in the "MyClusterName" cluster.

.EXAMPLE
    C:\PS> Get-VMHost "MyESXiHostName" | Get-VM | Get-VMByToolsInfo -ToolsRunningStatus guestToolsRunning -ToolsVersionStatus guestToolsNeedUpgrade

    Retrieves the virtual machines with VMTools that need to upgrade on the "MyESXiHostName" ESXi host.

.NOTES
    This advanced function assumes that you are connected to at least one vCenter Server system.

.NOTES
    Author                                    : Daoyuan Wang
    Author email                              : daoyuanw@vmware.com
    Version                                   : 1.0
    ==========Tested Against Environment==========
    VMware vSphere Hypervisor(ESXi) Version   : 6.5 (build 4564106)
    VMware vCenter Server Version             : 6.5 (build 4602587)(build 4602587)
    PowerCLI Version                          : PowerCLI 6.5 (build 4624819)
    PowerShell Version                        : 5.1
#>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true,
                    ValueFromPipelinebyPropertyName=$True,
                    Position = 0)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VM,

        [Parameter(Mandatory=$false)]
        [String] $ToolsVersion,

        [Parameter(Mandatory=$false)]
        [ValidateSet("guestToolsRunning",
                    "guestToolsNotRunning",
                    "guestToolsExecutingScripts")]
        [String] $ToolsRunningStatus,

        [Parameter(Mandatory=$false)]
        [ValidateSet("guestToolsNotInstalled",
                    "guestToolsNeedUpgrade",
                    "guestToolsCurrent",
                    "guestToolsUnmanaged")]
        [String] $ToolsVersionStatus
    )

    Process {
        $vmList = Get-VM $VM

        if ((-not $ToolsVersion) -and (-not $ToolsRunningStatus) -and (-not $ToolsVersionStatus)) {
            Throw "Please specify at lease one parameter: ToolsVersion, ToolsRunningStatus or ToolsVersionStatus"
        }

        if ($ToolsVersion) {
            $vmList = $vmList | Where-Object {$_.Guest.ToolsVersion -like $ToolsVersion}
        }

        if ($ToolsRunningStatus) {
            $vmList = $vmList | Where-Object {$_.Guest.ExtensionData.ToolsRunningStatus -eq $ToolsRunningStatus}
        }

        if ($ToolsVersionStatus) {
            $vmList = $vmList | Where-Object {$_.Guest.ExtensionData.ToolsVersionStatus -eq $ToolsVersionStatus}
        }

        $vmList
    }
}

Function Get-VMToolsUpgradePolicy {
<#
.SYNOPSIS
    This advanced function retrieves the VMTools upgrade policy info of specified virtual machines.

.DESCRIPTION
    This advanced function retrieves the VMTools upgrade policy info of specified virtual machines.

.PARAMETER VM
    Specifies the virtual machines which you want to query VMTools status of.

.EXAMPLE
    C:\PS> Get-VM "*rhel*" | Get-VMToolsUpgradePolicy
    Name                   VMToolsUpgradePolicy
    ------                 ----------------------
    111394-RHEL-6.8-0      manual
    111394-RHEL-6.8-1      manual
    111393-RHEL-Server-7.2 upgradeAtPowerCycle
    Retrieves VMTools upgrade policy info of virtual machines with name containing "rhel".

.EXAMPLE
    C:\PS> Get-VM -Location "MyClusterName" | Get-VMToolsUpgradePolicy
    Retrieves VMTools upgrade policy info from virtual machines which run in the "MyClusterName" cluster.

.EXAMPLE
    C:\PS> Get-VMHost "MyESXiHostName" | Get-VM | Get-VMToolsUpgradePolicy
    Retrieves VMTools upgrade policyinfo of virtual machines which run on the "MyESXiHostName" ESXi host.

.NOTES
    This advanced function assumes that you are connected to at least one vCenter Server system.

.NOTES
    Author                                    : Kyle Ruddy
    Author email                              : kmruddy@gmail.com
    Version                                   : 1.0
    ==========Tested Against Environment==========
    VMware vSphere Hypervisor(ESXi) Version   : 6.5 (build 7388607)
    VMware vCenter Server Version             : 6.5 (build 7312210)
    PowerCLI Version                          : PowerCLI 6.5 (build 7155375)
    PowerShell Version                        : 5.1
#>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true,
                    ValueFromPipelinebyPropertyName=$True,
                    Position = 0)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VM
    )

    Process {
        
        Get-VM $VM | Select-Object Name, @{Name="VMToolsUpgradePolicy"; Expression={$_.ExtensionData.Config.Tools.ToolsUpgradePolicy}}

    }

}

Function Set-VMToolsUpgradePolicy {
<#
.SYNOPSIS
    This advanced function sets the VMTool's upgrade policy to either "manual" or "upgradeAtPowerCycle".

.DESCRIPTION
    This advanced function sets the VMTool's upgrade policy to either "manual" or "upgradeAtPowerCycle" of specified virtual machines.

.PARAMETER VM
    Specifies the virtual machines which you want to set the VMTool's upgrade policy of.

.EXAMPLE
    C:\PS> Import-Module .\VMToolsManagement.psm1
    C:\PS> $VCServer = Connect-VIServer -Server <vCenter Server IP> -User <vCenter User> -Password <vCenter Password>
    C:\PS> Get-VM -Server $VCServer | Set-VMToolsUpgradePolicy -UpgradePolicy manual

    Sets VMTool's upgrade policy to "manual" of all virtual machines in the $VCServer vCenter Server.

.EXAMPLE
    C:\PS> Get-VM "*win*" | Set-VMToolsUpgradePolicy -UpgradePolicy upgradeAtPowerCycle

    Sets VMTool's upgrade policy to "upgradeAtPowerCycle" of virtual machines with name containing "win".

.EXAMPLE
    C:\PS> Get-VM -Location "MyClusterName" | Set-VMToolsUpgradePolicy -UpgradePolicy upgradeAtPowerCycle

    Sets VMTool's upgrade policy to "upgradeAtPowerCycle" of virtual machines in the "MyClusterName" cluster.

.EXAMPLE
    C:\PS> Get-VMHost "MyESXiHostName" | Get-VM | Set-VMToolsUpgradePolicy -UpgradePolicy manual

    Sets VMTool's upgrade policy to "manual" of virtual machines on the "MyESXiHostName" ESXi host.

.NOTES
    This advanced function assumes that you are connected to at least one vCenter Server system.

.NOTES
    Author                                    : Daoyuan Wang
    Author email                              : daoyuanw@vmware.com
    Version                                   : 1.1
    Update Author                             : Kyle Ruddy
    Update email                              : kmruddy@gmail.com
    ==========Tested Against Environment==========
    VMware vSphere Hypervisor(ESXi) Version   : 6.5 (build 4564106)(build 7388607)
    VMware vCenter Server Version             : 6.5 (build 4602587)(build 7312210)
    PowerCLI Version                          : PowerCLI 6.5 (build 4624819)(build 7155375)
    PowerShell Version                        : 5.1
#>

    [CmdletBinding(SupportsShouldProcess)]

    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true,
                    ValueFromPipelinebyPropertyName=$True,
                    Position = 0)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VM,

        [Parameter(Mandatory=$false,
                    Position = 1)]
        [ValidateSet("upgradeAtPowerCycle",
                    "manual")]
        [String] $UpgradePolicy
    )
    Begin {
        $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $vmConfigSpec.Tools = New-Object VMware.Vim.ToolsConfigInfo
        $vmConfigSpec.Tools.ToolsUpgradePolicy = $UpgradePolicy
    }

    Process {
        foreach ($_ in $VM) {
            # Get current setting
            $vmView = Get-View $_ -Property Config.Tools.ToolsUpgradePolicy
            # Change if VMTools upgrade policy is not "upgradeAtPowerCycle"
            if ($vmView.Config.Tools.ToolsUpgradePolicy -ne $UpgradePolicy) {
                Write-Verbose "Applying 'upgradeAtPowerCycle' setting to $($_.Name)..."
                $vmView.ReconfigVM($vmConfigSpec)
                Get-VMToolsUpgradePolicy -VM $_
            }
        }
    }
}

Function Invoke-VMToolsListProcessInVM {
<#
.Synopsis
    This advanced function lists the processes in the virtual machine.

.Description
    This advanced function lists the running processes in the virtual machine.

.PARAMETER VM
    Specifies the virtual machine which you want to list the processes of.

.Parameter GuestUser
    Specifies the user name you want to use for authenticating with the guest OS.

.Parameter GuestPassword
    Specifies the password you want to use for authenticating with the guest OS.

.Example
    C:\PS> Import-Module .\VMToolsManagement.psm1
    C:\PS> $SampleVM = get-vm "MyVMName"
    C:\PS> Invoke-VMToolsListProcessInVM -VM $SampleVM -GuestUser <username> -GuestPassword <password>

    ScriptOutput
    -----------------------------------------------------------------------------------------------------------------------
    |  USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
    |  root         1  0.0  0.0  19360  1556 ?        Ss   Jul20   0:02 /sbin/init
    |  root         2  0.0  0.0      0     0 ?        S    Jul20   0:00 [kthreadd]
    |  root         3  0.0  0.0      0     0 ?        S    Jul20   0:06 [migration/0]
    |  root         4  0.0  0.0      0     0 ?        S    Jul20   0:00 [ksoftirqd/0]
    |  root         5  0.0  0.0      0     0 ?        S    Jul20   0:00 [stopper/0]
    ......

    List the processes in the "MyVMName" VM.

.NOTES
    This advanced function lists processes in the guest OS of virtual machine.
    A VMTools should already be running in the guest OS.

.NOTES
    Author                                    : Daoyuan Wang
    Author email                              : daoyuanw@vmware.com
    Version                                   : 1.0
    ==========Tested Against Environment==========
    VMware vSphere Hypervisor(ESXi) Version   : 6.5 (build 4564106)
    VMware vCenter Server Version             : 6.5 (build 4602587)
    PowerCLI Version                          : PowerCLI 6.5 (build 4624819)
    PowerShell Version                        : 5.1
    Guest OS                                  : RHEL6.8, Windows7
#>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true,
                    ValueFromPipelinebyPropertyName=$True,
                    Position = 0)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $GuestUser,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String] $GuestPassword
    )

    Process {
        $vmView = Get-VM $VM | Get-View -Property Guest
        if ($vmView.Guest.State -eq 'NotRunning') {
            Write-Error "$VM is Not Running, unable to list the processes!"
            return
        }

        if ($vmView.Guest.GuestFamily -match 'windows') {
            $command = 'Get-Process'
        } elseif ($vmView.Guest.GuestFamily -match 'linux') {
            $command = 'ps aux'
        } else {
            $command = 'ps'
        }

        Invoke-VMScript -VM $VM -ScriptText $command -GuestUser $GuestUser -GuestPassword $GuestPassword
    }
}

Function Update-VMToolsImageLocation {
<#
.Synopsis
    This advanced function updates the link /productLocker in ESXi host.

.Description
    This advanced function updates the link /productLocker in ESXi host directly to avoid host reboot.

.Parameter VMHost
    Specifies the ESXi host on which you want to update the /productLocker link.

.Parameter HostUser
    Specifies the user name you want to use for authenticating with the ESXi host.

.Parameter HostPassword
    Specifies the password you want to use for authenticating with the ESXi host.

.Parameter ImageLocation
    Specifies the new image location Where-Object you want /producterLocker to link.

.Example
    C:\PS> Import-Module .\VMToolsManagement.psm1
    C:\PS> $SampleHost = get-vmhost <host ip>
    C:\PS> Update-VMToolsImageLocation -VmHost $SampleHost -HostUser 'root' -HostPassword <host password> -ImageLocation '/locker/packages/6.5.0/'

    Update link /productLocker successfully.

    Update the link /producterLocker on $SampleHost to point to '/locker/packages/6.5.0/'.

.NOTES
    This advanced function connects to ESXi host to execute shell command directly.
    Make sure the SSH service on ESXi host is enabled, and a SSH library(Posh-SSH or SSH-Sessions etc.)
    for powershell is already installed on client Where-Object you call this advanced function.
    You can instal Posh-SSH by executing:
        iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
    For SSH-Sessions installation and usage, please refer to
        http://www.powershelladmin.com/wiki/SSH_from_PowerShell_using_the_SSH.NET_library


.NOTES
    Author                                    : Daoyuan Wang
    Author email                              : daoyuanw@vmware.com
    Version                                   : 1.0
    ==========Tested Against Environment==========
    VMware vSphere Hypervisor(ESXi) Version   : 6.5 (build 4564106)
    VMware vCenter Server Version             : 6.5 (build 4602587)
    PowerCLI Version                          : PowerCLI 6.5 (build 4624819)
    PowerShell Version                        : 5.1
#>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true,
                    ValueFromPipelinebyPropertyName=$True,
                    Position = 0)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost] $VMHost,

        [Parameter(Mandatory=$true)]
        [String] $HostUser,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String] $HostPassword,

        [Parameter(Mandatory=$true)]
        [String] $ImageLocation
    )

    Process {
        if (-not (Get-Command New-SSHSession)) {
            Throw "This advanced function depends on SSH library. Please ensure a SSH library is already installed!"
        }

        $password = new-object System.Security.SecureString
        if ($HostPassword) {
            $password = ConvertTo-SecureString -AsPlainText $HostPassword -Force
        }

        $crendential = New-Object System.Management.Automation.PSCredential -ArgumentList $HostUser, $password
        $sshSession = New-SSHSession -ComputerName $VMHost -Credential $crendential -Force

        $result = Invoke-SshCommand -SSHSession $sshSession -Command "readlink /productLocker" -EnsureConnection:$false
        Write-Verbose "The link /productLocker before change: $($result.Output)"

        $command = "rm /productLocker && ln -s $ImageLocation /productLocker"
        Write-Verbose "Updating /productLocker on $VMHost..."
        $result = Invoke-SshCommand -SSHSession $sshSession -Command $command -EnsureConnection:$false
        if ($result.ExitStatus -eq 0) {
            Write-Host "Update link /productLocker successfully." -ForegroundColor Green
        } else {
            Write-Error "Failed to update link /productLocker: $($result.Error)"
        }

        $result = Invoke-SshCommand -SSHSession $sshSession -Command "readlink /productLocker" -EnsureConnection:$false
        Write-Verbose "The link /productLocker after change: $($result.Output)"
    }
}

Function Set-VMToolsConfInVM {
<#
.Synopsis
    This advanced function sets the tools.conf content in guest OS.

.Description
    This advanced function copies the tools.conf in gueset OS of virtual machine to localhost,
    then sets it locally by setting "vmtoolsd.level" to a valid level and copies it back to the guest OS.

.PARAMETER VM
    Specifies the virtual machine to update.

.PARAMETER LogLevel
    Specifies the desired log level to log.

.Parameter GuestUser
    Specifies the user name you want to use for authenticating with the guest OS.

.Parameter GuestPassword
    Specifies the password you want to use for authenticating with the guest OS.

.Example
    C:\PS> Import-Module .\VMToolsManagement.psm1
    C:\PS> $SampleVM = get-vm "MyVMName"
    C:\PS> Update-VMToolsConfInVM -VM $SampleVM -GuestUser <username> -GuestPassword <password>

    Update tools.conf of 111394-RHEL-6.8-0 successfully.

    Updates the tools.conf in $SampleVM, changes the vmtoolsd log level to info ("vmtoolsd.level = info") for example.

.NOTES
    This advanced function updates the tools.conf in guest OS. A VMTools should already be running in the guest OS.

.NOTES
    Author                                    : Daoyuan Wang
    Author email                              : daoyuanw@vmware.com
    Version                                   : 1.1
    Update Author                             : Kyle Ruddy
    Update email                              : kmruddy@gmail.com
    ==========Tested Against Environment==========
    VMware vSphere Hypervisor(ESXi) Version   : 6.5 (build 4564106)(build 7388607)
    VMware vCenter Server Version             : 6.5 (build 4602587)(build 7312210)
    PowerCLI Version                          : PowerCLI 6.5 (build 4624819)(build 7155375)
    PowerShell Version                        : 5.1
#>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true,
                    ValueFromPipelinebyPropertyName=$True,
                    Position = 0)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $VM,

        [Parameter(Mandatory=$true,
                    Position = 1)]
        [ValidateSet("none",
                    "critical",
                    "error",
                    "warning",
                    "message",
                    "info",
                    "debug")]
        [String] $LogLevel,

        [Parameter(Mandatory=$true)]
        [String] $GuestUser,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String] $GuestPassword
    )

    Process {
        $vmGuest = Get-VMGuest $VM
        $OsName = $vmGuest.OSFullName
        $guestToolsConfFile = ""
        $localToolsConfFile = ".\tools.conf"

        # Determine the tools.conf path in guest OS
        if (($OsName -match "Linux") `
                -or ($OsName -match "FreeBSD") `
                -or ($OsName -match "Solaris")) {
            $guestToolsConfFile = '/etc/vmware-tools/tools.conf'
        } elseif (($OsName  -match "Windows Server 2003") `
                -or ($OsName -match "Windows Server 2000") `
                -or ($OsName -match "Windows XP")) {
            $guestToolsConfFile = 'C:\Documents and Settings\All Users\Application Data\VMware\VMware Tools\tools.conf'
        } elseif ($OsName -match "Windows") {
            $guestToolsConfFile = 'C:\ProgramData\VMware\VMware Tools\tools.conf'
        } elseif ($OsName -match "Mac") {
            $guestToolsConfFile = '/Library/Application Support/VMware Tools/tools.conf'
        } else {
            Throw "Unknown tools.conf path on OS: $OsName"
        }

        # Get the tools.conf from guest OS to localhost, ignore the error if tools.conf was not found in guest OS
        Write-Verbose "Copy tools.conf from $VM to localhost..."
        $lastError = $Error[0]
        Copy-VMGuestFile -Source $guestToolsConfFile -Destination $localToolsConfFile -VM $VM -GuestToLocal `
                -GuestUser $GuestUser -GuestPassword $GuestPassword -Force -ErrorAction:SilentlyContinue

        # The tools.conf doesn't exist in guest OS, create an empty one locally
        if (($Error[0] -ne $lastError) -and ($Error[0] -notmatch 'tools.conf was not found')) {
            Write-Error "Failed to copy tools.conf from $VM"
            return
        } elseif (-not (Test-Path $localToolsConfFile)) {
            Set-Content $localToolsConfFile $null
        }

        #############################################################################
        # Updates tools.conf by setting vmtoolsd.level = info, just for example.
        #############################################################################
        $confContent = Get-Content $localToolsConfFile
        $updatedContent = "vmtoolsd.level = $LogLevel"

        Write-Verbose "Editing tools.conf (set 'vmtoolsd.level = info' for example)..."
        if ($confContent -match "vmtoolsd\.level") {
            $confContent -replace "vmtoolsd\.level.*", $updatedContent | Set-Content $localToolsConfFile
        } elseif ($confContent -match "logging") {
            Add-Content $localToolsConfFile $updatedContent
        } else {
            Add-Content $localToolsConfFile "[logging]`nlog=true"
            Add-Content $localToolsConfFile $updatedContent
        }

        # Upload the changed tools.conf to guest OS
        try {
            Write-Verbose "Copy local tools.conf to $VM..."
            Copy-VMGuestFile -Source $localToolsConfFile -Destination $guestToolsConfFile -VM $VM -LocalToGuest `
                    -GuestUser $GuestUser -GuestPassword $GuestPassword -Force -ErrorAction:Stop
        } catch {
            Write-Error "Failed to update tools.conf of $VM"
            Write-Verbose "Removing the local tools configuration file"
            Remove-Item $localToolsConfFile
            return
        }
        Write-Host "The tools.conf updated in $VM successfully." -ForegroundColor Green
        Write-Verbose "Removing the local tools configuration file"
        Remove-Item $localToolsConfFile 
    }
}

Function Invoke-VMToolsVIBInstall {
<#
.SYNOPSIS
    This advanced function installs VMTool VIB in ESXi hosts.

.DESCRIPTION
    This advanced function installs VMTool VIB in specified ESXi hosts.

.PARAMETER VMHost
    Specifies the ESXi hosts which you want to install VMTool VIB in.

.PARAMETER ToolsVibUrl
    Specifies the URL of VMTools VIB package which you want to install in ESXi hosts.

.EXAMPLE
    C:\PS> Import-Module .\VMToolsManagement.psm1
    C:\PS> $VCServer = Connect-VIServer -Server <vCenter Server IP> -User <vCenter User> -Password <vCenter Password>.
    C:\PS> $viBurl = "http://<YOUR URL>/VMware_locker_tools-light_6.5.0-10.2.0.6085460.vib"
    C:\PS> Get-VMHost -Server $VCServer | Invoke-VMToolsVIBInstall -ToolsVibUrl $viBurl

    Install VMTool VIB in $VCServer.

.EXAMPLE
    C:\PS> Invoke-VMToolsVIBInstall -VMHost "MyESXiHostName" -ToolsVibUrl $viBurl

    Installs VMTools VIB package successfully.

    Installs VMTool VIB in the "MyESXiHostName" ESXi host.

.EXAMPLE
    C:\PS> Get-VMHost -Location "MyClusterName" | Invoke-VMToolsVIBInstall -ToolsVibUrl $vib

    Installs VMTool VIB in ESXi host of the "MyClusterName" cluster.

.NOTES
    This advanced function assumes that you are connected to at least one vCenter Server system.

.NOTES
    Author                                    : Daoyuan Wang
    Author email                              : daoyuanw@vmware.com
    Version                                   : 1.0
    ==========Tested Against Environment==========
    VMware vSphere Hypervisor(ESXi) Version   : 6.5 (build 4564106)
    VMware vCenter Server Version             : 6.5 (build 4602587)
    PowerCLI Version                          : PowerCLI 6.5 (build 4624819)
    PowerShell Version                        : 5.1
#>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true,
                    ValueFromPipelinebyPropertyName=$True,
                    Position = 0)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost[]] $VMHost,

        [Parameter(Mandatory=$true)]
        [String] $ToolsVibUrl
    )

    Process {
        foreach ($_ in $VMHost) {
            $esxcli = Get-EsxCLI -VMHost $_ -V2

            $result = $esxcli.software.vib.list.Invoke() | Where-Object {$_.name -match 'tools'}
            Write-Verbose "Existing tools VIB on $_ before installing: $($result.Name)_$($result.Version)"

            # Install VIBs
            Write-Verbose "Installing $ToolsVibUrl on $($_.Name)..."
            $Error.Clear()
            $cliArgs = $esxcli.software.vib.install.CreateArgs()
            $cliArgs.viburl = $ToolsVibUrl
            $cliArgs.nosigcheck = $true
            $cliArgs.force = $true
            $result = $esxcli.software.vib.install.Invoke($cliArgs)
            if ($Error) {
                Write-Error "Failed to install VMTools VIB package!"
            } else {
                Write-Verbose $result.Message
                $result = $esxcli.software.vib.list.Invoke() | Where-Object {$_.name -match 'tools'}
                Write-Verbose "Tools VIB on $_ after installing: $($result.Name)_$($result.Version)"
                Write-Host "VMTools VIB package installed on $_ successfully." -ForegroundColor Green
            }
        }
    }
}

Function Invoke-VMToolsUpgradeInVMs {
<#
.SYNOPSIS
    This advanced function upgrades VMTools to the version bundled by ESXi host.

.DESCRIPTION
    This advanced function upgrades VMTools of specified virtual machines to the version
    bundled by ESXi host. You can also specify the number of virtual machines
    to upgrade in parallel.

.PARAMETER VM
    Specifies the virtual machines you want to upgrade VMTools of.

.PARAMETER GuestOSType
    Specifies the guest OS type of the virtual machines.

.PARAMETER VersionToUpgrade
    Specifies the current running VMTools version of virtual machines.

.PARAMETER MaxParallelUpgrades
    Specifies the max virtual machine numbers to upgrade in parallel.

.EXAMPLE
    C:\PS> Import-Module .\VMToolsManagement.psm1
    C:\PS> $VCServer = Connect-VIServer -Server <vCenter Server IP> -User <vCenter User> -Password <vCenter Password>
    C:\PS> Get-VM -Server $VCServer | Invoke-VMToolsUpgradeInVMs -MaxParallelUpgrades 5

    Upgrades VMTools of all virtual machines in the $VCServer vCenter Server, 5 at a time in parallel.

.EXAMPLE
    C:\PS> Get-VM | Invoke-VMToolsUpgradeInVMs -GuestOSType windows -MaxParallelUpgrades 1 | ft -Autosize

    Upgrade result:

    VmName                                   UpgradeResult  ToolsVersion ToolsVersionStatus    TotalSeconds Message
    ------                                   -------------  ------------ ------------------    ------------ -------
    111167-Win-7-Sp1-64-Enterprise-NoTools-2 Completed      10.1.0       guestToolsCurrent              102 Upgrade VMTools successfully
    111393-RHEL-Server-7.2                   Skipped        10.0.0       guestToolsNeedUpgrade            0 Guest OS type does not meet condtion 'windows'
    111305-Windows-Server2016                Completed      10.1.0       guestToolsCurrent              144 Upgrade VMTools successfully

    Upgrades VMTools of windows virtual machines one by one.

.EXAMPLE
    C:\PS> Get-VM -Location "MyClusterName" | Invoke-VMToolsUpgradeInVMs -MaxParallelUpgrades 2 | ft -Autosize

    Upgrade result:

    VmName                                   UpgradeResult  ToolsVersion ToolsVersionStatus    TotalSeconds Message
    ------                                   -------------  ------------ ------------------    ------------ -------
    111167-Win-7-Sp1-64-Enterprise-NoTools-2 Failed         10.0.0       guestToolsNeedUpgrade            0 The required VMware Tools ISO image does not exist or is inaccessible.
    111393-RHEL-Server-7.2                   Completed      10.1.0       guestToolsCurrent              100 Upgrade VMTools successfully

    Upgrades VMTools of virtual machines in the "MyClusterName" cluster, 2 at a time.

.EXAMPLE
    C:\PS> Get-VMHost "MyESXiHostName" | Get-VM | Invoke-VMToolsUpgradeInVMs -MaxParallelUpgrades 5

    Upgrades VMTools of virtual machines on the "MyESXiHostName" ESXi host, 5 at a time.

.NOTES
    This advanced function assumes an old VMTools is already running in the virtual machine.

.NOTES
    Author                                    : Daoyuan Wang
    Author email                              : daoyuanw@vmware.com
    Version                                   : 1.0
    ==========Tested Against Environment==========
    VMware vSphere Hypervisor(ESXi) Version   : 6.5 (build 4564106)
    VMware vCenter Server Version             : 6.5 (build 4602587)
    PowerCLI Version                          : PowerCLI 6.5 (build 4624819)
    PowerShell Version                        : 5.1
#>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipeLine = $true,
                    ValueFromPipelinebyPropertyName=$True,
                    Position = 0)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VM,

        [Parameter(Mandatory=$false)]
        [ValidateSet("linux", "windows")]
        [String] $GuestOSType,

        [Parameter(Mandatory=$false)]
        [String] $VersionToUpgrade,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 5)]
        [Int] $MaxParallelUpgrades = 1
    )

    Begin {
        $RunspacePool = [runspacefactory]::CreateRunspacePool(
            1,          #Min Runspaces
            $MaxParallelUpgrades   #Max Runspaces
        )

        $RunspacePool.Open()

        $jobs = New-Object System.Collections.ArrayList
        $result = @()
    }

    Process {
        foreach ($_ in $VM) {
            $vmView = Get-View $_ -Property Guest
            $toolsVersion = $_.Guest.ToolsVersion
            $toolsVersionStatus = $vmView.Guest.ToolsVersionStatus

            # Skip if VMTools doesn't need to upgrade
            if ($toolsVersionStatus -ne "guestToolsNeedUpgrade") {
                Write-Host "No VMTools need to upgrade!`nVM: '$_', ToolsVersionStatus: '$toolsVersionStatus'"
                $result += [pscustomobject]@{
                    VmName = $_.Name
                    UpgradeResult = "Skipped"
                    ToolsVersion = $toolsVersion
                    ToolsVersionStatus = $toolsVersionStatus
                    TotalSeconds = 0
                    Message = "No VMTools need to upgrade!"
                }
                continue
            }

            # Skip if current VMTools doesn't meet to specified version
            if ($VersionToUpgrade -and ($toolsVersion -notmatch $VersionToUpgrade)) {
                Write-Host "Current ToolsVersion in $_ is: $toolsVersion,"`
                         "does not meet condtion `'$VersionToUpgrade`', skipping it..." -ForegroundColor Yellow
                $result += [pscustomobject]@{
                    VmName = $_.Name
                    UpgradeResult = "Skipped"
                    ToolsVersion = $toolsVersion
                    ToolsVersionStatus = $toolsVersionStatus
                    TotalSeconds = 0
                    Message = "Current VMTools version does not meet condtion `'$VersionToUpgrade`'"
                }
                continue
            }

            # Create a thread to upgrade VMTools for each virtual machine
            $PSThread = [powershell]::Create()
            $PSThread.RunspacePool = $RunspacePool

            # Script content to upgrade VMTools
            $PSThread.AddScript({
                Param (
                    $vcServer,
                    $session,
                    $vmId,
                    $GuestOSType
                )
                # Load PowerCLI module and connect to VCServer, as child thread environment is independent with parent
                if(-not $global:DefaultVIServer) {
                    $moduleName = "vmware.vimautomation.core"
                    if(-not (Get-Module | Where-Object {$_.name -eq $moduleName})) {
                        try {
                            Import-Module $moduleName -ErrorAction SilentlyContinue | Out-Null
                        }
                        catch {
                            Throw "Failed to load PowerCLI module('$moduleName')"
                        }
                    }
                    try {
                        $server = Connect-VIServer -Server $vcserver -session $session -Force
                    }
                    catch {
                        Throw "Failed to connect to VI server: $vcserver"
                    }
                }

                # Retrieves VM
                $vm = Get-VM -Id $vmId

                $ThreadID = [appdomain]::GetCurrentThreadId()
                Write-Verbose “Thread[$ThreadID]: Beginning Update-Tools for $vm”

                if ($vm.PowerState -ne 'PoweredOn') {
                    Write-Host "Powering on VM: $vm..."
                    Start-VM $vm | Out-Null
                    $vm = Get-VM $vm
                }

                # Wait for OS and VMTools starting up
                $timeOut = 60*10 #seconds
                $refreshInterval = 5 #seconds
                $count = $timeOut/$refreshInterval
                while (($vm.Guest.ExtensionData.ToolsRunningStatus -ne "guestToolsRunning") `
                                                            -or (-not $vm.Guest.GuestFamily)) {
                    $count -= 1
                    if ($count -lt 0) {
                        Write-Error "VMTools doesn't start up in $timeOut seconds, please check if $vm is hung!"
                        break
                    }
                    Write-Verbose "Waiting for VMTools running in $vm before upgrading..."
                    Start-Sleep -Seconds $refreshInterval
                }

                # Skip if virtual machine doesn't meet specified guest OS type
                if ($GuestOSType -and ($vm.Guest.GuestFamily -notmatch $GuestOSType)) {
                    Write-Host "GuestFamily of $vm is: $($vm.Guest.GuestFamily),"`
                             "does not meet condition `'$GuestOSType`', skipping it..." -ForegroundColor Yellow
                    # upgrade result
                    [pscustomobject]@{
                        VmName = $vm.Name
                        UpgradeResult = "Skipped"
                        ToolsVersion = $vm.Guest.ToolsVersion
                        ToolsVersionStatus = $vm.Guest.ExtensionData.ToolsVersionStatus
                        TotalSeconds = 0
                        Message = "Guest OS type does not meet condtion `'$GuestOSType`'"
                    }
                    Disconnect-VIServer $server -Confirm:$false
                    return
                }

                # Upgrade VMTools and check the tools version status
                Write-Host "Upgrading VMTools for VM: $vm..."
                $task = Update-Tools -VM $vm -RunAsync
                $task | Wait-Task
                $task = Get-Task -Id $task.Id

                if ($task.State -eq "Success") {
                    $upgradeResult = "Completed"
                    $message = "Upgrade VMTools successfully"
                    Write-Host "Upgrade VMTools successfully for VM: $vm" -ForegroundColor Green
                } else {
                    $upgradeResult = "Failed"
                    $message = $task.ExtensionData.Info.Error.LocalizedMessage
                    Write-Error "Failed to upgrade VMTools for VM: $vm"
                }
                $vm = Get-VM $vm
                # Upgrade result to return
                [pscustomobject]@{
                    VmName = $vm.Name
                    UpgradeResult = $upgradeResult
                    ToolsVersion = $vm.Guest.ToolsVersion
                    ToolsVersionStatus = $vm.Guest.ExtensionData.ToolsVersionStatus
                    TotalSeconds = [math]::Floor(($task.FinishTime).Subtract($task.StartTime).TotalSeconds)
                    Message = $message
                }
                Write-Verbose “Thread[$ThreadID]: Ending Update-Tools for $vm”
            })  | Out-Null
            $vc = $Global:DefaultVIServer.ServiceUri.Host
            $vcSession = $Global:DefaultVIServer.SessionSecret
            $PSThread.AddArgument($vc).AddArgument($vcSession).AddArgument($_.Id).AddArgument($GuestOSType) | Out-Null

            # Start thread
            $Handle = $PSThread.BeginInvoke()
            $job = New-Object System.Object
            $job | Add-Member -type NoteProperty -name Thread   -value  $PSThread
            $job | Add-Member -type NoteProperty -name Handle   -value  $Handle
            $jobs.Add($job) | Out-Null

            Write-Verbose (“Available Runspaces in RunspacePool: {0}” -f $RunspacePool.GetAvailableRunspaces())
        }
    }

    End {
        #Verify all threads completed
        while (($jobs | Where-Object {$_.Handle.iscompleted -ne "Completed"}).Count -gt 0) {
            Start-Sleep -Seconds 5
        }

        $upgradeResult = $jobs | foreach {
            $_.Thread.EndInvoke($_.Handle)
            $_.Thread.Dispose()
        }
        $result += $upgradeResult
        $result

        $RunspacePool.Close()
        $RunspacePool.Dispose()
    }
}

Export-ModuleMember *-*
