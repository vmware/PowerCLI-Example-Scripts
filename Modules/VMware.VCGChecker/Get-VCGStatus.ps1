$Uuid = [guid]::NewGuid()
$Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$Headers.add("x-request-id", $Uuid)
$Headers.add("x-api-toolid", "180209100001")
$Headers.add("x-api-key", "SJyb8QjK2L")
$Url_Perfix = 'https://apigw.vmware.com/m4/compatibility/v1'
$Url = $Url_Perfix + "/compatible/servers/search?"
$UrlPci = $Url_Perfix + "/compatible/iodevices/search?"
$apiQurryDict=@{}

#
# Ping remote api server.
#
Function PingApiServer(){
    $apiServerIp='apigw.vmware.com'
    $results =Test-Connection $apiServerIp -Quiet
    if($results -ne $true){
        error ("Failed to access VMware Compatibility API,
        Unable to use comparison function, only view basic hardware information;
        you can use 'Get-VCGHWInfo -g <fileName>' create hardware json,
        then use 'Check-VCGStatus -f <fileName>' load hardware json file to comapre  when connect an available network")
        Exit(1)
    }
}

#
# Get the web request.
#
Function Get-WebRequest($VCGurl) {
    try {
        $req = Invoke-WebRequest -Headers $Headers -Uri $VCGUrl -ErrorVariable $err -UseBasicParsing
    }
    catch {
        if ($err[0].errorrecord.exception.response) {
            error ("WebReponse code:" + $err[0].errorrecord.exception.response.statuscode.value__)
            error ($exitScript)
            Exit(1)
        }
        else {
            error ("Failed to check " + $type + " data for " + $HostResource.hostname)
            error ("Failed to access VMware Compatibility API, please check your Internet connection or contact VMware Compatibility API administrator")
            error ("Exit the script")
            Exit(1)
        }
    }
    return $req
}

Function Get-RemoteApiTitleString([object]$device,$EsxiVersion){
    if ($device.type -eq 'Server') {
        $Title = $device.model + $device.vendor + $device.cpufeatureid + $device.biosversion +$EsxiVersion
    }
    else{
        $Title = $device.vid +  $device.did + $device.Svid + $device.Ssid + $EsxiVersion
    }
    return $Title
}

Function Get-ResponseFromApi([object]$device,$EsxiVersion){
    if ($device.type -eq 'Server') {
        $VCGUrl = $Url + "model=" + $device.model + "&releaseversion=" + $EsxiVersion `
            + "&vendor=" + $device.vendor + "&cpuFeatureId=" + $device.cpufeatureid `
            + "&bios=" + $device.biosversion
        debug ("Model:" + $device.model)
        debug ("VCG Url:" + $VCGUrl)
        $Headers.GetEnumerator() | ForEach-Object {debug ("Req Header:" + $_.key + ":" + $_.value)}
        $request = Get-WebRequest $VCGUrl
        $Response = ConvertFrom-Json -InputObject $request -Erroraction 'silentlycontinue'
    }
    elseif ($device.type -eq 'IO Device') {
        $VCGUrl = $UrlPci + "vid=0X" + $device.vid + "&did=0X" + $device.did + "&svid=0X" + $device.Svid `
            + "&ssid=0X" + $device.Ssid + "&releaseversion=" + $EsxiVersion `
            + "&driver=" + $device.Driver + "&driverversion=" + $device.driverversion + "&firmware=N/A"
        debug ("Model:" + $device.model)
        debug ("VCG Url:" + $VCGUrl)
        $Headers.GetEnumerator() | ForEach-Object {debug ("Req Header:" + $_.key + ":" + $_.value)}
        $request = Get-WebRequest $VCGUrl
        $Response = ConvertFrom-Json -InputObject $request -Erroraction 'silentlycontinue'
    }
    return $Response
}
#
# Get the data from api
#
Function Get-VCGData($HostResource) {
    foreach ($device in $HostResource.ComponentResource) {
        if ($HostResource.checkRelease) {
            $EsxiVersion = $HostResource.checkRelease
        }
        else {
            $EsxiVersion = $HostResource.version
        }
        $temp=0
        $title=Get-RemoteApiTitleString $device $EsxiVersion
        if($apiQurryDict.Count -eq 0){
            $Response= Get-ResponseFromApi $device $EsxiVersion
            $apiQurryDict.Add($title,$Response)
        }else{
            foreach($onetitle in $apiQurryDict.keys){
                if($onetitle -eq $title){
                    $Response= $apiQurryDict[$onetitle]
                    $temp=1
                    break
                }
            }
            if($temp -eq 0){
                $Response= Get-ResponseFromApi $device $EsxiVersion
                $apiQurryDict.Add($title,$Response)
            }
        }

        if ($Response.matches) {
            foreach ($match in $Response.matches) {
                $device.vcgLink += [string]$match.vcgLink
            }
        }
        else {
            foreach ($potentialMatche in $Response.potentialMatches) {
                $device.vcgLink += [string]$potentialMatche.vcgLink
            }
        }
        $device.status = [string]$Response.searchResult.status
        $device.matchResult = [string]$Response.searchResult.matchResult
        $device.warnings = $Response.searchResult.warnings
        $device.updateRelease = [string]$Response.searchOption.foundRelease
    }
}

#
# Send the hardware data to VCG API and handle returned result
#
Function Get-DataFromRemoteApi([object]$servers) {
    info ("Checking hardware compatibility result with VMware Compatibility Guide API...")
    info ("This may take a few minutes depending on your network.")
    for ($idx = 0; $idx -lt $servers.Count; $idx++) {
        $server = $servers[$idx]
        $i = $idx + 1
        info ([string]$i + "/" + [string]$servers.Count + " - Checking hardware compatibility results for " + $server.hostname)
        if (!$server -or $server.ComponentResource.Count -eq 0) {
            error('Failed to get the hardware info.')
            Exit(1)
        }
        Get-VCGData $server
    }
    return $servers
}

Function Get-VCGStatus{
    Param(
        [Parameter(Mandatory=$true)]  $Data,
        [Parameter(Mandatory=$false)] $Version
    )
    $checkRelease = $Version
    PingApiServer

    foreach ($vmHost in $Data) {
        # $vmHost|add-member -Name "checkRelease" -value $checkRelease -MemberType NoteProperty -Force
        $vmHost.checkRelease=$checkRelease
    }

    $results = Get-DataFromRemoteApi($Data)
    if ($results.Count -eq 0) {
        error ("Failed to get compatibility results. No report will be generated")
        error ("Exit the script")
        Exit(1)
    }
    return $results
}