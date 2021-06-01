function Copy-Ipsetv2t {
    
    <#
      .SYNOPSIS
      Syncs Nsx IpSets from  Nsx v server to  Nsx t Server
  
      .DESCRIPTION
      Syncs Nsx IpSets from  Nsx  v server to  Nsx t Manager Server
      Takes any strings for the NSX v server to  and creates ip sets in  Nsx T Manager  Server.
  
      .PARAMETER Name
      Specifies the file name.
  
      .PARAMETER Extension
      Specifies the extension. "Txt" is the default.
  
      .INPUTS
       Takes NSXV and NSX T Manager fqdn and Credentials Credential1 is for NSX V and Credential2 is for NSX T 
  
      .OUTPUTS
      None
  
      .EXAMPLE
      C:\PS> Copy-Ipsetv2t -nsxvmanager nsxvmanage -nsxtmanager  nsxvmanager 
  
          Prompts for Credentials , Provide Credential which has full rights on Nsx v Manager and t manager
      
      .LINK
      Online version: https://github.com/j33tu/NSX
  
      .LINK
      Set-Item
  #>
    [CmdletBinding()] 
    param (
      [parameter(mandatory = $true)]
      [string] $nsxvmanager,
      [parameter(mandatory = $true)]
      [string] $nsxtmanager,
      [parameter(mandatory = $true)]
      [pscredential] $credential1,
      [parameter(mandatory = $true)]
      [pscredential] $credential2
    )
    begin {
  
      Connect-NsxServer $nsxvmanager -DisableVIAutoConnect -Credential $credential1
      $NsxIpSets = @(Get-NsxIpSet) 
      Disconnect-NsxServer $nsxvmanager
      Connect-NsxtServer $nsxtmanager -Credential $credential2
  
     
    }
      
    process {
      Write-Verbose -Message  "Syncing NsxIpSets from $nsxvmanager to $nsxtmanager" 
      foreach ($NsxIpSet in $NsxIpSets) {
        try {
          $ipsetname = $NsxIpSet.name
          $ipsetips = $NsxIpSet.Value
          #Create IP Set
          $ipsetsvc = Get-NsxtService -Name com.vmware.nsx.ip_sets
          $ipsetspec = $ipsetsvc.Help.create.ip_set.Create()
          $ipsetspec.ip_addresses = New-Object System.Collections.Generic.List[string]
          $ipsetspec.display_name = $ipsetname
          $ipsetips.Split(",") | ForEach { $ipsetspec.ip_addresses.Add($_) }
          $ipsetsvc.create($ipsetspec)
          Write-Verbose -Message "Created the IPSet with name $($NsxIpSet.Name) and Ipaddresses $($NsxIpSet.Value)"  -Verbose
                  
        }
        catch {
          Write-Verbose -Message  "FAILED to create Ip set $($NsxIpSet.Name) and Ipaddresses $($NsxIpSet.Value)" -Verbose
  
        }
        
        
      }
    }
    end {
      Write-Verbose -Message  "Operation Finished"
    }
  }
  