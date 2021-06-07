<#
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: BSD-2-Clause
#>
function Export-Tag {
   [CmdletBinding()]
   Param (
      [Parameter(Mandatory = $True, Position = 1)]
      [VMware.VimAutomation.ViCore.Types.V1.VIServer]$Server,

      [Parameter(Mandatory = $True, Position = 2)]
      [string]$Destination,

	  [Parameter(Mandatory = $False, Position = 3)]
      [boolean]$ExportAssignments
   )

   # Retrieve all categories
   $categoryList = Get-TagCategory -Server $server
   # Retrieve all tags
   $tagList = Get-Tag -Server $server
   # Store the tags, categories and assignments (if selected) in a list to export them at once
   If ($ExportAssignments) {
      $tagAssignments = Get-TagAssignment -Server $server
      $export = @($categoryList, $tagList, $tagAssignments)
   } else {
      $export = @($categoryList, $tagList)
   }
   # Export the tags and categories to the specified destination
   Export-Clixml -InputObject $export -Path $destination
}

function Import-Tag {
   [CmdletBinding()]
   Param (
      [Parameter(Mandatory = $True, Position = 1)]
      [VMware.VimAutomation.ViCore.Types.V1.VIServer]$Server,

      [Parameter(Mandatory = $True, Position = 2)]
      [string]$Source,

	  [Parameter(Mandatory = $False, Position = 3)]
      [boolean]$ImportAssignments
   )

   # Import the tags and categories from the specified source
   $import = Import-Clixml -Path $source
   # Divide the input in separate lists for tags and categories
   $categoryList = $import[0]
   $tagList = $import[1]

   # Store the newly created categories to avoid retrieving them later
   $categories = @()

   # First create all categories on the server
   foreach ($category in $categoryList) {
      $categories += `
         New-TagCategory `
            -Name $category.Name `
            -Description $category.Description `
            -Cardinality $category.Cardinality `
            -EntityType $category.EntityType `
            -Server $server `
         | Out-Null
   }

   # Then create all tags in the corresponding categories
   foreach ($tag in $tagList) {
      # Find the category object in the list
      $category = $categories | where {$_.Name -eq $tag.Category.Name}
      if ($category -eq $null) {$category = $tag.Category.Name}

      New-Tag `
         -Name $tag.Name `
         -Description $tag.Description `
         -Category $category `
         -Server $server `
      | Out-Null
   }

   # Restore the assignments if selected
   If ($ImportAssignments) {
      # Check for assignments in the file
      If ($import[2]) {
         # If tags were found, assign them
	     $tagAssignments = $import[2]
		 ForEach ($assignment in $tagAssignments) {
		    New-TagAssignment `
			   -Tag (Get-Tag -Server $server -Name $assignment.Tag.Name -Category $assignment.Tag.Category) `
			   -Entity (Get-VIObjectByVIView -MORef $assignment.Entity.id) `
			   -Server $server `
			| Out-Null
		 }
	  } else {
	    # If no assignments were found, output warning
		Write-Warning "Source file does not contain tag assignments."
	  }
   }
}
