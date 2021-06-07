/*
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
*/

using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceModel.Security;
using System.Text;
using System.Threading.Tasks;

namespace VMware.vSphere.SsoAdminClient.DataTypes
{
   public class LockoutPolicy
   {
      SsoAdminClient _client;
      public LockoutPolicy(SsoAdminClient client) {
         _client = client;
      }

      public SsoAdminClient GetClient() {
         return _client;
      }

      public string Description { get; set; }
      public long AutoUnlockIntervalSec { get; set; }
      public long FailedAttemptIntervalSec { get; set; }
      public int MaxFailedAttempts { get; set; }
   }
}
