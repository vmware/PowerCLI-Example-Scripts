// **************************************************************************
//  Copyright 2020 VMware, Inc.
// **************************************************************************

using System;
using System.Collections.Generic;
using System.IdentityModel.Selectors;
using System.Linq;
using System.Security;
using System.Text;
using System.Threading.Tasks;
using VMware.Binding.Sts.StsService;

namespace VMware.vSphere.SsoAdminClient.DataTypes
{
   public class SsoAdminServer {

      private SsoAdminClient _client;

      public SsoAdminServer(string hostname, 
         string user, 
         SecureString password, 
         X509CertificateValidator serverCertificateValidator) {

         Name = hostname;

         _client = new SsoAdminClient(
            hostname,
            user,
            password,
            serverCertificateValidator);

         Id = $"/SsoAdminServer={NormalizeUserName()}@{Name}";
      }

      private string NormalizeUserName() {
         string result = User;
         if (User.Contains('@')) {
            var parts = User.Split('@');
            var userName = parts[0];
            var domain = parts[1];
            result = $"{domain}/{userName}";
         }
         return result;
      }

      public string Name { get; }
      public Uri ServiceUri => _client?.ServiceUri;
      public string User => _client?.User;
      public string Id { get; set; }
      public bool IsConnected => _client != null;
      public SsoAdminClient Client => _client;

      public void Disconnect() {
         _client = null;
      }

      public override string ToString() {
         return Name;
      }

      public override int GetHashCode() {
         return Id != null ? Id.GetHashCode() : base.GetHashCode();
      }

      public override bool Equals(object obj) {
         bool result = false;
         if (obj is SsoAdminServer target) {
            result = string.Equals(Id, target.Id);
         }
         return result;
      }
   }
}
