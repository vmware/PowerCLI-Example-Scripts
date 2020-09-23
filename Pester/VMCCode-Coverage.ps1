Remove-Module VMware.VMC
import-module ../Modules/VMware.VMC/VMware.VMC.psm1

invoke-pester ./Functions -CodeCoverage ..\Modules\VMware.VMC\VMware.VMC.psm1