# VMware Private AI Foundation with NVIDIA Guide

This example demonstrates how a VI admin would:

* instantiate a new VCF workload domain for data scientist teams
* setup the following infrastructure configuration required for **PAIF-N** workload domain

## Deploying a VI workload domain

This script creates a VI workload domain using the **PowerCLI** SDK module for **VCF SDDC Manager**.

The script can be broken into two main parts. First, the ESXi hosts are being commissioned. Then, the actual VI domain is created using the commissioned ESXi hosts.

Both steps - ESXi host commissioning and VI domain creations - are three-stage operations themselves. The commissioning/creation specs are constructed. The specs are validated. The actual operation is invoked. The validation and operation invocation are long-running tasks. This requires awaiting and status tracking until their completion. The waiting for validation and the actual operation is done using helper cmdlets -
Wait-VcfValidation and Wait-VcfTask, located in `utils` sub-folder.

On completion, a new VI workload domain reflecting the given parameters should be created.

## ESXi hosts configuration for AI workloads

This script configures the ESXi host for AI workloads which includes installing the Nvidia AI Enterprise vGPU driver and Nvidia GPU Management Daemon on the ESXi hosts. vLCM is used for that purpose.

The script changes the default graphics type of the GPU devices to Shared Direct. The Xorg service is then restarted. Finally, the vLCM is used to install the NVIDIA GPU driver and management daemon.

## NSX Edge Cluster creation

This script creates an NSX edge cluster to provide connectivity from external networks to Supervisor Cluster objects.

## Workload Management enablement and configuration

This script enables Workload Management (Kubernetes) and sets it up for AI workloads.

The script:

  1. Enables the Supervisor cluster
  2. Creates content library for the deep learning VM template
  3. Creates GPU-enabled VMClass
  4. Creates namespace(s) and assigns the created VMClass and assigns deep learning VM content library
