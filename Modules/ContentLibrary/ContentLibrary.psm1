Function Get-ContentLibrary {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function lists all available vSphere Content Libaries
    .PARAMETER LibraryName
        The name of a vSphere Content Library
    .EXAMPLE
        Get-ContentLibrary
    .EXAMPLE
        Get-ContentLibrary -LibraryName Test
#>
    param(
        [Parameter(Mandatory=$false)][String]$LibraryName
    )

    $contentLibaryService = Get-CisService com.vmware.content.library
    $libaryIDs = $contentLibaryService.list()

    $results = @()
    foreach($libraryID in $libaryIDs) {
        $library = $contentLibaryService.get($libraryID)

        # Use vCenter REST API to retrieve name of Datastore that is backing the Content Library
        $datastoreService = Get-CisService com.vmware.vcenter.datastore
        $datastore = $datastoreService.get($library.storage_backings.datastore_id)

        if($library.publish_info.published) {
            $published = $library.publish_info.published
            $publishedURL = $library.publish_info.publish_url
            $externalReplication = $library.publish_info.persist_json_enabled
        } else {
            $published = $library.publish_info.published
            $publishedURL = "N/A"
            $externalReplication = "N/A"
        }

        if($library.subscription_info) {
            $subscribeURL = $library.subscription_info.subscription_url
            $published = "N/A"
        } else {
            $subscribeURL = "N/A"
        }

        if(!$LibraryName) {
            $libraryResult = [pscustomobject] @{
                Id = $library.Id;
                Name = $library.Name;
                Type = $library.Type;
                Description = $library.Description;
                Datastore = $datastore.name;
                Published = $published;
                PublishedURL = $publishedURL;
                JSONPersistence = $externalReplication;
                SubscribedURL = $subscribeURL;
                CreationTime = $library.Creation_Time;
            }
            $results+=$libraryResult
        } else {
            if($LibraryName -eq $library.name) {
                $libraryResult = [pscustomobject] @{
                    Name = $library.Name;
                    Id = $library.Id;
                    Type = $library.Type;
                    Description = $library.Description;
                    Datastore = $datastore.name;
                    Published = $published;
                    PublishedURL = $publishedURL;
                    JSONPersistence = $externalReplication;
                    SubscribedURL = $subscribeURL;
                    CreationTime = $library.Creation_Time;
                }
                $results+=$libraryResult
            }
        }
    }
    $results
}

Function Get-ContentLibraryItems {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function lists all items within a given vSphere Content Library
    .PARAMETER LibraryName
        The name of a vSphere Content Library
    .PARAMETER LibraryItemName
        The name of a vSphere Content Library Item
    .EXAMPLE
        Get-ContentLibraryItems -LibraryName Test
    .EXAMPLE
        Get-ContentLibraryItems -LibraryName Test -LibraryItemName TinyPhotonVM
#>
    param(
        [Parameter(Mandatory=$true)][String]$LibraryName,
        [Parameter(Mandatory=$false)][String]$LibraryItemName
    )

    $contentLibaryService = Get-CisService com.vmware.content.library
    $libaryIDs = $contentLibaryService.list()

    $results = @()
    foreach($libraryID in $libaryIDs) {
        $library = $contentLibaryService.get($libraryId)
        if($library.name -eq $LibraryName) {
            $contentLibaryItemService = Get-CisService com.vmware.content.library.item
            $itemIds = $contentLibaryItemService.list($libraryID)

            foreach($itemId in $itemIds) {
                $item = $contentLibaryItemService.get($itemId)

                if(!$LibraryItemName) {
                    $itemResult = [pscustomobject] @{
                        Name = $item.name;
                        Id = $item.id;
                        Description = $item.description;
                        Size = $item.size
                        Type = $item.type;
                        Version = $item.version;
                        MetadataVersion = $item.metadata_version;
                        ContentVersion = $item.content_version;
                    }
                    $results+=$itemResult
                } else {
                    if($LibraryItemName -eq $item.name) {
                        $itemResult = [pscustomobject] @{
                            Name = $item.name;
                            Id = $item.id;
                            Description = $item.description;
                            Size = $item.size
                            Type = $item.type;
                            Version = $item.version;
                            MetadataVersion = $item.metadata_version;
                            ContentVersion = $item.content_version;
                        }
                        $results+=$itemResult
                    }
                }
            }
        }
    }
    $results
}

Function Get-ContentLibraryItemFiles {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function lists all item files within a given vSphere Content Library
    .PARAMETER LibraryName
        The name of a vSphere Content Library
    .PARAMETER LibraryItemName
        The name of a vSphere Content Library Item
    .EXAMPLE
        Get-ContentLibraryItemFiles -LibraryName Test
    .EXAMPLE
        Get-ContentLibraryItemFiles -LibraryName Test -LibraryItemName TinyPhotonVM
#>
    param(
        [Parameter(Mandatory=$true)][String]$LibraryName,
        [Parameter(Mandatory=$false)][String]$LibraryItemName
    )

    $contentLibaryService = Get-CisService com.vmware.content.library
    $libaryIDs = $contentLibaryService.list()

    $results = @()
    foreach($libraryID in $libaryIDs) {
        $library = $contentLibaryService.get($libraryId)
        if($library.name -eq $LibraryName) {
            $contentLibaryItemService = Get-CisService com.vmware.content.library.item
            $itemIds = $contentLibaryItemService.list($libraryID)

            foreach($itemId in $itemIds) {
                $itemName = ($contentLibaryItemService.get($itemId)).name
                $contenLibraryItemFileSerice = Get-CisService com.vmware.content.library.item.file
                $files = $contenLibraryItemFileSerice.list($itemId)

                foreach($file in $files) {
                    if(!$LibraryItemName) {
                        $fileResult = [pscustomobject] @{
                            Name = $file.name;
                            Version = $file.version;
                            Size = $file.size;
                            Stored = $file.cached;
                        }
                        $results+=$fileResult
                    } else {
                        if($itemName -eq $LibraryItemName) {
                            $fileResult = [pscustomobject] @{
                                Name = $file.name;
                                Version = $file.version;
                                Size = $file.size;
                                Stored = $file.cached;
                            }
                            $results+=$fileResult
                        }
                    }
                }
            }
        }
    }
    $results
}

Function Set-ContentLibrary {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function updates the JSON Persistence property for a given Content Library
    .PARAMETER LibraryName
        The name of a vSphere Content Library
    .EXAMPLE
        Set-ContentLibraryItems -LibraryName Test -JSONPersistenceEnabled
    .EXAMPLE
        Set-ContentLibraryItems -LibraryName Test -JSONPersistenceDisabled
#>
    param(
        [Parameter(Mandatory=$true)][String]$LibraryName,
        [Parameter(Mandatory=$false)][Switch]$JSONPersistenceEnabled,
        [Parameter(Mandatory=$false)][Switch]$JSONPersistenceDisabled
    )

    $contentLibaryService = Get-CisService com.vmware.content.library
    $libaryIDs = $contentLibaryService.list()

    $found = $false
    foreach($libraryID in $libaryIDs) {
        $library = $contentLibaryService.get($libraryId)
        if($library.name -eq $LibraryName) {
            $found = $true
            break
        }
    }

    if($found) {
        $localLibraryService = Get-CisService -Name "com.vmware.content.local_library"

        if($JSONPersistenceEnabled) {
            $jsonPersist = $true
        } else {
            $jsonPersist = $false
        }

        $updateSpec = $localLibraryService.Help.update.update_spec.Create()
        $updateSpec.type = $library.type
        $updateSpec.publish_info.authentication_method = $library.publish_info.authentication_method
        $updateSpec.publish_info.persist_json_enabled = $jsonPersist
        Write-Host "Updating JSON Persistence configuration setting for $LibraryName  ..."
        $localLibraryService.update($library.id,$updateSpec)
    } else {
        Write-Host "Unable to find Content Library $Libraryname"
    }
}

Function New-ExtReplicatedContentLibrary {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function creates a new Subscriber Content Library from a JSON Persisted
        Content Library that has been externally replicated
    .PARAMETER LibraryName
        The name of the new vSphere Content Library
    .PARAMETER DatastoreName
        The name of the vSphere Datastore which contains JSON Persisted configuration file
    .PARAMETER SubscribeLibraryName
        The name fo the root directroy of the externally replicated Content Library residing on vSphere Datastore
    .PARAMETER AutoSync
        Whether or not to Automatically sync content
    .PARAMETER OnDemand
        Only sync content when requested
    .EXAMPLE
        New-ExtReplicatedContentLibrary -LibraryName Bar -DatastoreName iSCSI-02 -SubscribeLibraryName myExtReplicatedLibrary
    .EXAMPLE
        New-ExtReplicatedContentLibrary -LibraryName Bar -DatastoreName iSCSI-02 -SubscribeLibraryName myExtReplicatedLibrary -AutoSync $false -OnDemand $true
#>
    param(
        [Parameter(Mandatory=$true)][String]$LibraryName,
        [Parameter(Mandatory=$true)][String]$DatastoreName,
        [Parameter(Mandatory=$true)][String]$SubscribeLibraryName,
        [Parameter(Mandatory=$false)][Boolean]$AutoSync=$false,
        [Parameter(Mandatory=$false)][Boolean]$OnDemand=$true
    )

    $datastore = Get-Datastore -Name $DatastoreName

    if($datastore) {
        $datastoreId = $datastore.ExtensionData.MoRef.Value
        $datastoreUrl = $datastore.ExtensionData.Info.Url
        $subscribeUrl = $datastoreUrl + $SubscribeLibraryName + "/lib.json"

        $subscribeLibraryService = Get-CisService -Name "com.vmware.content.subscribed_library"

        $StorageSpec = [pscustomobject] @{
                        datastore_id = $datastoreId;
                        type         = "DATASTORE";
        }

        $UniqueChangeId = [guid]::NewGuid().tostring()

        $createSpec = $subscribeLibraryService.Help.create.create_spec.Create()
        $createSpec.name = $LibraryName
        $addResults = $createSpec.storage_backings.Add($StorageSpec)
        $createSpec.subscription_info.automatic_sync_enabled = $false
        $createSpec.subscription_info.on_demand = $true
        $createSpec.subscription_info.subscription_url = $subscribeUrl
        $createSpec.subscription_info.authentication_method = "NONE"
        $createSpec.type = "SUBSCRIBED"
        Write-Host "Creating new Externally Replicated Content Library called $LibraryName ..."
        $library = $subscribeLibraryService.create($UniqueChangeId,$createSpec)
    }
}

Function Remove-SubscribedContentLibrary {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function deletes a Subscriber Content Library
    .PARAMETER LibraryName
        The name of the new vSphere Content Library to delete
    .EXAMPLE
        Remove-SubscribedContentLibrary -LibraryName Bar
#>
    param(
        [Parameter(Mandatory=$true)][String]$LibraryName
    )

    $contentLibaryService = Get-CisService com.vmware.content.library
    $libaryIDs = $contentLibaryService.list()

    $found = $false
    foreach($libraryID in $libaryIDs) {
        $library = $contentLibaryService.get($libraryId)
        if($library.name -eq $LibraryName) {
            $found = $true
            break
        }
    }

    if($found) {
        $subscribeLibraryService = Get-CisService -Name "com.vmware.content.subscribed_library"

        Write-Host "Deleting Subscribed Content Library $LibraryName ..."
        $subscribeLibraryService.delete($library.id)
    } else {
        Write-Host "Unable to find Content Library $LibraryName"
    }
}

Function New-LocalContentLibrary {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function creates a new Subscriber Content Library from a JSON Persisted
        Content Library that has been externally replicated
    .PARAMETER LibraryName
        The name of the new vSphere Content Library
    .PARAMETER DatastoreName
        The name of the vSphere Datastore to store the Content Library
    .PARAMETER Publish
        Whther or not to publish the Content Library, this is required for JSON Peristence
    .PARAMETER JSONPersistence
        Whether or not to enable JSON Persistence which enables external replication of Content Library
    .EXAMPLE
        New-LocalContentLibrary -LibraryName Foo -DatastoreName iSCSI-01 -Publish $true
    .EXAMPLE
        New-LocalContentLibrary -LibraryName Foo -DatastoreName iSCSI-01 -Publish $true -JSONPersistence $true
#>
    param(
        [Parameter(Mandatory=$true)][String]$LibraryName,
        [Parameter(Mandatory=$true)][String]$DatastoreName,
        [Parameter(Mandatory=$false)][Boolean]$Publish=$true,
        [Parameter(Mandatory=$false)][Boolean]$JSONPersistence=$false
    )

    $datastore = Get-Datastore -Name $DatastoreName

    if($datastore) {
        $datastoreId = $datastore.ExtensionData.MoRef.Value
        $localLibraryService = Get-CisService -Name "com.vmware.content.local_library"

        $StorageSpec = [pscustomobject] @{
                        datastore_id = $datastoreId;
                        type         = "DATASTORE";
        }

        $UniqueChangeId = [guid]::NewGuid().tostring()

        $createSpec = $localLibraryService.Help.create.create_spec.Create()
        $createSpec.name = $LibraryName
        $addResults = $createSpec.storage_backings.Add($StorageSpec)
        $createSpec.publish_info.authentication_method = "NONE"
        $createSpec.publish_info.persist_json_enabled = $JSONPersistence
        $createSpec.publish_info.published = $Publish
        $createSpec.type = "LOCAL"
        Write-Host "Creating new Local Content Library called $LibraryName ..."
        $library = $localLibraryService.create($UniqueChangeId,$createSpec)
    }
}

Function Remove-LocalContentLibrary {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function deletes a Local Content Library
    .PARAMETER LibraryName
        The name of the new vSphere Content Library to delete
    .EXAMPLE
        Remove-LocalContentLibrary -LibraryName Bar
#>
    param(
        [Parameter(Mandatory=$true)][String]$LibraryName
    )

    $contentLibaryService = Get-CisService com.vmware.content.library
    $libaryIDs = $contentLibaryService.list()

    $found = $false
    foreach($libraryID in $libaryIDs) {
        $library = $contentLibaryService.get($libraryId)
        if($library.name -eq $LibraryName) {
            $found = $true
            break
        }
    }

    if($found) {
        $localLibraryService = Get-CisService -Name "com.vmware.content.local_library"

        Write-Host "Deleting Local Content Library $LibraryName ..."
        $localLibraryService.delete($library.id)
    } else {
        Write-Host "Unable to find Content Library $LibraryName"
    }
}

Function Copy-ContentLibrary {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function copies all library items from one Content Library to another
    .PARAMETER SourceLibaryName
        The name of the source Content Library to copy from
    .PARAMETER DestinationLibaryName
        The name of the desintation Content Library to copy to
    .PARAMETER DeleteSourceFile
        Whther or not to delete library item from the source Content Library after copy
    .EXAMPLE
        Copy-ContentLibrary -SourceLibaryName Foo -DestinationLibaryName Bar
    .EXAMPLE
        Copy-ContentLibrary -SourceLibaryName Foo -DestinationLibaryName Bar -DeleteSourceFile $true
#>
    param(
        [Parameter(Mandatory=$true)][String]$SourceLibaryName,
        [Parameter(Mandatory=$true)][String]$DestinationLibaryName,
        [Parameter(Mandatory=$false)][Boolean]$DeleteSourceFile=$false
    )

    $sourceLibraryId = (Get-ContentLibrary -LibraryName $SourceLibaryName).Id
    if($sourceLibraryId -eq $null) {
        Write-Host -ForegroundColor red "Unable to find Source Content Library named $SourceLibaryName"
        exit
    }
    $destinationLibraryId = (Get-ContentLibrary -LibraryName $DestinationLibaryName).Id
    if($destinationLibraryId -eq $null) {
        Write-Host -ForegroundColor Red "Unable to find Destination Content Library named $DestinationLibaryName"
        break
    }

    $sourceItemFiles = Get-ContentLibraryItems -LibraryName $SourceLibaryName
    if($sourceItemFiles -eq $null) {
        Write-Host -ForegroundColor red "Unable to retrieve Content Library Items from $SourceLibaryName"
        break
    }

    $contentLibaryItemService = Get-CisService com.vmware.content.library.item

    foreach ($sourceItemFile in  $sourceItemFiles) {
        # Check to see if file already exists in destination Content Library
        $result = Get-ContentLibraryItems -LibraryName $DestinationLibaryName -LibraryItemName $sourceItemFile.Name

        if($result -eq $null) {
            # Create CopySpec
            $copySpec = $contentLibaryItemService.Help.copy.destination_create_spec.Create()
            $copySpec.library_id = $destinationLibraryId
            $copySpec.name = $sourceItemFile.Name
            $copySpec.description = $sourceItemFile.Description
            # Create random Unique Copy Id
            $UniqueChangeId = [guid]::NewGuid().tostring()

            # Perform Copy
            try {
                Write-Host -ForegroundColor Cyan "Copying" $sourceItemFile.Name "..."
                $copyResult = $contentLibaryItemService.copy($UniqueChangeId, $sourceItemFile.Id, $copySpec)
            } catch {
                Write-Host -ForegroundColor Red "Failed to copy" $sourceItemFile.Name
                $Error[0]
                break
            }

            # Delete source file if set to true
            if($DeleteSourceFile) {
                try {
                    Write-Host -ForegroundColor Magenta "Deleteing" $sourceItemFile.Name "..."
                    $deleteResult = $contentLibaryItemService.delete($sourceItemFile.Id)
                } catch {
                    Write-Host -ForegroundColor Red "Failed to delete" $sourceItemFile.Name
                    $Error[0]
                    break
                }
            }
        } else {
            Write-Host -ForegroundColor Yellow "Skipping" $sourceItemFile.Name "already exists"

            # Delete source file if set to true
            if($DeleteSourceFile) {
                try {
                    Write-Host -ForegroundColor Magenta "Deleteing" $sourceItemFile.Name "..."
                    $deleteResult = $contentLibaryItemService.delete($sourceItemFile.Id)
                } catch {
                    Write-Host -ForegroundColor Red "Failed to delete" $sourceItemFile.Name
                    break
                }
            }
        }
    }
}

Function New-VMTX {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function clones a VM to VM Template in Content Library (currently only supported on VMC)
    .PARAMETER SourceVMName
        The name of the source VM to clone
    .PARAMETER VMTXName
        The name of the VM Template in Content Library
    .PARAMETER Description
        Description of the VM template
    .PARAMETER LibaryName
        The name of the Content Library to clone to
    .PARAMETER FolderName
        The name of vSphere Folder (Defaults to Workloads for VMC)
    .PARAMETER ResourcePoolName
        The name of the vSphere Resource Pool (Defaults to Compute-ResourcePools for VMC)
    .EXAMPLE
        New-VMTX -SourceVMName "Windows10-BaseInstall" -VMTXName "Windows10-VMTX-Template" -LibraryName "VMC-CL-01"
#>
    param(
        [Parameter(Mandatory=$true)][String]$SourceVMName,
        [Parameter(Mandatory=$true)][String]$VMTXName,
        [Parameter(Mandatory=$false)][String]$Description,
        [Parameter(Mandatory=$true)][String]$LibraryName,
        [Parameter(Mandatory=$false)][String]$FolderName="Workloads",
        [Parameter(Mandatory=$false)][String]$ResourcePoolName="Compute-ResourcePool"
    )

    $vmtxService = Get-CisService -Name "com.vmware.vcenter.vm_template.library_items"

    $sourceVMId = ((Get-VM -Name $SourceVMName).ExtensionData.MoRef).Value
    $libraryId = ((Get-ContentLibrary -LibraryName $LibraryName).Id).Value
    $folderId = ((Get-Folder -Name $FolderName).ExtensionData.MoRef).Value
    $rpId = ((Get-ResourcePool -Name $ResourcePoolName).ExtensionData.MoRef).Value

    $vmtxCreateSpec =  $vmtxService.Help.create.spec.Create()
    $vmtxCreateSpec.source_vm = $sourceVMId
    $vmtxCreateSpec.name = $VMTXName
    $vmtxCreateSpec.description = $Description
    $vmtxCreateSpec.library = $libraryId
    $vmtxCreateSpec.placement.folder = $folderId
    $vmtxCreateSpec.placement.resource_pool = $rpId

    Write-Host "`nCreating new VMTX Template from $SourceVMName in Content Library $LibraryName ..."
    $result = $vmtxService.create($vmtxCreateSpec)
}

Function New-VMFromVMTX {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function deploys a new VM from Template in Content Library (currently only supported in VMC)
    .PARAMETER VMTXName
        The name of the VM Template in Content Library to deploy from
    .PARAMETER NewVMName
        The name of the new VM to deploy
    .PARAMETER FolderName
        The name of vSphere Folder (Defaults to Workloads for VMC)
    .PARAMETER ResourcePoolName
        The name of the vSphere Resource Pool (Defaults to Compute-ResourcePools for VMC)
    .PARAMETER NumCpu
        The number of vCPU to configure for the new VM
    .PARAMETER MemoryMb
        The amount of memory (MB) to configure for the new VM
    .PARAMETER PowerOn
        To power on the VM after deploy
    .EXAMPLE
        New-VMFromVMTX -NewVMName "FooFoo" -VMTXName "FooBar" -PowerOn $true -NumCpu 4 -MemoryMB 2048
#>
    param(
        [Parameter(Mandatory=$true)][String]$VMTXName,
        [Parameter(Mandatory=$true)][String]$NewVMName,
        [Parameter(Mandatory=$false)][String]$FolderName="Workloads",
        [Parameter(Mandatory=$false)][String]$ResourcePoolName="Compute-ResourcePool",
        [Parameter(Mandatory=$false)][String]$DatastoreName="WorkloadDatastore",
        [Parameter(Mandatory=$false)][Int]$NumCpu,
        [Parameter(Mandatory=$false)][Int]$MemoryMB,
        [Parameter(Mandatory=$false)][Boolean]$PowerOn=$false
    )

    $vmtxService = Get-CisService -Name "com.vmware.vcenter.vm_template.library_items"
    $vmtxId = (Get-ContentLibraryItem -Name $VMTXName).Id
    $folderId = ((Get-Folder -Name $FolderName).ExtensionData.MoRef).Value
    $rpId = ((Get-ResourcePool -Name $ResourcePoolName).ExtensionData.MoRef).Value
    $datastoreId = ((Get-Datastore -Name $DatastoreName).ExtensionData.MoRef).Value

    $vmtxDeploySpec =  $vmtxService.Help.deploy.spec.Create()
    $vmtxDeploySpec.name = $NewVMName
    $vmtxDeploySpec.powered_on = $PowerOn
    $vmtxDeploySpec.placement.folder = $folderId
    $vmtxDeploySpec.placement.resource_pool = $rpId
    $vmtxDeploySpec.vm_home_storage.datastore = $datastoreId
    $vmtxDeploySpec.disk_storage.datastore = $datastoreId

    if($NumCpu) {
        $vmtxDeploySpec.hardware_customization.cpu_update.num_cpus = $NumCpu
    }
    if($MemoryMB) {
        $vmtxDeploySpec.hardware_customization.memory_update.memory = $MemoryMB
    }

    Write-Host "`nDeploying new VM $NewVMName from VMTX Template $VMTXName ..."
    $results = $vmtxService.deploy($vmtxId,$vmtxDeploySpec)
}