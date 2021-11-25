/*
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
*/

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMware.vSphere.SsoAdminClient.DataTypes
{
   public class ActiveDirectoryIdentitySource : IdentitySource
   {
      public string Type { get; set; }
      public string Alias { get; set; }

      public string AuthenticationType { get; set; }
      public string AuthenticationUsername { get; set; }

      public string FriendlyName { get; set; }
      public string PrimaryUrl { get; set; }
      public string FailoverUrl { get; set; }
      public string UserBaseDN { get; set; }
      public string GroupBaseDN { get; set; }

      public System.Security.Cryptography.X509Certificates.X509Certificate2[] Certificates {get ;set;}
   }
}
