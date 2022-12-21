<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

Function Connect-SkylineInsights {
<#
    .NOTES
    ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 21, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
    ===========================================================================
    .SYNOPSIS
    Use this function to create the auth header to connect to Skyline Insights API
    .DESCRIPTION
    This function will allow you to connect to a Skyline Insights API.
    A global variable will be set with the Servername & Header value for use by other functions.
    .EXAMPLE
    PS C:\> Connect-SkylineInsights -apiKey 'my-key-from-csp'
    This will use the provided API key to create a connection to Skyline Insights.
    .EXAMPLE
    PS C:\> Connect-SkylineInsights -apiKey 'my-key-from-csp' -SaveCredentials
    This will use the PowerCLI VICredentialStore Item to save the provided API key.  On next use this key will be provided automatically.
#>
    param(
        [string]$apiKey,
        [switch]$SaveCredentials,
        [Parameter(DontShow)]$cspApi = 'console.cloud.vmware.com',
        [Parameter(DontShow)]$skylineApi = 'skyline.vmware.com'
    )
    
    if ($PSEdition -eq 'Core' -And $SaveCredentials) {
        write-error 'The parameter SaveCredentials of Connect-SkylineInsights cmdlet is not supported on PowerShell Core.'
        return
    }

    if ($PSEdition -eq 'Core' -AND !$apiKey) {
        write-error 'An API key is required.'
        return
    }

    # Create VICredentialStore item to save the API key
    if ($apiKey -AND $SaveCredentials) {
        if ( (Get-Command Get-VICredentialStoreItem -ErrorAction:SilentlyContinue | Measure-Object).Count -gt 0 ) {
            $savedCred = Get-VICredentialStoreItem -host $skylineApi -ErrorAction:SilentlyContinue
            if ($savedCred) {
                $savedCred | Remove-VICredentialStoreItem -Confirm:$false
            }
            New-VICredentialStoreItem -Host $skylineApi -User 'api-key' -Password $apiKey
        } else {
            Write-Warning 'Use of -SaveCredentials requires the PowerCLI VICredentialStoreItem cmdlets.'
        }
    }

    if (!$apiKey) {
        if ( (Get-Command Get-VICredentialStoreItem -ErrorAction:SilentlyContinue | Measure-Object).Count -gt 0 ) {
            $savedCred = Get-VICredentialStoreItem -host $skylineApi -ErrorAction:SilentlyContinue
        }
        if ( ($savedCred | Measure-Object).Count -eq 1) {
            $apiKey = $savedCred.Password
        } else {
            write-error 'An API key is required.'
            return
        }
    }

    $loginHeader = @{
        'Accept' = 'application/json'
        'Content-Type' = 'application/x-www-form-urlencoded'
    } 
    $loginBody = @{'refresh_token' = $apiKey }
    
    try {
        $webRequest = Invoke-RestMethod -Uri "https://$cspApi/csp/gateway/am/api/auth/api-tokens/authorize?grant_type=refresh_token" -method POST -Headers $loginHeader -Body $loginBody

        $global:DefaultSkylineConnection = New-Object psobject -property @{ 'Name'=$skylineApi; 'CSPName'=$cspApi; 'ConnectionDetail'=$webRequest; APIKey = $apiKey;
        'Refresh_Token'=$webRequest.refresh_token; 'SkylineAPI'="https://$skylineApi/public/api/data"; PSTypeName='SkylineConnection' }
    
        # Return the connection object
        $global:SkylineInsightsApiQueryCount = 0
        $global:SkylineInsightsApiQueryLastTime = $null
        $global:DefaultSkylineConnection
    } catch {
        Write-Error ("Failure connecting to $skylineAPI.  Posted $loginBody " + $_)
    } # end try/catch block
}

Function Disconnect-SkylineInsights {
<#
    .NOTES
    ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 21, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
    ===========================================================================
    .SYNOPSIS
    Use this function to disconnect from Skyline Insights API
    .DESCRIPTION
    This function will allow you to disconnect from a Skyline Insights API.
    The global variable will be set with the Servername & Header value for use by other functions.
    .EXAMPLE
    PS C:\> Disconnect-SkylineInsights
    This will remove a connection to Skyline Insights.
#>
    if ($global:DefaultSkylineConnection) {
        $global:DefaultSkylineConnection = $null
    } else {
        Write-Error 'Could not find an existing connection to SkylineInsights API.'
    }
}

Function Invoke-SkylineInsightsApi {
<#
    .NOTES
    ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 21, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
    ===========================================================================
    .SYNOPSIS
    Use this function to post a query to the Skyline Insights API.
    .DESCRIPTION
    This function will allow you to query the Skyline Insights API.
    Proper headers will be formatted and posted if a DefaultSkylineConnection is present.
    This is primarily a helper function used by other functions included in the module.  
    It is exported in the module manifest to be used for any custom queries.
    .EXAMPLE
    PS C:\> Invoke-SkylineInsightsApi -queryBody '{formatted-query-string-converted-to-json}'
#>
    param(
        [Parameter(Mandatory=$true)][string]$queryBody,
        [Parameter(DontShow=$true)][int]$sleepTimerMs=501
    )
    
    if ( !$global:DefaultSkylineConnection ) {
        Write-Error 'You are not currently connected to any servers. Please connect first using Connect-SkylineInsights.'
        return;
    }

    write-debug "Querybody: $queryBody"
    try {
        if ($global:SkylineInsightsApiQueryLastTime) {
            $timeSinceLastQuery = (New-TimeSpan $global:SkylineInsightsApiQueryLastTime (Get-Date)).TotalMilliseconds
            if ($timeSinceLastQuery -lt $sleepTimerMs) {
                Write-Debug "Waiting $($sleepTimerMs-$timeSinceLastQuery)ms to prevent HTTP 429 TOO_MANY_REQUESTS error"
                Start-Sleep -Milliseconds ($sleepTimerMs-$timeSinceLastQuery) 
            }
        }
        $restCall = invoke-restmethod -method post -Uri $($global:DefaultSkylineConnection.SkylineAPI) -Headers @{Authorization = "Bearer $($global:DefaultSkylineConnection.ConnectionDetail.access_token)"} -body $queryBody -ContentType "application/json"
        $global:SkylineInsightsApiQueryCount++
        $global:SkylineInsightsApiQueryLastTime = Get-Date
        if ($restCall.errors) {
            Write-Error $restCall.errors.Message
        }
        return $restCall
    } catch {
        $incomingError = $_
        try {
            # are nested try/catch blocks the powershell equilivent of vbscript On Error Resume Next?
            $errorStatusAsJson = ($incomingError | ConvertFrom-Json).status
            if ($errorStatusAsJson -eq '429 TOO_MANY_REQUESTS') {
                write-error 'Encountered HTTP 429 TOO_MANY_REQUESTS error, consider increasing sleepTimerMs value.'
                start-sleep -Milliseconds (2*$sleepTimerMs)
                break
            }
        } catch {
            # this was the error from trying to cast the incoming error to Json
        }
        if (!$errorStatusAsJson) { write-error $incomingError }
    }
}


Function Get-SkylineFinding {
<#
    .NOTES
    ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 21, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
    ===========================================================================
    .SYNOPSIS
    Use this function to query findings from the Skyline Insights API.
    .DESCRIPTION
    This function will allow you to query the Skyline Insights API for Findings.
    As described in the documentation, the maximum limit per page is 200 records.  This function provides
    an optional pagesize parameter to request smaller batches, but by default assumes 200 records.
    .EXAMPLE
    PS C:\> Get-SkylineFinding
#>
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName=$true)][string]$findingId,
        [Parameter(ValueFromPipelineByPropertyName=$true)][string[]]$products,
        [Parameter(ValueFromPipelineByPropertyName=$true)][ValidateSet('CRITICAL','MODERATE','TRIVIAL')][string]$severity,
        [Parameter(DontShow=$true)][ValidateRange(1,200)][int]$pagesize=200
    )

    begin {
        $queryBody = @"
{
    activeFindings(limit: $pagesize, start: 0 filter: {}) {
        findings {
            findingId
            accountId
            findingDisplayName
            severity
            products
            findingDescription
            findingImpact
            recommendations
            kbLinkURLs
            recommendationsVCF
            kbLinkURLsVCF
            categoryName
            findingTypes
            firstObserved
            totalAffectedObjectsCount
        }
        totalRecords
        timeTaken
    }
}
"@

    }
    process {
        if (!$products) { $products = 'NO_PRODUCT_FILTER'}
        foreach ($thisProduct in $products) {
            if ($findingId) { $filterString = "findingId: `"$findingId`"," }
            if ($thisProduct -ne 'NO_PRODUCT_FILTER') { $filterString += "product: `"$thisProduct`"," }

            # Try to get results the first time
            $results = @()
            $thisIteration = 0
            do {
                $thisQueryBody = $queryBody -Replace 'filter: {}', "filter: { $filterString }" -Replace 'start: 0', "start: $thisIteration"
                Write-Debug $thisQueryBody
                $thisResult = Invoke-SkylineInsightsApi -queryBody (@{'query' = $thisQueryBody} | ConvertTo-Json -Compress)
                $totalRecords = $thisResult.data.activeFindings.totalRecords
                if ($severity) {
                    $thisResult.data.activeFindings.Findings | Where-Object {$_.severity -eq $severity}
                } else {
                    $thisResult.data.activeFindings.Findings
                }
                $results += ($thisResult.data.activeFindings.Findings)
                $thisIteration += $pageSize
            } while ($results.count -lt $totalRecords ) # end do/while loop

            #return $results
        }
    }
    end {

    }
}

Function Get-SkylineAffectedObject {
<#
    .NOTES
    ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 21, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
    ===========================================================================
    .SYNOPSIS
    Use this function to query affected objects from the Skyline Insights API.
    .DESCRIPTION
    This function will allow you to query the Skyline Insights API for affected objects.
    Input parameters are required for the findingId and product.  Products can be provided as an object (from Get-SkylineFinding) or
    a single product can be specified by name (or delimited list).
    As described in the documentation, the maximum limit per page is 200 records.  This function provides
    an optional pagesize parameter to request smaller batches, but by default assumes 200 records.
    .EXAMPLE
    PS C:\> Get-SkylineAffectedObject -findingId 'vSphere-Vmtoolsmemoryleak-KB#76163' -product 'core-vcenter01.lab.enterpriseadmins.org'
    This example uses the ByName parameter set to pass in specific findings/product and expects either a single product or a 'separator' delimited list
    .EXAMPLE
    PS C:\> Get-SkylineFinding | Select-Object -First 2 | Get-SkylineAffectedObject
    This example uses the ByObject parameter set to pass in products as an object from Get-SkylineFinding
#>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string]$findingId,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string[]]$products,
        [Parameter(DontShow=$true)][ValidateRange(1,200)][int]$pagesize=200
    )

    begin {
        $queryBody = @"
        {
            activeFindings(
                filter: {
                    findingId: "",
                    product: "",
                }) {
            findings {
                totalAffectedObjectsCount
                affectedObjects(start: 0, limit: $pagesize)  {
                    sourceName
                    objectName
                    objectType
                    version
                    buildNumber
                    solutionTags {
                    type
                    version
                    }
                    firstObserved
                }
            }
            totalRecords
            timeTaken
            }
        }
"@

        # Try to get results the first time
    }

    process {
        foreach ( $thisProduct in $products ) {
            $thisIteration = 0
            $results = @() # reset results variable between products
            do {
                $thisQueryBody = $queryBody -Replace 'product: "",', "product: `"$thisProduct`"," -Replace 'start: 0', "start: $thisIteration" -Replace 'findingId: "",', "findingId: `"$findingId`","
                Write-Debug $thisQueryBody
                $thisResult = Invoke-SkylineInsightsApi -queryBody (@{'query' = $thisQueryBody} | ConvertTo-Json -Compress)
                $totalRecords = $thisResult.data.activeFindings.Findings.totalAffectedObjectsCount
                $thisResult.data.activeFindings.Findings.affectedObjects | Select-Object @{N='findingId';E={$findingId}}, *
                $results += ($thisResult.data.activeFindings.Findings.affectedObjects) | Select-Object @{N='findingId';E={$findingId}}, *
                $thisIteration += $pagesize
            } while ($results.count -lt $totalRecords ) # end do/while loop
        } # end foreach product loop
    } 
}

Function Format-SkylineResult {
<#
    .NOTES
    ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 21, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
    ===========================================================================
    .SYNOPSIS
    Use this function to format results from the Skyline Insights API
    .DESCRIPTION
    This function will format the output from the Skyline Insights API.
    For example, Get-SkylineFinding and Get-SkylineAffectedObject will return some strings, date values as numbers, and object properties.
    This function will convert date numbers to powershell dates and objects to delimiter separated stings.  This should help with exporting
    results to CSV files for example.
    .EXAMPLE
    PS C:\> Get-SkylineFinding | Format-SkylineResult | Export-Csv c:\temp\findings.csv -NoTypeInformation
    This will return Skyline Findings, format them as needed, and export results to a CSV file.
#>
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)][PSCustomObject]$inputObject,
        [string]$separator = '; '
    )
    begin {
        $results = @()

        # To format the dates, we need to add the value returned by the API to the begining of time
        $startOfTime = Get-Date '1970-01-01'
    }
    
    process {
        if ( $inputObject.accountId ) {
            #This appears to be a Finding
            $results += $inputObject | Select-Object findingId, accountId, findingDisplayName, severity, @{N='product';E={[string]::join($separator, $_.products)}}, findingDescription,
                findingImpact, @{N='recommendations';E={[string]::Join($separator,$_.recommendations)}}, @{N='kbLinkURLs';E={[string]::Join($separator, $_.kbLinkURLs)}},
                @{N='recommendationsVCF';E={[string]::Join($separator,$_.recommendationsVCF)}}, @{N='kbLinkURLsVCF';E={[string]::Join($separator, $_.kbLinkURLsVCF)}},
                categoryName, @{N='findingTypes';E={[string]::Join($sep, $_.findingTypes)}}, @{N='firstObserved';E={ $startOfTime+[timespan]::FromMilliseconds($_.firstObserved) }},
                totalAffectedObjectsCount

        } elseif ( $inputObject.objectName ) {
            #This appears to be an AffectedObject
            $results += $inputObject | Select-Object findingId, sourceName, objectName, objectType, version, buildNumber, @{N='solutionTags-Type';E={$_.solutionTags.type}}, 
                @{N='solutionTags-Version';E={$_.solutionTags.version}}, @{N='firstObserved';E={ $startOfTime+[timespan]::FromMilliseconds($_.firstObserved) }}
        } else {
            write-warning "Unable to determine input object type."
        } # end inputobject evaluation
    } #end process

    end {
        return $results
    }
}

Function Start-SkylineInsightsApiExplorer {
<#
    .NOTES
    ===========================================================================
    Created by:	Brian Wuchner
    Date:		February 21, 2022
    Blog:		www.enterpriseadmins.org
    Twitter:		@bwuch
    ===========================================================================
    .SYNOPSIS
    Use this function to launch the Skyline Insights API in a browser.
    .DESCRIPTION
    This function will open the Skyline Insights API explorer in the default web browser and populate
    the clipboard with the necessary authorization header value to enable interactive queries.
    .EXAMPLE
    PS C:\> Start-SkylineInsightsApiExplorer
#>
    if ( !$global:DefaultSkylineConnection ) {
        Write-Error 'You are not currently connected to any servers. Please connect first using Connect-SkylineInsights.'
        return;
    }
    "Default web browser will launch to the Skyline Insights API explorer.  In the lower left select 'Request Headers' and paste the authorization/bearer token into the text box.  `nNote: this script has updated your clipboard with the required auth token."
    "{`"Authorization`":`"Bearer $($global:DefaultSkylineConnection.ConnectionDetail.access_token)`"}" | Set-Clipboard 
    Start-Process "https://$($global:DefaultSkylineConnection.Name)/public/api/docs"
}

