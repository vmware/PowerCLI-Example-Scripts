<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>

param(
    [Parameter(Mandatory = $true)]
    [string]
    $VcAddress,

    [Parameter(Mandatory = $true)]
    [string]
    $User,

    [Parameter(Mandatory = $true)]
    [string]
    $Password
)

# Import Vmware.vSphere.SsoAdmin Module
$modulePath = Join-Path (Split-Path $PSScriptRoot | Split-Path) "VMware.vSphere.SsoAdmin.psd1"
Import-Module $modulePath

$script:lsClient = $null

Describe "Lookup Service Client Integration Tests" {
   Context "Retrieval of Service API Url" {
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
         $actual | Should -Not -Be $null
         $actual.ToString().StartsWith("https://$VCAddress/sso-adminserver/sdk/") | Should -Be $true
      }

      It 'Gets STS API Url' {
         # Act
         $actual = $script:lsClient.GetStsEndpointUri()

         # Assert
         $actual | Should -Not -Be $null
         $actual.ToString().StartsWith("https://$VCAddress/sts/STSService") | Should -Be $true
      }
   }
}