#Script gets total memory allocation in GB of all powered on VMs in the environment
#Author: Chris Bradshaw via https://isjw.uk/powercli-snippet-total-memory-allocation/

[System.Math]::Round(((get-vm |
  where-object{$_.PowerState -eq "PoweredOn" }).MemoryGB |
  Measure-Object -Sum).Sum ,0)
