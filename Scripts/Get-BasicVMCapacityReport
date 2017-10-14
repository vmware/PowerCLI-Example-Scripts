
$myCol = @()
$start = (Get-Date).AddDays(-30)
$finish = Get-Date
$cluster= "Demo"

$objServers = Get-Cluster $cluster | Get-VM
foreach ($server in $objServers) {
    if ($server.guest.osfullname -ne $NULL){
        if ($server.guest.osfullname.contains("Windows")){
            $stats = get-stat -Entity $server -Stat "cpu.usage.average","mem.usage.average" -Start $start -Finish $finish

            $ServerInfo = "" | Select-Object vName, OS, Mem, AvgMem, MaxMem, CPU, AvgCPU, MaxCPU, pDisk, Host
            $ServerInfo.vName  = $server.name
            $ServerInfo.OS     = $server.guest.osfullname
            $ServerInfo.Host   = $server.vmhost.name
            $ServerInfo.Mem    = $server.memoryGB
            $ServerInfo.AvgMem = $("{0:N2}" -f ($stats | Where-Object {$_.MetricId -eq "mem.usage.average"} | Measure-Object -Property Value -Average).Average)
            $ServerInfo.MaxMem = $("{0:N2}" -f ($stats | Where-Object {$_.MetricId -eq "mem.usage.average"} | Measure-Object -Property Value -Maximum).Maximum)
            $ServerInfo.CPU    = $server.numcpu
            $ServerInfo.AvgCPU = $("{0:N2}" -f ($stats | Where-Object {$_.MetricId -eq "cpu.usage.average"} | Measure-Object -Property Value -Average).Average)
            $ServerInfo.MaxCPU = $("{0:N2}" -f ($stats | Where-Object {$_.MetricId -eq "cpu.usage.average"} | Measure-Object -Property Value -Maximum).Maximum)
            $ServerInfo.pDisk  = [Math]::Round($server.ProvisionedSpaceGB,2)

            $mycol += $ServerInfo
        }
    }
}

$myCol | Sort-Object vName | Export-Csv "VM_report.csv" -NoTypeInformation
