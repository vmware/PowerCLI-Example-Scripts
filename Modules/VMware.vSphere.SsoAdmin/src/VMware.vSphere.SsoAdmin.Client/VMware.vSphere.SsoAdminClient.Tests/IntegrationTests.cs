/*
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
*/
using NUnit.Framework;
using System.Linq;
using System.Security;
using VMware.vSphere.SsoAdmin.Utils;
using VMware.vSphere.SsoAdminClient.DataTypes;

namespace VMware.vSphere.SsoAdminClient.Tests
{
   public class Tests
   {
      private string _vc = "<vc>";
      private string _user = "<user>";
      private string _rawPassword = "<password>";
      private SecureString _password;
      [SetUp]
      public void Setup() {
         _password = new SecureString();
         foreach (char c in _rawPassword) {
            _password.AppendChar(c);
         }
      }

      [Test]
      public void AddRemoveLocalUser() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());
         var expectedUserName = "test-user2";
         var expectedPassword = "te$tPa$sW0rd";
         var expectedDescription = "test-description";
         var expectedEmail = "testuse@testdomain.loc";
         var expectedFirstName = "Test";
         var expectedLastName = "User";

         // Act Create User
         var actual = ssoAdminClient.CreateLocalUser(
            expectedUserName,
            expectedPassword,
            expectedDescription,
            expectedEmail,
            expectedFirstName,
            expectedLastName);

         // Assert Created User
         Assert.AreEqual(expectedUserName, actual.Name);
         Assert.AreEqual(expectedDescription, actual.Description);
         Assert.AreEqual(expectedEmail, actual.EmailAddress);
         Assert.AreEqual(expectedFirstName, actual.FirstName);
         Assert.AreEqual(expectedLastName, actual.LastName);

         // Act Delete User
         ssoAdminClient.DeleteLocalUser(
            actual);
      }

      [Test]
      public void GetAllLocalOsUsers() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());

         // Act
         var actual = ssoAdminClient.GetLocalUsers("", "localos").ToArray();

         // Assert
         Assert.NotNull(actual);
         Assert.Greater(actual.Length, 0);
      }

      [Test]
      public void GetRootLocalOsUsers() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());

         // Act
         var actual = ssoAdminClient.GetLocalUsers("root", "localos").ToArray();

         // Assert
         Assert.NotNull(actual);
         Assert.AreEqual(1, actual.Length);
         Assert.AreEqual("root", actual[0].Name);
         Assert.AreEqual("localos", actual[0].Domain);
      }

      [Test]
      public void GetRootLocalOsGroups() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());

         // Act
         var actual = ssoAdminClient.GetGroups("", "localos").ToArray();

         // Assert
         Assert.NotNull(actual);
         Assert.Greater(actual.Length, 1);
         Assert.AreEqual("localos", actual[0].Domain);
      }

      [Test]
      public void GetPersonUsersInGroup() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());

         // Act
         var actual = ssoAdminClient.GetPersonUsersInGroup("", new Group(ssoAdminClient) {
            Name = "Administrators",
            Domain = "vsphere.local"
         }).ToArray();

         // Assert
         Assert.NotNull(actual);
         Assert.GreaterOrEqual(actual.Length, 1);
         Assert.AreEqual("vsphere.local", actual[0].Domain);
      }

      [Test]
      public void AddRemoveUserFromGroup() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());

         var expectedUserName = "test-user5";
         var expectedPassword = "te$tPa$sW0rd";
         var newUser = ssoAdminClient.CreateLocalUser(
            expectedUserName,
            expectedPassword);

         var group = ssoAdminClient.GetGroups("administrators", newUser.Domain).FirstOrDefault<Group>();

         // Act
         var addActual = ssoAdminClient.AddPersonUserToGroup(newUser, group);
         var removeActual = ssoAdminClient.RemovePersonUserFromGroup(newUser, group);

         // Assert
         Assert.IsTrue(addActual);
         Assert.IsTrue(removeActual);

         // Cleanup
         ssoAdminClient.DeleteLocalUser(
            newUser);
      }

      [Test]
      public void ResetUserPassword() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());

         var expectedUserName = "test-user6";
         var expectedPassword = "te$tPa$sW0rd";
         var updatePassword = "TE$tPa$sW0rd";
         var newUser = ssoAdminClient.CreateLocalUser(
            expectedUserName,
            expectedPassword);

         // Act
         // Assert
         Assert.DoesNotThrow(() => {
            ssoAdminClient.ResetPersonUserPassword(newUser, updatePassword);
         });


         // Cleanup
         ssoAdminClient.DeleteLocalUser(
            newUser);
      }

      [Test]
      public void GetPasswordPolicy() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());

         // Act
         var actual = ssoAdminClient.GetPasswordPolicy();

         // Assert
         Assert.NotNull(actual);
      }

      [Test]
      public void SetPasswordPolicy() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());

         var originalPasswordPolicy = ssoAdminClient.GetPasswordPolicy();

         var expectedDescription = "TestDescription";
         var expectedProhibitedPreviousPasswordsCount = originalPasswordPolicy.ProhibitedPreviousPasswordsCount + 1;
         var expectedMinLength = originalPasswordPolicy.MinLength + 1;
         var expectedMaxLength = originalPasswordPolicy.MaxLength + 1;
         var exptectedMaxIdenticalAdjacentCharacters = originalPasswordPolicy.MaxIdenticalAdjacentCharacters + 1;
         var expectedMinNumericCount = originalPasswordPolicy.MinNumericCount + 1;
         var expectedMinSpecialCharCount = originalPasswordPolicy.MinSpecialCharCount + 1;
         var expectedMinAlphabeticCount = originalPasswordPolicy.MinAlphabeticCount + 2;
         var expectedMinUppercaseCount = 0;
         var expectedMinLowercaseCount = originalPasswordPolicy.MinLowercaseCount + 2;
         var expectedPasswordLifetimeDays = originalPasswordPolicy.PasswordLifetimeDays - 2;

         // Act
         var actual = ssoAdminClient.SetPasswordPolicy(
            description: expectedDescription,
            prohibitedPreviousPasswordsCount: expectedProhibitedPreviousPasswordsCount,
            minLength: expectedMinLength,
            maxLength: expectedMaxLength,
            maxIdenticalAdjacentCharacters: exptectedMaxIdenticalAdjacentCharacters,
            minNumericCount: expectedMinNumericCount,
            minSpecialCharCount: expectedMinSpecialCharCount,
            minAlphabeticCount: expectedMinAlphabeticCount,
            minUppercaseCount: expectedMinUppercaseCount,
            minLowercaseCount: expectedMinLowercaseCount,
            passwordLifetimeDays: expectedPasswordLifetimeDays);

         // Assert
         Assert.NotNull(actual);
         Assert.AreEqual(expectedDescription, actual.Description);
         Assert.AreEqual(expectedProhibitedPreviousPasswordsCount, actual.ProhibitedPreviousPasswordsCount);
         Assert.AreEqual(expectedMinLength, actual.MinLength);
         Assert.AreEqual(expectedMaxLength, actual.MaxLength);
         Assert.AreEqual(exptectedMaxIdenticalAdjacentCharacters, actual.MaxIdenticalAdjacentCharacters);
         Assert.AreEqual(expectedMinNumericCount, actual.MinNumericCount);
         Assert.AreEqual(expectedMinAlphabeticCount, actual.MinAlphabeticCount);
         Assert.AreEqual(expectedMinUppercaseCount, actual.MinUppercaseCount);
         Assert.AreEqual(expectedMinLowercaseCount, actual.MinLowercaseCount);
         Assert.AreEqual(expectedPasswordLifetimeDays, actual.PasswordLifetimeDays);

         // Cleanup
         ssoAdminClient.SetPasswordPolicy(
            description: originalPasswordPolicy.Description,
            prohibitedPreviousPasswordsCount: originalPasswordPolicy.ProhibitedPreviousPasswordsCount,
            minLength: originalPasswordPolicy.MinLength,
            maxLength: originalPasswordPolicy.MaxLength,
            maxIdenticalAdjacentCharacters: originalPasswordPolicy.MaxIdenticalAdjacentCharacters,
            minNumericCount: originalPasswordPolicy.MinNumericCount,
            minSpecialCharCount: originalPasswordPolicy.MinSpecialCharCount,
            minAlphabeticCount: originalPasswordPolicy.MinAlphabeticCount,
            minUppercaseCount: originalPasswordPolicy.MinUppercaseCount,
            minLowercaseCount: originalPasswordPolicy.MinLowercaseCount,
            passwordLifetimeDays: originalPasswordPolicy.PasswordLifetimeDays);
      }

      [Test]
      public void GetLockoutPolicy() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());

         // Act
         var actual = ssoAdminClient.GetLockoutPolicy();

         // Assert
         Assert.NotNull(actual);
      }

      [Test]
      public void SetLockoutPolicy() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());
         var originalLockoutPolicy = ssoAdminClient.GetLockoutPolicy();
         var expectedDescription = "TestDescription";
         var expectedAutoUnlockIntervalSec = 20;
         var expectedFailedAttemptIntervalSec = 30;
         var expectedMaxFailedAttempts = 5;

         // Act
         var actual = ssoAdminClient.SetLockoutPolicy(
            expectedDescription,
            expectedAutoUnlockIntervalSec,
            expectedFailedAttemptIntervalSec,
            expectedMaxFailedAttempts);

         // Assert
         Assert.NotNull(actual);
         Assert.AreEqual(expectedDescription, actual.Description);
         Assert.AreEqual(expectedAutoUnlockIntervalSec, actual.AutoUnlockIntervalSec);
         Assert.AreEqual(expectedFailedAttemptIntervalSec, actual.FailedAttemptIntervalSec);
         Assert.AreEqual(expectedMaxFailedAttempts, actual.MaxFailedAttempts);

         // Cleanup
         ssoAdminClient.SetLockoutPolicy(
            originalLockoutPolicy.Description,
            originalLockoutPolicy.AutoUnlockIntervalSec,
            originalLockoutPolicy.FailedAttemptIntervalSec,
            originalLockoutPolicy.MaxFailedAttempts
            );
      }

      [Test]
      public void GetDomains() {
         // Arrange
         var ssoAdminClient = new SsoAdminClient(_vc, _user, _password, new AcceptAllX509CertificateValidator());

         // Act
         var actual = ssoAdminClient.GetDomains().ToArray<IdentitySource>();

         // Assert
         Assert.NotNull(actual);
         Assert.IsTrue(actual.Length >= 2);
      }
   }
}