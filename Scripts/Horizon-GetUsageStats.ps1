<#
.NOTES
Script name: Horizon-UsageStats.ps1
Author: Ray Heffer, @rayheffer
Last Edited on: 04/18/2017
Dependencies: PowerCLI 6.5 R1 or later, Horizon 7.0.2 or later
.DESCRIPTION
This is a sample script that retrieves the Horizon usage statistics. This produces the same metrics as listed under View Configuration > Product Licensing and Usage. Service providers can use this script or incorporate it with their existing scripts to automate the reporting of Horizon usage.

Example Output:
NumConnections                 : 180
NumConnectionsHigh             : 250
NumViewComposerConnections     : 0
NumViewComposerConnectionsHigh : 0
NumTunneledSessions            : 0
NumPSGSessions                 : 180
#>

# User Configuration
$hzUser = "Administrator"
$hzPass = "VMware1!"
$hzDomain = "vmw.lab"
$hzConn = "connect01.vmw.lab"

# Import the Horizon module
Import-Module VMware.VimAutomation.HorizonView

# Establish connection to Connection Server
$hvServer = Connect-HVServer -server $hzConn -User $hzUser -Password $hzPass -Domain $hzDomain

# Assign a variable to obtain the API Extension Data
$hvServices = $Global:DefaultHVServers.ExtensionData

# Retrieve Connection Server Health metrics
$hvHealth =$hvServices.ConnectionServerHealth.ConnectionServerHealth_List()

# Display ConnectionData (Usage stats)
$hvHealth.ConnectionData
