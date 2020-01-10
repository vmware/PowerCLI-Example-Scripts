#
# Generate the html report and save it to the report folder
# TODO: change to the class
Function Export-VCGReport {
    Param(
        [Parameter(Mandatory=$true)] $Data,
        [Parameter(Mandatory=$true)] $Dir
    )
    if (!(Test-Path $Dir)) {
        New-Item -Type directory -Confirm:$false -Path $Dir -Force |Out-Null
    }

    $Data,$flag = refactorData $Data

    $null=Generate_CsvReport $Data $Dir
    $null=Generate_HtmlReport $Data $Dir
    $null=Generate_SummaryReport $Data $Dir
}
Function Generate_HtmlReport($Data, $Dir) {
    info ("Generating compatibility detail report...")
    $content = $generalHead
    $content += '<h1>ESXi Hardware Compatibility Report for {0}</h1>' -f $Data.hostname
    $content += $generalBodyBase
    if (-not(checkVersion($Data))) {
        $content += '<th>Installed Release</th>'
    }
    else {
        $content += '<th>Checked Release</th>'
    }
    $content += $generalBodyRest
    foreach ($VCResource in $Data) {
        $checkVersion = $VCResource.checkRelease
        $Count1 = $VCResource.DCResource.HostResource.ComponentResource.Count
        $Process = '<tr>'
        if ($VCResource.hostname -ne 'null') {
            $Process += '<td rowspan="{0}">{1}</td>' -f $Count1, [string]$VCResource.hostname
        }
        else {
            $Process += '<td rowspan="{0}">{1}</td>' -f $Count1, '/'
        }
        foreach ($DCResource in $VCResource.DCResource) {
            $Count2 = $DCResource.HostResource.ComponentResource.Count
            if ($DCResource.dcname -ne 'null') {
                $Process += '<td rowspan="{0}">{1}</td>' -f [string]$Count2, [string]$DCResource.dcname
            }
            else {
                $Process += '<td rowspan="{0}">{1}</td>' -f [string]$Count2, '/'
            }
            foreach ($HostResourceOne in $DCResource.HostResource) {
                $Count = $HostResourceOne.ComponentResource.count
                $Process += '<td rowspan="{0}">{1}</td>' -f $Count, $HostResourceOne.HostName
                foreach ($OneDevice in $HostResourceOne.ComponentResource) {
                    if ($OneDevice.type -eq 'Server') {
                        # $InfoServer = "" | Select HostName, Manufacturer, Model, CPU, Version, Bios, CpuFeature, Uuid, VcgLink, Status, FoundRelease, MatchResult, Warnings
                        $InfoServer = @{}
                        $InfoServer.HostName = $HostResourceOne.hostname
                        $InfoServer.Version = $HostResourceOne.version
                        $InfoServer.Manufacturer = $OneDevice.vendor
                        $InfoServer.Model = $OneDevice.model
                        $InfoServer.CPU = $OneDevice.cpumodel
                        $InfoServer.Bios = $OneDevice.biosversion
                        $InfoServer.CpuFeature = $OneDevice.cpufeatureid
                        $InfoServer.Uuid = $OneDevice.uuid
                        $InfoServer.VcgLink = $OneDevice.vcgLink
                        $InfoServer.Status = formatStatus($OneDevice.status)
                        $InfoServer.MatchResult = $OneDevice.matchResult
                        $InfoServer.Warnings = (([string]$OneDevice.warnings) -split "More information")[0]
                        # server info
                        $Process += '<td>Server</td>'
                        $Process += '<td>{0}</td>' -f $InfoServer.Model
                        $Process += '<td>{0}</td>' -f $InfoServer.Manufacturer
                        if (-not $checkVersion) {
                            $Process += '<td>{0}</td>' -f $InfoServer.Version
                        }
                        else {
                            $Process += '<td>{0}</td>' -f $checkVersion
                        }
                        $Process += '<td>{0}</td>' -f $InfoServer.Status
                        $Process += '<td>{0},<br>CpuFeature:{1},<br>Bios:{2}</td>' -f $InfoServer.CPU, $InfoServer.CpuFeature, $InfoServer.Bios
                        if ($InfoServer.VcgLink.Count -gt 0) {
                            $Process += '<td>{0}<br>' -f $InfoServer.Warnings
                            foreach ($link in $InfoServer.VcgLink) {
                                $Process += '<a href="{0}"target="_blank" > VCG link</a><br>' -f $link
                            }
                            $Process += '</td>'
                        }
                        else
                        {$Process += '<td>{0}<br>N/A</td>' -f $InfoServer.Warnings}
                        $Process += '</tr>'
                    }
                    else {
                        # $InfoPci = "" | Select model, vendor, Vid, Did, Svid, Ssid, Driver, DriverVersion, Version, Pccid, VcgLink, Status, FoundRelease, MatchResult, Warnings
                        $InfoPci = @{}
                        $InfoPci.model = $OneDevice.model
                        $InfoPci.vendor = $OneDevice.vendor
                        $InfoPci.Vid = $OneDevice.vid
                        $InfoPci.Did = $OneDevice.did
                        $InfoPci.Svid = $OneDevice.svid
                        $InfoPci.Ssid = $OneDevice.ssid
                        $InfoPci.Driver = $OneDevice.driver
                        $InfoPci.DriverVersion = $OneDevice.driverversion
                        $InfoPci.Version = $HostResourceOne.version
                        $InfoPci.Pccid = $OneDevice.pciid
                        $InfoPci.VcgLink = $OneDevice.vcgLink
                        $InfoPci.Status = formatStatus($OneDevice.status)
                        $InfoPci.MatchResult = $OneDevice.matchResult
                        $InfoPci.Warnings = (([string]$OneDevice.warnings) -split "More information")[0]
                        # IO info
                        # TODO:Variable information coverage, need to be modified
                        $Process += '<tr>'
                        $Process += '<td>IO Device</td>'
                        $Process += '<td>{0}</td>' -f $InfoPci.model
                        $Process += '<td>{0}</td>' -f $InfoPci.vendor
                        if (-not $checkVersion) {
                            $Process += '<td>{0}</td>' -f $InfoPci.Version
                        }
                        else {
                            $Process += '<td>{0}</td>' -f $checkVersion
                        }
                        $Process += '<td>{0}</td>' -f $InfoPci.Status
                        $Process += '<td>PCI ID:{0} <br>Driver:{1} Version:{2}</td>' -f $InfoPci.Pccid, $InfoPci.Driver, $InfoPci.DriverVersion
                        if ($InfoPci.VcgLink.Count -gt 0) {
                            $Process += '<td>{0}<br>' -f $InfoPci.Warnings
                            foreach ($link in $InfoPci.VcgLink) {
                                $Process += '<a href="{0}"target="_blank" > VCG link</a><br>' -f $link
                            }
                            $Process += '</td>'
                        }
                        else
                        {$Process += '<td>{0}<br>N/A</td>' -f $InfoPci.Warnings}
                        $Process += '</tr>'
                    }
                }
            }
        }
        $content += $Process
    }
    $content += $generalFooter
    #define filename and filepath
    $dataTime = Get-Date -Format 'yyyy-M-d_h-m'
    $vcName = vcName($Data)
    $filename = 'compreport_' + $vcName + $dataTime + '.html'
    $filePath = $Dir + '\' + $filename
    #save report
    $content |Out-File -FilePath $filePath -Encoding utf8| Out-Null
    info ("Report " + "'" + $filePath + "'" + " has been created!")
}

Function Generate_SummaryReport($Data, $Dir) {
    info ("Generating compatibility summary report...")
    $content = $summaryHead
    $vcCount = $Data.length
    $barsWidth = 45 / ($vcCount+1)
    $content += 'var barsWidth = {0};' -f $barsWidth
    # get vCName arry and host count
    $vcNameArray = @()
    foreach ($DCResource in $Data) {
        $vcNameArray += $DCResource.DCResource[0].vcname
    }

    $content += "var vCname = ["
    foreach ($vc in $vcNameArray) {
        $content += '"{0}",' -f $vc
    }
    $content += "];"
    # Count Compatible or unpgrade
    $compatibleCountFormat = '['
    $mayNotCompatibleCountFormat = '['
    $UnabletoUpgradeCountFormat = '['
    foreach ($VCResource in $Data) {
        $checkVersion = $VCResource.checkRelease
        $compatibleCount = 0
        $notcompatibleCount = 0
        $UnabletoUpgradeCount = 0
        foreach ($DCResource in $VCResource.DCResource) {
            foreach ($HostResourceOne in $DCResource.HostResource) {
                foreach ($OneDevice in $HostResourceOne.ComponentResource) {
                    $flagcompatible = 0
                    # if($checkVersion){
                    #     if(-not($OneDevice.upgrade)){
                    #         $flagcompatible = 'null'
                    #         break
                    #     }
                    # }
                    #whether compatible
                    if ($OneDevice.status -ne 'Compatible') {
                        $flagcompatible = 0
                        break
                    }
                    else {
                        $flagcompatible = 1
                    }
                    #whether upgrade
                }

                if ($flagcompatible -eq 1) {
                    $compatibleCount += 1
                }
                elseif($flagcompatible -eq 0){
                     $notcompatibleCount += 1
                }

                elseif($flagcompatible -eq 'null') {
                    $UnabletoUpgradeCount += 1
                }
            }
        }
        $compatibleCountFormat += $compatibleCount
        $compatibleCountFormat += ','
        $mayNotCompatibleCountFormat += $notcompatibleCount
        $mayNotCompatibleCountFormat += ','
        $UnabletoUpgradeCountFormat += $UnabletoUpgradeCount
        $UnabletoUpgradeCountFormat += ','
    }
    $compatibleCountFormat += ',]'
    $mayNotCompatibleCountFormat += ',]'
    $UnabletoUpgradeCountFormat += ']'

    $dataDict = [Ordered]@{}

    if (-not(checkVersion($Data))) {
        $content += 'var lengendSeries = ["Compatible","May Not Compatible"];'
        $content += $hostCountHead

        $dataDict.Insert(0, "Compatible", $compatibleCountFormat)
        $dataDict.Insert(1, "May Not Compatible", $mayNotCompatibleCountFormat)
    }
    else {
        $content += 'var lengendSeries = ["Compatible","May Not Compatible","Unable to upgrade"];'
        $content += $hostCountHead

        $dataDict.Insert(0, "Compatible", $compatibleCountFormat)
        $dataDict.Insert(1, "May Not Compatible", $mayNotCompatibleCountFormat)
        $dataDict.Insert(2, "Unable to upgrade", $UnabletoUpgradeCountFormat)
    }
    [System.Collections.IEnumerator]$dataDict = $dataDict.Keys.GetEnumerator();
    $formatContent = formatHostCountGraphic $dataDict

    $content += $formatContent
    $content += $hostCountRest


    # Host Compatibility
    $compatibleCount = 0
    $mayNotcompatibleCount = 0
    $unableUpgradeCount = 0
    foreach ($VCResource in $Data) {
        foreach ($DCResource in $VCResource.DCResource) {
            foreach ($HostResourceOne in $DCResource.HostResource) {
                foreach ($OneDevice in $HostResourceOne.ComponentResource) {
                    #whether compatible
                    $flagcompatible = 0
                    # if ($checkVersion){
                    #     if (-not($OneDevice.upgrade)){
                    #         $flagcompatible = 'null'
                    #         break
                    #     }
                    # }
                    if ($OneDevice.status -ne 'Compatible') {
                        $flagcompatible = 0
                        break
                    }
                    else {
                        $flagcompatible = 1
                    }

                }
                if ($flagcompatible -eq 1) {
                    $compatibleCount += 1
                }
                elseif ($flagcompatible -eq 0) {
                    $mayNotcompatibleCount += 1
                }
                elseif ($flagcompatible -eq 'null') {
                    $unableUpgradeCount += 1
                }
            }
        }
    }

    if (-not(checkVersion($Data))) {
        $content += "var seriesCount = {'Compatible':$compatibleCount, 'May Not Compatible':$mayNotcompatibleCount,};"
        $content += "var lengendSeries = ['Compatible','May Not Compatible'];"
        $content += "var catalog = [
			{value:seriesCount['Compatible'], name:'Compatible'},
			{value:seriesCount['May Not Compatible'], name:'May Not Compatible'},
		];"
        $content += "var colors = [colorsC,colorsM];"
    }
    else {
        $content += "var seriesCount = {'Compatible':$compatibleCount, 'May Not Compatible':$mayNotcompatibleCount,'Unable to Upgrade':$unableUpgradeCount};"
        $content += "var lengendSeries = ['Compatible','May Not Compatible','Unable to Upgrade'];"
        $content += "var catalog = [
			{value:seriesCount['Compatible'], name:'Compatible'},
			{value:seriesCount['May Not Compatible'], name:'May Not Compatible'},
			{value:seriesCount['Unable to Upgrade'], name:'Unable to Upgrade'},
		];"
        $content += "var colors = [colorsC,colorsM,colorsU];"
    }

    $content += $hostCompatible


    #Host Model Compatibility by vCenter
    if (-not(checkVersion($Data))) {
        $serverSource = "[['series', 'Compatible', 'May Not Compatible',],"
    }
    else {
        $serverSource = "[['series', 'Compatible','May Not compatible','No Upgrade Path'],"
    }

    foreach ($VCResource in $Data) {
        $compatibleCount = 0
        $mayNotCompatibleCount = 0
        $unableUpgradeCount = 0
        $checkVersion = $VCResource.checkRelease
        foreach ($DCResourceOne in $VCResource.DCResource) {
            foreach ($HostResourceOne in $DCResourceOne.HostResource) {
                $flagcompatible = 0
                foreach ($ComoenentResourceOne in $HostResourceOne.ComponentResource) {
                    #whether compatible
                    if ($ComoenentResourceOne.type -eq 'Server') {
                        # if ($checkVersion) {
                        #     if (-not($ComoenentResourceOne.upgrade)) {
                        #         $flagcompatible = 'null'
                        #         break
                        #     }
                        # }
                        if ($ComoenentResourceOne.status -ne 'Compatible') {
                            $flagcompatible = 0
                        }
                        else {
                            $flagcompatible = 1
                        }
                        break

                    }
                }
                if ($flagcompatible -eq 1) {
                    $compatibleCount += 1
                }
                elseif ($flagcompatible -eq 0) {
                    $mayNotcompatibleCount += 1
                }
                elseif ($flagcompatible -eq 'null') {
                    $unableUpgradeCount += 1
                }
            }
        }
        if (-not $checkVersion) {
            $serverSource += '["{0}",{1},{2}],' -f $DCResourceOne.vcname, $compatibleCount, $mayNotCompatibleCount
        }
        else {
            $serverSource += '["{0}",{1},{2},{3}],' -f $DCResourceOne.vcname, $compatibleCount, $mayNotCompatibleCount, $unableUpgradeCount
        }
    }
    $serverSource += '];'
    $content += 'var serverSource = {0}' -f $serverSource
    $content += $hostModelCompatibleHead

    if (-not $checkVersion) {
        $colorsArray = 'colorsC', 'colorsM'
    }
    else {
        $colorsArray = 'colorsC', 'colorsM', 'colorsU'
    }
    foreach ($colors in $colorsArray) {
        $content += $hostModelCompatibleBody
        $content += "color:$colors},"
    }
    $content += $hostModelCompatibleRest

    #count IO Device compatibility by vCenter
    if (-not(checkVersion($Data))) {
        $ioSource = "[['series', 'Compatible', 'May Not Compatible',],"
    }
    else {
        $ioSource = "[['series', 'Compatible','May Not Compatible','No Upgrade Path',],"
    }

    foreach ($VCResource in $Data) {
        $compatibleCount = 0
        $mayNotCompatibleCount = 0
        $unableUpgradeCount = 0
        $checkVersion = $VCResource.checkRelease
        foreach ($DCResourceOne in $VCResource.DCResource) {
            foreach ($HostResourceOne in $DCResourceOne.HostResource) {
                $flagcompatible = 0
                foreach ($ComoenentResourceOne in $HostResourceOne.ComponentResource) {
                    if ($ComoenentResourceOne.type -eq 'IO Device') {
                        # if ($checkVersion) {
                        #     if (-not($ComoenentResourceOne.upgrade)) {
                        #         $flagcompatible = 'null'
                        #     }
                        # }
                        if ($ComoenentResourceOne.status -ne 'Compatible') {
                            $flagcompatible = 0
                        }
                        else {
                            $flagcompatible = 1
                        }

                        if ($flagcompatible -eq 1) {
                            $compatibleCount += 1
                        }
                        elseif ($flagcompatible -eq 0) {
                            $mayNotCompatibleCount += 1
                        }
                        elseif ($flagcompatible -eq 'null') {
                            $unableUpgradeCount += 1
                        }
                    }
                }

            }
        }
        if (-not $checkVersion) {
            $ioSource += '["{0}",{1},{2}],' -f $DCResourceOne.vcname, $compatibleCount, $mayNotCompatibleCount
        }
        else {
            $ioSource += '["{0}",{1},{2},{3}],' -f $DCResourceOne.vcname, $compatibleCount, $mayNotCompatibleCount, $unableUpgradeCount
        }
    }

    $ioSource += '];'
    $content += 'var ioSource = {0}' -f $ioSource
    $content += $ioCompatibleHead
    if (-not $checkVersion) {
        $colorsArray = 'colorsC', 'colorsM'
    }
    else {
        $colorsArray = 'colorsC', 'colorsM', 'colorsU'
    }
    foreach ($colors in $colorsArray) {
        $content += $ioCompatibleBody
        $content += "color:$colors},"
    }
    $content += $ioCompatibleRest

    $dataTime = Get-Date -Format 'yyyy-M-d_h-m'
    $vcName = vcName($Data)
    $filename = 'sumreport_' + $vcName + $dataTime + '.html'
    $filePath = $Dir + '\' + $filename
    # Out-put a html report
    $content |Out-File -FilePath $filePath -Encoding utf8| Out-Null
    info ("Report " + "'" + $filePath + "'" + " has been created!")
}

Function Generate_CsvReport($Data, $Dir) {
    info("Generating compatibility csv report")
    #define header
    $content = ''
    $content += "VC,"
    $content += "DataCenter,"
    $content += "Host,"
    $content += "Type,"
    $content += "Model Name,"
    $content += "Vendor,"
    if (-not(checkVersion($Data))) {
        $content += "Installed Release,"
    }
    else {
        $content += "Checked Release,"
    }
    $content += "Compatible Status,"
    $content += "Hardware Detail,"
    $content += "Comments,"
    $content += 'VCG Link,'
    $content += "`n"

    #formate content
    foreach ($VCResource in $Data) {
        $checkVersion = $VCResource.checkRelease
        foreach ($DCResourceOne in $VCResource.DCResource) {
            foreach ($HostResourceOne in $DCResourceOne.HostResource) {
                $installVersion = $HostResourceOne.version
                foreach ($ComoenentResourceOne in $HostResourceOne.ComponentResource) {
                    if ($DCResourceOne.vcname -ne 'null') {
                        $content += "{0}," -f $DCResourceOne.vcname
                    }
                    else {
                        $content += "{0}," -f '/'
                    }
                    #DataCenterDetail
                    if ($DCResourceOne.dcname -ne 'null') {
                        $content += "{0}," -f $DCResourceOne.dcname
                    }
                    else {
                        $content += "{0}," -f '/'
                    }
                    #Host
                    $content += "{0}," -f $HostResourceOne.hostname
                    #Type
                    $content += "{0}," -f $ComoenentResourceOne.type
                    #Model Name
                    $content += '"{0}",' -f $ComoenentResourceOne.model
                    #Vendor
                    $content += '"{0}",' -f $ComoenentResourceOne.vendor
                    if (-not $checkVersion) {
                        #Installed Release
                        $content += '"{0}",' -f $installVersion
                    }
                    else {
                        $content += '"{0}",' -f $checkVersion
                    }
                    #Status
                    $content += '"{0}",' -f (formatStatus($ComoenentResourceOne.status))
                    #CompatibleHardware
                    if ($ComoenentResourceOne.type -eq 'IO Device') {
                        $CompatibleHardware = "'PCI ID:{0}, Driver:{1} {2}" -f $ComoenentResourceOne.pciid, $ComoenentResourceOne.Driver, $ComoenentResourceOne.DriverVersion
                    }
                    else {
                        $CompatibleHardware = "'CPU: {0}(Feature:{1}) BIOS:{2}" -f $ComoenentResourceOne.cpumodel, $ComoenentResourceOne.cpufeatureid, $ComoenentResourceOne.biosversion
                    }
                    $content += '"{0}",' -f $CompatibleHardware

                    #Comments

                    if ($ComoenentResourceOne.Warnings.Count -gt 0) {
                        $Comments = $ComoenentResourceOne.Warnings
                    }
                    else {
                        $Comments ='N/A'
                    }

                    $content += '"{0}",' -f $Comments

                    #VCG Link
                    $VCGLink = ''
                    foreach ($link in $ComoenentResourceOne.VcgLink) {
                        $VCGLink += $link
                        $VCGLink += ' '
                    }
                    $content += '"{0}",' -f $VCGLink
                    $content += "`n"
                }
            }
        }
    }

    #define filename and path
    $dataTime = Get-Date -Format 'yyyy-M-d_h-m'
    $vcName = vcName($Data)
    $filename = 'compreport_' + $vcName + $dataTime + '.csv'
    $filePath = $Dir + '\' + $filename
    #save csv report
    info ("Report " + "'" + $filePath + "'" + " has been created!")
    $content |Out-File -FilePath $filePath -Encoding utf8| Out-Null
    return $content
}
Function refactorData ($data) {
    $DCResource,$flag = refactorDC $data
    $data,$flag = refactorVC $DCResource
    return $data, $true
}

Function refactorDC($data) {
    $DCResource = @()
    $HostResource = @()
    $HR = @{}
    $DC = @{}

    $ReData = $data

    $HR.__type__ = $ReData[0].__type__
    $HR.vcname = $ReData[0].vcname
    $HR.dcname = $ReData[0].dcname
    $HR.hostname = $ReData[0].hostname
    $HR.apitype = $ReData[0].apitype
    $HR.powerstatus = $ReData[0].powerstatus
    $HR.version = $ReData[0].version
    $HR.fullname = $ReData[0].fullname
    $HR.connectionstatus = $ReData[0].connectionstatus
    $HR.ComponentResource = $ReData[0].ComponentResource
    $HostResource += $HR # HostResource = [{'hostname':'10.110.126.170'}]
    $DC.dcname = $ReData[0].dcname  #$DC={'dcname':'ha-datacenter'}
    $DC.vcname = $ReData[0].vcname
    $DC.HostResource = $HostResource  #$DC={'dcname':'ha-datacenter','HostResource':[{'hostname':'10.110.126.170'}]}
    $DC.checkRelease =  $ReData[0].checkRelease

    $DCResource += $DC  #$DCResource = [{'dcname':'ha-datacenter','HostResource':[{'hostname':'10.110.126.170'},]}]
    $dcname = $ReData[0].dcname
    $vcname = $ReData[0].vcname
    $DcIndex = 0
    for ($i = 1; $i -lt $ReData.Count; $i++) {
        $temp = $ReData[$i]
        $HR = @{}
        if ($temp.dcname -eq $dcname -and $temp.vcname -eq $vcname) {
            $HR.__type__ = $temp.__type__
            $HR.vcname = $temp.vcname
            $HR.dcname = $temp.dcname
            $HR.hostname = $temp.hostname
            $HR.apitype = $temp.apitype
            $HR.powerstatus = $temp.powerstatus
            $HR.version = $temp.version
            $HR.fullname = $temp.fullname
            $HR.connectionstatus = $temp.connectionstatus
            $HR.ComponentResource = $temp.ComponentResource
            $DCResource[$DcIndex].HostResource += $HR
        }
        else {
            $DcIndex += 1
            $DCResource += @{} #$DCResource = [{'dcname':'ha-datacenter','HostResource':[{'hostname':'10.110.126.170'},{'hostname':'10.110.126.171'}]},{}]
            $DCResource[$DcIndex].dcname = $temp.dcname  # [{'dcname':'ha-datacenter','HostResource':[{'hostname':'10.110.126.170'},{'hostname':'10.110.126.171'}]},{'dcname':'hw-datacenter'}]
            $DCResource[$DcIndex].vcname = $temp.vcname
            $DCResource[$DcIndex].checkRelease = $temp.checkRelease
            $DCResource[$DcIndex].HostResource = @()  # [{'dcname':'ha-datacenter','HostResource':[{'hostname':'10.110.126.170'},{'hostname':'10.110.126.171'}]},{'dcname':'hw-datacenter','HostResource':[]}]
            $HR = @{}
            $HR.__type__ = $temp.__type__
            $HR.vcname = $temp.vcname
            $HR.dcname = $temp.dcname
            $HR.hostname = $temp.hostname
            $HR.apitype = $temp.apitype
            $HR.powerstatus = $temp.powerstatus
            $HR.version = $temp.version
            $HR.fullname = $temp.fullname
            $HR.connectionstatus = $temp.connectionstatus
            $HR.ComponentResource = $temp.ComponentResource
            $DCResource[$DcIndex].HostResource += $HR # [{'dcname':'ha-datacenter','HostResource':[{'hostname':'10.110.126.170'},{'hostname':'10.110.126.171'}]},{'dcname':'hw-datacenter','HostResource':[{'hostname':'10.110.126.173'}]}]
            $dcname = $temp.dcname
            $vcname = $temp.vcname
        }
    }
    return $DCResource,$true
    # return $DCResource
}

Function refactorVC ($data) {
    $VCResource = @()
    $DCResource = @()
    $VC = @{}
    $DCResource += $data[0]
    $VC.DCResource = $DCResource
    $VC.hostname = $data[0].vcName
    $VC.checkRelease = $data[0].checkRelease

    $VCResource += $VC
    $vcname = $data[0].vcname
    $VcIndex = 0
    for ($i = 1 ; $i -lt $data.Count; $i++){
        $temp = $data[$i]
        if ($vcname -eq $temp.vcname) {
            $VCResource[$VcIndex].DCResource += $temp
        }
        else {
            $VcIndex += 1
            $DCResource = @()
            $VC = @{}
            $DCResource += $temp
            $VC.hostname = $temp.vcName
            $VC.DCResource = $DCResource
            $VC.checkRelease = $temp.checkRelease
            $VCResource += $VC
            $vcname = $temp.vcname
        }
    }
    return $VCResource,$true
}

Function vcName($Data) {
    $vcName = ''
    foreach ($VCResource in $Data) {
        $vcName += $VCResource.hostname
        $vcName += '_'
    }
    return $vcName
}

Function checkVersion($Data) {
    foreach ($VCResource in $Data) {
        $checkVersion = $VCResource.checkRelease
        return $checkVersion
    }
}

Function formatStatus($status) {
    if ($status -eq 'MayNotBeCompatible') {
        return 'May Not Be Compatible'
    }
    else {
        return $status
    }
}

Function formatHostCountGraphic($dataDict) {
    while ($dataDict.MoveNext()) {
        $items = $dataDict.Key

        if ($items -eq 'Compatible') {
            $colors = 'colorsC'
        }
        elseif ($items -eq 'May Not Compatible') {
            $colors = 'colorsM'
        }
        elseif ($items -eq 'Unable to upgrade') {
            $colors = 'colorsU'
        }

        $content += $hostCountBody
        $items = "'{0}'" -f $items
        $content += 'name: {0},' -f $items
        $content += 'data: {0},' -f $dataDict.Value
        $content += 'color: {0},' -f $colors
        $content += '},'
    }

    return $content
}


#Detail report
$generalHead = @'
<!doctype html>
<html lang="en">
<head>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <!-- Bootstrap CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm"
        crossorigin="anonymous">
    <title>ESXi Compatible Report</title>
</head>
<style>
body {
    margin: 10px;
}
td,th {
    padding:5px;
}
</style>
<body>
'@

$generalBodyBase = @'
<p>  [WARNING] The compatible status may not be fully accurate, please validate it with the official VMware Compatibility Guide</p>
				<script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
				<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
				<div>
				    <table border="1">
				    <tbody>
				        <tr>
					    <th>VC</th>
					    <th>DataCenter</th>
					    <th>Host</th>
					    <th>Type</th>
					    <th>Model Name</th>
					    <th>Vendor</th>

'@

$generalBodyRest = @'
					    <th>Compatible Status</th>
					    <th>Hardware Detail</th>
					    <th>Comments</th>
					</tr>
				    </tbody>
					<tbody>
'@

$generalFooter = @'
</tbody>
	</table>
    </div>
</body>
</html>

'@


#Summary report
$summaryHead = @'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Summary Report</title>
    <style>
        body{
	    min-width: 1400px;
        margin: 0px;
	    padding: 0px;
	    background:#FAFAFA;
	    width: 100%;
	    height: 100%;
	    background-size: cover;
	    background-repeat: no-repeat;
	    background-image: url(https://myvmware.workspaceair.com/SAAS/jersey/manager/api/images/520470)
        }
        #header{
            margin: 0 auto;
            min-width: 1400px;
        }
        #header #title{
	    text-align: center;
	    font-size: 34px;
	    height: 60px;
	    line-height: 60px;
	    background:#313131;
	    color: #fff;
	    }
        #content{
            width: 1400px;
            margin: 0 auto;
            z-index:999;
        }
        #content div{
	    float: left;
	    background:#FAFAFA;
	 }
	#content #main,#host_compatatibility{margin-top:10px;}
    </style>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/echarts/4.1.0/echarts.min.js"></script>


</head>
<body>
    <div id="header"><div id="title">ESXi Compatibility Summary Report</div></div>
    <div id="content">
        <div id="main" style="width: 700px;height:340px;"></div>
        <div id="host_compatatibility" style="width: 700px;height:340px;"></div>
        <div id="host_model_compatatibility" style="width: 700px;height:340px;"></div>
        <div id="IO_compatatibility" style="width: 700px;height:340px;"></div>
        <script type="text/javascript">
			var colorsC = "#318700";
			var colorsM = "#FF8400";
			var colorsN = "#C92100";
			var colorsU = "#FFDC0B";
            // Host count
            var myChart = echarts.init(document.getElementById('main'));
'@

$hostCountHead = @'
var option =  {
			    title : {
			        text: 'Count of Host by vCenter',
					left:'center',
					y: 'top',
			    },
				grid:{
					x:110,
				},
			    legend: {
			        data: lengendSeries,
					y: 'bottom'
			    },
			    calculable : true,
			    xAxis : [
			        {
			            type : 'value',
			            data : vCname
			        },

			    ],
			    yAxis : {
			        type: 'category',
					data: vCname,
					axisLabel:{
						rotate:45,
						formatter: function(value) {
						    if (value.length > 20) {
						      return value.substring(0, 20) + "...";
						    } else {
						      return value;
						    }
						}

					},
			    },
			    series : [
'@
$hostCountBody = @'
					{
			            type:'bar',
						barWidth:barsWidth,
						stack: 'Count',
			            itemStyle: {normal: {label:{show:true,  textStyle: {
                            color:'black'},formatter:function(p){return p.value > 0 ? (p.value):' ';}}}},

'@
$hostCountRest = @'
   ]
			};
            myChart.setOption(option);

            // Host Compatibility
            var myChart = echarts.init(document.getElementById('host_compatatibility'));
'@

$hostCompatible = @'
var option =  {
    color: colors,
    title: {
        text: 'Host Compatibility',
	    left:'center',
	    background:'black',
	},
	grid:{
		x:110,
	},
	tooltip: {
	    show: true,
	    trigger: 'item'
	},
	legend:{
	    bottom:0,
	    x: 'center',
	    data:lengendSeries,
	},
    series : [
        {
            name: '',
            type: 'pie',
            radius: ['50%','70%'],
            data:catalog,
            label:{
                normal:{
                    show: true,
                    position: 'top',
                    textStyle: {
                        color:'black'
                    },
                }
            },
        }
    ]
}
myChart.setOption(option);

// Host_model_compatatibility
var myChart = echarts.init(document.getElementById('host_model_compatatibility'));
'@

$hostModelCompatibleHead = @'
var option = {
    title: {
        text: 'Host Model Compatibility by vCenter',
        left:'center'
    },
	grid:{
		x:110,
	},
    legend: {
                y:'bottom'
    },
    dataset: {
        source: serverSource
    },
    xAxis: {},
    yAxis: {
    type: 'category',
    axisLabel:{
    	rotate:45,
		formatter: function(value) {
		    if (value.length > 20) {
		      return value.substring(0, 20) + "...";
		    } else {
		      return value;
		    }
		}
	},
},
    // Declare several bar series, each will be mapped
    // to a column of dataset.source by default.


    series: [
'@
$hostModelCompatibleBody = @'
        {
			type: 'bar',
			barWidth:barsWidth,
	        label:{
		        normal:{
		            show: true,
					position: 'right',
		            textStyle: {
		                color:'black',
		            },
				},
			},
'@
$hostModelCompatibleRest = @'
    ]
};
myChart.setOption(option);

// IO_compatatibility
var myChart = echarts.init(document.getElementById('IO_compatatibility'));
'@

$ioCompatibleHead = @'
var option = {
    title: [
		{
			text: 'IO Device Compatibility by vCenter',
			left:'center',
		},
		{
			subtext : '(IO number each of ESXi Host)',
			left:'center',
			y:'5%',
		},
	],
	grid:{
		x:110,
	},
    legend: {
                y:'bottom'
    },
    dataset: {
        source: ioSource
    },
    xAxis: {},
    yAxis: {
    type: 'category',
    axisLabel:{
    	rotate:45,
		formatter: function(value) {
		    if (value.length > 20) {
		      return value.substring(0, 20) + "...";
		    } else {
		      return value;
		    }
		}
	},
},
    // Declare several bar series, each will be mapped
    // to a column of dataset.source by default.


    series: [
'@
$ioCompatibleBody = @'
        {
			type: 'bar',
			barWidth:barsWidth,
	        label:{
		        normal:{
		            show: true,
					position: 'right',
		            textStyle: {
		                color:'black',
		            },
				},
			},
'@
$ioCompatibleRest = @'
    ]
	};
    myChart.setOption(option);
        </script>
    </div>
</body>
</html>
'@

