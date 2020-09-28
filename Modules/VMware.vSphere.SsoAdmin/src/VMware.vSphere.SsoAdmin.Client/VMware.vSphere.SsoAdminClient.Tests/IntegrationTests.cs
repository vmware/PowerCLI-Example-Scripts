using NUnit.Framework;
using System.Security;
using VMware.vSphere.SsoAdmin.Utils;

namespace VMware.vSphere.SsoAdminClient.Tests
{
   public class Tests
   {
      private string _vc = "<place VC address here>";
      private string _user = "<place VC user here>";
      private string _rawPassword = "<place password here>";
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
   }
}