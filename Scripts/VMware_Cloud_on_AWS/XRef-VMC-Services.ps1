$refreshToken = 'your-refresh-token'

$reportPath = '.\VMC-services.xlsx'

Connect-Vmc -RefreshToken $refreshToken > $null

$columns = @{}
$services = Get-VmcService |  Sort-Object -Property Name
$services | ForEach-Object -Process {
    $_.Help | Get-Member -MemberType NoteProperty | where{'Constants','Documentation' -notcontains $_.Name} |
    ForEach-Object -Process {
        if(-not $columns.ContainsKey($_.Name)){
            $columns.Add($_.Name,'')
        }
    }
}
$columns = $columns.Keys | Sort-Object
$report = @()
foreach($service in $services){
    $obj = [ordered]@{
        Name = $service.Name
    }
    $columns | ForEach-Object -Process {
        $obj.Add($_,'')
    }

    $service.Help | Get-Member -MemberType NoteProperty | where{'Constants','Documentation' -notcontains $_.Name} |
    ForEach-Object -Process {
#        $obj.Item($_.Name) = "$($service.Help.$($_.Name).Documentation)"
        $obj.Item($_.Name) = "X"
    }
    $report += New-Object PSObject -Property $obj
}
$report | Export-Excel -Path $reportPath -WorksheetName 'Services' -FreezeTopRow -BoldTopRow -AutoSize -Show

Disconnect-Vmc -Confirm:$false

