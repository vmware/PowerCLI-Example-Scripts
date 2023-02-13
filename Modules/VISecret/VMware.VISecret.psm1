<#
.SYNOPSIS
This cmdlet downloads the dependencies and intializes the default settings of the VISecret module

.PARAMETER Vault
The vault to save the credentials to. The default value is "VMwareSecretStore"

.DESCRIPTION
This cmdlet downloads the dependecies and initializes the default settings of the VISecret module.
It uses Microsoft.PowerShell.SecretStore as a default vault and sets it in no password mode, so that
the credentials are encrypted, but the user is not prompted for a password. If you want to use a different
vault or to use it with a password you should initialize those settings manually and not use this cmdlet.

.EXAMPLE
PS C:\> Initialize-VISecret

Initializes the default settings of the VISecret module
#>
function Initialize-VISecret {
    [CmdletBinding()]
    param(
        [string]$Vault = "VMwareSecretStore"
    )

    process {
        Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None -Interaction None -Confirm:$false 

        Register-SecretVault -Name $Vault -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
    }
}

<#
.SYNOPSIS
This cmdlet saves new credential in the secret vault or updates it if it already exists.

.DESCRIPTION
This cmdlet saves new credential in the secret vault or updates it if it already exists. 

.PARAMETER Server
The IP address or the hostname of the server to save the credential for

.PARAMETER Password
The password to be saved in the secret vault

.PARAMETER SecureStringPassword
The SecureString password to be saved in the secret vault

.PARAMETER User
The username for which to save the credential

.PARAMETER Vault
The vault to save the credential to. The default value is "VMwareSecretStore"

.EXAMPLE
PS C:\> New-VISecret -Server 10.10.10.10 -User administrator@vsphere.local -password pass

Saves the password for the administrator@vsphere.local user on the 10.10.10.10 server in the secret vault

#>
function New-VISecret {
    [CmdletBinding()]
    [Alias("Set-VISecret")]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Server,
        [Parameter(Mandatory=$true)]
        [string]$User,
        [string]$Password,
        [securestring]$SecureStringPassword,
        [string]$Vault
    )
    
    begin {
        if ([string]::IsNullOrWhiteSpace($password) -and (-not $secureStringPassword)) {
            Throw "Either Password or SecureStringPassword parameter needs to be specified"
        }

        if (-not [string]::IsNullOrWhiteSpace($password) -and $secureStringPassword) {
            Throw "Password and SecureStringPassword parameters cannot be both specified at the same time"
        }
    }
    
    process {
        $params = @{
            "Name" = "VISecret|"+$server+"|"+$User            
        }
         if ($password) {
            $params += @{"Secret" = $password} 
        } elseif ($secureStringPassword) {
            $params += @{"SecureStringSecret" = $secureStringPassword}
        } elseif ($Vault) {
            $params += @{"Vault" = $Vault} 
        }
        Set-Secret @params
    }
}
<#
.SYNOPSIS
Retrieves a credential from the secret store vault.

.DESCRIPTION
Retrieves a credential from the secret store vault.

.PARAMETER Server
The IP address or the hostname of the server to retrieve the credential for

.PARAMETER User
The username for which to retrieve the credential

.PARAMETER AsPlainText
Specifies that a credential should be returned as a String (in plain text) instead of a SecureString. 
To ensure security, you should avoid using plaintext strings whenever possible.

.PARAMETER Vault
The vault to retrieve the credential from. The default value is "VMwareSecretStore"

.EXAMPLE
PS C:\> $securePassword = Get-VISecret -Server 10.10.10.10 -User administrator@vsphere.local

Retrieves the password for the administrator@vsphere.local user on the 10.10.10.10 server from the secret vault
#>
function Get-VISecret {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Server,
        [Parameter(Mandatory=$true)]
        [string]$User,
        [switch]$AsPlainText,
        [string]$Vault
    )
    
    process {
        $params = @{
            "Name" = "VISecret|"+$server+"|"+$User            
        }
        if ($AsPlainText.IsPresent) {
            $params += @{"AsPlainText" = $AsPlainText.ToBool()} 
        } elseif ($Vault) {
            $params += @{"Vault" = $Vault} 
        }
        Get-Secret @params        
    }
}

<#
.SYNOPSIS
Removes a credential from the vault.

.DESCRIPTION
Removes a credential from the vault.

.PARAMETER Server
The IP address or the hostname of the server to remove the credential for

.PARAMETER User
The username for which to remove the credential

.PARAMETER Vault
The vault to remove the credential from. The default value is "VMwareSecretStore"

.EXAMPLE
PS C:\> Remove-VISecret -Server 10.10.10.10 -User administrator@vsphere.local

Removes the password for the administrator@vsphere.local user on the 10.10.10.10 server from the vault
#>
function Remove-VISecret {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Server,
        [Parameter(Mandatory=$true)]
        [string]$User,
        [string]$Vault
    )
    
    process {
        $params = @{
            "Name" = "VISecret|"+$server+"|"+$User            
        }
        if ($Vault) {
            $params += @{"Vault" = $Vault} 
        }
        Remove-Secret @params
    }
}

<#
.SYNOPSIS
This cmdlet establishes a connection to a vCenter Server system.

.DESCRIPTION
This cmdlet establishes a connection to a vCenter Server system. 
If a credential object or username and password the cmdlet uses them to connect and if the
-SaveCredential parameter is specified saves them in the vault. If only username
is specified the cmdlet uses the server name and the user name to search for the password in the 
vault. 

.PARAMETER Server
Specifies the IP address or the DNS name of the vSphere server to which you want to connect.

.PARAMETER User
Specifies the user name you want to use for authenticating with the server.

.PARAMETER Password
Specifies the password you want to use for authenticating with the server.

.PARAMETER Credential
Specifies a PSCredential object that contains credentials for authenticating with the server.

.PARAMETER AllLinked
Indicates whether you want to connect to vCenter Server in linked mode. If you specify $true 
for the -AllLinked parameter and the server to which you want to connect is a part of a federation 
vCenter Server, you'll be connected to all members of the linked vCenter Server. To use this 
option, PowerCLI must be configured to work in multiple servers connection mode. To configure 
PowerCLI to support multiple servers connection, specify Multiple for the DefaultVIServerMode 
parameter of the Set-PowerCLIConfiguration cmdlet.

.PARAMETER Force
Suppresses all user interface prompts during the cmdlet execution.

.PARAMETER NotDefault
Indicates that you do not want to include the server to which you connect into the $defaultVIServers variable.

.PARAMETER Port
Specifies the port on the server you want to use for the connection.

.PARAMETER Protocol
Specifies the Internet protocol you want to use for the connection. It can be either http or https.

.PARAMETER SaveCredentials
Indicates that you want to save the specified credentials in the vault.

.PARAMETER Vault
The vault to save the credential to. The default value is "VMwareSecretStore"

.EXAMPLE
Connect-VIServer -Server 10.10.10.10 -User administrator@vsphere.local

Connects to a vSphere server using the saved credential for the specified user

.EXAMPLE
Connect-VIServer -Server 10.10.10.10 -User administrator@vsphere.local -Password pass -SaveCredential

Connects to a vSphere server using the specified username and password and saves them in the vault
#>
function Connect-VIServerWithSecret {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Server,        
        [string]$User,
        [string]$Password,
        [pscredential]$Credential,
        [switch]$AllLinked,
        [switch]$Force,
        [switch]$NotDefault,
        [int]$Port,
        [string]$Protocol,
        [switch]$SaveCredentials,
        [string]$Vault
    )

    begin {
        if ([string]::IsNullOrWhiteSpace($User) -and (-not $Credential)) {
            if ($global:defaultUser) {
                $User = $global:defaultUser
            } else {
                Throw "Either User or Credential parameters needs to be specified"
            }
        }

        if ((-not [string]::IsNullOrWhiteSpace($User) -or -not [string]::IsNullOrWhiteSpace($Password)) -and $Credential) {
            Throw "User/Password and Credential parameters cannot be both specified at the same time"
        }
    }

    process {
        $params = @{
            "Server" = $Server
            "AllLinked" = $AllLinked
            "Force" = $Force
            "NotDefault" = $NotDefault
        }  
        if ($Protocol) {
            $params += @{"Protocol" = $Protocol}
        }
        if ($Port) {
            $params += @{"Port" = $Port}
        }
        if ($User) {
            if (-not $Password) {
                if ($Vault) {
                    $secret = Get-Secret -Name ("VISecret|"+$server+"|"+$User) -Vault $Vault -ErrorAction SilentlyContinue
                } else {
                    $secret = Get-Secret -Name ("VISecret|"+$server+"|"+$User) -ErrorAction SilentlyContinue
                }
                if (-not $secret) {
                    Throw "No password has been found for this server and user in the password vault"
                }
                $Credential = New-Object System.Management.Automation.PSCredential ($User, $secret)
            }
            else {
                $securePass = ConvertTo-SecureString -String $Password -AsPlainText
                $Credential = New-Object System.Management.Automation.PSCredential ($User, $securePass)
            }
        }
        $params += @{"Credential" = $Credential}
        Connect-VIServer @params
        if ($SaveCredentials) {
            New-VISecret -Server $Server -User $User -SecureStringPassword $Credential.Password -Vault $Vault
        }      
    }
}