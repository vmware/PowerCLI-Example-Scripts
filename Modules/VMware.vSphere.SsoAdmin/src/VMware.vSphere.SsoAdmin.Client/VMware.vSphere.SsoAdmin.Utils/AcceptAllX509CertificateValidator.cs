/*
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
*/

using System;
using System.IdentityModel.Selectors;
using System.Security.Cryptography.X509Certificates;

namespace VMware.vSphere.SsoAdmin.Utils
{
   public class AcceptAllX509CertificateValidator : X509CertificateValidator
   {
      public override void Validate(X509Certificate2 certificate) {
         // Check that there is a certificate.
         if (certificate == null) {
            throw new ArgumentNullException(nameof(certificate));
         }
      }
   }
}
