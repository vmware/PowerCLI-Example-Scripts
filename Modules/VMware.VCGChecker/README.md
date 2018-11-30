# About 
This module is designed to ease the work of collecting hardware inventory data and compare it with VMware's official VCG data. Before deploying vSphere, it is required to validate your physical machines with VCG to make sure all the devices in your physical machines are compatible with the vSphere version you want to install. It is a time-consuming and painful experience to collect hardware/driver/firmware data from all of the machines, especially when you have a huge number of machines in your data center. 

# How It Works
By using this module, it will automate the data collection and comparison work. 

When running the module, it will connect to the target vCenter or ESXi to read the hardware data. It is a read-only operation and nothing on the target hosts will be changed. There is almost no impact on the machine's performance as the read operation takes just few seconds. 

The module will then send your hardware inventory data to VMware's offical website to conduct a compatibility check. The result will be 'Compatible', 'May not be compatible' or 'Not compatible'. 
* Compatible: the hardware is compatible with the given vSphere release. Link to that VCG page will be provided.
* May not be compatible: manual check is required to confirm the compatibility status of this hardware. A few potential matching VCG records will be provided.
* Not compatible: the hardware is not compatible with the given vSphere release.

After the checking is completed, the module will generate reports in different formats for your review and future use. A summary view in html will give you an overview of your machines compatibility status; an html file with device details to view each device/driver/firmware you have, their compatibility with vSphere version you specified and links to the corresponding VCG documents online; a csv file with device details to allow customization on report in Excel or by your own tool.

# Usage
Considering many data center may have control on internet access, we create 3 cmdlets to meet various situations. 
* Get-VCGHWInfo: cmdlet to collect hardware info
* Get-VCGStatus: cmdlet to check hardware compatibility by query VCG website
* Export-VCGReport: cmdlet to export the summary/html/csv reports

1. You need to first import this module after you import PowerCLI module  
PS> Import-Module &lt;path_to_VMware.VCGChecker.psd1>

2. Connect to the target vSphere hosts using Connect-VIServer and get VMHosts  
PS> Connect-VIServer -Server &lt;server> -User &lt;username> -Password &lt;password>   
PS> $vmhosts = Get-VMHost

3. Collect the hardware data  
PS> $hwdata = Get-VCGHWInfo -vmHosts $vmhosts  
Note: if you don't have internet access, you need to connect your client to internet before proceeding to the next step.

4. Specify the target vSphere release you want to check and submit the hardware data to VMware website  
PS> $vcgdata= Get-VCGStatus -Data $hwdata -Version '&lt;release>'

5. Save the compatibility reports   
PS> Export-VCGReport -Data $vcgdata -Dir &lt;dir>

# Known Limitation
* The module is not able to get the firmware version for HBA devices. 
* The module is not able to get the HDD/SSD data. 
