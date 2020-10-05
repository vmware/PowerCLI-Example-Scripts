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
   public class Group
   {
      public string Name { get; set; }
      public string Domain { get; set; }

      public override string ToString() {
         return $"{Name}@{Domain}";
      }
   }
}
