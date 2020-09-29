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
   public class PersonUser
   {
      public string Name { get; set; }
      public string Domain { get; set; }
      public string Description { get; set; }
      public string FirstName { get; set; }
      public string LastName { get; set; }
      public string EmailAddress { get; set; }

      public override string ToString() {
         return $"{Name}@{Domain}";
      }
   }
}
