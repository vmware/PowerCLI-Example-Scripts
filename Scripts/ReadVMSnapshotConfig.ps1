function Get-VMSnapshotConfigContent {
<#
   .SYNOPSIS
      Reads <vm name>.vmsd file content

   .DESCRIPTION
      Build the vmsd file http URI following https://code.vmware.com/apis/358/vsphere#/doc/vim.FileManager.html
      and reads its content with the session established by Connect-VIServer

   .INPUTS
      VirtualMachine

   .OUTPUTS
      String - the content of the vmsd file

   .NOTES
      Author: Dimitar Milov
      Version: 1.0

   .EXAMPLE
      Get-VM <MyVM> | Get-VMSnapshotConfigContent
#>

[CmdletBinding()]
param(
   [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
   [ValidateNotNull()]
   [VMware.VimAutomation.Types.VirtualMachine]
   $VM
)

PROCESS {
   # Create web client from current session
   $sessionKey = $vm.GetClient().ConnectivityService.CurrentUserSession.SoapSessionKey
   $certValidationHandler = $vm.GetClient().ConnectivityService.GetValidationHandlerForCurrentServer()
   $webClient = [vmware.vimautomation.common.util10.httpclientUtil]::CreateHttpClientWithSessionReuse($certValidationHandler, $sessionKey, $null)

   # Build VMSD file http URI
   # https://code.vmware.com/apis/358/vsphere#/doc/vim.FileManager.html
   $vmName = $vm.Name
   $datastoreName = ($vm | Get-Datastore).Name
   $dcName = ($vm | Get-Datacenter).Name
   $serverAddress = $vm.GetClient().ConnectivityService.ServerAddress
   $vmsdUri = [uri]"https://$serverAddress/folder/$vmName/$vmName.vmsd?dcPath=$dcName&dsName=$datastoreName"

   # Get VMSD content as string
   $task = $webClient.GetAsync($vmsdUri)
   $task.Wait()
   $vmsdContent = $task.Result.Content.ReadAsStringAsync().Result

   # Dispose web client
   $webClient.Dispose()

   # Result
   $vmsdContent
}

}

function Get-VMSnapshotConfigSetting {
<#
   .SYNOPSIS
      Gets the value of a specified key from the snapshot config file content

   .DESCRIPTION
      Reads the VM's snapshot config file and searches for specified key. 
      If key is found its value is returned as an output

   .INPUTS
      VirtualMachine and key

   .OUTPUTS
      String - config value for the specified key

   .NOTES
      Author: Dimitar Milov
      Version: 1.0

   .EXAMPLE
      Get-VM <MyVM> | Get-VMSnapshotConfigSetting -Key "numSentinels"
#>
[CmdletBinding()]
param(
   [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
   [ValidateNotNull()]
   [VMware.VimAutomation.Types.VirtualMachine]
   $VM,

   [Parameter(Mandatory=$true)]
   [ValidateNotNull()]
   [string]
   $Key
)

PROCESS {
   $content = Get-VMSnapshotConfigContent -vm $vm

   $keyMatch = $content | Select-String ('{0} = "(?<value>.*)"' -f $key)

   if ($keyMatch.Matches -ne $null) {
      $keyMatch.Matches[0].Groups["value"].Value
   }
}
}
