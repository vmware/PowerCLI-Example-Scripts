/*
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
*/

using System;
using System.Collections.Generic;
using System.IdentityModel.Selectors;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.WindowsRuntime;
using System.Security;
using System.Security.Cryptography.X509Certificates;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.ServiceModel.Security;
using System.Text;
using System.Text.RegularExpressions;
using VMware.Binding.WsTrust;
using VMware.Binding.WsTrust.SecurityContext;
using VMware.vSphere.LsClient;
using VMware.vSphere.SsoAdminClient.DataTypes;
using VMware.vSphere.SsoAdminClient.SsoAdminServiceReference2;

namespace VMware.vSphere.SsoAdminClient
{
    public class SsoAdminClient
    {
        private const int WEB_OPERATION_TIMEOUT_SECONDS = 300;

        private SsoPortTypeClient _ssoAdminBindingClient;
        private UserPassSecurityContext _securityContext;

        public SsoAdminClient(string hostname, string user, SecureString password, X509CertificateValidator serverCertificateValidator)
        {
            if (hostname == null) throw new ArgumentNullException(nameof(hostname));
            if (user == null) throw new ArgumentNullException(nameof(user));
            if (password == null) throw new ArgumentNullException(nameof(password));

            var lsClient = new LookupServiceClient(hostname, serverCertificateValidator);

            // Create STS Client
            var stsUri = lsClient.GetStsEndpointUri();
            _securityContext = new UserPassSecurityContext(user, password, stsUri, serverCertificateValidator);
            // Initialize security context with Saml token by username and password
            _securityContext.GetToken();

            // Create SSO Admin Binding Client
            var ssoAdminUri = lsClient.GetSsoAdminEndpointUri();
            ServiceUri = ssoAdminUri;
            User = user;
            _ssoAdminBindingClient = new SsoPortTypeClient(GetBinding(), new EndpointAddress(ssoAdminUri));
            _ssoAdminBindingClient.ChannelFactory.Endpoint.EndpointBehaviors.Add(new WsTrustBehavior());

            var serverAuthentication = GetServerAuthentication(serverCertificateValidator);

            if (serverAuthentication != null)
            {
                _ssoAdminBindingClient
                   .ChannelFactory
                   .Credentials
                   .ServiceCertificate
                   .SslCertificateAuthentication = serverAuthentication;
            }
        }

        #region Private Helpers
        private X509ServiceCertificateAuthentication GetServerAuthentication(X509CertificateValidator serverCertificateValidator)
        {
            if (serverCertificateValidator != null)
            {
                return new X509ServiceCertificateAuthentication
                {
                    CertificateValidationMode = X509CertificateValidationMode.Custom,
                    CustomCertificateValidator = serverCertificateValidator
                };
            }

            // Default .NET behavior for TLS certificate validation
            return null;
        }

        private static MessageEncodingBindingElement GetWcfEncoding()
        {
            // VMware STS requires SOAP version 1.1
            return new TextMessageEncodingBindingElement(MessageVersion.Soap11, Encoding.UTF8);
        }

        private static HttpsTransportBindingElement GetWcfTransport(bool useSystemProxy)
        {
            // Communication with the STS is over https
            HttpsTransportBindingElement transport = new HttpsTransportBindingElement
            {
                RequireClientCertificate = false
            };

            transport.UseDefaultWebProxy = useSystemProxy;
            transport.MaxBufferSize = 2147483647;
            transport.MaxReceivedMessageSize = 2147483647;

            return transport;
        }

        private static CustomBinding GetBinding()
        {

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

        private WsSecurityContext CreateAuthorizedInvocationContext()
        {
            // Issue Bearer token to authorize create solution user to SSO Admin service
            var bearerToken = _securityContext.GetToken();

            // Set WS Trust Header Serialization with issued bearer SAML token
            var securityContext = new WsSecurityContext
            {
                ClientChannel = _ssoAdminBindingClient.InnerChannel,
                Properties = {
               Credentials = {
                  BearerToken = bearerToken
               }
            }
            };
            return securityContext;
        }

        String SecureStringToString(SecureString value)
        {
            IntPtr valuePtr = IntPtr.Zero;
            try
            {
                valuePtr = Marshal.SecureStringToGlobalAllocUnicode(value);
                return Marshal.PtrToStringUni(valuePtr);
            }
            finally
            {
                Marshal.ZeroFreeGlobalAllocUnicode(valuePtr);
            }
        }
        #endregion

        #region Public interface

        public Uri ServiceUri { get; }
        public string User { get; }

        public PersonUser CreateLocalUser(
           string userName,
           string password,
           string description = null,
           string emailAddress = null,
           string firstName = null,
           string lastName = null)
        {

            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin CreateLocalSolutionUser operation
            var ssoPrincipalId = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.CreateLocalPersonUserAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     userName,
                     new SsoAdminPersonDetails
                     {
                         description = description,
                         emailAddress = emailAddress,
                         firstName = firstName,
                         lastName = lastName
                     },
                     password)).Result;

            return GetLocalUsers(ssoPrincipalId.name, ssoPrincipalId.domain, authorizedInvocationContext);
        }

        private PersonUser GetLocalUsers(string userName, string domain, WsSecurityContext wsSecurityContext)
        {
            // Invoke SSO Admin FindPersonUserAsync operation
            var personUser = wsSecurityContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.FindPersonUserAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalDiscoveryService",
                         Value = "principalDiscoveryService"
                     },
                     new SsoPrincipalId
                     {
                         name = userName,
                         domain = domain
                     })).Result;

            Nullable<int> passwordRemainingDays = null;
            try {
                passwordRemainingDays = wsSecurityContext.
                    InvokeOperation(() =>
                        _ssoAdminBindingClient.GetDaysRemainingUntilPasswordExpirationAsync(
                            new ManagedObjectReference
                            {
                               type = "SsoAdminPrincipalManagementService",
                               Value = "principalManagementService"
                            },
                            new SsoPrincipalId
                            {
                                name = userName,
                                domain = domain
                            })).Result;
            } catch {}


            return new PersonUser(this)
            {
                Name = personUser.id.name,
                Domain = personUser.id.domain,
                Description = personUser.details.description,
                FirstName = personUser.details.firstName,
                LastName = personUser.details.lastName,
                EmailAddress = personUser.details.emailAddress,
                Locked = personUser.locked,
                Disabled = personUser.disabled,
                PasswordExpirationRemainingDays = passwordRemainingDays
            };
        }

        public IEnumerable<PersonUser> GetLocalUsers(string searchString, string domain)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin FindPersonUsersAsync operation
            var personUsers = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.FindPersonUsersAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalDiscoveryService",
                         Value = "principalDiscoveryService"
                     },
                     new SsoAdminPrincipalDiscoveryServiceSearchCriteria
                     {
                         searchString = searchString,
                         domain = domain
                     },
                     int.MaxValue)).Result.returnval;

            if (personUsers != null)
            {
                foreach (var personUser in personUsers)
                {
                    Nullable<int> passwordRemainingDays = null;
                    try {
                        passwordRemainingDays = authorizedInvocationContext.
                            InvokeOperation(() =>
                                _ssoAdminBindingClient.GetDaysRemainingUntilPasswordExpirationAsync(
                                    new ManagedObjectReference
                                    {
                                       type = "SsoAdminPrincipalManagementService",
                                       Value = "principalManagementService"
                                    },
                                   personUser.id)).Result;
                    } catch {}
                    yield return new PersonUser(this)
                    {
                        Name = personUser.id.name,
                        Domain = personUser.id.domain,
                        Description = personUser.details.description,
                        FirstName = personUser.details.firstName,
                        LastName = personUser.details.lastName,
                        EmailAddress = personUser.details.emailAddress,
                        Locked = personUser.locked,
                        Disabled = personUser.disabled,
                        PasswordExpirationRemainingDays = passwordRemainingDays
                    };
                }
            }

        }

        public IEnumerable<PersonUser> GetPersonUsersInGroup(string searchString, DataTypes.Group group)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin FindPersonUsersAsync operation
            var personUsers = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.FindPersonUsersInGroupAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalDiscoveryService",
                         Value = "principalDiscoveryService"
                     },
                     new SsoPrincipalId
                     {
                         name = group.Name,
                         domain = group.Domain
                     },
                     searchString,
                     int.MaxValue)).Result.returnval;

            if (personUsers != null)
            {
                foreach (var personUser in personUsers)
                {
                     Nullable<int> passwordRemainingDays = null;
                     try
                     {
                        passwordRemainingDays = authorizedInvocationContext.
                            InvokeOperation(() =>
                                _ssoAdminBindingClient.GetDaysRemainingUntilPasswordExpirationAsync(
                                    new ManagedObjectReference
                                    {
                                       type = "SsoAdminPrincipalManagementService",
                                       Value = "principalManagementService"
                                    },
                                   personUser.id)).Result;
                     } catch {}
                     yield return new PersonUser(this)
                     {
                        Name = personUser.id.name,
                        Domain = personUser.id.domain,
                        Description = personUser.details.description,
                        FirstName = personUser.details.firstName,
                        LastName = personUser.details.lastName,
                        EmailAddress = personUser.details.emailAddress,
                        Locked = personUser.locked,
                        Disabled = personUser.disabled,
                        PasswordExpirationRemainingDays = passwordRemainingDays
                     };
                }
            }
        }

        public void DeleteLocalUser(
           PersonUser principal)
        {

            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin DeleteLocalPrincipal operation
            authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.DeleteLocalPrincipalAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     principal.Name));
        }

        private DataTypes.Group FindGroup(string name, string domain, WsSecurityContext wsSecurityContext)
        {
            // Invoke SSO Admin FindGroupAsync operation
            var group = wsSecurityContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.FindGroupAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalDiscoveryService",
                         Value = "principalDiscoveryService"
                     },
                     new SsoPrincipalId
                     {
                         name = name,
                         domain = domain
                     })).Result;

            return new DataTypes.Group(this)
            {
                Name = group.id.name,
                Domain = group.id.domain,
                Description = group.details.description
            };
        }

        public IEnumerable<DataTypes.Group> GetGroupsInGroup(string searchString, DataTypes.Group group)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin FindGroupsInGroupResponse operation
            var groups = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.FindGroupsInGroupAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalDiscoveryService",
                         Value = "principalDiscoveryService"
                     },
                     new SsoPrincipalId
                     {
                         name = group.Name,
                         domain = group.Domain
                     },
                     searchString,
                     int.MaxValue)).Result.returnval;

            if (groups != null)
            {
                foreach (var g in groups)
                {
                    yield return new DataTypes.Group(this)
                    {
                        Name = g.id.name,
                        Domain = g.id.domain,
                        Description = g.details.description
                    };
                }
            }
        }

        public DataTypes.Group CreateLocalGroup(string name, string description)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin FindGroupsAsync operation
            var ssoAdminGroup = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.CreateLocalGroupAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     name,
                     new SsoAdminGroupDetails
                     {
                         description = description
                     })).Result;

            if (ssoAdminGroup != null)
            {
                return FindGroup(ssoAdminGroup.name, ssoAdminGroup.domain, authorizedInvocationContext);
            }
            else
            {
                return null;
            }
        }

        public DataTypes.Group UpdateLocalGroup(DataTypes.Group group, string description)
        {
            if (description == null) {
                description = string.Empty;
            }

            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin DeleteLocalPrincipal operation
            var updatedGroup = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.UpdateLocalGroupDetailsAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     group.Name,
                     new SsoAdminGroupDetails
                     {
                         description = description
                     })).Result;

            if (updatedGroup != null)
            {
                return FindGroup(updatedGroup.name, updatedGroup.domain, authorizedInvocationContext);
            }
            else
            {
                return null;
            }
        }


        public void RemoveLocalGroup(DataTypes.Group group)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin DeleteLocalPrincipal operation
            authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.DeleteLocalPrincipalAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     group.Name));
        }

        public IEnumerable<DataTypes.Group> GetGroups(string searchString, string domain)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin FindGroupsAsync operation
            var ssoAdminGroups = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.FindGroupsAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalDiscoveryService",
                         Value = "principalDiscoveryService"
                     },
                     new SsoAdminPrincipalDiscoveryServiceSearchCriteria
                     {
                         searchString = searchString,
                         domain = domain
                     },
                     int.MaxValue)).Result.returnval;

            if (ssoAdminGroups != null)
            {
                foreach (var group in ssoAdminGroups)
                {
                    yield return FindGroup(group.id.name, group.id.domain, authorizedInvocationContext);
                }
            }
        }

        public bool AddPersonUserToGroup(PersonUser user, DataTypes.Group group)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin AddUserToLocalGroupAsync operation
            return authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.AddUserToLocalGroupAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     new SsoPrincipalId
                     {
                         name = user.Name,
                         domain = user.Domain
                     },
                     group.Name)).Result;
        }

        public bool AddGroupToGroup(DataTypes.Group groupToAdd, DataTypes.Group destinationGroup)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin AddGroupToLocalGroupAsync operation
            return authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.AddGroupToLocalGroupAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     new SsoPrincipalId
                     {
                         name = groupToAdd.Name,
                         domain = groupToAdd.Domain
                     },
                     destinationGroup.Name)).Result;
        }

        public bool RemovePersonUserFromGroup(PersonUser user, DataTypes.Group group)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin RemoveFromLocalGroupAsync operation
            return authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.RemoveFromLocalGroupAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     new SsoPrincipalId
                     {
                         name = user.Name,
                         domain = user.Domain
                     },
                     group.Name)).Result;
        }

        public bool RemoveGroupFromGroup(DataTypes.Group groupToRemove, DataTypes.Group group)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin RemoveFromLocalGroupAsync operation
            return authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.RemoveFromLocalGroupAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     new SsoPrincipalId
                     {
                         name = groupToRemove.Name,
                         domain = groupToRemove.Domain
                     },
                     group.Name)).Result;
        }

        public void ResetPersonUserPassword(PersonUser user, string newPassword)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin ResetLocalPersonUserPasswordAsync operation
            authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.ResetLocalPersonUserPasswordAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     user.Name,
                     newPassword)).Wait();
        }

        public void ResetSelfPersonUserPassword(SecureString newPassword)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin ResetLocalPersonUserPasswordAsync operation
            authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.ResetSelfLocalPersonUserPasswordAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     SecureStringToString(newPassword))).Wait();
        }

        public bool UnlockPersonUser(PersonUser user)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin UnlockUserAccountAsync operation
            return authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.UnlockUserAccountAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     new SsoPrincipalId
                     {
                         name = user.Name,
                         domain = user.Domain
                     })).Result;
        }

        public bool EnablePersonUser(PersonUser user)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin EnableUserAccountAsync operation
            return authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.EnableUserAccountAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     new SsoPrincipalId
                     {
                         name = user.Name,
                         domain = user.Domain
                     })).Result;
        }

        public bool DisablePersonUser(PersonUser user)
        {
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin DisableUserAccountAsync operation
            return authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.DisableUserAccountAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPrincipalManagementService",
                         Value = "principalManagementService"
                     },
                     new SsoPrincipalId
                     {
                         name = user.Name,
                         domain = user.Domain
                     })).Result;
        }

        public PasswordPolicy GetPasswordPolicy()
        {
            PasswordPolicy result = null;
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin GetLocalPasswordPolicyAsync operation
            var ssoAdminPasswordPolicy = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.GetLocalPasswordPolicyAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminPasswordPolicyService",
                         Value = "passwordPolicyService"
                     })).Result;

            if (ssoAdminPasswordPolicy != null)
            {
                result = new PasswordPolicy(this)
                {
                    Description = ssoAdminPasswordPolicy.description,
                    ProhibitedPreviousPasswordsCount = ssoAdminPasswordPolicy.prohibitedPreviousPasswordsCount,
                    MinLength = ssoAdminPasswordPolicy.passwordFormat.lengthRestriction.minLength,
                    MaxLength = ssoAdminPasswordPolicy.passwordFormat.lengthRestriction.maxLength,
                    MaxIdenticalAdjacentCharacters = ssoAdminPasswordPolicy.passwordFormat.maxIdenticalAdjacentCharacters,
                    MinNumericCount = ssoAdminPasswordPolicy.passwordFormat.minNumericCount,
                    MinSpecialCharCount = ssoAdminPasswordPolicy.passwordFormat.minSpecialCharCount,
                    MinAlphabeticCount = ssoAdminPasswordPolicy.passwordFormat.alphabeticRestriction.minAlphabeticCount,
                    MinUppercaseCount = ssoAdminPasswordPolicy.passwordFormat.alphabeticRestriction.minUppercaseCount,
                    MinLowercaseCount = ssoAdminPasswordPolicy.passwordFormat.alphabeticRestriction.minLowercaseCount,
                    PasswordLifetimeDays = ssoAdminPasswordPolicy.passwordLifetimeDays
                };
            }

            return result;
        }

        public PasswordPolicy SetPasswordPolicy(
             string description = null,
             int? prohibitedPreviousPasswordsCount = null,
             int? minLength = null,
             int? maxLength = null,
             int? maxIdenticalAdjacentCharacters = null,
             int? minNumericCount = null,
             int? minSpecialCharCount = null,
             int? minAlphabeticCount = null,
             int? minUppercaseCount = null,
             int? minLowercaseCount = null,
             int? passwordLifetimeDays = null)
        {

            if (description != null ||
                prohibitedPreviousPasswordsCount != null ||
                minLength != null ||
                maxLength != null ||
                maxIdenticalAdjacentCharacters != null ||
                minNumericCount != null ||
                minSpecialCharCount != null ||
                minAlphabeticCount != null ||
                minUppercaseCount != null ||
                minLowercaseCount != null ||
                passwordLifetimeDays != null)
            {

                var ssoAdminPasswordPolicy = new SsoAdminPasswordPolicy();
                ssoAdminPasswordPolicy.description = description;

                if (passwordLifetimeDays != null)
                {
                    ssoAdminPasswordPolicy.passwordLifetimeDays = passwordLifetimeDays.Value;
                    ssoAdminPasswordPolicy.passwordLifetimeDaysSpecified = true;
                }

                if (prohibitedPreviousPasswordsCount != null)
                {
                    ssoAdminPasswordPolicy.prohibitedPreviousPasswordsCount = prohibitedPreviousPasswordsCount.Value;
                }

                // Update SsoAdminPasswordFormat if needed
                if (minLength != null ||
                    maxLength != null ||
                    maxIdenticalAdjacentCharacters != null ||
                    minNumericCount != null ||
                    minSpecialCharCount != null ||
                    minAlphabeticCount != null ||
                    minUppercaseCount != null ||
                    minLowercaseCount != null)
                {

                    ssoAdminPasswordPolicy.passwordFormat = new SsoAdminPasswordFormat();

                    if (maxIdenticalAdjacentCharacters != null)
                    {
                        ssoAdminPasswordPolicy.passwordFormat.maxIdenticalAdjacentCharacters = maxIdenticalAdjacentCharacters.Value;
                    }

                    if (minNumericCount != null)
                    {
                        ssoAdminPasswordPolicy.passwordFormat.minNumericCount = minNumericCount.Value;
                    }

                    if (minSpecialCharCount != null)
                    {
                        ssoAdminPasswordPolicy.passwordFormat.minSpecialCharCount = minSpecialCharCount.Value;
                    }

                    // Update LengthRestriction if needed
                    if (minLength != null ||
                        maxLength != null)
                    {
                        ssoAdminPasswordPolicy.passwordFormat.lengthRestriction = new SsoAdminPasswordFormatLengthRestriction();
                        if (maxLength != null)
                        {
                            ssoAdminPasswordPolicy.passwordFormat.lengthRestriction.maxLength = maxLength.Value;
                        }
                        if (minLength != null)
                        {
                            ssoAdminPasswordPolicy.passwordFormat.lengthRestriction.minLength = minLength.Value;
                        }
                    }

                    // Update AlphabeticRestriction if needed
                    if (minAlphabeticCount != null ||
                        minUppercaseCount != null ||
                        minLowercaseCount != null)
                    {
                        ssoAdminPasswordPolicy.passwordFormat.alphabeticRestriction = new SsoAdminPasswordFormatAlphabeticRestriction();

                        if (minAlphabeticCount != null)
                        {
                            ssoAdminPasswordPolicy.passwordFormat.alphabeticRestriction.minAlphabeticCount = minAlphabeticCount.Value;
                        }

                        if (minUppercaseCount != null)
                        {
                            ssoAdminPasswordPolicy.passwordFormat.alphabeticRestriction.minUppercaseCount = minUppercaseCount.Value;
                        }

                        if (minLowercaseCount != null)
                        {
                            ssoAdminPasswordPolicy.passwordFormat.alphabeticRestriction.minLowercaseCount = minLowercaseCount.Value;
                        }
                    }
                }

                // Create Authorization Invocation Context
                var authorizedInvocationContext =
                   CreateAuthorizedInvocationContext();

                // Invoke SSO Admin UpdateLocalPasswordPolicyAsync operation
                authorizedInvocationContext.
                   InvokeOperation(() =>
                      _ssoAdminBindingClient.UpdateLocalPasswordPolicyAsync(
                         new ManagedObjectReference
                         {
                             type = "SsoAdminPasswordPolicyService",
                             Value = "passwordPolicyService"
                         },
                         ssoAdminPasswordPolicy)).Wait();
            }

            return GetPasswordPolicy();
        }

        public LockoutPolicy GetLockoutPolicy()
        {
            LockoutPolicy result = null;
            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            // Invoke SSO Admin GetLockoutPolicyAsync operation
            var ssoAdminLockoutPolicy = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.GetLockoutPolicyAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminLockoutPolicyService",
                         Value = "lockoutPolicyService"
                     })).Result;

            if (ssoAdminLockoutPolicy != null)
            {
                result = new LockoutPolicy(this)
                {
                    Description = ssoAdminLockoutPolicy.description,
                    AutoUnlockIntervalSec = ssoAdminLockoutPolicy.autoUnlockIntervalSec,
                    FailedAttemptIntervalSec = ssoAdminLockoutPolicy.failedAttemptIntervalSec,
                    MaxFailedAttempts = ssoAdminLockoutPolicy.maxFailedAttempts
                };
            }

            return result;
        }

        public LockoutPolicy SetLockoutPolicy(
           string description,
           long? autoUnlockIntervalSec,
           long? failedAttemptIntervalSec,
           int? maxFailedAttempts)
        {

            if (description != null ||
               autoUnlockIntervalSec != null ||
               failedAttemptIntervalSec != null ||
               maxFailedAttempts != null)
            {

                var ssoAdminLockoutPolicy = new SsoAdminLockoutPolicy();

                ssoAdminLockoutPolicy.description = description;

                if (autoUnlockIntervalSec != null)
                {
                    ssoAdminLockoutPolicy.autoUnlockIntervalSec = autoUnlockIntervalSec.Value;
                }

                if (failedAttemptIntervalSec != null)
                {
                    ssoAdminLockoutPolicy.failedAttemptIntervalSec = failedAttemptIntervalSec.Value;
                }

                if (maxFailedAttempts != null)
                {
                    ssoAdminLockoutPolicy.maxFailedAttempts = maxFailedAttempts.Value;
                }

                // Create Authorization Invocation Context
                var authorizedInvocationContext =
                   CreateAuthorizedInvocationContext();

                // Invoke SSO Admin GetLockoutPolicyAsync operation
                authorizedInvocationContext.
                   InvokeOperation(() =>
                      _ssoAdminBindingClient.UpdateLockoutPolicyAsync(
                         new ManagedObjectReference
                         {
                             type = "SsoAdminLockoutPolicyService",
                             Value = "lockoutPolicyService"
                         },
                         ssoAdminLockoutPolicy)).Wait();

            }

            return GetLockoutPolicy();
        }

        public TokenLifetime GetTokenLifetime()
        {

            // Create Authorization Invocation Context
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            var maxHoKTokenLifetime = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.GetMaximumHoKTokenLifetimeAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminConfigurationManagementService",
                         Value = "configurationManagementService"
                     })).Result;

            var maxBearerTokenLifetime = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.GetMaximumBearerTokenLifetimeAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminConfigurationManagementService",
                         Value = "configurationManagementService"
                     })).Result;

            return new TokenLifetime(this)
            {
                MaxHoKTokenLifetime = maxHoKTokenLifetime,
                MaxBearerTokenLifetime = maxBearerTokenLifetime
            };
        }

        public TokenLifetime SetTokenLifetime(
           long? maxHoKTokenLifetime,
           long? maxBearerTokenLifetime)
        {

            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            if (maxHoKTokenLifetime != null)
            {
                authorizedInvocationContext.
                InvokeOperation(() =>
                   _ssoAdminBindingClient.SetMaximumHoKTokenLifetimeAsync(
                      new ManagedObjectReference
                      {
                          type = "SsoAdminConfigurationManagementService",
                          Value = "configurationManagementService"
                      },
                      maxHoKTokenLifetime.Value)).Wait();
            }

            if (maxBearerTokenLifetime != null)
            {
                authorizedInvocationContext.
                InvokeOperation(() =>
                   _ssoAdminBindingClient.SetMaximumBearerTokenLifetimeAsync(
                      new ManagedObjectReference
                      {
                          type = "SsoAdminConfigurationManagementService",
                          Value = "configurationManagementService"
                      },
                      maxBearerTokenLifetime.Value)).Wait();
            }


            return GetTokenLifetime();
        }

        public void AddActiveDirectoryExternalDomain(
           string domainName,
           string domainAlias,
           string friendlyName,
           string primaryUrl,
           string baseDNUsers,
           string baseDNGroups,
           string authenticationUserName,
           string authenticationPassword,
           string serverType)
        {

            string authenticationType = "password";
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            authorizedInvocationContext.
            InvokeOperation(() =>
               _ssoAdminBindingClient.AddExternalDomainAsync(
                  new ManagedObjectReference
                  {
                      type = "SsoAdminDomainManagementService",
                      Value = "domainManagementService"
                  },
                  serverType,
                  domainName,
                  domainAlias,
                  new SsoAdminExternalDomainDetails
                  {
                      friendlyName = friendlyName,
                      primaryUrl = primaryUrl,
                      userBaseDn = baseDNUsers,
                      groupBaseDn = baseDNGroups
                  },
                  authenticationType,
                  new SsoAdminDomainManagementServiceAuthenticationCredentails
                  {
                      username = authenticationUserName,
                      password = authenticationPassword
                  })).Wait();
        }

        public void AddLdapIdentitySource(
           string domainName,
           string domainAlias,
           string friendlyName,
           string primaryUrl,
           string failoverUrl,
           string baseDNUsers,
           string baseDNGroups,
           string authenticationUserName,
           SecureString authenticationPassword,
           string serverType,
           X509Certificate2[] ldapCertificates)
        {

            string authenticationType = "password";
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            var adminLdapIdentitySourceDetails = new SsoAdminLdapIdentitySourceDetails
            {
                friendlyName = friendlyName,
                primaryUrl = primaryUrl,
                failoverUrl = failoverUrl,
                userBaseDn = baseDNUsers,
                groupBaseDn = baseDNGroups
            };

            if (ldapCertificates != null && ldapCertificates.Length > 0)
            {
                var certificates = new List<string>();
                foreach (var ldapCert in ldapCertificates)
                {
                    certificates.Add(Convert.ToBase64String(ldapCert.Export(X509ContentType.Cert), Base64FormattingOptions.InsertLineBreaks));
                }

                if (certificates.Count > 0)
                {
                    adminLdapIdentitySourceDetails.certificates = certificates.ToArray();
                }
            }

            try
            {
                authorizedInvocationContext.
                InvokeOperation(() =>
                   _ssoAdminBindingClient.RegisterLdapAsync(
                      new ManagedObjectReference
                      {
                          type = "SsoAdminIdentitySourceManagementService",
                          Value = "identitySourceManagementService"
                      },
                      serverType,
                      domainName,
                      domainAlias,
                      adminLdapIdentitySourceDetails,
                      authenticationType,
                      new SsoAdminIdentitySourceManagementServiceAuthenticationCredentials
                      {
                          username = authenticationUserName,
                          password = SecureStringToString(authenticationPassword)
                      })).Wait();
            }
            catch (AggregateException e)
            {
                throw e.InnerException;
            }
        }

        public void UpdateLdapIdentitySource(
           string name,
           string friendlyName,
           string primaryUrl,
           string failoverUrl,
           string baseDNUsers,
           string baseDNGroups,
           X509Certificate2[] ldapCertificates)
        {

            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            var adminLdapIdentitySourceDetails = new SsoAdminLdapIdentitySourceDetails
            {
                friendlyName = friendlyName,
                primaryUrl = primaryUrl,
                failoverUrl = failoverUrl,
                userBaseDn = baseDNUsers,
                groupBaseDn = baseDNGroups
            };

            if (ldapCertificates != null && ldapCertificates.Length > 0)
            {
                var certificates = new List<string>();
                foreach (var ldapCert in ldapCertificates)
                {
                    certificates.Add(Convert.ToBase64String(ldapCert.Export(X509ContentType.Cert), Base64FormattingOptions.InsertLineBreaks));
                }

                if (certificates.Count > 0)
                {
                    adminLdapIdentitySourceDetails.certificates = certificates.ToArray();
                }
            }

            try
            {
                authorizedInvocationContext.
                InvokeOperation(() =>
                   _ssoAdminBindingClient.UpdateLdapAsync(
                      new ManagedObjectReference
                      {
                          type = "SsoAdminIdentitySourceManagementService",
                          Value = "identitySourceManagementService"
                      },
                      name,
                      adminLdapIdentitySourceDetails)).Wait();
            }
            catch (AggregateException e)
            {
                throw e.InnerException;
            }
        }

        public void UpdateLdapIdentitySourceAuthentication(
            string name,
            string authenticationUserName,
            SecureString authenticationPassword)
        {

            string authenticationType = "password";
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            try
            {
                authorizedInvocationContext.
                InvokeOperation(() =>
                   _ssoAdminBindingClient.UpdateLdapAuthnTypeAsync(
                      new ManagedObjectReference
                      {
                          type = "SsoAdminIdentitySourceManagementService",
                          Value = "identitySourceManagementService"
                      },
                      name,
                      authenticationType,
                      new SsoAdminIdentitySourceManagementServiceAuthenticationCredentials
                      {
                          username = authenticationUserName,
                          password = SecureStringToString(authenticationPassword)
                      })).Wait();
            }
            catch (AggregateException e)
            {
                throw e.InnerException;
            }
        }

        public IEnumerable<IdentitySource> GetDomains()
        {
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            var identitySources = authorizedInvocationContext.
            InvokeOperation(() =>
               _ssoAdminBindingClient.GetAsync(
                  new ManagedObjectReference
                  {
                      type = "SsoAdminIdentitySourceManagementService",
                      Value = "identitySourceManagementService"
                  })).Result;

            if (identitySources != null)
            {
                var localos = new LocalOSIdentitySource();
                localos.Name = identitySources.localOS.name;
                yield return localos;

                foreach (var systemDomain in identitySources.system.domains) {
                    var system = new SystemIdentitySource();
                    system.Name = systemDomain.name;
                    yield return system;
                }


                if (identitySources.ldaps != null && identitySources.ldaps.Length > 0)
                {
                    foreach (var externalDomain in identitySources.ldaps)
                    {
                        var extIdentitySource = new ActiveDirectoryIdentitySource();
                        extIdentitySource.Name = externalDomain.name;
                        extIdentitySource.Type = externalDomain.type;
                        extIdentitySource.AuthenticationType = externalDomain.authenticationDetails?.authenticationType;
                        extIdentitySource.AuthenticationUsername = externalDomain.authenticationDetails?.username;
                        extIdentitySource.FriendlyName = externalDomain.details?.friendlyName;
                        extIdentitySource.PrimaryUrl = externalDomain.details?.primaryUrl;
                        extIdentitySource.FailoverUrl = externalDomain.details?.failoverUrl;
                        extIdentitySource.GroupBaseDN = externalDomain.details?.groupBaseDn;
                        extIdentitySource.UserBaseDN = externalDomain.details?.userBaseDn;
                        if (externalDomain.details?.certificates != null && externalDomain.details?.certificates.Length > 0) {
                            var certificatesList = new List<X509Certificate2>();
                            foreach (var cert in externalDomain.details?.certificates) {
                                certificatesList.Add(new X509Certificate2(Convert.FromBase64String(cert)));
                            }
                           extIdentitySource.Certificates = certificatesList.ToArray();
                        }

                        yield return extIdentitySource;
                    }
                }
            }
        }

        public void SetDefaultIdentitySource(string domainName)
        {
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            var setDefaultDomainRequest = new IdS_setDefaultDomainsRequest
            {
                domainNames = new string[]{domainName}
            };

            try
            {
                authorizedInvocationContext.
                InvokeOperation(() =>
                   _ssoAdminBindingClient.IdS_setDefaultDomainsAsync(
                      new ManagedObjectReference
                      {
                          type = "SsoAdminIdentitySourceManagementService",
                          Value = "identitySourceManagementService"
                      },
                      new string[]{domainName})).Wait();
            }
            catch (AggregateException e)
            {
                throw e.InnerException;
            }
        }

        public string GetDefaultIdentitySourceDomainName()
        {
            string result = null;
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            try
            {
                var response = authorizedInvocationContext.
                InvokeOperation(() =>
                   _ssoAdminBindingClient.IdS_getDefaultDomainsAsync(
                      new ManagedObjectReference
                      {
                          type = "SsoAdminIdentitySourceManagementService",
                          Value = "identitySourceManagementService"
                      })).Result;
                if (response != null && response.returnval != null && response.returnval.Length > 0) {
                    result = response.returnval[0];
                }
            }
            catch (AggregateException e)
            {
                throw e.InnerException;
            }

            return result;
        }

        public void DeleteDomain(string name)
        {

            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            try
            {
                authorizedInvocationContext.
                InvokeOperation(() =>
                   _ssoAdminBindingClient.DeleteAsync(
                      new ManagedObjectReference
                      {
                          type = "SsoAdminIdentitySourceManagementService",
                          Value = "identitySourceManagementService"
                      },
                      name)).Wait();
            }
            catch (AggregateException e)
            {
                throw e.InnerException;
            }
        }
        #endregion

        #region AuthenticationConfiguration
        public DataTypes.AuthenticationPolicy GetAuthenticationPolicy() {
             var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            var authnPolicy = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.GetAuthnPolicyAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminConfigurationManagementService",
                         Value = "configurationManagementService"
                     })).Result;

            return new DataTypes.AuthenticationPolicy(this)
            {
                PasswordAuthnEnabled = authnPolicy.PasswordAuthnEnabled,
                WindowsAuthnEnabled = authnPolicy.WindowsAuthEnabled,
                SmartCardAuthnEnabled = authnPolicy.CertAuthEnabled,
                CRLCacheSize = authnPolicy.clientCertPolicy.crlCacheSize,
                CRLUrl = authnPolicy.clientCertPolicy.crlUrl,
                OCSPEnabled = authnPolicy.clientCertPolicy.ocspEnabled,
                OCSPResponderSigningCert = string.IsNullOrEmpty(authnPolicy.clientCertPolicy.ocspResponderSigningCert) ? null : new X509Certificate2(authnPolicy.clientCertPolicy.ocspResponderSigningCert),
                OCSPUrl = authnPolicy.clientCertPolicy.ocspUrl,
                Oids = authnPolicy.clientCertPolicy.oids,
                SendOCSPNonce = authnPolicy.clientCertPolicy.sendOCSPNonce,
                TrustedCAs = authnPolicy.clientCertPolicy.trustedCAs,
                UseCRLAsFailOver = authnPolicy.clientCertPolicy.useCRLAsFailOver,
                UseInCertCRL = authnPolicy.clientCertPolicy.useInCertCRL
            };
        }

        public void SetAuthenticationPolicy(
            bool passwordAuthnEnabled,
            bool windowsAuthnEnabled,
            bool smartCardAuthnEnabled,
            int crlCacheSize,
            string crlUrl,
            bool ocspEnabled,
            X509Certificate2 ocspResponderSigningCert,
            string ocspUrl,
            string[] oids,
            bool sendOCSPNonce,
            string[] trustedCAs,
            bool useCRLAsFailOver,
            bool useInCertCRL
        ) {
             var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

             var ssoAdminAuthnPolicy = new SsoAdminAuthnPolicy{
                         PasswordAuthnEnabled = passwordAuthnEnabled,
                         WindowsAuthEnabled = windowsAuthnEnabled,
                         CertAuthEnabled = smartCardAuthnEnabled,
                         clientCertPolicy = new SsoAdminClientCertPolicy {
                            enabled = smartCardAuthnEnabled,
                            crlCacheSize = crlCacheSize,
                            crlUrl = crlUrl,
                            ocspEnabled = ocspEnabled,
                            ocspUrl = ocspUrl,
                            oids = oids,
                            sendOCSPNonce = sendOCSPNonce,
                            trustedCAs = trustedCAs,
                            useCRLAsFailOver = useCRLAsFailOver,
                            useInCertCRL = useInCertCRL
                         }
                     };
                if (ocspResponderSigningCert != null) {
                    ssoAdminAuthnPolicy.clientCertPolicy.ocspResponderSigningCert = Convert.ToBase64String(ocspResponderSigningCert.Export(X509ContentType.Cert), Base64FormattingOptions.InsertLineBreaks);
                }


            authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.SetAuthnPolicyAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminConfigurationManagementService",
                         Value = "configurationManagementService"
                     },
                     ssoAdminAuthnPolicy
                    )).Wait();
        }
        #endregion

        #region Global Permission
        public void SetRoleForUser(DataTypes.PersonUser user, string role) {
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            var authnPolicy = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.SetRoleAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminRoleManagementService",
                         Value = "roleManagementService"
                     },
                     new SsoPrincipalId{
                         domain = user.Domain,
                         name = user.Name
                     },
                     role)).Result;
        }

        public void SetRoleForGroup(DataTypes.Group group, string role) {
            var authorizedInvocationContext =
               CreateAuthorizedInvocationContext();

            var authnPolicy = authorizedInvocationContext.
               InvokeOperation(() =>
                  _ssoAdminBindingClient.SetRoleAsync(
                     new ManagedObjectReference
                     {
                         type = "SsoAdminRoleManagementService",
                         Value = "roleManagementService"
                     },
                     new SsoPrincipalId{
                         domain = group.Domain,
                         name = group.Name
                     },
                     role)).Result;
        }
        #endregion
    }
}
