<#
.SYNOPSIS

Connects to VMware Cloud Partner Navigator

.DESCRIPTION

Uses refresh token to call the Navigator IAM API and get an access token that is stored in $Global:NavigatorConnection.accessToken

.PARAMETER RefreshToken
VMware Cloud Services Refresh Token

.PARAMETER Server
Used by VMware to connect to internal development instances of Navigator.

.INPUTS

None.

.OUTPUTS

None. Access Token is written to $Global:NavigatorConnection

.EXAMPLE

PS> Connect-Navigator -RefreshToken 12312313134123141234234525234523412341234234252451234123123123

#>
function Connect-Navigator {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]$RefreshToken,
        [String]$server = "https://console.navigator.vmware.com"
    )
    
    begin {
        
    }
    
    process {
        $connectionParams = @{
            uri                = "$($server)/cphub/api/auth/v1/authn/accesstoken";
            userAgent          = "Navigator-PowerShell";
            contentType        = "application/json";
            headers            = @{
                "X-XSRF-TOKEN" = "j4QPhAAZ-jwDjc4uI1Z8URuXJTqa9U4Y23rg";
            };
            body               = @{refreshToken = $refreshToken} | ConvertTo-Json;
            method             = "POST";
        }
        try {
            $response = Invoke-WebRequest @connectionParams
            $Global:NavigatorConnection = @{server = $server; accessToken = (ConvertFrom-Json $response.Content).accessToken}
        }
        catch {
            Write-Host $PSItem.Exception.Message -ForegroundColor RED
        }
        
    }
    end {
        
    }
}

<#
.SYNOPSIS

Retrieves Navigator Provider and Tenant organizations 

.DESCRIPTION

Retrieves Navigator Provider and Tenant organizations 

.PARAMETER OrgId
Specifies a specific OrgId to retrieve

.PARAMETER DisplayName
Retrieves orgs with specified display name

.PARAMETER OrgType
Can be used to search for "PROVIDER" or "TENANT" org types

.INPUTS

None.

.OUTPUTS

Navigator Org Objects

.EXAMPLE

PS> Get-NavigatorOrg -DisplayName "Foo" -OrgType "TENANT"

.EXAMPLE

PS> Get-NavigatorOrg -OrgId c28e8c89-d03d-4572-9be1-5f13edb82af6 

#>
function Get-NavigatorOrg {
    [CmdletBinding(DefaultParameterSetName = 'byNameAndType')]
    param (
        # Parameter help description
        [Parameter(ParameterSetName = 'byOrgId')]
        [String]$OrgID,
        # Parameter help description
        [Parameter(ParameterSetName = 'byNameAndType',Position=0)]
        [String]$DisplayName,
        # Parameter help description
        [Parameter(ParameterSetName = 'byNameAndType')]
        [String]$OrgType
    )
    
    begin {

    }
    
    process { 
        $headers = @{
            "csp-auth-token" = $Global:NavigatorConnection.accessToken;
        }

        if ($orgId) {
            try {
                $orgData = Invoke-WebRequest `
                -Uri "$($Global:NavigatorConnection.server)/cphub/api/core/v1/mgmt/orgs/$($orgId)/" `
                -Headers $headers
                Write-Verbose $orgData

                if ($orgData) {
                    $content = ConvertFrom-Json $orgData.Content
                    $content
                }

            }
            catch {
                Write-Host $PSItem.Exception.Message -ForegroundColor RED
            }
        } 
        else {
            $response = Invoke-WebRequest `
            -Uri "$($Global:NavigatorConnection.server)/cphub/api/auth/v1/loggedinuser/orgs" `
            -Headers $headers

            $orgIDs = (ConvertFrom-Json $response.Content).loggedInUserOrgs

            foreach ($orgID in $orgIDs) {
                $orgData = $null
                try {
                    $orgData = Invoke-WebRequest `
                    -Uri "$($Global:NavigatorConnection.server)/cphub/api/core/v1/mgmt/orgs/$($orgID)/" `
                    -Headers $headers
                    Write-Verbose $orgData

                    if ($orgData) {
                        $content = ConvertFrom-Json $orgData.Content

                        if ($orgType) {
                            $content = $content | Where-Object orgType -eq $orgType
                        }
                        if ($DisplayName) {
                            $content = $content | Where-Object DisplayName -like $DisplayName
                        }
                        $content | Add-Member -NotePropertyName orgId -NotePropertyValue $content.id
                        $content
                    }
                }
                
                catch {
                    #Write-Host $PSItem.Exception.Message -ForegroundColor RED
                    # Had to comment this catch out because we get 404s for orgs we belong to that are not navigator orgs.
                }
            }
        }
    }
    
    end {
        
    }
}

<#
.SYNOPSIS

Gets support requests for a given organization

.DESCRIPTION

Gets support requests for a given organization

.PARAMETER OrgId
Specifies a specific OrgID for which to retrieve support requests

.INPUTS

Navigator Org Object

.OUTPUTS

Navigator Support Ticket Object

.EXAMPLE

PS> Get-NavigatorSupportRequest -OrgId d7f32037-b9b5-41ec-9394-ba3edbbc9cac

.EXAMPLE

PS> Get-NavigatorOrg -OrgId d7f32037-b9b5-41ec-9394-ba3edbbc9cac | Get-NavigatorSupportRequest
#>
function Get-NavigatorSupportRequest {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
        [String]
        $orgID
    )
    
    begin {
        
    }
    
    process {
        $tickets = @()
        $headers = @{
            "csp-auth-token" = $Global:NavigatorConnection.accessToken;
        }
        try {
            $response = Invoke-WebRequest `
            -Headers $headers `
            -Uri "$($Global:NavigatorConnection.server)/cphub/api/support/v1/orgs/$orgID/support-requests?includeTenantOrgs=true&pageLimit=100&pageStart=1&userTicketsOnly=false"
            Write-Verbose $response
            #Write-Verbose ($response.Content | ConvertFrom-Json).supportTickets
            if ($response.Content) {
                $tickets += ($response.Content | ConvertFrom-Json).supportTickets    
            }
        }
        catch {
            Write-Host $PSItem.Exception.Message -ForegroundColor RED
        }

        $tickets
    }
    
    end {
        
    }
}

function Get-NavigatorSupportRequestMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
        [String]$ParentOrgId,
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
        [String]$OrgId
    )
    
    begin {
        
    }
    
    process {
        $headers = @{
            "csp-auth-token" = $Global:NavigatorConnection.accessToken;
        }

        try {
            $response = Invoke-WebRequest `
            -Headers $headers `
            -Uri "$($Global:NavigatorConnection.server)/cphub/api/support/v1/orgs/$ParentOrgId/support-requests/metadata?tenantId=$OrgId"
            Write-Verbose $response

            $jsonResponse = $response | ConvertFrom-Json


        }
        catch {
            Write-Host $PSItem.Exception.Message -ForegroundColor RED
        }
    }
    
    end {
        
    }
}

<#
.SYNOPSIS

Gets subscriptions for a given organization

.DESCRIPTION

Gets subscriptions for a given organization

.PARAMETER OrgId
Specifies a specific OrgID for which to retrieve subscriptions

.INPUTS

Navigator Org Object

.OUTPUTS

Navigator Subscription Object

.EXAMPLE

PS> Get-NavigatorSubscriptions -OrgId d7f32037-b9b5-41ec-9394-ba3edbbc9cac

.EXAMPLE

PS> Get-NavigatorOrg -OrgId d7f32037-b9b5-41ec-9394-ba3edbbc9cac | Get-NavigatorSubscriptions
#>
function Get-NavigatorSubscriptions {
    [CmdletBinding()]
    param (
        [String]$OrgId
    )
    
    begin {
        
    }
    
    process {
        $headers = @{
            "csp-auth-token" = $Global:NavigatorConnection.accessToken;
        }
        try {
            $response = Invoke-WebRequest `
            -Headers $headers `
            -Uri "$($Global:NavigatorConnection.server)/cphub/api/billing/v1/orgs/$OrgId/subscriptions?allTenants=true"
            Write-Verbose $response

            $response | ConvertFrom-Json
        }
        catch {
            Write-Host $PSItem.Exception.Message -ForegroundColor RED
        }
    }
    
    end {
        
    }
}

<#
.SYNOPSIS

Gets usage report for a given organization

.DESCRIPTION

Gets usage report for a given organization

.PARAMETER OrgId
Specifies a specific OrgID for which to retrieve usage

.INPUTS

Navigator Org Object

.OUTPUTS

Navigator usage report Object

.EXAMPLE

PS> Get-NavigatorUsageReport -OrgId d7f32037-b9b5-41ec-9394-ba3edbbc9cac

.EXAMPLE

PS> Get-NavigatorOrg -OrgId d7f32037-b9b5-41ec-9394-ba3edbbc9cac | Get-NavigatorUsageReport
#>
function Get-NavigatorUsageReport {
    [CmdletBinding()]
    param (
        [String]$OrgId
    )
    
    begin {
        
    }
    
    process {
        $headers = @{
            "csp-auth-token" = $Global:NavigatorConnection.accessToken;
        }
        try {
            $response = Invoke-WebRequest `
            -Headers $headers `
            -Uri "$($Global:NavigatorConnection.server)/cphub/api/billing/v1/orgs/$OrgId/usage-report?abd=false&detailView=false&providerReport=false"
            Write-Verbose $response

            $response | ConvertFrom-Json
        }
        catch {
            Write-Host $PSItem.Exception.Message -ForegroundColor RED
        }
    }
    
    end {
        
    }
}

<#
.SYNOPSIS

Creates a new Customer Organization in VMware Cloud Partner Navigator

.DESCRIPTION

Creates a new Customer Organization in VMware Cloud Partner Navigator


-City "Zionsville" -State "IN" -Zip "46077" -Country "US" -Domain "example.com" -verbose

.PARAMETER OrgId
Specifies a specific OrgID for which to retrieve subscriptions
.PARAMETER DisplayName
Specifies the short name for the organization
.PARAMETER CompanyName
Full company name of the organization
.PARAMETER AddressLine1
Address for the organization
.PARAMETER AddressLine2
Additional address line for the organization if needed
.PARAMETER City
City of the organization
.PARAMETER State
State of the organization
.PARAMETER Zip
Zip Code of the organizaiton
.PARAMETER Country
2-letter country code of the organization
.PARAMETER Domain
Domain name of the organization
.PARAMETER OrgId


.INPUTS

Navigator Provider Org Object

.OUTPUTS

Navigator Customer Record Object

.EXAMPLE

PS> New-NavigatorCustomer -OrgId d7f32037-b9b5-41ec-9394-ba3edbbc9cac -DisplayName Neptune -CompanyName Neptune -AddressLine1 "123 Fake St." -City "Zionsville" -State "IN" -Zip "46077" -Country "US" -Domain "example.com" -verbose

.EXAMPLE

PS> Get-NavigatorOrg -OrgId d7f32037-b9b5-41ec-9394-ba3edbbc9cac | New-NavigatorCustomer -DisplayName Neptune -CompanyName Neptune -AddressLine1 "123 Fake St." -City "Zionsville" -State "IN" -Zip "46077" -Country "US" -Domain "example.com" -verbose
#>
function New-NavigatorCustomer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
        [String]$OrgId,
        [Parameter(Mandatory=$true)]
        [String]$DisplayName,
        [Parameter(Mandatory=$true)]
        [String]$CompanyName,
        [String]$TenantType   = "DEFAULT",
 #       [String]$AdminUserEmail, # Call fails if this is provided.
        [Parameter(Mandatory=$true)]
        [String]$Domain,
        [Parameter(Mandatory=$true)]
        [String]$AddressLine1,
        [String]$AddressLine2 = '',
        [Parameter(Mandatory=$true)]
        [String]$City,
        [Parameter(Mandatory=$true)]
        [String]$State,
        [Parameter(Mandatory=$true)]
        [String]$Zip,
        [Parameter(Mandatory=$true)]
        [String]$Country,    # Country list has to come from /csp/gateway/iam/vmwid/api/user-registration/configuration/countries
        [String]$Tag          = ''
    )
    
    begin {
        if ($Country.Length -ne 2) {
            Write-Error -Message "Please use 2 letter country code." -ErrorAction Stop
        }
    }
    
    process {
        $headers = @{
            "csp-auth-token" = $Global:NavigatorConnection.accessToken
            "Content-Type" = "application/json"
        }

        $body = @{
            'displayName'    = $DisplayName
            'companyName'    = $CompanyName
            'tenantType'     = $TenantType
            'adminUserEmail' = ""
            'domain'         = $Domain
            'addressLine1'   = $AddressLine1
            'addressLine2'   = $AddressLine2
            'city'           = $City
            'state'          = $State
            'zip'            = $Zip
            'country'        = $Country
            'tag'            = $Tag
        }
        try {
            Write-Verbose ($body | ConvertTo-Json)
            $response = Invoke-WebRequest `
            -Headers $headers `
            -Uri "$($Global:NavigatorConnection.server)/cphub/api/core/v1/mgmt/orgs/$OrgId/tenants" `
            -Method "POST" `
            -Body ($body | ConvertTo-Json)
            Write-Verbose $response

            $response | ConvertFrom-Json
        }
        catch {
            Write-Host $PSItem.Exception.Message -ForegroundColor RED
        }
    }
    
    end {
        
    }
}

### GET CMDLET TEMPLATE SNIPPET
### COPY AND PASTE THIS FOR CREATING NEW GET CMDLET
# function Get-Navigator... {
#     [CmdletBinding()]
#     param (
#         [String]$OrgId
#     )
    
#     begin {
        
#     }
    
#     process {
#         $headers = @{
#             "csp-auth-token" = $Global:NavigatorConnection.accessToken;
#         }
#         try {
#             $response = Invoke-WebRequest `
#             -Headers $headers `
#             -Uri "$($Global:NavigatorConnection.server)/cphub/api/..."
#             Write-Verbose $response

#             $response | ConvertFrom-Json
#         }
#         catch {
#             Write-Host $PSItem.Exception.Message -ForegroundColor RED
#         }
#     }
    
#     end {
        
#     }
# }

Export-ModuleMember *
