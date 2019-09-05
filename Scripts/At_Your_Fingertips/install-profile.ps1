[cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    #        [Parameter(Mandatory = $true)]
    [ValidateSet('CurrentUserCurrentHost', 'CurrentUserAllHosts',
        'AllUsersCurrentHost', 'AllUsersAllHosts')]
    [string]$Scope,
    [switch]$NoClobber,
    [switch]$Backup,
    [string]$NewProfile = '.\NewProfile.ps1'
)

if ($PSCmdlet.ShouldProcess("$($Profile.$Scope)", "Create $Scope profile"))
{
    $profilePath = $Profile."$Scope"
    Write-Verbose -Message "Target is $profilePath"
    $createProfile = $true
    if (Test-Path -Path $profilePath)
    {
        Write-Verbose -Message "Target exists"
        if ($NoClobber)
        {
            Write-Verbose -Message "Cannot overwrite target due to NoClobber"
            $createProfile = $false
        }
        elseif ($Backup)
        {
            Write-Verbose -Message "Create a backup as $profilePath.bak"
            Copy-Item -Path $profilePath -Destination "$profilePath.bak" -Confirm:$false -Force
        }
        elseif (-not $NoClobber)
        {
            Write-Verbose -Message "Target will be overwritten"
        }
        else
        {
            Write-Verbose -Message "Use -NoClobber:$false or -Backup"
        }
    }
    if ($createProfile)
    {
        if (-not $NewProfile)
        {
            $script:MyInvocation.MyCommand | select *
            $folder = Split-Path -Parent -Path $script:MyInvocation.MyCommand.Path
            $folder = Get-Location
            $NewProfile = "$folder\NewProfile.ps1"
        }
        Write-Verbose -Message "New profile expected at $NewProfile"
        if (Test-Path -Path $NewProfile)
        {
            Write-Verbose -Message "Copy $NewProfile to $profilePath"
            Copy-Item -Path $NewProfile -Destination $profilePath -Confirm:$false
        }
        else
        {
            Write-Warning -Message "Could not find the new profile file!"
            Write-Warning -Message "Use the NewProfile parameter or store a NewProfile.ps1 file in folder $folder."
        }
    }
}