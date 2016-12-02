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
    if ($pscmdlet.ShouldProcess($global:DefaultHVServers[0].uid,'hvServer not specified, use default hvServer connection?')) {
      $hvServer = $global:DefaultHVServers[0]
      return $hvServer.ExtensionData
    }
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
    Add-HVDesktop -PoolName 'ManualPool' -Machines 'manualPool1', 'manualPool2'.

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
      Write-Error "Make sure Get-HVPool advanced function is loaded, $_"
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
        $desktop_service_helper.Desktop_AddMachinesToManualDesktop($services,$id,$machineList)
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
    Add-HVRDSServer -Farm "manualFarmTest" -RdsServers "vm-for-rds","vm-for-rds-2"

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
      Write-Error "Make sure Get-HVFarm advanced function is loaded, $_"
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
          $farm_service_helper.Farm_AddRDSServers($services, $id, $serverList)
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
[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient") | Out-Null

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
     Get-HVFarm -FarmName 'Farm-01'

.EXAMPLE
     Get-HVFarm -FarmName 'Farm-01' -FarmDisplayName 'Sales RDS Farm'

.EXAMPLE
     Get-HVFarm -FarmName 'Farm-01' -FarmType 'MANUAL'

.EXAMPLE
     Get-HVFarm -FarmName 'Farm-01' -FarmType 'MANUAL' -Enabled $true

.EXAMPLE
     Get-HVFarm -FarmName 'Farm-01'

.OUTPUTs
    Returns the list of FarmSummaryView or FarmInfo object matching the query criteria.

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
     Get-HVFarm -FarmName 'Farm-01'

.EXAMPLE
     Get-HVFarm -FarmName 'Farm-01' -FarmDisplayName 'Sales RDS Farm'

.EXAMPLE
     Get-HVFarm -FarmName 'Farm-01' -FarmType 'MANUAL'

.EXAMPLE
     Get-HVFarm -FarmName 'Farm-01' -FarmType 'MANUAL' -Enabled $true

.EXAMPLE
     Get-HVFarm -FarmName 'Farm-01'

.OUTPUTs
    Returns the list of FarmSummaryView or FarmInfo object matching the query criteria.

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
  $farmList = Find-HVFarm -Param $PSBoundParameters
  return $farmList
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

  $parms = $Param

  $query_service_helper = New-Object VMware.Hv.QueryServiceService
  $query = New-Object VMware.Hv.QueryDefinition

  # build the query values

  $query.queryEntityType = 'FarmSummaryView'
  [VMware.Hv.queryfilter[]]$filterSet = @()
  foreach ($setting in $farmSelectors.Keys) {
    if ($null -ne $parms[$setting]) {
      $equalsFilter = New-Object VMware.Hv.QueryFilterEquals
      $equalsFilter.memberName = $farmSelectors[$setting]
      $equalsFilter.value = $parms[$setting]
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
   Get-HVPool -PoolName 'mypool' -PoolType MANUAL -UserAssignment FLOATING -Enabled $true -ProvisioningEnabled $true

.EXAMPLE
   Get-HVPool -PoolType AUTOMATED -UserAssignment FLOATING

.EXAMPLE
   Get-HVPool -PoolName 'myrds' -PoolType RDS -UserAssignment DEDICATED -Enabled $false

.EXAMPLE
   Get-HVPool -PoolName 'myrds' -PoolType RDS -UserAssignment DEDICATED -Enabled $false -HvServer $mycs

.OUTPUTS
   Returns list of objects of type Desktop

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
   Get-HVPoolSummary -PoolName 'mypool' -PoolType MANUAL -UserAssignment FLOATING -Enabled $true -ProvisioningEnabled $true

.EXAMPLE
   Get-HVPoolSummary -PoolType AUTOMATED -UserAssignment FLOATING

.EXAMPLE
   Get-HVPoolSummary -PoolName 'myrds' -PoolType RDS -UserAssignment DEDICATED -Enabled $false

.EXAMPLE
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
  $poolList = Find-HVPool -Param $psboundparameters
  Return $poolList
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

  $parms = $Param

  $query_service_helper = New-Object VMware.Hv.QueryServiceService
  $query = New-Object VMware.Hv.QueryDefinition

  $wildCard = $false
  #Only supports wild card '*'
  if ($parms['PoolName'] -and $parms['PoolName'].contains('*')) {
    $wildcard = $true
  }
  if ($parms['PoolDisplayName'] -and $parms['PoolDisplayName'].contains('*')) {
    $wildcard = $true
  }
  # build the query values
  $query.queryEntityType = 'DesktopSummaryView'
  if (! $wildcard) {
    [VMware.Hv.queryfilter[]]$filterSet = @()
    foreach ($setting in $poolSelectors.Keys) {
      if ($null -ne $parms[$setting]) {
        $equalsFilter = New-Object VMware.Hv.QueryFilterEquals
        $equalsFilter.memberName = $poolSelectors[$setting]
        $equalsFilter.value = $parms[$setting]
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
      if ($null -ne $parms[$setting]) {
        if ($wildcard -and (($setting -eq 'PoolName') -or ($setting -eq 'PoolDisplayName')) ) {
          $strFilterSet += '($_.' + $poolSelectors[$setting] + ' -like "' + $parms[$setting] + '")'
        } else {
          $strFilterSet += '($_.' + $poolSelectors[$setting] + ' -eq "' + $parms[$setting] + '")'
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
    Get-HVQueryFilter data.name -Eq vmware

.EXAMPLE
    Get-HVQueryFilter -MemberName data.name -Eq -MemberValue vmware

.EXAMPLE
    Get-HVQueryFilter data.name -Ne vmware

.EXAMPLE
    Get-HVQueryFilter data.name -Contains vmware

.EXAMPLE
    Get-HVQueryFilter data.name -Startswith vmware

.EXAMPLE
    $filter = Get-HVQueryFilter data.name -Startswith vmware
    Get-HVQueryFilter -Not $filter

.EXAMPLE
    $filter1 = Get-HVQueryFilter data.name -Startswith vmware
    $filter2 = Get-HVQueryFilter data.name -Contains pool
    Get-HVQueryFilter -And @($filter1, $filter2)

.EXAMPLE
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
    Get-HVQueryResult DesktopSummaryView

.EXAMPLE
    Get-HVQueryResult DesktopSummaryView (Get-HVQueryFilter data.name -Eq vmware)

.EXAMPLE
    Get-HVQueryResult -EntityType DesktopSummaryView -Filter (Get-HVQueryFilter desktopSummaryData.name -Eq vmware)

.EXAMPLE
    Get-HVQueryResult -EntityType DesktopSummaryView -Filter (Get-HVQueryFilter desktopSummaryData.name -Eq vmware) -SortBy desktopSummaryData.displayName

.EXAMPLE
    $myFilter = Get-HVQueryFilter data.name -Contains vmware
    Get-HVQueryResult -EntityType DesktopSummaryView -Filter $myFilter -SortBy desktopSummaryData.displayName -SortDescending $false

.EXAMPLE
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
    Applicable only to Linked Clone farms.

.PARAMETER SnapshotVM
    Base image snapshot for RDS Servers.

.PARAMETER VmFolder
    VM folder to deploy the RDSServers to.
    Applicable to Linked Clone farms.

.PARAMETER HostOrCluster
    Host or cluster to deploy the RDSServers in.
    Applicable to Linked Clone farms.

.PARAMETER ResourcePool
    Resource pool to deploy the RDSServers.
    Applicable to Linked Clone farms.

.PARAMETER Datastores
    Datastore names to store the RDSServer.
    Applicable to Linked Clone farms.

.PARAMETER UseVSAN
    Whether to use vSphere VSAN. This is applicable for vSphere 5.5 or later.
    Applicable to Linked Clone farms.

.PARAMETER EnableProvisioning
    Set to true to enable provision of RDSServers immediately in farm.
    Applicable to Linked Clone farms.

.PARAMETER StopOnProvisioningError
    Set to true to stop provisioning of all RDSServers on error.
    Applicable to Linked Clone farms.

.PARAMETER TransparentPageSharingScope
    The transparent page sharing scope.
    The default value is 'VM'.

.PARAMETER NamingMethod
    Determines how the VMs in the farm are named.
    Set PATTERN to use naming pattern.
    The default value is PATTERN. Curentlly only PATTERN is allowed.

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
    Applicable to Linked Clone farms.

.PARAMETER AdContainer
    This is the Active Directory container which the Servers will be added to upon creation.
    The default value is 'CN=Computers'.
    Applicable to Linked Clone farm.

.PARAMETER NetBiosName
    Domain Net Bios Name.
    Applicable to Linked Clone farms.

.PARAMETER DomainAdmin
    Domain Administrator user name which will be used to join the domain.
    Default value is null.
    Applicable to Linked Clone farms.

.PARAMETER SysPrepName
    The customization spec to use.
    Applicable to Linked Clone farms.

.PARAMETER RdsServers
    List of existing registered RDS server names to add into manual farm.
    Applicable to Manual farms.

.PARAMETER Spec
    Path of the JSON specification file.

.PARAMETER HvServer
    Reference to Horizon View Server to query the farms from. If the value is not passed or null then first element from global:DefaultHVServers would be considered inplace of hvServer.

.EXAMPLE
    New-HVFarm -LinkedClone -FarmName 'LCFarmTest' -ParentVM 'Win_Server_2012_R2' -SnapshotVM 'Snap_RDS' -VmFolder 'PoolVM' -HostOrCluster 'cls' -ResourcePool 'cls' -Datastores 'datastore1 (5)' -FarmDisplayName 'LC Farm Test' -Description  'created LC Farm from PS' -EnableProvisioning $true -StopOnProvisioningError $false -NamingPattern  "LCFarmVM_PS" -MinReady 1 -MaximumCount 1  -SysPrepName "RDSH_Cust2" -NetBiosName "adviewdev"

.EXAMPLE
    New-HVFarm -Spec C:\VMWare\Specs\LinkedClone.json

.EXAMPLE
    New-HVFarm -Manual -FarmName "manualFarmTest" -FarmDisplayName "manualFarmTest" -Description "Manual PS Test" -RdsServers "vm-for-rds.eng.vmware.com","vm-for-rds-2.eng.vmware.com"

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

    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [switch]
    $Manual,

    #farmSpec.farmData.name
    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
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

    #farmSpec.automatedfarmSpec.virtualCenter if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [string]
    $Vcenter,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.parentVM if LINKED_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [string]
    $ParentVM,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.snapshotVM if LINKED_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [string]
    $SnapshotVM,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.vmFolder if LINKED_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [string]
    $VmFolder,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.hostOrCluster if LINKED_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [string]
    $HostOrCluster,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterProvisioningData.resourcePool if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [string]
    $ResourcePool,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.datastore if LINKED_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [string[]]
    $Datastores,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.useVSAN if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [string]
    $UseVSAN,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.enableProvsioning if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]
    $EnableProvisioning = $true,

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.stopOnProvisioningError if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [boolean]
    $StopOnProvisioningError = $true,

    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [string]
    $TransparentPageSharingScope = 'VM',

    #farmSpec.automatedfarmSpec.rdsServerNamingSpec.namingMethod if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [ValidateSet('PATTERN')]
    [string]
    $NamingMethod = 'PATTERN',

    #farmSpec.automatedfarmSpec.rdsServerNamingSpec.patternNamingSettings.namingPattern if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [string]
    $NamingPattern = $farmName + '{n:fixed=4}',

    #farmSpec.automatedfarmSpec.virtualCenterProvisioningSettings.minReadyVMsOnVComposerMaintenance if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [int]
    $MinReady = 0,

    #farmSpec.automatedfarmSpec.rdsServerNamingSpec.patternNamingSettings.maxNumberOfRDSServers if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [int]
    $MaximumCount = 1,

    #farmSpec.automatedfarmSpec.customizationSettings.adContainer if LINKED_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [string]
    $AdContainer = 'CN=Computers',

    #farmSpec.automatedfarmSpec.customizationSettings.domainAdministrator
    [Parameter(Mandatory = $true,ParameterSetName = 'LINKED_CLONE')]
    [string]
    $NetBiosName,

    #farmSpec.automatedfarmSpec.customizationSettings.domainAdministrator
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [string]
    $DomainAdmin = $null,

    #farmSpec.automatedfarmSpec.customizationSettings.sysprepCustomizationSettings.customizationSpec if LINKED_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [string]
    $SysPrepName,

    ##farmSpec.manualfarmSpec.rdsServers
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
        $sourceFarm = Get-HVFarm -farmName $farmName -hvServer $hvServer
      } catch {
        Write-Error "Make sure Get-HVFarm advanced function is loaded, $_"
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
      if ($jsonObject.type -eq 'AUTOMATED') {
        $farmType = 'AUTOMATED'
        if ($null -ne $jsonObject.AutomatedFarmSpec.VirtualCenter) {
          $vCenter = $jsonObject.AutomatedFarmSpec.VirtualCenter
        }
        $linkedClone = $true
        $netBiosName = $jsonObject.NetBiosName
        $adContainer = $jsonObject.AutomatedFarmSpec.CustomizationSettings.AdContainer

        $namingMethod = $jsonObject.AutomatedFarmSpec.RdsServerNamingSpec.NamingMethod
        $namingPattern = $jsonObject.AutomatedFarmSpec.RdsServerNamingSpec.patternNamingSettings.namingPattern
        $maximumCount = $jsonObject.AutomatedFarmSpec.RdsServerNamingSpec.patternNamingSettings.maxNumberOfRDSServers

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
        }
        $sysPrepName = $jsonObject.AutomatedFarmSpec.CustomizationSettings.SysprepCustomizationSettings.CustomizationSpec
      } elseif ($jsonObject.type -eq 'MANUAL') {
        $manual = $true
        $farmType = 'MANUAL'
        $RdsServersObjs = $jsonObject.ManualFarmSpec.RdsServers

        foreach ($RdsServerObj in $RdsServersObjs) {
          $rdsServers += $RdsServerObj.rdsServer
        }
      }
      $farmDisplayName = $jsonObject.data.DisplayName
      $description = $jsonObject.data.Description
      $accessGroup = $jsonObject.data.AccessGroup
      $farmName = $jsonObject.data.name
    }

    if ($linkedClone) {
      $farmType = 'AUTOMATED'
      $provisioningType = 'VIEW_COMPOSER'
    } elseif ($manual) {
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

        if (!$farmVirtualMachineNamingSpec) {
          $farmSpecObj.AutomatedFarmSpec.RdsServerNamingSpec.NamingMethod = $namingMethod
          $farmSpecObj.AutomatedFarmSpec.RdsServerNamingSpec.patternNamingSettings.namingPattern = $namingPattern
          $farmSpecObj.AutomatedFarmSpec.RdsServerNamingSpec.patternNamingSettings.maxNumberOfRDSServers = $maximumCount
        } else {
          $vmNamingSpec = New-Object VMware.Hv.FarmRDSServerNamingSpec
          $vmNamingSpec.NamingMethod = 'PATTERN'

          $vmNamingSpec.patternNamingSettings = New-Object VMware.Hv.FarmPatternNamingSettings
          $vmNamingSpec.patternNamingSettings.namingPattern = $namingPattern
          $vmNamingSpec.patternNamingSettings.maxNumberOfRDSServers = $maximumCount
        }

        #
        # build the VM LIST
        #
        try {
          $farmVirtualCenterProvisioningData = Get-HVFarmProvisioningData -vc $virtualCenterID -vmObject $farmVirtualCenterProvisioningData
          $hostClusterId = $farmVirtualCenterProvisioningData.HostOrCluster
          $farmVirtualCenterStorageSettings = Get-HVFarmStorageObject -hostclusterID $hostClusterId -storageObject $farmVirtualCenterStorageSettings
          $farmVirtualCenterNetworkingSettings = Get-HVFarmNetworkSetting -networkObject $farmVirtualCenterNetworkingSettings
          $farmCustomizationSettings = Get-HVFarmCustomizationSetting -vc $virtualCenterID -customObject $farmCustomizationSettings
        } catch {
          $handleException = $true
          Write-Error "Failed to create Farm with error: $_"
          break
        }

        $farmSpecObj.AutomatedFarmSpec.RdsServerMaxSessionsData.MaxSessionsType = "UNLIMITED"

        if (!$FarmVirtualCenterProvisioningSettings) {
          $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.enableProvisioning = $true
          $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.stopProvisioningOnError = $true
          $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.minReadyVMsOnVComposerMaintenance = 0
          $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData = $farmVirtualCenterProvisioningData
          $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings = $farmVirtualCenterStorageSettings
          $farmSpecObj.AutomatedFarmSpec.VirtualCenterProvisioningSettings.VirtualCenterNetworkingSettings = $FarmVirtualCenterNetworkingSettings

          $farmSpecObj.AutomatedFarmSpec.CustomizationSettings = $farmCustomizationSettings
          $farmSpecObj.AutomatedFarmSpec.ProvisioningType = $provisioningType
          $farmSpecObj.AutomatedFarmSpec.VirtualCenter = $virtualCenterID
        } else {
          $FarmVirtualCenterProvisioningSettings.VirtualCenterProvisioningData = $farmVirtualCenterProvisioningData
          $FarmVirtualCenterProvisioningSettings.VirtualCenterStorageSettings = $farmVirtualCenterStorageSettings
          $FarmVirtualCenterProvisioningSettings.VirtualCenterNetworkingSettings = $FarmVirtualCenterNetworkingSettings

          $FarmAutomatedFarmSpec = New-Object VMware.Hv.FarmAutomatedFarmSpec
          $FarmAutomatedFarmSpec.ProvisioningType = $provisioningType
          $FarmAutomatedFarmSpec.VirtualCenter = $virtualCenterID
          $FarmAutomatedFarmSpec.VirtualCenterProvisioningSettings = $farmVirtualCenterProvisioningSettings
          $FarmAutomatedFarmSpec.virtualCenterManagedCommonSettings = $farmVirtualCenterManagedCommonSettings
          $FarmAutomatedFarmSpec.CustomizationSettings = $farmCustomizationSettings
        }
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
    $farm_service_helper.Farm_Create($services, $farmSpecObj)
  }

  end {
    [System.gc]::collect()
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
    [Parameter(Mandatory = $false)]
    [VMware.Hv.FarmVirtualCenterStorageSettings]$StorageObject,

    [Parameter(Mandatory = $true)]
    [VMware.Hv.HostOrClusterId]$HostClusterID
  )
  if (!$storageObject) {
    $storageObject = New-Object VMware.Hv.FarmVirtualCenterStorageSettings

    $FarmSpaceReclamationSettings = New-Object VMware.Hv.FarmSpaceReclamationSettings -Property @{ 'reclaimVmDiskSpace' = $false }

    $FarmViewComposerStorageSettingsList = @{
      'useSeparateDatastoresReplicaAndOSDisks' = $false;
      'replicaDiskDatastore' = $FarmReplicaDiskDatastore
      'useNativeSnapshots' = $false;
      'spaceReclamationSettings' = $FarmSpaceReclamationSettings;
    }

    $storageObject.ViewComposerStorageSettings = New-Object VMware.Hv.FarmViewComposerStorageSettings -Property $FarmViewComposerStorageSettingsList
  }

  if ($datastores) {
    $Datastore_service_helper = New-Object VMware.Hv.DatastoreService
    $datastoreList = $Datastore_service_helper.Datastore_ListDatastoresByHostOrCluster($services, $hostClusterID)
    $datastoresSelected = @()
    foreach ($ds in $datastores) {
      $datastoresSelected += ($datastoreList | Where-Object { $_.datastoredata.name -eq $ds }).id
    }
    foreach ($ds in $datastoresSelected) {
      $datastoresObj = New-Object VMware.Hv.FarmVirtualCenterDatastoreSettings
      $datastoresObj.Datastore = $ds
      $datastoresObj.StorageOvercommit = 'UNBOUNDED'
      $StorageObject.Datastores += $datastoresObj
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
    $ViewComposerDomainAdministrator_service_helper = New-Object VMware.Hv.ViewComposerDomainAdministratorService
    $ViewComposerDomainAdministratorID = ($ViewComposerDomainAdministrator_service_helper.ViewComposerDomainAdministrator_List($services, $vcID) | Where-Object { $_.base.domain -match $netBiosName })
    if (! [string]::IsNullOrWhitespace($domainAdmin)) {
      $ViewComposerDomainAdministratorID = ($ViewComposerDomainAdministratorID | Where-Object { $_.base.userName -ieq $domainAdmin }).id
    } else {
      $ViewComposerDomainAdministratorID = $ViewComposerDomainAdministratorID[0].id
    }
    if ($null -eq $ViewComposerDomainAdministratorID) {
      throw "No Composer Domain Administrator found with netBiosName: [$netBiosName]"
    }
    $ADDomain_service_helper = New-Object VMware.Hv.ADDomainService
    $adDomianId = ($ADDomain_service_helper.ADDomain_List($services) | Where-Object { $_.NetBiosName -eq $netBiosName } | Select-Object -Property id)
    if ($null -eq $adDomianId) {
      throw "No Domain found with netBiosName: [$netBiosName]"
    }
    $ad_containder_service_helper = New-Object VMware.Hv.AdContainerService
    $adContainerId = ($ad_containder_service_helper.ADContainer_ListByDomain($services, $adDomianId.id) | Where-Object { $_.Rdn -eq $adContainer } | Select-Object -Property id).id
    if ($null -eq $adContainerId) {
      throw "No AdContainer found with name: [$adContainer]"
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
    $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.AdContainer = $adContainerId
    $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.ReusePreExistingAccounts = $false
    $farmSpecObj.AutomatedFarmSpec.CustomizationSettings.SysprepCustomizationSettings = $sysprepCustomizationSettings

    $customObject = $farmSpecObj.AutomatedFarmSpec.CustomizationSettings
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
  } elseif ($farmType -eq 'MANUAL') {
    # No need to set
  }
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
   New-HVPool -LinkedClone -PoolName 'vmwarepool' -UserAssignment FLOATING -ParentVM 'Agent_vmware' -SnapshotVM 'kb-hotfix' -VmFolder 'vmware' -HostOrCluster 'CS-1' -ResourcePool 'CS-1' -Datastores 'datastore1' -NamingMethod PATTERN -PoolDisplayName 'vmware linkedclone pool' -Description  'created linkedclone pool from ps' -EnableProvisioning $true -StopOnProvisioningError $false -NamingPattern  "vmware2" -MinReady 1 -MaximumCount 1 -SpareCount 1 -ProvisioningTime UP_FRONT -SysPrepName vmwarecust -CustType SYS_PREP -NetBiosName adviewdev -DomainAdmin root

.EXAMPLE
   Create new automated linked clone pool by using JSON spec file
   New-HVPool -Spec C:\VMWare\Specs\LinkedClone.json

.EXAMPLE
   Clone new pool from automated linked (or) full clone pool
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

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.datastore if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $true,ParameterSetName = 'FULL_CLONE')]
    [string[]]
    $Datastores,

    #desktopSpec.automatedDesktopSpec.virtualCenterProvisioningSettings.virtualCenterStorageSettings.useVSAN if LINKED_CLONE, INSTANT_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'FULL_CLONE')]
    [string]
    $UseVSAN,

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

    [Parameter(Mandatory = $false,ParameterSetName = 'INSTANT_CLONE')]
    [Parameter(Mandatory = $false,ParameterSetName = 'LINKED_CLONE')]
    [string]$DomainAdmin = $null,

    #desktopSpec.automatedDesktopSpec.customizationSettings.customizationType if LINKED_CLONE, FULL_CLONE
    [Parameter(Mandatory = $true,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $true,ParameterSetName = "FULL_CLONE")]
    [ValidateSet('CLONE_PREP','QUICK_PREP','SYS_PREP','NONE')]
    [string]
    $CustType,

    #desktopSpec.automatedDesktopSpec.customizationSettings.sysprepCustomizationSettings.customizationSpec if LINKED_CLONE, FULL_CLONE
    [Parameter(Mandatory = $false,ParameterSetName = "LINKED_CLONE")]
    [Parameter(Mandatory = $false,ParameterSetName = "FULL_CLONE")]
    [string]
    $SysPrepName,

    #manual desktop
    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [ValidateSet('VIRTUAL_CENTER','UNMANAGED')]
    [string]
    $Source,

    [Parameter(Mandatory = $true,ParameterSetName = 'MANUAL')]
    [Parameter(Mandatory = $false,ParameterSetName = "JSON_FILE")]
    [string[]]$VM,

    #farm
    [Parameter(Mandatory = $false,ParameterSetName = 'RDS')]
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
        Write-Error "Make sure Get-HVPool advanced function is loaded, $_"
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
        } else {
          if ($jsonObject.AutomatedDesktopSpec.ProvisioningType -eq "VIEW_COMPOSER") {
            $LinkedClone = $true
          } else {
            $FullClone = $true
          }
          $sysPrepName = $jsonObject.SysPrepName
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
        if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.Template) {
          $template = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.Template
        }
        if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.ParentVm) {
          $parentVM = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.ParentVm
        }
        if ($null -ne $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.Snapshot) {
          $snapshotVM = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.Snapshot
        }
        $vmFolder = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.VmFolder
        $hostOrCluster = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.HostOrCluster
        $resourcePool = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterProvisioningData.ResourcePool
        $dataStoreList = $jsonObject.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.VirtualCenterStorageSettings.Datastores
        foreach ($dtStore in $dataStoreList) {
          $datastores += $dtStore.Datastore
        }
      } elseif ($jsonObject.type -eq "MANUAL") {
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
    }

    if ($PSCmdlet.MyInvocation.ExpectingInput -or $clonePool) {

      if ($clonePool -and ($clonePool.GetType().name -eq 'DesktopSummaryView')) {
        $clonePool = Get-HVPool -poolName $clonePool.desktopsummarydata.name
      } elseif (!($clonePool -and ($clonePool.GetType().name -eq 'DesktopInfo'))) {
        Write-Error "In pipeline did not get object of expected type DesktopSummaryView/DesktopInfo"
        return
      }
      $poolType = $clonePool.type
      $desktopBase = $clonePool.base
      $desktopSettings = $clonePool.DesktopSettings
      $provisioningType = $null
      if ($clonePool.AutomatedDesktopData) {
        $provisioningType = $clonePool.AutomatedDesktopData.ProvisioningType
        $virtualCenterID = $clonePool.AutomatedDesktopData.VirtualCenter
        $desktopUserAssignment = $clonePool.AutomatedDesktopData.userAssignment
        $desktopVirtualMachineNamingSpec = $clonePool.AutomatedDesktopData.VmNamingSettings
        $DesktopVirtualCenterProvisioningSettings = $clonePool.AutomatedDesktopData.VirtualCenterProvisioningSettings
        $DesktopVirtualCenterProvisioningData = $DesktopVirtualCenterProvisioningSettings.VirtualCenterProvisioningData
        $DesktopVirtualCenterStorageSettings = $DesktopVirtualCenterProvisioningSettings.VirtualCenterStorageSettings
        $DesktopVirtualCenterNetworkingSettings = $DesktopVirtualCenterProvisioningSettings.VirtualCenterNetworkingSettings
        $desktopVirtualCenterManagedCommonSettings = $clonePool.AutomatedDesktopData.virtualCenterManagedCommonSettings
        $desktopCustomizationSettings = $clonePool.AutomatedDesktopData.CustomizationSettings
      }
      if (($null -eq $provisioningType) -or ($provisioningType -eq 'INSTANT_CLONE_ENGINE')) {
        Write-Error "Only Automated linked clone or full clone pool support cloning"
        break
      }
    } else {

      if ($InstantClone) {
        $poolType = 'AUTOMATED'
        $provisioningType = 'INSTANT_CLONE_ENGINE'
      }
      elseif ($LinkedClone) {
        $poolType = 'AUTOMATED'
        $provisioningType = 'VIEW_COMPOSER'
      }
      elseif ($FullClone) {
        $poolType = 'AUTOMATED'
        $provisioningType = 'VIRTUAL_CENTER'
      }
      elseif ($Manual) { $poolType = 'MANUAL' }
      elseif ($RDS) { $poolType = 'RDS' }

    }
    $script:desktopSpecObj = Get-HVDesktopSpec -poolType $poolType -provisioningType $provisioningType -namingMethod $namingMethod

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
          $desktopVirtualCenterStorageSettings = Get-HVPoolStorageObject -hostclusterID $hostClusterId -storageObject $desktopVirtualCenterStorageSettings
          $DesktopVirtualCenterNetworkingSettings = Get-HVPoolNetworkSetting -networkObject $DesktopVirtualCenterNetworkingSettings
          $desktopCustomizationSettings = Get-HVPoolCustomizationSetting -vc $virtualCenterID -customObject $desktopCustomizationSettings
        } catch {
          $handleException = $true
          Write-Error "Failed to create Pool with error: $_"
          break
        }

        if (!$DesktopVirtualCenterProvisioningSettings) {
          $desktopSpecObj.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.enableProvisioning = $true
          $desktopSpecObj.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.stopProvisioningOnError = $true
          $desktopSpecObj.AutomatedDesktopSpec.VirtualCenterProvisioningSettings.minReadyVMsOnVComposerMaintenance = 0
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

    if ($desktopSettings) { $desktopSpecObj.DesktopSettings = $desktopSettings }

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
    $desktop_helper.Desktop_create($services,$desktopSpecObj)
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
      throw "No vmfolder found with Name: [$vmFolder]"
    }
  }
  if ($hostOrCluster) {
    $vmFolder_helper = New-Object VMware.Hv.HostOrClusterService
    $hostClusterList = ($vmFolder_helper.HostOrCluster_GetHostOrClusterTree($services,$vmobject.datacenter)).treeContainer.children.info
    $hostClusterObj = $hostClusterList | Where-Object { $_.name -eq $hostOrCluster }
    if ($null -eq $hostClusterObj) {
      throw "No hostOrCluster found with Name: [$hostOrCluster]"
    }
    $vmObject.HostOrCluster = $hostClusterObj.id
  }
  if ($resourcePool) {
    $resourcePool_helper = New-Object VMware.Hv.ResourcePoolService
    $resourcePoolList = $resourcePool_helper.ResourcePool_GetResourcePoolTree($services,$vmobject.HostOrCluster)
    $resourcePoolObj = $resourcePoolList | Where-Object { $_.resourcepooldata.name -eq $resourcePool }
    if ($null -eq $resourcePoolObj) {
      throw "No hostOrCluster found with Name: [$resourcePool]"
    }
    $vmObject.ResourcePool = $resourcePoolObj.id
  }
  return $vmObject
}

function Get-HVPoolStorageObject {
  param(
    [Parameter(Mandatory = $false)]
    [VMware.Hv.DesktopVirtualCenterStorageSettings]$StorageObject,

    [Parameter(Mandatory = $true)]
    [VMware.Hv.HostOrClusterId]$HostClusterID
  )
  if (!$storageObject) {
    $storageObject = New-Object VMware.Hv.DesktopVirtualCenterStorageSettings
    $storageAcceleratorList = @{
      'useViewStorageAccelerator' = $false
    }
    $desktopViewStorageAcceleratorSettings = New-Object VMware.Hv.DesktopViewStorageAcceleratorSettings -Property $storageAcceleratorList
    $storageObject.viewStorageAcceleratorSettings = $desktopViewStorageAcceleratorSettings
    $desktopSpaceReclamationSettings = New-Object VMware.Hv.DesktopSpaceReclamationSettings -Property @{ 'reclaimVmDiskSpace' = $false }
    $desktopPersistentDiskSettings = New-Object VMware.Hv.DesktopPersistentDiskSettings -Property @{ 'redirectWindowsProfile' = $false }
    $desktopNonPersistentDiskSettings = New-Object VMware.Hv.DesktopNonPersistentDiskSettings -Property @{ 'redirectDisposableFiles' = $false }

    $desktopViewComposerStorageSettingsList = @{
      'useSeparateDatastoresReplicaAndOSDisks' = $false;
      'useNativeSnapshots' = $false;
      'spaceReclamationSettings' = $desktopSpaceReclamationSettings;
      'persistentDiskSettings' = $desktopPersistentDiskSettings;
      'nonPersistentDiskSettings' = $desktopNonPersistentDiskSettings
    }
    if (!$FullClone) {
      $storageObject.ViewComposerStorageSettings = New-Object VMware.Hv.DesktopViewComposerStorageSettings -Property $desktopViewComposerStorageSettingsList
    }
  }
  if ($datastores) {
    $datastore_helper = New-Object VMware.Hv.DatastoreService
    $datastoreList = $datastore_helper.Datastore_ListDatastoresByHostOrCluster($services,$hostClusterID)
    $datastoresSelected = @()
    foreach ($ds in $datastores) {
      $datastoresSelected += ($datastoreList | Where-Object { $_.datastoredata.name -eq $ds }).id
    }
    foreach ($ds in $datastoresSelected) {
      $myDatastores = New-Object VMware.Hv.DesktopVirtualCenterDatastoreSettings
      $myDatastores.Datastore = $ds
      $mydatastores.StorageOvercommit = 'UNBOUNDED'
      $storageObject.Datastores += $myDatastores
    }
  }
  if ($storageObject.Datastores.Count -eq 0) {
    throw "No datastore found with Name: [$datastores]"
  }
  if ($useVSAN) { $storageObject.useVSAN = $useVSAN }
  return $storageObject
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
        $adDomianId = ($ad_domain_helper.ADDomain_List($services) | Where-Object { $_.NetBiosName -eq $netBiosName } | Select-Object -Property id)
        if ($null -eq $adDomianId) {
          throw "No Domain found with netBiosName: [$netBiosName]"
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
      } else {
        $instantCloneEngineDomainAdministrator = $instantCloneEngineDomainAdministrator[0].id
      }
      if ($null -eq $instantCloneEngineDomainAdministrator) {
        throw "No Instant Clone Engine Domain Administrator found with netBiosName: [$netBiosName]"
      }
      $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings = Get-CustomizationObject
      $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CloneprepCustomizationSettings.InstantCloneEngineDomainAdministrator = $instantCloneEngineDomainAdministrator
    }
    else {
      if ($LinkedClone) {
        $viewComposerDomainAdministrator_helper = New-Object VMware.Hv.ViewComposerDomainAdministratorService
        $ViewComposerDomainAdministratorID = ($viewComposerDomainAdministrator_helper.ViewComposerDomainAdministrator_List($services,$vcID) | Where-Object { $_.base.domain -match $netBiosName })
        if (![string]::IsNullOrWhitespace($domainAdmin)) {
            $ViewComposerDomainAdministratorID = ($ViewComposerDomainAdministratorID | Where-Object { $_.base.userName -ieq $domainAdmin }).id
        } else {
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
        } elseif ($custType -eq 'QUICK_PREP') {
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.CustomizationType = 'QUICK_PREP'
          $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.QuickprepCustomizationSettings = Get-CustomizationObject
        } else {
          throw "The customization type: [$custType] is not supported for LinkedClone Pool"
        }
        $desktopSpecObj.AutomatedDesktopSpec.CustomizationSettings.DomainAdministrator = $ViewComposerDomainAdministratorID
      } elseif ($FullClone) {
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
        } elseif ($custType -eq 'NONE') {
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
  } elseif ($LinkedClone) {
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

function Get-HVDesktopSpec {

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
  } elseif ($poolType -eq 'MANUAL') {
    $desktop_spec_helper.getDataObject().ManualDesktopSpec.userAssignment = $desktop_helper.getDesktopUserAssignmentHelper().getDataObject()
    $desktop_spec_helper.getDataObject().ManualDesktopSpec.viewStorageAcceleratorSettings = $desktop_helper.getDesktopViewStorageAcceleratorSettingsHelper().getDataObject()
    $desktop_spec_helper.getDataObject().ManualDesktopSpec.virtualCenterManagedCommonSettings = $desktop_helper.getDesktopVirtualCenterManagedCommonSettingsHelper().getDataObject()
  } else {
    $desktop_spec_helper.getDataObject().RdsDesktopSpec = $desktop_helper.getDesktopRDSDesktopSpecHelper().getDataObject()
  }
  return $desktop_spec_helper.getDataObject()

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
   Remove-HVFarm -FarmName 'Farm-01' -HvServer $hvServer

.EXAMPLE
   $farm_array | Remove-HVFarm -HvServer $hvServer

.EXAMPLE
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
          $farmList += $farmObj.id
        }
      } else {
        Write-Error "Unable to retrieve FarmSummaryView with given farmName [$farmName]"
        break
      }
    } elseif ($PSCmdlet.MyInvocation.ExpectingInput) {
      foreach ($item in $farm) {
        if ($item.GetType().name -eq 'FarmInfo' -or $item.GetType().name -eq 'FarmSummaryView') {
          $farmList += $item.id
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
      $farm_service_helper.Farm_Delete($services, $item)
    }
    Write-Host "Farm Deleted"

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
   Remove-HVPool -HvServer $hvServer -PoolName 'FullClone' -DeleteFromDisk

.EXAMPLE
   $pool_array | Remove-HVPool -HvServer $hvServer  -DeleteFromDisk

.EXAMPLE
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
        Write-Error "Make sure Get-HVPool advanced function is loaded, $_"
        break
      }
      if ($myPools) {
        foreach ($poolObj in $myPools) {
          $poolList += $poolObj.id
        }
      } else {
        Write-Error "No desktopsummarydata found with pool name: [$pool]"
        break
      }
    } elseif ($PSCmdlet.MyInvocation.ExpectingInput) {
      foreach ($item in $pool) {
        if (($item.GetType().name -eq 'DesktopInfo') -or ($item.GetType().name -eq 'DesktopSummaryView')) {
          $poolList += $item.id
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
        $queryResults = Get-HVQueryResults MachineSummaryView (Get-HVQueryFilter base.desktop -eq $item)
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
      Write-Host "Deleting Pool"
      $desktop_service_helper.Desktop_Delete($services,$item,$deleteSpec)
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
    Set-HVFarm -FarmName 'Farm-o1' -Spec 'C:\Edit-HVFarm\ManualEditFarm.json'

.EXAMPLE
    Set-HVFarm -FarmName 'Farm-o1' -Key 'base.description' -Value 'updated description'

.EXAMPLE
    $farm_array | Set-HVFarm -Key 'base.description' -Value 'updated description'

.EXAMPLE
    Set-HVFarm -farm 'Farm2' -Start

.EXAMPLE
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
    $farmList = @()
    if ($farmName) {
      try {
        $farmSpecObj = Get-HVFarmSummary -farmName $farmName -hvServer $hvServer
      } catch {
        Write-Error "Make sure Get-HVFarm advanced function is loaded, $_"
        break
      }
      if ($farmSpecObj) {
        foreach ($farmObj in $farmSpecObj) {
          if (($Start -or $Stop) -and ("AUTOMATED" -ne $farmObj.Data.Type)) {
            Write-Error "Start/Stop operation is not supported for farm with name : [$farmObj.Data.Name]"
            return
          }
          $farmList += $farmObj.id
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
          $farmList += $item.id
        }
        elseif ($item.GetType().name -eq 'FarmInfo') {
          if (($Start -or $Stop) -and ("AUTOMATED" -ne $item.Type)) {
            Write-Error "Start/Stop operation is not supported for farm with name : [$item.Data.Name]"
            return
          }
          $farmList += $item.id
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
    foreach ($item in $farmList) {
      $farm_service_helper.Farm_Update($services,$item,$updates)
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
    Set-HVPool -PoolName 'ManualPool' -Spec 'C:\Edit-HVPool\EditPool.json'

.EXAMPLE
    Set-HVPool -PoolName 'RDSPool' -Key 'base.description' -Value 'update description'

.Example
    Set-HVPool  -PoolName 'LnkClone' -Disable

.Example
    Set-HVPool  -PoolName 'LnkClone' -Enable

.Example
    Set-HVPool  -PoolName 'LnkClone' -Start

.Example
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
    $poolList = @()
    if ($poolName) {
      try {
        $desktopPools = Get-HVPoolSummary -poolName $poolName -hvServer $hvServer
      } catch {
        Write-Error "Make sure Get-HVPool advanced function is loaded, $_"
        break
      }
      if ($desktopPools) {
        foreach ($desktopObj in $desktopPools) {
          if (($Start -or $Stop) -and ("AUTOMATED" -ne $item.DesktopSummaryData.Type)) {
            Write-Error "Start/Stop operation is not supported for Poll with name : [$item.DesktopSummaryData.Name]"
            return
          }
          $poolList += $desktopObj.id
        }
      }
    } elseif ($PSCmdlet.MyInvocation.ExpectingInput) {
      foreach ($item in $pool) {
        if ($item.GetType().name -eq 'DesktopInfo') {
          if (($Start -or $Stop) -and ("AUTOMATED" -ne $item.Type)) {
            Write-Error "Start/Stop operation is not supported for Pool with name : [$item.Base.Name]"
            return
          }
          $poolList += $item.id
        }
        elseif ($item.GetType().name -eq 'DesktopSummaryView') {
          if (($Start -or $Stop) -and ("AUTOMATED" -ne $item.DesktopSummaryData.Type)) {
            Write-Error "Start/Stop operation is not supported for Poll with name : [$item.DesktopSummaryData.Name]"
            return
          }
          $poolList += $item.id
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
    foreach ($item in $poolList) {
      $desktop_helper.Desktop_Update($services,$item,$updates)
    }
  }

  end {
    [System.gc]::collect()
  }
}

function Start-HVFarm {
<#
.SYNOPSIS
    Perform maintenance tasks on the farm(s).

.DESCRIPTION
    This function is used to perform maintenance tasks like enable/disable, start/stop and recompose the farm.

.PARAMETER Farm
    Name/Object(s) of the farm. Object(s) should be of type FarmSummaryView/FarmInfo.

.PARAMETER Recompose
    Switch for recompose operation. Requests a recompose of RDS Servers in the specified 'AUTOMATED' farm. This marks the RDS Servers for recompose, which is performed asynchronously.

.PARAMETER StartTime
    Specifies when to start the operation. If unset, the operation will begin immediately.

.PARAMETER LogoffSetting
    Determines when to perform the operation on machines which have an active session. This property will be one of:
    "FORCE_LOGOFF" - Users will be forced to log off when the system is ready to operate on their RDS Servers. Before being forcibly logged off, users may have a grace period in which to save their work (Global Settings).
    "WAIT_FOR_LOGOFF" - Wait for connected users to disconnect before the task starts. The operation starts immediately on RDS Servers without active sessions.

.PARAMETER StopOnFirstError
    Indicates that the operation should stop on first error.

.PARAMETER Servers
    The RDS Server(s) id to recompose. Provide a comma separated list for multiple RDSServerIds.

.PARAMETER ParentVM
    New base image VM for automated farm's RDS Servers. This must be in the same datacenter as the base image of the RDS Server.

.PARAMETER SnapshotVM
    Base image snapshot for the Automated Farm's RDS Servers.

.PARAMETER Vcenter
    Virtual Center server-address (IP or FQDN) of the given farm. This should be same as provided to the Connection Server while adding the vCenter server.

.PARAMETER HvServer
    Reference to Horizon View Server to query the data from. If the value is not passed or null then first element from global:DefaultHVServers would be considered inplace of hvServer.

.EXAMPLE
    Start-HVFarm -Recompose -Farm 'Farm-01' -LogoffSetting FORCE_LOGOFF -ParentVM 'View-Agent-Win8' -SnapshotVM 'Snap_USB'

.EXAMPLE
    $myTime = Get-Date '10/03/2016 12:30:00'
    Start-HVFarm -Farm 'Farm-01' -Recompose -LogoffSetting 'FORCE_LOGOFF' -ParentVM 'ParentVM' -SnapshotVM 'SnapshotVM' -StartTime $myTime

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

    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [System.DateTime]$StartTime,

    [Parameter(Mandatory = $true,ParameterSetName = 'RECOMPOSE')]
    [ValidateSet('FORCE_LOGOFF','WAIT_FOR_LOGOFF')]
    [string]$LogoffSetting,

    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [boolean]$StopOnFirstError = $true,

    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
    [string []]$Servers,

    [Parameter(Mandatory = $true,ParameterSetName = 'RECOMPOSE')]
    [string]$ParentVM,

    [Parameter(Mandatory = $true,ParameterSetName = 'RECOMPOSE')]
    [string]$SnapshotVM,

    [Parameter(Mandatory = $false,ParameterSetName = 'RECOMPOSE')]
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
    $farmList = @{}
    $farmType = @{}
    $farmSource = @{}
    $farm_service_helper = New-Object VMware.Hv.FarmService
    if ($farm) {
      if ($farm.GetType().name -eq 'FarmInfo') {
        $id = $farm.id
        $name = $farm.data.name
        $type = $farm.type
      }
      elseif ($farm.GetType().name -eq 'FarmSummaryView') {
        $id = $farm.id
        $name = $farm.data.name
        $type = $farm.data.type
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
          $type = $farmSpecObj.data.type
        } else {
          Write-Error "Unable to retrieve FarmSummaryView with given farmName [$farm]"
          break
        }
      } else {
        Write-Error "In pipeline did not get object of expected type FarmSummaryView/FarmInfo"
        break
      }
      if ($type -eq 'AUTOMATED') {
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
            $farm_service_helper.Farm_Update($services,$item,$updates)

            $farm_service_helper.Farm_Recompose($services,$item,$spec)
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
    Start-HVPool -Recompose -Pool 'LCPool3' -LogoffSetting FORCE_LOGOFF -ParentVM 'View-Agent-Win8' -SnapshotVM 'Snap_USB'

.EXAMPLE
    Start-HVPool -Refresh -Pool 'LCPool3' -LogoffSetting FORCE_LOGOFF

.EXAMPLE
    $myTime = Get-Date '10/03/2016 12:30:00'
    Start-HVPool -Rebalance -Pool 'LCPool3' -LogoffSetting FORCE_LOGOFF -StartTime $myTime

.EXAMPLE
    Start-HVPool -SchedulePushImage -Pool 'InstantPool' -LogoffSetting FORCE_LOGOFF -ParentVM 'InsParentVM' -SnapshotVM 'InsSnapshotVM'

.EXAMPLE
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
            Write-Error "Make sure Get-HVPool advanced function is loaded, $_"
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
            $desktop_helper.Desktop_Rebalance($services,$item,$spec)
          }
        }
        'REFRESH' {
          $spec = Get-HVTaskSpec -Source $poolSource.$item -poolName $poolList.$item -operation $operation -taskSpecName 'DesktopRefreshSpec' -desktopId $item
          if ($null -ne $spec) {
            # make sure current task on VMs, must be None
            $desktop_helper.Desktop_Refresh($services,$item,$spec)
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
            $desktop_helper.Desktop_Update($services,$item,$updates)

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
            $desktop_helper.Desktop_SchedulePushImage($services,$item,$spec)
          }
        }
        'CANCEL_PUSH_IMAGE' {
          if ($poolSource.$item -ne 'INSTANT_CLONE_ENGINE') {
            Write-Error "$poolList.$item is not a INSTANT CLONE pool"
            break
          } else {
            $desktop_helper.Desktop_CancelScheduledPushImage($services,$item)
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

Export-ModuleMember Add-HVDesktop,Add-HVRDSServer,Connect-HVEvent,Disconnect-HVEvent,Get-HVEvent,Get-HVFarm,Get-HVFarmSummary,Get-HVPool,Get-HVPoolSummary,Get-HVQueryResult,Get-HVQueryFilter,New-HVFarm,New-HVPool,Remove-HVFarm,Remove-HVPool,Set-HVFarm,Set-HVPool,Start-HVFarm,Start-HVPool
