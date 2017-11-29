Function Export-DRSRules {
<#
    .NOTES
    ===========================================================================
    Created by:     William Lam
    Date:          11/21/2017
    Blog:          https://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Export DRS Rules to JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .DESCRIPTION
        Export DRS Rules to JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .EXAMPLE
        Export-DRSRules -Path C:\Users\primp\Desktop\VMworld2017 -Cluster Windows-Cluster
#>
    param(
        [Parameter(Mandatory=$false)][String]$Path,
        [Parameter(Mandatory=$true)][String]$Cluster
    )

    $rules = Get-Cluster -Name $Cluster | Get-DrsRule

    $results = @()
    foreach ($rule in $rules) {
        $vmNames = @()
        $vmIds = $rule.VMIds

        # Reconstruct MoRef ID to VM Object to get Name
        foreach ($vmId in $vmIds) {
            $vm = New-Object VMware.Vim.ManagedObjectReference
            $vm.Type = "VirtualMachine"
            $vm.Value = ($vmId -replace "VirtualMachine-","")
            $vmView = Get-View $vm
            $vmNames += $vmView.name
        }

        $rulesObject = [pscustomobject] @{
            Name = $rule.ExtensionData.Name;
            Type = $rule.Type; #VMAffinity = 1, VMAntiAffinity = 0
            Enabled = $rule.Enabled;
            Mandatory = $rule.ExtensionData.Mandatory
            VM = $vmNames
        }
        $results+=$rulesObject
    }
    if($Path) {
        $fullPath = $Path + "\DRSRules.json"
        Write-Host -ForegroundColor Green "Exporting DRS Rules to $fullpath ..."
        $results | ConvertTo-Json | Out-File $fullPath
    } else {
        $results | ConvertTo-Json
    }
}

Function Import-DRSRules {
<#
    .NOTES
    ===========================================================================
    Created by:     William Lam
    Date:          11/21/2017
    Blog:          https://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Import DRS Rules from JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .DESCRIPTION
        Import DRS Rules from JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .EXAMPLE
        Import-DRSRules -Path C:\Users\primp\Desktop\VMworld2017 -Cluster Windows-Cluster
#>
    param(
        [Parameter(Mandatory=$true)][String]$Path,
        [Parameter(Mandatory=$true)][String]$Cluster
    )

    Get-DrsRule -Cluster $cluster | Remove-DrsRule -Confirm:$false | Out-Null

    $DRSRulesFilename = "/DRSRules.json"
    $fullPath = $Path + $DRSRulesFilename
    $json = Get-Content -Raw $fullPath | ConvertFrom-Json

    foreach ($line in $json) {
        $vmArr = @()
        $vmNames = $line.vm
        foreach ($vmName in $vmNames) {
            $vmView = Get-VM -Name $vmName
            $vmArr+=$vmView
        }
        New-DrsRule -Name $line.name -Enabled $line.Enabled -Cluster (Get-Cluster -Name $Cluster) -KeepTogether $line.Type -VM $vmArr
    }
}

Function Export-DRSClusterGroup {
<#
    .NOTES
    ===========================================================================
    Created by:     William Lam
    Date:          11/21/2017
    Blog:          https://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Export DRS Cluster Group Rules to JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .DESCRIPTION
        Export DRS Cluster Group Rules to JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .EXAMPLE
        Export-DRSClusterGroup -Path C:\Users\primp\Desktop\VMworld2017 -Cluster Windows-Cluster
#>
    param(
        [Parameter(Mandatory=$false)][String]$Path,
        [Parameter(Mandatory=$true)][String]$Cluster
    )

    $rules = Get-Cluster -Name $Cluster | Get-DrsClusterGroup

    $results = @()
    foreach ($rule in $rules) {
        $rulesObject = [pscustomobject] @{
            Name = $rule.ExtensionData.Name;
            Type = $rule.GroupType; #VMType = 1, HostType = 0
            Member = $rule.Member
        }
        $results+=$rulesObject
    }
    if($Path) {
        $fullPath = $Path + "\DRSClusterGroupRules.json"
        Write-Host -ForegroundColor Green "Exporting DRS Cluster Group Rules to $fullpath ..."
        $results | ConvertTo-Json | Out-File $fullPath
    } else {
        $results | ConvertTo-Json
    }
}

Function Import-DRSClusterClusterGroup {
<#
    .NOTES
    ===========================================================================
    Created by:     William Lam
    Date:          11/21/2017
    Blog:          https://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Import DRS Cluster Group Rules from JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .DESCRIPTION
        Import DRS Cluster Group Rules from JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .EXAMPLE
        Import-DRSClusterClusterGroup -Path C:\Users\primp\Desktop\VMworld2017 -Cluster Windows-Cluster
#>
    param(
        [Parameter(Mandatory=$true)][String]$Path,
        [Parameter(Mandatory=$true)][String]$Cluster
    )

    $DRSClusterGroupRulesFilename = "\DRSClusterGroupRules.json"
    $fullPath = $Path + $DRSClusterGroupRulesFilename
    $json = Get-Content -Raw $fullPath | ConvertFrom-Json

    foreach ($line in $json) {
        $memberArr = @()
        $members = $line.member

        # VMHost Group
        if($line.Type -eq 0) {
            foreach ($member in $members) {
                $memberView = Get-VMhost -Name $member
                $memberArr+=$memberView
            }
            New-DrsClusterGroup -Name $line.name -Cluster (Get-Cluster -Name $Cluster) -VMhost $memberArr
        # VM Group
        } else {
            foreach ($member in $members) {
                $memberView = Get-VM -Name $member
                $memberArr+=$memberView
            }
            New-DrsClusterGroup -Name $line.name -Cluster (Get-Cluster -Name $Cluster) -VM $memberArr
        }
    }
}

Function Export-Tag {
<#
    .NOTES
    ===========================================================================
    Created by:     William Lam
    Date:          11/21/2017
    Blog:          https://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Export vSphere Tags and VM Assocations to JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .DESCRIPTION
        Export vSphere Tags and VM Assocations to JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .EXAMPLE
        Export-Tag -Path C:\Users\primp\Desktop\VMworld2017
#>
    param(
        [Parameter(Mandatory=$false)][String]$Path
    )

    # Export Tag Categories
    $tagCatagorys = Get-TagCategory

    $tagCatresults = @()
    foreach ($tagCategory in $tagCatagorys) {
        $tagCatObj = [pscustomobject] @{
            Name = $tagCategory.Name;
            Cardinality = $tagCategory.Cardinality;
            Description = $tagCategory.Description;
            Type = $tagCategory.EntityType
        }
        $tagCatresults+=$tagCatObj
    }
    if($Path) {
        $fullPath = $Path + "\AllTagCategory.json"
        Write-Host -ForegroundColor Green "Exporting vSphere Tag Category to $fullpath ..."
        $tagCatresults | ConvertTo-Json | Out-File $fullPath
    } else {
        $tagCatresults | ConvertTo-Json
    }

    # Export Tags
    $tags = Get-Tag

    $tagResults = @()
    foreach ($tag in $tags) {
        $tagObj = [pscustomobject] @{
            Name = $tag.Name;
            Description = $tag.Description;
            Category = $tag.Category.Name
        }
        $tagResults+=$tagObj
    }
    if($Path) {
        $fullPath = $Path + "\AllTag.json"
        Write-Host -ForegroundColor Green "Exporting vSphere Tag to $fullpath ..."
        $tagResults | ConvertTo-Json | Out-File $fullPath
    } else {
        $tagResults | ConvertTo-Json
    }

    # Export VM to Tag Mappings
    $vms = Get-VM

    $vmResults = @()
    foreach ($vm in $vms) {
        $tagAssignments = $vm | Get-TagAssignment
        $tags = @()
        foreach ($tagAssignment in $tagAssignments) {
            $tag = $tagAssignment.Tag
            $tagName = $tag -split "/"
            $tags+=$tagName
        }
        $vmObj = [pscustomobject] @{
            Name = $vm.name;
            Tag = $tags
        }
        $vmResults+=$vmObj
    }
    if($Path) {
        $fullPath = $Path + "\AllTagAssocations.json"
        Write-Host -ForegroundColor Green "Exporting VM to vSphere Tag Assignment to $fullpath ..."
        $vmResults | ConvertTo-Json | Out-File $fullPath
    } else {
        $vmResults | ConvertTo-Json
    }
}

Function Import-Tag {
<#
    .NOTES
    ===========================================================================
    Created by:     William Lam
    Date:          11/21/2017
    Blog:          https://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Import vSphere Tags and VM Assocations from JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .DESCRIPTION
        Import vSphere Tags and VM Assocations from JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .EXAMPLE
        Import-Tag -Path C:\Users\primp\Desktop\VMworld2017
#>
    param(
        [Parameter(Mandatory=$true)][String]$Path
    )

    $tagCatFilename = "\AllTagCategory.json"
    $fullPath = $Path + $tagCatFilename
    $tagCategoryJson = Get-Content -Raw $fullPath | ConvertFrom-Json

    $tagFilename = "\AllTag.json"
    $fullPath = $Path + $tagFilename
    $tagJson = Get-Content -Raw $fullPath | ConvertFrom-Json

    $vmTagFilename = "\AllTagAssocations.json"
    $fullPath = $Path + $vmTagFilename
    $vmTagJson = Get-Content -Raw $fullPath | ConvertFrom-Json

    # Re-Create Tag Category
    foreach ($category in $tagCategoryJson) {
        if($category.Cardinality -eq 0) {
            $cardinality = "Single"
        } else {
            $cardinality = "Multiple"
        }
        New-TagCategory -Name $category.Name -Cardinality $cardinality -Description $category.Description -EntityType $category.Type
    }

    # Re-Create Tags
    foreach ($tag in $tagJson) {
        New-Tag -Name $tag.Name -Description $tag.Description -Category (Get-TagCategory -Name $tag.Category)
    }

    # Re-Create VM to Tag Mappings
    foreach ($vmTag in $vmTagJson) {
        $vm = Get-VM -Name $vmTag.name
        $tags = $vmTag.Tag
        foreach ($tag in $tags) {
            New-TagAssignment -Entity $vm -Tag (Get-Tag -Name $tag)
        }
    }
}

Function Export-VMFolder {
<#
    .NOTES
    ===========================================================================
    Created by:     William Lam
    Date:          11/21/2017
    Blog:          https://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Export vSphere Folder to JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .DESCRIPTION
        Export vSphere Folder to JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .EXAMPLE
        Export-VMFolder -Path C:\Users\primp\Desktop\VMworld2017
#>
    param(
        [Parameter(Mandatory=$false)][String]$Path
    )
    $vms = Get-VM

    $vmFolderResults = @()
    foreach ($vm in $vms) {
        $vmFolderObj = [pscustomobject] @{
            Name = $vm.name;
            Folder = $vm.Folder.Name;
        }
        $vmFolderResults+=$vmFolderObj
    }
    if($Path) {
        $fullPath = $Path + "\AllVMFolder.json"
        Write-Host -ForegroundColor Green "Exporting VM Folders to $fullpath ..."
        $vmFolderResults | ConvertTo-Json | Out-File $fullPath
    } else {
        $vmFolderResults | ConvertTo-Json
    }
}

Function Import-VMFolder {
<#
    .NOTES
    ===========================================================================
    Created by:     William Lam
    Date:          11/21/2017
    Blog:          https://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Import vSphere Folder from JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .DESCRIPTION
        Import vSphere Folder from JSON file based on VMworld Demo https://youtu.be/MagjfbIL4kg
    .EXAMPLE
        Import-VMFolder -Path C:\Users\primp\Desktop\VMworld2017
#>
    param(
        [Parameter(Mandatory=$true)][String]$Path
    )

    $vmFolderFilename = "\AllVMFolder.json"
    $fullPath = $Path + $vmFolderFilename
    $vmFolderJson = Get-Content -Raw $fullPath | ConvertFrom-Json

    # Root vm Folder
    $rootVMFolder = Get-Folder -Type VM -Name vm

    $folders = $vmFolderJson | Select Folder | Sort-Object -Property Folder -Unique
    foreach ($folder in $folders) {
        $rootVMFolder | New-Folder -Name $folder.folder
    }

    foreach ($vmFolder in $vmFolderJson) {
        $vm = Get-VM -Name $vmFolder.Name
        $folder = Get-Folder -Name $vmFolder.Folder
        Move-VM -VM $vm -Destination $folder
    }
}

Function Export-VMStoragePolicy {
<#
    .NOTES
    ===========================================================================
    Created by:     William Lam
    Date:          11/21/2017
    Blog:          https://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Export VM Storage Policies to JSON file
    .DESCRIPTION
        Export VM Storage Policies to JSON file
    .EXAMPLE
        Export-VMStoragePolicy -Path C:\Users\primp\Desktop\VMworld2017
#>
    param(
        [Parameter(Mandatory=$false)][String]$Path
    )

    foreach ($policy in Get-SpbmStoragePolicy) {
        $policyName = $policy.Name
        if($Path) {
            Write-Host -ForegroundColor Green "Exporting Policy $policyName to $Path\$policyName.xml ..."
            $policy | Export-SpbmStoragePolicy -FilePath $Path\$policyName.xml -Force | Out-Null
        } else {
            $policy
        }
    }
}

Function Import-VMStoragePolicy {
<#
    .NOTES
    ===========================================================================
    Created by:     William Lam
    Date:          11/21/2017
    Blog:          https://www.virtuallyghetto.com
    Twitter:       @lamw
    ===========================================================================

    .SYNOPSIS
        Import VM Storage Policies from JSON file
    .DESCRIPTION
        Import VM Storage Policies from JSON file
    .EXAMPLE
        Import-VMStoragePolicy -Path C:\Users\primp\Desktop\VMworld2017
#>
    param(
        [Parameter(Mandatory=$false)][String]$Path
    )

    foreach ($file in Get-ChildItem -Path $Path -Filter *.xml) {
        $policyName = $file.name
        $policyName = $policyName.replace(".xml","")
        if(Get-SpbmStoragePolicy -Name $policyName -ErrorAction SilentlyContinue) {
            Continue
        } else {
            Write-Host "Importing Policy $policyname ..."
            Import-SpbmStoragePolicy -FilePath $Path\$file -Name $policyName
        }
    }
}