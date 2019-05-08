Function Remove-HVApplication {
<#
.Synopsis
   Removes the specified application if exists.

.DESCRIPTION
   Removes the specified application if exists.

.PARAMETER ApplicationName
   Application to be deleted.
   The name of the application must be given that is to be searched for and remove if exists.

.PARAMETER HvServer
   View API service object of Connect-HVServer cmdlet.

.EXAMPLE
   Remove-HVApplication -ApplicationName 'App1' -HvServer $HvServer
   Removes 'App1', if exists.

.OUTPUTS
   Removes the specified application if exists.

.NOTES
    Author                      : Samiullasha S
    Author email                : ssami@vmware.com
    Version                     : 1.2

    ===Tested Against Environment====
    Horizon View Server Version : 7.8.0
    PowerCLI Version            : PowerCLI 11.1
    PowerShell Version          : 5.0
#>
  param (
    [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
    [string]$ApplicationName,

    [Parameter(Mandatory = $False)]
    $HvServer = $null
  )
  begin {
    $services = Get-ViewAPIService -HvServer $HvServer
    if ($null -eq $services) {
        Write-Error "Could not retrieve View API services from connection object"
        break
    }
  }
  process {
    $App= Get-HVApplication -ApplicationName $ApplicationName -HvServer $HvServer
    if (!$App) {
        Write-Host "Application '$ApplicationName' not found. $_"
        return
    }
    $AppService= New-Object VMware.Hv.ApplicationService
    $AppService.Application_Delete($services,$App.Id)
    if ($?) {
        Write-Host "'$ApplicationName' has been successfully removed."
    }
  }
  end {
    [System.GC]::Collect()
  }
}
