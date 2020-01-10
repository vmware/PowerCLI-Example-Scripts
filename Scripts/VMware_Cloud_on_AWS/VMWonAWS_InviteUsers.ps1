<#  
.SYNOPSIS  
    Takes email address input in order to create VMware Cloud on AWS invites for the desired Organization
.DESCRIPTION 
    Script which can be used to automate the process of adding new users to a specified VMware Cloud on AWS Organization
.NOTES  
    Author:  Kyle Ruddy, @kmruddy, kmruddy.com
.PARAMETER newUserEmail
	Plain text email address or array of email addresses
.PARAMETER roleName
	Desired role name of the new users, default is Organization Member
.EXAMPLE
   PS > ./VMWonAWS_InviteUsers.ps1 -newUserEmail 'testuser@vmware.com'
.EXAMPLE 
   PS > ./VMWonAWS_InviteUsers.ps1 -newUserEmail $arrayOfEmailAddresses
#>
[CmdletBinding(SupportsShouldProcess=$True)] 
    param (

        [Parameter (Mandatory = $True, Position=0)]
        $newUserEmail,
        [Parameter (Mandatory = $False, Position=1)]
        [ValidateSet("Organization Member","Organization Owner","Support User")]
        [string]$roleName = "Organization Member"
    )

    # Set Static Variables for your environment 
    $oauthToken = 'xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    $orgID = 'xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    
    ### DO NOT MODIFY CODE BELOW THIS LINE ###
    $inviteReport = @()
    $userEmail = @()

    # Email Validation Testing
    if ($newUserEmail -is [array]) {
        foreach ($email in $newUserEmail) {
            try {
				$userEmail += [mailAddress]$email | select-object -ExpandProperty Address
			}
			catch {
				Write-Warning "$email is not a valid email address"
			}
        }
    }
    else {
		try {
			$userEmail += [mailAddress]$newUserEmail | select-object -ExpandProperty Address
		}
		catch {
			Write-Warning "$newUserEmail is not a valid email address"
		}
    }
    
	if ($userEmail.Count -eq 0) {
        Write-Warning "No valid email addresses found."
		Break
    }

    # Validation and translation of the role name to the role ID
    if ($roleName -eq 'Organization Member') {
        $orgRoleNames = @("org_member")
    }
    elseif ($roleName -eq 'Organization Owner') {
        $orgRoleNames = @("org_owner")
    }
    elseif ($roleName -eq 'Support User') {
        $orgRoleNames = @("support_user")
    }

    # Creating custom objects to start building out the body input
    $bodyObj = new-object -TypeName System.Object      
    $SvcRoleNames = @("vmc-user:full")
    $SvcDefinitionLink = '/csp/gateway/slc/api/definitions/external/ybUdoTC05kYFC9ZG560kpsn0I8M_'
    $bodyObj | Add-Member -Name 'orgRoleNames' -MemberType Noteproperty -Value $orgRoleNames
    $serviceRolesDtos = New-Object -TypeName System.Object
    $serviceRolesDtos | Add-Member -Name 'serviceDefinitionLink' -MemberType Noteproperty -Value $SvcDefinitionLink
    $serviceRolesDtos | Add-Member -Name 'serviceRoleNames' -MemberType Noteproperty -Value $SvcRoleNames
    $bodyObj | Add-Member -Name 'serviceRolesDtos' -MemberType Noteproperty -Value @($serviceRolesDtos)
    $bodyObj | Add-Member -Name 'usernames' -MemberType Noteproperty -Value $userEmail
    $body = $bodyObj | ConvertTo-Json -Depth 100

    # Connecting to the REST API service for authentication and then to perform the POST method 
    $connection = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize?refresh_token=$oauthToken" -Method Post
    $accesskey = ($connection.content | Convertfrom-json).access_token
    $inviteUsers = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/orgs/$orgID/invitations" -headers @{"csp-auth-token"="$accesskey"} -Method Post -Body $body -ContentType "application/json"

    # Outputting the successful invite which was just created
    $orgInviteRefResponse = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/orgs/$orgid/invitations" -headers @{"csp-auth-token"="$accessKey"} -Method Get
    if ($orgInviteRefResponse) {
        $orgInviteRefObject = $orgInviteRefResponse | ConvertFrom-Json

        foreach ($inviteRef in $orgInviteRefObject) {
            $link = $inviteRef.refLink
            $orgInviteResponse = Invoke-WebRequest -Uri "https://console.cloud.vmware.com$link" -headers @{"csp-auth-token"="$accessKey"} -Method Get

            $orgInviteObject = $orgInviteResponse.content | ConvertFrom-Json

            foreach ($emailInput in $userEmail) {

                if ($orgInviteObject.username -eq $emailInput) {
                    $i = New-Object System.Object
                    $i | Add-Member -Type NoteProperty -Name InviteID -Value $orgInviteObject.refLink.Substring($orgInviteObject.refLink.Length - 36)
                    $i | Add-Member -Type NoteProperty -Name Username -Value $orgInviteObject.username
                    $i | Add-Member -Type NoteProperty -Name Status -Value $orgInviteObject.status
                    $i | Add-Member -Type NoteProperty -Name OrgRoles -Value ($orgInviteObject.OrgRoleNames -join ", ")
                    $i | Add-Member -Type NoteProperty -Name Requester -Value $orgInviteObject.generatedBy
                    $inviteReport += $i
                }
            }
        }
    }

    return $inviteReport