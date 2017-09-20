#Script returns total disk usage by all Powered On VMs in the environment in Gigabytes
#Author: Chris Bradshaw via  https://isjw.uk/using-powercli-to-measure-vm-disk-space-usage/

[math]::Round(((get-vm | Where-object{$_.PowerState -eq "PoweredOn" }).UsedSpaceGB | measure-Object -Sum).Sum)
