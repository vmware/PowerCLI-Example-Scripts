/*
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
*/
using System;
using System.Collections;
using System.Collections.Generic;
using System.IdentityModel.Selectors;
using System.Linq;
using System.Security;
using System.Security.Cryptography.X509Certificates;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.ServiceModel.Security;
using System.Text;
using LookupServiceReference;

namespace VMware.vSphere.LsClient
{
   public class LookupServiceClient {
      private const int WEB_OPERATION_TIMEOUT_SECONDS = 30;
      private LsPortTypeClient _lsClient;

      private static readonly ManagedObjectReference RootMoRef = new ManagedObjectReference
      {
         type = "LookupServiceInstance",
         Value = "ServiceInstance"
      };

      public LookupServiceClient(string hostname, X509CertificateValidator serverCertificateValidator) {
         var lsUri = $"https://{hostname}/lookupservice/sdk";

         _lsClient = new LsPortTypeClient(GetBinding(), new EndpointAddress(new Uri(lsUri)));

         var serverAuthentication = GetServerAuthentication(serverCertificateValidator);

         if (serverAuthentication != null)
         {
            _lsClient
               .ChannelFactory
               .Credentials
               .ServiceCertificate
               .SslCertificateAuthentication = serverAuthentication;
         }
      }

      #region Private Helpers
      private X509ServiceCertificateAuthentication GetServerAuthentication(X509CertificateValidator serverCertificateValidator)
      {
         if (serverCertificateValidator != null) {
            return new X509ServiceCertificateAuthentication {
               CertificateValidationMode = X509CertificateValidationMode.Custom,
               CustomCertificateValidator = serverCertificateValidator
            };
         }

         // Default .NET behavior for TLS certificate validation
         return null;
      }

      private static MessageEncodingBindingElement GetWcfEncoding()
      {
         return new TextMessageEncodingBindingElement(MessageVersion.Soap11, Encoding.UTF8);
      }

      private static HttpsTransportBindingElement GetWcfTransport(bool useSystemProxy)
      {
         HttpsTransportBindingElement transport = new HttpsTransportBindingElement
         {
            RequireClientCertificate = false
         };

         transport.UseDefaultWebProxy = useSystemProxy;
         transport.MaxBufferSize = 2147483647;
         transport.MaxReceivedMessageSize = 2147483647;

         return transport;
      }

      private static Binding GetBinding() {
        var binding = new CustomBinding(GetWcfEncoding(), GetWcfTransport(true));

         var timeout = TimeSpan.FromSeconds(WEB_OPERATION_TIMEOUT_SECONDS);
         binding.CloseTimeout = timeout;
         binding.OpenTimeout = timeout;
         binding.ReceiveTimeout = timeout;
         binding.SendTimeout = timeout;

         return binding;
      }
      #endregion

      public Uri GetSsoAdminEndpointUri() {
         var product = "com.vmware.cis";
         var endpointType = "com.vmware.cis.cs.identity.admin";
         var type = "sso:admin";
         return FindServiceEndpoint(product, type, endpointType);
      }

      public Uri GetStsEndpointUri() {
         var product = "com.vmware.cis";
         var type = "cs.identity";
         var endpointType = "com.vmware.cis.cs.identity.sso";
         return FindServiceEndpoint(product, type, endpointType);
      }

      private Uri FindServiceEndpoint(string product, string type, string endpointType) {
         Uri result = null;

         var svcContent = _lsClient.RetrieveServiceContentAsync(RootMoRef).Result;
         var filterCriteria = new LookupServiceRegistrationFilter() {
            serviceType = new LookupServiceRegistrationServiceType {
               product = product,
               type = type
            }
         };

         var lsRegInfo = _lsClient.
            ListAsync(svcContent.serviceRegistration, filterCriteria)
            .Result?
            .returnval?
            .FirstOrDefault();
         if (lsRegInfo != null) {
            var registrationEndpooint = lsRegInfo.
               serviceEndpoints?.
               Where(a => a.endpointType.type == endpointType)?.
               FirstOrDefault<LookupServiceRegistrationEndpoint>();
            if (registrationEndpooint != null) {
               result = new Uri(registrationEndpooint.url);
            }
         }
         return result;
      }
   }

}
