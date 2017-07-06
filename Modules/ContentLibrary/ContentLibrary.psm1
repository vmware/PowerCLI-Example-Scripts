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
        $library = $contentLibaryService.get($libraryId)

        # Use vCenter REST API to retrieve name of Datastore that is backing the Content Library
        $datastoreService = Get-CisService com.vmware.vcenter.datastore
        $datastore = $datastoreService.get($library.storage_backings.datastore_id)

        if(!$LibraryName) {
            $libraryResult = [pscustomobject] @{
                Id = $library.Id;
                Name = $library.Name;
                Type = $library.Type;
                Description = $library.Description;
                Datastore = $datastore.name;
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