function Get-CISTag {
<#  
.SYNOPSIS  
    Gathers tag information from the CIS REST API endpoint
.DESCRIPTION 
    Will provide a list of tags
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Name
    Tag name which should be retreived
.PARAMETER Category
    Tag category name which should be retreived
.PARAMETER Id
    Tag ID which should be retreived 
.EXAMPLE
	Get-CISTag
    Retreives all tag information 
.EXAMPLE
	Get-CISTag -Name tagName
    Retreives the tag information based on the specified name
#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low')] 
	param(
	[Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
    [String]$Name,
    [Parameter(Mandatory=$false,Position=1,ValueFromPipelineByPropertyName=$true)]
    [String]$Category,
    [Parameter(Mandatory=$false,Position=2,ValueFromPipelineByPropertyName=$true)]
    [String]$Id
  	)

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagSvc = Get-CisService -Name com.vmware.cis.tagging.tag 
        if ($PSBoundParameters.ContainsKey("Id")) {
            $tagOutput = $tagSvc.get($Id)
        } else {
            $tagArray = @()
            $tagIdList = $tagSvc.list() | Select-Object -ExpandProperty Value
            foreach ($t in $tagIdList) {
                $tagArray += $tagSvc.get($t)
            }
            if ($PSBoundParameters.ContainsKey("Name")) {
                $tagOutput = $tagArray | Where {$_.Name -eq $Name}
            } elseif ($PSBoundParameters.ContainsKey("Category")) { 
                $tagCatid = Get-CISTagCategory -Name $Category | Select-Object -ExpandProperty Id
                $tagIdList = $tagSvc.list_tags_for_category($tagCatid)
                $tagArray2 = @()
                foreach ($t in $tagIdList) {
                    $tagArray2 += $tagSvc.get($t)
                }
                $tagOutput = $tagArray2
            } else {
                $tagOutput = $tagArray
            }
        }
        $tagOutput | Select-Object Id, Name, Description
    }

}

function New-CISTag {
<#  
.SYNOPSIS  
    Creates a new tag from the CIS REST API endpoint
.DESCRIPTION 
    Will create a new tag
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Name
    Tag name which should be created
.PARAMETER Category
    Category name where the new tag should be associated
.PARAMETER Description
    Description for the new tag
.PARAMETER CategoryID
    Category ID where the new tag should be associated
.EXAMPLE
    New-CISTag -Name tagName -Category categoryName -Description "Tag Descrition"
    Creates a new tag based on the specified name
#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Medium')] 
    param(
    [Parameter(Mandatory=$true,Position=0)]
    [String]$Name,
    [Parameter(Mandatory=$false,Position=1)]
    [String]$Category,
    [Parameter(Mandatory=$false,Position=2)]
    [String]$Description,
    [Parameter(Mandatory=$false,Position=3)]
    [String]$CategoryID
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagSvc = Get-CisService -Name com.vmware.cis.tagging.tag 
        $tagCreateHelper = $tagSvc.Help.create.create_spec.Create()
        $tagCreateHelper.name = $Name
        if ($PSBoundParameters.ContainsKey("Category")) {
            $tagCreateHelper.category_id = Get-CISTagCategory -Name $Category | Select-Object -ExpandProperty Id
        } elseif ($PSBoundParameters.ContainsKey("CategoryId")) {
            $tagCreateHelper.category_id = $CategoryID
        } else {Write-Warning "No Category input found. Add a Category name or ID."; break}
        if ($PSBoundParameters.ContainsKey("Description")) {
            $tagCreateHelper.description = $Description
        } else {
            $tagCreateHelper.description = ""
        }
        $tagNewId = $tagSvc.create($tagCreateHelper)
        Get-CISTag -Id $tagNewId
    }

}

function Remove-CISTag {
<#  
.SYNOPSIS  
    Removes a tag from the CIS REST API endpoint
.DESCRIPTION 
    Will delete a new tag
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Name
    Tag name which should be removed
.PARAMETER ID
    Tag ID which should be removed
.EXAMPLE
    Remove-CISTag -Name tagName 
    Removes a new tag based on the specified name
#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')] 
    param(
    [Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
    [String]$Name,
    [Parameter(Mandatory=$false,Position=1,ValueFromPipelineByPropertyName=$true)]
    [String]$ID
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagSvc = Get-CisService -Name com.vmware.cis.tagging.tag 
        if ($ID) {
            $tagSvc.delete($ID)
        } else {
            $tagId = Get-CISTag -Name $Name | select -ExpandProperty Id
            if ($tagId) {$tagSvc.delete($tagId)}
            else {Write-Warning "No valid tag found."}
        }
    }
}

function Get-CISTagCategory {
<#  
.SYNOPSIS  
    Gathers tag category information from the CIS REST API endpoint
.DESCRIPTION 
    Will provide a list of tag categories
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Name
    Tag category name which should be retreived 
.PARAMETER Id
    Tag category ID which should be retreived
.EXAMPLE
    Get-CISTagCategory
    Retreives all tag category information 
.EXAMPLE
    Get-CISTagCategory -Name tagCategoryName
    Retreives the tag category information based on the specified name
#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low')] 
    param(
    [Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
    [String]$Name,
    [Parameter(Mandatory=$false,Position=2,ValueFromPipelineByPropertyName=$true)]
    [String]$Id
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagCatSvc = Get-CisService -Name com.vmware.cis.tagging.category
        if ($PSBoundParameters.ContainsKey("Id")) {
            $tagCatOutput = $tagCatSvc.get($Id)
        } else {
            $tagCatArray = @()
            $tagCatIdList = $tagCatSvc.list() | Select-Object -ExpandProperty Value
            foreach ($tc in $tagCatIdList) {
                $tagCatArray += $tagCatSvc.get($tc)
            }
            if ($PSBoundParameters.ContainsKey("Name")) {
                $tagCatOutput = $tagCatArray | Where {$_.Name -eq $Name}
            } else {
                $tagCatOutput = $tagCatArray
            }
        }
        $tagCatOutput | Select-Object Id, Name, Description, Cardinality
    }

}

function New-CISTagCategory {
<#  
.SYNOPSIS  
    Creates a new tag category from the CIS REST API endpoint
.DESCRIPTION 
    Will create a new tag category
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Name
    Tag category name which should be created 
.PARAMETER Description
    Tag category ID which should be retreived
.PARAMETER Cardinality
    Tag category ID which should be retreived
.PARAMETER AssociableTypes
    Tag category ID which should be retreived    
.EXAMPLE
    New-CISTagCategory -Name NewTagCategoryName -Description "New Tag Category Description" -Cardinality "Single" -AssociableTypes    
    Creates a new tag category with the specified information
#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Medium')] 
    param(
    [Parameter(Mandatory=$true,Position=0)]
    [String]$Name,
    [Parameter(Mandatory=$false,Position=1)]
    [String]$Description,
    [Parameter(Mandatory=$false,Position=2)]
    [ValidateSet("SINGLE","MULTIPLE")]
    [String]$Cardinality = "SINGLE",
    [Parameter(Mandatory=$false,Position=3)]
    [ValidateSet("All", "Cluster", "Datacenter", "Datastore", "DatastoreCluster", "DistributedPortGroup", "DistributedSwitch", "Folder", "ResourcePool", "VApp", "VirtualPortGroup", "VirtualMachine", "VMHost")]
    [String]$AssociableTypes = "All"
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagCatSvc = Get-CisService -Name com.vmware.cis.tagging.category
        $tagCatCreateHelper = $tagCatSvc.Help.create.create_spec.Create()
        $tagCatCreateHelper.name = $Name
        if ($PSBoundParameters.ContainsKey("Description")) {
            $tagCatCreateHelper.description = $Description
        } else {$tagCatCreateHelper.description = ""}
        $tagCatCreateHelper.cardinality = $Cardinality
        $tagCatCreateAssocTypeHelper = $tagCatSvc.help.create.create_spec.associable_types.create()
        $tagCatCreateAssocTypeHelper.Add($AssociableTypes)
        $tagCatCreateHelper.associable_types = $tagCatCreateAssocTypeHelper
        $tagCatNewId = $tagCatSvc.create($tagCatCreateHelper)
        Get-CISTagCategory -Id $tagCatNewId
    }

}

function Remove-CISTagCategory {
<#  
.SYNOPSIS  
    Removes tag category information from the CIS REST API endpoint
.DESCRIPTION 
    Will remove a tag categorie
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Name
    Tag category name which should be removed 
.PARAMETER Id
    Tag category ID which should be removed
.EXAMPLE
    Remove-CISTagCategory -Name tagCategoryName
    Removes the tag category information based on the specified name

#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')] 
    param(
    [Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
    [String]$Name,
    [Parameter(Mandatory=$false,Position=2,ValueFromPipelineByPropertyName=$true)]
    [String]$Id
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagCatSvc = Get-CisService -Name com.vmware.cis.tagging.category
        if ($PSBoundParameters.ContainsKey("Id")) {
            $tagCatSvc.delete($Id)
        } elseif ($PSBoundParameters.ContainsKey("Name")) {
            $tagCatId = Get-CISTagCategory -Name $Name | Select-Object -ExpandProperty Id
            $tagCatSvc.delete($tagCatId)
        } else {Write-Warning "No tag category found."}
    }
}

function Get-CISTagAssignment {
<#  
.SYNOPSIS  
    Displays a list of the tag assignments from the CIS REST API endpoint
.DESCRIPTION 
    Will provide a list of the tag assignments
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Category
    Tag category name which should be referenced
.PARAMETER Entity
    Object name which should be retreived
.PARAMETER ObjectId
    Object ID which should be retreived
.EXAMPLE
    Get-CISTagAssignment 
    Retreives all tag assignment information
.EXAMPLE
    Get-CISTagAssignment -Entity VMName
    Retreives all tag assignments for the VM name
.EXAMPLE
    Get-CISTagAssignment -ObjectId 'vm-11'
    Retreives all tag assignments for the VM object
#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low')] 
    param(
    [Parameter(Mandatory=$false,Position=0)]
    [String]$Category,
    [Parameter(Mandatory=$false,Position=1)]
    [String]$Entity,
    [Parameter(Mandatory=$false,Position=2,ValueFromPipelineByPropertyName=$true)]
    [String]$ObjectId
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagOutput = @()
        [Boolean]$vCenterConn = $false
        $tagAssocSvc = Get-CisService -Name com.vmware.cis.tagging.tag_association
        if ($PSBoundParameters.ContainsKey("ObjectId")) {
            if ($ObjectId.split('-')[0] -eq 'vm') {
                $objType = 'VirtualMachine'
            } else {Write-Warning 'Only VirtualMachine types currently supported.'; break}
            $objObject = $tagAssocSvc.help.list_attached_tags.object_id.create()
            $objObject.id = $ObjectId
            $objObject.type = $objType
            $tagIdOutput = $tagAssocSvc.list_attached_tags($objObject)
        } elseif ($PSBoundParameters.ContainsKey("Entity")) {
            if ($global:DefaultVIServer -and $global:DefaultVIServer.Name -eq $global:DefaultCisServers.Name) {
                [Boolean]$vCenterConn = $true
                $viObject = (Get-Inventory -Name $Entity).ExtensionData.MoRef
                $objObject = $tagAssocSvc.help.list_attached_tags.object_id.create()
                $objObject.id = $viObject.Value
                $objObject.type = $viObject.type
            } else {
                $vmSvc = Get-CisService -Name com.vmware.vcenter.vm
                $filterVmNameObj = $vmsvc.help.list.filter.create()
                $filterVmNameObj.names.add($Entity) | Out-Null
                $objId = $vmSvc.list($filterVmNameObj) | Select-Object -ExpandProperty vm
                if ($objId) {$objType = 'VirtualMachine'}
                else {Write-Warning "No entities found."; break}
                $objObject = $tagAssocSvc.help.list_attached_tags.object_id.create()
                $objObject.id = $objId
                $objObject.type = $objType
            }
            $tagIdOutput = $tagAssocSvc.list_attached_tags($objObject)
        } else {
            $tagSvc = Get-CisService -Name com.vmware.cis.tagging.tag 
            $tagIdOutput = @()
            $tagCategories = Get-CISTagCategory | Sort-Object -Property Name
            if ($Category) {
                $tagCatId = $tagCategories | where {$_.Name -eq $Category} | Select-Object -ExpandProperty Id
                $tagIdOutput += $tagSvc.list_tags_for_category($tagCatId)
            } else {
                foreach ($tagCat in $tagCategories) {
                    $tagIdOutput += $tagSvc.list_tags_for_category($tagCat.id)
                }
            }
        }
        $tagReference = Get-CISTag

        if ($Entity -or $ObjectId) {
            foreach ($tagId in $tagIdOutput) {
                $tagAttObj = @()
                if ($Entity) {
                    $tagAttObj += $tagAssocSvc.list_attached_objects($tagId) | where {$_.type -eq $viObject.type -and $_.id -eq $viObject.Value}
                } else {
                    $tagAttObj += $tagAssocSvc.list_attached_objects($tagId) | where {$_.id -eq $ObjectId}
                }
                foreach ($obj in $tagAttObj) {
                    if ($obj.type -eq "VirtualMachine") {
                        if (-Not $vmSvc) {$vmSvc = Get-CisService -Name com.vmware.vcenter.vm}
                        $filterVmObj = $vmsvc.help.list.filter.create()
                        $filterVmObj.vms.add($obj.Id) | Out-Null
                        $objName = $vmSvc.list($filterVmObj) | Select-Object -ExpandProperty Name
                    }
                    else {$objName = 'Object Not Found'}                
                    $tempObject = "" | Select-Object Tag, Entity
                    $tempObject.Tag = $tagReference | where {$_.id -eq $tagId} | Select-Object -ExpandProperty Name
                    $tempObject.Entity = $objName
                    $tagOutput += $tempObject
                }
            }
        } else {
            foreach ($tagId in $tagIdOutput) {
                $tagAttObj = @()
                $tagAttObj += $tagAssocSvc.list_attached_objects($tagId)
                if ($global:DefaultVIServer -and $global:DefaultVIServer.Name -eq $global:DefaultCisServers.Name) {
                    [Boolean]$vCenterConn = $true
                }  elseif ($tagAttObj.Type -contains 'VirtualMachine') {
                    if (-Not $vmSvc) {$vmSvc = Get-CisService -Name com.vmware.vcenter.vm}
                }
                foreach ($obj in $tagAttObj) {
                    if ($vCenterConn) {
                        $newViObj = New-Object -TypeName VMware.Vim.ManagedObjectReference
                        $newViObj.Type = $obj.type
                        $newViObj.Value = $obj.id
                        $objName = Get-View -Id $newViObj -Property Name | Select-Object -ExpandProperty Name
                    } elseif ($obj.type -eq "VirtualMachine") {
                        $filterVmObj = $vmsvc.help.list.filter.create()
                        $filterVmObj.vms.add($obj.Id) | Out-Null
                        $objName = $vmSvc.list($filterVmObj) | Select-Object -ExpandProperty Name
                    } else {$objName = 'Object Not Found'}                
                    $tempObject = "" | Select-Object Tag, Entity
                    $tempObject.Tag = $tagReference | where {$_.id -eq $tagId} | Select-Object -ExpandProperty Name
                    $tempObject.Entity = $objName
                    $tagOutput += $tempObject
                }
            }
        }
        return $tagOutput
    }
}

function New-CISTagAssignment {
<#  
.SYNOPSIS  
    Creates new tag assignments from the CIS REST API endpoint
.DESCRIPTION 
    Will create new tag assignments
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Tag
    Tag name which should be referenced
.PARAMETER Entity
    Object name which should be retreived
.PARAMETER TagId
    Tag ID/s which should be referenced
.PARAMETER ObjectId
    Object ID which/s should be retreived
.EXAMPLE
    New-CISTagAssignment -Tag TagName -Entity VMName
    Creates a tag assignment between the Tag name and the VM name
.EXAMPLE
    New-CISTagAssignment -TagId $tagId -ObjectId 'vm-11'
    Creates a tag assignment between the Tag ID and the Object ID
#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Medium')] 
    param(
    [Parameter(Mandatory=$false,Position=0)]
    $Tag,
    [Parameter(Mandatory=$false,Position=1)]
    $Entity,
    [Parameter(Mandatory=$false,Position=2)]
    $TagId,
    [Parameter(Mandatory=$false,Position=3)]
    $ObjectId
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagAssocSvc = Get-CisService -Name com.vmware.cis.tagging.tag_association
        if ($PSBoundParameters.ContainsKey("Tag") -and $PSBoundParameters.ContainsKey("Entity")) {
            if ($Tag -is [array] -and $Entity -isnot [array]) {
                $tagIdList = $tagAssocSvc.help.attach_multiple_tags_to_object.tag_ids.create()
                foreach ($t in $Tag) {
                    $tempId = Get-CISTag -Name $t | Select-Object -ExpandProperty Id
                    $tagIdList.add($tempId) | Out-Null
                }
                if ($global:DefaultVIServer -and $global:DefaultVIServer.Name -eq $global:DefaultCisServers.Name) {
                    $viObject = (Get-Inventory -Name $Entity).ExtensionData.MoRef
                    $objObject = $tagAssocSvc.help.list_attached_tags.object_id.create()
                    $objObject.id = $viObject.Value
                    $objObject.type = $viObject.type
                } else {
                    $vmSvc = Get-CisService -Name com.vmware.vcenter.vm
                    $filterVmNameObj = $vmsvc.help.list.filter.create()
                    $filterVmNameObj.names.add($Entity) | Out-Null
                    $objId = $vmSvc.list($filterVmNameObj) | Select-Object -ExpandProperty vm
                    if ($objId) {$objType = 'VirtualMachine'}
                    else {Write-Warning "No entities found."; break}
                    $objObject = $tagAssocSvc.help.list_attached_tags.object_id.create()
                    $objObject.id = $objId
                    $objObject.type = $objType
                }
                $tagAssocSvc.attach_multiple_tags_to_object($objObject,$tagIdList) | Out-Null
            } elseif ($Tag -isnot [array] -and $Entity -is [array]) {
                $tagId = Get-CISTag -Name $Tag | Select-Object -ExpandProperty Id
                $objList = $tagAssocSvc.help.attach_tag_to_multiple_objects.object_ids.create()
                foreach ($e in $Entity) {
                    if ($global:DefaultVIServer -and $global:DefaultVIServer.Name -eq $global:DefaultCisServers.Name) {
                        $viObject = (Get-Inventory -Name $e).ExtensionData.MoRef
                        $objObject = $tagAssocSvc.help.list_attached_tags.object_id.create()
                        $objObject.id = $viObject.Value
                        $objObject.type = $viObject.type
                    } else {
                        $vmSvc = Get-CisService -Name com.vmware.vcenter.vm
                        $filterVmNameObj = $vmsvc.help.list.filter.create()
                        $filterVmNameObj.names.add($Entity) | Out-Null
                        $objId = $vmSvc.list($filterVmNameObj) | Select-Object -ExpandProperty vm
                        if ($objId) {$objType = 'VirtualMachine'}
                        else {Write-Warning "No entities found."; break}
                        $objObject = $tagAssocSvc.help.list_attached_tags.object_id.create()
                        $objObject.id = $objId
                        $objObject.type = $objType
                    }
                    $objList.add($objObject) | Out-Null
                }
                $tagAssocSvc.attach_tag_to_multiple_objects($TagId,$objList) | Out-Null
            } elseif ($Tag -isnot [array] -and $Entity -isnot [array]) {
                $tagId = Get-CISTag -Name $Tag | Select-Object -ExpandProperty Id
                if ($global:DefaultVIServer -and $global:DefaultVIServer.Name -eq $global:DefaultCisServers.Name) {
                    $viObject = (Get-Inventory -Name $Entity).ExtensionData.MoRef
                    $objObject = $tagAssocSvc.help.list_attached_tags.object_id.create()
                    $objObject.id = $viObject.Value
                    $objObject.type = $viObject.type
                } else {
                    $vmSvc = Get-CisService -Name com.vmware.vcenter.vm
                    $filterVmNameObj = $vmsvc.help.list.filter.create()
                    $filterVmNameObj.names.add($Entity) | Out-Null
                    $objId = $vmSvc.list($filterVmNameObj) | Select-Object -ExpandProperty vm
                    if ($objId) {$objType = 'VirtualMachine'}
                    else {Write-Warning "No entities found."; break}
                    $objObject = $tagAssocSvc.help.list_attached_tags.object_id.create()
                    $objObject.id = $objId
                    $objObject.type = $objType
                }
                $tagAssocSvc.attach($TagId,$objObject) | Out-Null
            }
        } elseif ($PSBoundParameters.ContainsKey("TagId") -and $PSBoundParameters.ContainsKey("ObjectId")) {
            if ($ObjectId.split('-')[0] -eq 'vm') {
                $objType = 'VirtualMachine'
            } else {Write-Warning 'Only VirtualMachine types currently supported.'; break}
            if ($TagId -is [array] -and $ObjectId -isnot [array]) {
                $objObject = $tagAssocSvc.help.attach_multiple_tags_to_object.object_id.create()
                $objObject.id = $ObjectId
                $objObject.type = $objType
                $tagIdList = $tagAssocSvc.help.attach_multiple_tags_to_object.tag_ids.create()
                foreach ($tId in $TagId) {
                    $tagIdList.add($tId) | Out-Null
                }
                $tagAssocSvc.attach_multiple_tags_to_object($objObject,$tagIdList) | Out-Null
            } elseif ($TagId -isnot [array] -and $ObjectId -is [array]) {
                $objList = $tagAssocSvc.help.attach_tag_to_multiple_objects.object_ids.create()
                foreach ($obj in $ObjectId) {
                    $objObject = $tagAssocSvc.help.attach_tag_to_multiple_objects.object_ids.element.create()
                    $objObject.id = $obj
                    $objObject.type = $objType
                    $objList.add($objObject) | Out-Null
                }
                $tagAssocSvc.attach_tag_to_multiple_objects($TagId,$objList) | Out-Null
            } elseif ($TagId -isnot [array] -and $ObjectId -isnot [array]) {
                $objObject = $tagAssocSvc.help.attach.object_id.create()
                $objObject.id = $ObjectId
                $objObject.type = $objType
                $tagAssocSvc.attach($TagId,$objObject) | Out-Null
            }
        
        } else {Write-Output "Multiple tags with multiple objects are not a supported call."}

    }
}

function Remove-CISTagAssignment {
<#  
.SYNOPSIS  
    Removes a tag assignment from the CIS REST API endpoint
.DESCRIPTION 
    Will remove provided tag assignments
.NOTES  
    Author:  Kyle Ruddy, @kmruddy
.PARAMETER Tag
    Tag name which should be removed
.PARAMETER Entity
    Object name which should be removed
.PARAMETER TagId
    Tag ID/s which should be removed
.PARAMETER ObjectId
    Object ID which/s should be removed
.EXAMPLE
    Remove-CISTagAssignment -TagId $tagId -ObjectId 'vm-11'
    Removes the tag assignment between the Tag ID and the Object ID
.EXAMPLE
    Remove-CISTagAssignment -Tag TagName -Entity VMName
    Removes the tag assignment between the Tag name and the Entity name
#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')] 
    param(
    [Parameter(Mandatory=$false,Position=0,ValueFromPipelineByPropertyName=$true)]
    $Tag,
    [Parameter(Mandatory=$false,Position=1,ValueFromPipelineByPropertyName=$true)]
    $Entity,
    [Parameter(Mandatory=$false,Position=2)]
    $TagId,
    [Parameter(Mandatory=$false,Position=3)]
    $ObjectId
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CIS Connection found, please use the Connect-CisServer to connect" } Else {
        $tagAssocSvc = Get-CisService -Name com.vmware.cis.tagging.tag_association
        if ($PSBoundParameters.ContainsKey("Tag") -and $PSBoundParameters.ContainsKey("Entity")) {
            if ($Tag -is [array] -and $Entity -isnot [array]) {
                $tagIdList = $tagAssocSvc.help.detach_multiple_tags_from_object.tag_ids.create()
                foreach ($t in $Tag) {
                    $tempId = Get-CISTag -Name $t | Select-Object -ExpandProperty Id
                    $tagIdList.add($tempId) | Out-Null
                }
                if ($global:DefaultVIServer -and $global:DefaultVIServer.Name -eq $global:DefaultCisServers.Name) {
                    $viObject = (Get-Inventory -Name $Entity).ExtensionData.MoRef
                    $objObject = $tagAssocSvc.help.detach_multiple_tags_from_object.object_id.create()
                    $objObject.id = $viObject.Value
                    $objObject.type = $viObject.type
                } else {
                    $vmSvc = Get-CisService -Name com.vmware.vcenter.vm
                    $filterVmNameObj = $vmsvc.help.list.filter.create()
                    $filterVmNameObj.names.add($Entity) | Out-Null
                    $objId = $vmSvc.list($filterVmNameObj) | Select-Object -ExpandProperty vm
                    if ($objId) {$objType = 'VirtualMachine'}
                    else {Write-Warning "No entities found."; break}
                    $objObject = $tagAssocSvc.help.detach_multiple_tags_from_object.object_id.create()
                    $objObject.id = $objId
                    $objObject.type = $objType
                }
                $tagAssocSvc.detach_multiple_tags_from_object($objObject,$tagIdList) | Out-Null
            } elseif ($Tag -isnot [array] -and $Entity -is [array]) {
                $tagId = Get-CISTag -Name $Tag | Select-Object -ExpandProperty Id
                $objList = $tagAssocSvc.help.detach_tag_from_multiple_objects.object_ids.create()
                foreach ($e in $Entity) {
                    if ($global:DefaultVIServer -and $global:DefaultVIServer.Name -eq $global:DefaultCisServers.Name) {
                        $viObject = (Get-Inventory -Name $e).ExtensionData.MoRef
                        $objObject = $tagAssocSvc.help.detach_tag_from_multiple_objects.object_ids.element.create()
                        $objObject.id = $viObject.Value
                        $objObject.type = $viObject.type
                    } else {
                        $vmSvc = Get-CisService -Name com.vmware.vcenter.vm
                        $filterVmNameObj = $vmsvc.help.list.filter.create()
                        $filterVmNameObj.names.add($Entity) | Out-Null
                        $objId = $vmSvc.list($filterVmNameObj) | Select-Object -ExpandProperty vm
                        if ($objId) {$objType = 'VirtualMachine'}
                        else {Write-Warning "No entities found."; break}
                        $objObject = $tagAssocSvc.help.detach_tag_from_multiple_objects.object_ids.element.create()
                        $objObject.id = $objId
                        $objObject.type = $objType
                    }
                    $objList.add($objObject) | Out-Null
                }
                $tagAssocSvc.detach_tag_from_multiple_objects($TagId,$objList) | Out-Null
            } elseif ($Tag -isnot [array] -and $Entity -isnot [array]) {
                $tagId = Get-CISTag -Name $Tag | Select-Object -ExpandProperty Id
                if ($global:DefaultVIServer -and $global:DefaultVIServer.Name -eq $global:DefaultCisServers.Name) {
                    $viObject = (Get-Inventory -Name $Entity).ExtensionData.MoRef
                    $objObject = $tagAssocSvc.help.detach.object_id.create()
                    $objObject.id = $viObject.Value
                    $objObject.type = $viObject.type
                } else {
                    $vmSvc = Get-CisService -Name com.vmware.vcenter.vm
                    $filterVmNameObj = $vmsvc.help.list.filter.create()
                    $filterVmNameObj.names.add($Entity) | Out-Null
                    $objId = $vmSvc.list($filterVmNameObj) | Select-Object -ExpandProperty vm
                    if ($objId) {$objType = 'VirtualMachine'}
                    else {Write-Warning "No entities found."; break}
                    $objObject = $tagAssocSvc.help.detach.object_id.create()
                    $objObject.id = $objId
                    $objObject.type = $objType
                }
                $tagAssocSvc.detach($TagId,$objObject) | Out-Null
            }
        } elseif ($PSBoundParameters.ContainsKey("TagId") -and $PSBoundParameters.ContainsKey("ObjectId")) {
            if ($ObjectId.split('-')[0] -eq 'vm') {
                $objType = 'VirtualMachine'
            } else {Write-Warning 'Only VirtualMachine types currently supported.'; break}
            if ($TagId -is [array] -and $ObjectId -isnot [array]) {
                $objObject = $tagAssocSvc.help.detach_multiple_tags_from_object.object_id.create()
                $objObject.id = $ObjectId
                $objObject.type = $objType
                $tagIdList = $tagAssocSvc.help.detach_multiple_tags_from_object.tag_ids.create()
                foreach ($tId in $TagId) {
                    $tagIdList.add($tId) | Out-Null
                }
                $tagAssocSvc.detach_multiple_tags_from_object($objObject,$tagIdList) | Out-Null
            } elseif ($TagId -isnot [array] -and $ObjectId -is [array]) {
                $objList = $tagAssocSvc.help.detach_tag_from_multiple_objects.object_ids.create()
                foreach ($obj in $ObjectId) {
                    $objObject = $tagAssocSvc.help.detach_tag_from_multiple_objects.object_ids.element.create()
                    $objObject.id = $obj
                    $objObject.type = $objType
                    $objList.add($objObject) | Out-Null
                }
                $tagAssocSvc.detach_tag_from_multiple_objects($TagId,$objList) | Out-Null
            } elseif ($TagId -isnot [array] -and $ObjectId -isnot [array]) {
                $objObject = $tagAssocSvc.help.detach.object_id.create()
                $objObject.id = $ObjectId
                $objObject.type = $objType
                $tagAssocSvc.detach($TagId,$objObject) | Out-Null
            }
        } else {Write-Output "Multiple tags with multiple objects are not a supported call."}

    }
}