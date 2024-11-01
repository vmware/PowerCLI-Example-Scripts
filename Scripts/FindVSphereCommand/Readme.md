# FindVSphereCommand module

This module contains a single `Find-VSphereCommand` cmdlet. This cmdlet maps a vSphere Automation API path (path + HttpMethod) to a PowerCLI SDK cmdlet.

## Examples

### Find a cmdlet for VM creation

``` powershell
PS C:\Users\la001741> Find-VSphereCommand -Name *create*vm*

Name                 CommandName                              Method  Path
----                 -----------                              ------  ----
CreateVmHardwareCdr… Invoke-CreateVmHardwareCdrom              POST   /api/vcenter/vm/{vm}/hardware/cdrom
CreateVmDataSets     Invoke-CreateVmDataSets                   POST   /api/vcenter/vm/{vm}/data-sets
CreateTemporaryVmFi… Invoke-CreateTemporaryVmFilesystemDirec…  POST   /api/vcenter/vm/{vm}/guest/filesystem/directories?ac…
CreateVmFilesystemD… Invoke-CreateVmFilesystemDirectories      POST   /api/vcenter/vm/{vm}/guest/filesystem/directories?ac…
CreateVmHardwareDisk Invoke-CreateVmHardwareDisk               POST   /api/vcenter/vm/{vm}/hardware/disk
CreateVmHardwareEth… Invoke-CreateVmHardwareEthernet           POST   /api/vcenter/vm/{vm}/hardware/ethernet
CreateTemporaryVmFi… Invoke-CreateTemporaryVmFilesystemFiles   POST   /api/vcenter/vm/{vm}/guest/filesystem/files?action=c…
CreateVmHardwareFlo… Invoke-CreateVmHardwareFloppy             POST   /api/vcenter/vm/{vm}/hardware/floppy
CreateNamespaceInst… Invoke-CreateNamespaceInstancesRegister…  POST   /api/vcenter/namespaces/instances/{namespace}/regist…
CreateVmTemplateLib… Invoke-CreateVmTemplateLibraryItems       POST   /api/vcenter/vm-template/library-items
CreateVmHardwareAda… Invoke-CreateVmHardwareAdapterNvme        POST   /api/vcenter/vm/{vm}/hardware/adapter/nvme
CreateVmHardwarePar… Invoke-CreateVmHardwareParallel           POST   /api/vcenter/vm/{vm}/hardware/parallel
CreateVmGuestProces… Invoke-CreateVmGuestProcesses             POST   /api/vcenter/vm/{vm}/guest/processes?action=create
CreateVmHardwareAda… Invoke-CreateVmHardwareAdapterSata        POST   /api/vcenter/vm/{vm}/hardware/adapter/sata
CreateVmHardwareAda… Invoke-CreateVmHardwareAdapterScsi        POST   /api/vcenter/vm/{vm}/hardware/adapter/scsi
CreateVmHardwareSer… Invoke-CreateVmHardwareSerial             POST   /api/vcenter/vm/{vm}/hardware/serial
CreateVmConsoleTick… Invoke-CreateVmConsoleTickets             POST   /api/vcenter/vm/{vm}/console/tickets
CreateVmGuestFilesy… Invoke-CreateVmGuestFilesystem            POST   /api/vcenter/vm/{vm}/guest/filesystem?action=create
CreateVm             Invoke-CreateVm                           POST   /api/vcenter/vm
CreateCertificateMa… Invoke-CreateCertificateManagementVmcaR…  POST   /api/vcenter/certificate-management/vcenter/vmca-root

```

### Explore '/api/vcenter/vm' with Post http method

``` powershell
PS C:\Users\la001741> Find-VSphereCommand -Path /api/vcenter/vm -Method Post

Name                 CommandName                              Method  Path
----                 -----------                              ------  ----
CreateVm             Invoke-CreateVm                           POST   /api/vcenter/vm

```

### Explore '/api/vcenter/storage/policies/*' with Get http method

``` powershell
PS C:\Users> Find-VSphereCommand -Path /api/vcenter/storage/policies/* -Method Get

Name                 CommandName                              Method  Path
----                 -----------                              ------  ----
ListPoliciesEntitie… Invoke-ListPoliciesEntitiesCompliance      GET   /api/vcenter/storage/policies/entities/compliance
ListPoliciesComplia… Invoke-ListPoliciesComplianceVm            GET   /api/vcenter/storage/policies/compliance/vm
ListPolicyPoliciesVm Invoke-ListPolicyPoliciesVm                GET   /api/vcenter/storage/policies/{policy}/vm

```

## Using the module

### Clone PowerCLI-Example-Scripts GitHub repository

#### Full repository clone

``` powershell
cd <local-repositories-root>
git clone git@github.com:vmware/PowerCLI-Example-Scripts.git
```

#### Partial (Scripts/FindVSphereCommand) repository clone only

``` powershell
cd <local-repositories-root>
git clone -n --depth=1 --filter=tree:0 git@github.com:vmware/PowerCLI-Example-Scripts.git
cd PowerCLI-Example-Scripts
git sparse-checkout set --no-cone Scripts/FindVSphereCommand
git checkout
```

### Import the module

``` powershell
Import-Module <local-repositories-root>/Scripts/FindVSphereCommand/FindVSphereCommand.psd1
```
