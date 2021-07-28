/*
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
*/

using System.Security.Cryptography.X509Certificates;

namespace VMware.vSphere.SsoAdminClient.DataTypes
{
    public class AuthenticationPolicy
    {
        SsoAdminClient _client;
        public AuthenticationPolicy(SsoAdminClient client) {
            _client = client;
        }

        public SsoAdminClient GetClient() {
            return _client;
        }

        public bool PasswordAuthnEnabled { get; internal set; }
        public bool WindowsAuthnEnabled { get; internal set; }
        public bool SmartCardAuthnEnabled { get; internal set; }
        public bool OCSPEnabled { get; internal set; }
        public bool UseCRLAsFailOver { get; internal set; }
        public bool SendOCSPNonce { get; internal set; }
        public string OCSPUrl { get; internal set; }
        public X509Certificate2  OCSPResponderSigningCert { get; internal set; }
        public bool UseInCertCRL { get; internal set; }
        public string CRLUrl { get; internal set; }
        public int CRLCacheSize { get; internal set; }
        public string[] Oids { get; internal set; }
        public string[] TrustedCAs { get; internal set; }

    }
}