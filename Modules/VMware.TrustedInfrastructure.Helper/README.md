Prerequisites/Steps to use this module:
  1. You must be a Trust Authority Administrator, a part of the TrustedAdmins group and also have the "Host.Inventory.Add Host To Cluster" privilege on vCenter system.
  2. The ESXi host must be wiped from existing Trusted Infrastructure configuration. If the ESXi host has been previously configured as  part of vSphere Trust Authority (part of a vCenter configured for vSphere Trust Authority, a Trust Authority Cluster or Trusted Cluster), you must use the decommission script first.
  3. TrustAuthorityCluster and TrustedCluster should be in a healthy state (check all vSphere Trust Authority APIs which return Health field).
  4. The ESXi host must be removed from vCenter.
  5. You must know the ESXi host root credentials (username and password).
  6. You must have purchased sufficient license for vSphere Trust Authority.
  7. You must have PowerCLI 12.1.0 and above.
  8. Following PowerCLI module is required to be imported: VMware.VimAutomation.Security.
  9. Run the command Get-Command -Module VMware.TrustedInfrastructure.Helper. This should inform the following functions are available:
     - Add-TrustAuthorityVMHost
     - Add-TrustedVMHost
     If you do not see these functions listed, the PowerCLI module is not loaded correctly.
  10. Run Get-Help Add-TrustAuthorityVMHost -full and Get-Help Add-TrustedVMHost -full to see how to use these two functions.
  11. Others, please refer vSphere documentation.
