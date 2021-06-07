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
   public class PersonUser
   {
      SsoAdminClient _client;
      public PersonUser(SsoAdminClient client) {
         _client = client;
      }

      public string Name { get; set; }
      public string Domain { get; set; }
      public string Description { get; set; }
      public string FirstName { get; set; }
      public string LastName { get; set; }
      public string EmailAddress { get; set; }
      public bool Locked { get; set; }
      public bool Disabled { get; set; }

      public Nullable<int> PasswordExpirationRemainingDays { get; set; }

      public SsoAdminClient GetClient() {
         return _client;
      }

      public override string ToString() {
         return $"{Name}@{Domain}";
      }
   }
}
