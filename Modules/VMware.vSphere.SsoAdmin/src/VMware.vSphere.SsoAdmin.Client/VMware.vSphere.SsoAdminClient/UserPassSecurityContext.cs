/*
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
*/
using System;
using System.Collections.Generic;
using System.IdentityModel.Selectors;
using System.Linq;
using System.Security;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;
using System.Xml;
using VMware.Binding.Sts;

namespace VMware.vSphere.SsoAdminClient
{
   public class UserPassSecurityContext
   {
      private string _user;
      private SecureString _password;
      private VmwareSecruityTokenService _stsClient;
      private SamlSecurityToken _validToken;
      public UserPassSecurityContext(
         string user,
         SecureString password,
         Uri stsUri,
         X509CertificateValidator serverCertificateValidator) {

         if (user == null) throw new ArgumentNullException(nameof(user));
         if (password == null) throw new ArgumentNullException(nameof(password));
         if (stsUri == null) throw new ArgumentNullException(nameof(stsUri));

         _user = user;
         _password = password;

         Action<X509Certificate2> certHandler = null;
         if (serverCertificateValidator != null) {
            certHandler = serverCertificateValidator.Validate;
         }
         _stsClient = new VmwareSecruityTokenService(stsUri, false, certHandler);
      }

      private void RenewIfNeeded() {
         if (_validToken == null ||
             _validToken.Expires < (DateTime.Now + new TimeSpan(0, 0, 30))) {
            _validToken = _stsClient.IssueBearerTokenByUserCredential(
              _user,
              _password);
         }
      }

      public XmlElement GetToken() {
         RenewIfNeeded();
         return _validToken.RawToken;
      }
   }
}
