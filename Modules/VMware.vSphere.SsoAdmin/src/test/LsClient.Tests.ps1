#**************************************************************************
# Copyright (c) VMware, Inc. All rights reserved.
#**************************************************************************

param(
    [Parameter(Mandatory = $true)]
    [string]
    $VcAddress,

    [Parameter(Mandatory = $true)]
    [string]
    $VcUser,

    [Parameter(Mandatory = $true)]
    [string]
    $VcUserPassword
)

# Import Vmware.vSphere.SsoAdmin Module
$modulePath = Join-Path (Split-Path $PSScriptRoot | Split-Path) "VMware.vSphere.SsoAdmin.psd1"
Import-Module $modulePath

$script:lsClient = $null

Describe "Lookup Service Client Integration Tests" {
   Context "Retrieval of SsoAdmin API Url" {
      BeforeAll {
            ## Create LsClient
            $skipCertificateCheckValidator = New-Object `
            'VMware.vSphere.SsoAdmin.Utils.AcceptAllX509CertificateValidator'
            
            $script:lsClient = New-Object `
            'VMware.vSphere.LsClient.LookupServiceClient' `
            -ArgumentList @($VCAddress, $skipCertificateCheckValidator)
            
      }
      
      It 'Gets SsoAdmin API Url' {
         # Act
         $actual = $script:lsClient.GetSsoAdminEndpointUri()

         # Assert
         $actual | Should Not Be $null
         $actual.ToString().StartsWith("https://$VCAddress/sso-adminserver/sdk/") | Should Be $true
      }   
   }
}