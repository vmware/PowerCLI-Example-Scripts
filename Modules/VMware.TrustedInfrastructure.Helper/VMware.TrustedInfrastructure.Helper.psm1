# Script Module : VMware.TrustedInfrastructure.Helper
# Version       : 1.0

# Copyright © 2020 VMware, Inc. All Rights Reserved.

# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

$TrustedClusterSettingsFile =
-join((48..57 + 65..90 + 97..122) | get-random -count 6 | %{[char]$_})+".json"

$TrustAuthorityClusterSettingsFile =
-join((48..57 + 65..90 + 97..122) | get-random -count 6 | %{[char]$_})+".json"

Function Add-TrustAuthorityVMHost {
   <#
    .SYNOPSIS
       This cmdlet adds a new host into the specific Trust Authority cluster.
       There are some preconditions need to be met:
       1. The newly added host is cleared of any previous Trust Authority configurations
       2. The Trust Authority Cluster settings are all healthy
       3. The connection user has the needed privileges. Please, check vSphere documentation.
       4. The trust between Key Servers and TrustAuthorityKeyProvider uses the signed client certificate, user should provide its privateKey part
   .DESCRIPTION
       This cmdlet adds a new host into the specific Trust Authority cluster.
   .PARAMETER TrustAuthorityCluster
       Specifies the Trust Authority cluster you want to add the new host.
   .PARAMETER VMHostAddress
       Specifies the ip address of the new host you want to add to the specific Trust Authority cluster.
   .PARAMETER Credential
       Specifies the credential of the new host.
   .PARAMETER DestDir
       Specifies the location where you want to save the settings
   .PARAMETER PrivateKey
       Specifies the private key part of the ClientCertificate of the TrustAuthorityKeyProvider. It's a hashtable type with: the keyprovider.Name as the Key, and the File having the PrivateKey string for the ClientCertificate of the keyprovider as its Value.
   .PARAMETER BaseImageFolder
       Specifies the folder having all the baseImage files to re-create the TrustAuthorityVMHostBaseImage.
   .EXAMPLE
       PS C:\> $ts = Get-TrustAuthorityCluster "mycluster"
       PS C:\> $pass = Read-Host "Please enter the host's password" -AsSecureString
       PS C:\> $credential = New-Object System.Management.Automation.PSCredential -ArgumentList root,$pass
       PS C:\> $privateKeyHash = @{"provider1"="c:\myprivatekey.txt";}
       PS C:\> Add-TrustAuthorityVMHost -TrustAuthorityCluster $ts -VMHostAddress 1.1.1.1 -Credential $credential -DestDir c:\destDir\ -PrivateKey $privateKeyHash -BaseImageFolder "c:\baseImages\"
       Add the host 1.1.1.1 with the $credential to Trust Authority cluster "mycluster", also saves the setting file of the trustedcluster "mycluster" to folder c:\destDir\.
   .EXAMPLE
       PS C:\> $ts = Get-TrustAuthorityCluster "mycluster"
       PS C:\> Add-TrustAuthorityVMHost -TrustAuthorityCluster $ts -VMHostAddress 1.1.1.1 -Credential root -DestDir c:\destDir\ -BaseImageFolder "c:\baseImages\"
       Add the host 1.1.1.1 with the credential root (a window wizard will be prompted to let you input the password for the user root) to Trust Authority cluster "mycluster", also saves the setting file of the trustedcluster "mycluster" to folder c:\destDir\.
   .NOTES
       Author                                    : Carrie Yang
       Author email                              : yangm@vmware.com
   #>

   [CmdLetBinding()]

   Param (
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
      [VMware.VimAutomation.Security.Types.V1.TrustedInfrastructure.TrustAuthorityCluster] $TrustAuthorityCluster,

      [Parameter(Mandatory=$True)]
      [String] $VMHostAddress,

      [Parameter(Mandatory=$True)]
      [System.Management.Automation.Credential()]
      $Credential,

      [Parameter(Mandatory=$True)]
      [String] $DestDir,

      [hashtable] $PrivateKey,

      [Parameter(Mandatory=$True)]
      [String] $BaseImageFolder
   )

   Begin {
      Write-Warning "Please confirm the new host to add is cleared from any previous Trust Authority Configurations." -WarningAction Inquire

      Write-Warning "Please confirm the connection user has the privilege to add the new host to the cluster $($TrustAuthorityCluster.Name)." -WarningAction Inquire

      Write-Warning "Please confirm the connection user has been added to 'TrustedAdmins' group." -WarningAction Inquire

      $server = GetViServer -clusterUid $TrustAuthorityCluster.Uid

      ConfirmIsVCenter $server

      Check-VMHostVersionAndLicense -VMHostName $VMHostAddress -Credential $Credential -CheckLicense:$false -ErrorAction Stop
      $DestinationFile =  Join-Path $destDir $TrustAuthorityClusterSettingsFile
      Write-Verbose "The file to save settings is $DestinationFile"

      Check-TrustAuthorityClusterHealth -TrustAuthorityCluster $TrustAuthorityCluster
      IsSelfSignedClientCertificate -TrustAuthorityCluster $TrustAuthorityCluster -privateKey $privateKey
   }

   Process {
      Save-TrustAuthorityClusterSettings -TrustAuthorityCluster $TrustAuthorityCluster -DestinationFile $DestinationFile -ErrorAction Stop

      Join-VMHost -ClusterName $TrustAuthorityCluster.Name -VMHostAddress $VMHostAddress -Credential $Credential -Server $server -ErrorAction Stop
      Apply-TrustAuthorityClusterSettings -TrustAuthorityCluster $TrustAuthorityCluster -SettingsFile $DestinationFile -BaseImageFolder $baseImageFolder -PrivateKey $privateKey -ErrorAction Stop
   }
}

Function Add-TrustedVMHost {
   <#
   .SYNOPSIS
       This cmdlet adds a new host into the specific trusted cluster.
       There are some preconditions need to be met:
       1. No active workloads in the workload host as the cmdlet will interrup the workloads
       2. The newly added host is cleared of any previous Trust Authority Configurations
       3. Sufficient license
       For vCenter Server 7.0.1 and above, use 'Set-TrustedCluster -Remediate' to remediate the trusted cluster after adding a new host directly.
   .DESCRIPTION
       This cmdlet adds a new host into the specific Trusted cluster.
   .PARAMETER TrustedCluster
       Specifies the Trusted cluster you want to add the new host.
   .PARAMETER VMHostAddress
       Specifies the ip address of the new host you want to add to the specific Trusted cluster.
   .PARAMETER Credential
       Specifies the credential of the new host.
   .PARAMETER DestDir
       Specifies the location where you want to save the settings
   .EXAMPLE
       PS C:\> $ts = Get-TrustedCluster "mycluster"
       PS C:\> $pass = Read-Host "Please enter the host's password" -AsSecureString
       PS C:\> $credential = New-Object System.Management.Automation.PSCredential -ArgumentList root,$pass
       PS C:\> Add-TrustedVMHost -TrustedCluster $ts -VMHostAddress 1.1.1.1 -Credential $credential -DestDir c:\destDir\
       Add the host 1.1.1.1 with the $credential to Trusted Cluster "mycluster", also saves the setting file of the trustedcluster "mycluster" to folder c:\destDir\.
   .EXAMPLE
       PS C:\> $ts = Get-TrustedCluster "mycluster"
       PS C:\> Add-TrustedVMHost -TrustedCluster $ts -VMHostAddress 1.1.1.1 -Credential root -DestDir c:\destDir\
       Add the host 1.1.1.1 with the credential root (a window wizard will be prompted to let you input the password for the user root) to Trusted Cluster "mycluster", also saves the setting file of the trustedcluster "mycluster" to folder c:\destDir\.
   .NOTES
       Author                                    : Carrie Yang
       Author email                              : yangm@vmware.com
   #>

   [CmdLetBinding()]

   Param (
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
      [VMware.VimAutomation.Security.Types.V1.TrustedInfrastructure.TrustedCluster] $TrustedCluster,

      [Parameter(Mandatory=$True)]
      [String] $VMHostAddress,

      [Parameter(Mandatory=$True)]
      [System.Management.Automation.Credential()]
      $Credential,

      [Parameter(Mandatory=$True)]
      [String] $DestDir
   )

   Begin {
      Write-Warning "Please confirm workload cluster has no currently active workloads! This operation will interrupt the active crypto operations." -WarningAction Inquire

      Write-Warning "Please confirm the new host to add is cleared from any previous Trust Authority Configurations." -WarningAction Inquire

      Write-Warning "Please confirm the connection user has the privilege to add the new host to the cluster $($TrustedCluster.Name)." -WarningAction Inquire

      Write-Warning "Please confirm the connection user has been added to 'TrustedAdmins' group." -WarningAction Inquire

      $server = GetViServer -clusterUid $TrustedCluster.Uid
      Write-Verbose "The server got is: $server"
      ConfirmIsVCenter $server

      if (Is70AboveServer -VIServer $server) {
         Throw "Use 'Set-TrustedCluster -Remediate' cmdlet from VMware.VimAutomation.Security module."
      }

      Check-VMHostVersionAndLicense -VMHostName $VMHostAddress -Credential $Credential -CheckLicense:$true -Allow70Above $false
      $DestinationFile =  Join-Path $DestDir $TrustedClusterSettingsFile
      Write-Verbose "The file to save settings is $DestinationFile"
   }

   Process {
      Check-TrustedClusterSettings -TrustedCluster $TrustedCluster -ErrorAction Stop
      Save-TrustedClusterSettings -TrustedCluster $TrustedCluster -DestinationFile $DestinationFile -ErrorAction Stop
      Remove-TrustedClusterSettings -TrustedCluster $TrustedCluster -ErrorAction Stop
      Join-VMHost -ClusterName $TrustedCluster.Name -VMHostAddress $VMHostAddress -Credential $Credential -Server $server -ErrorAction Stop
      Apply-TrustedClusterSettings -TrustedCluster $TrustedCluster -SettingsFile $DestinationFile -ErrorAction Stop
   }
}

Function Save-TrustedClusterSettings {
   <#
   .SYNOPSIS
       This cmdlet saves the settings of the specific Trusted Cluster to the file $DestinationFile.
   .DESCRIPTION
       This cmdlet saves the settings of the specific Trusted Cluster to the file $DestinationFile.
   .PARAMETER TrustedCluster
       Specifies the Trusted Cluster you want to save the settings.
   .PARAMETER DestinationFile
       Specifies the file you want to save the settings to.
   .EXAMPLE
       PS C:\> $ts = Get-TrustedCluster "mycluster"
       PS C:\> Save-TrustedClusterSettings -TrustedCluster $ts -DestinationFile "c:\myfile.json"
       Saves the settings of Trusted Cluster "mycluster" to file c:\myfile.json.
   .NOTES
       Author                                    : Carrie Yang
       Author email                              : yangm@vmware.com
   #>

   [CmdLetBinding()]

   Param (
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
      [VMware.VimAutomation.Security.Types.V1.TrustedInfrastructure.TrustedCluster] $TrustedCluster,

      [Parameter(Mandatory=$True)]
      [String] $DestinationFile
   )

   Begin {
      $greenvc = GetViServer -clusterUid $TrustedCluster.Uid
      Write-Host "Saving the settings of TrustedCluster $($TrustedCluster.Name)..."
   }

   Process {
      $TrustedCluster = Get-TrustedCluster $TrustedCluster.Name -Server $greenvc

      $TrustedClusterjson = @"
      {
        "VC": "",
        "TrustedCluster":
        {
          "Name": "$($TrustedCluster.Name)",
          "AttestationServiceInfo": [],
          "KeyProviderServiceInfo": []
          }
        }
"@
      $attestInfo = $TrustedCluster.AttestationServiceInfo
      $keyproviderInfo = $TrustedCluster.KeyProviderServiceInfo
      $jsonObj = ConvertFrom-Json -InputObject $TrustedClusterjson
      $jsonObj.VC = $greenvc
      $jsonObj.TrustedCluster.AttestationServiceInfo = $attestInfo
      $jsonObj.TrustedCluster.KeyProviderServiceInfo = $keyproviderInfo

      $jsonObj | ConvertTo-Json | Out-File $DestinationFile -Force
   }
}

Function Save-TrustAuthorityClusterSettings {
   <#
   .SYNOPSIS
       This cmdlet saves the settings of the specific Trust Authority Cluster to the file $DestinationFile.
   .DESCRIPTION
       This cmdlet saves the settings of the specific Trust Authority Cluster to the file $DestinationFile.
   .PARAMETER TrustedCluster
       Specifies the Trust Authority Cluster you want to save the settings.
   .PARAMETER DestinationFile
       Specifies the file you want to save the settings to.
   .EXAMPLE
       PS C:\> $ts = Get-TrustAuthorityCluster "mycluster"
       PS C:\> Save-TrustAuthorityClusterSettings -TrustAuthorityCluster $ts -DestinationFile "c:\myfile.json"
       Saves the settings of Trust Authority Cluster "mycluster" to file c:\myfile.json.
   .NOTES
       Author                                    : Carrie Yang
       Author email                              : yangm@vmware.com
   #>

   [CmdLetBinding()]

   Param (
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
      [VMware.VimAutomation.Security.Types.V1.TrustedInfrastructure.TrustAuthorityCluster] $TrustAuthorityCluster,

      [Parameter(Mandatory=$True)]
      [String] $DestinationFile
   )

   Begin {
      $bluevc = GetViServer -clusterUid $TrustAuthorityCluster.Uid
      Write-Host "Saving the settings of TrustAuthorityCluster $($TrustAuthorityCluster.Name)..."
   }

   Process {
      $json = @"
      {
         "VC": "",
         "TrustAuthorityCluster": {
            "Name": "",
            "TrustAuthorityPrincipal": [],
            "TrustAuthorityKeyProvider": [],
            "TrustAuthorityVMHostBaseImage": [],
            "TrustAuthorityTpm2AttestationSettings": {},
            "TrustAuthorityTpm2CACertificate": [],
            "TrustAuthorityTpm2EndorsementKey": []
         }
      }
"@
      $jsonObj = ConvertFrom-Json -InputObject $json
      $jsonObj.VC = $bluevc
      $jsonObj.TrustAuthorityCluster.Name = $TrustAuthorityCluster.Name
      $kp = Get-TrustAuthorityKeyProvider -Cluster $TrustAuthorityCluster -Server $bluevc

      $i = 0

      if ($kp -ne $null) {
         $jsonObj.TrustAuthorityCluster.TrustAuthorityKeyProvider = $kp | Select-Object -Property Name, PrimaryKeyId, Description, ProxyAddress, ProxyPort, ConnectionTimeoutSeconds, KmipServerUsername
         $clientCert = @{}
         $serverCert = @{}
         $clientCSR = @{}
      }

      $kp | Foreach-Object {
         $kps = Get-TrustAuthorityKeyProviderServer -KeyProvider $_  -Server $bluevc| Select-Object -Property Address, Port, Name
         $clientCertTemp = Get-TrustAuthorityKeyProviderClientCertificate -KeyProvider $_ -Server $bluevc
         $clientCertStr = [System.Convert]::ToBase64String($($clientCertTemp.GetRawCertData()))
         $serverCertTemp = Get-TrustAuthorityKeyProviderServerCertificate -KeyProvider $_ -Server $bluevc | Select-Object -Property CertificateRawData, Trusted
         $clientCSRTemp = Get-TrustAuthorityKeyProviderClientCertificateCSR -KeyProvider $_ -Server $bluevc

         $jsonObj.TrustAuthorityCluster.TrustAuthorityKeyProvider[$i] | Add-Member -Name "KmipServers" -value $kps -MemberType NoteProperty
         $jsonObj.TrustAuthorityCluster.TrustAuthorityKeyProvider[$i] | Add-Member -Name "ClientCertificate" -value $clientCertStr -MemberType NoteProperty
         $jsonObj.TrustAuthorityCluster.TrustAuthorityKeyProvider[$i] | Add-Member -Name "ClientCertificateCSR" -value $clientCSRTemp -MemberType NoteProperty
         $jsonObj.TrustAuthorityCluster.TrustAuthorityKeyProvider[$i] | Add-Member -Name "ServerCertificate" -value $serverCertTemp -MemberType NoteProperty
         $i++

         if ($clientCertTemp -ne $null) {
            $clientCert.Add($_.Name, $clientCertTemp)
         }

         if ($serverCertTemp -ne $null) {
            $serverCert.Add($_.Name, $serverCertTemp)
         }

         if (![string]::IsNullOrWhiteSpace($clientCSRTemp)) {
            $clientCSR.Add($_.Name, $clientCSRTemp)
         }
      }

      $principals = Get-TrustAuthorityPrincipal -Cluster $TrustAuthorityCluster -Server $bluevc| Select-Object -Property Name, Issuer, Domain, Type, IssuerAlias, certRawData

      $tpm2Settings = Get-TrustAuthorityTpm2AttestationSettings -Cluster $TrustAuthorityCluster -Server $bluevc | Select-Object -Property RequireEndorsementKey, RequireCertificateValidation
      $tpm2CA = Get-TrustAuthorityTpm2CACertificate -Cluster $TrustAuthorityCluster -Server $bluevc
      $tpm2Ek = Get-TrustAuthorityTpm2EndorsementKey -Cluster $TrustAuthorityCluster -Server $bluevc
      $baseImages = Get-TrustAuthorityVMHostBaseImage -Cluster $TrustAuthorityCluster -Server $bluevc

      $jsonObj.VC = GetViServer -clusterUid $TrustAuthorityCluster.Uid
      $jsonObj.TrustAuthorityCluster.TrustAuthorityPrincipal = $principals

      $jsonObj.TrustAuthorityCluster.TrustAuthorityTpm2AttestationSettings = $tpm2Settings

      $jsonObj.TrustAuthorityCluster.TrustAuthorityTpm2CACertificate = $tpm2CA | Select-Object -Property Name

      $i = 0
      $tpm2CA | Foreach-Object {
         $certStr = ConvertFrom-X509Chain -CertChain $_.CertificateChain
         $jsonObj.TrustAuthorityCluster.TrustAuthorityTpm2CACertificate[$i] | Add-Member -Name "certRawData" -value $certStr -MemberType NoteProperty

         $i++
      }

      $jsonObj.TrustAuthorityCluster.TrustAuthorityTpm2EndorsementKey = $tpm2Ek
      $jsonObj.TrustAuthorityCluster.TrustAuthorityVMHostBaseImage = $baseImages

      $jsonObj | ConvertTo-Json -Depth 6 | Out-File $DestinationFile -Force
   }
}

Function Apply-TrustAuthorityClusterSettings {
   <#
   .SYNOPSIS
       This cmdlet applies the settings in the specific $SettingsFile to a Trust Authority Cluster.
       Here are some limitations when applying the TrustAuthorityKeyProvider Settings:
       - The CSR configuration will not be preserved, user needs to reset the CSR and get it signed by the Key Server, then retrieve the signed client certificate to set it back to TrustAuthorityKeyProvider
       - If self signed certificates are used for trust setup, they need to be redone on new host.
   .DESCRIPTION
       This cmdlet applies the settings in the specific $SettingsFile to a Trust Authority Cluster
   .PARAMETER TrustAuthorityCluster
       Specifies the Trust Authority Cluster you want to apply the settings
   .PARAMETER SettingsFile
       Specifies the file having the settings you want to apply
   .PARAMETER PrivateKey
      Specifies the private key part of the ClientCertificate of the TrustAuthorityKeyProvider. It is a hashtable type with: the Key is the TrustAuthorityKeyProvider.Name, and the Value is the filePath for the TrustAuthorityKeyProvider's ClientCertificate PrivateKey part.
   .PARAMETER BaseImageFolder
      Specifies the folder having all the baseImage files to re-create the TrustAuthorityVMHostBaseImage. All the .tgz files under this folder and its sub-folders will be used to re-create TrustAuthorityVMHostBaseImage objects.
   .EXAMPLE
      PS C:\> $privateKeyHash = @{"provider1"="c:\myprivatekey.txt";}
      PS C:\> $ts = Get-TrustAuthorityCluster "mycluster"
      PS C:\> Apply-TrustAuthorityClusterSettings -TrustAuthorityCluster $ts -SettingsFile "c:\myfile.json"  -PrivateKey $privateKeyHash -BaseImageFolder "c:\myimages\"
       Applies the settings in file c:\myfile.json to Trust Authority Cluster "mycluster" with all the baseimage files under c:\myimages\ recursively, and cmdlet will prompt for inputting the password for each TrustAuthorityKeyProvider, also the PrivateKey info saved in c:\myprivatekey.txt will be used for the TrustAuthorityKeyProvider provider1.
   .NOTES
       Author                                    : Carrie Yang
       Author email                              : yangm@vmware.com
   #>

   [CmdLetBinding()]

   Param (
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
      [VMware.VimAutomation.Security.Types.V1.TrustedInfrastructure.TrustAuthorityCluster] $TrustAuthorityCluster,

      [Parameter(Mandatory=$True)]
      [String] $SettingsFile,

      [hashtable] $PrivateKey,

      [String] $BaseImageFolder
   )

   Begin {
      Write-Host "Applying the saved settings to TrustAuthorityCluster $($TrustAuthorityCluster.Name)..."
   }

   Process {
      Set-TrustAuthorityCluster -TrustAuthorityCluster $TrustAuthorityCluster -State Enabled -Confirm:$false
      $blueserver = GetViServer -clusterUid $TrustAuthorityCluster.Uid

      $jsonObj = Get-Content $SettingsFile | Out-String |ConvertFrom-Json
      if ($($jsonObj.TrustAuthorityCluster.Name) -ne $($TrustAuthorityCluster.Name)) {
         Write-Warning "Wrong TrustAuthorityCluster or wrong json file provided, the json file is not for the TrustAuthorityCluster: $($TrustAuthorityCluster.Name)"
      }

      $kp = $jsonObj."TrustAuthorityCluster".TrustAuthorityKeyProvider
      $principals =  $jsonObj."TrustAuthorityCluster".TrustAuthorityPrincipal
      $tpm2Setting =  $jsonObj."TrustAuthorityCluster".TrustAuthorityTpm2AttestationSettings
      $tpm2CA =  $jsonObj."TrustAuthorityCluster".TrustAuthorityTpm2CACertificate
      $tpm2Ek =  $jsonObj."TrustAuthorityCluster".TrustAuthorityTpm2EndorsementKey
      $baseImages =  $jsonObj."TrustAuthorityCluster".TrustAuthorityVMHostBaseImage

      if ($kp -ne $null) {
         $kp | Foreach-Object {
            $provider = $_
            $kps =  $provider.KmipServers
            $cmd = "New-TrustAuthorityKeyProvider"
            $allArgs = @{
               'TrustAuthorityCluster' = $TrustAuthorityCluster;
               'Name' = $provider.Name;
               'PrimaryKeyId' = $provider.PrimaryKeyId;
               'KmipServerName' = $kps[0].Name;
               'KmipServerAddress' = $kps[0].Address;
               'KmipServerPort' = $kps[0].Port;
               'Server' = $blueserver;
            }

            if (![String]::IsNullOrWhiteSpace($provider.Description)) {
               $allArgs += @{'Description' = $provider.Description;}
            }

            if (![String]::IsNullOrWhiteSpace($provider.ProxyAddress)) {
               $allArgs += @{'ProxyAddress' = $provider.ProxyAddress;}
            }

            if (![String]::IsNullOrWhiteSpace($provider.ProxyPort)) {
               $allArgs += @{'ProxyPort' = $provider.ProxyPort;}
            }

            if (![String]::IsNullOrWhiteSpace($provider.ConnectionTimeOutSeconds)) {
               $allArgs += @{'ConnectionTimeOutSeconds' = $provider.ConnectionTimeOutSeconds;}
            }

            if (![String]::IsNullOrWhiteSpace($provider.KmipServerUsername)) {
               $allArgs += @{'KmipServerUsername' = $provider.KmipServerUsername;}
            }

            & $cmd @allArgs

            if (($kps | Measure-Object).Count -gt 1) {
               for ($i = 1; $i -gt ($kps | Measure-Object).Count; $i++) {
                  LogAndRunCmdlet {Add-TrustAuthorityKeyProviderServer -KeyProvider $provider.Name -TrustAuthorityCluster $TrustAuthorityCluster -Address $kps[$i].Address -Name $kps[$i].Name -Port $kps[$i].Port -Server $blueserver -ErrorAction:Continue}
               }
            }

            if (![String]::IsNullOrWhiteSpace($($_.ClientCertificateCSR))) {
               Write-Warning "CSR configuration won't be preserved, please manually establish the trust between kmip servers and trust authority keyprovider: $($_.Name)"
            }

            if ($provider.ClientCertificate -ne $null) {
               if ($privateKey -ne $null -and $privateKey.ContainsKey($($provider.Name))) {
                  $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                  $cert.Import([System.Text.Encoding]::Default.GetBytes($provider.ClientCertificate))
                  try {
                     $pkStr = [System.IO.File]::ReadAllText($privateKey.$($provider.Name))
                  } catch {
                     Throw "Failed to read privateKey file: $($privateKey.$($_.Name))"
                  }

                  $cmd = {Set-TrustAuthorityKeyProviderClientCertificate -KeyProvider $provider.Name -TrustAuthorityCluster $TrustAuthorityCluster -Certificate $cert -PrivateKey $privateKey.$($provider.Name) -Server $blueserver -ErrorAction:Continue}
                  LogAndRunCmdlet $cmd
               } else {
                  LogAndRunCmdlet {New-TrustAuthorityKeyProviderClientCertificate -KeyProvider $provider.Name -TrustAuthorityCluster $TrustAuthorityCluster -Server $blueserver -ErrorAction:Continue}
               }
            }

            if ($_.ServerCertificate -ne $null) {
               $trustedcerts = [System.Collections.ArrayList]@()
               $provider.ServerCertificate | Foreach-Object {
                  $certStr = $_
                  $tempStr = $certStr.CertificateRawData
                  if ($certStr.Trusted) {
                     $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                     $cert.Import([System.Text.Encoding]::Default.GetBytes($tempStr))
                     $trustedcerts.Add($cert) | Out-Null
                  }
               }

               $cmd = {Set-TrustAuthorityKeyProviderServerCertificate -KeyProvider $provider.Name -TrustAuthorityCluster $TrustAuthorityCluster -Certificate $trustedcerts -Server $blueserver -ErrorAction:Continue}
               LogAndRunCmdlet $cmd
            }

            $kmipPwd = Read-Host "Enter the password of Trust Authority Key Provider $($_.Name) (Return if none)" -AsSecureString

            if ($kmipPwd.Length -gt 0) {
               LogAndRunCmdlet {Set-TrustAuthorityKeyProvider -KeyProvider $provider.Name -TrustAuthorityCluster $TrustAuthorityCluster -KmipServerPassword $kmipPwd -Server $blueserver -ErrorAction:Continue}
            }
         }
      }

      if ($tpm2Setting -ne $null) {
         $cmd = {Set-TrustAuthorityTpm2AttestationSettings -RequireCertificateValidation:$tpm2Setting.RequireCertificateValidation -RequireEndorsementKey:$tpm2Setting.RequireEndorsementKey -TrustAuthorityCluster $TrustAuthorityCluster -Server $blueserver -Confirm:$false -ErrorAction:Continue}
         LogAndRunCmdlet $cmd
      }

      if ($tpm2CA -ne $null) {
         $tpm2CA | Foreach-Object {
            $ca = $_
            $chain = ConvertTo-X509Chain $ca.certRawData
            $cmd = {New-TrustAuthorityTpm2CACertificate -TrustAuthorityCluster $TrustAuthorityCluster -CertificateChain $chain -Name $ca.Name -Server $blueserver -Confirm:$false -ErrorAction:Continue}
            LogAndRunCmdlet $cmd
         }
      }

      if ($tpm2Ek -ne $null) {
         $tpm2Ek | Foreach-Object {
            $ek = $_
            $publicKey = $ek.PublicKey
            $cmd = {New-TrustAuthorityTpm2EndorsementKey -TrustAuthorityCluster $TrustAuthorityCluster -Name $ek.Name -PublicKey $publicKey -Server $blueserver -Confirm:$false -ErrorAction:Continue}
            LogAndRunCmdlet $cmd
         }
      }

      if ($baseImages -ne $null) {
         $cmd = {New-TrustAuthorityVMHostBaseImage -TrustAuthorityCluster $TrustAuthorityCluster -FilePath $baseImageFolder -Server $blueserver -Confirm:$false -ErrorAction:Continue}
         LogAndRunCmdlet $cmd
      }

      if ($principals -ne $null) {
         $errorBeforeExecution = $Global:error.Clone()
         $Global:error.Clear()
         $principals | Foreach-Object {
            $p = $_
            $chainList = [System.Collections.ArrayList]@()
            $p.certRawData | Foreach-Object {
               $str = $_
               $chain = ConvertTo-X509Chain -certString $str
               $chainList.Add($chain) | Out-Null
            }

            $cmd = {New-TrustAuthorityPrincipal -TrustAuthorityCluster $TrustAuthorityCluster -Name $p.Name -Domain $p.Domain -Issuer $p.Issuer -CertificateChain $chainList -Type $p.Type -Server $blueserver -Confirm:$false -ErrorAction:Continue}
            $newPrincipal = LogAndRunCmdlet $cmd
            CheckNewTrustAuthorityPrincipalResult -TAPrincipal $newPrincipal
         }
         $Global:error.AddRange($errorBeforeExecution)
      }
   }
}


Function Apply-TrustedClusterSettings {
   <#
   .SYNOPSIS
       This cmdlet applies the settings in the specific $SettingsFile to a Trusted Cluster.
   .DESCRIPTION
       This cmdlet applies the settings in the specific $SettingsFile to a Trusted Cluster
   .PARAMETER TrustedCluster
       Specifies the Trusted Cluster you want to apply the settings.
   .PARAMETER SettingsFile
       Specifies the file having the settings you want to apply.
   .EXAMPLE
       PS C:\> $ts = Get-TrustedCluster "mycluster"
       PS C:\> Apply-TrustedClusterSettings -TrustedCluster $ts -SettingsFile "c:\myfile.json"
       Applies the settings in file c:\myfile.json to Trusted Cluster "mycluster".
   .NOTES
       Author                                    : Carrie Yang
       Author email                              : yangm@vmware.com
   #>

   [CmdLetBinding()]

   Param (
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
      [VMware.VimAutomation.Security.Types.V1.TrustedInfrastructure.TrustedCluster] $TrustedCluster,

      [Parameter(Mandatory=$True)]
      [String] $SettingsFile
   )

   Begin {
      $greenvc = GetViServer -clusterUid $TrustedCluster.Uid
      Write-Host "Applying the saved settings to TrustedCluster $($TrustedCluster.Name)..."
   }

   Process {
      $jsonObj = Get-Content $SettingsFile | ConvertFrom-Json

      if ($($jsonObj.TrustedCluster.Name) -ne $($TrustedCluster.Name)) {
         Write-Warning "Wrong trustedcluster or wrong json file provided, the json file is not for the trustedcluster: $($TrustedCluster.Name)"
      }

      if ($jsonObj.TrustedCluster.AttestationServiceInfo -ne $null) {
         $attests = Get-AttestationServiceInfo -Server $greenvc | Where-Object {$($_.Name) -in $($jsonObj.TrustedCluster.AttestationServiceInfo)}
         $cmd = {Add-TrustedClusterAttestationServiceInfo -TrustedCluster $TrustedCluster -AttestationServiceInfo $attests -Confirm:$false -Server $greenvc -ErrorAction:Continue}
         LogAndRunCmdlet $cmd
      }

      if ($jsonObj.TrustedCluster.KeyProviderServiceInfo -ne $null) {
         $kms = Get-KeyProviderServiceInfo -Server $greenvc | Where-Object {$($_.Name) -in $($jsonObj.TrustedCluster.KeyProviderServiceInfo)}
         $cmd = {Add-TrustedClusterKeyProviderServiceInfo -TrustedCluster $TrustedCluster -KeyProviderServiceInfo $kms -Confirm:$false -Server $greenvc -ErrorAction:Continue}
         LogAndRunCmdlet $cmd
      }
   }
}

Function LogAndRunCmdlet {
   [CmdLetBinding()]

   Param (
      [Parameter(Mandatory=$True)]
      [ScriptBlock] $CmdBlock
   )

   Process {
      Write-Host "Running cmdlet: $CmdBlock"
      & $CmdBlock
   }
}

Function CheckNewTrustAuthorityPrincipalResult {

   [CmdLetBinding()]

   Param (
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][AllowNull()]
      [VMware.VimAutomation.Security.Types.V1.TrustedInfrastructure.TrustAuthorityPrincipal] $TAPrincipal
   )

   Begin {
      $expectedCmdName = "NewTrustAuthorityPrincipal"
      $expectedError = "com.vmware.esx.authentication.trust.security_token_issuers.issuer_already_exists"
   }

   Process {
      $err = $Global:Error[0]

      if (($TAPrincipal -eq $null) -and ($($err.Exception.TargetSite.Name) -eq $expectedCmdName)) {
         if ($($err.Exception.InnerException) -match $expectedError) {
            Write-Error "Operation didn't complete successfully. This is a known issue. Refer to https://kb.vmware.com/s/article/77146 to recover the host, then rerun New-TrustAuthorityPrincipal cmdlet to create the TrustAuthorityPrincipal for the new host please."
         }
      } elseif ($TAPrincipal) {
         $TAPrincipal
      }
   }
}

Function Join-VMHost {
   Param (
      [Parameter(Mandatory=$True)]
      [String] $ClusterName,

      [Parameter(Mandatory=$True)]
      [String] $VMHostAddress,

      [Parameter(Mandatory=$True)]
      [System.Management.Automation.Credential()]
      $Credential,

      [Parameter(Mandatory=$True)]
      [ValidateNotNullOrEmpty()]
      [String] $Server
   )

   Process {
      Write-Host "Adding new host $VMHostAddress to cluster $ClusterName..."
      Add-VMHost -Name $VMHostAddress -Credential $Credential -Location $ClusterName -Server $Server -Force
   }
}

Function Remove-TrustedClusterSettings {
   [CmdLetBinding()]

   Param (
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
      [VMware.VimAutomation.Security.Types.V1.TrustedInfrastructure.TrustedCluster] $TrustedCluster
   )

   Begin {
      $greenvc = GetViServer -clusterUid $TrustedCluster.Uid
      Write-Host "Removing the settings of TrustedCluster $($TrustedCluster.Name)..."
      $TrustedCluster = Get-TrustedCluster $TrustedCluster.Name -Server $greenvc
   }

   Process {
      if ($TrustedCluster.State -eq 'Enabled') {
         Set-TrustedCluster -TrustedCluster $TrustedCluster -State Disabled -Server $greenvc -Confirm:$false
      } else {
         if ($TrustedCluster.KeyProviderServiceInfo -ne $null) {
            Remove-TrustedClusterKeyProviderServiceInfo -TrustedCluster $TrustedCluster -KeyProviderServiceInfo $TrustedCluster.KeyProviderServiceInfo -Server $greenvc -Confirm:$false
         }
      }
   }
}


Function IsSelfSignedClientCertificate {
   [CmdLetBinding()]

   Param (
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
      [VMware.VimAutomation.Security.Types.V1.TrustedInfrastructure.TrustAuthorityCluster] $TrustAuthorityCluster,

      [hashtable] $privateKey
   )

   Begin {
      $bluevc = GetViServer -clusterUid $TrustAuthorityCluster.Uid
   }

   Process {
      $kp = Get-TrustAuthorityKeyProvider -TrustAuthorityCluster $TrustAuthorityCluster -Server $bluevc

      $privateKeyNotSet = $False
      $kpNames = [System.Collections.ArrayList]@()
      if ($kp -ne $null) {
         $kp | Foreach-Object {
            $k = $_
            $clientCert = Get-TrustAuthorityKeyProviderClientCertificate -KeyProvider $k -TrustAuthorityCluster $TrustAuthorityCluster -Server $bluevc
            if ($clientCert -ne $null -and !($privateKey -ne $null -and $privateKey.ContainsKey($($k.Name)))) {
               $privateKeyNotSet = $True
               $kpNames.Add($k.Name) | Out-Null
            }
         }
      }

      if ($privateKeyNotSet) {
         $kpnameStr = [System.String]::join(",", $($kpNames))
         Write-Warning "For self-signed client certificate, the cmdlet might not be able to establish the trust between the kmip servers and the keyprovider: ($kpnameStr). `nManually try to use followed cmdlets to establish the trust: `n 1. New-TrustAuthorityKeyProviderClientCertificate;`n 2. Get-TrustAuthorityKeyProviderClientCertificate; `n then make the certificate be signed in kmip servers." -WarningAction Inquire
      }
   }
}

Function Is70AboveServer {
   Param (
      [Parameter(Mandatory=$True)]
      [ValidateNotNullOrEmpty()]
      [String] $VIServer
   )

   Process {
      if ([String]::IsNullOrWhiteSpace($VIServer)) {
         Throw "Please provide a valid vCenter Server!"
      }

      $SI = Get-View Serviceinstance -Server $VIServer
      $apiVersion = [System.Version]$($SI.Content.About.Version)
      $MajorVersion = $apiVersion.Major
      $MinorVersion = $apiVersion.Minor
      $buildNum = $apiVersion.Build

      if (($MajorVersion -lt 7) -or ($MajorVersion -eq 7 -And $MinorVersion -eq 0 -And $buildNum -eq 0)) {
         return $false
      }

      return $true
   }
}


Function Check-VMHostVersionAndLicense {
    [CmdLetBinding()]

    Param (
       [Parameter(Mandatory=$True)]
       [String] $VMHostName,

       [Parameter(Mandatory=$True)]
       [System.Management.Automation.Credential()]
       $Credential,

       [Parameter(Mandatory=$True)]
       [bool]$CheckLicense,

       [bool]$Allow70Above=$true
    )

    Begin {
       Write-Host "Checking the version of the vmhost $VMHostName..."
    }

    Process {
       $server = Connect-VIServer -Server $VMHostName -Credential $Credential -ErrorAction:Stop

       $vmhost = Get-VMHost -server $server

       $apiVersion = [System.Version]$($vmhost.ApiVersion)
       $MajorVersion = $apiVersion.Major
       $MinorVersion = $apiVersion.Minor
       $buildNum = $apiVersion.Build

       if (!$Allow70Above) {
          if ($MajorVersion -ne 7 -or $MinorVersion -ne 0 -or $buildNum -ne 0) {
             Disconnect-VIServer -Server $server -confirm:$false
             Throw "VMHost of $apiVersion is not supported, only 7.0.0 is supported...`n"
          }
       } else {
          if ($MajorVersion -lt 7) {
             Disconnect-VIServer -Server $server -confirm:$false
             Throw "VMHost of $apiVersion is not supported, only 7.0.0 and above are supported...`n"
          }
       }

       # Check license
       if ($CheckLicense) {
          Write-Host "Checking the license of the vmhost $VMHostName..."
          $si = Get-View serviceinstance -Server $server
          $lm = Get-View $si.Content.LicenseManager
          $a = $lm.Licenses.Properties.Value | Where-Object {"trustedplatform" -in $_.Key}
          if ($a -eq $null) {
             Disconnect-VIServer -Server $server -confirm:$false
             Throw "VMHost $VMHostName has no sufficient license to be configured as trusted infrastructure host...`n"
          }
       }

       Disconnect-VIServer -Server $server -confirm:$false
    }
}

Function Check-TrustAuthorityClusterHealth {
    [CmdLetBinding()]

    Param (
       [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
       [VMware.VimAutomation.Security.Types.V1.TrustedInfrastructure.TrustAuthorityCluster] $TrustAuthorityCluster
    )

    Begin {
       $bluevc = GetViServer -clusterUid $TrustAuthorityCluster.Uid
    }

    Process {
       Write-Host "Checking the healthy status of TrustAuthorityCluster $($TrustAuthorityCluster.Name)..."
       $TrustAuthorityCluster = Get-TrustAuthorityCluster -Name $TrustAuthorityCluster.Name -Server $bluevc
       # Check the cluster is enabled
       if ($TrustAuthorityCluster.State -ne 'Enabled') {
          Throw "The given TrustAuthorityCluster $($TrustAuthorityCluster.Name) hasn't been configured yet!"
       }

       # Check services healthy
       $status = Get-TrustAuthorityServicesStatus -TrustAuthorityCluster $TrustAuthorityCluster -Server $bluevc

       if ($status.AttestationServiceStatus.Health -ne 'Ok') {
          Throw "The AttestationServiceStatus is not healthy, please fix it first!"
       }

       if ($status.KeyProviderServiceStatus.Health -ne 'Ok') {
          Throw "The KeyProviderServiceStatus is not healthy, please fix it first!"
       }

       # Check TrustAuthorityPrincipal's healthy
       $principals = Get-TrustAuthorityPrincipal -TrustAuthorityCluster $TrustAuthorityCluster -Server $bluevc

       $principals | Foreach-Object {
          if ($_.Health -ne 'Ok') {
             Throw "The TrustAuthorityPrincipal $($p.Name) is not healthy, please fix it first!"
          }
       }

       # Check TrustAuthorityKeyProvider's healthy
       $kp = Get-TrustAuthorityKeyProvider -TrustAuthorityCluster $TrustAuthorityCluster -Server $bluevc
       $kp | Foreach-Object {
          $k = $_
          if ($k.Status.Health -ne 'Ok') {
             Throw "TrustAuthorityKeyProvider $($k.Name) is not healthy, please fix it first!"
          }

          $k.Status.ServerStatus | Foreach-Object {
             if ($_.Health -ne 'Ok') {
                Throw "The ServerStatus $($status.Name) in TrustAuthorityKeyProvider $($k.Name) is not healthy, please fix it first!"
             }
          }
       }

       # Check tpm2 settings
       $tpm2Setting = Get-TrustAuthorityTpm2AttestationSettings -TrustAuthorityCluster $TrustAuthorityCluster -Server $bluevc
       if ($tpm2Setting.Health -ne 'Ok') {
          Throw "TrustAuthorityTpm2AttestationSettings is not healthy, please fix it first!"
       }

       # Check tpm2Ek healthy
       $tpm2Eks = Get-TrustAuthorityTpm2EndorsementKey -TrustAuthorityCluster $TrustAuthorityCluster -Server $bluevc
       if ($tpm2Eks -ne $null) {
          $tpm2Eks | Foreach-Object {
             if ($_.Health -ne 'Ok') {
                Throw "TrustAuthorityTpm2EndorsementKey $($ek.Name) is not healthy, please fix it first!"
             }
          }
       }

       # Check tpm2CA healthy
       $tpm2cas = Get-TrustAuthorityTpm2CACertificate -TrustAuthorityCluster $TrustAuthorityCluster -Server $bluevc
       if ($tpm2cas -ne $null) {
          $tpm2cas | Foreach-Object {
             if ($_.Health -ne 'Ok') {
                Throw "TrustAuthorityTpm2CACertificate $($ca.Name) is not healthy, please fix it first!"
             }
          }
       }

       # Check BaseImage healthy
       $baseImages = Get-TrustAuthorityVMHostBaseImage -TrustAuthorityCluster $TrustAuthorityCluster -Server $bluevc
       if ($baseImages -ne $null) {
          $baseImages | Foreach-Object {
             if ($_.Health -ne 'Ok') {
                Throw "TrustAuthorityVMHostBaseImage $($img.Name) is not healthy, please fix it first!"
             }
          }
       }
   }
}

Function Check-TrustedClusterSettings {
   [CmdLetBinding()]

   Param (
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
      [VMware.VimAutomation.Security.Types.V1.TrustedInfrastructure.TrustedCluster] $TrustedCluster
   )

   Begin {
      $greenvc = GetViServer -clusterUid $TrustedCluster.Uid
      Write-Host "Checking the settings of TrustedCluster $($TrustedCluster.Name)..."
   }

   Process {
      $TrustedCluster = Get-TrustedCluster $TrustedCluster.Name -Server $greenvc

      if (!$TrustedCluster.AttestationServiceInfo -and !$TrustedCluster.KeyProviderServiceInfo) {
         Throw "The cluster $($TrustedCluster.Name) hasn't been configured yet, you can add the host directly."
      }
   }
}

Function GetViServer {
   Param (
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
      [string] $clusterUid
   )

   Process {
      $server = $global:DefaultVIServers | Where-Object { [VMware.VimAutomation.Sdk.Types.V1.DistinguishedName]::GetConnectionDn($clusterUid) -eq $_.Id}

      return $server
   }
}

Function ConfirmIsVCenter {
   <#
    .SYNOPSIS
       This function confirms the connected VI server is vCenter Server.
    .DESCRIPTION
       This function confirms the connected VI server is vCenter Server.
    .EXAMPLE
       C:\PS>ConfirmIsVCenter
       Throws exception if the connected VIServer is not vCenter Server.
   #>

   Param (
      [Parameter(Mandatory=$True)]
      [ValidateNotNullOrEmpty()]
      [String] $VIServer
   )

   Process {
      if ([String]::IsNullOrWhiteSpace($VIServer)) {
         Throw "Please provide a valid vCenter Server!"
      }

      $SI = Get-View Serviceinstance -Server $VIServer
      $VIType = $SI.Content.About.ApiType

      if ($VIType -ne "VirtualCenter") {
         Throw "Operation requires vCenter Server!"
      }
   }
}

Function ConvertFrom-X509Chain {
   Param (
      [Parameter(Mandatory=$True)]
      [System.Security.Cryptography.X509Certificates.X509Chain] $CertChain
   )

   Process {
      $certStr = $null
      $($CertChain.ChainElements) | Foreach-Object {
         if ($certStr -eq $null) {
            $certStr = [System.Convert]::ToBase64String($($_.Certificate.GetRawCertData()))
         } else {
            $certStr = $certStr, [System.Convert]::ToBase64String($($_.Certificate.GetRawCertData()))
         }
      }

      return $certStr
   }
}

Function ConvertTo-X509Chain {
   Param (
      [Parameter(Mandatory=$True)]
      [System.Array] $certString
   )

   Process {
      $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
      if ($certString.Length -gt 0) {
         for ($i = 0; $i -lt $certString.Length - 1; $i++ ) {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $cert.Import([System.Text.Encoding]::Default.GetBytes($certString[$i].replace("\n", [Environment]::NewLine)))
            $chain.ChainPolicy.ExtraStore.Add($cert) | Out-Null
         }
      }

      $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
      $cert.Import([System.Text.Encoding]::Default.GetBytes($certString[-1].replace("\n", [Environment]::NewLine)))
      $chain.Build($cert) | Out-Null

      return $chain
   }
}


Export-ModuleMember Add-TrustAuthorityVMHost, Add-TrustedVMHost
# SIG # Begin signature block
# MIIi9AYJKoZIhvcNAQcCoIIi5TCCIuECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDicYU2iA+clsiG
# VfuCJGR5GCDk63j+8YRckQvxLcD5yKCCD8swggTMMIIDtKADAgECAhBdqtQcwalQ
# C13tonk09GI7MA0GCSqGSIb3DQEBCwUAMH8xCzAJBgNVBAYTAlVTMR0wGwYDVQQK
# ExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEfMB0GA1UECxMWU3ltYW50ZWMgVHJ1c3Qg
# TmV0d29yazEwMC4GA1UEAxMnU3ltYW50ZWMgQ2xhc3MgMyBTSEEyNTYgQ29kZSBT
# aWduaW5nIENBMB4XDTE4MDgxMzAwMDAwMFoXDTIxMDkxMTIzNTk1OVowZDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExEjAQBgNVBAcMCVBhbG8gQWx0
# bzEVMBMGA1UECgwMVk13YXJlLCBJbmMuMRUwEwYDVQQDDAxWTXdhcmUsIEluYy4w
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCuswYfqnKot0mNu9VhCCCR
# vVcCrxoSdB6G30MlukAVxgQ8qTyJwr7IVBJXEKJYpzv63/iDYiNAY3MOW+Pb4qGI
# bNpafqxc2WLW17vtQO3QZwscIVRapLV1xFpwuxJ4LYdsxHPZaGq9rOPBOKqTP7Jy
# KQxE/1ysjzacA4NXHORf2iars70VpZRksBzkniDmurvwCkjtof+5krxXd9XSDEFZ
# 9oxeUGUOBCvSLwOOuBkWPlvCnzEqMUeSoXJavl1QSJvUOOQeoKUHRycc54S6Lern
# 2ddmdUDPwjD2cQ3PL8cgVqTsjRGDrCgOT7GwShW3EsRsOwc7o5nsiqg/x7ZmFpSJ
# AgMBAAGjggFdMIIBWTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDArBgNVHR8E
# JDAiMCCgHqAchhpodHRwOi8vc3Yuc3ltY2IuY29tL3N2LmNybDBhBgNVHSAEWjBY
# MFYGBmeBDAEEATBMMCMGCCsGAQUFBwIBFhdodHRwczovL2Quc3ltY2IuY29tL2Nw
# czAlBggrBgEFBQcCAjAZDBdodHRwczovL2Quc3ltY2IuY29tL3JwYTATBgNVHSUE
# DDAKBggrBgEFBQcDAzBXBggrBgEFBQcBAQRLMEkwHwYIKwYBBQUHMAGGE2h0dHA6
# Ly9zdi5zeW1jZC5jb20wJgYIKwYBBQUHMAKGGmh0dHA6Ly9zdi5zeW1jYi5jb20v
# c3YuY3J0MB8GA1UdIwQYMBaAFJY7U/B5M5evfYPvLivMyreGHnJmMB0GA1UdDgQW
# BBTVp9RQKpAUKYYLZ70Ta983qBUJ1TANBgkqhkiG9w0BAQsFAAOCAQEAlnsx3io+
# W/9i0QtDDhosvG+zTubTNCPtyYpv59Nhi81M0GbGOPNO3kVavCpBA11Enf0CZuEq
# f/ctbzYlMRONwQtGZ0GexfD/RhaORSKib/ACt70siKYBHyTL1jmHfIfi2yajKkMx
# UrPM9nHjKeagXTCGthD/kYW6o7YKKcD7kQUyBhofimeSgumQlm12KSmkW0cHwSSX
# TUNWtshVz+74EcnZtGFI6bwYmhvnTp05hWJ8EU2Y1LdBwgTaRTxlSDP9JK+e63vm
# SXElMqnn1DDXABT5RW8lNt6g9P09a2J8p63JGgwMBhmnatw7yrMm5EAo+K6gVliJ
# LUMlTW3O09MbDTCCBVkwggRBoAMCAQICED141/l2SWCyYX308B7KhiowDQYJKoZI
# hvcNAQELBQAwgcoxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5j
# LjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE6MDgGA1UECxMxKGMp
# IDIwMDYgVmVyaVNpZ24sIEluYy4gLSBGb3IgYXV0aG9yaXplZCB1c2Ugb25seTFF
# MEMGA1UEAxM8VmVyaVNpZ24gQ2xhc3MgMyBQdWJsaWMgUHJpbWFyeSBDZXJ0aWZp
# Y2F0aW9uIEF1dGhvcml0eSAtIEc1MB4XDTEzMTIxMDAwMDAwMFoXDTIzMTIwOTIz
# NTk1OVowfzELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0
# aW9uMR8wHQYDVQQLExZTeW1hbnRlYyBUcnVzdCBOZXR3b3JrMTAwLgYDVQQDEydT
# eW1hbnRlYyBDbGFzcyAzIFNIQTI1NiBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCXgx4AFq8ssdIIxNdok1FgHnH24ke021hN
# I2JqtL9aG1H3ow0Yd2i72DarLyFQ2p7z518nTgvCl8gJcJOp2lwNTqQNkaC07BTO
# kXJULs6j20TpUhs/QTzKSuSqwOg5q1PMIdDMz3+b5sLMWGqCFe49Ns8cxZcHJI7x
# e74xLT1u3LWZQp9LYZVfHHDuF33bi+VhiXjHaBuvEXgamK7EVUdT2bMy1qEORkDF
# l5KK0VOnmVuFNVfT6pNiYSAKxzB3JBFNYoO2untogjHuZcrf+dWNsjXcjCtvanJc
# YISc8gyUXsBWUgBIzNP4pX3eL9cT5DiohNVGuBOGwhud6lo43ZvbAgMBAAGjggGD
# MIIBfzAvBggrBgEFBQcBAQQjMCEwHwYIKwYBBQUHMAGGE2h0dHA6Ly9zMi5zeW1j
# Yi5jb20wEgYDVR0TAQH/BAgwBgEB/wIBADBsBgNVHSAEZTBjMGEGC2CGSAGG+EUB
# BxcDMFIwJgYIKwYBBQUHAgEWGmh0dHA6Ly93d3cuc3ltYXV0aC5jb20vY3BzMCgG
# CCsGAQUFBwICMBwaGmh0dHA6Ly93d3cuc3ltYXV0aC5jb20vcnBhMDAGA1UdHwQp
# MCcwJaAjoCGGH2h0dHA6Ly9zMS5zeW1jYi5jb20vcGNhMy1nNS5jcmwwHQYDVR0l
# BBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIBBjApBgNVHREE
# IjAgpB4wHDEaMBgGA1UEAxMRU3ltYW50ZWNQS0ktMS01NjcwHQYDVR0OBBYEFJY7
# U/B5M5evfYPvLivMyreGHnJmMB8GA1UdIwQYMBaAFH/TZafC3ey78DAJ80M5+gKv
# MzEzMA0GCSqGSIb3DQEBCwUAA4IBAQAThRoeaak396C9pK9+HWFT/p2MXgymdR54
# FyPd/ewaA1U5+3GVx2Vap44w0kRaYdtwb9ohBcIuc7pJ8dGT/l3JzV4D4ImeP3Qe
# 1/c4i6nWz7s1LzNYqJJW0chNO4LmeYQW/CiwsUfzHaI+7ofZpn+kVqU/rYQuKd58
# vKiqoz0EAeq6k6IOUCIpF0yH5DoRX9akJYmbBWsvtMkBTCd7C6wZBSKgYBU/2sn7
# TUyP+3Jnd/0nlMe6NQ6ISf6N/SivShK9DbOXBd5EDBX6NisD3MFQAfGhEV0U5eK9
# J0tUviuEXg+mw3QFCu+Xw4kisR93873NQ9TxTKk/tYuEr2Ty0BQhMIIFmjCCA4Kg
# AwIBAgIKYRmT5AAAAAAAHDANBgkqhkiG9w0BAQUFADB/MQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMSkwJwYDVQQDEyBNaWNyb3NvZnQgQ29kZSBW
# ZXJpZmljYXRpb24gUm9vdDAeFw0xMTAyMjIxOTI1MTdaFw0yMTAyMjIxOTM1MTda
# MIHKMQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNV
# BAsTFlZlcmlTaWduIFRydXN0IE5ldHdvcmsxOjA4BgNVBAsTMShjKSAyMDA2IFZl
# cmlTaWduLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkxRTBDBgNVBAMT
# PFZlcmlTaWduIENsYXNzIDMgUHVibGljIFByaW1hcnkgQ2VydGlmaWNhdGlvbiBB
# dXRob3JpdHkgLSBHNTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK8k
# CAgpejWeYAyq50s7Ttx8vDxFHLsr4P4pAvlXCKNkhRUn9fGtyDGJXSLoKqqmQrOP
# +LlVt7G3S7P+j34HV+zvQ9tmYhVhz2ANpNje+ODDYgg9VBPrScpZVIUm5SuPG5/r
# 9aGRwjNJ2ENjalJL0o/ocFFN0Ylpe8dw9rPcEnTbe11LVtOWvxV3obD0oiXyrxyS
# Zxjl9AYE75C55ADk3Tq1Gf8CuvQ87uCL6zeL7PTXrPL28D2v3XWRMxkdHEDLdCQZ
# IZPZFP6sKlLHj9UESeSNY0eIPGmDy/5HvSt+T8WVrg6d1NFDwGdz4xQIfuU/n3O4
# MwrPXT80h5aK7lPoJRUCAwEAAaOByzCByDARBgNVHSAECjAIMAYGBFUdIAAwDwYD
# VR0TAQH/BAUwAwEB/zALBgNVHQ8EBAMCAYYwHQYDVR0OBBYEFH/TZafC3ey78DAJ
# 80M5+gKvMzEzMB8GA1UdIwQYMBaAFGL7CiFbf0NuEdoJVFBr9dKWcfGeMFUGA1Ud
# HwROMEwwSqBIoEaGRGh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3By
# b2R1Y3RzL01pY3Jvc29mdENvZGVWZXJpZlJvb3QuY3JsMA0GCSqGSIb3DQEBBQUA
# A4ICAQCBKoIWjDRnK+UD6zR7jKKjUIr0VYbxHoyOrn3uAxnOcpUYSK1iEf0g/T9H
# BgFa4uBvjBUsTjxqUGwLNqPPeg2cQrxc+BnVYONp5uIjQWeMaIN2K4+Toyq1f75Z
# +6nJsiaPyqLzghuYPpGVJ5eGYe5bXQdrzYao4mWAqOIV4rK+IwVqugzzR5NNrKSM
# B3k5wGESOgUNiaPsn1eJhPvsynxHZhSR2LYPGV3muEqsvEfIcUOW5jIgpdx3hv08
# 44tx23ubA/y3HTJk6xZSoEOj+i6tWZJOfMfyM0JIOFE6fDjHGyQiKEAeGkYfF9sY
# 9/AnNWy4Y9nNuWRdK6Ve78YptPLH+CHMBLpX/QG2q8Zn+efTmX/09SL6cvX9/zoc
# Qjqh+YAYpe6NHNRmnkUB/qru//sXjzD38c0pxZ3stdVJAD2FuMu7kzonaknAMK5m
# yfcjKDJ2+aSDVshIzlqWqqDMDMR/tI6Xr23jVCfDn4bA1uRzCJcF29BUYl4DSMLV
# n3+nZozQnbBP1NOYX0t6yX+yKVLQEoDHD1S2HmfNxqBsEQOE00h15yr+sDtuCjqm
# a3aZBaPxd2hhMxRHBvxTf1K9khRcSiRqZ4yvjZCq0PZ5IRuTJnzDzh69iDiSrkXG
# GWpJULMF+K5ZN4pqJQOUsVmBUOi6g4C3IzX0drlnHVkYrSCNlDGCEn8wghJ7AgEB
# MIGTMH8xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlv
# bjEfMB0GA1UECxMWU3ltYW50ZWMgVHJ1c3QgTmV0d29yazEwMC4GA1UEAxMnU3lt
# YW50ZWMgQ2xhc3MgMyBTSEEyNTYgQ29kZSBTaWduaW5nIENBAhBdqtQcwalQC13t
# onk09GI7MA0GCWCGSAFlAwQCAQUAoIGWMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
# AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCoGCisGAQQBgjcCAQwx
# HDAaoRiAFmh0dHA6Ly93d3cudm13YXJlLmNvbS8wLwYJKoZIhvcNAQkEMSIEIEIQ
# y4E7C63SmxSxEC+1DBchnh7DW24QhvnHyMjCEuJ+MA0GCSqGSIb3DQEBAQUABIIB
# ADwK/sQPu5Vv+Jink4WM/Bf3CvrNgyfZD13TPDsMlt+tSEjghyHQ5/Xz4asgQuKB
# CSUgh0bJDaDaz9FF1oY9VUHHsonuB4sVhMKevKbXsYVuvUU65tBZ0RN+74RP/3iS
# rQAADQdIGuKBX1pmOmyE65A6pLWmJ+j05XCagPFboiXdiEcVxfCqRctK8MSyvtzd
# HOa2miNTIPEPUTVvqo/9nZCUwFhNN8TwaaOwrkMZv0NOFGk9AaGyQJuHb/IP1y2r
# cgFGtWA+WgPKftWq1s9Evk7W3WXV/nlKu55zg8K/no2Ug6+7KE0jNGUJJHg/yp6b
# gO/kfYj4sIwd5RJvOkk45QChghAjMIIQHwYKKwYBBAGCNwMDATGCEA8wghALBgkq
# hkiG9w0BBwKggg/8MIIP+AIBAzEPMA0GCWCGSAFlAwQCAQUAMIHmBgsqhkiG9w0B
# CRABBKCB1gSB0zCB0AIBAQYJKwYBBAGgMgIDMDEwDQYJYIZIAWUDBAIBBQAEIMSa
# 32tGkSO0MHzDIAL+rOzowJzdf7nOyZAYmKBTXDbnAg4BbKiJKXgAAAAAAjyk+xgT
# MjAyMDEwMTIxMDE3MTEuOTY0WjADAgEBoGOkYTBfMQswCQYDVQQGEwJKUDEcMBoG
# A1UEChMTR01PIEdsb2JhbFNpZ24gSy5LLjEyMDAGA1UEAxMpR2xvYmFsU2lnbiBU
# U0EgZm9yIEFkdmFuY2VkIC0gRzMgLSAwMDMtMDGgggxqMIIE6jCCA9KgAwIBAgIM
# M5Agd2HEJt2UUAMNMA0GCSqGSIb3DQEBCwUAMFsxCzAJBgNVBAYTAkJFMRkwFwYD
# VQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVz
# dGFtcGluZyBDQSAtIFNIQTI1NiAtIEcyMB4XDTE4MDYxNDEwMDAwMFoXDTI5MDMx
# ODEwMDAwMFowXzELMAkGA1UEBhMCSlAxHDAaBgNVBAoTE0dNTyBHbG9iYWxTaWdu
# IEsuSy4xMjAwBgNVBAMTKUdsb2JhbFNpZ24gVFNBIGZvciBBZHZhbmNlZCAtIEcz
# IC0gMDAzLTAxMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv3Gj+IDO
# E5Be8KfdP9KY8kE6Sdp/WC+ePDoBE8ptNJlbDCccROdW4wkv9W+rTr4nYmbGuLKH
# x2W+xsBeqT6u+yR0iyv4aARkhqo64qohj/rxnbkYMF6afAf1O3Uu2gklGav+c+lx
# neyq9j4ShYEUJPjmPpnfrvO5i9UmywSommFW7yhwqEtqKyVq5aA2ny25mofcdA4f
# QqBBOpYHDst7MtUBC1ORfVY0T7S8sHRHnKp6bF/kjlGfk5BhAz6PX0FBUHg5LRIS
# 3OvqADCyP+FtE7d1SBVrTg7Rl+NO25bZ0WKvCEHPIg/o3c7Y6pNWbtM6j2dKaki6
# /GHlbFmzEi0CgQIDAQABo4IBqDCCAaQwDgYDVR0PAQH/BAQDAgeAMEwGA1UdIARF
# MEMwQQYJKwYBBAGgMgEeMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2Jh
# bHNpZ24uY29tL3JlcG9zaXRvcnkvMAkGA1UdEwQCMAAwFgYDVR0lAQH/BAwwCgYI
# KwYBBQUHAwgwRgYDVR0fBD8wPTA7oDmgN4Y1aHR0cDovL2NybC5nbG9iYWxzaWdu
# LmNvbS9ncy9nc3RpbWVzdGFtcGluZ3NoYTJnMi5jcmwwgZgGCCsGAQUFBwEBBIGL
# MIGIMEgGCCsGAQUFBzAChjxodHRwOi8vc2VjdXJlLmdsb2JhbHNpZ24uY29tL2Nh
# Y2VydC9nc3RpbWVzdGFtcGluZ3NoYTJnMi5jcnQwPAYIKwYBBQUHMAGGMGh0dHA6
# Ly9vY3NwMi5nbG9iYWxzaWduLmNvbS9nc3RpbWVzdGFtcGluZ3NoYTJnMjAdBgNV
# HQ4EFgQUeaezg3HWs0B2IOZ0Crf39+bd3XQwHwYDVR0jBBgwFoAUkiGnSpVdZLCb
# tB7mADdH5p1BK0wwDQYJKoZIhvcNAQELBQADggEBAIc0fm43ZxsIEQJttimYchTL
# SH7IyY8viQ2vD/IsIZBuO7ccAaqBaMQQI0v4CeOrX+pFps4O/qSA6WtqDAD5yoYQ
# DD7/HxrpHOUil2TZrOnj6NpTYGMLt45P3NUh9J3eE2o4NeVs4yZM29Z0Z0W5TwTE
# WAgam2ZFPSQaGpJXyV8oR3hn21zKrQvotw/RthYyNCIENnJM73umvLauBMDZeKCI
# yIZrGNqWjStuIlzLf70XvZ63toZNgxBNsDKy4BOgy2DihHUU6SG9EKKktgjPOw0p
# WVmp08NMDX9CzIgUtELlugTVmEqkjQc9SR94bWVtYL38zlnrLOnFqtqt7taTrBUw
# ggQVMIIC/aADAgECAgsEAAAAAAExicZQBDANBgkqhkiG9w0BAQsFADBMMSAwHgYD
# VQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSMzETMBEGA1UEChMKR2xvYmFsU2ln
# bjETMBEGA1UEAxMKR2xvYmFsU2lnbjAeFw0xMTA4MDIxMDAwMDBaFw0yOTAzMjkx
# MDAwMDBaMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNh
# MTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQSAtIFNIQTI1NiAt
# IEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqpuOw6sRUSUBtpaU
# 4k/YwQj2RiPZRcWVl1urGr/SbFfJMwYfoA/GPH5TSHq/nYeer+7DjEfhQuzj46FK
# bAwXxKbBuc1b8R5EiY7+C94hWBPuTcjFZwscsrPxNHaRossHbTfFoEcmAhWkkJGp
# eZ7X61edK3wi2BTX8QceeCI2a3d5r6/5f45O4bUIMf3q7UtxYowj8QM5j0R5tnYD
# V56tLwhG3NKMvPSOdM7IaGlRdhGLD10kWxlUPSbMQI2CJxtZIH1Z9pOAjvgqOP1r
# oEBlH1d2zFuOBE8sqNuEUBNPxtyLufjdaUyI65x7MCb8eli7WbwUcpKBV7d2ydiA
# CoBuCQIDAQABo4HoMIHlMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/
# AgEAMB0GA1UdDgQWBBSSIadKlV1ksJu0HuYAN0fmnUErTDBHBgNVHSAEQDA+MDwG
# BFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20v
# cmVwb3NpdG9yeS8wNgYDVR0fBC8wLTAroCmgJ4YlaHR0cDovL2NybC5nbG9iYWxz
# aWduLm5ldC9yb290LXIzLmNybDAfBgNVHSMEGDAWgBSP8Et/qC5FJK5NUPpjmove
# 4t0bvDANBgkqhkiG9w0BAQsFAAOCAQEABFaCSnzQzsm/NmbRvjWek2yX6AbOMRhZ
# +WxBX4AuwEIluBjH/NSxN8RooM8oagN0S2OXhXdhO9cv4/W9M6KSfREfnops7yyw
# 9GKNNnPRFjbxvF7stICYePzSdnno4SGU4B/EouGqZ9uznHPlQCLPOc7b5neVp7uy
# y/YZhp2fyNSYBbJxb051rvE9ZGo7Xk5GpipdCJLxo/MddL9iDSOMXCo4ldLA1c3P
# iNofKLW6gWlkKrWmotVzr9xG2wSukdduxZi61EfEVnSAR3hYjL7vK/3sbL/RlPe/
# UOB74JD9IBh4GCJdCC6MHKCX8x2ZfaOdkdMGRE4EbnocIOM28LZQuTCCA18wggJH
# oAMCAQICCwQAAAAAASFYUwiiMA0GCSqGSIb3DQEBCwUAMEwxIDAeBgNVBAsTF0ds
# b2JhbFNpZ24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYD
# VQQDEwpHbG9iYWxTaWduMB4XDTA5MDMxODEwMDAwMFoXDTI5MDMxODEwMDAwMFow
# TDEgMB4GA1UECxMXR2xvYmFsU2lnbiBSb290IENBIC0gUjMxEzARBgNVBAoTCkds
# b2JhbFNpZ24xEzARBgNVBAMTCkdsb2JhbFNpZ24wggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQDMJXaQeQZ4Ihb1wIO2hMoonv0FdhHFrYhy/EYCQ8eyip0E
# XyTLLkvhYIJG4VKrDIFHcGzdZNHr9SyjD4I9DCuul9e2FIYQebs7E4B3jAjhSdJq
# Yi8fXvqWaN+JJ5U4nwbXPsnLJlkNc96wyOkmDoMVxu9bi9IEYMpJpij2aTv2y8go
# keWdimFXN6x0FNx04Druci8unPvQu7/1PQDhBjPogiuuU6Y6FnOM3UEOIDrAtKeh
# 6bJPkC4yYOlXy7kEkmho5TgmYHWyn3f/kRTvriBJ/K1AFUjRAjFhGV64l++td7dk
# mnq/X8ET75ti+w1s4FRpFqkD2m7pg5NxdsZphYIXAgMBAAGjQjBAMA4GA1UdDwEB
# /wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSP8Et/qC5FJK5NUPpj
# move4t0bvDANBgkqhkiG9w0BAQsFAAOCAQEAS0DbwFCq/sgM7/eWVEVJu5YACUGs
# sxOGhigHM8pr5nS5ugAtrqQK0/Xx8Q+Kv3NnSoPHRHt44K9ubG8DKY4zOUXDjuS5
# V2yq/BKW7FPGLeQkbLmUY/vcU2hnVj6DuM81IcPJaP7O2sJTqsyQiunwXUaMld16
# WCgaLx3ezQA3QY/tRG3XUyiXfvNnBB4V14qWtNPeTCekTBtzc3b0F5nCH3oO4y0I
# rQocLP88q1UOD5F+NuvDV0m+4S4tfGCLw0FREyOdzvcya5QBqJnnLDMfOjsl0oZA
# zjsshnjJYS8Uuu7bVW/fhO4FCU29KNhyztNiUGUe65KXgzHZs7XKR1g/XzGCAokw
# ggKFAgEBMGswWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYt
# c2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hBMjU2
# IC0gRzICDDOQIHdhxCbdlFADDTANBglghkgBZQMEAgEFAKCB8DAaBgkqhkiG9w0B
# CQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIJ1Mp8MoZoM8GN+RvFGW
# kxLQOL4htvdgNS1G5j3jevwAMIGgBgsqhkiG9w0BCRACDDGBkDCBjTCBijCBhwQU
# rmsC2QsljAmRsRYSid62aVY5HW8wbzBfpF0wWzELMAkGA1UEBhMCQkUxGTAXBgNV
# BAoTEEdsb2JhbFNpZ24gbnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0
# YW1waW5nIENBIC0gU0hBMjU2IC0gRzICDDOQIHdhxCbdlFADDTANBgkqhkiG9w0B
# AQEFAASCAQCw0o79lMBljtr86gcDxeF2/v1wLaLJaxTvwLJ3bYLabHR5wZUv42aO
# 3KEMzeIvLN9/mMSn7rq6vcWGZSAZVvWecDntZE9OYU7i4cQdRucXctFGpoTN6MKF
# yeX3vMbe7YfBPGJkNB6HfYp4qWy6CkWWlWXgK1MOKo+HQFORkZtDqqpoUa3soqVl
# IeCMCcJjJIrSd3LA8NFYtOUfPXRmdhcn10xke3vTBO4T7pTLdymcm3x909UN+0cE
# xIe2wMG3D3XxSN+Rx5+iz9thPISgVdOgJLP4FxQ5fU1ci56k35wXQeDnHQFyQTO+
# uF+EWBmAiBQ6cGTiYvDOZSG2Ody3NSPn
# SIG # End signature block
