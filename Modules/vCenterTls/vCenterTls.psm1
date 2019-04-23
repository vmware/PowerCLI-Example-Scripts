Using Module VMware.VimAutomation.Core

function Get-vCenterTrustedRootChain {
    <#
    .Synopsis
        Get trusted root certificate(s)
    .DESCRIPTION
        Get trusted root certificate(s)
        Use 'Connect-CisServer' first to establish a connection
    .PARAMETER Server
        CisServer Connection.  Uses $Global:DefatultCisServer[0] by default
    .PARAMETER Chain
        Retrieve specific root chain
    .EXAMPLE
        Get-vCenterTrustedRootChain
    .EXAMPLE
        $CisServer = Connect-CisServer servername
        Get-vCenterTrustedRootChain -Server $CisServer -Chain $ChainId
    #>

    [CmdletBinding(DefaultParameterSetName="All")]
    
    Param
    (
        [Parameter()]
        [VMware.VimAutomation.Cis.Core.Types.V1.CisServer]
        $Server=$Global:DefaultCisServers[0],

        [Parameter(Position=0)]
        [String]
        $Chain
    )
   
    Begin{

    }
    Process
    {
        if($Chain) {
            $UriPath = "/vcenter/certificate-management/vcenter/trusted-root-chains/$chain"
        } else {
            $UriPath = '/vcenter/certificate-management/vcenter/trusted-root-chains'
        }
        $RestMethod = 'Get'


        $Result = Invoke-CisRest -Server $Server -Method $RestMethod -UriPath $UriPath
        if($Chain) {
            $Certificate = $Result.cert_chain.cert_chain | ConvertTo-X509Certificate
            [pscustomobject]@{
                PSTypeName = "VCenterTls.TrustedRootCert"
                Chain = $Chain
                Thumbprint = $Certificate.Thumbprint
                Subject = $Certificate.Subject
                Issuer = $Certificate.Issuer
                ValidFrom = $Certificate.NotBefore
                ValidTo = $Certificate.NotAfter
            }
        }
        
        else {
            $Result | ForEach-Object {Get-vCenterTrustedRootChain -Server $Server -Chain $_.chain}            
        }
    }
    End
    {
    }
}

function Add-vCenterTrustedRootChain {
    <#
    .Synopsis
        Adds a new certificate to the trusted root store
    .DESCRIPTION
        Adds a new certificate to the trusted root store
        Use 'Connect-CisServer' first to establish a connection
    .PARAMETER Server
        CisServer Connection.  Uses $Global:DefatultCisServer[0] by default
    .PARAMETER Certificate
        PEM encoded certificate file.  May contain a single certificate or a full chain
    .EXAMPLE
        Add-vCenterTrustedRootChain -Certificate <PEM Certificate or Chain>
    .EXAMPLE
        $CisServer = Connect-CisServer servername
        Add-vCenterTrustedRootChain -Server $CisServer -Certificate <PEM Certificate or Chain>
    #>

    [CmdletBinding(DefaultParameterSetName="All")]
    
    Param
    (
        [Parameter(ValueFromPipeline=$true)]
        [VMware.VimAutomation.Cis.Core.Types.V1.CisServer]
        $Server=$Global:DefaultCisServers[0],

        [Parameter(Mandatory=$true,Position=0)]
        [ValidateScript({
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The Path argument must be a file"
            }
            try{
                #Test if this is a valid certificate file
                New-Object System.Security.Cryptography.X509Certificates.X509Certificate2((Resolve-Path -Path $_).Path)
            } catch {
                throw "File is not a valid certificate"
            }
            return $true
        })]         
        [System.IO.FileInfo]
        $Certificate

    )
    
    Begin{
    }
    Process
    {
        $BeginString = '-----BEGIN CERTIFICATE-----'
        $EndString = '-----END CERTIFICATE-----'

        $UriPath = '/vcenter/certificate-management/vcenter/trusted-root-chains'
        $RestMethod = 'Post'

        $CertificateFile = Get-Content -Path $Certificate
        $CertificateList = New-Object System.Collections.ArrayList
        foreach($Line in $CertificateFile) {
            switch -Regex ($Line) {
                $BeginString {
                    $Chain = New-Object System.Text.StringBuilder
                    $Chain.Append($Line) | Out-Null
                    $Chain.Append('\n') | Out-Null
                }
                $EndString {
                    $Chain.Append('\n')  | Out-Null
                    $Chain.Append($Line) | Out-Null
                    $CertificateList.Add($Chain.ToString()) | Out-Null
                }
                default {
                    $Chain.Append($Line) | Out-Null
                }
            }
        }
        foreach($Cert in $CertificateList) {
            $Body = @{
                spec = @{
                    cert_chain = @{
                        cert_chain = @($Cert)
                    }
                    chain = ''
                }
            }
            Invoke-CisRest -Server $Server -Method $RestMethod -UriPath $UriPath -Body $Body
        }
    }
    End
    {
    }
}

function Remove-vCenterTrustedRootChain {
    <#
    .Synopsis
        Removes a certificate from the trusted root store
    .DESCRIPTION
        Removes a certificate from the trusted root store
        Use 'Connect-CisServer' first to establish a connection
    .PARAMETER Server
        CisServer Connection.  Uses $Global:DefatultCisServer[0] by default
    .PARAMETER Chain
        Id of the certificate chain to remove
    .EXAMPLE
        Remove-vCenterTrustedRootChain -Chain $ChainId
    .EXAMPLE
        $CisServer = Connect-CisServer servername
        Remove-vCenterTrustedRootChain -Server $CisServer -Chain $Chain
    #>

    [CmdletBinding(DefaultParameterSetName="All")]
    
    Param
    (
        [Parameter()]
        [VMware.VimAutomation.Cis.Core.Types.V1.CisServer]
        $Server=$Global:DefaultCisServers[0],

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [String]
        $Chain
    )
    
    Begin{
    }
    Process
    {
        $UriPath = "/vcenter/certificate-management/vcenter/trusted-root-chains/$chain"
        $RestMethod = 'Delete'

        Invoke-CisRest -Server $Server -Method $RestMethod -UriPath $UriPath -Body $Body
    }
    End
    {
    }
}

function New-vCenterCertificateSigningRequest {
    <#
    .Synopsis
        Creates a new CSR
    .DESCRIPTION
        Creates a new CSR
        Use 'Connect-CisServer' first to establish a connection
    .PARAMETER Server
        CisServer Connection.  Uses $Global:DefatultCisServer[0] by default
    .PARAMETER State
        State or province
    .PARAMETER Country
        Country
    .PARAMETER Locality
        Locality
    .PARAMETER Organization
        Organization
    .PARAMETER OrganizationUnit
        Organization Unit
    .PARAMETER Email
        Email Address
    .PARAMETER CommonName
        Common Name.  Will default to PNID if not specified. The PNID is equal to the System Name parameter input during deployment of vCenter
    .PARAMETER KeySize
        Size of key.  Default size of 2048 used if none specified
    .PARAMETER SubjectAltName
        Subject Alternative Name.  Comma separated list of hostnames and/or IPs.
    .EXAMPLE
        New-vCenterCertificateSigningRequest
    .EXAMPLE
        $CisServer = Connect-CisServer servername
        New-vCenterCertificateSigningRequest -Server $CisServer 
    #>

    [CmdletBinding(DefaultParameterSetName="All")]
    
    
    Param
    (
        [Parameter()]
        [VMware.VimAutomation.Cis.Core.Types.V1.CisServer]
        $Server=$Global:DefaultCisServers[0],

        [Parameter()]
        [Alias("Name")]
        [String]
        $CommonName,

        [Parameter(Mandatory=$true)]
        [Alias("Org")]
        [String]
        $Organization,

        [Parameter(Mandatory=$true)]
        [Alias("OrgUnit")]
        [String]
        $OrganizationUnit,

        [Parameter(Mandatory=$true)]
        [String]
        $Country,

        [Parameter(Mandatory=$true)]
        [Alias("Province")]
        [String]
        $State,
                
        [Parameter(Mandatory=$true)]
        [Alias("City")]
        [String]
        $Locality,

        [Parameter()]
        [String]
        $Email='',

        [Parameter()]
        [Alias("SAN")]
        [String]
        $SubjectAltName,

        [Parameter()]
        [ValidateSet(2048,4096,8192,16384)]
        [Int]
        $KeySize

    )
    
    Begin{
    }
    Process
    {
        $UriPath = '/vcenter/certificate-management/vcenter/tls-csr'
        $RestMethod = 'Post'

        # Create mandatory parameters
        $Body = @{
            spec = @{
                state_or_province = $State
                country = $Country
                locality = $Locality
                organization = $Organization
                organization_unit = $OrganizationUnit
                email_address = $Email
            }
        }
        # Add optional supplied parameters
        if($CommonName) { $Body.spec.common_name = $CommonName}
        if($KeySize) { $Body.spec.key_size = $KeySize}
        if($SubjectAltName) {
            $Body.spec.subject_alt_name = $SubjectAltName -split ','
        }

        $Result = Invoke-CisRest -Server $Server -Method $RestMethod -UriPath $UriPath -Body $Body
        if($Result) {
            $Result.Csr
        }
    }

    End
    {
    }
}

Function Get-vCenterCertificate {
    <#
    .Synopsis
        Get the vCenter Machine_SSL Certificate
    .DESCRIPTION
        Get the vCenter Machine_SSL Certificate
        Use 'Connect-CisServer' first to establish a connection
    .PARAMETER Server
        CisServer Connection.  Uses $Global:DefatultCisServer[0] by default
    .EXAMPLE
        Get-vCenterCertificate
    .EXAMPLE
        $CisServer = Connect-CisServer servername
        Get-vCenterCertificate -Server $CisServer
    #>

    [CmdletBinding(DefaultParameterSetName="All")]
   
    Param
    (
        [Parameter()]
        [VMware.VimAutomation.Cis.Core.Types.V1.CisServer]
        $Server=$Global:DefaultCisServers[0]

    )
    
    Begin{

    }
    Process
    {
        $UriPath = '/vcenter/certificate-management/vcenter/tls'
        $RestMethod = 'Get'

        Invoke-CisRest -Server $Server -Method $RestMethod -UriPath $UriPath

    }
    End
    {
    }
}

function Set-vCenterCertificate {
    <#
    .Synopsis
        Replaces the vCenter Machine_SSL Certificate
    .DESCRIPTION
        Replaces the vCenter Machine_SSL Certificate
        Use 'Connect-CisServer' first to establish a connection
    .PARAMETER Server
        CisServer Connection.  Uses $Global:DefatultCisServer[0] by default
    .PARAMETER Certificate
        PEM encoded certificate file
    .PARAMETER Key
        PEM encoded RSA Key file in PKCS8 format.  Not required if CSR used to generate certificate was created by VCSA  
    .PARAMETER Renew
        Renews the VECS generated default certificate
    .PARAMETER Duration
        Length of time the certificate is valid.  Duration is 730 days (2 years) if not specified.
    .EXAMPLE
        Set-vCenterCertificate -Certificate <Path to cert file> -Key <Path to key file>
    .EXAMPLE
        Set-vCenterCertificate -Renew -Duration 730
    .EXAMPLE
        $CisServer = Connect-CisServer servername
        Set-vCenterCertificate -Server $CisServer -Certificate <Path to cert file> -Key <Path to key file>
    #>

    [CmdletBinding(DefaultParameterSetName="All")]
    
    Param
    (
        [Parameter(ValueFromPipeline=$true)]
        [VMware.VimAutomation.Cis.Core.Types.V1.CisServer]
        $Server=$Global:DefaultCisServers[0],

        [Parameter(ParameterSetName="Replace",Mandatory=$true)]
        [ValidateScript({
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The Path argument must be a file"
            }
            try{
                #Test if this is a valid certificate file
                New-Object System.Security.Cryptography.X509Certificates.X509Certificate2((Resolve-Path -Path $_).Path)
            } catch {
                throw "File is not a valid certificate"
            }
            return $true
        })]         
        [System.IO.FileInfo]
        $Certificate,

        [Parameter(ParameterSetName="Replace")]
        [ValidateScript({
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The Path argument must be a file"
            }
            return $true
        })]         
        [System.IO.FileInfo]
        $Key,

        [Parameter(ParameterSetName="Renew")]
        [Switch]
        $Renew,

        [Parameter(ParameterSetName="Renew")]
        [ValidateRange(1, 730)]
        [Int]
        $Duration
    )
    
    Begin{
    }
    Process
    {
        #Certificate and key markers
        $BeginCertString = '-----BEGIN CERTIFICATE-----'
        $EndCertString = '-----END CERTIFICATE-----'
        $BeginKeyString = '-----BEGIN PRIVATE KEY-----'
        $EndKeyString = '-----END PRIVATE KEY-----'

        switch($PsCmdlet.ParameterSetName) {
            'Replace' {
                $UriPath = '/vcenter/certificate-management/vcenter/tls'
                $RestMethod = 'Put'
                $Body = @{spec = @{cert=$null}}

                $CertificateFile = Get-Content -Path $Certificate
                foreach($Line in $CertificateFile) {
                    switch -Regex ($Line) {
                        $BeginCertString {
                            $Chain = New-Object System.Text.StringBuilder
                            $Chain.Append($Line) | Out-Null
                            $Chain.Append('\n') | Out-Null
                        }
                        $EndCertString {
                            $Chain.Append('\n')  | Out-Null
                            $Chain.Append($Line) | Out-Null
                            $Body.spec.cert = $Chain.ToString()
                        }
                        default {
                            $Chain.Append($Line) | Out-Null
                        }
                    }
                }
                if($Key) {
                    $KeyFile = Get-Content -Path $Key
                    foreach($Line in $KeyFile) {
                        switch -Regex ($Line) {
                            $BeginKeyString {
                                $KeyString = New-Object System.Text.StringBuilder
                                $KeyString.Append($Line) | Out-Null
                                $KeyString.Append('\n') | Out-Null
                            }
                            $EndKeyString {
                                $KeyString.Append('\n')  | Out-Null
                                $KeyString.Append($Line) | Out-Null
                                $Body.spec.key = $KeyString.ToString()
                            }
                            default {
                                $KeyString.Append($Line) | Out-Null
                            }
                        }
                    }
                }
            }
            'Renew' {
                $UriPath = '/vcenter/certificate-management/vcenter/tls?action=renew'
                $RestMethod = 'Post'
                if($Duration) {
                    $Body = @{duration=$Duration}
                } else {
                    $Body = @{}
                }
            }
        }
        Invoke-CisRest -Server $Server -Method $RestMethod -UriPath $UriPath -Body $Body
        }

    End
    {
    }
}

function ConvertTo-X509Certificate {
    <#
    .Synopsis
        Converts PEM Base64 encoded string to an X509 Certificate
    .DESCRIPTION
        Converts PEM Base64 encoded string to an X509 Certificate
    .PARAMETER CertificateData
        PEM encoded certificate chain file
    #>

    [CmdletBinding(DefaultParameterSetName="All")]
    
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
        [String]
        $CertificateData
    )
    
    Begin{
    }
    Process
    {
        $BeginString = '-----BEGIN CERTIFICATE-----'
        $EndString = '-----END CERTIFICATE-----'

        foreach($Line in ($CertificateData -split '\n')) {
            switch -Regex ($Line) {
                $BeginString {
                    #Create a new string when we see ---begin certificate---
                    $Chain = New-Object System.Text.StringBuilder
                }
                $EndString {
                    [System.Security.Cryptography.X509Certificates.X509Certificate2]([System.Convert]::FromBase64String($Chain.ToString()))
                    $Chain.Clear() | Out-Null
                }
                default {
                    $Chain.Append($Line) | Out-Null
                }
            }
        }
    }

    End
    {
    }
}

function Set-NetCertficatePolicy {
    <#
    .Synopsis
        Sets the System.Net.ServicePointManager Certificate Policy
    .DESCRIPTION
        Sets the System.Net.ServicePointManager Certificate Policy
    .PARAMETER Policy
        Default|TrustAll
    .EXAMPLE
        Set-CertificatePolicy -Policy TrustAll
    .EXAMPLE
        Set-CertificatePolicy -Policy Default
    #>

    [CmdletBinding(DefaultParameterSetName="All")]
    
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateSet('TrustAll','Default')]
        [String]
        $Policy
    )
    
    Begin{
    }
    Process
    {
        switch($Policy) {
            'TrustAll' {
                class TrustAllCertsPolicy : System.Net.ICertificatePolicy
                {
                    [bool] CheckValidationResult(
                        [System.Net.ServicePoint] $a,
                        [System.Security.Cryptography.X509Certificates.X509Certificate] $b,
                        [System.Net.WebRequest] $c,
                        [int] $d
                    )
                    {
                        return $true
                    }
                }
                [System.Net.ServicePointManager]::CertificatePolicy = [TrustAllCertsPolicy]::new()
            }
            'Default' {
                [System.Net.ServicePointManager]::CertificatePolicy = $null
            }
            default{
                [System.Net.ServicePointManager]::CertificatePolicy = $null
            }
        }
    }
    End
    {
    }
}

function Invoke-CisRest {

    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [VMware.VimAutomation.Cis.Core.Types.V1.CisServer]
        $Server=$Global:DefaultCisServers[0],
    
        [Parameter(Mandatory=$true)]
        [ValidateSet('Get','Post','Put','Delete','Patch')]
        [string]
        $Method,
    
        [Parameter(Mandatory=$true)]
        [String]
        $UriPath,
    
        [Parameter()]
        [System.Collections.Hashtable]
        $Body=@{}
        
    )
    Begin{   
    }
    Process
    {
        $Uri = 'https://'+$Server.Name+'/rest'+$UriPath
        $Headers = @{'vmware-api-session-id' = $Server.SessionSecret
                     'Accept' = 'application/json'
                     }
        $ContentType = 'application/json'

        if($Body) {
            # ConvertTo-Json escapes '\n' which we don't want.
            $JsonBody = ($Body | ConvertTo-Json -Depth 10).Replace('\\n','\n')
        }
        try {
            switch($Method) {
                'Get' {
                    $Response = Invoke-RestMethod -Method $Method -Uri $Uri -Body $Body -Headers $Headers
                    $Response.value
                }
                'Post' {
                    $Response = Invoke-RestMethod -ContentType $ContentType -Method $Method -Uri $Uri -Body $JsonBody -Headers $Headers
                    $Response.Value
                }
                'Put' {
                    Invoke-RestMethod -ContentType $ContentType -Method $Method -Uri $Uri -Body $JsonBody -Headers $Headers | Out-Null
                }        
                'Patch' {
                    Invoke-RestMethod -ContentType $ContentType -Method $Method -Uri $Uri -Body $JsonBody -Headers $Headers | Out-Null
                }
                'Delete' {
                    Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Headers | Out-Null
                }
            }
        }  
        catch{
            $_
            $ResponseStream = $_.Exception.Response.GetResponseStream()
            $Reader = New-Object System.IO.StreamReader($ResponseStream)
            $Reader.baseStream.Position=0
            $Reader.DiscardBufferedData()
            #$Reader.ReadToEnd() | ConvertFrom-Json 
            $Reader.ReadToEnd() | ConvertFrom-Json | Select-Object -ExpandProperty value | Select-Object -ExpandProperty messages        
        }
    }
    End
    {
    }
        
}