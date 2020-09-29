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
   }
}