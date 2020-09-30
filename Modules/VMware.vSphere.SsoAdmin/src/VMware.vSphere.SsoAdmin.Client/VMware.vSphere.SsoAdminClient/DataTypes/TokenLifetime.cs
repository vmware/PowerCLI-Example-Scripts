// **************************************************************************
//  Copyright (c) VMware, Inc.  All rights reserved. -- VMware Confidential.
// **************************************************************************

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMware.vSphere.SsoAdminClient.DataTypes
{
   public class TokenLifetime
   {
      SsoAdminClient _client;
      public TokenLifetime(SsoAdminClient client) {
         _client = client;
      }

      public SsoAdminClient GetClient() {
         return _client;
      }

      public long MaxHoKTokenLifetime { get; set; }
      public long MaxBearerTokenLifetime { get; set; }
   }
}
