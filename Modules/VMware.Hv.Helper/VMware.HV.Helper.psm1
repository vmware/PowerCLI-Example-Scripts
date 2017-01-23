#Script Module : VMware.Hv.Helper
#Version       : 1.0

#Copyright © 2016 VMware, Inc. All Rights Reserved.

#Permission is hereby granted, free of charge, to any person obtaining a copy of
#this software and associated documentation files (the "Software"), to deal in
#the Software without restriction, including without limitation the rights to
#use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
#of the Software, and to permit persons to whom the Software is furnished to do
#so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

function Get-HVObject {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TypeName,

    [Parameter(Mandatory = $false)]
    [System.Collections.Hashtable]$PropertyName
  )
  $objStr = 'VMware.Hv.' + $typeName
  return New-Object $objStr -Property $propertyName
}

function Get-ViewAPIService {
  param(
    [Parameter(Mandatory = $false)]
    $HvServer
  )
  if ($null -ne $hvServer) {
    if ($hvServer.GetType().name -ne 'ViewServerImpl') {
      $type = $hvServer.GetType().name
      Write-Error "Expected hvServer type is ViewServerImpl, but received: [$type]"
      return $null
    }
    elseif ($hvServer.IsConnected) {
      return $hvServer.ExtensionData
    }
  } elseif ($global:DefaultHVServers.Length -gt 0) {
     $hvServer = $global:DefaultHVServers[0]
     return $hvServer.ExtensionData
  }
  return $null
}

function Get-VcenterID {
  param(
    [Parameter(Mandatory = $true)]
    $Services,

    [Parameter(Mandatory = $false)]
    [string]
    $Vcenter
  )
  $vc_service_helper = New-Object VMware.Hv.VirtualCenterService
  $vcList = $vc_service_helper.VirtualCenter_List($services)
  if ($vCenter) {
    #ServerSpec.ServerName is IP/FQDN of the vCenter server. Input vCenter will be IP/FQDN of the vcenter server
    $virtualCenterId = ($vcList | Where-Object { $_.ServerSpec.ServerName -eq $vCenter }).id
    if ($virtualCenterId.Count -ne 1) {
      Write-Error "vCenter Server not found: [$vCenter], please make sure vCenter is added in Connection Server"
      return $null
    }
  }
  else {
    if ($vcList.Count -ne 1) {
      Write-Error "Multiple Vcenter servers found, please specify the vCenter Name"
      return $null
    }
    else { $virtualCenterId = $vcList.id }
  }
  return $virtualCenterId
}

function Get-JsonObject {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SpecFile
  )
  try {
    return Get-Content -Raw $specFile | ConvertFrom-Json
  } catch {
    throw "Failed to read json file [$specFile], $_"
  }
}

function Get-MapEntry {
  param(
    [Parameter(Mandatory = $true)]
    $Key,

    [Parameter(Mandatory = $true)]
    $Value
  )

  $update = New-Object VMware.Hv.MapEntry
  $update.key = $key
  $update.value = $value
  return $update
}

function Get-RegisteredPhysicalMachine ($Services,$MachinesList) {
  [VMware.Hv.MachineId[]]$machines = $null
  $query_service_helper = New-Object VMware.Hv.QueryServiceService
  foreach ($machineName in $machinesList) {
    $QueryFilterEquals = New-Object VMware.Hv.QueryFilterEquals
    $QueryFilterEquals.memberName = 'machineBase.name'
    $QueryFilterEquals.value = $machineName

    $defn = New-Object VMware.Hv.QueryDefinition
    $defn.queryEntityType = 'RegisteredPhysicalMachineInfo'
    $defn.Filter = $QueryFilterEquals

    $queryResults = $query_service_helper.QueryService_Query($services,$defn)
    $res = $queryResults.results
    $machines += $res.id
  }
  return $machines
}

function Get-RegisteredRDSServer ($Services,$ServerList) {
  [VMware.Hv.RDSServerId[]]$servers = $null
  $query_service_helper = New-Object VMware.Hv.QueryServiceService
  foreach ($serverName in $serverList) {
    $QueryFilterEquals = New-Object VMware.Hv.QueryFilterEquals
    $QueryFilterEquals.memberName = 'base.name'
    $QueryFilterEquals.value = $serverName

    $defn = New-Object VMware.Hv.QueryDefinition
    $defn.queryEntityType = 'RDSServerInfo'
    $defn.Filter = $QueryFilterEquals

    $queryResults = $query_service_helper.QueryService_Query($services,$defn)

    $servers += $queryResults.results.id
  }
  if ($null -eq $servers) {
    throw "No Registered RDS server found with name: [$serverList]"
  }
  return $servers
}

function Add-HVDesktop {
<#
.SYNOPSIS
Adds virtual machine to existing pool

.DESCRIPTION
The Add-HVDesktop adds virtual machines to already exiting pools by using view API service object(hvServer) of Connect-HVServer cmdlet. VMs can be added to any of unmanaged manual, managed manual or Specified name. This advanced function do basic checks for pool and view API service connection existance, hvServer object is bound to specific connection server.

.PARAMETER PoolName
    Pool name to which new VMs are to be added.

.PARAMETER Machines
    List of virtual machine names which need to be added to the given pool.

.PARAMETER Users
    List of virtual machine users for given machines.

.PARAMETER Vcenter
    Virtual Center server-address (IP or FQDN) of the given pool. This should be same as provided to the Connection Server while adding the vCenter server.

.PARAMETER HvServer
    View API service object of Connect-HVServer cmdlet.

.EXAMPLE
    Add managed manual VMs to existing manual pool
    Add-HVDesktop -PoolName 'ManualPool' -Machines 'manualPool1', 'manualPool2' -Confirm:$false

.EXAMPLE
    Add virtual machines to automated specific named dedicated pool
    Add-HVDesktop -PoolName 'SpecificNamed' -Machines 'vm-01', 'vm-02' -Users 'user1', 'user2'

.EXAMPLE
    Add machines to automated specific named Floating pool
    Add-HVDesktop -PoolName 'SpecificNamed' -Machines 'vm-03', 'vm-04'

.EXAMPLE
    Add machines to unmanged manual pool
    Add-HVDesktop -PoolName 'Unmanaged' -Machines 'desktop-1.eng.vmware.com'

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.0
    Dependencies                : Make sure pool already exists before adding VMs to it.

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0

#>
  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $PoolName,

    [Parameter(Mandatory = $true)]
    [string[]]
    $Machines,

    [Parameter(Mandatory = $false)]
    [string[]]
    $Users,

    [Parameter(Mandatory = $false)]
    [string]
    $Vcenter,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }

  process {
    try {
      $desktopPool = Get-HVPoolSummary -poolName $poolName -hvServer $hvServer
    } catch {
      Write-Error "Make sure Get-HVPoolSummary advanced function is loaded, $_"
      break
    }
    if ($desktopPool) {
      $id = $desktopPool.id
      $type = $desktopPool.desktopsummarydata.type
      $source = $desktopPool.desktopsummarydata.source
      $userAssignment = $desktopPool.desktopsummarydata.userAssignment
    } else {
      Write-Error "Unable to retrieve DesktopSummaryView with given poolName: [$poolName]"
      break
    }

    $desktop_service_helper = New-Object VMware.Hv.DesktopService
    $user_assignement_helper = $desktop_service_helper.getDesktopUserAssignmentHelper()
    switch ($type) {
      'AUTOMATED' {
        if (($userAssignment -eq $user_assignement_helper.USER_ASSIGNMENT_DEDICATED) -and ($machines.Length -ne $users.Length)) {
          Write-Error "Parameters machines length: [$machines.Length] and users length: [$users.Length] should be of same size"
          return
        }
        [VMware.Hv.DesktopSpecifiedName[]]$desktopSpecifiedNameArray = @()
        $cnt = 0
        foreach ($machine in $machines) {
          $specifiedNames = New-Object VMware.Hv.DesktopSpecifiedName
          $specifiedNames.vmName = $machine
          if ($userAssignment -eq $user_assignement_helper.USER_ASSIGNMENT_DEDICATED -and $users) {
            try {
              $specifiedNames.user = Get-UserId -user $users[$cnt]
            } catch {
              Write-Error "Unable to retrieve UserOrGroupId for user: [$users[$cnt]], $_"
              return
            }
          }
          $desktopSpecifiedNameArray += $specifiedNames
          $cnt += 1
        }
        $desktop_service_helper.Desktop_AddMachinesToSpecifiedNamingDesktop($services,$id,$desktopSpecifiedNameArray)
      }
      'MANUAL' {
        if ($source -eq 'UNMANAGED') {
          $machineList = Get-RegisteredPhysicalMachine -services $services -machinesList $machines
          if ($machineList.Length -eq 0) {
            Write-Error "Failed to retrieve registerd physical machines with the given machines parameter"
            return
          }
        } else {
		  $vcId = Get-VcenterID -services $services -vCenter $vCenter
          $machineList = Get-MachinesByVCenter -machineList $machines -vcId $vcId
          if ($machineList.Length -eq 0) {
            Write-Error "Failed to get any Virtual Center machines with the given machines parameter"
            return
          }
        }
        if ($pscmdlet.ShouldProcess($machines)) {
          $desktop_service_helper.Desktop_AddMachinesToManualDesktop($services,$id,$machineList)
        }
        return $machineList
      }
      default {
        Write-Error "Only Automated/Manual pool types support this add operation"
        break
      }
    }
  }

  end {
    [System.gc]::collect()
  }
}

function Get-UserId ($User) {

  $defn = New-Object VMware.Hv.QueryDefinition
  $defn.queryEntityType = 'ADUserOrGroupSummaryView'
  [VMware.Hv.QueryFilter[]]$filters = $null
  $groupfilter = New-Object VMware.Hv.QueryFilterEquals -Property @{ 'memberName' = 'base.group'; 'value' = $false }
  $userNameFilter = New-Object VMware.Hv.QueryFilterEquals -Property @{ 'memberName' = 'base.name'; 'value' = $user }
  $treeList = @()
  $treeList += $userNameFilter
  $treelist += $groupfilter
  $filterAnd = New-Object VMware.Hv.QueryFilterAnd
  $filterAnd.Filters = $treelist
  $defn.Filter = $filterAnd
  $query_service_helper = New-Object VMware.Hv.QueryServiceService
  $res = $query_service_helper.QueryService_Query($services,$defn)
  if ($null -eq $res.results) {
    throw "Query service did not return any users with given user name: [$user]"
  }
  return $res.results.id
}

function Get-MachinesByVCenter ($MachineList,$VcId) {

  [VMware.Hv.MachineId[]]$machines = $null
  $virtualMachine_helper = New-Object VMware.Hv.VirtualMachineService
  $vcMachines = $virtualMachine_helper.VirtualMachine_List($services,$vcId)
  $machineDict = @{}
  foreach ($vMachine in $vcMachines) {
    $machineDict.Add($vMachine.name,$vMachine.id)
  }
  foreach ($machineName in $machineList) {
    if ($machineDict.Contains($machineName)) {
      $machines += $machineDict.$machineName
    }
  }
  return $machines
}

function Add-HVRDSServer {
<#
.SYNOPSIS
    Add RDS Servers to an existing farm.

.DESCRIPTION
    The Add-HVRDSServer adds RDS Servers to already exiting farms by using view API service object(hvServer) of Connect-HVServer cmdlet. We can add RDSServers to manual farm type only. This advanced function do basic checks for farm and view API service connection existance. This hvServer is bound to specific connection server.

.PARAMETER FarmName
    farm name to which new RDSServers are to be added.

.PARAMETER RdsServers
    RDS servers names which need to be added to the given farm. Provide a comma separated list for multiple names.

.PARAMETER HvServer
    View API service object of Connect-HVServer cmdlet.

.EXAMPLE
    Add RDSServers to manual farm
    Add-HVRDSServer -Farm "manualFarmTest" -RdsServers "vm-for-rds","vm-for-rds-2" -Confirm:$false

.OUTPUTS
    None

.NOTES
    Author                      : Ankit Gupta.
    Author email                : guptaa@vmware.com
    Version                     : 1.0
    Dependencies                : Make sure farm already exists before adding RDSServers to it.

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>
  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(
    [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
    $FarmName,

    [Parameter(Mandatory = $true)]
    [string[]]
    $RdsServers,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }

  process {
    try {
      $farmSpecObj = Get-HVFarmSummary -farmName $farmName -hvServer $hvServer
    } catch {
      Write-Error "Make sure Get-HVFarmSummary advanced function is loaded, $_"
      break
    }
    if ($farmSpecObj) {
      $id = $farmSpecObj.id
      $type = $farmSpecObj.data.type

    } else {
      Write-Error "Unable to retrieve FarmSummaryView with given farmName: [$farmName]"
      break
    }
    $farm_service_helper = New-Object VMware.Hv.FarmService
    switch ($type) {
      'AUTOMATED' {
        Write-Error "Only Manual farm types supported for this add operation"
        break
      }
      'MANUAL' {
        try {
          $serverList = Get-RegisteredRDSServer -services $services -serverList $rdsServers
          if ($pscmdlet.ShouldProcess($rdsServers)) {
            $farm_service_helper.Farm_AddRDSServers($services, $id, $serverList)
          }
          return $serverList
        } catch {
          Write-Error "Failed to Add RDS Server to Farm with error: $_"
          break
        }
      }
    }
  }

  end {
    [System.gc]::collect()
  }
}



function Connect-HVEvent {
<#
.SYNOPSIS
   This function is used to connect to the event database configured on Connection Server.

.DESCRIPTION
   This function queries the specified Connection Server for event database configuration and returns the connection object to it. If event database is not configured on specified connection server, it will return null.
   Currently, Horizon 7 is supporting SQL server and Oracle 12c as event database servers. To configure event database, goto 'Event Database Configuration' tab in Horizon admin UI.

.PARAMETER HvServer
   View API service object of Connect-HVServer cmdlet.

.PARAMETER DbUserName
   User name to be used in database connection. If not passed, default database user name on the Connection Server will be used.

.PARAMETER DbPassword
   Password corresponds to 'dbUserName' user.

.EXAMPLE
   Connecting to the database with default username configured on Connection Server $hvServer.
   Connect-HVEvent -HvServer $hvServer

.EXAMPLE
   Connecting to the database configured on Connection Server $hvServer with customised user name 'system'.
   $hvDbServer = Connect-HVEvent -HvServer $hvServer -DbUserName 'system'

.EXAMPLE
   Connecting to the database with customised user name and password.
   $hvDbServer = Connect-HVEvent -HvServer $hvServer -DbUserName 'system' -DbPassword 'censored'

.EXAMPLE
   Connecting to the database with customised user name and password, with password being a SecureString.
   $password = Read-Host 'Database Password' -AsSecureString
   $hvDbServer = Connect-HVEvent -HvServer $hvServer -DbUserName 'system' -DbPassword $password

.OUTPUTS
   Returns a custom object that has database connection as 'dbConnection' property.

.NOTES
    Author                      : Paramesh Oddepally.
    Author email                : poddepally@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    $DbPassword = $null,

    [Parameter(Mandatory = $false)]
    $HvServer = $null,

    [Parameter(Mandatory = $false)]
    [string]$DbUserName = $null
  )

  begin {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient") | Out-Null
    # Connect to Connection Server and call the View API service
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
    $EventDatabaseHelper = New-Object VMware.Hv.EventDatabaseService
    $EventDatabaseInfo = $EventDatabaseHelper.EventDatabase_Get($services)

    # Check whether event database is configured on the connection server
    # If not, return empty
    if (!$EventDatabaseInfo.EventDatabaseSet) {
      Write-Error "Event Database is not configured on Connection Server. To configure Event DB, go to 'Events Configuration' Tab in Horizon Admin UI"
      break
    }

    $dbServer = $EventDatabaseInfo.Database.server
    $dbType = $EventDatabaseInfo.Database.type
    $dbPort = $EventDatabaseInfo.Database.port
    $dbName = $EventDatabaseInfo.Database.name
    if (!$dbUserName) { $dbUserName = $EventDatabaseInfo.Database.userName }
    $dbTablePrefix = $EventDatabaseInfo.Database.tablePrefix

    if (!$dbPassword) { $dbPassword = Read-Host 'Database Password for' $dbUserName@$dbServer -AsSecureString }

    if ($dbType -eq "SQLSERVER") {
      if ($dbPassword.GetType().name -eq 'String'){
        $password = ConvertTo-SecureString $dbPassword -AsPlainText -Force
      } elseif ($dbPassword.GetType().name -eq 'SecureString') {
        $password = $dbPassword
      } else {
        Write-Error "Unsupported type recieved for dbPassword: [$dbPassword]. dbpassword should either be String or SecureString type. "
	    break
      }
      $connectionString = "Data Source=$dbServer, $dbPort; Initial Catalog=$dbName;"
      $connection = New-Object System.Data.SqlClient.SqlConnection ($connectionString)
      $password.MakeReadOnly()
      $connection.Credential = New-Object System.Data.SqlClient.SqlCredential($dbUserName, $password);
    } elseif ($dbType -eq "ORACLE") {
      if ($dbPassword.GetType().name -eq 'SecureString'){
        $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword))
      }  elseif ($dbPassword.GetType().name -eq 'String') {
        $password = $dbPassword
      } else {
        Write-Error "Unsupported type recieved for dbPassword: [$dbPassword]. dbpassword should either be String or SecureString type. "
	    break
      }
      $dataSource = "(DESCRIPTION = " +
      "(ADDRESS = (PROTOCOL = TCP)(HOST = $dbServer)(PORT = $dbPort))" +
      "(CONNECT_DATA =" +
      "(SERVICE_NAME = $dbName))" +
      ");"
      $connectionString = "Data Source=$dataSource;User Id=$dbUserName;Password=$password;"
      $connection = New-Object System.Data.OracleClient.OracleConnection ($connectionString)
    } else {
      Write-Error "Unsupported DB type received: [$dbType]"
      break
    }
  }

  process {
    try {
      $connection.Open()
    } catch {
      Write-Error "Failed to connect to database server: [$dbServer], $_"
      break
    }
    Write-Host "Successfully connected to $dbType database: [$dbServer]"
    return New-Object pscustomobject -Property @{ dbConnection = $connection; dbTablePrefix = $dbTablePrefix; }
  }

  end {
    [System.gc]::collect()
  }
}

function Disconnect-HVEvent {
<#
.SYNOPSIS
   This function is used to disconnect the database connection.

.DESCRIPTION
   This function will disconnect the database connection made earlier during Connect-HVEvent function.

.PARAMETER HvDbServer
   Connection object returned by Connect-HVEvent advanced function. This is a mandatory input.

.EXAMPLE
   Disconnecting the database connection on $hvDbServer.
   Disconnect-HVEvent -HvDbServer $hvDbServer

.OUTPUTS
   None

.NOTES
    Author                      : Paramesh Oddepally.
    Author email                : poddepally@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$HvDbServer
  )

  begin {
    $dbConnection = $hvDbServer.dbConnection

    # Validate the hvDbServer type. If not of expected type, dbConnection will be null.
    if ($null -eq $dbConnection) {
      Write-Error "No valid connection object found on hvDbServer parameter: [$hvDbServer]"
      break
    }

    # validate the user connection type of dbConnection
    if (!$dbConnection.GetType().name.Equals("SqlConnection") -and !$dbConnection.GetType().name.Equals("OracleConnection")) {
      Write-Error "The dbConnection object in hvDbServer parameter is not an SQL/Oracle DB connection: [$hvDbServer.GetType().Name]"
      break
    }
  }

  process {
    $dbConnection.Close()
    Write-Host "Successfully closed the database connection"
  }

  end {
    [System.gc]::collect()
  }
}

function Get-HVEvent {
<#
.SYNOPSIS
   Queries the events from event database configured on Connection Server.

.DESCRIPTION
   This function is used to query the events information from event database. It returns the object that has events in five columns as UserName, Severity, EventTime, Module and Message. EventTime will show the exact time when the event got registered in the database and it follows timezone on database server.
   User can apply different filters on the event columns using the filter parameters userFilter, severityFilter, timeFilter, moduleFilter, messageFilter. Mention that when multiple filters are provided then rows which satisify all the filters will be returned.

.PARAMETER HvDbServer
   Connection object returned by Connect-HVEvent advanced function.

.PARAMETER TimePeriod
   Timeperiod of the events that user is interested in. It can take following four values:
      'day' - Lists last one day events from database
      'week' - Lists last 7 days events from database
      'month' - Lists last 30 days events from database
      'all' - Lists all the events stored in database

.PARAMETER FilterType
   Type of filter action to be applied. The parameters userfilter, severityfilter, timefilter, modulefilter, messagefilter can be used along with this. It can take following values:
      'contains' - Retrieves the events that contains the string specified in filter parameters
      'startsWith' - Retrieves the events that starts with the string specified in filter parameters
      'isExactly' - Retrieves the events that exactly match with the string specified in filter parameters

.PARAMETER UserFilter
   String that can applied in filtering on 'UserName' column.

.PARAMETER SeverityFilter
   String that can applied in filtering on 'Severity' column.

.PARAMETER TimeFilter
   String that can applied in filtering on 'EventTime' column.

.PARAMETER ModuleFilter
   String that can applied in filtering on 'Module' column.

.PARAMETER MessageFilter
   String that can applied in filtering on 'Message' column.

.EXAMPLE
   Querying all the database events on database $hvDbServer.
   $e = Get-HVEvent -hvDbServer $hvDbServer
   $e.Events

.EXAMPLE
   Querying all the database events where user name startswith 'aduser', severity is of 'err' type, having module name as 'broker', message starting with 'aduser' and time starting with 'HH:MM:SS.fff'.
   The resulting events will be exported to a csv file 'myEvents.csv'.
   $e = Get-HVEvent -HvDbServer $hvDbServer -TimePeriod 'all' -FilterType 'startsWith' -UserFilter 'aduser' -SeverityFilter 'err' -TimeFilter 'HH:MM:SS.fff' -ModuleFilter 'broker' -MessageFilter 'aduser'
   $e.Events | Export-Csv -Path 'myEvents.csv' -NoTypeInformation

.OUTPUTS
   Returns a custom object that has events information in 'Events' property. Events property will have events information with five columns: UserName, Severity, EventTime, Module and Message.

.NOTES
    Author                      : Paramesh Oddepally.
    Author email                : poddepally@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$HvDbServer,

    [Parameter(Mandatory = $false)]
    [ValidateSet('day','week','month','all')]
    [string]$TimePeriod = 'all',

    [Parameter(Mandatory = $false)]
    [ValidateSet('contains','startsWith','isExactly')]
    [string]$FilterType = 'contains',

    [Parameter(Mandatory = $false)]
    [string]$UserFilter = "",

    [Parameter(Mandatory = $false)]
    [string]$SeverityFilter = "",

    [Parameter(Mandatory = $false)]
    [string]$TimeFilter = "",

    [Parameter(Mandatory = $false)]
    [string]$ModuleFilter = "",

    [Parameter(Mandatory = $false)]
    [string]$MessageFilter = ""
  )

  begin {
    $dbConnection = $hvDbServer.dbConnection
    $dbTablePrefix = $hvDbServer.dbTablePrefix

    # database table names
    $eventTable = $dbTablePrefix + "event"
    $eventDataTable = $dbTablePrefix + "event_data"

    # Verify the connection type in connectObject type
    $isSqlType = $dbConnection.GetType().name.Equals("SqlConnection")
    $isOracleType = $dbConnection.GetType().name.Equals("OracleConnection")

    if ($isSqlType) {
      $command = New-Object System.Data.Sqlclient.Sqlcommand
      $adapter = New-Object System.Data.SqlClient.SqlDataAdapter
    } elseif ($isOracleType) {
      $command = New-Object System.Data.OracleClient.OracleCommand
      $adapter = New-Object System.Data.OracleClient.OracleDataAdapter
    } else {
      Write-Error "The dbConnection object in hvDbServer parameter is not an SQL/Oracle DB connection:[$dbConnection.GetType().Name] "
      break
    }
  }

  process {
    $command.Connection = $dbConnection

    # Extract the filter parameters and build the filterQuery string
    $filterQuery = ""

    if ($userFilter -ne "") {
      $filterQuery = $filterQuery + " UserSID.StrValue"
      if ($filterType -eq 'contains') { $filterQuery = $filterQuery + " LIKE '%$userFilter%'" }
      elseif ($filterType -eq 'startsWith') { $filterQuery = $filterQuery + " LIKE '$userFilter%'" }
      else { $filterQuery = $filterQuery + " LIKE '$userFilter'" }
    }

    if ($severityFilter -ne "") {
      if ($filterQuery -ne "") { $filterQuery = $filterQuery + " AND" }
      $filterQuery = $filterQuery + " Severity"
      if ($filterType -eq 'contains') { $filterQuery = $filterQuery + " LIKE '%$severityFilter%'" }
      elseif ($filterType -eq 'startsWith') { $filterQuery = $filterQuery + " LIKE '$severityFilter%'" }
      else { $filterQuery = " LIKE '$severityFilter'" }
    }

    if ($moduleFilter -ne "") {
      if ($filterQuery -ne "") { $filterQuery = $filterQuery + " AND" }
      $filterQuery = $filterQuery + " Module"
      if ($filterType -eq 'contains') { $filterQuery = $filterQuery + " LIKE '%$moduleFilter%'" }
      elseif ($filterType -eq 'startsWith') { $filterQuery = $filterQuery + " LIKE '$moduleFilter%'" }
      else { $filterQuery = " LIKE '$moduleFilter'" }
    }

    if ($messageFilter -ne "") {
      if ($filterQuery -ne "") { $filterQuery = $filterQuery + " AND" }
      $filterQuery = $filterQuery + " ModuleAndEventText"
      if ($filterType -eq 'contains') { $filterQuery = $filterQuery + " LIKE '%$messageFilter%'" }
      elseif ($filterType -eq 'startsWith') { $filterQuery = $filterQuery + " LIKE '$messageFilter%'" }
      else { $filterQuery = " LIKE '$messageFilter'" }
    }

    if ($timeFilter -ne "") {
      if ($filterQuery -ne "") { $filterQuery = $filterQuery + " AND" }

      if ($isSqlType) { $filterQuery = $filterQuery + " FORMAT(Time, 'MM/dd/yyyy HH:mm:ss.fff')" }
      else { $timePeriodQuery = $filterQuery = $filterQuery + " TO_CHAR(Time, 'MM/DD/YYYY HH24:MI:SS.FF3')" }

      if ($filterType -eq 'contains') { $filterQuery = $filterQuery + " LIKE '%$timeFilter%'" }
      elseif ($filterType -eq 'startsWith') { $filterQuery = $filterQuery + " LIKE '$timeFilter%'" }
      else { $filterQuery = " LIKE '$timeFilter'" }
    }


    # Calculate the Timeperiod and build the timePeriodQuery string
    # It queries the current time from database server and calculates the time range
    if ($timePeriod -eq 'day') {
      $timeInDays = 1
    } elseif ($timePeriod -eq 'week') {
      $timeInDays = 7
    } elseif ($timePeriod -eq 'month') {
      $timeInDays = 30
    } else {
      $timeInDays = 0
    }

    if ($isSqlType) {
      $query = "SELECT CURRENT_TIMESTAMP"
    } else {
      $query = "SELECT CURRENT_TIMESTAMP from dual"
    }

    $command.CommandText = $query
    $adapter.SelectCommand = $command
    $DataTable = New-Object System.Data.DataTable
    $adapter.Fill($DataTable)

    $toDate = $DataTable.Rows[0][0]
    $fromDate = $toDate.AddDays(- ($timeInDays))

    if ($timePeriod -eq 'all') {
      if ($isSqlType) { $timePeriodQuery = " FORMAT(Time, 'MM/dd/yyyy HH:mm:ss.fff') < '" + $toDate + "'" }
      else { $timePeriodQuery = " TO_CHAR(Time, 'MM/DD/YYYY HH24:MI:SS.FF3') < '" + $toDate + "'" }
    } else {
      if ($isSqlType) { $timePeriodQuery = " FORMAT(Time, 'MM/dd/yyyy HH:mm:ss.fff')   BETWEEN '" + $fromDate + "' AND  '" + $toDate + "'" }
      else { $timePeriodQuery = " TO_CHAR(Time, 'MM/DD/YYYY HH24:MI:SS.FF3') BETWEEN '" + $fromDate + "' AND  '" + $toDate + "'" }
    }


    # Build the Query string based on the database type and filter parameters
    if ($isSqlType) {
      $query = "SELECT  UserSID.StrValue AS UserName, Severity, FORMAT(Time, 'MM/dd/yyyy HH:mm:ss.fff') as EventTime, Module, ModuleAndEventText AS Message FROM $eventTable " +
      " LEFT OUTER JOIN (SELECT EventID, StrValue FROM $eventDataTable WITH (NOLOCK)  WHERE (Name = 'UserDisplayName')) UserSID ON $eventTable.EventID = UserSID.EventID "
      $query = $query + " WHERE $timePeriodQuery"
      if ($filterQuery -ne "") { $query = $query + " AND $filterQuery" }
      $query = $query + " ORDER BY EventTime DESC"
    } else {
      $query = " SELECT UserSID.StrValue AS UserName, Severity, TO_CHAR(Time, 'MM/DD/YYYY HH24:MI:SS.FF3') AS EventTime, Module, ModuleAndEventText AS Message FROM $eventTable " +
      " LEFT OUTER JOIN (SELECT EventID, StrValue FROM $eventDataTable WHERE (Name = 'UserDisplayName')) UserSID ON $eventTable.EventID = UserSID.EventID"
      $query = $query + " WHERE $timePeriodQuery"
      if ($filterQuery -ne "") { $query = $query + " AND $filterQuery" }
      $query = $query + " ORDER BY EventTime DESC"
    }

    $command.CommandText = $query
    $adapter.SelectCommand = $command

    $DataTable = New-Object System.Data.DataTable
    $adapter.Fill($DataTable) | Out-Null

    Write-Host "Number of records found : " $DataTable.Rows.Count

    <#
     # This code allows the events to get printed on console
      Write-Host " User     Time     Severity     Module     ModuleAndEventText "
      Foreach($row in $DataTable.Rows) {
        Write-Host $row[0]  "   "  $row[1]  " "  $row[2]  " "  $row[3]  " "  $row[4]  " "
      }#>
    return New-Object pscustomobject -Property @{ Events = $DataTable; }
  }

  end {
    [System.gc]::collect()
  }
}

function Get-HVFarm {
<#
.SYNOPSIS
    This function is used to find farms based on the search criteria provided by the user.

.DESCRIPTION
    This function queries the specified Connection Server for farms which are configured on the server. If no farm is configured on the specified connection server or no farm matches the given search criteria, it will return null.

.PARAMETER FarmName
    farmName to be searched

.PARAMETER FarmDisplayName
    farmDisplayName to be searched

.PARAMETER FarmType
    farmType to be searched. It can take following values:
    "AUTOMATED"	- search for automated farms only
    'MANUAL' - search for manual farms only

.PARAMETER Enabled
    search for farms which are enabled

.PARAMETER Full
    Switch to get list of FarmSummaryView or FarmInfo objects in the result. If it is true a list of FarmInfo objects is returned ohterwise a list of FarmSummaryView objects is returned.

.PARAMETER HvServer
    Reference to Horizon View Server to query the data from. If the value is not passed or null then first element from global:DefaultHVServers would be considered inplace of hvServer.

.EXAMPLE
     Queries and returns farmInfo based on given parameter farmName
     Get-HVFarm -FarmName 'Farm-01'

.EXAMPLE
     Queries and returns farmInfo based on given parameters farmName, farmDisplayName
     Get-HVFarm -FarmName 'Farm-01' -FarmDisplayName 'Sales RDS Farm'

.EXAMPLE
     Queries and returns farmInfo based on given parameters farmName, farmType
     Get-HVFarm -FarmName 'Farm-01' -FarmType 'MANUAL'

.EXAMPLE
     Queries and returns farmInfo based on given parameters farmName, FarmType etc
     Get-HVFarm -FarmName 'Farm-01' -FarmType 'MANUAL' -Enabled $true

.EXAMPLE
     Queries and returns farmInfo based on parameter farmName with wild character *
     Get-HVFarm -FarmName 'Farm-0*'

.OUTPUTs
    Returns the list of FarmInfo object matching the query criteria.

.NOTES
    Author                      : Ankit Gupta.
    Author email                : guptaa@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]

  param(
    [Parameter(Mandatory = $false)]
    [string]
    $FarmName,

    [Parameter(Mandatory = $false)]
    [string]
    $FarmDisplayName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('MANUAL','AUTOMATED')]
    [string]
    $FarmType,

    [Parameter(Mandatory = $false)]
    [boolean]
    $Enabled,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  $services = Get-ViewAPIService -hvServer $hvServer
  if ($null -eq $services) {
    Write-Error "Could not retrieve ViewApi services from connection object"
    break
  }
  $farmList = Find-HVFarm -Param $PSBoundParameters
  if (! $farmList) {
    Write-Host "Get-HVFarm: No Farm Found with given search parameters"
    break
  }
  $farm_service_helper = New-Object VMware.Hv.FarmService
  $queryResults = @()
  foreach ($id in $farmList.id) {
    $info = $farm_service_helper.Farm_Get($services,$id)
    $queryResults += $info
  }
  $farmList = $queryResults
  return $farmList
}

function Get-HVFarmSummary {
<#
.SYNOPSIS
    This function is used to find farms based on the search criteria provided by the user.

.DESCRIPTION
    This function queries the specified Connection Server for farms which are configured on the server. If no farm is configured on the specified connection server or no farm matches the given search criteria, it will return null.

.PARAMETER FarmName
    farmName to be searched

.PARAMETER FarmDisplayName
    farmDisplayName to be searched

.PARAMETER FarmType
    farmType to be searched. It can take following values:
    "AUTOMATED"	- search for automated farms only
    'MANUAL' - search for manual farms only

.PARAMETER Enabled
    search for farms which are enabled

.PARAMETER HvServer
    Reference to Horizon View Server to query the data from. If the value is not passed or null then first element from global:DefaultHVServers would be considered inplace of hvServer.

.EXAMPLE
     Queries and returns farmSummary objects based on given parameter farmName
     Get-HVFarmSummary -FarmName 'Farm-01'

.EXAMPLE
     Queries and returns farmSummary objects based on given parameters farmName, farmDisplayName
     Get-HVFarmSummary -FarmName 'Farm-01' -FarmDisplayName 'Sales RDS Farm'

.EXAMPLE
     Queries and returns farmSummary objects based on given parameters farmName, farmType
     Get-HVFarmSummary -FarmName 'Farm-01' -FarmType 'MANUAL'

.EXAMPLE
     Queries and returns farmSummary objects based on given parameters farmName, FarmType etc
     Get-HVFarmSummary -FarmName 'Farm-01' -FarmType 'MANUAL' -Enabled $true

.EXAMPLE
     Queries and returns farmSummary objects based on given parameter farmName with wild character *
     Get-HVFarmSummary -FarmName 'Farm-0*'

.OUTPUTs
    Returns the list of FarmSummary object matching the query criteria.

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]

  param(
    [Parameter(Mandatory = $false)]
    [string]
    $FarmName,

    [Parameter(Mandatory = $false)]
    [string]
    $FarmDisplayName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('MANUAL','AUTOMATED')]
    [string]
    $FarmType,

    [Parameter(Mandatory = $false)]
    [boolean]
    $Enabled,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  $services = Get-ViewAPIService -hvServer $hvServer
  if ($null -eq $services) {
    Write-Error "Could not retrieve ViewApi services from connection object"
    break
  }
  Return Find-HVFarm -Param $PSBoundParameters
}

function Find-HVFarm {
   [CmdletBinding()]
   param(
    [Parameter(Mandatory = $true)]
    $Param
  )
  #
  # This translates the function arguments into the View API properties that must be queried
  $farmSelectors = @{
    'farmName' = 'data.name';
    'farmDisplayName' = 'data.displayName';
    'enabled' = 'data.enabled';
    'farmType' = 'data.type';
  }

  $params = $Param

  $query_service_helper = New-Object VMware.Hv.QueryServiceService
  $query = New-Object VMware.Hv.QueryDefinition

  $wildcard = $false
  # build the query values
  if ($params['FarmName'] -and $params['FarmName'].contains('*')) {
    $wildcard = $true
  }
  if ($params['FarmDisplayName'] -and $params['FarmDisplayName'].contains('*')) {
    $wildcard = $true
  }

  $query.queryEntityType = 'FarmSummaryView'
  if (! $wildcard) {
    [VMware.Hv.queryfilter[]]$filterSet = @()
    foreach ($setting in $farmSelectors.Keys) {
      if ($null -ne $params[$setting]) {
        $equalsFilter = New-Object VMware.Hv.QueryFilterEquals
        $equalsFilter.memberName = $farmSelectors[$setting]
        $equalsFilter.value = $params[$setting]
        $filterSet += $equalsFilter
      }
    }
    if ($filterSet.Count -gt 0) {
      $queryList = New-Object VMware.Hv.QueryFilterAnd
      $queryList.Filters = $filterset
      $query.Filter = $queryList
    }

    $queryResults = $query_service_helper.QueryService_Query($services, $query)
    $farmList = $queryResults.results
  } elseif ($wildcard -or [string]::IsNullOrEmpty($farmList)){
    $query.Filter = $null
    $queryResults = $query_service_helper.QueryService_Query($services,$query)
    $strFilterSet = @()
    foreach ($setting in $farmSelectors.Keys) {
      if ($null -ne $params[$setting]) {
        if ($wildcard -and (($setting -eq 'FarmName') -or ($setting -eq 'FarmDisplayName')) ) {
          $strFilterSet += '($_.' + $farmSelectors[$setting] + ' -like "' + $params[$setting] + '")'
        } else {
          $strFilterSet += '($_.' + $farmSelectors[$setting] + ' -eq "' + $params[$setting] + '")'
        }
      }
    }
    $whereClause =  [string]::Join(' -and ', $strFilterSet)
    $scriptBlock = [Scriptblock]::Create($whereClause)
    $farmList = $queryResults.results | where $scriptBlock
  }
  Return $farmList
}

function Get-HVPool {
<#
.Synopsis
   Gets pool(s) information with given search parameters.

.DESCRIPTION
   Queries and returns pools information, the pools list would be determined based on
   queryable fields poolName, poolDisplayName, poolType, userAssignment, enabled,
   provisioningEnabled. When more than one fields are used for query the pools which
   satisfy all fields criteria would be returned.

.PARAMETER PoolName
   Pool name to query for.
   If the value is null or not provided then filter will not be applied,
   otherwise the pools which has name same as value will be returned.

.PARAMETER PoolDisplayName
   Pool display name to query for.
   If the value is null or not provided then filter will not be applied,
   otherwise the pools which has display name same as value will be returned.

.PARAMETER PoolType
   Pool type to filter with.
   If the value is null or not provided then filter will not be applied.
   If the value is MANUAL then only manual pools would be returned.
   If the value is AUTOMATED then only automated pools would be returned
   If the value is RDS then only Remote Desktop Service Pool pools would be returned

.PARAMETER UserAssignment
   User Assignment of pool to filter with.
   If the value is null or not provided then filter will not be applied.
   If the value is DEDICATED then only dedicated pools would be returned.
   If the value is FLOATING then only floating pools would be returned

.PARAMETER Enabled
   Pool enablement to filter with.
   If the value is not provided then then filter will not be applied.
   If the value is true then only pools which are enabled would be returned.
   If the value is false then only pools which are disabled would be returned.

.PARAMETER HvServer
    Reference to Horizon View Server to query the pools from. If the value is not passed or null then
    first element from global:DefaultHVServers would be considered inplace of hvServer

.EXAMPLE
   Queries and returns pool object(s) based on given parameters poolName, poolType etc.
   Get-HVPool -PoolName 'mypool' -PoolType MANUAL -UserAssignment FLOATING -Enabled $true -ProvisioningEnabled $true

.EXAMPLE
   Queries and returns pool object(s) based on given parameters poolType and userAssignment
   Get-HVPool -PoolType AUTOMATED -UserAssignment FLOATING

.EXAMPLE
   Queries and returns pool object(s) based on given parameters poolName, PoolType etc.
   Get-HVPool -PoolName 'myrds' -PoolType RDS -UserAssignment DEDICATED -Enabled $false

.EXAMPLE
   Queries and returns pool object(s) based on given parameters poolName and HvServer etc.
   Get-HVPool -PoolName 'myrds' -PoolType RDS -UserAssignment DEDICATED -Enabled $false -HvServer $mycs

.OUTPUTS
   Returns list of objects of type DesktopInfo

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]

  param(
    [Parameter(Mandatory = $false)]
    [string]
    $PoolName,

    [Parameter(Mandatory = $false)]
    [string]
    $PoolDisplayName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('MANUAL','AUTOMATED','RDS')]
    [string]
    $PoolType,

    [Parameter(Mandatory = $false)]
    [ValidateSet('FLOATING','DEDICATED')]
    [string]
    $UserAssignment,

    [Parameter(Mandatory = $false)]
    [boolean]
    $Enabled,

    [Parameter(Mandatory = $false)]
    [boolean]
    $ProvisioningEnabled,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  $services = Get-ViewAPIService -hvServer $hvServer
  if ($null -eq $services) {
    Write-Error "Could not retrieve ViewApi services from connection object"
    break
  }
  $poolList = Find-HVPool -Param $PSBoundParameters
  if (! $poolList) {
    Write-Host "Get-HVPool: No Pool Found with given search parameters"
    break
  }
  $queryResults = @()
  $desktop_helper = New-Object VMware.Hv.DesktopService
  foreach ($id in $poolList.id) {
    $info = $desktop_helper.Desktop_Get($services,$id)
    $queryResults += $info
  }
  $poolList = $queryResults
  return $poolList
}

function Get-HVPoolSummary {
<#
.Synopsis
   Gets pool summary with given search parameters.

.DESCRIPTION
   Queries and returns pools information, the pools list would be determined based on
   queryable fields poolName, poolDisplayName, poolType, userAssignment, enabled,
   provisioningEnabled. When more than one fields are used for query the pools which
   satisfy all fields criteria would be returned.

.PARAMETER PoolName
   Pool name to query for.
   If the value is null or not provided then filter will not be applied,
   otherwise the pools which has name same as value will be returned.

.PARAMETER PoolDisplayName
   Pool display name to query for.
   If the value is null or not provided then filter will not be applied,
   otherwise the pools which has display name same as value will be returned.

.PARAMETER PoolType
   Pool type to filter with.
   If the value is null or not provided then filter will not be applied.
   If the value is MANUAL then only manual pools would be returned.
   If the value is AUTOMATED then only automated pools would be returned
   If the value is RDS then only Remote Desktop Service Pool pools would be returned

.PARAMETER UserAssignment
   User Assignment of pool to filter with.
   If the value is null or not provided then filter will not be applied.
   If the value is DEDICATED then only dedicated pools would be returned.
   If the value is FLOATING then only floating pools would be returned

.PARAMETER Enabled
   Pool enablement to filter with.
   If the value is not provided then then filter will not be applied.
   If the value is true then only pools which are enabled would be returned.
   If the value is false then only pools which are disabled would be returned.

.PARAMETER HvServer
    Reference to Horizon View Server to query the pools from. If the value is not passed or null then
    first element from global:DefaultHVServers would be considered inplace of hvServer

.EXAMPLE
   Queries and returns desktopSummaryView based on given parameters poolName, poolType etc.
   Get-HVPoolSummary -PoolName 'mypool' -PoolType MANUAL -UserAssignment FLOATING -Enabled $true -ProvisioningEnabled $true

.EXAMPLE
   Queries and returns desktopSummaryView based on given parameters poolType, userAssignment.
   Get-HVPoolSummary -PoolType AUTOMATED -UserAssignment FLOATING

.EXAMPLE
   Queries and returns desktopSummaryView based on given parameters poolName, poolType, userAssignment etc.
   Get-HVPoolSummary -PoolName 'myrds' -PoolType RDS -UserAssignment DEDICATED -Enabled $false

.EXAMPLE
   Queries and returns desktopSummaryView based on given parameters poolName, HvServer etc.
   Get-HVPoolSummary -PoolName 'myrds' -PoolType RDS -UserAssignment DEDICATED -Enabled $false -HvServer $mycs

.OUTPUTS
   Returns list of DesktopSummaryView

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]

  param(
    [Parameter(Mandatory = $false)]
    [string]
    $PoolName,

    [Parameter(Mandatory = $false)]
    [string]
    $PoolDisplayName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('MANUAL','AUTOMATED','RDS')]
    [string]
    $PoolType,

    [Parameter(Mandatory = $false)]
    [ValidateSet('FLOATING','DEDICATED')]
    [string]
    $UserAssignment,

    [Parameter(Mandatory = $false)]
    [boolean]
    $Enabled,

    [Parameter(Mandatory = $false)]
    [boolean]
    $ProvisioningEnabled,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  $services = Get-ViewAPIService -hvServer $hvServer
  if ($null -eq $services) {
    Write-Error "Could not retrieve ViewApi services from connection object"
    break
  }
  Return Find-HVPool -Param $psboundparameters
}

function Find-HVPool {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    $Param
  )

  # This translates the function arguments into the View API properties that must be queried
  $poolSelectors = @{
    'poolName' = 'desktopSummaryData.name';
    'poolDisplayName' = 'desktopSummaryData.displayName';
    'enabled' = 'desktopSummaryData.enabled';
    'poolType' = 'desktopSummaryData.type';
    'userAssignment' = 'desktopSummaryData.userAssignment';
    'provisioningEnabled' = 'desktopSummaryData.provisioningEnabled'
  }

  $params = $Param

  $query_service_helper = New-Object VMware.Hv.QueryServiceService
  $query = New-Object VMware.Hv.QueryDefinition

  $wildCard = $false
  #Only supports wild card '*'
  if ($params['PoolName'] -and $params['PoolName'].contains('*')) {
    $wildcard = $true
  }
  if ($params['PoolDisplayName'] -and $params['PoolDisplayName'].contains('*')) {
    $wildcard = $true
  }
  # build the query values
  $query.queryEntityType = 'DesktopSummaryView'
  if (! $wildcard) {
    [VMware.Hv.queryfilter[]]$filterSet = @()
    foreach ($setting in $poolSelectors.Keys) {
      if ($null -ne $params[$setting]) {
        $equalsFilter = New-Object VMware.Hv.QueryFilterEquals
        $equalsFilter.memberName = $poolSelectors[$setting]
        $equalsFilter.value = $params[$setting]
        $filterSet += $equalsFilter
      }
    }
    if ($filterSet.Count -gt 0) {
      $andFilter = New-Object VMware.Hv.QueryFilterAnd
      $andFilter.Filters = $filterset
      $query.Filter = $andFilter
    }
    $queryResults = $query_service_helper.QueryService_Query($services,$query)
    $poolList = $queryResults.results
  }
  if ($wildcard -or [string]::IsNullOrEmpty($poolList)) {
    $query.Filter = $null
    $queryResults = $query_service_helper.QueryService_Query($services,$query)
    $strFilterSet = @()
    foreach ($setting in $poolSelectors.Keys) {
      if ($null -ne $params[$setting]) {
        if ($wildcard -and (($setting -eq 'PoolName') -or ($setting -eq 'PoolDisplayName')) ) {
          $strFilterSet += '($_.' + $poolSelectors[$setting] + ' -like "' + $params[$setting] + '")'
        } else {
          $strFilterSet += '($_.' + $poolSelectors[$setting] + ' -eq "' + $params[$setting] + '")'
        }
      }
    }
    $whereClause =  [string]::Join(' -and ', $strFilterSet)
    $scriptBlock = [Scriptblock]::Create($whereClause)
    $poolList = $queryResults.results | where $scriptBlock
  }
  Return $poolList
}


function Get-HVQueryFilter {
<#
.Synopsis
    Creates a VMware.Hv.QueryFilter based on input provided.

.DESCRIPTION
    This is a factory method to create a VMware.Hv.QueryFilter. The type of the QueryFilter would be determined based on switch used.

.PARAMETER MemberName
    Property path separated by . (dot) from the root of queryable data object which is being queried for

.PARAMETER MemberValue
    Value of property (memberName) which is used for filtering

.PARAMETER Eq
    Switch to create QueryFilterEquals filter

.PARAMETER Ne
    Switch to create QueryFilterNotEquals filter

.PARAMETER Contains
    Switch to create QueryFilterContains filter

.PARAMETER Startswith
    Switch to create QueryFilterStartsWith filter

.PARAMETER Not
    Switch to create QueryFilterNot filter, used for negating existing filter

.PARAMETER And
    Switch to create QueryFilterAnd filter, used for joing two or more filters

.PARAMETER Or
    Switch to create QueryFilterOr filter, used for joing two or more filters

.PARAMETER Filter
    Filter to used in QueryFilterNot to negate the result

.PARAMETER Filters
    List of filters to join using QueryFilterAnd or QueryFilterOr


.EXAMPLE
    Creates queryFilterEquals with given parameters memberName(position 0) and memberValue(position 2)
    Get-HVQueryFilter data.name -Eq vmware

.EXAMPLE
    Creates queryFilterEquals with given parameters memberName and memberValue
    Get-HVQueryFilter -MemberName data.name -Eq -MemberValue vmware

.EXAMPLE
    Creates queryFilterNotEquals filter with given parameters memberName and memberValue
    Get-HVQueryFilter data.name -Ne vmware

.EXAMPLE
    Creates queryFilterContains with given parameters memberName and memberValue
    Get-HVQueryFilter data.name -Contains vmware

.EXAMPLE
    Creates queryFilterStartsWith with given parameters memberName and memberValue
    Get-HVQueryFilter data.name -Startswith vmware

.EXAMPLE
    Creates queryFilterNot with given parameter filter
    $filter = Get-HVQueryFilter data.name -Startswith vmware
    Get-HVQueryFilter -Not $filter

.EXAMPLE
    Creates queryFilterAnd with given parameter filters array
    $filter1 = Get-HVQueryFilter data.name -Startswith vmware
    $filter2 = Get-HVQueryFilter data.name -Contains pool
    Get-HVQueryFilter -And @($filter1, $filter2)

.EXAMPLE
    Creates queryFilterOr with given parameter filters array
    $filter1 = Get-HVQueryFilter data.name -Startswith vmware
    $filter2 = Get-HVQueryFilter data.name -Contains pool
    Get-HVQueryFilter -Or @($filter1, $filter2)

.OUTPUTS
    Returns the QueryFilter object

.NOTES
    Author                      : Kummara Ramamohan.
    Author email                : kramamohan@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>
  [CmdletBinding()]
  param(
    # Type 1 parametersets which requires memberName, memberValue as input
    [Parameter(ParameterSetName = 'eq',Mandatory = $true,Position = 0)]
    [Parameter(ParameterSetName = 'contains',Mandatory = $true,Position = 0)]
    [Parameter(ParameterSetName = 'startswith',Mandatory = $true,Position = 0)]
    [Parameter(ParameterSetName = 'ne',Mandatory = $true,Position = 0)]
    [string]$MemberName,

    [Parameter(ParameterSetName = "eq",Mandatory = $true,Position = 1)]
    [switch]$Eq,

    [Parameter(ParameterSetName = "contains",Mandatory = $true,Position = 1)]
    [switch]$Contains,

    [Parameter(ParameterSetName = "startswith",Mandatory = $true,Position = 1)]
    [switch]$Startswith,

    [Parameter(ParameterSetName = "ne",Mandatory = $true,Position = 1)]
    [switch]$Ne,

    [Parameter(ParameterSetName = 'eq',Mandatory = $true,Position = 2)]
    [Parameter(ParameterSetName = 'contains',Mandatory = $true,Position = 2)]
    [Parameter(ParameterSetName = 'startswith',Mandatory = $true,Position = 2)]
    [Parameter(ParameterSetName = 'ne',Mandatory = $true,Position = 2)]
    [System.Object]$MemberValue,

    # Negation #
    [Parameter(ParameterSetName = "not",Mandatory = $true,Position = 0)]
    [switch]$Not,

    [Parameter(ParameterSetName = 'not',Mandatory = $true,Position = 1)]
    [VMware.Hv.QueryFilter]$Filter,

    # Aggregators to join more than 1 filters #
    [Parameter(ParameterSetName = 'and',Mandatory = $true,Position = 0)]
    [switch]$And,

    [Parameter(ParameterSetName = "or",Mandatory = $true,Position = 0)]
    [switch]$Or,

    [Parameter(ParameterSetName = "and",Mandatory = $true,Position = 1)]
    [Parameter(ParameterSetName = "or",Mandatory = $true,Position = 1)]
    [VMware.Hv.QueryFilter[]]$Filters
  )

  begin {
    $switchToClassName = @{
      'eq' = 'QueryFilterEquals';
      'startswith' = 'QueryFilterStartsWith';
      'contains' = 'QueryFilterContains';
      'ne' = 'QueryFilterNotEquals';
      'not' = 'QueryFilterNot';
      'and' = 'QueryFilterAnd';
      'or' = 'QueryFilterOr';
    }
  }
  process {
    $queryFilter = Get-HVObject -typeName $switchToClassName[$PsCmdlet.ParameterSetName]

    switch ($PsCmdlet.ParameterSetName) {

      { @( 'eq','startswith','contains','ne') -icontains $_ } {
        $queryFilter.memberName = $memberName
        $queryFilter.value = $membervalue
      }

      { @( 'and','or') -icontains $_ } {
        $queryFilter.filters = $filters
      }

      { @( 'not') -icontains $_ } {
        $queryFilter.filter = $filter
      }
    }
  }
  end {
    return $queryFilter
  }
}

function Get-HVQueryResult {
<#
.Synopsis
    Returns the query results from ViewApi Query Service

.DESCRIPTION
    Get-HVQueryResult is a API to query the results using ViewApi. The filtering of the returned
    list would be done based on input parameters filter, sortDescending, sortyBy, limit

.PARAMETER EntityType
    ViewApi Queryable entity type which is being queried for.The return list would be containing objects of entityType

.PARAMETER Filter
    Filter to used for filtering the results, See Get-HVQueryFilter for more information

.PARAMETER SortBy
    Data field path used for sorting the results

.PARAMETER SortDescending
    If the value is set to true (default) then the results will be sorted in descending order
    If the value is set to false then the results will be sorted in ascending order

.PARAMETER Limit
    Max number of objects to retrieve. Default would be 0 which means retieve all the results

.PARAMETER HvServer
    Reference to Horizon View Server to query the data from. If the value is not passed or null then
    first element from global:DefaultHVServers would be considered inplace of hvServer

.EXAMPLE
    Returns query results of entityType DesktopSummaryView(position 0)
    Get-HVQueryResult DesktopSummaryView

.EXAMPLE
    Returns query results of entityType DesktopSummaryView(position 0) with given filter(position 1)
    Get-HVQueryResult DesktopSummaryView (Get-HVQueryFilter data.name -Eq vmware)

.EXAMPLE
    Returns query results of entityType DesktopSummaryView with given filter
    Get-HVQueryResult -EntityType DesktopSummaryView -Filter (Get-HVQueryFilter desktopSummaryData.name -Eq vmware)

.EXAMPLE
    Returns query results of entityType DesktopSummaryView with given filter and also sorted based on dispalyName
    $myFilter = Get-HVQueryFilter data.name -Contains vmware
    Get-HVQueryResult -EntityType DesktopSummaryView -Filter $myFilter -SortBy desktopSummaryData.displayName -SortDescending $false

.EXAMPLE
    Returns query results of entityType DesktopSummaryView, maximum count equal to limit
    Get-HVQueryResult DesktopSummaryView -Limit 10

.OUTPUTS
    Returns the list of objects of entityType

.NOTES
    Author                      : Kummara Ramamohan.
    Author email                : kramamohan@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(SupportsShouldProcess = $true,
    ConfirmImpact = 'High')]
  param(
    [Parameter(Position = 0,Mandatory = $true)]
    [ValidateSet('ADUserOrGroupSummaryView','ApplicationIconInfo','ApplicationInfo','DesktopSummaryView',
      'EntitledUserOrGroupGlobalSummaryView','EntitledUserOrGroupLocalSummaryView','FarmHealthInfo',
      'FarmSummaryView','GlobalApplicationEntitlementInfo','GlobalEntitlementSummaryView',
      'MachineNamesView','MachineSummaryView','PersistentDiskInfo','PodAssignmentInfo',
      'RDSServerInfo','RDSServerSummaryView','RegisteredPhysicalMachineInfo','SampleInfo',
      'SessionLocalSummaryView','TaskInfo','URLRedirectionInfo','UserHomeSiteInfo')]
    [string]$EntityType,

    [Parameter(Position = 1,Mandatory = $false)]
    [VMware.Hv.QueryFilter]$Filter = $null,

    [Parameter(Position = 2,Mandatory = $false)]
    [string]$SortBy = $null,

    [Parameter(Position = 3,Mandatory = $false)]
    [bool]$SortDescending = $true,

    [Parameter(Position = 4,Mandatory = $false)]
    [int16]$Limit = 0,

    [Parameter(Position = 5,Mandatory = $false)]
    $HvServer = $null
  )

  begin {
    $services = Get-ViewAPIService -hvServer $hvServer

    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }

  process {
    $queryDef = New-Object VMware.Hv.QueryDefinition
    $queryDef.queryEntityType = $entityType
    $queryDef.sortDescending = $sortDescending

    if ($sortBy) {
      $queryDef.sortBy = $sortBy
    }

    if ($limit -gt 0) {
      $queryDef.limit = $limit
    }

    $queryDef.filter = $filter

    $returnList = @()
    $query_service_helper = New-Object VMware.Hv.QueryServiceService
    $queryResults = $query_service_helper.QueryService_Create($services,$queryDef)
    $returnList += $queryResults.results

    while ($queryResults -and ($queryResults.RemainingCount -gt 0)) {
      $queryResults = $query_service_helper.QueryService_GetNext($services,$queryResults.id)
      $returnList += $queryResults.results
    }

    if ($queryResults.id) {
      $query_service_helper.QueryService_Delete($services,$queryResults.id)
    }
  }

  end {
    return $returnList
  }
}


function New-HVFarm {
<#
.Synopsis
   Creates a new farm.

.DESCRIPTION
   Creates a new farm, the type would be determined based on input parameters.

.PARAMETER LinkedClone
   Switch to Create Automated Linked Clone farm.

.PARAMETER InstantClone
   Switch to Create Automated Instant Clone farm.

.PARAMETER Manual
   Switch to Create Manual farm.

.PARAMETER FarmName
   Name of the farm.

.PARAMETER FarmDisplayName
   Display name of the farm.

.PARAMETER Description
   Description of the farm.

.PARAMETER AccessGroup
   View access group can organize the servers in the farm.
   Default Value is 'Root'.

.PARAMETER Enable
    Set true to enable the farm otherwise set to false.

.PARAMETER Vcenter
    Virtual Center server-address (IP or FQDN) where the farm RDS Servers are located. This should be same as provided to the Connection Server while adding the vCenter server.

.PARAMETER ParentVM
    Base image VM for RDS Servers.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER SnapshotVM
    Base image snapshot for RDS Servers.

.PARAMETER VmFolder
    VM folder to deploy the RDSServers to.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER HostOrCluster
    Host or cluster to deploy the RDSServers in.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER ResourcePool
    Resource pool to deploy the RDSServers.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER Datastores
    Datastore names to store the RDSServer.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER UseVSAN
    Whether to use vSphere VSAN. This is applicable for vSphere 5.5 or later.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER EnableProvisioning
    Set to true to enable provision of RDSServers immediately in farm.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER StopOnProvisioningError
    Set to true to stop provisioning of all RDSServers on error.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER TransparentPageSharingScope
    The transparent page sharing scope.
    The default value is 'VM'.

.PARAMETER NamingMethod
    Determines how the VMs in the farm are named.
    Set PATTERN to use naming pattern.
    The default value is PATTERN. Currently only PATTERN is allowed.

.PARAMETER NamingPattern
    RDS Servers will be named according to the specified naming pattern.
    Value would be considered only when $namingMethod = PATTERN
    The default value is farmName + '{n:fixed=4}'.

.PARAMETER MinReady
    Minimum number of ready (provisioned) Servers during View Composer maintenance operations.
    The default value is 0.
    Applicable to Linked Clone farms.

.PARAMETER MaximumCount
    Maximum number of Servers in the farm.
    The default value is 1.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER AdContainer
    This is the Active Directory container which the Servers will be added to upon creation.
    The default value is 'CN=Computers'.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER NetBiosName
    Domain Net Bios Name.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER DomainAdmin
    Domain Administrator user name which will be used to join the domain.
    Default value is null.
    Applicable to Linked Clone and Instant Clone farms.

.PARAMETER SysPrepName
    The customization spec to use.
    Applicable to Linked Clone farms.

.PARAMETER PowerOffScriptName
    Power off script. ClonePrep can run a customization script on instant-clone machines before they are powered off. Provide the path to the script on the parent virtual machine.
    Applicable to Instant Clone farms.

.PARAMETER PowerOffScriptParameters
    Power off script parameters. Example: p1 p2 p3 
    Applicable to Instant Clone farms.

.PARAMETER PostSynchronizationScriptName
    Post synchronization script. ClonePrep can run a customization script on instant-clone machines after they are created or recovered or a new image is pushed. Provide the path to the script on the parent virtual machine.
    Applicable to Instant Clone farms.

.PARAMETER PostSynchronizationScriptParameters
    Post synchronization script parameters. Example: p1 p2 p3 
    Applicable to Instant Clone farms.

.PARAMETER RdsServers
    List of existing registered RDS server names to add into manual farm.
    Applicable to Manual farms.

.PARAMETER Spec
    Path of the JSON specification file.

.PARAMETER HvServer
    Reference to Horizon View Server to query the farms from. If the value is not passed or null then first element from global:DefaultHVServers would be considered inplace of hvServer.

.EXAMPLE
    Creates new linkedClone farm by using naming pattern 
    New-HVFarm -LinkedClone -FarmName 'LCFarmTest' -ParentVM 'Win_Server_2012_R2' -SnapshotVM 'Snap_RDS' -VmFolder 'PoolVM' -HostOrCluster 'cls' -ResourcePool 'cls' -Datastores 'datastore1 (5)' -FarmDisplayName 'LC Farm Test' -Description 'created LC Farm from PS' -EnableProvisioning $true -StopOnProvisioningError $false -NamingPattern "LCFarmVM_PS" -MinReady 1 -MaximumCount 1  -SysPrepName "RDSH_Cust2" -NetBiosName "adviewdev"

.EXAMPLE
    Creates new linkedClone farm by using naming pattern 
    New-HVFarm -InstantClone -FarmName 'ICFarmCL' -ParentVM 'vm-rdsh-ic' -SnapshotVM 'Snap_5' -VmFolder 'Instant_Clone_VMs' -HostOrCluster 'vimal-cluster' -ResourcePool 'vimal-cluster' -Datastores 'datastore1' -FarmDisplayName 'IC Farm using CL' -Description 'created IC Farm from PS command-line' -EnableProvisioning $true -StopOnProvisioningError $false -NamingPattern "ICFarmCL-" -NetBiosName "ad-vimalg"

.EXAMPLE
    Creates new linkedClone farm by using json file 
    New-HVFarm -Spec C:\VMWare\Specs\LinkedClone.json -Confirm:$false

.EXAMPLE
    Creates new linkedClone farm by using json file 
    New-HVFarm -Spec C:\VMWare\Specs\InstantCloneFarm.json -Confirm:$false

.EXAMPLE
    Creates new manual farm by using rdsServers names
    New-HVFarm -Manual -FarmName "manualFarmTest" -FarmDisplayName "manualFarmTest" -Description "Manual PS Test" -RdsServers "vm-for-rds.eng.vmware.com","vm-for-rds-2.eng.vmware.com" -Confirm:$false

.OUTPUTS
  None

.NOTES
    Author                      : Ankit Gupta.
    Author email                : guptaa@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(

    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [switch]
    $LinkedClone,

    [Parameter(Mandatory = $true,ParameterSetName = "INSTANT_CLONE")]
    [switch]
    $InstantClone,

    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [switch]
    $Manual,

    #farmSpec.farmData.name
    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = "INSTANT_CLONE")]
    [string]
    $FarmName,

    #farmSpec.farmData.displayName
    [Parameter(Mandatory = $false)]
    [string]
    $FarmDisplayName = $farmName,

    #farmSpec.farmData.description
    [Parameter(Mandatory = $false)]
    [string]
    $Description = ' ',

    #farmSpec.farmData.accessGroup
    [Parameter(Mandatory = $false)]
    [string]
    $AccessGroup = 'Root',

    #farmSpec.farmData.enabled
    [Parameter(Mandatory = $false)]
    [boolean]
    $Enable = $true,

    #farmSpec.data.settings.disconnectedSessionTimeoutPolicy
    [Parameter(Mandatory = $false)]
    [ValidateSet("IMMEDIATE","NEVER","AFTER")]
    [string]
    $DisconnectedSessionTimeoutPolicy  = "NEVER",

    #farmSpec.data.settings.disconnectedSessionTimeoutMinutes
    [Parameter(Mandatory = $false)]
    [ValidateRange(1,[Int]::MaxValue)]
    [int]
    $DisconnectedSessionTimeoutMinutes,
    
    #farmSpec.data.settings.emptySessionTimeoutPolicy
    [Parameter(Mandatory = $false)]
    [ValidateSet("NEVER","AFTER")]
    [string]
    $EmptySessionTimeoutPolicy = "AFTER",

    #farmSpec.data.settings.emptySessionTimeoutMinutes
    [Parameter(Mandatory = $false)]
    [ValidateSet(1,[Int]::MaxValue)]
    [int]
    $EmptySessionTimeoutMinutes = 1,

    #farmSpec.data.settings.logoffAfterTimeout
    [Parameter(Mandatory = $false)]
    [boolean]
    $LogoffAfterTimeout = $false,

    #farmSpec.data.displayProtocolSettings.defaultDisplayProtocol
    [Parameter(Mandatory = $false)]
    [ValidateSet("RDP","PCOIP","BLAST")]
    [string]
    $DefaultDisplayProtocol = "PCOIP",

    #farmSpec.data.displayProtocolSettings.allowDisplayProtocolOverride
    [Parameter(Mandatory = $false)]
    [boolean]
    $AllowDisplayProtocolOverride = $true,

    #farmSpec.data.displayProtocolSettings.enableHTMLAccess
    [Parameter(Mandatory = $false)]
    [boolean]
    $EnableHTMLAccess = $false,

    #farmSpec.data.serverErrorThreshold
    [Parameter(Mandatory = $false)]
    [ValidateRange(0,[Int]::MaxValue)]
    $ServerErrorThreshold = 0,

    #farmSpec.data.mirageConfigurationOverrides.overrideGlobalSetting
    [Parameter(Mandatory = $false)]
    [boolean]
    $OverrideGlobalSetting = $false,

    #farmSpec.data.mirageConfigurationOverrides.enabled
    [Parameter(Mandatory = $false)]
    [boolean]
    $MirageServerEnabled,

    #farmSpec.data.mirageConfigurationOverrides.url
    [Parameter(Mandatory = $false)]
    [string]
    $Url,

    #farmSpec.automatedfarmSpec.virtualCenter if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $Vcenter,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.parentVM if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $ParentVM,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.snapshotVM if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $SnapshotVM,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.vmFolder if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $VmFolder,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.hostOrCluster if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $HostOrCluster,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.resourcePool if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $ResourcePool,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.dataCenter if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $dataCenter,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.datastore if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [string[]]
    $Datastores,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.datastores.storageOvercommit if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [string[]]
    $StorageOvercommit = $null,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.useVSAN if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [boolean]
    $UseVSAN = $false,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.enableProvsioning if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [boolean]
    $EnableProvisioning = $true,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.stopOnProvisioningError if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [boolean]
    $StopOnProvisioningError = $true,

    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $TransparentPageSharingScope = 'VM',

    #farmSpec.automatedfarmSpec.rdsServerNamingSpec.namingMethod if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [ValidateSet('PATTERN')]
    [string]
    $NamingMethod = 'PATTERN',

    #farmSpec.automatedfarmSpec.rdsServerNamingSpec.patternNamingSettings.namingPattern if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $NamingPattern = $farmName + '{n:fixed=4}',

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.minReadyVMsOnVComposerMaintenance if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [int]
    $MinReady = 0,

    #farmSpec.automatedfarmSpec.rdsServerNamingSpec.patternNamingSettings.maxNumberOfRDSServers if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [int]
    $MaximumCount = 1,

	#farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.useSeparateDatastoresReplicaAndOSDisks if INSTANT_CLONE, LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [boolean]
    $UseSeparateDatastoresReplicaAndOSDisks = $false,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.replicaDiskDatastore, if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $ReplicaDiskDatastore,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.useNativeSnapshots, if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [boolean]
    $UseNativeSnapshots = $false,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.spaceReclamationSettings.reclaimVmDiskSpace, if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [boolean]
    $ReclaimVmDiskSpace = $false,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.spaceReclamationSettings.reclamationThresholdGB
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateRange(0,[Int]::MaxValue)]
    [int]
    $ReclamationThresholdGB = 1,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.spaceReclamationSettings.blackoutTimes
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [VMware.Hv.FarmBlackoutTime[]]
    $BlackoutTimes,

    #farmSpec.automatedfarmSpec.customizationSettings.adContainer if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = "INSTANT_CLONE")]
    [string]
    $AdContainer = 'CN=Computers',

    #farmSpec.automatedfarmSpec.customizationSettings.domainAdministrator
    #farmSpec.automatedfarmSpec.customizationSettings.cloneprepCustomizationSettings.instantCloneEngineDomainAdministrator
    [Parameter(Mandatory = $true,ParameterSetName = 'LINKED_CLONE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $NetBiosName,

    #farmSpec.automatedfarmSpec.customizationSettings.domainAdministrator
    #farmSpec.automatedfarmSpec.customizationSettings.cloneprepCustomizationSettings.instantCloneEngineDomainAdministrator
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = "INSTANT_CLONE")]
    [string]
    $DomainAdmin = $null,

    #farmSpec.automatedfarmSpec.customizationSettings.reusePreExistingAccounts
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [Boolean]
    $ReusePreExistingAccounts = $false,

    #farmSpec.automatedfarmSpec.customizationSettings.sysprepCustomizationSettings.customizationSpec if LINKED_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [string]
    $SysPrepName,

    #desktopSpec.automatedfarmSpec.customizationSettings.cloneprepCustomizationSettings.powerOffScriptName if INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $PowerOffScriptName,

    #farmSpec.automatedfarmSpec.customizationSettings.cloneprepCustomizationSettings.powerOffScriptParameters if INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $PowerOffScriptParameters,

    #farmSpec.automatedfarmSpec.customizationSettings.cloneprepCustomizationSettings.postSynchronizationScriptName if INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $PostSynchronizationScriptName,

    #farmSpec.automatedfarmSpec.customizationSettings.cloneprepCustomizationSettings.postSynchronizationScriptParameters if INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $PostSynchronizationScriptParameters,

    #farmSpec.automatedfarmSpec.rdsServerMaxSessionsData.maxSessionsType if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = "INSTANT_CLONE")]
    [ValidateSet("UNLIMITED", "LIMITED")]
    [string]
    $MaxSessionsType = "UNLIMITED",

    #farmSpec.automatedfarmSpec.rdsServerMaxSessionsData.maxSessionsType if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = "INSTANT_CLONE")]
    [ValidateRange(1, [int]::MaxValue)]
    [int]
    $MaxSessions,

    #farmSpec.manualfarmSpec.rdsServers
    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [string[]]
    $RdsServers,

    [Parameter(Mandatory = $false,ParameterSetName = 'JSON_FILE')]
    [string]
    $Spec,

    [Parameter(Mandatory = $false)]
    $HvServer = $null

  )
  #
  # farmSpec/FarmInfo
  #   *farmData
  #        +AccessGroupId
  #		 +FarmSessionSettings
  #   FarmAutomatedfarmSpec/FarmAutomatedFarmData
  #        */+VirtualCenterId
  #        FarmRDSServerNamingSpec/FarmVirtualMachineNamingSettings
  #                FarmPatternNamingSpec/FarmPatternNamingSettings
  #        FarmVirtualCenterProvisioningSettings
  #                FarmVirtualCenterProvisioningData/virtualCenterProvisioningData
  #                FarmVirtualCenterStorageSettings
  #                FarmVirtualCenterNetworkingSettings
  #        FarmVirtualCenterManagedCommonSettings
  #        FarmCustomizationSettings
  #                ViewComposerDomainAdministratorId
  #                ADContainerId
  #                FarmSysprepCustomizationSettings
  #                      CustomizationSpecId
  #                FarmCloneprepCustomizationSettings
  #                      InstantCloneEngineDomainAdministratorId
  #
  #   FarmManualfarmSpec
  #        RDSServerId[]
  #

  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }

  process {

    if ($farmName) {
      try {
        $sourceFarm = Get-HVFarmSummary -farmName $farmName -hvServer $hvServer
      } catch {
        Write-Error "Make sure Get-HVFarmSummary advanced function is loaded, $_"
        break
      }
      if ($sourceFarm) {
        Write-Error "Farm with name [$farmName] already exists"
        return
      }
    }
    $farm_service_helper = New-Object VMware.Hv.FarmService
    if ($spec) {
      try {
        $jsonObject = Get-JsonObject -specFile $spec
      } catch {
        Write-Error "Json file exception, $_"
        break
      }
      try {
        Test-HVFarmSpec -PoolObject $jsonObject
      } catch {
        Write-Error "Json object validation failed, $_"
        break
      }
      if ($jsonObject.type -eq 'AUTOMATED') {
        $farmType = 'AUTOMATED'
        $provisioningType = $jsonObject.ProvisioningType
        if ($null -ne $jsonObject.AutomatedFarmSpec.VirtualCenter) {
          $vCenter = $jsonObject.AutomatedFarmSpec.VirtualCenter
        }

        $netBiosName = $jsonObject.NetBiosName
        if (!$jsonObject.AutomatedFarmSpec.CustomizationSettings.AdContainer) {
          Write-Host "adContainer was empty using CN=Computers"
        } else {
          $AdContainer = $jsonObject.AutomatedFarmSpec.CustomizationSettings.AdContainer
        }

        #populate customization settings attributes based on the cutomizationType
        if ($jsonObject.AutomatedFarmSpec.ProvisioningType -eq "INSTANT_CLONE_ENGINE") {
          $InstantClone = $true
          if ($null -ne $jsonObject.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings) {
            $DomainAdmin = $jsonObject.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings.InstantCloneEngineDomainAdministrator
            $powerOffScriptName = $jsonObject.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings.PowerOffScriptName
            $powerOffScriptParameters = $jsonObject.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings.PowerOffScriptParameters
            $postSynchronizationScriptName = $jsonObject.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings.PostSynchronizationScriptName
            $postSynchronizationScriptParameters = $jsonObject.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings.PostSynchronizationScriptParameters
          }
        } elseif ($jsonObject.AutomatedFarmSpec.ProvisioningType -eq "VIEW_COMPOSER") {
            $LinkedClone = $true
            $DomainAdmin = $jsonObject.AutomatedFarmSpec.CustomizationSettings.domainAdministrator
            $reusePreExistingAccounts = $jsonObject.AutomatedFarmSpec.CustomizationSettings.ReusePreExistingAccounts
            $sysPrepName = $jsonObject.AutomatedFarmSpec.CustomizationSettings.SysprepCustomizationSettings.CustomizationSpec
        }

        $namingMethod = $jsonObject.AutomatedFarmSpec.RdsServerNamingSpec.NamingMethod
        $namingPattern = $jsonObject.AutomatedFarmSpec.RdsServerNamingSpec.patternNamingSettings.namingPattern
        $maximumCount = $jsonObject.AutomatedFarmSpec.RdsServerNamingSpec.patternNamingSettings.maxNumberOfRDSServers
        $enableProvisioning = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.EnableProvisioning
        $stopProvisioningOnError = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.StopProvisioningOnError
        $minReady = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.MinReadyVMsOnVComposerMaintenance

        $transparentPageSharingScope = $jsonObject.AutomatedFarmSpec.virtualCenterManagedCommonSettings.TransparentPageSharingScope

        if ($null -ne $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.ParentVm) {
          $parentVM = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.ParentVm
        }
        if ($null -ne $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.Snapshot) {
          $snapshotVM = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.Snapshot
        }
        $vmFolder = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.VmFolder
        $hostOrCluster = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.HostOrCluster
        $resourcePool = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.ResourcePool
        $dataStoreList = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.Datastores

        foreach ($dtStore in $dataStoreList) {
          $datastores += $dtStore.Datastore
          $storageOvercommit += $dtStore.StorageOvercommit
        }
        $useVSan =  $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.UseVSan
        
        ## ViewComposerStorageSettings for Linked-Clone farms
        if ($LinkedClone -or $InstantClone) {
          $useSeparateDatastoresReplicaAndOSDisks = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.ViewComposerStorageSettings.UseSeparateDatastoresReplicaAndOSDisks
          if ($useSeparateDatastoresReplicaAndOSDisks) {
            $replicaDiskDatastore = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.ViewComposerStorageSettings.ReplicaDiskDatastore
          }
          if ($LinkedClone) {
            #For Instant clone desktops, this setting can only be set to false
            $useNativeSnapshots = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.ViewComposerStorageSettings.UseNativeSnapshots
            $reclaimVmDiskSpace = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.ViewComposerStorageSettings.SpaceReclamationSettings.ReclaimVmDiskSpace
            if ($reclaimVmDiskSpace) {
                $ReclamationThresholdGB = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.ViewComposerStorageSettings.SpaceReclamationSettings.ReclamationThresholdGB
                if ($null -ne $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.ViewComposerStorageSettings.SpaceReclamationSettings.blackoutTimes) {
                    $blackoutTimesList = $jsonObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.ViewComposerStorageSettings.SpaceReclamationSettings.blackoutTimes
                    foreach ($blackout in $blackoutTimesList) {
                        $blackoutObj  = New-Object VMware.Hv.DesktopBlackoutTime
                        $blackoutObj.Days = $blackout.Days
                        $blackoutObj.StartTime = $blackout.StartTime
                        $blackoutObj.EndTime = $blackoutObj.EndTime
                        $blackoutTimes += $blackoutObj
                    }
                }
            }
          }
        }

        $maxSessionsType = $jsonObject.AutomatedFarmSpec.RdsServerMaxSessionsData.MaxSessionsType
        if ($maxSessionsType -eq "LIMITED") {
            $maxSessions = $jsonObject.AutomatedFarmSpec.RdsServerMaxSessionsData.MaxSessions
        }

      } elseif ($jsonObject.type -eq 'MANUAL') {
        $manual = $true
        $farmType = 'MANUAL'
        $RdsServersObjs = $jsonObject.ManualFarmSpec.RdsServers

        foreach ($RdsServerObj in $RdsServersObjs) {
          $rdsServers += $RdsServerObj.rdsServer
        }
      }
      $farmDisplayName = $jsonObject.Data.DisplayName
      $description = $jsonObject.Data.Description
      $accessGroup = $jsonObject.Data.AccessGroup
      $farmName = $jsonObject.Data.name
      if ($null -ne $jsonObject.Data.Enabled) {
        $enable = $jsonObject.Data.Enabled
      }
      if ($null -ne $jsonObject.Data.Settings) {
        $disconnectedSessionTimeoutPolicy = $jsonObject.Data.Settings.DisconnectedSessionTimeoutPolicy
        $disconnectedSessionTimeoutMinutes = $jsonObject.Data.Settings.DisconnectedSessionTimeoutMinutes
        $emptySessionTimeoutPolicy = $jsonObject.Data.Settings.EmptySessionTimeoutPolicy
        $emptySessionTimeoutMinutes = $jsonObject.Data.Settings.EmptySessionTimeoutMinutes
        $logoffAfterTimeout = $jsonObject.Data.Settings.LogoffAfterTimeout
      }
      if ($null -ne $jsonObject.Data.DisplayProtocolSettings) {
        $defaultDisplayProtocol = $jsonObject.Data.DisplayProtocolSettings.DefaultDisplayProtocol
        $allowDisplayProtocolOverride = $jsonObject.Data.DisplayProtocolSettings.AllowDisplayProtocolOverride
        $enableHTMLAccess = $jsonObject.Data.DisplayProtocolSettings.EnableHTMLAccess
      }
      if ($null -ne $jsonObject.Data.serverErrorThreshold) {
        $serverErrorThreshold = $jsonObject.Data.serverErrorThreshold
      }
      if ($null -ne $jsonObject.Data.MirageConfigurationOverrides) {
        $overrideGlobalSetting = $jsonObject.Data.MirageConfigurationOverrides.OverrideGlobalSetting
        $mirageserverEnabled = $jsonObject.Data.MirageConfigurationOverrides.Enabled
        $url = $jsonObject.Data.MirageConfigurationOverrides.url
      }
    }

    if ($linkedClone) {
      $farmType = 'AUTOMATED'
      $provisioningType = 'VIEW_COMPOSER'
    } elseif ($InstantClone) {
      $farmType = 'AUTOMATED'
      $provisioningType = 'INSTANT_CLONE_ENGINE'
    }elseif ($manual) {
      $farmType = 'MANUAL'
    }

    $script:farmSpecObj = Get-FarmSpec -farmType $farmType -provisioningType $provisioningType -namingMethod $namingMethod

    #
    # build out the infrastructure based on type of provisioning
    #
    $handleException = $false
    switch ($farmType) {

      'MANUAL' {
        try {
          $serverList = Get-RegisteredRDSServer -services $services -serverList $rdsServers
          $farmSpecObj.ManualFarmSpec.RdsServers = $serverList
        } catch {
          $handleException = $true
          Write-Error "Failed to create Farm with error: $_"
          break
        }
      }
      default {
        #
        # accumulate properties that are shared among various type
        #

        #
        # vCenter: if $vcenterID is defined, then this is a clone
        #           if the user specificed the name, then find it from the list
        #          if none specified, then automatically use the vCenter if there is only one
        #

        if (!$virtualCenterID) {
          $virtualCenterID = Get-VcenterID -services $services -vCenter $vCenter
        }

        if ($null -eq $virtualCenterID) {
          $handleException = $true
          break
        }

        #
        # transparentPageSharingScope
        #

        if (!$farmVirtualCenterManagedCommonSettings) {
          if ($farmSpecObj.AutomatedFarmSpec) {
            $farmSpecObj.AutomatedFarmSpec.virtualCenterManagedCommonSettings.TransparentPageSharingScope = $transparentPageSharingScope
          }
          $farmVirtualCenterManagedCommonSettings = $farmSpecObj.AutomatedFarmSpec.virtualCenterManagedCommonSettings
        }

        if ($farmSpecObj.AutomatedFarmSpec.RdsServerNamingSpec) {
          $farmSpecObj.AutomatedFarmSpec.RdsServerNamingSpec.NamingMethod = $namingMethod
          $farmSpecObj.AutomatedFarmSpec.RdsServerNamingSpec.patternNamingSettings.namingPattern = $namingPattern
          $farmSpecObj.AutomatedFarmSpec.RdsServerNamingSpec.patternNamingSettings.maxNumberOfRDSServers = $maximumCount
        } else {
          $vmNamingSpec = New-Object VMware.Hv.FarmRDSServerNamingSpec
          $vmNamingSpec.NamingMethod = $namingMethod
          $vmNamingSpec.patternNamingSettings = New-Object VMware.Hv.FarmPatternNamingSettings
          $vmNamingSpec.patternNamingSettings.namingPattern = $namingPattern
          $vmNamingSpec.patternNamingSettings.maxNumberOfRDSServers = $maximumCount
          $farmSpecObj.AutomatedFarmSpec.RdsServerNamingSpec = $vmNamingSpec
        }

        #
        # build the VM LIST
        #
        try {
          $farmVirtualCenterProvisioningData = Get-HVFarmProvisioningData -vc $virtualCenterID -vmObject $farmVirtualCenterProvisioningData

          $HostOrCluster_helper = New-Object VMware.Hv.HostOrClusterService
          $hostClusterIds = (($HostOrCluster_helper.HostOrCluster_GetHostOrClusterTree($services, $farmVirtualCenterProvisioningData.datacenter)).treeContainer.children.info).Id
          $farmVirtualCenterStorageSettings = Get-HVFarmStorageObject -hostclusterIDs $hostClusterIds -storageObject $farmVirtualCenterStorageSettings
          $farmVirtualCenterNetworkingSettings = Get-HVFarmNetworkSetting -networkObject $farmVirtualCenterNetworkingSettings
          $farmCustomizationSettings = Get-HVFarmCustomizationSetting -vc $virtualCenterID -customObject $farmCustomizationSettings
        } catch {
          $handleException = $true
          Write-Error "Failed to create Farm with error: $_"
          break
        }

        $farmSpecObj.AutomatedFarmSpec.RdsServerMaxSessionsData.MaxSessionsType = $maxSessionsType
        if ($maxSessionsType -eq "LIMITED") {
            $farmSpecObj.AutomatedFarmSpec.RdsServerMaxSessionsData.MaxSessionsType = $maxSessions
        }
        $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.enableProvisioning = $enableProvisioning
        $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.stopProvisioningOnError = $stopProvisioningOnError
        $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.minReadyVMsOnVComposerMaintenance = $minReady
        $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData = $farmVirtualCenterProvisioningData
        $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings = $farmVirtualCenterStorageSettings
        $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterNetworkingSettings = $FarmVirtualCenterNetworkingSettings

		$farmSpecObj.AutomatedFarmSpec.CustomizationSettings = $farmCustomizationSettings
        $farmSpecObj.AutomatedFarmSpec.ProvisioningType = $provisioningType
        $farmSpecObj.AutomatedFarmSpec.VirtualCenter = $virtualCenterID
      }
    }

    if ($handleException) {
      break
    }

    $farmData = $farmSpecObj.data
    $AccessGroup_service_helper = New-Object VMware.Hv.AccessGroupService
    $ag = $AccessGroup_service_helper.AccessGroup_List($services) | Where-Object { $_.base.name -eq $accessGroup }
    $farmData.AccessGroup = $ag.id

    $farmData.name = $farmName
    $farmData.DisplayName = $farmDisplayName
    $farmData.Description = $description
    if ($farmData.Settings) {
        $farmData.Settings.DisconnectedSessionTimeoutPolicy = $disconnectedSessionTimeoutPolicy
        if ($disconnectedSessionTimeoutPolicy -eq "AFTER") {
            $farmData.Settings.DisconnectedSessionTimeoutMinutes = $disconnectedSessionTimeoutMinutes
        }
        $farmData.Settings.EmptySessionTimeoutPolicy = $emptySessionTimeoutPolicy
        if ($emptySessionTimeoutPolicy -eq "AFTER") {
            $farmData.Settings.EmptySessionTimeoutMinutes = $emptySessionTimeoutMinutes
        }
        $logoffAfterTimeout = $farmData.Settings.logoffAfterTimeout
    }
    if ($farmData.DisplayProtocolSettings) {
        $farmData.DisplayProtocolSettings.DefaultDisplayProtocol = $defaultDisplayProtocol
        $farmData.DisplayProtocolSettings.AllowDisplayProtocolOverride = $AllowDisplayProtocolOverride
        $farmData.DisplayProtocolSettings.EnableHTMLAccess = $enableHTMLAccess
    }
    if ($farmData.MirageConfigurationOverrides){
        $farmData.MirageConfigurationOverrides.OverrideGlobalSetting = $overrideGlobalSetting
        $farmData.MirageConfigurationOverrides.Enabled = $mirageServerEnabled
        if ($url) {
            $farmData.MirageConfigurationOverrides.Url = $url
        }
    }
    $farmSpecObj.type = $farmType

    if ($FarmAutomatedFarmSpec) {
      $farmSpecObj.AutomatedFarmSpec = $FarmAutomatedFarmSpec
    }
    if ($FarmManualFarmSpec) {
      $farmSpecObj.ManualFarmSpec = $FarmManualFarmSpec
    }

    # Please uncomment below code, if you want to save the json file
    <#
    $myDebug = convertto-json -InputObject $farmSpecObj -depth 12
    $myDebug | out-file -filepath c:\temp\copiedfarm.json
    #>

    if ($pscmdlet.ShouldProcess($farmSpecObj.data.name)) {
      $Id = $farm_service_helper.Farm_Create($services, $farmSpecObj)
    } else {
	  try {
        Test-HVFarmSpec -PoolObject $farmSpecObj
      } catch {
        Write-Error "FarmSpec object validation failed, $_"
		break
      }
	}
    return $farmSpecObj
  }

  end {
    [System.gc]::collect()
  }

}

function Test-HVFarmSpec {
  param(
    [Parameter(Mandatory = $true)]
    $PoolObject
  )
  if ($null -eq $PoolObject.Type) {
    Throw "Specify type of farm"
  }
  $jsonFarmTypeArray = @('AUTOMATED','MANUAL')
  if (! ($jsonFarmTypeArray -contains $PoolObject.Type)) {
    Throw "Farm type must be AUTOMATED or MANUAL"
  }
  if ($null -eq $PoolObject.Data.Name) {
    Throw "Specify farm name"
  }
  if ($null -eq $PoolObject.Data.AccessGroup) {
    Throw "Specify horizon access group"
  }
  if ($PoolObject.Type -eq "AUTOMATED"){
    $jsonProvisioningType = $PoolObject.AutomatedFarmSpec.ProvisioningType
    if ($null -eq $jsonProvisioningType) {
        Throw "Must specify provisioningType"
    }
    if ($null -eq $PoolObject.AutomatedFarmSpec.RdsServerNamingSpec.namingMethod) {
        Throw "Must specify naming method to PATTERN"
    }
    if ($null -eq  $PoolObject.AutomatedFarmSpec.RdsServerNamingSpec.patternNamingSettings) {
        Throw "Specify Naming pattern settings"
    }
    if ($null -eq $PoolObject.AutomatedFarmSpec.RdsServerNamingSpec.patternNamingSettings.namingPattern) {
        Throw "Specify specified naming pattern"
    }
    if ($null -eq $PoolObject.AutomatedFarmSpec.virtualCenterProvisioningSettings.enableProvisioning) {
        Throw "Specify Whether to enable provisioning or not"
    }
    if ($null -eq $PoolObject.AutomatedFarmSpec.virtualCenterProvisioningSettings.stopProvisioningOnError) {
        Throw "Specify Whether provisioning on all VMs stops on error"
    }
    $jsonTemplate = $PoolObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.Template
    $jsonParentVm = $PoolObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.ParentVm
    $jsonSnapshot = $PoolObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.Snapshot
    $jsonVmFolder = $PoolObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.VmFolder
    $jsonHostOrCluster = $PoolObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.HostOrCluster
    $ResourcePool = $PoolObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.ResourcePool
    if (!( ($null -ne $jsonTemplate) -or (($null -ne $jsonParentVm) -and ($null -ne $jsonSnapshot) )) ) {
       Throw "Must specify Template or (ParentVm and Snapshot) names"
    }
    if ($null -eq $jsonVmFolder) {
       Throw "Must specify VM folder to deploy the VMs"
    }
    if ($null -eq $jsonHostOrCluster) {
       Throw "Must specify Host or cluster to deploy the VMs"
    }
    if ($null -eq $resourcePool) {
       Throw "Must specify Resource pool to deploy the VMs"
    }
    if ($null -eq $PoolObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.Datastores) {
       Throw "Must specify datastores names"
    }
    if ($null -eq $PoolObject.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.useVSan) {
       Throw "Must specify whether to use virtual SAN or not"
    }
    $customizationType = $PoolObject.AutomatedFarmSpec.CustomizationSettings.customizationType
    if ($null -eq $customizationType) {
        Throw "Specify customization type"
    }
    if ($customizationType -eq 'SYS_PREP' -and $null -eq $PoolObject.AutomatedFarmSpec.CustomizationSettings.SysprepCustomizationSettings) {
        Throw "Specify sysPrep customization settings"
    }
    if ($customizationType -eq 'CLONE_PREP' -and $null -eq $PoolObject.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings) {
        Throw "Specify clone customization settings"
    }
    if ($null -eq $PoolObject.AutomatedFarmSpec.RdsServerMaxSessionsData.MaxSessionsType) {
        Throw "Specify MaxSessionsType"
    }
  } elseif ($PoolObject.Type -eq "MANUAL") {
    if ($null -eq $PoolObject.manualFarmSpec.rdsServers) {
        Throw "Specify rdsServers name"
    }
  }
}


function Get-HVFarmProvisioningData {
  param(
    [Parameter(Mandatory = $false)]
    [VMware.Hv.FarmVirtualCenterProvisioningData]$VmObject,

    [Parameter(Mandatory = $true)]
    [VMware.Hv.VirtualCenterId]$VcID
  )
  if (!$vmObject) {
    $vmObject = $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData
  }
  if ($parentVM) {
    $BaseImage_service_helper = New-Object VMware.Hv.BaseImageVmService
    $parentList = $BaseImage_service_helper.BaseImageVm_List($services, $vcID)
    $parentVMObj = $parentList | Where-Object { $_.name -eq $parentVM }
    if ($null -eq $parentVMObj) {
      throw "No Parent VM found with name: [$parentVM]"
    }
    $vmObject.ParentVm = $parentVMObj.id
    $dataCenterID = $parentVMObj.datacenter
    if ($dataCenter -and $dataCenterID) {
        $baseImageVmInfo = $base_imageVm_helper.BaseImageVm_ListByDatacenter($dataCenterID)
        if (! ($baseImageVmInfo.Path -like "/$dataCenter/*")) {
            throw "$parentVM not exists in datacenter: [$dataCenter]"
        }
    }
    $vmObject.datacenter = $dataCenterID
  }
  if ($snapshotVM) {
    $BaseImageSnapshot_service_helper = New-Object VMware.Hv.BaseImageSnapshotService
    $snapshotList = $BaseImageSnapshot_service_helper.BaseImageSnapshot_List($services, $parentVMObj.id)
    $snapshotVMObj = $snapshotList | Where-Object { $_.name -eq $snapshotVM }
    if ($null -eq $snapshotVMObj) {
      throw "No Snapshot found with name: [$snapshotVM] for VM name: [$parentVM] "
    }
    $vmObject.Snapshot = $snapshotVMObj.id
  }
  if ($vmFolder) {
    $VmFolder_service_helper = New-Object VMware.Hv.VmFolderService
    $folders = $VmFolder_service_helper.VmFolder_GetVmFolderTree($services, $vmObject.datacenter)
    $folderList = @()
    $folderList += $folders
    while ($folderList.Length -gt 0) {
      $item = $folderList[0]
      if ($item -and !$_.folderdata.incompatiblereasons.inuse -and !$_.folderdata.incompatiblereasons.viewcomposerreplicafolder -and ($item.folderdata.name -eq $vmFolder)) {
        $vmObject.VmFolder = $item.id
        break
      }
      foreach ($folderItem in $item.children) {
        $folderList += $folderItem
      }
      $folderList = $folderList[1..$folderList.Length]
    }
    if ($null -eq $vmObject.VmFolder) {
      throw "No VM Folder found with name: [$vmFolder]"
    }
  }
  if ($hostOrCluster) {
    $HostOrCluster_service_helper = New-Object VMware.Hv.HostOrClusterService
    $hostClusterList = ($HostOrCluster_service_helper.HostOrCluster_GetHostOrClusterTree($services, $vmobject.datacenter)).treeContainer.children.info
    $HostClusterObj = $hostClusterList | Where-Object { $_.name -eq $hostOrCluster }
    if ($null -eq $HostClusterObj) {
      throw "No host or cluster found with name: [$hostOrCluster]"
    }
    $vmObject.HostOrCluster = $HostClusterObj.id
  }
  if ($resourcePool) {
    $ResourcePool_service_helper = New-Object VMware.Hv.ResourcePoolService
    $resourcePoolList = $ResourcePool_service_helper.ResourcePool_GetResourcePoolTree($services, $vmobject.HostOrCluster)
    $resourcePoolObj = $resourcePoolList | Where-Object { $_.resourcepooldata.name -eq $resourcePool }
    if ($null -eq $resourcePoolObj) {
      throw "No resource pool found with name: [$resourcePool]"
    }
    $vmObject.ResourcePool = $resourcePoolObj.id
  }
  return $vmObject
}


function Get-HVFarmStorageObject {
  param(

    [Parameter(Mandatory = $true)]
    [VMware.Hv.HostOrClusterId[]]$HostClusterIDs,
	
	[Parameter(Mandatory = $false)]
    [VMware.Hv.FarmVirtualCenterStorageSettings]$StorageObject
  )
  if (!$storageObject) {
    $storageObject = New-Object VMware.Hv.FarmVirtualCenterStorageSettings

    $FarmSpaceReclamationSettings = New-Object VMware.Hv.FarmSpaceReclamationSettings -Property @{ 'reclaimVmDiskSpace' = $false }
    if ($reclaimVmDiskSpace) {
        $FarmSpaceReclamationSettings.ReclamationThresholdGB = $reclamationThresholdGB
        if ($blackoutTimes) {
          $FarmSpaceReclamationSettings.BlackoutTimes = $blackoutTimes
        }
    }

    $FarmViewComposerStorageSettingsList = @{
      'useSeparateDatastoresReplicaAndOSDisks' = $UseSeparateDatastoresReplicaAndOSDisks;
      'useNativeSnapshots' = $useNativeSnapshots;
      'spaceReclamationSettings' = $FarmSpaceReclamationSettings;
    }

    $storageObject.ViewComposerStorageSettings = New-Object VMware.Hv.FarmViewComposerStorageSettings -Property $FarmViewComposerStorageSettingsList
  }

  if ($datastores) {
    if ($StorageOvercommit -and  ($datastores.Length -ne  $StorageOvercommit.Length) ) {
        throw "Parameters datastores length: [$datastores.Length] and StorageOvercommit length: [$StorageOvercommit.Length] should be of same size"
    }
    $Datastore_service_helper = New-Object VMware.Hv.DatastoreService
    foreach ($hostClusterID in $hostClusterIDs) {
        $datastoreList += $Datastore_service_helper.Datastore_ListDatastoresByHostOrCluster($services, $hostClusterID)
    }
    $datastoresSelected = @()
    foreach ($ds in $datastores) {
      $datastoresSelected += ($datastoreList | Where-Object { $_.datastoredata.name -eq $ds }).id
    }
    if (! $storageOvercommit) {
      foreach ($ds in $datastoresSelected) {
        $storageOvercommit += ,'UNBOUNDED'
      }
    } 
    $StorageOvercommitCnt = 0
    foreach ($ds in $datastoresSelected) {
      $datastoresObj = New-Object VMware.Hv.FarmVirtualCenterDatastoreSettings
      $datastoresObj.Datastore = $ds
      $datastoresObj.StorageOvercommit =  $storageOvercommit[$StorageOvercommitCnt]
      $StorageObject.Datastores += $datastoresObj
    }
    if ($useSeparateDatastoresReplicaAndOSDisks) {
        $StorageObject.ViewComposerStorageSettings.UseSeparateDatastoresReplicaAndOSDisks = $UseSeparateDatastoresReplicaAndOSDisks
        $FarmReplicaDiskDatastore = ($datastoreList | Where-Object { $_.datastoredata.name -eq $replicaDiskDatastore }).id
        $StorageObject.ViewComposerStorageSettings.ReplicaDiskDatastore = $FarmReplicaDiskDatastore
    }

  }
  if ($storageObject.Datastores.Count -eq 0) {
    throw "No datastores found with name: [$datastores]"
  }
  if ($useVSAN) { $storageObject.useVSAN = $useVSAN }
  return $storageObject
}


function Get-HVFarmNetworkSetting {
  param(
    [Parameter(Mandatory = $false)]
    [VMware.Hv.FarmVirtualCenterNetworkingSettings]$NetworkObject
  )
  if (!$networkObject) {
    $networkObject = $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterNetworkingSettings
  }
  return $networkObject
}


function Get-HVFarmCustomizationSetting {
  param(
    [Parameter(Mandatory = $false)]
    [VMware.Hv.FarmCustomizationSettings]$CustomObject,

    [Parameter(Mandatory = $true)]
    [VMware.Hv.VirtualCenterId]$VcID
  )
  if (!$customObject) {
    # View Composer and Instant Clone Engine Active Directory container for QuickPrep and ClonePrep. This must be set for Instant Clone Engine or SVI sourced desktops.
    if ($InstantClone -or $LinkedClone) {
        $ad_domain_helper = New-Object VMware.Hv.ADDomainService
        $ADDomains = $ad_domain_helper.ADDomain_List($services)
        if ($netBiosName) {
          $adDomianId = ($ADDomains | Where-Object { $_.NetBiosName -eq $netBiosName } | Select-Object -Property id)
          if ($null -eq $adDomianId) {
            throw "No Domain found with netBiosName: [$netBiosName]"
          }
        } else {
          $adDomianId = ($ADDomains[0] | Select-Object -Property id)
          if ($null -eq $adDomianId) {
            throw "No Domain configured in view administrator UI"
          }
        }
        $ad_container_helper = New-Object VMware.Hv.AdContainerService
        $adContainerId = ($ad_container_helper.ADContainer_ListByDomain($services,$adDomianId.id) | Where-Object { $_.Rdn -eq $adContainer } | Select-Object -Property id).id
        if ($null -eq $adContainerId) {
          throw "No AdContainer found with name: [$adContainer]"
        }
        $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.AdContainer = $adContainerId
    }

    if ($InstantClone) {
      $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.CustomizationType = 'CLONE_PREP'
      $instantCloneEngineDomainAdministrator_helper = New-Object VMware.Hv.InstantCloneEngineDomainAdministratorService
      $instantCloneEngineDomainAdministrator = ($instantCloneEngineDomainAdministrator_helper.InstantCloneEngineDomainAdministrator_List($services) | Where-Object { $_.namesData.dnsName -match $netBiosName })
      if (![string]::IsNullOrWhitespace($domainAdmin)) {
        $instantCloneEngineDomainAdministrator = ($instantCloneEngineDomainAdministrator | Where-Object { $_.base.userName -eq $domainAdmin }).id
      } elseIf ($null -ne $instantCloneEngineDomainAdministrator) {
        $instantCloneEngineDomainAdministrator = $instantCloneEngineDomainAdministrator[0].id
      }
      if ($null -eq $instantCloneEngineDomainAdministrator) {
        throw "No Instant Clone Engine Domain Administrator found with netBiosName: [$netBiosName]"
      }
      $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings = New-Object VMware.Hv.FarmClonePrepCustomizationSettings
      $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings.InstantCloneEngineDomainAdministrator = $instantCloneEngineDomainAdministrator
      $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings.powerOffScriptName = $powerOffScriptName
      $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings.powerOffScriptParameters = $powerOffScriptParameters
      $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings.postSynchronizationScriptName = $postSynchronizationScriptName
      $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.CloneprepCustomizationSettings.postSynchronizationScriptParameters = $postSynchronizationScriptParameters
      $customObject = $farmSpecObj.AutomatedFarmSpec.CustomizationSettings
    } elseif ($LinkedClone) {
      $ViewComposerDomainAdministrator_service_helper = New-Object VMware.Hv.ViewComposerDomainAdministratorService
      $ViewComposerDomainAdministratorID = ($ViewComposerDomainAdministrator_service_helper.ViewComposerDomainAdministrator_List($services, $vcID) | Where-Object { $_.base.domain -match $netBiosName })
      if (! [string]::IsNullOrWhitespace($domainAdmin)) {
        $ViewComposerDomainAdministratorID = ($ViewComposerDomainAdministratorID | Where-Object { $_.base.userName -ieq $domainAdmin }).id
      } elseif ($null -ne $ViewComposerDomainAdministratorID) {
        $ViewComposerDomainAdministratorID = $ViewComposerDomainAdministratorID[0].id
      }
      if ($null -eq $ViewComposerDomainAdministratorID) {
        throw "No Composer Domain Administrator found with netBiosName: [$netBiosName]"
      }

      #Support only Sysprep Customization
      $sysprepCustomizationSettings = $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.SysprepCustomizationSettings
      
      # Get SysPrep CustomizationSpec ID
      $CustomizationSpec_service_helper = New-Object VMware.Hv.CustomizationSpecService
      $sysPrepIds = $CustomizationSpec_service_helper.CustomizationSpec_List($services, $vcID) | Where-Object { $_.customizationSpecData.name -eq $sysPrepName } | Select-Object -Property id
      if ($sysPrepIds.Count -eq 0) {
        throw "No Sysprep Customization spec found with Name: [$sysPrepName]"
      }
      $sysprepCustomizationSettings.CustomizationSpec = $sysPrepIds[0].id

      $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.CustomizationType = 'SYS_PREP'
      $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.DomainAdministrator = $ViewComposerDomainAdministratorID
      $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.ReusePreExistingAccounts = $reusePreExistingAccounts
      $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.SysprepCustomizationSettings = $sysprepCustomizationSettings
      $customObject = $farmSpecObj.AutomatedFarmSpec.CustomizationSettings
    }
  }
  return $customObject
}

function Get-FarmSpec {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FarmType,

    [Parameter(Mandatory = $false)]
    [string]$ProvisioningType,

    [Parameter(Mandatory = $false)]
    [string]$NamingMethod
  )

  $farm_helper = New-Object VMware.Hv.FarmService
  $farm_spec_helper = $farm_helper.getFarmSpecHelper()
  $farm_spec_helper.setType($farmType)
  if ($farmType -eq 'AUTOMATED') {
    $farm_spec_helper.getDataObject().AutomatedFarmSpec.RdsServerNamingSpec.PatternNamingSettings = $farm_helper.getFarmPatternNamingSettingsHelper().getDataObject()
    $farm_spec_helper.getDataObject().AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings = $farm_helper.getFarmViewComposerStorageSettingsHelper().getDataObject()


  }
  $farm_spec_helper.getDataObject().Data.Settings = $farm_helper.getFarmSessionSettingsHelper().getDataObject()
  $farm_spec_helper.getDataObject().Data.DisplayProtocolSettings = $farm_helper.getFarmDisplayProtocolSettingsHelper().getDataObject()
  $farm_spec_helper.getDataObject().Data.MirageConfigurationOverrides = $farm_helper.getFarmMirageConfigurationOverridesHelper( ).getDataObject()
  return $farm_spec_helper.getDataObject()
}


function New-HVPool {
<#
.Synopsis
   Creates new desktop pool.

.DESCRIPTION
   Creates new desktop pool, the type and user assignment type would be
   determined based on input parameters.

.PARAMETER InstantClone
   Switch to Create Instant Clone pool.

.PARAMETER LinkedClone
   Switch to Create Linked Clone pool.

.PARAMETER FullClone
   Switch to Create Full Clone pool.

.PARAMETER Manual
   Switch to Create Manual Clone pool.

.PARAMETER Rds
   Switch to Create RDS pool.

.PARAMETER PoolName
   Name of the pool.

.PARAMETER PoolDisplayName
   Display name of pool.

.PARAMETER Description
   Description of pool.

.PARAMETER AccessGroup
   View access group can organize the desktops in the pool.
   Default Value is 'Root'.

.PARAMETER GlobalEntitlement
   Description of pool.
   Global entitlement to associate the pool.

.PARAMETER UserAssignment
    User Assignment type of pool.
    Set to DEDICATED for dedicated desktop pool.
    Set to FLOATING for floating desktop pool.

.PARAMETER AutomaticAssignment
    Automatic assignment of a user the first time they access the machine.
    Applicable to dedicated desktop pool.

.PARAMETER Enable
    Set true to enable the pool otherwise set to false.

.PARAMETER ConnectionServerRestrictions
    Connection server restrictions.
    This is a list of tags that access to the desktop is restricted to.
    No list means that the desktop can be accessed from any connection server.

.PARAMETER PowerPolicy
    Power policy for the machines in the desktop after logoff.
	This setting is only relevant for managed machines

.PARAMETER AutomaticLogoffPolicy
    Automatically log-off policy after disconnect. 
	This property has a default value of "NEVER".

.PARAMETER AutomaticLogoffMinutes
    The timeout in minutes for automatic log-off after disconnect.
	This property is required if automaticLogoffPolicy is set to "AFTER".

.PARAMETER AllowUsersToResetMachines
    Whether users are allowed to reset/restart their machines. 

.PARAMETER AllowMultipleSessionsPerUser
    Whether multiple sessions are allowed per user in case of Floating User Assignment.

.PARAMETER DeleteOrRefreshMachineAfterLogoff
	Whether machines are to be deleted or refreshed after logoff in case of Floating User Assignment.

.PARAMETER RefreshOsDiskAfterLogoff
	Whether and when to refresh the OS disks for dedicated-assignment, linked-clone machines. 

.PARAMETER RefreshPeriodDaysForReplicaOsDisk
    Regular interval at which to refresh the OS disk.

.PARAMETER RefreshThresholdPercentageForReplicaOsDisk
	With the 'AT_SIZE' option for refreshOsDiskAfterLogoff, the size of the linked clone's OS disk in the datastore is compared to its maximum allowable size.

.PARAMETER SupportedDisplayProtocols
	The list of supported display protocols for the desktop. 

.PARAMETER DefaultDisplayProtocol
    The default display protocol for the desktop. For a managed desktop, this will default to "PCOIP". For an unmanaged desktop, this will default to "RDP". 

.PARAMETER AllowUsersToChooseProtocol
    Whether the users can choose the protocol. 

.PARAMETER Renderer3D
    Specify 3D rendering dependent types hardware, software, vsphere client etc.

.PARAMETER EnableGRIDvGPUs
    Whether GRIDvGPUs enabled or not

.PARAMETER VRamSizeMB
    VRAM size for View managed 3D rendering. More VRAM can improve 3D performance.

.PARAMETER MaxNumberOfMonitors
    The greater these values are, the more memory will be consumed on the associated ESX hosts

.PARAMETER MaxResolutionOfAnyOneMonitor
    The greater these values are, the more memory will be consumed on the associated ESX hosts.

.PARAMETER EnableHTMLAccess
    HTML Access, enabled by VMware Blast technology, allows users to connect to View machines from Web browsers.

.PARAMETER Quality
    This setting determines the image quality that the flash movie will render. Lower quality results in less bandwidth usage.

.PARAMETER Throttling
    This setting affects the frame rate of the flash movie. If enabled, the frames per second will be reduced based on the aggressiveness level.

.PARAMETER OverrideGlobalSetting
    Mirage configuration specified here will be used for this Desktop
    
.PARAMETER Enabled
	Whether a Mirage server is enabled. 

.PARAMETER Url
    The URL of the Mirage server. This should be in the form "<(DNS name)|(IPv4)|(IPv6)><:(port)>". IPv6 addresses must be enclosed in square brackets.

.PARAMETER Vcenter
    Virtual Center server-address (IP or FQDN) where the pool virtual machines are located. This should be same as provided to the Connection Server while adding the vCenter server.

.PARAMETER Template
    Virtual machine Template name to clone Virtual machines.
    Applicable only to Full Clone pools.

.PARAMETER ParentVM
    Parent Virtual Machine to clone Virtual machines.
    Applicable only to Linked Clone and Instant Clone pools.

.PARAMETER SnapshotVM
    Base image VM for Linked Clone pool and current Image for Instant Clone Pool.

.PARAMETER VmFolder
    VM folder to deploy the VMs to.
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER HostOrCluster
    Host or cluster to deploy the VMs in.
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER ResourcePool
    Resource pool to deploy the VMs.
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER Datastores
    Datastore names to store the VM
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER UseVSAN
    Whether to use vSphere VSAN. This is applicable for vSphere 5.5 or later.
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER UseSeparateDatastoresReplicaAndOSDisks
    Whether to use separate datastores for replica and OS disks.
	
.PARAMETER ReplicaDiskDatastore
    Datastore to store replica disks for View Composer and Instant clone engine sourced machines. 

.PARAMETER UseNativeSnapshots
    Native NFS Snapshots is a hardware feature, specify whether to use or not

.PARAMETER ReclaimVmDiskSpace
    virtual machines can be configured to use a space efficient disk format that supports reclamation of unused disk space.

.PARAMETER ReclamationThresholdGB
    Initiate reclamation when unused space on VM exceeds the threshold.

.PARAMETER RedirectWindowsProfile
    Windows profiles will be redirected to persistent disks, which are not affected by View Composer operations such as refresh, recompose and rebalance.

.PARAMETER UseSeparateDatastoresPersistentAndOSDisks
    Whether to use separate datastores for persistent and OS disks. This must be false if redirectWindowsProfile is false.

.PARAMETER PersistentDiskDatastores
    Name of the Persistent disk datastore

.PARAMETER PersistentDiskStorageOvercommit
    Storage overcommit determines how view places new VMs on the selected datastores. 

.PARAMETER DiskSizeMB
    Size of the persistent disk in MB.

.PARAMETER DiskDriveLetter
    Persistent disk drive letter.

.PARAMETER RedirectDisposableFiles
    Redirect disposable files to a non-persistent disk that will be deleted automatically when a user's session ends.

.PARAMETER NonPersistentDiskSizeMB
    Size of the non persistent disk in MB.

.PARAMETER NonPersistentDiskDriveLetter
    Non persistent disk drive letter.

.PARAMETER UseViewStorageAccelerator
    Whether to use View Storage Accelerator.

.PARAMETER ViewComposerDiskTypes
    Disk types to enable for the View Storage Accelerator feature.

.PARAMETER RegenerateViewStorageAcceleratorDays
    How often to regenerate the View Storage Accelerator cache.

.PARAMETER BlackoutTimes
    A list of blackout times.

.PARAMETER StopOnProvisioningError
    Set to true to stop provisioning of all VMs on error.
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER TransparentPageSharingScope
    The transparent page sharing scope.
    The default value is 'VM'.

.PARAMETER NamingMethod
    Determines how the VMs in the desktop are named.
    Set SPECIFIED to use specific name.
    Set PATTERN to use naming pattern.
    The default value is PATTERN. For Instant Clone pool the value must be PATTERN.

.PARAMETER NamingPattern
    Virtual machines will be named according to the specified naming pattern.
    Value would be considered only when $namingMethod = PATTERN.
    The default value is poolName + '{n:fixed=4}'.

.PARAMETER MinReady
    Minimum number of ready (provisioned) machines during View Composer maintenance operations.
    The default value is 0.
    Applicable to Linked Clone Pools.

.PARAMETER MaximumCount
    Maximum number of machines in the pool.
    The default value is 1.
    Applicable to Full, Linked, Instant Clone Pools

.PARAMETER SpareCount
    Number of spare powered on machines in the pool.
    The default value is 1.
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER ProvisioningTime
    Determines when machines are provisioned.
    Supported values are ON_DEMAND, UP_FRONT.
    The default value is UP_FRONT.
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER MinimumCount
    The minimum number of machines to have provisioned if on demand provisioning is selected.
    The default value is 0.
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER SpecificNames
    Specified names of VMs in the pool.
    The default value is <poolName>-1
    Applicable to Full, Linked and Cloned Pools.

.PARAMETER StartInMaintenanceMode
    Set this to true to allow virtual machines to be customized manually before users can log
    in and access them.
    the default value is false
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER NumUnassignedMachinesKeptPoweredOn
    Number of unassigned machines kept powered on. value should be less than max number of vms in the pool.
    The default value is 1.
    Applicable to Full, Linked, Instant Clone Pools.
    When JSON Spec file is used for pool creation, the value will be read from JSON spec.

.PARAMETER AdContainer
    This is the Active Directory container which the machines will be added to upon creation.
    The default value is 'CN=Computers'.
    Applicable to Instant Clone Pool.

.PARAMETER NetBiosName
    Domain Net Bios Name.
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER DomainAdmin
    Domain Administrator user name which will be used to join the domain.
    Default value is null.
    Applicable to Full, Linked, Instant Clone Pools.

.PARAMETER CustType
    Type of customization to use.
    Supported values are 'CLONE_PREP','QUICK_PREP','SYS_PREP','NONE'.
    Applicable to Full, Linked Clone Pools.

.PARAMETER SysPrepName
    The customization spec to use.
    Applicable to Full, Linked Clone Pools.

.PARAMETER PowerOffScriptName
    Power off script. ClonePrep/QuickPrep can run a customization script on instant/linked clone machines before they are powered off. Provide the path to the script on the parent virtual machine.
    Applicable to Linked, Instant Clone pools.

.PARAMETER PowerOffScriptParameters
    Power off script parameters. Example: p1 p2 p3 
    Applicable to Linked, Instant Clone pools.

.PARAMETER PostSynchronizationScriptName
    Post synchronization script. ClonePrep/QuickPrep can run a customization script on instant/linked clone machines after they are created or recovered or a new image is pushed. Provide the path to the script on the parent virtual machine.
    Applicable to Linked, Instant Clone pools.

.PARAMETER PostSynchronizationScriptParameters
    Post synchronization script parameters. Example: p1 p2 p3 
    Applicable to Linked, Instant Clone pools.
.PARAMETER Source
    Source of the Virtual machines for manual pool.
    Supported values are 'VIRTUAL_CENTER','UNMANAGED'.
    Set VIRTUAL_CENTER for vCenter managed VMs.
    Set UNMANAGED for Physical machines or VMs which are not vCenter managed VMs.
    Applicable to Manual Pools.

.PARAMETER VM
    List of existing virtual machine names to add into manual pool.
    Applicable to Manual Pools.

.PARAMETER Farm
    Farm to create RDS pools
    Applicable to RDS Pools.

.PARAMETER Spec
    Path of the JSON specification file.

.PARAMETER ClonePool
    Existing pool info to clone a new pool.

.PARAMETER HvServer
    Reference to Horizon View Server to query the pools from. If the value is not passed or null then
    first element from global:DefaultHVServers would be considered inplace of hvServer.

.EXAMPLE
   Create new automated linked clone pool with naming method pattern
   New-HVPool -LinkedClone -PoolName 'vmwarepool' -UserAssignment FLOATING -ParentVM 'Agent_vmware' -SnapshotVM 'kb-hotfix' -VmFolder 'vmware' -HostOrCluster 'CS-1' -ResourcePool 'CS-1' -Datastores 'datastore1' -NamingMethod PATTERN -PoolDisplayName 'vmware linkedclone pool' -Description  'created linkedclone pool from ps' -EnableProvisioning $true -StopOnProvisioningError $false -NamingPattern  "vmware2" -MinReady 0 -MaximumCount 1 -SpareCount 1 -ProvisioningTime UP_FRONT -SysPrepName vmwarecust -CustType SYS_PREP -NetBiosName adviewdev -DomainAdmin root

.EXAMPLE
   Create new automated linked clone pool by using JSON spec file
   New-HVPool -Spec C:\VMWare\Specs\LinkedClone.json -Confirm:$false

.EXAMPLE
   Clones new pool by using existing pool configuration
   Get-HVPool -PoolName 'vmwarepool' | New-HVPool -PoolName 'clonedPool' -NamingPattern 'clonelnk1';
   (OR)
   $vmwarepool = Get-HVPool -PoolName 'vmwarepool';  New-HVPool -ClonePool $vmwarepool -PoolName 'clonedPool' -NamingPattern 'clonelnk1';

.EXAMPLE
  Create new automated instant clone pool with naming method pattern
  New-HVPool -InstantClone -PoolName "InsPoolvmware" -PoolDisplayName "insPool" -Description "create instant pool" -UserAssignment FLOATING -ParentVM 'Agent_vmware' -SnapshotVM 'kb-hotfix' -VmFolder 'vmware' -HostOrCluster  'CS-1' -ResourcePool 'CS-1' -NamingMethod PATTERN -Datastores 'datastore1' -NamingPattern "inspool2" -NetBiosName 'adviewdev' -DomainAdmin root

.EXAMPLE
  Create new automated full clone pool with naming method pattern
  New-HVPool -FullClone -PoolName "FullClone" -PoolDisplayName "FullClonePra" -Description "create full clone" -UserAssignment DEDICATED -Template 'powerCLI-VM-TEMPLATE' -VmFolder 'vmware' -HostOrCluster 'CS-1' -ResourcePool 'CS-1'  -Datastores 'datastore1' -NamingMethod PATTERN -NamingPattern 'FullCln1' -SysPrepName vmwarecust -CustType SYS_PREP -NetBiosName adviewdev -DomainAdmin root

.EXAMPLE
  Create new managed manual pool from virtual center managed VirtualMachines.
  New-HVPool -MANUAL -PoolName 'manualVMWare' -PoolDisplayName 'MNLPUL' -Description 'Manual pool creation' -UserAssignment FLOATING -Source VIRTUAL_CENTER -VM 'PowerCLIVM1', 'PowerCLIVM2'

.EXAMPLE
  Create new unmanaged manual pool from unmanaged VirtualMachines.
  New-HVPool -MANUAL -PoolName 'unmangedVMWare' -PoolDisplayName 'unMngPl' -Description 'unmanaged Manual Pool creation' -UserAssignment FLOATING -Source UNMANAGED -VM 'myphysicalmachine.vmware.com'

.OUTPUTS
  None

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(

    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [switch]
    $InstantClone,

    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [switch]
    $LinkedClone,

    [Parameter(Mandatory = $true,ParameterSetName = 'FULL_CLONE')]
    [switch]
    $FullClone,

    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [switch]
    $Manual,

    [Parameter(Mandatory = $true,ParameterSetName = 'RDS')]
    [switch]
    $Rds,

    [Parameter(Mandatory = $true,ParameterSetName = 'JSON_FILE')]
    [string]
    $Spec,

    [Parameter(Mandatory = $true,ValueFromPipeline = $true,ParameterSetName = 'CLONED_POOL')]
    $ClonePool,

    #desktopSpec.desktopBase.name
    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'FULL_CLONE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'RDS')]
    [Parameter(Mandatory = $true,ParameterSetName = 'CLONED_POOL')]
    [string]
    $PoolName,

    #desktopSpec.desktopBase.displayName
    [Parameter(Mandatory = $false)]
    [string]
    $PoolDisplayName = $poolName,

    #desktopSpec.desktopBase.description
    [Parameter(Mandatory = $false)]
    [string]
    $Description = ' ',

    #desktopSpec.desktopBase.accessGroup
    [Parameter(Mandatory = $false)]
    [string]
    $AccessGroup = 'Root',

    #desktopSpec.globalEntitlement
    [Parameter(Mandatory = $false)]
    [string]
    $GlobalEntitlement,

    #desktopSpec.automatedDesktopSpec.desktopUserAssignment.userAssigment if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    #desktopSpec.manualDesktopSpec.desktopUserAssignment.userAssigment if MANUAL
    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'FULL_CLONE')]
    [ValidateSet('FLOATING','DEDICATED')]
    [string]
    $UserAssignment,

    #desktopSpec.automatedDesktopSpec.desktopUserAssignment.automaticAssignment
    [Parameter(Mandatory = $false,ParameterSetName = 'MANUAL')]
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [boolean]
    $AutomaticAssignment = $true,

    #desktopSpec.desktopSettings.enabled
    [Parameter(Mandatory = $false)]
    [boolean]
    $Enable = $true,

    #desktopSpec.desktopSettings.connectionServerRestrictions
    [Parameter(Mandatory = $false)]
    [string[]]
    $ConnectionServerRestrictions,

	#desktopSpec.desktopSettings.deleting
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]$Deleting = $false,

    #desktopSpec.desktopSettings.logoffSettings.powerPloicy
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateSet('TAKE_NO_POWER_ACTION', 'ALWAYS_POWERED_ON', 'SUSPEND', 'POWER_OFF')]
    [string]$PowerPolicy = 'TAKE_NO_POWER_ACTION',

    #desktopSpec.desktopSettings.logoffSettings.powerPloicy
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateSet('IMMEDIATELY', 'NEVER', 'AFTER')]
    [string]$AutomaticLogoffPolicy = 'NEVER',

    #desktopSpec.desktopSettings.logoffSettings.automaticLogoffMinutes
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateRange(1,120)]
    [int]$AutomaticLogoffMinutes = 120,

    #desktopSpec.desktopSettings.logoffSettings.allowUsersToResetMachines
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]$allowUsersToResetMachines = $false,

    #desktopSpec.desktopSettings.logoffSettings.allowMultipleSessionsPerUser
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]$allowMultipleSessionsPerUser = $false,

    #desktopSpec.desktopSettings.logoffSettings.deleteOrRefreshMachineAfterLogoff
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateSet('NEVER', 'DELETE', 'AFTER')]
    [string]$deleteOrRefreshMachineAfterLogoff = 'NEVER',

    #desktopSpec.desktopSettings.logoffSettings.refreshOsDiskAfterLogoff
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateSet('NEVER', 'ALWAYS', 'EVERY', 'AT_SIZE')]
    [string]$refreshOsDiskAfterLogoff = 'NEVER',

    #desktopSpec.desktopSettings.logoffSettings.refreshPeriodDaysForReplicaOsDisk
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [int]$refreshPeriodDaysForReplicaOsDisk = 120,

    #desktopSpec.desktopSettings.logoffSettings.refreshThresholdPercentageForReplicaOsDisk
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateRange(1,100)]
    [int]$refreshThresholdPercentageForReplicaOsDisk,

    #DesktopDisplayProtocolSettings
    #desktopSpec.desktopSettings.logoffSettings.supportedDisplayProtocols
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateSet('RDP', 'PCOIP', 'BLAST')]
    [string[]]$supportedDisplayProtocols = @('RDP', 'PCOIP', 'BLAST'),

    #desktopSpec.desktopSettings.logoffSettings.defaultDisplayProtocol
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateSet('RDP', 'PCOIP', 'BLAST')]
    [string]$defaultDisplayProtocol = 'PCOIP',

    #desktopSpec.desktopSettings.logoffSettings.allowUsersToChooseProtocol
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [int]$allowUsersToChooseProtocol = $true,

    #desktopSpec.desktopSettings.logoffSettings.enableHTMLAccess
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]$enableHTMLAccess = $false,

    # DesktopPCoIPDisplaySettings
    #desktopSpec.desktopSettings.logoffSettings.pcoipDisplaySettings.renderer3D
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateSet('MANAGE_BY_VSPHERE_CLIENT', 'AUTOMATIC', 'SOFTWARE', 'HARDWARE', 'DISABLED')]
    [string]$renderer3D = 'DISABLED',

    #desktopSpec.desktopSettings.logoffSettings.pcoipDisplaySettings.enableGRIDvGPUs
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]$enableGRIDvGPUs = $false,

    #desktopSpec.desktopSettings.logoffSettings.pcoipDisplaySettings.vRamSizeMB
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateRange(64,512)]
    [int]$vRamSizeMB = 96,

    #desktopSpec.desktopSettings.logoffSettings.pcoipDisplaySettings.maxNumberOfMonitors
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateRange(1,4)]
    [int]$maxNumberOfMonitors = 2,

    #desktopSpec.desktopSettings.logoffSettings.pcoipDisplaySettings.maxResolutionOfAnyOneMonitor
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateSet('WUXGA', 'WSXGA_PLUS', 'WQXGA', 'UHD')]
    [string]$maxResolutionOfAnyOneMonitor = 'WUXGA',

    # flashSettings
    #desktopSpec.desktopSettings.flashSettings.quality
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateSet('NO_CONTROL', 'LOW', 'MEDIUM', 'HIGH')]
    [string]$quality = 'NO_CONTROL',

    #desktopSpec.desktopSettings.flashSettings.throttling
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateSet('DISABLED', 'CONSERVATIVE', 'MODERATE', 'AGGRESSIVE')]
    [string]$throttling = 'DISABLED',

    #mirageConfigurationOverrides
    #desktopSpec.desktopSettings.mirageConfigurationOverrides.overrideGlobalSetting
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]$overrideGlobalSetting = $false,

    #desktopSpec.desktopSettings.mirageConfigurationOverrides.enabled
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]$enabled = $true,

    #desktopSpec.desktopSettings.mirageConfigurationOverrides.url
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [string]$url = $true,

    #desktopSpec.automatedDesktopSpec.virtualCenter if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    #desktopSpec.manualDesktopSpec.virtualCenter if MANUAL
    [Parameter(Mandatory = $false,ParameterSetName = 'MANUAL')]
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [string]
    $Vcenter,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.template if FULL_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = 'FULL_CLONE')]
    [string]
    $Template,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.parentVM if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $ParentVM,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.snapshotVM if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $SnapshotVM,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.vmFolder if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'FULL_CLONE')]
    [string]
    $VmFolder,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.hostOrCluster if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'FULL_CLONE')]
    [string]
    $HostOrCluster,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.resourcePool if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'FULL_CLONE')]
    [string]
    $ResourcePool,

	#desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.datacenter if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [string]
    $datacenter,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.datastore if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'FULL_CLONE')]
    [string[]]
    $Datastores,

	#desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.datastores.storageOvercommit if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [string[]]
    $StorageOvercommit = $null,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.useVSAN if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [boolean]
    $UseVSAN =  $false,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.useSeparateDatastoresReplicaAndOSDisks if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [boolean]
    $UseSeparateDatastoresReplicaAndOSDisks = $false,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.replicaDiskDatastore if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [string]
    $ReplicaDiskDatastore,

	#desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.UseNativeSnapshots if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [boolean]
    $UseNativeSnapshots = $false,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.spaceReclamationSettings.reclaimVmDiskSpace if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [boolean]
    $ReclaimVmDiskSpace = $false,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.spaceReclamationSettings.reclamationThresholdGB if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateRange(0,[Int]::MaxValue)]
    [int]
    $ReclamationThresholdGB =  1,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.persistentDiskSettings.redirectWindowsProfile if LINKED_CLONE, INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [boolean]
    $RedirectWindowsProfile = $true,
    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.persistentDiskSettings.useSeparateDatastoresPersistentAndOSDisks if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]
    $UseSeparateDatastoresPersistentAndOSDisks = $false,
    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.persistentDiskSettings.PersistentDiskDatastores if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [string[]]
    $PersistentDiskDatastores,
    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.persistentDiskSettings.PersistentDiskDatastores if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [string[]]
    $PersistentDiskStorageOvercommit = $null,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.persistentDiskSettings.diskSizeMB if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateRange(128,[Int]::MaxValue)]
    [int]
    $DiskSizeMB = 2048,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.persistentDiskSettings.diskDriveLetter if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidatePattern("^[D-Z]$")]
    [string]
    $DiskDriveLetter = "D",

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.nonPersistentDiskSettings.redirectDisposableFiles if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]
    $redirectDisposableFiles,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.nonPersistentDiskSettings.diskSizeMB if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateRange(512,[Int]::MaxValue)]
    [int]
    $NonPersistentDiskSizeMB = 4096,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewComposerStorageSettings.nonPersistentDiskSettings.diskDriveLetter if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidatePattern("^[D-Z]|Auto$")]
    [string]
    $NonPersistentDiskDriveLetter = "Auto",

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewStorageAcceleratorSettings.useViewStorageAccelerator if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]
    $UseViewStorageAccelerator =  $false,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewStorageAcceleratorSettings.useViewStorageAccelerator if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [string]
    $ViewComposerDiskTypes = "OS_DISKS",

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewStorageAcceleratorSettings.regenerateViewStorageAcceleratorDays if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateRange(1,999)]
    [int]
    $RegenerateViewStorageAcceleratorDays = 7,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.viewStorageAcceleratorSettings.blackoutTimes if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [VMware.Hv.DesktopBlackoutTime[]]
    $BlackoutTimes,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterNetworkingSettings.nics
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [VMware.Hv.DesktopNetworkInterfaceCardSettings[]]
    $Nics,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.enableProvsioning if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [boolean]
    $EnableProvisioning = $true,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.stopOnProvisioningError if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [boolean]
    $StopOnProvisioningError = $true,

    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'MANUAL')]
    [string]
    $TransparentPageSharingScope = 'VM',

    #desktopSpec.automatedDesktopSpec.vmNamingSpec.namingMethod if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'FULL_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'CLONED_POOL')]
    [ValidateSet('SPECIFIED','PATTERN')]
    [string]
    $NamingMethod = 'PATTERN',

    #desktopSpec.automatedDesktopSpec.vmNamingSpec.namingPattern if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'CLONED_POOL')]
    [string]
    $NamingPattern = $poolName + '{n:fixed=4}',

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.minReadyVMsOnVComposerMaintenance if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [int]
    $MinReady = 0,

    #desktopSpec.automatedDesktopSpec.vmNamingSpec.patternNamingSettings.maxNumberOfMachines if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [int]
    $MaximumCount = 1,

    #desktopSpec.automatedDesktopSpec.vmNamingSpec.patternNamingSettings.numberOfSpareMachines if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [int]
    $SpareCount = 1,

    #desktopSpec.automatedDesktopSpec.vmNamingSpec.patternNamingSettings.provisioningTime if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [ValidateSet('ON_DEMAND','UP_FRONT')]
    [string]
    $ProvisioningTime = 'UP_FRONT',

    #desktopSpec.automatedDesktopSpec.vmNamingSpec.patternNamingSettings.minimumNumberOfMachines if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [int]
    $MinimumCount = 0,

    #desktopSpec.automatedDesktopSpec.vmNamingSpec.specifiNamingSpec.namingPattern if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'CLONED_POOL')]
    [string[]]
    $SpecificNames = $poolName + '-1',

    #desktopSpec.automatedDesktopSpec.vmNamingSpec.specifiNamingSpec.startMachinesInMaintenanceMode if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [boolean]
    $StartInMaintenanceMode = $false,

    #desktopSpec.automatedDesktopSpec.vmNamingSpec.specifiNamingSpec.numUnassignedMachinesKeptPoweredOnif LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = "JSON_FILE")]
    [int]
    $NumUnassignedMachinesKeptPoweredOn = 1,

    #desktopSpec.automatedDesktopSpec.customizationSettings.cloneprepCustomizationSettings.instantCloneEngineDomainAdministrator if INSTANT_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    $AdContainer = 'CN=Computers',

    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [string]$NetBiosName,

    #desktopSpec.automatedDesktopSpec.customizationSettings.domainAdministrator
    #desktopSpec.automatedDesktopSpec.customizationSettings.cloneprepCustomizationSettings.instantCloneEngineDomainAdministrator
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [string]$DomainAdmin = $null,

    #desktopSpec.automatedDesktopSpec.customizationSettings.customizationType if LINKED_CLONE, FULL_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = "FULL_CLONE")]
    [ValidateSet('CLONE_PREP','QUICK_PREP','SYS_PREP','NONE')]
    [string]
    $CustType,

    #desktopSpec.automatedDesktopSpec.customizationSettings.reusePreExistingAccounts if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [Boolean]
    $ReusePreExistingAccounts = $false,

    #desktopSpec.automatedDesktopSpec.customizationSettings.sysprepCustomizationSettings.customizationSpec if LINKED_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = "FULL_CLONE")]
    [string]
    $SysPrepName,

    #desktopSpec.automatedDesktopSpec.customizationSettings.noCustomizationSettings.doNotPowerOnVMsAfterCreation if FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "FULL_CLONE")]
    [boolean]
    $DoNotPowerOnVMsAfterCreation = $false,

    #desktopSpec.automatedDesktopSpec.customizationSettings.quickprepCustomizationSettings.powerOffScriptName if LINKED_CLONE, INSTANT_CLONE
    #desktopSpec.automatedDesktopSpec.customizationSettings.cloneprepCustomizationSettings.powerOffScriptName
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [string]
    $PowerOffScriptName,

    #desktopSpec.automatedDesktopSpec.customizationSettings.quickprepCustomizationSettings.powerOffScriptParameters
    #desktopSpec.automatedDesktopSpec.customizationSettings.cloneprepCustomizationSettings.powerOffScriptParameters
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [string]
    $PowerOffScriptParameters,

    #desktopSpec.automatedDesktopSpec.customizationSettings.quickprepCustomizationSettings.postSynchronizationScriptName
    #desktopSpec.automatedDesktopSpec.customizationSettings.cloneprepCustomizationSettings.postSynchronizationScriptName
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [string]
    $PostSynchronizationScriptName,

    #desktopSpec.automatedDesktopSpec.customizationSettings.quickprepCustomizationSettings.postSynchronizationScriptParameters
    #desktopSpec.automatedDesktopSpec.customizationSettings.cloneprepCustomizationSettings.postSynchronizationScriptParameters
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [string]
    $PostSynchronizationScriptParameters,

    #manual desktop
    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [ValidateSet('VIRTUAL_CENTER','UNMANAGED')]
    [string]
    $Source,

    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [Parameter(Mandatory = $false,ParameterSetName = "JSON_FILE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'CLONED_POOL')]
    [string[]]$VM,

    #farm
    [Parameter(Mandatory = $false,ParameterSetName = 'RDS')]
    [Parameter(Mandatory = $false,ParameterSetName = 'CLONED_POOL')]

    [string]
    $Farm,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )
  #
  #
  #
  # DesktopSpec/DesktopInfo
  #   *DesktopBase
  #        +AccessGroupId
  #   &DesktopSettings
  #        DesktopLogoffSettings
  #        DesktopDisplayProtocolSettings
  #               DesktopPCoIPDisplaySettings
  #        DesktopAdobeFlashSettings
  #        DesktopAdobeFlashSettings
  #        DesktopMirageConfigurationOverrides
  #   DesktopAutomatedDesktopSpec/DesktopAutomatedDesktopData
  #        */+VirtualCenterId
  #        DesktopUserAssignment
  #        DesktopVirtualMachineNamingSpec/DesktopVirtualMachineNamingSettings
  #                DesktopPatternNamingSpec/DesktopPatternNamingSettings
  #                DesktopSpecificNamingSettings/DesktopSpecificNamingSettings
  #        DesktopVirtualCenterProvisioningSettings
  #                DesktopVirtualCenterProvisioningData/virtualCenterProvisioningData
  #                DesktopVirtualCenterStorageSettings
  #                DesktopVirtualCenterNetworkingSettings
  #        DesktopVirtualCenterManagedCommonSettings
  #        DesktopCustomizationSettings
  #                ViewComposerDomainAdministratorId
  #                ADContainerId
  #                DesktopNoCustomizationSettings
  #                DesktopSysprepCustomizationSettings
  #                      CustomizationSpecId
  #                DesktopQuickprepCustomizationSettings
  #                      DesktopQuickprepCustomizationSettings
  #                DesktopCloneprepCustomizationSettings
  #                      InstantCloneEngineDomainAdministratorId
  #   DesktopManualDesktopSpec
  #        DesktopUserAssignment
  #        MachineId[]
  #        VirtualCenterId
  #        DesktopViewStorageAcceleratorSettings
  #                 DesktopBlackoutTime[]
  #        DesktopVirtualCenterManagedCommonSettings
  #   DesktopRDSDesktopSpec
  #        DesktopBlackoutTime[]
  #   DesktopGlobalEntitlementData
  #        GlobalEntitlementId


  #  retrieve values from the pipeline  ... takes care of "get-hvpool -poolName <name> | New-HVPool -poolName <name> common parameters
  #

  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }

  process {

    if ($poolName) {
      try {
        $sourcePool = Get-HVPoolSummary -poolName $poolName -hvServer $hvServer
      } catch {
        Write-Error "Make sure Get-HVPoolSummary advanced function is loaded, $_"
        break
      }
      if ($sourcePool) {
        Write-Error "Pool with name: [$poolName] already exists"
        break
      }
    }

    if ($spec) {
      try {
        $jsonObject = Get-JsonObject -specFile $spec
      } catch {
        Write-Error "Json file exception, $_"
        break
      }
      
	  try {
	    #Json object validation
        Test-HVPoolSpec -PoolObject $jsonObject
      } catch {
        Write-Error "Json object validation failed, $_"
        break
      }
      if ($jsonObject.type -eq "AUTOMATED") {
        $poolType = 'AUTOMATED'
        if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenter) {
          $vCenter = $jsonObject.AutomatedDesktopSpec.VirtualCenter
        }
        $userAssignment = $jsonObject.AutomatedDesktopSpec.userAssignment.userAssignment
        $automaticAssignment = $jsonObject.AutomatedDesktopSpec.userAssignment.AutomaticAssignment
        $netBiosName = $jsonObject.NetBiosName
        if (!$jsonObject.AutomatedDesktopSpec.CustomizationSettings.AdContainer) {
          Write-Host "adContainer was empty using CN=Computers"
        } else {
          $adContainer = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.AdContainer
        }
        $custType = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.CustomizationType
        if ($jsonObject.AutomatedDesktopSpec.ProvisioningType -eq "INSTANT_CLONE_ENGINE") {
          $InstantClone = $true
          if ($null -ne $jsonObject.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings) {
            $domainAdmin = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings.InstantCloneEngineDomainAdministrator
            $powerOffScriptName = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings.PowerOffScriptName
            $powerOffScriptParameters = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings.PowerOffScriptParameters
            $postSynchronizationScriptName = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings.PostSynchronizationScriptName
            $postSynchronizationScriptParameters = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings.PostSynchronizationScriptParameters
          }
        } else {
          if ($jsonObject.AutomatedDesktopSpec.ProvisioningType -eq "VIEW_COMPOSER") {
            $LinkedClone = $true
            $domainAdmin = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.domainAdministrator
          } elseIf($jsonObject.AutomatedDesktopSpec.ProvisioningType -eq "VIRTUAL_CENTER") {
            $FullClone = $true
          }
          switch ($custType) {
            'SYS_PREP' {
              $sysprepCustomizationSettings = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.SysprepCustomizationSettings
              $sysPrepName = $sysprepCustomizationSettings.customizationSpec
              $reusePreExistingAccounts = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.reusePreExistingAccounts
            }
            'QUICK_PREP' {
              $powerOffScriptName = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.QuickprepCustomizationSettings.PowerOffScriptName
              $powerOffScriptParameters = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.QuickprepCustomizationSettings.PowerOffScriptParameters
              $postSynchronizationScriptName = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.QuickprepCustomizationSettings.PostSynchronizationScriptName
              $postSynchronizationScriptParameters = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.QuickprepCustomizationSettings.PostSynchronizationScriptParameters
            }
            'NONE' {
              $doNotPowerOnVMsAfterCreation = $jsonObject.AutomatedDesktopSpec.CustomizationSettings.NoCustomizationSettings.DoNotPowerOnVMsAfterCreation
            }
          }
        }
        $namingMethod = $jsonObject.AutomatedDesktopSpec.VmNamingSpec.NamingMethod
        $transparentPageSharingScope = $jsonObject.AutomatedDesktopSpec.virtualCenterManagedCommonSettings.TransparentPageSharingScope
        if ($namingMethod -eq "PATTERN") {
          $namingPattern = $jsonObject.AutomatedDesktopSpec.VmNamingSpec.patternNamingSettings.namingPattern
          $maximumCount = $jsonObject.AutomatedDesktopSpec.VmNamingSpec.patternNamingSettings.maxNumberOfMachines
          $spareCount = $jsonObject.AutomatedDesktopSpec.VmNamingSpec.patternNamingSettings.numberOfSpareMachines
          $provisioningTime = $jsonObject.AutomatedDesktopSpec.VmNamingSpec.patternNamingSettings.provisioningTime
        } else {
          $specificNames = $jsonObject.AutomatedDesktopSpec.VmNamingSpec.specifiedNames
          $startInMaintenanceMode = $jsonObject.AutomatedDesktopSpec.VmNamingSpec.SpecificNamingSpec.startMachinesInMaintenanceMode
          $numUnassignedMachinesKeptPoweredOn = $jsonObject.AutomatedDesktopSpec.VmNamingSpec.SpecificNamingSpec.numUnassignedMachinesKeptPoweredOn
        }
        $enableProvisioning = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.EnableProvisioning
        $stopProvisioningOnError = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.stopProvisioningOnError
        $minReady = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.minReadyVMsOnVComposerMaintenance
        if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.Template) {
          $template = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.Template
        }
        if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.ParentVm) {
          $parentVM = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.ParentVm
        }
        if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.Snapshot) {
          $snapshotVM = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.Snapshot
        }
        $dataCenter = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.dataCenter
        $vmFolder = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.VmFolder
        $hostOrCluster = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.HostOrCluster
        $resourcePool = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.ResourcePool
        $dataStoreList = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.Datastores
        foreach ($dtStore in $dataStoreList) {
          $datastores += $dtStore.Datastore
          $storageOvercommit += $dtStore.StorageOvercommit
        }
        $useVSan = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.UseVSan
        if ($LinkedClone -or $InstantClone) {
            $useSeparateDatastoresReplicaAndOSDisks = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.UseSeparateDatastoresReplicaAndOSDisks
            if ($useSeparateDatastoresReplicaAndOSDisks) {
                $replicaDiskDatastore = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.replicaDiskDatastore
            }
            if ($LinkedClone) {
                #For Instant clone desktops, this setting can only be set to false
                $useNativeSnapshots = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.useNativeSnapshots
                $reclaimVmDiskSpace = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.spaceReclamationSettings.reclaimVmDiskSpace
                if ($reclaimVmDiskSpace) {
                    $reclamationThresholdGB = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.spaceReclamationSettings.reclamationThresholdGB
                }
                if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.PersistentDiskSettings) {
                    $redirectWindowsProfile = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.PersistentDiskSettings.RedirectWindowsProfile
                    if ($redirectWindowsProfile) {
                        $useSeparateDatastoresPersistentAndOSDisks = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.PersistentDiskSettings.UseSeparateDatastoresPersistentAndOSDisks
                    }
                    $dataStoreList = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.PersistentDiskSettings.persistentDiskDatastores
                    foreach ($dtStore in $dataStoreList) {
                        $persistentDiskDatastores += $dtStore.Datastore
                        $PersistentDiskStorageOvercommit += $dtStore.StorageOvercommit
                    }
                    if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.PersistentDiskSettings.DiskSizeMB) {
                        $diskSizeMB = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.PersistentDiskSettings.DiskSizeMB
                    }
                    if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.PersistentDiskSettings.DiskDriveLetter) {
                        $diskDriveLetter = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.PersistentDiskSettings.DiskDriveLetter
                    }
                }
                if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.nonPersistentDiskSettings) {
                    $redirectDisposableFiles = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.NonPersistentDiskSettings.RedirectDisposableFiles
                    if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.NonPersistentDiskSettings.DiskSizeMB) {
                        $nonPersistentDiskSizeMB = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.NonPersistentDiskSettings.DiskSizeMB
                    }
                    if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.NonPersistentDiskSettings.DiskDriveLetter) {
                        $nonPersistentDiskDriveLetter = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings.NonPersistentDiskSettings.DiskDriveLetter
                    }
                }
            } else {
                $useNativeSnapshots = $false
                $redirectWindowsProfile = $false
            }
        }
        if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.viewStorageAcceleratorSettings) {
            $useViewStorageAccelerator = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.viewStorageAcceleratorSettings.UseViewStorageAccelerator
            if ($useViewStorageAccelerator -and $LinkedClone) {
                $viewComposerDiskTypes = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.viewStorageAcceleratorSettings.ViewComposerDiskTypes
            }
            if (! $InstantClone -and $useViewStorageAccelerator) {
                $regenerateViewStorageAcceleratorDays = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.viewStorageAcceleratorSettings.RegenerateViewStorageAcceleratorDays
                if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.viewStorageAcceleratorSettings.blackoutTimes) {
                    $blackoutTimesList =$jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.viewStorageAcceleratorSettings.blackoutTimes
                    foreach ($blackout in $blackoutTimesList) {
                        $blackoutObj  = New-Object VMware.Hv.DesktopBlackoutTime
                        $blackoutObj.Days = $blackout.Days
                        $blackoutObj.StartTime = $blackout.StartTime
                        $blackoutObj.EndTime = $blackoutObj.EndTime
                        $blackoutTimes += $blackoutObj
                    }
                }
            }
        }
        <# ToDo Nic
        if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.nics) {
            $nicList = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.nics
            foreach($nicObj in  $nicList) {
                $nic = New-Object VMware.Hv.DesktopNetworkInterfaceCardSettings
            }
        }
        #>
      } elseIf ($jsonObject.type -eq "MANUAL") {
        $MANUAL = $true
        $poolType = 'MANUAL'
        $userAssignment = $jsonObject.ManualDesktopSpec.userAssignment.userAssignment
        $automaticAssignment = $jsonObject.ManualDesktopSpec.userAssignment.AutomaticAssignment
        $source = $jsonObject.ManualDesktopSpec.source
        $VMs = $jsonObject.ManualDesktopSpec.Machines
        foreach ($vmObj in $VMs) {
          $VM += $vmObj.Machine
        }

      } else {
        $RDS = $true
        $poolType = 'RDS'
        $farm = $jsonObject.RdsDesktopSpec.farm
      }
      $poolDisplayName = $jsonObject.base.DisplayName
      $description = $jsonObject.base.Description
      $accessGroup = $jsonObject.base.AccessGroup
      $poolName = $jsonObject.base.name

	  <#
      # Populate desktop settings
      #>
      if ($null -ne $jsonObject.DesktopSettings) {
          $Enable = $jsonObject.DesktopSettings.enabled
          $deleting = $jsonObject.DesktopSettings.deleting
          if ($null -ne $jsonObject.DesktopSettings.connectionServerRestrictions) {
             $ConnectionServerRestrictions = $jsonObject.DesktopSettings.connectionServerRestrictions
          }
          if ($poolType -ne 'RDS') {
            if ($null -ne $jsonObject.DesktopSettings.logoffSettings) {
              $powerPolicy = $jsonObject.DesktopSettings.logoffSettings.powerPolicy
              $automaticLogoffPolicy = $jsonObject.DesktopSettings.logoffSettings.automaticLogoffPolicy
              if ($null -ne $jsonObject.DesktopSettings.logoffSettings.automaticLogoffMinutes) {
                $automaticLogoffMinutes = $jsonObject.DesktopSettings.logoffSettings.automaticLogoffMinutes
              }
              $allowUsersToResetMachines = $jsonObject.DesktopSettings.logoffSettings.allowUsersToResetMachines
              $allowMultipleSessionsPerUser = $jsonObject.DesktopSettings.logoffSettings.allowMultipleSessionsPerUser
              $deleteOrRefreshMachineAfterLogoff = $jsonObject.DesktopSettings.logoffSettings.deleteOrRefreshMachineAfterLogoff
              $refreshOsDiskAfterLogoff = $jsonObject.DesktopSettings.logoffSettings.refreshOsDiskAfterLogoff
              if ($jsonObject.DesktopSettings.logoffSettings.refreshPeriodDaysForReplicaOsDisk) {
                $refreshPeriodDaysForReplicaOsDisk = $jsonObject.DesktopSettings.logoffSettings.refreshPeriodDaysForReplicaOsDisk
              }
              if ($jsonObject.DesktopSettings.logoffSettings.refreshThresholdPercentageForReplicaOsDisk) {
               $refreshThresholdPercentageForReplicaOsDisk = $jsonObject.DesktopSettings.logoffSettings.refreshThresholdPercentageForReplicaOsDisk
              }
            }

            if ($null -ne $jsonObject.DesktopSettings.displayProtocolSettings) {
              $supportedDisplayProtocols = $jsonObject.DesktopSettings.displayProtocolSettings.supportedDisplayProtocols
              $defaultDisplayProtocol = $jsonObject.DesktopSettings.displayProtocolSettings.defaultDisplayProtocol
              $allowUsersToChooseProtocol = $jsonObject.DesktopSettings.displayProtocolSettings.allowUsersToChooseProtocol
              if ($null -ne $jsonObject.DesktopSettings.displayProtocolSettings.pcoipDisplaySettings) {
                $renderer3D = $jsonObject.DesktopSettings.displayProtocolSettings.pcoipDisplaySettings.renderer3D
                $enableGRIDvGPUs = $jsonObject.DesktopSettings.displayProtocolSettings.pcoipDisplaySettings.enableGRIDvGPUs
                if ($jsonObject.DesktopSettings.displayProtocolSettings.pcoipDisplaySettings.vRamSizeMB) {
                 $vRamSizeMB = $jsonObject.DesktopSettings.displayProtocolSettings.pcoipDisplaySettings.vRamSizeMB
                }
                $maxNumberOfMonitors = $jsonObject.DesktopSettings.displayProtocolSettings.pcoipDisplaySettings.maxNumberOfMonitors
                $maxResolutionOfAnyOneMonitor = $jsonObject.DesktopSettings.displayProtocolSettings.pcoipDisplaySettings.maxResolutionOfAnyOneMonitor
              }
              $enableHTMLAccess = $jsonObject.DesktopSettings.displayProtocolSettings.enableHTMLAccess
            }

            if ($null -ne $jsonObject.DesktopSettings.mirageConfigurationOverrides) {
              $overrideGlobalSetting = $jsonObject.DesktopSettings.mirageConfigurationOverrides.overrideGlobalSetting
              if ($jsonObject.DesktopSettings.mirageConfigurationOverrides.enabled) {
               $enabled = $jsonObject.DesktopSettings.mirageConfigurationOverrides.enabled
              }
              if ($jsonObject.DesktopSettings.mirageConfigurationOverrides.url) {
               $url = $jsonObject.DesktopSettings.mirageConfigurationOverrides.url
              }
            }
          }
          if ($null -ne $jsonObject.DesktopSettings.flashSettings) {
             $quality = $jsonObject.DesktopSettings.flashSettings.quality
             $throttling = $jsonObject.DesktopSettings.flashSettings.throttling
          }
          #desktopsettings ends
        }
        if ($null -ne $jsonObject.GlobalEntitlementData) {
            $globalEntitlement = $jsonObject.GlobalEntitlementData.globalEntitlement
        }
    }

    if ($PSCmdlet.MyInvocation.ExpectingInput -or $clonePool) {

      if ($clonePool -and ($clonePool.GetType().name -eq 'DesktopSummaryView')) {
        $clonePool = Get-HVPool -poolName $clonePool.desktopsummarydata.name
      } elseIf (!($clonePool -and ($clonePool.GetType().name -eq 'DesktopInfo'))) {
        Write-Error "In pipeline did not get object of expected type DesktopSummaryView/DesktopInfo"
        return
      }
      $poolType = $clonePool.type
      $desktopBase = $clonePool.base
      $desktopSettings = $clonePool.DesktopSettings
      $provisioningType = $clonePool.source
      if ($clonePool.AutomatedDesktopData) {
        $provisioningType = $clonePool.AutomatedDesktopData.ProvisioningType
        $virtualCenterID = $clonePool.AutomatedDesktopData.VirtualCenter
        $desktopUserAssignment = $clonePool.AutomatedDesktopData.userAssignment
        $desktopVirtualMachineNamingSpec = $clonePool.AutomatedDesktopData.VmNamingSettings
        $DesktopVirtualCenterProvisioningSettings = $clonePool.AutomatedDesktopData.VirtualCenterProvisioningSettings
        $DesktopVirtualCenterProvisioningData = $DesktopVirtualCenterProvisioningSettings.VirtualCenterProvisioningData
        $DesktopVirtualCenterStorageSettings = $DesktopVirtualCenterProvisioningSettings.VirtualCenterStorageSettings
        $DesktopVirtualCenterNetworkingSettings = $DesktopVirtualCenterProvisioningSettings.VirtualCenterNetworkingSettings
        $DesktopVirtualCenterManagedCommonSettings = $clonePool.AutomatedDesktopData.virtualCenterManagedCommonSettings
        $DesktopCustomizationSettings = $clonePool.AutomatedDesktopData.CustomizationSettings
      }
	  elseIf ($clonePool.ManualDesktopData) {
        if (! $VM) {
            Write-Error "ManualDesktop pool cloning requires list of machines, parameter VM is empty"
            break
        }
        $source = $clonePool.source
        $virtualCenterID = $clonePool.ManualDesktopData.VirtualCenter
        $desktopUserAssignment = $clonePool.ManualDesktopData.userAssignment
        $desktopVirtualCenterStorageSettings = $clonePool.ManualDesktopData.viewStorageAcceleratorSettings
        $desktopVirtualCenterManagedCommonSettings = $clonePool.ManualDesktopData.virtualCenterManagedCommonSettings
      }
	  elseIf($clonePool.RdsDesktopData) {
        if (! $Farm) {
            Write-Error "RdsDesktop pool cloning requires farm, parameter Farm is not set"
            break
        }
      }
      if ($provisioningType -eq 'INSTANT_CLONE_ENGINE' -and $poolType -eq 'AUTOMATED') {
        Write-Error "Cloning is not supported for instant clone pools"
        break
      }
    } else {

      if ($InstantClone) {
        $poolType = 'AUTOMATED'
        $provisioningType = 'INSTANT_CLONE_ENGINE'
      }
      elseIf ($LinkedClone) {
        $poolType = 'AUTOMATED'
        $provisioningType = 'VIEW_COMPOSER'
      }
      elseIf ($FullClone) {
        $poolType = 'AUTOMATED'
        $provisioningType = 'VIRTUAL_CENTER'
      }
      elseIf ($Manual) { $poolType = 'MANUAL' }
      elseIf ($RDS) { $poolType = 'RDS' }

    }
    $script:desktopSpecObj = Get-DesktopSpec -poolType $poolType -provisioningType $provisioningType -namingMethod $namingMethod

    #
    # accumulate properties that are shared among various type
    #

    if ($poolType -ne 'RDS') {
      #
      # vCenter: if $vcenterID is defined, then this is a clone
      #           if the user specificed the name, then find it from the list
      #          if none specified, then automatically use the vCenter if there is only one
      #
      # skips Unmanged Manual pool for VC check
      if (! (($poolType -eq 'MANUAL') -and ($source  -eq 'UNMANAGED'))) {

          if (!$virtualCenterID) {
            $virtualCenterID = Get-VcenterID -services $services -vCenter $vCenter
          }
          if ($null -eq $virtualCenterID) {
            $handleException = $true
            break
          }
      }
      #
      # populate user assignment
      #
      if (!$desktopUserAssignment) {
        if ($desktopSpecObj.AutomatedDesktopSpec) {
          $desktopSpecObj.AutomatedDesktopSpec.userAssignment.userAssignment = $userAssignment
          $desktopSpecObj.AutomatedDesktopSpec.userAssignment.AutomaticAssignment = $automaticAssignment
          $desktopUserAssignment = $desktopSpecObj.AutomatedDesktopSpec.userAssignment
        } else {
          $desktopSpecObj.ManualDesktopSpec.userAssignment.userAssignment = $userAssignment
          $desktopSpecObj.ManualDesktopSpec.userAssignment.AutomaticAssignment = $automaticAssignment
          $desktopUserAssignment = $desktopSpecObj.ManualDesktopSpec.userAssignment
        }

      }
      #
      # transparentPageSharingScope
      #
      if (!$desktopVirtualCenterManagedCommonSettings) {
        if ($desktopSpecObj.AutomatedDesktopSpec) {
          $desktopSpecObj.AutomatedDesktopSpec.virtualCenterManagedCommonSettings.TransparentPageSharingScope = $transparentPageSharingScope
          $desktopVirtualCenterManagedCommonSettings = $desktopSpecObj.AutomatedDesktopSpec.virtualCenterManagedCommonSettings
        } else {
          $desktopSpecObj.ManualDesktopSpec.virtualCenterManagedCommonSettings.TransparentPageSharingScope = $transparentPageSharingScope
          $desktopVirtualCenterManagedCommonSettings = $desktopSpecObj.ManualDesktopSpec.virtualCenterManagedCommonSettings
        }
      }
    }
    #
    # build out the infrastructure based on type of provisioning
    #
    switch ($poolType)
    {
      'RDS' {
        <#
            Query FarmId from Farm Name
        #>
        $QueryFilterEquals = New-Object VMware.Hv.QueryFilterEquals
        $QueryFilterEquals.memberName = 'data.name'
        $QueryFilterEquals.value = $farm
        $defn = New-Object VMware.Hv.QueryDefinition
        $defn.queryEntityType = 'FarmSummaryView'
        $defn.Filter = $QueryFilterEquals
        $query_service_helper = New-Object VMware.Hv.QueryServiceService
        $queryResults = $query_service_helper.QueryService_Query($services,$defn)
        if ($queryResults.results.Count -eq 0) {
          Write-Error "No farm found with name: [$farm]"
          return
        }
        $farmID = $queryResults.results.id
        $desktopSpecObj.RdsDesktopSpec.farm = $farmID
      }
      'MANUAL' {
        [VMware.Hv.MachineId[]]$machineList = $null
        $desktopSpecObj.ManualDesktopSpec.source = $source
        if ($source -eq 'VIRTUAL_CENTER') {
          # Get vCenter VMs
          $vmTable = @{}
          $vm | ForEach-Object { $vmTable[$_] = $_ }
          $virtual_machine_helper = New-Object VMware.Hv.VirtualMachineService
          $machineId = ($virtual_machine_helper.VirtualMachine_List($services,$virtualCenterId) | Where-Object { $vmTable.Contains($_.name) } | Select-Object -Property Id)
          $machineList += $machineId.id
          $desktopSpecObj.ManualDesktopSpec.VirtualCenter = $virtualCenterID
        } else {
          # Get Physical Regstered VMs
          $machineList = Get-RegisteredPhysicalMachine -services $services -machinesList $VM
        }
        $desktopSpecObj.ManualDesktopSpec.Machines = $machineList
        if ($desktopUserAssignment) {
            $desktopSpecObj.ManualDesktopSpec.userAssignment = $desktopUserAssignment
        }
      }
      default {
        if (!$desktopVirtualMachineNamingSpec) {
          $desktopSpecObj.AutomatedDesktopSpec.VmNamingSpec.NamingMethod = $namingMethod
          if ($namingMethod -eq 'PATTERN') {
            $desktopSpecObj.AutomatedDesktopSpec.VmNamingSpec.patternNamingSettings.namingPattern = $namingPattern
            $desktopSpecObj.AutomatedDesktopSpec.VmNamingSpec.patternNamingSettings.maxNumberOfMachines = $maximumCount
            $desktopSpecObj.AutomatedDesktopSpec.VmNamingSpec.patternNamingSettings.numberOfSpareMachines = $spareCount
            $desktopSpecObj.AutomatedDesktopSpec.VmNamingSpec.patternNamingSettings.provisioningTime = $provisioningTime

            if ($provisioningTime -eq 'ON_DEMAND') { $desktopSpecObj.AutomatedDesktopSpec.VmNamingSpec.patternNamingSettings.minNumberOfMachines = $minimumCount }
          } else {
            $desktopSpecifiedName = @()
            $specificNames | ForEach-Object { $desktopSpecifiedName += New-Object VMware.Hv.DesktopSpecifiedName -Property @{ 'vmName' = $_; } }
            $desktopSpecObj.AutomatedDesktopSpec.VmNamingSpec.SpecificNamingSpec.specifiedNames = $desktopSpecifiedName
            $desktopSpecObj.AutomatedDesktopSpec.VmNamingSpec.SpecificNamingSpec.startMachinesInMaintenanceMode = $startInMaintenanceMode
            $desktopSpecObj.AutomatedDesktopSpec.VmNamingSpec.SpecificNamingSpec.numUnassignedMachinesKeptPoweredOn = $numUnassignedMachinesKeptPoweredOn
          }
        } else {
          $vmNamingSpec = New-Object VMware.Hv.DesktopVirtualMachineNamingSpec
          if ($desktopVirtualMachineNamingSpec.NamingMethod -eq 'PATTERN') {
            $vmNamingSpec.NamingMethod = 'PATTERN'
            $vmNamingSpec.patternNamingSettings = $desktopVirtualMachineNamingSpec.patternNamingSettings
            $vmNamingSpec.patternNamingSettings.namingPattern = $namingPattern
          } else {
            $desktopSpecifiedName = @()
            $specificNames | ForEach-Object { $desktopSpecifiedName += New-Object VMware.Hv.DesktopSpecifiedName -Property @{ 'vmName' = $_; } }
            $vmNamingSpec.NamingMethod = 'SPECIFIED'
            $vmNamingSpec.SpecificNamingSpec = New-Object VMware.Hv.DesktopSpecificNamingSpec
            $vmNamingSpec.SpecificNamingSpec.numUnassignedMachinesKeptPoweredOn = $desktopVirtualMachineNamingSpec.specificNamingSettings.numUnassignedMachinesKeptPoweredOn
            $vmNamingSpec.SpecificNamingSpec.startMachinesInMaintenanceMode = $desktopVirtualMachineNamingSpec.specificNamingSettings.startMachinesInMaintenanceMode
            $vmNamingSpec.SpecificNamingSpec.specifiedNames = $desktopSpecifiedName
          }

        }

        #
        # build the VM LIST
        #
        $handleException = $false
        try {
          $desktopVirtualCenterProvisioningData = Get-HVPoolProvisioningData -vc $virtualCenterID -vmObject $desktopVirtualCenterProvisioningData
          $hostClusterId = $desktopVirtualCenterProvisioningData.HostOrCluster
          $hostOrCluster_helper = New-Object VMware.Hv.HostOrClusterService
          $hostClusterIds = (($hostOrCluster_helper.HostOrCluster_GetHostOrClusterTree($services, $desktopVirtualCenterProvisioningData.datacenter)).treeContainer.children.info).Id
          $desktopVirtualCenterStorageSettings = Get-HVPoolStorageObject -hostClusterIds $hostClusterId -storageObject $desktopVirtualCenterStorageSettings
          $DesktopVirtualCenterNetworkingSettings = Get-HVPoolNetworkSetting -networkObject $DesktopVirtualCenterNetworkingSettings
          $desktopCustomizationSettings = Get-HVPoolCustomizationSetting -vc $virtualCenterID -customObject $desktopCustomizationSettings
        } catch {
          $handleException = $true
          Write-Error "Failed to create Pool with error: $_"
          break
        }

        if (! $DesktopVirtualCenterProvisioningSettings) {
          $desktopSpecObj.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.enableProvisioning = $enableProvisioning
          $desktopSpecObj.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.stopProvisioningOnError = $stopProvisioningOnError
          $desktopSpecObj.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.minReadyVMsOnVComposerMaintenance = $minReady
          $desktopSpecObj.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData = $desktopVirtualCenterProvisioningData
          $desktopSpecObj.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings = $desktopVirtualCenterStorageSettings
          $desktopSpecObj.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterNetworkingSettings = $DesktopVirtualCenterNetworkingSettings
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings = $desktopCustomizationSettings
          $desktopSpecObj.AutomatedDesktopSpec.ProvisioningType = $provisioningType
          $desktopSpecObj.AutomatedDesktopSpec.VirtualCenter = $virtualCenterID
        }
        else {
          $DesktopVirtualCenterProvisioningSettings.VirtualCenterProvisioningData = $desktopVirtualCenterProvisioningData
          $DesktopVirtualCenterProvisioningSettings.VirtualCenterStorageSettings = $desktopVirtualCenterStorageSettings
          $DesktopVirtualCenterProvisioningSettings.VirtualCenterNetworkingSettings = $DesktopVirtualCenterNetworkingSettings

          $DesktopAutomatedDesktopSpec = New-Object VMware.Hv.DesktopAutomatedDesktopSpec
          $DesktopAutomatedDesktopSpec.ProvisioningType = $provisioningType
          $DesktopAutomatedDesktopSpec.VirtualCenter = $virtualCenterID
          $DesktopAutomatedDesktopSpec.userAssignment = $desktopUserAssignment
          $DesktopAutomatedDesktopSpec.VmNamingSpec = $vmNamingSpec
          $DesktopAutomatedDesktopSpec.VirtualCenterProvisioningSettings = $desktopVirtualCenterProvisioningSettings
          $DesktopAutomatedDesktopSpec.virtualCenterManagedCommonSettings = $desktopVirtualCenterManagedCommonSettings
          $DesktopAutomatedDesktopSpec.CustomizationSettings = $desktopCustomizationSettings
        }
      }
    }

    if ($handleException) {
      break
    }
    if (!$desktopBase) {
      $accessGroup_client = New-Object VMware.Hv.AccessGroupService
      $ag = $accessGroup_client.AccessGroup_List($services) | Where-Object { $_.base.name -eq $accessGroup }
      $desktopSpecObj.base.AccessGroup = $ag.id
    } else {
      $desktopSpecObj.base = $desktopBase
    }

    $desktopSpecObj.base.name = $poolName
    $desktopSpecObj.base.DisplayName = $poolDisplayName
    $desktopSpecObj.base.Description = $description
    $desktopSpecObj.type = $poolType

	if (! $desktopSettings) {
        $desktopSettingsService = New-Object VMware.Hv.DesktopService
        $desktopSettingsHelper = $desktopSettingsService.getDesktopSettingsHelper()
        $desktopSettingsHelper.setEnabled($Enable)
        $desktopSettingsHelper.setConnectionServerRestrictions($ConnectionServerRestrictions)

        #$desktopLogoffSettings = New-Object VMware.Hv.DesktopLogoffSettings
        $desktopLogoffSettings = $desktopSettingsService.getDesktopLogoffSettingsHelper()
        if ($InstantClone) {
            $deleteOrRefreshMachineAfterLogoff = "DELETE"
            $powerPolicy = "ALWAYS_POWERED_ON"
        }
        $desktopLogoffSettings.setPowerPolicy($powerPolicy)
        $desktopLogoffSettings.setAutomaticLogoffPolicy($automaticLogoffPolicy)
        $desktopLogoffSettings.setAutomaticLogoffMinutes($automaticLogoffMinutes)
        $desktopLogoffSettings.setAllowUsersToResetMachines($allowUsersToResetMachines)
        $desktopLogoffSettings.setAllowMultipleSessionsPerUser($allowMultipleSessionsPerUser)
        $desktopLogoffSettings.setDeleteOrRefreshMachineAfterLogoff($deleteOrRefreshMachineAfterLogoff)
        $desktopLogoffSettings.setRefreshOsDiskAfterLogoff($refreshOsDiskAfterLogoff)
        $desktopLogoffSettings.setRefreshPeriodDaysForReplicaOsDisk($refreshPeriodDaysForReplicaOsDisk)
        if ($refreshThresholdPercentageForReplicaOsDisk -and $refreshOsDiskAfterLogoff -eq "AT_SIZE") {
            $desktopLogoffSettings.setRefreshThresholdPercentageForReplicaOsDisk($refreshThresholdPercentageForReplicaOsDisk)
        }
        if ($poolType -ne 'RDS') {
            $desktopSettingsHelper.setLogoffSettings($desktopLogoffSettings.getDataObject())
 
            $desktopDisplayProtocolSettings = $desktopSettingsService.getDesktopDisplayProtocolSettingsHelper()
            #setSupportedDisplayProtocols is not exists, because this property cannot be updated.
            $desktopDisplayProtocolSettings.getDataObject().SupportedDisplayProtocols = $supportedDisplayProtocols
            $desktopDisplayProtocolSettings.setDefaultDisplayProtocol($defaultDisplayProtocol)
            $desktopDisplayProtocolSettings.setEnableHTMLAccess($enableHTMLAccess)
            $desktopDisplayProtocolSettings.setAllowUsersToChooseProtocol($allowUsersToChooseProtocol)

            $desktopPCoIPDisplaySettings = $desktopSettingsService.getDesktopPCoIPDisplaySettingsHelper()
            $desktopPCoIPDisplaySettings.setRenderer3D($renderer3D)
            #setEnableGRIDvGPUs is not exists, because this property cannot be updated.
            $desktopPCoIPDisplaySettings.getDataObject().EnableGRIDvGPUs = $enableGRIDvGPUs
            $desktopPCoIPDisplaySettings.setVRamSizeMB($vRamSizeMB)
            $desktopPCoIPDisplaySettings.setMaxNumberOfMonitors($maxNumberOfMonitors)
            $desktopPCoIPDisplaySettings.setMaxResolutionOfAnyOneMonitor($maxResolutionOfAnyOneMonitor)
            $desktopDisplayProtocolSettings.setPcoipDisplaySettings($desktopPCoIPDisplaySettings.getDataObject())
            $desktopSettingsHelper.setDisplayProtocolSettings($desktopDisplayProtocolSettings.getDataObject())

            $desktopMirageConfigOverrides = $desktopSettingsService.getDesktopMirageConfigurationOverridesHelper()
            $desktopMirageConfigOverrides.setEnabled($enabled)
            $desktopMirageConfigOverrides.setOverrideGlobalSetting($overrideGlobalSetting)
            $desktopMirageConfigOverrides.setUrl($url)
            $desktopSettingsHelper.setMirageConfigurationOverrides($desktopMirageConfigOverrides.getDataObject())
            $desktopSettings = $desktopSettingsHelper.getDataObject()
        }
        $desktopFlashSettings = $desktopSettingsService.getDesktopAdobeFlashSettingsHelper()
        $desktopFlashSettings.setQuality($quality)
        $desktopFlashSettings.setThrottling($throttling)
        $desktopSettingsHelper.setFlashSettings($desktopFlashSettings.getDataObject())
    }

    $desktopSpecObj.DesktopSettings = $desktopSettings
    $info = $services.PodFederation.PodFederation_get()
    if ($globalEntitlement -and ("ENABLED" -eq $info.localPodStatus.status)) {
        $QueryFilterEquals = New-Object VMware.Hv.QueryFilterEquals
        $QueryFilterEquals.memberName = 'base.displayName'
        $QueryFilterEquals.value = $globalEntitlement
        $defn = New-Object VMware.Hv.QueryDefinition
        $defn.queryEntityType = 'GlobalEntitlementSummaryView'
        $defn.Filter = $QueryFilterEquals
        $query_service_helper = New-Object VMware.Hv.QueryServiceService
        try {
            $queryResults = $query_service_helper.QueryService_Query($services,$defn)
            $globalEntitlementid = $queryResults.Results.id
            if ($globalEntitlementid.length -eq 1) {
                $desktopGlobalEntitlementData = New-Object VMware.Hv.DesktopGlobalEntitlementData -Property @{'globalEntitlement'= $globalEntitlementid;}
            }
        }
        catch {
            Write-Host "GlobalEntitlement " $_
        }
    }
    if ($desktopAutomatedDesktopSpec) {
      $desktopSpecObj.AutomatedDesktopSpec = $desktopAutomatedDesktopSpec
    }
    if ($DesktopManualDesktopSpecList) { $desktopSpecObj.ManualDesktopSpec = $DesktopManualDesktopSpecList }
    if ($desktopRDSDesktopSpec) { $desktopSpecObj.RdsDesktopSpec = $RDSDesktopSpec }
    if ($desktopGlobalEntitlementData) { $desktopSpecObj.GlobalEntitlementData = $desktopGlobalEntitlementData }

    # Please uncomment below code, if you want save desktopSpec object to json file
    <#
      $myDebug = convertto-json -InputObject $desktopSpecObj -depth 12
      $myDebug | out-file -filepath c:\temp\copieddesktop.json
    #>
    $desktop_helper = New-Object VMware.Hv.DesktopService
    if ($pscmdlet.ShouldProcess($desktopSpecObj.base.name)) {
      $id = $desktop_helper.Desktop_create($services,$desktopSpecObj)
    } else {
	  try {
	    #DesktopSpec validation
        Test-HVPoolSpec -PoolObject $desktopSpecObj
      } catch {
        Write-Error "DesktopSpec object validation failed, $_"
        break
      }
	}
    return $desktopSpecObj
  }

  end {
    $desktopSpecObj = $null
    [System.gc]::collect()
  }
}

function Get-HVPoolProvisioningData {
  param(
    [Parameter(Mandatory = $false)]
    [VMware.Hv.DesktopVirtualCenterProvisioningData]$VmObject,

    [Parameter(Mandatory = $true)]
    [VMware.Hv.VirtualCenterId]$VcID
  )
  if (!$vmObject) { $vmObject = $desktopSpecObj.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData }
  if ($template) {
    $vm_template_helper = New-Object VMware.Hv.VmTemplateService
    $templateList = $vm_template_helper.VmTemplate_List($services,$vcID)
    $templateVM = $templateList | Where-Object { $_.name -eq $template }
    if ($null -eq $templateVM) {
      throw "No template VM found with Name: [$template]"
    }
    $vmObject.Template = $templateVM.id
    $dataCenterID = $templateVM.datacenter
    if ($dataCenter -and $dataCenterID) {
        $VmTemplateInfo = $vm_template_helper.VmTemplate_ListByDatacenter($dataCenterID)
        if (! ($VmTemplateInfo.Path -like "/$dataCenter/*")) {
            throw "$template not exists in datacenter: [$dataCenter]"
        }
    }
    $vmObject.datacenter = $dataCenterID
  }
  if ($parentVM) {
    $base_imageVm_helper = New-Object VMware.Hv.BaseImageVmService
    $parentList = $base_imageVm_helper.BaseImageVm_List($services,$vcID)
    $parentVmObj = $parentList | Where-Object { $_.name -eq $parentVM }
    if ($null -eq $parentVMObj) {
      throw "No parent VM found with Name: [$parentVM]"
    }
    $vmObject.ParentVm = $parentVmObj.id
    $dataCenterID = $parentVmObj.datacenter
    $vmObject.datacenter = $dataCenterID
  }
  if ($snapshotVM) {
    $baseImageSnapshot_helper = New-Object VMware.Hv.BaseImageSnapshotService
    $snapshotList = $baseImageSnapshot_helper.BaseImageSnapshot_List($services,$parentVmObj.id)
    $snapshotVmObj = $snapshotList | Where-Object { $_.name -eq $snapshotVM }
    if ($null -eq $snapshotVmObj) {
      throw "No sanpshot found with Name: [$snapshotVM]"
    }
    $vmObject.Snapshot = $snapshotVmObj.id
  }
  if ($vmFolder) {
    $vmFolder_helper = New-Object VMware.Hv.VmFolderService
    $folders = $vmFolder_helper.VmFolder_GetVmFolderTree($services,$vmObject.datacenter)
    $folderList = @()
    $folderList += $folders
    while ($folderList.Length -gt 0) {
      $item = $folderList[0]
      if ($item -and !$_.folderdata.incompatiblereasons.inuse -and `
		!$_.folderdata.incompatiblereasons.viewcomposerreplicafolder -and `
		(($item.folderdata.path -eq $vmFolder) -or ($item.folderdata.name -eq $vmFolder))) {
        $vmObject.VmFolder = $item.id
        break
      }
      foreach ($folderItem in $item.children) {
        $folderList += $folderItem
      }
      $folderList = $folderList[1..$folderList.Length]
    }
    if ($null -eq $vmObject.VmFolder) {
      throw "No vmfolder found with Name: [$vmFolder]"
    }
  }
  if ($hostOrCluster) {
    $vmFolder_helper = New-Object VMware.Hv.HostOrClusterService
    $hostClusterList = ($vmFolder_helper.HostOrCluster_GetHostOrClusterTree($services,$vmobject.datacenter)).treeContainer.children.info
    $hostClusterObj = $hostClusterList | Where-Object { ($_.path -eq $hostOrCluster) -or ($_.name -eq $hostOrCluster) }
    if ($null -eq $hostClusterObj) {
      throw "No hostOrCluster found with Name: [$hostOrCluster]"
    }
    $vmObject.HostOrCluster = $hostClusterObj.id
  }
  if ($resourcePool) {
    $resourcePool_helper = New-Object VMware.Hv.ResourcePoolService
    $resourcePoolList = $resourcePool_helper.ResourcePool_GetResourcePoolTree($services,$vmobject.HostOrCluster)
    $resourcePoolObj = $resourcePoolList | Where-Object { ($_.resourcepooldata.path -eq $resourcePool) -or ($_.resourcepooldata.name -eq $resourcePool) }
    if ($null -eq $resourcePoolObj) {
      throw "No hostOrCluster found with Name: [$resourcePool]"
    }
    $vmObject.ResourcePool = $resourcePoolObj.id
  }
  return $vmObject
}

function Get-HVPoolStorageObject {
  param(
    [Parameter(Mandatory = $true)]
    [VMware.Hv.HostOrClusterId[]]$HostClusterIDs,
	
	[Parameter(Mandatory = $false)]
    [VMware.Hv.DesktopVirtualCenterStorageSettings]$StorageObject
  )
  $datastoreList = $null
  if (!$storageObject) {
    $datastore_helper = New-Object VMware.Hv.DatastoreService
    foreach ($hostClusterID in $hostClusterIDs){
        $datastoreList += $datastore_helper.Datastore_ListDatastoresByHostOrCluster($services,$hostClusterID)
    }
    $storageObject = New-Object VMware.Hv.DesktopVirtualCenterStorageSettings
    $storageAcceleratorList = @{
      'useViewStorageAccelerator' = $useViewStorageAccelerator
    }
    $desktopViewStorageAcceleratorSettings = New-Object VMware.Hv.DesktopViewStorageAcceleratorSettings -Property $storageAcceleratorList
    $storageObject.viewStorageAcceleratorSettings = $desktopViewStorageAcceleratorSettings
    $desktopSpaceReclamationSettings = New-Object VMware.Hv.DesktopSpaceReclamationSettings -Property @{ 'reclaimVmDiskSpace' = $reclaimVmDiskSpace; 'reclamationThresholdGB' = $reclamationThresholdGB}
    $desktopPersistentDiskSettings = New-Object VMware.Hv.DesktopPersistentDiskSettings -Property @{ 'redirectWindowsProfile' = $false }
    $desktopNonPersistentDiskSettings = New-Object VMware.Hv.DesktopNonPersistentDiskSettings -Property @{ 'redirectDisposableFiles' = $false }
    if ($LinkedClone) {
      if ($blackoutTimes) {
        $storageObject.viewStorageAcceleratorSettings.BlackoutTimes = $blackoutTimes
      }
      if ($useViewStorageAccelerator) {
        $storageObject.viewStorageAcceleratorSettings.ViewComposerDiskTypes = $viewComposerDiskTypes
        $storageObject.viewStorageAcceleratorSettings.RegenerateViewStorageAcceleratorDays = $regenerateViewStorageAcceleratorDays
      }
      $desktopPersistentDiskSettings.RedirectWindowsProfile = $redirectWindowsProfile
      if ($redirectWindowsProfile) {
        $desktopPersistentDiskSettings.UseSeparateDatastoresPersistentAndOSDisks = $useSeparateDatastoresPersistentAndOSDisks
        $desktopPersistentDiskSettings.DiskSizeMB = $diskSizeMB
        $desktopPersistentDiskSettings.DiskDriveLetter = $diskDriveLetter
      }
      if ($useSeparateDatastoresPersistentAndOSDisks) {
        if ($persistentDiskStorageOvercommit -and  ($persistentDiskDatastores.Length -ne  $persistentDiskStorageOvercommit.Length) ) {
          throw "Parameters persistentDiskDatastores length: [$persistentDiskDatastores.Length] and persistentDiskStorageOvercommit length: [$persistentDiskStorageOvercommit.Length] should be of same size"
        }
        $desktopPersistentDiskSettings.PersistentDiskDatastores = Get_Datastore -DatastoreInfoList $datastoreList -DatastoreNames $PersistentDiskDatastores -DsStorageOvercommit $persistentDiskStorageOvercommit
      }
      $desktopNonPersistentDiskSettings.RedirectDisposableFiles = $redirectDisposableFiles
      $desktopNonPersistentDiskSettings.DiskSizeMB = $nonPersistentDiskSizeMB
      $desktopNonPersistentDiskSettings.DiskDriveLetter = $nonPersistentDiskDriveLetter
    }

    $desktopViewComposerStorageSettingsList = @{
      'useNativeSnapshots' = $useNativeSnapshots;
      'spaceReclamationSettings' = $desktopSpaceReclamationSettings;
      'persistentDiskSettings' = $desktopPersistentDiskSettings;
      'nonPersistentDiskSettings' = $desktopNonPersistentDiskSettings
    }
    if (!$FullClone) {
      $storageObject.ViewComposerStorageSettings = New-Object VMware.Hv.DesktopViewComposerStorageSettings -Property $desktopViewComposerStorageSettingsList
    }
  }
  if ($datastores) {
    if ($StorageOvercommit -and  ($datastores.Length -ne  $StorageOvercommit.Length) ) {
      throw "Parameters datastores length: [$datastores.Length] and StorageOvercommit length: [$StorageOvercommit.Length] should be of same size"
    }
	$storageObject.Datastores = Get-HVDatastore -DatastoreInfoList $datastoreList -DatastoreNames $datastores -DsStorageOvercommit $StorageOvercommit
	if ($useSeparateDatastoresReplicaAndOSDisks) {
      $storageObject.ViewComposerStorageSettings.UseSeparateDatastoresReplicaAndOSDisks = $UseSeparateDatastoresReplicaAndOSDisks
      $storageObject.ViewComposerStorageSettings.ReplicaDiskDatastore =  ($datastoreInfoList | Where-Object { ($_.datastoredata.name -eq $replicaDiskDatastore) -or ($_.datastoredata.path -eq $replicaDiskDatastore)}).id
    }
  }
  if ($storageObject.Datastores.Count -eq 0) {
    throw "No datastore found with Name: [$datastores]"
  }
  if ($useVSAN) { $storageObject.useVSAN = $useVSAN }
  return $storageObject
}

function Get-HVDatastore {
  param(
    [Parameter(Mandatory = $true)]
    [VMware.Hv.DatastoreInfo[]]
    $DatastoreInfoList,

    [Parameter(Mandatory = $true)]
    [string[]]
    $DatastoreNames,

    [Parameter(Mandatory = $false)]
    [string[]]
    $DsStorageOvercommit

  )
  $datastoresSelected = @()
  foreach ($ds in $datastoreNames) {
    $datastoresSelected += ($datastoreInfoList | Where-Object { ($_.DatastoreData.Path -eq $ds) -or ($_.datastoredata.name -eq $ds) }).id
  }
  $Datastores = $null
  if (! $DsStorageOvercommit) {
      $DsStorageOvercommit += 'UNBOUNDED'
  }
  $StorageOvercommitCnt = 0
  foreach ($ds in $datastoresSelected) {
    $myDatastores = New-Object VMware.Hv.DesktopVirtualCenterDatastoreSettings
    $myDatastores.Datastore = $ds
    $mydatastores.StorageOvercommit = $DsStorageOvercommit[$StorageOvercommitCnt]
    $Datastores += $myDatastores
    $StorageOvercommitCnt++
  }
  return $Datastores
}

function Get-HVPoolNetworkSetting {
  param(
    [Parameter(Mandatory = $false)]
    [VMware.Hv.DesktopVirtualCenterNetworkingSettings]$NetworkObject
  )
  if (!$networkObject) {
    $networkObject = $desktopSpecObj.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterNetworkingSettings
  }
  return $networkObject
}

function Get-HVPoolCustomizationSetting {
  param(
    [Parameter(Mandatory = $false)]
    [VMware.Hv.DesktopCustomizationSettings]$CustomObject,

    [Parameter(Mandatory = $true)]
    [VMware.Hv.VirtualCenterId]$VcID
  )
  if (!$customObject) {
    # View Composer and Instant Clone Engine Active Directory container for QuickPrep and ClonePrep. This must be set for Instant Clone Engine or SVI sourced desktops.
    if ($InstantClone -or $LinkedClone) {
        $ad_domain_helper = New-Object VMware.Hv.ADDomainService
        $ADDomains = $ad_domain_helper.ADDomain_List($services)
        if ($netBiosName) {
          $adDomianId = ($ADDomains | Where-Object { $_.NetBiosName -eq $netBiosName } | Select-Object -Property id)
          if ($null -eq $adDomianId) {
            throw "No Domain found with netBiosName: [$netBiosName]"
          }
        } else {
          $adDomianId = ($ADDomains[0] | Select-Object -Property id)
          if ($null -eq $adDomianId) {
            throw "No Domain configured in view administrator UI"
          }
        }
        $ad_container_helper = New-Object VMware.Hv.AdContainerService
        $adContainerId = ($ad_container_helper.ADContainer_ListByDomain($services,$adDomianId.id) | Where-Object { $_.Rdn -eq $adContainer } | Select-Object -Property id).id
        if ($null -eq $adContainerId) {
          throw "No AdContainer found with name: [$adContainer]"
        }
        $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.AdContainer = $adContainerId
    }
    if ($InstantClone) {
      $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CustomizationType = 'CLONE_PREP'
      $instantCloneEngineDomainAdministrator_helper = New-Object VMware.Hv.InstantCloneEngineDomainAdministratorService
      $instantCloneEngineDomainAdministrator = ($instantCloneEngineDomainAdministrator_helper.InstantCloneEngineDomainAdministrator_List($services) | Where-Object { $_.namesData.dnsName -match $netBiosName })
      if (![string]::IsNullOrWhitespace($domainAdmin)) {
        $instantCloneEngineDomainAdministrator = ($instantCloneEngineDomainAdministrator | Where-Object { $_.base.userName -eq $domainAdmin }).id
      } elseIf ($null -ne $instantCloneEngineDomainAdministrator) {
        $instantCloneEngineDomainAdministrator = $instantCloneEngineDomainAdministrator[0].id
      }
      if ($null -eq $instantCloneEngineDomainAdministrator) {
        throw "No Instant Clone Engine Domain Administrator found with netBiosName: [$netBiosName]"
      }
      $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings = Get-CustomizationObject
      $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings.InstantCloneEngineDomainAdministrator = $instantCloneEngineDomainAdministrator
      $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings.powerOffScriptName = $powerOffScriptName
      $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings.powerOffScriptParameters = $powerOffScriptParameters
      $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings.postSynchronizationScriptName = $postSynchronizationScriptName
      $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings.postSynchronizationScriptParameters = $postSynchronizationScriptParameters
    }
    else {
      if ($LinkedClone) {
        $viewComposerDomainAdministrator_helper = New-Object VMware.Hv.ViewComposerDomainAdministratorService
        $ViewComposerDomainAdministratorID = ($viewComposerDomainAdministrator_helper.ViewComposerDomainAdministrator_List($services,$vcID) | Where-Object { $_.base.domain -match $netBiosName })
        if (![string]::IsNullOrWhitespace($domainAdmin)) {
            $ViewComposerDomainAdministratorID = ($ViewComposerDomainAdministratorID | Where-Object { $_.base.userName -ieq $domainAdmin }).id
        } elseIf ($null -ne $ViewComposerDomainAdministratorID) {
            $ViewComposerDomainAdministratorID = $ViewComposerDomainAdministratorID[0].id
        }
        if ($null -eq $ViewComposerDomainAdministratorID) {
            throw "No Composer Domain Administrator found with netBiosName: [$netBiosName]"
        }
        if ($custType -eq 'SYS_PREP') {
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CustomizationType = 'SYS_PREP'
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.SysprepCustomizationSettings = Get-CustomizationObject

          # Get SysPrep CustomizationSpec ID
          $customization_spec_helper = New-Object VMware.Hv.CustomizationSpecService
          $sysPrepIds = $customization_spec_helper.CustomizationSpec_List($services,$vcID) | Where-Object { $_.customizationSpecData.name -eq $sysPrepName } | Select-Object -Property id
          if ($sysPrepIds.Count -eq 0) {
            throw "No Sysprep Customization Spec found with Name: [$sysPrepName]"
          }
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.SysprepCustomizationSettings.CustomizationSpec = $sysPrepIds[0].id
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.ReusePreExistingAccounts = $reusePreExistingAccounts
        } elseIf ($custType -eq 'QUICK_PREP') {
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CustomizationType = 'QUICK_PREP'
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.QuickprepCustomizationSettings = Get-CustomizationObject
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.QuickprepCustomizationSettings.powerOffScriptName = $powerOffScriptName
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.QuickprepCustomizationSettings.powerOffScriptParameters = $powerOffScriptParameters
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.QuickprepCustomizationSettings.postSynchronizationScriptName = $postSynchronizationScriptName
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.QuickprepCustomizationSettings.postSynchronizationScriptParameters = $postSynchronizationScriptParameters
        } else {
          throw "The customization type: [$custType] is not supported for LinkedClone Pool"
        }
        $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.DomainAdministrator = $ViewComposerDomainAdministratorID
      } elseIf ($FullClone) {
        if ($custType -eq 'SYS_PREP') {
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CustomizationType = 'SYS_PREP'
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.SysprepCustomizationSettings = Get-CustomizationObject
          # Get SysPrep CustomizationSpec ID
          $customization_spec_helper = New-Object VMware.Hv.CustomizationSpecService
          $sysPrepIds = $customization_spec_helper.CustomizationSpec_List($services,$vcID) | Where-Object { $_.customizationSpecData.name -eq $sysPrepName } | Select-Object -Property id
          if ($sysPrepIds.Count -eq 0) {
            throw "No Sysprep Customization Spec found with Name: [$sysPrepName]"
          }
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.SysprepCustomizationSettings.CustomizationSpec = $sysPrepIds[0].id
        } elseIf ($custType -eq 'NONE') {
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.NoCustomizationSettings = Get-CustomizationObject
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.NoCustomizationSettings.DoNotPowerOnVMsAfterCreation = $false
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CustomizationType = "NONE"
        } else {
          throw "The customization type: [$custType] is not supported for FullClone Pool."
        }
      }
    }
    $customObject = $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings
  }
  return $customObject
}

function Get-CustomizationObject {
  if ($InstantClone) {
    return New-Object VMware.Hv.DesktopCloneprepCustomizationSettings
  } elseIf ($LinkedClone) {
    if ($custType -eq 'QUICK_PREP') {
      return New-Object VMware.Hv.DesktopQuickPrepCustomizationSettings
    } else {
      return New-Object VMware.Hv.DesktopSysPrepCustomizationSettings
    }
  } else {
    if ($custType -eq 'SYS_PREP') {
      return New-Object VMware.Hv.DesktopSysPrepCustomizationSettings
    } else {
      return New-Object VMware.Hv.DesktopNoCustomizationSettings
    }
  }
}

function Get-DesktopSpec {

  param(
    [Parameter(Mandatory = $true)]
    [string]$PoolType,

    [Parameter(Mandatory = $false)]
    [string]$ProvisioningType,

    [Parameter(Mandatory = $false)]
    [string]$NamingMethod
  )
  $desktop_helper = New-Object VMware.Hv.DesktopService
  $desktop_spec_helper = $desktop_helper.getDesktopSpecHelper()
  $desktop_spec_helper.setType($poolType)
  if ($poolType -eq $desktop_spec_helper.TYPE_AUTOMATED) {
    if ($namingMethod -eq 'PATTERN') {
      $desktop_spec_helper.getDataObject().AutomatedDesktopSpec.VmNamingSpec.patternNamingSettings = $desktop_helper.getDesktopPatternNamingSettingsHelper().getDataObject()
    } else {
      $desktop_spec_helper.getDataObject().AutomatedDesktopSpec.VmNamingSpec.SpecificNamingSpec = $desktop_helper.getDesktopSpecificNamingSpecHelper().getDataObject()
    }
    if ($provisioningType -ne 'VIRTUAL_CENTER') {
      $desktop_spec_helper.getDataObject().AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.ViewComposerStorageSettings = $desktop_helper.getDesktopViewComposerStorageSettingsHelper().getDataObject()
    }
  } elseIf ($poolType -eq 'MANUAL') {
    $desktop_spec_helper.getDataObject().ManualDesktopSpec.userAssignment = $desktop_helper.getDesktopUserAssignmentHelper().getDataObject()
    $desktop_spec_helper.getDataObject().ManualDesktopSpec.viewStorageAcceleratorSettings = $desktop_helper.getDesktopViewStorageAcceleratorSettingsHelper().getDataObject()
    $desktop_spec_helper.getDataObject().ManualDesktopSpec.virtualCenterManagedCommonSettings = $desktop_helper.getDesktopVirtualCenterManagedCommonSettingsHelper().getDataObject()
  } else {
    $desktop_spec_helper.getDataObject().RdsDesktopSpec = $desktop_helper.getDesktopRDSDesktopSpecHelper().getDataObject()
  }
  return $desktop_spec_helper.getDataObject()

}

function Test-HVPoolSpec {
  param(
    [Parameter(Mandatory = $true)]
    $PoolObject
  )
  if ($null -eq $PoolObject.type) {
    Throw "Pool type is empty, need to be configured"
  }
  if ($null -eq $PoolObject.Base.Name) {
    Throw "Pool name is empty, need to be configured"
  }
  if ($null -eq $PoolObject.Base.AccessGroup) {
    Throw "AccessGroup of pool is empty, need to be configured"
  }
  if ($PoolObject.type -eq "AUTOMATED") {
     if (! (($PoolObject.AutomatedDesktopSpec.UserAssignment.UserAssignment -eq "FLOATING") -or ($PoolObject.AutomatedDesktopSpec.UserAssignment.UserAssignment -eq "DEDICATED")) ) {
        Throw "UserAssignment must be FLOATING or DEDICATED"
     }
     if ($PoolObject.AutomatedDesktopSpec.ProvisioningType -eq $null) {
        Throw "Pool Provisioning type is empty, need to be configured"
     }
     $provisionTypeArray = @('VIRTUAL_CENTER', 'VIEW_COMPOSER', 'INSTANT_CLONE_ENGINE')
     if (! ($provisionTypeArray  -contains $PoolObject.AutomatedDesktopSpec.provisioningType)) {
        Throw "ProvisioningType of pool is invalid"
     }
     if ($null -eq $PoolObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.EnableProvisioning) {
        Throw "Whether to enable provisioning immediately or not, need to be configured"
     }
     if ($null -eq $PoolObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.StopProvisioningOnError) {
        Throw "Whether to stop provisioning immediately or not on error, need to be configured"
     }
     if ($null -eq $PoolObject.AutomatedDesktopSpec.VmNamingSpec.NamingMethod) {
        Throw "Determines how the VMs in the desktop are named, need to be configured"
     }
     if ($null -ne $PoolObject.AutomatedDesktopSpec.VmNamingSpec.NamingMethod) {
        $namingMethodArray = @('PATTERN','SPECIFIED')
        if (! ($namingMethodArray -contains $PoolObject.AutomatedDesktopSpec.VmNamingSpec.NamingMethod)) {
            Throw "NamingMethod property must to be one of these SPECIFIED or PATTERN"
        }
        if (($null -eq $PoolObject.AutomatedDesktopSpec.VmNamingSpec.patternNamingSettings) -and ($null -eq $PoolObject.AutomatedDesktopSpec.VmNamingSpec.specificNamingSpec)) {
            Throw "Naming pattern (or) Specified name settings need to be configured"
        }
     }
     if ($null -eq $PoolObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.UseVSan) {
        Throw "Must specify whether to use virtual SAN or not"
     }
     $jsonTemplate = $PoolObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.Template
     $jsonParentVm = $PoolObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.ParentVm
     $jsonSnapshot = $PoolObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.Snapshot
     $jsonVmFolder = $PoolObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.VmFolder
     $jsonHostOrCluster = $PoolObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.HostOrCluster
     $ResourcePool = $PoolObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.virtualCenterProvisioningData.ResourcePool
     if (! (($null -ne $jsonTemplate) -or (($null -ne $jsonParentVm) -and ($null -ne $jsonSnapshot) ))) {
        Throw "Must specify Template or (ParentVm and Snapshot) names"
     }
     if ($null -eq $jsonVmFolder) {
        Throw "Must specify VM folder to deploy the VMs"
     }
     if ($null -eq $jsonHostOrCluster) {
        Throw "Must specify HostOrCluster to deploy the VMs"
     }
     if ($null -eq $resourcePool) {
        Throw "Must specify Resource pool to deploy the VMs"
     }
     if ($null -eq $PoolObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.Datastores) {
        Throw "Must specify datastores names"
     }
     if ($null -eq $PoolObject.AutomatedDesktopSpec.VirtualCenterManagedCommonSettings.transparentPageSharingScope) {
        Throw "Must specify transparent page sharing scope"
     }
     $jsonCustomizationType = $PoolObject.AutomatedDesktopSpec.CustomizationSettings.CustomizationType
     switch ($jsonCustomizationType) {
        "NONE" {
            if ($null -eq $PoolObject.AutomatedDesktopSpec.CustomizationSettings.noCustomizationSettings) {
                Throw "Specify noCustomization Settings"
            }
        }
        "QUICK_PREP" {
            if ($null -eq $PoolObject.AutomatedDesktopSpec.CustomizationSettings.quickprepCustomizationSettings) {
                Throw "Specify quickPrep customizationSettings"
            }
        }
        "SYS_PREP" {
            if ($null -eq $PoolObject.AutomatedDesktopSpec.CustomizationSettings.sysprepCustomizationSettings) {
                Throw "Specify sysPrep customizationSettings"
            }
        }
        "CLONE_PREP" {
            if ($null -eq $PoolObject.AutomatedDesktopSpec.CustomizationSettings.cloneprepCustomizationSettings) {
                Throw "Specify clonePrep customizationSettings"
            }
        }
     }
  } elseIf ($PoolObject.Type -eq "MANUAL") {
    $jsonUserAssignment = $PoolObject.ManualDesktopSpec.UserAssignment.UserAssignment
    if (! (($jsonUserAssignment -eq "FLOATING") -or ($jsonUserAssignment -eq "DEDICATED")) ) {
        Throw "UserAssignment must be FLOATING or DEDICATED"
    }
    $jsonSource = @('VIRTUAL_CENTER','UNMANAGED')
    if (! ($jsonSource -contains $PoolObject.ManualDesktopSpec.Source)) {
        Throw "The Source of machines must be VIRTUAL_CENTER or UNMANAGED"
    }
    if ($null -eq $PoolObject.ManualDesktopSpec.Machines) {
        Throw "Specify list of virtual machines to be added to this pool"
    }
  }
  elseIf ($PoolObject.type -eq "RDS") {
    if ($null -eq $PoolObject.RdsDesktopSpec.Farm) {
        Throw "Specify farm needed to create RDS desktop"
    }
  }
}

function Remove-HVFarm {
<#
.SYNOPSIS
    Deletes specified farm(s).

.DESCRIPTION
    This function deletes the farm(s) with the specified name/object(s) from the Connection Server. Optionally, user can pipe the farm object(s) as input to this function.

.PARAMETER FarmName
    Name of the farm to be deleted.

.PARAMETER Farm
    Object(s) of the farm to be deleted. Object(s) should be of type FarmSummaryView/FarmInfo.

.PARAMETER HvServer
    Reference to Horizon View Server to query the data from. If the value is not passed or null then first element from global:DefaultHVServers would be considered inplace of hvServer.

.EXAMPLE
   Delete a given farm. For an automated farm, all the RDS Server VMs are deleted from disk whereas for a manual farm only the RDS Server associations are removed.
   Remove-HVFarm -FarmName 'Farm-01' -HvServer $hvServer -Confirm:$false

.EXAMPLE
   Deletes a given Farm object(s). For an automated farm, all the RDS Server VMs are deleted from disk whereas for a manual farm only the RDS Server associations are removed.
   $farm_array | Remove-HVFarm -HvServer $hvServer

.EXAMPLE
   Deletes a given Farm object. For an automated farm, all the RDS Server VMs are deleted from disk whereas for a manual farm only the RDS Server associations are removed.
   $farm1 = Get-HVFarm -FarmName 'Farm-01'
   Remove-HVFarm -Farm $farm1

.OUTPUTS
   None

.NOTES
    Author                      : Ankit Gupta.
    Author email                : guptaa@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'option')]
    [string]
    [ValidateNotNullOrEmpty()] $FarmName,

    # Farmobject
    [Parameter(ValueFromPipeline = $true,Mandatory = $true,ParameterSetName = 'pipeline')]
    [ValidateNotNullOrEmpty()] $Farm,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }
  process {
    $farmList = @()
    if ($farmName) {
      try {
        $farmSpecObj = Get-HVFarm -farmName $farmName -hvServer $hvServer
      } catch {
        Write-Error "Make sure Get-HVFarm advanced function is loaded, $_"
        break
      }
      if ($farmSpecObj) {
        foreach ($farmObj in $farmSpecObj) {
          $farmList += @{"id" = $farmObj.id; "Name" =  $farmObj.data.name}
        }
      } else {
        Write-Error "Unable to retrieve FarmSummaryView with given farmName [$farmName]"
        break
      }
    } elseif ($PSCmdlet.MyInvocation.ExpectingInput -or $Farm) {
      foreach ($item in $farm) {
        if (($item.GetType().name -eq 'FarmInfo') -or ($item.GetType().name -eq 'FarmSummaryView')) {
          $farmList += @{"id" = $item.id; "Name" =  $item.data.name}
        }
        else {
          Write-Error "In pipeline did not get object of expected type FarmSummaryView/FarmInfo"
          [System.gc]::collect()
          return
        }
      }
    }
    $farm_service_helper = New-Object VMware.Hv.FarmService
    foreach ($item in $farmList) {
      if ($pscmdlet.ShouldProcess($item.Name)) {
        $farm_service_helper.Farm_Delete($services, $item.id)
      }
      Write-Host "Farm Deleted: " $item.Name
    }
  }
  end {
    [System.gc]::collect()
  }
}

function Remove-HVPool {
<#
.SYNOPSIS
    Deletes specified pool(s).

.DESCRIPTION
    This function deletes the pool(s) with the specified name/object(s) from Connection Server. This can be used for deleting any pool irrespective of its type.
    Optionally, user can pipe the pool object(s) as input to this function.

.PARAMETER PoolName
    Name of the pool to be deleted.

.PARAMETER Pool
    Object(s) of the pool to be deleted.

.PARAMETER DeleteFromDisk
    Switch parameter to delete the virtual machine(s) from the disk.

.PARAMETER HvServer
    View API service object of Connect-HVServer cmdlet.

.PARAMETER TerminateSession
    Logs off a session forcibly to virtual machine(s). This operation will also log off a locked session.

.EXAMPLE
   Deletes pool from disk with given parameters PoolName etc.
   Remove-HVPool -HvServer $hvServer -PoolName 'FullClone' -DeleteFromDisk -Confirm:$false

.EXAMPLE
   Deletes specified pool from disk
   $pool_array | Remove-HVPool -HvServer $hvServer  -DeleteFromDisk

.EXAMPLE
   Deletes specified pool and VM(s) associations are removed from view Manager
   Remove-HVPool -Pool $pool1

.OUTPUTS
   None

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(
    [Parameter(Mandatory = $false,ParameterSetName = 'option')]
    [string] $poolName,

    # PoolObject
    [Parameter(ValueFromPipeline = $true,ParameterSetName = 'pipeline')]
    $Pool,

    [Parameter(Mandatory = $false)]
    [switch] $TerminateSession = $false,

    [Parameter(Mandatory = $false)]
    [switch] $DeleteFromDisk,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }

  process {
    $poolList = @()
    if ($poolName) {
      try {
        $myPools = Get-HVPoolSummary -poolName $poolName -hvServer $hvServer
      } catch {
        Write-Error "Make sure Get-HVPoolSummary advanced function is loaded, $_"
        break
      }
      if ($myPools) {
        foreach ($poolObj in $myPools) {
          $poolList += @{id = $poolObj.id; name = $poolObj.desktopSummaryData.name}
        }
      } else {
        Write-Error "No desktopsummarydata found with pool name: [$pool]"
        break
      }
    } elseif ($PSCmdlet.MyInvocation.ExpectingInput) {
      foreach ($item in $pool) {
        if ($item.GetType().name -eq 'DesktopSummaryView') {
          $poolList += @{id = $item.id; name = $item.desktopSummaryData.name}
        }
        elseif ($item.GetType().name -eq 'DesktopInfo') {
          $poolList += @{id = $item.id; name = $item.base.name}
        }
        else {
          Write-Error "In pipeline did not get object of expected type DesktopSummaryView/DesktopInfo"
          [System.gc]::collect()
          return
        }
      }
    }
    $desktop_service_helper = New-Object VMware.Hv.DesktopService
    $deleteSpec = New-Object VMware.Hv.DesktopDeleteSpec
    $deleteSpec.DeleteFromDisk = $deleteFromDisk
    foreach ($item in $poolList) {
      if ($terminateSession) {
        #Terminate session
        $queryResults = Get-HVQueryResult MachineSummaryView (Get-HVQueryFilter base.desktop -eq $item.id)
        $sessions += $queryResults.base.session
        if ($null -ne $sessions) {
          $session_service_helper = New-Object VMware.Hv.SessionService
          try {
            Write-Host "Terminating Sessions, it may take few seconds..."
            $session_service_helper.Session_LogoffSessionsForced($services,$sessions)
          } catch {
            Write-Host "Warning: Terminate Session failed."
          }
        } else {
          Write-Host "No session found."
        }
      }
      Write-Host "Deleting Pool: " $item.Name
      if ($pscmdlet.ShouldProcess($item.Name)) {
        $desktop_service_helper.Desktop_Delete($services,$item.id,$deleteSpec)
      }
    }
  }

  end {
    [System.gc]::collect()
  }
}

function Set-HVFarm {
<#
.SYNOPSIS
    Edit farm configuration by passing key/values as parameters/json.

.DESCRIPTION
    This function allows user to edit farm configuration by passing key/value pairs. Optionally, user can pass a JSON spec file. User can also pipe the farm object(s) as input to this function.

.PARAMETER FarmName
    Name of the farm to edit.

.PARAMETER Farm
    Object(s) of the farm to edit. Object(s) should be of type FarmSummaryView/FarmInfo.

.PARAMETER Enable
    Switch to enable the farm(s).

.PARAMETER Disable
    Switch to disable the farm(s).

.PARAMETER Start
    Switch to enable provisioning immediately for the farm(s). It's applicable only for 'AUTOMATED' farm type.

.PARAMETER Stop
    Switch to disable provisioning immediately for the farm(s). It's applicable only for 'AUTOMATED' farm type.

.PARAMETER Key
    Property names path separated by . (dot) from the root of desktop spec.

.PARAMETER Value
    Property value corresponds to above key name.

.PARAMETER Spec
    Path of the JSON specification file containing key/value pair.

.PARAMETER HvServer
    Reference to Horizon View Server to query the data from. If the value is not passed or null then first element from global:DefaultHVServers would be considered inplace of hvServer.

.EXAMPLE
    Updates farm configuration by using json file
    Set-HVFarm -FarmName 'Farm-01' -Spec 'C:\Edit-HVFarm\ManualEditFarm.json' -Confirm:$false

.EXAMPLE
    Updates farm configuration with given parameters key and value
    Set-HVFarm -FarmName 'Farm-01' -Key 'base.description' -Value 'updated description'

.EXAMPLE
    Updates farm(s) configuration with given parameters key and value
    $farm_array | Set-HVFarm -Key 'base.description' -Value 'updated description'

.EXAMPLE
    Enables provisioning to specified farm
    Set-HVFarm -farm 'Farm2' -Start

.EXAMPLE
    Enables specified farm
    Set-HVFarm -farm 'Farm2' -Enable

.OUTPUTS
    None

.NOTES
    Author                      : Ankit Gupta.
    Author email                : guptaa@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'option')]
    [string]$FarmName,

    [Parameter(ValueFromPipeline = $true,ParameterSetName = 'pipeline')]
    $Farm,

    [Parameter(Mandatory = $false)]
    [switch]$Enable,

    [Parameter(Mandatory = $false)]
    [switch]$Disable,

    [Parameter(Mandatory = $false)]
    [switch]$Start,

    [Parameter(Mandatory = $false)]
    [switch]$Stop,

    [Parameter(Mandatory = $false)]
    [string]$Key,

    [Parameter(Mandatory = $false)]
    $Value,

    [Parameter(Mandatory = $false)]
    [string]$Spec,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }

  process {
    $farmList = @{}
    if ($farmName) {
      try {
        $farmSpecObj = Get-HVFarmSummary -farmName $farmName -hvServer $hvServer
      } catch {
        Write-Error "Make sure Get-HVFarmSummary advanced function is loaded, $_"
        break
      }
      if ($farmSpecObj) {
        foreach ($farmObj in $farmSpecObj) {
          if (($Start -or $Stop) -and ("AUTOMATED" -ne $farmObj.Data.Type)) {
            Write-Error "Start/Stop operation is not supported for farm with name : [$farmObj.Data.Name]"
            return
          }
          $farmList.add($farmObj.id, $farmObj.data.name)
        }
      } else {
        Write-Error "Unable to retrieve FarmSummaryView with given farmName [$farmName]"
        break
      }
    } elseif ($PSCmdlet.MyInvocation.ExpectingInput) {
      foreach ($item in $farm) {
        if ($item.GetType().name -eq 'FarmSummaryView') {
          if (($Start -or $Stop) -and ("AUTOMATED" -ne $item.Data.Type)) {
            Write-Error "Start/Stop operation is not supported for farm with name : [$item.Data.Name]"
            return
          }
          $farmList.add($item.id, $item.data.name)
        }
        elseif ($item.GetType().name -eq 'FarmInfo') {
          if (($Start -or $Stop) -and ("AUTOMATED" -ne $item.Type)) {
            Write-Error "Start/Stop operation is not supported for farm with name : [$item.Data.Name]"
            return
          }
          $farmList.add($item.id, $item.data.name)
        }
        else {
          Write-Error "In pipeline did not get object of expected type FarmSummaryView/FarmInfo"
          [System.gc]::collect()
          return
        }
      }
    }

    $updates = @()
    if ($key -and $value) {
      $updates += Get-MapEntry -key $key -value $value
    } elseif ($key -or $value) {
      Write-Error "Both key:[$key] and value:[$value] need to be specified"
    }
    if ($spec) {
      $specObject = Get-JsonObject -specFile $spec
      foreach ($member in ($specObject.PSObject.Members | Where-Object { $_.MemberType -eq 'NoteProperty' })) {
        $updates += Get-MapEntry -key $member.name -value $member.value
      }
    }
    if ($Enable) {
      $updates += Get-MapEntry -key 'data.enabled' -value $true
    }
    elseif ($Disable) {
      $updates += Get-MapEntry -key 'data.enabled' -value $false
    }
    elseif ($Start) {
      $updates += Get-MapEntry -key 'automatedFarmData.virtualCenterProvisioningSettings.enableProvisioning' `
            -value $true
    }
    elseif ($Stop) {
      $updates += Get-MapEntry -key 'automatedFarmData.virtualCenterProvisioningSettings.enableProvisioning' `
            -value $false
    }
    $farm_service_helper = New-Object VMware.Hv.FarmService
    foreach ($item in $farmList.Keys) {
      if ($pscmdlet.ShouldProcess($farmList.$item)) {
        $farm_service_helper.Farm_Update($services,$item,$updates)
      }
      Write-Host "Update successful for farm: " $farmList.$item
    }
  }

  end {
    $updates = $null
    [System.gc]::collect()
  }
}

function Set-HVPool {
<#
.SYNOPSIS
    Sets the existing pool properties.

.DESCRIPTION
    This cmdlet allows user to edit pool configuration by passing key/value pair. Optionally, user can pass a JSON spec file.

.PARAMETER PoolName
    Name of the pool to edit.

.PARAMETER Pool
    Object(s) of the pool to edit.

.PARAMETER Enable
    Switch parameter to enable the pool.

.PARAMETER Disable
    Switch parameter to disable the pool.

.PARAMETER Start
    Switch parameter to start the pool.

.PARAMETER Stop
    Switch parameter to stop the pool.

.PARAMETER Key
    Property names path separated by . (dot) from the root of desktop spec.

.PARAMETER Value
    Property value corresponds to above key name.

.PARAMETER HvServer
    View API service object of Connect-HVServer cmdlet.

.PARAMETER Spec
    Path of the JSON specification file containing key/value pair.

.EXAMPLE
    Updates pool configuration by using json file
    Set-HVPool -PoolName 'ManualPool' -Spec 'C:\Edit-HVPool\EditPool.json' -Confirm:$false

.EXAMPLE
    Updates pool configuration with given parameters key and value
    Set-HVPool -PoolName 'RDSPool' -Key 'base.description' -Value 'update description'

.Example
    Disables specified pool
    Set-HVPool  -PoolName 'LnkClone' -Disable

.Example
    Enables specified pool
    Set-HVPool  -PoolName 'LnkClone' -Enable

.Example
    Enables provisioning to specified pool
    Set-HVPool  -PoolName 'LnkClone' -Start

.Example
    Disables provisioning to specified pool
    Set-HVPool  -PoolName 'LnkClone' -Stop

.OUTPUTS
    None

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]

  param(
    [Parameter(Mandatory = $true,ParameterSetName = 'option')]
    [string]$PoolName,

    #pool object
    [Parameter(ValueFromPipeline = $true,ParameterSetName = 'pipeline')]
    $Pool,

    [Parameter(Mandatory = $false)]
    [switch]$Enable,

    [Parameter(Mandatory = $false)]
    [switch]$Disable,

    [Parameter(Mandatory = $false)]
    [switch]$Start,

    [Parameter(Mandatory = $false)]
    [switch]$Stop,

    [Parameter(Mandatory = $false)]
    [string]$Key,

    [Parameter(Mandatory = $false)]
    $Value,

    [Parameter(Mandatory = $false)]
    [string]$Spec,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }

  process {
    $poolList = @{}
    if ($poolName) {
      try {
        $desktopPools = Get-HVPoolSummary -poolName $poolName -hvServer $hvServer
      } catch {
        Write-Error "Make sure Get-HVPoolSummary advanced function is loaded, $_"
        break
      }
      if ($desktopPools) {
        foreach ($desktopObj in $desktopPools) {
          if (($Start -or $Stop) -and ("AUTOMATED" -ne $item.DesktopSummaryData.Type)) {
            Write-Error "Start/Stop operation is not supported for Poll with name : [$item.DesktopSummaryData.Name]"
            return
          }
          $poolList.add($desktopObj.id, $desktopObj.DesktopSummaryData.Name)
        }
      }
    } elseif ($PSCmdlet.MyInvocation.ExpectingInput -or $Pool) {
      foreach ($item in $pool) {
        if ($item.GetType().name -eq 'DesktopInfo') {
          if (($Start -or $Stop) -and ("AUTOMATED" -ne $item.Type)) {
            Write-Error "Start/Stop operation is not supported for Pool with name : [$item.Base.Name]"
            return
          }
          $poolList.add($item.id, $item.Base.Name)
        }
        elseif ($item.GetType().name -eq 'DesktopSummaryView') {
          if (($Start -or $Stop) -and ("AUTOMATED" -ne $item.DesktopSummaryData.Type)) {
            Write-Error "Start/Stop operation is not supported for Poll with name : [$item.DesktopSummaryData.Name]"
            return
          }
          $poolList.add($item.id, $item.DesktopSummaryData.Name)
        }
        else {
          Write-Error "In pipeline did not get object of expected type DesktopSummaryView/DesktopInfo"
          [System.gc]::collect()
          return
        }
      }
    }
    $updates = @()
    if ($key -and $value) {
      $updates += Get-MapEntry -key $key -value $value
    } elseif ($key -or $value) {
      Write-Error "Both key:[$key] and value:[$value] needs to be specified"
    }
    if ($spec) {
      try {
        $specObject = Get-JsonObject -specFile $spec
      } catch {
        Write-Error "Json file exception, $_"
        return
      }
      foreach ($member in ($specObject.PSObject.Members | Where-Object { $_.MemberType -eq 'NoteProperty' })) {
        $updates += Get-MapEntry -key $member.name -value $member.value
      }
    }
    if ($Enable) {
      $updates += Get-MapEntry -key 'desktopSettings.enabled' -value $true
    }
    elseif ($Disable) {
      $updates += Get-MapEntry -key 'desktopSettings.enabled' -value $false
    }
    elseif ($Start) {
      $updates += Get-MapEntry -key 'automatedDesktopData.virtualCenterProvisioningSettings.enableProvisioning' `
        -value $true
    }
    elseif ($Stop) {
      $updates += Get-MapEntry -key 'automatedDesktopData.virtualCenterProvisioningSettings.enableProvisioning' `
        -value $false
    }
    $desktop_helper = New-Object VMware.Hv.DesktopService
    foreach ($item in $poolList.Keys) {
      if ($pscmdlet.ShouldProcess($poolList.$item)) {
       $desktop_helper.Desktop_Update($services,$item,$updates)
      }
    }
    Write-Host "Update successful for Pool: " $poolList.$item
  }

  end {
    [System.gc]::collect()
  }
}

function Start-HVFarm {
<#
.SYNOPSIS
    Performs maintenance tasks on the farm(s).

.DESCRIPTION
    This function is used to perform maintenance tasks like enable/disable, start/stop and recompose the farm. This function is also used for scheduling maintenance operation on instant-clone farm(s).

.PARAMETER Farm
    Name/Object(s) of the farm. Object(s) should be of type FarmSummaryView/FarmInfo.

.PARAMETER Recompose
    Switch for recompose operation. Requests a recompose of RDS Servers in the specified 'AUTOMATED' farm. This marks the RDS Servers for recompose, which is performed asynchronously.

.PARAMETER Schedule_Maintenance
    Switch for Schedule_Maintenance operation. Requests for scheduling maintenance operation on RDS Servers in the specified Instant clone farm. This marks the RDS Servers for scheduled maintenance, which is performed according to the schedule.

.PARAMETER Cancel_Maintenance
    Switch for cancelling maintenance operation. Requests for cancelling a scheduled maintenance operation on the specified Instant clone farm. This stops further maintenance operation on the given farm.

.PARAMETER StartTime
    Specifies when to start the recompose/Schedule_Maintenance operation. If unset, the recompose operation will begin immediately.
    For IMMEDIATE maintenance if unset, maintenance will begin immediately. For RECURRING maintenance if unset, will be calculated based on recurring maintenance configuration. If in the past, maintenance will begin immediately.

.PARAMETER LogoffSetting
    Determines when to perform the operation on machines which have an active session. This property will be one of:
    "FORCE_LOGOFF" - Users will be forced to log off when the system is ready to operate on their RDS Servers. Before being forcibly logged off, users may have a grace period in which to save their work (Global Settings). This is the default value.
    "WAIT_FOR_LOGOFF" - Wait for connected users to disconnect before the task starts. The operation starts immediately on RDS Servers without active sessions.

.PARAMETER StopOnFirstError
    Indicates that the operation should stop on first error. Defaults to true.

.PARAMETER Servers
    The RDS Server(s) id to recompose. Provide a comma separated list for multiple RDSServerIds.

.PARAMETER ParentVM
    New base image VM for automated farm's RDS Servers. This must be in the same datacenter as the base image of the RDS Server.

.PARAMETER SnapshotVM
    Base image snapshot for the Automated Farm's RDS Servers.

.PARAMETER Vcenter
    Virtual Center server-address (IP or FQDN) of the given farm. This should be same as provided to the Connection Server while adding the vCenter server.

.PARAMETER MaintenanceMode
    The mode of schedule maintenance for Instant Clone Farm. This property will be one of:
    "IMMEDIATE"	- All server VMs will be refreshed once, immediately or at user scheduled time.
    "RECURRING"	- All server VMs will be periodically refreshed based on MaintenancePeriod and MaintenanceStartTime.

.PARAMETER MaintenanceStartTime
    Configured start time for the recurring maintenance. This property must be in the form hh:mm in 24 hours format.

.PARAMETER MaintenancePeriod
    This represents the frequency at which to perform recurring maintenance. This property will be one of:
    "DAILY"	- Daily recurring maintenance
    "WEEKLY" - Weekly recurring maintenance
    "MONTHLY" - Monthly recurring maintenance

.PARAMETER StartInt
    Start index for weekly or monthly maintenance. Weekly: 1-7 (Sun-Sat), Monthly: 1-31.
    This property is required if maintenancePeriod is set to "WEEKLY"or "MONTHLY".
    This property has values 1-7 for maintenancePeriod "WEEKLY".
    This property has values 1-31 for maintenancePeriod "MONTHLY".

.PARAMETER EveryInt
    How frequently to repeat maintenance, expressed as a multiple of the maintenance period. e.g. Every 2 weeks.
    This property has a default value of 1. This property has values 1-100.

.PARAMETER HvServer
    Reference to Horizon View Server to query the data from. If the value is not passed or null then first element from global:DefaultHVServers would be considered inplace of hvServer.

.EXAMPLE
    Requests a recompose of RDS Servers in the specified automated farm
    Start-HVFarm -Recompose -Farm 'Farm-01' -LogoffSetting FORCE_LOGOFF -ParentVM 'View-Agent-Win8' -SnapshotVM 'Snap_USB' -Confirm:$false

.EXAMPLE
    Requests a recompose task for automated farm in specified time
    $myTime = Get-Date '10/03/2016 12:30:00'
    Start-HVFarm -Farm 'Farm-01' -Recompose -LogoffSetting 'FORCE_LOGOFF' -ParentVM 'ParentVM' -SnapshotVM 'SnapshotVM' -StartTime $myTime

.EXAMPLE
    Requests a Schedule_Maintenance task for instant-clone farm. Schedules an IMMEDIATE maintenance.
    Start-HVFarm -Farm 'ICFarm-01' -Schedule_Maintenance -MaintenanceMode IMMEDIATE

.EXAMPLE
    Requests a Schedule_Maintenance task for instant-clone farm. Schedules a recurring weekly maintenace every Saturday night at 23:30 and updates the parentVM and snapshot.
    Start-HVFarm -Schedule_Maintenance -Farm 'ICFarm-01' -MaintenanceMode RECURRING -MaintenancePeriod WEEKLY -MaintenanceStartTime '11:30' -StartInt 6 -EveryInt 1 -ParentVM 'vm-rdsh-ic' -SnapshotVM 'Snap_Updated'

.EXAMPLE
    Requests a Cancel_Maintenance task for instant-clone farm. Cancels recurring maintenance.
    Start-HVFarm -Cancel_Maintenance -Farm 'ICFarm-01' -MaintenanceMode RECURRING

.OUTPUTS
    None

.NOTES
    Author                      : Ankit Gupta.
    Author email                : guptaa@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(
    [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
    $Farm,

    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [switch]$Recompose,

    [Parameter(Mandatory = $false,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [switch]$Schedule_Maintenance,

    [Parameter(Mandatory = $false,ParameterSetName = 'CANCEL_MAINTENANCE')]
    [switch]$Cancel_Maintenance,

    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [System.DateTime]$StartTime,

    [Parameter(Mandatory = $true,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [ValidateSet('FORCE_LOGOFF','WAIT_FOR_LOGOFF')]
    [string]$LogoffSetting = 'FORCE_LOGOFF',

    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [boolean]$StopOnFirstError = $true,

    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [string []]$Servers,

    [Parameter(Mandatory = $true,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [string]$ParentVM,

    [Parameter(Mandatory = $true,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [string]$SnapshotVM,

    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [string]$Vcenter,

    [Parameter(Mandatory = $true,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'CANCEL_MAINTENANCE')]
    [ValidateSet('IMMEDIATE','RECURRING')]
    [string]$MaintenanceMode,

    [Parameter(Mandatory = $false,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [ValidatePattern('^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$')]
    [string]$MaintenanceStartTime,

    [Parameter(Mandatory = $false,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [ValidateSet('DAILY','WEEKLY','MONTHLY')]
    [string]$MaintenancePeriod,

    [Parameter(Mandatory = $false,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [ValidateRange(1, 31)]
    [int]$StartInt,

    [Parameter(Mandatory = $false,ParameterSetName = 'SCHEDULE_MAINTENANCE')]
    [ValidateRange(1, 100)]
    [int]$EveryInt = 1,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }

  process {
    $farmList = @{}
    $farmType = @{}
    $farmSource = @{}
    $farm_service_helper = New-Object VMware.Hv.FarmService
    if ($farm) {
      if ($farm.GetType().name -eq 'FarmInfo') {
        $id = $farm.id
        $name = $farm.data.name
        $type = $farm.type
        $source = $farm.source
      }
      elseif ($farm.GetType().name -eq 'FarmSummaryView') {
        $id = $farm.id
        $name = $farm.data.name
        $type = $farm.data.type
        $source = $farm.data.source
      }
      elseif ($farm.GetType().name -eq 'String') {
        try {
          $farmSpecObj = Get-HVFarm -farmName $farm -hvServer $hvServer
        } catch {
          Write-Error "Make sure Get-HVFarm advanced function is loaded, $_"
          break
        }
        if ($farmSpecObj) {
          $id = $farmSpecObj.id
          $name = $farmSpecObj.data.name
          $type = $farmSpecObj.type
          $source = $farmSpecObj.source
        } else {
          Write-Error "Unable to retrieve FarmSummaryView with given farmName [$farm]"
          break
        }
      } else {
        Write-Error "In pipeline did not get object of expected type FarmSummaryView/FarmInfo"
        break
      }
      if (!$source) {
        $source = 'VIEW_COMPOSER'
      }
      $farmList.Add($id,$name)
      $farmType.Add($id,$type)
      $farmSource.Add($id,$source)
    }
  }


  end {
    foreach ($item in $farmList.Keys) {
      $operation = $PsCmdlet.ParameterSetName
      Write-Host "Performing $operation" on $farmList.$item
      switch ($operation) {
        'RECOMPOSE' {
          if ($farmSource.$item -ne 'VIEW_COMPOSER') {
            Write-Error "RECOMPOSE operation is not supported for farm with name [$farmList.$item]"
            break
          } else {
            $vcId = Get-VcenterID -services $services -vCenter $vCenter
            if ($null -eq $vcId) {
              break
            }
            $serverList = Get-AllRDSServersInFarm -services $services -farm $item -serverList $servers
            if ($null -eq $serverList) {
              Write-Error "No servers found for the farm [$item]"
            }
            $spec = New-Object VMware.Hv.FarmRecomposeSpec
            $spec.LogoffSetting = $logoffSetting
            $spec.StopOnFirstError = $stopOnFirstError
            $spec.RdsServers = $serverList
            try {
              $spec = Set-HVFarmSpec -vcId $vcId -spec $spec
            } catch {
              Write-Error "RECOMPOSE task failed with error: $_"
              break
            }
            if ($startTime) { $spec.startTime = $startTime }
            # Update Base Image VM and Snapshot in Farm
            $updates = @()
            $updates += Get-MapEntry -key 'automatedFarmData.virtualCenterProvisioningSettings.virtualCenterProvisioningData.parentVm' -value $spec.ParentVM
            $updates += Get-MapEntry -key 'automatedFarmData.virtualCenterProvisioningSettings.virtualCenterProvisioningData.snapshot' -value $spec.Snapshot
            if ($pscmdlet.ShouldProcess($farmList.$item)) {
              $farm_service_helper.Farm_Update($services,$item,$updates)
              $farm_service_helper.Farm_Recompose($services,$item,$spec)
            }
            Write-Host "Performed recompose task on farm: " $farmList.$item
          }
        }
        'SCHEDULE_MAINTENANCE' {
          if ($farmSource.$item -ne 'INSTANT_CLONE_ENGINE') {
            Write-Error "SCHEDULE_MAINTENANCE operation is not supported for farm with name [$farmList.$item]. It is only supported for instant-clone farms."
            break
          } else {
            $spec = New-Object VMware.Hv.FarmMaintenanceSpec
            $spec.MaintenanceMode = $MaintenanceMode
            $spec.ScheduledTime = $StartTime
            if ($MaintenanceMode -eq "RECURRING") {
                $spec.RecurringMaintenanceSettings = New-Object VMware.Hv.FarmRecurringMaintenanceSettings
                $spec.RecurringMaintenanceSettings.MaintenancePeriod = $MaintenancePeriod
                $spec.RecurringMaintenanceSettings.EveryInt = $EveryInt
                if (!$MaintenanceStartTime) {
                    Write-Error "MaintenanceStartTime must be defined for MaintenanceMode = RECURRING."
                    break;
                } else {
                    $spec.RecurringMaintenanceSettings.StartTime = $MaintenanceStartTime
                }
                if ($MaintenancePeriod -ne 'DAILY') {
                    if (!$StartInt) {
                        Write-Error "StartInt must be defined for MaintenancePeriod WEEKLY or MONTHLY."
                        break;
                    } else {
                        $spec.RecurringMaintenanceSettings.StartInt = $StartInt
                    }
                }
            }
            #image settings are specified
            if ($ParentVM -and $SnapshotVM) {
                $spec.ImageMaintenanceSettings = New-Object VMware.Hv.FarmImageMaintenanceSettings
                $spec.ImageMaintenanceSettings.LogoffSetting = $LogoffSetting
                $spec.ImageMaintenanceSettings.StopOnFirstError = $StopOnFirstError
                $vcId = Get-VcenterID -services $services -vCenter $Vcenter
                if ($null -eq $vcId) {
                    Write-Error "VCenter is required if you specify ParentVM name."
                    break
                }
                try {
                    $spec.ImageMaintenanceSettings = Set-HVFarmSpec -vcId $vcId -spec $spec.ImageMaintenanceSettings
                } catch {
                    Write-Error "SCHEDULE_MAINTENANCE task failed with error: $_"
                    break
                }
            }
            # call scheduleMaintenance service on farm
            if ($pscmdlet.ShouldProcess($farmList.$item)) {
              $farm_service_helper.Farm_ScheduleMaintenance($services, $item, $spec)
              Write-Host "Performed SCHEDULE_MAINTENANCE task on farm: " $farmList.$item
            }
          }
        }
        'CANCEL_MAINTENANCE' {
            if ($pscmdlet.ShouldProcess($farmList.$item)) {
              $farm_service_helper.Farm_CancelScheduleMaintenance($services, $item, $MaintenanceMode)
              Write-Host "Performed CANCEL_MAINTENANCE task on farm: " $farmList.$item
            }
          }
        }
      return
    }
  }

}

function Get-AllRDSServersInFarm ($Services,$Farm,$ServerList) {
  [VMware.Hv.RDSServerId[]]$servers = @()
  $query_service_helper = New-Object VMware.Hv.QueryServiceService
  $remainingCount = 1 # run through loop at least once
  $query = New-Object VMware.Hv.QueryDefinition
  $query.queryEntityType = 'RDSServerSummaryView'
  $farmFilter = New-Object VMware.Hv.QueryFilterEquals -Property @{ 'MemberName' = 'base.farm'; 'value' = $farm }
  if ($serverList) {
    $serverFilters = [VMware.Hv.queryFilter[]]@()
    foreach ($name in $serverList) {
      $serverFilters += (New-Object VMware.Hv.QueryFilterEquals -Property @{ 'memberName' = 'base.name'; 'value' = $name })
    }
    $serverList = New-Object VMware.Hv.QueryFilterOr -Property @{ 'filters' = $serverFilters }
    $treeList = @()
    $treeList += $serverList
    $treelist += $farmFilter
    $query.Filter = New-Object VMware.Hv.QueryFilterAnd -Property @{ 'filters' = $treeList }
  } else {
    $query.Filter = $farmFilter
  }
  while ($remainingCount -ge 1) {
    $queryResults = $query_service_helper.QueryService_Query($services,$query)
    $results = $queryResults.results
    $servers += $results.id
    $query.StartingOffset = $query.StartingOffset + $queryResults.results.Count
    $remainingCount = $queryResults.RemainingCount
  }
  return $servers
}

function Set-HVFarmSpec {
  param(
    [Parameter(Mandatory = $true)]
    [VMware.Hv.VirtualCenterId]$VcID,

    [Parameter(Mandatory = $true)]
    $Spec
  )
  if ($parentVM) {
    $baseImage_service_helper = New-Object VMware.Hv.BaseImageVmService
    $parentList = $baseImage_service_helper.BaseImageVm_List($services, $vcID)
    $parentVMObj = $parentList | Where-Object { $_.name -eq $parentVM }
    if ($null -eq $parentVMObj) {
      throw "No Parent VM found with name: [$parentVM]"
    }
    $spec.ParentVm = $parentVMObj.id
  }
  if ($snapshotVM) {
    $parentVM = $spec.ParentVm.id
    $baseImageSnapshot_service_helper = New-Object VMware.Hv.BaseImageSnapshotService
    $snapshotList = $baseImageSnapshot_service_helper.BaseImageSnapshot_List($services, $spec.ParentVm)
    $snapshotVMObj = $snapshotList | Where-Object { $_.name -eq $snapshotVM }
    if ($null -eq $snapshotVMObj) {
      throw "No Snapshot found with name: [$snapshotVM] for VM name: [$parentVM] "
    }
    $spec.Snapshot = $snapshotVMObj.id
  }
  return $spec
}

function Start-HVPool {
<#
.SYNOPSIS
    Perform maintenance tasks on Pool.

.DESCRIPTION
    This cmdlet is used to perform maintenance tasks like enable/disable the pool, enable/disable the provisioning of a pool, refresh, rebalance, recompose, push image and cancel image. Push image and Cancel image tasks only applies for instant clone pool.

.PARAMETER Pool
    Name/Object(s) of the pool.

.PARAMETER Refresh
    Switch parameter to refresh operation.

.PARAMETER Recompose
    Switch parameter to recompose operation.

.PARAMETER Rebalance
    Switch parameter to rebalance operation.

.PARAMETER SchedulePushImage
    Switch parameter to push image operation.

.PARAMETER CancelPushImage
    Switch parameter to cancel push image operation.

.PARAMETER StartTime
    Specifies when to start the operation. If unset, the operation will begin immediately.

.PARAMETER LogoffSetting
    Determines when to perform the operation on machines which have an active session. This property will be one of:
    'FORCE_LOGOFF' - Users will be forced to log off when the system is ready to operate on their virtual machines.
    'WAIT_FOR_LOGOFF' - Wait for connected users to disconnect before the task starts. The operation starts immediately on machines without active sessions.

.PARAMETER StopOnFirstError
    Indicates that the operation should stop on first error.

.PARAMETER Machines
    The machine names to recompose. These must be associated with the pool.

.PARAMETER ParentVM
    New base image VM for the desktop. This must be in the same datacenter as the base image of the desktop.

.PARAMETER SnapshotVM
    Name of the snapshot used in pool deployment.

.PARAMETER Vcenter
    Virtual Center server-address (IP or FQDN) of the given pool. This should be same as provided to the Connection Server while adding the vCenter server.

.PARAMETER HvServer
    View API service object of Connect-HVServer cmdlet.

.EXAMPLE
    Requests a recompose of machines in the specified pool
    Start-HVPool -Recompose -Pool 'LCPool3' -LogoffSetting FORCE_LOGOFF -ParentVM 'View-Agent-Win8' -SnapshotVM 'Snap_USB'

.EXAMPLE
    Requests a refresh of machines in the specified pool
    Start-HVPool -Refresh -Pool 'LCPool3' -LogoffSetting FORCE_LOGOFF -Confirm:$false

.EXAMPLE
    Requests a rebalance of machines in a pool with specified time
    $myTime = Get-Date '10/03/2016 12:30:00'
    Start-HVPool -Rebalance -Pool 'LCPool3' -LogoffSetting FORCE_LOGOFF -StartTime $myTime

.EXAMPLE
    Requests an update of push image operation on the specified Instant Clone Engine sourced pool
    Start-HVPool -SchedulePushImage -Pool 'InstantPool' -LogoffSetting FORCE_LOGOFF -ParentVM 'InsParentVM' -SnapshotVM 'InsSnapshotVM'

.EXAMPLE
    Requests a cancellation of the current scheduled push image operation on the specified Instant Clone Engine sourced pool
    Start-HVPool -CancelPushImage -Pool 'InstantPool'

.OUTPUTS
    None

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.0

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(
    # handles both objects and string
    [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
    $Pool,

    [Parameter(Mandatory = $false,ParameterSetName = 'REFRESH')]
    [switch]$Refresh,

    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [switch]$Recompose,

    [Parameter(Mandatory = $false,ParameterSetName = 'REBALANCE')]
    [switch]$Rebalance,

    [Parameter(Mandatory = $false,ParameterSetName = 'PUSH_IMAGE')]
    [switch]$SchedulePushImage,

    [Parameter(Mandatory = $false,ParameterSetName = 'CANCEL_PUSH_IMAGE')]
    [switch]$CancelPushImage,

    [Parameter(Mandatory = $false,ParameterSetName = 'REBALANCE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'REFRESH')]
    [Parameter(Mandatory = $false,ParameterSetName = 'PUSH_IMAGE')]
    [System.DateTime]$StartTime,

    [Parameter(Mandatory = $true,ParameterSetName = 'REBALANCE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'REFRESH')]
    [Parameter(Mandatory = $false,ParameterSetName = 'PUSH_IMAGE')]
    [ValidateSet('FORCE_LOGOFF','WAIT_FOR_LOGOFF')]
    [string]$LogoffSetting,

    [Parameter(Mandatory = $false,ParameterSetName = 'REBALANCE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'REFRESH')]
    [Parameter(Mandatory = $false,ParameterSetName = 'PUSH_IMAGE')]
    [boolean]$StopOnFirstError = $true,

    [Parameter(Mandatory = $false,ParameterSetName = 'REBALANCE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'REFRESH')]
    [string []]$Machines,

    [Parameter(Mandatory = $true,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'PUSH_IMAGE')]
    [string]$ParentVM,

    [Parameter(Mandatory = $true,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'PUSH_IMAGE')]
    [string]$SnapshotVM,

    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'PUSH_IMAGE')]
    [string]$Vcenter,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )


  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }

  process {

    $poolList = @{}
    $poolType = @{}
    $poolSource = @{}
    if ($pool) {
      foreach ($item in $pool) {
        if ($item.GetType().name -eq 'DesktopInfo') {
          $id = $item.id
          $name = $item.base.name
          $source = $item.source
          $type = $item.type
        } elseif ($item.GetType().name -eq 'DesktopSummaryView') {
          $id = $item.id
          $name = $item.desktopsummarydata.name
          $source = $item.desktopsummarydata.source
          $type = $item.desktopsummarydata.type
        } elseif ($item.GetType().name -eq 'String') {
          try {
            $poolObj = Get-HVPoolSummary -poolName $item -hvServer $hvServer
          } catch {
            Write-Error "Make sure Get-HVPoolSummary advanced function is loaded, $_"
            break
          }
          if ($poolObj) {
            $id = $poolObj.id
            $name = $poolObj.desktopsummarydata.name
            $source = $poolObj.desktopsummarydata.source
            $type = $poolObj.desktopsummarydata.type
          } else {
            Write-Error "No desktopsummarydata found with pool name: [$item]"
            break
          }
        } else {
          Write-Error "In pipeline did not get object of expected type DesktopSummaryView/DesktopInfo"
          break
        }
        $poolList.Add($id,$name)
        $poolType.Add($id,$type)
        $poolSource.Add($id,$source)
      }
    }
  }

  end {
    foreach ($item in $poolList.Keys) {
      $operation = $PsCmdlet.ParameterSetName
      Write-Host "Performing $operation on" $poolList.$item
      $desktop_helper = New-Object VMware.Hv.DesktopService
      switch ($operation) {
        'REBALANCE' {
          $spec = Get-HVTaskSpec -Source $poolSource.$item -poolName $poolList.$item -operation $operation -taskSpecName 'DesktopRebalanceSpec' -desktopId $item
          if ($null -ne $spec) {
            # make sure current task on VMs, must be None
            if ($pscmdlet.ShouldProcess($poolList.$item)) {
              $desktop_helper.Desktop_Rebalance($services,$item,$spec)
            }
            Write-Host "Performed rebalance task on Pool: " $PoolList.$item
          }
        }
        'REFRESH' {
          $spec = Get-HVTaskSpec -Source $poolSource.$item -poolName $poolList.$item -operation $operation -taskSpecName 'DesktopRefreshSpec' -desktopId $item
          if ($null -ne $spec) {
            # make sure current task on VMs, must be None
            if ($pscmdlet.ShouldProcess($poolList.$item)) {
              $desktop_helper.Desktop_Refresh($services,$item,$spec)
            }
            Write-Host "Performed refresh task on Pool: " $PoolList.$item
          }
        }
        'RECOMPOSE' {
          $spec = Get-HVTaskSpec -Source $poolSource.$item -poolName $poolList.$item -operation $operation -taskSpecName 'DesktopRecomposeSpec' -desktopId $item
          if ($null -ne $spec) {
            $vcId = Get-VcenterID -services $services -vCenter $vCenter
            $spec = Set-HVPoolSpec -vcId $vcId -spec $spec

            # make sure current task on VMs, must be None
            $desktop_helper.Desktop_Recompose($services,$item,$spec)

            # Update Base Image VM and Snapshot in Pool
            $updates = @()
            $updates += Get-MapEntry -key 'automatedDesktopData.virtualCenterProvisioningSettings.virtualCenterProvisioningData.parentVm' -value $spec.ParentVM
            $updates += Get-MapEntry -key 'automatedDesktopData.virtualCenterProvisioningSettings.virtualCenterProvisioningData.snapshot' -value $spec.Snapshot
            if ($pscmdlet.ShouldProcess($poolList.$item)) {
              $desktop_helper.Desktop_Update($services,$item,$updates)
            }
            Write-Host "Performed recompose task on Pool: " $PoolList.$item
          }
        }
        'PUSH_IMAGE' {
          if ($poolSource.$item -ne 'INSTANT_CLONE_ENGINE') {
            Write-Error "$poolList.$item is not a INSTANT CLONE pool"
            break
          } else {
            $spec = New-Object VMware.Hv.DesktopPushImageSpec
            $vcId = Get-VcenterID -services $services -vCenter $vCenter
            $spec = Set-HVPoolSpec -vcId $vcId -spec $spec
            $spec.Settings = New-Object VMware.Hv.DesktopPushImageSettings
            $spec.Settings.LogoffSetting = $logoffSetting
            $spec.Settings.StopOnFirstError = $stopOnFirstError
            if ($startTime) { $spec.Settings.startTime = $startTime }
            if ($pscmdlet.ShouldProcess($poolList.$item)) {
              $desktop_helper.Desktop_SchedulePushImage($services,$item,$spec)
            }
            Write-Host "Performed push_image task on Pool: " $PoolList.$item
          }
        }
        'CANCEL_PUSH_IMAGE' {
          if ($poolSource.$item -ne 'INSTANT_CLONE_ENGINE') {
            Write-Error "$poolList.$item is not a INSTANT CLONE pool"
            break
          } else {
            if ($pscmdlet.ShouldProcess($poolList.$item)) {
              $desktop_helper.Desktop_CancelScheduledPushImage($services,$item)
            }
            Write-Host "Performed cancel_push_image task on Pool: " $PoolList.$item
          }
        }
      }
    }
  }
}

function Get-Machine ($Pool,$MachineList) {
  [VMware.Hv.MachineId[]]$machines = @()
  $remainingCount = 1 # run through loop at least once
  $query = New-Object VMware.Hv.QueryDefinition
  $query.queryEntityType = 'MachineSummaryView'
  $poolFilter = New-Object VMware.Hv.QueryFilterEquals -Property @{ 'MemberName' = 'base.desktop'; 'value' = $pool }
  if ($machineList) {
    $machineFilters = [vmware.hv.queryFilter[]]@()
    foreach ($name in $machineList) {
      $machineFilters += (New-Object VMware.Hv.QueryFilterEquals -Property @{ 'memberName' = 'base.name'; 'value' = $name })
    }
    $machineList = New-Object VMware.Hv.QueryFilterOr -Property @{ 'filters' = $machineFilters }
    $treeList = @()
    $treeList += $machineList
    $treelist += $poolFilter
    $query.Filter = New-Object VMware.Hv.QueryFilterAnd -Property @{ 'filters' = $treeList }
  } else {
    $query.Filter = $poolFilter
  }
  while ($remainingCount -ge 1) {
    $query_service_helper = New-Object VMware.Hv.QueryServiceService
    $queryResults = $query_service_helper.QueryService_Query($services, $query)
    $results = $queryResults.results
    $machines += $results.id
    $query.StartingOffset = $query.StartingOffset + $queryResults.results.Count
    $remainingCount = $queryResults.RemainingCount
  }
  return $machines
}

function Set-HVPoolSpec {
  param(
    [Parameter(Mandatory = $true)]
    [VMware.Hv.VirtualCenterId]$VcID,

    [Parameter(Mandatory = $true)]
    $Spec
  )
  if ($parentVM) {
    $baseimage_helper = New-Object VMware.Hv.BaseImageVmService
    $parentList = $baseimage_helper.BaseImageVm_List($services,$vcID)
    $parentVMObj = $parentList | Where-Object { $_.name -eq $parentVM }
    $spec.ParentVm = $parentVMObj.id
  }
  if ($snapshotVM) {
    $baseimage_snapshot_helper = New-Object VMware.Hv.BaseImageSnapshotService
    $snapshotList = $baseimage_snapshot_helper.BaseImageSnapshot_List($services,$spec.ParentVm)
    $snapshotVMObj = $snapshotList | Where-Object { $_.name -eq $snapshotVM }
    $spec.Snapshot = $snapshotVMObj.id
  }
  return $spec
}

function Get-HVTaskSpec {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [string]$PoolName,

    [Parameter(Mandatory = $true)]
    [string]$Operation,

    [Parameter(Mandatory = $true)]
    [string]$TaskSpecName,

    [Parameter(Mandatory = $true)]
    $DesktopId

  )
  if ($source -ne 'VIEW_COMPOSER') {
    Write-Error "$operation task is not supported for pool type: [$source]"
    return $null
  }
  $machineList = Get-Machine $desktopId $machines
  if ($machineList.Length -eq 0) {
    Write-Error "Failed to get any Virtual Center machines with the given pool name: [$poolName]"
    return $null
  }
  $spec = Get-HVObject -TypeName $taskSpecName
  $spec.LogoffSetting = $logoffSetting
  $spec.StopOnFirstError = $stopOnFirstError
  $spec.Machines = $machineList
  if ($startTime) { $spec.startTime = $startTime }
  return $spec
}

function Find-HVMachine {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    $Param
  )

  $params = $Param

  try {
    if ($params['PoolName']) {
      $poolObj = Get-HVPoolSummary -poolName $params['PoolName'] -hvServer $params['HvServer']
      if ($poolObj.Length -ne 1) {
        Write-Host "Failed to retrieve specific pool object with given PoolName : " $params['PoolName']
        break;
      } else {
        $desktopId = $poolObj.Id
      }
    }
  } catch {
    Write-Error "Make sure Get-HVPoolSummary advanced function is loaded, $_"
    break
  }
  #
  # This translates the function arguments into the View API properties that must be queried
  $machineSelectors = @{
    'PoolName' = 'base.desktop';
    'MachineName' = 'base.name';
    'DnsName' = 'base.dnsName';
    'State' = 'base.basicState';
  }


  $query_service_helper = New-Object VMware.Hv.QueryServiceService
  $query = New-Object VMware.Hv.QueryDefinition

  $wildCard = $false
  #Only supports wild card '*'
  if ($params['MachineName'] -and $params['MachineName'].contains('*')) {
    $wildcard = $true
  }
  if ($params['DnsName'] -and $params['DnsName'].contains('*')) {
    $wildcard = $true
  }
  # build the query values, MachineNamesView is having more info than
  # MachineSummaryView
  $query.queryEntityType = 'MachineNamesView'
  if (! $wildcard) {
    [VMware.Hv.queryfilter[]]$filterSet = @()
    foreach ($setting in $machineSelectors.Keys) {
      if ($null -ne $params[$setting]) {
        $equalsFilter = New-Object VMware.Hv.QueryFilterEquals
        $equalsFilter.memberName = $machineSelectors[$setting]
        if ($equalsFilter.memberName -eq 'base.desktop') {
            $equalsFilter.value = $desktopId
        } else {
            $equalsFilter.value = $params[$setting]
        }
        $filterSet += $equalsFilter
      }
    }
    if ($filterSet.Count -gt 0) {
      $andFilter = New-Object VMware.Hv.QueryFilterAnd
      $andFilter.Filters = $filterset
      $query.Filter = $andFilter
    }
    $queryResults = $query_service_helper.QueryService_Query($services,$query)
    $machineList = $queryResults.results
  }
  if ($wildcard -or [string]::IsNullOrEmpty($machineList)) {
    $query.Filter = $null
    $queryResults = $query_service_helper.QueryService_Query($services,$query)
    $strFilterSet = @()
    foreach ($setting in $machineSelectors.Keys) {
      if ($null -ne $params[$setting]) {
        if ($wildcard -and (($setting -eq 'MachineName') -or ($setting -eq 'DnsName')) ) {
          $strFilterSet += '($_.' + $machineSelectors[$setting] + ' -like "' + $params[$setting] + '")'
        } else {
          $strFilterSet += '($_.' + $machineSelectors[$setting] + ' -eq "' + $params[$setting] + '")'
        }
      }
    }
    $whereClause =  [string]::Join(' -and ', $strFilterSet)
    $scriptBlock = [Scriptblock]::Create($whereClause)
    $machineList = $queryResults.results | where $scriptBlock
  }
  return $machineList
}


function Get-HVMachine {
<#
.Synopsis
   Gets virtual Machine(s) information with given search parameters.

.DESCRIPTION
   Queries and returns virtual machines information, the machines list would be determined
   based on queryable fields poolName, dnsName, machineName, state. When more than one
   fields are used for query the virtual machines which satisfy all fields criteria would be returned.

.PARAMETER PoolName
   Pool name to query for.
   If the value is null or not provided then filter will not be applied,
   otherwise the virtual machines which has name same as value will be returned.

.PARAMETER MachineName
   The name of the Machine to query for.
   If the value is null or not provided then filter will not be applied,
   otherwise the virtual machines which has display name same as value will be returned.

.PARAMETER DnsName
   DNS name for the Machine to filter with.
   If the value is null or not provided then filter will not be applied,
   otherwise the virtual machines which has display name same as value will be returned.

.PARAMETER State
   The basic state of the Machine to filter with.
   If the value is null or not provided then filter will not be applied,
   otherwise the virtual machines which has display name same as value will be returned.

.PARAMETER HvServer
    Reference to Horizon View Server to query the virtual machines from. If the value is not passed or null then
    first element from global:DefaultHVServers would be considered inplace of hvServer

.EXAMPLE
   Queries VM(s) with given parameter poolName
   Get-HVDesktop -PoolName 'ManualPool'

.EXAMPLE
   Queries VM(s) with given parameter machineName
   Get-HVDesktop -MachineName 'PowerCLIVM'

.EXAMPLE
   Queries VM(s) with given parameter vm state
   Get-HVDesktop -State CUSTOMIZING

.EXAMPLE
   Queries VM(s) with given parameter dnsName with wildcard character *
   Get-HVDesktop -DnsName 'powercli-*'

.OUTPUTS
  Returns list of objects of type MachineInfo

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.1

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2, 7.0.3
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]

  param(
    [Parameter(Mandatory = $false)]
    [string]
    $PoolName,

    [Parameter(Mandatory = $false)]
    [string]
    $MachineName,

    [Parameter(Mandatory = $false)]
    [string]
    $DnsName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('PROVISIONING','PROVISIONING_ERROR','WAIT_FOR_AGENT','CUSTOMIZING',
    'DELETING','MAINTENANCE','ERROR','PROVISIONED','AGENT_UNREACHABLE','UNASSIGNED_USER_CONNECTED',
    'CONNECTED','UNASSIGNED_USER_DISCONNECTED','DISCONNECTED','AGENT_ERR_STARTUP_IN_PROGRESS',
    'AGENT_ERR_DISABLED','AGENT_ERR_INVALID_IP','AGENT_ERR_NEED_REBOOT','AGENT_ERR_PROTOCOL_FAILURE',
    'AGENT_ERR_DOMAIN_FAILURE','AGENT_CONFIG_ERROR','ALREADY_USED','AVAILABLE','IN_PROGRESS','DISABLED',
    'DISABLE_IN_PROGRESS','VALIDATING','UNKNOWN')]
    [string]
    $State,

    [Parameter(Mandatory = $false)]
    [string]
    $JsonFilePath,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  $services = Get-ViewAPIService -hvServer $hvServer
  if ($null -eq $services) {
    Write-Error "Could not retrieve ViewApi services from connection object"
    break
  }

  $machineList = Find-HVMachine -Param $PSBoundParameters
  if (!$machineList) {
    Write-Host "No Virtual Machine(s) Found with given search parameters"
    break
  }
  $queryResults = @()
  $desktop_helper = New-Object VMware.Hv.MachineService
  foreach ($id in $machineList.id) {
    $info = $desktop_helper.Machine_Get($services,$id)
    $queryResults += $info
  }
  $machineList = $queryResults
  return $machineList
}

function Get-HVMachineSummary {
<#
.Synopsis
   Gets virtual Machine(s) summary with given search parameters.

.DESCRIPTION
   Queries and returns virtual machines information, the machines list would be determined
   based on queryable fields poolName, dnsName, machineName, state. When more than one
   fields are used for query the virtual machines which satisfy all fields criteria would be returned.

.PARAMETER PoolName
   Pool name to query for.
   If the value is null or not provided then filter will not be applied,
   otherwise the virtual machines which has name same as value will be returned.

.PARAMETER MachineName
   The name of the Machine to query for.
   If the value is null or not provided then filter will not be applied,
   otherwise the virtual machines which has display name same as value will be returned.

.PARAMETER DnsName
   DNS name for the Machine to filter with.
   If the value is null or not provided then filter will not be applied,
   otherwise the virtual machines which has display name same as value will be returned.

.PARAMETER State
   The basic state of the Machine to filter with.
   If the value is null or not provided then filter will not be applied,
   otherwise the virtual machines which has display name same as value will be returned.

.PARAMETER HvServer
    Reference to Horizon View Server to query the virtual machines from. If the value is not passed or null then
    first element from global:DefaultHVServers would be considered inplace of hvServer

.EXAMPLE
   Queries VM(s) with given parameter poolName
   Get-HVDesktopSummary -PoolName 'ManualPool'

.EXAMPLE
   Queries VM(s) with given parameter machineName
   Get-HVDesktopSummary -MachineName 'PowerCLIVM'

.EXAMPLE
   Queries VM(s) with given parameter vm state
   Get-HVDesktopSummary -State CUSTOMIZING

.EXAMPLE
   Queries VM(s) with given parameter dnsName with wildcard character *
   Get-HVDesktopSummary -DnsName 'powercli-*'

.OUTPUTS
  Returns list of objects of type MachineNamesView

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.1

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2, 7.0.3
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>

  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]

  param(
    [Parameter(Mandatory = $false)]
    [string]
    $PoolName,

    [Parameter(Mandatory = $false)]
    [string]
    $MachineName,

    [Parameter(Mandatory = $false)]
    [string]
    $DnsName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('PROVISIONING','PROVISIONING_ERROR','WAIT_FOR_AGENT','CUSTOMIZING',
    'DELETING','MAINTENANCE','ERROR','PROVISIONED','AGENT_UNREACHABLE','UNASSIGNED_USER_CONNECTED',
    'CONNECTED','UNASSIGNED_USER_DISCONNECTED','DISCONNECTED','AGENT_ERR_STARTUP_IN_PROGRESS',
    'AGENT_ERR_DISABLED','AGENT_ERR_INVALID_IP','AGENT_ERR_NEED_REBOOT','AGENT_ERR_PROTOCOL_FAILURE',
    'AGENT_ERR_DOMAIN_FAILURE','AGENT_CONFIG_ERROR','ALREADY_USED','AVAILABLE','IN_PROGRESS','DISABLED',
    'DISABLE_IN_PROGRESS','VALIDATING','UNKNOWN')]
    [string]
    $State,

    [Parameter(Mandatory = $false)]
    [string]
    $JsonFilePath,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )

  $services = Get-ViewAPIService -hvServer $hvServer
  if ($null -eq $services) {
    Write-Error "Could not retrieve ViewApi services from connection object"
    break
  }

  $machineList = Find-HVMachine -Param $PSBoundParameters
  return $machineList
}

function Get-HVPoolSpec {
<#
.Synopsis
   Gets desktop specification

.DESCRIPTION
   Converts DesktopInfo Object to DesktopSpec. Also Converts view API Ids to human readable names

.PARAMETER DesktopInfo
   An object with detailed description of a desktop instance.

.PARAMETER HvServer
    Reference to Horizon View Server to query the virtual machines from. If the value is not passed or null then
    first element from global:DefaultHVServers would be considered inplace of hvServer

.EXAMPLE
   Converts DesktopInfo to DesktopSpec
   Get-HVPoolSpec -DesktopInfo $DesktopInfoObj

.EXAMPLE
   Converts DesktopInfo to DesktopSpec and also dumps json object
   Get-HVPool -PoolName 'LnkClnJson' | Get-HVPoolSpec -FilePath "C:\temp\LnkClnJson.json"

.OUTPUTS
  Returns desktop specification

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.1

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2, 7.0.3
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>
  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]

  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [VMware.HV.DesktopInfo]
    $DesktopInfo,

    [Parameter(Mandatory = $false)]
    [String]
    $FilePath,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )
  
  $DesktopSpec = New-Object VMware.HV.DesktopSpec
  $DesktopPsObj = (($DesktopSpec | ConvertTo-Json -Depth 14) | ConvertFrom-Json)
  $DesktopInfoPsObj = (($DesktopInfo | ConvertTo-Json -Depth 14) | ConvertFrom-Json)
  $DesktopPsObj.Type = $DesktopInfoPsObj.Type
  $DesktopPsObj.DesktopSettings = $DesktopInfoPsObj.DesktopSettings

  $entityId = New-Object VMware.HV.EntityId
  $entityId.Id = $DesktopInfoPsObj.Base.AccessGroup.Id
  $DesktopPsObj.Base = New-Object PsObject -Property @{
    name = $DesktopInfoPsObj.Base.Name;
    displayName = $DesktopInfoPsObj.Base.displayName;
    accessGroup = (Get-HVInternalName -EntityId $entityId);
    description = $DesktopInfoPsObj.Base.description;
  }

  if (! $DesktopInfoPsObj.GlobalEntitlementData.GlobalEntitlement) {
    $DesktopPsObj.GlobalEntitlementData = $null
  } else {
    $entityId.Id = $DesktopInfoPsObj.GlobalEntitlementData.GlobalEntitlement.Id
    $DesktopPsObj.GlobalEntitlementData = Get-HVInternalName -EntityId $entityId
  }

  Switch ($DesktopInfo.Type) {
    "AUTOMATED" {
      $specificNamingSpecObj = $null
      if ("SPECIFIED" -eq $DesktopInfoPsObj.AutomatedDesktopData.vmNamingSettings.NamingMethod) {
        $specificNamingSpecObj =  New-Object PsObject -Property @{
          specifiedNames = $null;
          startMachinesInMaintenanceMode = $DesktopInfoPsObj.AutomatedDesktopData.vmNamingSettings.SpecificNamingSettings.StartMachinesInMaintenanceMode;
          numUnassignedMachinesKeptPoweredOn = $DesktopInfoPsObj.AutomatedDesktopData.vmNamingSettings.SpecificNamingSettings.NumUnassignedMachinesKeptPoweredOn;
        }
      }
      $vmNamingSpecObj = New-Object PsObject -Property @{
        namingMethod = $DesktopInfoPsObj.AutomatedDesktopData.vmNamingSettings.NamingMethod;
        patternNamingSettings = $DesktopInfoPsObj.AutomatedDesktopData.VmNamingSettings.PatternNamingSettings;
        specificNamingSpec = $specificNamingSpecObj;
      }
      $virtualCenterProvisioningDataObj = New-Object PsObject @{
        template = $null;
        parentVm = $null;
        snapshot = $null;
        datacenter = $null;
        vmFolder = $null;
        hostOrCluster = $null;
        resourcePool= $null;
      }
      $ProvisioningSettingsObj = $DesktopInfoPsObj.AutomatedDesktopData.VirtualCenterProvisioningSettings
      if ($ProvisioningSettingsObj.VirtualCenterProvisioningData.Datacenter){
        $entityId.Id = $ProvisioningSettingsObj.VirtualCenterProvisioningData.Datacenter.Id
        $virtualCenterProvisioningDataObj.Datacenter  = Get-HVInternalName -EntityId $entityId
      }
      if ($ProvisioningSettingsObj.VirtualCenterProvisioningData.HostOrCluster){
        $entityId.Id = $ProvisioningSettingsObj.VirtualCenterProvisioningData.HostOrCluster.Id
        $virtualCenterProvisioningDataObj.HostOrCluster  = Get-HVInternalName -EntityId $entityId
      }
      if ($ProvisioningSettingsObj.VirtualCenterProvisioningData.ResourcePool){
        $entityId.Id = $ProvisioningSettingsObj.VirtualCenterProvisioningData.ResourcePool.Id
        $virtualCenterProvisioningDataObj.ResourcePool  = Get-HVInternalName -EntityId $entityId
      }
      if ($ProvisioningSettingsObj.VirtualCenterProvisioningData.ParentVm){
        $entityId.Id = $ProvisioningSettingsObj.VirtualCenterProvisioningData.ParentVm.Id
        $virtualCenterProvisioningDataObj.ParentVm  = Get-HVInternalName -EntityId $entityId `
          -VcId $DesktopInfo.AutomatedDesktopData.virtualCenter
      }
      if ($ProvisioningSettingsObj.VirtualCenterProvisioningData.Snapshot){
        $entityId.Id = $ProvisioningSettingsObj.VirtualCenterProvisioningData.Snapshot.Id
        $virtualCenterProvisioningDataObj.Snapshot  = Get-HVInternalName -EntityId $entityId `
        -BaseImageVmId $DesktopInfo.AutomatedDesktopData.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.ParentVm
      }
      if ($ProvisioningSettingsObj.VirtualCenterProvisioningData.Template){
        $entityId.Id = $ProvisioningSettingsObj.VirtualCenterProvisioningData.Template.Id
        $virtualCenterProvisioningDataObj.Template  = Get-HVInternalName -EntityId $entityId
      }
      if ($ProvisioningSettingsObj.VirtualCenterProvisioningData.VmFolder){
        $entityId.Id = $ProvisioningSettingsObj.VirtualCenterProvisioningData.VmFolder.Id
        $virtualCenterProvisioningDataObj.VmFolder  = Get-HVInternalName -EntityId $entityId
      }
      
      $DesktopInfoPsObj.AutomatedDesktopData.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData = `
        $virtualCenterProvisioningDataObj
      $datastores = $DesktopInfoPsObj.AutomatedDesktopData.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.datastores
      $dataStoresObj = Get-DataStoreName -datastores $datastores
      $DesktopInfoPsObj.AutomatedDesktopData.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.datastores = `
        $dataStoresObj
      $virtualCenterStorageSettingsObj = `
        $DesktopInfoPsObj.AutomatedDesktopData.VirtualCenterProvisioningSettings.virtualCenterStorageSettings
      if($virtualCenterStorageSettingsObj.replicaDiskDatastore) {
        $entityId.Id = $virtualCenterStorageSettingsObj.replicaDiskDatastore.Id
        $DesktopInfoPsObj.AutomatedDesktopData.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.replicaDiskDatastore =`
          Get-HVInternalName -EntityId $entityId
      }
      if($virtualCenterStorageSettingsObj.persistentDiskSettings) {
        $datastores = $virtualCenterStorageSettingsObj.persistentDiskSettings.persistentDiskDatastores
        $dataStoresObj = Get-DataStoreName -datastores $datastores
        $DesktopInfoPsObj.AutomatedDesktopData.VirtualCenterProvisioningSettings.virtualCenterStorageSettings.persistentDiskSettings.persistentDiskDatastores = `
          $dataStoresObj
      }
      if ($DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.domainAdministrator) {
        $entityId.Id = $DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.domainAdministrator.Id
        $DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.domainAdministrator = Get-HVInternalName -EntityId $entityId
      }
      if ($DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.adContainer) {
        $entityId.Id = $DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.adContainer.Id
        $DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.adContainer = Get-HVInternalName -EntityId $entityId
      }
      if ($DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.sysprepCustomizationSettings) {
        $entityId.Id = `
          $DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.sysprepCustomizationSettings.customizationSpec.Id
        $DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.sysprepCustomizationSettings.customizationSpec = `
          Get-HVInternalName -EntityId $entityId 
      }
      if ($DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.cloneprepCustomizationSettings) {
        $entityId.Id = `
          $DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.cloneprepCustomizationSettings.instantCloneEngineDomainAdministrator.Id
        $DesktopInfoPsObj.AutomatedDesktopData.customizationSettings.cloneprepCustomizationSettings.instantCloneEngineDomainAdministrator = `
          Get-HVInternalName -EntityId $entityId 
      }

      $DesktopPsObj.AutomatedDesktopSpec = New-Object PsObject  -Property @{
        provisioningType = $DesktopInfoPsObj.AutomatedDesktopData.ProvisioningType;
        virtualCenter = $null;
        userAssignment = $DesktopInfoPsObj.AutomatedDesktopData.UserAssignment;
        virtualCenterProvisioningSettings = $DesktopInfoPsObj.AutomatedDesktopData.VirtualCenterProvisioningSettings;
        virtualCenterManagedCommonSettings = $DesktopInfoPsObj.AutomatedDesktopData.virtualCenterManagedCommonSettings;
        customizationSettings = $DesktopInfoPsObj.AutomatedDesktopData.customizationSettings;
        vmNamingSpec = $VmNamingSpecObj;
      }
      if ($DesktopInfoPsObj.AutomatedDesktopData.virtualCenter) {
        $entityId.Id = $DesktopInfoPsObj.AutomatedDesktopData.virtualCenter.Id
        $DesktopPsObj.AutomatedDesktopSpec.virtualCenter = Get-HVInternalName `
          -EntityId $entityId
      }
      break
    }
    "MANUAL" {
      $DesktopPsObj.ManualDesktopSpec = New-Object PsObject -Property @{
        userAssignment = $DesktopInfoPsObj.ManualDesktopData.UserAssignment;
        source = $DesktopInfoPsObj.ManualDesktopData.Source;
        virtualCenter = $null;
        machines = $null;
        viewStorageAcceleratorSettings = $DesktopInfoPsObj.ManualDesktopData.ViewStorageAcceleratorSettings;
        virtualCenterManagedCommonSettings = $DesktopInfoPsObj.ManualDesktopData.VirtualCenterManagedCommonSettings;
      }
      if ($DesktopInfoPsObj.ManualDesktopData.virtualCenter) {
        $entityId.Id = $DesktopInfoPsObj.ManualDesktopData.virtualCenter.Id
        $DesktopPsObj.ManualDesktopSpec.virtualCenter = Get-HVInternalName `
          -EntityId $entityId
      }
      break 
    }
    "RDS" {
      $DesktopPsObj.rdsDesktopSpec =  New-Object PsObject -Property @{
        farm = $null;
      }
      break
    }
  }
  $DesktopSpecJson = ($DesktopPsObj | ConvertTo-Json -Depth 14)
  if ($filePath) {
    $DesktopSpecJson |  Out-File -FilePath $filePath
  }
  return $DesktopSpecJson
}

function Get-DataStoreName {
  param(
    [Parameter(Mandatory = $true)]
    $datastores
  )
  $dataStoresObj = @()
  $entityId = New-Object VMware.Hv.EntityId
  $datastores | % {
    $entityId.Id = $_.datastore.Id
    $dataStoresObj += , (New-Object PsObject -Property @{
        datastore = Get-HVInternalName -EntityId $entityId;
        storageOvercommit = $_.storageOvercommit;
    })
  }
  return $dataStoresObj
}

function Get-HVInternalName {
<#
.Synopsis
   Gets human readable name

.DESCRIPTION
   Converts Horizon API Ids to human readable names. Horizon API Ids are base64 encoded, this function
   will decode and returns internal/human readable names.

.PARAMETER EntityId
   Representation of a manageable entity id.

.PARAMETER HvServer
    Reference to Horizon View Server to query the virtual machines from. If the value is not passed or null then
    first element from global:DefaultHVServers would be considered inplace of hvServer

.EXAMPLE
   Decodes Horizon API Id and returns human readable name
   Get-HVInternalName -EntityId $entityId

.OUTPUTS
  Returns human readable name

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.1

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2, 7.0.3
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>
  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [VMware.HV.EntityId]
    $EntityId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [VMware.HV.VirtualCenterId]
    $VcId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [VMware.HV.BaseImageVmId]
    $BaseImageVmId,

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )
  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }
  process {
    $tokens = ($EntityId.id -split "/")
    $serviceName = $tokens[0]
    Switch ($serviceName) {
      'VirtualCenter' {
         $vc_id = New-Object VMware.HV.VirtualCenterId
         $vc_id.Id = $EntityId.Id
         return ($services.VirtualCenter.VirtualCenter_Get($vc_id)).serverSpec.serverName
       }
       'InstantCloneEngineDomainAdministrator' {
         $Icid = New-Object VMware.HV.InstantCloneEngineDomainAdministratorId
         $Icid.Id = $EntityId.Id
         $Info = $services.InstantCloneEngineDomainAdministrator.InstantCloneEngineDomainAdministrator_Get($Icid)
         return $Info.Base.Username
       }
       'BaseImageVm' {
         $info = $services.BaseImageVm.BaseImageVm_List($VcId) | where { $_.id.id -eq  $EntityId.id }
         return $info.name
       }
       'BaseImageSnapshot' {
         $info = $services.BaseImageSnapshot.BaseImageSnapshot_List($BaseImageVmId) | where { $_.id.id -eq  $EntityId.id }
         return $info.name
       }
       'VmTemplate' {
         $info = $services.VmTemplate.VmTemplate_List($VcId) | where { $_.id.id -eq  $EntityId.id }
         return $info.name
       }
       'ViewComposerDomainAdministrator' {
         $AdministratorId = New-Object VMware.HV.ViewComposerDomainAdministratorId
         $AdministratorId.id = $EntityId.id
         $info = $services.ViewComposerDomainAdministrator.ViewComposerDomainAdministrator_Get($AdministratorId)
         return $info.base.userName
       }
       default {
         $base64String  = $tokens[$tokens.Length-1]
         $mod = $base64String.Length % 4
         if ($mod -ne 0) {
           #Length of a string must be multiples of 4
           $base64String = $base64String.PadRight(($base64String.Length + (4 - $mod)), "=")
         }
         #Convert 4 bytes to 3 bytes base64 decoding
         return ([System.Text.Encoding]::ASCII.GetString([System.Convert]:: `
           FromBase64String($base64String)))
       }
    }
  }
  end {
    [System.gc]::collect()
  }
}


function Get-UserInfo {
  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^.+?[@\\].+?$")]
    [String]
    $UserName
  )

  if ($UserName -match '^.+?[@].+?$') {
    $info = $UserName -split "@"
    $Domain = $info[1]
    $Name = $Info[0]
  } else {
    $info = $UserName -split "\\"
    $Domain = $info[0]
    $Name = $Info[1]
  }
  return @{'Name' = $Name; 'Domain' = $Domain}
}

function New-HVEntitlement {
<#
.Synopsis
   Associates a user/group with a resource

.DESCRIPTION
   This represents a simple association between a single user/group and a resource that they can be assigned.

.PARAMETER User
   User prinicipal name of user or group

.PARAMETER ResourceName
   The resource(Application, Pool etc.) name

.PARAMETER Resource
   Object(s) of the resource(Application, Desktop etc) to entitle

.PARAMETER ResourceType
   Type of Resource(Application, Desktop etc)

.PARAMETER Type
   Whether or not this is a group or a user.

.PARAMETER HvServer
   Reference to Horizon View Server. If the value is not passed or null then
   first element from global:DefaultHVServers would be considered inplace of hvServer

.EXAMPLE
   Associate a user/group with a pool 
   New-HVEntitlement  -User 'administrator@adviewdev.eng.vmware.com' -ResourceName 'InsClnPol' -Confirm:$false

.EXAMPLE
   Associate a user/group with a application
   New-HVEntitlement  -User 'adviewdev\administrator' -ResourceName 'Calculator' -ResourceType Application

.EXAMPLE 
   Associate a user/group with a URLRedirection settings
   New-HVEntitlement  -User 'adviewdev.eng.vmware.com\administrator' -ResourceName 'UrlSetting1' -ResourceType URLRedirection
     
.EXAMPLE
   Associate a user/group with a desktop entitlement
   New-HVEntitlement  -User 'adviewdev.eng.vmware.com\administrator' -ResourceName 'GE1' -ResourceType GlobalEntitlement

.EXAMPLE
   Associate a user/group with a application entitlement
   New-HVEntitlement  -User 'adviewdev\administrator' -ResourceName 'GEAPP1' -ResourceType GlobalApplicationEntitlement

.EXAMPLE
   Associate a user/group with list of pools
   $pools = Get-HVPool; $pools | New-HVEntitlement  -User 'adviewdev\administrator' -Confirm:$false
      

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.1

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2, 7.0.3
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>
  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^.+?[@\\].+?$")]
    [String]
    $User,

    [Parameter(Mandatory = $true,ParameterSetName ='Default')]
    [ValidateNotNullOrEmpty()]
    [String]
    $ResourceName,

    [Parameter(Mandatory = $true,ValueFromPipeline = $true,ParameterSetName ='PipeLine')]
    $Resource,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Application','Desktop','GlobalApplicationEntitlement','GlobalEntitlement',
    'URLRedirection')]
    [String]
    $ResourceType = 'Desktop',

    [Parameter(Mandatory = $false)]
    [ValidateSet('User','Group')]
    [String]
    $Type = 'User',

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )
  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }
  process {
    $userInfo = Get-UserInfo -UserName $User
    $UserOrGroupName = $userInfo.Name
    $Domain = $userInfo.Domain
    $IsGroup = ($Type -eq 'Group')
    $filter1 = Get-HVQueryFilter 'base.name' -Eq $UserOrGroupName
    $filter2 = Get-HVQueryFilter 'base.domain' -Eq $Domain
    $filter3 = Get-HVQueryFilter 'base.group' -Eq $IsGroup
    $andFilter = Get-HVQueryFilter -And -Filters @($filter1, $filter2, $filter3)
    $results = Get-HVQueryResult -EntityType ADUserOrGroupSummaryView -Filter $andFilter -HvServer $HvServer
    if ($results.length -ne 1) {
      Write-Host "Unable to find specific user or group with given search parameters"
      return
    }
    $ResourceObjs = $null
    $info = $services.PodFederation.PodFederation_get()
    switch($ResourceType){
      "Desktop" {
        if ($ResourceName) {
          $ResourceObjs = Get-HVPool -PoolName $ResourceName
          if (! $ResourceObjs) {
            Write-Host "No pool found with given resourceName: " $ResourceName
            return
          }
        } elseif ($PSCmdlet.MyInvocation.ExpectingInput -or $Resource) {
          foreach ($item in $Resource) {
            if ($item.GetType().name -eq 'DesktopInfo') {
              $ResourceObjs += ,$item
            }
            elseif ($item.GetType().name -eq 'DesktopSummaryView') {
              $ResourceObjs += ,$item
            }
            else {
              Write-Error "In pipeline didn't received object(s) of expected type DesktopSummaryView/DesktopInfo"
              return
            }
          }
        }
      }
      "Application" {
        if ($ResourceName) {
          $eqFilter = Get-HVQueryFilter 'data.name' -Eq $ResourceName
          $ResourceObjs = Get-HVQueryResult -EntityType ApplicationInfo -Filter $eqFilter -HvServer $HvServer
          if (! $ResourceObjs) {
            Write-Host "No Application found with given resourceName: " $ResourceName
            return
          }
        } elseif ($PSCmdlet.MyInvocation.ExpectingInput -or $Resource) {
          foreach ($item in $Resource) {
            if ($item.GetType().name -eq 'ApplicationInfo') {
              $ResourceObjs += ,$item
            
            } else {
              Write-Error "In pipeline didn't received object(s) of expected type ApplicationInfo"
              return
            }
          }
        }
      }
      "URLRedirection" {
        if ($ResourceName) {
          $UrlRedirectionList = $services.URLRedirection.URLRedirection_List()
          $ResourceObjs = $UrlRedirectionList | Where-Object { $_.urlRedirectionData.displayName -like $ResourceName}
          if (! $ResourceObjs) {
            Write-Host "No URLRedirectionData found with given resourceName: " $ResourceName
            return
          }
        } elseif ($PSCmdlet.MyInvocation.ExpectingInput -or $Resource) {
          foreach ($item in $Resource) {
            if ($item.GetType().name -eq 'URLRedirectionInfo') {
              $ResourceObjs += ,$item
            } else {
              Write-Error "In pipeline didn't received object(s) of expected type URLRedirectionInfo"
              return
            }
          }
        }
      }
      "GlobalApplicationEntitlement" {
        if ("ENABLED" -eq $info.localPodStatus.status) {
          if ($ResourceName) {
            $eqFilter = Get-HVQueryFilter 'base.displayName' -Eq $ResourceName
            $ResourceObjs = Get-HVQueryResult -EntityType GlobalApplicationEntitlementInfo -Filter $eqFilter -HvServer $HvServer
            if (! $ResourceObjs) {
              Write-Host "No globalApplicationEntitlementInfo found with given resourceName: " $ResourceName
              return
            } elseif ($PSCmdlet.MyInvocation.ExpectingInput -or $Resource) {
              foreach ($item in $Resource) {
                if ($item.GetType().name -eq 'GlobalApplicationEntitlementInfo') {
                  $ResourceObjs += ,$item
                } else {
                  Write-Error "In pipeline didn't received object(s) of expected type globalApplicationEntitlementInfo"
                  return
                }
              }
            }
          }
        } else {
          Write-Host "Multi-DataCenter-View/CPA is not enabled"
          return
        }
      }
      "GlobalEntitlement" {
        if ("ENABLED" -eq $info.localPodStatus.status) {
          if ($ResourceName) {
            $eqFilter = Get-HVQueryFilter 'base.displayName' -Eq $ResourceName
            $ResourceObjs = Get-HVQueryResult -EntityType GlobalEntitlementSummaryView -Filter $eqFilter -HvServer $HvServer
            if (! $ResourceObjs) {
              Write-Host "No globalEntitlementSummary found with given resourceName: " $ResourceName
              return
            } elseif ($PSCmdlet.MyInvocation.ExpectingInput -or $Resource) {
              foreach ($item in $Resource) {
                if ($item.GetType().name -eq 'GlobalEntitlementSummaryView') {
                  $ResourceObjs += ,$item
                } else {
                  Write-Error "In pipeline didn't received object(s) of expected type GlobalEntitlementSummaryView"
                  return
                }
              }
            }
          }
        } else {
          Write-Host "Multi-DataCenter-View/CPA is not enabled"
          return
        }
      }
    }
    $base = New-Object VMware.HV.UserEntitlementBase
    $base.UserOrGroup = $results.id
    foreach ($ResourceObj in $ResourceObjs) {
      $base.Resource = $ResourceObj.id
      if ($pscmdlet.ShouldProcess($User)) {
        $id = $services.UserEntitlement.UserEntitlement_Create($base)
      }
    }
    Write-host $ResourceObjs.Length " resource(s) entitled with User or group: " $User
  }
  end {
    [System.gc]::collect()
  }
}


function Get-HVEntitlement {
<#
.Synopsis
   Gets association data between a user/group and a resource

.DESCRIPTION
   Provides entitlement Info between a single user/group and a resource that they can be assigned.

.PARAMETER User
   User prinicipal name of user or group

.PARAMETER ResourceName
   The resource(Application, Pool etc.) name

.PARAMETER Resource
   Object(s) of the resource(Application, Desktop etc) to entitle

.PARAMETER ResourceType
   Type of Resource(Application, Desktop etc)

.PARAMETER Type
   Whether or not this is a group or a user.

.PARAMETER HvServer
   Reference to Horizon View Server. If the value is not passed or null then
   first element from global:DefaultHVServers would be considered inplace of hvServer

.EXAMPLE
   Gets all the entitlements related to application pool 
   Get-HVEntitlement -ResourceType Application

.EXAMPLE
   Gets entitlements specific to user or group name and application resource
   Get-HVEntitlement -User 'adviewdev.eng.vmware.com\administrator' -ResourceName 'calculator' -ResourceType Application

.EXAMPLE 
   Gets entitlements specific to user or group and URLRedirection resource
   Get-HVEntitlement -User 'adviewdev.eng.vmware.com\administrator' -ResourceName 'UrlSetting1' -ResourceType URLRedirection
     
.EXAMPLE
   Gets entitlements specific to user or group and GlobalEntitlement resource
   Get-HVEntitlement -User 'administrator@adviewdev.eng.vmware.com' -ResourceName 'GE1' -ResourceType GlobalEntitlement

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.1

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2, 7.0.3
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>


   [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(
    [Parameter(Mandatory = $false)]
    [ValidatePattern("^.+?[@\\].+?$")]
    [String]
    $User,

    [Parameter(Mandatory = $false)]
    [ValidateSet('User','Group')]
    [String]
    $Type = 'User',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ResourceName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Application','Desktop','GlobalApplicationEntitlement','GlobalEntitlement',
    'URLRedirection')]
    [String]
    $ResourceType = 'Desktop',

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )
  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }
  process {
    $AndFilter = @()
    $results = @()
    $ResourceObjs = $null
    if ($User) {
      $userInfo = Get-UserInfo -UserName $User
      $UserOrGroupName = $userInfo.Name
      $Domain = $userInfo.Domain
      $nameFilter = Get-HVQueryFilter 'base.name' -Eq $UserOrGroupName
      $AndFilter += $nameFilter
      $doaminFilter = Get-HVQueryFilter 'base.domain' -Eq $Domain
      $AndFilter += $doaminFilter
    }
    $IsGroup = ($Type -eq 'Group')
    $groupFilter = Get-HVQueryFilter 'base.group' -Eq $IsGroup
    $AndFilter += $groupFilter
    $info = $services.PodFederation.PodFederation_get()
    $cpaEnabled = ("ENABLED" -eq $info.localPodStatus.status)
    switch($ResourceType) {
      "Desktop" {
        if ($ResourceName) {
          $ResourceObjs = Get-HVPool -PoolName $ResourceName -HvServer $HvServer
          if (! $ResourceObjs) {
            Write-Host "No pool found with given resourceName: " $ResourceName
            return
          }
          $AndFilter += Get-HVQueryFilter 'localData.desktops' -Contains ([VMware.Hv.DesktopId[]]$ResourceObjs.Id)
        }
        $AndFilter = Get-HVQueryFilter -And -Filters $AndFilter
        $results = (Get-HVQueryResult -EntityType EntitledUserOrGroupLocalSummaryView -Filter $AndFilter -HvServer $HvServer)
        $results = $results | where {$_.localData.desktops -ne $null}
      }
      "Application" {
        if ($ResourceName) {
          $eqFilter = Get-HVQueryFilter 'data.name' -Eq $ResourceName
          $ResourceObjs = Get-HVQueryResult -EntityType ApplicationInfo -Filter $eqFilter -HvServer $HvServer
          if (! $ResourceObjs) {
            Write-Host "No Application found with given resourceName: " $ResourceName
            return
          }
          $AndFilter += Get-HVQueryFilter 'localData.applications' -Contains ([VMware.Hv.ApplicationId[]]$ResourceObjs.Id)
        }
        $AndFilter = Get-HVQueryFilter -And -Filters $AndFilter
        $results = (Get-HVQueryResult -EntityType EntitledUserOrGroupLocalSummaryView -Filter $AndFilter -HvServer $HvServer)
        $results = $results | where {$_.localData.applications -ne $null}
      }
      "URLRedirection" {
        $localFilter = @()
        $globalFilter = @()
        $localFilter += $AndFilter
        $globalFilter += $AndFilter
        if ($ResourceName) {
          $UrlRedirectionList = $services.URLRedirection.URLRedirection_List()
          $ResourceObjs = $UrlRedirectionList | Where-Object { $_.urlRedirectionData.displayName -like $ResourceName}
          if (! $ResourceObjs) {
            Write-Host "No URLRedirectionData found with given resourceName: " $ResourceName
            return
          }
          $localFilter +=  Get-HVQueryFilter 'localData.urlRedirectionSettings' -Contains ([VMware.Hv.URLRedirectionId[]]$ResourceObjs.Id)
          if ($cpaEnabled) {
            $globalFilter += Get-HVQueryFilter 'globalData.urlRedirectionSettings' -Contains ([VMware.Hv.URLRedirectionId[]]$ResourceObjs.Id)
          }
        }
        $localFilter = Get-HVQueryFilter -And -Filters $localFilter
        $localResults = Get-HVQueryResult -EntityType EntitledUserOrGroupLocalSummaryView -Filter $localFilter -HvServer $HvServer
        $results += ($localResults | where {$_.localData.urlRedirectionSettings -ne $null})
        if ($cpaEnabled) {
          $globalFilter = Get-HVQueryFilter -And -Filters $globalFilter
          $globalResults = Get-HVQueryResult -EntityType EntitledUserOrGroupGlobalSummaryView -Filter $globalFilter -HvServer $HvServer
          $globalResults = $globalResults | where {$_.globalData.urlRedirectionSettings -ne $null}
          $results +=  $globalResults
        }
      }
      "GlobalApplicationEntitlement" {
        if (! $cpaEnabled) {
          Write-Host "Multi-DataCenter-View/CPA is not enabled"
          return
        }
        if ($ResourceName) {
          $eqFilter = Get-HVQueryFilter 'base.displayName' -Eq $ResourceName
          $ResourceObjs = Get-HVQueryResult -EntityType GlobalApplicationEntitlementInfo -Filter $eqFilter -HvServer $HvServer
          if (! $ResourceObjs) {
            Write-Host "No globalApplicationEntitlementInfo found with given resourceName: " $ResourceName
            return
          }
          $AndFilter += Get-HVQueryFilter 'globalData.globalApplicationEntitlements' -Contains ([VMware.Hv.GlobalApplicationEntitlementId[]]$ResourceObjs.Id)
        }
        $AndFilter = Get-HVQueryFilter -And -Filters $AndFilter
        $results = (Get-HVQueryResult -EntityType EntitledUserOrGroupGlobalSummaryView -Filter $AndFilter -HvServer $HvServer)
        $results = $results| where {$_.globalData.globalApplicationEntitlements -ne $null}
      }
      "GlobalEntitlement" {
        if (! $cpaEnabled) {
          Write-Host "Multi-DataCenter-View/CPA is not enabled"
          return
        }
        if ($ResourceName) {
          $eqFilter = Get-HVQueryFilter 'base.displayName' -Eq $ResourceName
          $ResourceObjs = Get-HVQueryResult -EntityType GlobalEntitlementSummaryView -Filter $eqFilter -HvServer $HvServer
          if (! $ResourceObjs) {
            Write-Host "No globalEntitlementSummary found with given resourceName: " $ResourceName
            return
          }
          $AndFilter += Get-HVQueryFilter 'globalData.globalEntitlements' -Contains ([VMware.Hv.GlobalEntitlementId[]]$ResourceObjs.Id)
        }
        $AndFilter = Get-HVQueryFilter -And -Filters $AndFilter
        $results = (Get-HVQueryResult -EntityType EntitledUserOrGroupGlobalSummaryView -Filter $AndFilter -HvServer $HvServer) 
        $results = $results | where {$_.globalData.globalEntitlements -ne $null}
      }
    }
    if (! $results) {
      Write-Host "Get-HVEntitlement: No entitlements found with given search parameters"
      break
    }
    return $results
  }
  end {
    [System.gc]::collect()
  }
}

function Remove-HVEntitlement {
<#
.Synopsis
   Deletes association data between a user/group and a resource

.DESCRIPTION
   Removes entitlement between a single user/group and a resource that already been assigned.

.PARAMETER User
   User prinicipal name of user or group

.PARAMETER ResourceName
   The resource(Application, Pool etc.) name

.PARAMETER Resource
   Object(s) of the resource(Application, Desktop etc) to entitle

.PARAMETER ResourceType
   Type of Resource(Application, Desktop etc)

.PARAMETER Type
   Whether or not this is a group or a user.

.PARAMETER HvServer
   Reference to Horizon View Server. If the value is not passed or null then
   first element from global:DefaultHVServers would be considered inplace of hvServer

.EXAMPLE
   Deletes entitlement between a user/group and a pool resource 
   Remove-HVEntitlement -User 'administrator@adviewdev'  -ResourceName LnkClnJSon -Confirm:$false

.EXAMPLE
   Deletes entitlement between a user/group and a Application resource
   Remove-HVEntitlement -User 'adviewdev\puser2' -ResourceName 'calculator' -ResourceType Application

.EXAMPLE 
   Deletes entitlement between a user/group and a GlobalApplicationEntitlement resource
   Remove-HVEntitlement -User 'adviewdev\administrator' -ResourceName 'GEAPP1' -ResourceType GlobalApplicationEntitlement

.NOTES
    Author                      : Praveen Mathamsetty.
    Author email                : pmathamsetty@vmware.com
    Version                     : 1.1

    ===Tested Against Environment====
    Horizon View Server Version : 7.0.2, 7.0.3
    PowerCLI Version            : PowerCLI 6.5
    PowerShell Version          : 5.0
#>


   [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'High'
  )]
  param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^.+?[@\\].+?$")]
    [String]
    $User,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ResourceName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('User','Group')]
    [String]
    $Type = 'User',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Application','Desktop','GlobalApplicationEntitlement','GlobalEntitlement',
    'URLRedirection')]
    [String]
    $ResourceType = 'Desktop',

    [Parameter(Mandatory = $false)]
    $HvServer = $null
  )
  begin {
    $services = Get-ViewAPIService -hvServer $hvServer
    if ($null -eq $services) {
      Write-Error "Could not retrieve ViewApi services from connection object"
      break
    }
  }
  process {
    $AndFilter = @()
    $results = $null
    $userInfo = Get-UserInfo -UserName $User
    $UserOrGroupName = $userInfo.Name
    $Domain = $userInfo.Domain
    $nameFilter = Get-HVQueryFilter 'base.name' -Eq $UserOrGroupName
    $doaminFilter = Get-HVQueryFilter 'base.domain' -Eq $Domain
    $IsGroup = ($Type -eq 'Group')
    $groupFilter = Get-HVQueryFilter 'base.group' -Eq $IsGroup
    [VMware.Hv.UserEntitlementId[]] $userEntitlements = $null
    if ($ResourceName) {
      $info = $services.PodFederation.PodFederation_get()
      switch($ResourceType) {
        "Desktop" {
          $ResourceObjs = Get-HVPool -PoolName $ResourceName -HvServer $HvServer
          if (! $ResourceObjs) {
            Write-Host "No pool found with given resourceName: " $ResourceName
            return
          }
          $AndFilter += Get-HVQueryFilter 'localData.desktops' -Contains ([VMware.HV.DesktopId[]] $ResourceObjs.Id)
          $filters = Get-HVQueryFilter -And -Filters $AndFilter
          $results = Get-HVQueryResult -EntityType EntitledUserOrGroupLocalSummaryView -Filter $filters -HvServer $HvServer
          if ($results) {
            foreach ($result in $Results) {
              $userEntitlements = $result.localData.desktopUserEntitlements
              if ($pscmdlet.ShouldProcess($User)) {
                $services.UserEntitlement.UserEntitlement_DeleteUserEntitlements($userEntitlements)
              }
              Write-Host $userEntitlements.Length " desktopUserEntitlement(s) are removed for UserOrGroup " $user
            }
          }
        }
        "Application" {
          $eqFilter = Get-HVQueryFilter 'data.name' -Eq $ResourceName
          $ResourceObjs = Get-HVQueryResult -EntityType ApplicationInfo -Filter $eqFilter -HvServer $HvServer
          if (! $ResourceObjs) {
            Write-Host "No Application found with given resourceName: " $ResourceName
            return
          }
          $AndFilter += Get-HVQueryFilter 'localData.applications' -Contains ([VMware.HV.ApplicationId[]] $ResourceObjs.Id)
          $AndFilter = Get-HVQueryFilter -And -Filters $AndFilter
          $results = Get-HVQueryResult -EntityType EntitledUserOrGroupLocalSummaryView -Filter $AndFilter -HvServer $HvServer
          if ($results) {
            foreach ($result in $Results) {
              $userEntitlements = $result.localData.applicationUserEntitlements
              if ($pscmdlet.ShouldProcess($User)) {
                $services.UserEntitlement.UserEntitlement_DeleteUserEntitlements($userEntitlements)
              }
              Write-Host $userEntitlements.Length " applicationUserEntitlement(s) are removed for UserOrGroup " $user
            }
          }
        }
        "URLRedirection" {
          $UrlRedirectionList = $services.URLRedirection.URLRedirection_List()
          $ResourceObjs = $UrlRedirectionList | Where-Object { $_.urlRedirectionData.displayName -like $ResourceName}
          if (! $ResourceObjs) {
            Write-Host "No URLRedirectionData found with given resourceName: " $ResourceName
            return
          }
          $localFilter = @()
          $localFilter += $AndFilter
          $localFilter +=  (Get-HVQueryFilter 'localData.urlRedirectionSettings' -Contains ([VMware.HV.URLRedirectionId[]]$ResourceObjs.Id))
          $localFilter = Get-HVQueryFilter -And -Filters $localFilter
          $results = Get-HVQueryResult -EntityType EntitledUserOrGroupLocalSummaryView -Filter $localFilter -HvServer $HvServer
          if ("ENABLED" -eq $info.localPodStatus.status) {
            $globalFilter = @()
            $globalFilter += $AndFilter
            $globalFilter += Get-HVQueryFilter 'globalData.urlRedirectionSettings' -Contains ([VMware.HV.URLRedirectionId[]]$ResourceObjs.Id)
            $globalFilter = Get-HVQueryFilter -And -Filters $globalFilter
            $results += Get-HVQueryResult -EntityType EntitledUserOrGroupGlobalSummaryView -Filter $globalFilter -HvServer $HvServer
          }
          if ($results) {
            foreach ($result in $Results) {
              if ($result.GetType().Name -eq 'EntitledUserOrGroupLocalSummaryView') {
                $userEntitlements = $result.localData.urlRedirectionUserEntitlements
                if ($pscmdlet.ShouldProcess($User)) {
                  $services.UserEntitlement.UserEntitlement_DeleteUserEntitlements($userEntitlements)
                }
              } else {
                $userEntitlements = $result.globalData.urlRedirectionUserEntitlements
                if ($pscmdlet.ShouldProcess($User)) {
                  $services.UserEntitlement.UserEntitlement_DeleteUserEntitlements($userEntitlements)
                }
              }
              Write-Host $userEntitlements.Length " urlRedirectionUserEntitlement(s) are removed for UserOrGroup " $user
            }
          }
        }
        "GlobalApplicationEntitlement" {
          if ("ENABLED" -ne $info.localPodStatus.status) {
            Write-Host "Multi-DataCenter-View/CPA is not enabled"
            return
          }
          $eqFilter = Get-HVQueryFilter 'base.displayName' -Eq $ResourceName
          $ResourceObjs = Get-HVQueryResult -EntityType GlobalApplicationEntitlementInfo -Filter $eqFilter -HvServer $HvServer
          if (! $ResourceObjs) {
              Write-Host "No globalApplicationEntitlementInfo found with given resourceName: " $ResourceName
              return
          }
          $AndFilter += Get-HVQueryFilter 'globalData.globalApplicationEntitlements' -Contains ([VMware.Hv.GlobalApplicationEntitlementId[]]$ResourceObjs.Id)
          $AndFilter = Get-HVQueryFilter -And -Filters $AndFilter
          $results = Get-HVQueryResult -EntityType EntitledUserOrGroupGlobalSummaryView -Filter $AndFilter -HvServer $HvServer
          if ($results) {
            foreach ($result in $Results) {
              $userEntitlements = $result.globalData.globalUserApplicationEntitlements
              if ($pscmdlet.ShouldProcess($User)) {
                $services.UserEntitlement.UserEntitlement_DeleteUserEntitlements($userEntitlements)
              }
              Write-Host $userEntitlements.Length " GlobalApplicationEntitlement(s) are removed for UserOrGroup " $user
            }
          }
        }
        "GlobalEntitlement" {
          if ("ENABLED" -ne $info.localPodStatus.status) {
            Write-Host "Multi-DataCenter-View/CPA is not enabled"
            return
          }
          $eqFilter = Get-HVQueryFilter 'base.displayName' -Eq $ResourceName
          $ResourceObjs = Get-HVQueryResult -EntityType GlobalEntitlementSummaryView -Filter $eqFilter -HvServer $HvServer
          if (! $ResourceObjs) {
              Write-Host "No globalEntitlementSummary found with given resourceName: " $ResourceName
              return
          }
          $AndFilter += Get-HVQueryFilter 'globalData.globalEntitlements' -Contains ([VMware.Hv.GlobalEntitlementId[]]$ResourceObjs.Id)
          $AndFilter = Get-HVQueryFilter -And -Filters $AndFilter
          $results = Get-HVQueryResult -EntityType EntitledUserOrGroupGlobalSummaryView -Filter $AndFilter -HvServer $HvServer
          if ($results) {
            foreach ($result in $Results) {
              $userEntitlements = $result.globalData.globalUserEntitlements
              if ($pscmdlet.ShouldProcess($User)) {
                $services.UserEntitlement.UserEntitlement_DeleteUserEntitlements($userEntitlements)
              }
              Write-Host $userEntitlements.Length " GlobalEntitlement(s) are removed for UserOrGroup " $user
            }
            
          }
        }
      }
    }
    if (! $results) {
      Write-Host "Remove-HVEntitlement: No entitlements found with given search parameters"
      return
    }
  }
  end {
    [System.gc]::collect()
  }
}

Export-ModuleMember Add-HVDesktop,Add-HVRDSServer,Connect-HVEvent,Disconnect-HVEvent,Get-HVPoolSpec,Get-HVInternalName, Get-HVEvent,Get-HVFarm,Get-HVFarmSummary,Get-HVPool,Get-HVPoolSummary,Get-HVMachine,Get-HVMachineSummary,Get-HVQueryResult,Get-HVQueryFilter,New-HVFarm,New-HVPool,Remove-HVFarm,Remove-HVPool,Set-HVFarm,Set-HVPool,Start-HVFarm,Start-HVPool,New-HVEntitlement,Get-HVEntitlement,Remove-HVEntitlement
