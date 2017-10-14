<#
Script name: get-peakvms.ps1
Created on: 09/06/2016
Author: Scott White, @soggychipsnz, https://github.com/LatexGolem
Description: This script will interrogate vcenter to find the peak users of network or storage usage. 
This was quite handy for me to quickly identify the source of issues such as an inbound DDOS, outbound DOS or a server pummiling storage due to swapping/etc.
I would suggest that when you first run the script you run it in host mode, which will identify where the hotspot is. Then once the hot host has been identified, run it in VM mode.
For each statistic the number of operations/packets is collectioned along ith the throughput split into reads or writes/sent or recieved - giving you peak and 95th percentiles
Really need to get around to tidying this up :)
Results will be outputted to OGV and into a timestamped CSV in the current working directory
Dependencies: Nothing special. Assumes vsphere logging has 20 second samples for the last 60 minutes and 5 minute samples in the past 24 hours.
#>

$clusterfilter = "*"

#Gather basic stuff
do{
	$modes =  @("host","vm")
	$mode = $modes | OGV -PassThru -Title "Select mode of operation"
	$stats = @("Disk Throughput","Network Throughput")
	$stat = $stats | OGV -PassThru -Title  "Select type of Stat to check"
	if (($mode.count -eq 2) -or ($stat.count -eq 2) ){write-host "Please select only a single mode of operation and statistic type."}
}while ($mode.count -eq 2 -and $stat.count -eq 2)

$hour = 1..24
$hour = $hour | OGV -PassThru -Title "Select number of hours to go back in time"


#Helper Stuff
$start = (Get-Date).addHours(-$hour)
$finish = (Get-Date)
$duration = $finish - $start | %{[int]$_.TotalSeconds}
#If Start is within the last hour, use 20 second sampling otherwise 5 minute avg 
if (((Get-Date) - $start ).TotalSeconds -gt 3700) {$interval=300} else {$interval=20}

function getstats($starttime,$endtime,$sample,$stat,$entity){
	(Get-Stat -Entity $entity -Stat $stat -IntervalSecs $sample -Start $starttime -Finish $endtime).value | measure -Sum | %{$_.sum}
}


if ($mode -eq "host"){
	$clusters = get-cluster $clusterfilter
	$vmhosts = $clusters | OGV -PassThru -Title "Select Cluster(s) to target, to get all member Hosts"| get-vmhost
	
	if ($stat -eq "Network Throughput"){
		$master = @()
		$vmhosts | %{
			$metric ="net.packetsRx.summation"
			$pktrx = getstats $start $finish $interval $metric $_

			$metric ="net.packetsTx.summation"
			$pkttx = getstats $start $finish $interval $metric $_

			$metric ="net.bytesRx.average"
			$bytesrx = getstats $start $finish $interval $metric $_

			$metric ="net.bytesTx.average"
			$bytestx = getstats $start $finish $interval $metric $_

			$row = "" | select name,pktrx,pkttx,bytesrx,bytestx
			$row.name = $_.name
			$row.pktrx = $pktrx
			$row.pkttx = $pkttx
			$row.bytesrx = $bytesrx
			$row.bytestx = $bytestx
			$master += $row
			}
		$master | ogv #sort -Property name | Format-Table  
	}
	if ($stat -eq "Disk Throughput"){
		#Target the datastore, just one.
		$datastore = Get-Datastore -vmhost $vmhost[0]| OGV -PassThru -Title "Select target datastore"
		#Yes this is fugly.
		$instance = ($datastore | Get-View).Info.Url.Split("/") | select -last 2 | select -First 1

		$master = @()
		$vmhosts | %{
			$metric ="datastore.datastoreReadIops.latest"
			$rop = (Get-Stat -Entity $_ -Stat $metric -IntervalSecs $interval -Start $start -Finish $finish | ?{$_.Instance -match $instance}).value | measure -Sum | %{$_.sum}

			$metric ="datastore.datastoreWriteIops.latest"
			$wrop = (Get-Stat -Entity $_ -Stat $metric -IntervalSecs $interval -Start $start -Finish $finish | ?{$_.Instance -match $instance}).value | measure -Sum | %{$_.sum}

			$metric ="datastore.datastoreReadBytes.latest"
			$rbytes = (Get-Stat -Entity $_ -Stat $metric -IntervalSecs $interval -Start $start -Finish $finish | ?{$_.Instance -match $instance}).value | measure -Sum | %{$_.sum}

			$metric ="datastore.datastoreWriteBytes.latest"
			$wrbytes = (Get-Stat -Entity $_ -Stat $metric -IntervalSecs $interval -Start $start -Finish $finish | ?{$_.Instance -match $instance}).value | measure -Sum | %{$_.sum}

			$row = "" | select name,rop,wrop,rbytes,wrbytes
			$row.name = $_.name
			$row.rop = $rop
			$row.wrop = $wrop
			$row.rbytes = $rbytes
			$row.wrbytes = $wrbytes
			$master += $row
			}
		$master | ogv 
	}

}if ($mode -eq "vm"){
	Write-Host "Do note doing things on a vmbasis take quite some time (please isolate on a host basis first)"
	#Currently only works on a cluster basis
	$clusters = get-cluster $clusterfilter
	$vms = $clusters |get-vmhost | OGV -PassThru -Title "Select Hosts(s) to target, to get all member VMs"| get-vm  | ?{$_.powerstate -match "poweredOn"}
	
	if ($stat -eq "Network Throughput"){
		$master = new-object system.collections.arraylist
		$vms | %{
			$metric ="net.packetsRx.summation"
			$pktrx = getstats $start $finish $interval $metric $_

			$metric ="net.packetsTx.summation"
			$pkttx = getstats $start $finish $interval $metric $_

			$metric ="net.bytesRx.average"
			$bytesrx = getstats $start $finish $interval $metric $_

			$metric ="net.bytesTx.average"
			$bytestx = getstats $start $finish $interval $metric $_

			$row = "" | select name,pktrx,pkttx,bytesrx,bytestx
			$row.name = $_.name
			$row.pktrx = $pktrx
			$row.pkttx = $pkttx
			$row.bytesrx = $bytesrx
			$row.bytestx = $bytestx
			$master += $row
			}
		$master | ogv
		}
	if ($stat -eq "Disk Throughput"){
		$master = new-object system.collections.arraylist

		$vms = $vms |?{$_.PowerState -eq "PoweredOn"}
        foreach ($vm in $vms){
			$row = ""| select name,iops,riops,riops95,rpeak,wiops,wiops95,wpeak,throughputGBpduration,wMBps,rMBps,datastore,used,prov,iops95

			$metric = "datastore.numberReadAveraged.average"
			$rawdata = Get-Stat -Entity $vm -Stat $metric -IntervalSecs $interval -Start $start -Finish $finish
			$tmp = $rawdata.value | measure -average -Maximum 
			$row.riops = [int] $tmp.average
			$row.rpeak = [int] $tmp.Maximum
			$row.riops95 = ($rawdata.value | sort)[[math]::Round(($rawdata.count-1) * .95)]
			
			$metric = "datastore.numberwriteaveraged.average"
			$rawdata = Get-Stat -Entity $vm -Stat $metric -IntervalSecs $interval -Start $start -Finish $finish
			$tmp = $rawdata.value | measure -average -Maximum
			$row.wiops = [int] $tmp.average
			$row.wpeak = [int] $tmp.Maximum
			$row.wiops95 = ($rawdata.value | sort)[[math]::Round(($rawdata.count-1) * .95)]
			
			$row.iops = ($row.wiops + $row.riops)
			
			$metric = "datastore.write.average"
			$rawdatawr = Get-Stat -Entity $vm -Stat $metric -IntervalSecs $interval -Start $start -Finish $finish
			
			$metric = "datastore.read.average"
			$rawdatar = Get-Stat -Entity $vm -Stat $metric -IntervalSecs $interval -Start $start -Finish $finish
			$reads = $rawdatar.value | measure -Sum  | %{$_.sum}| %{$_ /($duration/$interval)/1024/1024}
			$writes = $rawdatawr.value | measure -Sum  | %{$_.sum}| %{$_ /($duration/$interval)/1024/1024}
			$total = $reads * $duration + $writes * $duration
			
			
			$row.name = $vm.name
			$row.throughputGBpduration =  [decimal]::round($total,2)
			$row.wMBps =  [decimal]::round($writes*1024,2)
			$row.rMBps =  [decimal]::round($reads*1024,2)
			$row.datastore = ($vm.DatastoreIdList[0] | Get-VIObjectByVIView).name #(($vm.DatastoreIdList| select -First 1 | Get-VIObjectByVIView).Name)
			
            $row.used = [System.Math]::Round(($vm.UsedSpaceGB))
            $row.prov = [System.Math]::Round(($vm.ProvisionedSpaceGB))
			$row.iops95 = $row.riops95 + $row.wiops95

			$master += $row
			}
	$master | ogv
		}

}
$master | Export-Csv "$mode$stat-$(get-date -Format HHmm).csv"
