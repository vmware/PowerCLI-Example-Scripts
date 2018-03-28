$moduleRoot = Resolve-Path "$PSScriptRoot\.."
$moduleName = "VMware-vCD-Module"
$ConfigFile = "$moduleRoot\examples\OnBoarding.json"

Describe "General project validation: $moduleName" {

    $scripts = Get-ChildItem $moduleRoot -Include *.ps1, *.psm1, *.psd1 -Recurse

    # TestCases are splatted to the script so we need hashtables
    $testCase = $scripts | Foreach-Object {@{file = $_}}
    It "Script <file> should be valid powershell" -TestCases $testCase {
        param($file)

        $file.fullname | Should Exist

        $contents = Get-Content -Path $file.fullname -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
        $errors.Count | Should Be 0
    }

    It "Module '$moduleName' prerequirements are met" {
        {Import-Module VMware.VimAutomation.Cloud -Force} | Should Not Throw
    }

    It "Module '$moduleName' can import cleanly" {
        {Import-Module (Join-Path $moduleRoot "$moduleName.psd1") -force } | Should Not Throw
    }

    It "Module '$moduleName' JSON example is valid" {
        {Get-Content -Raw -Path $ConfigFile | ConvertFrom-Json} | Should Not Throw
    }


}
