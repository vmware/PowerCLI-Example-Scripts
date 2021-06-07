
#Get vLCM Image Profile 
#.....List all types of vLCM images 
Get-LcmImage

#.....List Only baseImage (ESXi) vLCM images 
Get-LCMImage -Type 'BaseImage'

#.....List Only VendorAddOn vLCM images 
Get-LCMImage -Type 'VendorAddOn'

#.....List Only Component vLCM images
Get-LCMImage -Type 'Component'

#.....List Only Package(Firmware) vLCM images
Get-LCMImage -Type 'Package'

#.....List Only Package vLCM images
Get-LCMImage -Type 'BaseImage', 'VendorAddOn'

#.....List vLCM Image based on a version

#Create a new Cluster with vLCM Desired Image and
$clusterName= Read-Host -Prompt 'Provide the cluster Name'
$vLCMBaseImage = Get-LCMImage -Version '7.0 GA - 15843807'
New-Cluster -Location Datacenter -Name $clusterName -BaseImage  $vLCMBaseImage -HAEnabled -DrsEnabled


#Get Cluster vlcm desired Image 
#.....Cluster with a vLCM desired Image 
Get-Cluster -Name $clusterName |Select-Object -Property Name, Image, @{n='BaseImageVersion'; e={$_.BaseImage.Version}}, Componenets, VendorAddon

#Update Cluster vLCM desired Image
#.....Change the Cluster Base Image to ESXi 7.0 U2
$vLCMBaseImageu2= Get-LcmImage -Version '7.0 U2a - 17867351'
Get-Cluster -Name $clusterName|Set-Cluster -BaseImage $vLCMBaseImageu2

#Check the Cluster Compliance 
#.....Check the Cluster Compliance 
Get-Cluster -Name $clusterName|Test-LcmClusterCompliance

#Remediate vLCM Cluster
#.....Remediating vLCM
Get-Cluster -Name $clusterName|Set-Cluster -Remediate -AcceptEULA

#Export vLCM Desired Image 
Get-Cluster -Name $clusterName|Export-LcmClusterDesiredState -Destination 'F:\Image' -ExportOfflineBundle -ExportIsoImage

#Import vLCM Desired Image
#Cluster as a parameter
Import-LcmClusterDesiredState -Cluster 'Jatin' -LocalSpecLocation F:\Image\TAM-APJ-desired-state-spec.json -Verbose
#get-cluster and Import vLCM desired image
Get-Cluster -Name 'Jatin1' |Import-LcmClusterDesiredState -LocalSpecLocation F:\Image\TAM-APJ-desired-state-spec.json

#Create a new Cluster and Import LCM desired image 
New-Cluster -Name 'Lab-test' -Location Datacenter |Import-LcmClusterDesiredState -LocalSpecLocation F:\Image\TAM-APJ-desired-state-spec.json
