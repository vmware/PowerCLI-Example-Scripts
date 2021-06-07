/*
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
*/

using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Security;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using VMware.vSphere.SsoAdminClient.DataTypes;

namespace VMware.vSphere.SsoAdmin.Utils
{
   public class StringToSsoAdminServerArgumentTransformationAttribute : ArgumentTransformationAttribute
   {
      public override object Transform(EngineIntrinsics engineIntrinsics, object inputData) {
         object result = inputData;

         if (inputData is string obnValue &&
             !string.IsNullOrEmpty(obnValue)) {
            // Adopt PowerShell regex chars
            var csharpObnValue = obnValue.Replace("*", ".*").Replace("?", ".?");
            result = null;

            var obnMatchingServers = new List<SsoAdminServer>();

            var ssoAdminServerVariable = engineIntrinsics.SessionState.PSVariable.GetValue("DefaultSsoAdminServers");

            if (ssoAdminServerVariable is PSObject ssoAdminServersPsObj &&
                ssoAdminServersPsObj.BaseObject is List<SsoAdminServer> connectedServers) {
               foreach (var server in connectedServers) {
                  if (!string.IsNullOrEmpty(Regex.Match(server.ToString(), csharpObnValue)?.Value)) {
                     obnMatchingServers.Add(server);
                  }
              }
            }

            if (obnMatchingServers.Count > 0) {
               result = obnMatchingServers.ToArray();
            } else {
               // Non-terminating error for not matching value
               engineIntrinsics.Host.UI.WriteErrorLine($"'{obnValue}' doesn't match any objects in $global:DefaultSsoAdminServers variable");
            }

         }

         return result;
      }
   }
}
