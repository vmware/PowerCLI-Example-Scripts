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
   public class PasswordPolicy
   {
      SsoAdminClient _client;
      public PasswordPolicy(SsoAdminClient client) {
         _client = client;
      }

      public string Description { get; set; }
      public int ProhibitedPreviousPasswordsCount { get; set; }
      public int MinLength { get; set; }
      public int MaxLength { get; set; }
      public int MinNumericCount { get; set; }
      public int MinSpecialCharCount { get; set; }
      public int MaxIdenticalAdjacentCharacters { get; set; }
      public int MinAlphabeticCount { get; set; }
      public int MinUppercaseCount { get; set; }
      public int MinLowercaseCount { get; set; }
      public int PasswordLifetimeDays { get; set; }

      public SsoAdminClient GetClient() {
         return _client;
      }
   }
}
