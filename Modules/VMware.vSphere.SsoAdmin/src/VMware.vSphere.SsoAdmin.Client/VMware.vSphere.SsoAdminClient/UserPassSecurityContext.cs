// **************************************************************************
//  Copyright (c) VMware, Inc.  All rights reserved. -- VMware Confidential.
// **************************************************************************
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

      public XmlElement GetToken() {
         return _stsClient.IssueBearerTokenByUserCredential(
           _user,
           _password).RawToken;
      }
   }
}
