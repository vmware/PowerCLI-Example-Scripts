Function Save-VCGJsonFile{
    Param(
        [Parameter(Mandatory=$true)] $FileName,
        [Parameter(Mandatory=$true)] $Data,
        [Parameter(Mandatory=$true)] $Dir
    )
    $json = @()
    $Data | ForEach-Object { $json += $_.to_jsonobj()}

    if (!(Test-Path $Dir)) {
       New-Item -Type directory -Confirm:$false -Path $Dir -Force |Out-Null
    }

    $Path= $Dir + '\' + $FileName + '.json'
    info ("Saving data to " + $Path)
    ConvertTo-Json -Depth 10 -Compress $json | Out-File -encoding 'UTF8' -FilePath $Path
}