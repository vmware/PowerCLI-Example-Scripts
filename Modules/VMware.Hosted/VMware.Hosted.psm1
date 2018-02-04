Function Get-Confirmation {
    $choice = ""
    while ($choice -notmatch "[y|n]"){
        $choice = read-host "Do you want to continue? (Y/N)"
    }
    if($choice -ne 'y') {
        break
    }
}

Function Connect-HostedServer {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Server,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Username,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Password,
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$Protocol = "http",
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][int]$Port = 8697
    )
    $pair = $Username+":"+$Password
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"
    $headers = @{Authorization = $basicAuthValue}

    $Global:DefaultHostedServer = [pscustomobject] @{
        Server=$Protocol + "://" + $server + ":$Port/api";
        Protcol=$Protocol
        Headers=$headers
    }

    if($DefaultHostedServer.Protcol -eq "https") {
        # PowerShell Core has a nice -SkipCertificateCheck but looks like Windows does NOT :(
        if($PSVersionTable.PSEdition -eq "Core") {
            $Global:fusionCommand = "Invoke-Webrequest -SkipCertificateCheck "
        } else {
            # Needed for Windows PowerShell to handle HTTPS scenario
            # https://stackoverflow.com/a/15627483
            $Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
            $Compiler = $Provider.CreateCompiler()
            $Params = New-Object System.CodeDom.Compiler.CompilerParameters
            $Params.GenerateExecutable = $false
            $Params.GenerateInMemory = $true
            $Params.IncludeDebugInformation = $false
            $Params.ReferencedAssemblies.Add("System.DLL") > $null
            $TASource=@'
            namespace Local.ToolkitExtensions.Net.CertificatePolicy
            {
                public class TrustAll : System.Net.ICertificatePolicy
                {
                    public bool CheckValidationResult(System.Net.ServicePoint sp,System.Security.Cryptography.X509Certificates.X509Certificate cert, System.Net.WebRequest req, int problem)
                    {
                        return true;
                    }
                }
            }
'@
            $TAResults=$Provider.CompileAssemblyFromSource($Params,$TASource)
            $TAAssembly=$TAResults.CompiledAssembly
            ## We create an instance of TrustAll and attach it to the ServicePointManager
            $TrustAll = $TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
            [System.Net.ServicePointManager]::CertificatePolicy = $TrustAll
            $Global:fusionCommand = "Invoke-Webrequest "
        }
    } else {
        $Global:fusionCommand = "Invoke-Webrequest "
    }
    $Global:DefaultHostedServer
}

Function Disconnect-HostedServer {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Server
    )

    $Global:DefaultHostedServer = $null
}

Function Get-HostedVM {
    Param (
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$Id
    )

    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    if($Id) {
        $vmUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id
        try {
            $params = "-Headers `$Global:DefaultHostedServer.Headers -Uri $vmUri -Method GET -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
            $command = $Global:fusionCommand + $params
            $vm = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
        } catch {
             Write-host -ForegroundColor Red "Invalid VM Id $Id"
             break
        }

        $vmIPUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id + "/ip"
        try {
            $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmIPUri -Method GET -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
            $command = $Global:fusionCommand + $params
            $vmIPResults = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
            $vmIP = $vmIPResults.ip
        } catch {
            $vmIP = "N/A"
        }

        $vmPowerUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id + "/power"
        try {
            $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmPowerUri -Method GET -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
            $command = $Global:fusionCommand + $params
            $vmPower = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
        } catch {
            $vmPower = "N/A"
        }

        $results = [pscustomobject] @{
            Id = $vm.Id;
            CPU = $vm.Cpu.processors;
            Memory = $vm.Memory;
            PowerState = $vmPower.power_state;
            IPAddress = $vmIP;
        }
        $results
    } else {
        $uri = $Global:DefaultHostedServer.Server + "/vms"
        $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $uri -Method GET -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
        $command = $Global:fusionCommand + $params
        try {
            Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-host -ForegroundColor Red "Failed to list VMs"
        }
    }
}

Function Start-HostedVM {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Id
    )

    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    $vmPowerUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id + "/power"
    try {
        $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmPowerUri -Method GET -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
        $command = $Global:fusionCommand + $params
        $vmPower = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-host -ForegroundColor Red "Invalid VM Id $Id"
        break
    }

    if($vmPower.power_state -eq "poweredOff" -or $vmPower.power_state -eq "suspended") {
        try {
            Write-Host "Powering on VM $Id ..."
            $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmPowerUri -Method PUT -ContentType `"application/vnd.vmware.vmw.rest-v1+json`" -Body `"on`""
            $command = $Global:fusionCommand + $params
            $vm = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-host -ForegroundColor Red "Unable to Power On VM $Id"
            break
        }
    } else {
        Write-Host "VM $Id is already Powered On"
    }
}

Function Stop-HostedVM {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Id,
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][boolean]$Soft,
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][boolean]$Confirm = $true
    )

    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    if($Confirm) {
        Get-Confirmation
    }

    $vmPowerUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id + "/power"
    try {
        $params += "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmPowerUri -Method GET -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
        $command = $Global:fusionCommand + $params
        $vmPower = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-host -ForegroundColor Red "Invalid VM Id $Id"
        break
    }

    if($vmPower.power_state -eq "poweredOn") {
        if($Soft) {
            try {
                Write-Host "Shutting down VM $Id ..."
                $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmPowerUri -Method PUT -ContentType `"application/vnd.vmware.vmw.rest-v1+json`" -Body `"shutdown`""
                $command = $Global:fusionCommand + $params
                $vm = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
            } catch {
                Write-host -ForegroundColor Red "Unable to Shutdown VM $Id"
                break
            }
        } else {
            try {
                Write-Host "Powering off VM $Id ..."
                $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmPowerUri -Method PUT -ContentType `"application/vnd.vmware.vmw.rest-v1+json`" -Body `"off`""
                $command = $Global:fusionCommand + $params
                $vm = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
            } catch {
                Write-host -ForegroundColor Red "Unable to Power Off VM $Id"
                break
            }
        }
    } else {
        Write-Host "VM $Id is already Powered Off"
    }
}

Function Suspend-HostedVM {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Id,
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][boolean]$Confirm
    )

    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    if($Confirm) {
        Get-Confirmation
    }

    $vmPowerUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id + "/power"
    try {
        $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmPowerUri -Method GET -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
        $command = $Global:fusionCommand + $params
        $vmPower = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-host -ForegroundColor Red "Invalid VM Id $Id"
        break
    }

    if($vmPower.power_state -eq "poweredOn") {
        try {
            Write-Host "Suspending VM $Id ..."
            $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmPowerUri -Method PUT -ContentType `"application/vnd.vmware.vmw.rest-v1+json`" -Body `"suspend`""
            $command = $Global:fusionCommand + $params
            $vm = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-host -ForegroundColor Red "Unable to suspend VM $Id"
            break
        }
    } else {
        Write-Host "VM $Id can not be suspended because it is either Powered Off or Suspended"
    }
}

Function Resume-HostedVM {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Id
    )

    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    $vmPowerUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id + "/power"
    try {
        $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmPowerUri -Method GET -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
        $command = $Global:fusionCommand + $params
        $vmPower = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-host -ForegroundColor Red "Invalid VM Id $Id"
        break
    }

    if($vmPower.power_state -eq "suspended") {
        try {
            Start-HostedVM -Id $Id
        } catch {
            Write-host -ForegroundColor Red "Unable to Resume VM $Id"
            break
        }
    } else {
        Write-Host "VM $Id is not Suspended"
    }
}

Function New-HostedVM {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$ParentId,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Name
    )

    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    $vm = Get-HostedVM -Id $ParentId

    if($vm -match "Invalid VM Id") {
        Write-host -ForegroundColor Red "Unable to find existing VM Id $ParentId"
        break
    }

    $vmUri = $Global:DefaultHostedServer.Server + "/vms"
    $body = @{"ParentId"="$ParentId";"Name"=$Name}
    $body = $body | ConvertTo-Json

    try {
        Write-Host "Cloning VM $ParentId to $Name ..."
        $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmUri -Method POST -ContentType `"application/vnd.vmware.vmw.rest-v1+json`" -Body `$body"
        $command = $Global:fusionCommand + $params
        Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-host -ForegroundColor Red "Failed to Clone VM Id $ParentId"
        break
    }
}

Function Remove-HostedVM {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Id,
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][boolean]$Confirm = $true
    )

    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    $vm = Get-HostedVM -Id $Id

    if($vm -match "Invalid VM Id") {
        Write-host -ForegroundColor Red "Unable to find existing VM Id $Id"
        break
    }

    if($Confirm) {
        Get-Confirmation
    } 

    $vmUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id
    try {
        Write-Host "Deleting VM Id $Id ..."
        $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmUri -Method DELETE -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
        $command = $Global:fusionCommand + $params
        Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-host -ForegroundColor Red "Failed to Delete VM Id $Id"
        break
    }
}

Function Get-HostedVMSharedFolder {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Id
    )

    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    $folderUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id + "/sharedfolders"
    try {
        $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $folderUri -Method GET -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
        $command = $Global:fusionCommand + $params
        Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-host -ForegroundColor Red "Invalid VM Id $Id"
        break
    }
}

Function New-HostedVMSharedFolder {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Id,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$FolderName,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$HostPath
    )

    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    $body = @{"folder_id"="$FolderName";"host_path"=$HostPath;"flags"=4}
    $body = $body | ConvertTo-Json

    $folderUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id + "/sharedfolders"
    try {
        Write-Host "Creating new Shared Folder $FolderName to $HostPath for VM Id $Id ..."
        $params += "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $folderUri -Method POST -ContentType `"application/vnd.vmware.vmw.rest-v1+json`" -Body `$body"
        $command = $Global:fusionCommand + $params
        Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-host -ForegroundColor Red "Failed to create Shared Folder for VM Id $Id"
        break
    }
}

Function Remove-HostedVMSharedFolder {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Id,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$FolderName,
        [parameter(Mandatory=$false,ValueFromPipeline=$true)][boolean]$Confirm = $true
    )

    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    if($Confirm) {
        Get-Confirmation
    }

    $folderUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id + "/sharedfolders/" + $FolderName
    try {
        Write-Host "Removing Shared Folder $FolderName for VM Id $Id ..."
        $params += "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $folderUri -Method DELETE -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
        $command = $Global:fusionCommand + $params
        Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-host -ForegroundColor Red "Failed to remove Shared Folder for VM Id $Id"
        break
    }
}

Function Get-HostedVMNic {
    Param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Id
    )

    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    $vmNicUri = $Global:DefaultHostedServer.Server + "/vms/" + $Id + "/nic"
    try {
        $params += "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $vmNicUri -Method GET -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
        $command = $Global:fusionCommand + $params
        $vmNics = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-host -ForegroundColor Red "Invalid VM Id $Id"
        break
    }

    $results = @()
    foreach ($vmNic in $vmNics.nics) {
        $tmp = [pscustomobject]  @{
            Index = $vmNic.index;
            Type = $vmNic.Type;
            VMnet = $vmNic.Vmnet;
        }
        $results+=$tmp
    }
    $results
}

Function Get-HostedNetworks {
    if(!$Global:DefaultHostedServer) {
        Write-Host -ForegroundColor Red "You are not connected to Hosted Server, please run Connect-HostedServer"
        exit
    }

    $networksUri = $Global:DefaultHostedServer.Server + "/vmnet"
    try {
        $params = "-UseBasicParsing -Headers `$Global:DefaultHostedServer.Headers -Uri $networksUri -Method GET -ContentType `"application/vnd.vmware.vmw.rest-v1+json`""
        $command = $Global:fusionCommand + $params
        $networks = Invoke-Expression -Command $command | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-host -ForegroundColor Red "Unable to retrieve Networks"
        break
    }

    $results = @()
    foreach ($network in $networks.vmnets) {
        $tmp = [pscustomobject] @{
            Name = $network.Name;
            Type = $network.Type;
            DHCP = $network.Dhcp;
            Network = $network.subnet;
            Netmask = $network.mask;
        }
        $results+=$tmp
    }
    $results
}