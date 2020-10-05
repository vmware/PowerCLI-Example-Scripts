// **************************************************************************
//  Copyright 2020 VMware, Inc.
// **************************************************************************
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

      public SsoAdminClient GetClient() {
         return _client;
      }

      public override string ToString() {
         return $"{Name}@{Domain}";
      }
   }
}
