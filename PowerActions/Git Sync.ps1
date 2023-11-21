#Intall git
tdnf install -y git

#Clone the repo
git clone -n --depth=1 --filter=tree:0 https://github.com/vmware/PowerCLI-Example-Scripts.git
cd PowerCLI-Example-Scripts
git sparse-checkout set --no-cone PowerActions
git checkout
cd PowerActions

#Select the content library in which you want to store the scirpts from the repo
$contentLibraryName = 'Power Actions'
$contentLibrary = Get-ContentLibrary $contentLibraryName

#Get all the files that we have cloned from the repo
$files = Get-ChildItem -Path . -File
foreach ($file in $files) {
    $name = $file.BaseName

    #Check if the item for this file already exists in the content library
    $item = Get-ContentLibraryItem -Name $name -ContentLibrary $contentLibrary -ErrorAction SilentlyContinue
    if ($item) {
        #If the item exists, check if it is up to date
        #Create a folder to store the current content library item
        if (-not (Test-Path -Path ./cl_versions -PathType Container))
        {
            New-Item -Path ./cl_versions -ItemType Directory
        }
        #Download the item from the content library
        $clFile = Export-ContentLibraryItem -ContentLibraryItem $item -Destination ((Get-Location).Path + "/cl_version") -Force
        #Compare if it's the same as the file we have downloaded from the repo
        $compResult = Compare-Object -ReferenceObject (Get-Content $file.FullName) -DifferenceObject (Get-Content ($clFile.FullName+"/"+$file.Name))
        if ($compResult) {
            #If the item is not up to date, update it
            Write-Host "Updating $name"
            Set-ContentLibraryItem -ContentLibraryItem $item -Files $file.FullName
        } else {
            Write-Host "$name is up to date"
        }
    } else {
        #If the item does not exist, create it
        New-ContentLibraryItem -Name $name -Files $file.FullName -ContentLibrary $contentLibrary
    }
}