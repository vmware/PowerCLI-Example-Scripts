function Export-Tag {
   [CmdletBinding()]
   Param (
      [Parameter(Mandatory = $True, Position = 1)]
      [VMware.VimAutomation.ViCore.Types.V1.VIServer]$Server, 
      
      [Parameter(Mandatory = $True, Position = 2)]
      [string]$Destination
   )
   
   # Retrieve all categories
   $categoryList = Get-TagCategory -Server $server
   # Retrieve all tags
   $tagList = Get-Tag -Server $server
   # Store the tags and categories in a list to export them at once
   $export = @($categoryList, $tagList)
   # Export the tags and categories to the specified destination
   Export-Clixml -InputObject $export -Path $destination
}

function Import-Tag {
   [CmdletBinding()]
   Param (
      [Parameter(Mandatory = $True, Position = 1)]
      [VMware.VimAutomation.ViCore.Types.V1.VIServer]$Server, 
      
      [Parameter(Mandatory = $True, Position = 2)]
      [string]$Source
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
}