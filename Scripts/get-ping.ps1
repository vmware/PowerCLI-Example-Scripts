Function Get-PingStatus
 {
    param(
        [Parameter(ValueFromPipeline=$true)]       
        [string]$device,
        
        [validateSet("Online","Offline","ObjectTable")]
        [String]$getObject
    ) 

begin{
    $hash = @()

    }
process{
    
    $device| foreach {
            if (Test-Connection $_ -Count 1 -Quiet) {
                
                if(-not($GetObject)){write-host -ForegroundColor green "Online: $_ "}
                    
                    $Hash = $Hash += @{Online="$_"}
            }else{

                if(-not($GetObject)){write-host -ForegroundColor Red "Offline: $_ "}
                    
                    $Hash = $Hash += @{Offline="$_"}
                }
        }            
    }

end {
    if($GetObject) {
 
            $Global:Objects = $Hash | foreach { [PSCustomObject]@{
                
                DeviceName = $_.Values| foreach { "$_" }
                Online     = $_.Keys| where {$_ -eq "Online"} 
                offline    = $_.Keys| where {$_ -eq "Offline"} 
                }
            }   

    Switch -Exact ($GetObject)
        {

            'Online'      { $Global:Objects| where 'online'| select -ExpandProperty DeviceName }
            'Offline'     { $Global:Objects| where 'offline'| select -ExpandProperty DeviceName }
            'ObjectTable' { return $Global:Objects }       
        }

    }       
  } 
}
