#
# Provide environment information in the PS Console
#
# History:
# 1.0 - August 4th 2019 - LucD
#       Initial version (for session HBI1729BU VMworld US 2019)
# 2.0 - September 9th 2019 - virtualex
#       Added PowerShell-Core compatibility
#
# 1) PS prompt
# - current (local) time
# - execution time of the previous command
# - shortened PWD
# 2) Window title
# - User/Admin
# - PS-32/64-Edition-Version
# - PCLI version
# - git repo/branch
# - VC/ESXi:defaultServer-User [# connections]

function prompt
{
    # Current time
    $date = (Get-Date).ToString('HH:mm:ss')
    Write-Host -Object '[' -NoNewLine
    Write-Host -Object $date -ForegroundColor Cyan -BackgroundColor DarkBlue -NoNewline
    Write-Host -Object ']' -NoNewLine

    # Execution time previous command
    $history = Get-History -ErrorAction Ignore -Count 1
    if ($history)
    {
        $time = ([DateTime](New-TimeSpan -Start $history.StartExecutionTime -End $history.EndExecutionTime).Ticks).ToString('HH:mm:ss.ffff')
        Write-Host -Object '[' -NoNewLine
        Write-Host -Object "$time" -ForegroundColor Yellow -BackgroundColor DarkBlue -NoNewLine
        Write-Host -Object '] ' -NoNewLine
    }

    # Shortened PWD
    $path = $pwd.Path.Split('\')
    if ($path.Count -gt 3)
    {
        $path = $path[0], '..', $path[-2], $path[-1]
    }
    Write-Host -Object "$($path -join '\')" -NoNewLine

    # Prompt function needs to return something,
    # otherwise the default 'PS>' will be added
    "> "

    # Refresh the window's title
    Set-Title
}

function Set-Title
{
    # Running as Administrator or a regular user
    If (($PSEdition -eq 'Core') -and ($IsWindows -eq 'True') -or ($PSEdition -ine 'Core'))
    { 
        $userInfo = [Security.Principal.WindowsIdentity]::GetCurrent()
        if ((New-Object Security.Principal.WindowsPrincipal $userInfo).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
        {
            $role = 'Admin'
        }
        else
        {
            $role = 'User'
        }
    }

    # Usertype user@hostname
    If (($PSEdition -eq 'Core') -and ($IsWindows -ine 'True')) {
        $env:computername = hostname
        $user = "$($env:user)@$($env:computername)"
    }
    Else {
    $user = "$role $($userInfo.Name)@$($env:computername)"
    }

    # PowerShell environment/PS version
    $bits = 32
    if ([Environment]::Is64BitProcess)
    {
        $bits = 64
    }
    $ps = " - PS-$($bits): $PSEdition/$($PSVersionTable.PSVersion.ToString())"

    # PowerCLI version (derived from module VMware.PowerCLI)
    $pcliModule = Get-Module -Name VMware.PowerCLI -ListAvailable |
    Sort-Object -Property Version -Descending |
    Select-Object -First 1
	$pcli = " - PCLI: $(if($pcliModule){$pcliModule.Version.ToString()}else{'na'})"

    # If git is present and if in a git controlled folder, display repositoryname/current_branch
    $gitStr = ''
    if ((Get-Command -Name 'git' -CommandType Application -ErrorAction SilentlyContinue).Count -gt 0)
    {
        $gitTopLevel = & { git rev-parse --show-toplevel 2> $null }
        if ($gitTopLevel.Length -ne 0)
        {
            $gitRepo = Split-Path -Path $gitTopLevel -Leaf
            $gitBranch = (git branch | Where-Object { $_ -match "\*" }).Trimstart('* ')
            $gitStr = " - git: $gitRepo/$gitBranch"
        }
    }

    # If there is an open vSphere Server connection
    # display [VC|ESXi] last_connected_server-connected_user [number of open server connections]
    if ($global:defaultviserver)
    {
        $vcObj = (Get-Variable -Scope global -Name 'DefaultVIServer').Value
        if ($vcObj.ProductLine -eq 'vpx')
        {
            $vcSrv = 'VC'
        }
        else
        {
            $vcSrv = 'ESXi'
        }
        $vc = " - $($vcSrv): $($vcObj.Name)-$($vcObj.User) [$($global:DefaultVIServers.Count)]"
    }

    # Update the Window's title
    $host.ui.RawUI.WindowTitle = "$user$ps$pcli$vc$gitStr"
}

# Set title after starting session
Set-Title
