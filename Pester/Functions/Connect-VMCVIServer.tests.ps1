#Requires -Modules Pester, VMware.VMC

inModuleScope VMware.VMC {
    $functionName = "Connect-VMCVIServer"
    Describe "$functionName" -Tag 'Unit' {
        . "$PSScriptRoot/Shared.ps1"

        $Org = 'MyOrg'
        $Sddc = 'MySddc'
        
        $global:DefaultVMCServers = $true

        $secpasswd = ConvertTo-SecureString "password" -AsPlainText -Force
        $Mockedcreds = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)
        $cloud_username = "MockedUserName"
        $vc_public_ip = "MockedServer"

        Mock Get-VMCSDDCDefaultCredential {
            $object = [PSCustomObject] @{
                'vc_public_ip'  = $vc_public_ip
                'cloud_username' = $cloud_username
                'cloud_password' = $Mockedcreds.Password
            }
            return $object
        }

        Mock Write-host {}

        Mock Connect-VIServer {}

        Mock Connect-CisServer {}

        Mock Write-Error

        Context "Sanity checking" {
            $command = Get-Command -Name $functionName

            defParam $command 'Org'
            defParam $command 'Sddc'
            defParam $command 'Autologin'
        }

        Context "Behavior testing" {
            It "gets creds via Get-VMCSDDCDefaultCredential" {
                { Connect-VMCVIServer -org $Org -Sddc $Sddc  } | Should Not Throw
                Assert-MockCalled -CommandName Get-VMCSDDCDefaultCredential -Times 1 -Scope It -ParameterFilter { $org -eq $Org -and $Sddc -eq $Sddc  }
            }
            It "calls the Connect-VIServer" {
                { Connect-VMCVIServer -org $Org -Sddc $Sddc } | Should Not Throw
                Assert-MockCalled -CommandName Connect-VIServer -Times 1 -Scope It -ParameterFilter { `
                                                                                $Server -eq $vc_public_ip `
                                                                                -and $User -eq $cloud_username `
                                                                                -and $Password -eq $Mockedcreds.Password }
            }
            It "calls the Connect-CisServer" {
                { Connect-VMCVIServer -org $Org -Sddc $Sddc } | Should Not Throw
                Assert-MockCalled -CommandName Connect-CisServer -Times 1 -Scope It -ParameterFilter { `
                                                                                $Server -eq $vc_public_ip `
                                                                                -and $User -eq $cloud_username `
                                                                                -and $Password -eq $Mockedcreds.password }
            }
            It "gets writes an error if not connected" {
                $global:DefaultVMCServers = $false
                { Connect-VMCVIServer -org $Org -Sddc $Sddc  } | Should Not Throw
                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It -ParameterFilter { $org -eq $Org -and $Sddc -eq $Sddc  }
            }
        }
    }
}