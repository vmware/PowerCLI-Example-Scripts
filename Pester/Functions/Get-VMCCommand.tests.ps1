#Requires -Modules Pester, VMware.VMC, VMware.VimAutomation.Vmc


inModuleScope VMware.VMC {
    $functionName = "Get-VMCCommand"
    Describe "$functionName" -Tag 'Unit' {
        Mock Get-Command {
            "Mocked Command Response"
        }

        Context "Behavior testing" {
            It "should call get-command on VMware.VimAutomation.Vmc" {
                { Get-VMCCommand } | Should Not Throw
                Assert-MockCalled -CommandName Get-command -Times 1 -Scope It -ParameterFilter { $Module -eq 'VMware.VimAutomation.Vmc' }

            }
            It "should call get-command on VMware.Vmc" {
                { Get-VMCCommand } | Should Not Throw
                Assert-MockCalled -CommandName Get-command -Times 1 -Scope It -ParameterFilter { $Module -eq 'VMware.VMC' }
            }
        }
    }
}