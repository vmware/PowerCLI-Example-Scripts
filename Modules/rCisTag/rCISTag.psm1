function Disable-SSLValidation{
<#
.SYNOPSIS
    Disables SSL certificate validation
.DESCRIPTION
    Disable-SSLValidation disables SSL certificate validation by using reflection to implement the System.Net.ICertificatePolicy class.
 
    Author: Matthew Graeber (@mattifestation)
    License: BSD 3-Clause
.NOTES
    Reflection is ideal in situations when a script executes in an environment in which you cannot call csc.ese to compile source code. If compiling code is an option, then implementing System.Net.ICertificatePolicy in C# and Add-Type is trivial.
.LINK
    http://www.exploit-monday.com
#>
 
    Set-StrictMode -Version 2
 
    # You have already run this function
    if ([System.Net.ServicePointManager]::CertificatePolicy.ToString() -eq 'IgnoreCerts') { Return }
 
    $Domain = [AppDomain]::CurrentDomain
    $DynAssembly = New-Object System.Reflection.AssemblyName('IgnoreCerts')
    $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('IgnoreCerts', $false)
    $TypeBuilder = $ModuleBuilder.DefineType('IgnoreCerts', 'AutoLayout, AnsiClass, Class, Public, BeforeFieldInit', [System.Object], [System.Net.ICertificatePolicy])
    $TypeBuilder.DefineDefaultConstructor('PrivateScope, Public, HideBySig, SpecialName, RTSpecialName') | Out-Null
    $MethodInfo = [System.Net.ICertificatePolicy].GetMethod('CheckValidationResult')
    $MethodBuilder = $TypeBuilder.DefineMethod($MethodInfo.Name, 'PrivateScope, Public, Virtual, HideBySig, VtableLayoutMask', $MethodInfo.CallingConvention, $MethodInfo.ReturnType, ([Type[]] ($MethodInfo.GetParameters() | % {$_.ParameterType})))
    $ILGen = $MethodBuilder.GetILGenerator()
    $ILGen.Emit([Reflection.Emit.Opcodes]::Ldc_I4_1)
    $ILGen.Emit([Reflection.Emit.Opcodes]::Ret)
    $TypeBuilder.CreateType() | Out-Null
 
    # Disable SSL certificate validation
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object IgnoreCerts
}

function Invoke-vCisRest{
    param (
        [String]$Method,
        [String]$Request,
        [PSObject]$Body
    )
    
    Process
    {
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name)"
        Write-Verbose -Message "`t$($PSCmdlet.ParameterSetName)"
        Write-Verbose -Message "`tCalled from $($stack = Get-PSCallStack; $stack[1].Command) at $($stack[1].Location)"
    
        Disable-SSLValidation

        $sRest = @{
          Uri = "https:/",$Script:CisServer.Server,'rest',$Request -join '/'
          Method = $Method
#          Body = &{if($Body){$Body}}
          Body = &{if($Body){$Body | ConvertTo-Json -Depth 32}}
          ContentType = 'application/json'
          Headers = &{
            if($Script:CisServer.ContainsKey('vmware-api-session-id')){
                @{
                    'vmware-api-session-id' = "$($Script:CisServer.'vmware-api-session-id')"
                }
            }
            else{
                @{
                    Authorization = "$($Script:CisServer.AuthHeader)"
                }
            }
          }  
        }
        Try
        {
#            $result = Invoke-WebRequest @sRest
            $result = Invoke-RestMethod @sRest
        }
        Catch
        {
        
        }
        $result
    }
}

function Connect-rCisServer{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory, Position = 1)]
        [String]$Server,
        [Parameter(Mandatory = $True,ValueFromPipeline = $True, Position = 2, ParameterSetName = 'Credential')]
        [System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory = $True, Position = 2, ParameterSetName = 'PlainText')]
        [String]$User,
        [Parameter(Mandatory = $True, Position = 3, ParameterSetName = 'PlainText')]
        [String]$Password,
        [string]$Proxy,
        [Parameter(DontShow)]
        [switch]$Fiddler = $false
    )
    
    Process
    {
        if ($Proxy)
        {
          if ($PSDefaultParameterValues.ContainsKey('*:Proxy'))
          {
            $PSDefaultParameterValues['*:Proxy'] = $Proxy
          }
          else
          {
            $PSDefaultParameterValues.Add('*:Proxy', $Proxy)
          }
          if ($PSDefaultParameterValues.ContainsKey('*:ProxyUseDefaultCredentials'))
          {
            $PSDefaultParameterValues['*:ProxyUseDefaultCredentials'] = $True
          }
          else
          {
            $PSDefaultParameterValues.Add('*:ProxyUseDefaultCredentials', $True)
          }
        }
        if ($PSCmdlet.ParameterSetName -eq 'PlainText')
        {
          $sPswd = ConvertTo-SecureString -String $Password -AsPlainText -Force
          $CisCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ($User, $sPswd)
        }
        if ($PSCmdlet.ParameterSetName -eq 'Credential')
        {
          $CisCredential = $Credential
        }
        if ($Fiddler)
        {
          if (Get-Process -Name fiddler -ErrorAction SilentlyContinue)
          {
            if ($PSDefaultParameterValues.ContainsKey('Invoke-RestMethod:Proxy'))
            {
              $PSDefaultParameterValues['Invoke-RestMethod:Proxy'] = 'http://127.0.0.1:8888'
            }
            else
            {
              $PSDefaultParameterValues.Add('Invoke-RestMethod:Proxy', 'http://127.0.0.1:8888')
            }
          }
        }
        $Script:CisServer = @{
            Server = $Server
            AuthHeader = &{
                $User = $CisCredential.UserName
                $Password = $CisCredential.GetNetworkCredential().password
		
                $Encoded = [System.Text.Encoding]::UTF8.GetBytes(($User, $Password -Join ':'))
                $EncodedPassword = [System.Convert]::ToBase64String($Encoded)
                "Basic $($EncodedPassword)"
            }
        }
        $sRest = @{
            Method = 'Post'
            Request = 'com/vmware/cis/session'
        }
        If($PSCmdlet.ShouldProcess("CisServer $($Server)"))
        {
            $result = Invoke-vCisRest @sRest

            $Script:CisServer.Add('vmware-api-session-id',$result.value)
            $Script:CisServer.Remove('AuthHeader')
        }
    }
}

function Disconnect-rCisServer{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $True, Position = 1)]
        [String]$Server
    )
    
    Process
    {
        if($Server -ne $Script:CisServer.Server){
            Write-Warning "You are not connected to server $($Server)"
        }

        $sRest = @{
            Method = 'Delete'
            Request = 'com/vmware/cis/session'
        }
        If($PSCmdlet.ShouldProcess("CisServer $($Server)"))
        {
            $result = Invoke-vCisRest @sRest
            $Script:CisServer.Remove('vmware-api-session-id')
        }
    }    
}

function Get-rCisTag{`	
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low', DefaultParameterSetName='Name')]
    param (
        [Parameter(Position = 1, ParameterSetName='Name')]
        [String[]]$Name,
        [Parameter(Position = 2, ParameterSetName='Name',ValueFromPipeline = $true)]
        [PSObject[]]$Category,
        [Parameter(Mandatory = $True, Position = 1, ParameterSetName='Id')]
        [String[]]$Id
    )

    Process
    {
        if($PSCmdlet.ParameterSetName -eq 'Name'){
            if($Category){
                $tagIds = $Category | %{
                    $categoryIds = &{if($_ -is [string]){
                        (Get-rCisTagCategory -Name $_).Id
                    }
                    else{
                        $_.Id
                    }}
                    $categoryIds | %{
                        # Get all tags in categories
                        $sRest = @{
                            Method = 'Post'
                            Request = "com/vmware/cis/tagging/tag/id:$([uri]::EscapeDataString($_))?~action=list-tags-for-category"
                        }
                        (Invoke-vCisRest @sRest).value
                    }
                }
            }
            else{
                $sRest = @{
                    Method = 'Get'
                    Request = 'com/vmware/cis/tagging/tag'
                }
                $tagIds = (Invoke-vCisRest @sRest).value
            }
        }
        else{
            $tagIds = $Id
        }

        # Get category details
        $out = @()
        $tagIds | where{($PSCmdlet.ParameterSetName -eq 'Id' -and $Id -contains $_) -or $PSCmdlet.ParameterSetName -eq 'Name'} | %{
            $sRest = @{
                Method = 'Get'
                Request = "com/vmware/cis/tagging/tag/id:$([uri]::EscapeDataString($_))"
            }
            $result = Invoke-vCisRest @sRest

            if($PSCmdlet.ParameterSetName -eq 'Id' -or ($PSCmdlet.ParameterSetName -eq 'Name' -and ($Name -eq $null -or $Name -contains $result.value.name))){
                $out += New-Object PSObject -Property @{
                    Description = $result.value.description
                    Id = $result.value.id
                    Name = $result.value.name
                    Category = (Get-rCisTagCategory -Id $result.value.category_id).Name
                    Uid = "$($global:defaultviserver.Id)Tag=$($result.value.id)/"
                    Client = $global:defaultviserver.Client
                }
            }
        }
        $out | Select-Object Category,Description,Id,Name,Uid,Client
    }

}

function Get-rCisTagCategory{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low', DefaultParameterSetName='Name')]
    param (
        [Parameter(Position = 1, ParameterSetName='Name')]
        [String[]]$Name,
        [Parameter(Mandatory = $True, Position = 1, ParameterSetName='Id')]
        [String[]]$Id
    )

    Begin
    {
        $txtInfo = (Get-Culture).TextInfo
        $entityTab = @{
            'ClusterComputeResource' = 'Cluster'
            'DistributedVirtualSwitch' = 'DistributedSwitch'
            'VmwareDistributedVirtualSwitch' = 'DistributedSwitch'
            'HostSystem' = 'VMHost'
            'DistributedVirtualPortGroup' = 'DistributedPortGroup'
            'VirtualApp' = 'VApp'
            'StoragePod' = 'DatastoreCluster'
            'Network' = 'VirtualPortGroup'
        }
    }

    Process
    {
        if($PSCmdlet.ParameterSetName -eq 'Name'){
            # Get all categories
            $sRest = @{
                Method = 'Get'
                Request = 'com/vmware/cis/tagging/category'
            }
            $tagCategoryIds = (Invoke-vCisRest @sRest).value
        }
        else{
            $tagCategoryIds = $Id
        }

        # Get category details
        $out = @()
        $tagCategoryids | where{($PSCmdlet.ParameterSetName -eq 'Id' -and $Id -contains $_) -or $PSCmdlet.ParameterSetName -eq 'Name'} | %{
            $sRest = @{
                Method = 'Get'
                Request = "com/vmware/cis/tagging/category/id:$([uri]::EscapeDataString($_))"
            }
            $result = Invoke-vCisRest @sRest
            if($PSCmdlet.ParameterSetName -eq 'Id' -or ($PSCmdlet.ParameterSetName -eq 'Name' -and ($Name -eq $null -or $Name -contains $result.value.name))){
                $out += New-Object PSObject -Property @{
                    Description = $result.value.description
                    Cardinality = $txtInfo.ToTitleCase($result.value.cardinality.ToLower())
                    EntityType = @(&{
                        if($result.value.associable_types.Count -eq 0){'All'}
                        else{
                            $result.value.associable_types | %{
                                if($entityTab.ContainsKey($_)){
                                    $entityTab.Item($_)
                                }
                                else{$_}
                            }
                        }} | Sort-Object -Unique)
                    Id = $result.value.id
                    Name = $result.value.name
                    Uid = "$($global:defaultviserver.Id)TagCategory=$($result.value.id)/"
                    Client = $global:defaultviserver.Client
                }
            }
        }
        $out | Select-Object Description,Cardinality,EntityType,Id,Name,Uid,Client             
    }
}

function Get-rCisTagAssignment{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Low')]
    param (
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [PSObject[]]$Entity,
        [parameter(Position = 2)]
        [PSObject[]]$Tag,
        [parameter(Position = 3)]
        [PSObject[]]$Category
    )

    Begin
    {
        if($Category.Count -ne 0 -or $Tag.Count -ne 0){
            $tagIds = @((Get-rCisTag -Name $Tag -Category $Category).Id)
        }
        else{
            $tagIds = @((Get-rCisTag).Id)
        }
        $out = @()
    }

    Process
    {
        foreach($ent in $Entity){
            if($ent -is [string]){
                $ent = Get-Inventory -Name $ent -ErrorAction SilentlyContinue
            }

            $entMoRef = New-Object PSObject -Property @{
                    type = $ent.ExtensionData.MoRef.Type
                    id = $ent.ExtensionData.MoRef.Value
            }
            $sRest = @{
                Method = 'Post'
                Request = 'com/vmware/cis/tagging/tag-association?~action=list-attached-tags-on-objects'
                Body = @{
                    object_ids = @($entMoRef)
                }
            }
            $tagObj = (Invoke-vCisRest @sRest).value
            foreach($obj in @($tagObj)){
                foreach($tag in ($obj.tag_ids | where{$tagIds -contains $_})){
                    $sMoRef = "$($obj.object_id.type)-$($obj.object_id.id)"
                    $out += New-Object PSObject -Property @{
                        Entity = (Get-View -id $sMoRef -Property Name).Name
                        Tag = (Get-rCisTag -Id $tag).Name
                        Id = 'com.vmware.cis.tagging.TagAssociationModel'
                        Name = 'com.vmware.cis.tagging.TagAssociationModel'
                        Uid = "$($global:defaultviserver.Id)VirtualMachine=$($sMoRef)/TagAssignment=/Tag=$($tag.tag_id)/"
                        Client = $global:defaultviserver.Client
                    }
                }
            }
        }
    }

    End
    {
        if($out.Count -eq 0)
        {
            $sRest = @{
                Method = 'Post'
                Request = 'com/vmware/cis/tagging/tag-association?~action=list-attached-objects-on-tags'
                Body = @{
                    tag_ids = $tagIds
                }
            }
            $tagObj = (Invoke-vCisRest @sRest).value
            $out = foreach($tag in @(($tagObj | where{$tagIds -contains $_.tag_id}))){
                foreach($obj in $tag.object_ids){
                    $sMoRef = "$($obj.type)-$($obj.id)"
                    New-Object PSObject -Property @{
                        Entity = (Get-View -id $sMoRef -Property Name).Name
                        Tag = (Get-rCisTag -Id $tag.tag_id).Name
                        Id = 'com.vmware.cis.tagging.TagAssociationModel'
                        Name = 'com.vmware.cis.tagging.TagAssociationModel'
                        Uid = "$($global:defaultviserver.Id)VirtualMachine=$($sMoRef)/TagAssignment=/Tag=$($tag.tag_id)/"
                        Client = $global:defaultviserver.Client
                    }
                }
            }
        }

        $out | Select-Object Uid,Tag,Entity,Id,Name,Client
    }
}

function New-rCisTag{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory=$true, Position = 1)]
        [String[]]$Name,
        [Parameter(Mandatory=$true, Position = 2,ValueFromPipeline = $true)]
        [PSObject]$Category,
        [Parameter(Position = 3)]
        [string]$Description
    )

    Process
    {
        $out = @()
        if($Category -is [String]){
            $Category = Get-rCisTagCategory -Name $Category
        }
        $Name | %{
            $sRest = @{
                Method = 'Post'
                Request = 'com/vmware/cis/tagging/tag'
                Body = @{
                    create_spec = @{
                        category_id = $Category.Id
                        name = $_
                        description = $Description
                    }
                }
            }
            $tagId = (Invoke-vCisRest @sRest).value
            $out += New-Object PSObject -Property @{
                Category = $Category.Name
                Description = $Description
                Id = $tagId
                Name = $_
                Uid = "$($global:defaultviserver.Id)Tag=$($tagId)/"
                Client = $global:defaultviserver.Client
            }
        }
        $out | Select-Object Category,Description,Id,Name,Uid,Client
    }
}

function New-rCisTagCategory{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory=$true, Position = 1)]
        [String[]]$Name,
        [Parameter(Position = 2)]
        [ValidateSet('Single','Multiple')]
        [string]$Cardinality = 'Single',
        [Parameter(Position = 3)]
        [string]$Description,
        [Parameter(Position = 4)]
        [string[]]$EntityType
    )

    Process
    {
        $out = @()
        $Name | %{
            $sRest = @{
                Method = 'Post'
                Request = 'com/vmware/cis/tagging/category'
                Body = @{
                    create_spec = @{
                        cardinality = $Cardinality.ToUpper()
                        associable_types = @($EntityType)
                        name = $_
                        description = $Description
                    }
                }
            }
            $categoryId = (Invoke-vCisRest @sRest).value
            $out += New-Object PSObject -Property @{
                    Description = $Description
                    Cardinality = $Cardinality
                    EntityType = @($EntityType)
                    Id = $categoryId
                    Name = $_
                    Uid = "$($global:defaultviserver.Id)TagCategory=$($categoryId)/"
                    Client = $global:defaultviserver.Client
            }
        }
        $out | Select-Object Description,Cardinality,EntityType,Id,Name,Uid,Client             
    }
}

function New-rCisTagAssignment{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory=$true, Position = 1)]
        [String[]]$Tag,
        [Parameter(Mandatory=$true,ValueFromPipeline = $true, Position = 2)]
        [PSObject[]]$Entity
    )
    
    Process
    {
        $tagIds = @((Get-rCisTag -Name $Tag).Id)
        $Entity = foreach($ent in $Entity){
            if($ent -is [string]){
                $ent = Get-Inventory -Name $ent -ErrorAction SilentlyContinue
            }
            $entMoRef = New-Object PSObject -Property @{
                    type = $ent.ExtensionData.MoRef.Type
                    id = $ent.ExtensionData.MoRef.Value
            }
            foreach($tagId in $tagIds){
                $sRest = @{
                    Method = 'Post'
                    Request = "com/vmware/cis/tagging/tag-association/id:$($tagId)?~action=attach"
                    Body = @{
                        object_id = $entMoRef
                    }
                }
                Invoke-vCisRest @sRest
            }
        }
    }

#        foreach($ent in 
#        if($Tag.Count -eq 1)
#        {
#            $tagId = (Get-rCisTag -Name $Tag).Id
#        }
#        elseif($Tag.Count -gt 1)
#        {
#            $tagIds = (Get-rCisTag -Name $Tag).Id
#        }
#        $Entity = foreach($ent in $Entity){
#            if($ent -is [string]){
#                Get-Inventory -Name $ent -ErrorAction SilentlyContinue
#            }
#            else{$ent}
#        }
#
#        if($Entity.Count -eq 1)
#        {
#            $entMoRef = New-Object PSObject -Property @{
#                    type = $Entity[0].ExtensionData.MoRef.Type
#                    id = $Entity[0].ExtensionData.MoRef.Value
#            }
#            if($tag.Count -eq 1){
#                $sRest = @{
#                    Method = 'Post'
#                    Request = "com/vmware/cis/tagging/tag-association/id:$($tagId)?~action=attach"
#                    Body = @{
#                        object_id = $entMoRef
#                    }
#                }
#                Invoke-vCisRest @sRest
#            }
#            elseif($Tag.Count -gt 1){
#                $sRest = @{
#                    Method = 'Post'
#                    Request = 'com/vmware/cis/tagging/tagassociation?~action=attach-multiple-tags-to-object'
#                    Body = @{
#                        object_id = $entMoRef
#                        tag_ids = @($tagIds)
#                    }
#                }
#                Invoke-vCisRest @sRest
#            }
#        }
#        elseif($Entity.Count -gt 1)
#        {
#            $entMorefs = $Entity | %{
#                New-Object PSObject -Property @{
#                    type = $_.ExtensionData.MoRef.Type
#                    id = $_.ExtensionData.MoRef.Value
#                }
#            }
#            if($tag.Count -eq 1){
#                $sRest = @{
#                    Method = 'Post'
#                    Request = 'com/vmware/cis/tagging/tagassociation/id:$($tagId)?~action=attach-tag-to-multiple-objects'
#                    Body = @{
#                        objects_ids = @($entMoRefs)
#                        tag_id = $tagId
#                    }
#                }
#                Invoke-vCisRest @sRest
#            }
#            elseif($Tag.Count -gt 1){
#                $tagIds | %{
#                    $sRest = @{
#                        Method = 'Post'
#                        Request = 'com/vmware/cis/tagging/tagassociation/id:$($tagId)?~action=attach-tag-to-multiple-objects'
#                        Body = @{
#                            objects_ids = @($entMoRefs)
#                            tag_id = $_
#                        }
#                    }
#                    Invoke-vCisRest @sRest
#                }                    
#            }
#        }
#    }
}

function Remove-rCisTag{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High', DefaultParameterSetName='Name')]
    param (
        [Parameter(Mandatory=$true, Position = 1, ValueFromPipeline = $true,ParameterSetName='Name')]
        [PSObject[]]$Tag,
        [Parameter(Mandatory=$true, Position = 1, ValueFromPipelineByPropertyName = $true,ParameterSetName='Id')]
        [String[]]$Id
    )
    
    Process
    {
        if($PSCmdlet.ParameterSetName -eq 'Name'){
            foreach($tagObj in $Tag){
                if($tagObj -is [string]){
                    $tagObj = Get-rCisTag -Name $tagObj
                }
                $sRest = @{
                    Method = 'Delete'
                    Request = "com/vmware/cis/tagging/tag/id:$($tagObj.Id)"
                }
                Invoke-vCisRest @sRest
            }
        }
        else{
            foreach($tagId in $Id){
                $sRest = @{
                    Method = 'Delete'
                    Request = "com/vmware/cis/tagging/tag/id:$($tagId)"
                }
                Invoke-vCisRest @sRest
            }
        }
    }
}

function Remove-rCisTagCategory{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High', DefaultParameterSetName='Name')]
    param (
        [Parameter(Mandatory=$true,Position = 1, ValueFromPipeline = $true,ParameterSetName='Name')]
        [PSObject[]]$Category,
        [Parameter(Mandatory=$true,Position = 1, ValueFromPipelineByPropertyName = $true,ParameterSetName='Id')]
        [String[]]$Id
    )
    
    Process
    {
        if($PSCmdlet.ParameterSetName -eq 'Name'){
            foreach($catObj in $Category){
                if($catObj -is [string]){
                    $catObj = Get-rCisTagCategory -Name $catObj
                }
                $sRest = @{
                    Method = 'Delete'
                    Request = "com/vmware/cis/tagging/category/id:$($catObj.Id)"
                }
                Invoke-vCisRest @sRest
            }
        }
        else{
            foreach($catId in $Id){
                $sRest = @{
                    Method = 'Delete'
                    Request = "com/vmware/cis/tagging/category/id:$($catId)"
                }
                Invoke-vCisRest @sRest
            }
        }
    }
}

function Remove-rCisTagAssignment{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High',DefaultParameterSetName='Assignment')]
    param (
        [Parameter(Mandatory=$true, Position = 1, ValueFromPipeline = $true,ParameterSetName='Assignment')]
        [PSObject[]]$TagAssignment,
        [Parameter(Mandatory=$true,Position = 1, ValueFromPipeline = $true,ParameterSetName='Name')]
        [string[]]$Tag,
        [Parameter(Position = 2, ParameterSetName='Name')]
        [string[]]$Category,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true,ParameterSetName='Id')]
        [string[]]$TagId,
        [Parameter(ParameterSetName='Name')]
        [Parameter(ParameterSetName='Id')]
        [PSObject[]]$Entity
    )
    
    Process
    {
        
        switch ($PSCmdlet.ParameterSetName){
           'Name' {
                $TagAssignment = Get-rCisTagAssignment -Entity $Entity -Tag $Tag -Category $Category
            }
            'Id' {
                $tags = Get-rCisTag -Id $TagId
                $TagAssignment = Get-rCisTagAssignment -Tag $tags.Name -Entity $Entity
            }
        }
        if($TagAssignment){
            $entMoRefs = @(Get-Inventory -Name $TagAssignment.Entity -ErrorAction SilentlyContinue | %{
                New-Object PSObject -Property @{
                    type = $_.ExtensionData.MoRef.Type
                    id = $_.ExtensionData.MoRef.Value
                }
            })
            $tagIds = @((Get-rCisTag -Name $TagAssignment.Tag).Id)
        }

        foreach($entMoRef in $entMoRefs){
            foreach($tId in $tagIds){
                $sRest = @{
                    Method = 'Post'
                    Request = "com/vmware/cis/tagging/tag-association/id:$($tId)?~action=detach"
                    Body = @{
                        object_id = $entMoRef
                    }
                }
                Invoke-vCisRest @sRest
            }
        }
    }
}

function Set-rCisTag{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory=$true, Position = 1, ValueFromPipeline = $true)]
        [PSObject[]]$Tag,
        [Parameter(Position = 2)]
        [string]$Name,
        [Parameter(Position = 3)]
        [string]$Description
    )

    Process
    {
        foreach($tagObj in $Tag){
            if($tagObj -is [string]){
                $tagObj = Get-rCisTag -Name $tagObj
            }
            $sRest = @{
                Method = 'Patch'
                Request = "com/vmware/cis/tagging/tag/id:$($tagObj.Id)"
                Body = @{
                    update_spec = @{
                        name = $Name
                        description = $Description
                    }
                }
            }
            Invoke-vCisRest @sRest
        }
    }
}

function Set-rCisTagCategory{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory=$true, Position = 1, ValueFromPipeline = $true)]
        [PSObject[]]$Category,
        [Parameter(Position = 2)]
        [string]$Name,
        [Parameter(Position = 3)]
        [ValidateSet('Single','Multiple')]
        [string]$Cardinality,                             # Only SINGLE to MULTIPLE
#        [string[]]$AddEntityType,                        # Does not work
        [string]$Description
    )

    Process
    {
         foreach($catObj in $Category){
            if($catObj -is [string]){
                $catObj = Get-rCisTagCategory -Name $catObj
            }
            $sRest = @{
                Method = 'Patch'
                Request = "com/vmware/cis/tagging/category/id:$($catObj.Id)"
                Body = @{
                    update_spec = @{
                    }
                }
            }
            if($Name){
                $sRest.Body.update_spec.Add('name',$Name)
            }
            if($Description){
                $sRest.Body.update_spec.Add('description',$Description)
            }
            if($Cardinality -and $catObj.Cardinality -eq 'SINGLE'){
                $sRest.Body.update_spec.Add('cardinality',$Cardinality.ToUpper())
            }
            if($Name -or $Description -or $Cardinality){
                Invoke-vCisRest @sRest
            }
        }
    }
}
