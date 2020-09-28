// **************************************************************************
//  Copyright (c) VMware, Inc.  All rights reserved. -- VMware Confidential.
// **************************************************************************

using System;
using System.Collections.Generic;
using System.IdentityModel.Selectors;
using System.Security;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.ServiceModel.Security;
using System.Text;
using VMware.Binding.WsTrust;
using VMware.Binding.WsTrust.SecurityContext;
using VMware.vSphere.LsClient;
using VMware.vSphere.SsoAdminClient.DataTypes;
using VMware.vSphere.SsoAdminClient.SsoAdminServiceReferencer;

namespace VMware.vSphere.SsoAdminClient
{
   public class SsoAdminClient
   {
      private const int WEB_OPERATION_TIMEOUT_SECONDS = 30;

      private string _server;      
      private SsoPortTypeClient _ssoAdminBindingClient;
      private UserPassSecurityContext _securityContext;

      public SsoAdminClient(string hostname, string user, SecureString password, X509CertificateValidator serverCertificateValidator) {
         if (hostname == null) throw new ArgumentNullException(nameof(hostname));
         if (user == null) throw new ArgumentNullException(nameof(user));
         if (password == null) throw new ArgumentNullException(nameof(password));

         _server = hostname;
         var lsClient = new LookupServiceClient(hostname, serverCertificateValidator);
         
         // Create STS Client
         var stsUri = lsClient.GetStsEndpointUri();
         _securityContext = new UserPassSecurityContext(user, password, stsUri, serverCertificateValidator);

         // Create SSO Admin Binding Client
         var ssoAdminUri = lsClient.GetSsoAdminEndpointUri();
         _ssoAdminBindingClient = new SsoPortTypeClient(GetBinding(), new EndpointAddress(ssoAdminUri));
         _ssoAdminBindingClient.ChannelFactory.Endpoint.EndpointBehaviors.Add(new WsTrustBehavior());

         var serverAuthentication = GetServerAuthentication(serverCertificateValidator);

         if (serverAuthentication != null) {
            _ssoAdminBindingClient
               .ChannelFactory
               .Credentials
               .ServiceCertificate
               .SslCertificateAuthentication = serverAuthentication;
         }
      }

      #region Private Helpers
      private X509ServiceCertificateAuthentication GetServerAuthentication(X509CertificateValidator serverCertificateValidator) {
         if (serverCertificateValidator != null) {
            return new X509ServiceCertificateAuthentication {
               CertificateValidationMode = X509CertificateValidationMode.Custom,
               CustomCertificateValidator = serverCertificateValidator
            };
         }

         // Default .NET behavior for TLS certificate validation
         return null;
      }

      private static MessageEncodingBindingElement GetWcfEncoding() {
         // VMware STS requires SOAP version 1.1
         return new TextMessageEncodingBindingElement(MessageVersion.Soap11, Encoding.UTF8);
      }

      private static HttpsTransportBindingElement GetWcfTransport(bool useSystemProxy) {
         // Communication with the STS is over https
         HttpsTransportBindingElement transport = new HttpsTransportBindingElement {
            RequireClientCertificate = false
         };

         transport.UseDefaultWebProxy = useSystemProxy;
         transport.MaxBufferSize = 2147483647;
         transport.MaxReceivedMessageSize = 2147483647;

         return transport;
      }

      private static CustomBinding GetBinding() {

         // There is no build-in WCF binding capable of communicating
         // with VMware STS, so we create a plain custom one.
         // This binding does not provide support for WS-Trust,
         // that support is currently implemented as a WCF endpoint behaviour.
         var binding = new CustomBinding(GetWcfEncoding(), GetWcfTransport(true));

         var timeout = TimeSpan.FromSeconds(WEB_OPERATION_TIMEOUT_SECONDS);
         binding.CloseTimeout = timeout;
         binding.OpenTimeout = timeout;
         binding.ReceiveTimeout = timeout;
         binding.SendTimeout = timeout;

         return binding;
      }

      private WsSecurityContext CreateAuthorizedInvocationContext() {
         // Issue Bearer token to authorize create solution user to SSO Admin service
         var bearerToken = _securityContext.GetToken();

         // Set WS Trust Header Serialization with issued bearer SAML token
         var securityContext = new WsSecurityContext {
            ClientChannel = _ssoAdminBindingClient.InnerChannel,
            Properties = {
               Credentials = {
                  BearerToken = bearerToken
               }
            }
         };
         return securityContext;
      }
      #endregion

      #region Public interface

      public Principal CreateLocalUser(         
         string userName,
         string password,
         string description = null,
         string emailAddress = null,
         string firstName = null,
         string lastName = null) {

         // Create Authorization Invocation Context
         var authorizedInvocationContext =
            CreateAuthorizedInvocationContext();

         // Invoke SSO Admin CreateLocalSolutionUser operation
         var ssoPrincipalId = authorizedInvocationContext.
            InvokeOperation(() =>
               _ssoAdminBindingClient.CreateLocalPersonUserAsync(
                  new ManagedObjectReference {
                     type = "SsoAdminPrincipalManagementService",
                     Value = "principalManagementService"
                  },
                  userName,
                  new SsoAdminPersonDetails {
                     description = description,
                     emailAddress = emailAddress,
                     firstName = firstName,
                     lastName = lastName
                  },
                  password)).Result;

         return GetLocalUsers(ssoPrincipalId.name, ssoPrincipalId.domain, authorizedInvocationContext);
      }

      private Principal GetLocalUsers(string userName, string domain, WsSecurityContext wsSecurityContext) {
         // Invoke SSO Admin FindPersonUserAsync operation
         var personUser = wsSecurityContext.
            InvokeOperation(() =>
               _ssoAdminBindingClient.FindPersonUserAsync(
                  new ManagedObjectReference {
                     type = "SsoAdminPrincipalDiscoveryService",
                     Value = "principalDiscoveryService"
                  },
                  new SsoPrincipalId {
                     name = userName,
                     domain = domain
                  })).Result;
         return new Principal {
            Name = personUser.id.name,
            Domain = personUser.id.domain,
            Description = personUser.details.description,
            FirstName = personUser.details.firstName,
            LastName = personUser.details.lastName,
            EmailAddress = personUser.details.emailAddress
         };
      }

      public IEnumerable<Principal> GetAllLocalUsers() {
         // Create Authorization Invocation Context
         var authorizedInvocationContext =
            CreateAuthorizedInvocationContext();

         // Invoke SSO Admin FindPersonUsersAsync operation
         var personUsers = authorizedInvocationContext.
            InvokeOperation(() =>
               _ssoAdminBindingClient.FindPersonUsersAsync(
                  new ManagedObjectReference {
                     type = "SsoAdminPrincipalDiscoveryService",
                     Value = "principalDiscoveryService"
                  },                  
                  new SsoAdminPrincipalDiscoveryServiceSearchCriteria (),
                  int.MaxValue)).Result.returnval;

         foreach (var personUser in personUsers) {
            yield return new Principal {
               Name = personUser.id.name,
               Domain = personUser.id.domain,
               Description = personUser.details.description,
               FirstName = personUser.details.firstName,
               LastName = personUser.details.lastName,
               EmailAddress = personUser.details.emailAddress
            };
         }
      }

      public void DeleteLocalUser(
         Principal principal) {

         // Create Authorization Invocation Context
         var authorizedInvocationContext =
            CreateAuthorizedInvocationContext();

         // Invoke SSO Admin DeleteLocalPrincipal operation
         authorizedInvocationContext.
            InvokeOperation(() =>
               _ssoAdminBindingClient.DeleteLocalPrincipalAsync(
                  new ManagedObjectReference {
                     type = "SsoAdminPrincipalManagementService",
                     Value = "principalManagementService"
                  },
                  principal.Name));
      }

      #endregion
   }
}
